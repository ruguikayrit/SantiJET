import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/program_project.dart';
import '../../state/app_state.dart';
import '../../state/license_state.dart';
import '../../ui/design_system.dart';
import 'settings_scaffold.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  late final TextEditingController _name;
  late final TextEditingController _role;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _name = TextEditingController(text: profile.displayName);
    _role = TextEditingController(text: profile.role);
  }

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(profileProvider.notifier).save(
      LocalProfile(
        displayName: _name.text.trim(),
        role: _role.text.trim(),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hesap bilgileri kaydedildi.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final license = ref.watch(licenseProvider);

    return SettingsScaffold(
      title: 'Hesap',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          SJCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cihazdaki profil',
                  style: AppTypography.onCard(AppTypography.headlineMedium),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ad ve unvan bu telefonda kalır. Giriş, hesap veya bulut yoktur.',
                  style: AppTypography.cardBodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Ad soyad',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _role,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Unvan',
                    hintText: 'Şef, kontrollük, planlama…',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SJButton(label: 'Kaydet', onPressed: _save, expanded: true),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
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
        ],
      ),
    );
  }
}
