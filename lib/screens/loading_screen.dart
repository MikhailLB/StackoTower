import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/app_orientation.dart';
import '../app/stacko_assets.dart';
import 'main_menu_screen.dart';

/// Splash screen using static PNG background images (portrait & landscape).
/// Shows an animated "Loading…" text and a 4-state progress bar while game
/// assets warm up, then navigates to [MainMenuScreen].
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  bool _hasNavigated = false;

  // Bar cycles 1 → 2 → 3 → 4 over [_barDuration].
  late final AnimationController _barCtrl;
  static const _barDuration = Duration(milliseconds: 4500);

  // "Loading…" dots: 0 → 1 → 2 → 3 dots, cycling every 500 ms.
  late final AnimationController _dotsCtrl;
  int _dots = 0;

  static const _minDuration = Duration(milliseconds: 5500);

  @override
  void initState() {
    super.initState();
    setOrientationsForLoadingScreens();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _barCtrl = AnimationController(vsync: this, duration: _barDuration);

    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (mounted) setState(() => _dots = (_dots + 1) % 4);
          _dotsCtrl.forward(from: 0);
        }
      });

    _run();
  }

  Future<void> _run() async {
    final start = DateTime.now();

    // Kick off the bar and dots animations immediately.
    _barCtrl.forward();
    _dotsCtrl.forward(from: 0);

    // Preload game assets while the bar plays.
    await _preload();

    // Wait for bar to finish + ensure minimum splash time.
    await _barCtrl.forward();
    final elapsed = DateTime.now().difference(start);
    if (elapsed < _minDuration) {
      await Future<void>.delayed(_minDuration - elapsed);
    }

    _goToMenu();
  }

  Future<void> _preload() async {
    final assets = <String>[
      StackoAssets.startBg,
      StackoAssets.startBuilding,
      StackoAssets.gameName,
      StackoAssets.icon,
      ...StackoAssets.allBlocks,
      for (var i = 1; i <= 4; i++) StackoAssets.loadingBar(i),
    ];
    for (final path in assets) {
      if (!mounted) return;
      try {
        await precacheImage(AssetImage(path), context);
      } catch (_) {}
    }
    // Warm up fonts so the main menu doesn't flash a fallback font.
    try {
      GoogleFonts.nunito();
      GoogleFonts.bangers();
      await GoogleFonts.pendingFonts([GoogleFonts.nunito(), GoogleFonts.bangers()]);
    } catch (_) {}
  }

  void _goToMenu() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondary) => const MainMenuScreen(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (context, animation, secondary, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _barCtrl.dispose();
    _dotsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: OrientationBuilder(
        builder: (context, orientation) {
          final isPortrait = orientation == Orientation.portrait;
          final bgAsset = isPortrait
              ? StackoAssets.splashPortrait
              : StackoAssets.splashLandscape;
          final size = MediaQuery.of(context).size;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Full-screen background image.
              Image.asset(
                bgAsset,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),

              // Loading bar — anchored toward the bottom.
              Positioned(
                bottom: isPortrait ? size.height * 0.06 : size.height * 0.05,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated "Loading..." dots text
                    _DotsText(dots: _dots, isLandscape: !isPortrait),
                    const SizedBox(height: 12),
                    // 4-state bar image
                    AnimatedBuilder(
                      animation: _barCtrl,
                      builder: (context, child) {
                        final state =
                            (_barCtrl.value * 4).clamp(0.0, 4.0).floor().clamp(1, 4);
                        final barW = isPortrait
                            ? size.width * 0.68
                            : size.height * 0.45;
                        return Center(
                          child: Image.asset(
                            StackoAssets.loadingBar(state),
                            width: barW,
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DotsText extends StatelessWidget {
  const _DotsText({required this.dots, required this.isLandscape});

  final int dots;
  final bool isLandscape;

  @override
  Widget build(BuildContext context) {
    final dotStr = '.' * dots;
    final fontSize = isLandscape ? 18.0 : 20.0;
    return Text(
      'Loading$dotStr',
      textAlign: TextAlign.center,
      style: GoogleFonts.nunito(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: Colors.white.withValues(alpha: 0.9),
        letterSpacing: 1.5,
        shadows: const [
          Shadow(blurRadius: 8, color: Colors.black87, offset: Offset(0, 2)),
        ],
      ),
    );
  }
}
