import 'package:flutter/material.dart';
import 'package:santijet_demir/core/widgets/app_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_theme.dart';
import 'package:santijet_demir/core/theme/page_background.dart';
import 'package:santijet_demir/features/auth/providers/auth_provider.dart';
import 'package:santijet_demir/features/demo/demo_seed_provider.dart';
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
  bool _obscurePassword = true;

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

  Future<void> _continueAsGuest() async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _loading = true);
    try {
      final ok = await ref.read(authProvider.notifier).loginAsGuest();
      if (!context.mounted) return;
      if (!ok) {
        messenger.showAppSnackBar(
          SnackBar(
            content: Text(
              ref.read(authProvider).error ?? 'Misafir girişi başarısız',
            ),
          ),
        );
        return;
      }

      try {
        await ref.read(demoSeedControllerProvider).loadAll();
      } catch (e) {
        if (!context.mounted) return;
        messenger.showAppSnackBar(
          SnackBar(
            content: Text(
              'Misafir oturumu açıldı; demo veri yüklenemedi: $e',
            ),
          ),
        );
        router.go(AppRoutes.dashboard);
        return;
      }

      if (!context.mounted) return;
      messenger.showAppSnackBar(
        const SnackBar(
          content: Text(
            'Demo Şantiye yüklendi. Premium paket için üyelik açın.',
          ),
        ),
      );
      router.go(AppRoutes.dashboard);
    } finally {
      if (context.mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Giriş her zaman koyu — uygulama teması ne olursa olsun.
    syncPageBackground(AppColors.darkCanvas);
    return Theme(
      data: AppTheme.dark,
      child: Scaffold(
        backgroundColor: AppColors.darkCanvas,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/demir_login_background.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
              filterQuality: FilterQuality.high,
            ),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Image.asset(
                    'assets/images/splash_bolt.png',
                    width: 114,
                    height: 144,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.fromLTRB(26, 0, 26, 18),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight - 18,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Transform.translate(
                                  offset: const Offset(0, -18),
                                  child: const Column(
                                    children: [
                                      Image(
                                        image: AssetImage(
                                          'assets/images/splash_wordmark.png',
                                        ),
                                        width: 240,
                                        fit: BoxFit.contain,
                                        filterQuality: FilterQuality.high,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'DEMİR',
                                        style: TextStyle(
                                          color: Color(0xFF176BFF),
                                          fontSize: 30,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2,
                                          height: 0.85,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                            children: [
                              const Text(
                                'Giriş Yap',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 27,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 7),
                              const Text(
                                'Hesabınıza giriş yaparak devam edin.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFFA5AAB5),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _LoginField(
                                controller: _emailCtrl,
                                hint: 'E-posta adresiniz',
                                icon: Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 14),
                              _LoginField(
                                controller: _passwordCtrl,
                                hint: 'Şifreniz',
                                icon: Icons.lock_outline_rounded,
                                obscureText: _obscurePassword,
                                onSubmitted: (_) => _submit(),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(0xFF8A909D),
                                    size: 22,
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _loading
                                      ? null
                                      : () {
                                          final email =
                                              _emailCtrl.text.trim();
                                          final path = email.isEmpty
                                              ? AppRoutes.forgotPassword
                                              : '${AppRoutes.forgotPassword}?email=${Uri.encodeComponent(email)}';
                                          context.push(path);
                                        },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                  child: const Text(
                                    'Şifremi Unuttum?',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: FilledButton(
                                  onPressed: _loading ? null : _submit,
                                  style: FilledButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF0878FF),
                                    foregroundColor: Colors.white,
                                    shape: const StadiumBorder(),
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const SizedBox.expand(
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Text(
                                                'Giriş Yap',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Align(
                                                alignment: Alignment.centerRight,
                                                child: Icon(
                                                  Icons.arrow_forward_rounded,
                                                  size: 25,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: OutlinedButton.icon(
                                  onPressed:
                                      _loading ? null : _continueAsGuest,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        const Color(0xFF9FC5FF),
                                    side: const BorderSide(
                                      color: Color(0xFF9FC5FF),
                                      width: 1.2,
                                    ),
                                    shape: const StadiumBorder(),
                                  ),
                                  icon: const Icon(
                                    Icons.play_circle_outline_rounded,
                                    size: 23,
                                  ),
                                  label: const Text(
                                    'Demo Olarak Dene',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              InkWell(
                                onTap: _loading
                                    ? null
                                    : () => context.push(AppRoutes.register),
                                borderRadius: BorderRadius.circular(12),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.person_add_alt_1_outlined,
                                        color: Color(0xFF176BFF),
                                        size: 25,
                                      ),
                                      SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Hesap Oluştur',
                                            style: TextStyle(
                                              color: Color(0xFF176BFF),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'Yeni bir hesap açın.',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.verified_user_outlined,
                                    color: Color(0xFFB3BCCB),
                                    size: 18,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Güvenli Giriş',
                                    style: TextStyle(
                                      color: Color(0xFFB3BCCB),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 63.25,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        onSubmitted: onSubmitted,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFF8B909C),
            fontSize: 16,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF8A909D),
            size: 23,
          ),
          suffixIcon: suffixIcon,
          filled: true,
          isDense: true,
          fillColor: const Color(0xC20E141D),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF243244)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF243244)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFF176BFF), width: 1.2),
          ),
        ),
      ),
    );
  }
}

