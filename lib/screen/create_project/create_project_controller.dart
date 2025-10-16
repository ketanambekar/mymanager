import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/database/apis/user_project_api.dart';
import 'package:mymanager/database/tables/user_projects/models/user_project_model.dart';

class CreateProjectController extends GetxController {
  final projectFormKey = GlobalKey<FormState>();
  final TextEditingController projectNameTextController =
      TextEditingController();
  final TextEditingController projectDescTextController =
      TextEditingController();
  final TextEditingController projectTypeTextController =
      TextEditingController();

  @override
  void onInit() {
    super.onInit();
  }

  Future<void> createProject() async {
    if (projectNameTextController.text.isEmpty) return;
    final newProject = UserProjects(
      projectId: '',
      projectName: projectNameTextController.text,
      projectStatus: 'Active',
      projectDescription: projectDescTextController.text,
      projectType: projectTypeTextController.text,
      projectColor: '#FF00FF',
    );

    await UserProjectsApi.createProject(newProject);
    Get.back(result: true);
    print('Project created!');
  }
}
