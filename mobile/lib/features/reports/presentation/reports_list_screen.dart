import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/status_badge.dart';
import '../data/reports_repository.dart';

class ReportsListScreen extends ConsumerStatefulWidget {
  const ReportsListScreen({super.key});

  @override
  ConsumerState<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends ConsumerState<ReportsListScreen> {
  String? _selectedStatus;

  final _statuses = const [
    {'label': 'All', 'value': null},
    {'label': 'Queued', 'value': 'QUEUED'},
    {'label': 'Processing', 'value': 'PROCESSING'},
    {'label': 'Extracted', 'value': 'EXTRACTED'},
    {'label': 'Failed', 'value': 'FAILED'},
  ];

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(reportsListProvider(_selectedStatus));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Emergency Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.drafts_outlined),
            tooltip: 'Drafts',
            onPressed: () => context.push(RoutePaths.reportDrafts),
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync Queue',
            onPressed: () => context.push(RoutePaths.reportSync),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _statuses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final item = _statuses[i];
                final isSelected = _selectedStatus == item['value'];
                return ChoiceChip(
                  label: Text(item['label']!),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      _selectedStatus = item['value'];
                    });
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: reportsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => ErrorState(
                message: err.toString(),
                onRetry: () => ref.refresh(reportsListProvider(_selectedStatus)),
              ),
              data: (reports) {
                if (reports.isEmpty) {
                  return EmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'No Reports Found',
                    message: _selectedStatus == null
                        ? 'No emergency reports submitted yet.'
                        : 'No reports matching this filter.',
                    actionLabel: 'Submit Report',
                    onAction: () => context.push(RoutePaths.reportNew),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(reportsListProvider(_selectedStatus)),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => context.push(RoutePaths.reportDetailsFor(report.id)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    StatusBadge.fromStatus(report.status.value),
                                    Text(
                                      'ID: ${report.id.substring(0, 8)}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  report.description ?? 'No description provided',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                if (report.locationDescription != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          report.locationDescription!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Received: ${report.submittedAt.toLocal().toString().substring(0, 16)}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textHint),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alert),
        label: const Text('Report Emergency'),
        onPressed: () => context.push(RoutePaths.reportNew),
      ),
    );
  }
}
