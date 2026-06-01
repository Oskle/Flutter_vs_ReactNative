import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme.dart';
import '../../../domain/entities/academic_entities.dart';
import '../../dashboard/views/dashboard_view.dart';
import '../controllers/teacher_home_controller.dart';

class TeacherCourseDetailView extends StatefulWidget {
  final TeacherCourseOverview course;

  const TeacherCourseDetailView({super.key, required this.course});

  @override
  State<TeacherCourseDetailView> createState() =>
      _TeacherCourseDetailViewState();
}

class _TeacherCourseDetailViewState extends State<TeacherCourseDetailView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TeacherHomeController _controller = Get.find<TeacherHomeController>();

  final _evaluationCycles = <EvaluationCycleData>[].obs;
  final _isLoadingCycles = false.obs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEvaluationCycles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvaluationCycles() async {
    _isLoadingCycles.value = true;
    try {
      final cycles =
          await _controller.getEvaluationCyclesByCourse(widget.course.id);
      _evaluationCycles.assignAll(cycles);
    } finally {
      _isLoadingCycles.value = false;
    }
  }

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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppColors.appBar,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Grupos'),
                Tab(text: 'Evaluaciones'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGroupsTab(),
          _buildEvaluationsTab(),
        ],
      ),
    );
  }

  Widget _buildGroupsTab() {
    if (widget.course.categories.isEmpty) {
      return _buildEmptyState(
        icon: Icons.category_outlined,
        title: 'Sin categorías todavía',
        description:
            'Carga un CSV en este curso para comenzar a organizar grupos.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.course.categories.length,
      itemBuilder: (context, index) {
        final category = widget.course.categories[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.category_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                title: Text(
                  category.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '${category.groups.length} grupos · ${category.activeStudentsCount} estudiantes',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                children: [
                  if (category.groups.isEmpty)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Sin grupos en esta categoría',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    )
                  else
                    ...category.groups.map((group) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                                dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              childrenPadding:
                                  const EdgeInsets.fromLTRB(14, 0, 14, 8),
                              title: Text(
                                group.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                '${group.code} · ${group.activeStudentsCount} estudiantes',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              children: [
                                if (group.students.isEmpty)
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding: EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        'Sin estudiantes activos',
                                        style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  ...group.students.map((student) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 2),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor:
                                                AppColors.primarySoft,
                                            child: Text(
                                              _initials(
                                                  student.name, student.email),
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  student.name.isEmpty
                                                      ? student.email
                                                      : student.name,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w500,
                                                    color:
                                                        AppColors.textPrimary,
                                                  ),
                                                ),
                                                Text(
                                                  '${student.email}${student.studentId.isNotEmpty ? ' · ${student.studentId}' : ''}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.textMuted,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEvaluationsTab() {
    return Stack(
      children: [
        Obx(() {
          if (_isLoadingCycles.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (widget.course.categories.isEmpty) {
            return _buildEmptyState(
              icon: Icons.assignment_outlined,
              title: 'Sin categorías para evaluar',
              description:
                  'Crea categorías y grupos primero para poder crear evaluaciones.',
            );
          }

          if (_evaluationCycles.isEmpty) {
            return _buildEmptyState(
              icon: Icons.assignment_outlined,
              title: 'No hay evaluaciones todavía',
              description:
                  'Pulsa el botón + para crear una nueva evaluación entre pares.',
            );
          }

          final cyclesByGroup = <String, List<EvaluationCycleData>>{};
          for (final cycle in _evaluationCycles) {
            cyclesByGroup.putIfAbsent(cycle.groupId, () => []).add(cycle);
          }

          return RefreshIndicator(
            onRefresh: _loadEvaluationCycles,
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: widget.course.categories.length,
              itemBuilder: (context, catIndex) {
                final category = widget.course.categories[catIndex];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 0, 10),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            category.name.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              letterSpacing: 0.6,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...category.groups.map((group) {
                      final groupCycles = cyclesByGroup[group.id] ?? [];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            group.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${group.code} · ${group.activeStudentsCount} estudiantes',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceAlt,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${groupCycles.length} eval.',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (groupCycles.isEmpty) ...[
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Sin evaluaciones para este grupo',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(height: 12),
                                  ...groupCycles.map(_buildCycleItem),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 6),
                  ],
                );
              },
            ),
          );
        }),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _showCreateEvaluationDialog(context),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Nueva evaluación'),
          ),
        ),
      ],
    );
  }

  Widget _buildCycleItem(EvaluationCycleData cycle) {
    final isOpen = cycle.isOpen;
    final statusColor = isOpen ? AppColors.success : AppColors.textMuted;
    final statusBg =
        isOpen ? AppColors.successSoft : AppColors.surfaceAlt;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => Get.to(() => DashboardView(cycleId: cycle.id)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        cycle.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isOpen ? 'Abierta' : 'Cerrada',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.analytics_outlined,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
                if (cycle.rubrics.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: cycle.rubrics.map((rubric) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          rubric,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                if (cycle.closesAt != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        'Cierra: ${_formatDate(cycle.closesAt!)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
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
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
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

  void _showCreateEvaluationDialog(BuildContext context) {
    final groupsWithCategory = <({GroupOverview group, String categoryName})>[];
    for (final cat in widget.course.categories) {
      for (final group in cat.groups) {
        groupsWithCategory.add((group: group, categoryName: cat.name));
      }
    }

    if (groupsWithCategory.isEmpty) {
      Get.snackbar(
        'Error',
        'Debes crear categorías y grupos antes de crear evaluaciones',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    final titleCtrl = TextEditingController();
    final rubricCtrl = TextEditingController();
    final selectedGroupEntry = Rx<({GroupOverview group, String categoryName})?>(
      groupsWithCategory.first,
    );
    final selectedDate = Rxn<DateTime>();
    final rubrics = <String>[].obs;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.assignment_add,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Nueva evaluación',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Título de la evaluación',
                      hintText: 'Ej: Corte 1 - Sprint 2',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _formLabel('Grupo'),
                  const SizedBox(height: 8),
                  Obx(() {
                    return DropdownButtonFormField<int>(
                      initialValue:
                          groupsWithCategory.indexOf(selectedGroupEntry.value!),
                      isExpanded: true,
                      items: groupsWithCategory.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        return DropdownMenuItem(
                          value: idx,
                          child: Text(
                            '${item.categoryName} > ${item.group.name}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (idx) {
                        if (idx != null) {
                          selectedGroupEntry.value = groupsWithCategory[idx];
                        }
                      },
                    );
                  }),
                  const SizedBox(height: 16),
                  _formLabel('Rúbrica (criterios a evaluar)'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: rubricCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Ej: Comunicación',
                          ),
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              rubrics.add(value.trim());
                              rubricCtrl.clear();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            final value = rubricCtrl.text.trim();
                            if (value.isNotEmpty) {
                              rubrics.add(value);
                              rubricCtrl.clear();
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(
                              Icons.add_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Obx(() {
                    if (rubrics.isEmpty) {
                      return const Text(
                        'Agrega al menos un criterio',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      );
                    }
                    return Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: rubrics.asMap().entries.map((entry) {
                        return Chip(
                          label: Text(
                            entry.value,
                            style: const TextStyle(fontSize: 12),
                          ),
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () {
                            rubrics.removeAt(entry.key);
                          },
                          backgroundColor: AppColors.primarySoft,
                          labelStyle: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          deleteIconColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide.none,
                          ),
                        );
                      }).toList(),
                    );
                  }),
                  const SizedBox(height: 16),
                  _formLabel('Fecha de cierre (opcional)'),
                  const SizedBox(height: 8),
                  Obx(() {
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: dialogContext,
                          initialDate:
                              DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: dialogContext,
                            initialTime: const TimeOfDay(hour: 23, minute: 59),
                          );
                          if (time != null) {
                            selectedDate.value = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          }
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.divider),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                selectedDate.value != null
                                    ? _formatDate(selectedDate.value!)
                                    : 'Seleccionar fecha',
                                style: TextStyle(
                                  color: selectedDate.value != null
                                      ? AppColors.textPrimary
                                      : AppColors.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            if (selectedDate.value != null)
                              InkWell(
                                onTap: () => selectedDate.value = null,
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: AppColors.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            Obx(() {
              final canCreate = rubrics.isNotEmpty;
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: canCreate
                      ? AppColors.primary
                      : AppColors.divider,
                  disabledBackgroundColor: AppColors.divider,
                  foregroundColor: Colors.white,
                ),
                onPressed: canCreate
                    ? () async {
                        final title = titleCtrl.text.trim();
                        final entry = selectedGroupEntry.value;

                        if (title.isEmpty || entry == null) {
                          return;
                        }

                        Navigator.of(dialogContext).pop();
                        await _controller.createEvaluationCycle(
                          courseId: widget.course.id,
                          groupId: entry.group.id,
                          title: title,
                          rubrics: rubrics.toList(),
                          closesAt: selectedDate.value,
                        );
                        await _loadEvaluationCycles();
                      }
                    : null,
                child: const Text('Crear'),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _formLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}
