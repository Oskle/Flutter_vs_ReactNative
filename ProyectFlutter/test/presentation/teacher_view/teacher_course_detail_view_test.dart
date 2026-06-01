import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:coeval/presentation/teacher_view/views/teacher_course_detail_view.dart';
import 'package:coeval/presentation/teacher_view/controllers/teacher_home_controller.dart';
import 'package:coeval/domain/entities/academic_entities.dart';
import '../../mocks/mock_teacher_controller.dart';

void main() {
  late MockTeacherHomeController mockController;

  final testCourse = TeacherCourseOverview(
    id: 'c1',
    name: 'Software Testing',
    nrc: '1010',
    term: '202410',
    categoriesCount: 1,
    groupsCount: 1,
    activeStudentsCount: 5,
    categories: [
      CategoryOverview(
        id: 'cat1',
        name: 'Sprint 1',
        activeStudentsCount: 5,
        groups: [
          GroupOverview(
            id: 'g1',
            code: 'G1',
            name: 'DevTeam 1',
            activeStudentsCount: 5,
            students: [
              StudentOverview(
                uid: 's1',
                name: 'Student 1',
                email: 's1@test.com',
                studentId: '101',
              ),
            ],
          ),
        ],
      ),
    ],
  );

  setUp(() {
    mockController = MockTeacherHomeController();

    // Mocking methods
    when(() => mockController.getEvaluationCyclesByCourse(any()))
        .thenAnswer((_) async => []);

    Get.put<TeacherHomeController>(mockController);
  });

  tearDown(() => Get.reset());

  group('TeacherCourseDetailView - Pruebas de Nivel 1', () {
    testWidgets('Debe mostrar las pestañas "Grupos" y "Evaluaciones"', (WidgetTester tester) async {
      await tester.pumpWidget(GetMaterialApp(
        home: TeacherCourseDetailView(course: testCourse),
      ));

      expect(find.text('Grupos'), findsOneWidget);
      expect(find.text('Evaluaciones'), findsOneWidget);
    });

    testWidgets('Debe mostrar la categoría y el grupo en la pestaña de Grupos', (WidgetTester tester) async {
      await tester.pumpWidget(GetMaterialApp(
        home: TeacherCourseDetailView(course: testCourse),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Sprint 1'), findsOneWidget);
      
      // Expand the category ExpansionTile to see the groups
      await tester.tap(find.text('Sprint 1'));
      await tester.pumpAndSettle();

      expect(find.text('DevTeam 1'), findsOneWidget);
    });

    testWidgets('Debe mostrar mensaje cuando no hay evaluaciones en la pestaña correspondiente', (WidgetTester tester) async {
      await tester.pumpWidget(GetMaterialApp(
        home: TeacherCourseDetailView(course: testCourse),
      ));

      // Cambiar a la pestaña de evaluaciones
      await tester.tap(find.text('Evaluaciones'));
      await tester.pumpAndSettle();

      expect(find.text('No hay evaluaciones todavía'), findsOneWidget);
    });

    testWidgets('Debe mostrar los ciclos de evaluación si existen', (WidgetTester tester) async {
      final cycle = EvaluationCycleData(
        id: 'cy1',
        courseId: 'c1',
        groupId: 'g1',
        title: 'Evaluación Parcial',
        status: 'open',
        openedBy: 'teacher@test.com',
        openedAt: DateTime.now(),
        rubrics: ['Puntualidad'],
      );

      when(() => mockController.getEvaluationCyclesByCourse('c1'))
          .thenAnswer((_) async => [cycle]);

      await tester.pumpWidget(GetMaterialApp(
        home: TeacherCourseDetailView(course: testCourse),
      ));

      await tester.tap(find.text('Evaluaciones'));
      await tester.pumpAndSettle();

      expect(find.text('Evaluación Parcial'), findsOneWidget);
      expect(find.text('Abierta'), findsOneWidget);
      expect(find.text('Puntualidad'), findsOneWidget);
    });

    testWidgets('Debe abrir el diálogo de "Nueva Evaluación" al pulsar el botón +', (WidgetTester tester) async {
      await tester.pumpWidget(GetMaterialApp(
        home: TeacherCourseDetailView(course: testCourse),
      ));

      await tester.tap(find.text('Evaluaciones'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Nueva Evaluación'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Título de la evaluación'), findsOneWidget);
    });
  });
}
