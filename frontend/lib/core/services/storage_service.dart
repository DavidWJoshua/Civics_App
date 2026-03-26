import '../utils/token_storage.dart';

class StorageService {
  Future<String?> getToken() async {
    return TokenStorage.getToken();
  }

  Future<void> saveToken(String token) async {
    return TokenStorage.saveToken(token);
  }

  Future<void> clear() async {
    return TokenStorage.clear();
  }
}
