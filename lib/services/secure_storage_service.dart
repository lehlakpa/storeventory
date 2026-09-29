import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  const SecureStorageService();
  static const storage = FlutterSecureStorage(
    mOptions: MacOsOptions(usesDataProtectionKeychain: false),
  );
  static const sessionKey = 'auth_session_v1';

  Future<Map<String, dynamic>?> readSession() async {
    final value = await storage.read(key: sessionKey);
    if (value == null) return null;
    try {
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (_) {
      await clearSession();
      return null;
    }
  }

  Future<void> saveSession(Map<String, dynamic> session) =>
      storage.write(key: sessionKey, value: jsonEncode(session));

  Future<void> clearSession() => storage.delete(key: sessionKey);

  // Only non-sensitive preferences migrate. Old demo tokens are discarded.
  Future<void> migrateLegacyPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in ['theme_mode', 'has_seen_onboarding']) {
      final value = prefs.get(key);
      if (value != null) {
        if (await storage.read(key: key) == null) {
          await storage.write(key: key, value: value.toString());
        }
        await prefs.remove(key);
      }
    }
    for (final key in ['access_token', 'refresh_token', 'biometric_enabled']) {
      await prefs.remove(key);
    }
  }
}
