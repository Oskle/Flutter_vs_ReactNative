import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme.dart';
import '../../../domain/entities/academic_entities.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/teacher_home_controller.dart';
import 'teacher_course_detail_view.dart';

class TeacherHomeView extends StatelessWidget {
  const TeacherHomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TeacherHomeController>();
    final authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mis cursos'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: authController.logout,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.courses.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.courses.isEmpty) {
          return _EmptyState(
            icon: Icons.menu_book_rounded,
            title: 'No hay cursos todavía',
            description:
                'Crea tu primer curso pulsando el botón + para comenzar a gestionar tus equipos.',
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadCourses,
          color: AppColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: controller.courses.length,
            itemBuilder: (context, index) {
              final course = controller.courses[index];
              return _CourseCard(course: course, controller: controller);
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateCourseDialog(context, controller),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo curso'),
      ),
    );
  }

  void _showCreateCourseDialog(
    BuildContext context,
    TeacherHomeController controller,
  ) {
    final nameCtrl = TextEditingController();
    final nrcCtrl = TextEditingController();
    final termCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (_) {
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
                  Icons.class_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Crear curso',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nrcCtrl,
                decoration: const InputDecoration(
                  labelText: 'NRC',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: termCtrl,
                decoration: const InputDecoration(
                  labelText: 'Periodo',
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final nrc = nrcCtrl.text.trim();
                final term = termCtrl.text.trim();

                if (name.isEmpty || nrc.isEmpty || term.isEmpty) {
                  return;
                }

                Get.back();
                await controller.createCourse(name: name, nrc: nrc, term: term);
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );
  }
}

class _CourseCard extends StatelessWidget {
  final TeacherCourseOverview course;
  final TeacherHomeController controller;

  const _CourseCard({required this.course, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Get.to(() => TeacherCourseDetailView(course: course));
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderSoft),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              course.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                height: 1.2,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'NRC ${course.nrc}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course.term,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoChip(
                            icon: Icons.category_outlined,
                            text: '${course.categoriesCount} categorías',
                          ),
                          _InfoChip(
                            icon: Icons.group_work_outlined,
                            text: '${course.groupsCount} grupos',
                          ),
                          _InfoChip(
                            icon: Icons.people_alt_outlined,
                            text: '${course.activeStudentsCount} estudiantes',
                          ),
                        ],
                      ),
                      if (course.categories.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        const Text(
                          'Categorías y grupos',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...course.categories.map((category) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${category.name} · ${category.groups.length} grupos · ${category.activeStudentsCount} estudiantes',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: 12),
                      Obx(() {
                        final isProcessing =
                            controller.isCsvProcessing(course.id);
                        return Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: isProcessing
                                    ? null
                                    : () => _openCategorySyncDialog(context),
                                icon: isProcessing
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primary,
                                        ),
                                      )
                                    : const Icon(Icons.upload_file_rounded,
                                        size: 18),
                                label: Text(
                                  isProcessing
                                      ? 'Procesando CSV...'
                                      : 'Cargar CSV',
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: isProcessing
                                      ? AppColors.textMuted
                                      : AppColors.primary,
                                  side: BorderSide(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.4),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openCategorySyncDialog(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      final fileName = file.name;
      final bytes = file.bytes;
      if (bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No se pudo leer el archivo seleccionado')),
        );
        return;
      }

      final categoryName = _extractCategoryName(fileName);
      if (categoryName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'El nombre del archivo no tiene el formato esperado (debe empezar con "Categoria")')),
        );
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Confirmar importación',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DialogInfoRow(label: 'Archivo', value: fileName),
              const SizedBox(height: 6),
              _DialogInfoRow(
                  label: 'Categoría detectada', value: categoryName),
              const SizedBox(height: 14),
              const Text(
                '¿Desea continuar con la importación?',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Importar'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final content = utf8.decode(bytes, allowMalformed: true);
        await controller.syncCsvContent(
          courseId: course.id,
          categoryName: categoryName,
          csvContent: content,
          uploadedBy: controller.primaryTeacherOwner,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al abrir el archivo CSV: $e')),
      );
    }
  }

  String? _extractCategoryName(String fileName) {
    var nameWithoutExt = fileName;
    if (nameWithoutExt.toLowerCase().endsWith('.csv')) {
      nameWithoutExt = nameWithoutExt.substring(0, nameWithoutExt.length - 4);
    }

    final normalizedName = _normalizeText(nameWithoutExt.toLowerCase());
    if (!normalizedName.startsWith('categoria')) {
      return null;
    }

    final categoriaIndex = normalizedName.indexOf('categoria');
    final categoriaLength = 'categoria'.length;

    final categoryPart =
        nameWithoutExt.substring(categoriaIndex + categoriaLength);
    if (categoryPart.isEmpty) {
      return null;
    }

    final pieces = categoryPart.split('_');
    final rawCategory = pieces.first.trim();
    if (rawCategory.isEmpty) {
      return null;
    }

    return rawCategory;
  }

  String _normalizeText(String text) {
    return text
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('Á', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ú', 'U')
        .replaceAll('ñ', 'n')
        .replaceAll('Ñ', 'N');
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _DialogInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
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
}
