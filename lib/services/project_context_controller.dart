import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mymanager/database/apis/user_project_api.dart';
import 'package:mymanager/database/tables/user_projects/models/user_project_model.dart';

class ProjectContextController extends GetxController {
  static const String _selectedProjectKey = 'selected_project_id';

  final GetStorage _storage = GetStorage();
  final RxList<UserProjects> projects = <UserProjects>[].obs;
  final RxnString selectedProjectId = RxnString();

  UserProjects? get selectedProject {
    final id = selectedProjectId.value;
    if (id == null || id.isEmpty) return null;
    for (final project in projects) {
      if (project.projectId == id) return project;
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    loadProjects();
  }

  Future<void> loadProjects() async {
    final fetched = await UserProjectsApi.getProjects();
    projects.value = fetched;

    if (fetched.isEmpty) {
      selectedProjectId.value = null;
      await _storage.remove(_selectedProjectKey);
      return;
    }

    final stored = _storage.read<String>(_selectedProjectKey);
    final current = selectedProjectId.value;

    String? candidate;
    for (final id in <String?>[current, stored].whereType<String>()) {
      final exists = fetched.any((p) => p.projectId == id);
      if (exists) {
        candidate = id;
        break;
      }
    }

    final nextId = candidate ?? fetched.first.projectId;
    if (selectedProjectId.value != nextId) {
      selectedProjectId.value = nextId;
    }
    await _storage.write(_selectedProjectKey, nextId);
  }

  Future<void> selectProject(String? projectId) async {
    if (projectId == null || projectId.isEmpty) return;
    if (!projects.any((p) => p.projectId == projectId)) return;

    if (selectedProjectId.value != projectId) {
      selectedProjectId.value = projectId;
      await _storage.write(_selectedProjectKey, projectId);
    }
  }
}
