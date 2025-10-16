import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/screen/create_project/create_project_controller.dart';
import 'package:mymanager/widgets/app_button.dart';

class CreateProjectView extends StatelessWidget {
  CreateProjectView({super.key});
  final CreateProjectController controller =
      Get.find<CreateProjectController>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add New Project")),
      body: Container(
        margin: EdgeInsets.all(16),
        child: Form(
          key: controller.projectFormKey,
          child: Column(
            children: <Widget>[
              TextField(
                controller: controller.projectNameTextController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Project Name',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  // controller.userName.value = value;
                },
              ),
              SizedBox(height: 16),
              TextField(
                controller: controller.projectDescTextController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Project Description',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  // controller.userName.value = value;
                },
              ),
              SizedBox(height: 16),

              TextField(
                controller: controller.projectTypeTextController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Project Type',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  // controller.userName.value = value;
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white10,
        height: 75,
        padding: EdgeInsets.all(8),
        child: AppButton(
          text: 'Create Project',
          onTap: () {
            controller.createProject();
            // Get.back();
          },
        ),
      ),
    );
  }
}
