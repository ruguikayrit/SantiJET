import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/providers/app_data_provider.dart';

/// Proje koduna katıl — Demir ile aynı kurgu (yerel kod eşleştirme).
class JoinProjectScreen extends ConsumerStatefulWidget {
  const JoinProjectScreen({super.key});

  @override
  ConsumerState<JoinProjectScreen> createState() => _JoinProjectScreenState();
}

class _JoinProjectScreenState extends ConsumerState<JoinProjectScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _loading = true);
    try {
      final projects = ref.read(projectsProvider);
      final found = projects
          .where((p) => p.code.trim().toUpperCase() == code)
          .toList();
      if (!mounted) return;
      if (found.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu kodla proje bulunamadı')),
        );
        return;
      }
      final project = found.first;
      ref.read(activeProjectIdProvider.notifier).set(project.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${project.name} projesine katıldınız')),
      );
      context.go(AppRoutes.home);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Proje Koduna Katıl')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const Text(
            'Şantiye sorumlusunun paylaştığı proje kodunu girin. '
            'Aynı kodla kayıtlı proje bu cihazda varsa aktif edilir.',
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _codeCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Proje Kodu',
              hintText: 'YTFC2T377X',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _join,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Projeye Katıl'),
          ),
        ],
      ),
    );
  }
}
