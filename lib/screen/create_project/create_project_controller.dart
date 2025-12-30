import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/constants/app_constants.dart';
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
    if (projectFormKey.currentState?.validate() != true) return;
    
    try {
      final newProject = UserProjects(
        projectId: '',
        projectName: projectNameTextController.text.trim(),
        projectStatus: AppConstants.projectStatusActive,
        projectDescription: projectDescTextController.text.trim(),
        projectType: projectTypeTextController.text.trim(),
        projectColor: '#FF00FF',
      );

      await UserProjectsApi.createProject(newProject);
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
