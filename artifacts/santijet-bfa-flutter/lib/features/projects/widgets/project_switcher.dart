import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/providers/kesif_provider.dart';
import '../../../domain/entities/kesif.dart';

/// Aktif şantiye / proje kartı — tıklanınca mevcut işler arasında seçim.
class ProjectSwitcher extends ConsumerWidget {
  const ProjectSwitcher({super.key});

  Future<void> _openPicker(BuildContext context, WidgetRef ref) async {
    final projects = ref.read(kesifProvider);
    final activeId = ref.read(activeKesifIdProvider) ??
        ref.read(activeKesifProvider)?.id;

    final sheetTheme = _sheetThemeOf(context);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _sheetSurface,
      builder: (ctx) => Theme(
        data: sheetTheme,
        child: _pickerBody(
          ctx: ctx,
          theme: sheetTheme,
          projects: projects,
          activeId: activeId,
          onSelect: (id) {
            ref.read(activeKesifIdProvider.notifier).set(id);
            Navigator.pop(ctx);
          },
          onManage: () {
            Navigator.pop(ctx);
            context.push(AppRoutes.projeler);
          },
        ),
      ),
    );
  }

  static Color get _sheetSurface => AppColors.useDarkChrome
      ? AppColors.darkSurfaceElevated
      : AppColors.lightSurface;

  static ThemeData _sheetThemeOf(BuildContext context) {
    final parent = Theme.of(context);
    if (AppColors.useDarkChrome) {
      return parent.copyWith(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.electricBlueLight,
          onPrimary: AppColors.darkTextPrimary,
          secondary: AppColors.electricBlueLight,
          onSecondary: AppColors.darkTextPrimary,
          surface: AppColors.darkSurfaceElevated,
          onSurface: AppColors.darkTextPrimary,
          onSurfaceVariant: AppColors.darkTextSecondary,
          outline: AppColors.darkBorder,
          error: AppColors.critical,
          onError: AppColors.darkTextPrimary,
        ),
        scaffoldBackgroundColor: AppColors.darkSurfaceElevated,
        canvasColor: AppColors.darkSurfaceElevated,
        cardColor: AppColors.darkSurfaceElevated,
        dividerColor: AppColors.darkBorder,
        textTheme: parent.textTheme.apply(
          bodyColor: AppColors.darkTextPrimary,
          displayColor: AppColors.darkTextPrimary,
        ),
        iconTheme: const IconThemeData(color: AppColors.darkTextSecondary),
      );
    }
    return parent.copyWith(
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.electricBlue,
        onPrimary: Colors.white,
        secondary: AppColors.electricBlueLight,
        onSecondary: Colors.white,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
        onSurfaceVariant: AppColors.lightTextSecondary,
        outline: AppColors.lightBorder,
        error: AppColors.critical,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.lightSurface,
      canvasColor: AppColors.lightSurface,
      cardColor: AppColors.lightSurface,
      dividerColor: AppColors.lightBorder,
      textTheme: parent.textTheme.apply(
        bodyColor: AppColors.lightTextPrimary,
        displayColor: AppColors.lightTextPrimary,
      ),
      iconTheme: const IconThemeData(color: AppColors.lightTextSecondary),
    );
  }

  Widget _pickerBody({
    required BuildContext ctx,
    required ThemeData theme,
    required List<KesifProject> projects,
    required String? activeId,
    required ValueChanged<String> onSelect,
    required VoidCallback onManage,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Henüz kayıtlı şantiye yok. Projelerim’den ekleyebilirsiniz.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: onManage,
                child: const Text('Projelerim'),
              ),
            ],
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
                'Şantiye seçin',
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
                  return _ProjectOptionTile(
                    project: p,
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
    final project = ref.watch(activeKesifProvider);
    final surface = AppColors.surfaceElevated;
    final ink = AppColors.readableOn(surface);
    final inkSecondary = AppColors.readableSecondaryOn(surface);
    final inkMuted = AppColors.readableMutedOn(surface);

    final ad = project?.ad.trim() ?? '';
    final konum = project?.konum.trim() ?? '';
    final kod = project?.kod.trim() ?? '';

    return Semantics(
      label: project == null ? 'Şantiye seçin' : 'Aktif şantiye: $ad',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openPicker(context, ref),
          borderRadius: AppRadii.md,
          child: Tooltip(
            message: project == null ? 'Şantiye seçin' : 'Şantiye değiştir',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: AppRadii.md,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.apartment,
                    size: 20,
                    color: AppColors.useDarkChrome
                        ? AppColors.electricBlueLight
                        : AppColors.electricBlue,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: project == null
                        ? Text(
                            'Şantiye seçin',
                            style: AppTypography.titleMedium.copyWith(
                              color: ink,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ad.isEmpty ? 'Şantiye adı yok' : ad,
                                style: AppTypography.titleMedium.copyWith(
                                  color: ink,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                konum.isEmpty ? 'Konum yok' : konum,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: inkSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                kod.isEmpty ? 'Proje kodu yok' : kod,
                                style: AppTypography.bodySmall.copyWith(
                                  color: inkMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(Icons.expand_more, color: inkMuted),
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

  final KesifProject project;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ad = project.ad.trim();
    final konum = project.konum.trim();
    final kod = project.kod.trim();

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
                      ad.isEmpty ? 'Şantiye adı yok' : ad,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      konum.isEmpty ? 'Konum yok' : konum,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (kod.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        kod,
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
