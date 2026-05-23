import 'dart:ui' as ui;

import 'package:flame/flame.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

import '../../app/stacko_assets.dart';
import '../stacko_constants.dart';

/// The starter platform the player stacks blocks on. Rendered from
/// [StackoAssets.startBuilding] at exactly the body dimensions.
class StartBuilding extends BodyComponent {
  StartBuilding() : super(priority: 0);

  late final ui.Image _image;

  @override
  bool get renderBody => false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _image = await Flame.images.load(StackoAssets.startBuilding);
  }

  @override
  Body createBody() {
    final width = StackoConstants.startBuildingWidth;
    final height = StackoConstants.startBuildingHeight;
    final centreY = StackoConstants.startBuildingTopY + height / 2;
    final shape = PolygonShape()..setAsBoxXY(width / 2, height / 2);
    final body = world.createBody(BodyDef(
      type: BodyType.static,
      position: Vector2(0, centreY),
      userData: 'start_building',
    ));
    body.createFixture(FixtureDef(
      shape,
      friction: 0.95,
      restitution: 0.0,
    ));
    return body;
  }

  @override
  void render(Canvas canvas) {
    final dst = Rect.fromCenter(
      center: Offset.zero,
      width: StackoConstants.startBuildingWidth,
      height: StackoConstants.startBuildingHeight,
    );
    final src = Rect.fromLTWH(
      0,
      0,
      _image.width.toDouble(),
      _image.height.toDouble(),
    );
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
