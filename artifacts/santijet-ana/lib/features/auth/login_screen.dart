import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_info.dart';
import '../../data/providers/app_state_provider.dart';
import '../../domain/models/app_user.dart';

const _navy = Color(0xFF16213E);
const _card = Color(0xFF1E293B);
const _border = Color(0xFF334155);
const _orange = Color(0xFFE85D04);

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

/// Kullanıcı listesi + PIN + yeni kullanıcı (RN login port).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String? _selectedUserId;
  String? _pinUserId;
  final _pinCtrl = TextEditingController();
  bool _pinError = false;

  final _newNameCtrl = TextEditingController();
  final _newPinCtrl = TextEditingController();
  final _newPinConfirmCtrl = TextEditingController();
  String _newRoleId = 'santiye-sefi';

  @override
  void dispose() {
    _pinCtrl.dispose();
    _newNameCtrl.dispose();
    _newPinCtrl.dispose();
    _newPinConfirmCtrl.dispose();
    super.dispose();
  }

  Color _roleColor(String id) => _roleColors[id] ?? const Color(0xFF6B7280);

  String _roleName(String roleId) {
    for (final r in ref.read(appStateProvider).roles) {
      if (r.id == roleId) return r.name;
    }
    return roleId;
  }

  void _handleLogin() {
    final id = _selectedUserId;
    if (id == null) return;
    AppUser? user;
    for (final u in ref.read(appStateProvider).appUsers) {
      if (u.id == id) user = u;
    }
    if (user == null) return;
    if (user.pin.isNotEmpty) {
      setState(() {
        _pinUserId = user!.id;
        _pinCtrl.clear();
        _pinError = false;
      });
    } else {
      ref.read(appStateProvider.notifier).login(user.id);
    }
  }

  void _handlePinConfirm() {
    AppUser? user;
    for (final u in ref.read(appStateProvider).appUsers) {
      if (u.id == _pinUserId) user = u;
    }
    if (user == null) return;
    if (_pinCtrl.text == user.pin) {
      ref.read(appStateProvider.notifier).login(user.id);
      setState(() => _pinUserId = null);
    } else {
      setState(() {
        _pinError = true;
        _pinCtrl.clear();
      });
    }
  }

  Future<void> _openNewUserSheet() async {
    final roles = ref.read(appStateProvider).roles;
    _newNameCtrl.clear();
    _newPinCtrl.clear();
    _newPinConfirmCtrl.clear();
    _newRoleId = roles.isNotEmpty ? roles.first.id : 'santiye-sefi';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Yeni Kullanıcı',
                      style: TextStyle(
                        color: Color(0xFFF1F5F9),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _label('Ad Soyad'),
                    _input(_newNameCtrl, 'Örn: Ahmet Yılmaz'),
                    const SizedBox(height: 12),
                    _label('Rol'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final r in roles)
                          GestureDetector(
                            onTap: () => setModal(() => _newRoleId = r.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: _newRoleId == r.id
                                    ? _roleColor(r.id)
                                    : _navy,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: _newRoleId == r.id
                                      ? _roleColor(r.id)
                                      : _border,
                                ),
                              ),
                              child: Text(
                                r.name,
                                style: TextStyle(
                                  color: _newRoleId == r.id
                                      ? Colors.white
                                      : const Color(0xFF94A3B8),
                                  fontSize: 13,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _label('PIN (Opsiyonel, 4 haneli)'),
                    _input(
                      _newPinCtrl,
                      'PIN girilmezse şifresiz giriş',
                      obscure: true,
                      maxLength: 4,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setModal(() {}),
                    ),
                    if (_newPinCtrl.text.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _label('PIN Tekrar'),
                      _input(
                        _newPinConfirmCtrl,
                        '••••',
                        obscure: true,
                        maxLength: 4,
                        keyboardType: TextInputType.number,
                        error: _newPinConfirmCtrl.text.isNotEmpty &&
                            _newPinCtrl.text != _newPinConfirmCtrl.text,
                        onChanged: (_) => setModal(() {}),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          final name = _newNameCtrl.text.trim();
                          if (name.isEmpty) return;
                          if (_newPinCtrl.text.isNotEmpty &&
                              _newPinCtrl.text != _newPinConfirmCtrl.text) {
                            return;
                          }
                          ref.read(appStateProvider.notifier).addAppUser(
                                AppUser(
                                  id: '',
                                  name: name,
                                  roleId: _newRoleId,
                                  pin: _newPinCtrl.text.length == 4
                                      ? _newPinCtrl.text
                                      : '',
                                  profession: '',
                                  phone: '',
                                  address: '',
                                  company: '',
                                ),
                              );
                          Navigator.pop(ctx);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _orange,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Kullanıcı Oluştur',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final users = state.appUsers;
    AppUser? selected;
    AppUser? pinUser;
    for (final u in users) {
      if (u.id == _selectedUserId) selected = u;
      if (u.id == _pinUserId) pinUser = u;
    }

    return Scaffold(
      backgroundColor: _navy,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 32),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0x33E85D04),
                    borderRadius: BorderRadius.circular(36),
                  ),
                  child: const Icon(Icons.storage_outlined,
                      size: 36, color: _orange),
                ),
                const SizedBox(height: 16),
                Text(
                  AppInfo.legalName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Rajdhani',
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Hesabınızı seçin',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 14,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 28),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: users.isEmpty
                        ? const Column(
                            children: [
                              SizedBox(height: 40),
                              Icon(Icons.groups_outlined,
                                  size: 40, color: Color(0xFF475569)),
                              SizedBox(height: 12),
                              Text(
                                'Henüz kullanıcı yok',
                                style: TextStyle(
                                  color: Color(0xFFE2E8F0),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Başlamak için ilk kullanıcıyı oluşturun',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 14,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'KULLANICI',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedUserId,
                                dropdownColor: _card,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: _card,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                        color: _border, width: 1.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                        color: _orange, width: 1.5),
                                  ),
                                ),
                                hint: const Text(
                                  'Kullanıcı seçin...',
                                  style: TextStyle(
                                    color: Color(0xFF475569),
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                items: [
                                  for (final u in users)
                                    DropdownMenuItem(
                                      value: u.id,
                                      child: Text(
                                        '${u.name} · ${_roleName(u.roleId)}',
                                        style: const TextStyle(
                                          color: Color(0xFFF1F5F9),
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _selectedUserId = v),
                              ),
                              if (selected != null) ...[
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: _handleLogin,
                                    icon: const Icon(Icons.login, size: 18),
                                    label: Text(
                                      selected.pin.isNotEmpty
                                          ? 'PIN ile Giriş Yap'
                                          : 'Giriş Yap',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: _orange,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openNewUserSheet,
                      icon: const Icon(Icons.person_add_alt_1, size: 18),
                      label: const Text(
                        'Yeni Kullanıcı Ekle',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF94A3B8),
                        side: const BorderSide(color: _border),
                        backgroundColor: _card,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_pinUserId != null)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Material(
                    color: _card,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'PIN Girin',
                            style: TextStyle(
                              color: Color(0xFFF1F5F9),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            ),
                          ),
                          Text(
                            pinUser?.name ?? '',
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontFamily: 'Inter',
                            ),
                          ),
                          if (_pinError)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'Yanlış PIN, tekrar deneyin',
                                style: TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontSize: 13,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _pinCtrl,
                            autofocus: true,
                            obscureText: true,
                            maxLength: 4,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFF1F5F9),
                              fontSize: 28,
                              letterSpacing: 8,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Inter',
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            onChanged: (_) => setState(() => _pinError = false),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: '••••',
                              filled: true,
                              fillColor: const Color(0xFF0F172A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  onPressed: () =>
                                      setState(() => _pinUserId = null),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _orange,
                                  ),
                                  child: const Text('İptal'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  onPressed: _pinCtrl.text.length == 4
                                      ? _handlePinConfirm
                                      : null,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _navy,
                                  ),
                                  child: const Text('Giriş'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          t,
          style: const TextStyle(
            color: Color(0xFFE2E8F0),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      );

  Widget _input(
    TextEditingController c,
    String hint, {
    bool obscure = false,
    int? maxLength,
    TextInputType? keyboardType,
    bool error = false,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: c,
      obscureText: obscure,
      maxLength: maxLength,
      keyboardType: keyboardType,
      onChanged: onChanged,
      inputFormatters: keyboardType == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      style: const TextStyle(
        color: Color(0xFFF1F5F9),
        fontSize: 15,
        fontFamily: 'Inter',
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        filled: true,
        fillColor: _navy,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: error ? const Color(0xFFDC2626) : _border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: error ? const Color(0xFFDC2626) : _orange,
          ),
        ),
      ),
    );
  }
}
