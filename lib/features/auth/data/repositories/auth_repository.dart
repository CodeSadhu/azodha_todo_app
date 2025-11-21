import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/strings.dart';

class AuthRepository {
  final FlutterSecureStorage _secureStorage;
  static const String _keyToken = 'auth_token';

  AuthRepository(this._secureStorage);

  Future<bool> login(String username, String password) async {
    if (username == AppStrings.mockUsername &&
        password == AppStrings.mockPassword) {
      await _secureStorage.write(key: _keyToken, value: 'mock_token_12345');
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: _keyToken);
  }

  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.read(key: _keyToken);
    return token != null;
  }
}
