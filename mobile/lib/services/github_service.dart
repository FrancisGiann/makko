import '../core/supabase/supabase_client.dart';
import '../models/github_link.dart';
import '../models/github_commit.dart';
import '../models/github_issue.dart';
import 'validation.dart';

class GithubProjectData {
  final GithubLink? link;
  final List<GithubCommit> commits;
  final List<GithubIssue> issues;

  GithubProjectData({
    required this.link,
    required this.commits,
    required this.issues,
  });
}

class GithubSyncResponse {
  final String projectId;
  final String repoFullName;
  final int commitsSynced;
  final int issuesSynced;
  final DateTime lastSyncedAt;

  const GithubSyncResponse({
    required this.projectId,
    required this.repoFullName,
    required this.commitsSynced,
    required this.issuesSynced,
    required this.lastSyncedAt,
  });
}

GithubSyncResponse parseGithubSyncResponse(
  dynamic body, {
  required String projectId,
}) {
  const invalid = FormatException(
    'GitHub synchronization returned an invalid response.',
  );
  final data = body is Map ? body['data'] : null;
  if (data is! Map || data['project_id'] != projectId) throw invalid;
  final rawRepository = data['repo_full_name'];
  if (rawRepository is! String) throw invalid;
  String repository;
  try {
    repository = Validation.normalizeRepository(rawRepository);
  } catch (_) {
    throw invalid;
  }
  if (repository != rawRepository) throw invalid;
  final commits = data['commits_synced'];
  final issues = data['issues_synced'];
  if (commits is! int || commits < 0 || commits > 30) throw invalid;
  if (issues is! int || issues < 0 || issues > 500) throw invalid;
  final timestamp = data['last_synced_at'];
  if (timestamp is! String) throw invalid;
  final lastSyncedAt = DateTime.tryParse(timestamp);
  if (lastSyncedAt == null) throw invalid;
  return GithubSyncResponse(
    projectId: projectId,
    repoFullName: repository,
    commitsSynced: commits,
    issuesSynced: issues,
    lastSyncedAt: lastSyncedAt,
  );
}

class GithubService {
  Future<GithubProjectData> getProjectData(String projectId) async {
    final project = Validation.requireId(projectId, 'Project');
    final linkResponse = await supabase
        .from('github_links')
        .select('id,project_id,repo_full_name,last_synced_at,created_at')
        .eq('project_id', project)
        .maybeSingle();

    if (linkResponse == null) {
      return GithubProjectData(link: null, commits: [], issues: []);
    }

    final link = GithubLink.fromJson(linkResponse);

    final commitsResponse = await supabase
        .from('github_commits')
        .select(
          'id,github_link_id,sha,message,author_name,author_login,committed_at,html_url,synced_at',
        )
        .eq('github_link_id', link.id)
        .order('committed_at', ascending: false)
        .limit(10);

    final issuesResponse = await supabase
        .from('github_issues')
        .select(
          'id,github_link_id,github_node_id,number,title,state,author_login,labels,github_created_at,github_updated_at,html_url,synced_at',
        )
        .eq('github_link_id', link.id)
        .eq('state', 'open')
        .order('github_updated_at', ascending: false)
        .limit(10);

    return GithubProjectData(
      link: link,
      commits: (commitsResponse as List)
          .map((c) => GithubCommit.fromJson(c))
          .toList(),
      issues: (issuesResponse as List)
          .map((i) => GithubIssue.fromJson(i))
          .toList(),
    );
  }

  Future<void> connect(String projectId, String owner, String repo) async {
    final project = Validation.requireId(projectId, 'Project');
    final normalized = Validation.normalizeRepository('$owner/$repo');
    await supabase.from('github_links').insert({
      'project_id': project,
      'repo_full_name': normalized,
    });
  }

  Future<void> syncGithub(String projectId) async {
    final project = Validation.requireId(projectId, 'Project');
    final response = await supabase.functions.invoke(
      'github-sync',
      body: {'project_id': project},
    );
    if (response.status < 200 || response.status >= 300) {
      throw const FormatException(
        'GitHub synchronization failed. Try again in a moment.',
      );
    }
    parseGithubSyncResponse(response.data, projectId: project);
  }

  Future<void> disconnect(String projectId, String linkId) async {
    final project = Validation.requireId(projectId, 'Project');
    final link = Validation.requireId(linkId, 'GitHub link');
    await supabase
        .from('github_links')
        .delete()
        .eq('id', link)
        .eq('project_id', project);
  }
}
