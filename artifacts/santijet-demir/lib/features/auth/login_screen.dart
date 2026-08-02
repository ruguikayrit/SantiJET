import 'package:flutter/material.dart';
import 'package:santijet_demir/core/widgets/app_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/config/supabase_config.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/features/auth/providers/auth_provider.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _loading = true);
    try {
      final ok = await ref.read(authProvider.notifier).login(
            email: _emailCtrl.text,
            password: _passwordCtrl.text,
          );
      if (!context.mounted) return;

      if (!ok) {
        final error = ref.read(authProvider).error;
        messenger.showAppSnackBar(
          SnackBar(content: Text(error ?? 'Giriş başarısız')),
        );
        return;
      }

      if (ref.read(authProvider).usesSupabase) {
        try {
          await ref
              .read(projectsControllerProvider)
              .refreshFromCloud()
              .timeout(const Duration(seconds: 15));
        } catch (_) {
          messenger.showAppSnackBar(
            const SnackBar(
              content: Text(
                'Giriş başarılı. Proje senkronu tamamlanamadı; Projelerim ekranından devam edebilirsiniz.',
              ),
            ),
          );
        }
      }

      router.go(AppRoutes.projects);
    } finally {
      if (context.mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final wordmarkAsset = AppColors.wordmarkAssetFor(brightness);
    // Koyu: kullanıcı referans tipografisi (895×150). Açık: mevcut light asset.
    final wordmarkAspect =
        brightness == Brightness.dark ? (895 / 150) : (900 / 157);
    final wordmarkWidth = 240.0;
    final wordmarkHeight = wordmarkWidth / wordmarkAspect;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        minimum: EdgeInsets.zero,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg + MediaQuery.viewPaddingOf(context).bottom,
          ),
          children: [
            const SizedBox(height: 36),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/splash_bolt.png',
                    width: 108,
                    height: 108,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                  const SizedBox(height: 10),
                  Image.asset(
                    wordmarkAsset,
                    width: wordmarkWidth,
                    height: wordmarkHeight,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    alignment: Alignment.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'DEMİR',
                    style: AppTypography.titleMedium.copyWith(
                      fontSize: AppTypography.brandScale * 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 4,
                      height: 1.0,
                      color: AppColors.electricBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Giriş Yap',
              style: AppTypography.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-posta'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Şifre'),
              onSubmitted: (_) => _submit(),
            ),
            if (SupabaseConfig.isConfigured)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _loading
                      ? null
                      : () {
                          final trimmed = _emailCtrl.text.trim();
                          final path = trimmed.isEmpty
                              ? AppRoutes.forgotPassword
                              : '${AppRoutes.forgotPassword}?email=${Uri.encodeComponent(trimmed)}';
                          context.push(path);
                        },
                  child: const Text('Şifremi unuttum'),
                ),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Giriş Yap'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.push(AppRoutes.register),
              child: const Text('Bireysel veya kurumsal hesap oluştur'),
            ),
          ],
        ),
      ),
    );
  }
}
