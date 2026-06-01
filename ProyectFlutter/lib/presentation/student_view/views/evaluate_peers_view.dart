import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme.dart';
import '../../../domain/entities/academic_entities.dart';
import '../controllers/student_home_controller.dart';

class EvaluatePeersView extends StatefulWidget {
  final PendingEvaluationInfo pendingInfo;

  const EvaluatePeersView({super.key, required this.pendingInfo});

  @override
  State<EvaluatePeersView> createState() => _EvaluatePeersViewState();
}

class _EvaluatePeersViewState extends State<EvaluatePeersView> {
  final StudentHomeController _controller = Get.find<StudentHomeController>();

  final _rubricScores = <String, Map<int, int>>{}.obs;
  final _comments = <String, String>{}.obs;
  final _isSubmitting = false.obs;
  final _submittedUids = <String>{}.obs;

  List<String> get rubrics => widget.pendingInfo.cycle.rubrics;

  @override
  void initState() {
    super.initState();
    _submittedUids.addAll(widget.pendingInfo.alreadyEvaluatedUids);

    for (final peer in widget.pendingInfo.peersToEvaluate) {
      _rubricScores[peer.uid] = {};
      for (int i = 0; i < rubrics.length; i++) {
        _rubricScores[peer.uid]![i] = 3;
      }
      _comments[peer.uid] = '';
    }
  }

  List<StudentOverview> get _pendingPeers {
    return widget.pendingInfo.peersToEvaluate
        .where((p) => !_submittedUids.contains(p.uid))
        .toList();
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
              widget.pendingInfo.cycle.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.pendingInfo.group.name,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: Obx(() {
        final pendingPeers = _pendingPeers;
        final total = widget.pendingInfo.peersToEvaluate.length;
        final completed = total - pendingPeers.length;

        if (pendingPeers.isEmpty) {
          return _buildAllDoneState();
        }

        return Column(
          children: [
            _buildProgressBanner(completed, total),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: pendingPeers.length,
                itemBuilder: (context, index) {
                  final peer = pendingPeers[index];
                  return _buildPeerEvaluationCard(peer);
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildProgressBanner(int completed, int total) {
    final progress = total > 0 ? completed / total : 0.0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              const Text(
                'Progreso',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '$completed / $total',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.divider,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllDoneState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 56,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Has evaluado a todos tus compañeros',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Gracias por completar la evaluación.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeerEvaluationCard(StudentOverview peer) {
    return Obx(() {
      final isSubmitting = _isSubmitting.value;
      final peerScores = _rubricScores[peer.uid] ?? {};

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primarySoft,
                    child: Text(
                      _getInitials(peer.name, peer.email),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          peer.name.isEmpty ? peer.email : peer.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (peer.name.isNotEmpty)
                          Text(
                            peer.email,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildAverageScoreBadge(peerScores),
                ],
              ),
              const SizedBox(height: 18),
              if (rubrics.isEmpty)
                _buildSingleScoreSlider(peer, isSubmitting)
              else
                ...rubrics.asMap().entries.map((entry) {
                  return _buildRubricSlider(
                    peer: peer,
                    rubricIndex: entry.key,
                    rubricName: entry.value,
                    currentScore: peerScores[entry.key] ?? 3,
                    isSubmitting: isSubmitting,
                  );
                }),
              const SizedBox(height: 4),
              const Text(
                'Comentarios (opcional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                enabled: !isSubmitting,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Escribe un comentario sobre el desempeño...',
                ),
                onChanged: (value) {
                  _comments[peer.uid] = value;
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      isSubmitting ? null : () => _submitEvaluation(peer),
                  style: ElevatedButton.styleFrom(
                    disabledBackgroundColor: AppColors.divider,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    isSubmitting ? 'Enviando...' : 'Enviar evaluación',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildAverageScoreBadge(Map<int, int> scores) {
    if (scores.isEmpty) return const SizedBox.shrink();

    final avg = scores.values.reduce((a, b) => a + b) / scores.length;
    final color = _getScoreColor(avg);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        'Prom: ${avg.toStringAsFixed(1)}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSingleScoreSlider(StudentOverview peer, bool isSubmitting) {
    final scores = _rubricScores[peer.uid] ?? {};
    final score = (scores[0] ?? 3).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Puntuación general',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        _buildScoreSlider(
          score: score,
          onChanged: isSubmitting
              ? null
              : (value) {
                  final map = Map<int, int>.from(_rubricScores[peer.uid] ?? {});
                  map[0] = value.round();
                  _rubricScores[peer.uid] = map;
                },
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildRubricSlider({
    required StudentOverview peer,
    required int rubricIndex,
    required String rubricName,
    required int currentScore,
    required bool isSubmitting,
  }) {
    final scoreColor = _getScoreColor(currentScore.toDouble());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '${rubricIndex + 1}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                rubricName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$currentScore',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: scoreColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        _buildScoreSlider(
          score: currentScore.toDouble(),
          onChanged: isSubmitting
              ? null
              : (value) {
                  final map = Map<int, int>.from(_rubricScores[peer.uid] ?? {});
                  map[rubricIndex] = value.round();
                  _rubricScores[peer.uid] = map;
                },
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildScoreSlider({
    required double score,
    required void Function(double)? onChanged,
  }) {
    return Row(
      children: [
        const Text(
          '1',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.divider,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.18),
              valueIndicatorColor: AppColors.primary,
              activeTickMarkColor: Colors.white,
              inactiveTickMarkColor: AppColors.textMuted,
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              valueIndicatorTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Slider(
              value: score,
              min: 1,
              max: 5,
              divisions: 4,
              label: score.toStringAsFixed(0),
              onChanged: onChanged,
            ),
          ),
        ),
        const Text(
          '5',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Future<void> _submitEvaluation(StudentOverview peer) async {
    _isSubmitting.value = true;
    try {
      final peerScores = _rubricScores[peer.uid] ?? {};
      final comment = _comments[peer.uid] ?? '';

      final scoresList = <int>[];
      if (rubrics.isEmpty) {
        scoresList.add(peerScores[0] ?? 3);
      } else {
        for (int i = 0; i < rubrics.length; i++) {
          scoresList.add(peerScores[i] ?? 3);
        }
      }

      final success = await _controller.submitEvaluation(
        cycleId: widget.pendingInfo.cycle.id,
        evaluateeUid: peer.uid,
        scores: scoresList,
        comments: comment.isEmpty ? null : comment,
      );

      if (success) {
        _submittedUids.add(peer.uid);
        Get.snackbar(
          'Evaluación enviada',
          'Has evaluado a ${peer.name.isEmpty ? peer.email : peer.name}',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.successSoft,
          colorText: AppColors.success,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 2),
        );
      }
    } finally {
      _isSubmitting.value = false;
    }
  }

  String _getInitials(String name, String email) {
    if (name.isNotEmpty) {
      final parts = name.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
    }
    return email.substring(0, email.length >= 2 ? 2 : 1).toUpperCase();
  }

  Color _getScoreColor(double score) {
    switch (score.round()) {
      case 1:
        return const Color(0xFFD32F2F);
      case 2:
        return const Color(0xFFEF6C00);
      case 3:
        return const Color(0xFFB58A00);
      case 4:
        return const Color(0xFF6BBE3A);
      case 5:
        return AppColors.success;
      default:
        return AppColors.textMuted;
    }
  }
}
