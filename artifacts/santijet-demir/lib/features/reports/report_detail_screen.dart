import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/domain/entities/report.dart';
import 'package:santijet_demir/features/reports/providers/reports_provider.dart';

class ReportDetailScreen extends ConsumerWidget {
  const ReportDetailScreen({super.key, required this.reportId});

  final String reportId;

  ReportCategory? _findCategory(List<ReportCategory> categories) {
    for (final c in categories) {
      if (c.id == reportId) return c;
    }
    return null;
  }

  ReportItem? _findReport(List<ReportItem> reports) {
    for (final r in reports) {
      if (r.id == reportId) return r;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(reportCategoriesProvider);
    final reports = ref.watch(reportsProvider);

    final category = _findCategory(categories);
    final report = _findReport(reports);

    final title = report?.title ?? category?.title ?? 'Rapor';
    final format = report?.format ?? category?.format ?? 'PDF';
    final date = report?.date ?? DateTime.now();
    final size = report?.size ?? '—';
    final generatedBy = report?.generatedBy ?? 'Sistem';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: Text(title, style: AppTypography.titleLarge)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: AppRadii.md,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _MetaRow('Format', format),
                _MetaRow('Boyut', size),
                _MetaRow('Tarih', DateFormat('d MMM yyyy, HH:mm').format(date)),
                _MetaRow('Oluşturan', generatedBy),
                _MetaRow('Proje', 'ABC İnşaat — Blok A'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Önizleme', style: AppTypography.headlineMedium),
          const SizedBox(height: 12),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight,
              borderRadius: AppRadii.md,
              border: Border.all(color: AppColors.border),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    format == 'PDF' ? Icons.picture_as_pdf : Icons.table_chart,
                    size: 48,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 8),
                  Text('Rapor önizlemesi', style: AppTypography.bodyMedium),
                  Text(
                    'Gerçek PDF/Excel export Faz 5\'te eklenecek',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _FakeChartPreview(),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionButton(
                icon: Icons.download,
                label: 'İndir',
                onPressed: () => _showSnack(context, 'Rapor indiriliyor...'),
              ),
              _ActionButton(
                icon: Icons.upload,
                label: 'Dışa Aktar',
                onPressed: () => _showSnack(context, 'Dışa aktarma hazırlanıyor...'),
              ),
              _ActionButton(
                icon: Icons.share,
                label: 'Paylaş',
                onPressed: () => _showSnack(context, 'Paylaşım menüsü açılıyor...'),
              ),
              _ActionButton(
                icon: Icons.visibility,
                label: 'Görüntüle',
                onPressed: () => _showSnack(context, 'Tam ekran önizleme'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.electricBlue),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium),
          Text(value, style: AppTypography.titleMedium),
        ],
      ),
    );
  }
}

class _FakeChartPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const heights = [0.6, 0.85, 0.45, 0.72, 0.55, 0.9, 0.68];

    return Container(
      height: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: heights.map((h) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(
                height: 80 * h,
                decoration: BoxDecoration(
                  color: AppColors.electricBlue.withValues(alpha: 0.4 + h * 0.3),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
