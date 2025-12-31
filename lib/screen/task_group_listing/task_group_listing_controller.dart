import 'package:get/get.dart';
import 'package:mymanager/database/apis/user_project_api.dart';
import 'package:mymanager/database/apis/task_api.dart';
import 'package:mymanager/database/tables/user_projects/models/user_project_model.dart';

class TaskGroupListingController extends GetxController {
  final RxList<UserProjects> projects = <UserProjects>[].obs;
  final RxBool isLoading = false.obs;
  final RxMap<String, int> projectTaskCounts = <String, int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadProjects();
  }

  Future<void> loadProjects() async {
    isLoading.value = true;
    try {
      final allProjects = await UserProjectsApi.getProjects();
      projects.value = allProjects;
      
      // Load task counts for each project
      for (var project in allProjects) {
        final tasks = await TaskApi.getTasks(projectId: project.projectId);
        projectTaskCounts[project.projectId] = tasks.length;
      }
    } catch (e) {
      print('Error loading projects: $e');
    } finally {
      isLoading.value = false;
    }
  }

  int getTaskCount(String projectId) {
    return projectTaskCounts[projectId] ?? 0;
  }
}
