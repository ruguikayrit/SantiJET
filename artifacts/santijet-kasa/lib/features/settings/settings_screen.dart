import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_info.dart';
import '../../core/design_system/sj_card.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_mode_provider.dart';
import '../../data/demo_data.dart';
import '../../data/hareketler_store.dart';
import '../../data/settings_store.dart';

/// Ayarlar — tema, şantiye, demo, sil, lisans iskeleti. Abonelik yok.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final santiyeler = ref.watch(santiyelerProvider);
    final defaultSantiye = ref.watch(defaultSantiyeProvider);
    final licensed = ref.watch(licenseUnlockedProvider);

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
              context.go(AppRoutes.kasa);
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
                Text(AppInfo.pricingLine, style: AppTypography.cardBodySmall),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SJCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tek seferlik lisans',
                  style: AppTypography.cardLabelMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  licensed ? 'Açık (iskelet)' : 'Kilitli (iskelet)',
                  style: AppTypography.cardTitleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Mağaza IAP bağlanınca burada unlock görünecek. Şimdilik '
                  'yalnızca durum alanı — abonelik yok.',
                  style: AppTypography.cardBodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => ref
                          .read(licenseUnlockedProvider.notifier)
                          .setUnlocked(true),
                      child: const Text('Simüle: aç'),
                    ),
                    OutlinedButton(
                      onPressed: () => ref
                          .read(licenseUnlockedProvider.notifier)
                          .setUnlocked(false),
                      child: const Text('Simüle: kilit'),
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
                Text('Görünüm', style: AppTypography.cardLabelMedium),
                const SizedBox(height: AppSpacing.sm),
                Text(themeLabel(mode), style: AppTypography.cardTitleMedium),
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
                Text(
                  'Varsayılan şantiye',
                  style: AppTypography.cardLabelMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  key: ValueKey('default-$defaultSantiye'),
                  initialValue: santiyeler.contains(defaultSantiye)
                      ? defaultSantiye
                      : (santiyeler.isNotEmpty ? santiyeler.first : null),
                  items: santiyeler
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(defaultSantiyeProvider.notifier).setDefault(v);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Şantiyeler', style: AppTypography.cardLabelMedium),
                const SizedBox(height: AppSpacing.xs),
                ...santiyeler.map(
                  (s) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(s, style: AppTypography.cardBodyMedium),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () =>
                          ref.read(santiyelerProvider.notifier).remove(s),
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final controller = TextEditingController();
                    final name = await showDialog<String>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.surfaceElevated,
                        title: Text(
                          'Şantiye ekle',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                        content: TextField(
                          controller: controller,
                          autofocus: true,
                          decoration: const InputDecoration(
                            hintText: 'Örn. İZMİT/EFSANE',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Vazgeç'),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(ctx, controller.text.trim()),
                            child: const Text('Ekle'),
                          ),
                        ],
                      ),
                    );
                    if (name != null && name.isNotEmpty) {
                      await ref.read(santiyelerProvider.notifier).add(name);
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Şantiye ekle'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SJCard(
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surfaceElevated,
                  title: Text(
                    'Demo veri yükle',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  content: Text(
                    'Mevcut hareketlerin üzerine örnek Excel verisi yazılır.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Vazgeç'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Yükle'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                final demo = buildDemoHareketler();
                await ref.read(hareketlerProvider.notifier).replaceAll(demo);
                await ref
                    .read(santiyelerProvider.notifier)
                    .replaceAll(['İZMİT/EFSANE']);
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Demo veri', style: AppTypography.cardTitleMedium),
                const SizedBox(height: 4),
                Text(
                  'Excel örneğine benzer 12 satır yükle.',
                  style: AppTypography.cardBodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SJCard(
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surfaceElevated,
                  title: Text(
                    'Tüm veriyi sil',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  content: Text(
                    'Bu cihazdaki tüm kasa hareketleri silinir.',
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
              if (ok == true) {
                await ref.read(hareketlerProvider.notifier).clear();
              }
            },
            child: Text(
              'Tüm veriyi sil',
              style: AppTypography.cardTitleMedium.copyWith(
                color: AppColors.critical,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SJCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hakkında', style: AppTypography.cardLabelMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  AppInfo.displayName,
                  style: AppTypography.onCard(AppTypography.headlineMedium),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sürüm ${AppInfo.version}\n${AppInfo.tagline}\n${AppInfo.supportEmail}',
                  style: AppTypography.cardBodySmall.copyWith(height: 1.45),
                ),
              ],
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
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.electricBlue.withValues(alpha: 0.2),
      checkmarkColor: AppColors.electricBlue,
      labelStyle: AppTypography.labelMedium.copyWith(
        color: selected ? AppColors.electricBlue : AppColors.textSecondary,
      ),
      side: BorderSide(
        color: selected ? AppColors.electricBlue : AppColors.border,
      ),
      backgroundColor: AppColors.surface,
    );
  }
}
