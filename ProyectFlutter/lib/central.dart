import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'presentation/auth/controllers/auth_controller.dart';
import 'presentation/auth/views/login_view.dart';
import 'presentation/student_view/views/student_home_view.dart';
import 'presentation/teacher_view/views/teacher_home_view.dart';

class Central extends StatelessWidget {
  const Central({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find();

    return Obx(() {
      if (authController.isLoading.value && !authController.isLoggedIn.value) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      if (!authController.isLoggedIn.value ||
          authController.currentUser.value == null) {
        return const LoginView();
      }

      final user = authController.currentUser.value!;

      if (user.isTeacher) {
        return const TeacherHomeView();
      }

      return const StudentHomeView();
    });
  }
}
