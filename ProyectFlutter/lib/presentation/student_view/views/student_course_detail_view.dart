import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme.dart';
import '../../../domain/entities/academic_entities.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/student_home_controller.dart';
import 'evaluate_peers_view.dart';

class StudentCourseDetailView extends StatefulWidget {
  final TeacherCourseOverview course;

  const StudentCourseDetailView({super.key, required this.course});

  @override
  State<StudentCourseDetailView> createState() =>
      _StudentCourseDetailViewState();
}

class _StudentCourseDetailViewState extends State<StudentCourseDetailView> {
  final StudentHomeController _controller = Get.find<StudentHomeController>();
  final AuthController _authController = Get.find<AuthController>();

  final _pendingEvaluations = <PendingEvaluationInfo>[].obs;
  final _isLoading = false.obs;

  @override
  void initState() {
    super.initState();
    _loadPendingEvaluations();
  }

  Future<void> _loadPendingEvaluations() async {
    _isLoading.value = true;
    try {
      final allPending = await _controller.getPendingEvaluations();
      final forThisCourse = allPending
          .where((p) => p.cycle.courseId == widget.course.id)
          .toList();
      _pendingEvaluations.assignAll(forThisCourse);
    } finally {
      _isLoading.value = false;
    }
  }

  String get _currentEmail =>
      _authController.currentUser.value?.email.trim().toLowerCase() ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.course.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'NRC ${widget.course.nrc} · ${widget.course.term}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadPendingEvaluations,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPendingEvaluationsSection(),
              const SizedBox(height: 16),
              _buildMyGroupsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: AppColors.textPrimary, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }

  Widget _buildPendingEvaluationsSection() {
    return Obx(() {
      if (_isLoading.value) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      }

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(
                icon: Icons.assignment_outlined,
                title: 'Evaluaciones pendientes',
                trailing: _pendingEvaluations.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_pendingEvaluations.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 14),
              if (_pendingEvaluations.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.successSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 40,
                        color: AppColors.success,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No tienes evaluaciones pendientes',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._pendingEvaluations.map(_buildPendingEvaluationCard),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildPendingEvaluationCard(PendingEvaluationInfo pending) {
    final pendingCount = pending.pendingCount;
    final totalPeers = pending.peersToEvaluate.length;
    final completedCount = totalPeers - pendingCount;
    final isPending = pendingCount > 0;
    final accent = isPending ? AppColors.primary : AppColors.success;
    final accentSoft =
        isPending ? AppColors.primarySoft : AppColors.successSoft;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isPending
              ? () async {
                  await Get.to(() => EvaluatePeersView(pendingInfo: pending));
                  _loadPendingEvaluations();
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pending.cycle.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accentSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isPending
                            ? '$pendingCount pendiente${pendingCount > 1 ? 's' : ''}'
                            : 'Completada',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${pending.categoryName} · ${pending.group.name}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: totalPeers > 0 ? completedCount / totalPeers : 0,
                    minHeight: 6,
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation(accent),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$completedCount de $totalPeers compañeros evaluados',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                    if (pending.cycle.closesAt != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 11,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _formatDate(pending.cycle.closesAt!),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyGroupsSection() {
    final myCategories = widget.course.categories.where((cat) {
      return cat.groups.any((group) {
        return group.students
            .any((s) => s.email.trim().toLowerCase() == _currentEmail);
      });
    }).toList();

    if (myCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              icon: Icons.group_outlined,
              title: 'Mis grupos',
            ),
            const SizedBox(height: 14),
            ...myCategories.map((category) {
              final myGroups = category.groups.where((group) {
                return group.students
                    .any((s) => s.email.trim().toLowerCase() == _currentEmail);
              }).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...myGroups.map((group) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.group_work_outlined,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${group.name} (${group.code})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...group.students.map((student) {
                            final isMe = student.email.trim().toLowerCase() ==
                                _currentEmail;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: isMe
                                        ? AppColors.primarySoft
                                        : AppColors.divider,
                                    child: Text(
                                      _initials(student.name, student.email),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: isMe
                                            ? AppColors.primary
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '${student.name.isEmpty ? student.email : student.name}${isMe ? ' (Tú)' : ''}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isMe
                                            ? AppColors.primary
                                            : AppColors.textSecondary,
                                        fontWeight: isMe
                                            ? FontWeight.w700
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 4),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  String _initials(String name, String email) {
    if (name.isNotEmpty) {
      final parts = name.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
    }
    return email.substring(0, email.length >= 2 ? 2 : 1).toUpperCase();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
