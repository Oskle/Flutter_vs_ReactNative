import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/academic_entities.dart';
import '../../domain/entities/dashboard_stats.dart';

class AppCache {
  AppCache._();

  static final AppCache instance = AppCache._();

  static const String _teacherCoursesPrefix = 'cache.teacher.courses.';
  static const String _studentCoursesPrefix = 'cache.student.courses.';
  static const String _teacherDashboardPrefix = 'cache.teacher.dashboard.';
  static const String _studentDashboardPrefix = 'cache.student.dashboard.';
  static const String _studentPendingPrefix = 'cache.student.pending.';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<void> setTeacherCourses(
    String owner,
    List<TeacherCourseOverview> courses,
  ) async {
    final prefs = await _prefs;
    final key = '$_teacherCoursesPrefix$owner';
    final payload = jsonEncode(courses.map(_teacherCourseToMap).toList());
    await prefs.setString(key, payload);
  }

  Future<List<TeacherCourseOverview>?> getTeacherCourses(String owner) async {
    final prefs = await _prefs;
    final key = '$_teacherCoursesPrefix$owner';
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded
          .whereType<Map>()
          .map((item) => _teacherCourseFromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> setStudentCourses(
    String studentKey,
    List<TeacherCourseOverview> courses,
  ) async {
    final prefs = await _prefs;
    final key = '$_studentCoursesPrefix$studentKey';
    final payload = jsonEncode(courses.map(_teacherCourseToMap).toList());
    await prefs.setString(key, payload);
  }

  Future<List<TeacherCourseOverview>?> getStudentCourses(String studentKey) async {
    final prefs = await _prefs;
    final key = '$_studentCoursesPrefix$studentKey';
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded
          .whereType<Map>()
          .map((item) => _teacherCourseFromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> setTeacherDashboard(
    String cycleId,
    DashboardConsolidated consolidated,
  ) async {
    final prefs = await _prefs;
    final key = '$_teacherDashboardPrefix$cycleId';
    final payload = jsonEncode(_dashboardConsolidatedToMap(consolidated));
    await prefs.setString(key, payload);
  }

  Future<DashboardConsolidated?> getTeacherDashboard(String cycleId) async {
    final prefs = await _prefs;
    final key = '$_teacherDashboardPrefix$cycleId';
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return _dashboardConsolidatedFromMap(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  Future<void> setStudentDashboard(
    String studentUid,
    List<EvaluationResult> results,
  ) async {
    final prefs = await _prefs;
    final key = '$_studentDashboardPrefix$studentUid';
    final payload = jsonEncode(results.map(_evaluationResultToMap).toList());
    await prefs.setString(key, payload);
  }

  Future<List<EvaluationResult>?> getStudentDashboard(String studentUid) async {
    final prefs = await _prefs;
    final key = '$_studentDashboardPrefix$studentUid';
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded
          .whereType<Map>()
          .map((item) => _evaluationResultFromMap(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> setPendingEvaluations(
    String studentKey,
    List<PendingEvaluationInfo> pendingEvaluations,
  ) async {
    final prefs = await _prefs;
    final key = '$_studentPendingPrefix$studentKey';
    final payload = jsonEncode(
      pendingEvaluations.map(_pendingEvaluationToMap).toList(),
    );
    await prefs.setString(key, payload);
  }

  Future<List<PendingEvaluationInfo>?> getPendingEvaluations(
    String studentKey,
  ) async {
    final prefs = await _prefs;
    final key = '$_studentPendingPrefix$studentKey';
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded
          .whereType<Map>()
          .map(
            (item) => _pendingEvaluationFromMap(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> invalidateTeacherCourses(String owner) async {
    final prefs = await _prefs;
    await prefs.remove('$_teacherCoursesPrefix$owner');
  }

  Future<void> invalidateStudentCourses(String studentKey) async {
    final prefs = await _prefs;
    await prefs.remove('$_studentCoursesPrefix$studentKey');
  }

  Future<void> invalidateTeacherDashboardCycle(String cycleId) async {
    final prefs = await _prefs;
    await prefs.remove('$_teacherDashboardPrefix$cycleId');
  }

  Future<void> invalidateStudentDashboard(String studentUid) async {
    final prefs = await _prefs;
    await prefs.remove('$_studentDashboardPrefix$studentUid');
  }

  Future<void> invalidatePendingEvaluations(String studentKey) async {
    final prefs = await _prefs;
    await prefs.remove('$_studentPendingPrefix$studentKey');
  }

  Future<void> invalidateAllCourses() async {
    final prefs = await _prefs;
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_teacherCoursesPrefix) ||
          key.startsWith(_studentCoursesPrefix)) {
        await prefs.remove(key);
      }
    }
  }

  Future<void> invalidateAllDashboards() async {
    final prefs = await _prefs;
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_teacherDashboardPrefix) ||
          key.startsWith(_studentDashboardPrefix)) {
        await prefs.remove(key);
      }
    }
  }

  Future<void> invalidateAllPendingEvaluations() async {
    final prefs = await _prefs;
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_studentPendingPrefix)) {
        await prefs.remove(key);
      }
    }
  }

  Future<void> clearAll() async {
    await invalidateAllCourses();
    await invalidateAllDashboards();
    await invalidateAllPendingEvaluations();
  }

  Map<String, dynamic> _teacherCourseToMap(TeacherCourseOverview value) {
    return {
      'id': value.id,
      'name': value.name,
      'nrc': value.nrc,
      'term': value.term,
      'categoriesCount': value.categoriesCount,
      'groupsCount': value.groupsCount,
      'activeStudentsCount': value.activeStudentsCount,
      'categories': value.categories.map(_categoryToMap).toList(),
    };
  }

  TeacherCourseOverview _teacherCourseFromMap(Map<String, dynamic> map) {
    final categoriesRaw = map['categories'];
    return TeacherCourseOverview(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      nrc: (map['nrc'] ?? '').toString(),
      term: (map['term'] ?? '').toString(),
      categoriesCount: _asInt(map['categoriesCount']),
      groupsCount: _asInt(map['groupsCount']),
      activeStudentsCount: _asInt(map['activeStudentsCount']),
      categories: categoriesRaw is List
          ? categoriesRaw
                .whereType<Map>()
                .map((item) => _categoryFromMap(Map<String, dynamic>.from(item)))
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> _categoryToMap(CategoryOverview value) {
    return {
      'id': value.id,
      'name': value.name,
      'activeStudentsCount': value.activeStudentsCount,
      'groups': value.groups.map(_groupToMap).toList(),
    };
  }

  CategoryOverview _categoryFromMap(Map<String, dynamic> map) {
    final groupsRaw = map['groups'];
    return CategoryOverview(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      activeStudentsCount: _asInt(map['activeStudentsCount']),
      groups: groupsRaw is List
          ? groupsRaw
                .whereType<Map>()
                .map((item) => _groupFromMap(Map<String, dynamic>.from(item)))
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> _groupToMap(GroupOverview value) {
    return {
      'id': value.id,
      'code': value.code,
      'name': value.name,
      'activeStudentsCount': value.activeStudentsCount,
      'students': value.students.map(_studentToMap).toList(),
    };
  }

  GroupOverview _groupFromMap(Map<String, dynamic> map) {
    final studentsRaw = map['students'];
    return GroupOverview(
      id: (map['id'] ?? '').toString(),
      code: (map['code'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      activeStudentsCount: _asInt(map['activeStudentsCount']),
      students: studentsRaw is List
          ? studentsRaw
                .whereType<Map>()
                .map((item) => _studentFromMap(Map<String, dynamic>.from(item)))
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> _studentToMap(StudentOverview value) {
    return {
      'uid': value.uid,
      'name': value.name,
      'email': value.email,
      'studentId': value.studentId,
    };
  }

  StudentOverview _studentFromMap(Map<String, dynamic> map) {
    return StudentOverview(
      uid: (map['uid'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      studentId: (map['studentId'] ?? '').toString(),
    );
  }

  Map<String, dynamic> _evaluationResultToMap(EvaluationResult value) {
    return {
      'id': value.id,
      'cycleId': value.cycleId,
      'evaluatee': _studentToMap(value.evaluatee),
      'groupId': value.groupId,
      'groupName': value.groupName,
      'rubricScores': value.rubricScores,
      'averageTotal': value.averageTotal,
      'comments': value.comments,
      'totalEvaluators': value.totalEvaluators,
    };
  }

  Map<String, dynamic> _evaluationCycleToMap(EvaluationCycleData value) {
    return {
      'id': value.id,
      'courseId': value.courseId,
      'groupId': value.groupId,
      'title': value.title,
      'status': value.status,
      'openedBy': value.openedBy,
      'openedAt': value.openedAt.toIso8601String(),
      'closesAt': value.closesAt?.toIso8601String(),
      'rubrics': value.rubrics,
    };
  }

  EvaluationCycleData _evaluationCycleFromMap(Map<String, dynamic> map) {
    return EvaluationCycleData(
      id: (map['id'] ?? '').toString(),
      courseId: (map['courseId'] ?? '').toString(),
      groupId: (map['groupId'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
      openedBy: (map['openedBy'] ?? '').toString(),
      openedAt: DateTime.tryParse((map['openedAt'] ?? '').toString()) ??
          DateTime.now(),
      closesAt: map['closesAt'] == null || map['closesAt'].toString().isEmpty
          ? null
          : DateTime.tryParse(map['closesAt'].toString()),
      rubrics: (map['rubrics'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }

  Map<String, dynamic> _pendingEvaluationToMap(PendingEvaluationInfo value) {
    return {
      'cycle': _evaluationCycleToMap(value.cycle),
      'group': _groupToMap(value.group),
      'categoryName': value.categoryName,
      'peersToEvaluate': value.peersToEvaluate.map(_studentToMap).toList(),
      'alreadyEvaluatedUids': value.alreadyEvaluatedUids,
    };
  }

  PendingEvaluationInfo _pendingEvaluationFromMap(Map<String, dynamic> map) {
    final peersRaw = map['peersToEvaluate'];
    return PendingEvaluationInfo(
      cycle: _evaluationCycleFromMap(
        Map<String, dynamic>.from((map['cycle'] as Map?) ?? const {}),
      ),
      group: _groupFromMap(
        Map<String, dynamic>.from((map['group'] as Map?) ?? const {}),
      ),
      categoryName: (map['categoryName'] ?? '').toString(),
      peersToEvaluate: peersRaw is List
          ? peersRaw
                .whereType<Map>()
                .map((item) => _studentFromMap(Map<String, dynamic>.from(item)))
                .toList()
          : const [],
      alreadyEvaluatedUids:
          (map['alreadyEvaluatedUids'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }

  EvaluationResult _evaluationResultFromMap(Map<String, dynamic> map) {
    final rubricRaw = map['rubricScores'];
    final rubricScores = <String, double>{};
    if (rubricRaw is Map) {
      rubricRaw.forEach((key, value) {
        rubricScores[key.toString()] = _asDouble(value);
      });
    }

    final commentsRaw = map['comments'];

    return EvaluationResult(
      id: (map['id'] ?? '').toString(),
      cycleId: (map['cycleId'] ?? '').toString(),
      evaluatee: _studentFromMap(
        Map<String, dynamic>.from((map['evaluatee'] as Map?) ?? const {}),
      ),
      groupId: (map['groupId'] ?? '').toString(),
      groupName: (map['groupName'] ?? '').toString(),
      rubricScores: rubricScores,
      averageTotal: _asDouble(map['averageTotal']),
      comments: commentsRaw is List
          ? commentsRaw.map((item) => item.toString()).toList()
          : const [],
      totalEvaluators: _asInt(map['totalEvaluators']),
    );
  }

  Map<String, dynamic> _groupStatsToMap(GroupStats value) {
    return {
      'groupId': value.groupId,
      'groupName': value.groupName,
      'totalStudents': value.totalStudents,
      'evaluatedStudents': value.evaluatedStudents,
      'averageScore': value.averageScore,
    };
  }

  GroupStats _groupStatsFromMap(Map<String, dynamic> map) {
    return GroupStats(
      groupId: (map['groupId'] ?? '').toString(),
      groupName: (map['groupName'] ?? '').toString(),
      totalStudents: _asInt(map['totalStudents']),
      evaluatedStudents: _asInt(map['evaluatedStudents']),
      averageScore: _asDouble(map['averageScore']),
    );
  }

  Map<String, dynamic> _dashboardConsolidatedToMap(
    DashboardConsolidated value,
  ) {
    return {
      'cycleTitle': value.cycleTitle,
      'results': value.results.map(_evaluationResultToMap).toList(),
      'groupAverage': value.groupAverage,
      'totalStudents': value.totalStudents,
      'evaluatedStudents': value.evaluatedStudents,
      'pendingStudents': value.pendingStudents,
      'totalEvaluationsSubmitted': value.totalEvaluationsSubmitted,
      'rubricAverages': value.rubricAverages,
      'groupStats': value.groupStats.map(_groupStatsToMap).toList(),
      'topStudents': value.topStudents.map(_evaluationResultToMap).toList(),
      'lowStudents': value.lowStudents.map(_evaluationResultToMap).toList(),
    };
  }

  DashboardConsolidated _dashboardConsolidatedFromMap(Map<String, dynamic> map) {
    final resultsRaw = map['results'];
    final groupStatsRaw = map['groupStats'];
    final topStudentsRaw = map['topStudents'];
    final lowStudentsRaw = map['lowStudents'];
    final rubricAveragesRaw = map['rubricAverages'];

    final rubricAverages = <String, double>{};
    if (rubricAveragesRaw is Map) {
      rubricAveragesRaw.forEach((key, value) {
        rubricAverages[key.toString()] = _asDouble(value);
      });
    }

    return DashboardConsolidated(
      cycleTitle: (map['cycleTitle'] ?? '').toString(),
      results: resultsRaw is List
          ? resultsRaw
                .whereType<Map>()
                .map(
                  (item) =>
                      _evaluationResultFromMap(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
      groupAverage: _asDouble(map['groupAverage']),
      totalStudents: _asInt(map['totalStudents']),
      evaluatedStudents: _asInt(map['evaluatedStudents']),
      pendingStudents: _asInt(map['pendingStudents']),
      totalEvaluationsSubmitted: _asInt(map['totalEvaluationsSubmitted']),
      rubricAverages: rubricAverages,
      groupStats: groupStatsRaw is List
          ? groupStatsRaw
                .whereType<Map>()
                .map(
                  (item) => _groupStatsFromMap(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
      topStudents: topStudentsRaw is List
          ? topStudentsRaw
                .whereType<Map>()
                .map(
                  (item) =>
                      _evaluationResultFromMap(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
      lowStudents: lowStudentsRaw is List
          ? lowStudentsRaw
                .whereType<Map>()
                .map(
                  (item) =>
                      _evaluationResultFromMap(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
    );
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _asDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
