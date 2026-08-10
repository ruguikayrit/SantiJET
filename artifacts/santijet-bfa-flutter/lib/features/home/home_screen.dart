import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_empty_state.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/kesif_provider.dart';
import '../projects/widgets/project_switcher.dart';

/// Ana sayfa — şantiye seçimi (özet içerik sonra eklenecek).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(activeKesifProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SantijetHeader(showWordmark: true),
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: ProjectSwitcher(),
            ),
            if (project == null)
              Expanded(
                child: SJEmptyState(
                  title: 'Önce şantiye ekleyin',
                  message:
                      'Keşif, metraj ve yaklaşık maliyet için en az bir proje gerekli.',
                  icon: Icons.apartment_outlined,
                  actionLabel: 'Projelerim',
                  onAction: () => context.push(AppRoutes.projeler),
                ),
              )
            else
              const Spacer(),
          ],
        ),
      ),
    );
  }
}
