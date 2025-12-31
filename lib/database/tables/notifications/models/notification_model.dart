class NotificationModel {
  final String notificationId;
  final String title;
  final String message;
  final String type; // 'task', 'project', 'reminder', 'system'
  final String? relatedId;
  final bool isRead;
  final String createdAt;

  NotificationModel({
    required this.notificationId,
    required this.title,
    required this.message,
    required this.type,
    this.relatedId,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      notificationId: map['notificationId'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      type: map['type'] as String,
      relatedId: map['relatedId'] as String?,
      isRead: (map['isRead'] as int) == 1,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notificationId': notificationId,
      'title': title,
      'message': message,
      'type': type,
      'relatedId': relatedId,
      'isRead': isRead ? 1 : 0,
      'created_at': createdAt,
    };
  }

  NotificationModel copyWith({
    String? notificationId,
    String? title,
    String? message,
    String? type,
    String? relatedId,
    bool? isRead,
    String? createdAt,
  }) {
    return NotificationModel(
      notificationId: notificationId ?? this.notificationId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
