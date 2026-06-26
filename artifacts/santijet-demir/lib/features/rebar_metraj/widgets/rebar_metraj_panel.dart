import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/data/services/dxf_rebar_parser.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';
import 'package:santijet_demir/features/rebar_metraj/providers/rebar_metraj_provider.dart';

class RebarMetrajPanel extends ConsumerWidget {
  const RebarMetrajPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(rebarMetrajResultProvider);
    final loading = ref.watch(rebarMetrajLoadingProvider);
    final error = ref.watch(rebarMetrajErrorProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const _InfoBanner(),
        const SizedBox(height: 16),
        _UploadCard(
          loading: loading,
          onPickFile: () => _pickAndParse(context, ref),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          _ErrorBanner(message: error),
        ],
        if (result != null) ...[
          const SizedBox(height: 20),
          _ResultSummary(result: result),
          const SizedBox(height: 16),
          Text('Çap Bazlı Metraj', style: AppTypography.headlineMedium),
          const SizedBox(height: 12),
          ...result.lines.map((line) => _MetrajLineCard(line: line)),
          if (result.textDetails.isNotEmpty) ...[
            const SizedBox(height: 20),
            _TextDetailSection(details: result.textDetails),
          ],
          if (result.warnings.isNotEmpty) ...[
            const SizedBox(height: 16),
            _WarningsCard(warnings: result.warnings),
          ],
          const SizedBox(height: 16),
          _MetaCard(result: result),
        ],
      ],
    );
  }

  Future<void> _pickAndParse(BuildContext context, WidgetRef ref) async {
    ref.read(rebarMetrajErrorProvider.notifier).state = null;

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['dxf', 'dwg'],
      withData: true,
    );

    if (picked == null || picked.files.isEmpty) return;

    final file = picked.files.first;
    final fileName = file.name;
    final extension = fileName.split('.').last.toLowerCase();

    final bytes = file.bytes;
    if (bytes == null) {
      ref.read(rebarMetrajErrorProvider.notifier).state =
          'Dosya okunamadı. Lütfen tekrar deneyin.';
      return;
    }

    ref.read(rebarMetrajLoadingProvider.notifier).state = true;
    try {
      final parser = ref.read(dxfRebarParserProvider);
      final isDwg =
          extension == 'dwg' || DxfRebarParser.isDwgBytes(bytes);
      final result = isDwg
          ? await parser.parseDwgBytes(fileName: fileName, bytes: bytes)
          : parser.parseBytes(fileName: fileName, bytes: bytes);
      ref.read(rebarMetrajResultProvider.notifier).state = result;
    } on FormatException catch (e) {
      ref.read(rebarMetrajErrorProvider.notifier).state = e.message;
    } catch (e) {
      ref.read(rebarMetrajErrorProvider.notifier).state =
          'CAD dosyası işlenemedi. DWG için sayfayı yenileyin; DXF için '
          'ASCII formatında kaydedilmiş olduğundan emin olun. Etiketlerde adet, '
          'çap (FI/Ø) ve l= boy birlikte olmalı (ör. üst.334Ø22/15 l=120).';
    } finally {
      ref.read(rebarMetrajLoadingProvider.notifier).state = false;
    }
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.electricBlue.withValues(alpha: 0.08),
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.electricBlue.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.architecture, color: AppColors.electricBlueLight, size: 20),
              const SizedBox(width: 8),
              Text('CAD\'den otomatik metraj', style: AppTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '1. AutoCAD/BricsCAD projesini DWG veya ASCII DXF olarak yükleyin\n'
            '2. üst.334Ø22/15 l=120 → 334 ad × 12 m (aralık hesaba katılmaz)\n'
            '3. 15000Ø16 l=200 → 15000 ad × 2 m\n'
            '4. Tonaj = adet × boy × birim ağırlık (kg/m)',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'DWG web tarayıcıda doğrudan okunur. DXF için ASCII formatı önerilir.',
            style: AppTypography.labelMedium.copyWith(color: AppColors.success),
          ),
        ],
      ),
    );
  }
}

class _UploadCard extends StatelessWidget {
  const _UploadCard({
    required this.loading,
    required this.onPickFile,
  });

  final bool loading;
  final VoidCallback onPickFile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.upload_file, size: 48, color: AppColors.electricBlueLight),
          const SizedBox(height: 12),
          Text('CAD Dosyası Yükle', style: AppTypography.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'DWG · DXF (ASCII)',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: loading ? null : onPickFile,
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.folder_open),
            label: Text(loading ? 'İşleniyor...' : 'Dosya Seç'),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.critical.withValues(alpha: 0.1),
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.critical.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.critical, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: AppTypography.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _ResultSummary extends StatelessWidget {
  const _ResultSummary({required this.result});

  final RebarMetrajResult result;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00', 'tr_TR');

    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Toplam Tonaj',
            value: formatter.format(result.totalTonnage),
            unit: 't',
            color: AppColors.electricBlueLight,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryTile(
            label: 'Toplam Uzunluk',
            value: formatter.format(result.totalLengthM),
            unit: 'm',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryTile(
            label: 'Çubuk Sayısı',
            value: '${result.totalBarCount}',
            unit: 'ad',
            color: AppColors.info,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelMedium),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: AppTypography.headlineMedium.copyWith(color: color),
              children: [
                TextSpan(text: value),
                TextSpan(
                  text: ' $unit',
                  style: AppTypography.labelMedium.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetrajLineCard extends StatelessWidget {
  const _MetrajLineCard({required this.line});

  final RebarMetrajLine line;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00', 'tr_TR');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.electricBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Ø${line.diameter}',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.electricBlueLight,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ø${line.diameter} demir', style: AppTypography.titleMedium),
                Text(
                  '${line.barCount} çubuk · ${formatter.format(line.totalLengthM)} m',
                  style: AppTypography.bodySmall,
                ),
                if (line.layerName.isNotEmpty)
                  Text(
                    line.layerName,
                    style: AppTypography.labelMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${formatter.format(line.tonnage)} t',
                style: AppTypography.titleMedium.copyWith(color: AppColors.success),
              ),
              Text(
                '${formatter.format(line.weightKg)} kg',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TextDetailSection extends StatelessWidget {
  const _TextDetailSection({required this.details});

  final List<RebarMetrajTextDetail> details;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00', 'tr_TR');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tanınan Demir Etiketleri', style: AppTypography.headlineMedium),
        const SizedBox(height: 4),
        Text(
          '${details.length} etiket (adet + çap + boy)',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: 12),
        ...details.map(
          (detail) => _TextDetailCard(detail: detail, formatter: formatter),
        ),
      ],
    );
  }
}

class _TextDetailCard extends StatelessWidget {
  const _TextDetailCard({
    required this.detail,
    required this.formatter,
  });

  final RebarMetrajTextDetail detail;
  final NumberFormat formatter;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.electricBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  detail.entityType,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.electricBlueLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            detail.sourceText,
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '${detail.quantity} ad · '
            'Ø${detail.diameter} · '
            '${formatter.format(detail.lengthM)} m · '
            '${formatter.format(detail.weightKg)} kg',
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _WarningsCard extends StatelessWidget {
  const _WarningsCard({required this.warnings});

  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Uyarılar', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          ...warnings.map(
            (warning) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $warning', style: AppTypography.bodySmall),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.result});

  final RebarMetrajResult result;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dosya Bilgisi', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          _MetaRow(label: 'Dosya', value: result.fileName),
          _MetaRow(label: 'Format', value: result.sourceFormat),
          _MetaRow(label: 'Tarih', value: dateFormat.format(result.parsedAt)),
          _MetaRow(
            label: 'Tanınan etiket',
            value: '${result.textDetails.length}',
          ),
          _MetaRow(
            label: 'Atlanan metin',
            value: '${result.skippedEntityCount}',
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: AppTypography.bodySmall)),
          Expanded(child: Text(value, style: AppTypography.titleMedium)),
        ],
      ),
    );
  }
}
