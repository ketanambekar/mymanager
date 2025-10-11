import 'package:mymanager/constants/app_constants.dart';
import 'package:mymanager/utils/global_utils.dart';

class UserProjectModel {
  final String projectId;
  final String projectTitle;
  final DateTime projectCreatedDate;
  final DateTime projectUpdatedDate;
  final List<UserProjectModel> projectTasks;

  UserProjectModel({
    required this.projectId,
    required this.projectTitle,
    required this.projectCreatedDate,
    required this.projectUpdatedDate,
    List<UserProjectModel>? projectTasks,
  }) : projectTasks = projectTasks ?? [];

  UserProjectModel copyWith({
    String? projectId,
    String? projectTitle,
    DateTime? projectCreatedDate,
    DateTime? projectUpdatedDate,
    List<UserProjectModel>? projectTasks,
  }) {
    return UserProjectModel(
      projectId: projectId ?? this.projectId,
      projectTitle: projectTitle ?? this.projectTitle,
      projectCreatedDate: projectCreatedDate ?? this.projectCreatedDate,
      projectUpdatedDate: projectUpdatedDate ?? this.projectUpdatedDate,
      projectTasks: projectTasks ?? List<UserProjectModel>.from(this.projectTasks),
    );
  }

  factory UserProjectModel.fromJson(Map<String, dynamic> json) {
    final raw = json['projectTasks'];
    return UserProjectModel(
      projectId:
          json['projectId']?.toString() ?? makeId(AppConstants.projectIdKey),
      projectTitle: json['projectTitle'] ?? '',
      projectCreatedDate:
          DateTime.tryParse(json['projectCreatedDate'] ?? '') ?? DateTime.now(),
      projectUpdatedDate:
          DateTime.tryParse(json['projectUpdatedDate'] ?? '') ?? DateTime.now(),
      projectTasks: raw is List
          ? raw.map((e) => UserProjectModel.fromJson(Map<String, dynamic>.from(e))).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'projectId': projectId,
    'projectTitle': projectTitle,
    'projectCreatedDate': projectCreatedDate.toIso8601String(),
    'projectUpdatedDate': projectUpdatedDate.toIso8601String(),
    'projectTasks': projectTasks.map((t) => t.toJson()).toList(),
  };
}
