import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../app/skyline.dart';
import '../main.dart';

/// Between-chapter bonus mini-game: a marker sweeps the gauge — tap to lock it
/// inside the glowing zone. Three supply drops, coins by accuracy. No failure,
/// pure upside, a quick palate-cleanser between districts.
class BonusGameScreen extends StatefulWidget {
  const BonusGameScreen({super.key});

  @override
  State<BonusGameScreen> createState() => _BonusGameScreenState();
}

class _BonusGameScreenState extends State<BonusGameScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  double _pos = 0; // 0..1
  double _dir = 1;
  double _speed = 0.85;

  int _round = 0;
  static const _rounds = 3;
  int _earned = 0;
  bool _locked = false;
  String _flash = '';

  // Target zone centre + half-width (shrinks each round).
  double _zoneC = 0.5;
  double _zoneH = 0.16;

  @override
  void initState() {
    super.initState();
    _newRound();
    _ticker = createTicker(_tick)..start();
  }

  void _newRound() {
    _locked = false;
    _pos = 0;
    _dir = 1;
    _speed = 0.8 + _round * 0.2;
    _zoneH = 0.16 - _round * 0.035;
    _zoneC = 0.3 + (_round * 0.23) % 0.4;
  }

  void _tick(Duration now) {
    final dt = (now - _last).inMicroseconds / 1e6;
    _last = now;
    if (dt <= 0 || dt > 0.1 || _locked) return;
    _pos += _dir * _speed * dt;
    if (_pos >= 1) {
      _pos = 1;
      _dir = -1;
    } else if (_pos <= 0) {
      _pos = 0;
      _dir = 1;
    }
    setState(() {});
  }

  Future<void> _lock() async {
    if (_locked) return;
    _locked = true;
    HapticFeedback.mediumImpact();
    final dist = (_pos - _zoneC).abs();
    int coins;
    String label;
    if (dist <= _zoneH * 0.35) {
      coins = 120;
      label = 'BULLSEYE +120';
    } else if (dist <= _zoneH) {
      coins = 60;
      label = 'NICE +60';
    } else {
      coins = 15;
      label = '+15';
    }
    _earned += coins;
    setState(() => _flash = label);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    _round++;
    if (_round >= _rounds) {
      await progress.addCoins(_earned);
      if (!mounted) return;
      _finish();
    } else {
      setState(() {
        _flash = '';
        _newRound();
      });
    }
  }

  void _finish() {
    _ticker.stop();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Sky.panel, Sky.panelDeep],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Sky.amber.withValues(alpha: 0.6), width: 1.6),
            boxShadow: Sky.glow(Sky.amber, blur: 24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('SUPPLY SECURED', style: Sky.display(size: 22, color: Sky.amber)),
              const SizedBox(height: 14),
              Text('+$_earned coins', style: Sky.number(size: 26, color: Sky.amber)),
              const SizedBox(height: 22),
              GestureDetector(
                onTap: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).maybePop();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  decoration: BoxDecoration(
                    color: Sky.cyan,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: Sky.glow(Sky.cyan, blur: 14),
                  ),
                  child: Text('CONTINUE',
                      style: Sky.label(size: 16, color: Sky.bg0, spacing: 2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SkyBackdrop(
        glowColor: Sky.amber,
        child: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _lock(),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Text('SUPPLY DROP', style: Sky.display(size: 26)),
                const SizedBox(height: 4),
                Text('Drop ${_round + 1} / $_rounds  ·  tap in the zone',
                    style: Sky.body(size: 14)),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: SizedBox(
                    height: 60,
                    child: CustomPaint(
                      painter: _GaugePainter(pos: _pos, zoneC: _zoneC, zoneH: _zoneH),
                      size: Size.infinite,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(_flash,
                    style: Sky.label(size: 22, color: Sky.lime)),
                const Spacer(),
                Text('EARNED  $_earned',
                    style: Sky.number(size: 20, color: Sky.amber)),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.pos, required this.zoneC, required this.zoneH});
  final double pos;
  final double zoneC;
  final double zoneH;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, y - 8, size.width, 16),
      const Radius.circular(8),
    );
    canvas.drawRRect(track, Paint()..color = Sky.panelDeep);
    canvas.drawRRect(
        track,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Sky.line);

    // Zone.
    final zl = (zoneC - zoneH).clamp(0.0, 1.0) * size.width;
    final zr = (zoneC + zoneH).clamp(0.0, 1.0) * size.width;
    final zone = RRect.fromRectAndRadius(
      Rect.fromLTRB(zl, y - 8, zr, y + 8),
      const Radius.circular(8),
    );
    canvas.drawRRect(zone, Paint()..color = Sky.lime.withValues(alpha: 0.4));
    // Bullseye.
    final bl = (zoneC - zoneH * 0.35) * size.width;
    final br = (zoneC + zoneH * 0.35) * size.width;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTRB(bl, y - 8, br, y + 8), const Radius.circular(8)),
        Paint()..color = Sky.amber.withValues(alpha: 0.6));

    // Marker.
    final mx = pos * size.width;
    canvas.drawCircle(Offset(mx, y), 12,
        Paint()..color = Sky.cyan..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawCircle(Offset(mx, y), 8, Paint()..color = Sky.text);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.pos != pos || old.zoneC != zoneC || old.zoneH != zoneH;
}
