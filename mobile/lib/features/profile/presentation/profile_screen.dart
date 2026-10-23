import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/route_paths.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/sanket_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/data/auth_repository.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull?.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Operator Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(RoutePaths.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.surfaceVariant,
                    child: Text(
                      user?.initials ?? 'OP',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.displayName ?? 'Field Operator',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? 'operator@sanket.ai',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            StatusBadge.fromStatus(user?.role.value ?? 'PUBLIC'),
            const SizedBox(height: 32),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('App Settings'),
                    subtitle: const Text('Language, Theme, Notifications'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => context.push(RoutePaths.settings),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.drafts_outlined),
                    title: const Text('Offline Drafts'),
                    subtitle: const Text('Manage unsent emergency submissions'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => context.push(RoutePaths.reportDrafts),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.sync),
                    title: const Text('Sync Queue'),
                    subtitle: const Text('View queued submissions'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => context.push(RoutePaths.reportSync),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            SanketButton(
              text: 'Sign Out',
              icon: Icons.logout,
              variant: ButtonVariant.destructive,
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out of SANKET AI?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(authStateProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go(RoutePaths.login);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
