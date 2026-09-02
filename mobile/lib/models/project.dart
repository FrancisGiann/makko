class Project {
  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  Project({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'],
    ownerId: json['owner_id'],
    name: json['name'],
    description: json['description'],
    tags: List<String>.from(json['tags'] ?? []),
    createdAt: DateTime.parse(json['created_at']),
    updatedAt: DateTime.parse(json['updated_at']),
  );
}
