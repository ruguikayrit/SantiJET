import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/backup/program_backup.dart';
import '../../state/app_state.dart';
import '../../ui/design_system.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final project = ref.watch(activeProjectProvider);
    final profile = ref.watch(profileProvider);

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
          _SettingsTile(
            icon: Icons.account_circle_outlined,
            title: 'Hesap',
            subtitle: profile.isEmpty
                ? 'Cihazdaki ad ve unvan — giriş yok'
                : [
                    if (profile.displayName.trim().isNotEmpty)
                      profile.displayName.trim(),
                    if (profile.role.trim().isNotEmpty) profile.role.trim(),
                  ].join(' · '),
            onTap: () => context.push('/settings/hesap'),
          ),
          _SettingsTile(
            icon: Icons.qr_code_2_outlined,
            title: 'İş kodu',
            subtitle: project == null
                ? 'Şantiye kodunu gör veya koda geç'
                : project.code,
            onTap: () => context.push('/settings/is-kodu'),
          ),
          _SettingsTile(
            icon: Icons.folder_copy_outlined,
            title: 'Projelerim',
            subtitle: project?.name ?? 'Proje seç veya oluştur',
            onTap: () => context.push('/settings/projeler'),
          ),
          _SettingsTile(
            icon: Icons.dark_mode_outlined,
            title: 'Tema',
            subtitle: themeLabel(themeMode),
            onTap: () => _showThemePicker(context, ref, themeMode),
          ),
          _SettingsTile(
            icon: Icons.backup_outlined,
            title: 'Yedekleme',
            subtitle: 'Programı JSON olarak cihaza kaydet',
            onTap: () => _exportBackup(context, ref),
          ),
          _SettingsTile(
            icon: Icons.settings_backup_restore_outlined,
            title: 'Geri yükleme',
            subtitle: 'JSON yedekten programı geri yaz',
            onTap: () => _importBackup(context, ref),
          ),
          _SettingsTile(
            icon: Icons.swap_vert_rounded,
            title: 'MS Project · Excel · PDF',
            subtitle: 'İş programı dosya alışverişi',
            onTap: () => context.push('/aktar'),
          ),
          _SettingsTile(
            icon: Icons.play_circle_outline,
            title: 'Uygulama tanıtımı',
            subtitle: 'Adam-gün, saha kaydı ve mukayese',
            onTap: () => context.push('/settings/tanitim'),
          ),
          _SettingsTile(
            icon: Icons.science_outlined,
            title: 'Demo veriyi yükle',
            subtitle: 'İki şantiye, imalat ve günlük adam kaydı',
            onTap: () => _loadDemo(context, ref),
          ),
          _SettingsTile(
            icon: Icons.info_outline,
            title: 'Hakkında',
            subtitle: '${AppInfo.displayName} v${AppInfo.version}',
            onTap: () => context.push('/settings/hakkinda'),
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.delete_forever_outlined,
            title: 'Tüm veriyi sil',
            subtitle: 'Projeler, imalatlar ve saha kayıtları silinir',
            destructive: true,
            onTap: () => _clearData(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _showThemePicker(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final next = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in const [
              ('santijet_pro', 'ŞantiJET Pro'),
              ('santijet', 'ŞantiJET'),
              ('light', 'Açık'),
              ('dark', 'Koyu'),
            ])
              ListTile(
                title: Text(option.$2),
                trailing: current == option.$1
                    ? Icon(Icons.check, color: AppColors.electricBlue)
                    : null,
                onTap: () => Navigator.pop(context, option.$1),
              ),
          ],
        ),
      ),
    );
    if (next != null) await ref.read(themeModeProvider.notifier).select(next);
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    try {
      final backup = ProgramBackup(
        projects: ref.read(projectsProvider),
        items: ref.read(programItemsProvider),
        dailyCrew: ref.read(dailyCrewProvider),
        profile: ref.read(profileProvider),
        activeProjectId: ref.read(activeProjectProvider)?.id,
        themeMode: ref.read(themeModeProvider),
      );
      await FileSaver.instance.saveFile(
        name: 'santijet-is-programi-yedek',
        bytes: backup.encode(),
        fileExtension: 'json',
        mimeType: MimeType.json,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yedek dosyası hazırlandı.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yedek alınamadı: $error')),
        );
      }
    }
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final accepted = await _confirm(
      context,
      title: 'Yedek geri yüklensin mi?',
      message: 'Mevcut projeler ve imalatlar bu dosyayla değişir.',
      action: 'Geri yükle',
    );
    if (!accepted) return;
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: 'İş Programı yedeği seç',
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (file == null) return;
      final backup = ProgramBackup.decode(await file.readAsBytes());
      await ref.read(programItemsProvider.notifier).replaceItems(backup.items);
      await ref.read(dailyCrewProvider.notifier).replaceAll(backup.dailyCrew);
      await ref.read(projectsProvider.notifier).replaceAll(
        backup.projects,
        activeProjectId: backup.activeProjectId,
      );
      await ref.read(profileProvider.notifier).save(backup.profile);
      if (backup.themeMode != null) {
        await ref.read(themeModeProvider.notifier).select(backup.themeMode!);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yedek geri yüklendi.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Geri yükleme olmadı: $error')),
        );
      }
    }
  }

  Future<void> _loadDemo(BuildContext context, WidgetRef ref) async {
    final accepted = await _confirm(
      context,
      title: 'Demo veri yüklensin mi?',
      message: 'Mevcut imalatlar silinip örnek program yazılacak.',
      action: 'Yükle',
    );
    if (!accepted) return;
    await ref.read(programItemsProvider.notifier).loadDemo();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demo program yüklendi.')),
      );
    }
  }

  Future<void> _clearData(BuildContext context, WidgetRef ref) async {
    final accepted = await _confirm(
      context,
      title: 'Tüm veriler silinsin mi?',
      message: 'Projeler, imalatlar ve saha kayıtları kalıcı olarak silinir.',
      action: 'Tümünü sil',
    );
    if (!accepted) return;
    await ref.read(programItemsProvider.notifier).clear();
    await ref.read(projectsProvider.notifier).resetToDefault();
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
    final titleColor = destructive
        ? AppColors.critical
        : AppColors.cardTextPrimary;
    final subColor = destructive
        ? AppColors.critical.withValues(alpha: 0.8)
        : AppColors.cardTextSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SJCard(
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
      ),
    );
  }
}
