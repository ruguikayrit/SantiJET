import 'package:flutter/material.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';

void showReportMissingDataDialog(
  BuildContext context, {
  required String reportTitle,
  required List<String> missingRequirements,
}) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Rapor oluşturulamıyor'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$reportTitle için aşağıdaki veriler gereklidir:',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 12),
          for (final item in missingRequirements)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(
                    child: Text(item, style: AppTypography.bodyMedium),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'İstenen veriler olmadan rapor oluşturulamaz.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tamam'),
        ),
      ],
    ),
  );
}
