import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/supabase_config.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/remote/supabase_service.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _register = false;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!SupabaseConfig.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bulut hesabı yapılandırılmamış (SUPABASE_URL / ANON_KEY).',
          ),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await SupabaseService.waitUntilReady();
      final auth = ref.read(authProvider.notifier);
      if (_register) {
        await auth.signUp(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
          displayName: _nameCtrl.text,
        );
      } else {
        await auth.signIn(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );
      }
      if (!mounted) return;
      if (ref.read(authProvider).isAuthenticated) {
        context.pop();
      } else {
        final err = ref.read(authProvider).error;
        if (err != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    if (auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Hesap'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: Text(auth.user!.displayName),
              subtitle: Text(auth.user!.email),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () async {
                await ref.read(authProvider.notifier).signOut();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Çıkış yapıldı')),
                );
              },
              child: const Text('Çıkış Yap'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_register ? 'Hesap Oluştur' : 'Giriş Yap'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const Text(
            'Aynı iş kodunu paylaşan kullanıcılar personel, puantaj, '
            'imalat, görev ve günlük rapor verilerine birlikte erişir. '
            'Katılmak veya bulutta iş açmak için giriş gerekir.',
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_register) ...[
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Ad Soyad'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          TextField(
            controller: _emailCtrl,
            decoration: const InputDecoration(labelText: 'E-posta'),
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _passwordCtrl,
            decoration: const InputDecoration(labelText: 'Şifre'),
            obscureText: true,
            autofillHints: const [AutofillHints.password],
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_register ? 'Kayıt Ol' : 'Giriş Yap'),
          ),
          TextButton(
            onPressed: _loading
                ? null
                : () => setState(() => _register = !_register),
            child: Text(
              _register
                  ? 'Zaten hesabım var — giriş yap'
                  : 'Hesap oluştur',
            ),
          ),
        ],
      ),
    );
  }
}
