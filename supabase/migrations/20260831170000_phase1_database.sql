-- Makko Phase 1: Supabase database
--
-- This migration is intentionally forward-only. Once applied to a shared
-- Supabase project, make any correction in a new timestamped migration rather
-- than editing this file. It is safe to apply to a fresh database; it is not
-- a destructive reset and is not intended to be re-applied after it succeeds.

CREATE SCHEMA IF NOT EXISTS private;

-- Supabase projects provide the extensions schema. Creating it here also keeps
-- this migration usable in a vanilla local PostgreSQL test database.
CREATE SCHEMA IF NOT EXISTS extensions;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

CREATE TYPE public.issue_type AS ENUM (
  'task',
  'bug'
);

CREATE TYPE public.issue_priority AS ENUM (
  'low',
  'medium',
  'high'
);

CREATE TYPE public.issue_status AS ENUM (
  'todo',
  'in_progress',
  'done'
);

-- CHECK constraints cannot contain subqueries. Keep the tag invariant in a
-- small immutable helper so it remains database-enforced and index-safe.
CREATE OR REPLACE FUNCTION private.valid_project_tags(p_tags text[])
RETURNS boolean
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
RETURNS NULL ON NULL INPUT
SET search_path = ''
AS $$
  SELECT pg_catalog.cardinality(p_tags) <= 20
    AND pg_catalog.array_position(p_tags, NULL) IS NULL
    AND NOT EXISTS (
      SELECT 1
      FROM pg_catalog.unnest(p_tags) AS tag(value)
      WHERE pg_catalog.btrim(value) = ''
         OR value <> pg_catalog.btrim(value)
         OR pg_catalog.char_length(value) > 40
    )
    AND (
      SELECT pg_catalog.count(DISTINCT pg_catalog.lower(value))
      FROM pg_catalog.unnest(p_tags) AS tag(value)
    ) = pg_catalog.cardinality(p_tags);
$$;

CREATE TABLE public.projects (
  id uuid PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  owner_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  name text NOT NULL,
  description text,
  tags text[] NOT NULL DEFAULT '{}'::text[],
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT projects_name_not_blank CHECK (btrim(name) <> ''),
  CONSTRAINT projects_name_trimmed CHECK (name = btrim(name)),
  CONSTRAINT projects_name_length CHECK (char_length(name) BETWEEN 1 AND 120),
  CONSTRAINT projects_description_length CHECK (
    description IS NULL OR (description = btrim(description)
      AND btrim(description) <> '' AND char_length(description) <= 5000)
  ),
  CONSTRAINT projects_tags_valid CHECK (private.valid_project_tags(tags))
);

CREATE TABLE public.issues (
  id uuid PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES public.projects (id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  type public.issue_type NOT NULL,
  priority public.issue_priority NOT NULL DEFAULT 'medium',
  status public.issue_status NOT NULL DEFAULT 'todo',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT issues_title_not_blank CHECK (btrim(title) <> ''),
  CONSTRAINT issues_title_trimmed CHECK (title = btrim(title)),
  CONSTRAINT issues_title_length CHECK (char_length(title) BETWEEN 1 AND 200),
  CONSTRAINT issues_description_length CHECK (
    description IS NULL OR (description = btrim(description)
      AND btrim(description) <> '' AND char_length(description) <= 10000)
  )
);

CREATE TABLE public.activity_log (
  id uuid PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES public.projects (id) ON DELETE CASCADE,
  issue_id uuid REFERENCES public.issues (id) ON DELETE SET NULL,
  action text NOT NULL,
  description text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT activity_log_action_not_blank CHECK (btrim(action) <> ''),
  CONSTRAINT activity_log_action_length CHECK (char_length(action) <= 64),
  CONSTRAINT activity_log_action_allowed CHECK (
    action IN ('project.created', 'project.updated', 'issue.created',
      'issue.updated', 'issue.deleted')
  ),
  CONSTRAINT activity_log_description_not_blank CHECK (btrim(description) <> ''),
  CONSTRAINT activity_log_description_length CHECK (char_length(description) <= 1000)
);

CREATE TABLE public.github_links (
  id uuid PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES public.projects (id) ON DELETE CASCADE,
  repo_full_name text NOT NULL,
  last_synced_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT github_links_project_unique UNIQUE (project_id),
  CONSTRAINT github_links_repo_not_blank CHECK (btrim(repo_full_name) <> ''),
  CONSTRAINT github_links_repo_length CHECK (char_length(repo_full_name) <= 140),
  CONSTRAINT github_links_repo_trimmed CHECK (repo_full_name = btrim(repo_full_name)),
  CONSTRAINT github_links_repo_shape CHECK (
    repo_full_name ~ '^[A-Za-z0-9][A-Za-z0-9-]{0,38}/[A-Za-z0-9._-]{1,100}$'
  )
);

CREATE TABLE public.github_commits (
  id uuid PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  github_link_id uuid NOT NULL REFERENCES public.github_links (id) ON DELETE CASCADE,
  sha text NOT NULL,
  message text NOT NULL,
  author_name text,
  author_login text,
  committed_at timestamptz NOT NULL,
  html_url text NOT NULL,
  synced_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT github_commits_link_sha_unique UNIQUE (github_link_id, sha),
  CONSTRAINT github_commits_sha_format CHECK (sha ~ '^[0-9A-Fa-f]{40,64}$'),
  CONSTRAINT github_commits_message_length CHECK (char_length(message) <= 10000),
  CONSTRAINT github_commits_author_name_length CHECK (
    author_name IS NULL OR char_length(author_name) <= 255
  ),
  CONSTRAINT github_commits_author_login_length CHECK (
    author_login IS NULL OR char_length(author_login) <= 39
  ),
  CONSTRAINT github_commits_url CHECK (
    html_url ~ '^https://github[.]com/[[:graph:]]+$'
  )
);

CREATE TABLE public.github_issues (
  id uuid PRIMARY KEY DEFAULT extensions.gen_random_uuid(),
  github_link_id uuid NOT NULL REFERENCES public.github_links (id) ON DELETE CASCADE,
  github_node_id text NOT NULL,
  number integer NOT NULL,
  title text NOT NULL,
  state text NOT NULL,
  author_login text,
  labels text[] NOT NULL DEFAULT '{}'::text[],
  github_created_at timestamptz NOT NULL,
  github_updated_at timestamptz NOT NULL,
  html_url text NOT NULL,
  synced_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT github_issues_link_node_unique UNIQUE (github_link_id, github_node_id),
  CONSTRAINT github_issues_link_number_unique UNIQUE (github_link_id, number),
  CONSTRAINT github_issues_node_id_not_blank CHECK (btrim(github_node_id) <> ''),
  CONSTRAINT github_issues_node_id_length CHECK (char_length(github_node_id) <= 255),
  CONSTRAINT github_issues_number_positive CHECK (number > 0),
  CONSTRAINT github_issues_title_not_blank CHECK (btrim(title) <> ''),
  CONSTRAINT github_issues_title_length CHECK (char_length(title) <= 500),
  CONSTRAINT github_issues_state_valid CHECK (state IN ('open', 'closed')),
  CONSTRAINT github_issues_author_login_length CHECK (
    author_login IS NULL OR char_length(author_login) <= 39
  ),
  CONSTRAINT github_issues_labels_no_nulls CHECK (array_position(labels, NULL) IS NULL),
  CONSTRAINT github_issues_url CHECK (
    html_url ~ '^https://github[.]com/[[:graph:]]+$'
  )
);

-- Foreign-key indexes support ownership joins, cascades, and the common
-- project-scoped reads used by both clients.
CREATE INDEX projects_owner_updated_at_idx
  ON public.projects (owner_id, updated_at DESC);

CREATE INDEX issues_project_created_at_idx
  ON public.issues (project_id, created_at DESC);
CREATE INDEX issues_project_status_idx ON public.issues (project_id, status);
CREATE INDEX issues_project_priority_idx ON public.issues (project_id, priority);
CREATE INDEX issues_project_type_idx ON public.issues (project_id, type);

CREATE INDEX activity_log_issue_id_idx ON public.activity_log (issue_id);
CREATE INDEX activity_log_project_created_at_idx
  ON public.activity_log (project_id, created_at DESC);

CREATE INDEX github_commits_link_committed_at_idx
  ON public.github_commits (github_link_id, committed_at DESC);
CREATE INDEX github_issues_link_updated_at_idx
  ON public.github_issues (github_link_id, github_updated_at DESC);

-- Only change updated_at when a meaningful mutable field changed. This avoids
-- timestamp churn when a client submits an identical row or only updated_at.
CREATE OR REPLACE FUNCTION private.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  IF TG_TABLE_NAME = 'projects' THEN
    IF NEW.name IS NOT DISTINCT FROM OLD.name
       AND NEW.description IS NOT DISTINCT FROM OLD.description
       AND NEW.tags IS NOT DISTINCT FROM OLD.tags THEN
      NEW.updated_at := OLD.updated_at;
    ELSE
      NEW.updated_at := pg_catalog.now();
    END IF;
  ELSIF TG_TABLE_NAME = 'issues' THEN
    IF NEW.title IS NOT DISTINCT FROM OLD.title
       AND NEW.description IS NOT DISTINCT FROM OLD.description
       AND NEW.type IS NOT DISTINCT FROM OLD.type
       AND NEW.priority IS NOT DISTINCT FROM OLD.priority
       AND NEW.status IS NOT DISTINCT FROM OLD.status THEN
      NEW.updated_at := OLD.updated_at;
    ELSE
      NEW.updated_at := pg_catalog.now();
    END IF;
  ELSE
    RAISE EXCEPTION 'private.set_updated_at attached to unsupported table %', TG_TABLE_NAME;
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION private.prevent_issue_project_change()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  IF NEW.project_id IS DISTINCT FROM OLD.project_id THEN
    RAISE EXCEPTION 'issues.project_id is immutable after insert'
      USING ERRCODE = '23000';
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION private.log_project_activity()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_description text;
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.activity_log (project_id, action, description)
    VALUES (
      NEW.id,
      'project.created',
      pg_catalog.format('Project created: "%s"', NEW.name)
    );
    RETURN NEW;
  END IF;

  -- updated_at-only and identical updates are intentionally silent.
  IF OLD.name IS NOT DISTINCT FROM NEW.name
     AND OLD.description IS NOT DISTINCT FROM NEW.description
     AND OLD.tags IS NOT DISTINCT FROM NEW.tags THEN
    RETURN NEW;
  END IF;

  v_description := 'Project updated';
  IF OLD.name IS DISTINCT FROM NEW.name THEN
    v_description := pg_catalog.format('Project renamed from "%s" to "%s"', OLD.name, NEW.name);
  ELSIF OLD.description IS DISTINCT FROM NEW.description THEN
    v_description := 'Project description updated';
  ELSIF OLD.tags IS DISTINCT FROM NEW.tags THEN
    v_description := 'Project tags updated';
  END IF;

  INSERT INTO public.activity_log (project_id, action, description)
  VALUES (NEW.id, 'project.updated', v_description);
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION private.log_issue_activity()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_description text;
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.activity_log (project_id, issue_id, action, description)
    VALUES (
      NEW.project_id,
      NEW.id,
      'issue.created',
      pg_catalog.format('Issue created: "%s"', NEW.title)
    );
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    -- A project/account cascade removes the parent before its child rows. In
    -- that path there is no valid project FK target for a history row; a
    -- direct issue delete still reaches the insert below while the project
    -- exists.
    IF NOT EXISTS (
      SELECT 1
      FROM public.projects
      WHERE public.projects.id = OLD.project_id
    ) THEN
      RETURN OLD;
    END IF;

    -- Keep the history row after the issue disappears, without retaining a
    -- dangling issue identifier.
    INSERT INTO public.activity_log (project_id, issue_id, action, description)
    VALUES (
      OLD.project_id,
      NULL,
      'issue.deleted',
      pg_catalog.format('Issue deleted: "%s"', OLD.title)
    );
    RETURN OLD;
  END IF;

  -- updated_at-only and identical updates are intentionally silent.
  IF OLD.title IS NOT DISTINCT FROM NEW.title
     AND OLD.description IS NOT DISTINCT FROM NEW.description
     AND OLD.type IS NOT DISTINCT FROM NEW.type
     AND OLD.priority IS NOT DISTINCT FROM NEW.priority
     AND OLD.status IS NOT DISTINCT FROM NEW.status THEN
    RETURN NEW;
  END IF;

  IF OLD.status IS DISTINCT FROM NEW.status THEN
    v_description := pg_catalog.format('Issue "%s" status changed from %s to %s',
      NEW.title, OLD.status, NEW.status);
  ELSIF OLD.priority IS DISTINCT FROM NEW.priority THEN
    v_description := pg_catalog.format('Issue "%s" priority changed from %s to %s',
      NEW.title, OLD.priority, NEW.priority);
  ELSIF OLD.type IS DISTINCT FROM NEW.type THEN
    v_description := pg_catalog.format('Issue "%s" type changed from %s to %s',
      NEW.title, OLD.type, NEW.type);
  ELSIF OLD.title IS DISTINCT FROM NEW.title THEN
    v_description := pg_catalog.format('Issue renamed from "%s" to "%s"', OLD.title, NEW.title);
  ELSE
    v_description := pg_catalog.format('Issue "%s" description updated', NEW.title);
  END IF;

  INSERT INTO public.activity_log (project_id, issue_id, action, description)
  VALUES (NEW.project_id, NEW.id, 'issue.updated', v_description);
  RETURN NEW;
END;
$$;

CREATE TRIGGER projects_set_updated_at
BEFORE UPDATE ON public.projects
FOR EACH ROW
EXECUTE FUNCTION private.set_updated_at();

CREATE TRIGGER projects_activity_log
AFTER INSERT OR UPDATE ON public.projects
FOR EACH ROW
EXECUTE FUNCTION private.log_project_activity();

CREATE TRIGGER issues_set_updated_at
BEFORE UPDATE ON public.issues
FOR EACH ROW
EXECUTE FUNCTION private.set_updated_at();

CREATE TRIGGER issues_project_id_immutable
BEFORE UPDATE OF project_id ON public.issues
FOR EACH ROW
EXECUTE FUNCTION private.prevent_issue_project_change();

CREATE TRIGGER issues_activity_log
AFTER INSERT OR UPDATE OR DELETE ON public.issues
FOR EACH ROW
EXECUTE FUNCTION private.log_issue_activity();

-- RLS is enabled on every application table. Do not use FORCE RLS: trusted
-- SECURITY DEFINER activity triggers need to insert their own history rows.
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.issues ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.github_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.github_commits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.github_issues ENABLE ROW LEVEL SECURITY;

CREATE POLICY projects_select_own
ON public.projects FOR SELECT TO authenticated
USING (owner_id = (SELECT auth.uid()));

CREATE POLICY projects_insert_own
ON public.projects FOR INSERT TO authenticated
WITH CHECK (owner_id = (SELECT auth.uid()));

CREATE POLICY projects_update_own
ON public.projects FOR UPDATE TO authenticated
USING (owner_id = (SELECT auth.uid()))
WITH CHECK (owner_id = (SELECT auth.uid()));

CREATE POLICY projects_delete_own
ON public.projects FOR DELETE TO authenticated
USING (owner_id = (SELECT auth.uid()));

CREATE POLICY issues_select_owned_project
ON public.issues FOR SELECT TO authenticated
USING (EXISTS (
  SELECT 1
  FROM public.projects AS p
  WHERE p.id = issues.project_id
    AND p.owner_id = (SELECT auth.uid())
));

CREATE POLICY issues_insert_owned_project
ON public.issues FOR INSERT TO authenticated
WITH CHECK (EXISTS (
  SELECT 1
  FROM public.projects AS p
  WHERE p.id = issues.project_id
    AND p.owner_id = (SELECT auth.uid())
));

CREATE POLICY issues_update_owned_project
ON public.issues FOR UPDATE TO authenticated
USING (EXISTS (
  SELECT 1
  FROM public.projects AS p
  WHERE p.id = issues.project_id
    AND p.owner_id = (SELECT auth.uid())
))
WITH CHECK (EXISTS (
  SELECT 1
  FROM public.projects AS p
  WHERE p.id = issues.project_id
    AND p.owner_id = (SELECT auth.uid())
));

CREATE POLICY issues_delete_owned_project
ON public.issues FOR DELETE TO authenticated
USING (EXISTS (
  SELECT 1
  FROM public.projects AS p
  WHERE p.id = issues.project_id
    AND p.owner_id = (SELECT auth.uid())
));

CREATE POLICY activity_log_select_owned_project
ON public.activity_log FOR SELECT TO authenticated
USING (EXISTS (
  SELECT 1
  FROM public.projects AS p
  WHERE p.id = activity_log.project_id
    AND p.owner_id = (SELECT auth.uid())
));

CREATE POLICY github_links_select_owned_project
ON public.github_links FOR SELECT TO authenticated
USING (EXISTS (
  SELECT 1
  FROM public.projects AS p
  WHERE p.id = github_links.project_id
    AND p.owner_id = (SELECT auth.uid())
));

CREATE POLICY github_links_insert_owned_project
ON public.github_links FOR INSERT TO authenticated
WITH CHECK (EXISTS (
  SELECT 1
  FROM public.projects AS p
  WHERE p.id = github_links.project_id
    AND p.owner_id = (SELECT auth.uid())
));

CREATE POLICY github_links_delete_owned_project
ON public.github_links FOR DELETE TO authenticated
USING (EXISTS (
  SELECT 1
  FROM public.projects AS p
  WHERE p.id = github_links.project_id
    AND p.owner_id = (SELECT auth.uid())
));

CREATE POLICY github_commits_select_owned_project
ON public.github_commits FOR SELECT TO authenticated
USING (EXISTS (
  SELECT 1
  FROM public.github_links AS gl
  JOIN public.projects AS p ON p.id = gl.project_id
  WHERE gl.id = github_commits.github_link_id
    AND p.owner_id = (SELECT auth.uid())
));

CREATE POLICY github_issues_select_owned_project
ON public.github_issues FOR SELECT TO authenticated
USING (EXISTS (
  SELECT 1
  FROM public.github_links AS gl
  JOIN public.projects AS p ON p.id = gl.project_id
  WHERE gl.id = github_issues.github_link_id
    AND p.owner_id = (SELECT auth.uid())
));

-- Keep the API surface explicit. Service-role writes are intentionally not
-- granted here; Phase 2's Edge Function will use its trusted server role.
REVOKE ALL ON TABLE
  public.projects,
  public.issues,
  public.activity_log,
  public.github_links,
  public.github_commits,
  public.github_issues
FROM PUBLIC, anon, authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.projects TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.issues TO authenticated;
GRANT SELECT ON public.activity_log TO authenticated;
GRANT SELECT ON public.github_links TO authenticated;
GRANT INSERT (project_id, repo_full_name) ON public.github_links TO authenticated;
GRANT DELETE ON public.github_links TO authenticated;
GRANT SELECT ON public.github_commits, public.github_issues TO authenticated;

-- Private helper functions are trigger-only. No API role can call trusted
-- insertion or validation helpers directly.
REVOKE ALL ON SCHEMA private FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION
  private.valid_project_tags(text[]),
  private.set_updated_at(),
  private.prevent_issue_project_change(),
  private.log_project_activity(),
  private.log_issue_activity()
FROM PUBLIC, anon, authenticated;

-- The tag validator is used by an authenticated INSERT's CHECK constraint.
-- Expose only that immutable validator; trigger functions remain private.
GRANT USAGE ON SCHEMA private TO authenticated;
GRANT EXECUTE ON FUNCTION private.valid_project_tags(text[]) TO authenticated;
