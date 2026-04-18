import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 28,
    this.borderRadius = 10,
  });

  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        'assets/images/logo.png',
        height: size,
        width: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

