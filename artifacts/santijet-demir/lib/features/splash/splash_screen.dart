import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/animations/app_animations.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_shadows.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/features/auth/providers/auth_provider.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';

/// ŞantiJET DEMİR açılış ekranı — referans logo + wordmark + DEMİR.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _wordmarkAspect = 1774 / 514;

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
    try {
      await ref
          .read(authProvider.notifier)
          .restoreSession()
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      // Ağ/Supabase yanıt vermezse yerel modda devam et.
    }

    if (!mounted) return;
    final auth = ref.read(authProvider);

    if (auth.isAuthenticated && auth.usesSupabase) {
      try {
        await ref
            .read(projectsControllerProvider)
            .refreshFromCloud()
            .timeout(const Duration(seconds: 10));
        await ref
            .read(projectsControllerProvider)
            .ensureMigratedFromLegacy()
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        // Bulut senkronu başarısız — yerel veri ile devam.
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final latestAuth = ref.read(authProvider);
    if (!latestAuth.isAuthenticated) {
      context.go(AppRoutes.login);
      return;
    }

    final activeProjectId = ref.read(activeProjectIdProvider);
    if (activeProjectId != null) {
      context.go(AppRoutes.dashboard);
    } else {
      context.go(AppRoutes.projects);
    }
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

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _BlueprintGridPainter(),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.04,
              child: CustomPaint(
                painter: _RebarOverlayPainter(),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                          const SizedBox(height: 28),
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
                          const SizedBox(height: AppSpacing.splashWordmarkToDemir),
                          FadeIn(
                            delay: const Duration(milliseconds: 550),
                            child: Text(
                              'DEMİR',
                              style: AppTypography.displayLarge.copyWith(
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
                AnimatedBuilder(
                  animation: _loadingController,
                  builder: (context, child) {
                    return Container(
                      width: 130,
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: AppColors.border,
                        boxShadow: AppShadows.loadingBarGlow,
                      ),
                      child: Align(
                        alignment: Alignment(_loadingController.value * 2 - 1, 0),
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
                const SizedBox(height: AppSpacing.splashBottomSafe),
              ],
            ),
          ),
        ],
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
      ..color = AppColors.rebarOverlay
      ..strokeWidth = 2;

    for (var i = 0; i < 6; i++) {
      final y = size.height * 0.15 + i * 80;
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 40), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
