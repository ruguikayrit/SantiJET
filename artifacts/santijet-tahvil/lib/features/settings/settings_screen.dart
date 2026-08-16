import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_info.dart';
import '../../core/design_system/sj_card.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../../data/records_store.dart';
import '../../domain/tahvil_rules.dart';

/// Ayarlar — tema, fiyatlandırma, kurallar. Hesap / abonelik yok.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/hesap');
            }
          },
        ),
        title: Text(
          'Ayarlar',
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          SJCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Satış modeli', style: AppTypography.cardLabelMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Tek fiyat. Abonelik yok.',
                  style: AppTypography.onCard(AppTypography.headlineMedium),
                ),
                const SizedBox(height: 6),
                Text(
                  AppInfo.pricingLine,
                  style: AppTypography.cardBodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SJCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Görünüm', style: AppTypography.cardLabelMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  themeLabel(mode),
                  style: AppTypography.cardTitleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final option in const [
                      ('santijet_pro', 'ŞantiJET Pro'),
                      ('santijet', 'ŞantiJET'),
                      ('light', 'Açık'),
                      ('dark', 'Koyu'),
                      ('system', 'Sistem'),
                    ])
                      _ThemeChip(
                        label: option.$2,
                        selected: mode == option.$1,
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(option.$1),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SJCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tahvil kuralları', style: AppTypography.cardLabelMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '• Çap farkı en fazla ±$tahvilMaxDiameterDiffMm mm\n'
                  '• Hedef kesit proje kesitine eşit veya büyük\n'
                  '• Fazla kesit en fazla %${(tahvilMaxAreaDeviationRatio * 100).toStringAsFixed(0)}\n'
                  '• Donatı aralığı en fazla ${tahvilMaxSpacingCm.toStringAsFixed(0)} cm\n'
                  '• Standart çaplar: Ø8–Ø32',
                  style: AppTypography.cardBodyMedium.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SJCard(
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surfaceElevated,
                  title: Text(
                    'Kayıtları sil',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  content: Text(
                    'Bu cihazdaki tahvil kayıtları silinir.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Vazgeç'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Sil'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(tahvilRecordsProvider.notifier).clear();
              }
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Kayıtları temizle',
                    style: AppTypography.cardTitleMedium,
                  ),
                ),
                Icon(
                  Icons.delete_outline,
                  color: AppColors.statusInkOnCard(AppColors.critical),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '${AppInfo.displayName}  ·  v${AppInfo.version}',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppInfo.supportEmail,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.electricBlue
              : AppColors.cardInsetSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AppTypography.cardLabelLarge.copyWith(
            color: selected ? Colors.white : AppColors.cardTextPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
