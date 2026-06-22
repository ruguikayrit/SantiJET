import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/features/auth/providers/auth_provider.dart';
import 'package:santijet_demir/data/repositories/project_repository.dart';
import 'package:santijet_demir/domain/entities/project.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';

class ProjectListScreen extends ConsumerStatefulWidget {
  const ProjectListScreen({super.key});

  @override
  ConsumerState<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(projectsControllerProvider).ensureMigratedFromLegacy();
        if (ref.read(authProvider).usesSupabase) {
          await ref.read(projectsControllerProvider).refreshFromCloud();
        }
      } on ProjectException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Projeler yüklenemedi: $e')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final projects = ref.watch(userProjectsProvider);
    final activeId = ref.watch(activeProjectIdProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Projelerim'),
        actions: [
          IconButton(
            tooltip: 'Çıkış',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            'Merhaba, ${auth.user?.displayName ?? ''}',
            style: AppTypography.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            auth.usesSupabase
                ? 'Bulut senkronizasyonu aktif. Proje kodu tüm cihazlarda geçerlidir.'
                : 'Her projenin verileri birbirinden ayrıdır. Proje kodu ile ekip arkadaşlarınızı davet edin.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 20),
          ...projects.map((project) {
            final selected = project.id == activeId;
            return _ProjectCard(
              project: project,
              selected: selected,
              onOpen: () => _openProject(project),
              onMembers: () => context.push(AppRoutes.projectMembers(project.id)),
            );
          }),
          if (projects.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Henüz proje yok. Yeni proje oluşturun veya kod ile katılın.',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'join',
            onPressed: () => context.push(AppRoutes.joinProject),
            icon: const Icon(Icons.qr_code),
            label: const Text('Koda Katıl'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'new',
            onPressed: () => _createProject(context),
            icon: const Icon(Icons.add),
            label: const Text('Yeni Proje'),
          ),
        ],
      ),
    );
  }

  Future<void> _openProject(Project project) async {
    await ref.read(projectsControllerProvider).switchProject(project.id);
    if (mounted) context.go(AppRoutes.dashboard);
  }

  Future<void> _createProject(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final nameCtrl = TextEditingController();
    final locationCtrl = TextEditingController(text: 'İstanbul');

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Proje'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Proje Adı'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: locationCtrl,
              decoration: const InputDecoration(labelText: 'Konum'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Oluştur')),
        ],
      ),
    );

    final name = nameCtrl.text;
    final location = locationCtrl.text;
    nameCtrl.dispose();
    locationCtrl.dispose();

    if (created != true || !context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final project = await ref.read(projectsControllerProvider).createProject(
            name: name,
            location: location,
          );
      if (!context.mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(content: Text('Proje kartı oluşturuldu — Kod: ${project.code}')),
      );
      await ref.read(projectsControllerProvider).switchProject(project.id);
      try {
        await ref
            .read(projectsControllerProvider)
            .refreshFromCloud()
            .timeout(const Duration(seconds: 10));
      } catch (_) {
        // Kart yerelde hazır; bulut senkronu sonraki açılışta tekrar denenir.
      }
    } on ProjectException catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(content: Text('Proje oluşturulamadı: $e')),
      );
    }
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.selected,
    required this.onOpen,
    required this.onMembers,
  });

  final Project project;
  final bool selected;
  final VoidCallback onOpen;
  final VoidCallback onMembers;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(
          color: selected ? AppColors.electricBlueLight : AppColors.border,
        ),
      ),
      child: InkWell(
        onTap: onOpen,
        borderRadius: AppRadii.md,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(project.name, style: AppTypography.titleMedium),
                  ),
                  if (selected)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.electricBlue.withValues(alpha: 0.15),
                        borderRadius: AppRadii.full,
                      ),
                      child: Text('Aktif', style: AppTypography.labelSmall),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(project.location, style: AppTypography.bodySmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Kod: ${project.code}',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.electricBlueLight,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Kodu kopyala',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: project.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Proje kodu kopyalandı')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                  ),
                  IconButton(
                    tooltip: 'Ekip',
                    onPressed: onMembers,
                    icon: const Icon(Icons.group, size: 20),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
