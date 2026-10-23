import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/report_model.dart';

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ReportsRepository(client);
});

final reportsListProvider = FutureProvider.family<List<ReportModel>, String?>((ref, status) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.listReports(status: status);
});

final reportDetailsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.getReport(id);
});

class ReportsRepository {
  final ApiClient _client;

  ReportsRepository(this._client);

  Future<Map<String, dynamic>?> submitReport({
    required String description,
    String? location,
    bool aiConsent = true,
    String? idempotencyKey,
  }) async {
    final options = Options(
      headers: idempotencyKey != null ? {'Idempotency-Key': idempotencyKey} : null,
    );

    final res = await _client.dio.post(
      '/api/v1/reports',
      data: {
        'description': description,
        'location': location,
        'ai_consent': aiConsent,
      },
      options: options,
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      return res.data as Map<String, dynamic>;
    }
    return null;
  }

  Future<List<ReportModel>> listReports({String? status, int limit = 50, int offset = 0}) async {
    final params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (status != null && status.isNotEmpty) {
      params['status'] = status;
    }

    final res = await _client.get('/api/v1/reports', params: params);
    if (res.statusCode == 200 && res.data != null) {
      final items = (res.data['items'] as List<dynamic>?) ?? [];
      return items.map((e) {
        final m = e as Map<String, dynamic>;
        return ReportModel(
          id: m['id'] as String,
          description: m['description'] as String?,
          locationDescription: m['location'] as String?,
          status: ReportStatus.fromString(m['status'] as String? ?? 'pending'),
          processingState: ProcessingState.fromString(m['status'] as String? ?? 'queued'),
          submitterId: 'citizen',
          submittedAt: DateTime.parse(m['received_at'] as String),
          aiSummary: m['extraction'] != null ? (m['extraction']['summary'] as String?) : null,
        );
      }).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> getReport(String id) async {
    final res = await _client.get('/api/v1/reports/$id');
    if (res.statusCode == 200 && res.data != null) {
      return res.data as Map<String, dynamic>;
    }
    throw Exception('Failed to load report details');
  }

  Future<Map<String, dynamic>> getReceipt(String id) async {
    final res = await _client.get('/api/v1/reports/$id/receipt');
    if (res.statusCode == 200 && res.data != null) {
      return res.data as Map<String, dynamic>;
    }
    throw Exception('Failed to load receipt');
  }

  Future<void> retryReport(String id) async {
    await _client.post('/api/v1/reports/$id/retry');
  }

  Future<void> reviewReport(String id) async {
    await _client.post('/api/v1/reports/$id/review');
  }

  Future<List<Map<String, dynamic>>> getMatches(String id) async {
    final res = await _client.get('/api/v1/reports/$id/matches');
    if (res.statusCode == 200 && res.data != null) {
      final items = (res.data['items'] as List<dynamic>?) ?? [];
      return items.cast<Map<String, dynamic>>();
    }
    return [];
  }
}
