import 'package:flutter/material.dart';

import '../../core/design_system/design_system.dart';
import '../../core/theme/app_spacing.dart';

/// Dışa aktarma format seçici — PDF veya Excel.
enum ExportFormat { pdf, excel }

abstract final class ExportFormatSheet {
  static Future<ExportFormat?> pick(BuildContext context, {String? title}) {
    return SJModal.showSheet<ExportFormat>(
      context: context,
      title: title ?? 'Dışa Aktar',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SJButton(
            label: 'PDF',
            icon: Icons.picture_as_pdf_outlined,
            variant: SJButtonVariant.secondary,
            onPressed: () => Navigator.of(context).pop(ExportFormat.pdf),
          ),
          const SizedBox(height: AppSpacing.sm),
          SJButton(
            label: 'Excel',
            icon: Icons.table_chart_outlined,
            variant: SJButtonVariant.secondary,
            onPressed: () => Navigator.of(context).pop(ExportFormat.excel),
          ),
        ],
      ),
    );
  }
}
