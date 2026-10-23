class TaskModel {
  final String id;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final String? assigneeId;
  final String? incidentId;
  final String? reportId;
  final DateTime? dueAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;

  const TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.assigneeId,
    this.incidentId,
    this.reportId,
    this.dueAt,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    status: TaskStatus.fromString(json['status'] as String? ?? 'pending'),
    priority: TaskPriority.fromString(json['priority'] as String? ?? 'medium'),
    assigneeId: json['assignee_id'] as String?,
    incidentId: json['incident_id'] as String?,
    reportId: json['report_id'] as String?,
    dueAt: json['due_at'] != null ? DateTime.parse(json['due_at'] as String) : null,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    notes: json['notes'] as String?,
  );
}

enum TaskStatus {
  pending('pending'), inProgress('in_progress'), completed('completed'), cancelled('cancelled');

  final String value;
  const TaskStatus(this.value);
  factory TaskStatus.fromString(String v) =>
    TaskStatus.values.firstWhere((s) => s.value == v,
      orElse: () => TaskStatus.pending);

  String get label => switch (this) {
    pending => 'Pending',
    inProgress => 'In Progress',
    completed => 'Completed',
    cancelled => 'Cancelled',
  };
}

enum TaskPriority {
  low('low'), medium('medium'), high('high'), critical('critical');

  final String value;
  const TaskPriority(this.value);
  factory TaskPriority.fromString(String v) =>
    TaskPriority.values.firstWhere((s) => s.value == v,
      orElse: () => TaskPriority.medium);
}
