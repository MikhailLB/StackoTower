import 'package:flutter/material.dart';

import '../app/app_theme.dart';

/// Shared "neon construction" UI building blocks — a deliberately different
/// visual language from the glossy pill buttons used elsewhere, so StackoTower
/// reads as its own app.
class NeonColors {
  static const violet = Color(0xFF7B4FD4);
  static const cyan = Color(0xFF35E0E0);
  static const cardFill = Color(0xFF181436);
  static const cardFillDeep = Color(0xFF110E2A);
}

/// A dark rounded panel with a soft neon edge + glow.
class NeonCard extends StatelessWidget {
  const NeonCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.edge = NeonColors.violet,
    this.glow = true,
    this.radius = 20,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color edge;
  final bool glow;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [NeonColors.cardFill, NeonColors.cardFillDeep],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: edge.withValues(alpha: 0.45), width: 1.5),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: edge.withValues(alpha: 0.18),
                  blurRadius: 22,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: card);
  }
}

/// A chunky icon+label tile used in the menu's bottom action bar.
class NeonTile extends StatelessWidget {
  const NeonTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = NeonColors.violet,
    this.featured = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: featured ? 16 : 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: featured
                ? [const Color(0xFFFFD93D), const Color(0xFFFF8C00)]
                : [color.withValues(alpha: 0.32), color.withValues(alpha: 0.12)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: featured
                ? const Color(0xFFFF6B00).withValues(alpha: 0.7)
                : color.withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: featured
              ? [
                  BoxShadow(
                    color: const Color(0xFFFFC233).withValues(alpha: 0.4),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: featured ? Colors.white : color == NeonColors.violet
                    ? const Color(0xFFD9C6FF)
                    : color,
                size: featured ? 30 : 24),
            SizedBox(height: featured ? 4 : 3),
            Text(
              label,
              style: AppTextStyles.button(
                size: featured ? 18 : 13,
                color: featured ? Colors.white : AppColors.text,
              ).copyWith(
                shadows: featured
                    ? [
                        const Shadow(
                            color: Colors.black54,
                            blurRadius: 3,
                            offset: Offset(0, 1)),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small circular icon button (settings / back).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({super.key, required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: NeonColors.cardFill,
          shape: BoxShape.circle,
          border: Border.all(color: NeonColors.violet.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Icon(icon, color: AppColors.text, size: 22),
      ),
    );
  }
}

/// Coin balance chip.
class CoinChip extends StatelessWidget {
  const CoinChip({super.key, required this.coins});
  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: NeonColors.cardFill,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on_rounded, color: AppColors.accent, size: 20),
          const SizedBox(width: 6),
          Text('$coins', style: AppTextStyles.button(size: 16)),
        ],
      ),
    );
  }
}

/// Left-aligned section label with a neon tick.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color = AppColors.accent});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8)],
          ),
        ),
        const SizedBox(width: 10),
        Text(text.toUpperCase(),
            style: AppTextStyles.button(size: 16)
                .copyWith(letterSpacing: 1.5)),
      ],
    );
  }
}

/// A small empty-lot preview: grid of plots with obstacle blocks and the
/// START/EXIT markers.
class LotPreview extends StatelessWidget {
  const LotPreview({
    super.key,
    required this.rows,
    required this.cols,
    required this.box,
    required this.walls,
    required this.startIndex,
    required this.exitIndex,
  });

  final int rows;
  final int cols;
  final double box;
  final Set<int> walls;
  final int startIndex;
  final int exitIndex;

  @override
  Widget build(BuildContext context) {
    final cell = box / (rows > cols ? rows : cols);
    return Container(
      width: box,
      height: box,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: NeonColors.cardFillDeep,
        borderRadius: BorderRadius.circular(12),
      ),
      // Border via foregroundDecoration so it never insets the grid.
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: SizedBox(
        width: cell * cols,
        height: cell * rows,
        child: Column(
          children: [
            for (var r = 0; r < rows; r++)
              Row(
                children: [
                  for (var c = 0; c < cols; c++)
                    _previewCell(r * cols + c, cell),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _previewCell(int i, double cell) {
    final wall = walls.contains(i);
    return Container(
      width: cell,
      height: cell,
      decoration: BoxDecoration(
        color: wall
            ? NeonColors.violet.withValues(alpha: 0.55)
            : Colors.white.withValues(alpha: 0.04),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.07), width: 0.5),
      ),
      child: wall
          ? null
          : i == startIndex
              ? const Icon(Icons.play_circle_fill_rounded,
                  color: AppColors.accent, size: 13)
              : i == exitIndex
                  ? const Icon(Icons.outlined_flag_rounded,
                      color: Color(0xFF35E0E0), size: 13)
                  : null,
    );
  }
}
