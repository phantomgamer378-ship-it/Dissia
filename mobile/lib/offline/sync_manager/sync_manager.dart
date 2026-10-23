import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../draft_store/draft_repository.dart';
import '../../features/reports/data/reports_repository.dart';

final syncManagerProvider = Provider<SyncManager>((ref) {
  final draftRepo = ref.watch(draftRepositoryProvider);
  final reportsRepo = ref.watch(reportsRepositoryProvider);
  return SyncManager(draftRepo, reportsRepo);
});

class SyncManager {
  final DraftRepository _draftRepo;
  final ReportsRepository _reportsRepo;
  bool _isSyncing = false;

  SyncManager(this._draftRepo, this._reportsRepo);

  bool get isSyncing => _isSyncing;

  Future<void> syncAll() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final drafts = await _draftRepo.getDrafts();
      final pending = drafts.where((d) => d.syncStatus == 'pending_sync' || d.syncStatus == 'failed');

      for (final draft in pending) {
        await syncDraft(draft.id);
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> syncDraft(String draftId) async {
    final drafts = await _draftRepo.getDrafts();
    final draft = drafts.firstWhere((d) => d.id == draftId, orElse: () => throw Exception('Draft not found'));

    await _draftRepo.updateSyncStatus(draftId, 'syncing');

    try {
      final result = await _reportsRepo.submitReport(
        description: draft.description,
        location: draft.location,
        aiConsent: draft.aiConsent,
        idempotencyKey: 'draft-${draft.id}',
      );

      if (result != null) {
        // Successfully submitted to server
        await _draftRepo.deleteDraft(draftId);
        return true;
      } else {
        await _draftRepo.updateSyncStatus(draftId, 'failed', error: 'Server did not return receipt');
        return false;
      }
    } catch (e) {
      await _draftRepo.updateSyncStatus(draftId, 'failed', error: e.toString());
      return false;
    }
  }
}
