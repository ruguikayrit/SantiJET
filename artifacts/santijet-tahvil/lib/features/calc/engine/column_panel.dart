import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../domain/engine/engine.dart';
import 'engine_form_widgets.dart';
import 'engine_result_card.dart';

class ColumnPanel extends StatefulWidget {
  const ColumnPanel({required this.onSave, super.key});

  final EngineSaveFn onSave;

  @override
  State<ColumnPanel> createState() => _ColumnPanelState();
}

class _ColumnPanelState extends State<ColumnPanel> {
  int _projectDia = 16;
  int _newDia = 14;
  int _stirrupDia = 8;
  int _newStirrupDia = 8;
  StirrupZone _zone = StirrupZone.confinement;
  bool _hasLap = false;

  late final TextEditingController _width;
  late final TextEditingController _height;
  late final TextEditingController _story;
  late final TextEditingController _cover;
  late final TextEditingController _projectCount;
  late final TextEditingController _newCount;
  late final TextEditingController _stirrupSpacing;
  late final TextEditingController _newStirrupSpacing;
  late final TextEditingController _legs;
  late final TextEditingController _crossties;

  @override
  void initState() {
    super.initState();
    _width = TextEditingController(text: '30');
    _height = TextEditingController(text: '30');
    _story = TextEditingController(text: '300');
    _cover = TextEditingController(text: '25');
    _projectCount = TextEditingController(text: '4');
    _newCount = TextEditingController(text: '6');
    _stirrupSpacing = TextEditingController(text: '10');
    _newStirrupSpacing = TextEditingController(text: '10');
    _legs = TextEditingController(text: '2');
    _crossties = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _width.dispose();
    _height.dispose();
    _story.dispose();
    _cover.dispose();
    _projectCount.dispose();
    _newCount.dispose();
    _stirrupSpacing.dispose();
    _newStirrupSpacing.dispose();
    _legs.dispose();
    _crossties.dispose();
    super.dispose();
  }

  ColumnTahvilInput? _input() {
    final w = parseDecimal(_width.text);
    final h = parseDecimal(_height.text);
    final story = parseDecimal(_story.text);
    final c = parseDecimal(_cover.text);
    final pn = int.tryParse(_projectCount.text);
    final nn = int.tryParse(_newCount.text);
    final ss = parseDecimal(_stirrupSpacing.text);
    final nss = parseDecimal(_newStirrupSpacing.text);
    final legs = int.tryParse(_legs.text);
    final ties = int.tryParse(_crossties.text);
    if (w == null ||
        h == null ||
        story == null ||
        c == null ||
        pn == null ||
        nn == null ||
        ss == null ||
        nss == null ||
        legs == null ||
        ties == null) {
      return null;
    }
    return ColumnTahvilInput(
      widthMm: Units.cmToMm(w),
      heightMm: Units.cmToMm(h),
      storyHeightMm: Units.cmToMm(story),
      coverMm: c,
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
      crosstieCount: ties,
      hasLap: _hasLap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final input = _input();
    final result = input == null
        ? TahvilResult.invalid('Kolon kesiti, adet ve etriye değerlerini girin.')
        : const ColumnTahvilCalculator().evaluate(input);
    final suggestions = input == null
        ? const <TahvilSuggestion>[]
        : const TahvilSuggester().suggestColumn(
            base: input,
            newDiameterMm: _newDia,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EngineInputCard(
          title: 'Kolon kesiti',
          child: Column(
            children: [
              EngineYellowField(
                label: 'Genişlik (cm)',
                controller: _width,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.sm),
              EngineYellowField(
                label: 'Yükseklik / derinliği (cm)',
                controller: _height,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.sm),
              EngineYellowField(
                label: 'Kat yüksekliği (cm)',
                controller: _story,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.sm),
              EngineYellowField(
                label: 'Paspayı (mm)',
                controller: _cover,
                onChanged: (_) => setState(() {}),
                hint: 'mm',
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        EngineInputCard(
          title: 'Proje boyuna donatı',
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
          title: 'Yeni boyuna donatı',
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
          title: 'Etriye / çiroz',
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
              Text('Proje etriye çapı'),
              const SizedBox(height: 6),
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
              Text('Yeni etriye çapı'),
              const SizedBox(height: 6),
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
                label: 'Etriye kol sayısı',
                controller: _legs,
                onChanged: (_) => setState(() {}),
                integer: true,
                hint: 'adet',
              ),
              const SizedBox(height: AppSpacing.sm),
              EngineYellowField(
                label: 'Çiroz sayısı',
                controller: _crossties,
                onChanged: (_) => setState(() {}),
                integer: true,
                hint: 'adet',
              ),
              const SizedBox(height: AppSpacing.md),
              GestureDetector(
                onTap: () => setState(() => _hasLap = !_hasLap),
                child: Row(
                  children: [
                    Icon(
                      _hasLap
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Bindirme bölgesi')),
                  ],
                ),
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
          'Kolon · As ${RebarMath.formatArea(result.projectAs!)} → '
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
