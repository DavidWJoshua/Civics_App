import 'secure_token_storage.dart';

/// TokenStorage — kept for backward compatibility.
/// All methods now delegate to SecureTokenStorage (flutter_secure_storage).
/// New code should use SecureTokenStorage directly.
@Deprecated('Use SecureTokenStorage instead for new code')
class TokenStorage {
  static Future<void> saveToken(String token) async =>
      SecureTokenStorage.saveAccessToken(token);

  static Future<String?> getToken() async =>
      SecureTokenStorage.getAccessToken();

  static Future<void> saveRole(String role) async =>
      SecureTokenStorage.saveRole(role);

  static Future<String?> getRole() async =>
      SecureTokenStorage.getRole();

  static Future<void> clear() async =>
      SecureTokenStorage.clear();
}
