import 'dart:math';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mymanager/constants/app_constants.dart';
import 'package:mymanager/core/models/sub_task.dart';
import 'package:mymanager/core/models/task_model.dart';


class TaskStorageService extends GetxService {
  late final GetStorage _box;
  final RxList<Task> tasks = <Task>[].obs;

  /// call this in main() or via Binding before using the service
  Future<TaskStorageService> init() async {
    await GetStorage.init(); // idempotent
    _box = GetStorage();
    _loadFromStorage();
    return this;
  }

  // small deterministic id generator (milliseconds + random)
  String _makeId() => '${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(9999)}';

  void _loadFromStorage() {
    final raw = _box.read<List<dynamic>>(AppConstants.storageTasksKey);
    if (raw == null) {
      tasks.assignAll([]);
      return;
    }
    final list = raw.map((e) => Task.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    tasks.assignAll(list);
  }

  Future<void> _saveToStorage() async {
    final jsonList = tasks.map((t) => t.toJson()).toList();
    await _box.write(AppConstants.storageTasksKey, jsonList);
  }

  // ---------- CRUD ----------

  /// Create a new task. Returns the created task (with id).
  Future<Task> createTask(Task task) async {
    // ensure id
    if (task.id.isEmpty) task.id = _makeId();
    tasks.insert(0, task); // insert at front by default (newest first)
    await _saveToStorage();
    return task;
  }

  /// Convenience to create from fields (fills id)
  Future<Task> createTaskFrom({
    required String taskName,
    String? taskDate,
    String? taskTime,
    List<String>? taskAlerts,
    String? taskSlot,
    List<SubTask>? subTasks,
    String? taskDuration,
    String? taskEndTime,
    String? taskStartDate,
    String? taskFrequency,
    bool isTaskAlert = false,
    String? taskStatus,
    String? taskDescription,
    String? taskCategory,
    String? taskPriority,
  }) async {
    final t = Task(
      id: _makeId(),
      taskName: taskName,
      taskDate: taskDate,
      taskTime: taskTime,
      taskAlerts: taskAlerts,
      taskSlot: taskSlot,
      subTasks: subTasks,
      taskDuration: taskDuration,
      taskEndTime: taskEndTime,
      taskStartDate: taskStartDate,
      taskFrequency: taskFrequency,
      isTaskAlert: isTaskAlert,
      taskStatus: taskStatus,
      taskDescription: taskDescription,
      taskCategory: taskCategory,
      taskPriority: taskPriority,
    );
    return createTask(t);
  }

  /// Read all tasks (reactive list available at [tasks])
  List<Task> readAll() => tasks;

  /// Get by id
  Task? getById(String id) => tasks.firstWhereOrNull((t) => t.id == id);

  /// Update a task (by id)
  Future<Task?> updateTask(String id, Task updated) async {
    final idx = tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return null;
    tasks[idx] = updated;
    await _saveToStorage();
    return updated;
  }

  /// Partial update using a map of fields
  Future<Task?> patchTask(String id, Map<String, dynamic> changes) async {
    final idx = tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return null;
    final old = tasks[idx];
    // simplistic: convert toJson, merge, then fromJson
    final merged = {...old.toJson(), ...changes};
    final newTask = Task.fromJson(merged);
    tasks[idx] = newTask;
    await _saveToStorage();
    return newTask;
  }

  /// Delete by id
  Future<bool> deleteTask(String id) async {
    final idx = tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return false;
    tasks.removeAt(idx);
    await _saveToStorage();
    return true;
  }

  /// Clear all tasks
  Future<void> clearAll() async {
    tasks.clear();
    await _box.remove(AppConstants.storageTasksKey);
  }

  // ---------- helpers / queries ----------

  /// return tasks for an ISO date string (or simple date match)
  List<Task> tasksForDate(String dateStr) =>
      tasks.where((t) => t.taskDate != null && t.taskDate == dateStr).toList();

  /// return tasks matching a predicate
  List<Task> where(bool Function(Task) test) => tasks.where(test).toList();

  /// toggle task status (completed/pending)
  Future<Task?> toggleStatus(String id, {String? completedStatus, String? pendingStatus}) async {
    final idx = tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return null;
    final cur = tasks[idx];
    final newStatus = (cur.taskStatus == completedStatus) ? pendingStatus : completedStatus;
    final updated = cur.copyWith(taskStatus: newStatus);
    tasks[idx] = updated;
    await _saveToStorage();
    return updated;
  }
}
