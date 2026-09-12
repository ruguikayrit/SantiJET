import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design_system/sj_card.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/rebar_weight.dart';
import '../../../domain/engine/engine.dart';

class EngineModuleBar extends StatelessWidget {
  const EngineModuleBar({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final TahvilModule selected;
  final ValueChanged<TahvilModule> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final module in TahvilModule.values)
          GestureDetector(
            onTap: () => onChanged(module),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: module == selected
                    ? AppColors.electricBlue
                    : AppColors.surface,
                borderRadius: AppRadii.sm,
                border: Border.all(
                  color: module == selected
                      ? AppColors.electricBlue
                      : AppColors.border,
                ),
              ),
              child: Text(
                module.label,
                style: AppTypography.cardLabelLarge.copyWith(
                  color: module == selected
                      ? Colors.white
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
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
