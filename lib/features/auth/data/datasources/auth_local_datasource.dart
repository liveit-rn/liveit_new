import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class AuthLocalDataSource {
  Future<String?> getAccessToken();
  Future<void> storeAccessToken(String token);
  Future<void> removeAccessToken();
  Future<bool> isAuthenticated();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage storage;
  static const String _tokenKey = 'access_token';

  AuthLocalDataSourceImpl({required this.storage});

  @override
  Future<String?> getAccessToken() async {
    return await storage.read(key: _tokenKey);
  }

  @override
  Future<void> storeAccessToken(String token) async {
    await storage.write(key: _tokenKey, value: token);
  }

  @override
  Future<void> removeAccessToken() async {
    await storage.delete(key: _tokenKey);
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
