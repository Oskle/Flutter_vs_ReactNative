import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:coeval/presentation/dashboard/views/dashboard_view.dart';
import 'package:coeval/presentation/dashboard/controllers/dashboard_controller.dart';
import 'package:coeval/domain/entities/dashboard_stats.dart';
import 'package:coeval/domain/entities/academic_entities.dart';
import '../../mocks/mock_dashboard_controller.dart';

void main() {
  late MockDashboardController mockController;

  setUp(() {
    mockController = MockDashboardController();

    // Mocking observables
    when(() => mockController.isLoading).thenReturn(false.obs);
    when(() => mockController.studentResults).thenReturn(<EvaluationResult>[].obs);
    when(() => mockController.teacherConsolidated).thenReturn(Rxn<DashboardConsolidated>());
    
    // Mocking methods
    when(() => mockController.loadDashboardData(cycleId: any(named: 'cycleId')))
        .thenAnswer((_) async => {});

    Get.put<DashboardController>(mockController);
  });

  tearDown(() => Get.reset());

  group('DashboardView - Pruebas de Nivel 1', () {
    
    testWidgets('Debe mostrar estado de carga', (WidgetTester tester) async {
      when(() => mockController.isLoading).thenReturn(true.obs);

      await tester.pumpWidget(const GetMaterialApp(home: DashboardView()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Vista Estudiante: Debe mostrar mensaje si no hay resultados', (WidgetTester tester) async {
      when(() => mockController.isTeacher).thenReturn(false);
      when(() => mockController.studentResults).thenReturn(<EvaluationResult>[].obs);

      await tester.pumpWidget(const GetMaterialApp(home: DashboardView()));
      await tester.pump();

      expect(find.text('No tienes resultados de evaluaciones todavía.'), findsOneWidget);
    });

    testWidgets('Vista Estudiante: Debe mostrar card con promedios', (WidgetTester tester) async {
      when(() => mockController.isTeacher).thenReturn(false);
      final mockResult = EvaluationResult(
        id: '1',
        cycleId: 'Corte 1',
        evaluatee: StudentOverview(uid: 'me', name: 'Yo', email: '', studentId: ''),
        rubricScores: {'Liderazgo': 4.5},
        averageTotal: 4.5,
        comments: ['Buen trabajo'],
        totalEvaluators: 2,
      );
      when(() => mockController.studentResults).thenReturn(<EvaluationResult>[mockResult].obs);

      await tester.pumpWidget(const GetMaterialApp(home: DashboardView()));
      await tester.pump();

      expect(find.textContaining('Corte 1'), findsOneWidget);
      expect(find.text('4.5'), findsAtLeastNWidgets(1));
      expect(find.text('• "Buen trabajo"'), findsOneWidget);
    });

    testWidgets('Vista Docente: Debe mostrar mensaje cuando no hay consolidado', (WidgetTester tester) async {
      when(() => mockController.isTeacher).thenReturn(true);
      when(() => mockController.teacherConsolidated).thenReturn(Rxn<DashboardConsolidated>());

      await tester.pumpWidget(const GetMaterialApp(home: DashboardView(cycleId: 'cycle_final')));
      await tester.pump();

      expect(find.text('Selecciona una evaluación para ver los resultados.'), findsOneWidget);
    });
  });
}
