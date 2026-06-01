import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:coeval/presentation/student_view/views/student_home_view.dart';
import 'package:coeval/presentation/student_view/controllers/student_home_controller.dart';
import 'package:coeval/presentation/auth/controllers/auth_controller.dart';
import 'package:coeval/domain/entities/academic_entities.dart';
import 'package:coeval/data/datasources/roble_datasource.dart';
import '../../mocks/mock_student_controller.dart';
import '../../mocks/mock_auth_controller.dart';

void main() {
  late MockStudentHomeController mockStudentController;
  late MockAuthController mockAuthController;

  setUp(() {
    mockStudentController = MockStudentHomeController();
    mockAuthController = MockAuthController();

    // Configure AuthController with direct assignment
    mockAuthController.isLoggedIn.value = true;
    mockAuthController.currentUser.value = UserData(
      id: '1',
      uid: 'uid123',
      email: 'student@uninorte.edu.co',
      name: 'Student Test',
      role: 'student',
    );

    // Mock methods
    when(() => mockStudentController.loadCourses()).thenAnswer((_) async {});
    when(() => mockStudentController.loadPendingEvaluations()).thenAnswer((_) async {});
    when(() => mockAuthController.logout()).thenAnswer((_) async {});

    Get.put<AuthController>(mockAuthController);
    Get.put<StudentHomeController>(mockStudentController);
  });

  tearDown(() {
    Get.reset();
  });

  group('StudentHomeView - Pruebas de Nivel 1', () {
    testWidgets('Debe mostrar mensaje cuando no hay cursos', (WidgetTester tester) async {
      await tester.pumpWidget(const GetMaterialApp(home: StudentHomeView()));

      expect(find.text('Mis Cursos'), findsOneWidget);
      expect(find.text('No estás inscrito en cursos todavía'), findsOneWidget);
    });

    testWidgets('Debe mostrar CircularProgressIndicator al cargar cursos', (WidgetTester tester) async {
      mockStudentController.isLoading.value = true;
      mockStudentController.courses.clear();

      await tester.pumpWidget(const GetMaterialApp(home: StudentHomeView()));
      
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Debe mostrar la lista de cursos correctamente', (WidgetTester tester) async {
      final course = TeacherCourseOverview(
        id: 'c1',
        name: 'Curso de Prueba',
        nrc: '1234',
        term: '202410',
        categoriesCount: 1,
        groupsCount: 1,
        activeStudentsCount: 30,
        categories: [],
      );
      
      mockStudentController.courses.add(course);

      await tester.pumpWidget(const GetMaterialApp(home: StudentHomeView()));
      await tester.pump();

      expect(find.text('Curso de Prueba'), findsOneWidget);
      expect(find.text('NRC 1234 · 202410'), findsOneWidget);
    });

    testWidgets('Debe mostrar el badge de evaluaciones pendientes si existen', (WidgetTester tester) async {
      final pendingInfo = PendingEvaluationInfo(
        cycle: EvaluationCycleData(
          id: 'cycle1',
          courseId: 'course1',
          groupId: 'g1',
          title: 'Evaluación Test',
          status: 'open',
          openedBy: 'teacher@test.com',
          openedAt: DateTime.now(),
          rubrics: ['Criterio'],
        ),
        group: GroupOverview(
          id: 'g1',
          name: 'Grupo 1',
          code: 'G1',
          activeStudentsCount: 5,
          students: [],
        ),
        categoryName: 'Categoría Test',
        peersToEvaluate: [
          StudentOverview(uid: 'u1', name: 'Peer 1', email: 'p1@test.com', studentId: '1'),
          StudentOverview(uid: 'u2', name: 'Peer 2', email: 'p2@test.com', studentId: '2'),
          StudentOverview(uid: 'u3', name: 'Peer 3', email: 'p3@test.com', studentId: '3'),
          StudentOverview(uid: 'u4', name: 'Peer 4', email: 'p4@test.com', studentId: '4'),
          StudentOverview(uid: 'u5', name: 'Peer 5', email: 'p5@test.com', studentId: '5'),
        ],
        alreadyEvaluatedUids: [],
      );
      mockStudentController.pendingEvaluations.add(pendingInfo);

      await tester.pumpWidget(const GetMaterialApp(home: StudentHomeView()));
      await tester.pump();

      expect(find.text('5'), findsOneWidget);
      expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);
    });

    testWidgets('Debe llamar al logout del AuthController al pulsar el botón de salida', (WidgetTester tester) async {
      await tester.pumpWidget(const GetMaterialApp(home: StudentHomeView()));
      await tester.pump();
      
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pump();
      
      verify(() => mockAuthController.logout()).called(1);
    });
  });
}
