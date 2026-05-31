import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class LinkBridge {
  static const String _key = 'a_tu';

  static Future<String?> consumeTapUrl() async {
    if (!Platform.isIOS) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.trim().isEmpty) return null;
      await prefs.remove(_key);
      return raw.trim();
    } catch (_) {
      return null;
    }
  }
}
