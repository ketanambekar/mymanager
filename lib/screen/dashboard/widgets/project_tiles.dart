import 'package:flutter/material.dart';
import 'package:mymanager/database/tables/user_projects/models/user_project_model.dart';
import 'package:mymanager/theme/app_text_styles.dart';
import 'package:mymanager/utils/global_utils.dart';

class ProjectTiles extends StatelessWidget {
  final UserProjects project;
  const ProjectTiles({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 16, 8, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(project.projectName ?? '', style: AppTextStyles.bodyLarge),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: Icon(
                  Icons.timelapse_outlined,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              Text(
                timeAgo(project.projectUpdatedAt.toString()),
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ],
      ),
    );
    ;
  }
}
