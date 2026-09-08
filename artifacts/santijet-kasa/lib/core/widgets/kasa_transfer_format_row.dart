import 'package:flutter/material.dart';

import '../design_system/sj_button.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../../domain/kasa_transfer_format.dart';

/// JPG · PDF · Excel — içe / dışa aktarımda ortak üçlü.
class KasaTransferFormatRow extends StatelessWidget {
  const KasaTransferFormatRow({
    required this.title,
    required this.busy,
    required this.onSelected,
    this.enabled = true,
    super.key,
  });

  final String title;
  final bool busy;
  final bool enabled;
  final ValueChanged<KasaTransferFormat> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: SJButton(
                label: 'JPG',
                icon: Icons.image_outlined,
                variant: SJButtonVariant.secondary,
                loading: busy,
                expanded: true,
                onPressed: !enabled || busy
                    ? null
                    : () => onSelected(KasaTransferFormat.jpg),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SJButton(
                label: 'PDF',
                icon: Icons.picture_as_pdf_outlined,
                loading: busy,
                expanded: true,
                onPressed: !enabled || busy
                    ? null
                    : () => onSelected(KasaTransferFormat.pdf),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SJButton(
                label: 'Excel',
                icon: Icons.table_chart_outlined,
                variant: SJButtonVariant.secondary,
                loading: busy,
                expanded: true,
                onPressed: !enabled || busy
                    ? null
                    : () => onSelected(KasaTransferFormat.excel),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
