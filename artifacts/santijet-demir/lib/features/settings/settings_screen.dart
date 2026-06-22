import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/empty_states.dart';
import 'package:santijet_demir/domain/entities/app_settings.dart';
import 'package:santijet_demir/features/auth/providers/app_lock_provider.dart';
import 'package:santijet_demir/features/settings/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final lock = ref.watch(appLockProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _ProfileHeader(settings: settings),
          const SizedBox(height: 16),
          _SettingsTile(
            icon: Icons.business,
            title: 'Firma Bilgileri',
            subtitle: settings.companyName,
            onTap: () => context.push(AppRoutes.companySettings),
          ),
          _SettingsTile(
            icon: Icons.apartment,
            title: 'Proje Bilgileri',
            subtitle: settings.projectName,
            onTap: () => context.push(AppRoutes.projectSettings),
          ),
          _SettingsTile(
            icon: Icons.notifications,
            title: 'Bildirim Ayarları',
            subtitle: 'Stok, sipariş, teslimat, analiz',
            onTap: () => context.push(AppRoutes.notificationSettings),
          ),
          _AppLockSettingsTile(
            isEnabled: lock.isEnabled,
            onToggle: (enabled) => _toggleAppLock(context, ref, enabled),
            onOpenDetails: () => _showAppLockSheet(context, ref),
          ),
          _SettingsTile(
            icon: Icons.dark_mode,
            title: 'Tema',
            subtitle: _themeLabel(settings.themeMode),
            onTap: () => _showThemePicker(context, ref),
          ),
          _SettingsTile(
            icon: Icons.scale,
            title: 'Birim Tercihi',
            subtitle: settings.weightUnit == 'kg' ? 'Kilogram (kg)' : 'Ton',
            onTap: () => _showUnitPicker(context, ref),
          ),
          _SettingsTile(
            icon: Icons.backup,
            title: 'Yedekleme & Geri Yükleme',
            subtitle: 'Ayarları dışa/içe aktar',
            onTap: () => _showBackupDialog(context, ref),
          ),
          _SettingsTile(
            icon: Icons.layers,
            title: 'Boş Durum Önizleme',
            subtitle: 'Figma empty state component\'leri',
            onTap: () => context.push(AppRoutes.emptyStates),
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'Hakkında',
            subtitle: 'ŞantiJET DEMİR v1.0.0',
            onTap: () => context.push(AppRoutes.about),
          ),
        ],
      ),
    );
  }

  String _themeLabel(String mode) => switch (mode) {
        'light' => 'Açık',
        'dark' => 'Koyu',
        _ => 'Sistem',
      };

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Açık'),
            onTap: () {
              ref.read(appSettingsProvider.notifier).setThemeMode('light');
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            title: const Text('Koyu'),
            onTap: () {
              ref.read(appSettingsProvider.notifier).setThemeMode('dark');
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            title: const Text('Sistem'),
            onTap: () {
              ref.read(appSettingsProvider.notifier).setThemeMode('system');
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _showUnitPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Kilogram (kg)'),
            onTap: () {
              ref.read(appSettingsProvider.notifier).setWeightUnit('kg');
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            title: const Text('Ton'),
            onTap: () {
              ref.read(appSettingsProvider.notifier).setWeightUnit('ton');
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _showBackupDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yedekleme'),
        content: const Text(
          'Ayarlarınız yerel olarak Hive\'da saklanır. '
          'Tam yedekleme/geri yükleme bir sonraki sürümde dosya seçici ile eklenecek.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tamam')),
        ],
      ),
    );
  }

  void _toggleAppLock(BuildContext context, WidgetRef ref, bool enabled) async {
    if (enabled) {
      final ok = await ref.read(appLockProvider.notifier).setEnabled(true);
      if (!context.mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN kilidi açıldı')),
        );
      }
      return;
    }

    final pinController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('PIN Kilidini Kapat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Kilidi kapatmak için mevcut PIN\'inizi girin.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Mevcut PIN'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      pinController.dispose();
      return;
    }

    final ok = await ref.read(appLockProvider.notifier).setEnabled(
          false,
          currentPin: pinController.text.trim(),
        );
    pinController.dispose();

    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN kilidi kapatıldı')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN hatalı, kilitleme kapatılamadı')),
      );
    }
  }

  void _showAppLockSheet(BuildContext context, WidgetRef ref) {
    final isEnabled = ref.read(appLockProvider).isEnabled;
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.viewPaddingOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Uygulama Kilidi', style: AppTypography.headlineMedium),
              const SizedBox(height: 8),
              Text(
                isEnabled
                    ? 'PIN 4–8 haneli olmalıdır. Bu telefonda bir kez girildikten sonra tekrar sorulmaz.'
                    : 'PIN kilidi kapalı. Açmak için Ayarlar\'daki anahtarı kullanın.',
                style: AppTypography.bodySmall,
              ),
              if (isEnabled) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: currentController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mevcut PIN'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: newController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Yeni PIN'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Yeni PIN (tekrar)'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () async {
                    final current = currentController.text.trim();
                    final newPin = newController.text.trim();
                    final confirm = confirmController.text.trim();

                    if (newPin != confirm) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Yeni PIN eşleşmiyor')),
                      );
                      return;
                    }

                    final ok = await ref.read(appLockProvider.notifier).changePin(
                          currentPin: current,
                          newPin: newPin,
                        );
                    if (!context.mounted) return;
                    if (ok) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('PIN güncellendi')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('PIN değiştirilemedi')),
                      );
                    }
                  },
                  child: const Text('PIN Değiştir'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    ref.read(appLockProvider.notifier).lock();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Uygulamayı Kilitle'),
                ),
              ],
            ],
          ),
        );
      },
    ).whenComplete(() {
      currentController.dispose();
      newController.dispose();
      confirmController.dispose();
    });
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.warning.withValues(alpha: 0.3),
            child: Text('U', style: AppTypography.headlineMedium),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('UĞUR TİRYAKİ', style: AppTypography.titleLarge),
                Text('Şantiye Şefi', style: AppTypography.bodySmall),
                Text(settings.projectName, style: AppTypography.labelMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppLockSettingsTile extends StatelessWidget {
  const _AppLockSettingsTile({
    required this.isEnabled,
    required this.onToggle,
    required this.onOpenDetails,
  });

  final bool isEnabled;
  final ValueChanged<bool> onToggle;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onOpenDetails,
                borderRadius: AppRadii.md,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline, color: AppColors.electricBlueLight, size: 22),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Uygulama Kilidi', style: AppTypography.titleMedium),
                            Text(
                              isEnabled ? 'Açık — PIN değiştir veya kilitle' : 'Kapalı',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.md,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: AppRadii.md,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.electricBlueLight, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.titleMedium),
                    Text(subtitle, style: AppTypography.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyStatesPreviewScreen extends StatelessWidget {
  const EmptyStatesPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Boş Durumlar')),
      body: ListView(
        children: EmptyStateType.values.map((type) {
          return SizedBox(
            height: 220,
            child: ModuleEmptyState(type: type),
          );
        }).toList(),
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Hakkında')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Image.asset('assets/images/s_logo.png', width: 80, height: 80),
            const SizedBox(height: 16),
            Text('ŞantiJET DEMİR', style: AppTypography.headlineLarge),
            Text('ÇELİK TAKİP SİSTEMİ', style: AppTypography.labelSmall),
            const SizedBox(height: 8),
            Text('Versiyon 1.0.0', style: AppTypography.bodyMedium),
            const SizedBox(height: 24),
            Text(
              'Demir keşfi, sipariş, teslimat, saha sayımı ve analiz '
              'için profesyonel çelik takip uygulaması.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
