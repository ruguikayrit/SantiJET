import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../domain/engine/engine.dart';
import 'engine_form_widgets.dart';
import 'engine_result_card.dart';

class SlabPanel extends StatefulWidget {
  const SlabPanel({required this.onSave, super.key});

  final EngineSaveFn onSave;

  @override
  State<SlabPanel> createState() => _SlabPanelState();
}

class _SlabPanelState extends State<SlabPanel> {
  RebarLayer _layer = RebarLayer.bottom;
  RebarDirection _direction = RebarDirection.x;
  int _projectDia = 10;
  int _newDia = 8;

  late final TextEditingController _thickness;
  late final TextEditingController _cover;
  late final TextEditingController _projectSpacing;
  late final TextEditingController _newSpacing;

  @override
  void initState() {
    super.initState();
    _thickness = TextEditingController(text: '15');
    _cover = TextEditingController(text: '20');
    _projectSpacing = TextEditingController(text: '20');
    _newSpacing = TextEditingController(text: '12.5');
  }

  @override
  void dispose() {
    _thickness.dispose();
    _cover.dispose();
    _projectSpacing.dispose();
    _newSpacing.dispose();
    super.dispose();
  }

  SlabTahvilInput? _input() {
    final t = parseDecimal(_thickness.text);
    final c = parseDecimal(_cover.text);
    final ps = parseDecimal(_projectSpacing.text);
    final ns = parseDecimal(_newSpacing.text);
    if (t == null || c == null || ps == null || ns == null) return null;
    return SlabTahvilInput(
      thicknessMm: Units.cmToMm(t),
      coverMm: c,
      projectDiameterMm: _projectDia,
      projectSpacingMm: Units.cmToMm(ps),
      newDiameterMm: _newDia,
      newSpacingMm: Units.cmToMm(ns),
      layer: _layer,
      direction: _direction,
    );
  }

  @override
  Widget build(BuildContext context) {
    final input = _input();
    final result = input == null
        ? TahvilResult.invalid('Döşeme kalınlığı ve aralıkları girin.')
        : const SlabTahvilCalculator().evaluate(input);
    final suggestions = input == null
        ? const <TahvilSuggestion>[]
        : const TahvilSuggester().suggestSlab(
            base: input,
            newDiameterMm: _newDia,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EngineInputCard(
          title: 'Döşeme',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EngineYellowField(
                label: 'Kalınlık (cm)',
                controller: _thickness,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.sm),
              EngineYellowField(
                label: 'Paspayı (mm)',
                controller: _cover,
                onChanged: (_) => setState(() {}),
                hint: 'mm',
              ),
              const SizedBox(height: AppSpacing.md),
              EngineChoiceChips(
                values: RebarLayer.values,
                selected: _layer,
                labelOf: (v) => v.label,
                onSelected: (v) => setState(() => _layer = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              EngineChoiceChips(
                values: RebarDirection.values,
                selected: _direction,
                labelOf: (v) => v.label,
                onSelected: (v) => setState(() => _direction = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        EngineInputCard(
          title: 'Proje donatısı',
          child: Column(
            children: [
              EngineDiameterChips(
                selected: _projectDia,
                onSelected: (d) => setState(() => _projectDia = d),
              ),
              const SizedBox(height: AppSpacing.md),
              EngineYellowField(
                label: 'Aralık (cm)',
                controller: _projectSpacing,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        EngineInputCard(
          title: 'Yeni donatı',
          child: Column(
            children: [
              EngineDiameterChips(
                selected: _newDia,
                onSelected: (d) => setState(() => _newDia = d),
              ),
              const SizedBox(height: AppSpacing.md),
              EngineYellowField(
                label: 'Aralık (cm)',
                controller: _newSpacing,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        EngineResultCard(
          result: result,
          onSave: () => _save(result),
        ),
        const SizedBox(height: AppSpacing.md),
        EngineSuggestionsBlock(suggestions: suggestions),
      ],
    );
  }

  void _save(TahvilResult result) {
    if (!result.isValid || result.projectAs == null || result.newAs == null) {
      return;
    }
    widget.onSave(
      summary: '${result.projectLine} → ${result.newLine}',
      detail:
          'Döşeme · As ${RebarMath.formatArea(result.projectAs!)} → '
          '${RebarMath.formatArea(result.newAs!)} ${result.asUnit}',
      allowed: result.verdict != TahvilVerdict.notSuitable,
      sourceLine: result.projectLine ?? '',
      targetLine: result.newLine ?? '',
      sourceAs: result.projectAs!,
      targetAs: result.newAs!,
      asUnit: result.asUnit,
    );
  }
}
