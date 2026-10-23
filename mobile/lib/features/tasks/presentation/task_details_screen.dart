import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/sanket_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/data/auth_repository.dart';
import '../data/tasks_repository.dart';

class TaskDetailsScreen extends ConsumerStatefulWidget {
  final String taskId;
  const TaskDetailsScreen({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends ConsumerState<TaskDetailsScreen> {
  bool _isLoading = false;

  Future<void> _handleTransition(String newStatus, int currentVersion, {String? assignee}) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(tasksRepositoryProvider).transitionTask(
            taskId: widget.taskId,
            status: newStatus,
            assignee: assignee,
            version: currentVersion,
          );
      ref.invalidate(taskDetailsProvider(widget.taskId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task status updated to $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAssignDialog(int currentVersion) {
    final assigneeCtrl = TextEditingController(text: 'responder-team-alpha');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign Task to Responder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: assigneeCtrl,
              decoration: const InputDecoration(labelText: 'Assignee / Unit Name *'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (assigneeCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              _handleTransition('ASSIGNED', currentVersion, assignee: assigneeCtrl.text.trim());
            },
            child: const Text('Confirm Assignment'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskAsync = ref.watch(taskDetailsProvider(widget.taskId));
    final user = ref.watch(authStateProvider).valueOrNull?.user;
    final isCoordinator = user?.role == UserRole.coordinator || user?.role == UserRole.admin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Task Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(taskDetailsProvider(widget.taskId)),
          ),
        ],
      ),
      body: taskAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorState(
          message: err.toString(),
          onRetry: () => ref.refresh(taskDetailsProvider(widget.taskId)),
        ),
        data: (task) {
          final title = task['title'] as String? ?? 'Untitled Task';
          final description = task['description'] as String? ?? 'No instructions provided.';
          final status = task['status'] as String? ?? 'PROPOSED';
          final incidentTitle = task['incident_title'] as String? ?? 'Unknown Incident';
          final assignee = task['assignee'] as String?;
          final version = task['version'] as int? ?? 1;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            StatusBadge.fromStatus(status),
                            Text('v$version', style: const TextStyle(color: AppColors.textHint, fontFamily: 'monospace')),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text('Associated Incident: $incidentTitle', style: const TextStyle(color: AppColors.accent, fontSize: 13)),
                        const Divider(height: 24),
                        const Text('INSTRUCTIONS', style: TextStyle(color: AppColors.textHint, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(description, style: const TextStyle(fontSize: 14, height: 1.4)),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Assignee', style: TextStyle(color: AppColors.textSecondary)),
                            Text(assignee ?? 'Unassigned', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text('Operational Actions', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),

                // Transition buttons based on status
                if (status == 'PROPOSED' && isCoordinator) ...[
                  SanketButton(
                    text: 'Approve Task',
                    icon: Icons.check_circle_outline,
                    isLoading: _isLoading,
                    onPressed: () => _handleTransition('APPROVED', version),
                  ),
                  const SizedBox(height: 12),
                  SanketButton(
                    text: 'Cancel Task',
                    icon: Icons.cancel_outlined,
                    variant: ButtonVariant.destructive,
                    isLoading: _isLoading,
                    onPressed: () => _handleTransition('CANCELLED', version),
                  ),
                ] else if (status == 'APPROVED' && isCoordinator) ...[
                  SanketButton(
                    text: 'Assign to Field Unit',
                    icon: Icons.person_add_outlined,
                    isLoading: _isLoading,
                    onPressed: () => _showAssignDialog(version),
                  ),
                  const SizedBox(height: 12),
                  SanketButton(
                    text: 'Cancel Task',
                    icon: Icons.cancel_outlined,
                    variant: ButtonVariant.destructive,
                    isLoading: _isLoading,
                    onPressed: () => _handleTransition('CANCELLED', version),
                  ),
                ] else if (status == 'ASSIGNED') ...[
                  SanketButton(
                    text: 'Start Task (In Progress)',
                    icon: Icons.play_arrow,
                    isLoading: _isLoading,
                    onPressed: () => _handleTransition('IN_PROGRESS', version),
                  ),
                  if (isCoordinator) ...[
                    const SizedBox(height: 12),
                    SanketButton(
                      text: 'Cancel Task',
                      variant: ButtonVariant.destructive,
                      isLoading: _isLoading,
                      onPressed: () => _handleTransition('CANCELLED', version),
                    ),
                  ],
                ] else if (status == 'IN_PROGRESS') ...[
                  SanketButton(
                    text: 'Mark Task Completed',
                    icon: Icons.check_circle_outline,
                    isLoading: _isLoading,
                    onPressed: () => _handleTransition('COMPLETED', version),
                  ),
                  if (isCoordinator) ...[
                    const SizedBox(height: 12),
                    SanketButton(
                      text: 'Cancel Task',
                      variant: ButtonVariant.destructive,
                      isLoading: _isLoading,
                      onPressed: () => _handleTransition('CANCELLED', version),
                    ),
                  ],
                ] else if (status == 'COMPLETED') ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: AppColors.success),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This field task has been marked complete.',
                            style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (status == 'CANCELLED') ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.cancel, color: AppColors.error),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This field task was cancelled.',
                            style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
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
