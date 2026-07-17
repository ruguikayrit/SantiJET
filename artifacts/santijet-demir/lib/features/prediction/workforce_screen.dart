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
import 'package:santijet_demir/domain/entities/workforce.dart';
import 'package:santijet_demir/features/prediction/providers/workforce_provider.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';

class WorkforceScreen extends ConsumerWidget {
  const WorkforceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(workforceProvider);
    final canEdit = ref.watch(canEditActiveProjectProvider);
    final hasProject = ref.watch(activeProjectIdProvider) != null;
    final dateFmt = DateFormat('d MMM yyyy', 'tr_TR');

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('Günlük Puantaj')),
      floatingActionButton: hasProject && canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _openEditor(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Puantaj ekle'),
            )
          : null,
      body: !hasProject
          ? const ModuleEmptyState(type: EmptyStateType.noProject)
          : entries.isEmpty
              ? ModuleEmptyState(
                  type: EmptyStateType.noActivity,
                  actionLabel: canEdit ? 'İlk puantajı ekle' : null,
                  onAction: canEdit ? () => _openEditor(context, ref) : null,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final e = entries[index];
                    return Material(
                      color: AppColors.surfaceElevated,
                      borderRadius: AppRadii.md,
                      child: InkWell(
                        borderRadius: AppRadii.md,
                        onTap: canEdit
                            ? () => _openEditor(context, ref, existing: e)
                            : null,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: AppRadii.md,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dateFmt.format(e.date),
                                style: AppTypography.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${e.steelWorkers} demirci · '
                                '${e.foremen} usta · '
                                '${e.supervisors} şef · '
                                '${e.hours.toStringAsFixed(0)} saat',
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    WorkforceEntry? existing,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WorkforceEditorScreen(existing: existing),
      ),
    );
  }
}

class WorkforceEditorScreen extends ConsumerStatefulWidget {
  const WorkforceEditorScreen({super.key, this.existing});

  final WorkforceEntry? existing;

  @override
  ConsumerState<WorkforceEditorScreen> createState() =>
      _WorkforceEditorScreenState();
}

class _WorkforceEditorScreenState extends ConsumerState<WorkforceEditorScreen> {
  late DateTime _date;
  late final TextEditingController _workers;
  late final TextEditingController _foremen;
  late final TextEditingController _supervisors;
  late final TextEditingController _hours;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _date = e?.date ?? DateTime.now();
    _workers = TextEditingController(text: '${e?.steelWorkers ?? ''}');
    _foremen = TextEditingController(text: '${e?.foremen ?? ''}');
    _supervisors = TextEditingController(text: '${e?.supervisors ?? ''}');
    _hours = TextEditingController(
      text: e == null ? '8' : e.hours.toString(),
    );
    _notes = TextEditingController(text: e?.notes ?? '');
  }

  @override
  void dispose() {
    _workers.dispose();
    _foremen.dispose();
    _supervisors.dispose();
    _hours.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final workers = int.tryParse(_workers.text.trim()) ?? 0;
    final foremen = int.tryParse(_foremen.text.trim()) ?? 0;
    final supervisors = int.tryParse(_supervisors.text.trim()) ?? 0;
    final hours = double.tryParse(_hours.text.replaceAll(',', '.')) ?? 0;

    if (workers <= 0 && foremen <= 0 && supervisors <= 0) {
      ScaffoldMessenger.of(context).showAppSnackBar(
        const SnackBar(content: Text('En az bir personel sayısı girin')),
      );
      return;
    }
    if (hours <= 0) {
      ScaffoldMessenger.of(context).showAppSnackBar(
        const SnackBar(content: Text('Çalışma saati gerekli')),
      );
      return;
    }

    final entry = WorkforceEntry(
      id: widget.existing?.id ??
          'wf-${DateTime.now().millisecondsSinceEpoch}',
      date: _date,
      steelWorkers: workers,
      foremen: foremen,
      supervisors: supervisors,
      hours: hours,
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
    );

    await ref.read(workforceProvider.notifier).upsert(entry);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showAppSnackBar(
      const SnackBar(content: Text('Puantaj kaydedildi')),
    );
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final id = widget.existing?.id;
    if (id == null) return;
    await ref.read(workforceProvider.notifier).delete(id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMMM yyyy', 'tr_TR');

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Puantaj ekle' : 'Puantaj düzenle'),
        actions: [
          if (widget.existing != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Tarih'),
            subtitle: Text(dateFmt.format(_date)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _workers,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Demirci sayısı'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _foremen,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Usta / formen'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _supervisors,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Şef / kontrol'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _hours,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: const InputDecoration(labelText: 'Çalışma saati'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(labelText: 'Not (opsiyonel)'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _save,
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}
