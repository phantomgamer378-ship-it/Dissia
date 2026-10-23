import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/empty_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alerts = [
      {
        'title': 'High Priority Report Ingested',
        'body': 'Emergency report received for Sector 12 flood barrier breach.',
        'time': '10 mins ago',
        'isUnread': true,
      },
      {
        'title': 'Task Assigned',
        'body': 'You have been assigned to Field Reconnaissance Unit Alpha.',
        'time': '1 hour ago',
        'isUnread': false,
      },
      {
        'title': 'Incident Status Changed',
        'body': 'Incident "Bridge 4 Waterlogging" moved to ACTIVE.',
        'time': '3 hours ago',
        'isUnread': false,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: alerts.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'No Notifications',
              message: 'You have no pending operational alerts.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final alert = alerts[i];
                final isUnread = alert['isUnread'] as bool;

                return Card(
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isUnread ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.crisis_alert,
                        color: isUnread ? AppColors.primary : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      alert['title'] as String,
                      style: TextStyle(
                        fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(alert['body'] as String),
                        const SizedBox(height: 4),
                        Text(
                          alert['time'] as String,
                          style: TextStyle(color: AppColors.textHint, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
