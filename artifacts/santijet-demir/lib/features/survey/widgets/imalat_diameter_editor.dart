import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/data/services/rebar_weight_calculator.dart';
import 'package:santijet_demir/domain/entities/survey.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';

class ImalatDiameterEditor extends ConsumerStatefulWidget {
  const ImalatDiameterEditor({
    super.key,
    required this.imalat,
    required this.canEdit,
  });

  final SurveyImalat imalat;
  final bool canEdit;

  @override
  ConsumerState<ImalatDiameterEditor> createState() =>
      _ImalatDiameterEditorState();
}

class _DiameterRowDraft {
  _DiameterRowDraft({
    required this.diameter,
    required this.tonnageController,
  });

  int diameter;
  final TextEditingController tonnageController;
}

class _ImalatDiameterEditorState extends ConsumerState<ImalatDiameterEditor> {
  static const _defaultDiameters = [12, 16, 20, 22];
  late List<_DiameterRowDraft> _rows;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _rows = _rowsFromImalat(widget.imalat);
  }

  @override
  void didUpdateWidget(covariant ImalatDiameterEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imalat.id != widget.imalat.id) {
      _disposeRows();
      _rows = _rowsFromImalat(widget.imalat);
    }
  }

  @override
  void dispose() {
    _disposeRows();
    super.dispose();
  }

  void _disposeRows() {
    for (final row in _rows) {
      row.tonnageController.dispose();
    }
  }

  List<_DiameterRowDraft> _rowsFromImalat(SurveyImalat imalat) {
    if (imalat.diameterLines.isEmpty) {
      return _defaultDiameters
          .map(
            (d) => _DiameterRowDraft(
              diameter: d,
              tonnageController: TextEditingController(),
            ),
          )
          .toList();
    }

    return imalat.diameterLines
        .map(
          (line) => _DiameterRowDraft(
            diameter: line.diameter,
            tonnageController: TextEditingController(
              text: _formatTonnage(line.planned),
            ),
          ),
        )
        .toList();
  }

  String _formatTonnage(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  double get _draftTotal {
    return _rows.fold(
      0.0,
      (sum, row) => sum + _parseTonnage(row.tonnageController.text),
    );
  }

  double _parseTonnage(String text) {
    return double.tryParse(text.trim().replaceAll(',', '.')) ?? 0;
  }

  void _addRow() {
    final used = _rows.map((row) => row.diameter).toSet();
    final next = RebarWeightCalculator.standardDiameters.firstWhere(
      (diameter) => !used.contains(diameter),
      orElse: () => RebarWeightCalculator.standardDiameters.last,
    );
    setState(() {
      _rows.add(
        _DiameterRowDraft(
          diameter: next,
          tonnageController: TextEditingController(),
        ),
      );
    });
  }

  void _removeRow(int index) {
    if (_rows.length <= 1) return;
    setState(() {
      _rows.removeAt(index).tonnageController.dispose();
    });
  }

  Future<void> _save() async {
    final plannedByDiameter = <int, double>{};
    for (final row in _rows) {
      final tonnage = _parseTonnage(row.tonnageController.text);
      if (tonnage <= 0) continue;
      plannedByDiameter[row.diameter] =
          (plannedByDiameter[row.diameter] ?? 0) + tonnage;
    }

    if (plannedByDiameter.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir çap için miktar girin')),
      );
      return;
    }

    setState(() => _saving = true);
    await ref.read(surveyProjectProvider.notifier).updateImalatPlanned(
          imalatId: widget.imalat.id,
          plannedByDiameter: plannedByDiameter,
        );
    if (!mounted) return;
    setState(() => _saving = false);

    // Kayıt sonrası kartın kapanmaması için genişletilmiş durumu koru.
    ref.read(expandedImalatProvider.notifier).state = widget.imalat.id;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${widget.imalat.name} güncellendi — ${_draftTotal.toStringAsFixed(1)}t',
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.canEdit) {
      return _ReadOnlyDiameterLines(imalat: widget.imalat);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: const [
            Expanded(
              child: Text(
                'ÇAP',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'MİKTAR (ton)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            SizedBox(width: 40),
          ],
        ),
        const SizedBox(height: 8),
        ...List.generate(_rows.length, (index) {
          final row = _rows[index];
          final color = AppColors.diameterColor(row.diameter);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: row.diameter,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                    items: RebarWeightCalculator.standardDiameters
                        .map(
                          (diameter) => DropdownMenuItem(
                            value: diameter,
                            child: Text(
                              'Ø$diameter',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.diameterColor(diameter),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => row.diameter = value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: row.tonnageController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: '0',
                      suffixText: 't',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadii.sm,
                        borderSide:
                            BorderSide(color: color.withValues(alpha: 0.4)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadii.sm,
                        borderSide: BorderSide(color: color),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                IconButton(
                  onPressed:
                      _rows.length > 1 ? () => _removeRow(index) : null,
                  icon: const Icon(Icons.close, size: 18),
                  color: AppColors.textMuted,
                ),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addRow,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Çap Ekle'),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceHighlight,
            borderRadius: AppRadii.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Toplam', style: AppTypography.titleMedium),
              Text(
                '${_draftTotal.toStringAsFixed(1)}t',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.electricBlueLight,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Kaydediliyor…' : 'Kaydet'),
        ),
      ],
    );
  }
}

class _ReadOnlyDiameterLines extends StatelessWidget {
  const _ReadOnlyDiameterLines({required this.imalat});

  final SurveyImalat imalat;

  @override
  Widget build(BuildContext context) {
    if (imalat.diameterLines.isEmpty) {
      return Text(
        'Henüz çap/miktar girilmedi',
        style: AppTypography.bodySmall,
      );
    }

    return Column(
      children: imalat.diameterLines.map((line) {
        final color = AppColors.diameterColor(line.diameter);
        final ratio =
            imalat.planned > 0 ? line.planned / imalat.planned * 100 : 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Ø${line.diameter}',
                  style: AppTypography.titleMedium.copyWith(color: color),
                ),
              ),
              Expanded(
                child: Text(
                  line.planned.toStringAsFixed(1),
                  style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                ),
              ),
              Expanded(
                child: Text(
                  imalat.planned > 0 ? '${ratio.toStringAsFixed(0)}%' : '-',
                  style: AppTypography.labelMedium,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
