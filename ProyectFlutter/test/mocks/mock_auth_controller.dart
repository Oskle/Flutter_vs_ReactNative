import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:coeval/presentation/auth/controllers/auth_controller.dart';
import 'package:coeval/data/datasources/roble_datasource.dart';

class MockAuthController extends GetxController
    with Mock
    implements AuthController {
  @override
  final isLoggedIn = false.obs;

  @override
  final currentUser = Rxn<UserData>();
}