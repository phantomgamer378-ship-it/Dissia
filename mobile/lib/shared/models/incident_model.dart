class IncidentModel {
  final String id;
  final String title;
  final String? description;
  final IncidentStatus status;
  final IncidentSeverity severity;
  final String? locationDescription;
  final double? latitude;
  final double? longitude;
  final List<String> reportIds;
  final List<String> taskIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const IncidentModel({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.severity,
    this.locationDescription,
    this.latitude,
    this.longitude,
    this.reportIds = const [],
    this.taskIds = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory IncidentModel.fromJson(Map<String, dynamic> json) => IncidentModel(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    status: IncidentStatus.fromString(json['status'] as String? ?? 'open'),
    severity: IncidentSeverity.fromString(json['severity'] as String? ?? 'medium'),
    locationDescription: json['location_description'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    reportIds: (json['report_ids'] as List<dynamic>?)
        ?.map((e) => e as String).toList() ?? [],
    taskIds: (json['task_ids'] as List<dynamic>?)
        ?.map((e) => e as String).toList() ?? [],
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );
}

enum IncidentStatus {
  open('open'), active('active'), resolved('resolved'), closed('closed');

  final String value;
  const IncidentStatus(this.value);
  factory IncidentStatus.fromString(String v) =>
    IncidentStatus.values.firstWhere((s) => s.value == v,
      orElse: () => IncidentStatus.open);
}

enum IncidentSeverity {
  low('low'), medium('medium'), high('high'), critical('critical');

  final String value;
  const IncidentSeverity(this.value);
  factory IncidentSeverity.fromString(String v) =>
    IncidentSeverity.values.firstWhere((s) => s.value == v,
      orElse: () => IncidentSeverity.medium);
}
