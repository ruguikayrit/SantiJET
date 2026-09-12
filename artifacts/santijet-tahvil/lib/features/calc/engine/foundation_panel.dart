import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../domain/engine/engine.dart';
import 'engine_form_widgets.dart';
import 'engine_result_card.dart';

class FoundationPanel extends StatefulWidget {
  const FoundationPanel({required this.onSave, super.key});

  final EngineSaveFn onSave;

  @override
  State<FoundationPanel> createState() => _FoundationPanelState();
}

class _FoundationPanelState extends State<FoundationPanel> {
  FoundationKind _kind = FoundationKind.raft;
  RebarLayer _layer = RebarLayer.bottom;
  RebarDirection _direction = RebarDirection.x;
  int _projectDia = 12;
  int _newDia = 14;

  late final TextEditingController _width;
  late final TextEditingController _length;
  late final TextEditingController _thickness;
  late final TextEditingController _cover;
  late final TextEditingController _projectSpacing;
  late final TextEditingController _newSpacing;

  @override
  void initState() {
    super.initState();
    _width = TextEditingController(text: '200');
    _length = TextEditingController(text: '200');
    _thickness = TextEditingController(text: '30');
    _cover = TextEditingController(text: '50');
    _projectSpacing = TextEditingController(text: '15');
    _newSpacing = TextEditingController(text: '15');
  }

  @override
  void dispose() {
    _width.dispose();
    _length.dispose();
    _thickness.dispose();
    _cover.dispose();
    _projectSpacing.dispose();
    _newSpacing.dispose();
    super.dispose();
  }

  FoundationTahvilInput? _input() {
    final w = parseDecimal(_width.text);
    final l = parseDecimal(_length.text);
    final t = parseDecimal(_thickness.text);
    final c = parseDecimal(_cover.text);
    final ps = parseDecimal(_projectSpacing.text);
    final ns = parseDecimal(_newSpacing.text);
    if (w == null || l == null || t == null || c == null || ps == null || ns == null) {
      return null;
    }
    return FoundationTahvilInput(
      kind: _kind,
      widthMm: Units.cmToMm(w),
      lengthMm: Units.cmToMm(l),
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
        ? TahvilResult.invalid('Temel ölçülerini ve aralıkları girin.')
        : const FoundationTahvilCalculator().evaluate(input);
    final suggestions = input == null
        ? const <TahvilSuggestion>[]
        : const TahvilSuggester().suggestFoundation(
            base: input,
            newDiameterMm: _newDia,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EngineInputCard(
          title: 'Temel',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EngineChoiceChips(
                values: FoundationKind.values,
                selected: _kind,
                labelOf: (v) => v.label,
                onSelected: (v) => setState(() => _kind = v),
              ),
              const SizedBox(height: AppSpacing.md),
              EngineYellowField(
                label: 'Genişlik (cm)',
                controller: _width,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.sm),
              EngineYellowField(
                label: 'Uzunluk (cm)',
                controller: _length,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.sm),
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
          'Temel · As ${RebarMath.formatArea(result.projectAs!)} → '
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
