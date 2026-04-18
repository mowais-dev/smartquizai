import 'package:flutter/material.dart';

import '../../core/theme/app_gradients.dart';

class GradientProgressBar extends StatelessWidget {
  const GradientProgressBar({
    super.key,
    required this.value,
    this.height = 10,
    this.borderRadius = 999,
  });

  final double value; // 0..1
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.35),
                ),
              ),
            ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clamped,
              child: const DecoratedBox(
                decoration: BoxDecoration(gradient: AppGradients.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

