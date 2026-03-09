import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:mymanager/database/apis/task_status_api.dart';
import 'package:mymanager/database/apis/user_project_api.dart';
import 'package:mymanager/database/tables/tasks/models/task_model.dart';
import 'package:mymanager/database/tables/user_projects/models/user_project_model.dart';
import 'package:mymanager/services/api_client.dart';

class TaskApi {
  static final ApiClient _client = ApiClient.instance;

  static Future<void> createTask(Task task) async {
    await TaskStatusApi.getTaskStatuses();

    final projectId = task.projectId;
    if (projectId == null || projectId.isEmpty) {
      throw Exception('Task requires projectId');
    }

    final columnId = await _resolveColumnId(projectId);

    final response = await _client.post('/tasks', body: {
      'title': task.taskTitle,
      'description': task.taskDescription,
      'priority': _toBackendPriority(task.taskPriority),
      'status': TaskStatusApi.toCode(task.taskStatus),
      'project_id': int.tryParse(projectId),
      'column_id': columnId,
      'due_date': task.taskDueDate,
      'order_index': task.taskOrder
    });

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to create task: ${response.body}');
    }
  }

  static Future<List<Task>> getTasks({
    String? projectId,
    String? status,
    String? priority,
    bool includeCompleted = true,
    bool onlyParentTasks = false,
  }) async {
    try {
      await TaskStatusApi.getTaskStatuses();

      final projectIds = <String>[];
      if (projectId != null && projectId.isNotEmpty) {
        final projects = await UserProjectsApi.getProjects();
        projectIds.addAll(_collectProjectTreeIds(projects, projectId));
      } else {
        final projects = await UserProjectsApi.getProjects();
        projectIds.addAll(projects.map((p) => p.projectId));
      }

      final all = <Task>[];
      for (final pid in projectIds) {
        final query = <String, String>{
          'project_id': pid,
          'limit': '100',
          'page': '1'
        };
        if (status != null) query['status'] = TaskStatusApi.toCode(status);
        if (priority != null) query['priority'] = _toBackendPriority(priority);

        final uriQuery = query.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&');
        final response = await _client.get('/tasks?$uriQuery');
        if (response.statusCode < 200 || response.statusCode >= 300) continue;

        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final rows = (body['data'] as List<dynamic>? ?? const []);
        all.addAll(rows.cast<Map<String, dynamic>>().map(_mapTask));
      }

      var filtered = all;
      if (!includeCompleted) {
        filtered = filtered.where((t) => !TaskStatusApi.isCompletedStatus(t.taskStatus)).toList();
      }
      if (onlyParentTasks) {
        filtered = filtered.where((t) => (t.parentTaskId ?? '').isEmpty).toList();
      }

      filtered.sort((a, b) {
        final aOrder = a.taskOrder;
        final bOrder = b.taskOrder;
        if (aOrder != bOrder) return aOrder.compareTo(bOrder);
        return (b.taskCreatedAt ?? '').compareTo(a.taskCreatedAt ?? '');
      });

      return filtered;
    } catch (e, stack) {
      if (kDebugMode) {
        developer.log('Error getting tasks: $e', stackTrace: stack, name: 'TaskApi');
      }
      return [];
    }
  }

  static List<String> _collectProjectTreeIds(List<UserProjects> projects, String rootProjectId) {
    final included = <String>{rootProjectId};
    var added = true;

    while (added) {
      added = false;
      for (final project in projects) {
        final parentId = project.parentProjectId;
        if ((parentId ?? '').isEmpty) continue;
        if (!included.contains(parentId)) continue;
        if (included.add(project.projectId)) {
          added = true;
        }
      }
    }

    return included.toList();
  }

  static Future<List<Task>> getSubTasks(String parentTaskId, {String? projectId}) async {
    final all = await getTasks(
      projectId: projectId,
      includeCompleted: true,
      onlyParentTasks: false,
    );
    return all.where((t) => t.parentTaskId == parentTaskId).toList();
  }

  static Future<List<Task>> getTasksByQuadrant({required bool urgent, required bool important}) async {
    final tasks = await getTasks(includeCompleted: true);
    return tasks.where((t) {
      final u = (t.taskUrgency ?? '').toLowerCase() == 'high';
      final i = (t.taskImportance ?? '').toLowerCase() == 'high';
      return u == urgent && i == important;
    }).toList();
  }

  static Future<Task?> getTaskById(String taskId) async {
    final tasks = await getTasks(includeCompleted: true);
    final matches = tasks.where((t) => t.taskId == taskId);
    return matches.isEmpty ? null : matches.first;
  }

  static Future<int> updateTask(String taskId, Task updated) async {
    await TaskStatusApi.getTaskStatuses();

    final body = <String, dynamic>{
      'title': updated.taskTitle,
      'description': updated.taskDescription,
      'priority': _toBackendPriority(updated.taskPriority),
      'status': TaskStatusApi.toCode(updated.taskStatus),
      'due_date': updated.taskDueDate,
      'order_index': updated.taskOrder
    }..removeWhere((_, value) => value == null);

    final response = await _client.put('/tasks/$taskId', body: body);
    return response.statusCode >= 200 && response.statusCode < 300 ? 1 : 0;
  }

  static Future<int> completeTask(String taskId) async {
    final response = await _client.put('/tasks/$taskId', body: {
      'status': 'done'
    });
    return response.statusCode >= 200 && response.statusCode < 300 ? 1 : 0;
  }

  static Future<int> deleteTask(String taskId) async {
    final response = await _client.delete('/tasks/$taskId');
    return response.statusCode >= 200 && response.statusCode < 300 ? 1 : 0;
  }

  static Future<int> permanentlyDeleteTask(String taskId) => deleteTask(taskId);

  static Future<List<Task>> getDeletedTasks() async {
    return const [];
  }

  static Future<int> restoreTask(String taskId) async {
    return 0;
  }

  static Future<List<Task>> getTodayTasks() async {
    final tasks = await getTasks(includeCompleted: false);
    final now = DateTime.now();
    return tasks.where((t) {
      if (t.taskDueDate == null) return false;
      final due = DateTime.tryParse(t.taskDueDate!);
      if (due == null) return false;
      return due.year == now.year && due.month == now.month && due.day == now.day;
    }).toList();
  }

  static Future<List<Task>> getOverdueTasks() async {
    final tasks = await getTasks(includeCompleted: false);
    final now = DateTime.now();
    return tasks.where((t) {
      if (t.taskDueDate == null) return false;
      final due = DateTime.tryParse(t.taskDueDate!);
      if (due == null) return false;
      return due.isBefore(now);
    }).toList();
  }

  static Future<int> updateTimeSpent(String taskId, int minutesToAdd) async {
    final task = await getTaskById(taskId);
    if (task == null) return 0;
    final updated = task.copyWith(timeSpent: task.timeSpent + minutesToAdd);
    return updateTask(taskId, updated);
  }

  static Future<int> moveTask({required String taskId, required String columnId, required String status, int orderIndex = 0}) async {
    await TaskStatusApi.getTaskStatuses();

    final response = await _client.patch('/tasks/$taskId/move', body: {
      'column_id': int.tryParse(columnId),
      'status': TaskStatusApi.toCode(status),
      'order_index': orderIndex
    });
    return response.statusCode >= 200 && response.statusCode < 300 ? 1 : 0;
  }

  static Future<int?> _resolveColumnId(String projectId) async {
    final response = await _client.get('/projects/$projectId/boards');
    if (response.statusCode < 200 || response.statusCode >= 300) return null;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final boards = (body['data'] as List<dynamic>? ?? const []);
    if (boards.isEmpty) return null;

    final firstBoard = boards.first as Map<String, dynamic>;
    final columns = (firstBoard['Columns'] as List<dynamic>? ?? const []);
    if (columns.isEmpty) return null;

    for (final col in columns.cast<Map<String, dynamic>>()) {
      final name = (col['name']?.toString() ?? '').toLowerCase();
      if (name.contains('to do') || name == 'todo') {
        return col['id'] as int?;
      }
    }

    return columns.first['id'] as int?;
  }

  static Task _mapTask(Map<String, dynamic> raw) {
    return Task.fromMap({
      'task_id': raw['id'].toString(),
      'project_id': raw['project_id']?.toString(),
      'task_title': raw['title'] ?? '',
      'task_description': raw['description'],
      'task_priority': _fromBackendPriority(raw['priority']?.toString()),
      'task_urgency': _fromBackendPriority(raw['priority']?.toString()) == 'High' ? 'High' : 'Low',
      'task_importance': _fromBackendPriority(raw['priority']?.toString()) == 'High' ? 'High' : 'Low',
      'task_status': TaskStatusApi.toDisplay(raw['status']?.toString()),
      'task_frequency': null,
      'task_frequency_value': null,
      'enable_alerts': 0,
      'alert_time': null,
      'task_start_date': null,
      'task_due_date': raw['due_date'],
      'task_completed_date': TaskStatusApi.isCompletedStatus(raw['status']?.toString()) ? raw['updated_at'] : null,
      'time_estimate': null,
      'time_spent': 0,
      'task_color': null,
      'task_order': raw['order_index'] ?? 0,
      'is_recurring': 0,
      'parent_task_id': null,
      'energy_level': null,
      'focus_required': 0,
      'task_created_at': raw['created_at'],
      'task_updated_at': raw['updated_at']
    });
  }

  static String _toBackendPriority(String? priority) {
    final input = (priority ?? '').toLowerCase();
    if (input.contains('high') || input.contains('urgent')) return 'high';
    if (input.contains('low')) return 'low';
    return 'medium';
  }

  static String _fromBackendPriority(String? priority) {
    switch ((priority ?? '').toLowerCase()) {
      case 'high':
        return 'High';
      case 'low':
        return 'Low';
      default:
        return 'Medium';
    }
  }
}
