import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/animations/app_animations.dart';
import '../../core/constants/app_info.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/collaboration_provider.dart';

/// ŞantiJET Puantaj açılış ekranı — Demir splash ile birebir; ürün adı PUANTAJ.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _wordmarkAspect = 895 / 150;
  static const _boltWordmarkGap = 28.0;
  static const _boltWordmarkGapReduced = _boltWordmarkGap * 0.3;
  static const _wordmarkAnchorCompensation = _boltWordmarkGap * 0.35;

  late final AnimationController _loadingController;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final delay = Future<void>.delayed(const Duration(milliseconds: 1600));
    try {
      await ref.read(authProvider.notifier).restoreSession();
      if (ref.read(authProvider).isAuthenticated) {
        await ref.read(collaborationControllerProvider).pullMyProjects();
      }
    } catch (_) {
      // Splash'ı offline devam ettir.
    }
    await delay;
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final boltSize = (screenWidth * 0.76).clamp(280.0, 440.0);
    final wordmarkWidth = (screenWidth * 0.78).clamp(260.0, 360.0);
    final wordmarkHeight = wordmarkWidth / _wordmarkAspect;

    return Theme(
      data: AppTheme.dark,
      child: Scaffold(
        backgroundColor: AppColors.darkCanvas,
        body: ColoredBox(
          color: AppColors.darkCanvas,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _BlueprintGridPainter()),
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: 0.04,
                  child: CustomPaint(painter: _RebarOverlayPainter()),
                ),
              ),
              SafeArea(
                bottom: false,
                minimum: EdgeInsets.zero,
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  height: _wordmarkAnchorCompensation,
                                ),
                                FadeIn(
                                  delay: const Duration(milliseconds: 150),
                                  child: Image.asset(
                                    'assets/images/splash_bolt.png',
                                    width: boltSize,
                                    height: boltSize,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                                const SizedBox(height: _boltWordmarkGapReduced),
                                FadeIn(
                                  delay: const Duration(milliseconds: 350),
                                  child: Image.asset(
                                    'assets/images/splash_wordmark.png',
                                    width: wordmarkWidth,
                                    height: wordmarkHeight,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                                const SizedBox(
                                  height: AppSpacing.splashWordmarkToDemir,
                                ),
                                FadeIn(
                                  delay: const Duration(milliseconds: 550),
                                  child: Text(
                                    AppInfo.productLabel,
                                    style: AppTypography.displayLarge.copyWith(
                                      color: AppColors.electricBlue,
                                      letterSpacing: 6,
                                      shadows: const [
                                        Shadow(
                                          color: AppColors.electricBlueGlow,
                                          blurRadius: 24,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _loadingController,
                      builder: (context, child) {
                        return Container(
                          width: 130,
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: AppColors.darkBorder,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x660055FF),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Align(
                            alignment: Alignment(
                              _loadingController.value * 2 - 1,
                              0,
                            ),
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.electricBlue,
                                    AppColors.electricBlueLight,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(
                      height: MediaQuery.viewPaddingOf(context).bottom +
                          AppSpacing.lg,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlueprintGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.blueprintGrid
      ..strokeWidth = 0.5;

    const spacing = 24.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RebarOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0AFFFFFF)
      ..strokeWidth = 2;

    for (var i = 0; i < 6; i++) {
      final y = size.height * 0.15 + i * 80;
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 40), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
