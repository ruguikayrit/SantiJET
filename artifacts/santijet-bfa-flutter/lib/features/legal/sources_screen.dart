import 'package:flutter/material.dart';

import '../../core/constants/official_sources.dart';
import '../../core/design_system/design_system.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/services/link_service.dart';

/// Resmi kaynaklar ekranı.
class SourcesScreen extends StatelessWidget {
  const SourcesScreen({super.key});

  Future<void> _open(BuildContext context, OfficialSourceLink link) async {
    final ok = await SJModal.confirm(
      context: context,
      title: 'Resmi Kaynak',
      message: 'Resmi kurum yayını tarayıcıda açılacaktır.',
      confirmLabel: 'Aç',
    );
    if (!ok || !context.mounted) return;
    try {
      await linkService.openExternal(link.url);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bağlantı açılamadı: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Kaynaklar')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            SJCard(
              accentColor: AppColors.info,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Veri Doğrulama', style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    OfficialSources.verificationText,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    OfficialSources.distributionNotice,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final link in officialSourceLinks) ...[
              SJListItem(
                title: link.title,
                subtitle: '${link.subtitle}\n→ Resmi Kaynağı Aç',
                leadingIcon: Icons.open_in_browser,
                accentColor: AppColors.electricBlueLight,
                onTap: () => _open(context, link),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
          ],
        ),
      ),
    );
  }
}
