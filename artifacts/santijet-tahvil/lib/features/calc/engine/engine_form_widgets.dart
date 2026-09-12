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

String _moduleSubtitle(TahvilModule module) => switch (module) {
      TahvilModule.saha => '1 · 2 çeşit · aralık / adet',
      TahvilModule.foundation => 'Tekil · sürekli · radye',
      TahvilModule.column => 'Boyuna donatı · etriye',
      TahvilModule.beam => 'Bölge bazlı · mesnet / açıklık',
      TahvilModule.slab => '1 m şerit · As/m · X / Y',
    };

String _moduleTileHint(TahvilModule module) => switch (module) {
      TahvilModule.saha => 'Hızlı tahvil',
      TahvilModule.foundation => 'Temel tipi',
      TahvilModule.column => 'Kolon + etriye',
      TahvilModule.beam => 'Kiriş bölgeleri',
      TahvilModule.slab => 'Döşeme As/m',
    };

/// Hesap modülü — yatay kart şeridi, ikon + başlık + kısa açıklama.
class EngineModuleBar extends StatelessWidget {
  const EngineModuleBar({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final TahvilModule selected;
  final ValueChanged<TahvilModule> onChanged;

  static const _tileWidth = 112.0;
  static const _tileHeight = 92.0;

  @override
  Widget build(BuildContext context) {
    return SJCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Modül', style: AppTypography.cardLabelMedium),
                    const SizedBox(height: 4),
                    Text(
                      _moduleSubtitle(selected),
                      style: AppTypography.cardBodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.electricBlue.withValues(alpha: 0.12),
                  borderRadius: AppRadii.full,
                  border: Border.all(
                    color: AppColors.electricBlue.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  selected.label,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.electricBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: _tileHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: TahvilModule.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final module = TahvilModule.values[index];
                return _ModuleTile(
                  module: module,
                  selected: module == selected,
                  width: _tileWidth,
                  onTap: () => onChanged(module),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.module,
    required this.selected,
    required this.width,
    required this.onTap,
  });

  final TahvilModule module;
  final bool selected;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.textPrimary;
    final muted = selected
        ? Colors.white.withValues(alpha: 0.82)
        : AppColors.textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.sm,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: width,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.electricBlue
                : AppColors.cardInsetSurface,
            borderRadius: AppRadii.sm,
            border: Border.all(
              color: selected ? AppColors.electricBlue : AppColors.cardBorder,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.electricBlue.withValues(alpha: 0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_moduleIcon(module), size: 22, color: fg),
              const Spacer(),
              Text(
                module.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.cardTitleMedium.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _moduleTileHint(module),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.cardLabelSmall.copyWith(
                  color: muted,
                  fontSize: 10,
                  height: 1.2,
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
