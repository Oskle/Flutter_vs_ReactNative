import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/roble_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remoteDatasource;

  AuthRepositoryImpl(this._remoteDatasource);

  @override
  Future<void> registerStudent({
    required String email,
    required String password,
    required String name,
  }) async {
    final success = await _remoteDatasource.registerUser(email, password, name);

    if (!success) {
      throw RobleException('No se pudo registrar el usuario');
    }

    final authResult = await _remoteDatasource.loginUser(email, password);

    final uid =
        authResult.user?.id ??
        authResult.user?.uid ??
        _remoteDatasource.extractUidFromToken(authResult.accessToken);

    if (uid == null || uid.isEmpty) {
      throw RobleException('No se pudo obtener el UID de autenticación');
    }

    final saved = await _remoteDatasource.saveUserData(
      email,
      name,
      'student',
      uid,
    );

    if (!saved) {
      throw RobleException('No se pudo guardar el usuario en la tabla User');
    }
  }

  @override
  Future<AuthResult> login({required String email, required String password}) {
    return _remoteDatasource.loginUser(email, password);
  }

  @override
  Future<UserData?> getUserByEmail(String email) {
    return _remoteDatasource.getUserData(email);
  }

  @override
  Future<void> logout() async {
    await _remoteDatasource.logout();
  }

  @override
  Future<bool> verifyToken() {
    return _remoteDatasource.verifyToken();
  }

  @override
  Future<AuthResult?> refreshToken(String refreshToken) {
    return _remoteDatasource.refreshToken(refreshToken);
  }

  @override
  String? extractUidFromToken(String token) {
    return _remoteDatasource.extractUidFromToken(token);
  }

  @override
  void setToken(String? token) {
    _remoteDatasource.setToken(token);
  }

  @override
  Future<void> forgotPassword(String email) async {
    final success = await _remoteDatasource.forgotPassword(email);
    if (!success) {
      throw RobleException('No se pudo enviar el correo de recuperación');
    }
  }

  @override
  Future<void> resetPassword(String token, String newPassword) async {
    final success = await _remoteDatasource.resetPassword(token, newPassword);
    if (!success) {
      throw RobleException('No se pudo restablecer la contraseña');
    }
  }
}
