import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coeval/core/utils/app_cache.dart';
import 'package:coeval/domain/entities/academic_entities.dart';
import 'package:coeval/domain/entities/dashboard_stats.dart';

void main() {
  group('AppCache', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('guarda y lee cursos de profesor', () async {
      final cache = AppCache.instance;
      final courses = [
        TeacherCourseOverview(
          id: 'course_1',
          name: 'Movil I',
          nrc: '1234',
          term: '2026-1',
          categoriesCount: 1,
          groupsCount: 1,
          activeStudentsCount: 2,
          categories: [
            CategoryOverview(
              id: 'cat_1',
              name: 'CategoriaA',
              activeStudentsCount: 2,
              groups: [
                GroupOverview(
                  id: 'g_1',
                  code: 'G1',
                  name: 'Grupo 1',
                  activeStudentsCount: 2,
                  students: const [],
                ),
              ],
            ),
          ],
        ),
      ];

      await cache.setTeacherCourses('teacher@uninorte.edu.co', courses);
      final loaded = await cache.getTeacherCourses('teacher@uninorte.edu.co');

      expect(loaded, isNotNull);
      expect(loaded!.length, 1);
      expect(loaded.first.name, 'Movil I');
      expect(loaded.first.categories.first.groups.first.code, 'G1');
    });

    test('invalida cursos por owner y limpieza global', () async {
      final cache = AppCache.instance;
      final course = TeacherCourseOverview(
        id: 'course_1',
        name: 'Movil I',
        nrc: '1234',
        term: '2026-1',
        categoriesCount: 0,
        groupsCount: 0,
        activeStudentsCount: 0,
      );

      await cache.setTeacherCourses('teacher1', [course]);
      await cache.setTeacherCourses('teacher2', [course]);

      await cache.invalidateTeacherCourses('teacher1');
      final teacher1 = await cache.getTeacherCourses('teacher1');
      final teacher2 = await cache.getTeacherCourses('teacher2');

      expect(teacher1, isNull);
      expect(teacher2, isNotNull);

      await cache.invalidateAllCourses();
      final teacher2After = await cache.getTeacherCourses('teacher2');
      expect(teacher2After, isNull);
    });

    test('guarda y lee dashboard de profesor y estudiante', () async {
      final cache = AppCache.instance;
      final result = EvaluationResult(
        id: 'r1',
        cycleId: 'c1',
        evaluatee: StudentOverview(
          uid: 'u1',
          name: 'Ana',
          email: 'ana@uninorte.edu.co',
          studentId: '1001',
        ),
        groupId: 'g1',
        groupName: 'Grupo 1',
        rubricScores: const {'Puntualidad': 4.5},
        averageTotal: 4.5,
        comments: const ['Buen trabajo'],
        totalEvaluators: 2,
      );

      final consolidated = DashboardConsolidated(
        cycleTitle: 'Actividad 1',
        results: [result],
        groupAverage: 4.5,
        totalStudents: 2,
        evaluatedStudents: 1,
        pendingStudents: 1,
        totalEvaluationsSubmitted: 1,
        rubricAverages: const {'Puntualidad': 4.5},
        groupStats: [
          GroupStats(
            groupId: 'g1',
            groupName: 'Grupo 1',
            totalStudents: 2,
            evaluatedStudents: 1,
            averageScore: 4.5,
          ),
        ],
        topStudents: [result],
        lowStudents: [result],
      );

      await cache.setTeacherDashboard('cycle_1', consolidated);
      await cache.setStudentDashboard('u1', [result]);

      final teacher = await cache.getTeacherDashboard('cycle_1');
      final student = await cache.getStudentDashboard('u1');

      expect(teacher, isNotNull);
      expect(teacher!.cycleTitle, 'Actividad 1');
      expect(teacher.results.first.evaluatee.name, 'Ana');
      expect(student, isNotNull);
      expect(student!.length, 1);
      expect(student.first.averageTotal, 4.5);

      await cache.clearAll();
      final teacherAfter = await cache.getTeacherDashboard('cycle_1');
      final studentAfter = await cache.getStudentDashboard('u1');

      expect(teacherAfter, isNull);
      expect(studentAfter, isNull);
    });

    test('guarda, lee e invalida evaluaciones pendientes', () async {
      final cache = AppCache.instance;
      final pending = PendingEvaluationInfo(
        cycle: EvaluationCycleData(
          id: 'cycle_1',
          courseId: 'course_1',
          groupId: 'group_1',
          title: 'Actividad 1',
          status: 'open',
          openedBy: 'teacher@uninorte.edu.co',
          openedAt: DateTime.parse('2026-04-21T10:00:00Z'),
          rubrics: const ['Puntualidad'],
        ),
        group: GroupOverview(
          id: 'group_1',
          code: 'G1',
          name: 'Grupo 1',
          activeStudentsCount: 2,
          students: [
            StudentOverview(
              uid: 'student_1',
              name: 'Ana',
              email: 'ana@uninorte.edu.co',
              studentId: '1001',
            ),
          ],
        ),
        categoryName: 'CategoriaA',
        peersToEvaluate: [
          StudentOverview(
            uid: 'student_2',
            name: 'Bruno',
            email: 'bruno@uninorte.edu.co',
            studentId: '1002',
          ),
        ],
        alreadyEvaluatedUids: const [],
      );

      await cache.setPendingEvaluations('student_1', [pending]);
      final loaded = await cache.getPendingEvaluations('student_1');

      expect(loaded, isNotNull);
      expect(loaded!.length, 1);
      expect(loaded.first.cycle.title, 'Actividad 1');
      expect(loaded.first.peersToEvaluate.first.name, 'Bruno');

      await cache.invalidatePendingEvaluations('student_1');
      final afterInvalidation = await cache.getPendingEvaluations('student_1');
      expect(afterInvalidation, isNull);

      await cache.setPendingEvaluations('student_1', [pending]);
      await cache.clearAll();
      final afterClear = await cache.getPendingEvaluations('student_1');
      expect(afterClear, isNull);
    });
  });
}
