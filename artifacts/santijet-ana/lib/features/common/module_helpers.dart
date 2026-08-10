import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/routing/app_routes.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/sj_header.dart';
import '../../data/providers/app_state_provider.dart';
import '../../domain/models/page_key.dart';
import '../../domain/models/project.dart';

String newEntityId() {
  final now = DateTime.now().millisecondsSinceEpoch;
  final r = Random().nextInt(1 << 32).toRadixString(36);
  return '$now$r';
}

String todayIso() => DateTime.now().toIso8601String().substring(0, 10);

double parseNum(String? raw) =>
    double.tryParse((raw ?? '').replaceAll(',', '.').trim()) ?? 0;

String fmtNum(num n, {int maxFrac = 2}) {
  if (!n.isFinite) return '0';
  return NumberFormat.decimalPattern('tr_TR')
      .format(double.parse(n.toStringAsFixed(maxFrac)));
}

String fmtMoney(num n) =>
    '${NumberFormat.decimalPattern('tr_TR').format(n.round())} ₺';

void goBackOrHome(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.home);
  }
}

/// İzin yoksa ana sayfaya döner; edit yetkisi döner.
bool guardPage(BuildContext context, WidgetRef ref, PageKey pageKey) {
  final perm = ref.read(appStateProvider).getPermission(pageKey);
  if (perm == Permission.none) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) goBackOrHome(context);
    });
    return false;
  }
  return perm == Permission.edit;
}

Future<bool> confirmDelete(BuildContext context, String title) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: const Text('Bu kaydı silmek istediğinize emin misiniz?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('İptal'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Sil'),
        ),
      ],
    ),
  );
  return ok == true;
}

class ModuleScaffold extends ConsumerWidget {
  const ModuleScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.trailing,
    this.floatingActionButton,
    this.bottom,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final Widget? trailing;
  final Widget? floatingActionButton;
  final Widget? bottom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeDefinitionProvider).colors;
    return Scaffold(
      backgroundColor: colors.background,
      floatingActionButton: floatingActionButton,
      body: Column(
        children: [
          SjHeader(
            title: title,
            subtitle: subtitle,
            onBack: () => goBackOrHome(context),
            trailing: trailing,
          ),
          if (bottom != null) bottom!,
          Expanded(child: body),
        ],
      ),
    );
  }
}

class ProjectFilterBar extends ConsumerWidget {
  const ProjectFilterBar({
    super.key,
    required this.value,
    required this.onChanged,
    this.allowAll = true,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final bool allowAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeDefinitionProvider).colors;
    final projects = ref.watch(appStateProvider).projects;
    if (projects.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          if (allowAll)
            _chip(
              label: 'Tüm Projeler',
              selected: value == null,
              colors: colors,
              onTap: () => onChanged(null),
            ),
          ...projects.map(
            (p) => _chip(
              label: p.name,
              selected: value == p.id,
              colors: colors,
              onTap: () => onChanged(value == p.id && allowAll ? null : p.id),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required dynamic colors,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
      child: ChoiceChip(
        label: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: selected ? Colors.white : colors.foreground,
          ),
        ),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: colors.primary,
        backgroundColor: colors.muted,
        side: BorderSide.none,
      ),
    );
  }
}

class SjDropdownField<T> extends ConsumerWidget {
  const SjDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeDefinitionProvider).colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(color: colors.foreground),
        ),
        const SizedBox(height: AppSpacing.xxs),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.card,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            border: OutlineInputBorder(
              borderRadius: AppRadii.md,
              borderSide: BorderSide(color: colors.input),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadii.md,
              borderSide: BorderSide(color: colors.input),
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> showFormSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String title,
  required Widget child,
  double heightFactor = 0.92,
}) {
  final colors = ref.read(themeDefinitionProvider).colors;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: colors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * heightFactor,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.headlineMedium.copyWith(
                          color: colors.foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(Icons.close, color: colors.mutedForeground),
                    ),
                  ],
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      );
    },
  );
}

String projectNameOf(List<Project> projects, String id) {
  for (final p in projects) {
    if (p.id == id) return p.name;
  }
  return '—';
}

class EntityCard extends ConsumerWidget {
  const EntityCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.onDelete,
    this.extra,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final Widget? extra;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeDefinitionProvider).colors;
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      color: colors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.md,
        side: BorderSide(color: colors.border.withValues(alpha: 0.6)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.md,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.titleMedium.copyWith(
                        color: colors.foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                  if (onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      icon: Icon(Icons.delete_outline,
                          color: colors.destructive, size: 20),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ],
              if (extra != null) ...[
                const SizedBox(height: 8),
                extra!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}
