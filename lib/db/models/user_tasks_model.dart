import 'package:mymanager/constants/app_constants.dart';
import 'package:mymanager/core/models/sub_task.dart';
import 'package:mymanager/utils/global_utils.dart';

class UserTasksModel {
  final String id;
  final String title;
  final bool done;
  final List<SubTask> subTasks;

  UserTasksModel({
    required this.id,
    required this.title,
    this.done = false,
    List<SubTask>? subTasks,
  }) : subTasks = subTasks ?? [];

  UserTasksModel copyWith({
    String? id,
    String? title,
    bool? done,
    List<SubTask>? subTasks,
  }) {
    return UserTasksModel(
      id: id ?? this.id,
      title: title ?? this.title,
      done: done ?? this.done,
      subTasks: subTasks ?? List<SubTask>.from(this.subTasks),
    );
  }

  factory UserTasksModel.fromJson(Map<String, dynamic> json) {
    final raw = json['subTasks'];
    return UserTasksModel(
      id: json['id']?.toString() ?? makeId(AppConstants.taskIdKey),
      title: json['title'] ?? '',
      done: json['done'] ?? false,
      subTasks: raw is List
          ? raw
                .map((e) => SubTask.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'done': done,
    'subTasks': subTasks.map((s) => s.toJson()).toList(),
  };
}
