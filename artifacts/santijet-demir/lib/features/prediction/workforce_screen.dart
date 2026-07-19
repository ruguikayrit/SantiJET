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
        steelWorkers: '0',
        foremen: '0',
        supervisors: '0',
        hours: '8',
        overtimeHours: '0',
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
        if (entry.steelWorkers <= 0 &&
            entry.foremen <= 0 &&
            entry.supervisors <= 0) {
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
                        'Tabloya demirci ve mesai bilgisini girin. '
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
                              headingRowHeight: 40,
                              dataRowMinHeight: 52,
                              dataRowMaxHeight: 64,
                              columnSpacing: 12,
                              horizontalMargin: 8,
                              headingTextStyle: AppTypography.labelSmall.copyWith(
                                color: AppColors.electricBlueLight,
                                fontWeight: FontWeight.w700,
                              ),
                              dataTextStyle: AppTypography.bodySmall,
                              border: TableBorder.all(color: AppColors.border),
                              columns: const [
                                DataColumn(label: Text('TARİH')),
                                DataColumn(label: Text('DEMİRCİ')),
                                DataColumn(label: Text('USTA')),
                                DataColumn(label: Text('ŞEF')),
                                DataColumn(label: Text('SAAT')),
                                DataColumn(label: Text('MESAI')),
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
                                          controller: draft.workers,
                                          enabled: canEdit,
                                          onChanged: (_) =>
                                              setState(() => _dirty = true),
                                        ),
                                      ),
                                      DataCell(
                                        _CellField(
                                          controller: draft.foremen,
                                          enabled: canEdit,
                                          onChanged: (_) =>
                                              setState(() => _dirty = true),
                                        ),
                                      ),
                                      DataCell(
                                        _CellField(
                                          controller: draft.supervisors,
                                          enabled: canEdit,
                                          onChanged: (_) =>
                                              setState(() => _dirty = true),
                                        ),
                                      ),
                                      DataCell(
                                        _CellField(
                                          controller: draft.hours,
                                          enabled: canEdit,
                                          decimal: true,
                                          onChanged: (_) =>
                                              setState(() => _dirty = true),
                                        ),
                                      ),
                                      DataCell(
                                        _CellField(
                                          controller: draft.overtime,
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
      width: 56,
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
    required String steelWorkers,
    required String foremen,
    required String supervisors,
    required String hours,
    required String overtimeHours,
  })  : workers = TextEditingController(text: steelWorkers),
        foremen = TextEditingController(text: foremen),
        supervisors = TextEditingController(text: supervisors),
        hours = TextEditingController(text: hours),
        overtime = TextEditingController(text: overtimeHours);

  factory _PuantajDraft.fromEntry(WorkforceEntry entry) {
    return _PuantajDraft(
      id: entry.id,
      date: entry.date,
      steelWorkers: '${entry.steelWorkers}',
      foremen: '${entry.foremen}',
      supervisors: '${entry.supervisors}',
      hours: entry.hours.toString().replaceAll('.0', ''),
      overtimeHours: entry.overtimeHours.toString().replaceAll('.0', ''),
    );
  }

  final String id;
  DateTime date;
  final TextEditingController workers;
  final TextEditingController foremen;
  final TextEditingController supervisors;
  final TextEditingController hours;
  final TextEditingController overtime;

  WorkforceEntry? toEntry() {
    final steel = int.tryParse(workers.text.trim());
    final usta = int.tryParse(foremen.text.trim());
    final sef = int.tryParse(supervisors.text.trim());
    final saat = double.tryParse(hours.text.replaceAll(',', '.').trim());
    final mesai = double.tryParse(overtime.text.replaceAll(',', '.').trim());
    if (steel == null ||
        usta == null ||
        sef == null ||
        saat == null ||
        mesai == null) {
      return null;
    }
    if (saat < 0 || mesai < 0) return null;
    return WorkforceEntry(
      id: id.startsWith('new-')
          ? 'wf-${DateTime.now().millisecondsSinceEpoch}'
          : id,
      date: date,
      steelWorkers: steel,
      foremen: usta,
      supervisors: sef,
      hours: saat == 0 ? 8 : saat,
      overtimeHours: mesai,
    );
  }

  void dispose() {
    workers.dispose();
    foremen.dispose();
    supervisors.dispose();
    hours.dispose();
    overtime.dispose();
  }
}
