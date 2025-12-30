class Task {
  final String taskId;
  final String? projectId;
  final String taskTitle;
  final String? taskDescription;
  final String? taskPriority;
  final String? taskUrgency;
  final String? taskImportance;
  final String taskStatus;
  final String? taskFrequency;
  final int? taskFrequencyValue;
  final bool enableAlerts;
  final String? alertTime;
  final String? taskStartDate;
  final String? taskDueDate;
  final String? taskCompletedDate;
  final int? timeEstimate;
  final int timeSpent;
  final String? taskColor;
  final int taskOrder;
  final bool isRecurring;
  final String? parentTaskId;
  final String? energyLevel;
  final bool focusRequired;
  final String? taskCreatedAt;
  final String? taskUpdatedAt;

  Task({
    required this.taskId,
    this.projectId,
    required this.taskTitle,
    this.taskDescription,
    this.taskPriority,
    this.taskUrgency,
    this.taskImportance,
    this.taskStatus = 'Todo',
    this.taskFrequency,
    this.taskFrequencyValue,
    this.enableAlerts = false,
    this.alertTime,
    this.taskStartDate,
    this.taskDueDate,
    this.taskCompletedDate,
    this.timeEstimate,
    this.timeSpent = 0,
    this.taskColor,
    this.taskOrder = 0,
    this.isRecurring = false,
    this.parentTaskId,
    this.energyLevel,
    this.focusRequired = false,
    this.taskCreatedAt,
    this.taskUpdatedAt,
  });

  factory Task.fromMap(Map<String, dynamic> m) => Task(
        taskId: m['task_id'] as String,
        projectId: m['project_id'] as String?,
        taskTitle: m['task_title'] as String,
        taskDescription: m['task_description'] as String?,
        taskPriority: m['task_priority'] as String?,
        taskUrgency: m['task_urgency'] as String?,
        taskImportance: m['task_importance'] as String?,
        taskStatus: m['task_status'] as String? ?? 'Todo',
        taskFrequency: m['task_frequency'] as String?,
        taskFrequencyValue: m['task_frequency_value'] as int?,
        enableAlerts: (m['enable_alerts'] as int? ?? 0) == 1,
        alertTime: m['alert_time'] as String?,
        taskStartDate: m['task_start_date'] as String?,
        taskDueDate: m['task_due_date'] as String?,
        taskCompletedDate: m['task_completed_date'] as String?,
        timeEstimate: m['time_estimate'] as int?,
        timeSpent: m['time_spent'] as int? ?? 0,
        taskColor: m['task_color'] as String?,
        taskOrder: m['task_order'] as int? ?? 0,
        isRecurring: (m['is_recurring'] as int? ?? 0) == 1,
        parentTaskId: m['parent_task_id'] as String?,
        energyLevel: m['energy_level'] as String?,
        focusRequired: (m['focus_required'] as int? ?? 0) == 1,
        taskCreatedAt: m['task_created_at'] as String?,
        taskUpdatedAt: m['task_updated_at'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'task_id': taskId,
        'project_id': projectId,
        'task_title': taskTitle,
        'task_description': taskDescription,
        'task_priority': taskPriority,
        'task_urgency': taskUrgency,
        'task_importance': taskImportance,
        'task_status': taskStatus,
        'task_frequency': taskFrequency,
        'task_frequency_value': taskFrequencyValue,
        'enable_alerts': enableAlerts ? 1 : 0,
        'alert_time': alertTime,
        'task_start_date': taskStartDate,
        'task_due_date': taskDueDate,
        'task_completed_date': taskCompletedDate,
        'time_estimate': timeEstimate,
        'time_spent': timeSpent,
        'task_color': taskColor,
        'task_order': taskOrder,
        'is_recurring': isRecurring ? 1 : 0,
        'parent_task_id': parentTaskId,
        'energy_level': energyLevel,
        'focus_required': focusRequired ? 1 : 0,
        'task_created_at': taskCreatedAt,
        'task_updated_at': taskUpdatedAt,
      };

  Task copyWith({
    String? projectId,
    String? taskTitle,
    String? taskDescription,
    String? taskPriority,
    String? taskUrgency,
    String? taskImportance,
    String? taskStatus,
    String? taskFrequency,
    int? taskFrequencyValue,
    bool? enableAlerts,
    String? alertTime,
    String? taskStartDate,
    String? taskDueDate,
    String? taskCompletedDate,
    int? timeEstimate,
    int? timeSpent,
    String? taskColor,
    int? taskOrder,
    bool? isRecurring,
    String? parentTaskId,
    String? energyLevel,
    bool? focusRequired,
    String? taskUpdatedAt,
  }) {
    return Task(
      taskId: taskId,
      projectId: projectId ?? this.projectId,
      taskTitle: taskTitle ?? this.taskTitle,
      taskDescription: taskDescription ?? this.taskDescription,
      taskPriority: taskPriority ?? this.taskPriority,
      taskUrgency: taskUrgency ?? this.taskUrgency,
      taskImportance: taskImportance ?? this.taskImportance,
      taskStatus: taskStatus ?? this.taskStatus,
      taskFrequency: taskFrequency ?? this.taskFrequency,
      taskFrequencyValue: taskFrequencyValue ?? this.taskFrequencyValue,
      enableAlerts: enableAlerts ?? this.enableAlerts,
      alertTime: alertTime ?? this.alertTime,
      taskStartDate: taskStartDate ?? this.taskStartDate,
      taskDueDate: taskDueDate ?? this.taskDueDate,
      taskCompletedDate: taskCompletedDate ?? this.taskCompletedDate,
      timeEstimate: timeEstimate ?? this.timeEstimate,
      timeSpent: timeSpent ?? this.timeSpent,
      taskColor: taskColor ?? this.taskColor,
      taskOrder: taskOrder ?? this.taskOrder,
      isRecurring: isRecurring ?? this.isRecurring,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      energyLevel: energyLevel ?? this.energyLevel,
      focusRequired: focusRequired ?? this.focusRequired,
      taskCreatedAt: taskCreatedAt,
      taskUpdatedAt: taskUpdatedAt ?? this.taskUpdatedAt,
    );
  }

  // Helper methods for Eisenhower Matrix
  bool get isUrgentAndImportant =>
      (taskUrgency == 'High' && taskImportance == 'High') ||
      taskPriority == 'Urgent & Important';

  bool get isUrgentNotImportant =>
      (taskUrgency == 'High' && taskImportance != 'High') ||
      taskPriority == 'Urgent But Not Important';

  bool get isNotUrgentButImportant =>
      (taskUrgency != 'High' && taskImportance == 'High') ||
      taskPriority == 'Not Urgent But Important';

  bool get isNotUrgentNotImportant =>
      (taskUrgency != 'High' && taskImportance != 'High') ||
      taskPriority == 'Not Urgent & Not Important';

  bool get isOverdue {
    if (taskDueDate == null || taskStatus == 'Completed') return false;
    try {
      final dueDate = DateTime.parse(taskDueDate!);
      return DateTime.now().isAfter(dueDate);
    } catch (_) {
      return false;
    }
  }

  bool get isDueToday {
    if (taskDueDate == null) return false;
    try {
      final dueDate = DateTime.parse(taskDueDate!);
      final now = DateTime.now();
      return dueDate.year == now.year &&
          dueDate.month == now.month &&
          dueDate.day == now.day;
    } catch (_) {
      return false;
    }
  }

  bool get isSubTask => parentTaskId != null && parentTaskId!.isNotEmpty;
}
