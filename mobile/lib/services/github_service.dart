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
    final body = response.data;
    final data = body is Map ? body['data'] : null;
    if (data is! Map ||
        data['project_id'] is! String ||
        data['repo_full_name'] is! String ||
        data['commits_synced'] is! num ||
        data['issues_synced'] is! num ||
        data['last_synced_at'] is! String ||
        DateTime.tryParse(data['last_synced_at'] as String) == null) {
      throw const FormatException(
        'GitHub synchronization returned an invalid response.',
      );
    }
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
