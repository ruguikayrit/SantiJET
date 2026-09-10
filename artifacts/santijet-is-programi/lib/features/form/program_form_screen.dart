import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/daily_crew_entry.dart';
import '../../domain/man_day_progress.dart';
import '../../domain/program_item.dart';
import '../../state/app_state.dart';
import '../../ui/design_system.dart';

class ProgramFormScreen extends ConsumerStatefulWidget {
  const ProgramFormScreen({super.key, this.item});
  final ProgramItem? item;

  @override
  ConsumerState<ProgramFormScreen> createState() => _ProgramFormScreenState();
}

class _ProgramFormScreenState extends ConsumerState<ProgramFormScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController duration;
  late final TextEditingController crew;
  late final TextEditingController responsible;
  late final TextEditingController notes;
  late DateTime startDate;
  late ProgramStatus status;
  late bool isStatusManual;
  int todayWorkers = 0;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    name = TextEditingController(text: item?.name);
    duration = TextEditingController(
      text: '${item?.calculatedDays ?? 7}',
    );
    crew = TextEditingController(text: '${item?.plannedCrew ?? 4}');
    responsible = TextEditingController(text: item?.responsible);
    notes = TextEditingController(text: item?.notes);
    startDate = item?.startDate ?? DateTime.now();
    status = item?.status ?? ProgramStatus.planned;
    isStatusManual = item?.isStatusManual ?? false;
  }

  @override
  void dispose() {
    name.dispose();
    duration.dispose();
    crew.dispose();
    responsible.dispose();
    notes.dispose();
    super.dispose();
  }

  int get _days => int.tryParse(duration.text.trim()) ?? 0;
  int get _crew => int.tryParse(crew.text.trim()) ?? 0;
  DateTime get _endDate => ProgramItem.endDateFromDuration(startDate, _days);
  int get _plannedManDays =>
      _days < 1 || _crew < 1 ? 0 : _days * _crew;

  @override
  Widget build(BuildContext context) {
    final editing = widget.item != null;
    final logs = editing
        ? ref
              .watch(dailyCrewProvider)
              .where((entry) => entry.itemId == widget.item!.id)
              .toList()
        : const <DailyCrewEntry>[];
    final draft = ProgramItem(
      id: widget.item?.id ?? 'draft',
      santiyeId: widget.item?.santiyeId ?? ref.watch(activeSiteProvider),
      name: name.text,
      startDate: startDate,
      endDate: _endDate,
      plannedDays: _days < 1 ? null : _days,
      plannedCrew: _crew < 1 ? 1 : _crew,
      progress: widget.item?.progress ?? 0,
      status: status,
      responsible: responsible.text,
      notes: notes.text,
      isStatusManual: isStatusManual,
    );
    final row = ManDayProgress.of(draft, logs);
    final todayStamp = DateTime.now().toIso8601String().substring(0, 10);
    final todayLog = logs
        .where((entry) => entry.date.toIso8601String().substring(0, 10) == todayStamp)
        .firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: Text(
          editing ? 'İmalatı düzenle' : 'Yeni imalat',
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            _SectionLabel('PLAN'),
            TextFormField(
              controller: name,
              autofocus: !editing,
              decoration: const InputDecoration(
                labelText: 'İmalat adı *',
                prefixIcon: Icon(Icons.construction_outlined),
              ),
              validator: ProgramItemValidator.name,
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Başlangıç',
              value: startDate,
              onTap: _pickStart,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: duration,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Süre (gün) *',
                      prefixIcon: Icon(Icons.timelapse_rounded),
                    ),
                    validator: (value) =>
                        ProgramItemValidator.duration(int.tryParse(value ?? '') ?? 0),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: crew,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Ekip (adam) *',
                      prefixIcon: Icon(Icons.groups_outlined),
                    ),
                    validator: (value) =>
                        ProgramItemValidator.crew(int.tryParse(value ?? '') ?? 0),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Bitiş ${DateFormat('dd.MM.yyyy').format(_endDate)}  ·  '
              '$_plannedManDays adam-gün',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            SJCard(
              child: Row(
                children: [
                  Expanded(
                    child: _AgStat(
                      label: 'PLAN',
                      value: '$_plannedManDays',
                      unit: 'AG',
                    ),
                  ),
                  Expanded(
                    child: _AgStat(
                      label: 'SÜRE',
                      value: _days < 1 ? '—' : '$_days',
                      unit: 'gün',
                    ),
                  ),
                  Expanded(
                    child: _AgStat(
                      label: 'EKİP',
                      value: _crew < 1 ? '—' : '$_crew',
                      unit: 'adam',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: responsible,
              decoration: const InputDecoration(
                labelText: 'Ekip / sorumlu',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ProgramStatus>(
              initialValue: status,
              decoration: const InputDecoration(
                labelText: 'Durum',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              items: ProgramStatus.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(value.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    status = value;
                    isStatusManual = true;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: notes,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Not',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            if (editing) ...[
              const SizedBox(height: 22),
              _SectionLabel('SAHA — GERÇEKLEŞEN'),
              SJCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bugün kaç adam çalıştı?',
                      style: AppTypography.onCard(AppTypography.cardTitleMedium),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      todayLog == null
                          ? 'Kayıt yok. Sayıyı yazıp işleyin.'
                          : 'Bugün ${todayLog.workers} adam işlendi.',
                      style: AppTypography.cardBodySmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: '${todayLog?.workers ?? todayWorkers}',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Adam',
                            ),
                            onChanged: (value) =>
                                todayWorkers = int.tryParse(value) ?? 0,
                          ),
                        ),
                        const SizedBox(width: 10),
                        SJButton(
                          label: 'İşle',
                          icon: Icons.check_rounded,
                          onPressed: () => _logToday(todayLog?.workers ?? 0),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _CompareCard(row: row),
              if (logs.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'GÜNLÜK KAYIT',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                ...logs.reversed.take(14).map(
                  (entry) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(DateFormat('dd.MM.yyyy').format(entry.date)),
                    trailing: Text(
                      '${entry.workers} adam',
                      style: AppTypography.cardTitleMedium,
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 20),
            SJButton(
              label: editing ? 'Değişiklikleri Kaydet' : 'İmalatı Ekle',
              icon: Icons.check_rounded,
              expanded: true,
              onPressed: _save,
            ),
            if (editing) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('İmalatı Sil'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickStart() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
      helpText: 'Başlangıç tarihini seç',
    );
    if (selected == null) return;
    setState(() => startDate = selected);
  }

  Future<void> _logToday(int fallback) async {
    final workers = todayWorkers > 0 ? todayWorkers : fallback;
    final error = DailyCrewValidator.workers(workers);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    await ref.read(dailyCrewProvider.notifier).upsert(
      itemId: widget.item!.id,
      date: DateTime.now(),
      workers: workers,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bugün $workers adam işlendi.')),
      );
    }
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;
    final days = _days;
    final crewSize = _crew;
    if (ProgramItemValidator.duration(days) != null ||
        ProgramItemValidator.crew(crewSize) != null) {
      setState(() {});
      return;
    }
    final end = ProgramItem.endDateFromDuration(startDate, days);
    final item = ProgramItem(
      id:
          widget.item?.id ??
          'item-${DateTime.now().microsecondsSinceEpoch}',
      santiyeId: widget.item?.santiyeId ?? ref.read(activeSiteProvider),
      name: name.text.trim(),
      startDate: startDate,
      endDate: end,
      plannedDays: days,
      plannedCrew: crewSize,
      progress: widget.item?.progress ?? 0,
      status: status,
      responsible: responsible.text.trim(),
      notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
      isStatusManual: isStatusManual,
      wbs: widget.item?.wbs,
      outlineLevel: widget.item?.outlineLevel ?? 1,
      isMilestone: widget.item?.isMilestone ?? false,
      msProjectUid: widget.item?.msProjectUid,
      predecessors: widget.item?.predecessors,
    );
    await ref.read(programItemsProvider.notifier).save(item);
    await ref.read(programItemsProvider.notifier).syncProgress(item.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İmalat silinsin mi?'),
        content: const Text('Saha kayıtları da silinir. Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (accepted != true || widget.item == null) return;
    await ref.read(programItemsProvider.notifier).delete(widget.item!.id);
    if (mounted) Navigator.of(context).pop();
  }
}

class _CompareCard extends StatelessWidget {
  const _CompareCard({required this.row});
  final ManDayProgress row;

  @override
  Widget build(BuildContext context) {
    final behind = row.varianceToDate < 0;
    return SJCard(
      accentColor: behind ? AppColors.critical : AppColors.success,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PLAN / GERÇEK',
            style: AppTypography.onCard(
              AppTypography.labelSmall,
            ).copyWith(fontWeight: FontWeight.w700, letterSpacing: 1.1),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AgStat(
                  label: 'PLAN',
                  value: '${row.plannedManDays}',
                  unit: 'AG',
                ),
              ),
              Expanded(
                child: _AgStat(
                  label: 'GERÇEK',
                  value: '${row.realizedManDays}',
                  unit: 'AG',
                ),
              ),
              Expanded(
                child: _AgStat(
                  label: 'BUGÜNE PLAN',
                  value: '${row.plannedToDate}',
                  unit: 'AG',
                  color: behind ? AppColors.critical : AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            behind
                ? '${-row.varianceToDate} adam-gün geride · %${row.progress}'
                : 'Planın üzerinde veya denk · %${row.progress}',
            style: AppTypography.cardBodySmall,
          ),
        ],
      ),
    );
  }
}

class _AgStat extends StatelessWidget {
  const _AgStat({
    required this.label,
    required this.value,
    required this.unit,
    this.color,
  });
  final String label;
  final String value;
  final String unit;
  final Color? color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTypography.cardBodySmall),
      const SizedBox(height: 4),
      Text(
        value,
        style: AppTypography.kpiValue.copyWith(
          fontSize: 22,
          color: color ?? AppColors.cardTextPrimary,
        ),
      ),
      Text(unit, style: AppTypography.cardBodySmall),
    ],
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 10, top: 8),
    child: Text(
      text,
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    ),
  );
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today_outlined),
      ),
      child: Text(DateFormat('dd.MM.yyyy').format(value)),
    ),
  );
}
