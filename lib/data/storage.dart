import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Tiny wrapper around shared_preferences. Every call is a no-op until
/// [init] has run, so unit tests can use the stores without a device.
class Storage {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String? getString(String key) => _prefs?.getString(key);

  static void setString(String key, String value) => _prefs?.setString(key, value);

  static Object? getJson(String key) {
    final raw = getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  static void setJson(String key, Object value) => setString(key, jsonEncode(value));
}
