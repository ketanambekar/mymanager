class UserProjects {
  final String projectId;
  final String? projectName;
  final String? projectStatus;
  final String? projectDescription;
  final String? projectType;
  final String? projectColor;
  final String? projectCreatedAt;
  final String? projectUpdatedAt;

  UserProjects({
    required this.projectId,
    this.projectName,
    this.projectStatus,
    this.projectDescription,
    this.projectType,
    this.projectColor,
    this.projectCreatedAt,
    this.projectUpdatedAt,
  });

  factory UserProjects.fromMap(Map<String, dynamic> m) => UserProjects(
    projectId: m['project_id'] as String,
    projectName: m['project_name'] as String?,
    projectStatus: m['project_status'] as String?,
    projectDescription: m['project_description'] as String?,
    projectType: m['project_type'] as String?,
    projectColor: m['project_color'] as String?,
    projectCreatedAt: m['project_created_at'] as String?,
    projectUpdatedAt: m['project_updated_at'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'projectId': projectId,
    'projectName': projectName,
    'projectStatus': projectStatus,
    'projectDescription': projectDescription,
    'projectType': projectType,
    'projectColor': projectColor,
    'projectCreatedAt': projectCreatedAt,
    'projectUpdatedAt': projectUpdatedAt,
  };

  UserProjects copyWith({
    String? projectName,
    String? projectStatus,
    String? projectDescription,
    String? projectType,
    String? projectColor,
    String? projectUpdatedAt,
  }) {
    return UserProjects(
      projectId: projectId,
      projectName: projectName ?? this.projectName,
      projectStatus: projectStatus ?? this.projectStatus,
      projectDescription: projectDescription ?? this.projectDescription,
      projectType: projectType ?? this.projectType,
      projectColor: projectColor ?? this.projectColor,
      projectCreatedAt: projectCreatedAt,
      projectUpdatedAt: projectUpdatedAt ?? this.projectUpdatedAt,
    );
  }
}
