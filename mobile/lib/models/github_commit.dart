class GithubCommit {
  final String id;
  final String sha;
  final String message;
  final String authorName;
  final String? authorLogin;
  final DateTime date;
  final String htmlUrl;

  GithubCommit({
    required this.id,
    required this.sha,
    required this.message,
    required this.authorName,
    this.authorLogin,
    required this.date,
    required this.htmlUrl,
  });

  factory GithubCommit.fromJson(Map<String, dynamic> json) => GithubCommit(
    id: json['id'] ?? '',
    sha: json['sha'] ?? '',
    message:
        json['message'] ??
        (json['commit'] is Map ? (json['commit']['message'] ?? '') : ''),
    authorName:
        json['author_name'] ??
        (json['commit'] is Map && json['commit']['author'] is Map
            ? (json['commit']['author']['name'] ?? '')
            : ''),
    authorLogin: json['author_login'],
    date:
        DateTime.tryParse(json['committed_at']?.toString() ?? '') ??
        DateTime.now(),
    htmlUrl: json['html_url'] ?? '',
  );
}
