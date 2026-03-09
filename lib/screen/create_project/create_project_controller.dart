import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/constants/app_constants.dart';
import 'package:mymanager/database/apis/user_project_api.dart';
import 'package:mymanager/database/tables/user_projects/models/user_project_model.dart';
import 'package:mymanager/services/project_context_controller.dart';

class CreateProjectController extends GetxController {
  final projectFormKey = GlobalKey<FormState>();
  final TextEditingController projectNameTextController =
      TextEditingController();
  final TextEditingController projectDescTextController =
      TextEditingController();
  final TextEditingController projectTypeTextController =
      TextEditingController();
  final RxList<UserProjects> availableParentProjects = <UserProjects>[].obs;
  final RxnString selectedParentProjectId = RxnString();

  @override
  void onInit() {
    super.onInit();
    _loadParentProjects();
  }

  Future<void> _loadParentProjects() async {
    availableParentProjects.value = await UserProjectsApi.getProjects();
  }

  Future<void> createProject() async {
    if (projectFormKey.currentState?.validate() != true) return;
    
    try {
      final newProject = UserProjects(
        projectId: '',
        parentProjectId: selectedParentProjectId.value,
        projectName: projectNameTextController.text.trim(),
        projectStatus: AppConstants.projectStatusActive,
        projectDescription: projectDescTextController.text.trim(),
        projectType: projectTypeTextController.text.trim(),
        projectColor: '#FF00FF',
      );

      await UserProjectsApi.createProject(newProject);
      if (Get.isRegistered<ProjectContextController>()) {
        await Get.find<ProjectContextController>().loadProjects();
      }
      if (kDebugMode) {
        developer.log('Project created successfully', name: 'CreateProjectController');
      }
      Get.back(result: true);
    } catch (e, stack) {
      if (kDebugMode) {
        developer.log(
          'Error creating project: $e',
          error: e,
          stackTrace: stack,
          name: 'CreateProjectController',
        );
      }
    }
  }
}
