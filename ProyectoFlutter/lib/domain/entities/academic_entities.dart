class TeacherCourseOverview {
  final String id;
  final String name;
  final String nrc;
  final String term;
  final int categoriesCount;
  final int groupsCount;
  final int activeStudentsCount;
  final List<CategoryOverview> categories;

  TeacherCourseOverview({
    required this.id,
    required this.name,
    required this.nrc,
    required this.term,
    required this.categoriesCount,
    required this.groupsCount,
    required this.activeStudentsCount,
    this.categories = const [],
  });
}

class CategoryOverview {
  final String id;
  final String name;
  final int activeStudentsCount;
  final List<GroupOverview> groups;

  CategoryOverview({
    required this.id,
    required this.name,
    required this.activeStudentsCount,
    required this.groups,
  });
}

class GroupOverview {
  final String id;
  final String code;
  final String name;
  final int activeStudentsCount;
  final List<StudentOverview> students;

  GroupOverview({
    required this.id,
    required this.code,
    required this.name,
    required this.activeStudentsCount,
    this.students = const [],
  });
}

class StudentOverview {
  final String uid;
  final String name;
  final String email;
  final String studentId;

  StudentOverview({
    required this.uid,
    required this.name,
    required this.email,
    required this.studentId,
  });
}

class CsvSyncResult {
  final int createdGroups;
  final int activatedEnrollments;
  final int closedEnrollments;
  final int totalRows;

  CsvSyncResult({
    required this.createdGroups,
    required this.activatedEnrollments,
    required this.closedEnrollments,
    required this.totalRows,
  });
}

enum EvaluationScope {
  ownGroup,
  allGroups;

  static EvaluationScope fromString(String? value) {
    if (value == 'all_groups') return EvaluationScope.allGroups;
    return EvaluationScope.ownGroup;
  }

  String get apiValue =>
      this == EvaluationScope.allGroups ? 'all_groups' : 'own_group';

  String get label =>
      this == EvaluationScope.allGroups ? 'Todos los grupos' : 'Compañeros de grupo';

  String get description => this == EvaluationScope.allGroups
      ? 'Cada estudiante evalúa a integrantes de todos los demás grupos de la categoría'
      : 'Cada estudiante evalúa solo a los integrantes de su propio grupo';
}

class EvaluationCycleData {
  final String id;
  final String courseId;
  final String groupId;
  final String categoryId;
  final String title;
  final String status;
  final String openedBy;
  final DateTime openedAt;
  final DateTime? closesAt;
  final List<String> rubrics;
  final EvaluationScope evaluationScope;

  EvaluationCycleData({
    required this.id,
    required this.courseId,
    this.groupId = '',
    this.categoryId = '',
    required this.title,
    required this.status,
    required this.openedBy,
    required this.openedAt,
    this.closesAt,
    this.rubrics = const [],
    this.evaluationScope = EvaluationScope.ownGroup,
  });

  bool get isOpen => status.toLowerCase() == 'open';
  bool get isClosed => status.toLowerCase() == 'closed';
}

class PeerEvaluationData {
  final String id;
  final String cycleId;
  final String evaluatorUid;
  final String evaluateeUid;
  final List<int> scores;
  final String? comments;
  final DateTime createdAt;
  final DateTime? updatedAt;

  PeerEvaluationData({
    required this.id,
    required this.cycleId,
    required this.evaluatorUid,
    required this.evaluateeUid,
    required this.scores,
    this.comments,
    required this.createdAt,
    this.updatedAt,
  });

  double get averageScore {
    if (scores.isEmpty) return 0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }
}

class PendingEvaluationInfo {
  final EvaluationCycleData cycle;
  final GroupOverview group;
  final String categoryName;
  final List<StudentOverview> peersToEvaluate;
  final List<String> alreadyEvaluatedUids;

  PendingEvaluationInfo({
    required this.cycle,
    required this.group,
    required this.categoryName,
    required this.peersToEvaluate,
    required this.alreadyEvaluatedUids,
  });

  int get pendingCount {
    final evaluated = alreadyEvaluatedUids.toSet();
    final completedPeers = peersToEvaluate
        .where((peer) => evaluated.contains(peer.uid))
        .length;
    return peersToEvaluate.length - completedPeers;
  }
  bool get isComplete => pendingCount <= 0;
}
