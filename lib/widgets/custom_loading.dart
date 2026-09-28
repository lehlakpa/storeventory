import 'package:flutter/material.dart';

import '../core/constants/app_assets.dart';

class CustomLoading extends StatelessWidget {
  const CustomLoading({super.key, this.message = 'Loading…'});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          AppAssets.onboardingGrowth,
          height: 110,
          excludeFromSemantics: true,
        ),
        const SizedBox(height: 16),
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
        const SizedBox(height: 12),
        Text(message),
      ],
    ),
  );
}
