import 'package:flutter/material.dart';

import '../../ui/design_system.dart';
import 'settings_scaffold.dart';

class AppIntroScreen extends StatelessWidget {
  const AppIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsScaffold(
      title: 'Uygulama tanıtımı',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          Text(
            AppInfo.tagline,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _IntroCard(
            icon: Icons.timelapse_rounded,
            title: 'Plan adam-gündür',
            body:
                'İmalat adı, başlangıç, süre (gün) ve ekip (adam) yazılır. '
                'Bitiş süreye göre hesaplanır. Birim: süre × ekip = adam-gün.',
          ),
          const _IntroCard(
            icon: Icons.groups_outlined,
            title: 'Saha kaydı',
            body:
                'Her gün “bugün kaç adam çalıştı?” sorusu yazılır. '
                'İlerleme yüzdesi bu kayıtlardan doğar; kaydırıcı ile '
                'ilerleme girilmez.',
          ),
          const _IntroCard(
            icon: Icons.compare_arrows_rounded,
            title: 'Mukayese',
            body:
                'Özet, plan AG / gerçek AG / kalan AG gösterir. Kalan, '
                'işçilik ve nakit ihtiyacına işarettir; ödeme veya satınalma '
                'tutulmaz.',
          ),
          const _IntroCard(
            icon: Icons.swap_vert_rounded,
            title: 'Aktarım',
            body:
                'MS Project XML ve Excel gidip gelir. PDF yalnız rapordur. '
                '.mpp okunmaz; Project içinde XML olarak kaydedilir.',
          ),
          const _IntroCard(
            icon: Icons.phonelink_lock_outlined,
            title: 'Cihazda kalır',
            body:
                'Projeler, iş kodu ve yedek bu telefonda tutulur. Giriş, '
                'bulut veya abonelik yoktur. Lisans tek seferliktir.',
          ),
        ],
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SJCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.electricBlue),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.cardTitleMedium),
                  const SizedBox(height: 4),
                  Text(body, style: AppTypography.cardBodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
