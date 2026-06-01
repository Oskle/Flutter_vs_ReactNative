import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:coeval/presentation/student_view/controllers/student_home_controller.dart';
import 'package:coeval/domain/entities/academic_entities.dart';

class MockStudentHomeController extends GetxController
    with Mock
    implements StudentHomeController {
  @override
  final isLoading = false.obs;

  @override
  final courses = <TeacherCourseOverview>[].obs;

  @override
  final pendingEvaluations = <PendingEvaluationInfo>[].obs;

  @override
  int get totalPendingCount {
    int total = 0;
    for (final pending in pendingEvaluations) {
      total += pending.pendingCount;
    }
    return total;
  }
}
