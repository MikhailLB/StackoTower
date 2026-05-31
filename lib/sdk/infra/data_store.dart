import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_mode.dart';

class DataStore {
  static const _kMode    = 'a.m';
  static const _kCool    = 'a.pc';
  static const _kConsent = 'a.co';
  static const _kUrl     = 'a.u';
  static const _kTtl     = 'a.ut';
  static const _kOneShot = 'a.os';

  late SharedPreferences _prefs;
  final FlutterSecureStorage _safe = const FlutterSecureStorage();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  AppMode readMode() => AppMode.fromKey(_prefs.getString(_kMode));

  Future<void> writeMode(AppMode m) async =>
      _prefs.setString(_kMode, m.toKey());

  Future<String?> readSavedUrl() async {
    try { return await _safe.read(key: _kUrl); } catch (_) { return null; }
  }

  Future<void> writeSavedUrl(String url) async {
    try { await _safe.write(key: _kUrl, value: url); } catch (_) {}
  }

  Future<void> writeSavedTtl(int epochSeconds) async =>
      _prefs.setInt(_kTtl, epochSeconds);

  bool isSavedUrlExpired() {
    final ttl = _prefs.getInt(_kTtl);
    if (ttl == null) return true;
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 >= ttl;
  }

  bool readPushConsent() => _prefs.getBool(_kConsent) ?? false;

  Future<void> writePushConsent(bool ok) async =>
      _prefs.setBool(_kConsent, ok);

  int? readPushCooldown() => _prefs.getInt(_kCool);

  Future<void> writePushCooldown(int epochSeconds) async =>
      _prefs.setInt(_kCool, epochSeconds);

  bool needsPushPrompt() {
    if (readPushConsent()) return false;
    final until = readPushCooldown();
    if (until == null) return true;
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 >= until;
  }

  Future<void> stashOneShotUrl(String url) async {
    if (url.isEmpty) return;
    try { await _safe.write(key: _kOneShot, value: url); } catch (_) {}
  }

  Future<String?> consumeOneShotUrl() async {
    try {
      final v = await _safe.read(key: _kOneShot);
      if (v != null) await _safe.delete(key: _kOneShot);
      return v;
    } catch (_) {
      return null;
    }
  }
}
