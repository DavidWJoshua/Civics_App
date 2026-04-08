import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// SecureTokenStorage replaces SharedPreferences with flutter_secure_storage.
/// On Android: uses Android Keystore-backed EncryptedSharedPreferences.
/// On iOS: uses Keychain.
class SecureTokenStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _accessTokenKey = "auth_token";
  static const String _refreshTokenKey = "refresh_token";
  static const String _roleKey = "user_role";
  static const String _userIdKey = "user_id";

  // ─── Access Token ──────────────────────────────────────────────────────────

  static Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  // ─── Refresh Token ─────────────────────────────────────────────────────────

  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  // ─── Role ──────────────────────────────────────────────────────────────────

  static Future<void> saveRole(String role) async {
    await _storage.write(key: _roleKey, value: role);
  }

  static Future<String?> getRole() async {
    return await _storage.read(key: _roleKey);
  }

  // ─── User ID ───────────────────────────────────────────────────────────────

  static Future<void> saveUserId(String id) async {
    await _storage.write(key: _userIdKey, value: id);
  }

  static Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  /// Saves all auth data at once after successful login.
  static Future<void> saveAuthData({
    required String accessToken,
    required String refreshToken,
    required String role,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
      saveRole(role),
    ]);
  }

  /// Clears all stored auth data (use on logout).
  static Future<void> clear() async {
    await _storage.deleteAll();
  }

  /// Returns true if user has an access token stored (i.e. is logged in).
  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
