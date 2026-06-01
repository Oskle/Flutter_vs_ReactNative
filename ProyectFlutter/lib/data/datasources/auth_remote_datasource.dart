import 'roble_datasource.dart';

class AuthRemoteDatasource {
  final RobleDatasource _robleDatasource;

  AuthRemoteDatasource(this._robleDatasource);

  Future<bool> registerUser(String email, String password, String name) {
    return _robleDatasource.registerUser(email, password, name);
  }

  Future<AuthResult> loginUser(String email, String password) {
    return _robleDatasource.loginUser(email, password);
  }

  Future<bool> saveUserData(
    String email,
    String name,
    String role,
    String uid,
  ) {
    return _robleDatasource.saveUserData(email, name, role, uid);
  }

  Future<UserData?> getUserData(String email) {
    return _robleDatasource.getUserData(email);
  }

  Future<bool> logout() {
    return _robleDatasource.logout();
  }

  Future<bool> verifyToken() {
    return _robleDatasource.verifyToken();
  }

  Future<AuthResult?> refreshToken(String refreshToken) {
    return _robleDatasource.refreshToken(refreshToken);
  }

  String? extractUidFromToken(String token) {
    return _robleDatasource.extractUidFromToken(token);
  }

  void setToken(String? token) {
    _robleDatasource.setToken(token);
  }

  Future<bool> forgotPassword(String email) {
    return _robleDatasource.forgotPassword(email);
  }

  Future<bool> resetPassword(String token, String newPassword) {
    return _robleDatasource.resetPassword(token, newPassword);
  }
}
