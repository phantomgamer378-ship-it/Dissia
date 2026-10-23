import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';

import '../../../shared/widgets/status_badge.dart';
import '../../auth/data/auth_repository.dart';
import '../data/incidents_repository.dart';

class IncidentsListScreen extends ConsumerStatefulWidget {
  const IncidentsListScreen({super.key});

  @override
  ConsumerState<IncidentsListScreen> createState() => _IncidentsListScreenState();
}

class _IncidentsListScreenState extends ConsumerState<IncidentsListScreen> {
  final _searchCtrl = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showCreateIncidentDialog() {
    final titleCtrl = TextEditingController();
    final summaryCtrl = TextEditingController();
    final locCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Incident'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Incident Title *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: summaryCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Operational Summary'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locCtrl,
                decoration: const InputDecoration(labelText: 'Location / Zone'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              try {
                await ref.read(incidentsRepositoryProvider).createIncident(
                      title: titleCtrl.text.trim(),
                      summary: summaryCtrl.text.trim().isEmpty ? null : summaryCtrl.text.trim(),
                      location: locCtrl.text.trim().isEmpty ? null : locCtrl.text.trim(),
                    );
                ref.invalidate(incidentsListProvider);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final incidentsAsync = ref.watch(incidentsListProvider);
    final user = ref.watch(authStateProvider).valueOrNull?.user;
    final isCoordinator = user?.role == UserRole.coordinator || user?.role == UserRole.admin;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Operational Incidents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(incidentsListProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search incidents by title or location...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _filter.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _filter = '');
                        },
                      )
                    : null,
              ),
              onChanged: (val) => setState(() => _filter = val.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: incidentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => ErrorState(
                message: err.toString(),
                onRetry: () => ref.refresh(incidentsListProvider),
              ),
              data: (incidents) {
                final filtered = incidents.where((inc) {
                  if (_filter.isEmpty) return true;
                  return inc.title.toLowerCase().contains(_filter) ||
                      (inc.locationDescription?.toLowerCase().contains(_filter) ?? false);
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.crisis_alert_outlined,
                    title: 'No Incidents Found',
                    message: _filter.isEmpty
                        ? 'There are currently no active operational incidents.'
                        : 'No incidents match your search query.',
                    actionLabel: isCoordinator ? 'Create Incident' : null,
                    onAction: isCoordinator ? _showCreateIncidentDialog : null,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(incidentsListProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final inc = filtered[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => context.push(RoutePaths.incidentDetailsFor(inc.id)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    StatusBadge.fromStatus(inc.status.value),
                                    Text(
                                      inc.createdAt.toLocal().toString().substring(0, 16),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  inc.title,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                if (inc.description != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    inc.description!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                  ),
                                ],
                                if (inc.locationDescription != null) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          inc.locationDescription!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
      floatingActionButton: isCoordinator
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('New Incident'),
              onPressed: _showCreateIncidentDialog,
            )
          : null,
    );
  }
}
