import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/app_cache.dart';
import '../../../data/datasources/roble_datasource.dart';
import '../../../domain/usecases/login_use_case.dart';

class AuthController extends GetxController {
  final RegisterStudentUseCase _registerStudentUseCase;
  final LoginUseCase _loginUseCase;
  final GetUserByEmailUseCase _getUserByEmailUseCase;
  final LogoutUseCase _logoutUseCase;
  final VerifyTokenUseCase _verifyTokenUseCase;
  final SetTokenUseCase _setTokenUseCase;
  final ForgotPasswordUseCase _forgotPasswordUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;

  AuthController({
    required RegisterStudentUseCase registerStudentUseCase,
    required LoginUseCase loginUseCase,
    required GetUserByEmailUseCase getUserByEmailUseCase,
    required LogoutUseCase logoutUseCase,
    required VerifyTokenUseCase verifyTokenUseCase,
    required SetTokenUseCase setTokenUseCase,
    required ForgotPasswordUseCase forgotPasswordUseCase,
    required ResetPasswordUseCase resetPasswordUseCase,
  }) : _registerStudentUseCase = registerStudentUseCase,
       _loginUseCase = loginUseCase,
       _getUserByEmailUseCase = getUserByEmailUseCase,
       _logoutUseCase = logoutUseCase,
       _verifyTokenUseCase = verifyTokenUseCase,
       _setTokenUseCase = setTokenUseCase,
       _forgotPasswordUseCase = forgotPasswordUseCase,
       _resetPasswordUseCase = resetPasswordUseCase;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();

  var email = ''.obs;
  var password = ''.obs;
  var name = ''.obs;
  var isLoading = false.obs;
  var obscurePassword = true.obs;

  var currentUser = Rxn<UserData>();
  var isLoggedIn = false.obs;

  var emailError = Rxn<String>();
  var passwordError = Rxn<String>();
  var nameError = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    _checkExistingSession();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.onClose();
  }

  Future<void> _checkExistingSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('access_token');
    final savedId = prefs.getString('user_id');
    final savedEmail = prefs.getString('user_email');

    if (savedToken != null && savedEmail != null) {
      _setTokenUseCase(savedToken);

      final isValid = await _verifyTokenUseCase();
      if (isValid) {
        final dbUser = await _getUserByEmailUseCase(savedEmail);

        if (dbUser == null) {
          await _clearSession();
          return;
        }

        final resolvedUser =
            (dbUser.id == null || dbUser.id!.isEmpty) &&
                savedId != null &&
                savedId.isNotEmpty
            ? UserData(
                id: savedId,
                uid: dbUser.uid,
                email: dbUser.email,
                name: dbUser.name,
                role: dbUser.role,
              )
            : dbUser;

        currentUser.value = resolvedUser;
        isLoggedIn.value = true;

        if (resolvedUser.id != null && resolvedUser.id!.isNotEmpty) {
          await prefs.setString('user_id', resolvedUser.id!);
        }
        await prefs.setString('user_name', resolvedUser.name);
        await prefs.setString('user_role', resolvedUser.role);
        if (resolvedUser.uid != null && resolvedUser.uid!.isNotEmpty) {
          await prefs.setString('user_uid', resolvedUser.uid!);
        }
      } else {
        await _clearSession();
      }
    }
  }

  Future<void> _saveSession(
    String token,
    String userEmail,
    String? refreshToken,
    UserData? user,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
    await prefs.setString('user_email', userEmail);
    if (refreshToken != null) {
      await prefs.setString('refresh_token', refreshToken);
    }
    if (user != null) {
      if (user.id != null && user.id!.isNotEmpty) {
        await prefs.setString('user_id', user.id!);
      }
      await prefs.setString('user_name', user.name);
      await prefs.setString('user_role', user.role);
      if (user.uid != null && user.uid!.isNotEmpty) {
        await prefs.setString('user_uid', user.uid!);
      }
    }
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('refresh_token');
    await prefs.remove('user_name');
    await prefs.remove('user_role');
    await prefs.remove('user_uid');
    _setTokenUseCase(null);
    currentUser.value = null;
    isLoggedIn.value = false;
    await AppCache.instance.clearAll();
  }

  void prepareForLogin() {
    emailController.clear();
    passwordController.clear();
    email.value = '';
    password.value = '';
    emailError.value = null;
    passwordError.value = null;
    obscurePassword.value = true;
  }

  void prepareForRegister() {
    nameController.clear();
    emailController.clear();
    passwordController.clear();
    name.value = '';
    email.value = '';
    password.value = '';
    nameError.value = null;
    emailError.value = null;
    passwordError.value = null;
    obscurePassword.value = true;
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  bool _validateEmail(String emailValue) {
    if (emailValue.isEmpty) {
      emailError.value = 'El correo es requerido';
      return false;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(emailValue)) {
      emailError.value = 'Ingresa un correo válido';
      return false;
    }

    if (!emailValue.toLowerCase().endsWith('@uninorte.edu.co')) {
      emailError.value = 'Usa tu correo institucional (@uninorte.edu.co)';
      return false;
    }

    emailError.value = null;
    return true;
  }

  bool _validatePassword(String passwordValue) {
    if (passwordValue.isEmpty) {
      passwordError.value = 'La contraseña es requerida';
      return false;
    }

    if (passwordValue.length < 6) {
      passwordError.value = 'Mínimo 6 caracteres';
      return false;
    }

    passwordError.value = null;
    return true;
  }

  bool _validateName(String nameValue) {
    if (nameValue.isEmpty) {
      nameError.value = 'El nombre es requerido';
      return false;
    }

    if (nameValue.trim().split(' ').length < 2) {
      nameError.value = 'Ingresa nombre y apellido';
      return false;
    }

    nameError.value = null;
    return true;
  }

  bool validateLoginForm() {
    final emailValid = _validateEmail(email.value);
    final passwordValid = _validatePassword(password.value);
    return emailValid && passwordValid;
  }

  bool validateRegisterForm() {
    final nameValid = _validateName(name.value);
    final emailValid = _validateEmail(email.value);
    final passwordValid = _validatePassword(password.value);
    return nameValid && emailValid && passwordValid;
  }

  Future<void> register() async {
    if (!validateRegisterForm()) {
      _showError('Corrige los errores en el formulario');
      return;
    }

    isLoading.value = true;

    final emailToSend = email.value.trim();
    final passwordToSend = password.value;
    final nameToSend = name.value.trim();

    try {
      await _registerStudentUseCase(
        email: emailToSend,
        password: passwordToSend,
        name: nameToSend,
      );

      _showSuccess('Registro exitoso', 'Tu cuenta fue creada como estudiante');

      Get.offAllNamed('/login');
    } on RobleException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Error inesperado. Intenta de nuevo.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login() async {
    if (!validateLoginForm()) {
      _showError('Corrige los errores en el formulario');
      return;
    }

    isLoading.value = true;

    final emailToLogin = email.value.trim();
    final passwordToLogin = password.value;

    try {
      final result = await _loginUseCase(
        email: emailToLogin,
        password: passwordToLogin,
      );

      final dbUser = await _getUserByEmailUseCase(emailToLogin);

      if (dbUser == null) {
        await _clearSession();
        _showError(
          'Tu cuenta no está registrada en la tabla users. Contacta al administrador.',
        );
        return;
      }

      final userData = dbUser;

      await _saveSession(
        result.accessToken,
        emailToLogin,
        result.refreshToken,
        userData,
      );

      currentUser.value = userData;
      isLoggedIn.value = true;

      Get.offAllNamed('/');
    } on RobleException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Error de conexión. Verifica tu internet.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    isLoading.value = true;

    try {
      await _logoutUseCase();
    } finally {
      await _clearSession();
      isLoading.value = false;
      Get.offAllNamed('/');
    }
  }

  Future<void> forgotPassword() async {
    if (!_validateEmail(email.value)) {
      return;
    }

    isLoading.value = true;

    final emailToSend = email.value.trim();

    try {
      await _forgotPasswordUseCase(emailToSend);
      _showSuccess('Correo enviado', 'Revisa tu bandeja de entrada para restablecer tu contraseña');
    } on RobleException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Error inesperado. Intenta de nuevo.');
    } finally {
      isLoading.value = false;
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade900,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
      icon: Icon(Icons.error_outline, color: Colors.red.shade900),
    );
  }

  void _showSuccess(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.shade100,
      colorText: Colors.green.shade900,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
      icon: Icon(Icons.check_circle_outline, color: Colors.green.shade900),
    );
  }
}
