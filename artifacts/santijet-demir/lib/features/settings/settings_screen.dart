import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/features/auth/providers/app_lock_provider.dart';
import 'package:santijet_demir/features/auth/providers/auth_provider.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/settings/providers/profile_provider.dart';
import 'package:santijet_demir/features/settings/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final lock = ref.watch(appLockProvider);
    final project = ref.watch(activeProjectProvider);
    final displayName = ref.watch(profileDisplayNameProvider);
    final profession = ref.watch(profileProfessionProvider);
    final initial = ref.watch(profileInitialProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _ProfileHeader(
            displayName: displayName,
            profession: profession,
            initial: initial,
            projectName: project?.name ?? 'Proje seçilmedi',
            onEdit: () => _showProfileEditor(
              context,
              ref,
              displayName: displayName,
              profession: profession,
            ),
          ),
          const SizedBox(height: 16),
          _SettingsTile(
            icon: Icons.folder_copy,
            title: 'Projelerim',
            subtitle: project?.name ?? 'Proje seç veya oluştur',
            onTap: () => context.push(AppRoutes.projects),
          ),
          _SettingsTile(
            icon: Icons.business,
            title: 'Firma Bilgileri',
            subtitle: settings.companyName,
            onTap: () => context.push(AppRoutes.companySettings),
          ),
          _SettingsTile(
            icon: Icons.apartment,
            title: 'Proje Bilgileri',
            subtitle: project?.name ?? 'Aktif proje yok',
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
            icon: Icons.info_outline,
            title: 'Hakkında',
            subtitle: 'ŞantiJET DEMİR v1.0.0',
            onTap: () => context.push(AppRoutes.about),
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.delete_forever,
            title: 'Tüm Verileri Sil',
            subtitle: 'Projeler, yerel kayıtlar ve oturum silinir',
            onTap: () => _confirmDeleteAllData(context, ref),
            destructive: true,
          ),
        ],
      ),
    );
  }

  void _showProfileEditor(
    BuildContext context,
    WidgetRef ref, {
    required String displayName,
    required String profession,
  }) {
    final nameCtrl = TextEditingController(text: displayName);
    final professionCtrl = TextEditingController(text: profession);

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
            16 + MediaQuery.viewInsetsOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Profil Bilgileri', style: AppTypography.headlineMedium),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Ad Soyad'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: professionCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Meslek / Görev'),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  final ok = await ref.read(authProvider.notifier).updateProfile(
                        displayName: nameCtrl.text,
                        profession: professionCtrl.text,
                      );
                  if (!context.mounted) return;
                  if (ok) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profil güncellendi')),
                    );
                  } else {
                    final error = ref.read(authProvider).error;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(error ?? 'Profil güncellenemedi')),
                    );
                  }
                },
                child: const Text('Kaydet'),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      nameCtrl.dispose();
      professionCtrl.dispose();
    });
  }

  Future<void> _confirmDeleteAllData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tüm Verileri Sil'),
        content: const Text(
          'Tüm projeler, yerel kayıtlar ve oturum bilgisi silinecek. '
          'Bu işlem geri alınamaz. Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.critical,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Evet, Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await ref.read(appSettingsProvider.notifier).clearAllLocalData();
    await ref.read(authProvider.notifier).logout();
    ref.invalidate(userProjectsProvider);
    ref.invalidate(activeProjectProvider);
    ref.invalidate(activeProjectIdProvider);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tüm veriler silindi')),
    );
    context.go(AppRoutes.login);
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

  Future<String?> _showCreatePinDialog(BuildContext context) async {
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('PIN Oluştur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Uygulama girişi için 4–8 haneli bir PIN belirleyin.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newController,
              keyboardType: TextInputType.number,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Yeni PIN'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmController,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Yeni PIN (tekrar)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              final newPin = newController.text.trim();
              final confirm = confirmController.text.trim();
              if (!AppLockNotifier.isValidPin(newPin)) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('PIN 4–8 haneli olmalıdır')),
                );
                return;
              }
              if (newPin != confirm) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('PIN eşleşmiyor')),
                );
                return;
              }
              Navigator.pop(ctx, newPin);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    newController.dispose();
    confirmController.dispose();
    return result;
  }

  void _toggleAppLock(BuildContext context, WidgetRef ref, bool enabled) async {
    if (enabled) {
      final newPin = await _showCreatePinDialog(context);
      if (newPin == null || !context.mounted) return;

      final ok = await ref.read(appLockProvider.notifier).enableWithPin(newPin);
      if (!context.mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN kilidi etkinleştirildi')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN 4–8 haneli olmalıdır')),
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

    final ok = await ref.read(appLockProvider.notifier).disable(
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
                    : 'Şifresiz giriş aktif. PIN oluşturmak için anahtarı açın.',
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
  const _ProfileHeader({
    required this.displayName,
    required this.profession,
    required this.initial,
    required this.projectName,
    required this.onEdit,
  });

  final String displayName;
  final String profession;
  final String initial;
  final String projectName;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEdit,
        borderRadius: AppRadii.md,
        child: Container(
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
                child: Text(initial, style: AppTypography.headlineMedium),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName.toUpperCase(), style: AppTypography.titleLarge),
                    Text(profession, style: AppTypography.bodySmall),
                    Text(projectName, style: AppTypography.labelMedium),
                  ],
                ),
              ),
              const Icon(Icons.edit_outlined, color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
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
                              isEnabled
                                  ? 'Açık — PIN değiştir veya kilitle'
                                  : 'Kapalı — şifresiz giriş',
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
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

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
              Icon(
                icon,
                color: destructive ? AppColors.critical : AppColors.electricBlueLight,
                size: 22,
              ),
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
