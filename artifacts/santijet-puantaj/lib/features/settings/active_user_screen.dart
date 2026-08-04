import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/providers/active_operator_provider.dart';
import '../../data/providers/app_data_provider.dart';
import '../../domain/permissions/role_degree.dart';

/// Ayarlar → Yönetim — bu cihazda kim çalışıyor (görev yetkisi).
class ActiveUserScreen extends ConsumerWidget {
  const ActiveUserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(activeProjectProvider);
    final people = ref.watch(activePersonnelProvider);
    final selectedId = ref.watch(activeOperatorIdProvider);
    final operator = ref.watch(activeOperatorProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Aktif kullanıcı'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.yonetim),
        ),
      ),
      body: project == null
          ? SJEmptyState(
              title: 'Önce proje seçin',
              message: 'Aktif kullanıcı, seçili projedeki personelden belirlenir.',
              icon: Icons.apartment_outlined,
              actionLabel: 'Projelere Git',
              onAction: () => context.push(AppRoutes.projeler),
            )
          : people.isEmpty
              ? SJEmptyState(
                  title: 'Personel yok',
                  message: 'Önce aktif personel ekleyin.',
                  icon: Icons.groups_outlined,
                  actionLabel: 'Personele Git',
                  onAction: () => context.push(AppRoutes.personel),
                )
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    SJCard(
                      child: Builder(
                        builder: (context) {
                          final theme = Theme.of(context);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bu cihazda kim çalışıyor?',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Görev görünürlüğü ve atama yetkisi seçilen '
                                'personelin mesleğine (1. derece / saha) göre '
                                'uygulanır. Değişiklik Ayarlar’dan yapılır.',
                                style: theme.textTheme.bodySmall,
                              ),
                              if (operator != null) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Seçili: ${operator.name}'
                                  '${operator.profession.isNotEmpty ? ' · ${operator.profession}' : ''}',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    for (final p in people)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SJCard(
                          selected: p.id == selectedId,
                          onTap: () {
                            ref
                                .read(activeOperatorIdProvider.notifier)
                                .set(p.id);
                          },
                          padding: const EdgeInsets.all(14),
                          child: Builder(
                            builder: (context) {
                              final theme = Theme.of(context);
                              final first = RoleDegree.isFirstDegree(p);
                              final selected = p.id == selectedId;
                              return Row(
                                children: [
                                  Icon(
                                    selected
                                        ? Icons.check_circle
                                        : Icons.person_outline,
                                    color: selected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.name,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          [
                                            if (p.profession.isNotEmpty)
                                              p.profession,
                                            first
                                                ? '1. derece · görev atayabilir'
                                                : 'Yalnızca kendisine atanan görevler',
                                          ].join(' · '),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
