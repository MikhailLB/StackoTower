import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import 'level_config.dart';
import 'stacko_constants.dart';
import 'stacko_status.dart';
import 'stacko_world.dart';

/// Top-level Forge2D game. Owns the camera, forwards taps to the world,
/// and keeps the camera smoothly following the top of the tower.
///
/// Camera zoom: `size.x / worldWidth` so the full landscape 16-meter width
/// fits exactly — no black bars on any 16:9 (or wider) device.
class StackoGame extends Forge2DGame<StackoWorld> with TapCallbacks {
  StackoGame({
    required int Function() skinPicker,
    required LevelConfig levelConfig,
    bool slowHookEnabled = false,
    bool ghostBlockEnabled = false,
    bool speedFreezeEnabled = false,
    bool wideBaseEnabled = false,
  }) : super(
          gravity: Vector2(0, StackoConstants.gravity),
          world: StackoWorld(
            skinPicker: skinPicker,
            levelConfig: levelConfig,
            slowHookEnabled: slowHookEnabled,
            ghostBlockEnabled: ghostBlockEnabled,
            speedFreezeEnabled: speedFreezeEnabled,
            wideBaseEnabled: wideBaseEnabled,
          ),
        );

  @override
  Color backgroundColor() => const Color(0xFF87CEEB);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _applyZoom(size);
  }

  void _applyZoom(Vector2 size) {
    if (size.x <= 0) return;
    camera.viewfinder.zoom = size.x / StackoConstants.worldWidth;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _applyZoom(canvasSize);
    camera.viewfinder.position = StackoConstants.initialCameraTarget;
    world.startRound();
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (world.status.value == StackoStatus.paused ||
        world.status.value == StackoStatus.gameOver ||
        world.status.value == StackoStatus.levelComplete) {
      return;
    }
    world.dropBlock();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!world.isMounted) return;
    _followTower(dt);
  }

  void _followTower(double dt) {
    final desiredCenterY =
        world.currentTopY - StackoConstants.cameraOffsetBelowCenter;
    final current = camera.viewfinder.position.y;
    final target = math.min(current, desiredCenterY);
    final newY = current +
        (target - current) *
            (1 - math.exp(-dt * StackoConstants.cameraLerp));
    camera.viewfinder.position = Vector2(0, newY);
  }

  void setPaused(bool value) {
    world.setPaused(value);
    paused = value;
  }

  void requestSecondChance() {
    world.applySecondChance();
  }
}
