import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/incident_model.dart';

final incidentsRepositoryProvider = Provider<IncidentsRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return IncidentsRepository(client);
});

final incidentsListProvider = FutureProvider<List<IncidentModel>>((ref) async {
  final repo = ref.watch(incidentsRepositoryProvider);
  return repo.listIncidents();
});

final incidentDetailsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final repo = ref.watch(incidentsRepositoryProvider);
  return repo.getIncident(id);
});

class IncidentsRepository {
  final ApiClient _client;

  IncidentsRepository(this._client);

  Future<List<IncidentModel>> listIncidents() async {
    final res = await _client.get('/api/v1/incidents');
    if (res.statusCode == 200 && res.data != null) {
      final items = (res.data['items'] as List<dynamic>?) ?? [];
      return items.map((e) {
        final m = e as Map<String, dynamic>;
        return IncidentModel(
          id: m['id'] as String,
          title: m['title'] as String,
          description: m['summary'] as String?,
          status: IncidentStatus.fromString(m['status'] as String? ?? 'open'),
          severity: IncidentSeverity.fromString(m['severity'] as String? ?? 'medium'),
          locationDescription: m['location'] as String?,
          createdAt: DateTime.parse(m['created_at'] as String),
          updatedAt: DateTime.parse(m['created_at'] as String),
        );
      }).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> getIncident(String id) async {
    final res = await _client.get('/api/v1/incidents/$id');
    if (res.statusCode == 200 && res.data != null) {
      return res.data as Map<String, dynamic>;
    }
    throw Exception('Failed to load incident details');
  }

  Future<void> createIncident({
    required String title,
    String? summary,
    String? location,
    String? reportId,
  }) async {
    await _client.post(
      '/api/v1/incidents',
      data: {
        'title': title,
        'summary': summary,
        'location': location,
        'report_id': reportId,
      },
    );
  }

  Future<void> createTask(String incidentId, {required String title, String? description}) async {
    await _client.post(
      '/api/v1/incidents/$incidentId/tasks',
      data: {
        'title': title,
        'description': description,
      },
    );
  }

  Future<void> decideAssociation(String incidentId, String reportId, String state) async {
    await _client.post(
      '/api/v1/incidents/$incidentId/associations',
      data: {
        'report_id': reportId,
        'state': state,
      },
    );
  }
}
