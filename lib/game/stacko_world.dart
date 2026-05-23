import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';

import '../services/audio_service.dart';
import 'components/cloud.dart';
import 'components/ground.dart';
import 'components/hook.dart';
import 'components/sky_background.dart';
import 'components/start_bg.dart';
import 'components/start_building.dart';
import 'components/stacko_block.dart';
import 'level_config.dart';
import 'stacko_constants.dart';
import 'stacko_game.dart';
import 'stacko_status.dart';

/// Hosts every world-space component (background, blocks, hook, ground) and
/// drives the gameplay state machine.
class StackoWorld extends Forge2DWorld with HasGameReference<StackoGame> {
  StackoWorld({
    required this.skinPicker,
    required this.levelConfig,
    this.slowHookEnabled = false,
    this.ghostBlockEnabled = false,
    this.speedFreezeEnabled = false,
    this.wideBaseEnabled = false,
  }) : hook = Hook(skinIndexProvider: skinPicker);

  final int Function() skinPicker;
  final LevelConfig levelConfig;
  final bool slowHookEnabled;
  final bool ghostBlockEnabled;
  final bool speedFreezeEnabled;
  final bool wideBaseEnabled;

  final Hook hook;
  final List<StackoBlock> _placedBlocks = [];
  StackoBlock? _activeBlock;

  double currentTopY = StackoConstants.startBuildingTopY;
  double _settleTimer = 0;
  double _fallTimer = 0;

  final ValueNotifier<int> score = ValueNotifier(0);
  final ValueNotifier<StackoStatus> status =
      ValueNotifier(StackoStatus.ready);

  bool _secondChanceUsedThisRun = false;
  bool _ghostBlockUsedThisRun = false;

  double _slowHookSecondsRemaining = 0;
  static const _slowHookFactor = 1.8;

  int _speedFreezeBlocksRemaining = 0;
  int _wideBaseBlocksRemaining = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await add(SkyBackground());
    await add(StartBg());
    await add(GroundDecal());
    await add(Ground());
    await add(StartBuilding());
    await add(hook);
    await add(CloudLayer());
  }

  void startRound() {
    _placedBlocks.clear();
    _activeBlock = null;
    _settleTimer = 0;
    _fallTimer = 0;
    score.value = 0;
    currentTopY = StackoConstants.startBuildingTopY;
    hook.topY = currentTopY;
    hook.halfPeriod = StackoConstants.hookInitialHalfPeriod /
        levelConfig.hookSpeedMultiplier;
    _secondChanceUsedThisRun = false;
    _ghostBlockUsedThisRun = false;
    if (slowHookEnabled) {
      _slowHookSecondsRemaining = 6.0;
    }
    if (speedFreezeEnabled) {
      _speedFreezeBlocksRemaining = 10;
    }
    if (wideBaseEnabled) {
      _wideBaseBlocksRemaining = 3;
    }
    status.value = StackoStatus.swinging;
  }

  void dropBlock() {
    if (status.value != StackoStatus.swinging || !hook.hasBlock) return;
    final spawnPos = Vector2(hook.currentX, hook.currentY);
    final velocity = Vector2(hook.currentVelocityX, 0);
    final block = StackoBlock(
      skinIndex: skinPicker(),
      spawnPosition: spawnPos,
      spawnVelocity: velocity,
      spawnAngularVelocity: 0,
    );
    _activeBlock = block;
    add(block);
    hook.releaseBlock();
    _settleTimer = 0;
    _fallTimer = 0;
    status.value = StackoStatus.falling;
  }

  void applySecondChance() {
    if (status.value != StackoStatus.gameOver) return;
    if (_secondChanceUsedThisRun) return;
    _secondChanceUsedThisRun = true;
    _removeActiveBlock();
    hook.attachNewBlock();
    status.value = StackoStatus.swinging;
    _settleTimer = 0;
    _fallTimer = 0;
  }

  void setPaused(bool value) {
    if (value) {
      if (status.value == StackoStatus.swinging ||
          status.value == StackoStatus.falling) {
        status.value = StackoStatus.paused;
      }
    } else {
      if (status.value == StackoStatus.paused) {
        status.value = _activeBlock != null
            ? StackoStatus.falling
            : StackoStatus.swinging;
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (status.value == StackoStatus.ready ||
        status.value == StackoStatus.paused ||
        status.value == StackoStatus.gameOver ||
        status.value == StackoStatus.levelComplete) {
      return;
    }

    _updateHookSpeed(dt);

    var top = StackoConstants.startBuildingTopY;
    for (final b in _placedBlocks) {
      final t = b.topY;
      if (t < top) top = t;
    }
    if (_activeBlock != null && _activeBlock!.placed) {
      final t = _activeBlock!.topY;
      if (t < top) top = t;
    }
    currentTopY = top;
    hook.topY = currentTopY;
    hook.cameraCenterY = game.camera.viewfinder.position.y;

    if (status.value == StackoStatus.falling && _activeBlock != null) {
      _evaluateFalling(dt);
    }
  }

  void _updateHookSpeed(double dt) {
    final placed = _placedBlocks.length;
    double base;
    if (_speedFreezeBlocksRemaining > 0) {
      base = StackoConstants.hookInitialHalfPeriod /
          levelConfig.hookSpeedMultiplier;
    } else {
      final raw = (StackoConstants.hookInitialHalfPeriod /
              levelConfig.hookSpeedMultiplier) -
          placed * StackoConstants.hookSpeedUpPerBlock;
      base = math.max(
        StackoConstants.hookMinHalfPeriod / levelConfig.hookSpeedMultiplier,
        raw,
      );
    }

    if (_slowHookSecondsRemaining > 0) {
      _slowHookSecondsRemaining = math.max(0, _slowHookSecondsRemaining - dt);
      hook.halfPeriod = base * _slowHookFactor;
    } else {
      hook.halfPeriod = base;
    }
  }

  void _evaluateFalling(double dt) {
    final block = _activeBlock!;
    if (!block.isMounted) return;
    final body = block.body;
    final v = body.linearVelocity;
    final speed = v.length;

    _fallTimer += dt;
    if (speed < StackoConstants.settleSpeedThreshold) {
      _settleTimer += dt;
    } else {
      _settleTimer = 0;
    }

    final settled = _settleTimer >= StackoConstants.settleHoldSeconds;
    final timedOut = _fallTimer >= StackoConstants.settleTimeoutSeconds;
    final fellThrough =
        body.position.y > StackoConstants.groundTopY - 0.4;

    if (fellThrough) {
      _handleFail();
      return;
    }
    if (settled || timedOut) {
      _handleLanding();
    }
  }

  void _handleLanding() {
    final block = _activeBlock!;
    final blockTop = block.topY;
    final blockX = block.body.position.x;

    final supportTop = _findSupportTopAt(blockX, exclude: block);
    final supportingBlock = _findTopBlock(exclude: block);

    final landedAboveSomething = blockTop < supportTop + 0.05;
    final overlap = supportingBlock == null
        ? StackoConstants.blockWidth
        : _horizontalOverlap(block, supportingBlock);
    final tilt = block.body.angle.abs();

    final effectiveMinOverlap = _wideBaseBlocksRemaining > 0
        ? StackoConstants.minOverlapToCount *
            levelConfig.overlapMultiplier /
            2.0
        : StackoConstants.minOverlapToCount * levelConfig.overlapMultiplier;

    final tooMuchTilt = tilt > 0.7;
    final tooLittleOverlap = overlap < effectiveMinOverlap;

    if (!landedAboveSomething || tooMuchTilt || tooLittleOverlap) {
      _handleFail();
      return;
    }

    block.placed = true;
    _placedBlocks.add(block);
    score.value = _placedBlocks.length * StackoConstants.baseRewardPerBlock;
    _activeBlock = null;
    _settleTimer = 0;
    _fallTimer = 0;

    if (_speedFreezeBlocksRemaining > 0) _speedFreezeBlocksRemaining--;
    if (_wideBaseBlocksRemaining > 0) _wideBaseBlocksRemaining--;

    // Check level complete.
    if (_placedBlocks.length >= levelConfig.targetBlocks) {
      status.value = StackoStatus.levelComplete;
      return;
    }

    hook.attachNewBlock();
    status.value = StackoStatus.swinging;
  }

  void _handleFail() {
    // Ghost block: silently forgive one bad placement (no game over overlay).
    if (ghostBlockEnabled && !_ghostBlockUsedThisRun) {
      _ghostBlockUsedThisRun = true;
      _removeActiveBlock();
      hook.attachNewBlock();
      status.value = StackoStatus.swinging;
      _settleTimer = 0;
      _fallTimer = 0;
      return;
    }
    AudioService.instance.playSfx(Sfx.blockFall);
    AudioService.instance.vibrate(heavy: true);
    status.value = StackoStatus.gameOver;
  }

  void _removeActiveBlock() {
    final block = _activeBlock;
    _activeBlock = null;
    if (block != null && block.isMounted) {
      block.removeFromParent();
    }
  }

  StackoBlock? _findTopBlock({StackoBlock? exclude}) {
    StackoBlock? top;
    var minY = double.infinity;
    for (final b in _placedBlocks) {
      if (identical(b, exclude)) continue;
      final y = b.topY;
      if (y < minY) {
        minY = y;
        top = b;
      }
    }
    return top;
  }

  double _findSupportTopAt(double x, {StackoBlock? exclude}) {
    final hw = StackoConstants.startBuildingWidth / 2;
    var best = double.infinity;
    if (x.abs() <= hw) {
      best = StackoConstants.startBuildingTopY;
    }
    for (final b in _placedBlocks) {
      if (identical(b, exclude)) continue;
      final dx = (b.body.position.x - x).abs();
      if (dx < StackoConstants.blockWidth / 2 + 0.1) {
        final y = b.topY;
        if (y < best) best = y;
      }
    }
    return best;
  }

  double _horizontalOverlap(StackoBlock a, StackoBlock b) {
    final aLeft = a.body.position.x - StackoConstants.blockWidth / 2;
    final aRight = a.body.position.x + StackoConstants.blockWidth / 2;
    final bLeft = b.body.position.x - StackoConstants.blockWidth / 2;
    final bRight = b.body.position.x + StackoConstants.blockWidth / 2;
    final overlap =
        math.min(aRight, bRight) - math.max(aLeft, bLeft);
    return overlap.clamp(0, StackoConstants.blockWidth).toDouble();
  }
}
