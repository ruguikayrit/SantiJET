import 'package:flutter/material.dart';

import '../../ui/design_system.dart';
import 'settings_scaffold.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: 'Hakkında',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
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
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Sürüm ${AppInfo.version}',
                  style: AppTypography.cardTitleMedium,
                ),
                const SizedBox(height: 4),
                Text(AppInfo.pricingLine, style: AppTypography.cardBodySmall),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SJCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Destek', style: AppTypography.cardTitleMedium),
                const SizedBox(height: 6),
                Text(
                  AppInfo.supportEmail,
                  style: AppTypography.cardBodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
