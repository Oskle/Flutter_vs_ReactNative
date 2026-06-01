import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:app_links/app_links.dart';

import 'central.dart';
import 'core/theme.dart';
import 'data/datasources/academic_remote_datasource.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/datasources/dashboard_remote_datasource.dart';
import 'data/datasources/roble_datasource.dart';
import 'data/repositories/academic_repository_impl.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/dashboard_repository_impl.dart';
import 'domain/repositories/dashboard_repository.dart';
import 'domain/usecases/academic_use_cases.dart';
import 'domain/usecases/get_evaluation_results_use_case.dart';
import 'domain/usecases/login_use_case.dart';
import 'presentation/auth/controllers/auth_controller.dart';
import 'presentation/auth/views/login_view.dart';
import 'presentation/auth/views/register_view.dart';
import 'presentation/auth/controllers/reset_password_controller.dart';
import 'presentation/auth/views/reset_password_view.dart';
import 'presentation/dashboard/controllers/dashboard_controller.dart';
import 'presentation/student_view/controllers/student_home_controller.dart';
import 'presentation/teacher_view/controllers/teacher_home_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final robleDatasource = RobleDatasource();
  final authRemoteDatasource = AuthRemoteDatasource(robleDatasource);
  final academicRemoteDatasource = AcademicRemoteDatasource(robleDatasource);
  final dashboardRemoteDatasource = DashboardRemoteDatasource(robleDatasource);

  final authRepository = AuthRepositoryImpl(authRemoteDatasource);
  final academicRepository = AcademicRepositoryImpl(academicRemoteDatasource);
  final dashboardRepository = DashboardRepositoryImpl(dashboardRemoteDatasource);

  final authController = Get.put(
    AuthController(
      registerStudentUseCase: RegisterStudentUseCase(authRepository),
      loginUseCase: LoginUseCase(authRepository),
      getUserByEmailUseCase: GetUserByEmailUseCase(authRepository),
      logoutUseCase: LogoutUseCase(authRepository),
      verifyTokenUseCase: VerifyTokenUseCase(authRepository),
      setTokenUseCase: SetTokenUseCase(authRepository),
      forgotPasswordUseCase: ForgotPasswordUseCase(authRepository),
      resetPasswordUseCase: ResetPasswordUseCase(authRepository),
    ),
    permanent: true,
  );

  Get.put(
    ResetPasswordController(ResetPasswordUseCase(authRepository)),
    permanent: true,
  );

  Get.put(
    TeacherHomeController(
      authController: authController,
      createCourseUseCase: CreateCourseUseCase(academicRepository),
      getTeacherCourseOverviewsUseCase: GetTeacherCourseOverviewsUseCase(
        academicRepository,
      ),
      syncCategoryFromCsvUseCase: SyncCategoryFromCsvUseCase(
        academicRepository,
      ),
      createEvaluationCycleUseCase: CreateEvaluationCycleUseCase(
        academicRepository,
      ),
      getEvaluationCyclesByCourseUseCase: GetEvaluationCyclesByCourseUseCase(
        academicRepository,
      ),
    ),
    permanent: true,
  );

  Get.put(
    StudentHomeController(
      authController: authController,
      getStudentCourseOverviewsUseCase: GetStudentCourseOverviewsUseCase(
        academicRepository,
      ),
      getPendingEvaluationsUseCase: GetPendingEvaluationsForStudentUseCase(
        academicRepository,
      ),
      submitEvaluationUseCase: SubmitEvaluationUseCase(
        academicRepository,
      ),
    ),
    permanent: true,
  );

  // Inyectamos el nuevo DashboardController
  Get.put(
    DashboardController(
      getResultsUseCase: GetEvaluationResultsUseCase(dashboardRepository),
    ),
    permanent: true,
  );

  // Handle deep links
  final appLinks = AppLinks();
  _handleDeepLinks(appLinks);

  runApp(const MyApp());
}

void _handleDeepLinks(AppLinks appLinks) async {
  // Handle initial link
  try {
    final initialLink = await appLinks.getInitialLink();
    if (initialLink != null) {
      _handleLink(initialLink.toString());
    }
  } on PlatformException {
    // Handle exception
  }

  // Handle links while app is running
  appLinks.uriLinkStream.listen((Uri? uri) {
    if (uri != null) {
      _handleLink(uri.toString());
    }
  });
}

void _handleLink(String link) {
  final uri = Uri.parse(link);
  if (uri.path == '/reset-password' && uri.queryParameters.containsKey('token')) {
    final token = uri.queryParameters['token']!;
    Get.toNamed('/reset-password', arguments: token);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'CoEval',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const Central(),
      getPages: [
        GetPage(
          name: '/',
          page: () => const Central(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/login',
          page: () => const LoginView(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: '/register',
          page: () => const RegisterView(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: '/reset-password',
          page: () => const ResetPasswordView(),
          transition: Transition.rightToLeft,
        ),
      ],
    );
  }
}
