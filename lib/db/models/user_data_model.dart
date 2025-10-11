import 'package:mymanager/constants/app_constants.dart';
import 'package:mymanager/db/models/user_profile_model.dart';
import 'package:mymanager/db/models/user_project_model.dart';
import 'package:mymanager/db/models/user_sub_tasks_model.dart';
import 'package:mymanager/db/models/user_tasks_model.dart';
import 'package:mymanager/utils/global_utils.dart';

class UserDataModel {
  final UserProfileModel userProfileData;
  final List<UserProjectModel> userProjects;
  final List<UserTasksModel> userTasks;
  final List<UserSubTaskModel> userSubTasks;
  final int schemaVersion;

  UserDataModel({
    required this.userProfileData,
    List<UserProjectModel>? userProjects,
    List<UserTasksModel>? userTasks,
    List<UserSubTaskModel>? userSubTasks,
    this.schemaVersion = 1,
  }) : userProjects = userProjects ?? [],
       userTasks = userTasks ?? [],
       userSubTasks = userSubTasks ?? [];

  UserDataModel copyWith({
    UserProfileModel? userProfileData,
    List<UserProjectModel>? userProjects,
    List<UserTasksModel>? userTasks,
    List<UserSubTaskModel>? userSubTasks,
    int? schemaVersion,
  }) {
    return UserDataModel(
      userProfileData: userProfileData ?? this.userProfileData,
      userProjects:
          userProjects ?? List<UserProjectModel>.from(this.userProjects),
      userTasks: userTasks ?? List<UserTasksModel>.from(this.userTasks),
      userSubTasks:
          userSubTasks ?? List<UserSubTaskModel>.from(this.userSubTasks),
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }

  factory UserDataModel.empty() => UserDataModel(
    userProfileData: UserProfileModel(
      userId: makeId(AppConstants.userDataKey),
      userName: '',
      appVersion: '',
    ),
    userProjects: [],
    userTasks: [],
    userSubTasks: [],
    schemaVersion: 1,
  );

  factory UserDataModel.fromJson(Map<String, dynamic> json) {
    final p = json['userProfileData'] is Map
        ? UserProfileModel.fromJson(
            Map<String, dynamic>.from(json['userProfileData']),
          )
        : UserProfileModel(
            userId: makeId(AppConstants.userIdKey),
            userName: '',
            appVersion: '',
          );
    final rawProjects = json['userProjects'];
    final rawTasks = json['userTasks'];
    final rawSubTasks = json['userSubTasks'];
    return UserDataModel(
      userProfileData: p,
      userProjects: rawProjects is List
          ? rawProjects
                .map(
                  (e) =>
                      UserProjectModel.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : [],
      userTasks: rawTasks is List
          ? rawTasks
                .map(
                  (e) => UserTasksModel.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : [],
      userSubTasks: rawSubTasks is List
          ? rawSubTasks
                .map(
                  (e) =>
                      UserSubTaskModel.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : [],
      schemaVersion: json['schemaVersion'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'userProfileData': userProfileData.toJson(),
    'userProjects': userProjects.map((p) => p.toJson()).toList(),
    'userTasks': userTasks.map((s) => s.toJson()).toList(),
    'userSubTasks': userSubTasks.map((s) => s.toJson()).toList(),
    'schemaVersion': schemaVersion,
  };
}
