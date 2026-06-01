import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/datasources/roble_datasource.dart';
import '../../../domain/usecases/login_use_case.dart';

class ResetPasswordController extends GetxController {
  final ResetPasswordUseCase _resetPasswordUseCase;

  ResetPasswordController(this._resetPasswordUseCase);

  final tokenController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  var token = ''.obs;
  var newPassword = ''.obs;
  var confirmPassword = ''.obs;
  var isLoading = false.obs;
  var obscureNewPassword = true.obs;
  var obscureConfirmPassword = true.obs;

  var tokenError = Rxn<String>();
  var newPasswordError = Rxn<String>();
  var confirmPasswordError = Rxn<String>();

  @override
  void onInit() {
    super.onInit();
    // If token is passed via arguments
    final args = Get.arguments;
    if (args != null && args is String) {
      token.value = args;
      tokenController.text = args;
    }
  }

  @override
  void onClose() {
    tokenController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void toggleNewPasswordVisibility() {
    obscureNewPassword.value = !obscureNewPassword.value;
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.value = !obscureConfirmPassword.value;
  }

  bool _validateToken(String tokenValue) {
    if (tokenValue.isEmpty) {
      tokenError.value = 'El token es requerido';
      return false;
    }

    tokenError.value = null;
    return true;
  }

  bool _validateNewPassword(String passwordValue) {
    if (passwordValue.isEmpty) {
      newPasswordError.value = 'La nueva contraseña es requerida';
      return false;
    }

    if (passwordValue.length < 6) {
      newPasswordError.value = 'Mínimo 6 caracteres';
      return false;
    }

    newPasswordError.value = null;
    return true;
  }

  bool _validateConfirmPassword(String confirmValue) {
    if (confirmValue.isEmpty) {
      confirmPasswordError.value = 'Confirma la contraseña';
      return false;
    }

    if (confirmValue != newPassword.value) {
      confirmPasswordError.value = 'Las contraseñas no coinciden';
      return false;
    }

    confirmPasswordError.value = null;
    return true;
  }

  bool validateForm() {
    final tokenValid = _validateToken(token.value);
    final passwordValid = _validateNewPassword(newPassword.value);
    final confirmValid = _validateConfirmPassword(confirmPassword.value);
    return tokenValid && passwordValid && confirmValid;
  }

  Future<void> resetPassword() async {
    if (!validateForm()) {
      _showError('Corrige los errores en el formulario');
      return;
    }

    isLoading.value = true;

    final tokenToSend = token.value.trim();
    final passwordToSend = newPassword.value;

    try {
      await _resetPasswordUseCase(tokenToSend, passwordToSend);
      _showSuccess('Contraseña restablecida', 'Tu contraseña ha sido cambiada exitosamente');
      Get.offAllNamed('/login');
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