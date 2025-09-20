import 'sub_task.dart';

class Task {
  String id;
  String taskName;
  String? taskDate; // ISO date or friendly string
  String? taskTime; // ISO time or friendly string
  List<String>? taskAlerts; // e.g. ['-10m', '-1h'] or actual timestamps
  String? taskSlot; // optional slot label
  List<SubTask> subTasks;
  String? taskDuration;
  String? taskEndTime;
  String? taskStartDate;
  String? taskFrequency;
  bool isTaskAlert;
  String? taskStatus; // e.g. 'pending', 'completed'
  String? taskDescription;
  String? taskCategory;
  String? taskPriority;

  Task({
    required this.id,
    required this.taskName,
    this.taskDate,
    this.taskTime,
    this.taskAlerts,
    this.taskSlot,
    List<SubTask>? subTasks,
    this.taskDuration,
    this.taskEndTime,
    this.taskStartDate,
    this.taskFrequency,
    this.isTaskAlert = false,
    this.taskStatus,
    this.taskDescription,
    this.taskCategory,
    this.taskPriority,
  }) : subTasks = subTasks ?? [];

  factory Task.fromJson(Map<String, dynamic> json) {
    final subs = (json['subTasks'] as List<dynamic>?)
        ?.map((e) => SubTask.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList() ??
        [];
    return Task(
      id: json['id'] as String,
      taskName: json['taskName'] as String,
      taskDate: json['taskDate'] as String?,
      taskTime: json['taskTime'] as String?,
      taskAlerts: (json['taskAlerts'] as List<dynamic>?)?.map((e) => e as String).toList(),
      taskSlot: json['taskSlot'] as String?,
      subTasks: subs,
      taskDuration: json['taskDuration'] as String?,
      taskEndTime: json['taskEndTime'] as String?,
      taskStartDate: json['taskStartDate'] as String?,
      taskFrequency: json['taskFrequency'] as String?,
      isTaskAlert: json['isTaskAlert'] as bool? ?? false,
      taskStatus: json['taskStatus'] as String?,
      taskDescription: json['taskDescription'] as String?,
      taskCategory: json['taskCategory'] as String?,
      taskPriority: json['taskPriority'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'taskName': taskName,
    'taskDate': taskDate,
    'taskTime': taskTime,
    'taskAlerts': taskAlerts,
    'taskSlot': taskSlot,
    'subTasks': subTasks.map((s) => s.toJson()).toList(),
    'taskDuration': taskDuration,
    'taskEndTime': taskEndTime,
    'taskStartDate': taskStartDate,
    'taskFrequency': taskFrequency,
    'isTaskAlert': isTaskAlert,
    'taskStatus': taskStatus,
    'taskDescription': taskDescription,
    'taskCategory': taskCategory,
    'taskPriority': taskPriority,
  };

  // Convenience: copyWith for updates
  Task copyWith({
    String? taskName,
    String? taskDate,
    String? taskTime,
    List<String>? taskAlerts,
    String? taskSlot,
    List<SubTask>? subTasks,
    String? taskDuration,
    String? taskEndTime,
    String? taskStartDate,
    String? taskFrequency,
    bool? isTaskAlert,
    String? taskStatus,
    String? taskDescription,
    String? taskCategory,
    String? taskPriority,
  }) {
    return Task(
      id: id,
      taskName: taskName ?? this.taskName,
      taskDate: taskDate ?? this.taskDate,
      taskTime: taskTime ?? this.taskTime,
      taskAlerts: taskAlerts ?? this.taskAlerts,
      taskSlot: taskSlot ?? this.taskSlot,
      subTasks: subTasks ?? this.subTasks,
      taskDuration: taskDuration ?? this.taskDuration,
      taskEndTime: taskEndTime ?? this.taskEndTime,
      taskStartDate: taskStartDate ?? this.taskStartDate,
      taskFrequency: taskFrequency ?? this.taskFrequency,
      isTaskAlert: isTaskAlert ?? this.isTaskAlert,
      taskStatus: taskStatus ?? this.taskStatus,
      taskDescription: taskDescription ?? this.taskDescription,
      taskCategory: taskCategory ?? this.taskCategory,
      taskPriority: taskPriority ?? this.taskPriority,
    );
  }
}
