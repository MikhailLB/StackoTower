import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../state/game_progress.dart';

enum Sfx {
  buttonClick,
  blockLand,
  blockFall,
  levelComplete,
}

enum Bgm { menu, gameplay }

/// No-op audio stub — all sound has been removed.
/// The class keeps its public API so no call sites need to change.
class AudioService with WidgetsBindingObserver {
  AudioService._();

  static AudioService? _instance;
  static AudioService get instance => _instance!;

  static Future<void> init(GameProgress progress) async {
    if (_instance != null) return;
    _instance = AudioService._();
  }

  Future<void> playBgm(Bgm bgm) async {}
  Future<void> stopBgm() async {}
  Future<void> playSfx(Sfx sfx) async {}

  Future<void> vibrate({bool heavy = false}) async {
    if (heavy) {
      await HapticFeedback.heavyImpact();
    } else {
      await HapticFeedback.mediumImpact();
    }
  }
}
