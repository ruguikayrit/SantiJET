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
import 'package:santijet_demir/features/auth/providers/auth_provider.dart';
import 'package:santijet_demir/features/demo/demo_seed_provider.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/settings/providers/profile_provider.dart';
import 'package:santijet_demir/features/settings/providers/backup_provider.dart';
import 'package:santijet_demir/core/widgets/santijet_header.dart';
import 'package:santijet_demir/features/settings/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final project = ref.watch(activeProjectProvider);
    final displayName = ref.watch(profileDisplayNameProvider);
    final profession = ref.watch(profileProfessionProvider);
    final email = ref.watch(profileEmailProvider);
    final phone = ref.watch(profilePhoneProvider);
    final initial = ref.watch(profileInitialProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Column(
        children: [
          const DemirBrandHeader(
            title: 'Ayarlar',
            showBack: true,
            showSettings: false,
          ),
          Expanded(
            child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _ProfileHeader(
            displayName: displayName,
            profession: profession,
            email: email,
            phone: phone,
            initial: initial,
            onEdit: () => _showProfileEditor(
              context,
              ref,
              displayName: displayName,
              profession: profession,
              email: email,
              phone: phone,
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
            icon: Icons.architecture_outlined,
            title: 'Otomatik Metraj',
            subtitle: 'CAD dosyasından metraj',
            onTap: () => context.push(AppRoutes.metraj),
          ),
          _SettingsTile(
            icon: Icons.analytics_outlined,
            title: 'Analiz',
            subtitle: 'Hesap, kesim ve fire',
            onTap: () => context.push(AppRoutes.analysis),
          ),
          _SettingsTile(
            icon: Icons.dark_mode,
            title: 'Tema',
            subtitle: _themeLabel(settings.themeMode),
            onTap: () => _showThemePicker(context, ref),
          ),
          const _RebarUnitWeightTable(),
          _SettingsTile(
            icon: Icons.backup,
            title: 'Yedekleme & Geri Yükleme',
            subtitle: 'Proje verilerini JSON olarak dışa/içe aktar',
            onTap: () => _showBackupDialog(context, ref),
          ),
          const _DemoLoadSettingsTile(),
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
    required String email,
    required String phone,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      builder: (ctx) => _ProfileEditorSheet(
        displayName: displayName,
        profession: profession,
        email: email,
        phone: phone,
      ),
    );
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
        _ => 'Koyu',
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

}

class _DemoLoadSettingsTile extends ConsumerStatefulWidget {
  const _DemoLoadSettingsTile();

  @override
  ConsumerState<_DemoLoadSettingsTile> createState() =>
      _DemoLoadSettingsTileState();
}

class _DemoLoadSettingsTileState extends ConsumerState<_DemoLoadSettingsTile> {
  bool _busy = false;

  Future<void> _confirmAndLoad() async {
    if (_busy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Demo veriyi yükle'),
        content: const Text(
          'Demo Şantiye\'deki tüm kayıtlar silinir ve sıfırdan kurulur: '
          '4 imalat (A–D blok keşif), 4 sipariş, 2 teslimat, 2 saha sayımı '
          've Kolon CAD metrajı. Aktif proje Demo Şantiye olur. Devam edilsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yükle'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      final project =
          await ref.read(demoSeedControllerProvider).loadAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showAppSnackBar(
        SnackBar(
          content: Text(
            'Demo yüklendi: ${project.name}. Ana Sayfa ve sekmelerden test edin.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showAppSnackBar(
        SnackBar(content: Text('Demo yüklenemedi: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: Icons.dataset_outlined,
      title: 'Demo veriyi yükle',
      subtitle: _busy
          ? 'Yükleniyor…'
          : 'Eski demo silinir · yeni senaryo yüklenir',
      onTap: _busy ? () {} : _confirmAndLoad,
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.displayName,
    required this.profession,
    required this.email,
    required this.phone,
    required this.initial,
    required this.onEdit,
  });

  final String displayName;
  final String profession;
  final String email;
  final String phone;
  final String initial;
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
                    if (profession.isNotEmpty)
                      Text(profession, style: AppTypography.bodySmall),
                    if (email.isNotEmpty)
                      Text(email, style: AppTypography.bodySmall),
                    if (phone.isNotEmpty)
                      Text(phone, style: AppTypography.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.edit_outlined, color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}


class _RebarUnitWeightTable extends StatefulWidget {
  const _RebarUnitWeightTable();

  @override
  State<_RebarUnitWeightTable> createState() => _RebarUnitWeightTableState();
}

class _RebarUnitWeightTableState extends State<_RebarUnitWeightTable> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final weightFormat = NumberFormat('#,##0.###', 'tr_TR');
    final diameters = RebarWeightCalculator.standardDiameters;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                child: Row(
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
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
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
                                RebarWeightCalculator.kgPerMeter(
                                  diameters[i],
                                ),
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
              Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileEditorSheet extends ConsumerStatefulWidget {
  const _ProfileEditorSheet({
    required this.displayName,
    required this.profession,
    required this.email,
    required this.phone,
  });

  final String displayName;
  final String profession;
  final String email;
  final String phone;

  @override
  ConsumerState<_ProfileEditorSheet> createState() => _ProfileEditorSheetState();
}

class _ProfileEditorSheetState extends ConsumerState<_ProfileEditorSheet> {
  late final TextEditingController _nameCtrl = TextEditingController(text: widget.displayName);
  late final TextEditingController _professionCtrl = TextEditingController(text: widget.profession);
  late final TextEditingController _emailCtrl = TextEditingController(text: widget.email);
  late final TextEditingController _phoneCtrl = TextEditingController(text: widget.phone);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _professionCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Profil Bilgileri', style: AppTypography.headlineMedium),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Ad Soyad'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _professionCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Meslek',
                hintText: 'Örn: İnşaat mühendisi',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Mail adresi'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Telefon numarası'),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _save,
              child: const Text('Kaydet'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Çıkış Yap'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final okProfile = await ref.read(authProvider.notifier).updateProfile(
          displayName: _nameCtrl.text,
          profession: _professionCtrl.text,
          role: ref.read(profileRoleProvider),
        );
    if (!mounted) return;
    if (!okProfile) {
      final error = ref.read(authProvider).error;
      ScaffoldMessenger.of(context).showAppSnackBar(
        SnackBar(content: Text(error ?? 'Profil güncellenemedi')),
      );
      return;
    }
    await ref.read(appSettingsProvider.notifier).updateCompany(
          contactEmail: _emailCtrl.text.trim(),
          contactPhone: _phoneCtrl.text.trim(),
        );
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showAppSnackBar(const SnackBar(content: Text('Profil güncellendi')));
  }

  Future<void> _logout() async {
    final router = GoRouter.of(context);
    await ref.read(authProvider.notifier).logout();
    if (!mounted) {
      router.go(AppRoutes.login);
      return;
    }
    Navigator.pop(context);
    router.go(AppRoutes.login);
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Column(
        children: [
          const DemirBrandHeader(
            title: 'Hakkında',
            showBack: true,
            showSettings: false,
          ),
          Expanded(
            child: Padding(
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
          ),
        ],
      ),
    );
  }
}
