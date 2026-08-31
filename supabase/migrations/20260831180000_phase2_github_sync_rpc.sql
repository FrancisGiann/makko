-- Makko Phase 2: atomic GitHub snapshot writes
--
-- This is a forward-only migration. The synchronization Edge Function is the
-- only caller of this narrowly scoped SECURITY DEFINER RPC. The function
-- accepts complete, already-mapped snapshots and makes the replacement of a
-- link's cached rows atomic.

ALTER TABLE public.github_links
  ADD COLUMN IF NOT EXISTS sync_lease_token uuid,
  ADD COLUMN IF NOT EXISTS sync_lease_expires_at timestamptz;

ALTER TABLE public.github_links
  DROP CONSTRAINT IF EXISTS github_links_sync_lease_state;

ALTER TABLE public.github_links
  ADD CONSTRAINT github_links_sync_lease_state CHECK (
    (sync_lease_token IS NULL) = (sync_lease_expires_at IS NULL)
  );

CREATE OR REPLACE FUNCTION public.begin_github_sync(
  p_owner_id uuid,
  p_github_link_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_link public.github_links%ROWTYPE;
  v_project_owner uuid;
  v_now timestamptz;
  v_lease_token uuid;
  v_lease_expires_at timestamptz;
BEGIN
  IF p_owner_id IS NULL OR p_github_link_id IS NULL THEN
    RAISE EXCEPTION 'GitHub sync identifiers are required'
      USING ERRCODE = '22023';
  END IF;
  SELECT gl.*
  INTO v_link
  FROM public.github_links AS gl
  JOIN public.projects AS p ON p.id = gl.project_id
  WHERE gl.id = p_github_link_id
  FOR UPDATE OF gl, p;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'GitHub link not found or not owned by caller'
      USING ERRCODE = '42501';
  END IF;

  SELECT p.owner_id
  INTO v_project_owner
  FROM public.projects AS p
  WHERE p.id = v_link.project_id;

  IF NOT FOUND OR v_project_owner IS DISTINCT FROM p_owner_id THEN
    RAISE EXCEPTION 'GitHub link not found or not owned by caller'
      USING ERRCODE = '42501';
  END IF;

  v_now := pg_catalog.clock_timestamp();
  IF (v_link.sync_lease_token IS NOT NULL AND
      v_link.sync_lease_expires_at > v_now)
     OR (v_link.last_synced_at IS NOT NULL AND
         v_link.last_synced_at > v_now - INTERVAL '60 seconds') THEN
    -- One generic conflict code covers both an active lease and the short
    -- successful-sync cooldown without disclosing link state.
    RAISE EXCEPTION 'GitHub sync is temporarily unavailable'
      USING ERRCODE = '55006';
  END IF;

  v_lease_token := extensions.gen_random_uuid();
  v_lease_expires_at := v_now + INTERVAL '2 minutes';
  UPDATE public.github_links
  SET sync_lease_token = v_lease_token,
      sync_lease_expires_at = v_lease_expires_at
  WHERE id = v_link.id;

  RETURN pg_catalog.jsonb_build_object(
    'github_link_id', v_link.id,
    'project_id', v_link.project_id,
    'repo_full_name', v_link.repo_full_name,
    'last_synced_at', v_link.last_synced_at,
    'sync_lease_token', v_lease_token,
    'sync_lease_expires_at', v_lease_expires_at
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.abort_github_sync(
  p_owner_id uuid,
  p_github_link_id uuid,
  p_sync_lease_token uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_link public.github_links%ROWTYPE;
  v_project_owner uuid;
BEGIN
  IF p_owner_id IS NULL OR p_github_link_id IS NULL THEN
    RAISE EXCEPTION 'GitHub sync identifiers are required'
      USING ERRCODE = '22023';
  END IF;
  IF p_sync_lease_token IS NULL THEN
    RAISE EXCEPTION 'GitHub sync lease token is required'
      USING ERRCODE = '22023';
  END IF;

  SELECT gl.*
  INTO v_link
  FROM public.github_links AS gl
  JOIN public.projects AS p ON p.id = gl.project_id
  WHERE gl.id = p_github_link_id
  FOR UPDATE OF gl, p;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'GitHub link not found or not owned by caller'
      USING ERRCODE = '42501';
  END IF;

  SELECT p.owner_id
  INTO v_project_owner
  FROM public.projects AS p
  WHERE p.id = v_link.project_id;

  IF NOT FOUND OR v_project_owner IS DISTINCT FROM p_owner_id THEN
    RAISE EXCEPTION 'GitHub link not found or not owned by caller'
      USING ERRCODE = '42501';
  END IF;

  UPDATE public.github_links
  SET sync_lease_token = NULL,
      sync_lease_expires_at = NULL
  WHERE id = v_link.id
    AND sync_lease_token IS NOT DISTINCT FROM p_sync_lease_token;

  RETURN FOUND;
END;
$$;

CREATE OR REPLACE FUNCTION public.apply_github_sync(
  p_owner_id uuid,
  p_github_link_id uuid,
  p_sync_lease_token uuid,
  p_commits jsonb,
  p_issues jsonb
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_link public.github_links%ROWTYPE;
  v_project_owner uuid;
  v_commit record;
  v_issue record;
  v_commit_count integer := 0;
  v_issue_count integer := 0;
  v_synced_at timestamptz;
  v_now timestamptz;
BEGIN
  IF p_owner_id IS NULL OR p_github_link_id IS NULL OR p_sync_lease_token IS NULL THEN
    RAISE EXCEPTION 'GitHub sync identifiers are required'
      USING ERRCODE = '22023';
  END IF;

  IF pg_catalog.jsonb_typeof(p_commits) IS DISTINCT FROM 'array'
     OR pg_catalog.jsonb_typeof(p_issues) IS DISTINCT FROM 'array' THEN
    RAISE EXCEPTION 'GitHub sync snapshots must be JSON arrays'
      USING ERRCODE = '22023';
  END IF;

  -- These limits mirror the public GitHub fetch contract and prevent this
  -- service-role-only function from becoming an unbounded write surface.
  IF pg_catalog.jsonb_array_length(p_commits) > 30
     OR pg_catalog.jsonb_array_length(p_issues) > 500 THEN
    RAISE EXCEPTION 'GitHub sync snapshot exceeds its maximum size'
      USING ERRCODE = '22023';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM pg_catalog.jsonb_array_elements(p_commits) AS item
    WHERE pg_catalog.jsonb_typeof(item) IS DISTINCT FROM 'object'
  ) OR EXISTS (
    SELECT 1
    FROM pg_catalog.jsonb_array_elements(p_issues) AS item
    WHERE pg_catalog.jsonb_typeof(item) IS DISTINCT FROM 'object'
  ) THEN
    RAISE EXCEPTION 'GitHub sync snapshot entries must be JSON objects'
      USING ERRCODE = '22023';
  END IF;

  -- Lock the link before checking ownership. Every RPC call for a link is
  -- therefore serialized, and the project ownership check is against the
  -- current row rather than caller-supplied project data.
  SELECT gl.*
  INTO v_link
  FROM public.github_links AS gl
  JOIN public.projects AS p ON p.id = gl.project_id
  WHERE gl.id = p_github_link_id
  FOR UPDATE OF gl, p;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'GitHub link not found or not owned by caller'
      USING ERRCODE = '42501';
  END IF;

  SELECT p.owner_id
  INTO v_project_owner
  FROM public.projects AS p
  WHERE p.id = v_link.project_id;

  IF NOT FOUND OR v_project_owner IS DISTINCT FROM p_owner_id THEN
    RAISE EXCEPTION 'GitHub link not found or not owned by caller'
      USING ERRCODE = '42501';
  END IF;

  v_now := pg_catalog.clock_timestamp();
  IF v_link.sync_lease_token IS DISTINCT FROM p_sync_lease_token
     OR v_link.sync_lease_expires_at IS NULL
     OR v_link.sync_lease_expires_at <= v_now THEN
    RAISE EXCEPTION 'GitHub sync is temporarily unavailable'
      USING ERRCODE = '55006';
  END IF;

  -- DISTINCT ON keeps the first occurrence of duplicate keys in the complete
  -- snapshot. The table constraints remain the final validator for all
  -- lengths, formats, states, URLs, and cross-key conflicts.
  FOR v_commit IN
    SELECT DISTINCT ON (mapped.sha)
      mapped.sha,
      mapped.message,
      mapped.author_name,
      mapped.author_login,
      mapped.committed_at,
      mapped.html_url
    FROM pg_catalog.jsonb_array_elements(p_commits) WITH ORDINALITY AS raw(item, ordinal)
    CROSS JOIN LATERAL pg_catalog.jsonb_to_record(raw.item) AS mapped(
      sha text,
      message text,
      author_name text,
      author_login text,
      committed_at timestamptz,
      html_url text
    )
    ORDER BY mapped.sha, raw.ordinal
  LOOP
    INSERT INTO public.github_commits (
      github_link_id,
      sha,
      message,
      author_name,
      author_login,
      committed_at,
      html_url,
      synced_at
    )
    VALUES (
      v_link.id,
      v_commit.sha,
      v_commit.message,
      v_commit.author_name,
      v_commit.author_login,
      v_commit.committed_at,
      v_commit.html_url,
      pg_catalog.now()
    )
    ON CONFLICT (github_link_id, sha) DO UPDATE
    SET message = EXCLUDED.message,
        author_name = EXCLUDED.author_name,
        author_login = EXCLUDED.author_login,
        committed_at = EXCLUDED.committed_at,
        html_url = EXCLUDED.html_url,
        synced_at = EXCLUDED.synced_at;

    v_commit_count := v_commit_count + 1;
  END LOOP;

  DELETE FROM public.github_commits AS cached
  WHERE cached.github_link_id = v_link.id
    AND NOT EXISTS (
      SELECT 1
      FROM pg_catalog.jsonb_array_elements(p_commits) AS raw(item)
      WHERE cached.sha = pg_catalog.jsonb_extract_path_text(raw.item, 'sha')
    );

  FOR v_issue IN
    SELECT DISTINCT ON (mapped.github_node_id)
      mapped.github_node_id,
      mapped.number,
      mapped.title,
      mapped.state,
      mapped.author_login,
      mapped.labels,
      mapped.github_created_at,
      mapped.github_updated_at,
      mapped.html_url
    FROM pg_catalog.jsonb_array_elements(p_issues) WITH ORDINALITY AS raw(item, ordinal)
    CROSS JOIN LATERAL pg_catalog.jsonb_to_record(raw.item) AS mapped(
      github_node_id text,
      number integer,
      title text,
      state text,
      author_login text,
      labels text[],
      github_created_at timestamptz,
      github_updated_at timestamptz,
      html_url text
    )
    ORDER BY mapped.github_node_id, raw.ordinal
  LOOP
    INSERT INTO public.github_issues (
      github_link_id,
      github_node_id,
      number,
      title,
      state,
      author_login,
      labels,
      github_created_at,
      github_updated_at,
      html_url,
      synced_at
    )
    VALUES (
      v_link.id,
      v_issue.github_node_id,
      v_issue.number,
      v_issue.title,
      v_issue.state,
      v_issue.author_login,
      v_issue.labels,
      v_issue.github_created_at,
      v_issue.github_updated_at,
      v_issue.html_url,
      pg_catalog.now()
    )
    ON CONFLICT (github_link_id, github_node_id) DO UPDATE
    SET number = EXCLUDED.number,
        title = EXCLUDED.title,
        state = EXCLUDED.state,
        author_login = EXCLUDED.author_login,
        labels = EXCLUDED.labels,
        github_created_at = EXCLUDED.github_created_at,
        github_updated_at = EXCLUDED.github_updated_at,
        html_url = EXCLUDED.html_url,
        synced_at = EXCLUDED.synced_at;

    v_issue_count := v_issue_count + 1;
  END LOOP;

  DELETE FROM public.github_issues AS cached
  WHERE cached.github_link_id = v_link.id
    AND NOT EXISTS (
      SELECT 1
      FROM pg_catalog.jsonb_array_elements(p_issues) AS raw(item)
      WHERE cached.github_node_id = pg_catalog.jsonb_extract_path_text(raw.item, 'github_node_id')
    );

  -- Do this last. If any upsert, prune, or constraint check above fails, the
  -- function transaction rolls back and the previous sync timestamp remains.
  v_synced_at := pg_catalog.now();
  UPDATE public.github_links
  SET last_synced_at = v_synced_at,
      sync_lease_token = NULL,
      sync_lease_expires_at = NULL
  WHERE id = v_link.id;

  RETURN pg_catalog.jsonb_build_object(
    'commits_synced', v_commit_count,
    'issues_synced', v_issue_count,
    'last_synced_at', v_synced_at
  );
END;
$$;

REVOKE ALL ON FUNCTION public.apply_github_sync(uuid, uuid, uuid, jsonb, jsonb)
FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.begin_github_sync(uuid, uuid)
FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.abort_github_sync(uuid, uuid, uuid)
FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.begin_github_sync(uuid, uuid)
TO service_role;
GRANT EXECUTE ON FUNCTION public.abort_github_sync(uuid, uuid, uuid)
TO service_role;
GRANT EXECUTE ON FUNCTION public.apply_github_sync(uuid, uuid, uuid, jsonb, jsonb)
TO service_role;
