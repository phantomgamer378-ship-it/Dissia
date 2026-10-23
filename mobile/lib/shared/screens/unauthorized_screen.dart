import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/route_paths.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/sanket_button.dart';

class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_person_outlined, size: 64, color: AppColors.error),
              ),
              const SizedBox(height: 24),
              Text(
                'Access Restricted',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'Your account does not possess the permissions required to access this resource or is currently pending coordinator approval.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SanketButton(
                text: 'Return Home',
                onPressed: () => context.go(RoutePaths.home),
                variant: ButtonVariant.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
