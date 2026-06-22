import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
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
  double? _progress;

  void _ensureControllers(Project project) {
    _nameCtrl ??= TextEditingController(text: project.name);
    _locationCtrl ??= TextEditingController(text: project.location);
    _progress ??= project.progress;
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
    final progress = _progress!;

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
          Text('Proje İlerlemesi', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: progress,
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '${progress.toStringAsFixed(0)}%',
                  onChanged: canEdit ? (v) => setState(() => _progress = v) : null,
                ),
              ),
              Text('${progress.toStringAsFixed(0)}%', style: AppTypography.titleMedium),
            ],
          ),
          ClipRRect(
            borderRadius: AppRadii.full,
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 8,
              backgroundColor: AppColors.border,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 12),
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
                        progress: _progress,
                      ),
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
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
