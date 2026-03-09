import 'dart:convert';

import 'package:mymanager/database/models/task_status_option.dart';
import 'package:mymanager/services/api_client.dart';

class TaskStatusApi {
  static final ApiClient _client = ApiClient.instance;

  static List<TaskStatusOption> _cache = const [];

  static const List<TaskStatusOption> _fallback = [
    TaskStatusOption(id: 'todo', code: 'todo', name: 'Todo', color: '#6366F1', sortOrder: 1, isSystem: true),
    TaskStatusOption(id: 'on_progress', code: 'on_progress', name: 'In Progress', color: '#F59E0B', sortOrder: 2, isSystem: true),
    TaskStatusOption(id: 'done', code: 'done', name: 'Completed', color: '#22C55E', sortOrder: 3, isSystem: true),
  ];

  static List<TaskStatusOption> get cached => _cache.isNotEmpty ? _cache : _fallback;

  static Future<List<TaskStatusOption>> getTaskStatuses({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache.isNotEmpty) return _cache;

    final response = await _client.get('/task-statuses');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return cached;
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final rows = (body['data'] as List<dynamic>? ?? const []);
    _cache = rows.cast<Map<String, dynamic>>().map(TaskStatusOption.fromMap).toList();
    if (_cache.isEmpty) {
      _cache = _fallback;
    }
    return _cache;
  }

  static String toCode(String statusValue) {
    final input = statusValue.trim();
    if (input.isEmpty) return 'todo';

    for (final s in cached) {
      if (s.code.toLowerCase() == input.toLowerCase() || s.name.toLowerCase() == input.toLowerCase()) {
        return s.code;
      }
    }

    if (RegExp(r'^[a-z0-9_]+$').hasMatch(input.toLowerCase())) {
      return input.toLowerCase();
    }

    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s_-]'), '')
        .replaceAll(RegExp(r'[\s-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  static String toDisplay(String? codeOrName) {
    final input = (codeOrName ?? '').trim();
    if (input.isEmpty) return 'Todo';

    for (final s in cached) {
      if (s.code.toLowerCase() == input.toLowerCase() || s.name.toLowerCase() == input.toLowerCase()) {
        return s.name;
      }
    }

    final normalized = input.replaceAll('_', ' ').replaceAll('-', ' ');
    return normalized
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join(' ');
  }

  static bool isCompletedStatus(String? codeOrName) {
    final code = toCode(codeOrName ?? '');
    return code == 'done';
  }

  static String completedStatusName() {
    final status = cached.where((s) => s.code == 'done').toList();
    return status.isEmpty ? 'Completed' : status.first.name;
  }

  static Future<TaskStatusOption> createTaskStatus({required String name, String? code, String? color}) async {
    final response = await _client.post('/task-statuses', body: {
      'name': name,
      if ((code ?? '').trim().isNotEmpty) 'code': code,
      if ((color ?? '').trim().isNotEmpty) 'color': color,
    });

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to create status: ${response.body}');
    }

    await getTaskStatuses(forceRefresh: true);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return TaskStatusOption.fromMap(body['data'] as Map<String, dynamic>);
  }

  static Future<TaskStatusOption> updateTaskStatus({required String id, String? name, String? code, String? color}) async {
    final response = await _client.put('/task-statuses/$id', body: {
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (color != null) 'color': color,
    });

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to update status: ${response.body}');
    }

    await getTaskStatuses(forceRefresh: true);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return TaskStatusOption.fromMap(body['data'] as Map<String, dynamic>);
  }

  static Future<void> deleteTaskStatus(String id) async {
    final response = await _client.delete('/task-statuses/$id');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to delete status: ${response.body}');
    }

    await getTaskStatuses(forceRefresh: true);
  }
}
