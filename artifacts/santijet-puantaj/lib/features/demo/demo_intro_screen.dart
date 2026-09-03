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
      title: 'ŞantiJET SAHA ne işe yarar?',
      body:
          'Saha puantajı, imalat kaydı, günlük şantiye raporu ve görev '
          'takibini aynı projede tutar. Kayıtlar cihazda (Hive); ağ yokken '
          'de çalışır. Bulut senkron bu sürümde zorunlu değil.',
      accent: AppColors.electricBlue,
    ),
    _IntroPageData(
      icon: Icons.fact_check_outlined,
      title: 'Puantaj',
      body:
          'Günlük cetvelde personel durumunu işaretlersiniz (G/Ç/M/Y/X…). '
          'Çıkış, işten çıkış tarihini personel kartına yazar; ertesi gün '
          'listeden düşer. Haftalık/aylıkta ekip adam-gün ve yevmiyeli '
          'tabloları çıkar. Puantaj AL → PDF veya Excel.',
      accent: AppColors.info,
    ),
    _IntroPageData(
      icon: Icons.construction_outlined,
      title: 'İmalat ve verim',
      body:
          'İşe plan metraj, süre ve iş gücü tanımlarsınız; her güne '
          'gerçekleşen miktar ve adam girersiniz. Kartta plan–gerçek '
          'karşılaştırması ve birim verim (ör. m²/adam-gün) hesaplanır. '
          'Verim sekmesi işleri yüzdeye göre sıralar.',
      accent: AppColors.success,
    ),
    _IntroPageData(
      icon: Icons.description_outlined,
      title: 'Günlük / dönem raporu',
      body:
          'Rapor sekmesi o günün şantiye formudur: hava, puantaj özeti, '
          'fotoğraf, yapılan–planlı iş (İnşaat / Elektrik / Mekanik), '
          'gelen–giden–sipariş malzeme, makine ve vasıta. Gelen malzeme '
          'için irsaliye fotoğrafı + OCR satır üretebilir. Haftalık ve '
          'aylık görünümde bölümler kapalı; açınca dönem özeti. Rapor AL.',
      accent: AppColors.warning,
    ),
    _IntroPageData(
      icon: Icons.task_alt_outlined,
      title: 'Görev',
      body:
          'Her görevde kategori ve etiket gerekir. Durum: Yapılacak → '
          'Başlandı → Devam → Tamamlandı. Başlangıç / bitiş için Dün, '
          'Bugün veya özel tarih. Atananı değiştirince atayana onay '
          'düşer. 1. derece meslek (şef, mühendis…) görev atayabilir; '
          'formen ve altı yalnızca kendine atananı görür.',
      accent: AppColors.partial,
    ),
    _IntroPageData(
      icon: Icons.science_outlined,
      title: 'Örnek veri (demo)',
      body:
          '“Demo Şantiye” projesi açılır: personel, birkaç günlük '
          'puantaj, imalat satırları, rapor ve örnek görevler doldurulur. '
          'Boş şantiye kurmadan ekranları dolaşmak içindir. Bitince '
          'Ayarlar’dan silip kendi projenizi ekleyebilirsiniz.',
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
                          textAlign: TextAlign.left,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.5,
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
                        _loading
                            ? 'Örnek veri yükleniyor…'
                            : 'Örnek veriyi yükle',
                      ),
                    )
                  else
                    FilledButton(
                      onPressed: () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOut,
                      ),
                      child: const Text('Sonraki'),
                    ),
                  if (!isLast) ...[
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: _startDemo,
                      child: const Text('Metni atla, örnek veriyi yükle'),
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
