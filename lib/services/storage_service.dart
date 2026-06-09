import 'package:shared_preferences/shared_preferences.dart';

/// Persistent storage for player progress and preferences.
class StorageService {
  StorageService._(this._prefs);

  // --- Keys ---
  static const _kHighScore = 'st_high_score';
  static const _kCoins = 'st_coins';
  static const _kOwnedSkins = 'st_owned_skins';
  static const _kSelectedSkin = 'st_selected_skin';
  static const _kHighestUnlockedLevel = 'st_highest_unlocked_level';
  static const _kCompletedLevels = 'st_completed_levels';
  static const _kTutorialSeen = 'st_tutorial_seen';
  // Power-ups
  static const _kBoostSkip = 'st_boost_skip';
  static const _kBoostDoubleCoins = 'st_boost_double_coins';
  static const _kBoostLucky = 'st_boost_lucky';
  // Audio
  static const _kSoundEnabled = 'st_sound_enabled';
  static const _kMusicEnabled = 'st_music_enabled';
  static const _kVibrationEnabled = 'st_vibration_enabled';
  static const _kMusicVolume = 'st_music_volume';
  static const _kSfxVolume = 'st_sfx_volume';
  // Stars ("level:stars" entries)
  static const _kLevelStars = 'st_level_stars';
  // Road themes
  static const _kOwnedThemes = 'st_owned_themes';
  static const _kSelectedTheme = 'st_selected_theme';
  // Endless shift mode
  static const _kEndlessSolved = 'st_endless_solved';
  static const _kEndlessBestStreak = 'st_endless_best_streak';
  // Daily blueprint
  static const _kDailyStreak = 'st_daily_streak';
  static const _kDailyLastSolved = 'st_daily_last_solved';
  static const _kDailySolvedTotal = 'st_daily_solved_total';
  // Daily login bonus
  static const _kBonusLastClaim = 'st_bonus_last_claim';
  static const _kBonusStreak = 'st_bonus_streak';
  // Achievements
  static const _kAchievements = 'st_achievements';
  // Lifetime statistics
  static const _kStatPlotsPaved = 'st_stat_plots_paved';
  static const _kStatUndos = 'st_stat_undos';
  static const _kStatPerfect = 'st_stat_perfect';
  static const _kStatCoinsEarned = 'st_stat_coins_earned';
  static const _kStatCompletes = 'st_stat_completes';
  static const _kStatPlaySeconds = 'st_stat_play_seconds';
  static const _kStatBoostsUsed = 'st_stat_boosts_used';

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
    if (!_prefs.containsKey(_kSoundEnabled)) {
      await _prefs.setBool(_kSoundEnabled, true);
    }
    if (!_prefs.containsKey(_kMusicEnabled)) {
      await _prefs.setBool(_kMusicEnabled, true);
    }
    if (!_prefs.containsKey(_kVibrationEnabled)) {
      await _prefs.setBool(_kVibrationEnabled, true);
    }
    if (!_prefs.containsKey(_kMusicVolume)) {
      await _prefs.setDouble(_kMusicVolume, 0.6);
    }
    if (!_prefs.containsKey(_kSfxVolume)) {
      await _prefs.setDouble(_kSfxVolume, 0.8);
    }
    if (!_prefs.containsKey(_kOwnedThemes)) {
      await _prefs.setStringList(_kOwnedThemes, ['0']);
    }
  }

  // --- Getters ---
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
  bool get soundEnabled => _prefs.getBool(_kSoundEnabled) ?? true;
  bool get musicEnabled => _prefs.getBool(_kMusicEnabled) ?? true;
  bool get vibrationEnabled => _prefs.getBool(_kVibrationEnabled) ?? true;
  double get musicVolume => _prefs.getDouble(_kMusicVolume) ?? 0.6;
  double get sfxVolume => _prefs.getDouble(_kSfxVolume) ?? 0.8;
  List<int> get ownedSkins =>
      (_prefs.getStringList(_kOwnedSkins) ?? const ['1'])
          .map(int.parse)
          .toList()
        ..sort();
  int get selectedSkin => _prefs.getInt(_kSelectedSkin) ?? 0;
  Map<int, int> get levelStars {
    final out = <int, int>{};
    for (final e in _prefs.getStringList(_kLevelStars) ?? const <String>[]) {
      final parts = e.split(':');
      if (parts.length == 2) {
        final l = int.tryParse(parts[0]);
        final s = int.tryParse(parts[1]);
        if (l != null && s != null) out[l] = s;
      }
    }
    return out;
  }

  List<int> get ownedThemes =>
      (_prefs.getStringList(_kOwnedThemes) ?? const ['0'])
          .map(int.parse)
          .toList()
        ..sort();
  int get selectedTheme => _prefs.getInt(_kSelectedTheme) ?? 0;
  int get endlessSolved => _prefs.getInt(_kEndlessSolved) ?? 0;
  int get endlessBestStreak => _prefs.getInt(_kEndlessBestStreak) ?? 0;
  int get dailyStreak => _prefs.getInt(_kDailyStreak) ?? 0;
  String get dailyLastSolved => _prefs.getString(_kDailyLastSolved) ?? '';
  int get dailySolvedTotal => _prefs.getInt(_kDailySolvedTotal) ?? 0;
  String get bonusLastClaim => _prefs.getString(_kBonusLastClaim) ?? '';
  int get bonusStreak => _prefs.getInt(_kBonusStreak) ?? 0;
  Set<String> get achievements =>
      (_prefs.getStringList(_kAchievements) ?? const <String>[]).toSet();
  int get statPlotsPaved => _prefs.getInt(_kStatPlotsPaved) ?? 0;
  int get statUndos => _prefs.getInt(_kStatUndos) ?? 0;
  int get statPerfect => _prefs.getInt(_kStatPerfect) ?? 0;
  int get statCoinsEarned => _prefs.getInt(_kStatCoinsEarned) ?? 0;
  int get statCompletes => _prefs.getInt(_kStatCompletes) ?? 0;
  int get statPlaySeconds => _prefs.getInt(_kStatPlaySeconds) ?? 0;
  int get statBoostsUsed => _prefs.getInt(_kStatBoostsUsed) ?? 0;

  // --- Setters ---
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
  Future<void> setSoundEnabled(bool v) => _prefs.setBool(_kSoundEnabled, v);
  Future<void> setMusicEnabled(bool v) => _prefs.setBool(_kMusicEnabled, v);
  Future<void> setVibrationEnabled(bool v) =>
      _prefs.setBool(_kVibrationEnabled, v);
  Future<void> setMusicVolume(double v) => _prefs.setDouble(_kMusicVolume, v);
  Future<void> setSfxVolume(double v) => _prefs.setDouble(_kSfxVolume, v);
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

  Future<void> setLevelStars(Map<int, int> stars) => _prefs.setStringList(
        _kLevelStars,
        stars.entries.map((e) => '${e.key}:${e.value}').toList(),
      );

  Future<void> addOwnedTheme(int theme) async {
    final list = ownedThemes;
    if (!list.contains(theme)) {
      list.add(theme);
      await _prefs.setStringList(
        _kOwnedThemes,
        list.map((e) => e.toString()).toList(),
      );
    }
  }

  Future<void> setSelectedTheme(int theme) =>
      _prefs.setInt(_kSelectedTheme, theme);
  Future<void> setEndlessSolved(int v) => _prefs.setInt(_kEndlessSolved, v);
  Future<void> setEndlessBestStreak(int v) =>
      _prefs.setInt(_kEndlessBestStreak, v);
  Future<void> setDailyStreak(int v) => _prefs.setInt(_kDailyStreak, v);
  Future<void> setDailyLastSolved(String v) =>
      _prefs.setString(_kDailyLastSolved, v);
  Future<void> setDailySolvedTotal(int v) =>
      _prefs.setInt(_kDailySolvedTotal, v);
  Future<void> setBonusLastClaim(String v) =>
      _prefs.setString(_kBonusLastClaim, v);
  Future<void> setBonusStreak(int v) => _prefs.setInt(_kBonusStreak, v);
  Future<void> setAchievements(Set<String> ids) =>
      _prefs.setStringList(_kAchievements, ids.toList());
  Future<void> setStatPlotsPaved(int v) => _prefs.setInt(_kStatPlotsPaved, v);
  Future<void> setStatUndos(int v) => _prefs.setInt(_kStatUndos, v);
  Future<void> setStatPerfect(int v) => _prefs.setInt(_kStatPerfect, v);
  Future<void> setStatCoinsEarned(int v) =>
      _prefs.setInt(_kStatCoinsEarned, v);
  Future<void> setStatCompletes(int v) => _prefs.setInt(_kStatCompletes, v);
  Future<void> setStatPlaySeconds(int v) =>
      _prefs.setInt(_kStatPlaySeconds, v);
  Future<void> setStatBoostsUsed(int v) => _prefs.setInt(_kStatBoostsUsed, v);
}
