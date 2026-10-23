import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    this.color,
    this.icon,
  });

  factory StatusBadge.fromStatus(String status) {
    final s = status.toUpperCase();
    Color c;
    IconData ic;

    switch (s) {
      case 'QUEUED':
      case 'PENDING':
        c = AppColors.warning;
        ic = Icons.schedule;
        break;
      case 'PROCESSING':
      case 'IN_PROGRESS':
        c = AppColors.info;
        ic = Icons.autorenew;
        break;
      case 'EXTRACTED':
      case 'COMPLETED':
      case 'RESOLVED':
        c = AppColors.success;
        ic = Icons.check_circle_outline;
        break;
      case 'FAILED':
      case 'CANCELLED':
        c = AppColors.error;
        ic = Icons.error_outline;
        break;
      case 'REVIEWED':
      case 'CONFIRMED':
        c = AppColors.accent;
        ic = Icons.verified_outlined;
        break;
      default:
        c = AppColors.textSecondary;
        ic = Icons.info_outline;
    }

    return StatusBadge(label: status, color: c, icon: ic);
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: badgeColor),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: badgeColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
