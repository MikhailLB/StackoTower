import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/session_mode.dart';

class VaultService {
  static const _keySessionMode = 'st_session_mode';
  static const _keySavedUrl = 'st_sv_u';
  static const _keyUrlExpires = 'st_url_expires';
  static const _keyNotifSkipUntil = 'st_notif_skip_until';
  static const _keyNotifGranted = 'st_notif_granted';
  static const _keyNotifOsDenied = 'st_notif_os_denied';
  static const _keyPushUrl = 'st_psh_u';

  late SharedPreferences _prefs;
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // -- Session Mode --

  SessionMode getSessionMode() {
    return SessionMode.fromString(_prefs.getString(_keySessionMode));
  }

  Future<void> setSessionMode(SessionMode mode) async {
    await _prefs.setString(_keySessionMode, mode.toStorageString());
  }

  // -- Saved URL (secure) --

  Future<String?> getSavedUrl() async {
    return _secure.read(key: _keySavedUrl);
  }

  Future<void> setSavedUrl(String url) async {
    await _secure.write(key: _keySavedUrl, value: url);
  }

  // -- URL Expiry --

  int? getUrlExpires() => _prefs.getInt(_keyUrlExpires);

  Future<void> setUrlExpires(int expires) async {
    await _prefs.setInt(_keyUrlExpires, expires);
  }

  bool isUrlExpired() {
    final expires = getUrlExpires();
    if (expires == null) return true;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= expires;
  }

  // -- Notification Permission --

  bool isNotificationGranted() =>
      _prefs.getBool(_keyNotifGranted) ?? false;

  Future<void> setNotificationGranted(bool granted) async {
    await _prefs.setBool(_keyNotifGranted, granted);
  }

  bool isNotificationOsDenied() =>
      _prefs.getBool(_keyNotifOsDenied) ?? false;

  Future<void> setNotificationOsDenied() async {
    await _prefs.setBool(_keyNotifOsDenied, true);
  }

  int? getNotificationSkipUntil() => _prefs.getInt(_keyNotifSkipUntil);

  Future<void> setNotificationSkipUntil(int timestamp) async {
    await _prefs.setInt(_keyNotifSkipUntil, timestamp);
  }

  bool shouldShowNotificationScreen() {
    if (isNotificationGranted()) return false;
    if (isNotificationOsDenied()) return false;
    final skipUntil = getNotificationSkipUntil();
    if (skipUntil == null) return true;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return now >= skipUntil;
  }

  // -- One-time Push URL (secure) --

  Future<String?> getPushUrl() async {
    return _secure.read(key: _keyPushUrl);
  }

  Future<void> setPushUrl(String? url) async {
    if (url == null) {
      await _secure.delete(key: _keyPushUrl);
    } else {
      await _secure.write(key: _keyPushUrl, value: url);
    }
  }

  Future<String?> consumePushUrl() async {
    final url = await getPushUrl();
    if (url != null) {
      await _secure.delete(key: _keyPushUrl);
    }
    return url;
  }
}
