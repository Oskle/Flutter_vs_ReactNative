import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme.dart';
import '../../../domain/entities/dashboard_stats.dart';
import '../controllers/dashboard_controller.dart';

class DashboardView extends StatelessWidget {
  final String? cycleId;

  const DashboardView({super.key, this.cycleId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadDashboardData(cycleId: cycleId);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Resultados de evaluación'),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.isTeacher) {
          return _buildTeacherDashboard(controller);
        } else {
          return _buildStudentDashboard(controller);
        }
      }),
    );
  }

  Widget _buildStudentDashboard(DashboardController controller) {
    if (controller.studentResults.isEmpty) {
      return _buildEmptyState(
        icon: Icons.bar_chart_rounded,
        title: 'Sin resultados todavía',
        description: 'Cuando tus pares te evalúen, los resultados aparecerán aquí.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: controller.studentResults.length,
      itemBuilder: (context, index) {
        final result = controller.studentResults[index];
        final accent = _getScoreColor(result.averageTotal);

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    border: Border(
                      bottom: BorderSide(
                          color: accent.withValues(alpha: 0.25), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'EVALUACIÓN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              result.cycleId,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          result.averageTotal.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Promedio por criterio',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...result.rubricScores.entries
                          .map((e) => _buildRubricBar(e.key, e.value)),
                      if (result.comments.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Comentarios de tus pares',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...result.comments.map((c) => Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.format_quote_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      c,
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                        fontSize: 13,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeacherDashboard(DashboardController controller) {
    final consolidated = controller.teacherConsolidated.value;
    if (consolidated == null) {
      return _buildEmptyState(
        icon: Icons.analytics_outlined,
        title: 'Sin datos para mostrar',
        description: 'Selecciona una evaluación para ver los resultados.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EVALUACIÓN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      consolidated.cycleTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.7,
          children: [
            _buildKpiCard(
              label: 'Promedio general',
              value: consolidated.groupAverage.toStringAsFixed(2),
              icon: Icons.star_rate_rounded,
              accent: _getScoreColor(consolidated.groupAverage),
            ),
            _buildKpiCard(
              label: 'Estudiantes evaluados',
              value:
                  '${consolidated.evaluatedStudents}/${consolidated.totalStudents}',
              icon: Icons.people_alt_rounded,
              accent: AppColors.primary,
            ),
            _buildKpiCard(
              label: 'Pendientes',
              value: consolidated.pendingStudents.toString(),
              icon: Icons.hourglass_bottom_rounded,
              accent: consolidated.pendingStudents > 0
                  ? AppColors.warning
                  : AppColors.success,
            ),
            _buildKpiCard(
              label: 'Evaluaciones enviadas',
              value: consolidated.totalEvaluationsSubmitted.toString(),
              icon: Icons.check_circle_rounded,
              accent: AppColors.info,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildCoverageCard(consolidated.completionRate),
        if (consolidated.rubricAverages.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSectionTitle('Promedio por criterio'),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: consolidated.rubricAverages.entries
                    .map((entry) => _buildRubricBar(entry.key, entry.value))
                    .toList(),
              ),
            ),
          ),
        ],
        if (consolidated.groupStats.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSectionTitle('Promedio por grupo'),
          const SizedBox(height: 10),
          ...consolidated.groupStats.map(_buildGroupStatsCard),
        ],
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildRankingCard(
                title: 'Top rendimiento',
                icon: Icons.emoji_events_rounded,
                accent: AppColors.success,
                students: consolidated.topStudents,
                emptyText: 'Sin datos',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildRankingCard(
                title: 'Requieren apoyo',
                icon: Icons.support_rounded,
                accent: AppColors.warning,
                students: consolidated.lowStudents,
                emptyText: 'Sin datos',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('Detalle por estudiante'),
        const SizedBox(height: 10),
        Card(
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.surfaceAlt),
              headingTextStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
              dataTextStyle: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              dividerThickness: 0.6,
              columnSpacing: 22,
              columns: const [
                DataColumn(label: Text('Estudiante')),
                DataColumn(label: Text('Grupo')),
                DataColumn(label: Text('Promedio')),
                DataColumn(label: Text('Evaluadores')),
                DataColumn(label: Text('Estado')),
              ],
              rows: consolidated.results
                  .map((res) => DataRow(
                        cells: [
                          DataCell(Text(res.evaluatee.name.isEmpty
                              ? res.evaluatee.uid
                              : res.evaluatee.name)),
                          DataCell(Text(
                              res.groupName.isEmpty ? '-' : res.groupName)),
                          DataCell(Text(
                            res.averageTotal.toStringAsFixed(2),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _getScoreColor(res.averageTotal),
                            ),
                          )),
                          DataCell(Text(res.totalEvaluators.toString())),
                          DataCell(Icon(
                            res.isOutstanding
                                ? Icons.star_rounded
                                : Icons.person_outline_rounded,
                            color: res.isOutstanding
                                ? AppColors.warning
                                : AppColors.textMuted,
                            size: 18,
                          )),
                        ],
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required IconData icon,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: double.infinity,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverageCard(double completionRate) {
    final accent =
        completionRate >= 70 ? AppColors.success : AppColors.warning;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Cobertura de la actividad',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  '${completionRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: accent,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: (completionRate / 100).clamp(0, 1),
                color: accent,
                backgroundColor: AppColors.divider,
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRubricBar(String rubric, double value) {
    final color = _getScoreColor(value);
    final progress = (value / 5).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  rubric,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                value.toStringAsFixed(2),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupStatsCard(GroupStats stats) {
    final color = _getScoreColor(stats.averageScore);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.group_work_rounded,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.groupName.isEmpty ? 'Grupo' : stats.groupName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Evaluados: ${stats.evaluatedStudents}/${stats.totalStudents} · Pendientes: ${stats.pendingStudents}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  stats.averageScore.toStringAsFixed(2),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankingCard({
    required String title,
    required IconData icon,
    required Color accent,
    required List<EvaluationResult> students,
    required String emptyText,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accent, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (students.isEmpty)
              Text(
                emptyText,
                style: const TextStyle(color: AppColors.textMuted),
              )
            else
              ...students.map((student) {
                final color = _getScoreColor(student.averageTotal);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: color.withValues(alpha: 0.18),
                        child: Text(
                          _initials(
                              student.evaluatee.name, student.evaluatee.uid),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          student.evaluatee.name.isEmpty
                              ? student.evaluatee.uid
                              : student.evaluatee.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        student.averageTotal.toStringAsFixed(2),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: color,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 42, color: AppColors.primary),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name, String fallback) {
    if (name.isNotEmpty) {
      final parts = name.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
    }
    if (fallback.isEmpty) return '?';
    return fallback.substring(0, fallback.length >= 2 ? 2 : 1).toUpperCase();
  }

  Color _getScoreColor(double score) {
    if (score >= 4.0) return AppColors.success;
    if (score >= 3.0) return AppColors.warning;
    return AppColors.error;
  }
}
