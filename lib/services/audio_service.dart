import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../state/game_progress.dart';

/// Haptic event types (audio removed — vibration only).
enum Sfx {
  buttonClick,
  blockLand,
  blockFall,
  levelComplete,
}

/// Kept for API compatibility — audio is disabled on this build.
enum Bgm { menu, gameplay }

/// Haptic-only feedback service. All sound methods are no-ops; vibration
/// uses [HapticFeedback] with intensity matched to the event type.
class AudioService with WidgetsBindingObserver {
  AudioService._(this._progress);

  static AudioService? _instance;
  static AudioService get instance {
    final i = _instance;
    if (i == null) throw StateError('AudioService.init() must be called first');
    return i;
  }

  final GameProgress _progress;

  static Future<void> init(GameProgress progress) async {
    if (_instance != null) return;
    _instance = AudioService._(progress);
    WidgetsBinding.instance.addObserver(_instance!);
  }

  /// No-op — background music is disabled.
  Future<void> playBgm(Bgm bgm) async {}

  /// No-op — background music is disabled.
  Future<void> stopBgm() async {}

  /// Triggers haptic feedback appropriate for the given [sfx] event.
  Future<void> playSfx(Sfx sfx) async {
    if (!_progress.vibrationEnabled) return;
    switch (sfx) {
      case Sfx.buttonClick:
        await HapticFeedback.lightImpact();
      case Sfx.blockLand:
        await HapticFeedback.mediumImpact();
      case Sfx.blockFall:
        await HapticFeedback.heavyImpact();
      case Sfx.levelComplete:
        // Double tap for a satisfying level-complete feel.
        await HapticFeedback.heavyImpact();
        await Future<void>.delayed(const Duration(milliseconds: 120));
        await HapticFeedback.mediumImpact();
    }
  }

  /// Explicit vibration call — used by game components on impact.
  Future<void> vibrate({bool heavy = false}) async {
    if (!_progress.vibrationEnabled) return;
    if (heavy) {
      await HapticFeedback.heavyImpact();
    } else {
      await HapticFeedback.mediumImpact();
    }
  }
}
