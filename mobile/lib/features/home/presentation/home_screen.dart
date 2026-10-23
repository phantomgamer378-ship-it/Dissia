import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/route_paths.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/theme/app_theme.dart';

import '../../../shared/widgets/sanket_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/data/auth_repository.dart';
import '../../incidents/data/incidents_repository.dart';
import '../../reports/data/reports_repository.dart';
import '../../tasks/data/tasks_repository.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull?.user;
    final isOnline = ref.watch(isOnlineProvider);
    final incidentsAsync = ref.watch(incidentsListProvider);
    final tasksAsync = ref.watch(tasksListProvider);
    final reportsAsync = ref.watch(reportsListProvider(null));

    

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.emergency, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('SANKET AI', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          ],
        ),
        actions: [
          if (!isOnline)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning),
              ),
              child: const Row(
                children: [
                  Icon(Icons.wifi_off, size: 14, color: AppColors.warning),
                  SizedBox(width: 4),
                  Text('OFFLINE', style: TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => context.push(RoutePaths.notifications),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(incidentsListProvider);
          ref.invalidate(tasksListProvider);
          ref.invalidate(reportsListProvider(null));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User greeting banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.surfaceVariant,
                      AppColors.surfaceVariant.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Welcome, ${user?.displayName ?? user?.email ?? 'Operator'}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        StatusBadge.fromStatus(user?.role.value ?? 'PUBLIC'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI-assisted emergency ingestion, automated verification, and coordinated field operations.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    SanketButton(
                      text: 'Report New Emergency',
                      icon: Icons.campaign_rounded,
                      onPressed: () => context.push(RoutePaths.reportNew),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Operational Metric Cards
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'Incidents',
                      count: incidentsAsync.valueOrNull?.length.toString() ?? '...',
                      icon: Icons.crisis_alert,
                      color: AppColors.primary,
                      onTap: () => context.go(RoutePaths.incidents),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      label: 'Field Tasks',
                      count: tasksAsync.valueOrNull?.length.toString() ?? '...',
                      icon: Icons.assignment,
                      color: AppColors.warning,
                      onTap: () => context.go(RoutePaths.tasks),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      label: 'Reports',
                      count: reportsAsync.valueOrNull?.length.toString() ?? '...',
                      icon: Icons.description,
                      color: AppColors.accent,
                      onTap: () => context.go(RoutePaths.reports),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Actions Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Quick Operations', style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionTile(
                      title: 'Draft Reports',
                      subtitle: 'Local unsent records',
                      icon: Icons.drafts_outlined,
                      onTap: () => context.push(RoutePaths.reportDrafts),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionTile(
                      title: 'Sync Queue',
                      subtitle: 'Offline uploads',
                      icon: Icons.sync,
                      onTap: () => context.push(RoutePaths.reportSync),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recent Emergency Reports
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Reports', style: Theme.of(context).textTheme.titleLarge),
                  TextButton(
                    onPressed: () => context.go(RoutePaths.reports),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              reportsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Could not load reports: $e', style: const TextStyle(color: AppColors.error)),
                data: (reports) {
                  if (reports.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'No emergency reports received yet.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    );
                  }
                  final top3 = reports.take(3).toList();
                  return Column(
                    children: top3.map((r) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(r.description ?? 'Untitled report', maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(r.locationDescription ?? 'Unknown location'),
                          trailing: StatusBadge.fromStatus(r.status.value),
                          onTap: () => context.push(RoutePaths.reportDetailsFor(r.id)),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Active Tasks
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Assigned Tasks', style: Theme.of(context).textTheme.titleLarge),
                  TextButton(
                    onPressed: () => context.go(RoutePaths.tasks),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              tasksAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Could not load tasks: $e', style: const TextStyle(color: AppColors.error)),
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'No active field tasks.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    );
                  }
                  final top3 = tasks.take(3).toList();
                  return Column(
                    children: top3.map((t) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(t['title'] ?? 'Task', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Incident: ${t['incident_title'] ?? 'N/A'}'),
                          trailing: StatusBadge.fromStatus(t['status'] ?? 'PROPOSED'),
                          onTap: () => context.push(RoutePaths.taskDetailsFor(t['id'])),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MetricCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              count,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
