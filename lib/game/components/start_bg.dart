import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

import '../../app/stacko_assets.dart';
import '../stacko_constants.dart';
import '../stacko_game.dart';

/// Painted strip of distant city silhouettes sitting between the sky and
/// the starter platform. Rendered wide enough that edges stay off-screen
/// even when the camera pans horizontally.
class StartBg extends PositionComponent with HasGameReference<StackoGame> {
  StartBg() : super(priority: -50);

  late final ui.Image _image;

  @override
  Future<void> onLoad() async {
    _image = await Flame.images.load(StackoAssets.startBg);
    final aspect = _image.width / _image.height;
    final width = StackoConstants.worldWidth * 3.0;
    final height = width / aspect;
    size = Vector2(width, height);
    anchor = Anchor.bottomCenter;
    position = Vector2(0, StackoConstants.groundTopY + 0.4);
  }

  @override
  void render(Canvas canvas) {
    final src = Rect.fromLTWH(
      0,
      0,
      _image.width.toDouble(),
      _image.height.toDouble(),
    );
    final dst = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawImageRect(
      _image,
      src,
      dst,
      Paint()
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.medium,
    );
  }
}
