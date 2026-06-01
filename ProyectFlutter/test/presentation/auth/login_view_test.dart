import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:coeval/presentation/auth/views/login_view.dart';
import 'package:coeval/presentation/auth/controllers/auth_controller.dart';
import '../../mocks/mock_auth_controller.dart';

void main() {
  late MockAuthController mockController;

  setUp(() {
    mockController = MockAuthController();

    // Configuramos comportamientos básicos por defecto para que GetX no falle
    when(() => mockController.emailError).thenReturn(Rxn<String>());
    when(() => mockController.passwordError).thenReturn(Rxn<String>());
    when(() => mockController.isLoading).thenReturn(false.obs);
    when(() => mockController.obscurePassword).thenReturn(true.obs);
    when(() => mockController.emailController).thenReturn(TextEditingController());
    when(() => mockController.passwordController).thenReturn(TextEditingController());

    // Importante: Simular el método que llamas en el initState
    when(() => mockController.prepareForLogin()).thenReturn(null);

    Get.put<AuthController>(mockController);
  });

  tearDown(() {
    Get.reset();
  });

  group('LoginView - Pruebas de Nivel 1', () {

    testWidgets('Debe mostrar los elementos principales de CoEval', (WidgetTester tester) async {
      await tester.pumpWidget(const GetMaterialApp(home: LoginView()));

      // Verifica el título y subtítulo
      expect(find.text('CoEval'), findsOneWidget);
      expect(find.text('Evaluación entre pares'), findsOneWidget);

      // Verifica que el botón de "Ingresar" existe
      expect(find.text('Ingresar'), findsOneWidget);
    });

    testWidgets('Debe mostrar error visual si el controlador tiene emailError', (WidgetTester tester) async {
      // Simulamos que el controlador detectó un error de correo institucional
      when(() => mockController.emailError).thenReturn(Rxn<String>('Usa tu correo institucional (@uninorte.edu.co)'));

      await tester.pumpWidget(const GetMaterialApp(home: LoginView()));
      await tester.pump(); // Refresca la UI

      expect(find.text('Usa tu correo institucional (@uninorte.edu.co)'), findsOneWidget);
    });

    testWidgets('Debe mostrar CircularProgressIndicator cuando isLoading es true', (WidgetTester tester) async {
      // Simulamos que el app está cargando
      when(() => mockController.isLoading).thenReturn(true.obs);

      await tester.pumpWidget(const GetMaterialApp(home: LoginView()));
      await tester.pump();

      // El botón "Ingresar" desaparece y aparece el cargador
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Ingresar'), findsNothing);
    });
  });
}