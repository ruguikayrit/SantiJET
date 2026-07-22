import 'package:flutter/material.dart';
import 'package:santijet_demir/core/widgets/app_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/domain/entities/cutting_bending.dart';
import 'package:santijet_demir/features/analysis/analysis_report_service.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';

class AnalysisReportActions extends ConsumerStatefulWidget {
  const AnalysisReportActions({
    super.key,
    required this.batch,
    required this.sourceBatches,
  });

  final CuttingBendingBatch batch;
  final List<CuttingBendingBatch> sourceBatches;

  @override
  ConsumerState<AnalysisReportActions> createState() =>
      _AnalysisReportActionsState();
}

class _AnalysisReportActionsState extends ConsumerState<AnalysisReportActions> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String errorLabel) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showAppSnackBar(
          SnackBar(content: Text('$errorLabel: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _preview() {
    final projectName = ref.read(activeProjectProvider)?.name ?? '';
    return _run(
      () => analysisReportService.previewReport(
        projectName: projectName,
        batch: widget.batch,
        sourceBatches: widget.sourceBatches,
      ),
      'PDF önizleme hatası',
    );
  }

  Future<void> _share() {
    final projectName = ref.read(activeProjectProvider)?.name ?? '';
    return _run(
      () => analysisReportService.shareReport(
        projectName: projectName,
        batch: widget.batch,
        sourceBatches: widget.sourceBatches,
      ),
      'PDF paylaşım hatası',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: AppColors.electricBlueGlow,
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.electricBlue.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.electricBlueLight.withValues(alpha: 0.28),
                  ),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_outlined,
                  color: AppColors.electricBlueLight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rapor Oluştur', style: AppTypography.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Fire özeti ile firesiz/fireli kesim kartlarını '
                      '(görsel bar dahil) PDF rapor olarak dışa aktarın.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _preview,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.electricBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.description_outlined),
            label: Text(
              _busy ? 'Rapor hazırlanıyor…' : 'PDF Rapor Oluştur',
              style: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy ? null : _share,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.electricBlueLight,
              side: BorderSide(
                color: AppColors.electricBlueLight.withValues(alpha: 0.45),
              ),
              minimumSize: const Size.fromHeight(44),
            ),
            icon: const Icon(Icons.ios_share_outlined, size: 18),
            label: const Text('PDF Paylaş'),
          ),
        ],
      ),
    );
  }
}
