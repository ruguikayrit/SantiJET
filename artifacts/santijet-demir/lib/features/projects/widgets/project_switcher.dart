import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/domain/entities/project.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/projects/widgets/project_company_logo.dart';
import 'package:santijet_demir/features/settings/providers/settings_provider.dart';

/// Aktif proje kartı — Saha ile aynı: firma / iş adı / iş kodu + alt sayfa seçici.
class ProjectSwitcher extends ConsumerWidget {
  const ProjectSwitcher({super.key});

  Future<void> _openPicker(BuildContext context, WidgetRef ref) async {
    final projects = ref.read(userProjectsProvider);
    final activeId = ref.read(activeProjectIdProvider) ??
        ref.read(activeProjectProvider)?.id;
    final company =
        ref.read(appSettingsProvider.select((s) => s.companyName)).trim();
    final sheetSurface = AppColors.surfaceElevated;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: sheetSurface,
      builder: (ctx) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(
                surface: sheetSurface,
                onSurface: AppColors.textPrimary,
                onSurfaceVariant: AppColors.textSecondary,
                primary: AppColors.electricBlueLight,
              ),
        ),
        child: _pickerBody(
          ctx: ctx,
          projects: projects,
          activeId: activeId,
          company: company,
          onSelect: (id) async {
            await ref.read(projectsControllerProvider).switchProject(id);
            if (ctx.mounted) Navigator.pop(ctx);
          },
        ),
      ),
    );
  }

  Widget _pickerBody({
    required BuildContext ctx,
    required List<Project> projects,
    required String? activeId,
    required String company,
    required ValueChanged<String> onSelect,
  }) {
    if (projects.isEmpty) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Text(
            'Henüz kayıtlı iş yok. Ayarlar → Projeler’den ekleyebilirsiniz.',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.55,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Text(
                'İş seçin',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                itemCount: projects.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final p = projects[index];
                  return _ProjectOptionTile(
                    project: p,
                    company: company,
                    selected: p.id == activeId,
                    onTap: () => onSelect(p.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(activeProjectProvider);
    final company =
        ref.watch(appSettingsProvider.select((s) => s.companyName)).trim();

    final name = project?.name.trim() ?? '';
    final code = project?.code.trim() ?? '';

    return Semantics(
      label: project == null ? 'Proje seçin' : 'Aktif iş: $name',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openPicker(context, ref),
          borderRadius: AppRadii.md,
          child: Tooltip(
            message: project == null ? 'Proje seçin' : 'İş değiştir',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: AppRadii.md,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const ProjectCompanyLogo(size: 36, iconSize: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: project == null
                        ? Text(
                            'Proje seçin',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                company.isEmpty ? 'Firma adı yok' : company,
                                style: AppTypography.titleMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                name.isEmpty ? 'İşin adı yok' : name,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                code.isEmpty ? 'İşin kodu yok' : code,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(Icons.expand_more, color: AppColors.textMuted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectOptionTile extends StatelessWidget {
  const _ProjectOptionTile({
    required this.project,
    required this.company,
    required this.selected,
    required this.onTap,
  });

  final Project project;
  final String company;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = project.name.trim();
    final code = project.code.trim();

    return Material(
      color: selected
          ? AppColors.electricBlue.withValues(alpha: 0.08)
          : Colors.transparent,
      borderRadius: AppRadii.md,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.md,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              const ProjectCompanyLogo(size: 36, iconSize: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.isEmpty ? 'Firma adı yok' : company,
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name.isEmpty ? 'İşin adı yok' : name,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (code.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        code,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.electricBlueLight,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
