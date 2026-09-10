import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      body: Column(
        children: [
          const SantijetHeader(title: 'AYARLAR', showBack: true),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
              children: [
                _Section(
                  title: 'GÖRÜNÜM',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.contrast_rounded),
                      title: const Text('Tema'),
                      trailing: DropdownButton<ThemeMode>(
                        value: themeMode,
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(
                            value: ThemeMode.system,
                            child: Text('Sistem'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.light,
                            child: Text('Açık'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.dark,
                            child: Text('Koyu'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            ref.read(themeModeProvider.notifier).select(value);
                          }
                        },
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.apartment_rounded),
                      title: const Text('Varsayılan şantiye'),
                      subtitle: Text(activeSite),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.chevron_right_rounded),
                        onSelected: (value) =>
                            ref.read(activeSiteProvider.notifier).select(value),
                        itemBuilder: (context) => sites
                            .map(
                              (site) =>
                                  PopupMenuItem(value: site, child: Text(site)),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _Section(
                  title: 'VERİ',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.auto_awesome_outlined),
                      title: const Text('Demo veri'),
                      subtitle: const Text('10 örnek faaliyet yükle'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _loadDemo(context, ref),
                    ),
                    ListTile(
                      leading: Icon(
                        Icons.delete_sweep_outlined,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: Text(
                        'Tüm veriyi sil',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      onTap: () => _clearData(context, ref),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _Section(
                  title: 'LİSANS',
                  children: [
                    ListTile(
                      leading: Icon(
                        license.licensed
                            ? Icons.verified_rounded
                            : Icons.workspace_premium_outlined,
                        color: license.licensed
                            ? AppColors.success
                            : AppColors.electricBlue,
                      ),
                      title: Text(
                        license.licensed
                            ? 'Tek seferlik lisans etkin'
                            : 'Tek seferlik lisans',
                      ),
                      subtitle: Text(
                        license.message ??
                            license.product?.price ??
                            'Abonelik yok. Bir kez satın alın.',
                      ),
                      trailing: license.loading
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : license.licensed
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.success,
                            )
                          : TextButton(
                              onPressed: license.product == null
                                  ? null
                                  : () => ref
                                        .read(licenseProvider.notifier)
                                        .buy(),
                              child: const Text('Satın al'),
                            ),
                    ),
                    if (!license.licensed)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: license.storeAvailable
                              ? () =>
                                    ref.read(licenseProvider.notifier).restore()
                              : null,
                          child: const Text('Satın almayı geri yükle'),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _Section(
                  title: 'UYGULAMA',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info_outline_rounded),
                      title: const Text('Hakkında'),
                      subtitle: const Text('ŞantiJET İş Programı · v1.0.0'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => showAboutDialog(
                        context: context,
                        applicationName: 'ŞantiJET İş Programı',
                        applicationVersion: '1.0.0',
                        applicationLegalese: 'Planı sade tut. Sahada takip et.',
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
          title: Text(title),
          content: Text(message),
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SJCard(
    padding: const EdgeInsets.fromLTRB(6, 14, 6, 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: AppTypography.displayFont,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(height: 4),
        ...children,
      ],
    ),
  );
}
