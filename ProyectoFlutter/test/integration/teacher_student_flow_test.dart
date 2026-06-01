import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:coeval/data/datasources/academic_remote_datasource.dart';
import 'package:coeval/data/datasources/dashboard_remote_datasource.dart';
import 'package:coeval/data/datasources/roble_datasource.dart';
import 'package:coeval/data/repositories/academic_repository_impl.dart';
import 'package:coeval/data/repositories/dashboard_repository_impl.dart';
import 'package:coeval/domain/entities/academic_entities.dart';

void main() {
  group('Nivel 3 - Integracion flujo profesor/estudiante', () {
    late RobleDatasource robleDatasource;
    late AcademicRepositoryImpl academicRepository;
    late DashboardRepositoryImpl dashboardRepository;

    late Map<String, List<Map<String, dynamic>>> tables;
    int idCounter = 1;

    String nextId() => 'id_${idCounter++}';

    bool matchesFilter(dynamic rowValue, String queryValue) {
      if (rowValue == null) return false;
      final rowString = rowValue.toString().toLowerCase();
      final queryString = queryValue.toLowerCase();
      return rowString == queryString;
    }

    List<Map<String, dynamic>> readRows(
      String tableName,
      Map<String, String> query,
    ) {
      final source = tables[tableName] ?? const [];
      return source.where((row) {
        for (final entry in query.entries) {
          if (entry.key == 'tableName') continue;
          if (!matchesFilter(row[entry.key], entry.value)) {
            return false;
          }
        }
        return true;
      }).map((row) => Map<String, dynamic>.from(row)).toList();
    }

    setUp(() {
      tables = {
        'users': [
          {
            '_id': 'u_teacher',
            'uid': 'teacher_1',
            'email': 'teacher@uninorte.edu.co',
            'name': 'Profe Uno',
            'rol': 'teacher',
          },
          {
            '_id': 'u_student_1',
            'uid': 'student_1',
            'email': 'ana@uninorte.edu.co',
            'name': 'Ana',
            'rol': 'student',
          },
          {
            '_id': 'u_student_2',
            'uid': 'student_2',
            'email': 'bruno@uninorte.edu.co',
            'name': 'Bruno',
            'rol': 'student',
          },
        ],
        'courses': [],
        'group_categories': [],
        'groups': [],
        'enrollments': [],
        'csv_imports': [],
        'evaluation_cycles': [],
        'evaluations': [],
      };

      robleDatasource = RobleDatasource();
      robleDatasource.setToken('fake_token');

      robleDatasource.client = MockClient((request) async {
        final path = request.url.path;

        if (path.endsWith('/read')) {
          final tableName = request.url.queryParameters['tableName'];
          if (tableName == null) {
            return http.Response(jsonEncode({'error': 'tableName requerido'}), 400);
          }

          final rows = readRows(tableName, request.url.queryParameters);
          return http.Response(jsonEncode(rows), 200);
        }

        if (path.endsWith('/insert')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final tableName = body['tableName']?.toString() ?? '';
          final records = (body['records'] as List?) ?? const [];
          if (tableName.isEmpty || records.isEmpty) {
            return http.Response(jsonEncode({'inserted': []}), 400);
          }

          final inserted = <Map<String, dynamic>>[];
          for (final raw in records) {
            final row = Map<String, dynamic>.from(raw as Map);
            row.putIfAbsent('_id', nextId);
            (tables[tableName] ??= []).add(row);
            inserted.add(Map<String, dynamic>.from(row));
          }

          return http.Response(jsonEncode({'inserted': inserted}), 201);
        }

        if (path.endsWith('/update')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final tableName = body['tableName']?.toString() ?? '';
          final where = Map<String, dynamic>.from(
            (body['where'] ?? body['filters'] ?? const <String, dynamic>{}) as Map,
          );
          final set = Map<String, dynamic>.from(
            (body['set'] ?? body['updates'] ?? const <String, dynamic>{}) as Map,
          );

          var updated = 0;
          final rows = tables[tableName] ?? const [];
          for (final row in rows) {
            var match = true;
            for (final entry in where.entries) {
              if ((row[entry.key]?.toString() ?? '') != entry.value.toString()) {
                match = false;
                break;
              }
            }
            if (!match) continue;
            row.addAll(set);
            updated++;
          }

          return http.Response(jsonEncode({'updated': updated}), 200);
        }

        return http.Response(jsonEncode({'error': 'not found'}), 404);
      });

      academicRepository = AcademicRepositoryImpl(
        AcademicRemoteDatasource(robleDatasource),
      );
      dashboardRepository = DashboardRepositoryImpl(
        DashboardRemoteDatasource(robleDatasource),
      );
    });

    test('profesor crea curso, sincroniza CSV, estudiante evalua y dashboard consolida', () async {
      final createdCourse = await academicRepository.createCourse(
        name: 'Moviles Avanzados',
        nrc: '3001',
        term: '2026-1',
        teacherUid: 'teacher@uninorte.edu.co',
      );

      expect(createdCourse, isNotNull);
      final courseId = createdCourse!.id;

      const csv =
          'CategoriaA,Grupo 1,G1,ana@uninorte.edu.co,1001,Ana,Perez\n'
          'CategoriaA,Grupo 1,G1,bruno@uninorte.edu.co,1002,Bruno,Ruiz';

      final syncResult = await academicRepository.syncCategoryFromCsv(
        courseId: courseId,
        categoryName: 'CategoriaA',
        csvContent: csv,
        uploadedBy: 'teacher@uninorte.edu.co',
      );

      expect(syncResult.totalRows, 2);
      expect(syncResult.createdGroups, greaterThanOrEqualTo(1));
      expect(syncResult.activatedEnrollments, 2);

      final teacherCourses = await academicRepository.getTeacherCourseOverviews(
        'teacher@uninorte.edu.co',
      );
      expect(teacherCourses, isNotEmpty);
      expect(teacherCourses.first.categories, isNotEmpty);
      expect(teacherCourses.first.categories.first.groups, isNotEmpty);

      final categoryId = teacherCourses.first.categories.first.id;

      final cycle = await academicRepository.createEvaluationCycle(
        courseId: courseId,
        categoryId: categoryId,
        title: 'Actividad 1',
        openedBy: 'teacher@uninorte.edu.co',
        rubrics: const ['Puntualidad', 'Compromiso'],
        evaluationScope: EvaluationScope.ownGroup,
      );

      expect(cycle, isNotNull);

      final studentCourses = await academicRepository.getStudentCourseOverviews(
        studentEmail: 'ana@uninorte.edu.co',
        studentUid: 'student_1',
      );
      expect(studentCourses, isNotEmpty);

      final pendingForAna = await academicRepository.getPendingEvaluationsForStudent(
        studentUid: 'student_1',
        studentEmail: 'ana@uninorte.edu.co',
      );
      expect(pendingForAna, isNotEmpty);

      final submitOk = await academicRepository.submitEvaluation(
        cycleId: cycle!.id,
        evaluatorUid: 'student_1',
        evaluateeUid: 'student_2',
        scores: const [4, 5],
        comments: 'Buen aporte al equipo',
      );
      expect(submitOk, isTrue);

      final submitted = await academicRepository.getSubmittedEvaluations(
        cycleId: cycle.id,
        evaluatorUid: 'student_1',
      );
      expect(submitted, isNotEmpty);
      expect(submitted.first.averageScore, 4.5);

      final teacherDashboard = await dashboardRepository.getResultsForTeacher(
        cycle.id,
      );
      expect(teacherDashboard.results.length, 1);
      expect(teacherDashboard.groupAverage, 4.5);
      expect(teacherDashboard.totalStudents, 2);
      expect(teacherDashboard.evaluatedStudents, 1);
      expect(teacherDashboard.pendingStudents, 1);

      final studentDashboard = await dashboardRepository.getResultsForStudent(
        'student_2',
      );
      expect(studentDashboard, isNotEmpty);
      expect(studentDashboard.first.averageTotal, 4.5);
    });
  });
}
