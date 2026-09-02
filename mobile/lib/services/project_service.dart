import '../core/supabase/supabase_client.dart';
import '../models/project.dart';
import 'validation.dart';

class ProjectService {
  static const _projectColumns =
      'id,owner_id,name,description,tags,created_at,updated_at';

  Future<List<Project>> listProjects(String ownerId) async {
    final owner = Validation.requireId(ownerId, 'Owner');
    final response = await supabase
        .from('projects')
        .select(_projectColumns)
        .eq('owner_id', owner)
        .order('updated_at', ascending: false);
    return (response as List).map((json) => Project.fromJson(json)).toList();
  }

  Future<Project?> getProject(String ownerId, String projectId) async {
    final owner = Validation.requireId(ownerId, 'Owner');
    final project = Validation.requireId(projectId, 'Project');
    final response = await supabase
        .from('projects')
        .select(_projectColumns)
        .eq('id', project)
        .eq('owner_id', owner)
        .maybeSingle();

    if (response == null) return null;
    return Project.fromJson(response);
  }

  Future<Project> createProject(
    String ownerId, {
    required String name,
    String? description,
    List<String>? tags,
  }) async {
    final owner = Validation.requireId(ownerId, 'Owner');
    final normalized = Validation.normalizeProject(
      name: name,
      description: description,
      tags: tags,
    );
    final response = await supabase
        .from('projects')
        .insert({
          'owner_id': owner,
          'name': normalized.name,
          'description': normalized.description,
          'tags': normalized.tags,
        })
        .select(_projectColumns)
        .single();

    return Project.fromJson(response);
  }

  Future<Project> updateProject(
    String ownerId,
    String projectId, {
    required String name,
    String? description,
    List<String>? tags,
  }) async {
    final owner = Validation.requireId(ownerId, 'Owner');
    final project = Validation.requireId(projectId, 'Project');
    final normalized = Validation.normalizeProject(
      name: name,
      description: description,
      tags: tags,
    );
    final response = await supabase
        .from('projects')
        .update({
          'name': normalized.name,
          'description': normalized.description,
          'tags': normalized.tags,
        })
        .eq('id', project)
        .eq('owner_id', owner)
        .select(_projectColumns)
        .single();

    return Project.fromJson(response);
  }

  Future<void> deleteProject(String ownerId, String projectId) async {
    final owner = Validation.requireId(ownerId, 'Owner');
    final project = Validation.requireId(projectId, 'Project');
    await supabase
        .from('projects')
        .delete()
        .eq('id', project)
        .eq('owner_id', owner);
  }
}
