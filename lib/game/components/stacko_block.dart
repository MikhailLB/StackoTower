import 'dart:ui' as ui;

import 'package:flame/flame.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

import '../../app/stacko_assets.dart';
import '../../services/audio_service.dart';
import '../stacko_constants.dart';

/// A single dynamic physics block that the player drops from the crane.
class StackoBlock extends BodyComponent with ContactCallbacks {
  StackoBlock({
    required this.skinIndex,
    required this.spawnPosition,
    required this.spawnVelocity,
    required this.spawnAngularVelocity,
  }) : super(priority: 5);

  /// 1..6 — matches block_0X.webp skin files.
  final int skinIndex;
  final Vector2 spawnPosition;
  final Vector2 spawnVelocity;
  final double spawnAngularVelocity;

  late final ui.Image _image;

  /// True once the block is at rest and counted into the tower.
  bool placed = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _image = await Flame.images.load(StackoAssets.block(skinIndex));
  }

  @override
  Body createBody() {
    final hw = StackoConstants.blockWidth / 2;
    final hh = StackoConstants.blockHeight / 2;
    final shape = PolygonShape()..setAsBoxXY(hw, hh);
    final body = world.createBody(BodyDef(
      type: BodyType.dynamic,
      position: spawnPosition.clone(),
      linearVelocity: spawnVelocity.clone(),
      angularVelocity: spawnAngularVelocity,
      bullet: true,
      userData: 'stacko_block',
    ));
    body.createFixture(FixtureDef(
      shape,
      density: 1.4,
      friction: 0.92,
      restitution: 0.02,
    ));
    return body;
  }

  bool _impactCooldown = false;

  @override
  void postSolve(Object other, Contact contact, ContactImpulse impulse) {
    if (_impactCooldown) return;
    final maxImpulse = impulse.normalImpulses.isEmpty
        ? 0.0
        : impulse.normalImpulses.reduce((a, b) => a > b ? a : b);
    if (maxImpulse < 0.6) return;
    _impactCooldown = true;
    AudioService.instance.playSfx(Sfx.blockLand);
    AudioService.instance.vibrate();
    Future<void>.delayed(const Duration(milliseconds: 220), () {
      _impactCooldown = false;
    });
  }

  @override
  void render(Canvas canvas) {
    final dst = Rect.fromCenter(
      center: Offset.zero,
      width: StackoConstants.blockWidth,
      height: StackoConstants.blockHeight,
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

  /// World-space top Y of the block (smallest Y across all four corners).
  double get topY {
    final t = body.transform;
    final hw = StackoConstants.blockWidth / 2;
    final hh = StackoConstants.blockHeight / 2;
    final corners = <Vector2>[
      Vector2(-hw, -hh),
      Vector2(hw, -hh),
      Vector2(hw, hh),
      Vector2(-hw, hh),
    ];
    var minY = double.infinity;
    for (final c in corners) {
      final w = t.p + Vector2(
        c.x * t.q.cos - c.y * t.q.sin,
        c.x * t.q.sin + c.y * t.q.cos,
      );
      if (w.y < minY) minY = w.y;
    }
    return minY;
  }
}
