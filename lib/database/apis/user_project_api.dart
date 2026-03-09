import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:mymanager/database/tables/user_projects/models/user_project_model.dart';
import 'package:mymanager/services/api_client.dart';

class UserProjectsApi {
  static final ApiClient _client = ApiClient.instance;

  static Future<void> createProject(UserProjects project) async {
    final response = await _client.post('/projects', body: {
      'name': project.projectName ?? 'Untitled Project',
      'description': project.projectDescription,
      'parent_project_id':
          (project.parentProjectId == null || project.parentProjectId!.isEmpty)
              ? null
              : int.tryParse(project.parentProjectId!)
    });

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to create project: ${response.body}');
    }
  }

  static Future<List<UserProjects>> getProjects({bool includeDeleted = false}) async {
    try {
      final response = await _client.get('/projects');
      if (response.statusCode < 200 || response.statusCode >= 300) return [];

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (body['data'] as List<dynamic>? ?? const []);
      return list
          .cast<Map<String, dynamic>>()
          .map(_mapProject)
          .where((p) => includeDeleted || (p.projectStatus ?? '').toLowerCase() != 'deleted')
          .toList();
    } catch (e, stack) {
      if (kDebugMode) {
        developer.log('Error in getProjects: $e', stackTrace: stack, name: 'UserProjectsApi');
      }
      return [];
    }
  }

  static Future<UserProjects?> getProjectById(String projectId) async {
    final response = await _client.get('/projects/$projectId');
    if (response.statusCode < 200 || response.statusCode >= 300) return null;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null) return null;
    return _mapProject(data);
  }

  static Future<int> updateProjectById(String projectId, UserProjects updated) async {
    final response = await _client.put('/projects/$projectId', body: {
      'name': updated.projectName,
      'description': updated.projectDescription
    });
    return response.statusCode >= 200 && response.statusCode < 300 ? 1 : 0;
  }

  static Future<int> deleteProjectById(String projectId) async {
    final response = await _client.delete('/projects/$projectId');
    return response.statusCode >= 200 && response.statusCode < 300 ? 1 : 0;
  }

  static Future<int> updateProjectStatus(String projectId, String status) async {
    final response = await _client.put('/projects/$projectId', body: {});
    return response.statusCode >= 200 && response.statusCode < 300 ? 1 : 0;
  }

  static UserProjects _mapProject(Map<String, dynamic> raw) {
    return UserProjects.fromMap({
      'project_id': raw['id'].toString(),
      'parent_project_id': raw['parent_project_id']?.toString(),
      'project_name': raw['name'],
      'project_status': 'Active',
      'project_description': raw['description'],
      'project_type': null,
      'project_color': null,
      'project_created_at': raw['created_at'],
      'project_updated_at': raw['updated_at']
    });
  }
}
