import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:coeval/presentation/teacher_view/views/teacher_home_view.dart';
import 'package:coeval/presentation/teacher_view/controllers/teacher_home_controller.dart';
import 'package:coeval/presentation/auth/controllers/auth_controller.dart';
import 'package:coeval/domain/entities/academic_entities.dart';
import 'package:coeval/data/datasources/roble_datasource.dart';
import '../../mocks/mock_teacher_controller.dart';
import '../../mocks/mock_auth_controller.dart';

void main() {
  late MockTeacherHomeController mockTeacherController;
  late MockAuthController mockAuthController;

  setUp(() {
    mockTeacherController = MockTeacherHomeController();
    mockAuthController = MockAuthController();

    // Configure AuthController with direct assignment
    mockAuthController.isLoggedIn.value = true;
    mockAuthController.currentUser.value = UserData(
      id: '1',
      uid: 'uid123',
      email: 'teacher@uninorte.edu.co',
      name: 'Teacher Test',
      role: 'teacher',
    );

    // Mock methods
    when(() => mockAuthController.logout()).thenAnswer((_) async {});

    Get.put<TeacherHomeController>(mockTeacherController);
    Get.put<AuthController>(mockAuthController);
  });

  tearDown(() => Get.reset());

  group('TeacherHomeView - Pruebas de Nivel 1', () {
    testWidgets('Debe mostrar el título "My Courses" y botón de logout', (WidgetTester tester) async {
      await tester.pumpWidget(const GetMaterialApp(home: TeacherHomeView()));

      expect(find.text('My Courses'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('Debe mostrar CircularProgressIndicator al cargar cursos', (WidgetTester tester) async {
      mockTeacherController.isLoading.value = true;
      mockTeacherController.courses.clear();

      await tester.pumpWidget(const GetMaterialApp(home: TeacherHomeView()));
      
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Debe mostrar mensaje de no hay cursos cuando la lista está vacía', (WidgetTester tester) async {
      await tester.pumpWidget(const GetMaterialApp(home: TeacherHomeView()));
      await tester.pumpAndSettle();

      expect(find.text('No hay cursos todavía'), findsOneWidget);
    });

    testWidgets('Debe mostrar la lista de cursos correctamente', (WidgetTester tester) async {
      final mockCourse = TeacherCourseOverview(
        id: 'c1',
        name: 'Curso Docente Test',
        nrc: '9988',
        term: '202410',
        categoriesCount: 2,
        groupsCount: 4,
        activeStudentsCount: 20,
        categories: [],
      );

      mockTeacherController.courses.add(mockCourse);

      await tester.pumpWidget(const GetMaterialApp(home: TeacherHomeView()));
      await tester.pumpAndSettle();

      expect(find.text('Curso Docente Test'), findsOneWidget);
      expect(find.text('NRC 9988 · 202410'), findsOneWidget);
      expect(find.text('2 categorías'), findsOneWidget);
      expect(find.text('4 grupos'), findsOneWidget);
    });

    testWidgets('Debe abrir el diálogo de crear curso al pulsar el FAB', (WidgetTester tester) async {
      await tester.pumpWidget(const GetMaterialApp(home: TeacherHomeView()));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Crear curso'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Nombre'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'NRC'), findsOneWidget);
    });

    testWidgets('Debe llamar al logout del AuthController al pulsar el botón de salida', (WidgetTester tester) async {
      await tester.pumpWidget(const GetMaterialApp(home: TeacherHomeView()));
      await tester.pump();
      
      await tester.tap(find.byIcon(Icons.logout));
      await tester.pump();
      
      verify(() => mockAuthController.logout()).called(1);
    });
  });
}
