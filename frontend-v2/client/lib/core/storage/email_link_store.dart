import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores the address requested by this installation. Firebase owns its session;
/// no ID or refresh token is copied into preferences.
class EmailLinkStore {
  EmailLinkStore([SharedPreferencesAsync? preferences]) : _preferences = preferences ?? SharedPreferencesAsync();
  final SharedPreferencesAsync _preferences;
  static const _emailKey = 'autolinky.auth.email_link';
  Future<String?> read() => _preferences.getString(_emailKey);
  Future<void> save(String email) => _preferences.setString(_emailKey, email);
  Future<void> clear() => _preferences.remove(_emailKey);
}

/// Remove only the legacy app session, leaving preferences and unrelated keys.
Future<void> clearLegacySession({required bool web}) async {
  if (!web) await const FlutterSecureStorage().delete(key: 'autolinky.auth.session');
  final preferences = SharedPreferencesAsync();
  final keys = await preferences.getKeys();
  for (final key in keys.where((key) => key.startsWith('sb-') && key.endsWith('-auth-token'))) {
    await preferences.remove(key);
  }
}
