class GithubLink {
  final String id;
  final String projectId;
  final String repoFullName; // from repo_full_name
  final DateTime? lastSyncedAt;
  final DateTime createdAt;

  GithubLink({
    required this.id,
    required this.projectId,
    required this.repoFullName,
    this.lastSyncedAt,
    required this.createdAt,
  });

  factory GithubLink.fromJson(Map<String, dynamic> json) => GithubLink(
    id: json['id'],
    projectId: json['project_id'],
    repoFullName:
        json['repo_full_name'] ??
        "${json['owner']}/${json['repo']}", // fallback if schema mismatch
    lastSyncedAt: json['last_synced_at'] != null
        ? DateTime.parse(json['last_synced_at'])
        : null,
    createdAt: DateTime.parse(json['created_at']),
  );
}
