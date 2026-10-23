import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../../../offline/draft_store/draft_repository.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/sanket_button.dart';

class DraftsScreen extends ConsumerWidget {
  const DraftsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draftsAsync = ref.watch(draftsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Saved Drafts'),
      ),
      body: draftsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading drafts: $err')),
        data: (drafts) {
          final localDrafts = drafts.where((d) => d.syncStatus == 'draft').toList();

          if (localDrafts.isEmpty) {
            return EmptyState(
              icon: Icons.drafts_outlined,
              title: 'No Saved Drafts',
              message: 'Reports saved while composing or offline will appear here.',
              actionLabel: 'Create New Report',
              onAction: () => context.push(RoutePaths.reportNew),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: localDrafts.length,
            itemBuilder: (context, index) {
              final draft = localDrafts[index];
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
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.divider,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('DRAFT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          Text(
                            draft.updatedAt.toLocal().toString().substring(0, 16),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        draft.description.isEmpty ? 'Untitled draft' : draft.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      if (draft.location != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          draft.location!,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: SanketButton(
                              text: 'Submit Online',
                              icon: Icons.cloud_upload_outlined,
                              onPressed: () async {
                                await ref.read(draftRepositoryProvider).updateSyncStatus(draft.id, 'pending_sync');
                                if (context.mounted) {
                                  context.push(RoutePaths.reportSync);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.error),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Discard Draft?'),
                                  content: const Text('Are you sure you want to delete this unsaved draft?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Discard', style: TextStyle(color: AppColors.error))),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await ref.read(draftRepositoryProvider).deleteDraft(draft.id);
                                ref.invalidate(draftsStreamProvider);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
