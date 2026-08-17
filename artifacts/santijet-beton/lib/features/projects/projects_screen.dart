import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_modal.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/project_code_generator.dart';
import '../../data/providers/app_data_provider.dart';
import '../../domain/entities/project.dart';

/// Projelerim — Demir `ProjectListScreen` ile aynı kurgu ve kart tasarımı.
class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  /// İki stacked FAB (Koda Katıl + Yeni Proje) için alt boşluk.
  static const _fabStackClearance = 140.0;

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider);
    final activeId = ref.watch(activeProjectIdProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Projelerim'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.ayarlar);
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          _fabStackClearance,
        ),
        children: [
          Text(
            'Merhaba',
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Her projenin verileri birbirinden ayrıdır. '
            'Proje kodu ile ekip arkadaşlarınızı davet edin.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          ...projects.map((project) {
            final selected = project.id == activeId ||
                (activeId == null &&
                    projects.isNotEmpty &&
                    project.id == projects.first.id);
            return _ProjectCard(
              project: project,
              selected: selected,
              onOpen: () => _openProject(project),
              onEdit: () => _openEditor(context, existing: project),
              onDelete: () => _deleteProject(project),
            );
          }),
          if (projects.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Henüz proje yok. Yeni proje oluşturun veya kod ile katılın.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
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
    ref.read(activeProjectIdProvider.notifier).set(project.id);
    if (mounted) context.go(AppRoutes.home);
  }

  Future<void> _createProject(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final nameCtrl = TextEditingController();
    final locationCtrl = TextEditingController(text: 'İstanbul');
    final waCtrl = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Yeni Proje'),
        content: SingleChildScrollView(
          child: Column(
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
              const SizedBox(height: 8),
              TextField(
                controller: waCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Sipariş WhatsApp numarası',
                  hintText: '05xx xxx xx xx',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );

    final name = nameCtrl.text.trim();
    final location = locationCtrl.text.trim();
    final whatsappNumber = waCtrl.text.trim();
    nameCtrl.dispose();
    locationCtrl.dispose();
    waCtrl.dispose();

    if (created != true || !context.mounted) return;
    if (name.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Proje adı gerekli')),
      );
      return;
    }

    final code = _uniqueCode(ref.read(projectsProvider));
    final project = ref.read(projectsProvider.notifier).add(
          name: name,
          code: code,
          company: location,
          whatsappNumber: whatsappNumber,
        );
    ref.read(activeProjectIdProvider.notifier).set(project.id);
    messenger.showSnackBar(
      SnackBar(content: Text('Proje kartı oluşturuldu — Kod: ${project.code}')),
    );
  }

  String _uniqueCode(List<Project> existing) {
    final used = existing.map((e) => e.code.toUpperCase()).toSet();
    for (var i = 0; i < 20; i++) {
      final code = ProjectCodeGenerator.generate();
      if (!used.contains(code)) return code;
    }
    return ProjectCodeGenerator.generate();
  }

  Future<void> _openEditor(
    BuildContext context, {
    required Project existing,
  }) async {
    final nameCtrl = TextEditingController(text: existing.name);
    final locationCtrl = TextEditingController(text: existing.company);
    final codeCtrl = TextEditingController(text: existing.code);
    final waCtrl = TextEditingController(text: existing.whatsappNumber);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Projeyi düzenle'),
        content: SingleChildScrollView(
          child: Column(
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
              const SizedBox(height: 8),
              TextField(
                controller: codeCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Proje Kodu'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: waCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Sipariş WhatsApp numarası',
                  hintText: '05xx xxx xx xx',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    final name = nameCtrl.text.trim();
    final location = locationCtrl.text.trim();
    final code = codeCtrl.text.trim().toUpperCase();
    final whatsappNumber = waCtrl.text.trim();
    nameCtrl.dispose();
    locationCtrl.dispose();
    codeCtrl.dispose();
    waCtrl.dispose();

    if (saved != true || !context.mounted) return;

    ref.read(projectsProvider.notifier).update(
          existing.copyWith(
            name: name,
            company: location,
            code: code,
            whatsappNumber: whatsappNumber,
          ),
        );
  }

  Future<void> _deleteProject(Project p) async {
    final ok = await SJModal.confirm(
      context: context,
      title: 'Projeyi sil',
      message:
          '${p.name} ile bu projeye ait keşif, döküm ve sipariş kayıtları silinsin mi?',
      confirmLabel: 'Sil',
      destructive: true,
    );
    if (!ok || !mounted) return;

    final activeId = ref.read(activeProjectIdProvider);
    final discovery = ref
        .read(discoveryProvider)
        .where((e) => e.projectId != p.id)
        .toList();
    final pours =
        ref.read(poursProvider).where((e) => e.projectId != p.id).toList();
    final orders =
        ref.read(ordersProvider).where((e) => e.projectId != p.id).toList();
    final variance =
        ref.read(varianceProvider).where((e) => e.projectId != p.id).toList();
    final quality =
        ref.read(qualityProvider).where((e) => e.projectId != p.id).toList();
    ref.read(discoveryProvider.notifier).replaceAll(discovery);
    ref.read(poursProvider.notifier).replaceAll(pours);
    ref.read(ordersProvider.notifier).replaceAll(orders);
    ref.read(varianceProvider.notifier).replaceAll(variance);
    ref.read(qualityProvider.notifier).replaceAll(quality);
    ref.read(projectsProvider.notifier).delete(p.id);
    if (activeId == p.id) {
      final remaining = ref.read(projectsProvider);
      ref.read(activeProjectIdProvider.notifier).set(
            remaining.isEmpty ? null : remaining.first.id,
          );
    }
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.selected,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final Project project;
  final bool selected;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final location = project.company.trim().isEmpty
        ? 'Konum yok'
        : project.company.trim();
    final code = project.code.trim().isEmpty ? '—' : project.code.trim();

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
        onLongPress: onDelete,
        borderRadius: AppRadii.md,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.name.isEmpty ? 'Proje adı yok' : project.name,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (selected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.electricBlue.withValues(alpha: 0.15),
                        borderRadius: AppRadii.full,
                      ),
                      child: Text(
                        'Aktif',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                location,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Kod: $code',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.electricBlueLight,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Kodu kopyala',
                    onPressed: () {
                      if (project.code.trim().isEmpty) return;
                      Clipboard.setData(ClipboardData(text: project.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Proje kodu kopyalandı')),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                  ),
                  IconButton(
                    tooltip: 'Düzenle',
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 20),
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
