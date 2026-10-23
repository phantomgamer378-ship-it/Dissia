import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/status_badge.dart';
import '../data/tasks_repository.dart';

class TasksListScreen extends ConsumerStatefulWidget {
  const TasksListScreen({super.key});

  @override
  ConsumerState<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends ConsumerState<TasksListScreen> {
  String? _selectedFilter;

  final _filters = const [
    {'label': 'All Tasks', 'value': null},
    {'label': 'Proposed', 'value': 'PROPOSED'},
    {'label': 'Assigned', 'value': 'ASSIGNED'},
    {'label': 'In Progress', 'value': 'IN_PROGRESS'},
    {'label': 'Completed', 'value': 'COMPLETED'},
  ];

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Field Response Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(tasksListProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final item = _filters[i];
                final isSelected = _selectedFilter == item['value'];
                return ChoiceChip(
                  label: Text(item['label']!),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() => _selectedFilter = item['value']);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: tasksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => ErrorState(
                message: err.toString(),
                onRetry: () => ref.refresh(tasksListProvider),
              ),
              data: (tasks) {
                final filtered = tasks.where((t) {
                  if (_selectedFilter == null) return true;
                  return t['status'] == _selectedFilter;
                }).toList();

                if (filtered.isEmpty) {
                  return const EmptyState(
                    icon: Icons.assignment_turned_in_outlined,
                    title: 'No Tasks Assigned',
                    message: 'There are no active field response tasks matching this filter.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(tasksListProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final task = filtered[i];
                      final status = task['status'] as String? ?? 'PROPOSED';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => context.push(RoutePaths.taskDetailsFor(task['id'])),
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
                                      'Incident: ${task['incident_title'] ?? 'N/A'}',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppColors.accent,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  task['title'] ?? 'Untitled Task',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                if (task['description'] != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    task['description']!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.person_outline, size: 14, color: AppColors.textHint),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Assignee: ${task['assignee'] ?? 'Unassigned'}',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
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
    );
  }
}
