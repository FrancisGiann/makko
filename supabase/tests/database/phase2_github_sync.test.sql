BEGIN;

SELECT * FROM no_plan();

SELECT ok(
  to_regprocedure('public.begin_github_sync(uuid,uuid)') IS NOT NULL,
  'begin sync RPC exists'
);
SELECT ok(
  to_regprocedure('public.abort_github_sync(uuid,uuid,uuid)') IS NOT NULL,
  'abort sync RPC exists'
);
SELECT ok(
  to_regprocedure('public.apply_github_sync(uuid,uuid,uuid,jsonb,jsonb)') IS NOT NULL,
  'apply sync RPC exists'
);
SELECT ok(
  has_function_privilege('service_role', 'public.begin_github_sync(uuid,uuid)', 'EXECUTE')
  AND has_function_privilege('service_role', 'public.abort_github_sync(uuid,uuid,uuid)', 'EXECUTE')
  AND has_function_privilege('service_role', 'public.apply_github_sync(uuid,uuid,uuid,jsonb,jsonb)', 'EXECUTE'),
  'service_role can execute all sync lifecycle RPCs'
);
SELECT ok(
  NOT has_function_privilege('anon', 'public.begin_github_sync(uuid,uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.abort_github_sync(uuid,uuid,uuid)', 'EXECUTE')
  AND NOT has_function_privilege('anon', 'public.apply_github_sync(uuid,uuid,uuid,jsonb,jsonb)', 'EXECUTE'),
  'anon cannot execute sync lifecycle RPCs'
);
SELECT ok(
  NOT has_function_privilege('authenticated', 'public.begin_github_sync(uuid,uuid)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'public.abort_github_sync(uuid,uuid,uuid)', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'public.apply_github_sync(uuid,uuid,uuid,jsonb,jsonb)', 'EXECUTE'),
  'authenticated cannot execute sync lifecycle RPCs'
);
SELECT ok(
  EXISTS (SELECT 1 FROM pg_catalog.pg_attribute
          WHERE attrelid = 'public.github_links'::regclass AND attname = 'sync_lease_token' AND NOT attisdropped)
  AND EXISTS (SELECT 1 FROM pg_catalog.pg_attribute
              WHERE attrelid = 'public.github_links'::regclass AND attname = 'sync_lease_expires_at' AND NOT attisdropped),
  'GitHub links have persisted lease state'
);
SELECT ok(EXISTS (
  SELECT 1 FROM pg_catalog.pg_constraint
  WHERE conrelid = 'public.github_links'::regclass AND conname = 'github_links_sync_lease_state'
), 'lease token and expiry must be set or cleared together');
SELECT ok(EXISTS (
  SELECT 1 FROM pg_catalog.pg_constraint
  WHERE conrelid = 'public.github_commits'::regclass AND contype = 'f'
    AND confrelid = 'public.github_links'::regclass AND confdeltype = 'c'
), 'cached commits retain link cascade compatibility');
SELECT ok(EXISTS (
  SELECT 1 FROM pg_catalog.pg_constraint
  WHERE conrelid = 'public.github_issues'::regclass AND contype = 'f'
    AND confrelid = 'public.github_links'::regclass AND confdeltype = 'c'
), 'cached issues retain link cascade compatibility');

INSERT INTO auth.users (id, email)
VALUES
  ('00000000-0000-0000-0000-000000000011', 'phase2-a@example.test'),
  ('00000000-0000-0000-0000-000000000012', 'phase2-b@example.test');
INSERT INTO public.projects (id, owner_id, name)
VALUES
  ('10000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000011', 'Phase 2 A'),
  ('10000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000012', 'Phase 2 B');
INSERT INTO public.github_links (id, project_id, repo_full_name)
VALUES
  ('30000000-0000-0000-0000-000000000011', '10000000-0000-0000-0000-000000000011', 'makko/phase-two'),
  ('30000000-0000-0000-0000-000000000012', '10000000-0000-0000-0000-000000000012', 'makko/other');
INSERT INTO public.github_commits
  (github_link_id, sha, message, committed_at, html_url)
VALUES
  ('30000000-0000-0000-0000-000000000011', repeat('b', 40), 'stale commit',
   '2025-01-01T00:00:00Z', 'https://github.com/makko/phase-two/commit/' || repeat('b', 40));
INSERT INTO public.github_issues
  (github_link_id, github_node_id, number, title, state, labels,
   github_created_at, github_updated_at, html_url)
VALUES
  ('30000000-0000-0000-0000-000000000011', 'stale-node', 99, 'Stale issue', 'open', '{}',
   '2025-01-01T00:00:00Z', '2025-01-01T00:00:00Z',
   'https://github.com/makko/phase-two/issues/99');

SET LOCAL ROLE service_role;
CREATE TEMP TABLE phase2_sync_state (
  lease_token uuid NOT NULL,
  lease_expires_at timestamptz NOT NULL
) ON COMMIT DROP;

SELECT throws_ok(
  $$SELECT public.begin_github_sync(
    '00000000-0000-0000-0000-000000000012',
    '30000000-0000-0000-0000-000000000011'
  )$$,
  '42501', NULL::text, 'wrong owner is rejected before leasing'
);
SELECT is((SELECT count(*)::int FROM public.github_commits
           WHERE github_link_id = '30000000-0000-0000-0000-000000000011'), 1,
          'wrong-owner rejection leaves commits unchanged');
SELECT is((SELECT count(*)::int FROM public.github_issues
           WHERE github_link_id = '30000000-0000-0000-0000-000000000011'), 1,
          'wrong-owner rejection leaves issues unchanged');

INSERT INTO phase2_sync_state
SELECT (result->>'sync_lease_token')::uuid, (result->>'sync_lease_expires_at')::timestamptz
FROM (SELECT public.begin_github_sync(
  '00000000-0000-0000-0000-000000000011',
  '30000000-0000-0000-0000-000000000011'
) AS result) AS begun;
SELECT ok((SELECT lease_expires_at > clock_timestamp() FROM phase2_sync_state), 'lease expiry is in the future');
SELECT ok((SELECT lease_expires_at <= clock_timestamp() + interval '2 minutes 1 second' FROM phase2_sync_state),
          'lease expiry is bounded');
SELECT throws_ok(
  $$SELECT public.begin_github_sync(
    '00000000-0000-0000-0000-000000000011',
    '30000000-0000-0000-0000-000000000011'
  )$$,
  '55006', NULL::text, 'active lease rejects a concurrent begin'
);

SELECT throws_ok(
  $$SELECT public.apply_github_sync(
    '00000000-0000-0000-0000-000000000011',
    '30000000-0000-0000-0000-000000000011',
    'ffffffff-ffff-ffff-ffff-ffffffffffff', '[]'::jsonb, '[]'::jsonb
  )$$,
  '55006', NULL::text, 'mismatched apply token is rejected'
);
SELECT is(public.abort_github_sync(
  '00000000-0000-0000-0000-000000000011',
  '30000000-0000-0000-0000-000000000011',
  'ffffffff-ffff-ffff-ffff-ffffffffffff'
), false, 'mismatched abort token does not clear the lease');
SELECT throws_ok(
  $$SELECT public.abort_github_sync(
    '00000000-0000-0000-0000-000000000011',
    '30000000-0000-0000-0000-000000000011',
    NULL::uuid
  )$$,
  '22023', NULL::text, 'NULL abort token is rejected'
);
SELECT ok((SELECT sync_lease_token IS NOT NULL FROM public.github_links
           WHERE id = '30000000-0000-0000-0000-000000000011'),
          'mismatched token leaves lease state intact');
SELECT throws_ok(
  $$SELECT public.apply_github_sync(
    '00000000-0000-0000-0000-000000000012',
    '30000000-0000-0000-0000-000000000011',
    (SELECT lease_token FROM phase2_sync_state), '[]'::jsonb, '[]'::jsonb
  )$$,
  '42501', NULL::text, 'wrong-owner apply is rejected'
);

SELECT is((public.apply_github_sync(
  '00000000-0000-0000-0000-000000000011',
  '30000000-0000-0000-0000-000000000011',
  (SELECT lease_token FROM phase2_sync_state),
  jsonb_build_array(
    jsonb_build_object(
      'sha', repeat('a', 40), 'message', 'first commit', 'author_name', 'Makko',
      'author_login', 'makko', 'committed_at', '2026-01-01T00:00:00Z',
      'html_url', 'https://github.com/makko/phase-two/commit/' || repeat('a', 40)
    ),
    jsonb_build_object(
      'sha', repeat('a', 40), 'message', 'duplicate commit',
      'committed_at', '2026-01-01T00:00:00Z',
      'html_url', 'https://github.com/makko/phase-two/commit/' || repeat('a', 40)
    )
  ),
  jsonb_build_array(
    jsonb_build_object(
      'github_node_id', 'node-one', 'number', 1, 'title', 'First issue', 'state', 'open',
      'author_login', 'makko', 'labels', jsonb_build_array('bug'),
      'github_created_at', '2026-01-01T00:00:00Z', 'github_updated_at', '2026-01-02T00:00:00Z',
      'html_url', 'https://github.com/makko/phase-two/issues/1'
    ),
    jsonb_build_object(
      'github_node_id', 'node-one', 'number', 1, 'title', 'Duplicate issue', 'state', 'open',
      'labels', jsonb_build_array('task'), 'github_created_at', '2026-01-01T00:00:00Z',
      'github_updated_at', '2026-01-02T00:00:00Z',
      'html_url', 'https://github.com/makko/phase-two/issues/1'
    )
  )
)->>'commits_synced')::int, 1, 'duplicate snapshot rows count once');
SELECT is((SELECT message FROM public.github_commits
           WHERE github_link_id = '30000000-0000-0000-0000-000000000011'
             AND sha = repeat('a', 40)), 'first commit', 'first duplicate commit wins');
SELECT is((SELECT title FROM public.github_issues
           WHERE github_link_id = '30000000-0000-0000-0000-000000000011'
             AND github_node_id = 'node-one'), 'First issue', 'first duplicate issue wins');
SELECT is((SELECT count(*)::int FROM public.github_commits
           WHERE github_link_id = '30000000-0000-0000-0000-000000000011'
             AND sha = repeat('b', 40)), 0, 'stale commit is pruned');
SELECT is((SELECT count(*)::int FROM public.github_issues
           WHERE github_link_id = '30000000-0000-0000-0000-000000000011'
             AND github_node_id = 'stale-node'), 0, 'stale issue is pruned');
SELECT ok((SELECT sync_lease_token IS NULL AND sync_lease_expires_at IS NULL
           FROM public.github_links WHERE id = '30000000-0000-0000-0000-000000000011'),
          'successful apply clears the lease');
SELECT ok((SELECT last_synced_at IS NOT NULL FROM public.github_links
           WHERE id = '30000000-0000-0000-0000-000000000011'),
          'successful apply updates last_synced_at');

SELECT throws_ok(
  $$SELECT public.begin_github_sync(
    '00000000-0000-0000-0000-000000000011',
    '30000000-0000-0000-0000-000000000011'
  )$$,
  '55006', NULL::text, 'recent successful sync is cooled down'
);

SET LOCAL ROLE postgres;
UPDATE public.github_links SET last_synced_at = NULL
WHERE id = '30000000-0000-0000-0000-000000000011';
SET LOCAL ROLE service_role;
TRUNCATE phase2_sync_state;
INSERT INTO phase2_sync_state
SELECT (result->>'sync_lease_token')::uuid, (result->>'sync_lease_expires_at')::timestamptz
FROM (SELECT public.begin_github_sync(
  '00000000-0000-0000-0000-000000000011',
  '30000000-0000-0000-0000-000000000011'
) AS result) AS begun;

SET LOCAL ROLE postgres;
UPDATE public.github_links SET last_synced_at = '2026-02-01T00:00:00Z'
WHERE id = '30000000-0000-0000-0000-000000000011';
SET LOCAL ROLE service_role;
SELECT throws_ok(
  $$SELECT public.apply_github_sync(
    '00000000-0000-0000-0000-000000000011',
    '30000000-0000-0000-0000-000000000011',
    (SELECT lease_token FROM phase2_sync_state),
    jsonb_build_array(jsonb_build_object(
      'sha', 'not-a-sha', 'message', 'must rollback',
      'committed_at', '2026-01-04T00:00:00Z',
      'html_url', 'https://github.com/makko/phase-two/commit/not-a-sha'
    )),
    '[]'::jsonb
  )$$,
  '23514', NULL::text, 'invalid payload rolls back with a constraint error'
);
SELECT is((SELECT count(*)::int FROM public.github_commits
           WHERE github_link_id = '30000000-0000-0000-0000-000000000011'
             AND sha = 'not-a-sha'), 0, 'invalid payload leaves no partial row');
SELECT is((SELECT last_synced_at FROM public.github_links
           WHERE id = '30000000-0000-0000-0000-000000000011'),
          '2026-02-01T00:00:00+00'::timestamptz, 'invalid payload keeps timestamp');
SELECT ok((SELECT sync_lease_token IS NOT NULL FROM public.github_links
           WHERE id = '30000000-0000-0000-0000-000000000011'),
          'failed apply leaves lease for explicit abort');
SELECT is(public.abort_github_sync(
  '00000000-0000-0000-0000-000000000011',
  '30000000-0000-0000-0000-000000000011',
  (SELECT lease_token FROM phase2_sync_state)
), true, 'matching abort clears the failed lease');
SELECT ok((SELECT sync_lease_token IS NULL AND sync_lease_expires_at IS NULL
           FROM public.github_links WHERE id = '30000000-0000-0000-0000-000000000011'),
          'abort clears both lease fields');

SET LOCAL ROLE postgres;
UPDATE public.github_links SET last_synced_at = NULL
WHERE id = '30000000-0000-0000-0000-000000000011';
SET LOCAL ROLE service_role;
TRUNCATE phase2_sync_state;
INSERT INTO phase2_sync_state
SELECT (result->>'sync_lease_token')::uuid, (result->>'sync_lease_expires_at')::timestamptz
FROM (SELECT public.begin_github_sync(
  '00000000-0000-0000-0000-000000000011',
  '30000000-0000-0000-0000-000000000011'
) AS result) AS begun;
SELECT public.apply_github_sync(
  '00000000-0000-0000-0000-000000000011',
  '30000000-0000-0000-0000-000000000011',
  (SELECT lease_token FROM phase2_sync_state), '[]'::jsonb, '[]'::jsonb
);
SELECT is((SELECT count(*)::int FROM public.github_commits
           WHERE github_link_id = '30000000-0000-0000-0000-000000000011'), 0,
          'empty commit snapshot prunes all commits');
SELECT is((SELECT count(*)::int FROM public.github_issues
           WHERE github_link_id = '30000000-0000-0000-0000-000000000011'), 0,
          'empty issue snapshot prunes all issues');

SET LOCAL ROLE postgres;
INSERT INTO public.github_commits
  (github_link_id, sha, message, committed_at, html_url)
VALUES
  ('30000000-0000-0000-0000-000000000012', repeat('c', 40), 'cascade', now(),
   'https://github.com/makko/other/commit/' || repeat('c', 40));
INSERT INTO public.github_issues
  (github_link_id, github_node_id, number, title, state, labels,
   github_created_at, github_updated_at, html_url)
VALUES
  ('30000000-0000-0000-0000-000000000012', 'cascade-node', 1, 'cascade', 'open', '{}',
   now(), now(), 'https://github.com/makko/other/issues/1');
SET LOCAL ROLE service_role;
TRUNCATE phase2_sync_state;
INSERT INTO phase2_sync_state
SELECT (result->>'sync_lease_token')::uuid, (result->>'sync_lease_expires_at')::timestamptz
FROM (SELECT public.begin_github_sync(
  '00000000-0000-0000-0000-000000000012',
  '30000000-0000-0000-0000-000000000012'
) AS result) AS begun;
SELECT is(public.abort_github_sync(
  '00000000-0000-0000-0000-000000000012',
  '30000000-0000-0000-0000-000000000012',
  (SELECT lease_token FROM phase2_sync_state)
), true, 'matching abort succeeds on another link');
SET LOCAL ROLE postgres;
DELETE FROM public.projects WHERE id = '10000000-0000-0000-0000-000000000012';
SELECT is((SELECT count(*)::int FROM public.github_commits
           WHERE github_link_id = '30000000-0000-0000-0000-000000000012'), 0,
          'project deletion cascades commits');
SELECT is((SELECT count(*)::int FROM public.github_issues
           WHERE github_link_id = '30000000-0000-0000-0000-000000000012'), 0,
          'project deletion cascades issues');

SELECT * FROM finish();
ROLLBACK;
