import 'dart:convert';

class ReportDraft {
  final String id;
  final String description;
  final String? location;
  final double? latitude;
  final double? longitude;
  final bool aiConsent;
  final List<String> localAttachmentPaths;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus; // 'draft', 'pending_sync', 'syncing', 'failed', 'synced'
  final String? lastError;
  final int retryCount;

  const ReportDraft({
    required this.id,
    required this.description,
    this.location,
    this.latitude,
    this.longitude,
    this.aiConsent = true,
    this.localAttachmentPaths = const [],
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'draft',
    this.lastError,
    this.retryCount = 0,
  });

  ReportDraft copyWith({
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    bool? aiConsent,
    List<String>? localAttachmentPaths,
    DateTime? updatedAt,
    String? syncStatus,
    String? lastError,
    int? retryCount,
  }) =>
      ReportDraft(
        id: id,
        description: description ?? this.description,
        location: location ?? this.location,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        aiConsent: aiConsent ?? this.aiConsent,
        localAttachmentPaths: localAttachmentPaths ?? this.localAttachmentPaths,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        syncStatus: syncStatus ?? this.syncStatus,
        lastError: lastError,
        retryCount: retryCount ?? this.retryCount,
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'description': description,
    'location': location,
    'latitude': latitude,
    'longitude': longitude,
    'ai_consent': aiConsent ? 1 : 0,
    'local_attachments': jsonEncode(localAttachmentPaths),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'sync_status': syncStatus,
    'last_error': lastError,
    'retry_count': retryCount,
  };

  factory ReportDraft.fromMap(Map<String, dynamic> map) => ReportDraft(
    id: map['id'] as String,
    description: map['description'] as String,
    location: map['location'] as String?,
    latitude: (map['latitude'] as num?)?.toDouble(),
    longitude: (map['longitude'] as num?)?.toDouble(),
    aiConsent: (map['ai_consent'] as int? ?? 1) == 1,
    localAttachmentPaths: map['local_attachments'] != null
        ? (jsonDecode(map['local_attachments'] as String) as List<dynamic>).map((e) => e as String).toList()
        : [],
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
    syncStatus: map['sync_status'] as String? ?? 'draft',
    lastError: map['last_error'] as String?,
    retryCount: map['retry_count'] as int? ?? 0,
  );
}
