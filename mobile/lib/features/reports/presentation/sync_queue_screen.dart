import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../offline/draft_store/draft_repository.dart';
import '../../../offline/sync_manager/sync_manager.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/sanket_button.dart';
import '../../../shared/widgets/status_badge.dart';

class SyncQueueScreen extends ConsumerStatefulWidget {
  const SyncQueueScreen({super.key});

  @override
  ConsumerState<SyncQueueScreen> createState() => _SyncQueueScreenState();
}

class _SyncQueueScreenState extends ConsumerState<SyncQueueScreen> {
  bool _isSyncing = false;

  Future<void> _handleSyncAll() async {
    setState(() => _isSyncing = true);
    try {
      await ref.read(syncManagerProvider).syncAll();
      ref.invalidate(draftsStreamProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Synchronization completed.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draftsAsync = ref.watch(draftsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sync Queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(draftsStreamProvider),
          ),
        ],
      ),
      body: draftsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (drafts) {
          final pending = drafts.where((d) => d.syncStatus != 'draft').toList();

          if (pending.isEmpty) {
            return const EmptyState(
              icon: Icons.cloud_done_outlined,
              title: 'All Reports Synced',
              message: 'No pending uploads in the offline queue.',
            );
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.surfaceVariant,
                child: Row(
                  children: [
                    const Icon(Icons.sync_problem, color: AppColors.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${pending.length} item(s) pending synchronization.',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: SanketButton(
                        text: 'Sync All',
                        isLoading: _isSyncing,
                        onPressed: _handleSyncAll,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: pending.length,
                  itemBuilder: (context, i) {
                    final item = pending[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                StatusBadge.fromStatus(item.syncStatus),
                                Text(
                                  'Retries: ${item.retryCount}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              item.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            if (item.lastError != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.lastError!,
                                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('Retry Now'),
                                  onPressed: () async {
                                    await ref.read(syncManagerProvider).syncDraft(item.id);
                                    ref.invalidate(draftsStreamProvider);
                                  },
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                                  label: const Text('Discard', style: TextStyle(color: AppColors.error)),
                                  onPressed: () async {
                                    await ref.read(draftRepositoryProvider).deleteDraft(item.id);
                                    ref.invalidate(draftsStreamProvider);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
