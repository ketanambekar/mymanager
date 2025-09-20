class SubTask {
  final String id;
  String name;
  String? time;
  bool done;

  SubTask({required this.id, required this.name, this.time, this.done = false});

  factory SubTask.fromJson(Map<String, dynamic> json) {
    return SubTask(
      id: json['id'] as String,
      name: json['name'] as String,
      time: json['time'] as String?,
      done: json['done'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'time': time,
    'done': done,
  };
}
