import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/settings_store.dart';

/// Aktif şantiye kartı — tıklanınca bottom sheet ile seçim (Beton ProjectSwitcher deseni).
class SantiyeSwitcher extends ConsumerWidget {
  const SantiyeSwitcher({super.key});

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
          surface: AppColors.darkSurfaceElevated,
          onSurface: AppColors.darkTextPrimary,
          onSurfaceVariant: AppColors.darkTextSecondary,
          outline: AppColors.darkBorder,
        ),
        scaffoldBackgroundColor: AppColors.darkSurfaceElevated,
        textTheme: parent.textTheme.apply(
          bodyColor: AppColors.darkTextPrimary,
          displayColor: AppColors.darkTextPrimary,
        ),
      );
    }
    return parent.copyWith(
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.electricBlue,
        onPrimary: Colors.white,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
        onSurfaceVariant: AppColors.lightTextSecondary,
        outline: AppColors.lightBorder,
      ),
      scaffoldBackgroundColor: AppColors.lightSurface,
    );
  }

  Future<void> _openPicker(BuildContext context, WidgetRef ref) async {
    final santiyeler = ref.read(santiyelerProvider);
    final active = ref.read(activeSantiyeProvider);
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
          santiyeler: santiyeler,
          active: active,
          onSelect: (name) {
            ref.read(activeSantiyeProvider.notifier).setActive(name);
            Navigator.pop(ctx);
          },
        ),
      ),
    );
  }

  Widget _pickerBody({
    required BuildContext ctx,
    required ThemeData theme,
    required List<String> santiyeler,
    required String active,
    required ValueChanged<String> onSelect,
  }) {
    if (santiyeler.isEmpty) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Text(
            'Henüz kayıtlı şantiye yok. Ayarlar → Şantiye bölümünden ekleyebilirsiniz.',
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
                itemCount: santiyeler.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final name = santiyeler[index];
                  return _SantiyeOptionTile(
                    label: name,
                    selected: name == active,
                    onTap: () => onSelect(name),
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
    final active = ref.watch(activeSantiyeProvider);
    final surface = AppColors.surfaceElevated;
    final ink = AppColors.readableOn(surface);
    final inkMuted = AppColors.readableMutedOn(surface);

    return Semantics(
      label: 'Aktif şantiye: $active',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openPicker(context, ref),
          borderRadius: AppRadii.md,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: AppRadii.md,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Şantiye',
                        style: AppTypography.labelSmall.copyWith(
                          color: inkMuted,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        active,
                        style: AppTypography.titleMedium.copyWith(
                          color: ink,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.expand_more, color: inkMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SantiyeOptionTile extends StatelessWidget {
  const _SantiyeOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
