import '../entities/dashboard_stats.dart';

abstract class DashboardRepository {
  Future<List<EvaluationResult>> getResultsForStudent(String studentUid);
  Future<DashboardConsolidated> getResultsForTeacher(String cycleId);
}
