import 'package:flutter/material.dart';

import '../../../core/design_system/sj_button.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/services/production_export_service.dart';
import '../../../data/services/production_report_builder.dart';
import '../../../domain/entities/production.dart';

/// İmalat / Verim — PDF · Excel seçimi (Görev AL format satırı).
class ProductionExportSheet extends StatefulWidget {
  const ProductionExportSheet({
    required this.projectName,
    required this.productions,
    required this.kind,
    super.key,
  });

  final String projectName;
  final List<Production> productions;
  final ProductionExportKind kind;

  @override
  State<ProductionExportSheet> createState() => _ProductionExportSheetState();
}

class _ProductionExportSheetState extends State<ProductionExportSheet> {
  bool _busy = false;
  String? _error;

  String get _kindLabel =>
      widget.kind == ProductionExportKind.imalat ? 'İmalat' : 'Verim';

  Future<void> _export({required bool pdf}) async {
    if (widget.productions.isEmpty) {
      setState(() => _error = 'Dışa aktarılacak $_kindLabel kaydı yok.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final report = ProductionReportBuilder.build(
        projectName: widget.projectName,
        productions: widget.productions,
        kind: widget.kind,
      );
      if (pdf) {
        await productionExportService.exportPdf(report);
      } else {
        await productionExportService.exportExcel(report);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            pdf ? '$_kindLabel PDF dışa aktarıldı.' : '$_kindLabel Excel dışa aktarıldı.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = widget.productions.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${widget.projectName} · $count satır',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Format', style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: SJButton(
                label: 'PDF',
                icon: Icons.picture_as_pdf_outlined,
                loading: _busy,
                expanded: true,
                onPressed: () => _export(pdf: true),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SJButton(
                label: 'Excel',
                icon: Icons.table_chart_outlined,
                variant: SJButtonVariant.secondary,
                loading: _busy,
                expanded: true,
                onPressed: () => _export(pdf: false),
              ),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.critical,
            ),
          ),
        ],
      ],
    );
  }
}
