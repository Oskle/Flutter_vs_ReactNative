import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:coeval/presentation/student_view/views/student_course_detail_view.dart';
import 'package:coeval/presentation/student_view/controllers/student_home_controller.dart';
import 'package:coeval/presentation/auth/controllers/auth_controller.dart';
import 'package:coeval/domain/entities/academic_entities.dart';
import 'package:coeval/data/datasources/roble_datasource.dart';
import '../../mocks/mock_student_controller.dart';
import '../../mocks/mock_auth_controller.dart';

void main() {
  late MockStudentHomeController mockStudentController;
  late MockAuthController mockAuthController;

  final testCourse = TeacherCourseOverview(
    id: 'course1',
    name: 'Ingeniería de Software',
    nrc: '5544',
    term: '202410',
    categoriesCount: 1,
    groupsCount: 1,
    activeStudentsCount: 20,
    categories: [
      CategoryOverview(
        id: 'cat1',
        name: 'Primer Parcial',
        activeStudentsCount: 20,
        groups: [
          GroupOverview(
            id: 'g1',
            code: 'G1',
            name: 'Grupo Alpha',
            activeStudentsCount: 5,
            students: [
              StudentOverview(
                uid: 'me-uid',
                name: 'Yo Estudiante',
                email: 'yo@uninorte.edu.co',
                studentId: '1001',
              ),
              StudentOverview(
                uid: 'peer-uid',
                name: 'Compañero 1',
                email: 'peer1@uninorte.edu.co',
                studentId: '1002',
              ),
            ],
          ),
        ],
      ),
    ],
  );

  setUp(() {
    mockStudentController = MockStudentHomeController();
    mockAuthController = MockAuthController();

    // Configure AuthController with direct assignment
    mockAuthController.isLoggedIn.value = true;
    mockAuthController.currentUser.value = UserData(
      id: 'me-id',
      uid: 'me-uid',
      email: 'yo@uninorte.edu.co',
      name: 'Yo Estudiante',
      role: 'student',
    );

    // Mock methods
    when(() => mockStudentController.getPendingEvaluations()).thenAnswer((_) async => []);

    Get.put<AuthController>(mockAuthController);
    Get.put<StudentHomeController>(mockStudentController);
  });

  tearDown(() {
    Get.reset();
  });

  group('StudentCourseDetailView - Pruebas de Nivel 1', () {
    testWidgets('Debe mostrar el nombre del curso en el AppBar', (WidgetTester tester) async {
      await tester.pumpWidget(GetMaterialApp(
        home: StudentCourseDetailView(course: testCourse),
      ));

      expect(find.text('Ingeniería de Software'), findsOneWidget);
    });

    testWidgets('Debe mostrar mensaje de no hay evaluaciones pendientes cuando la lista es vacía', (WidgetTester tester) async {
      await tester.pumpWidget(GetMaterialApp(
        home: StudentCourseDetailView(course: testCourse),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No tienes evaluaciones pendientes'), findsOneWidget);
    });

    testWidgets('Debe mostrar la sección de "Mis Grupos" con mis compañeros', (WidgetTester tester) async {
      await tester.pumpWidget(GetMaterialApp(
        home: StudentCourseDetailView(course: testCourse),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Mis Grupos'), findsOneWidget);
      expect(find.text('Grupo Alpha (G1)'), findsOneWidget);
      expect(find.text('Yo Estudiante (Tú)'), findsOneWidget);
      expect(find.text('Compañero 1'), findsOneWidget);
    });

    testWidgets('Debe mostrar una evaluación pendiente si existe para este curso', (WidgetTester tester) async {
      final pendingEval = PendingEvaluationInfo(
        cycle: EvaluationCycleData(
          id: 'cycle1',
          courseId: 'course1',
          groupId: 'g1',
          title: 'Evaluación 1',
          status: 'open',
          openedBy: 'teacher@test.com',
          openedAt: DateTime.now(),
          closesAt: DateTime.now().add(const Duration(days: 1)),
          rubrics: [],
        ),
        group: testCourse.categories[0].groups[0],
        categoryName: 'Primer Parcial',
        peersToEvaluate: [
          StudentOverview(uid: 'peer-uid', name: 'Compañero 1', email: 'peer1@test.com', studentId: '1002'),
        ],
        alreadyEvaluatedUids: [],
      );

      when(() => mockStudentController.getPendingEvaluations()).thenAnswer((_) async => [pendingEval]);

      await tester.pumpWidget(GetMaterialApp(
        home: StudentCourseDetailView(course: testCourse),
      ));
      
      // Forzamos el renderizado después de que termine la carga asíncrona del initState
      await tester.pump(); 
      await tester.pump();

      expect(find.text('Evaluación 1'), findsOneWidget);
      expect(find.text('1 pendiente'), findsOneWidget);
    });
  });
}
