class TaskStatusOption {
  final String id;
  final String code;
  final String name;
  final String? color;
  final int sortOrder;
  final bool isSystem;

  const TaskStatusOption({
    required this.id,
    required this.code,
    required this.name,
    this.color,
    required this.sortOrder,
    required this.isSystem,
  });

  factory TaskStatusOption.fromMap(Map<String, dynamic> map) {
    return TaskStatusOption(
      id: (map['id'] ?? '').toString(),
      code: (map['code'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      color: map['color']?.toString(),
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
      isSystem: map['is_system'] == true,
    );
  }
}
