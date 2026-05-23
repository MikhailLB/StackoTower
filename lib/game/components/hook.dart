import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

import '../../app/stacko_assets.dart';
import '../stacko_constants.dart';

/// The crane hook + the block currently teased above the tower.
///
/// The hook slides horizontally across the top of the viewport. Its Y
/// position is pinned to the camera centre (via [cameraCenterY]) so it
/// always stays near the top of the screen even as the camera follows the
/// growing tower. The hanging block is anchored to [topY] (top of the
/// current tower), keeping the chain length visually constant.
class Hook extends PositionComponent {
  Hook({required this.skinIndexProvider}) : super(priority: 10);

  final int Function() skinIndexProvider;

  late ui.Image _hookImage;
  final Map<int, ui.Image> _blockImages = {};
  late ui.Image _blockImage;
  int _currentSkin = 1;

  /// Top-of-tower Y in world space. Updated every frame by StackoWorld.
  double topY = StackoConstants.startBuildingTopY;

  /// Camera centre Y in world space. Updated every frame by StackoWorld.
  double cameraCenterY = 0;

  /// Hook slide speed (half-period in seconds for one-way traverse).
  double halfPeriod = StackoConstants.hookInitialHalfPeriod;

  double _phase = 0;
  bool _hasBlock = true;

  double get currentX => math.sin(_phase) * StackoConstants.hookAmplitude;

  double get currentY =>
      topY -
      StackoConstants.hookBlockOffsetAboveTop -
      StackoConstants.blockHeight / 2;

  double get currentVelocityX =>
      math.cos(_phase) *
      StackoConstants.hookAmplitude *
      (math.pi / halfPeriod);

  double get blockY => currentY - StackoConstants.blockHeight / 2;

  bool get hasBlock => _hasBlock;

  @override
  Future<void> onLoad() async {
    _hookImage = await Flame.images.load(StackoAssets.hook);
    for (var i = 1; i <= 6; i++) {
      _blockImages[i] = await Flame.images.load(StackoAssets.block(i));
    }
    _currentSkin = skinIndexProvider();
    _blockImage = _blockImages[_currentSkin]!;
  }

  void releaseBlock() {
    _hasBlock = false;
  }

  void attachNewBlock() {
    _currentSkin = skinIndexProvider();
    _blockImage = _blockImages[_currentSkin] ?? _blockImage;
    _hasBlock = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _phase += dt * (math.pi / halfPeriod);
    if (_phase > math.pi * 2) _phase -= math.pi * 2;
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.medium;

    final cx = currentX;
    final blockCy = currentY;
    final blockTopY = blockCy - StackoConstants.blockHeight / 2;

    const hookSpriteHeight = StackoConstants.hookSpriteHeight;
    final hookAspect = _hookImage.width / _hookImage.height;
    final hookSpriteWidth = hookSpriteHeight * hookAspect;
    final hookCenterY = cameraCenterY - StackoConstants.hookScreenAnchor;
    final hookBottomY = hookCenterY + hookSpriteHeight / 2;

    canvas.drawImageRect(
      _hookImage,
      Rect.fromLTWH(
        0,
        0,
        _hookImage.width.toDouble(),
        _hookImage.height.toDouble(),
      ),
      Rect.fromCenter(
        center: Offset(cx, hookCenterY),
        width: hookSpriteWidth,
        height: hookSpriteHeight,
      ),
      paint,
    );

    if (_hasBlock) {
      final inset = StackoConstants.blockWidth * 0.08;
      final attachLeftX = cx - StackoConstants.blockWidth / 2 + inset;
      final attachRightX = cx + StackoConstants.blockWidth / 2 - inset;
      final chainPaint = Paint()
        ..color = const Color(0xFF1F1F1F)
        ..strokeWidth = 0.12
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(cx, hookBottomY),
        Offset(attachLeftX, blockTopY),
        chainPaint,
      );
      canvas.drawLine(
        Offset(cx, hookBottomY),
        Offset(attachRightX, blockTopY),
        chainPaint,
      );

      canvas.drawImageRect(
        _blockImage,
        Rect.fromLTWH(
          0,
          0,
          _blockImage.width.toDouble(),
          _blockImage.height.toDouble(),
        ),
        Rect.fromCenter(
          center: Offset(cx, blockCy),
          width: StackoConstants.blockWidth,
          height: StackoConstants.blockHeight,
        ),
        paint,
      );
    }
  }
}
