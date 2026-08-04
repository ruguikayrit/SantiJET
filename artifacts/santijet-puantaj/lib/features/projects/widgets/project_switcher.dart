import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/providers/app_data_provider.dart';
import '../../../domain/entities/project.dart';

/// Aktif proje kartı — tıklanınca mevcut işler arasında seçim (sayfa açılmaz).
class ProjectSwitcher extends ConsumerWidget {
  const ProjectSwitcher({super.key});

  Future<void> _openPicker(BuildContext context, WidgetRef ref) async {
    final projects = ref.read(projectsProvider);
    final activeId = ref.read(activeProjectIdProvider) ??
        ref.read(activeProjectProvider)?.id;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surfaceElevated,
      builder: (ctx) {
        final theme = Theme.of(ctx);
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
                style: theme.textTheme.bodyMedium,
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
                    style: theme.textTheme.titleMedium?.copyWith(
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
                      final selected = p.id == activeId;
                      return _ProjectOptionTile(
                        project: p,
                        selected: selected,
                        onTap: () {
                          ref
                              .read(activeProjectIdProvider.notifier)
                              .set(p.id);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(activeProjectProvider);
    final brightness = Theme.of(context).brightness;

    final company = project?.company.trim() ?? '';
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
                  const Icon(
                    Icons.apartment,
                    size: 20,
                    color: AppColors.electricBlueLight,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: project == null
                        ? Text(
                            'Proje seçin',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.inkFor(brightness),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                company.isEmpty ? 'Firma adı yok' : company,
                                style: AppTypography.titleMedium.copyWith(
                                  color: AppColors.inkFor(brightness),
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                name.isEmpty ? 'İşin adı yok' : name,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.inkSecondaryFor(brightness),
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                code.isEmpty ? 'İşin kodu yok' : code,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.inkMutedFor(brightness),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.expand_more,
                    color: AppColors.inkMutedFor(brightness),
                  ),
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
    required this.selected,
    required this.onTap,
  });

  final Project project;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final company = project.company.trim();
    final name = project.name.trim();
    final code = project.code.trim();

    return Material(
      color: selected
          ? theme.colorScheme.primary.withValues(alpha: 0.08)
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.isEmpty ? 'Firma adı yok' : company,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name.isEmpty ? 'İşin adı yok' : name,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (code.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        code,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
