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
        _ownedSkins = List<int>.from(_storage.ownedSkins),
        _selectedSkin = _storage.selectedSkin,
        _tutorialSeen = _storage.tutorialSeen,
        _vibrationEnabled = _storage.vibrationEnabled;

  final StorageService _storage;

  int _coins;
  int _highScore;
  int _highestUnlockedLevel;
  final Set<int> _completedLevels;
  int _skipBoosts;
  int _doubleCoinsBoosts;
  int _luckyBoosts;
  List<int> _ownedSkins;
  int _selectedSkin;
  bool _tutorialSeen;
  bool _vibrationEnabled;

  int get coins => _coins;
  int get highScore => _highScore;
  int get highestUnlockedLevel => _highestUnlockedLevel;
  Set<int> get completedLevels => Set.unmodifiable(_completedLevels);
  int get skipBoosts => _skipBoosts;
  int get doubleCoinsBoosts => _doubleCoinsBoosts;
  int get luckyBoosts => _luckyBoosts;
  List<int> get ownedSkins => List.unmodifiable(_ownedSkins);
  int get selectedSkin => _selectedSkin;
  bool get tutorialSeen => _tutorialSeen;
  bool get vibrationEnabled => _vibrationEnabled;

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

  // --- Tutorial ---

  Future<void> setTutorialSeen() async {
    if (_tutorialSeen) return;
    _tutorialSeen = true;
    await _storage.setTutorialSeen(true);
    notifyListeners();
  }

  // --- Power-ups ---

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

  // --- Vibration pref ---

  Future<void> setVibrationEnabled(bool value) async {
    _vibrationEnabled = value;
    await _storage.setVibrationEnabled(value);
    notifyListeners();
  }
}
