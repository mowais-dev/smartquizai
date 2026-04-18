import 'package:flutter/material.dart';

import 'glass_container.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 16),
    this.onTap,
    this.elevation,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final VoidCallback? onTap;
  final double? elevation;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      margin: margin,
      padding: padding,
      borderRadius: borderRadius ?? 16,
      onTap: onTap,
      child: child,
    );
  }
}
