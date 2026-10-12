import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_theme.dart';
import 'package:santijet_demir/core/theme/page_background.dart';
import 'package:santijet_demir/core/widgets/app_toast.dart';
import 'package:santijet_demir/domain/enums/membership_type.dart';
import 'package:santijet_demir/features/auth/providers/auth_provider.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/settings/providers/settings_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _accepted = true;
  String _dialCode = '+90';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _companyCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _backToLogin() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.login);
  }

  String _phoneValue() {
    final digits = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    final local = digits.startsWith('0') ? digits.substring(1) : digits;
    return '$_dialCode$local';
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final password = _passwordCtrl.text;
    final hasLetter = RegExp(r'[A-Za-zĞÜŞİÖÇğüşıöç]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);
    if (password.length < 8 || !hasLetter || !hasDigit) {
      messenger.showAppSnackBar(
        const SnackBar(
          content: Text('En az 8 karakter, harf ve rakam içermelidir.'),
        ),
      );
      return;
    }
    if (!_accepted) {
      messenger.showAppSnackBar(
        const SnackBar(
          content: Text('Devam etmek için kullanım koşullarını kabul edin.'),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final ok = await ref.read(authProvider.notifier).register(
            email: _emailCtrl.text,
            displayName: _nameCtrl.text,
            phone: _phoneValue(),
            password: password,
            membershipType: MembershipType.individual,
          );
      if (!context.mounted) return;

      if (!ok) {
        messenger.showAppSnackBar(
          SnackBar(content: Text(ref.read(authProvider).error ?? 'Kayıt başarısız')),
        );
        return;
      }

      final company = _companyCtrl.text.trim();
      if (company.isNotEmpty) {
        await ref.read(appSettingsProvider.notifier).updateCompany(
              companyName: company,
            );
      }

      if (ref.read(authProvider).usesSupabase) {
        try {
          await ref
              .read(projectsControllerProvider)
              .refreshFromCloud()
              .timeout(const Duration(seconds: 15));
        } catch (_) {}
      }

      router.go(AppRoutes.projects);
    } finally {
      if (context.mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    syncPageBackground(AppColors.darkCanvas);
    return Theme(
      data: AppTheme.dark,
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
                  Expanded(
                    child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _loading ? null : _backToLogin,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                              ),
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                              label: const Text('Geri', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                          const SizedBox(height: 28),
                  const Padding(
                    padding: EdgeInsets.only(right: 64),
                    child: Text(
                      'Hesap Oluştur',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Padding(
                    padding: EdgeInsets.only(right: 64),
                    child: Text(
                      'Şantiyeniz için hemen başlayın.',
                      style: TextStyle(color: Color(0xFFB7BDC7), fontSize: 15),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _RegField(
                    controller: _nameCtrl,
                    hint: 'Adınız Soyadınız',
                    icon: Icons.person_outline_rounded,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 10),
                  _RegField(
                    controller: _emailCtrl,
                    hint: 'E-posta adresiniz',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 10),
                  _PhoneField(
                    controller: _phoneCtrl,
                    dialCode: _dialCode,
                    onDialCode: (code) => setState(() => _dialCode = code),
                  ),
                  const SizedBox(height: 10),
                  _RegField(
                    controller: _companyCtrl,
                    hint: 'Firma adı (Opsiyonel)',
                    icon: Icons.apartment_outlined,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 10),
                  _RegField(
                    controller: _passwordCtrl,
                    hint: 'Şifre oluşturun',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF8A909D),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Color(0xFF8A909D), size: 16),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'En az 8 karakter, harf ve rakam içermelidir.',
                          style: TextStyle(color: Color(0xFF8A909D), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => setState(() => _accepted = !_accepted),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(top: 1),
                          decoration: BoxDecoration(
                            color: _accepted ? const Color(0xFF176BFF) : Colors.transparent,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: const Color(0xFF176BFF), width: 1.4),
                          ),
                          child: _accepted
                              ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: TextStyle(
                                color: Color(0xFFE7EAF0),
                                fontSize: 13,
                                height: 1.35,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Kullanım koşullarını',
                                  style: TextStyle(
                                    color: Color(0xFF4C8DFF),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                TextSpan(text: ' ve '),
                                TextSpan(
                                  text: 'Gizlilik politikasını',
                                  style: TextStyle(
                                    color: Color(0xFF4C8DFF),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                TextSpan(text: ' okudum, kabul ediyorum.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0878FF),
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
                                    'Hesabı Oluştur',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Icon(Icons.arrow_forward_rounded, size: 22),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Expanded(child: Divider(color: Colors.white)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'veya',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: _loading
                          ? null
                          : () {
                              ScaffoldMessenger.of(context).showAppSnackBar(
                                const SnackBar(
                                  content: Text('Google ile devam henüz kullanılamıyor.'),
                                ),
                              );
                            },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _GoogleMark(),
                          SizedBox(width: 10),
                          Text(
                            'Google ile Devam Et',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                      ],
                      ),
                      const Positioned(
                        top: -9,
                        right: 0,
                        child: Image(
                          image: AssetImage('assets/images/splash_bolt.png'),
                          width: 54,
                          height: 68,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Zaten hesabınız var mı? ',
                          style: TextStyle(color: Color(0xFFB7BDC7), fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: _loading ? null : _backToLogin,
                          child: const Text(
                            'Giriş Yap',
                            style: TextStyle(
                              color: Color(0xFF176BFF),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
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

class _RegField extends StatelessWidget {
  const _RegField({
    required this.hint,
    required this.icon,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.textCapitalization = TextCapitalization.none,
  });

  final String hint;
  final IconData icon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        readOnly: readOnly,
        onTap: onTap,
        textCapitalization: textCapitalization,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF8B909C), fontSize: 15),
          prefixIcon: Icon(icon, color: const Color(0xFF8A909D), size: 22),
          suffixIcon: suffixIcon,
          filled: true,
          isDense: true,
          fillColor: const Color(0xCC10161F),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: _border(const Color(0xFF243244)),
          enabledBorder: _border(const Color(0xFF243244)),
          focusedBorder: _border(const Color(0xFF176BFF)),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color),
    );
  }
}

class _PhoneField extends StatelessWidget {
  const _PhoneField({
    required this.controller,
    required this.dialCode,
    required this.onDialCode,
  });

  final TextEditingController controller;
  final String dialCode;
  final ValueChanged<String> onDialCode;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xCC10161F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF243244)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.phone_outlined, color: Color(0xFF8A909D), size: 20),
          const SizedBox(width: 6),
          PopupMenuButton<String>(
            initialValue: dialCode,
            padding: EdgeInsets.zero,
            color: const Color(0xFF121820),
            onSelected: onDialCode,
            itemBuilder: (context) => const [
              PopupMenuItem(value: '+90', child: Text('+90')),
              PopupMenuItem(value: '+1', child: Text('+1')),
              PopupMenuItem(value: '+49', child: Text('+49')),
              PopupMenuItem(value: '+44', child: Text('+44')),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dialCode,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF8A909D),
                  size: 18,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const SizedBox(
            height: 22,
            child: VerticalDivider(color: Color(0xFF314050), width: 1, thickness: 1),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'Telefon numaranız',
                hintStyle: TextStyle(color: Color(0xFF8B909C), fontSize: 15),
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        color: Color(0xFF4285F4),
        fontSize: 20,
        fontWeight: FontWeight.w800,
        height: 1,
      ),
    );
  }
}
