import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_toast.dart';
import 'package:santijet_demir/core/widgets/empty_states.dart';
import 'package:santijet_demir/domain/entities/survey.dart';
import 'package:santijet_demir/domain/entities/workforce.dart';
import 'package:santijet_demir/features/prediction/providers/workforce_provider.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';

class WorkforceScreen extends ConsumerStatefulWidget {
  const WorkforceScreen({super.key});

  @override
  ConsumerState<WorkforceScreen> createState() => _WorkforceScreenState();
}

class _WorkforceScreenState extends ConsumerState<WorkforceScreen> {
  final _drafts = <String, _DayDraft>{};
  var _dirty = false;
  var _saving = false;

  @override
  void dispose() {
    for (final draft in _drafts.values) {
      draft.dispose();
    }
    super.dispose();
  }

  List<_DayDraft> _ensureDrafts(List<WorkforceEntry> entries) {
    final keys = entries.map((e) => e.id).toSet();
    for (final key in _drafts.keys.toList()) {
      if (!keys.contains(key) && !key.startsWith('new-')) {
        _drafts.remove(key)?.dispose();
      }
    }
    for (final entry in entries) {
      _drafts.putIfAbsent(entry.id, () => _DayDraft.fromEntry(entry));
    }
    final ordered = <_DayDraft>[
      for (final entry in entries) _drafts[entry.id]!,
      ..._drafts.values.where((d) => d.id.startsWith('new-')),
    ];
    ordered.sort((a, b) => b.date.compareTo(a.date));
    return ordered;
  }

  void _addDay() {
    final id = 'new-${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _drafts[id] = _DayDraft(
        id: id,
        date: DateTime.now(),
        kalfa: '0',
        lines: [_LineDraft.newEmpty()],
      );
      _dirty = true;
    });
  }

  Future<void> _saveAll(List<_DayDraft> drafts) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final parsed = <WorkforceEntry>[];
      for (final draft in drafts) {
        final entry = draft.toEntry();
        if (entry == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showAppSnackBar(
            SnackBar(
              content: Text(
                '${DateFormat('d MMM', 'tr_TR').format(draft.date)}: '
                'geçersiz değer',
              ),
            ),
          );
          return;
        }
        if (!entry.hasLabor && entry.lines.every((l) => l.imalatName.trim().isEmpty)) {
          continue;
        }
        if (entry.lines.any((l) => l.hasLabor && l.imalatName.trim().isEmpty)) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showAppSnackBar(
            SnackBar(
              content: Text(
                '${DateFormat('d MMM', 'tr_TR').format(draft.date)}: '
                'imalat adı gerekli',
              ),
            ),
          );
          return;
        }
        parsed.add(entry);
      }

      final notifier = ref.read(workforceProvider.notifier);
      for (final entry in parsed) {
        await notifier.upsert(entry);
      }
      for (final key in _drafts.keys.toList()) {
        if (key.startsWith('new-')) {
          _drafts.remove(key)?.dispose();
        }
      }
      if (!mounted) return;
      setState(() => _dirty = false);
      ScaffoldMessenger.of(context).showAppSnackBar(
        const SnackBar(content: Text('Puantaj kaydedildi')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteDay(_DayDraft draft) async {
    if (!draft.id.startsWith('new-')) {
      await ref.read(workforceProvider.notifier).delete(draft.id);
    }
    setState(() {
      _drafts.remove(draft.id)?.dispose();
      _dirty = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(workforceProvider);
    final canEdit = ref.watch(canEditActiveProjectProvider);
    final hasProject = ref.watch(activeProjectIdProvider) != null;
    final imalats = ref.watch(surveyProjectProvider).imalats;
    final drafts = _ensureDrafts(entries);
    final dateFmt = DateFormat('d MMMM yyyy', 'tr_TR');

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Günlük Puantaj'),
        actions: [
          if (canEdit && hasProject)
            TextButton(
              onPressed: _saving || (!_dirty && drafts.isEmpty)
                  ? null
                  : () => _saveAll(drafts),
              child: Text(_saving ? '...' : 'Kaydet'),
            ),
        ],
      ),
      floatingActionButton: hasProject && canEdit
          ? FloatingActionButton.extended(
              onPressed: _addDay,
              icon: const Icon(Icons.add),
              label: const Text('Gün ekle'),
            )
          : null,
      body: !hasProject
          ? const ModuleEmptyState(type: EmptyStateType.noProject)
          : drafts.isEmpty
              ? ModuleEmptyState(
                  type: EmptyStateType.noActivity,
                  actionLabel: canEdit ? 'İlk günü ekle' : null,
                  onAction: canEdit ? _addDay : null,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    100,
                  ),
                  itemCount: drafts.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Her gün için kalfa (bilgi) ve imalat satırları girin. '
                          'Adam-gün = (tam×8 + yarım×4 + mesai_saat×kişi) / 8. '
                          'Kalfa hesaba girmez.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      );
                    }
                    final draft = drafts[index - 1];
                    return _DayCard(
                      draft: draft,
                      dateLabel: dateFmt.format(draft.date),
                      canEdit: canEdit,
                      imalats: imalats,
                      onChanged: () => setState(() => _dirty = true),
                      onPickDate: canEdit
                          ? () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: draft.date,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() {
                                  draft.date = picked;
                                  _dirty = true;
                                });
                              }
                            }
                          : null,
                      onDelete: canEdit ? () => _deleteDay(draft) : null,
                      onAddLine: canEdit
                          ? () => setState(() {
                                draft.lines.add(_LineDraft.newEmpty());
                                _dirty = true;
                              })
                          : null,
                      onRemoveLine: canEdit
                          ? (line) => setState(() {
                                line.dispose();
                                draft.lines.remove(line);
                                if (draft.lines.isEmpty) {
                                  draft.lines.add(_LineDraft.newEmpty());
                                }
                                _dirty = true;
                              })
                          : null,
                    );
                  },
                ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.draft,
    required this.dateLabel,
    required this.canEdit,
    required this.imalats,
    required this.onChanged,
    this.onPickDate,
    this.onDelete,
    this.onAddLine,
    this.onRemoveLine,
  });

  final _DayDraft draft;
  final String dateLabel;
  final bool canEdit;
  final List<SurveyImalat> imalats;
  final VoidCallback onChanged;
  final VoidCallback? onPickDate;
  final VoidCallback? onDelete;
  final VoidCallback? onAddLine;
  final ValueChanged<_LineDraft>? onRemoveLine;

  @override
  Widget build(BuildContext context) {
    final ustaGun = draft.previewUstaAdamGun;
    final duzGun = draft.previewDuzAdamGun;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onPickDate,
                  child: Text(
                    dateLabel,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Text(
                'Σ ${ (ustaGun + duzGun).toStringAsFixed(2) } adam.gün',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.electricBlueLight,
                ),
              ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: AppColors.textMuted,
                  onPressed: onDelete,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Kalfa (bilgi)', style: AppTypography.labelMedium),
              const SizedBox(width: 12),
              SizedBox(
                width: 64,
                child: _NumField(
                  controller: draft.kalfa,
                  enabled: canEdit,
                  onChanged: (_) => onChanged(),
                ),
              ),
              const Spacer(),
              Text(
                'Usta ${ustaGun.toStringAsFixed(2)} · Düz ${duzGun.toStringAsFixed(2)}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Çalışma (imalat)', style: AppTypography.labelMedium),
          const SizedBox(height: 8),
          for (final line in draft.lines) ...[
            _ImalatLineEditor(
              line: line,
              canEdit: canEdit,
              imalats: imalats,
              onChanged: onChanged,
              onRemove: onRemoveLine == null ? null : () => onRemoveLine!(line),
            ),
            const SizedBox(height: 10),
          ],
          if (onAddLine != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onAddLine,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('İmalat satırı'),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImalatLineEditor extends StatelessWidget {
  const _ImalatLineEditor({
    required this.line,
    required this.canEdit,
    required this.imalats,
    required this.onChanged,
    this.onRemove,
  });

  final _LineDraft line;
  final bool canEdit;
  final List<SurveyImalat> imalats;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  static const _manualValue = '__manual__';

  @override
  Widget build(BuildContext context) {
    final selected = line.imalatId ??
        (line.manualMode || imalats.isEmpty ? _manualValue : null);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: AppRadii.sm,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selected != null &&
                          (selected == _manualValue ||
                              imalats.any((i) => i.id == selected))
                      ? selected
                      : (imalats.isEmpty ? _manualValue : null),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: 'İmalat',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    ...imalats.map(
                      (imalat) => DropdownMenuItem(
                        value: imalat.id,
                        child: Text(imalat.name, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    const DropdownMenuItem(
                      value: _manualValue,
                      child: Text('Manuel yaz…'),
                    ),
                  ],
                  onChanged: !canEdit
                      ? null
                      : (value) {
                          if (value == null) return;
                          if (value == _manualValue) {
                            line.imalatId = null;
                            line.manualMode = true;
                          } else {
                            line.imalatId = value;
                            line.manualMode = false;
                            final matches =
                                imalats.where((i) => i.id == value);
                            if (matches.isNotEmpty) {
                              line.name.text = matches.first.name;
                            }
                          }
                          onChanged();
                        },
                ),
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, size: 18),
                  color: AppColors.textMuted,
                ),
            ],
          ),
          if (line.manualMode || selected == _manualValue) ...[
            const SizedBox(height: 8),
            TextField(
              controller: line.name,
              enabled: canEdit,
              decoration: const InputDecoration(
                isDense: true,
                labelText: 'İmalat adı (manuel)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => onChanged(),
            ),
          ],
          const SizedBox(height: 10),
          Text('Usta', style: AppTypography.labelSmall),
          const SizedBox(height: 4),
          _CrewRow(crew: line.usta, canEdit: canEdit, onChanged: onChanged),
          const SizedBox(height: 8),
          Text('Düz işçi', style: AppTypography.labelSmall),
          const SizedBox(height: 4),
          _CrewRow(crew: line.duz, canEdit: canEdit, onChanged: onChanged),
          const SizedBox(height: 6),
          Text(
            '→ Usta ${line.usta.previewAdamGun.toStringAsFixed(2)} adam.gün · '
            'Düz ${line.duz.previewAdamGun.toStringAsFixed(2)} adam.gün',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.electricBlueLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _CrewRow extends StatelessWidget {
  const _CrewRow({
    required this.crew,
    required this.canEdit,
    required this.onChanged,
  });

  final _CrewDraft crew;
  final bool canEdit;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _LabeledNum(
            label: 'Tam',
            controller: crew.tam,
            enabled: canEdit,
            onChanged: onChanged,
          ),
          _LabeledNum(
            label: 'Yarım',
            controller: crew.yarim,
            enabled: canEdit,
            onChanged: onChanged,
          ),
          _LabeledNum(
            label: 'Mesai kişi',
            controller: crew.mesaiKisi,
            enabled: canEdit,
            onChanged: onChanged,
            width: 72,
          ),
          _LabeledNum(
            label: 'Mesai saat',
            controller: crew.mesaiSaat,
            enabled: canEdit,
            onChanged: onChanged,
            decimal: true,
            width: 72,
          ),
        ],
      ),
    );
  }
}

class _LabeledNum extends StatelessWidget {
  const _LabeledNum({
    required this.label,
    required this.controller,
    required this.enabled,
    required this.onChanged,
    this.decimal = false,
    this.width = 56,
  });

  final String label;
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onChanged;
  final bool decimal;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: width,
            child: _NumField(
              controller: controller,
              enabled: enabled,
              decimal: decimal,
              onChanged: (_) => onChanged(),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  const _NumField({
    required this.controller,
    required this.enabled,
    required this.onChanged,
    this.decimal = false,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      inputFormatters: [
        if (decimal)
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
        else
          FilteringTextInputFormatter.digitsOnly,
      ],
      style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        border: OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }
}

class _CrewDraft {
  _CrewDraft({
    required String tam,
    required String yarim,
    required String mesaiKisi,
    required String mesaiSaat,
  })  : tam = TextEditingController(text: tam),
        yarim = TextEditingController(text: yarim),
        mesaiKisi = TextEditingController(text: mesaiKisi),
        mesaiSaat = TextEditingController(text: mesaiSaat);

  factory _CrewDraft.fromHours(WorkforceCrewHours hours) {
    return _CrewDraft(
      tam: '${hours.tam}',
      yarim: '${hours.yarim}',
      mesaiKisi: '${hours.mesaiKisi}',
      mesaiSaat: hours.mesaiSaat.toString().replaceAll('.0', ''),
    );
  }

  factory _CrewDraft.empty() =>
      _CrewDraft(tam: '0', yarim: '0', mesaiKisi: '0', mesaiSaat: '0');

  final TextEditingController tam;
  final TextEditingController yarim;
  final TextEditingController mesaiKisi;
  final TextEditingController mesaiSaat;

  double get previewAdamGun {
    final hours = toHours();
    return hours?.adamGun ?? 0;
  }

  WorkforceCrewHours? toHours() {
    final t = int.tryParse(tam.text.trim());
    final y = int.tryParse(yarim.text.trim());
    final mk = int.tryParse(mesaiKisi.text.trim());
    final ms = double.tryParse(mesaiSaat.text.replaceAll(',', '.').trim());
    if (t == null || y == null || mk == null || ms == null) return null;
    if (t < 0 || y < 0 || mk < 0 || ms < 0) return null;
    return WorkforceCrewHours(tam: t, yarim: y, mesaiKisi: mk, mesaiSaat: ms);
  }

  void dispose() {
    tam.dispose();
    yarim.dispose();
    mesaiKisi.dispose();
    mesaiSaat.dispose();
  }
}

class _LineDraft {
  _LineDraft({
    required this.id,
    this.imalatId,
    required String name,
    required this.usta,
    required this.duz,
    this.manualMode = false,
  }) : name = TextEditingController(text: name);

  factory _LineDraft.fromLine(WorkforceImalatLine line) {
    return _LineDraft(
      id: line.id,
      imalatId: line.imalatId,
      name: line.imalatName,
      usta: _CrewDraft.fromHours(line.usta),
      duz: _CrewDraft.fromHours(line.duzIsci),
      manualMode: line.imalatId == null,
    );
  }

  factory _LineDraft.newEmpty() {
    return _LineDraft(
      id: 'wil-${DateTime.now().millisecondsSinceEpoch}',
      name: '',
      usta: _CrewDraft.empty(),
      duz: _CrewDraft.empty(),
      manualMode: true,
    );
  }

  final String id;
  String? imalatId;
  bool manualMode;
  final TextEditingController name;
  final _CrewDraft usta;
  final _CrewDraft duz;

  WorkforceImalatLine? toLine() {
    final ustaHours = usta.toHours();
    final duzHours = duz.toHours();
    if (ustaHours == null || duzHours == null) return null;
    final label = name.text.trim();
    return WorkforceImalatLine(
      id: id.startsWith('wil-') ? id : 'wil-${DateTime.now().millisecondsSinceEpoch}',
      imalatId: manualMode ? null : imalatId,
      imalatName: label,
      usta: ustaHours,
      duzIsci: duzHours,
    );
  }

  void dispose() {
    name.dispose();
    usta.dispose();
    duz.dispose();
  }
}

class _DayDraft {
  _DayDraft({
    required this.id,
    required this.date,
    required String kalfa,
    required List<_LineDraft> lines,
  })  : kalfa = TextEditingController(text: kalfa),
        lines = lines;

  factory _DayDraft.fromEntry(WorkforceEntry entry) {
    return _DayDraft(
      id: entry.id,
      date: entry.date,
      kalfa: '${entry.kalfa}',
      lines: entry.lines.isEmpty
          ? [_LineDraft.newEmpty()]
          : entry.lines.map(_LineDraft.fromLine).toList(),
    );
  }

  final String id;
  DateTime date;
  final TextEditingController kalfa;
  final List<_LineDraft> lines;

  double get previewUstaAdamGun =>
      lines.fold(0.0, (sum, line) => sum + line.usta.previewAdamGun);

  double get previewDuzAdamGun =>
      lines.fold(0.0, (sum, line) => sum + line.duz.previewAdamGun);

  WorkforceEntry? toEntry() {
    final k = int.tryParse(kalfa.text.trim());
    if (k == null || k < 0) return null;
    final parsedLines = <WorkforceImalatLine>[];
    for (final line in lines) {
      final parsed = line.toLine();
      if (parsed == null) return null;
      if (!parsed.hasLabor && parsed.imalatName.trim().isEmpty) continue;
      parsedLines.add(parsed);
    }
    return WorkforceEntry(
      id: id.startsWith('new-')
          ? 'wf-${DateTime.now().millisecondsSinceEpoch}'
          : id,
      date: date,
      kalfa: k,
      lines: parsedLines,
    );
  }

  void dispose() {
    kalfa.dispose();
    for (final line in lines) {
      line.dispose();
    }
  }
}
