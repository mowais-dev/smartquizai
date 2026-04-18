import 'package:flutter/material.dart';

import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_palette.dart';

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.isDisabled = false,
    this.width,
    this.height,
    this.icon,
  });

  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final bool isDisabled;
  final double? width;
  final double? height;
  final IconData? icon;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  bool get _isDisabled => widget.isLoading || widget.isDisabled || widget.onPressed == null;

  @override
  Widget build(BuildContext context) {
    final buttonHeight = widget.height ?? 52;
    return SizedBox(
      width: widget.width ?? double.infinity,
      height: buttonHeight,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        scale: _pressed && !_isDisabled ? 0.98 : 1,
        child: Opacity(
          opacity: _isDisabled ? 0.55 : 1,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isDisabled ? null : widget.onPressed,
              onTapDown: (_) {
                if (_isDisabled) return;
                setState(() => _pressed = true);
              },
              onTapCancel: () {
                if (_pressed) setState(() => _pressed = false);
              },
              onTapUp: (_) {
                if (_pressed) setState(() => _pressed = false);
              },
              borderRadius: BorderRadius.circular(18),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: _isDisabled
                      ? null
                      : [
                          BoxShadow(
                            color: AppPalette.primaryB.withOpacity(0.22),
                            blurRadius: 26,
                            offset: const Offset(0, 16),
                          ),
                        ],
                ),
                child: Center(
                  child: widget.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.icon != null) ...[
                                Icon(widget.icon, size: 18, color: AppPalette.textPrimary),
                                if (widget.text.isNotEmpty) const SizedBox(width: 10),
                              ],
                              if (widget.text.isNotEmpty)
                                Text(
                                  widget.text,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: AppPalette.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
