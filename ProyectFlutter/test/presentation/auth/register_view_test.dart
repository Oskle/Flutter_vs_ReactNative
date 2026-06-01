import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:coeval/presentation/auth/views/register_view.dart';
import 'package:coeval/presentation/auth/controllers/auth_controller.dart';
import '../../mocks/mock_auth_controller.dart';

void main() {
  late MockAuthController mockController;

  setUp(() {
    mockController = MockAuthController();

    // Configuramos comportamientos básicos por defecto para que GetX no falle
    when(() => mockController.nameError).thenReturn(Rxn<String>());
    when(() => mockController.emailError).thenReturn(Rxn<String>());
    when(() => mockController.passwordError).thenReturn(Rxn<String>());
    when(() => mockController.isLoading).thenReturn(false.obs);
    when(() => mockController.obscurePassword).thenReturn(true.obs);
    when(() => mockController.nameController).thenReturn(TextEditingController());
    when(() => mockController.emailController).thenReturn(TextEditingController());
    when(() => mockController.passwordController).thenReturn(TextEditingController());

    // Importante: Simular el método que llamas en el initState
    when(() => mockController.prepareForRegister()).thenReturn(null);

    Get.put<AuthController>(mockController);
  });

  tearDown(() {
    Get.reset();
  });

  group('RegisterView - Pruebas de Nivel 1', () {

    testWidgets('Debe mostrar los elementos de registro correctamente', (WidgetTester tester) async {
      await tester.pumpWidget(const GetMaterialApp(home: RegisterView()));

      expect(find.text('Crear Cuenta'), findsOneWidget);
      expect(find.text('Regístrate como estudiante con tu cuenta institucional'), findsOneWidget);
      expect(find.text('Información Personal'), findsOneWidget);
      
      // Verifica campos de entrada
      expect(find.widgetWithText(TextField, 'Nombre completo'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Correo institucional'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Contraseña'), findsOneWidget);
    });

    testWidgets('Debe mostrar errores de validación si el controlador los emite', (WidgetTester tester) async {
      when(() => mockController.nameError).thenReturn(Rxn<String>('El nombre es requerido'));
      when(() => mockController.emailError).thenReturn(Rxn<String>('Usa tu correo institucional (@uninorte.edu.co)'));

      await tester.pumpWidget(const GetMaterialApp(home: RegisterView()));
      await tester.pump();

      expect(find.text('El nombre es requerido'), findsOneWidget);
      expect(find.text('Usa tu correo institucional (@uninorte.edu.co)'), findsOneWidget);
    });

    testWidgets('Debe mostrar CircularProgressIndicator al intentar registrarse', (WidgetTester tester) async {
      when(() => mockController.isLoading).thenReturn(true.obs);

      await tester.pumpWidget(const GetMaterialApp(home: RegisterView()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Crear cuenta'), findsNothing);
    });

    testWidgets('Debe llamar al método register del controlador al pulsar el botón', (WidgetTester tester) async {
      when(() => mockController.register()).thenAnswer((_) async => {});

      await tester.pumpWidget(const GetMaterialApp(home: RegisterView()));
      
      final registerButton = find.widgetWithText(ElevatedButton, 'Crear cuenta');
      await tester.tap(registerButton);
      
      verify(() => mockController.register()).called(1);
    });
  });
}
