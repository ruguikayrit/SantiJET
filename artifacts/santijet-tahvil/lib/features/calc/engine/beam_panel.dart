import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../domain/engine/engine.dart';
import 'engine_form_widgets.dart';
import 'engine_result_card.dart';

class BeamPanel extends StatefulWidget {
  const BeamPanel({required this.onSave, super.key});

  final EngineSaveFn onSave;

  @override
  State<BeamPanel> createState() => _BeamPanelState();
}

class _BeamPanelState extends State<BeamPanel> {
  BeamRegion _region = BeamRegion.spanBottom;
  StirrupZone _zone = StirrupZone.confinement;
  int _projectDia = 20;
  int _newDia = 16;
  int _stirrupDia = 8;
  int _newStirrupDia = 8;

  late final TextEditingController _width;
  late final TextEditingController _height;
  late final TextEditingController _cover;
  late final TextEditingController _projectCount;
  late final TextEditingController _newCount;
  late final TextEditingController _stirrupSpacing;
  late final TextEditingController _newStirrupSpacing;
  late final TextEditingController _legs;

  @override
  void initState() {
    super.initState();
    _width = TextEditingController(text: '25');
    _height = TextEditingController(text: '50');
    _cover = TextEditingController(text: '25');
    _projectCount = TextEditingController(text: '3');
    _newCount = TextEditingController(text: '5');
    _stirrupSpacing = TextEditingController(text: '10');
    _newStirrupSpacing = TextEditingController(text: '10');
    _legs = TextEditingController(text: '2');
  }

  @override
  void dispose() {
    _width.dispose();
    _height.dispose();
    _cover.dispose();
    _projectCount.dispose();
    _newCount.dispose();
    _stirrupSpacing.dispose();
    _newStirrupSpacing.dispose();
    _legs.dispose();
    super.dispose();
  }

  BeamTahvilInput? _input() {
    final w = parseDecimal(_width.text);
    final h = parseDecimal(_height.text);
    final c = parseDecimal(_cover.text);
    final pn = int.tryParse(_projectCount.text);
    final nn = int.tryParse(_newCount.text);
    final ss = parseDecimal(_stirrupSpacing.text);
    final nss = parseDecimal(_newStirrupSpacing.text);
    final legs = int.tryParse(_legs.text);
    if (w == null ||
        h == null ||
        c == null ||
        pn == null ||
        nn == null ||
        ss == null ||
        nss == null ||
        legs == null) {
      return null;
    }
    return BeamTahvilInput(
      widthMm: Units.cmToMm(w),
      heightMm: Units.cmToMm(h),
      coverMm: c,
      region: _region,
      projectDiameterMm: _projectDia,
      projectCount: pn,
      newDiameterMm: _newDia,
      newCount: nn,
      stirrupDiameterMm: _stirrupDia,
      stirrupSpacingMm: Units.cmToMm(ss),
      newStirrupDiameterMm: _newStirrupDia,
      newStirrupSpacingMm: Units.cmToMm(nss),
      stirrupZone: _zone,
      stirrupLegs: legs,
    );
  }

  @override
  Widget build(BuildContext context) {
    final input = _input();
    final result = input == null
        ? TahvilResult.invalid('Kiriş kesiti ve donatı adetlerini girin.')
        : const BeamTahvilCalculator().evaluate(input);
    final suggestions = input == null
        ? const <TahvilSuggestion>[]
        : const TahvilSuggester().suggestBeam(
            base: input,
            newDiameterMm: _newDia,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EngineInputCard(
          title: 'Kiriş kesiti',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EngineYellowField(
                label: 'Genişlik (cm)',
                controller: _width,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.sm),
              EngineYellowField(
                label: 'Yükseklik (cm)',
                controller: _height,
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
                values: BeamRegion.values,
                selected: _region,
                labelOf: (v) => v.label,
                onSelected: (v) => setState(() => _region = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        EngineInputCard(
          title: 'Proje donatısı (bu bölge)',
          child: Column(
            children: [
              EngineDiameterChips(
                selected: _projectDia,
                onSelected: (d) => setState(() => _projectDia = d),
              ),
              const SizedBox(height: AppSpacing.md),
              EngineYellowField(
                label: 'Adet',
                controller: _projectCount,
                onChanged: (_) => setState(() {}),
                integer: true,
                hint: 'adet',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        EngineInputCard(
          title: 'Yeni donatı (bu bölge)',
          child: Column(
            children: [
              EngineDiameterChips(
                selected: _newDia,
                onSelected: (d) => setState(() => _newDia = d),
              ),
              const SizedBox(height: AppSpacing.md),
              EngineYellowField(
                label: 'Adet',
                controller: _newCount,
                onChanged: (_) => setState(() {}),
                integer: true,
                hint: 'adet',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        EngineInputCard(
          title: 'Etriye',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EngineChoiceChips(
                values: StirrupZone.values,
                selected: _zone,
                labelOf: (v) => v.label,
                onSelected: (v) => setState(() => _zone = v),
              ),
              const SizedBox(height: AppSpacing.md),
              EngineDiameterChips(
                selected: _stirrupDia,
                onSelected: (d) => setState(() => _stirrupDia = d),
              ),
              const SizedBox(height: AppSpacing.sm),
              EngineYellowField(
                label: 'Proje etriye aralığı (cm)',
                controller: _stirrupSpacing,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              EngineDiameterChips(
                selected: _newStirrupDia,
                onSelected: (d) => setState(() => _newStirrupDia = d),
              ),
              const SizedBox(height: AppSpacing.sm),
              EngineYellowField(
                label: 'Yeni etriye aralığı (cm)',
                controller: _newStirrupSpacing,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.sm),
              EngineYellowField(
                label: 'Kol sayısı',
                controller: _legs,
                onChanged: (_) => setState(() {}),
                integer: true,
                hint: 'adet',
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
          'Kiriş · ${_region.label} · As ${RebarMath.formatArea(result.projectAs!)} → '
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
