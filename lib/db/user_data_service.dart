import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mymanager/constants/app_constants.dart';
import 'package:mymanager/db/models/user_profile_model.dart';
import 'package:mymanager/db/models/user_project_model.dart';
import 'package:mymanager/db/models/user_tasks_model.dart';
import 'package:mymanager/db/models/user_sub_tasks_model.dart';
import 'package:mymanager/db/models/user_data_model.dart';
import 'package:mymanager/utils/global_utils.dart';

class UserDataService extends GetxService {
  final GetStorage _box = GetStorage();
  // Use the same key you use elsewhere (picked from your AppConstants)
  final String _storageKey = AppConstants.userDataKey;

  late UserDataModel _cache;
  UserDataModel get userData => _cache;

  /// Initialize service and ensure userData exists
  Future<UserDataService> init() async {
    final raw = _box.read(_storageKey);

    if (raw == null) {
      // first run — create empty userData (this also generates userId via your makeId)
      _cache = UserDataModel.empty();
      await _persist();
    } else if (raw is Map<String, dynamic>) {
      _cache = UserDataModel.fromJson(Map<String, dynamic>.from(raw));
      // Example migration placeholder (bump schemaVersion handling here)
      if (_cache.schemaVersion < 1) {
        _cache = _migrate(_cache);
        await _persist();
      }
    } else {
      // corrupted or unexpected type: reset
      _cache = UserDataModel.empty();
      await _persist();
    }

    return this;
  }

  UserDataModel _migrate(UserDataModel old) {
    // Implement migrations here when schema changes
    return old.copyWith(schemaVersion: 1);
  }

  Future<void> _persist() async {
    await _box.write(_storageKey, _cache.toJson());
  }

  // ------------------ Profile ------------------

  /// Replace entire profile (use copyWith on the model before passing if needed)
  Future<void> updateProfile(UserProfileModel profile) async {
    _cache = _cache.copyWith(userProfileData: profile);
    await _persist();
  }

  /// Quick helper to update fields (if you prefer)
  Future<void> updateProfileFields({
    String? userName,
    String? appVersion,
  }) async {
    final old = _cache.userProfileData;
    final updated = old.copyWith(
      userName: userName ?? old.userName,
      appVersion: appVersion ?? old.appVersion,
    );
    await updateProfile(updated);
  }

  // ------------------ Projects ------------------

  /// Create a new project and persist
  Future<UserProjectModel> addProject({required String title}) async {
    final now = DateTime.now();
    final project = UserProjectModel(
      projectId: makeId(AppConstants.userDataKey),
      projectTitle: '',
      projectCreatedDate: now,
      projectUpdatedDate: now,
      projectTasks: [],
    );
    final newProjects = List<UserProjectModel>.from(_cache.userProjects)
      ..add(project);
    _cache = _cache.copyWith(userProjects: newProjects);
    await _persist();
    return project;
  }

  /// Update an entire project model (will update projectUpdatedDate automatically)
  Future<void> updateProject(UserProjectModel project) async {
    final idx = _cache.userProjects.indexWhere(
      (p) => p.projectId == project.projectId,
    );
    if (idx == -1) throw Exception('Project not found');
    final updated = project.copyWith(projectUpdatedDate: DateTime.now());
    final newProjects = List<UserProjectModel>.from(_cache.userProjects)
      ..[idx] = updated;
    _cache = _cache.copyWith(userProjects: newProjects);
    await _persist();
  }

  /// Remove project
  Future<void> removeProject(String projectId) async {
    final newProjects = _cache.userProjects
        .where((p) => p.projectId != projectId)
        .toList();
    _cache = _cache.copyWith(userProjects: newProjects);
    await _persist();
  }

  // ------------------ Tasks (per-project) ------------------

  /// Add task to a project
  Future<UserTasksModel> addTaskToProject({
    required String projectId,
    required String title,
    bool done = false,
  }) async {
    final pIdx = _cache.userProjects.indexWhere(
      (p) => p.projectId == projectId,
    );
    if (pIdx == -1) throw Exception('Project not found');

    final task = UserTasksModel(
      id: makeId(AppConstants.userDataKey),
      title: title,
      done: done,
      subTasks: [],
      // if your UserTasksModel has dates you can set them here
    );

    final project = _cache.userProjects[pIdx];
    final updatedProject = project.copyWith(
      projectTasks: List<UserProjectModel>.from(project.projectTasks)
        ..add(project),
      projectUpdatedDate: DateTime.now(),
    );

    final newProjects = List<UserProjectModel>.from(_cache.userProjects)
      ..[pIdx] = updatedProject;
    _cache = _cache.copyWith(userProjects: newProjects);
    await _persist();
    return task;
  }

  /// Update a task inside a project
  Future<void> updateTask({
    required String projectId,
    required UserProjectModel updatedTask,
  }) async {
    final pIdx = _cache.userProjects.indexWhere(
      (p) => p.projectId == projectId,
    );
    if (pIdx == -1) throw Exception('Project not found');

    final project = _cache.userProjects[pIdx];
    final tIdx = project.projectTasks.indexWhere(
      (t) => t.projectId == updatedTask.projectId,
    );
    if (tIdx == -1) throw Exception('Task not found');

    final newTasks = List<UserProjectModel>.from(project.projectTasks)
      ..[tIdx] = updatedTask;
    final updatedProject = project.copyWith(
      projectTasks: newTasks,
      projectUpdatedDate: DateTime.now(),
    );
    final newProjects = List<UserProjectModel>.from(_cache.userProjects)
      ..[pIdx] = updatedProject;

    _cache = _cache.copyWith(userProjects: newProjects);
    await _persist();
  }

  /// Remove a task from a project
  Future<void> removeTask({
    required String projectId,
    required String taskId,
  }) async {
    final pIdx = _cache.userProjects.indexWhere(
      (p) => p.projectId == projectId,
    );
    if (pIdx == -1) throw Exception('Project not found');

    final project = _cache.userProjects[pIdx];
    final newTasks = project.projectTasks
        .where((t) => t.projectId != taskId)
        .toList();
    final updatedProject = project.copyWith(
      projectTasks: newTasks,
      projectUpdatedDate: DateTime.now(),
    );
    final newProjects = List<UserProjectModel>.from(_cache.userProjects)
      ..[pIdx] = updatedProject;

    _cache = _cache.copyWith(userProjects: newProjects);
    await _persist();
  }

  // ------------------ SubTasks (global list) ------------------

  /// Add a global subtask (linked to a parent task by parentTaskId)
  Future<UserSubTaskModel> addSubTask({
    required String parentTaskId,
    required String title,
    bool done = false,
  }) async {
    final sub = UserSubTaskModel(
      id: makeId(AppConstants.userDataKey),
      parentTaskId: parentTaskId,
      title: title,
      done: done,
    );

    final newSubTasks = List<UserSubTaskModel>.from(_cache.userSubTasks)
      ..add(sub);
    _cache = _cache.copyWith(userSubTasks: newSubTasks);
    await _persist();
    return sub;
  }

  /// Update a global subtask
  Future<void> updateSubTask(UserSubTaskModel updated) async {
    final idx = _cache.userSubTasks.indexWhere((s) => s.id == updated.id);
    if (idx == -1) throw Exception('SubTask not found');
    final newSubTasks = List<UserSubTaskModel>.from(_cache.userSubTasks)
      ..[idx] = updated;
    _cache = _cache.copyWith(userSubTasks: newSubTasks);
    await _persist();
  }

  /// Remove a global subtask
  Future<void> removeSubTask(String subTaskId) async {
    final newSubTasks = _cache.userSubTasks
        .where((s) => s.id != subTaskId)
        .toList();
    _cache = _cache.copyWith(userSubTasks: newSubTasks);
    await _persist();
  }

  // ------------------ Query helpers ------------------

  UserProjectModel? getProjectById(String id) =>
      _cache.userProjects.firstWhereOrNull((p) => p.projectId == id);

  UserProjectModel? getTaskById(String projectId, String taskId) =>
      getProjectById(
        projectId,
      )?.projectTasks.firstWhereOrNull((t) => t.projectId == taskId);

  UserSubTaskModel? getSubTaskById(String id) =>
      _cache.userSubTasks.firstWhereOrNull((s) => s.id == id);

  // ------------------ Replace / Reset ------------------

  Future<void> replaceUserData(UserDataModel newData) async {
    _cache = newData;
    await _persist();
  }

  Future<void> reset() async {
    _cache = UserDataModel.empty();
    await _persist();
  }
}
