import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_palette.dart';

class GradientCircularProgress extends StatelessWidget {
  const GradientCircularProgress({
    super.key,
    required this.value,
    this.size = 160,
    this.strokeWidth = 10,
  });

  final double value; // 0..1
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0).toDouble();
    return CustomPaint(
      size: Size.square(size),
      painter: _GradientRingPainter(
        value: clamped,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _GradientRingPainter extends CustomPainter {
  const _GradientRingPainter({
    required this.value,
    required this.strokeWidth,
  });

  final double value;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final backgroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withOpacity(0.10);

    canvas.drawArc(rect, 0, math.pi * 2, false, backgroundPaint);

    if (value <= 0) return;

    final sweepGradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: (math.pi * 2) - (math.pi / 2),
      colors: const [
        AppPalette.primaryA,
        AppPalette.primaryB,
        AppPalette.primaryA,
      ],
      stops: const [0.0, 0.55, 1.0],
    );

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = sweepGradient.createShader(rect);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      (math.pi * 2) * value,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GradientRingPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.strokeWidth != strokeWidth;
  }
}
