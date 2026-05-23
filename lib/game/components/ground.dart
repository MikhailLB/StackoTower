import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

import '../../app/stacko_assets.dart';
import '../stacko_constants.dart';

/// Static Forge2D body acting as the floor. Invisible body; the visual is
/// painted by [GroundDecal].
class Ground extends BodyComponent {
  Ground() : super(priority: -10);

  @override
  Body createBody() {
    final shape = PolygonShape()
      ..setAsBox(
        StackoConstants.worldWidth * 5,
        2.5,
        Vector2(0, StackoConstants.groundTopY + 2.5),
        0,
      );
    final body = world.createBody(BodyDef(
      type: BodyType.static,
      position: Vector2.zero(),
      userData: 'ground',
    ));
    body.createFixture(FixtureDef(
      shape,
      friction: 0.9,
      restitution: 0.0,
    ));
    return body;
  }

  @override
  void render(Canvas canvas) {}
}

class GroundDecal extends PositionComponent {
  GroundDecal() : super(priority: -8);

  late final ui.Image _image;

  @override
  Future<void> onLoad() async {
    _image = await Flame.images.load(StackoAssets.ground);
    final aspect = _image.width / _image.height;
    final width = StackoConstants.worldWidth * 1.4;
    final height = width / aspect;
    size = Vector2(width, height);
    anchor = Anchor.topCenter;
    position = Vector2(0, StackoConstants.groundTopY - 0.05);
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..isAntiAlias = false;
    final src = Rect.fromLTWH(
      0,
      0,
      _image.width.toDouble(),
      _image.height.toDouble(),
    );
    final dst = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawImageRect(_image, src, dst, paint);
  }
}
