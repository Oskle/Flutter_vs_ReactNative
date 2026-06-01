import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:coeval/presentation/teacher_view/controllers/teacher_home_controller.dart';
import 'package:coeval/domain/entities/academic_entities.dart';

class MockTeacherHomeController extends GetxController
    with Mock
    implements TeacherHomeController {
  @override
  final isLoading = false.obs;

  @override
  final courses = <TeacherCourseOverview>[].obs;

  @override
  final processingCsvCourseIds = <String>[].obs;

  @override
  bool isCsvProcessing(String courseId) => processingCsvCourseIds.contains(courseId);
}