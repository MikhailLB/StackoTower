import 'package:flutter/foundation.dart';

import '../services/storage_service.dart';

/// In-memory mirror of [StorageService] that notifies the UI on changes.
class GameProgress extends ChangeNotifier {
  GameProgress(this._storage)
      : _coins = _storage.coins,
        _highScore = _storage.highScore,
        _highestUnlockedLevel = _storage.highestUnlockedLevel,
        _completedLevels = Set<int>.from(_storage.completedLevels),
        _skipBoosts = _storage.skipBoosts,
        _doubleCoinsBoosts = _storage.doubleCoinsBoosts,
        _luckyBoosts = _storage.luckyBoosts,
        _slowBoosts = _storage.slowBoosts,
        _widenBoosts = _storage.widenBoosts,
        _storySeen = _storage.storySeen,
        _tipsSeen = Set<String>.from(_storage.tipsSeen),
        _upBase = _storage.upBase,
        _upSteady = _storage.upSteady,
        _upPayout = _storage.upPayout,
        _bossesBeaten = Set<int>.from(_storage.bossesBeaten),
        _ownedSkins = List<int>.from(_storage.ownedSkins),
        _selectedSkin = _storage.selectedSkin,
        _tutorialSeen = _storage.tutorialSeen,
        _soundEnabled = _storage.soundEnabled,
        _musicEnabled = _storage.musicEnabled,
        _vibrationEnabled = _storage.vibrationEnabled,
        _musicVolume = _storage.musicVolume,
        _sfxVolume = _storage.sfxVolume,
        _levelStars = Map<int, int>.from(_storage.levelStars),
        _ownedThemes = List<int>.from(_storage.ownedThemes),
        _selectedTheme = _storage.selectedTheme,
        _endlessSolved = _storage.endlessSolved,
        _endlessBestStreak = _storage.endlessBestStreak,
        _dailyStreak = _storage.dailyStreak,
        _dailyLastSolved = _storage.dailyLastSolved,
        _dailySolvedTotal = _storage.dailySolvedTotal,
        _bonusLastClaim = _storage.bonusLastClaim,
        _bonusStreak = _storage.bonusStreak,
        _achievements = Set<String>.from(_storage.achievements),
        _statPlotsPaved = _storage.statPlotsPaved,
        _statUndos = _storage.statUndos,
        _statPerfect = _storage.statPerfect,
        _statCoinsEarned = _storage.statCoinsEarned,
        _statCompletes = _storage.statCompletes,
        _statPlaySeconds = _storage.statPlaySeconds,
        _statBoostsUsed = _storage.statBoostsUsed;

  final StorageService _storage;

  int _coins;
  int _highScore;
  int _highestUnlockedLevel;
  final Set<int> _completedLevels;
  int _skipBoosts;
  int _doubleCoinsBoosts;
  int _luckyBoosts;
  int _slowBoosts;
  int _widenBoosts;
  bool _storySeen;
  final Set<String> _tipsSeen;
  int _upBase;
  int _upSteady;
  int _upPayout;
  final Set<int> _bossesBeaten;

  static const int upMaxLevel = 5;
  List<int> _ownedSkins;
  int _selectedSkin;
  bool _tutorialSeen;
  bool _soundEnabled;
  bool _musicEnabled;
  bool _vibrationEnabled;
  double _musicVolume;
  double _sfxVolume;
  final Map<int, int> _levelStars;
  List<int> _ownedThemes;
  int _selectedTheme;
  int _endlessSolved;
  int _endlessBestStreak;
  int _dailyStreak;
  String _dailyLastSolved;
  int _dailySolvedTotal;
  String _bonusLastClaim;
  int _bonusStreak;
  final Set<String> _achievements;
  int _statPlotsPaved;
  int _statUndos;
  int _statPerfect;
  int _statCoinsEarned;
  int _statCompletes;
  int _statPlaySeconds;
  int _statBoostsUsed;

  int get coins => _coins;
  int get highScore => _highScore;
  int get highestUnlockedLevel => _highestUnlockedLevel;
  Set<int> get completedLevels => Set.unmodifiable(_completedLevels);
  int get skipBoosts => _skipBoosts;
  int get doubleCoinsBoosts => _doubleCoinsBoosts;
  int get luckyBoosts => _luckyBoosts;
  int get slowBoosts => _slowBoosts;
  int get widenBoosts => _widenBoosts;
  bool get storySeen => _storySeen;

  // --- Crane upgrades (permanent meta-progression) ---
  int get upBase => _upBase;
  int get upSteady => _upSteady;
  int get upPayout => _upPayout;

  /// Extra base half-width granted by the "Wide Base" upgrade.
  double get extraBaseHalf => _upBase * 0.012;

  /// Swing-speed multiplier from the "Steady Crane" upgrade (slower = easier).
  double get speedMul => 1 - _upSteady * 0.04;

  /// Coin reward multiplier from the "Payout" upgrade.
  double get payoutMul => 1 + _upPayout * 0.10;

  int upgradeLevel(String id) {
    switch (id) {
      case 'base':
        return _upBase;
      case 'steady':
        return _upSteady;
      case 'payout':
        return _upPayout;
      default:
        return 0;
    }
  }

  /// Price of the next level of an upgrade (escalates).
  int upgradePrice(String id) => 200 + upgradeLevel(id) * 250;

  /// Buys the next level of an upgrade if affordable & not maxed.
  Future<bool> buyUpgrade(String id) async {
    final lvl = upgradeLevel(id);
    if (lvl >= upMaxLevel) return false;
    if (!await spendCoins(upgradePrice(id))) return false;
    switch (id) {
      case 'base':
        _upBase++;
        await _storage.setUpBase(_upBase);
        break;
      case 'steady':
        _upSteady++;
        await _storage.setUpSteady(_upSteady);
        break;
      case 'payout':
        _upPayout++;
        await _storage.setUpPayout(_upPayout);
        break;
    }
    notifyListeners();
    return true;
  }

  // --- Bosses ---
  bool isBossBeaten(int districtIndex) => _bossesBeaten.contains(districtIndex);
  int get bossesBeaten => _bossesBeaten.length;
  Future<void> markBossBeaten(int districtIndex) async {
    if (!_bossesBeaten.add(districtIndex)) return;
    await _storage.setBossesBeaten(_bossesBeaten);
    notifyListeners();
  }

  bool hasTip(String id) => _tipsSeen.contains(id);
  Future<void> markTipSeen(String id) async {
    if (!_tipsSeen.add(id)) return;
    await _storage.setTipsSeen(_tipsSeen);
  }

  Future<void> setStorySeen() async {
    if (_storySeen) return;
    _storySeen = true;
    await _storage.setStorySeen(true);
  }
  List<int> get ownedSkins => List.unmodifiable(_ownedSkins);
  int get selectedSkin => _selectedSkin;
  bool get tutorialSeen => _tutorialSeen;
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;
  Map<int, int> get levelStars => Map.unmodifiable(_levelStars);
  List<int> get ownedThemes => List.unmodifiable(_ownedThemes);
  int get selectedTheme => _selectedTheme;
  int get endlessSolved => _endlessSolved;
  int get endlessBestStreak => _endlessBestStreak;
  int get dailyStreak => _dailyStreak;
  int get dailySolvedTotal => _dailySolvedTotal;
  Set<String> get achievements => Set.unmodifiable(_achievements);
  int get statPlotsPaved => _statPlotsPaved;
  int get statUndos => _statUndos;
  int get statPerfect => _statPerfect;
  int get statCoinsEarned => _statCoinsEarned;
  int get statCompletes => _statCompletes;
  int get statPlaySeconds => _statPlaySeconds;
  int get statBoostsUsed => _statBoostsUsed;

  int starsFor(int levelNumber) => _levelStars[levelNumber] ?? 0;
  int get totalStars =>
      _levelStars.values.fold(0, (sum, s) => sum + s);

  static String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool isDailySolved(DateTime now) => _dailyLastSolved == dateKey(now);

  // --- Coins & score ---

  Future<void> addCoins(int amount) async {
    if (amount <= 0) return;
    _coins += amount;
    _statCoinsEarned += amount;
    await _storage.setCoins(_coins);
    await _storage.setStatCoinsEarned(_statCoinsEarned);
    notifyListeners();
  }

  Future<bool> spendCoins(int amount) async {
    if (amount <= 0 || _coins < amount) return false;
    _coins -= amount;
    await _storage.setCoins(_coins);
    notifyListeners();
    return true;
  }

  Future<void> setHighScore(int score) async {
    if (score <= _highScore) return;
    _highScore = score;
    await _storage.setHighScore(_highScore);
    notifyListeners();
  }

  // --- Levels ---

  Future<void> completeLevel(int levelNumber) async {
    _completedLevels.add(levelNumber);
    await _storage.setCompletedLevels(_completedLevels);
    if (levelNumber >= _highestUnlockedLevel) {
      _highestUnlockedLevel = levelNumber + 1;
      await _storage.setHighestUnlockedLevel(_highestUnlockedLevel);
    }
    notifyListeners();
  }

  bool isLevelUnlocked(int levelNumber) =>
      levelNumber <= _highestUnlockedLevel;

  bool isLevelCompleted(int levelNumber) =>
      _completedLevels.contains(levelNumber);

  // --- Stars ---

  /// Stores [stars] for a level if it beats the previous best.
  /// Returns the number of newly earned stars (0 if no improvement).
  Future<int> recordLevelStars(int levelNumber, int stars) async {
    final prev = _levelStars[levelNumber] ?? 0;
    if (stars <= prev) return 0;
    _levelStars[levelNumber] = stars;
    await _storage.setLevelStars(_levelStars);
    notifyListeners();
    return stars - prev;
  }

  // --- Endless shift ---

  Future<void> recordEndlessSolve(int currentStreak) async {
    _endlessSolved++;
    await _storage.setEndlessSolved(_endlessSolved);
    if (currentStreak > _endlessBestStreak) {
      _endlessBestStreak = currentStreak;
      await _storage.setEndlessBestStreak(_endlessBestStreak);
    }
    notifyListeners();
  }

  // --- Daily blueprint ---

  /// Records today's daily puzzle as solved and returns the new streak.
  Future<int> recordDailySolve(DateTime now) async {
    final today = dateKey(now);
    if (_dailyLastSolved == today) return _dailyStreak;
    final yesterday = dateKey(now.subtract(const Duration(days: 1)));
    _dailyStreak = _dailyLastSolved == yesterday ? _dailyStreak + 1 : 1;
    _dailyLastSolved = today;
    _dailySolvedTotal++;
    await _storage.setDailyStreak(_dailyStreak);
    await _storage.setDailyLastSolved(_dailyLastSolved);
    await _storage.setDailySolvedTotal(_dailySolvedTotal);
    notifyListeners();
    return _dailyStreak;
  }

  // --- Daily login bonus ---

  bool canClaimDailyBonus(DateTime now) => _bonusLastClaim != dateKey(now);

  /// Bonus amount for the next claim (escalates with streak, capped at day 7).
  int nextDailyBonus(DateTime now) {
    final yesterday = dateKey(now.subtract(const Duration(days: 1)));
    final streak = _bonusLastClaim == yesterday ? _bonusStreak + 1 : 1;
    return 25 * streak.clamp(1, 7);
  }

  int get bonusStreak => _bonusStreak;

  /// Claims today's login bonus; returns the granted coins (0 if claimed).
  Future<int> claimDailyBonus(DateTime now) async {
    final today = dateKey(now);
    if (_bonusLastClaim == today) return 0;
    final amount = nextDailyBonus(now);
    final yesterday = dateKey(now.subtract(const Duration(days: 1)));
    _bonusStreak = _bonusLastClaim == yesterday ? _bonusStreak + 1 : 1;
    _bonusLastClaim = today;
    await _storage.setBonusStreak(_bonusStreak);
    await _storage.setBonusLastClaim(_bonusLastClaim);
    await addCoins(amount);
    return amount;
  }

  // --- Achievements ---

  bool hasAchievement(String id) => _achievements.contains(id);

  Future<void> unlockAchievement(String id) async {
    if (!_achievements.add(id)) return;
    await _storage.setAchievements(_achievements);
    notifyListeners();
  }

  // --- Lifetime statistics ---

  Future<void> recordRoundStats({
    required int plotsPaved,
    required int undos,
    required bool perfect,
    required int playSeconds,
  }) async {
    _statPlotsPaved += plotsPaved;
    _statUndos += undos;
    if (perfect) _statPerfect++;
    _statCompletes++;
    _statPlaySeconds += playSeconds;
    await _storage.setStatPlotsPaved(_statPlotsPaved);
    await _storage.setStatUndos(_statUndos);
    await _storage.setStatPerfect(_statPerfect);
    await _storage.setStatCompletes(_statCompletes);
    await _storage.setStatPlaySeconds(_statPlaySeconds);
    notifyListeners();
  }

  Future<void> recordBoostUsed() async {
    _statBoostsUsed++;
    await _storage.setStatBoostsUsed(_statBoostsUsed);
    notifyListeners();
  }

  // --- Road themes ---

  Future<void> setSelectedTheme(int theme) async {
    _selectedTheme = theme;
    await _storage.setSelectedTheme(theme);
    notifyListeners();
  }

  Future<void> unlockTheme(int theme) async {
    if (_ownedThemes.contains(theme)) return;
    _ownedThemes = [..._ownedThemes, theme]..sort();
    await _storage.addOwnedTheme(theme);
    notifyListeners();
  }

  // --- Skins ---

  Future<void> setSelectedSkin(int skin) async {
    _selectedSkin = skin;
    await _storage.setSelectedSkin(skin);
    notifyListeners();
  }

  Future<void> unlockSkin(int skin) async {
    if (_ownedSkins.contains(skin)) return;
    _ownedSkins = [..._ownedSkins, skin]..sort();
    await _storage.addOwnedSkin(skin);
    notifyListeners();
  }

  // --- Tutorial ---

  Future<void> setTutorialSeen() async {
    if (_tutorialSeen) return;
    _tutorialSeen = true;
    await _storage.setTutorialSeen(true);
    notifyListeners();
  }

  // --- Power-ups: grant / consume ---

  Future<void> grantSkip(int amount) async {
    _skipBoosts += amount;
    await _storage.setSkipBoosts(_skipBoosts);
    notifyListeners();
  }

  Future<bool> consumeSkip() async {
    if (_skipBoosts <= 0) return false;
    _skipBoosts--;
    await _storage.setSkipBoosts(_skipBoosts);
    notifyListeners();
    return true;
  }

  Future<void> grantDoubleCoins(int amount) async {
    _doubleCoinsBoosts += amount;
    await _storage.setDoubleCoinsBoosts(_doubleCoinsBoosts);
    notifyListeners();
  }

  Future<bool> consumeDoubleCoins() async {
    if (_doubleCoinsBoosts <= 0) return false;
    _doubleCoinsBoosts--;
    await _storage.setDoubleCoinsBoosts(_doubleCoinsBoosts);
    notifyListeners();
    return true;
  }

  Future<void> grantLucky(int amount) async {
    _luckyBoosts += amount;
    await _storage.setLuckyBoosts(_luckyBoosts);
    notifyListeners();
  }

  Future<bool> consumeLucky() async {
    if (_luckyBoosts <= 0) return false;
    _luckyBoosts--;
    await _storage.setLuckyBoosts(_luckyBoosts);
    notifyListeners();
    return true;
  }

  Future<void> grantSlow(int amount) async {
    _slowBoosts += amount;
    await _storage.setSlowBoosts(_slowBoosts);
    notifyListeners();
  }

  Future<bool> consumeSlow() async {
    if (_slowBoosts <= 0) return false;
    _slowBoosts--;
    await _storage.setSlowBoosts(_slowBoosts);
    notifyListeners();
    return true;
  }

  Future<void> grantWiden(int amount) async {
    _widenBoosts += amount;
    await _storage.setWidenBoosts(_widenBoosts);
    notifyListeners();
  }

  Future<bool> consumeWiden() async {
    if (_widenBoosts <= 0) return false;
    _widenBoosts--;
    await _storage.setWidenBoosts(_widenBoosts);
    notifyListeners();
    return true;
  }

  // --- Audio / prefs ---

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    await _storage.setSoundEnabled(value);
    notifyListeners();
  }

  Future<void> setMusicEnabled(bool value) async {
    _musicEnabled = value;
    await _storage.setMusicEnabled(value);
    notifyListeners();
  }

  Future<void> setVibrationEnabled(bool value) async {
    _vibrationEnabled = value;
    await _storage.setVibrationEnabled(value);
    notifyListeners();
  }

  Future<void> setMusicVolume(double value) async {
    _musicVolume = value.clamp(0.0, 1.0);
    await _storage.setMusicVolume(_musicVolume);
    notifyListeners();
  }

  Future<void> setSfxVolume(double value) async {
    _sfxVolume = value.clamp(0.0, 1.0);
    await _storage.setSfxVolume(_sfxVolume);
    notifyListeners();
  }
}
