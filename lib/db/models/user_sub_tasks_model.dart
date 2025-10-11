import 'package:mymanager/constants/app_constants.dart';
import 'package:mymanager/utils/global_utils.dart';

class UserSubTaskModel {
  final String id;
  final String parentTaskId;
  final String title;
  final bool done;

  UserSubTaskModel({
    required this.id,
    required this.parentTaskId,
    required this.title,
    this.done = false,
  });

  UserSubTaskModel copyWith({
    String? id,
    String? parentTaskId,
    String? title,
    bool? done,
  }) {
    return UserSubTaskModel(
      id: id ?? this.id,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      title: title ?? this.title,
      done: done ?? this.done,
    );
  }

  factory UserSubTaskModel.fromJson(Map<String, dynamic> json) {
    return UserSubTaskModel(
      id: json['id']?.toString() ?? makeId(AppConstants.subTaskIdKey),
      parentTaskId: json['parentTaskId']?.toString() ?? '',
      title: json['title'] ?? '',
      done: json['done'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'parentTaskId': parentTaskId,
    'title': title,
    'done': done,
  };
}
