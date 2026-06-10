import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../app/skyline.dart';
import '../main.dart';

/// Second between-chapter mini-game: hammer rivets as fast as you can before
/// the 5-second timer runs out. Pure upside, frantic and fun.
class RushGameScreen extends StatefulWidget {
  const RushGameScreen({super.key});

  @override
  State<RushGameScreen> createState() => _RushGameScreenState();
}

class _RushGameScreenState extends State<RushGameScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  double _time = 5.0;
  int _rivets = 0;
  bool _started = false;
  bool _done = false;
  double _pop = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  void _tick(Duration now) {
    final dt = (now - _last).inMicroseconds / 1e6;
    _last = now;
    if (dt <= 0 || dt > 0.1) return;
    if (_pop > 0) _pop = (_pop - dt * 4).clamp(0, 1);
    if (_started && !_done) {
      _time -= dt;
      if (_time <= 0) {
        _time = 0;
        _finish();
      }
    }
    setState(() {});
  }

  void _hit() {
    if (_done) return;
    _started = true;
    _rivets++;
    _pop = 1;
    HapticFeedback.selectionClick();
  }

  Future<void> _finish() async {
    _done = true;
    final coins = _rivets * 4;
    await progress.addCoins(coins);
    if (!mounted) return;
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
              Text('RIVETS DRIVEN', style: Sky.display(size: 20, color: Sky.amber)),
              const SizedBox(height: 12),
              Text('$_rivets', style: Sky.number(size: 40, color: Sky.cyan)),
              const SizedBox(height: 4),
              Text('+${_rivets * 4} coins', style: Sky.number(size: 22, color: Sky.amber)),
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
            onTapDown: (_) => _hit(),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Text('RIVET RUSH', style: Sky.display(size: 26)),
                const SizedBox(height: 4),
                Text(_started ? 'HAMMER!' : 'Tap fast to drive rivets!',
                    style: Sky.body(size: 14)),
                const SizedBox(height: 16),
                Text(_started ? _time.toStringAsFixed(1) : '5.0',
                    style: Sky.number(size: 30,
                        color: _time < 2 ? Sky.danger : Sky.text)),
                const Spacer(),
                Transform.scale(
                  scale: 1.0 + _pop * 0.12,
                  child: Container(
                    width: 180,
                    height: 180,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Sky.amber, Sky.danger],
                      ),
                      boxShadow: Sky.glow(Sky.amber, blur: 28 + _pop * 20),
                    ),
                    child: Text('$_rivets', style: Sky.number(size: 56, color: Sky.bg0)),
                  ),
                ),
                const Spacer(),
                Text('TAP ANYWHERE', style: Sky.label(size: 14, color: Sky.muted)),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
