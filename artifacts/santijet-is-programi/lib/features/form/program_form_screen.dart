import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/program_item.dart';
import '../../domain/project_tracking.dart';
import '../../state/app_state.dart';
import '../../ui/design_system.dart';

/// MS Project Giriş ve İzleme tablolarının aynı alanları ve hesabı.
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
  late final TextEditingController units;
  late final TextEditingController predecessors;
  late final TextEditingController resources;
  late final TextEditingController wbs;
  late final TextEditingController notes;
  late final TextEditingController percent;
  late final TextEditingController actualDuration;
  late final TextEditingController remainingDuration;
  late final TextEditingController actualWork;
  late final TextEditingController remainingWork;
  late ProjectTracking tracking;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    tracking = ProjectTracking.fromItem(item ?? _blankItem());
    name = TextEditingController(text: item?.name);
    predecessors = TextEditingController(text: item?.predecessors);
    resources = TextEditingController(text: item?.responsible);
    wbs = TextEditingController(text: item?.wbs);
    notes = TextEditingController(text: item?.notes);
    duration = TextEditingController();
    units = TextEditingController();
    percent = TextEditingController();
    actualDuration = TextEditingController();
    remainingDuration = TextEditingController();
    actualWork = TextEditingController();
    remainingWork = TextEditingController();
    _writeTracking();
  }

  ProgramItem _blankItem() => ProgramItem(
    id: 'draft',
    santiyeId: 'draft',
    name: '',
    startDate: DateTime.now(),
    endDate: ProgramItem.endDateFromDuration(DateTime.now(), 7),
    plannedDays: 7,
    plannedCrew: 4,
    progress: 0,
    status: ProgramStatus.planned,
    responsible: '',
  );

  @override
  void dispose() {
    name.dispose();
    duration.dispose();
    units.dispose();
    predecessors.dispose();
    resources.dispose();
    wbs.dispose();
    notes.dispose();
    percent.dispose();
    actualDuration.dispose();
    remainingDuration.dispose();
    actualWork.dispose();
    remainingWork.dispose();
    super.dispose();
  }

  void _writeTracking() {
    _syncing = true;
    duration.text = '${tracking.duration}';
    units.text = '${tracking.units}';
    percent.text = '${tracking.percentComplete}';
    actualDuration.text = '${tracking.actualDuration}';
    remainingDuration.text = '${tracking.remainingDuration}';
    actualWork.text = '${tracking.actualWork}';
    remainingWork.text = '${tracking.remainingWork}';
    _syncing = false;
  }

  void _setTracking(ProjectTracking next) {
    setState(() {
      tracking = next;
      _writeTracking();
    });
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.item != null;
    final date = DateFormat('dd.MM.yyyy');

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
          editing ? 'Görevi düzenle' : 'Yeni görev',
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
            const _SectionLabel('GİRİŞ'),
            TextFormField(
              controller: name,
              autofocus: !editing,
              decoration: const InputDecoration(
                labelText: 'Ad *',
                prefixIcon: Icon(Icons.task_alt_outlined),
              ),
              validator: ProgramItemValidator.name,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: duration,
                    enabled: !tracking.milestone,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Süre',
                      suffixText: 'gün',
                    ),
                    validator: (value) => ProgramItemValidator.duration(
                      int.tryParse(value ?? '') ?? 0,
                      milestone: tracking.milestone,
                    ),
                    onChanged: (value) {
                      if (_syncing) return;
                      _setTracking(
                        tracking.applyDuration(int.tryParse(value) ?? 0),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: units,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Birimler',
                      suffixText: 'adam',
                    ),
                    validator: (value) =>
                        ProgramItemValidator.crew(int.tryParse(value ?? '') ?? 0),
                    onChanged: (value) {
                      if (_syncing) return;
                      _setTracking(
                        tracking.applyUnits(int.tryParse(value) ?? 1),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Başlangıç',
              value: tracking.start,
              onTap: () => _pickDate(
                tracking.start,
                (date) => _setTracking(tracking.applyStart(date)),
              ),
            ),
            const SizedBox(height: 12),
            _DateField(
              label: 'Bitiş',
              value: tracking.finish,
              onTap: tracking.milestone
                  ? null
                  : () => _pickDate(
                      tracking.finish,
                      (date) => _setTracking(tracking.applyFinish(date)),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              'İş ${tracking.work} adam-gün  ·  '
              '${date.format(tracking.start)} – ${date.format(tracking.finish)}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: predecessors,
              decoration: const InputDecoration(
                labelText: 'Öncüller',
                hintText: '2FS+1 gün',
                prefixIcon: Icon(Icons.account_tree_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: resources,
              decoration: const InputDecoration(
                labelText: 'Kaynak Adları',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: wbs,
              decoration: const InputDecoration(
                labelText: 'WBS',
                prefixIcon: Icon(Icons.tag_outlined),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Kilometre taşı'),
              value: tracking.milestone,
              onChanged: (value) => _setTracking(tracking.applyMilestone(value)),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: notes,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notlar',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 22),
            const _SectionLabel('İZLEME'),
            TextFormField(
              controller: percent,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: '% Tamamlanma',
                suffixText: '%',
              ),
              validator: (value) => ProgramItemValidator.progress(
                int.tryParse(value ?? '') ?? 0,
              ),
              onChanged: (value) {
                if (_syncing) return;
                _setTracking(
                  tracking.applyPercentComplete(int.tryParse(value) ?? 0),
                );
              },
            ),
            const SizedBox(height: 12),
            _OptionalDateField(
              label: 'Fiili Başlangıç',
              value: tracking.actualStart,
              onPick: () => _pickDate(
                tracking.actualStart ?? tracking.start,
                (date) => _setTracking(tracking.applyActualStart(date)),
              ),
              onClear: () => _setTracking(tracking.applyActualStart(null)),
            ),
            const SizedBox(height: 12),
            _OptionalDateField(
              label: 'Fiili Bitiş',
              value: tracking.actualFinish,
              onPick: () => _pickDate(
                tracking.actualFinish ?? tracking.finish,
                (date) => _setTracking(tracking.applyActualFinish(date)),
              ),
              onClear: () => _setTracking(tracking.applyActualFinish(null)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: actualDuration,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Fiili Süre',
                      suffixText: 'gün',
                    ),
                    onChanged: (value) {
                      if (_syncing) return;
                      _setTracking(
                        tracking.applyActualDuration(int.tryParse(value) ?? 0),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: remainingDuration,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Kalan Süre',
                      suffixText: 'gün',
                    ),
                    onChanged: (value) {
                      if (_syncing) return;
                      _setTracking(
                        tracking.applyRemainingDuration(
                          int.tryParse(value) ?? 0,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SJCard(
              child: Row(
                children: [
                  Expanded(
                    child: _Stat(label: 'İŞ', value: '${tracking.work}', unit: 'AG'),
                  ),
                  Expanded(
                    child: _Stat(
                      label: 'FİİLİ İŞ',
                      value: '${tracking.actualWork}',
                      unit: 'AG',
                    ),
                  ),
                  Expanded(
                    child: _Stat(
                      label: 'KALAN İŞ',
                      value: '${tracking.remainingWork}',
                      unit: 'AG',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: actualWork,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Fiili İş',
                      suffixText: 'AG',
                    ),
                    onChanged: (value) {
                      if (_syncing) return;
                      _setTracking(
                        tracking.applyActualWork(int.tryParse(value) ?? 0),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: remainingWork,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Kalan İş',
                      suffixText: 'AG',
                    ),
                    onChanged: (value) {
                      if (_syncing) return;
                      _setTracking(
                        tracking.applyRemainingWork(int.tryParse(value) ?? 0),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SJButton(
              label: editing ? 'Değişiklikleri Kaydet' : 'Görevi Ekle',
              icon: Icons.check_rounded,
              expanded: true,
              onPressed: _save,
            ),
            if (editing) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Görevi Sil'),
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

  Future<void> _pickDate(
    DateTime initial,
    ValueChanged<DateTime> onPicked,
  ) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (selected != null) onPicked(selected);
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate()) return;
    final item = tracking.applyTo(
      ProgramItem(
        id: widget.item?.id ??
            'item-${DateTime.now().microsecondsSinceEpoch}',
        santiyeId: widget.item?.santiyeId ?? ref.read(activeSiteProvider),
        name: name.text.trim(),
        startDate: tracking.start,
        endDate: tracking.finish,
        plannedDays: tracking.duration,
        plannedCrew: tracking.units,
        progress: tracking.percentComplete,
        status: tracking.status(),
        responsible: resources.text.trim(),
        notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
        wbs: wbs.text.trim().isEmpty ? null : wbs.text.trim(),
        outlineLevel: widget.item?.outlineLevel ?? 1,
        isMilestone: tracking.milestone,
        msProjectUid: widget.item?.msProjectUid,
        predecessors: predecessors.text.trim().isEmpty
            ? null
            : predecessors.text.trim(),
      ),
    );
    await ref.read(programItemsProvider.notifier).save(item);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Görev silinsin mi?'),
        content: const Text('Bu işlem geri alınamaz.'),
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

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.unit});
  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTypography.cardBodySmall),
      const SizedBox(height: 4),
      Text(value, style: AppTypography.kpiValue.copyWith(fontSize: 22)),
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
  final VoidCallback? onTap;

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

class _OptionalDateField extends StatelessWidget {
  const _OptionalDateField({
    required this.label,
    required this.value,
    required this.onPick,
    required this.onClear,
  });
  final String label;
  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onPick,
    borderRadius: BorderRadius.circular(14),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.event_available_outlined),
        suffixIcon: value == null
            ? null
            : IconButton(
                tooltip: 'NA',
                onPressed: onClear,
                icon: const Icon(Icons.close),
              ),
      ),
      child: Text(
        value == null ? 'NA' : DateFormat('dd.MM.yyyy').format(value!),
      ),
    ),
  );
}
