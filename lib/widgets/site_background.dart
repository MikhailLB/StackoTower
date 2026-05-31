import 'package:flutter/material.dart';

import '../app/app_theme.dart';

/// Dark "construction site" backdrop with a faint dotted survey grid and
/// subtle corner hazard accents. Gives the route puzzle its own identity,
/// distinct from the old city-photo menu.
class SiteBackground extends StatelessWidget {
  const SiteBackground({super.key, this.child, this.cell = 30});

  final Widget? child;
  final double cell;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF15103A), Color(0xFF0E0B26), Color(0xFF080614)],
        ),
      ),
      child: CustomPaint(
        painter: _SitePainter(cell: cell),
        child: child,
      ),
    );
  }
}

class _SitePainter extends CustomPainter {
  _SitePainter({required this.cell});
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.05);
    for (var y = cell; y < size.height; y += cell) {
      for (var x = cell; x < size.width; x += cell) {
        canvas.drawCircle(Offset(x, y), 1.1, dot);
      }
    }

    // Corner hazard chevrons (very subtle).
    final hazard = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.06)
      ..strokeWidth = 10;
    for (var i = -2; i < 6; i++) {
      final o = i * 26.0;
      canvas.drawLine(Offset(0, o + 40), Offset(o + 40, 0), hazard);
      canvas.drawLine(
        Offset(size.width, size.height - o - 40),
        Offset(size.width - o - 40, size.height),
        hazard,
      );
    }

    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, const Color(0xFF050410).withValues(alpha: 0.65)],
        stops: const [0.55, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant _SitePainter oldDelegate) =>
      oldDelegate.cell != cell;
}
