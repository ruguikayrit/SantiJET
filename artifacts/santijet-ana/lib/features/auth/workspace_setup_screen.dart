import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_routes.dart';
import '../../core/theme/theme_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/providers/app_state_provider.dart';
import '../../data/services/workspace_api.dart';
import '../../domain/models/workspace_info.dart';

enum _Tab { create, join }

/// Bulut çalışma alanı oluştur / katıl (RN workspace-setup port).
class WorkspaceSetupScreen extends ConsumerStatefulWidget {
  const WorkspaceSetupScreen({super.key});

  @override
  ConsumerState<WorkspaceSetupScreen> createState() =>
      _WorkspaceSetupScreenState();
}

class _WorkspaceSetupScreenState extends ConsumerState<WorkspaceSetupScreen> {
  final _api = WorkspaceApi();
  _Tab _tab = _Tab.create;
  final _companyCtrl = TextEditingController();
  final _joinCodeCtrl = TextEditingController();
  final _createPassCtrl = TextEditingController();
  final _joinPassCtrl = TextEditingController();
  final _apiUrlCtrl = TextEditingController();

  bool _loading = false;
  bool _showAdvanced = false;
  WorkspaceInfo? _createdInfo;
  String? _errorMsg;

  @override
  void dispose() {
    _companyCtrl.dispose();
    _joinCodeCtrl.dispose();
    _createPassCtrl.dispose();
    _joinPassCtrl.dispose();
    _apiUrlCtrl.dispose();
    super.dispose();
  }

  String get _baseUrl => _apiUrlCtrl.text.trim().replaceAll(RegExp(r'/$'), '');

  Future<void> _handleCreate() async {
    setState(() => _errorMsg = null);
    if (_companyCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Firma adını girin.');
      return;
    }
    if (_createPassCtrl.text.length < 4) {
      setState(() => _errorMsg = 'Şifre en az 4 karakter olmalı.');
      return;
    }
    if (_baseUrl.isEmpty) {
      setState(() {
        _errorMsg = 'Sunucu URL girin (gelişmiş ayarlar).';
        _showAdvanced = true;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final ws = await _api.createWorkspace(
        companyName: _companyCtrl.text.trim(),
        password: _createPassCtrl.text,
        apiUrl: _baseUrl,
      );
      await ref.read(appStateProvider.notifier).setWorkspace(ws);
      try {
        await ref.read(appStateProvider.notifier).pushToCloud();
      } catch (_) {}
      if (!mounted) return;
      setState(() => _createdInfo = ws);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMsg = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleJoin() async {
    setState(() => _errorMsg = null);
    final code = _joinCodeCtrl.text.trim().toUpperCase();
    if (code.length < 4) {
      setState(() => _errorMsg = 'Geçerli bir davet kodu girin.');
      return;
    }
    if (_joinPassCtrl.text.isEmpty) {
      setState(() => _errorMsg = 'Çalışma alanı şifresini girin.');
      return;
    }
    if (_baseUrl.isEmpty) {
      setState(() {
        _errorMsg = 'Sunucu URL girin (gelişmiş ayarlar).';
        _showAdvanced = true;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final ws = await _api.joinWorkspace(
        inviteCode: code,
        password: _joinPassCtrl.text,
        apiUrl: _baseUrl,
      );
      await ref.read(appStateProvider.notifier).setWorkspace(ws);
      try {
        await ref.read(appStateProvider.notifier).pullFromCloud();
      } catch (_) {}
      if (!mounted) return;
      context.go(AppRoutes.home);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMsg = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleSkip() async {
    final notifier = ref.read(appStateProvider.notifier);
    final state = ref.read(appStateProvider);
    if (state.currentUserId == null) {
      await notifier.startLocalSession(name: 'Kullanıcı');
    } else {
      await notifier.setWorkspace(
        WorkspaceInfo(
          id: 'local',
          inviteCode: 'LOCAL',
          companyName: 'Yerel Kullanım',
          apiUrl: _baseUrl,
        ),
      );
    }
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeDefinitionProvider);
    final c = theme.colors;
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: c.secondary,
            padding: EdgeInsets.fromLTRB(24, top + 16, 24, 24),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE85D04),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child:
                      const Icon(Icons.layers, size: 32, color: Colors.white),
                ),
                const SizedBox(height: 14),
                Text(
                  'ŞantiJET',
                  style: TextStyle(
                    color: c.secondaryForeground,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Rajdhani',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ekibinizle veri paylaşmak için bir çalışma alanı oluşturun veya mevcut birine katılın.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: c.mutedForeground,
                    fontSize: 14,
                    height: 1.55,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                0,
                24,
                0,
                MediaQuery.paddingOf(context).bottom + 40,
              ),
              children: [
                if (_createdInfo != null)
                  _successCard(c, _createdInfo!)
                else ...[
                  _tabs(c),
                  const SizedBox(height: 16),
                  _formCard(c),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: _handleSkip,
                      child: Text(
                        'Şimdilik Atla — Yalnızca Yerel Kullanım',
                        style: TextStyle(
                          color: c.mutedForeground,
                          fontSize: 13,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _successCard(ThemeColors c, WorkspaceInfo ws) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 40),
          const SizedBox(height: 8),
          Text(
            'Çalışma Alanı Oluşturuldu!',
            style: TextStyle(
              color: c.foreground,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
          Text(
            ws.companyName,
            style: TextStyle(color: c.mutedForeground, fontFamily: 'Inter'),
          ),
          const SizedBox(height: 16),
          Text(
            'Davet Kodunuz',
            style: TextStyle(
              color: c.foreground,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0x33E85D04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE85D04)),
            ),
            child: Text(
              ws.inviteCode,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFE85D04),
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: 6,
                fontFamily: 'Inter',
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.go(AppRoutes.home),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE85D04),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text(
                'Devam Et',
                style: TextStyle(
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

  Widget _tabs(ThemeColors c) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final t in _Tab.values)
            Expanded(
              child: Material(
                color: _tab == t ? const Color(0xFFE85D04) : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                child: InkWell(
                  borderRadius: BorderRadius.circular(9),
                  onTap: () => setState(() {
                    _tab = t;
                    _errorMsg = null;
                  }),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      t == _Tab.create ? 'Yeni Oluştur' : 'Kodla Katıl',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _tab == t ? Colors.white : c.mutedForeground,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _formCard(ThemeColors c) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_tab == _Tab.create) ...[
            _label(c, 'Firma / Şantiye Adı'),
            _input(c, _companyCtrl, 'Örn: ABC İnşaat A.Ş.'),
            const SizedBox(height: 12),
            _label(c, 'Çalışma Alanı Şifresi'),
            _input(c, _createPassCtrl, 'En az 4 karakter', obscure: true),
          ] else ...[
            _label(c, 'Davet Kodu'),
            _input(
              c,
              _joinCodeCtrl,
              'AB3X9Z2K7M',
              maxLength: 12,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: 6,
                fontFamily: 'Inter',
              ),
              onChanged: (v) {
                final up = v.toUpperCase();
                if (up != v) {
                  _joinCodeCtrl.value = TextEditingValue(
                    text: up,
                    selection: TextSelection.collapsed(offset: up.length),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            _label(c, 'Çalışma Alanı Şifresi'),
            _input(c, _joinPassCtrl, 'Yöneticinizden alın', obscure: true),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading
                  ? null
                  : (_tab == _Tab.create ? _handleCreate : _handleJoin),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE85D04),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _tab == _Tab.create
                          ? 'Çalışma Alanı Oluştur'
                          : 'Katıl',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
              child: Text(
                'Sunucu Ayarları',
                style: TextStyle(
                  color: c.mutedForeground,
                  fontSize: 12,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
          if (_showAdvanced) ...[
            _label(c, 'Sunucu URL'),
            _input(
              c,
              _apiUrlCtrl,
              'https://...',
              keyboardType: TextInputType.url,
            ),
          ],
          if (_errorMsg != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0x33DC2626),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDC2626)),
              ),
              child: Text(
                _errorMsg!,
                style: const TextStyle(
                  color: Color(0xFFDC2626),
                  fontSize: 12,
                  fontFamily: 'Inter',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _label(ThemeColors c, String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 4),
        child: Text(
          t,
          style: TextStyle(
            color: c.foreground,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
      );

  Widget _input(
    ThemeColors c,
    TextEditingController controller,
    String hint, {
    bool obscure = false,
    int? maxLength,
    TextInputType? keyboardType,
    TextStyle? style,
    TextAlign textAlign = TextAlign.start,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      maxLength: maxLength,
      keyboardType: keyboardType,
      textAlign: textAlign,
      onChanged: onChanged,
      style: (style ?? const TextStyle(fontSize: 15, fontFamily: 'Inter'))
          .copyWith(color: c.foreground),
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        hintStyle: TextStyle(color: c.mutedForeground),
        filled: true,
        fillColor: c.muted,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE85D04)),
        ),
      ),
    );
  }
}
