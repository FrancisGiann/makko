BEGIN;

SELECT * FROM no_plan();

-- Schema, enum order, indexes, and RLS posture.
SELECT ok(to_regclass('public.projects') IS NOT NULL, 'projects table exists');
SELECT ok(to_regclass('public.issues') IS NOT NULL, 'issues table exists');
SELECT ok(to_regclass('public.activity_log') IS NOT NULL, 'activity_log table exists');
SELECT ok(to_regclass('public.github_links') IS NOT NULL, 'github_links table exists');
SELECT ok(to_regclass('public.github_commits') IS NOT NULL, 'github_commits table exists');
SELECT ok(to_regclass('public.github_issues') IS NOT NULL, 'github_issues table exists');
SELECT is(
  (SELECT array_agg(enumlabel ORDER BY enumsortorder)::text
   FROM pg_catalog.pg_enum e
   JOIN pg_catalog.pg_type t ON t.oid = e.enumtypid
   JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
   WHERE n.nspname = 'public' AND t.typname = 'issue_type'),
  '{task,bug}', 'issue_type enum values are stable'
);
SELECT is(
  (SELECT array_agg(enumlabel ORDER BY enumsortorder)::text
   FROM pg_catalog.pg_enum e
   JOIN pg_catalog.pg_type t ON t.oid = e.enumtypid
   JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
   WHERE n.nspname = 'public' AND t.typname = 'issue_priority'),
  '{low,medium,high}', 'issue_priority enum values are stable'
);
SELECT is(
  (SELECT array_agg(enumlabel ORDER BY enumsortorder)::text
   FROM pg_catalog.pg_enum e
   JOIN pg_catalog.pg_type t ON t.oid = e.enumtypid
   JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
   WHERE n.nspname = 'public' AND t.typname = 'issue_status'),
  '{todo,in_progress,done}', 'issue_status enum values are stable'
);
SELECT ok(to_regclass('public.projects_owner_updated_at_idx') IS NOT NULL, 'project owner/update index exists');
SELECT ok(to_regclass('public.issues_project_created_at_idx') IS NOT NULL, 'issue project/create index exists');
SELECT ok(to_regclass('public.issues_project_status_idx') IS NOT NULL, 'issue project/status index exists');
SELECT ok(to_regclass('public.issues_project_priority_idx') IS NOT NULL, 'issue project/priority index exists');
SELECT ok(to_regclass('public.issues_project_type_idx') IS NOT NULL, 'issue project/type index exists');
SELECT ok(to_regclass('public.activity_log_project_created_at_idx') IS NOT NULL, 'activity project/create index exists');
SELECT ok(to_regclass('public.activity_log_issue_id_idx') IS NOT NULL, 'activity issue index exists');
SELECT ok(to_regclass('public.github_commits_link_committed_at_idx') IS NOT NULL, 'commit link/commit index exists');
SELECT ok(to_regclass('public.github_issues_link_updated_at_idx') IS NOT NULL, 'GitHub issue link/update index exists');
SELECT ok((SELECT relrowsecurity FROM pg_catalog.pg_class WHERE oid = 'public.projects'::regclass), 'projects RLS enabled');
SELECT ok((SELECT relrowsecurity FROM pg_catalog.pg_class WHERE oid = 'public.issues'::regclass), 'issues RLS enabled');
SELECT ok((SELECT relrowsecurity FROM pg_catalog.pg_class WHERE oid = 'public.activity_log'::regclass), 'activity RLS enabled');
SELECT ok((SELECT relrowsecurity FROM pg_catalog.pg_class WHERE oid = 'public.github_links'::regclass), 'links RLS enabled');
SELECT ok((SELECT relrowsecurity FROM pg_catalog.pg_class WHERE oid = 'public.github_commits'::regclass), 'commits RLS enabled');
SELECT ok((SELECT relrowsecurity FROM pg_catalog.pg_class WHERE oid = 'public.github_issues'::regclass), 'GitHub issues RLS enabled');
SELECT ok(NOT (SELECT relforcerowsecurity FROM pg_catalog.pg_class WHERE oid = 'public.projects'::regclass), 'projects do not force RLS');
SELECT ok(NOT (SELECT relforcerowsecurity FROM pg_catalog.pg_class WHERE oid = 'public.issues'::regclass), 'issues do not force RLS');
SELECT ok(NOT (SELECT relforcerowsecurity FROM pg_catalog.pg_class WHERE oid = 'public.activity_log'::regclass), 'activity does not force RLS');
SELECT ok(NOT (SELECT relforcerowsecurity FROM pg_catalog.pg_class WHERE oid = 'public.github_links'::regclass), 'links do not force RLS');
SELECT ok(NOT (SELECT relforcerowsecurity FROM pg_catalog.pg_class WHERE oid = 'public.github_commits'::regclass), 'commits do not force RLS');
SELECT ok(NOT (SELECT relforcerowsecurity FROM pg_catalog.pg_class WHERE oid = 'public.github_issues'::regclass), 'GitHub issues do not force RLS');
SELECT ok(has_schema_privilege('authenticated', 'private', 'USAGE'), 'authenticated can evaluate the tags validator schema');
SELECT ok(has_function_privilege('authenticated', 'private.valid_project_tags(text[])', 'EXECUTE'), 'authenticated can execute only the tags validator');
SELECT ok(NOT has_function_privilege('authenticated', 'private.set_updated_at()', 'EXECUTE'), 'authenticated cannot execute updated-at trigger');
SELECT ok(NOT has_function_privilege('authenticated', 'private.prevent_issue_project_change()', 'EXECUTE'), 'authenticated cannot execute immutable-project trigger');
SELECT ok(NOT has_function_privilege('authenticated', 'private.log_project_activity()', 'EXECUTE'), 'authenticated cannot execute project activity trigger');
SELECT ok(NOT has_function_privilege('authenticated', 'private.log_issue_activity()', 'EXECUTE'), 'authenticated cannot execute issue activity trigger');

-- Required foreign keys and action allowlist are database constraints.
SELECT ok(EXISTS (
  SELECT 1 FROM pg_catalog.pg_constraint
  WHERE conrelid = 'public.projects'::regclass
    AND contype = 'f' AND confrelid = 'auth.users'::regclass
    AND confdeltype = 'c'
), 'projects owner cascade exists');
SELECT ok(EXISTS (
  SELECT 1 FROM pg_catalog.pg_constraint
  WHERE conrelid = 'public.issues'::regclass
    AND contype = 'f' AND confrelid = 'public.projects'::regclass
    AND confdeltype = 'c'
), 'issues project cascade exists');
SELECT ok(EXISTS (
  SELECT 1 FROM pg_catalog.pg_constraint
  WHERE conrelid = 'public.activity_log'::regclass
    AND contype = 'f' AND confrelid = 'public.issues'::regclass
    AND confdeltype = 'n'
), 'activity issue set-null exists');
-- Auth fixtures are local to this transaction.
INSERT INTO auth.users (id, email)
VALUES
  ('00000000-0000-0000-0000-000000000001', 'phase1-a@example.test'),
  ('00000000-0000-0000-0000-000000000002', 'phase1-b@example.test');

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000001","role":"authenticated"}', true);

INSERT INTO public.projects (id, owner_id, name, description, tags)
VALUES ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Alpha', NULL, ARRAY['Build', 'Review']);
SELECT is((SELECT count(*)::int FROM public.activity_log
           WHERE project_id = '10000000-0000-0000-0000-000000000001'), 1,
          'project creation is logged');
SELECT throws_ok(
  $$INSERT INTO public.activity_log (project_id, action, description)
    VALUES ('10000000-0000-0000-0000-000000000001', 'project.created', 'forged')$$,
  '42501', NULL::text, 'authenticated clients cannot forge activity rows'
);

SET LOCAL ROLE anon;
SELECT throws_ok(
  $$SELECT count(*) FROM public.projects$$,
  '42501', NULL::text, 'anon cannot read application tables'
);
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000001","role":"authenticated"}', true);

SELECT throws_ok(
  $$INSERT INTO public.projects (owner_id, name, description)
    VALUES ('00000000-0000-0000-0000-000000000001', '', NULL)$$,
  '23514', NULL::text, 'project name minimum is enforced'
);
SELECT throws_ok(
  $$INSERT INTO public.projects (owner_id, name, description)
    VALUES ('00000000-0000-0000-0000-000000000001', 'Valid', '')$$,
  '23514', NULL::text, 'empty project descriptions are rejected'
);
SELECT throws_ok(
  $$INSERT INTO public.projects (owner_id, name, tags)
    VALUES ('00000000-0000-0000-0000-000000000001', 'Valid', ARRAY['Build', 'build'])$$,
  '23514', NULL::text, 'project tags are case-insensitively unique'
);

UPDATE public.projects
SET name = 'Alpha renamed'
WHERE id = '10000000-0000-0000-0000-000000000001';
SELECT is((SELECT count(*)::int FROM public.activity_log
           WHERE project_id = '10000000-0000-0000-0000-000000000001'), 2,
          'meaningful project updates are logged');
UPDATE public.projects
SET updated_at = now()
WHERE id = '10000000-0000-0000-0000-000000000001';
SELECT is((SELECT count(*)::int FROM public.activity_log
           WHERE project_id = '10000000-0000-0000-0000-000000000001'), 2,
          'timestamp-only project updates are silent');

INSERT INTO public.projects (id, owner_id, name)
VALUES ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'Alpha sibling');
INSERT INTO public.issues (id, project_id, title, type)
VALUES ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'First issue', 'task');
SELECT is((SELECT count(*)::int FROM public.activity_log
           WHERE issue_id = '20000000-0000-0000-0000-000000000001'), 1,
          'issue creation is logged');
UPDATE public.issues SET status = 'in_progress'
WHERE id = '20000000-0000-0000-0000-000000000001';
SELECT is((SELECT count(*)::int FROM public.activity_log
           WHERE issue_id = '20000000-0000-0000-0000-000000000001'), 2,
          'meaningful issue updates are logged');
SELECT throws_ok(
  $$INSERT INTO public.issues (project_id, title, type)
    VALUES ('10000000-0000-0000-0000-000000000001', 'bad enum', 'not_an_enum')$$,
  '22P02', NULL::text, 'invalid issue enums are rejected'
);
SELECT throws_ok(
  $$UPDATE public.issues
    SET project_id = '10000000-0000-0000-0000-000000000002'
    WHERE id = '20000000-0000-0000-0000-000000000001'$$,
  '23000', NULL::text, 'issue project_id is immutable'
);
DELETE FROM public.issues WHERE id = '20000000-0000-0000-0000-000000000001';
SELECT is((SELECT count(*)::int FROM public.activity_log
           WHERE project_id = '10000000-0000-0000-0000-000000000001'
             AND action = 'issue.deleted' AND issue_id IS NULL), 1,
          'issue deletion preserves a project-level history row');

-- Create an issue owned by user A that user B must not read or mutate.
INSERT INTO public.issues (id, project_id, title, type)
VALUES ('20000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000002', 'Private sibling issue', 'task');

-- A second user cannot see or modify the first user's project graph.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000002', true);
SELECT set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000002","role":"authenticated"}', true);
SELECT is((SELECT count(*)::int FROM public.projects
           WHERE id = '10000000-0000-0000-0000-000000000001'), 0, 'second user cannot read project');
SELECT is((SELECT count(*)::int FROM public.activity_log
           WHERE project_id = '10000000-0000-0000-0000-000000000001'), 0, 'second user cannot read activity');
SELECT is((SELECT count(*)::int FROM public.issues
           WHERE id = '20000000-0000-0000-0000-000000000003'), 0, 'second user cannot read another user issue');
SELECT throws_ok(
  $$INSERT INTO public.issues (project_id, title, type)
    VALUES ('10000000-0000-0000-0000-000000000001', 'forbidden', 'bug')$$,
  '42501', NULL::text, 'second user cannot create an issue in another project'
);
UPDATE public.projects SET name = 'hijacked' WHERE id = '10000000-0000-0000-0000-000000000001';
DELETE FROM public.projects WHERE id = '10000000-0000-0000-0000-000000000001';
UPDATE public.issues SET title = 'hijacked' WHERE id = '20000000-0000-0000-0000-000000000003';
DELETE FROM public.issues WHERE id = '20000000-0000-0000-0000-000000000003';
SET LOCAL ROLE postgres;
SELECT is((SELECT name FROM public.projects
           WHERE id = '10000000-0000-0000-0000-000000000001'), 'Alpha renamed',
          'second user cannot update or delete another user project');
SELECT is((SELECT title FROM public.issues
           WHERE id = '20000000-0000-0000-0000-000000000003'), 'Private sibling issue',
          'second user cannot update or delete another user issue');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000002', true);
SELECT set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000002","role":"authenticated"}', true);
INSERT INTO public.projects (id, owner_id, name)
VALUES ('10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000002', 'Beta');
INSERT INTO public.issues (id, project_id, title, type)
VALUES ('20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000003', 'Beta issue', 'bug');

-- Link writes are narrowly scoped; sync timestamps and synchronized rows are
-- not client-writable.
SELECT throws_ok(
  $$INSERT INTO public.github_links (project_id, repo_full_name, last_synced_at)
    VALUES ('10000000-0000-0000-0000-000000000003', 'makko/beta', now())$$,
  '42501', NULL::text, 'client cannot forge a link sync timestamp'
);
SET LOCAL ROLE postgres;
SELECT set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000001","role":"authenticated"}', true);
SET LOCAL ROLE authenticated;
INSERT INTO public.github_links (project_id, repo_full_name)
VALUES ('10000000-0000-0000-0000-000000000001', 'makko/alpha');
SELECT throws_ok(
  $$INSERT INTO public.github_links (project_id, repo_full_name)
    VALUES ('10000000-0000-0000-0000-000000000001', 'makko/other')$$,
  '23505', NULL::text, 'a project has at most one GitHub link'
);
SELECT throws_ok(
  $$INSERT INTO public.activity_log (project_id, action, description)
    VALUES ('10000000-0000-0000-0000-000000000001', 'project.created', 'forged')$$,
  '42501', NULL::text, 'client cannot forge activity rows'
);
SELECT throws_ok(
  $$UPDATE public.github_links SET last_synced_at = now()
    WHERE project_id = '10000000-0000-0000-0000-000000000001'$$,
  '42501', NULL::text, 'client cannot update a link sync timestamp'
);

SET LOCAL ROLE postgres;
SELECT throws_ok(
  $$INSERT INTO public.activity_log (project_id, action, description)
    VALUES ('10000000-0000-0000-0000-000000000001', 'forged.action', 'invalid')$$,
  '23514', NULL::text, 'invalid activity actions are rejected as a constraint violation'
);
INSERT INTO public.activity_log (project_id, action, description)
VALUES ('10000000-0000-0000-0000-000000000001', 'project.created', repeat('x', 1000));
SELECT throws_ok(
  $$INSERT INTO public.activity_log (project_id, action, description)
    VALUES ('10000000-0000-0000-0000-000000000001', 'project.created', repeat('x', 1001))$$,
  '23514', NULL::text, 'activity descriptions over 1000 characters are rejected'
);
INSERT INTO public.github_commits
  (github_link_id, sha, message, committed_at, html_url)
SELECT id, repeat('a', 40), '', now(), 'https://github.com/makko/alpha/commit/' || repeat('a', 40)
FROM public.github_links WHERE project_id = '10000000-0000-0000-0000-000000000001';
SELECT throws_ok(
  $$INSERT INTO public.github_commits
    (github_link_id, sha, message, committed_at, html_url)
  SELECT id, repeat('b', 39), 'Invalid SHA', now(), 'https://github.com/makko/alpha/commit/invalid'
  FROM public.github_links WHERE project_id = '10000000-0000-0000-0000-000000000001'$$,
  '23514', NULL::text, 'commit SHA must be 40 to 64 hexadecimal characters'
);
INSERT INTO public.github_issues
  (github_link_id, github_node_id, number, title, state,
   labels, github_created_at, github_updated_at, html_url)
SELECT id, 'MDU6SXNzdWUx', 1, 'Alpha issue', 'open', ARRAY['bug'], now(), now(),
       'https://github.com/makko/alpha/issues/1'
FROM public.github_links WHERE project_id = '10000000-0000-0000-0000-000000000001';
SELECT throws_ok(
  $$INSERT INTO public.github_issues
    (github_link_id, github_node_id, number, title, state, labels,
     github_created_at, github_updated_at, html_url)
  SELECT id, 'MDU6SXNzdW51bGxhYmVs', 2, 'Null label', 'open', ARRAY['bug', NULL], now(), now(),
    'https://github.com/makko/alpha/issues/2'
  FROM public.github_links WHERE project_id = '10000000-0000-0000-0000-000000000001'$$,
  '23514', NULL::text, 'GitHub issue labels cannot contain NULL elements'
);
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000001","role":"authenticated"}', true);
SELECT is((SELECT count(*)::int FROM public.github_commits), 1, 'owner can read synchronized commits');
SELECT is((SELECT count(*)::int FROM public.github_issues), 1, 'owner can read synchronized issues');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000002', true);
SELECT set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000002","role":"authenticated"}', true);
SELECT is((SELECT count(*)::int FROM public.github_commits), 0, 'second user cannot read cached commits');
SELECT is((SELECT count(*)::int FROM public.github_issues), 0, 'second user cannot read cached GitHub issues');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', true);
SELECT set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000001","role":"authenticated"}', true);
SELECT throws_ok(
  $$INSERT INTO public.github_commits
    (github_link_id, sha, message, committed_at, html_url)
    VALUES ('00000000-0000-0000-0000-000000000000', repeat('f', 40), 'x', now(),
      'https://github.com/makko/alpha/commit/' || repeat('f', 40))$$,
  '42501', NULL::text, 'client cannot forge synchronized commits'
);

-- Link and project cascades remove synchronized and owned rows.
DELETE FROM public.github_links
WHERE project_id = '10000000-0000-0000-0000-000000000001';
SELECT is((SELECT count(*)::int FROM public.github_commits), 0, 'link deletion cascades commits');
SELECT is((SELECT count(*)::int FROM public.github_issues), 0, 'link deletion cascades GitHub issues');
DELETE FROM public.projects WHERE id = '10000000-0000-0000-0000-000000000001';
SELECT ok(NOT EXISTS (SELECT 1 FROM public.projects
                     WHERE id = '10000000-0000-0000-0000-000000000001'), 'project is deleted');
SELECT ok(NOT EXISTS (SELECT 1 FROM public.activity_log
                     WHERE project_id = '10000000-0000-0000-0000-000000000001'), 'project deletion cascades activity');
DELETE FROM public.projects WHERE id = '10000000-0000-0000-0000-000000000002';
SELECT ok(NOT EXISTS (SELECT 1 FROM public.projects
                     WHERE id = '10000000-0000-0000-0000-000000000002'), 'project deletion with an issue succeeds');
SELECT ok(NOT EXISTS (SELECT 1 FROM public.issues
                     WHERE id = '20000000-0000-0000-0000-000000000003'), 'project deletion cascades its issue');
SELECT ok(NOT EXISTS (SELECT 1 FROM public.activity_log
                     WHERE project_id = '10000000-0000-0000-0000-000000000002'), 'project deletion removes issue activity');
SET LOCAL ROLE postgres;
DELETE FROM auth.users WHERE id = '00000000-0000-0000-0000-000000000002';
SELECT ok(NOT EXISTS (SELECT 1 FROM public.projects
                     WHERE id = '10000000-0000-0000-0000-000000000003'), 'auth user deletion cascades projects');
SELECT ok(NOT EXISTS (SELECT 1 FROM public.issues
                     WHERE id = '20000000-0000-0000-0000-000000000002'), 'auth user deletion cascades issues');
SELECT ok(NOT EXISTS (SELECT 1 FROM public.activity_log
                     WHERE project_id = '10000000-0000-0000-0000-000000000003'), 'auth user deletion removes project activity');

SELECT * FROM finish();
ROLLBACK;
