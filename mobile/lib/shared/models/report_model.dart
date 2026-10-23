class ReportModel {
  final String id;
  final String? description;
  final String? category;
  final ReportStatus status;
  final ProcessingState processingState;
  final String? locationDescription;
  final double? latitude;
  final double? longitude;
  final String submitterId;
  final DateTime submittedAt;
  final DateTime? processedAt;
  final String? aiSummary;
  final List<String> evidenceIds;
  final String? incidentId;

  const ReportModel({
    required this.id,
    this.description,
    this.category,
    required this.status,
    required this.processingState,
    this.locationDescription,
    this.latitude,
    this.longitude,
    required this.submitterId,
    required this.submittedAt,
    this.processedAt,
    this.aiSummary,
    this.evidenceIds = const [],
    this.incidentId,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) => ReportModel(
    id: json['id'] as String,
    description: json['description'] as String?,
    category: json['category'] as String?,
    status: ReportStatus.fromString(json['status'] as String? ?? 'pending'),
    processingState: ProcessingState.fromString(
      json['processing_state'] as String? ?? 'queued'),
    locationDescription: json['location_description'] as String?,
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
    submitterId: json['submitter_id'] as String,
    submittedAt: DateTime.parse(json['submitted_at'] as String),
    processedAt: json['processed_at'] != null
        ? DateTime.parse(json['processed_at'] as String)
        : null,
    aiSummary: json['ai_summary'] as String?,
    evidenceIds: (json['evidence_ids'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList() ?? [],
    incidentId: json['incident_id'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'category': category,
    'status': status.value,
    'processing_state': processingState.value,
    'location_description': locationDescription,
    'latitude': latitude,
    'longitude': longitude,
    'submitter_id': submitterId,
    'submitted_at': submittedAt.toIso8601String(),
    'processed_at': processedAt?.toIso8601String(),
    'ai_summary': aiSummary,
    'evidence_ids': evidenceIds,
    'incident_id': incidentId,
  };
}

enum ReportStatus {
  pending('pending'),
  processing('processing'),
  reviewed('reviewed'),
  closed('closed'),
  failed('failed');

  final String value;
  const ReportStatus(this.value);

  factory ReportStatus.fromString(String value) =>
      ReportStatus.values.firstWhere(
        (s) => s.value == value,
        orElse: () => ReportStatus.pending,
      );

  String get label => switch (this) {
    pending => 'Pending',
    processing => 'Processing',
    reviewed => 'Reviewed',
    closed => 'Closed',
    failed => 'Failed',
  };
}

enum ProcessingState {
  queued('queued'),
  extracting('extracting'),
  extracted('extracted'),
  failed('failed');

  final String value;
  const ProcessingState(this.value);

  factory ProcessingState.fromString(String value) =>
      ProcessingState.values.firstWhere(
        (s) => s.value == value,
        orElse: () => ProcessingState.queued,
      );
}
