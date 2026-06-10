import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// "Skyline" neon identity for STACKO TOWER: Balance.
/// Deep night-sky indigo, cyan→magenta energy, geometric type.
class Sky {
  static const bg0 = Color(0xFF060417);
  static const bg1 = Color(0xFF0E0A2E);
  static const bg2 = Color(0xFF171041);

  static const panel = Color(0xFF160F33);
  static const panelDeep = Color(0xFF0B0822);
  static const line = Color(0x22FFFFFF);

  static const cyan = Color(0xFF27E5F2);
  static const magenta = Color(0xFFFF49D9);
  static const violet = Color(0xFF8C5BFF);
  static const lime = Color(0xFF63FF9C);
  static const amber = Color(0xFFFFC542);
  static const danger = Color(0xFFFF5470);

  static const text = Color(0xFFEAF2FF);
  static const muted = Color(0xFF8B93C7);

  static const bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bg1, bg0],
  );

  static const energyGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [cyan, magenta],
  );

  static List<BoxShadow> glow(Color c, {double blur = 18, double spread = 0}) =>
      [BoxShadow(color: c.withValues(alpha: 0.55), blurRadius: blur, spreadRadius: spread)];

  static TextStyle display({double size = 34, Color color = text}) =>
      GoogleFonts.orbitron(
        fontSize: size,
        color: color,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
        height: 1.05,
      );

  static TextStyle label({double size = 16, Color color = text, double spacing = 1.2}) =>
      GoogleFonts.rajdhani(
        fontSize: size,
        color: color,
        fontWeight: FontWeight.w700,
        letterSpacing: spacing,
      );

  static TextStyle body({double size = 15, Color color = muted}) =>
      GoogleFonts.rajdhani(
        fontSize: size,
        color: color,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      );

  static TextStyle number({double size = 26, Color color = text}) =>
      GoogleFonts.orbitron(
        fontSize: size,
        color: color,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      );
}

/// Animated night-sky backdrop: gradient, radial glow, drifting stars.
class SkyBackdrop extends StatefulWidget {
  const SkyBackdrop({super.key, required this.child, this.glowColor = Sky.violet});
  final Widget child;
  final Color glowColor;

  @override
  State<SkyBackdrop> createState() => _SkyBackdropState();
}

class _SkyBackdropState extends State<SkyBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 18))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: Sky.bgGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (_, _) => CustomPaint(
              painter: _SkyPainter(_c.value, widget.glowColor),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _SkyPainter extends CustomPainter {
  _SkyPainter(this.t, this.glow);
  final double t;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [glow.withValues(alpha: 0.22), Colors.transparent],
      ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.5, size.height * 0.16),
          radius: size.width * 0.75));
    canvas.drawRect(Offset.zero & size, glowPaint);

    // Deterministic drifting stars.
    final star = Paint()..color = Colors.white;
    for (var i = 0; i < 60; i++) {
      final sx = ((i * 73) % 100) / 100.0;
      final sy = ((i * 137) % 100) / 100.0;
      final twinkle = 0.3 + 0.7 * (0.5 + 0.5 * math.sin((t + i * 0.13) * 6.28));
      final drift = ((sy + t * 0.05) % 1.0);
      star.color = Colors.white.withValues(alpha: 0.06 + 0.14 * twinkle);
      canvas.drawCircle(
        Offset(sx * size.width, drift * size.height),
        (i % 3 == 0) ? 1.4 : 0.8,
        star,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SkyPainter old) => old.t != t || old.glow != glow;
}
