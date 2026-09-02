class ValidationError extends FormatException {
  const ValidationError(super.message);
}

class Validation {
  static String requireId(String? value, String label) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) throw ValidationError('$label is required.');
    return normalized;
  }

  static String? validateName(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) return 'Name is required';
    if (normalized.length > 120) return 'Name must be 120 characters or fewer';
    return null;
  }

  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email))
      return 'Enter a valid email address';
    return null;
  }

  static String? validatePassword(String? value) {
    if ((value ?? '').isEmpty) return 'Password is required';
    if (value!.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? validateIssueTitle(String? value) {
    final title = value?.trim() ?? '';
    if (title.isEmpty) return 'Title is required';
    if (title.length > 200) return 'Title must be 200 characters or fewer';
    return null;
  }

  static String? validateRepository(String? value) {
    final repository = value?.trim() ?? '';
    if (repository.isEmpty) return 'Repository is required';
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9-]{0,38}/[A-Za-z0-9._-]{1,100}$')
        .hasMatch(repository))
      return 'Use owner/repository format';
    return null;
  }

  static ProjectInput normalizeProject({
    required String name,
    String? description,
    List<String>? tags,
  }) {
    final normalizedName = name.trim();
    if (validateName(normalizedName) case final message?)
      throw ValidationError(message);
    final normalizedDescription = description?.trim() ?? '';
    if (normalizedDescription.length > 5000)
      throw const ValidationError(
        'Description must be 5,000 characters or fewer.',
      );
    final normalizedTags = (tags ?? const <String>[])
        .map((tag) => tag.trim())
        .toList();
    if (normalizedTags.length > 20 || normalizedTags.any((tag) => tag.isEmpty))
      throw const ValidationError('Use up to 20 non-empty tags.');
    if (normalizedTags.any((tag) => tag.length > 40))
      throw const ValidationError('Tags must be 40 characters or fewer.');
    if (normalizedTags.map((tag) => tag.toLowerCase()).toSet().length !=
        normalizedTags.length)
      throw const ValidationError('Tags must be unique.');
    return ProjectInput(
      name: normalizedName,
      description: normalizedDescription.isEmpty ? null : normalizedDescription,
      tags: normalizedTags,
    );
  }

  static IssueInput normalizeIssue({
    required String title,
    String? description,
    required String type,
    required String priority,
    required String status,
  }) {
    final normalizedTitle = title.trim();
    if (validateIssueTitle(normalizedTitle) case final message?)
      throw ValidationError(message);
    final normalizedDescription = description?.trim() ?? '';
    if (normalizedDescription.length > 10000)
      throw const ValidationError(
        'Description must be 10,000 characters or fewer.',
      );
    if (!const ['task', 'bug'].contains(type))
      throw const ValidationError('Choose a valid issue type.');
    if (!const ['low', 'medium', 'high'].contains(priority))
      throw const ValidationError('Choose a valid issue priority.');
    if (!const ['todo', 'in_progress', 'done'].contains(status))
      throw const ValidationError('Choose a valid issue status.');
    return IssueInput(
      title: normalizedTitle,
      description: normalizedDescription.isEmpty ? null : normalizedDescription,
      type: type,
      priority: priority,
      status: status,
    );
  }

  static String normalizeRepository(String value) {
    final repository = value.trim();
    if (validateRepository(repository) case final message?)
      throw ValidationError(message);
    return repository;
  }
}

class ProjectInput {
  final String name;
  final String? description;
  final List<String> tags;
  const ProjectInput({
    required this.name,
    this.description,
    required this.tags,
  });
}

class IssueInput {
  final String title;
  final String? description;
  final String type;
  final String priority;
  final String status;
  const IssueInput({
    required this.title,
    this.description,
    required this.type,
    required this.priority,
    required this.status,
  });
}
