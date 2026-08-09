import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/collaboration_provider.dart';
import '../../data/remote/supabase_project_sync.dart';
import '../../data/remote/supabase_service.dart';
import '../../domain/entities/project_member.dart';
import '../../domain/enums/project_role.dart';

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
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce giriş yapın')),
      );
      context.push(AppRoutes.auth);
      return;
    }

    setState(() => _loading = true);
    try {
      await SupabaseService.waitUntilReady();
      if (!SupabaseService.isReady) {
        throw ProjectException(
          'Bulut bağlantısı kurulamadı. SUPABASE ayarlarını kontrol edin.',
        );
      }

      final sync = ref.read(supabaseProjectSyncProvider);
      final project = await sync.joinByCode(
        user: auth.user!,
        code: _codeCtrl.text,
      );

      ref.read(projectsProvider.notifier).upsert(project);
      ref.read(projectMembersListProvider.notifier).upsert(
            ProjectMember(
              projectId: project.id,
              userId: auth.user!.id,
              email: auth.user!.email,
              displayName: auth.user!.displayName,
              role: ProjectRole.viewer,
              canEdit: false,
              joinedAt: DateTime.now(),
            ),
          );
      await ref.read(collaborationControllerProvider).pullMyProjects();
      await ref.read(collaborationControllerProvider).pullDomain(project.id);
      ref.read(activeProjectIdProvider.notifier).set(project.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${project.name} işine katıldınız')),
      );
      context.go(AppRoutes.home);
    } on ProjectException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Katılım başarısız: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İş Koduna Katıl')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const Text(
            'Şantiye sorumlusunun paylaştığı iş kodunu girin. '
            'Varsayılan olarak görüntüleme yetkisi verilir; '
            'sahip düzenleme yetkisini açabilir.',
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _codeCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'İş Kodu',
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
                : const Text('İşe Katıl'),
          ),
        ],
      ),
    );
  }
}
