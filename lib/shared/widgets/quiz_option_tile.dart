import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../core/theme/app_palette.dart';

class QuizOptionTile extends StatefulWidget {
  const QuizOptionTile({
    super.key,
    required this.option,
    required this.isSelected,
    required this.isCorrect,
    required this.isAnswered,
    required this.onTap,
  });

  final String option;
  final bool isSelected;
  final bool isCorrect;
  final bool isAnswered;
  final VoidCallback onTap;

  @override
  State<QuizOptionTile> createState() => _QuizOptionTileState();
}

class _QuizOptionTileState extends State<QuizOptionTile>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _shakeController;

  bool get _shouldShake => widget.isAnswered && widget.isSelected && !widget.isCorrect;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void didUpdateWidget(covariant QuizOptionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasShaking = oldWidget.isAnswered &&
        oldWidget.isSelected &&
        !oldWidget.isCorrect;
    if (!wasShaking && _shouldShake) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    IconData? icon;
    Color iconColor;

    if (!widget.isAnswered) {
      // Not answered yet
      backgroundColor = widget.isSelected
          ? Colors.white.withOpacity(0.08)
          : AppPalette.surface.withOpacity(0.60);
      borderColor = widget.isSelected
          ? AppPalette.primaryB.withOpacity(0.85)
          : AppPalette.outline.withOpacity(0.9);
      icon = null;
      iconColor = Colors.transparent;
    } else {
      // Answered
      if (widget.isCorrect) {
        backgroundColor = AppPalette.success.withOpacity(0.14);
        borderColor = AppPalette.success.withOpacity(0.85);
        icon = Icons.check_circle;
        iconColor = AppPalette.success;
      } else if (widget.isSelected && !widget.isCorrect) {
        backgroundColor = AppPalette.error.withOpacity(0.14);
        borderColor = AppPalette.error.withOpacity(0.90);
        icon = Icons.cancel;
        iconColor = AppPalette.error;
      } else {
        backgroundColor = AppPalette.surface.withOpacity(0.60);
        borderColor = AppPalette.outline.withOpacity(0.9);
        icon = null;
        iconColor = Colors.transparent;
      }
    }

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 1.2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: widget.isSelected
            ? [
                BoxShadow(
                  color: AppPalette.primaryB.withOpacity(0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isAnswered ? null : widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            scale: _pressed && !widget.isAnswered ? 0.985 : 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.option,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.3,
                            color: widget.isAnswered && widget.isCorrect
                                ? AppPalette.success
                                : widget.isAnswered &&
                                        widget.isSelected &&
                                        !widget.isCorrect
                                    ? AppPalette.error
                                    : AppPalette.textPrimary,
                            fontWeight:
                                widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                    ),
                  ),
                  if (icon != null) Icon(icon, color: iconColor, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final t = _shakeController.value;
        final damping = (1 - t);
        final offset = _shouldShake
            ? math.sin(t * math.pi * 8) * 7 * damping
            : 0.0;
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: content,
    );
  }
}
