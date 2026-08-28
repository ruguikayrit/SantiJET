import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_info.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/providers/demo_intro_provider.dart';
import '../../data/providers/demo_seed_provider.dart';

class DemoIntroScreen extends ConsumerStatefulWidget {
  const DemoIntroScreen({super.key});

  @override
  ConsumerState<DemoIntroScreen> createState() => _DemoIntroScreenState();
}

class _DemoIntroScreenState extends ConsumerState<DemoIntroScreen> {
  final _pageController = PageController();
  int _page = 0;
  bool _loading = false;

  static const _pages = <_IntroPageData>[
    _IntroPageData(
      icon: Icons.apartment_outlined,
      title: 'Şantiyeyi tek uygulamada yönetin',
      body:
          'ŞantiJET SAHA; personel puantajı, imalat takibi, verim analizi, '
          'günlük saha raporu ve görevleri bir arada tutar. İnternetsiz '
          'çalışır; veriler cihazınızda kalır.',
      accent: AppColors.electricBlue,
    ),
    _IntroPageData(
      icon: Icons.fact_check_outlined,
      title: 'Puantaj — kim sahadaydı?',
      body:
          'Kayıtlı personel için Mevcut / Yarım / İzinli / Raporlu gibi '
          'durumlar. Sigortasız ekip ve yevmiyeli işçi tabloları. '
          'Haftalık ve aylık cetvel + PDF dışa aktarım.',
      accent: AppColors.info,
    ),
    _IntroPageData(
      icon: Icons.construction_outlined,
      title: 'İmalat & Verim — ne kadar ilerledik?',
      body:
          'Her imalat için plan metraj, süre ve iş gücü girin; günlük '
          'kayıtlarla gerçekleşeni takip edin. Metraj · süre · adam-gün '
          'üçlü bar ve birim verim yüzdesi otomatik hesaplanır.',
      accent: AppColors.success,
    ),
    _IntroPageData(
      icon: Icons.description_outlined,
      title: 'Rapor & Görevler — saha ile ofis aynı sayfada',
      body:
          'Günlük raporda hava, fotoğraf, malzeme, makine ve puantaj '
          'özeti. Görevler Satın Alma / Saha / Ofis kategorilerinde; '
          'acil işler ana sayfada öne çıkar.',
      accent: AppColors.warning,
    ),
    _IntroPageData(
      icon: Icons.science_outlined,
      title: 'Demo ile keşfedin',
      body:
          '“Demo Şantiye” projesi tüm modülleri doldurulmuş halde açılır: '
          '10 personel, 4 imalat, 6 günlük rapor, görevler ve plan bulutu. '
          'Ana sayfadaki rehber kartından modüllere geçebilirsiniz.',
      accent: AppColors.electricBlueLight,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _startDemo() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await ref.read(demoSeedControllerProvider).loadAll();
      ref.read(demoIntroProvider.notifier).completeIntro(showGuide: true);
      if (!mounted) return;
      context.go(AppRoutes.home);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Demo yüklenemedi: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _skip() {
    ref.read(demoIntroProvider.notifier).completeIntro(showGuide: false);
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _page == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: Row(
                children: [
                  Text(
                    AppInfo.productLabel,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.electricBlue,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  TextButton(onPressed: _skip, child: const Text('Atla')),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: p.accent.withValues(alpha: 0.15),
                            borderRadius: AppRadii.lg,
                            border: Border.all(
                              color: p.accent.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Icon(p.icon, size: 44, color: p.accent),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          p.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          p.body,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.lg,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _pages.length; i++)
                        Container(
                          width: i == _page ? 22 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            borderRadius: AppRadii.full,
                            color: i == _page
                                ? AppColors.electricBlue
                                : AppColors.border,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (isLast)
                    FilledButton.icon(
                      onPressed: _loading ? null : _startDemo,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        _loading ? 'Demo hazırlanıyor…' : 'Demo ile keşfet',
                      ),
                    )
                  else
                    FilledButton(
                      onPressed: () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOut,
                      ),
                      child: const Text('Devam'),
                    ),
                  if (!isLast) ...[
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: _startDemo,
                      child: const Text('Doğrudan demo yükle'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroPageData {
  const _IntroPageData({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color accent;
}
