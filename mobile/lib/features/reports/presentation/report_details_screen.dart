import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../core/theme/app_theme.dart';
import '../../../shared/models/user_model.dart';

import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/sanket_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/data/auth_repository.dart';
import '../data/reports_repository.dart';

class ReportDetailsScreen extends ConsumerStatefulWidget {
  final String reportId;
  const ReportDetailsScreen({super.key, required this.reportId});

  @override
  ConsumerState<ReportDetailsScreen> createState() => _ReportDetailsScreenState();
}

class _ReportDetailsScreenState extends ConsumerState<ReportDetailsScreen> {
  bool _isActionLoading = false;

  Future<void> _handleReview() async {
    setState(() => _isActionLoading = true);
    try {
      await ref.read(reportsRepositoryProvider).reviewReport(widget.reportId);
      ref.invalidate(reportDetailsProvider(widget.reportId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report marked as reviewed by coordinator.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Review failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _handleRetry() async {
    setState(() => _isActionLoading = true);
    try {
      await ref.read(reportsRepositoryProvider).retryReport(widget.reportId);
      ref.invalidate(reportDetailsProvider(widget.reportId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Extraction job re-queued for processing.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Retry failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(reportDetailsProvider(widget.reportId));
    final user = ref.watch(authStateProvider).valueOrNull?.user;
    final isCoordinator = user?.role == UserRole.coordinator || user?.role == UserRole.admin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Report Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(reportDetailsProvider(widget.reportId)),
          ),
        ],
      ),
      body: reportAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => ErrorState(
          message: err.toString(),
          onRetry: () => ref.refresh(reportDetailsProvider(widget.reportId)),
        ),
        data: (data) {
          final description = data['description'] as String? ?? 'No description provided';
          final location = data['location'] as String? ?? 'No location provided';
          final status = data['status'] as String? ?? 'QUEUED';
          final urgency = data['urgency'] as String? ?? 'UNKNOWN';
          final reviewed = data['reviewed'] == true || data['reviewed'] == 1;
          final extraction = data['extraction'] as Map<String, dynamic>?;
          final metadata = data['processing_metadata'] as Map<String, dynamic>?;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header status card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            StatusBadge.fromStatus(status),
                            if (reviewed)
                              const Row(
                                children: [
                                  Icon(Icons.verified, size: 16, color: AppColors.accent),
                                  SizedBox(width: 4),
                                  Text(
                                    'HUMAN REVIEWED',
                                    style: TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Urgency Rating', style: TextStyle(color: AppColors.textSecondary)),
                            Text(
                              urgency,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: urgency == 'HIGH' || urgency == 'CRITICAL'
                                    ? AppColors.error
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Report ID', style: TextStyle(color: AppColors.textSecondary)),
                            Text(
                              widget.reportId.substring(0, 8),
                              style: const TextStyle(fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Original submitted data
                Text('Submitted Observation', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(description, style: const TextStyle(fontSize: 15, height: 1.4)),
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                location,
                                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // AI Extraction section
                Text('AI Extraction & Synthesis', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                const Text(
                  'AI proposals require human verification before operational deployment.',
                  style: TextStyle(color: AppColors.textHint, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: extraction != null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (extraction['summary'] != null) ...[
                                const Text('SUMMARY', style: TextStyle(color: AppColors.textHint, fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(extraction['summary'] as String, style: const TextStyle(fontSize: 14)),
                                const Divider(height: 24),
                              ],
                              if (extraction['hazards'] != null) ...[
                                const Text('HAZARDS DETECTED', style: TextStyle(color: AppColors.textHint, fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(extraction['hazards'].toString(), style: const TextStyle(fontSize: 14)),
                                const Divider(height: 24),
                              ],
                              if (metadata != null) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Model', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                    Text(metadata['model'] ?? 'Heuristic / Gemini', style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ],
                            ],
                          )
                        : const Text(
                            'No extraction generated yet. Report is awaiting processing worker.',
                            style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Coordinator actions
                if (isCoordinator) ...[
                  Text('Coordinator Controls', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  if (!reviewed)
                    SanketButton(
                      text: 'Confirm Human Review',
                      icon: Icons.verified_user_outlined,
                      isLoading: _isActionLoading,
                      onPressed: _handleReview,
                    ),
                  const SizedBox(height: 12),
                  SanketButton(
                    text: 'Retry AI Extraction',
                    icon: Icons.refresh,
                    variant: ButtonVariant.secondary,
                    isLoading: _isActionLoading,
                    onPressed: _handleRetry,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
