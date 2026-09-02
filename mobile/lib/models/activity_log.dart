class ActivityLog {
  final String id;
  final String projectId;
  final String type;
  final String description;
  final DateTime createdAt;

  ActivityLog({
    required this.id,
    required this.projectId,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  factory ActivityLog.fromJson(Map<String, dynamic> json) => ActivityLog(
    id: json['id'],
    projectId: json['project_id'],
    type: json['action'] ?? json['type'] ?? '',
    description: json['description'],
    createdAt: DateTime.parse(json['created_at']),
  );
}
