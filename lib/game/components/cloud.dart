import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';

import '../../app/stacko_assets.dart';
import '../stacko_constants.dart';

/// A drifting cloud sprite. Wraps horizontally so the sky always looks alive.
class Cloud extends SpriteComponent with HasGameReference {
  Cloud({
    required this.speed,
    required this.relativeY,
    required this.scaleFactor,
    required this.startX,
    required this.cloudAlpha,
  });

  final double speed;
  final double relativeY;
  final double scaleFactor;
  final double startX;
  final double cloudAlpha;

  static Future<Sprite> _loadSprite() async =>
      Sprite(await Flame.images.load(StackoAssets.cloud));

  @override
  Future<void> onLoad() async {
    sprite = await _loadSprite();
    final aspect = sprite!.srcSize.x / sprite!.srcSize.y;
    size = Vector2(scaleFactor, scaleFactor / aspect);
    anchor = Anchor.center;
    position = Vector2(startX, relativeY);
    paint = Paint()
      ..colorFilter = ColorFilter.mode(
        const Color(0xFFFFFFFF).withValues(alpha: cloudAlpha),
        BlendMode.modulate,
      );
    priority = -50;
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.x += speed * dt;
    final cameraCenter = game.camera.viewfinder.position;
    final maxX = cameraCenter.x + StackoConstants.worldWidth / 2 + size.x;
    final minX = cameraCenter.x - StackoConstants.worldWidth / 2 - size.x;
    if (position.x > maxX) {
      position.x = minX;
      position.y = cameraCenter.y + relativeY;
    } else if (position.x < minX) {
      position.x = maxX;
      position.y = cameraCenter.y + relativeY;
    }
  }
}

/// Spawns a set of clouds bound to the camera centre.
class CloudLayer extends Component with HasGameReference {
  CloudLayer({this.seed = 0});

  final int seed;
  late final math.Random _rand = math.Random(seed);

  @override
  Future<void> onLoad() async {
    for (var i = 0; i < 6; i++) {
      add(_spawnCloud());
    }
  }

  Cloud _spawnCloud() {
    final width = StackoConstants.worldWidth;
    final speed = (_rand.nextDouble() * 0.4 + 0.2) *
        (_rand.nextBool() ? 1 : -1);
    final relativeY = -_rand.nextDouble() * 4 - 0.5;
    final scale = 1.3 + _rand.nextDouble() * 1.5;
    final startX = (_rand.nextDouble() - 0.5) * width;
    final cloudOpacity = 0.7 + _rand.nextDouble() * 0.3;
    return Cloud(
      speed: speed,
      relativeY: relativeY,
      scaleFactor: scale,
      startX: startX,
      cloudAlpha: cloudOpacity,
    );
  }
}
