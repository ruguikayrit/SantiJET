import 'package:flutter/material.dart';
import 'package:santijet_demir/core/widgets/app_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/data/services/project_backup_service.dart';
import 'package:santijet_demir/data/services/rebar_weight_calculator.dart';
import 'package:santijet_demir/domain/enums/corporate_role.dart';
import 'package:santijet_demir/domain/enums/membership_type.dart';
import 'package:santijet_demir/features/auth/providers/app_lock_provider.dart';
import 'package:santijet_demir/features/auth/providers/auth_provider.dart';
import 'package:santijet_demir/features/auth/providers/membership_permission_provider.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/settings/providers/profile_provider.dart';
import 'package:santijet_demir/features/settings/providers/backup_provider.dart';
import 'package:santijet_demir/features/settings/providers/settings_provider.dart';
import 'package:santijet_demir/features/subscription/providers/subscription_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final lock = ref.watch(appLockProvider);
    final project = ref.watch(activeProjectProvider);
    final displayName = ref.watch(profileDisplayNameProvider);
    final profession = ref.watch(profileProfessionProvider);
    final role = ref.watch(profileRoleProvider);
    final initial = ref.watch(profileInitialProvider);
    final membershipLabel =
        ref.watch(authProvider).user?.membershipSummary ?? 'Bireysel';
    final package = ref.watch(currentSubscriptionPackageProvider);
    final canPrediction = ref.watch(canAccessPredictionProvider);
    final predictionRoute =
        canPrediction ? AppRoutes.prediction : AppRoutes.subscription;
    final workScheduleRoute =
        canPrediction ? AppRoutes.workSchedule : AppRoutes.subscription;
    final workforceRoute =
        canPrediction ? AppRoutes.workforce : AppRoutes.subscription;
    final lockedHint = canPrediction
        ? null
        : 'Analiz & Tahmin paketi gerekir · Paketleri gör';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _ProfileHeader(
            displayName: displayName,
            profession: profession,
            role: role,
            membershipLabel: membershipLabel,
            initial: initial,
            projectName: project?.name ?? 'Proje seçilmedi',
            onEdit: () => _showProfileEditor(
              context,
              ref,
              displayName: displayName,
              profession: profession,
              role: role,
            ),
          ),
          const SizedBox(height: 16),
          _SettingsTile(
            icon: Icons.workspace_premium_outlined,
            title: 'Abonelik',
            subtitle: '${package.title} · Paketleri gör',
            onTap: () => context.push(AppRoutes.subscription),
          ),
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
            icon: Icons.analytics_outlined,
            title: 'Demir Tahmin Motoru',
            subtitle: lockedHint ??
                'Stok tükenme, sipariş önerisi, iş programı',
            onTap: () => context.push(predictionRoute),
          ),
          _SettingsTile(
            icon: Icons.calendar_month_outlined,
            title: 'İş Programı',
            subtitle: lockedHint ??
                'Keşif imalatları · başlangıç / bitiş / süre',
            onTap: () => context.push(workScheduleRoute),
          ),
          _SettingsTile(
            icon: Icons.groups_outlined,
            title: 'Günlük Puantaj',
            subtitle: lockedHint ??
                'Gün × imalat puantajı — adam.gün ve iş gücü',
            onTap: () => context.push(workforceRoute),
          ),
          _SettingsTile(
            icon: Icons.notifications,
            title: 'Bildirim Ayarları',
            subtitle: 'Stok, sipariş, teslimat, analiz',
            onTap: () => context.push(AppRoutes.notificationSettings),
          ),
          _HapticSettingsTile(
            enabled: settings.hapticFeedback,
            onChanged: (v) =>
                ref.read(appSettingsProvider.notifier).setHapticFeedback(v),
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
          const _RebarUnitWeightTable(),
          _SettingsTile(
            icon: Icons.backup,
            title: 'Yedekleme & Geri Yükleme',
            subtitle: 'Proje verilerini JSON olarak dışa/içe aktar',
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
    required String role,
  }) {
    final user = ref.read(authProvider).user;
    final nameCtrl = TextEditingController(text: displayName);
    final professionCtrl = TextEditingController(text: profession);
    final roleCtrl = TextEditingController(text: role);
    var membershipType =
        user?.membershipType ?? MembershipType.individual;
    CorporateRole? corporateRole = user?.corporateRole;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.viewInsetsOf(ctx).bottom,
              ),
              child: SingleChildScrollView(
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
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Meslek',
                        hintText: 'Örn: İnşaat mühendisi',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: roleCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Görev (serbest metin)',
                        hintText: 'Örn: Saha mühendisi',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Üyelik tipi', style: AppTypography.titleMedium),
                    const SizedBox(height: 8),
                    SegmentedButton<MembershipType>(
                      segments: [
                        for (final type in MembershipType.values)
                          ButtonSegment(
                            value: type,
                            label: Text(type.label),
                          ),
                      ],
                      selected: {membershipType},
                      onSelectionChanged: (value) {
                        setModalState(() {
                          membershipType = value.first;
                          if (membershipType == MembershipType.individual) {
                            corporateRole = null;
                          }
                        });
                      },
                    ),
                    if (membershipType == MembershipType.corporate) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<CorporateRole>(
                        value: corporateRole,
                        decoration: const InputDecoration(
                          labelText: 'Kurumsal rol',
                        ),
                        items: [
                          for (final r in CorporateRole.values)
                            DropdownMenuItem(
                              value: r,
                              child: Text(r.label),
                            ),
                        ],
                        onChanged: (value) {
                          setModalState(() => corporateRole = value);
                        },
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () async {
                        final okProfile =
                            await ref.read(authProvider.notifier).updateProfile(
                                  displayName: nameCtrl.text,
                                  profession: professionCtrl.text,
                                  role: roleCtrl.text,
                                );
                        if (!okProfile) {
                          if (!context.mounted) return;
                          final error = ref.read(authProvider).error;
                          ScaffoldMessenger.of(context).showAppSnackBar(
                            SnackBar(
                              content: Text(error ?? 'Profil güncellenemedi'),
                            ),
                          );
                          return;
                        }

                        final okMembership = await ref
                            .read(authProvider.notifier)
                            .updateMembership(
                              membershipType: membershipType,
                              corporateRole: corporateRole,
                            );
                        if (!context.mounted) return;
                        if (okMembership) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showAppSnackBar(
                            const SnackBar(
                              content: Text('Profil ve üyelik güncellendi'),
                            ),
                          );
                        } else {
                          final error = ref.read(authProvider).error;
                          ScaffoldMessenger.of(context).showAppSnackBar(
                            SnackBar(
                              content: Text(error ?? 'Üyelik güncellenemedi'),
                            ),
                          );
                        }
                      },
                      child: const Text('Kaydet'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      nameCtrl.dispose();
      professionCtrl.dispose();
      roleCtrl.dispose();
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
    ScaffoldMessenger.of(context).showAppSnackBar(
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
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Yedekleme & Geri Yükleme', style: AppTypography.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Aktif projenin keşif, sipariş, teslimat, sayım ve metraj '
                'verilerini JSON dosyası olarak dışa/içe aktarın.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _exportProjectBackup(context, ref);
                },
                icon: const Icon(Icons.upload),
                label: const Text('Proje Verilerini Dışa Aktar'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _importProjectBackup(context, ref);
                },
                icon: const Icon(Icons.download),
                label: const Text('Proje Verilerini İçe Aktar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportProjectBackup(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(projectBackupControllerProvider).exportProject();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showAppSnackBar(
          const SnackBar(content: Text('Proje yedeği dışa aktarıldı')),
        );
      }
    } on BackupParseException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showAppSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showAppSnackBar(
          SnackBar(content: Text('Dışa aktarma hatası: $e')),
        );
      }
    }
  }

  Future<void> _importProjectBackup(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Proje Verilerini İçe Aktar'),
        content: const Text(
          'Seçilen yedek dosyası aktif projeye yazılır. Mevcut sipariş, '
          'teslimat, sayım ve keşif verileri üzerine yazılır. Devam edilsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('İçe Aktar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final summary = await ref.read(projectBackupControllerProvider).importBackup(
            expectedScope: BackupScope.project,
          );
      if (!context.mounted || summary.cancelled) return;

      ScaffoldMessenger.of(context).showAppSnackBar(
        SnackBar(
          content: Text(
            '${summary.domainCount} veri alanı içe aktarıldı'
            '${summary.projectName != null ? ' (${summary.projectName})' : ''}',
          ),
        ),
      );
    } on BackupParseException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showAppSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showAppSnackBar(
          SnackBar(content: Text('İçe aktarma hatası: $e')),
        );
      }
    }
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
                ScaffoldMessenger.of(ctx).showAppSnackBar(
                  const SnackBar(content: Text('PIN 4–8 haneli olmalıdır')),
                );
                return;
              }
              if (newPin != confirm) {
                ScaffoldMessenger.of(ctx).showAppSnackBar(
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
        ScaffoldMessenger.of(context).showAppSnackBar(
          const SnackBar(content: Text('PIN kilidi etkinleştirildi')),
        );
      } else {
        ScaffoldMessenger.of(context).showAppSnackBar(
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
      ScaffoldMessenger.of(context).showAppSnackBar(
        const SnackBar(content: Text('PIN kilidi kapatıldı')),
      );
    } else {
      ScaffoldMessenger.of(context).showAppSnackBar(
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
                      ScaffoldMessenger.of(context).showAppSnackBar(
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
                      ScaffoldMessenger.of(context).showAppSnackBar(
                        const SnackBar(content: Text('PIN güncellendi')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showAppSnackBar(
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
    required this.role,
    required this.membershipLabel,
    required this.initial,
    required this.projectName,
    required this.onEdit,
  });

  final String displayName;
  final String profession;
  final String role;
  final String membershipLabel;
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
                    Text(
                      membershipLabel,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.electricBlueLight,
                      ),
                    ),
                    if (profession.isNotEmpty)
                      Text(profession, style: AppTypography.bodySmall),
                    if (role.isNotEmpty)
                      Text(role, style: AppTypography.bodySmall),
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

class _HapticSettingsTile extends StatelessWidget {
  const _HapticSettingsTile({
    required this.enabled,
    required this.onChanged,
  });

  final bool enabled;
  final ValueChanged<bool> onChanged;

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
          const Icon(
            Icons.vibration,
            color: AppColors.electricBlueLight,
            size: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dokunma Titreşimi', style: AppTypography.titleMedium),
                Text(
                  enabled
                      ? 'Kart ve seçimlerde titreşim açık'
                      : 'Titreşim kapalı',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _RebarUnitWeightTable extends StatelessWidget {
  const _RebarUnitWeightTable();

  @override
  Widget build(BuildContext context) {
    final weightFormat = NumberFormat('#,##0.###', 'tr_TR');
    final diameters = RebarWeightCalculator.standardDiameters;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.table_chart_outlined,
                color: AppColors.electricBlueLight,
                size: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Demir Birim Hacim Ağırlık Tablosu',
                      style: AppTypography.titleMedium,
                    ),
                    Text(
                      'kg/m = d² / 162',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.canvas.withValues(alpha: 0.55),
              borderRadius: AppRadii.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Çap (mm)',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Birim ağırlık (kg/m)',
                    textAlign: TextAlign.right,
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < diameters.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: AppColors.border.withValues(alpha: 0.7),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ø${diameters[i]}',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      weightFormat.format(
                        RebarWeightCalculator.kgPerMeter(diameters[i]),
                      ),
                      textAlign: TextAlign.right,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.electricBlueLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            Image.asset(
              'assets/images/splash_bolt.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
            const SizedBox(height: 4),
            Text('ŞantiJET DEMİR', style: AppTypography.headlineLarge),
            const SizedBox(height: 8),
            Text('Versiyon 1.0.0', style: AppTypography.bodyMedium),
            const SizedBox(height: 24),
            Text(
              'Demir keşfi, sipariş, teslimat, stok takibi, fire analizi '
              've optimum kesim analizi yapan profesyonel ve özgün '
              'nervürlü demir takip uygulaması.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
