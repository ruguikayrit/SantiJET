import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/data/repositories/project_repository.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';

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
    setState(() => _loading = true);
    try {
      final project = await ref.read(projectsControllerProvider).joinByCode(
            _codeCtrl.text.trim().toUpperCase(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${project.name} projesine katıldınız')),
      );
      context.go(AppRoutes.dashboard);
    } on ProjectException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
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
            'Varsayılan olarak görüntüleme yetkisi verilir; '
            'sahip düzenleme yetkisini açabilir.',
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
