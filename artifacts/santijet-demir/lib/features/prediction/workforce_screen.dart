import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_toast.dart';
import 'package:santijet_demir/core/widgets/empty_states.dart';
import 'package:santijet_demir/domain/entities/workforce.dart';
import 'package:santijet_demir/features/prediction/providers/workforce_provider.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';

class WorkforceScreen extends ConsumerStatefulWidget {
  const WorkforceScreen({super.key});

  @override
  ConsumerState<WorkforceScreen> createState() => _WorkforceScreenState();
}

class _WorkforceScreenState extends ConsumerState<WorkforceScreen> {
  final _drafts = <String, _PuantajDraft>{};
  var _dirty = false;
  var _saving = false;

  @override
  void dispose() {
    for (final draft in _drafts.values) {
      draft.dispose();
    }
    super.dispose();
  }

  List<_PuantajDraft> _ensureDrafts(List<WorkforceEntry> entries) {
    final keys = entries.map((e) => e.id).toSet();
    for (final key in _drafts.keys.toList()) {
      if (!keys.contains(key) && !key.startsWith('new-')) {
        _drafts.remove(key)?.dispose();
      }
    }
    for (final entry in entries) {
      _drafts.putIfAbsent(entry.id, () => _PuantajDraft.fromEntry(entry));
    }
    final ordered = <_PuantajDraft>[
      for (final entry in entries) _drafts[entry.id]!,
      ..._drafts.values.where((d) => d.id.startsWith('new-')),
    ];
    ordered.sort((a, b) => b.date.compareTo(a.date));
    return ordered;
  }

  void _addRow() {
    final id = 'new-${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _drafts[id] = _PuantajDraft(
        id: id,
        date: DateTime.now(),
        kalfa: '0',
        usta: '0',
        duzIsci: '0',
        tamGun: '0',
        yarimGun: '0',
        mesaiSaati: '0',
      );
      _dirty = true;
    });
  }

  Future<void> _saveAll(List<_PuantajDraft> drafts) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final notifier = ref.read(workforceProvider.notifier);
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
        if (entry.kalfa <= 0 &&
            entry.usta <= 0 &&
            entry.duzIsci <= 0 &&
            entry.tamGun <= 0 &&
            entry.yarimGun <= 0 &&
            entry.mesaiSaati <= 0) {
          continue;
        }
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

  Future<void> _deleteDraft(_PuantajDraft draft) async {
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
    final drafts = _ensureDrafts(entries);
    final dateFmt = DateFormat('d MMM', 'tr_TR');

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
              onPressed: _addRow,
              icon: const Icon(Icons.add),
              label: const Text('Satır ekle'),
            )
          : null,
      body: !hasProject
          ? const ModuleEmptyState(type: EmptyStateType.noProject)
          : drafts.isEmpty
              ? ModuleEmptyState(
                  type: EmptyStateType.noActivity,
                  actionLabel: canEdit ? 'İlk satırı ekle' : null,
                  onAction: canEdit ? _addRow : null,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        8,
                      ),
                      child: Text(
                        'Tabloya kalfa, usta, düz işçi ve mesai bilgisini girin. '
                        'Değişikliklerden sonra Kaydet’e basın.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          0,
                          AppSpacing.md,
                          100,
                        ),
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: MediaQuery.sizeOf(context).width - 32,
                            ),
                            child: DataTable(
                              headingRowHeight: 48,
                              dataRowMinHeight: 52,
                              dataRowMaxHeight: 64,
                              columnSpacing: 10,
                              horizontalMargin: 8,
                              headingTextStyle:
                                  AppTypography.labelSmall.copyWith(
                                color: AppColors.electricBlueLight,
                                fontWeight: FontWeight.w700,
                                height: 1.15,
                              ),
                              dataTextStyle: AppTypography.bodySmall,
                              border: TableBorder.all(color: AppColors.border),
                              columns: const [
                                DataColumn(label: Text('TARİH')),
                                DataColumn(
                                  label: _HeaderLabel('KALFA'),
                                ),
                                DataColumn(
                                  label: _HeaderLabel('USTA'),
                                ),
                                DataColumn(
                                  label: _HeaderLabel('DÜZ', line2: 'İŞÇİ'),
                                ),
                                DataColumn(
                                  label: _HeaderLabel('TAM', line2: 'GÜN'),
                                ),
                                DataColumn(
                                  label: _HeaderLabel('YARIM', line2: 'GÜN'),
                                ),
                                DataColumn(
                                  label: _HeaderLabel('MESAI', line2: 'SAATİ'),
                                ),
                                DataColumn(label: Text('')),
                              ],
                              rows: [
                                for (final draft in drafts)
                                  DataRow(
                                    cells: [
                                      DataCell(
                                        InkWell(
                                          onTap: canEdit
                                              ? () async {
                                                  final picked =
                                                      await showDatePicker(
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
                                          child: Text(dateFmt.format(draft.date)),
                                        ),
                                      ),
                                      DataCell(
                                        _CellField(
                                          controller: draft.kalfa,
                                          enabled: canEdit,
                                          onChanged: (_) =>
                                              setState(() => _dirty = true),
                                        ),
                                      ),
                                      DataCell(
                                        _CellField(
                                          controller: draft.usta,
                                          enabled: canEdit,
                                          onChanged: (_) =>
                                              setState(() => _dirty = true),
                                        ),
                                      ),
                                      DataCell(
                                        _CellField(
                                          controller: draft.duzIsci,
                                          enabled: canEdit,
                                          onChanged: (_) =>
                                              setState(() => _dirty = true),
                                        ),
                                      ),
                                      DataCell(
                                        _CellField(
                                          controller: draft.tamGun,
                                          enabled: canEdit,
                                          onChanged: (_) =>
                                              setState(() => _dirty = true),
                                        ),
                                      ),
                                      DataCell(
                                        _CellField(
                                          controller: draft.yarimGun,
                                          enabled: canEdit,
                                          onChanged: (_) =>
                                              setState(() => _dirty = true),
                                        ),
                                      ),
                                      DataCell(
                                        _CellField(
                                          controller: draft.mesaiSaati,
                                          enabled: canEdit,
                                          decimal: true,
                                          onChanged: (_) =>
                                              setState(() => _dirty = true),
                                        ),
                                      ),
                                      DataCell(
                                        canEdit
                                            ? IconButton(
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  size: 18,
                                                ),
                                                color: AppColors.textMuted,
                                                onPressed: () =>
                                                    _deleteDraft(draft),
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  const _HeaderLabel(this.line1, {this.line2});

  final String line1;
  final String? line2;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.labelSmall.copyWith(
      color: AppColors.electricBlueLight,
      fontWeight: FontWeight.w700,
      height: 1.15,
    );
    if (line2 == null) {
      return Text(line1, style: style, textAlign: TextAlign.center);
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(line1, style: style, textAlign: TextAlign.center),
        Text(line2!, style: style, textAlign: TextAlign.center),
      ],
    );
  }
}

class _CellField extends StatelessWidget {
  const _CellField({
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
    return SizedBox(
      width: 52,
      child: TextField(
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
          border: InputBorder.none,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _PuantajDraft {
  _PuantajDraft({
    required this.id,
    required this.date,
    required String kalfa,
    required String usta,
    required String duzIsci,
    required String tamGun,
    required String yarimGun,
    required String mesaiSaati,
  })  : kalfa = TextEditingController(text: kalfa),
        usta = TextEditingController(text: usta),
        duzIsci = TextEditingController(text: duzIsci),
        tamGun = TextEditingController(text: tamGun),
        yarimGun = TextEditingController(text: yarimGun),
        mesaiSaati = TextEditingController(text: mesaiSaati);

  factory _PuantajDraft.fromEntry(WorkforceEntry entry) {
    return _PuantajDraft(
      id: entry.id,
      date: entry.date,
      kalfa: '${entry.kalfa}',
      usta: '${entry.usta}',
      duzIsci: '${entry.duzIsci}',
      tamGun: '${entry.tamGun}',
      yarimGun: '${entry.yarimGun}',
      mesaiSaati: entry.mesaiSaati.toString().replaceAll('.0', ''),
    );
  }

  final String id;
  DateTime date;
  final TextEditingController kalfa;
  final TextEditingController usta;
  final TextEditingController duzIsci;
  final TextEditingController tamGun;
  final TextEditingController yarimGun;
  final TextEditingController mesaiSaati;

  WorkforceEntry? toEntry() {
    final k = int.tryParse(kalfa.text.trim());
    final u = int.tryParse(usta.text.trim());
    final d = int.tryParse(duzIsci.text.trim());
    final tg = int.tryParse(tamGun.text.trim());
    final yg = int.tryParse(yarimGun.text.trim());
    final mesai =
        double.tryParse(mesaiSaati.text.replaceAll(',', '.').trim());
    if (k == null ||
        u == null ||
        d == null ||
        tg == null ||
        yg == null ||
        mesai == null) {
      return null;
    }
    if (mesai < 0) return null;
    return WorkforceEntry(
      id: id.startsWith('new-')
          ? 'wf-${DateTime.now().millisecondsSinceEpoch}'
          : id,
      date: date,
      kalfa: k,
      usta: u,
      duzIsci: d,
      tamGun: tg,
      yarimGun: yg,
      mesaiSaati: mesai,
    );
  }

  void dispose() {
    kalfa.dispose();
    usta.dispose();
    duzIsci.dispose();
    tamGun.dispose();
    yarimGun.dispose();
    mesaiSaati.dispose();
  }
}
