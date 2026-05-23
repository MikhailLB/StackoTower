import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

import '../../app/stacko_assets.dart';
import '../stacko_constants.dart';
import '../stacko_game.dart';

/// Sky background pinned to the camera every frame so the painted gradient
/// fills the viewport regardless of how high the tower has grown.
class SkyBackground extends PositionComponent
    with HasGameReference<StackoGame> {
  SkyBackground() : super(priority: -100);

  late final ui.Image _image;
  static const _padding = 1.0;

  @override
  Future<void> onLoad() async {
    _image = await Flame.images.load(StackoAssets.sky);
    size = Vector2(
      StackoConstants.worldWidth + _padding * 2,
      StackoConstants.worldHeight + _padding * 2,
    );
    anchor = Anchor.center;
  }

  @override
  void update(double dt) {
    super.update(dt);
    position = game.camera.viewfinder.position.clone();
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
