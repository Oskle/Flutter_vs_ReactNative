import '../entities/academic_entities.dart';
import '../repositories/academic_repository.dart';

class CreateCourseUseCase {
  final AcademicRepository _repository;

  CreateCourseUseCase(this._repository);

  Future<TeacherCourseOverview?> call({
    required String name,
    required String nrc,
    required String term,
    required String teacherUid,
  }) {
    return _repository.createCourse(
      name: name,
      nrc: nrc,
      term: term,
      teacherUid: teacherUid,
    );
  }
}

class GetTeacherCourseOverviewsUseCase {
  final AcademicRepository _repository;

  GetTeacherCourseOverviewsUseCase(this._repository);

  Future<List<TeacherCourseOverview>> call(String teacherUid) {
    return _repository.getTeacherCourseOverviews(teacherUid);
  }
}

class GetStudentCourseOverviewsUseCase {
  final AcademicRepository _repository;

  GetStudentCourseOverviewsUseCase(this._repository);

  Future<List<TeacherCourseOverview>> call({
    required String studentEmail,
    String? studentUid,
  }) {
    return _repository.getStudentCourseOverviews(
      studentEmail: studentEmail,
      studentUid: studentUid,
    );
  }
}

class SyncCategoryFromCsvUseCase {
  final AcademicRepository _repository;

  SyncCategoryFromCsvUseCase(this._repository);

  Future<CsvSyncResult> call({
    required String courseId,
    required String categoryName,
    required String csvContent,
    required String uploadedBy,
  }) {
    return _repository.syncCategoryFromCsv(
      courseId: courseId,
      categoryName: categoryName,
      csvContent: csvContent,
      uploadedBy: uploadedBy,
    );
  }
}

class CreateEvaluationCycleUseCase {
  final AcademicRepository _repository;

  CreateEvaluationCycleUseCase(this._repository);

  Future<EvaluationCycleData?> call({
    required String courseId,
    required String groupId,
    required String title,
    required String openedBy,
    required List<String> rubrics,
    DateTime? closesAt,
  }) {
    return _repository.createEvaluationCycle(
      courseId: courseId,
      groupId: groupId,
      title: title,
      openedBy: openedBy,
      rubrics: rubrics,
      closesAt: closesAt,
    );
  }
}

class SubmitEvaluationUseCase {
  final AcademicRepository _repository;

  SubmitEvaluationUseCase(this._repository);

  Future<bool> call({
    required String cycleId,
    required String evaluatorUid,
    required String evaluateeUid,
    required List<int> scores,
    String? comments,
  }) {
    return _repository.submitEvaluation(
      cycleId: cycleId,
      evaluatorUid: evaluatorUid,
      evaluateeUid: evaluateeUid,
      scores: scores,
      comments: comments,
    );
  }
}

class GetEvaluationCyclesByCourseUseCase {
  final AcademicRepository _repository;

  GetEvaluationCyclesByCourseUseCase(this._repository);

  Future<List<EvaluationCycleData>> call(String courseId) {
    return _repository.getEvaluationCyclesByCourse(courseId);
  }
}

class GetEvaluationCyclesByGroupUseCase {
  final AcademicRepository _repository;

  GetEvaluationCyclesByGroupUseCase(this._repository);

  Future<List<EvaluationCycleData>> call(String groupId) {
    return _repository.getEvaluationCyclesByGroup(groupId);
  }
}

class GetPendingEvaluationsForStudentUseCase {
  final AcademicRepository _repository;

  GetPendingEvaluationsForStudentUseCase(this._repository);

  Future<List<PendingEvaluationInfo>> call({
    required String studentUid,
    required String studentEmail,
  }) {
    return _repository.getPendingEvaluationsForStudent(
      studentUid: studentUid,
      studentEmail: studentEmail,
    );
  }
}

class GetSubmittedEvaluationsUseCase {
  final AcademicRepository _repository;

  GetSubmittedEvaluationsUseCase(this._repository);

  Future<List<PeerEvaluationData>> call({
    required String cycleId,
    required String evaluatorUid,
  }) {
    return _repository.getSubmittedEvaluations(
      cycleId: cycleId,
      evaluatorUid: evaluatorUid,
    );
  }
}
