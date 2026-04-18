import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.borderRadius = 16,
    this.blurSigma = 18,
    this.tint,
    this.borderOpacity,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final VoidCallback? onTap;
  final double borderRadius;
  final double blurSigma;
  final Color? tint;
  final double? borderOpacity;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundTint = tint ??
        (isDark
            ? Colors.white.withOpacity(0.06)
            : AppPalette.background.withOpacity(0.06));

    final borderColor = Colors.white.withOpacity(
      borderOpacity ?? (isDark ? 0.12 : 0.10),
    );

    final content = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: backgroundTint,
            borderRadius: radius,
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.10),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    final wrapped = Material(
      color: Colors.transparent,
      child: onTap == null
          ? content
          : InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: content,
            ),
    );

    if (margin == EdgeInsets.zero) return wrapped;
    return Padding(padding: margin, child: wrapped);
  }
}

