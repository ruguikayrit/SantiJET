import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/domain/entities/app_settings.dart';
import 'package:santijet_demir/features/settings/providers/settings_provider.dart';

class ProjectSettingsScreen extends ConsumerStatefulWidget {
  const ProjectSettingsScreen({super.key});

  @override
  ConsumerState<ProjectSettingsScreen> createState() =>
      _ProjectSettingsScreenState();
}

class _ProjectSettingsScreenState extends ConsumerState<ProjectSettingsScreen> {
  TextEditingController? _nameCtrl;
  TextEditingController? _codeCtrl;
  TextEditingController? _locationCtrl;
  double? _progress;

  void _ensureControllers(AppSettings settings) {
    _nameCtrl ??= TextEditingController(text: settings.projectName);
    _codeCtrl ??= TextEditingController(text: settings.projectCode);
    _locationCtrl ??= TextEditingController(text: settings.projectLocation);
    _progress ??= settings.projectProgress;
  }

  @override
  void dispose() {
    _nameCtrl?.dispose();
    _codeCtrl?.dispose();
    _locationCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    _ensureControllers(settings);
    final progress = _progress!;

    return Scaffold(
      appBar: AppBar(title: const Text('Proje Bilgileri')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Proje Adı'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeCtrl,
            decoration: const InputDecoration(labelText: 'Proje Kodu'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _locationCtrl,
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
                  onChanged: (v) => setState(() => _progress = v),
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
          if (settings.projectStartDate != null)
            Text(
              'Başlangıç: ${settings.projectStartDate!.day}.${settings.projectStartDate!.month}.${settings.projectStartDate!.year}',
              style: AppTypography.bodySmall,
            ),
          if (settings.projectEndDate != null)
            Text(
              'Bitiş: ${settings.projectEndDate!.day}.${settings.projectEndDate!.month}.${settings.projectEndDate!.year}',
              style: AppTypography.bodySmall,
            ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              await ref.read(appSettingsProvider.notifier).updateProject(
                    projectName: _nameCtrl!.text,
                    projectCode: _codeCtrl!.text,
                    projectLocation: _locationCtrl!.text,
                    projectProgress: _progress,
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
      ),
    );
  }
}
