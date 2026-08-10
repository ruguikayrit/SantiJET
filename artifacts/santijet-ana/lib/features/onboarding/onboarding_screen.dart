import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_info.dart';
import '../../core/routing/app_routes.dart';
import '../../data/providers/app_state_provider.dart';
import '../../domain/models/app_user.dart';

const _bg = Color(0xFF090D18);
const _card = Color(0xFF111827);
const _border = Color(0x12FFFFFF);
const _orange = Color(0xFFE85D04);

const _deployChannel =
    String.fromEnvironment('DEPLOY_CHANNEL', defaultValue: '');

const _roleColors = <String, Color>{
  'isveren': Color(0xFF7C3AED),
  'proje-muduru': Color(0xFFE85D04),
  'santiye-sefi': Color(0xFFDC2626),
  'saha-muhendisi': Color(0xFF16A34A),
  'teknik-ofis-muhendisi': Color(0xFF0EA5E9),
  'isg-birimi': Color(0xFFF59E0B),
  'taseron': Color(0xFF64748B),
  'satin-alma-birimi': Color(0xFF0891B2),
  'muhasebe-birimi': Color(0xFF059669),
  'ik-birimi': Color(0xFF8B5CF6),
  'diger-kullanicilar': Color(0xFF94A3B8),
};

enum _Step { welcome, emailForm, workspaceChoice, pinPrompt }

enum _AuthMethod { google, apple, email }

/// Onboarding — welcome → profil → çalışma alanı / PIN (RN port).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  _Step _step = _Step.welcome;
  _AuthMethod _authMethod = _AuthMethod.email;

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _loginPinCtrl = TextEditingController();

  String _roleId = 'santiye-sefi';
  String? _formError;
  String? _pinUserId;
  bool _pinError = false;
  String? _pendingLoginName;
  String? _pendingUserId;
  bool _stagingAutoStarted = false;

  @override
  void initState() {
    super.initState();
    if (_deployChannel == 'staging') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _stagingAutoStarted) return;
        _stagingAutoStarted = true;
        _quickStartLocal();
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _pinCtrl.dispose();
    _loginPinCtrl.dispose();
    super.dispose();
  }

  Color _roleColor(String roleId) =>
      _roleColors[roleId] ?? const Color(0xFF6B7280);

  String _roleName(String roleId) {
    for (final r in ref.read(appStateProvider).roles) {
      if (r.id == roleId) return r.name;
    }
    return roleId;
  }

  void _completePendingLogin() {
    final name = _pendingLoginName;
    if (name == null) return;
    for (final u in ref.read(appStateProvider).appUsers) {
      if (u.name == name) {
        ref.read(appStateProvider.notifier).login(u.id);
        _pendingLoginName = null;
        return;
      }
    }
  }

  Future<void> _quickStartLocal() async {
    try {
      ref.read(appStateProvider.notifier).applyLocalSessionSync(
            name: _deployChannel == 'staging' ? 'Staging Kullanıcı' : 'Kullanıcı',
            roleId: 'santiye-sefi',
          );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Oturum açılamadı: $e')),
      );
      return;
    }
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  void _handleExistingUser(AppUser user) {
    if (user.pin.isNotEmpty) {
      setState(() {
        _pinUserId = user.id;
        _loginPinCtrl.clear();
        _pinError = false;
        _step = _Step.pinPrompt;
      });
    } else {
      // Workspace yoksa yerel oturum tamamla.
      final ws = ref.read(appStateProvider).workspaceInfo;
      if (ws == null) {
        ref.read(appStateProvider.notifier).completeLocalOnboarding(user.id).then((_) {
          if (mounted) context.go(AppRoutes.home);
        });
      } else {
        ref.read(appStateProvider.notifier).login(user.id);
        context.go(AppRoutes.home);
      }
    }
  }

  void _handlePinConfirm() {
    AppUser? user;
    for (final u in ref.read(appStateProvider).appUsers) {
      if (u.id == _pinUserId) user = u;
    }
    if (user == null) return;
    if (_loginPinCtrl.text == user.pin) {
      final ws = ref.read(appStateProvider).workspaceInfo;
      if (ws == null) {
        ref.read(appStateProvider.notifier).completeLocalOnboarding(user.id).then((_) {
          if (mounted) context.go(AppRoutes.home);
        });
      } else {
        ref.read(appStateProvider.notifier).login(user.id);
        context.go(AppRoutes.home);
      }
    } else {
      setState(() {
        _pinError = true;
        _loginPinCtrl.clear();
      });
    }
  }

  void _handleEmailSubmit() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _formError = 'Adınızı girin');
      return;
    }
    final pin = _pinCtrl.text;
    final id = ref.read(appStateProvider.notifier).addAppUser(
          AppUser(
            id: '',
            name: name,
            roleId: _roleId,
            pin: pin.length == 4 ? pin : '',
            profession: '',
            phone: _emailCtrl.text.trim(),
            address: '',
            company: '',
          ),
        );
    _pendingLoginName = name;
    _pendingUserId = id;

    final ws = ref.read(appStateProvider).workspaceInfo;
    if (ws == null) {
      setState(() {
        _formError = null;
        _step = _Step.workspaceChoice;
      });
    } else {
      ref.read(appStateProvider.notifier).login(id);
      context.go(AppRoutes.home);
    }
  }

  Future<void> _handleBireysel() async {
    final id = _pendingUserId;
    if (id != null) {
      await ref.read(appStateProvider.notifier).completeLocalOnboarding(id);
    } else {
      await ref.read(appStateProvider.notifier).startLocalSession(
            name: _pendingLoginName ?? _nameCtrl.text.trim(),
            roleId: _roleId,
            pin: _pinCtrl.text,
          );
    }
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  void _handleEkip() {
    final id = _pendingUserId;
    if (id != null) {
      ref.read(appStateProvider.notifier).login(id);
    } else {
      _completePendingLogin();
    }
    if (mounted) context.go(AppRoutes.workspaceSetup);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final roles = state.roles;
    if (roles.isNotEmpty && !roles.any((r) => r.id == _roleId)) {
      _roleId = roles.first.id;
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: switch (_step) {
            _Step.pinPrompt => _buildPinPrompt(state),
            _Step.workspaceChoice => _buildWorkspaceChoice(),
            _Step.emailForm => _buildEmailForm(roles),
            _Step.welcome => _buildWelcome(state),
          },
        ),
      ),
    );
  }

  Widget _buildWelcome(AppState state) {
    final users = state.appUsers;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      children: [
        const SizedBox(height: 12),
        Center(
          child: Column(
            children: [
              Image.asset(
                'assets/images/santijet-icon.png',
                height: 56,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.bolt_rounded,
                  size: 56,
                  color: _orange,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                AppInfo.displayName,
                style: const TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Rajdhani',
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'İnşaat & Şantiye Yönetimi',
                style: TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Bireysel veya ekip olarak kullanın',
                style: TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 14,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        // Tek dokunuşla içeri gir — staging / web için en güvenilir yol.
        Material(
          color: _orange,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _quickStartLocal,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Hızlı Başla (Bireysel)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Row(
          children: [
            Expanded(child: Divider(color: _border)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'veya hesap ile',
                style: TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 13,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            Expanded(child: Divider(color: _border)),
          ],
        ),
        const SizedBox(height: 16),
        _authBtn(
          leading: const Text(
            'G',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFFDB4437),
              fontFamily: 'Inter',
            ),
          ),
          iconBg: const Color(0xFFFEF2F2),
          label: 'Google ile Devam Et',
          onTap: () => setState(() {
            _authMethod = _AuthMethod.google;
            _step = _Step.emailForm;
          }),
        ),
        const SizedBox(height: 12),
        _authBtn(
          leading: const Icon(Icons.phone_iphone, size: 18, color: Color(0xFF1C1917)),
          iconBg: const Color(0xFFF8FAFC),
          label: 'Apple ile Devam Et',
          onTap: () => setState(() {
            _authMethod = _AuthMethod.apple;
            _step = _Step.emailForm;
          }),
        ),
        const SizedBox(height: 12),
        _authBtn(
          leading: const Icon(Icons.mail_outline, size: 18, color: _orange),
          iconBg: const Color(0x33E85D04),
          label: 'E-posta ile Devam Et',
          primary: true,
          onTap: () => setState(() {
            _authMethod = _AuthMethod.email;
            _step = _Step.emailForm;
          }),
        ),
        const SizedBox(height: 24),
        const Row(
          children: [
            Expanded(child: Divider(color: _border)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'veya',
                style: TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 13,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            Expanded(child: Divider(color: _border)),
          ],
        ),
        const SizedBox(height: 16),
        Material(
          color: const Color(0x1A0EA5E9),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => context.push(AppRoutes.workspaceSetup),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x4D0EA5E9)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.link, size: 16, color: Color(0xFF0EA5E9)),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Şirket Kodunuz Var mı? Buradan Girin',
                      style: TextStyle(
                        color: Color(0xFF0EA5E9),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 14, color: Color(0xFF0EA5E9)),
                ],
              ),
            ),
          ),
        ),
        if (users.isNotEmpty) ...[
          const SizedBox(height: 28),
          const Text(
            'KAYITLI HESAPLAR',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 10),
          for (final u in users)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: _card,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _handleExistingUser(u),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: _roleColor(u.roleId),
                          child: Text(
                            u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                u.name,
                                style: const TextStyle(
                                  color: Color(0xFFF1F5F9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              Text(
                                _roleName(u.roleId),
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          u.pin.isNotEmpty ? Icons.lock_outline : Icons.login,
                          size: 14,
                          color: u.pin.isNotEmpty
                              ? const Color(0xFF64748B)
                              : const Color(0xFF22C55E),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
        const SizedBox(height: 24),
        const Text(
          'Devam ederek Kullanım Koşullarını ve\nGizlilik Politikasını kabul etmiş olursunuz',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF334155),
            fontSize: 11,
            height: 1.45,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Widget _authBtn({
    required Widget leading,
    required Color iconBg,
    required String label,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return Material(
      color: _card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        // Web/CanvasKit'te dar hit-test alanlarını büyüt.
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: primary ? const Color(0x66E85D04) : _border,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: leading,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: primary
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFFCBD5E1),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: primary ? _orange : const Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm(List roles) {
    final methodLabel = switch (_authMethod) {
      _AuthMethod.google => 'Google',
      _AuthMethod.apple => 'Apple',
      _AuthMethod.email => 'E-posta',
    };
    final methodColor = switch (_authMethod) {
      _AuthMethod.google => const Color(0xFFDB4437),
      _AuthMethod.apple => const Color(0xFF555555),
      _AuthMethod.email => _orange,
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _step = _Step.welcome),
          icon: const Icon(Icons.arrow_back, size: 20, color: Color(0xFF94A3B8)),
          label: const Text(
            'Geri',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 15,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: methodColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: methodColor.withOpacity(0.25)),
          ),
          child: Text(
            '$methodLabel ile Devam',
            style: TextStyle(
              color: methodColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Profilinizi Oluşturun',
          style: TextStyle(
            color: Color(0xFFF1F5F9),
            fontSize: 24,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Bu bilgiler ekibinizdeki kişilere görünecektir',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 14,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Ad Soyad',
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 6),
        _field(
          controller: _nameCtrl,
          hint: 'Örn: Ahmet Yılmaz',
          error: _formError != null,
          onChanged: (_) => setState(() => _formError = null),
          textCapitalization: TextCapitalization.words,
          autofocus: true,
        ),
        if (_formError != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _formError!,
              style: const TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 12,
                fontFamily: 'Inter',
              ),
            ),
          ),
        const SizedBox(height: 16),
        const Text(
          'E-posta Adresi',
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 6),
        _field(
          controller: _emailCtrl,
          hint: 'ornek@email.com',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        const Text(
          'Unvan / Rol',
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final r in roles)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _roleId = r.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: _roleId == r.id
                            ? _roleColor(r.id)
                            : _roleColor(r.id).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: _roleColor(r.id).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        r.name,
                        style: TextStyle(
                          color: _roleId == r.id
                              ? Colors.white
                              : _roleColor(r.id),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text.rich(
          TextSpan(
            text: 'PIN Kodu ',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
            children: [
              TextSpan(
                text: '(isteğe bağlı, 4 haneli)',
                style: TextStyle(
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        _field(
          controller: _pinCtrl,
          hint: 'Boş bırakılırsa şifresiz',
          keyboardType: TextInputType.number,
          obscure: true,
          maxLength: 4,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _handleEmailSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: _orange,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Devam Et',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkspaceChoice() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        children: [
          Image.asset(
            'assets/images/santijet-icon.png',
            height: 32,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.bolt_rounded, color: _orange, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nasıl Kullanmak İstersiniz?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 22,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'İstediğiniz zaman diğer seçeneğe geçebilirsiniz',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 28),
          _choiceCard(
            icon: Icons.person_outline,
            iconColor: const Color(0xFF3B82F6),
            title: 'Bireysel Kullan',
            desc:
                'Kendi şantiyeni tek başına yönet. İnternet bağlantısı gerekmez, veriler cihazında saklanır.',
            badgeIcon: Icons.bolt,
            badge: 'Hemen Başla',
            onTap: _handleBireysel,
          ),
          const SizedBox(height: 16),
          _choiceCard(
            icon: Icons.groups_outlined,
            iconColor: _orange,
            title: 'Ekip ile Kullan',
            desc:
                'Şirket kodu ile ekibine katıl ya da kendi ekibini oluştur. Veriler bulutta senkronize edilir.',
            badgeIcon: Icons.cloud_outlined,
            badge: 'Şirket Kodu Gir',
            onTap: _handleEkip,
          ),
        ],
      ),
    );
  }

  Widget _choiceCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
    required IconData badgeIcon,
    required String badge,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: iconColor),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFF1F5F9),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                desc,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                  height: 1.4,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(badgeIcon, size: 12, color: iconColor),
                  const SizedBox(width: 6),
                  Text(
                    badge,
                    style: TextStyle(
                      color: iconColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinPrompt(AppState state) {
    AppUser? pinUser;
    for (final u in state.appUsers) {
      if (u.id == _pinUserId) pinUser = u;
    }
    final c = _roleColor(pinUser?.roleId ?? '');
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _step = _Step.welcome),
              icon: const Icon(Icons.arrow_back,
                  size: 20, color: Color(0xFF94A3B8)),
              label: const Text(
                'Geri',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: c,
                  child: Text(
                    (pinUser?.name.isNotEmpty ?? false)
                        ? pinUser!.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  pinUser?.name ?? '',
                  style: const TextStyle(
                    color: Color(0xFFF1F5F9),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                ),
                Text(
                  _roleName(pinUser?.roleId ?? ''),
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          const Text(
            'PIN Kodunuzu Girin',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _loginPinCtrl,
            autofocus: true,
            obscureText: true,
            maxLength: 4,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFF1F5F9),
              fontSize: 28,
              letterSpacing: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() => _pinError = false),
            decoration: InputDecoration(
              counterText: '',
              hintText: '● ● ● ●',
              hintStyle: const TextStyle(color: Color(0xFF334155)),
              filled: true,
              fillColor: _card,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: _pinError ? const Color(0xFFDC2626) : _border,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: _pinError ? const Color(0xFFDC2626) : _orange,
                ),
              ),
            ),
          ),
          if (_pinError)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Yanlış PIN. Tekrar deneyin.',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontSize: 13,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed:
                  _loginPinCtrl.text.length == 4 ? _handlePinConfirm : null,
              style: FilledButton.styleFrom(
                backgroundColor: _orange,
                disabledBackgroundColor: _orange.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Giriş Yap',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    bool error = false,
    bool obscure = false,
    int? maxLength,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
    bool autofocus = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      maxLength: maxLength,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      autofocus: autofocus,
      style: const TextStyle(
        color: Color(0xFFF1F5F9),
        fontSize: 15,
        fontFamily: 'Inter',
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF334155)),
        filled: true,
        fillColor: _card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: error ? const Color(0xFFDC2626) : _border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: error ? const Color(0xFFDC2626) : _orange,
          ),
        ),
      ),
    );
  }
}
