import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design_system/sj_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/rebar_weight.dart';
import '../../../domain/engine/engine.dart';

IconData _moduleIcon(TahvilModule module) => switch (module) {
      TahvilModule.saha => Icons.bolt_rounded,
      TahvilModule.foundation => Icons.layers_outlined,
      TahvilModule.column => Icons.view_column_outlined,
      TahvilModule.beam => Icons.view_agenda_outlined,
      TahvilModule.slab => Icons.grid_on_outlined,
    };

/// Hesap modülü — kompakt yatay şerit (ikon + ad).
class EngineModuleBar extends StatelessWidget {
  const EngineModuleBar({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final TahvilModule selected;
  final ValueChanged<TahvilModule> onChanged;

  static const _stripHeight = 48.0;

  @override
  Widget build(BuildContext context) {
    return SJCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SizedBox(
        height: _stripHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.hardEdge,
          itemCount: TahvilModule.values.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            final module = TahvilModule.values[index];
            return _ModuleTile(
              module: module,
              selected: module == selected,
              onTap: () => onChanged(module),
            );
          },
        ),
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.module,
    required this.selected,
    required this.onTap,
  });

  final TahvilModule module;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.sm,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.electricBlue
                : AppColors.cardInsetSurface,
            borderRadius: AppRadii.sm,
            border: Border.all(
              color: selected ? AppColors.electricBlue : AppColors.cardBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_moduleIcon(module), size: 18, color: fg),
              const SizedBox(width: 6),
              Text(
                module.label,
                style: AppTypography.labelLarge.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EngineInputCard extends StatelessWidget {
  const EngineInputCard({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SJCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTypography.cardLabelMedium),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class EngineYellowField extends StatelessWidget {
  const EngineYellowField({
    required this.label,
    required this.controller,
    required this.onChanged,
    this.integer = false,
    this.hint,
    super.key,
  });

  static const _fill = Color(0xFFFFF8E1);
  static const _ink = Color(0xFF0B1220);

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool integer;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.cardLabelMedium),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              integer ? RegExp(r'[0-9]') : RegExp(r'[0-9.,]'),
            ),
          ],
          onChanged: onChanged,
          style: AppTypography.titleLarge.copyWith(color: _ink),
          decoration: InputDecoration(
            filled: true,
            fillColor: _fill,
            isDense: true,
            hintText: hint,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: const Color(0xFF6B7A90),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: AppRadii.sm,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadii.sm,
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadii.sm,
              borderSide: const BorderSide(color: AppColors.electricBlue),
            ),
          ),
        ),
      ],
    );
  }
}

class EngineDiameterChips extends StatelessWidget {
  const EngineDiameterChips({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final d in RebarWeight.standardDiameters)
          GestureDetector(
            onTap: () => onSelected(d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: d == selected
                    ? AppColors.electricBlue
                    : AppColors.cardInsetSurface,
                borderRadius: AppRadii.sm,
                border: Border.all(
                  color: d == selected
                      ? AppColors.electricBlue
                      : AppColors.cardBorder,
                ),
              ),
              child: Text(
                'Ø$d',
                style: AppTypography.cardLabelLarge.copyWith(
                  color: d == selected
                      ? Colors.white
                      : AppColors.cardTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class EngineChoiceChips<T> extends StatelessWidget {
  const EngineChoiceChips({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    super.key,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          GestureDetector(
            onTap: () => onSelected(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: value == selected
                    ? AppColors.electricBlue
                    : AppColors.cardInsetSurface,
                borderRadius: AppRadii.sm,
                border: Border.all(
                  color: value == selected
                      ? AppColors.electricBlue
                      : AppColors.cardBorder,
                ),
              ),
              child: Text(
                labelOf(value),
                style: AppTypography.cardLabelMedium.copyWith(
                  color: value == selected
                      ? Colors.white
                      : AppColors.cardTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

typedef EngineSaveFn = Future<void> Function({
  required String summary,
  required String detail,
  required bool allowed,
  required String sourceLine,
  required String targetLine,
  required double sourceAs,
  required double targetAs,
  required String asUnit,
});

double? parseDecimal(String raw) =>
    double.tryParse(raw.replaceAll(',', '.'));
