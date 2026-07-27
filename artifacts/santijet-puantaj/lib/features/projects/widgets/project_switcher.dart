import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/providers/app_data_provider.dart';

/// Aktif proje kartı — Demir `ProjectSwitcher` düzeni.
class ProjectSwitcher extends ConsumerWidget {
  const ProjectSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(activeProjectProvider);
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Semantics(
      label: project == null
          ? 'Proje seçin'
          : 'Aktif proje: ${project.name}',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(AppRoutes.projeler),
          borderRadius: AppRadii.md,
          child: Tooltip(
            message: project == null ? 'Proje seçin' : 'Projeyi değiştir',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceElevated
                    : AppColors.lightSurface,
                borderRadius: AppRadii.md,
                border: Border.all(
                  color: isDark ? AppColors.border : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.apartment,
                    size: 18,
                    color: AppColors.electricBlueLight,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project?.name ?? 'Proje seçin',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.inkFor(brightness),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (project != null)
                          Text(
                            project.code.trim().isEmpty
                                ? 'Kod yok'
                                : 'Kod: ${project.code}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.inkMutedFor(brightness),
                            ),
                          ),
                      ],
                    ),
                  ),
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
