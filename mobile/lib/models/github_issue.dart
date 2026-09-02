class GithubIssue {
  final String id;
  final int number;
  final String title;
  final String state;
  final String url;
  final List<String> labels;
  final String? authorLogin;

  GithubIssue({
    required this.id,
    required this.number,
    required this.title,
    required this.state,
    required this.url,
    this.labels = const [],
    this.authorLogin,
  });

  factory GithubIssue.fromJson(Map<String, dynamic> json) => GithubIssue(
    id: json['id']?.toString() ?? '',
    number: json['number'] is int
        ? json['number'] as int
        : int.tryParse('${json['number']}') ?? 0,
    title: json['title'] ?? '',
    state: json['state'] ?? 'open',
    url: json['html_url'] ?? '',
    labels: List<String>.from(json['labels'] ?? const []),
    authorLogin: json['author_login'],
  );
}
