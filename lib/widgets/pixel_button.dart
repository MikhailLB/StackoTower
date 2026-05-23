import 'package:flutter/material.dart';

import '../app/app_theme.dart';

enum PixelButtonColor { primary, secondary }

/// Modern game button with gradient, glow border, and press animation.
class PixelButton extends StatefulWidget {
  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width = 220,
    this.height = 60,
    this.fontSize = 22,
    this.color = PixelButtonColor.primary,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final double width;
  final double height;
  final double fontSize;
  final PixelButtonColor color;
  final IconData? icon;

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _down(TapDownDetails _) {
    if (widget.onPressed == null) return;
    _ctrl.forward();
  }

  void _up() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final isPrimary = widget.color == PixelButtonColor.primary;
    final disabled = widget.onPressed == null;

    final topGrad = isPrimary ? const Color(0xFFFFD93D) : AppColors.btnSecTop;
    final botGrad = isPrimary ? const Color(0xFFFF8C00) : AppColors.btnSecBottom;
    final topPress = isPrimary ? const Color(0xFFE8A800) : const Color(0xFF3D2070);
    final botPress = isPrimary ? const Color(0xFFB35800) : const Color(0xFF1A0D40);
    final borderCol = isPrimary
        ? const Color(0xFFFF6B00).withValues(alpha: 0.7)
        : AppColors.btnSecBorder.withValues(alpha: 0.8);
    final glowCol = isPrimary
        ? const Color(0xFFFFD93D).withValues(alpha: 0.35)
        : const Color(0xFF7B4FD4).withValues(alpha: 0.35);

    final radius = BorderRadius.circular(widget.height * 0.38);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _down,
      onTapUp: (_) { _up(); widget.onPressed?.call(); },
      onTapCancel: _up,
      child: ScaleTransition(
        scale: _scale,
        child: Opacity(
          opacity: disabled ? 0.45 : 1.0,
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              final t = _ctrl.value;
              return Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(topGrad, topPress, t)!,
                      Color.lerp(botGrad, botPress, t)!,
                    ],
                  ),
                  border: Border.all(color: borderCol, width: 1.5),
                  boxShadow: [
                    // Outer glow
                    BoxShadow(
                      color: glowCol,
                      blurRadius: 14 * (1 - t * 0.7),
                      spreadRadius: 1,
                    ),
                    // Drop shadow
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 8,
                      offset: Offset(0, 3 * (1 - t * 0.6)),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Top shine
                    Positioned(
                      top: 3,
                      left: 10,
                      right: 10,
                      height: widget.height * 0.38,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(widget.height * 0.34),
                            bottom: Radius.circular(4),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.25 * (1 - t * 0.8)),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Label
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: Colors.white, size: widget.fontSize * 1.1),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.button(
                            size: widget.fontSize,
                            color: Colors.white,
                          ).copyWith(
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
