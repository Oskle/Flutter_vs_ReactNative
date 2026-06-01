import '../entities/dashboard_stats.dart';
import '../repositories/dashboard_repository.dart';

class GetEvaluationResultsUseCase {
  final DashboardRepository _repository;

  GetEvaluationResultsUseCase(this._repository);

  Future<List<EvaluationResult>> executeForStudent(String studentUid) {
    return _repository.getResultsForStudent(studentUid);
  }

  Future<DashboardConsolidated> executeForTeacher(String cycleId) {
    return _repository.getResultsForTeacher(cycleId);
  }
}
