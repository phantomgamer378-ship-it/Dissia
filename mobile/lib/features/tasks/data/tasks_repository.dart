import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return TasksRepository(client);
});

final tasksListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(tasksRepositoryProvider);
  return repo.listTasks();
});

final taskDetailsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final repo = ref.watch(tasksRepositoryProvider);
  return repo.getTask(id);
});

class TasksRepository {
  final ApiClient _client;

  TasksRepository(this._client);

  Future<List<Map<String, dynamic>>> listTasks() async {
    final res = await _client.get('/api/v1/tasks');
    if (res.statusCode == 200 && res.data != null) {
      final items = (res.data['items'] as List<dynamic>?) ?? [];
      return items.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<Map<String, dynamic>> getTask(String id) async {
    final res = await _client.get('/api/v1/tasks/$id');
    if (res.statusCode == 200 && res.data != null) {
      return res.data as Map<String, dynamic>;
    }
    throw Exception('Failed to load task details');
  }

  Future<Map<String, dynamic>> transitionTask({
    required String taskId,
    required String status,
    String? assignee,
    required int version,
  }) async {
    final res = await _client.patch(
      '/api/v1/tasks/$taskId',
      data: {
        'status': status,
        'assignee': assignee,
        'version': version,
      },
    );
    if (res.statusCode == 200 && res.data != null) {
      return res.data as Map<String, dynamic>;
    }
    throw Exception('Failed to update task');
  }
}
