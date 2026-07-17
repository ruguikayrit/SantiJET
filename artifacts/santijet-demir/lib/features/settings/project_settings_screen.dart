import 'package:flutter/material.dart';
import 'package:santijet_demir/core/widgets/app_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/domain/entities/project.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';

class ProjectSettingsScreen extends ConsumerStatefulWidget {
  const ProjectSettingsScreen({super.key});

  @override
  ConsumerState<ProjectSettingsScreen> createState() =>
      _ProjectSettingsScreenState();
}

class _ProjectSettingsScreenState extends ConsumerState<ProjectSettingsScreen> {
  TextEditingController? _nameCtrl;
  TextEditingController? _locationCtrl;

  void _ensureControllers(Project project) {
    _nameCtrl ??= TextEditingController(text: project.name);
    _locationCtrl ??= TextEditingController(text: project.location);
  }

  @override
  void dispose() {
    _nameCtrl?.dispose();
    _locationCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(activeProjectProvider);
    final canEdit = ref.watch(canEditActiveProjectProvider);

    if (project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Proje Bilgileri')),
        body: Center(
          child: FilledButton(
            onPressed: () => context.push(AppRoutes.projects),
            child: const Text('Proje Seç'),
          ),
        ),
      );
    }

    _ensureControllers(project);

    return Scaffold(
      appBar: AppBar(title: const Text('Proje Bilgileri')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          TextField(
            controller: _nameCtrl,
            readOnly: !canEdit,
            decoration: const InputDecoration(labelText: 'Proje Adı'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: project.code,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Proje Kodu',
              helperText: 'Ekip daveti için bu kodu paylaşın',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _locationCtrl,
            readOnly: !canEdit,
            decoration: const InputDecoration(labelText: 'Konum'),
          ),
          const SizedBox(height: 20),
          if (project.startDate != null)
            Text(
              'Başlangıç: ${project.startDate!.day}.${project.startDate!.month}.${project.startDate!.year}',
              style: AppTypography.bodySmall,
            ),
          if (project.endDate != null)
            Text(
              'Bitiş: ${project.endDate!.day}.${project.endDate!.month}.${project.endDate!.year}',
              style: AppTypography.bodySmall,
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.projectMembers(project.id)),
            icon: const Icon(Icons.group),
            label: const Text('Ekip & Yetkiler'),
          ),
          if (canEdit) ...[
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                await ref.read(projectsControllerProvider).updateProject(
                      project.copyWith(
                        name: _nameCtrl!.text,
                        location: _locationCtrl!.text,
                      ),
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showAppSnackBar(
                    const SnackBar(content: Text('Proje bilgileri kaydedildi')),
                  );
                  context.pop();
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        ],
      ),
    );
  }
}
