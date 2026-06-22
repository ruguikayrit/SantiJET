import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/config/supabase_config.dart';
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
        messenger.showSnackBar(
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
          messenger.showSnackBar(
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
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const SizedBox(height: 32),
            Center(
              child: Image.asset('assets/images/s_logo.png', width: 72, height: 72),
            ),
            const SizedBox(height: 16),
            Text('Giriş Yap', style: AppTypography.headlineLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              SupabaseConfig.isConfigured
                  ? 'Bulut hesabı — tek oturum, proje kodu tüm cihazlarda geçerli.'
                  : 'Tek üyelik — aynı anda yalnızca bir oturum açık olabilir.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
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
              child: const Text('Hesabınız yok mu? Kayıt olun'),
            ),
          ],
        ),
      ),
    );
  }
}
