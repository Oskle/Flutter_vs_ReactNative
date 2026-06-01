import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme.dart';
import '../controllers/reset_password_controller.dart';

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final ResetPasswordController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Restablecer contraseña'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 32),
                _buildHeader(),
                const SizedBox(height: 28),
                _buildResetForm(),
                const SizedBox(height: 24),
                _buildResetButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: AppColors.appBar,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.appBar.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.lock_reset_rounded,
            size: 36,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Restablecer contraseña',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Ingresa el token de recuperación y tu nueva contraseña',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildResetForm() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => TextField(
                controller: controller.tokenController,
                onChanged: (v) => controller.token.value = v,
                decoration: InputDecoration(
                  labelText: 'Token de recuperación',
                  hintText: 'Ingresa el token del email',
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                  errorText: controller.tokenError.value,
                ),
              )),
          const SizedBox(height: 14),
          Obx(() => TextField(
                controller: controller.newPasswordController,
                obscureText: controller.obscureNewPassword.value,
                onChanged: (v) => controller.newPassword.value = v,
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  errorText: controller.newPasswordError.value,
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.obscureNewPassword.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: controller.toggleNewPasswordVisibility,
                  ),
                ),
              )),
          const SizedBox(height: 14),
          Obx(() => TextField(
                controller: controller.confirmPasswordController,
                obscureText: controller.obscureConfirmPassword.value,
                onChanged: (v) => controller.confirmPassword.value = v,
                decoration: InputDecoration(
                  labelText: 'Confirmar contraseña',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  errorText: controller.confirmPasswordError.value,
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.obscureConfirmPassword.value
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: controller.toggleConfirmPasswordVisibility,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildResetButton() {
    return Obx(() => SizedBox(
          width: double.infinity,
          height: 54,
          child: controller.isLoading.value
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                )
              : ElevatedButton(
                  onPressed: controller.resetPassword,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Restablecer contraseña',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.check_circle_outline,
                          color: Colors.white, size: 20),
                    ],
                  ),
                ),
        ));
  }
}
