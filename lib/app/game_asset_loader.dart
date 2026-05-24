import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'stacko_assets.dart';

/// Warms Flame image cache for gameplay sprites.
///
/// LoadingScreen does this on the white branch. Gray flow skips LoadingScreen
/// (SplashGate → MainMenuScreen), so we must preload during app boot instead.
Future<void> preloadGameAssets() async {
  Flame.images.prefix = '';

  final paths = <String>[
    StackoAssets.sky,
    StackoAssets.ground,
    StackoAssets.cloud,
    StackoAssets.hook,
    StackoAssets.startBg,
    StackoAssets.startBuilding,
    StackoAssets.icon,
    StackoAssets.gameName,
    ...StackoAssets.allBlocks,
    for (var i = 1; i <= 4; i++) StackoAssets.loadingBar(i),
  ];

  for (final path in paths) {
    try {
      await Flame.images.load(path);
    } catch (e) {
      debugPrint('[ASSETS] failed to preload $path: $e');
    }
  }

  try {
    GoogleFonts.bangers();
    GoogleFonts.fredoka();
    await GoogleFonts.pendingFonts(<TextStyle>[
      GoogleFonts.bangers(),
      GoogleFonts.fredoka(),
    ]);
  } catch (e) {
    debugPrint('[ASSETS] Google Fonts preload failed: $e');
  }
}
