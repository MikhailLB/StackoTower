import 'package:shared_preferences/shared_preferences.dart';

/// Persistent storage for player progress and preferences.
class StorageService {
  StorageService._(this._prefs);

  static const _kHighScore = 'fb_high_score';
  static const _kCoins = 'fb_coins';
  static const _kOwnedSkins = 'fb_owned_skins';
  static const _kSelectedSkin = 'fb_selected_skin';
  static const _kHighestUnlockedLevel = 'fb_highest_unlocked_level';
  static const _kCompletedLevels = 'fb_completed_levels';
  static const _kTutorialSeen = 'fb_tutorial_seen';
  static const _kBoostSkip = 'fb_boost_skip';
  static const _kBoostDoubleCoins = 'fb_boost_double_coins';
  static const _kBoostLucky = 'fb_boost_lucky';
  static const _kVibrationEnabled = 'fb_vibration_enabled';

  final SharedPreferences _prefs;

  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    final service = StorageService._(prefs);
    await service._seedDefaults();
    return service;
  }

  Future<void> _seedDefaults() async {
    if (!_prefs.containsKey(_kOwnedSkins)) {
      await _prefs.setStringList(_kOwnedSkins, ['1']);
    }
    if (!_prefs.containsKey(_kSelectedSkin)) {
      await _prefs.setInt(_kSelectedSkin, 0);
    }
    if (!_prefs.containsKey(_kHighestUnlockedLevel)) {
      await _prefs.setInt(_kHighestUnlockedLevel, 1);
    }
    if (!_prefs.containsKey(_kVibrationEnabled)) {
      await _prefs.setBool(_kVibrationEnabled, true);
    }
  }

  int get highScore => _prefs.getInt(_kHighScore) ?? 0;
  int get coins => _prefs.getInt(_kCoins) ?? 0;
  int get highestUnlockedLevel => _prefs.getInt(_kHighestUnlockedLevel) ?? 1;
  Set<int> get completedLevels =>
      (_prefs.getStringList(_kCompletedLevels) ?? const [])
          .map(int.parse)
          .toSet();
  int get skipBoosts => _prefs.getInt(_kBoostSkip) ?? 0;
  int get doubleCoinsBoosts => _prefs.getInt(_kBoostDoubleCoins) ?? 0;
  int get luckyBoosts => _prefs.getInt(_kBoostLucky) ?? 0;
  bool get tutorialSeen => _prefs.getBool(_kTutorialSeen) ?? false;
  bool get vibrationEnabled => _prefs.getBool(_kVibrationEnabled) ?? true;
  List<int> get ownedSkins =>
      (_prefs.getStringList(_kOwnedSkins) ?? const ['1'])
          .map(int.parse)
          .toList()
        ..sort();
  int get selectedSkin => _prefs.getInt(_kSelectedSkin) ?? 0;

  Future<void> setHighScore(int v) => _prefs.setInt(_kHighScore, v);
  Future<void> setCoins(int v) => _prefs.setInt(_kCoins, v);
  Future<void> setHighestUnlockedLevel(int v) =>
      _prefs.setInt(_kHighestUnlockedLevel, v);
  Future<void> setCompletedLevels(Set<int> levels) => _prefs.setStringList(
        _kCompletedLevels,
        levels.map((e) => e.toString()).toList(),
      );
  Future<void> setSkipBoosts(int v) => _prefs.setInt(_kBoostSkip, v);
  Future<void> setDoubleCoinsBoosts(int v) =>
      _prefs.setInt(_kBoostDoubleCoins, v);
  Future<void> setLuckyBoosts(int v) => _prefs.setInt(_kBoostLucky, v);
  Future<void> setTutorialSeen(bool v) => _prefs.setBool(_kTutorialSeen, v);
  Future<void> setVibrationEnabled(bool v) =>
      _prefs.setBool(_kVibrationEnabled, v);
  Future<void> setSelectedSkin(int skin) =>
      _prefs.setInt(_kSelectedSkin, skin);

  Future<void> addOwnedSkin(int skin) async {
    final list = ownedSkins;
    if (!list.contains(skin)) {
      list.add(skin);
      await _prefs.setStringList(
        _kOwnedSkins,
        list.map((e) => e.toString()).toList(),
      );
    }
  }
}
