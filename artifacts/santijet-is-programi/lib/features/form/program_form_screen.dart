import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
  late final TextEditingController responsible;
  late final TextEditingController notes;
  late DateTime startDate;
  late DateTime endDate;
  late int progress;
  late ProgramStatus status;
  late bool isStatusManual;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    name = TextEditingController(text: item?.name);
    responsible = TextEditingController(text: item?.responsible);
    notes = TextEditingController(text: item?.notes);
    startDate = item?.startDate ?? DateTime.now();
    endDate = item?.endDate ?? DateTime.now().add(const Duration(days: 7));
    progress = item?.progress ?? 0;
    status = item?.status ?? ProgramStatus.planned;
    isStatusManual = item?.isStatusManual ?? false;
  }

  @override
  void dispose() {
    name.dispose();
    responsible.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.item != null;
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
          editing ? 'Faaliyeti düzenle' : 'Yeni faaliyet',
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
            TextFormField(
              controller: name,
              autofocus: !editing,
              decoration: const InputDecoration(
                labelText: 'İmalat / faaliyet adı *',
                prefixIcon: Icon(Icons.construction_outlined),
              ),
              validator: ProgramItemValidator.name,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Başlangıç',
                    value: startDate,
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DateField(
                    label: 'Bitiş',
                    value: endDate,
                    onTap: () => _pickDate(isStart: false),
                  ),
                ),
              ],
            ),
            if (ProgramItemValidator.dates(startDate, endDate)
                case final error?)
              Padding(
                padding: const EdgeInsets.only(top: 7, left: 12),
                child: Text(
                  error,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            SJCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'İlerleme',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Text(
                        '%$progress',
                        style: AppTypography.kpiValue.copyWith(
                          color: AppColors.electricBlue,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: progress.toDouble(),
                    divisions: 20,
                    max: 100,
                    label: '%$progress',
                    onChanged: (value) =>
                        setState(() => progress = value.round()),
                  ),
                ],
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
              controller: responsible,
              decoration: const InputDecoration(
                labelText: 'Sorumlu',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: notes,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Not',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 20),
            SJButton(
              label: editing ? 'Değişiklikleri Kaydet' : 'Faaliyeti Ekle',
              icon: Icons.check_rounded,
              expanded: true,
              onPressed: _save,
            ),
            if (editing) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _delete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Faaliyeti Sil'),
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

  Future<void> _pickDate({required bool isStart}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: isStart ? startDate : endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
      helpText: isStart ? 'Başlangıç tarihini seç' : 'Bitiş tarihini seç',
    );
    if (selected == null) return;
    setState(() {
      if (isStart) {
        startDate = selected;
        if (endDate.isBefore(startDate)) endDate = startDate;
      } else {
        endDate = selected;
      }
    });
  }

  Future<void> _save() async {
    if (!formKey.currentState!.validate() ||
        ProgramItemValidator.dates(startDate, endDate) != null ||
        ProgramItemValidator.progress(progress) != null) {
      setState(() {});
      return;
    }
    final item = ProgramItem(
      id:
          widget.item?.id ??
          'item-${DateTime.now().microsecondsSinceEpoch.toString()}',
      santiyeId: widget.item?.santiyeId ?? ref.read(activeSiteProvider),
      name: name.text.trim(),
      startDate: startDate,
      endDate: endDate,
      progress: progress,
      status: status,
      responsible: responsible.text.trim(),
      notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
      isStatusManual: isStatusManual,
    );
    await ref.read(programItemsProvider.notifier).save(item);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Faaliyet silinsin mi?'),
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
