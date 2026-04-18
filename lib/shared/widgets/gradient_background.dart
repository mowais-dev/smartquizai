import 'package:flutter/material.dart';

import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_palette.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({
    super.key,
    required this.child,
    this.gradient = AppGradients.deepPurpleToBlue,
    this.padding = EdgeInsets.zero,
    this.addGlows = true,
  });

  final Widget child;
  final LinearGradient gradient;
  final EdgeInsets padding;
  final bool addGlows;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(gradient: gradient),
          child: const SizedBox.expand(),
        ),
        // Subtle dark overlay for contrast/readability.
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppPalette.background.withOpacity(0.55),
          ),
          child: const SizedBox.expand(),
        ),
        if (addGlows) ...[
          Positioned(
            top: -120,
            left: -80,
            child: _Glow(
              color: AppPalette.glowPurple.withOpacity(0.28),
              size: 320,
            ),
          ),
          Positioned(
            bottom: -140,
            right: -90,
            child: _Glow(
              color: AppPalette.glowBlue.withOpacity(0.22),
              size: 360,
            ),
          ),
        ],
        Padding(padding: padding, child: child),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: 80,
              spreadRadius: 20,
            ),
          ],
        ),
      ),
    );
  }
}

