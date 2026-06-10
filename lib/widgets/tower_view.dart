import 'package:flutter/material.dart';

import '../app/skyline.dart';
import '../game/tower_engine.dart';

/// Palettes unlockable in the shop (selectedTheme index → block colours).
class TowerSkin {
  const TowerSkin(this.name, this.colors);
  final String name;
  final List<Color> colors; // [normal, wide, light, counter, bonus]

  // [normal, wide, light, counter, bonus, fragile]
  static const all = <TowerSkin>[
    TowerSkin('Neon', [Sky.cyan, Sky.violet, Color(0xFF5C8BFF), Sky.amber, Sky.lime, Color(0xFFFF8AC0)]),
    TowerSkin('Sunset', [Color(0xFFFF8A5C), Color(0xFFFF4D88), Color(0xFFFFC25C), Color(0xFFFFE08A), Color(0xFF7CFFB0), Color(0xFFFFB0C8)]),
    TowerSkin('Aurora', [Color(0xFF5CFFD0), Color(0xFF7C5CFF), Color(0xFF5CC8FF), Color(0xFFFFE05C), Color(0xFFB0FF5C), Color(0xFFD0A0FF)]),
    TowerSkin('Mono', [Color(0xFFCBD5FF), Color(0xFF8FA0E0), Color(0xFFA9B6F0), Color(0xFFFFFFFF), Color(0xFF7C88B8), Color(0xFFB0B8D8)]),
    TowerSkin('Magma', [Color(0xFFFF5C3C), Color(0xFFFF8A00), Color(0xFFFFB23C), Color(0xFFFFD66B), Color(0xFFFF3C6B), Color(0xFFFFA080)]),
    TowerSkin('Toxic', [Color(0xFF8CFF3C), Color(0xFF3CFF8C), Color(0xFFCFFF3C), Color(0xFFFFF03C), Color(0xFF3CFFD0), Color(0xFFC0FF80)]),
  ];

  static TowerSkin byIndex(int i) => all[i.clamp(0, all.length - 1)];

  static const _ice = Color(0xFF9BE8FF);
  static const _bomb = Color(0xFFFF5470);

  Color colorFor(BlockKind k) {
    switch (k) {
      case BlockKind.normal:
        return colors[0];
      case BlockKind.wide:
        return colors[1];
      case BlockKind.light:
        return colors[2];
      case BlockKind.counter:
        return colors[3];
      case BlockKind.bonus:
        return colors[4];
      case BlockKind.fragile:
        return colors[5];
      case BlockKind.ice:
        return _ice;
      case BlockKind.bomb:
        return _bomb;
    }
  }
}

class TowerView extends StatelessWidget {
  const TowerView({
    super.key,
    required this.engine,
    required this.skin,
    this.toppleT = 0,
  });

  final TowerEngine engine;
  final TowerSkin skin;

  /// 0 → standing, 1 → fully collapsed (screen-driven on game over).
  final double toppleT;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TowerPainter(engine: engine, skin: skin, toppleT: toppleT),
      size: Size.infinite,
    );
  }
}

class _TowerPainter extends CustomPainter {
  _TowerPainter({required this.engine, required this.skin, required this.toppleT});

  final TowerEngine engine;
  final TowerSkin skin;
  final double toppleT;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final boardHalf = size.width * 0.42; // maps x=±1 to ±boardHalf
    final blockH = size.height * 0.052;
    final craneY = size.height * 0.10;
    final topBlockY = craneY + blockH * 1.6;

    // Whole-tower tilt: small live feedback + dramatic topple.
    final liveTilt = engine.leanPct * 0.05;
    final tilt = liveTilt + toppleT * (engine.leanPct.sign == 0 ? 1 : engine.leanPct.sign) * 0.9;

    canvas.save();
    // Pivot near the base (bottom centre) so the tower hinges realistically.
    final pivot = Offset(cx + engine.centreOfMass * boardHalf, size.height);
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(tilt);
    canvas.translate(-pivot.dx, -pivot.dy);

    // Draw blocks newest→oldest going downward from the crane.
    final n = engine.blocks.length;
    var lastY = topBlockY;
    for (var i = n - 1; i >= 0; i--) {
      final b = engine.blocks[i];
      final y = topBlockY + (n - 1 - i) * blockH;
      lastY = y;
      if (y > size.height + blockH) break; // off-screen below
      _drawBlock(canvas, cx, boardHalf, blockH, b, y);
    }

    // Base platform under the lowest visible block.
    final baseY = (n == 0 ? topBlockY : lastY) + blockH;
    if (baseY < size.height + blockH) {
      final baseRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, baseY),
            width: engine.baseHalf * 2 * boardHalf + 18,
            height: blockH * 0.9),
        Radius.circular(blockH * 0.2),
      );
      canvas.drawRRect(baseRect, Paint()..color = Sky.muted.withValues(alpha: 0.5));
      canvas.drawRRect(
          baseRect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = Colors.white.withValues(alpha: 0.4));
    }

    canvas.restore();

    // Crane rail + carried block (not part of the tilting tower).
    if (engine.running) {
      _drawCrane(canvas, size, cx, boardHalf, blockH, craneY);
    }
  }

  void _drawBlock(Canvas canvas, double cx, double boardHalf, double blockH,
      TowerBlock b, double y) {
    final w = b.halfW * 2 * boardHalf;
    final x = cx + b.x * boardHalf;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(x, y), width: w, height: blockH * 0.86),
      Radius.circular(blockH * 0.22),
    );
    final color = _colorFor(b.kind);
    canvas.drawRRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.95), color.withValues(alpha: 0.55)],
        ).createShader(rect.outerRect),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.5),
    );
    // glow (stronger for perfect placements)
    canvas.drawRRect(
      rect,
      Paint()
        ..color = color.withValues(alpha: b.perfect ? 0.5 : 0.25)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, b.perfect ? 14 : 8),
    );
  }

  void _drawCrane(Canvas canvas, Size size, double cx, double boardHalf,
      double blockH, double craneY) {
    final railPaint = Paint()
      ..color = Sky.muted.withValues(alpha: 0.5)
      ..strokeWidth = 3;
    canvas.drawLine(Offset(cx - boardHalf, craneY), Offset(cx + boardHalf, craneY), railPaint);

    final hookX = cx + engine.craneX * boardHalf;
    canvas.drawLine(Offset(hookX, craneY), Offset(hookX, craneY + blockH * 0.7),
        Paint()
          ..color = Sky.amber
          ..strokeWidth = 2);

    final carried = TowerBlock(
        x: engine.craneX, halfW: engine.nextKind.halfW, kind: engine.nextKind);
    _drawBlock(canvas, cx, boardHalf, blockH, carried, craneY + blockH * 1.2);

    // Drop guide line.
    canvas.drawLine(
      Offset(hookX, craneY + blockH * 1.7),
      Offset(hookX, size.height),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..strokeWidth = 1,
    );
  }

  Color _colorFor(BlockKind k) => skin.colorFor(k);

  @override
  bool shouldRepaint(covariant _TowerPainter old) => true;
}

/// Horizontal lean meter shown above the tower.
class LeanMeter extends StatelessWidget {
  const LeanMeter({super.key, required this.leanPct});
  final double leanPct;

  @override
  Widget build(BuildContext context) {
    final danger = leanPct.abs() > 0.7;
    final color = danger ? Sky.danger : (leanPct.abs() > 0.45 ? Sky.amber : Sky.lime);
    return SizedBox(
      height: 26,
      child: CustomPaint(
        painter: _LeanPainter(leanPct.clamp(-1, 1), color),
        size: Size.infinite,
      ),
    );
  }
}

class _LeanPainter extends CustomPainter {
  _LeanPainter(this.lean, this.color);
  final double lean;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height / 2 - 4, size.width, 8),
      const Radius.circular(4),
    );
    canvas.drawRRect(track, Paint()..color = Sky.panelDeep);
    canvas.drawRRect(
        track,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Sky.line);

    // centre tick
    canvas.drawLine(Offset(cx, 2), Offset(cx, size.height - 2),
        Paint()..color = Colors.white.withValues(alpha: 0.4)..strokeWidth = 2);

    // indicator
    final ix = cx + lean * (size.width / 2 - 8);
    canvas.drawCircle(Offset(ix, size.height / 2), 8,
        Paint()..color = color..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    canvas.drawCircle(Offset(ix, size.height / 2), 6, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _LeanPainter old) => old.lean != lean || old.color != color;
}
