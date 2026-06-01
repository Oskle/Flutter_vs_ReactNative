import '../../domain/entities/dashboard_stats.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDatasource _remoteDatasource;

  DashboardRepositoryImpl(this._remoteDatasource);

  @override
  Future<List<EvaluationResult>> getResultsForStudent(String studentUid) {
    return _remoteDatasource.getResultsForStudent(studentUid);
  }

  @override
  Future<DashboardConsolidated> getResultsForTeacher(String cycleId) {
    return _remoteDatasource.getResultsForTeacher(cycleId);
  }
}
