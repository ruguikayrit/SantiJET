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
import '../../data/kasa_json_backup.dart';
import '../../data/settings_store.dart';

/// Ayarlar — PRO bölüm overline + Beton tile dili. Abonelik yok.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _busy = false;

  Future<void> _exportJson() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await kasaJsonBackup.share(
        hareketler: ref.read(hareketlerProvider),
        santiyeler: ref.read(santiyelerProvider),
        activeSantiye: ref.read(activeSantiyeProvider),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('JSON dışa aktarılamadı: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importJson() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final snapshot = await kasaJsonBackup.pickAndDecode();
      if (snapshot == null) return;
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          title: Text(
            'JSON içe aktar',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: Text(
            '${snapshot.hareketler.length} hareket yüklenecek'
            '${snapshot.skipped > 0 ? ' (${snapshot.skipped} satır atlandı)' : ''}. '
            'Mevcut hareketlerin yerini alır.',
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
      if (ok != true) return;
      await ref
          .read(hareketlerProvider.notifier)
          .replaceAll(snapshot.hareketler);
      await ref
          .read(santiyelerProvider.notifier)
          .replaceAll(snapshot.santiyeler);
      await ref
          .read(activeSantiyeProvider.notifier)
          .setActive(snapshot.activeSantiye);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${snapshot.hareketler.length} hareket JSON’dan yüklendi.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('JSON içe aktarılamadı: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(themeModeProvider);
    final santiyeler = ref.watch(santiyelerProvider);
    final activeSantiye = ref.watch(activeSantiyeProvider);
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
                        licensed
                            ? Icons.verified_outlined
                            : Icons.lock_outline,
                        size: 20,
                        color: licensed
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
                              licensed
                                  ? 'Açık (iskelet — mağaza sonra)'
                                  : 'Kilitli (iskelet — mağaza sonra)',
                              style: AppTypography.cardBodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('GÖRÜNÜM'),
          SJCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(themeLabel(mode), style: AppTypography.cardTitleMedium),
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
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('ŞANTİYE'),
          SJCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aktif şantiye',
                  style: AppTypography.cardLabelMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Ana sayfadaki seçimle aynıdır. Yeni hareketler bu şantiyeye yazılır.',
                  style: AppTypography.cardBodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  key: ValueKey('active-$activeSantiye'),
                  initialValue: santiyeler.contains(activeSantiye)
                      ? activeSantiye
                      : (santiyeler.isNotEmpty ? santiyeler.first : null),
                  items: santiyeler
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      ref.read(activeSantiyeProvider.notifier).setActive(v);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Kayıtlı şantiyeler', style: AppTypography.cardLabelMedium),
                const SizedBox(height: AppSpacing.xs),
                ...santiyeler.map(
                  (s) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(s, style: AppTypography.cardBodyMedium),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: AppColors.cardTextMuted,
                      ),
                      onPressed: () async {
                        await ref.read(santiyelerProvider.notifier).remove(s);
                        await ref
                            .read(activeSantiyeProvider.notifier)
                            .ensureValid(ref.read(santiyelerProvider));
                      },
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
          const SizedBox(height: AppSpacing.lg),
          const _SectionLabel('VERİ'),
          _ActionTile(
            icon: Icons.file_download_outlined,
            title: 'JSON dışa aktar',
            subtitle: 'Tüm hareketler ve şantiyeler bir dosyaya yazılır.',
            onTap: _busy ? null : _exportJson,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ActionTile(
            icon: Icons.file_upload_outlined,
            title: 'JSON içe aktar',
            subtitle: 'Yedek dosyası mevcut verinin yerini alır.',
            onTap: _busy ? null : _importJson,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ActionTile(
            icon: Icons.dataset_outlined,
            title: 'Demo veri yükle',
            subtitle: 'Excel örneğine benzer 12 satır.',
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
                    'Mevcut hareketlerin üzerine örnek veri yazılır.',
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
                await ref
                    .read(activeSantiyeProvider.notifier)
                    .setActive('İZMİT/EFSANE');
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          _ActionTile(
            icon: Icons.delete_outline,
            title: 'Tüm veriyi sil',
            subtitle: 'Bu cihazdaki kasa hareketleri silinir.',
            destructive: true,
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

/// Chrome overline — PRO Ayarlar bölüm başlığı dili.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final titleColor =
        destructive ? AppColors.critical : AppColors.cardTextPrimary;
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
          Icon(
            Icons.chevron_right,
            color: AppColors.cardTextMuted,
            size: 20,
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
