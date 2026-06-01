import '../entities/academic_entities.dart';

abstract class AcademicRepository {
  Future<TeacherCourseOverview?> createCourse({
    required String name,
    required String nrc,
    required String term,
    required String teacherUid,
  });

  Future<List<TeacherCourseOverview>> getTeacherCourseOverviews(
    String teacherUid,
  );

  Future<List<TeacherCourseOverview>> getStudentCourseOverviews({
    required String studentEmail,
    String? studentUid,
  });

  Future<CsvSyncResult> syncCategoryFromCsv({
    required String courseId,
    required String categoryName,
    required String csvContent,
    required String uploadedBy,
  });

  Future<EvaluationCycleData?> createEvaluationCycle({
    required String courseId,
    required String groupId,
    required String title,
    required String openedBy,
    required List<String> rubrics,
    DateTime? closesAt,
  });

  Future<bool> submitEvaluation({
    required String cycleId,
    required String evaluatorUid,
    required String evaluateeUid,
    required List<int> scores,
    String? comments,
  });

  Future<List<EvaluationCycleData>> getEvaluationCyclesByCourse(
    String courseId,
  );

  Future<List<EvaluationCycleData>> getEvaluationCyclesByGroup(
    String groupId,
  );

  Future<List<PendingEvaluationInfo>> getPendingEvaluationsForStudent({
    required String studentUid,
    required String studentEmail,
  });

  Future<List<PeerEvaluationData>> getSubmittedEvaluations({
    required String cycleId,
    required String evaluatorUid,
  });
}
