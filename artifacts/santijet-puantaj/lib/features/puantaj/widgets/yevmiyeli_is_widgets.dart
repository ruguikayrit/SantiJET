import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/sj_button.dart';
import '../../../core/design_system/sj_card.dart';
import '../../../core/design_system/sj_modal.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/text_format.dart';
import '../../../data/providers/app_data_provider.dart';
import '../../../data/providers/collaboration_provider.dart';
import '../../../data/providers/yevmiyeli_is_provider.dart';
import '../../../domain/entities/person.dart';
import '../../../domain/entities/yevmiyeli_is_kaydi.dart';

String formatYevmiyeCount(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(0);
  return v.toStringAsFixed(1);
}

/// Yevmiyeli iş kayıt formu — personelden otomatik taşeron/meslek/ekip.
Future<void> openYevmiyeliIsEditor(
  BuildContext context,
  WidgetRef ref, {
  required String projectId,
  required String date,
  required List<Person> people,
  Person? initialPerson,
  YevmiyeliIsKaydi? existing,
}) async {
  final canEdit = ref.read(canEditActiveProjectProvider);
  if (!canEdit) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bu işte yalnızca görüntüleme yetkiniz var'),
      ),
    );
    return;
  }

  final sortedPeople = [...people]..sort((a, b) => a.name.compareTo(b.name));
  if (sortedPeople.isEmpty && existing == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Önce personel ekleyin.')),
    );
    return;
  }

  Person? selected = initialPerson;
  if (existing != null) {
    for (final p in sortedPeople) {
      if (p.id == existing.personId) {
        selected = p;
        break;
      }
    }
  }
  selected ??= sortedPeople.isNotEmpty ? sortedPeople.first : null;

  final companyCtrl = TextEditingController(
    text: existing?.company.isNotEmpty == true
        ? existing!.company
        : (selected?.company ?? ''),
  );
  final workCtrl = TextEditingController(text: existing?.workDescription ?? '');
  final noteCtrl = TextEditingController(text: existing?.note ?? '');
  var yevmiye = existing?.yevmiyeCount ?? 1.0;
  final formKey = GlobalKey<FormState>();

  final saved = await SJModal.showSheet<bool>(
    context: context,
    title: existing == null ? 'Yevmiyeli iş kaydı' : 'Yevmiyeli iş düzenle',
    child: StatefulBuilder(
      builder: (context, setModal) {
        final theme = Theme.of(context);
        final person = selected;
        final meta = [
          if ((person?.profession ?? '').trim().isNotEmpty)
            titleCaseTr(person!.profession),
          if ((person?.team ?? '').trim().isNotEmpty) titleCaseTr(person!.team),
        ].join(' · ');

        return Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Taşeronun parça iş için verdiği adamın günlük yevmiye kaydı. '
                'Yevmiye adedi elle yazılır.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                value: person?.id,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Personel *'),
                items: [
                  for (final p in sortedPeople)
                    DropdownMenuItem(
                      value: p.id,
                      child: Text(titleCaseTr(p.name)),
                    ),
                ],
                onChanged: existing != null
                    ? null
                    : (id) {
                        if (id == null) return;
                        Person? next;
                        for (final p in sortedPeople) {
                          if (p.id == id) {
                            next = p;
                            break;
                          }
                        }
                        if (next == null) return;
                        setModal(() {
                          selected = next;
                          if (companyCtrl.text.trim().isEmpty ||
                              companyCtrl.text.trim() ==
                                  titleCaseTr(person?.company ?? '')) {
                            companyCtrl.text = next!.company;
                          }
                        });
                      },
                validator: (v) =>
                    v == null || v.isEmpty ? 'Personel seçin' : null,
              ),
              if (meta.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  meta,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: companyCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Taşeron firma *',
                  hintText: 'Firma Adı / taşeron',
                ),
                validator: (v) {
                  if ((v ?? '').trim().isEmpty) return 'Firma zorunlu';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: workCtrl,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'İş tanımı *',
                  hintText: 'Örn. Klima drenaj hattı bağlantısı',
                ),
                validator: (v) {
                  if ((v ?? '').trim().isEmpty) return 'İş tanımı zorunlu';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('Yevmiye adedi *', style: theme.textTheme.labelLarge),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  IconButton(
                    onPressed: yevmiye <= 0.5
                        ? null
                        : () => setModal(
                              () => yevmiye = (yevmiye - 0.5).clamp(0.5, 30),
                            ),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '${formatYevmiyeCount(yevmiye)} yv',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.electricBlue,
                    ),
                  ),
                  IconButton(
                    onPressed: yevmiye >= 30
                        ? null
                        : () => setModal(
                              () => yevmiye = (yevmiye + 0.5).clamp(0.5, 30),
                            ),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                  const Spacer(),
                  Text(
                    '0,5 adım',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: noteCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Not (opsiyonel)',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SJButton(
                label: existing == null ? 'Kaydet' : 'Güncelle',
                onPressed: () {
                  if (!(formKey.currentState?.validate() ?? false)) return;
                  Navigator.of(context).pop(true);
                },
              ),
              if (existing != null) ...[
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                  ),
                  child: const Text('Sil'),
                ),
              ],
            ],
          ),
        );
      },
    ),
  );

  final person = selected;
  final company = companyCtrl.text;
  final work = workCtrl.text;
  final note = noteCtrl.text;
  companyCtrl.dispose();
  workCtrl.dispose();
  noteCtrl.dispose();

  if (saved == false && existing != null) {
    ref.read(yevmiyeliIsProvider.notifier).remove(existing.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yevmiyeli iş silindi.')),
      );
    }
    return;
  }
  if (saved != true || person == null) return;

  try {
    final notifier = ref.read(yevmiyeliIsProvider.notifier);
    if (existing != null) {
      notifier.upsert(
        existing.copyWith(
          personId: person.id,
          personName: person.name,
          company: company,
          profession: person.profession,
          team: person.team,
          workDescription: work,
          yevmiyeCount: yevmiye,
          note: note,
        ),
      );
    } else {
      notifier.addFromPerson(
        projectId: projectId,
        date: date,
        person: person,
        workDescription: work,
        yevmiyeCount: yevmiye,
        note: note,
        companyOverride: company,
      );
    }
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$e')),
    );
  }
}

/// Günlük puantaj — Yevmiyeli işler (Personel / Ekip ile aynı açılır başlık).
class DayYevmiyeliSection extends ConsumerStatefulWidget {
  const DayYevmiyeliSection({
    super.key,
    required this.date,
    required this.people,
    this.expanded,
    this.onExpandedChanged,
    this.initiallyExpanded = true,
  });

  final String date;
  final List<Person> people;
  final bool? expanded;
  final ValueChanged<bool>? onExpandedChanged;
  final bool initiallyExpanded;

  @override
  ConsumerState<DayYevmiyeliSection> createState() =>
      _DayYevmiyeliSectionState();
}

class _DayYevmiyeliSectionState extends ConsumerState<DayYevmiyeliSection> {
  late bool _internalExpanded = widget.initiallyExpanded;

  bool get _isExpanded => widget.expanded ?? _internalExpanded;

  void _toggle() {
    if (widget.expanded != null && widget.onExpandedChanged != null) {
      widget.onExpandedChanged!(!widget.expanded!);
      return;
    }
    setState(() => _internalExpanded = !_internalExpanded);
  }

  @override
  void didUpdateWidget(covariant DayYevmiyeliSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date) {
      _internalExpanded = widget.initiallyExpanded;
    } else if (widget.expanded == null &&
        oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      _internalExpanded = widget.initiallyExpanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final project = ref.watch(activeProjectProvider);
    if (project == null) return const SizedBox.shrink();

    final entries = ref
        .watch(yevmiyeliIsProvider)
        .where((e) => e.projectId == project.id && e.date == widget.date)
        .toList()
      ..sort((a, b) {
        final c = a.company.compareTo(b.company);
        if (c != 0) return c;
        return a.personName.compareTo(b.personName);
      });
    final total =
        entries.fold<double>(0, (sum, e) => sum + e.yevmiyeCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.md),
        InkWell(
          onTap: _toggle,
          borderRadius: AppRadii.sm,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 3,
                  height: 16,
                  margin: const EdgeInsets.only(top: 2),
                  color: AppColors.electricBlue,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Yevmiyeli işler',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (entries.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${entries.length} kayıt',
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
                ],
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded) ...[
          const SizedBox(height: AppSpacing.sm),
          if (entries.isEmpty)
            Text(
              'Taşeronun parça iş için verdiği adamları buraya kaydedin. '
              'Personel kartından da ekleyebilirsiniz.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            Column(
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _YevmiyeliRow(
                    index: i + 1,
                    entry: entries[i],
                    onTap: () => openYevmiyeliIsEditor(
                      context,
                      ref,
                      projectId: project.id,
                      date: widget.date,
                      people: widget.people,
                      existing: entries[i],
                    ),
                  ),
                ],
                const Divider(height: 16),
                Row(
                  children: [
                    Text(
                      'Günlük toplam',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${formatYevmiyeCount(total)} yv',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.electricBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ],
    );
  }
}

class _YevmiyeliRow extends StatelessWidget {
  const _YevmiyeliRow({
    required this.index,
    required this.entry,
    required this.onTap,
  });

  final int index;
  final YevmiyeliIsKaydi entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = [
      if (entry.profession.isNotEmpty) entry.profession,
      if (entry.team.isNotEmpty) entry.team,
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.sm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 22,
              child: Text(
                '$index',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.personName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    entry.company.isEmpty ? '—' : entry.company,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (meta.isNotEmpty)
                    Text(meta, style: theme.textTheme.labelSmall),
                  const SizedBox(height: 2),
                  Text(
                    entry.workDescription,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.electricBlue.withValues(alpha: 0.12),
                borderRadius: AppRadii.sm,
                border: Border.all(
                  color: AppColors.electricBlue.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                '${formatYevmiyeCount(entry.yevmiyeCount)} yv',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.electricBlue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Haftalık / aylık özet kartı.
class PeriodYevmiyeliSummary extends ConsumerWidget {
  const PeriodYevmiyeliSummary({
    super.key,
    required this.dates,
  });

  final List<String> dates;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(activeProjectProvider);
    if (project == null) return const SizedBox.shrink();

    // Watch so UI updates.
    final all = ref.watch(yevmiyeliIsProvider);
    final daySet = dates.toSet();
    final entries = all
        .where((e) => e.projectId == project.id && daySet.contains(e.date))
        .toList();

    if (entries.isEmpty) return const SizedBox.shrink();

    final total =
        entries.fold<double>(0, (sum, e) => sum + e.yevmiyeCount);
    final byCompany = <String, double>{};
    for (final e in entries) {
      final key = e.company.isEmpty ? 'Diğer' : e.company;
      byCompany[key] = (byCompany[key] ?? 0) + e.yevmiyeCount;
    }
    final companies = byCompany.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: SJCard.builder(
        builder: (context, cardTheme) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.handyman_outlined,
                    color: cardTheme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Yevmiyeli işler',
                      style: cardTheme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${entries.length} kayıt · ${formatYevmiyeCount(total)} yv',
                    style: cardTheme.textTheme.labelMedium?.copyWith(
                      color: AppColors.electricBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final c in companies.take(6))
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.key,
                          style: cardTheme.textTheme.bodySmall,
                        ),
                      ),
                      Text(
                        '${formatYevmiyeCount(c.value)} yv',
                        style: cardTheme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
