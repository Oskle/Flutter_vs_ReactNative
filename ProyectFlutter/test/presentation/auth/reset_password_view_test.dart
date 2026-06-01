import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:coeval/presentation/auth/views/reset_password_view.dart';
import 'package:coeval/presentation/auth/controllers/reset_password_controller.dart';
import '../../mocks/mock_reset_password_controller.dart';

void main() {
  late MockResetPasswordController mockController;

  setUp(() {
    mockController = MockResetPasswordController();

    // Mock methods
    when(() => mockController.resetPassword()).thenAnswer((_) async {});

    Get.put<ResetPasswordController>(mockController);
  });

  tearDown(() {
    Get.reset();
  });

  group('ResetPasswordView - Pruebas de Nivel 1', () {
    testWidgets('Debe mostrar los elementos de restablecimiento correctamente', (WidgetTester tester) async {
      await tester.pumpWidget(const GetMaterialApp(home: ResetPasswordView()));

      expect(find.text('Restablecer Contraseña'), findsAtLeastNWidgets(2));
      expect(find.text('Ingresa el token de recuperación y tu nueva contraseña'), findsOneWidget);
      
      expect(find.widgetWithText(TextField, 'Token de recuperación'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Nueva contraseña'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Confirmar contraseña'), findsOneWidget);
    });

    testWidgets('Debe mostrar errores de validación si el controlador los emite', (WidgetTester tester) async {
      mockController.tokenError.value = 'El token es requerido';
      mockController.confirmPasswordError.value = 'Las contraseñas no coinciden';

      await tester.pumpWidget(const GetMaterialApp(home: ResetPasswordView()));
      await tester.pump();

      expect(find.text('El token es requerido'), findsOneWidget);
      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
    });

    testWidgets('Debe mostrar CircularProgressIndicator cuando isLoading es true', (WidgetTester tester) async {
      mockController.isLoading.value = true;

      await tester.pumpWidget(const GetMaterialApp(home: ResetPasswordView()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Debe llamar a resetPassword al pulsar el botón', (WidgetTester tester) async {
      await tester.pumpWidget(const GetMaterialApp(home: ResetPasswordView()));
      await tester.pumpAndSettle();
      
      final button = find.widgetWithText(ElevatedButton, 'Restablecer Contraseña');
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pump();
      
      verify(() => mockController.resetPassword()).called(1);
    });
  });
}
