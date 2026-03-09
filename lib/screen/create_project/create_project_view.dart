import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mymanager/screen/create_project/create_project_controller.dart';
import 'package:mymanager/theme/theme_tokens.dart';

class CreateProjectView extends StatelessWidget {
  CreateProjectView({super.key});

  final CreateProjectController controller = Get.find<CreateProjectController>();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.appBg,
      appBar: AppBar(
        backgroundColor: context.appBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.title),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Create Project',
          style: GoogleFonts.plusJakartaSans(
            color: context.title,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? const [Color(0xFF0D1221), Color(0xFF121C31)]
                : const [Color(0xFFF7FAFF), Color(0xFFF0F5FF)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: context.panel.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: context.border),
                  boxShadow: [
                    BoxShadow(
                      color: cs.shadow.withValues(alpha: 0.14),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Form(
                  key: controller.projectFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7C4DFF), Color(0xFF536DFE)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.folder_copy_rounded, color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'New Project Workspace',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    color: context.title,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Set the essentials. You can edit details anytime.',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    color: context.subtitle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _FieldLabel(text: 'Project Name', color: context.subtitle),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: controller.projectNameTextController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'e.g., Mobile App Revamp',
                          prefixIcon: Icon(Icons.title_rounded),
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Project name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      _FieldLabel(text: 'Project Description', color: context.subtitle),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: controller.projectDescTextController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'What are you building? Who is it for?',
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 68),
                            child: Icon(Icons.description_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _FieldLabel(text: 'Project Type', color: context.subtitle),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: controller.projectTypeTextController,
                        decoration: const InputDecoration(
                          hintText: 'Personal, Work, Team, Client...',
                          prefixIcon: Icon(Icons.category_rounded),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _FieldLabel(text: 'Parent Project (Optional)', color: context.subtitle),
                      const SizedBox(height: 8),
                      Obx(
                        () => DropdownButtonFormField<String?>(
                          value: controller.selectedParentProjectId.value,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            hintText: 'Create as top-level project',
                            prefixIcon: Icon(Icons.account_tree_rounded),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('No parent (Top-level)'),
                            ),
                            ...controller.availableParentProjects.map(
                              (project) => DropdownMenuItem<String?>(
                                value: project.projectId,
                                child: Text(project.projectName ?? 'Untitled Project'),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            controller.selectedParentProjectId.value = value;
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['Work', 'Personal', 'Team', 'Planning']
                            .map(
                              (tag) => ActionChip(
                                label: Text(tag),
                                onPressed: () {
                                  controller.projectTypeTextController.text = tag;
                                },
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 26),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: controller.createProject,
                          icon: const Icon(Icons.add_rounded),
                          label: Text(
                            'Create Project',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
