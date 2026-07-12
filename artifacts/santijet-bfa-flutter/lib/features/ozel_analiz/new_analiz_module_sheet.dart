import 'package:flutter/material.dart';

import '../../core/design_system/design_system.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/enums/app_enums.dart';

/// Yeni analiz için disiplin seçici — RN `NewAnalizModulePickerModal` karşılığı.
abstract final class NewAnalizModuleSheet {
  static Future<AnalizDiscipline?> show(BuildContext context) {
    return SJModal.showSheet<AnalizDiscipline>(
      context: context,
      title: 'Yeni Analiz',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Tile(
            title: 'İnşaat B.F.A.',
            subtitle: 'İnşaat imalat analizi oluştur',
            icon: Icons.layers,
            color: AppColors.moduleInsaat,
            discipline: AnalizDiscipline.insaat,
          ),
          const SizedBox(height: AppSpacing.xs),
          _Tile(
            title: 'Mekanik Tesisat B.F.A.',
            subtitle: 'Mekanik tesisat analizi oluştur',
            icon: Icons.plumbing,
            color: AppColors.moduleMekanik,
            discipline: AnalizDiscipline.mekanik,
          ),
          const SizedBox(height: AppSpacing.xs),
          _Tile(
            title: 'Elektrik Tesisat B.F.A.',
            subtitle: 'Elektrik tesisat analizi oluştur',
            icon: Icons.bolt,
            color: AppColors.moduleElektrik,
            discipline: AnalizDiscipline.elektrik,
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.discipline,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final AnalizDiscipline discipline;

  @override
  Widget build(BuildContext context) {
    return SJCard(
      accentColor: color,
      onTap: () => Navigator.of(context).pop(discipline),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
