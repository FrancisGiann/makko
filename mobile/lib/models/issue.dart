class Issue {
  final String id;
  final String projectId;
  final String title;
  final String? description;
  final String type;
  final String priority;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Issue({
    required this.id,
    required this.projectId,
    required this.title,
    this.description,
    required this.type,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Issue.fromJson(Map<String, dynamic> json) => Issue(
    id: json['id'],
    projectId: json['project_id'],
    title: json['title'],
    description: json['description'],
    type: json['type'],
    priority: json['priority'],
    status: json['status'],
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );
}
