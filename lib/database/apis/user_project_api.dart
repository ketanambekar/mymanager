import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:mymanager/constants/app_constants.dart';
import 'package:mymanager/database/helper/database_helper.dart';
import 'package:mymanager/database/tables/user_projects/models/user_project_model.dart';
import 'package:mymanager/utils/global_utils.dart';

class UserProjectsApi {
  static String _generateId() => uuid.v4();

  static String _nowIso() => DateTime.now().toLocal().toIso8601String();

  /// Create a new project
  static Future<void> createProject(UserProjects project) async {
    try {
      final db = await DatabaseHelper.database;
      final id = project.projectId.isNotEmpty
          ? project.projectId
          : _generateId();
      final now = _nowIso();
      final map = <String, dynamic>{
        'project_id': id,
        'project_name': project.projectName,
        'project_status': project.projectStatus ?? AppConstants.projectStatusActive,
        'project_description': project.projectDescription,
        'project_type': project.projectType,
        'project_color': project.projectColor,
        'project_created_at': now,
        'project_updated_at': now,
      };

      await db.insert('user_projects_table', map);
      if (kDebugMode) {
        developer.log('Inserted project $id', name: 'UserProjectsApi');
      }
    } catch (e, stack) {
      developer.log(
        'Error in createProject: $e',
        stackTrace: stack,
        name: 'UserProjectsApi',
      );
      rethrow;
    }
  }

  /// Get all projects. Exclude Deleted by default.
  static Future<List<UserProjects>> getProjects({
    bool includeDeleted = false,
  }) async {
    try {
      final db = await DatabaseHelper.database;
      final whereClause = includeDeleted ? null : "project_status != '${AppConstants.projectStatusDeleted}'";
      final maps = await db.query(
        'user_projects_table',
        where: whereClause,
        orderBy: 'project_created_at DESC',
      );
      return maps.map((m) => UserProjects.fromMap(m)).toList();
    } catch (e, stack) {
      developer.log(
        'Error in getProjects: $e',
        stackTrace: stack,
        name: 'UserProjectsApi',
      );
      return [];
    }
  }

  /// Get project by ID
  static Future<UserProjects?> getProjectById(String projectId) async {
    try {
      final db = await DatabaseHelper.database;
      final maps = await db.query(
        'user_projects_table',
        where: 'project_id = ?',
        whereArgs: [projectId],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return UserProjects.fromMap(maps.first);
    } catch (e, stack) {
      developer.log(
        'Error in getProjectById: $e',
        stackTrace: stack,
        name: 'UserProjectsApi',
      );
      rethrow;
    }
  }

  /// Update project by ID (partial updates supported)
  static Future<int> updateProjectById(
    String projectId,
    UserProjects updated,
  ) async {
    try {
      final db = await DatabaseHelper.database;
      final now = _nowIso();

      final map = <String, dynamic>{
        'project_name': updated.projectName,
        'project_status': updated.projectStatus,
        'project_description': updated.projectDescription,
        'project_type': updated.projectType,
        'project_color': updated.projectColor,
        'project_updated_at': now,
      }..removeWhere((key, value) => value == null);

      final count = await db.update(
        'user_projects_table',
        map,
        where: 'project_id = ?',
        whereArgs: [projectId],
      );
      if (kDebugMode) {
        developer.log(
          'Updated project $projectId, rows=$count',
          name: 'UserProjectsApi',
        );
      }
      return count;
    } catch (e, stack) {
      developer.log(
        'Error in updateProjectById: $e',
        stackTrace: stack,
        name: 'UserProjectsApi',
      );
      return 0;
    }
  }

  /// Soft delete: sets project_status = 'Deleted'
  static Future<int> deleteProjectById(String projectId) async {
    try {
      final db = await DatabaseHelper.database;
      final now = _nowIso();

      final count = await db.update(
        'user_projects_table',
        {'project_status': AppConstants.projectStatusDeleted, 'project_updated_at': now},
        where: 'project_id = ?',
        whereArgs: [projectId],
      );
      if (kDebugMode) {
        developer.log(
          'Soft-deleted project $projectId, rows=$count',
          name: 'UserProjectsApi',
        );
      }
      return count;
    } catch (e, stack) {
      developer.log(
        'Error in deleteProjectById: $e',
        stackTrace: stack,
        name: 'UserProjectsApi',
      );
      return 0;
    }
  }

  /// Update only project status
  static Future<int> updateProjectStatus(
    String projectId,
    String status,
  ) async {
    try {
      final db = await DatabaseHelper.database;
      final now = _nowIso();

      final count = await db.update(
        'user_projects_table',
        {'project_status': status, 'project_updated_at': now},
        where: 'project_id = ?',
        whereArgs: [projectId],
      );
      if (kDebugMode) {
        developer.log(
          'Updated project status $projectId -> $status, rows=$count',
          name: 'UserProjectsApi',
        );
      }
      return count;
    } catch (e, stack) {
      developer.log(
        'Error in updateProjectStatus: $e',
        stackTrace: stack,
        name: 'UserProjectsApi',
      );
      return 0;
    }
  }
}
