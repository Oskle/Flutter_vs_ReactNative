import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:coeval/presentation/auth/controllers/reset_password_controller.dart';

class MockResetPasswordController extends GetxController
    with Mock
    implements ResetPasswordController {
  @override
  final tokenController = TextEditingController();

  @override
  final newPasswordController = TextEditingController();

  @override
  final confirmPasswordController = TextEditingController();

  @override
  final token = ''.obs;

  @override
  final newPassword = ''.obs;

  @override
  final confirmPassword = ''.obs;

  @override
  final isLoading = false.obs;

  @override
  final obscureNewPassword = true.obs;

  @override
  final obscureConfirmPassword = true.obs;

  @override
  final tokenError = Rxn<String>();

  @override
  final newPasswordError = Rxn<String>();

  @override
  final confirmPasswordError = Rxn<String>();
}
