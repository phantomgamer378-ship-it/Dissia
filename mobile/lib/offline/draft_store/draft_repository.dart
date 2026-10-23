import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'draft_model.dart';

final draftRepositoryProvider = Provider<DraftRepository>((ref) {
  return DraftRepository();
});

final draftsStreamProvider = StreamProvider<List<ReportDraft>>((ref) {
  final repo = ref.watch(draftRepositoryProvider);
  return repo.watchDrafts();
});

class DraftRepository {
  final _storage = const FlutterSecureStorage();
  static const _storageKey = 'sanket_report_drafts';

  Future<List<ReportDraft>> getDrafts() async {
    final raw = await _storage.read(key: _storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => ReportDraft.fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Stream<List<ReportDraft>> watchDrafts() async* {
    yield await getDrafts();
  }

  Future<void> saveDraft(ReportDraft draft) async {
    final current = await getDrafts();
    final index = current.indexWhere((d) => d.id == draft.id);
    if (index >= 0) {
      current[index] = draft;
    } else {
      current.add(draft);
    }
    await _saveAll(current);
  }

  Future<void> deleteDraft(String id) async {
    final current = await getDrafts();
    current.removeWhere((d) => d.id == id);
    await _saveAll(current);
  }

  Future<void> updateSyncStatus(String id, String status, {String? error}) async {
    final current = await getDrafts();
    final index = current.indexWhere((d) => d.id == id);
    if (index >= 0) {
      final existing = current[index];
      current[index] = existing.copyWith(
        syncStatus: status,
        lastError: error,
        retryCount: status == 'failed' ? existing.retryCount + 1 : existing.retryCount,
        updatedAt: DateTime.now(),
      );
      await _saveAll(current);
    }
  }

  Future<void> _saveAll(List<ReportDraft> drafts) async {
    final jsonStr = jsonEncode(drafts.map((d) => d.toMap()).toList());
    await _storage.write(key: _storageKey, value: jsonStr);
  }
}
