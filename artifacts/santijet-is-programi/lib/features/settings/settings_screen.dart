import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/app_state.dart';
import '../../state/license_state.dart';
import '../../ui/design_system.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final activeSite = ref.watch(activeSiteProvider);
    final sites = {
      activeSite,
      ...ref.watch(programItemsProvider).map((item) => item.santiyeId),
    }.toList()..sort();
    final license = ref.watch(licenseProvider);

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
              context.go('/');
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
          const _SectionLabel('LİSANS'),
          SJCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tek fiyat. Abonelik yok.',
                  style: AppTypography.onCard(AppTypography.headlineMedium),
                ),
                const SizedBox(height: 6),
                Text(AppInfo.pricingLine, style: AppTypography.cardBodySmall),
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardInsetSurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        license.licensed
                            ? Icons.verified_outlined
                            : Icons.lock_outline,
                        size: 20,
                        color: license.licensed
                            ? AppColors.success
                            : AppColors.cardTextMuted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tek seferlik lisans',
                              style: AppTypography.cardTitleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              license.licensed
                                  ? 'Lisans etkin'
                                  : (license.message ??
                                        license.product?.price ??
                                        'Kilitli — mağaza sonra'),
                              style: AppTypography.cardBodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (license.loading)
                        const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else if (!license.licensed && license.product != null)
                        TextButton(
                          onPressed: () =>
                              ref.read(licenseProvider.notifier).buy(),
                          child: const Text('Satın al'),
                        ),
                    ],
                  ),
                ),
                if (!license.licensed) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: license.storeAvailable
                          ? () => ref.read(licenseProvider.notifier).restore()
                          : null,
                      child: const Text('Satın almayı geri yükle'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('GÖRÜNÜM'),
          SJCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  themeLabel(themeMode),
                  style: AppTypography.cardTitleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Tema seçimi cihazda saklanır.',
                  style: AppTypography.cardBodySmall,
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
                    ])
                      _ThemeChip(
                        label: option.$2,
                        selected: themeMode == option.$1,
                        onTap: () => ref
                            .read(themeModeProvider.notifier)
                            .select(option.$1),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('ŞANTİYE'),
          SJCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Varsayılan şantiye',
                  style: AppTypography.cardLabelMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Program, Takvim ve Özet bu şantiyeyi kullanır.',
                  style: AppTypography.cardBodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: activeSite,
                  items: sites
                      .map(
                        (site) =>
                            DropdownMenuItem(value: site, child: Text(site)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(activeSiteProvider.notifier).select(value);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('VERİ'),
          _ActionTile(
            icon: Icons.swap_vert_rounded,
            title: 'MS Project · Excel · PDF aktarımı',
            subtitle: 'Programı dışa aktar ya da Project dosyası oku.',
            onTap: () => context.push('/aktar'),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ActionTile(
            icon: Icons.dataset_outlined,
            title: 'Demo veri yükle',
            subtitle: '10 örnek imalat, adam-gün ve saha kaydı.',
            onTap: () => _loadDemo(context, ref),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ActionTile(
            icon: Icons.delete_outline,
            title: 'Tüm veriyi sil',
            subtitle: 'Bu cihazdaki faaliyetler silinir.',
            destructive: true,
            onTap: () => _clearData(context, ref),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('HAKKINDA'),
          SJCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppInfo.displayName,
                  style: AppTypography.onCard(AppTypography.headlineMedium),
                ),
                const SizedBox(height: 6),
                Text(AppInfo.tagline, style: AppTypography.cardBodySmall),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '${AppInfo.displayName}  ·  v${AppInfo.version}',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            AppInfo.supportEmail,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Future<void> _loadDemo(BuildContext context, WidgetRef ref) async {
    final accepted = await _confirm(
      context,
      title: 'Demo veri yüklensin mi?',
      message: 'Mevcut faaliyetler silinip örnek program yüklenecek.',
      action: 'Yükle',
    );
    if (!accepted) return;
    await ref.read(programItemsProvider.notifier).loadDemo();
    await ref.read(activeSiteProvider.notifier).select('Merkez Şantiyesi');
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Demo program yüklendi.')));
    }
  }

  Future<void> _clearData(BuildContext context, WidgetRef ref) async {
    final accepted = await _confirm(
      context,
      title: 'Tüm veriler silinsin mi?',
      message: 'Cihazdaki faaliyetler kalıcı olarak silinecek.',
      action: 'Tümünü sil',
    );
    if (!accepted) return;
    await ref.read(programItemsProvider.notifier).clear();
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          title: Text(title, style: TextStyle(color: AppColors.textPrimary)),
          content: Text(
            message,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      title,
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        fontSize: 12,
      ),
    ),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final titleColor = destructive
        ? AppColors.critical
        : AppColors.cardTextPrimary;
    final subColor = destructive
        ? AppColors.critical.withValues(alpha: 0.8)
        : AppColors.cardTextSecondary;

    return SJCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            color: destructive ? AppColors.critical : AppColors.electricBlue,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.cardTitleMedium.copyWith(
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.cardBodySmall.copyWith(color: subColor),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.cardTextMuted, size: 20),
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
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.electricBlue : AppColors.cardInsetSurface,
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
