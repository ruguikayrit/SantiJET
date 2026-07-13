import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/widgets/empty_states.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';

/// Aktif proje yokken modül içeriği yerine ortak boş durum gösterir.
class ActiveProjectGate extends ConsumerWidget {
  const ActiveProjectGate({
    super.key,
    required this.child,
    this.inline = false,
  });

  final Widget child;
  final bool inline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(activeProjectProvider) != null) return child;

    return ModuleEmptyState(
      type: EmptyStateType.noProject,
      inline: inline,
      actionLabel: 'Proje Seç',
      onAction: () => context.push(AppRoutes.projects),
    );
  }
}

/// ScrollView / CustomScrollView içinde proje yokken kalan alanı doldurur.
class ActiveProjectSliverGate extends ConsumerWidget {
  const ActiveProjectSliverGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(activeProjectProvider) != null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverFillRemaining(
      hasScrollBody: false,
      child: ModuleEmptyState(
        type: EmptyStateType.noProject,
        actionLabel: 'Proje Seç',
        onAction: () => context.push(AppRoutes.projects),
      ),
    );
  }
}
