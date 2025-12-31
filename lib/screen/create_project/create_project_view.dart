import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mymanager/screen/create_project/create_project_controller.dart';

class CreateProjectView extends StatelessWidget {
  CreateProjectView({super.key});
  final CreateProjectController controller =
      Get.find<CreateProjectController>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Add New Project',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: controller.projectFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Header Icon
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C4DFF), Color(0xFF536DFE)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C4DFF).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.folder_outlined,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Project Name Field
                const Text(
                  'Project Name',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: controller.projectNameTextController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter project name',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      prefixIcon: Icon(
                        Icons.title,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Project Description Field
                const Text(
                  'Project Description',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: controller.projectDescTextController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Enter project description',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(bottom: 60),
                        child: Icon(
                          Icons.description_outlined,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Project Type Field
                const Text(
                  'Project Type',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: controller.projectTypeTextController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'e.g., Personal, Work, Team',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                      prefixIcon: Icon(
                        Icons.category_outlined,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Create Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      controller.createProject();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C4DFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Create Project',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
