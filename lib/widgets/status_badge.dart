import 'package:flutter/material.dart';

import '../core/constants/app_sizes.dart';

import '../core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final good = ['in stock', 'paid'].contains(status.toLowerCase());
    final warning = ['low stock', 'pending'].contains(status.toLowerCase());
    final foreground = good
        ? AppColors.success
        : warning
        ? AppColors.warning
        : AppColors.danger;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: good
            ? AppColors.successBackground
            : warning
            ? AppColors.warningBackground
            : AppColors.dangerBackground,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 10, color: foreground),
          const SizedBox(width: AppSizes.xs),
          Text(
            status,
            style: TextStyle(
              color: foreground,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
