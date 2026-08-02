import 'package:flutter/material.dart';

import '../../core/design_system/design_system.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/services/compare_export_service.dart';

/// Karşılaştırma PDF stil seçici.
abstract final class ComparePdfStyleSheet {
  static Future<ComparePdfStyle?> pick(BuildContext context) {
    return SJModal.showSheet<ComparePdfStyle>(
      context: context,
      title: 'PDF Stilini Seç',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SJButton(
            label: 'Renkli ve dolgulu',
            icon: Icons.palette_outlined,
            variant: SJButtonVariant.secondary,
            onPressed: () =>
                Navigator.of(context).pop(ComparePdfStyle.colorFilled),
          ),
          const SizedBox(height: AppSpacing.sm),
          SJButton(
            label: 'Siyah-beyaz ve dolgusuz',
            icon: Icons.contrast,
            variant: SJButtonVariant.secondary,
            onPressed: () =>
                Navigator.of(context).pop(ComparePdfStyle.monoPlain),
          ),
        ],
      ),
    );
  }
}
