import 'academic_entities.dart';

class EvaluationResult {
  final String id;
  final String cycleId;
  final StudentOverview evaluatee;
  final String groupId;
  final String groupName;
  final Map<String, double> rubricScores;
  final double averageTotal;
  final List<String> comments;
  final int totalEvaluators;

  EvaluationResult({
    required this.id,
    required this.cycleId,
    required this.evaluatee,
    this.groupId = '',
    this.groupName = '',
    required this.rubricScores,
    required this.averageTotal,
    required this.comments,
    required this.totalEvaluators,
  });

  bool get isOutstanding => averageTotal >= 4.0;
}

class DashboardConsolidated {
  final String cycleTitle;
  final List<EvaluationResult> results;
  final double groupAverage;
  final int totalStudents;
  final int evaluatedStudents;
  final int pendingStudents;
  final int totalEvaluationsSubmitted;
  final Map<String, double> rubricAverages;
  final List<GroupStats> groupStats;
  final List<EvaluationResult> topStudents;
  final List<EvaluationResult> lowStudents;

  DashboardConsolidated({
    required this.cycleTitle,
    required this.results,
    required this.groupAverage,
    this.totalStudents = 0,
    this.evaluatedStudents = 0,
    this.pendingStudents = 0,
    this.totalEvaluationsSubmitted = 0,
    this.rubricAverages = const {},
    this.groupStats = const [],
    this.topStudents = const [],
    this.lowStudents = const [],
  });

  double get completionRate {
    if (totalStudents == 0) return 0;
    return (evaluatedStudents / totalStudents) * 100;
  }
}

class GroupStats {
  final String groupId;
  final String groupName;
  final int totalStudents;
  final int evaluatedStudents;
  final double averageScore;

  GroupStats({
    required this.groupId,
    required this.groupName,
    required this.totalStudents,
    required this.evaluatedStudents,
    required this.averageScore,
  });

  int get pendingStudents => totalStudents - evaluatedStudents;

  double get completionRate {
    if (totalStudents == 0) return 0;
    return (evaluatedStudents / totalStudents) * 100;
  }
}
