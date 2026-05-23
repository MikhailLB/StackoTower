import 'package:flutter/foundation.dart';

import '../services/storage_service.dart';

/// In-memory mirror of [StorageService] that notifies the UI on changes.
class GameProgress extends ChangeNotifier {
  GameProgress(this._storage)
      : _coins = _storage.coins,
        _highScore = _storage.highScore,
        _highestUnlockedLevel = _storage.highestUnlockedLevel,
        _completedLevels = Set<int>.from(_storage.completedLevels),
        _slowHookBoosts = _storage.slowHookBoosts,
        _secondChanceBoosts = _storage.secondChanceBoosts,
        _doubleCoinsBoosts = _storage.doubleCoinsBoosts,
        _ghostBlockBoosts = _storage.ghostBlockBoosts,
        _speedFreezeBoosts = _storage.speedFreezeBoosts,
        _wideBaseBoosts = _storage.wideBaseBoosts,
        _luckyBoosts = _storage.luckyBoosts,
        _ownedSkins = List<int>.from(_storage.ownedSkins),
        _selectedSkin = _storage.selectedSkin,
        _soundEnabled = _storage.soundEnabled,
        _musicEnabled = _storage.musicEnabled,
        _vibrationEnabled = _storage.vibrationEnabled,
        _musicVolume = _storage.musicVolume,
        _sfxVolume = _storage.sfxVolume;

  final StorageService _storage;

  int _coins;
  int _highScore;
  int _highestUnlockedLevel;
  final Set<int> _completedLevels;
  int _slowHookBoosts;
  int _secondChanceBoosts;
  int _doubleCoinsBoosts;
  int _ghostBlockBoosts;
  int _speedFreezeBoosts;
  int _wideBaseBoosts;
  int _luckyBoosts;
  List<int> _ownedSkins;
  int _selectedSkin;
  bool _soundEnabled;
  bool _musicEnabled;
  bool _vibrationEnabled;
  double _musicVolume;
  double _sfxVolume;

  int get coins => _coins;
  int get highScore => _highScore;
  int get highestUnlockedLevel => _highestUnlockedLevel;
  Set<int> get completedLevels => Set.unmodifiable(_completedLevels);
  int get slowHookBoosts => _slowHookBoosts;
  int get secondChanceBoosts => _secondChanceBoosts;
  int get doubleCoinsBoosts => _doubleCoinsBoosts;
  int get ghostBlockBoosts => _ghostBlockBoosts;
  int get speedFreezeBoosts => _speedFreezeBoosts;
  int get wideBaseBoosts => _wideBaseBoosts;
  int get luckyBoosts => _luckyBoosts;
  List<int> get ownedSkins => List.unmodifiable(_ownedSkins);
  int get selectedSkin => _selectedSkin;
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;

  // --- Coins & score ---

  Future<void> addCoins(int amount) async {
    if (amount <= 0) return;
    _coins += amount;
    await _storage.setCoins(_coins);
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

  // --- Boosts: grant / consume ---

  Future<void> grantSlowHook(int amount) async {
    _slowHookBoosts += amount;
    await _storage.setSlowHookBoosts(_slowHookBoosts);
    notifyListeners();
  }

  Future<bool> consumeSlowHook() async {
    if (_slowHookBoosts <= 0) return false;
    _slowHookBoosts--;
    await _storage.setSlowHookBoosts(_slowHookBoosts);
    notifyListeners();
    return true;
  }

  Future<void> grantSecondChance(int amount) async {
    _secondChanceBoosts += amount;
    await _storage.setSecondChanceBoosts(_secondChanceBoosts);
    notifyListeners();
  }

  Future<bool> consumeSecondChance() async {
    if (_secondChanceBoosts <= 0) return false;
    _secondChanceBoosts--;
    await _storage.setSecondChanceBoosts(_secondChanceBoosts);
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

  Future<void> grantGhostBlock(int amount) async {
    _ghostBlockBoosts += amount;
    await _storage.setGhostBlockBoosts(_ghostBlockBoosts);
    notifyListeners();
  }

  Future<bool> consumeGhostBlock() async {
    if (_ghostBlockBoosts <= 0) return false;
    _ghostBlockBoosts--;
    await _storage.setGhostBlockBoosts(_ghostBlockBoosts);
    notifyListeners();
    return true;
  }

  Future<void> grantSpeedFreeze(int amount) async {
    _speedFreezeBoosts += amount;
    await _storage.setSpeedFreezeBoosts(_speedFreezeBoosts);
    notifyListeners();
  }

  Future<bool> consumeSpeedFreeze() async {
    if (_speedFreezeBoosts <= 0) return false;
    _speedFreezeBoosts--;
    await _storage.setSpeedFreezeBoosts(_speedFreezeBoosts);
    notifyListeners();
    return true;
  }

  Future<void> grantWideBase(int amount) async {
    _wideBaseBoosts += amount;
    await _storage.setWideBaseBoosts(_wideBaseBoosts);
    notifyListeners();
  }

  Future<bool> consumeWideBase() async {
    if (_wideBaseBoosts <= 0) return false;
    _wideBaseBoosts--;
    await _storage.setWideBaseBoosts(_wideBaseBoosts);
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
