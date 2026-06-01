import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:coeval/presentation/student_view/views/evaluate_peers_view.dart';
import 'package:coeval/presentation/student_view/controllers/student_home_controller.dart';
import 'package:coeval/domain/entities/academic_entities.dart';
import '../../mocks/mock_student_controller.dart';

void main() {
  late MockStudentHomeController mockController;

  final testPendingInfo = PendingEvaluationInfo(
    cycle: EvaluationCycleData(
      id: 'cycle1',
      courseId: 'course1',
      groupId: 'g1',
      title: 'Evaluación de Prueba',
      status: 'open',
      openedBy: 'teacher@test.com',
      openedAt: DateTime.now(),
      closesAt: DateTime.now().add(const Duration(days: 7)),
      rubrics: ['Responsabilidad', 'Cooperación'],
    ),
    group: GroupOverview(
      id: 'g1',
      name: 'Grupo 1',
      code: 'G1',
      activeStudentsCount: 5,
      students: [],
    ),
    categoryName: 'Parcial 1',
    peersToEvaluate: [
      StudentOverview(uid: 'u1', name: 'Compañero 1', email: 'c1@test.com', studentId: '2001'),
      StudentOverview(uid: 'u2', name: 'Compañero 2', email: 'c2@test.com', studentId: '2002'),
    ],
    alreadyEvaluatedUids: [],
  );

  setUp(() {
    mockController = MockStudentHomeController();
    
    // Configurar el mock para que Get.find no falle
    Get.put<StudentHomeController>(mockController);
  });

  tearDown(() {
    Get.reset();
  });

  group('EvaluatePeersView - Pruebas de Nivel 1', () {
    testWidgets('Debe mostrar la lista de compañeros por evaluar', (WidgetTester tester) async {
      await tester.pumpWidget(GetMaterialApp(
        home: EvaluatePeersView(pendingInfo: testPendingInfo),
      ));

      expect(find.text('Evaluación de Prueba'), findsOneWidget);
      expect(find.text('Grupo 1'), findsOneWidget);
      expect(find.text('Compañero 1'), findsOneWidget);
      expect(find.text('Compañero 2'), findsOneWidget);
    });

    testWidgets('Debe mostrar las rúbricas configuradas para cada compañero', (WidgetTester tester) async {
      await tester.pumpWidget(GetMaterialApp(
        home: EvaluatePeersView(pendingInfo: testPendingInfo),
      ));

      // Busca las rúbricas definidas en testPendingInfo
      expect(find.text('Responsabilidad'), findsNWidgets(2));
      expect(find.text('Cooperación'), findsNWidgets(2));
    });

    testWidgets('Debe permitir cambiar el valor de un slider (simulado)', (WidgetTester tester) async {
      await tester.pumpWidget(GetMaterialApp(
        home: EvaluatePeersView(pendingInfo: testPendingInfo),
      ));

      // El valor por defecto es 3. Verificamos que existan indicadores de puntuación "3"
      expect(find.text('3'), findsAtLeastNWidgets(4)); // 2 compañeros * 2 rúbricas
    });

    testWidgets('Debe llamar a submitEvaluation del controlador al enviar', (WidgetTester tester) async {
      when(() => mockController.submitEvaluation(
        cycleId: any(named: 'cycleId'),
        evaluateeUid: any(named: 'evaluateeUid'),
        scores: any(named: 'scores'),
        comments: any(named: 'comments'),
      )).thenAnswer((_) async => true);

      await tester.pumpWidget(GetMaterialApp(
        home: EvaluatePeersView(pendingInfo: testPendingInfo),
      ));

      // Pulsar el botón de enviar para el primer compañero
      final submitButtons = find.widgetWithText(ElevatedButton, 'Enviar Evaluación');
      await tester.tap(submitButtons.first);
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      verify(() => mockController.submitEvaluation(
        cycleId: 'cycle1',
        evaluateeUid: 'u1',
        scores: [3, 3],
        comments: null,
      )).called(1);
    });

    testWidgets('Debe mostrar pantalla de éxito cuando ya no quedan compañeros por evaluar', (WidgetTester tester) async {
      final infoCompletada = PendingEvaluationInfo(
        cycle: testPendingInfo.cycle,
        group: testPendingInfo.group,
        categoryName: 'Parcial 1',
        peersToEvaluate: [
          StudentOverview(uid: 'u1', name: 'C1', email: 'e1@test.com', studentId: '2001'),
        ],
        alreadyEvaluatedUids: ['u1'], // Marcado como evaluado
      );

      await tester.pumpWidget(GetMaterialApp(
        home: EvaluatePeersView(pendingInfo: infoCompletada),
      ));
      await tester.pump();

      expect(find.text('Has evaluado a todos tus compañeros'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });
}
