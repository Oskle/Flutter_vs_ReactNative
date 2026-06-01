import '../../domain/repositories/academic_repository.dart';
import '../../domain/entities/academic_entities.dart';
import '../datasources/academic_remote_datasource.dart';

class AcademicRepositoryImpl implements AcademicRepository {
  final AcademicRemoteDatasource _remoteDatasource;

  AcademicRepositoryImpl(this._remoteDatasource);

  @override
  Future<TeacherCourseOverview?> createCourse({
    required String name,
    required String nrc,
    required String term,
    required String teacherUid,
  }) {
    return _remoteDatasource.createCourse(
      name: name,
      nrc: nrc,
      term: term,
      teacherUid: teacherUid,
    );
  }

  @override
  Future<List<TeacherCourseOverview>> getTeacherCourseOverviews(
    String teacherUid,
  ) {
    return _remoteDatasource.getTeacherCourseOverviews(teacherUid);
  }

  @override
  Future<List<TeacherCourseOverview>> getStudentCourseOverviews({
    required String studentEmail,
    String? studentUid,
  }) {
    return _remoteDatasource.getStudentCourseOverviews(
      studentEmail: studentEmail,
      studentUid: studentUid,
    );
  }

  @override
  Future<CsvSyncResult> syncCategoryFromCsv({
    required String courseId,
    required String categoryName,
    required String csvContent,
    required String uploadedBy,
  }) {
    return _remoteDatasource.syncCategoryFromCsv(
      courseId: courseId,
      categoryName: categoryName,
      csvContent: csvContent,
      uploadedBy: uploadedBy,
    );
  }

  @override
  Future<EvaluationCycleData?> createEvaluationCycle({
    required String courseId,
    required String groupId,
    required String title,
    required String openedBy,
    required List<String> rubrics,
    DateTime? closesAt,
  }) {
    return _remoteDatasource.createEvaluationCycle(
      courseId: courseId,
      groupId: groupId,
      title: title,
      openedBy: openedBy,
      rubrics: rubrics,
      closesAt: closesAt,
    );
  }

  @override
  Future<bool> submitEvaluation({
    required String cycleId,
    required String evaluatorUid,
    required String evaluateeUid,
    required List<int> scores,
    String? comments,
  }) {
    return _remoteDatasource.submitEvaluation(
      cycleId: cycleId,
      evaluatorUid: evaluatorUid,
      evaluateeUid: evaluateeUid,
      scores: scores,
      comments: comments,
    );
  }

  @override
  Future<List<EvaluationCycleData>> getEvaluationCyclesByCourse(
    String courseId,
  ) {
    return _remoteDatasource.getEvaluationCyclesByCourse(courseId);
  }

  @override
  Future<List<EvaluationCycleData>> getEvaluationCyclesByGroup(
    String groupId,
  ) {
    return _remoteDatasource.getEvaluationCyclesByGroup(groupId);
  }

  @override
  Future<List<PendingEvaluationInfo>> getPendingEvaluationsForStudent({
    required String studentUid,
    required String studentEmail,
  }) {
    return _remoteDatasource.getPendingEvaluationsForStudent(
      studentUid: studentUid,
      studentEmail: studentEmail,
    );
  }

  @override
  Future<List<PeerEvaluationData>> getSubmittedEvaluations({
    required String cycleId,
    required String evaluatorUid,
  }) {
    return _remoteDatasource.getSubmittedEvaluations(
      cycleId: cycleId,
      evaluatorUid: evaluatorUid,
    );
  }
}
