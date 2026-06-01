import '../../data/datasources/roble_datasource.dart';
import '../repositories/auth_repository.dart';

class RegisterStudentUseCase {
  final AuthRepository _repository;

  RegisterStudentUseCase(this._repository);

  Future<void> call({
    required String email,
    required String password,
    required String name,
  }) {
    return _repository.registerStudent(
      email: email,
      password: password,
      name: name,
    );
  }
}

class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  Future<AuthResult> call({required String email, required String password}) {
    return _repository.login(email: email, password: password);
  }
}

class GetUserByEmailUseCase {
  final AuthRepository _repository;

  GetUserByEmailUseCase(this._repository);

  Future<UserData?> call(String email) {
    return _repository.getUserByEmail(email);
  }
}

class LogoutUseCase {
  final AuthRepository _repository;

  LogoutUseCase(this._repository);

  Future<void> call() {
    return _repository.logout();
  }
}

class VerifyTokenUseCase {
  final AuthRepository _repository;

  VerifyTokenUseCase(this._repository);

  Future<bool> call() {
    return _repository.verifyToken();
  }
}

class SetTokenUseCase {
  final AuthRepository _repository;

  SetTokenUseCase(this._repository);

  void call(String? token) {
    _repository.setToken(token);
  }
}

class ForgotPasswordUseCase {
  final AuthRepository _repository;

  ForgotPasswordUseCase(this._repository);

  Future<void> call(String email) {
    return _repository.forgotPassword(email);
  }
}

class ResetPasswordUseCase {
  final AuthRepository _repository;

  ResetPasswordUseCase(this._repository);

  Future<void> call(String token, String newPassword) {
    return _repository.resetPassword(token, newPassword);
  }
}

class ExtractUidFromTokenUseCase {
  final AuthRepository _repository;

  ExtractUidFromTokenUseCase(this._repository);

  String? call(String token) {
    return _repository.extractUidFromToken(token);
  }
}
