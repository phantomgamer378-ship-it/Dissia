import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/user_model.dart';

import '../../../shared/widgets/error_state.dart';

import '../../../shared/widgets/status_badge.dart';
import '../../auth/data/auth_repository.dart';
import '../data/incidents_repository.dart';

class IncidentDetailsScreen extends ConsumerStatefulWidget {
  final String incidentId;
  const IncidentDetailsScreen({super.key, required this.incidentId});

  @override
  ConsumerState<IncidentDetailsScreen> createState() => _IncidentDetailsScreenState();
}

class _IncidentDetailsScreenState extends ConsumerState<IncidentDetailsScreen> {
  void _showAddTaskDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Propose Field Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Task Title *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Instructions / Details'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                await ref.read(incidentsRepositoryProvider).createTask(
                      widget.incidentId,
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                    );
                ref.invalidate(incidentDetailsProvider(widget.incidentId));
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Create Task'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final incidentAsync = ref.watch(incidentDetailsProvider(widget.incidentId));
    final user = ref.watch(authStateProvider).valueOrNull?.user;
    final isCoordinator = user?.role == UserRole.coordinator || user?.role == UserRole.admin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Incident Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(incidentDetailsProvider(widget.incidentId)),
          ),
        ],
      ),
      body: incidentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorState(
          message: err.toString(),
          onRetry: () => ref.refresh(incidentDetailsProvider(widget.incidentId)),
        ),
        data: (data) {
          final title = data['title'] as String? ?? 'Untitled Incident';
          final summary = data['summary'] as String? ?? 'No operational summary';
          final location = data['location'] as String? ?? 'No location';
          final status = data['status'] as String? ?? 'OPEN';
          final reports = (data['reports'] as List<dynamic>?) ?? [];
          final tasks = (data['tasks'] as List<dynamic>?) ?? [];

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
                            Text(
                              data['created_at'] != null
                                  ? data['created_at'].toString().substring(0, 16)
                                  : '',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(summary, style: const TextStyle(fontSize: 14, height: 1.4)),
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Expanded(child: Text(location, style: const TextStyle(fontSize: 14))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Associated Reports
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Linked Reports (${reports.length})', style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
                const SizedBox(height: 8),
                if (reports.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No reports linked to this incident yet.', style: TextStyle(color: AppColors.textSecondary)),
                  )
                else
                  ...reports.map((r) {
                    final rep = r as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.description_outlined, color: AppColors.accent),
                        title: Text(rep['description'] ?? 'No text', maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(rep['location'] ?? 'No location'),
                        trailing: StatusBadge.fromStatus(rep['state'] ?? 'CONFIRMED'),
                        onTap: () => context.push(RoutePaths.reportDetailsFor(rep['id'])),
                      ),
                    );
                  }),
                const SizedBox(height: 20),

                // Associated Tasks
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Response Tasks (${tasks.length})', style: Theme.of(context).textTheme.titleLarge),
                    if (isCoordinator)
                      TextButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Task'),
                        onPressed: _showAddTaskDialog,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (tasks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No response tasks assigned yet.', style: TextStyle(color: AppColors.textSecondary)),
                  )
                else
                  ...tasks.map((t) {
                    final task = t as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.task_alt, color: AppColors.warning),
                        title: Text(task['title'] ?? 'Task', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Assignee: ${task['assignee'] ?? 'Unassigned'}'),
                        trailing: StatusBadge.fromStatus(task['status'] ?? 'PROPOSED'),
                        onTap: () => context.push(RoutePaths.taskDetailsFor(task['id'])),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}
