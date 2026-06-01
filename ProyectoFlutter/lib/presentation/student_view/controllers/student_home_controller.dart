import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_cache.dart';
import '../../../domain/entities/academic_entities.dart';
import '../../../domain/usecases/academic_use_cases.dart';
import '../../auth/controllers/auth_controller.dart';

class StudentHomeController extends GetxController {
  final AuthController _authController;
  final GetStudentCourseOverviewsUseCase _getStudentCourseOverviewsUseCase;
  final GetPendingEvaluationsForStudentUseCase _getPendingEvaluationsUseCase;
  final SubmitEvaluationUseCase _submitEvaluationUseCase;

  StudentHomeController({
    required AuthController authController,
    required GetStudentCourseOverviewsUseCase getStudentCourseOverviewsUseCase,
    required GetPendingEvaluationsForStudentUseCase getPendingEvaluationsUseCase,
    required SubmitEvaluationUseCase submitEvaluationUseCase,
  }) : _authController = authController,
       _getStudentCourseOverviewsUseCase = getStudentCourseOverviewsUseCase,
       _getPendingEvaluationsUseCase = getPendingEvaluationsUseCase,
       _submitEvaluationUseCase = submitEvaluationUseCase;

  final isLoading = false.obs;
  final courses = <TeacherCourseOverview>[].obs;
  final pendingEvaluations = <PendingEvaluationInfo>[].obs;
  Worker? _authWorker;

  String get _studentEmail =>
      _authController.currentUser.value?.email.trim().toLowerCase() ?? '';
  
  String get _studentUid =>
      (_authController.currentUser.value?.uid ?? 
       _authController.currentUser.value?.id ?? '').trim();

    String get _studentCacheKey =>
      _studentUid.isNotEmpty ? _studentUid : _studentEmail;

  @override
  void onInit() {
    super.onInit();

    _authWorker = everAll([
      _authController.isLoggedIn,
      _authController.currentUser,
    ], (_) async {
      if (_authController.isLoggedIn.value &&
          _authController.currentUser.value != null) {
        await loadCourses();
        await loadPendingEvaluations();
      } else {
        courses.clear();
        pendingEvaluations.clear();
      }
    });

    loadCourses();
    loadPendingEvaluations();
  }

  @override
  void onClose() {
    _authWorker?.dispose();
    super.onClose();
  }

  Future<void> loadCourses() async {
    final user = _authController.currentUser.value;
    if (user == null) {
      courses.clear();
      return;
    }

    final email = user.email.trim().toLowerCase();
    final uid = (user.uid ?? user.id ?? '').trim();

    if (email.isEmpty && uid.isEmpty) {
      courses.clear();
      return;
    }

    final cacheKey = uid.isNotEmpty ? uid : email;

    isLoading.value = true;
    try {
      final cached = await AppCache.instance.getStudentCourses(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        courses.assignAll(cached);
      }

      final result = await _getStudentCourseOverviewsUseCase(
        studentEmail: email,
        studentUid: uid.isEmpty ? null : uid,
      );
      courses.assignAll(result);
      await AppCache.instance.setStudentCourses(cacheKey, result);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadPendingEvaluations() async {
    if (_studentEmail.isEmpty && _studentUid.isEmpty) {
      pendingEvaluations.clear();
      return;
    }

    try {
      if (_studentCacheKey.isNotEmpty) {
        final cached = await AppCache.instance.getPendingEvaluations(
          _studentCacheKey,
        );
        if (cached != null && cached.isNotEmpty) {
          pendingEvaluations.assignAll(cached);
        }
      }

      final result = await _getPendingEvaluationsUseCase(
        studentEmail: _studentEmail,
        studentUid: _studentUid,
      );
      pendingEvaluations.assignAll(result);
      if (_studentCacheKey.isNotEmpty) {
        await AppCache.instance.setPendingEvaluations(
          _studentCacheKey,
          result,
        );
      }
    } catch (e) {
      _showError('Error al cargar evaluaciones pendientes');
    }
  }

  Future<List<PendingEvaluationInfo>> getPendingEvaluations() async {
    if (_studentEmail.isEmpty && _studentUid.isEmpty) {
      return [];
    }

    try {
      if (_studentCacheKey.isNotEmpty) {
        final cached = await AppCache.instance.getPendingEvaluations(
          _studentCacheKey,
        );
        if (cached != null && cached.isNotEmpty) {
          pendingEvaluations.assignAll(cached);
        }
      }

      return await _getPendingEvaluationsUseCase(
        studentEmail: _studentEmail,
        studentUid: _studentUid,
      );
    } catch (e) {
      _showError('Error al cargar evaluaciones pendientes');
      return [];
    }
  }

  Future<bool> submitEvaluation({
    required String cycleId,
    required String evaluateeUid,
    required List<int> scores,
    String? comments,
  }) async {
    final evaluatorUid = _studentUid.isNotEmpty 
        ? _studentUid 
        : 'email:$_studentEmail';

    try {
      final success = await _submitEvaluationUseCase(
        cycleId: cycleId,
        evaluatorUid: evaluatorUid,
        evaluateeUid: evaluateeUid,
        scores: scores,
        comments: comments,
      );

      if (!success) {
        _showError('No se pudo enviar la evaluación');
      } else {
        if (_studentCacheKey.isNotEmpty) {
          await AppCache.instance.invalidatePendingEvaluations(
            _studentCacheKey,
          );
        }
        await AppCache.instance.invalidateTeacherDashboardCycle(cycleId);
        if (_studentUid.isNotEmpty) {
          await AppCache.instance.invalidateStudentDashboard(_studentUid);
        }
        await loadPendingEvaluations();
      }

      return success;
    } catch (e) {
      _showError('Error al enviar evaluación: $e');
      return false;
    }
  }

  int get totalPendingCount {
    int total = 0;
    for (final pending in pendingEvaluations) {
      total += pending.pendingCount;
    }
    return total;
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade100,
      colorText: Colors.red.shade900,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 3),
      icon: Icon(Icons.error_outline, color: Colors.red.shade900),
    );
  }
}
