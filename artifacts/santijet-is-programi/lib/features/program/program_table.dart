import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/program_item.dart';
import '../../domain/project_tracking.dart';
import '../../state/app_state.dart';
import '../../ui/design_system.dart';

enum ProgramTableView { entry, tracking }

/// MS Project Giriş / İzleme tablosu — hücreden hızlı giriş, yatay kaydırma yok.
class ProgramTable extends ConsumerStatefulWidget {
  const ProgramTable({
    required this.items,
    required this.view,
    required this.siteId,
    required this.onOpenDetails,
    super.key,
  });

  final List<ProgramItem> items;
  final ProgramTableView view;
  final String siteId;
  final ValueChanged<ProgramItem> onOpenDetails;

  static final dayFmt = DateFormat('E dd.MM.yy', 'tr_TR');

  @override
  ConsumerState<ProgramTable> createState() => _ProgramTableState();
}

class _ProgramTableState extends ConsumerState<ProgramTable> {
  static const _draftId = '__draft__';

  final _list = ScrollController();
  _Edit? _editing;
  _Draft _draft = _Draft.fresh();

  @override
  void dispose() {
    _list.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SJCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TableHeader(view: widget.view),
          Expanded(
            child:
                widget.view == ProgramTableView.tracking && widget.items.isEmpty
                ? Center(
                    child: Text(
                      'Önce GİRİŞ’te görev yaz.',
                      style: AppTypography.cardBodySmall,
                    ),
                  )
                : ListView.builder(
                    controller: _list,
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount:
                        widget.items.length +
                        (widget.view == ProgramTableView.entry ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= widget.items.length) {
                        return _TaskBlock(
                          index: widget.items.length + 1,
                          item: null,
                          draft: _draft,
                          view: widget.view,
                          editing: _editing,
                          onEdit: _beginEdit,
                          onCommitText: _commitText,
                          onCommitDate: _commitDate,
                          onOpenMenu: null,
                        );
                      }
                      final item = widget.items[index];
                      return _TaskBlock(
                        index: index + 1,
                        item: item,
                        draft: null,
                        view: widget.view,
                        editing: _editing,
                        onEdit: _beginEdit,
                        onCommitText: _commitText,
                        onCommitDate: _commitDate,
                        onOpenMenu: (action) => _menu(item, action),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _beginEdit(String itemId, _Field field) {
    setState(() => _editing = _Edit(itemId, field));
  }

  Future<void> _commitText(String itemId, _Field field, String raw) async {
    final next = _nextField(field);
    if (itemId == _draftId) {
      _applyDraft(field, raw);
      if (field == _Field.name && _draft.name.trim().isNotEmpty) {
        final created = await _createFromDraft();
        if (!mounted) return;
        setState(() {
          _editing = created == null || next == null
              ? null
              : _Edit(created.id, next);
        });
        return;
      }
      setState(() => _editing = next == null ? null : _Edit(_draftId, next));
      return;
    }

    final item = widget.items.where((found) => found.id == itemId).firstOrNull;
    if (item == null) {
      setState(() => _editing = null);
      return;
    }
    final updated = _applyField(item, field, raw);
    if (updated != item) {
      await ref.read(programItemsProvider.notifier).save(updated);
    }
    if (!mounted) return;
    setState(() {
      _editing = next == null ? null : _Edit(itemId, next);
    });
  }

  Future<void> _commitDate(
    String itemId,
    _DateField field,
    DateTime? value,
  ) async {
    if (itemId == _draftId) {
      setState(() {
        switch (field) {
          case _DateField.start:
            _draft.start = value ?? _draft.start;
            _draft.finish = ProgramItem.endDateFromDuration(
              _draft.start,
              _draft.duration,
            );
          case _DateField.finish:
            if (value == null) return;
            if (value.isBefore(_draft.start)) {
              _draft.finish = _draft.start;
              _draft.duration = 1;
            } else {
              _draft.finish = value;
              _draft.duration = value.difference(_draft.start).inDays + 1;
            }
          case _DateField.actualStart:
          case _DateField.actualFinish:
            break;
        }
        _editing = null;
      });
      return;
    }

    final item = widget.items.where((found) => found.id == itemId).firstOrNull;
    if (item == null) return;
    final tracking = ProjectTracking.fromItem(item);
    final next = switch (field) {
      _DateField.start => tracking.applyStart(value ?? tracking.start),
      _DateField.finish => tracking.applyFinish(value ?? tracking.finish),
      _DateField.actualStart => tracking.applyActualStart(value),
      _DateField.actualFinish => tracking.applyActualFinish(value),
    };
    await ref.read(programItemsProvider.notifier).save(next.applyTo(item));
    if (mounted) setState(() => _editing = null);
  }

  void _applyDraft(_Field field, String raw) {
    final text = raw.trim();
    switch (field) {
      case _Field.wbs:
        _draft.wbs = text;
      case _Field.name:
        _draft.name = text;
      case _Field.duration:
        final days = int.tryParse(text);
        if (days != null && days >= 0) {
          _draft.duration = days < 1 ? 1 : days;
          _draft.finish = ProgramItem.endDateFromDuration(
            _draft.start,
            _draft.duration,
          );
        }
      case _Field.predecessors:
        _draft.predecessors = text;
      case _Field.resources:
        _draft.resources = text;
      case _Field.percent:
      case _Field.actualDuration:
      case _Field.remainingDuration:
      case _Field.actualWork:
      case _Field.remainingWork:
        break;
    }
  }

  Future<ProgramItem?> _createFromDraft() async {
    final name = _draft.name.trim();
    if (name.isEmpty) return null;
    final duration = _draft.duration < 1 ? 1 : _draft.duration;
    final start = _draft.start;
    final item = ProgramItem(
      id: 'item-${DateTime.now().microsecondsSinceEpoch}',
      santiyeId: widget.siteId,
      name: name,
      startDate: start,
      endDate: ProgramItem.endDateFromDuration(start, duration),
      plannedDays: duration,
      plannedCrew: 1,
      progress: 0,
      status: ProgramStatus.planned,
      responsible: _draft.resources.trim(),
      wbs: _draft.wbs.trim().isEmpty ? null : _draft.wbs.trim(),
      predecessors: _draft.predecessors.trim().isEmpty
          ? null
          : _draft.predecessors.trim(),
    );
    await ref.read(programItemsProvider.notifier).save(item);
    _draft = _Draft.fresh(after: item);
    return item;
  }

  ProgramItem _applyField(ProgramItem item, _Field field, String raw) {
    final text = raw.trim();
    final tracking = ProjectTracking.fromItem(item);
    switch (field) {
      case _Field.wbs:
        return item.copyWith(wbs: text.isEmpty ? null : text);
      case _Field.name:
        return text.isEmpty ? item : item.copyWith(name: text);
      case _Field.duration:
        final days = int.tryParse(text);
        if (days == null) return item;
        return tracking.applyDuration(days).applyTo(item);
      case _Field.predecessors:
        return item.copyWith(predecessors: text.isEmpty ? null : text);
      case _Field.resources:
        return item.copyWith(responsible: text);
      case _Field.percent:
        final value = int.tryParse(text.replaceAll('%', ''));
        if (value == null) return item;
        return tracking.applyPercentComplete(value).applyTo(item);
      case _Field.actualDuration:
        final value = int.tryParse(text);
        if (value == null) return item;
        return tracking.applyActualDuration(value).applyTo(item);
      case _Field.remainingDuration:
        final value = int.tryParse(text);
        if (value == null) return item;
        return tracking.applyRemainingDuration(value).applyTo(item);
      case _Field.actualWork:
        final value = int.tryParse(text);
        if (value == null) return item;
        return tracking.applyActualWork(value).applyTo(item);
      case _Field.remainingWork:
        final value = int.tryParse(text);
        if (value == null) return item;
        return tracking.applyRemainingWork(value).applyTo(item);
    }
  }

  Future<void> _menu(ProgramItem item, _RowAction action) async {
    switch (action) {
      case _RowAction.details:
        widget.onOpenDetails(item);
      case _RowAction.milestone:
        final next = ProjectTracking.fromItem(item)
            .applyMilestone(!item.isMilestone)
            .applyTo(item);
        await ref.read(programItemsProvider.notifier).save(next);
      case _RowAction.delete:
        final accepted = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Görev silinsin mi?'),
            content: Text(item.name),
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
        if (accepted == true) {
          await ref.read(programItemsProvider.notifier).delete(item.id);
        }
    }
  }

  _Field? _nextField(_Field field) {
    final order = widget.view == ProgramTableView.entry
        ? const [
            _Field.wbs,
            _Field.name,
            _Field.duration,
            _Field.predecessors,
            _Field.resources,
          ]
        : const [
            _Field.percent,
            _Field.actualDuration,
            _Field.remainingDuration,
            _Field.actualWork,
            _Field.remainingWork,
          ];
    final index = order.indexOf(field);
    if (index < 0 || index + 1 >= order.length) return null;
    return order[index + 1];
  }
}

class _Draft {
  _Draft({
    required this.name,
    required this.wbs,
    required this.duration,
    required this.start,
    required this.finish,
    required this.predecessors,
    required this.resources,
  });

  factory _Draft.fresh({ProgramItem? after}) {
    final start = after == null
        ? DateTime.now()
        : after.endDate.add(const Duration(days: 1));
    final day = DateTime(start.year, start.month, start.day);
    return _Draft(
      name: '',
      wbs: '',
      duration: 1,
      start: day,
      finish: ProgramItem.endDateFromDuration(day, 1),
      predecessors: '',
      resources: '',
    );
  }

  String name;
  String wbs;
  int duration;
  DateTime start;
  DateTime finish;
  String predecessors;
  String resources;
}

class _Edit {
  const _Edit(this.itemId, this.field);
  final String itemId;
  final _Field field;

  bool matches(String itemId, _Field field) =>
      this.itemId == itemId && this.field == field;
}

enum _Field {
  wbs,
  name,
  duration,
  predecessors,
  resources,
  percent,
  actualDuration,
  remainingDuration,
  actualWork,
  remainingWork,
}

enum _DateField { start, finish, actualStart, actualFinish }

enum _RowAction { details, milestone, delete }

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.view});
  final ProgramTableView view;

  @override
  Widget build(BuildContext context) {
    final rows = view == ProgramTableView.entry
        ? const [
            ['WBS', 'Görev Adı'],
            ['Süre', 'Başlangıç', 'Bitiş'],
            ['Öncüller', 'Kaynak Adları'],
          ]
        : const [
            ['WBS', 'Görev Adı'],
            ['% Tamamlanma', 'Fiili Başlangıç', 'Fiili Bitiş'],
            ['Fiili Süre', 'Kalan Süre', 'Fiili İş', 'Kalan İş'],
          ];
    final flex = view == ProgramTableView.entry
        ? const [
            [2, 7],
            [2, 4, 4],
            [5, 5],
          ]
        : const [
            [2, 7],
            [3, 4, 4],
            [3, 3, 2, 2],
          ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cardInsetSurface,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 32,
              child: Center(
                child: Text(
                  '#',
                  style: AppTypography.cardBodySmall.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.15,
                    color: AppColors.cardTextMuted,
                  ),
                ),
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppColors.cardBorder,
            ),
            Expanded(
              child: Column(
                children: [
                  for (var r = 0; r < rows.length; r++) ...[
                    if (r > 0)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.cardBorder,
                      ),
                    _GridLine(
                      children: [
                        for (var c = 0; c < rows[r].length; c++)
                          _HeaderCell(label: rows[r][c], flex: flex[r][c]),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskBlock extends StatelessWidget {
  const _TaskBlock({
    required this.index,
    required this.item,
    required this.draft,
    required this.view,
    required this.editing,
    required this.onEdit,
    required this.onCommitText,
    required this.onCommitDate,
    required this.onOpenMenu,
  });

  final int index;
  final ProgramItem? item;
  final _Draft? draft;
  final ProgramTableView view;
  final _Edit? editing;
  final void Function(String itemId, _Field field) onEdit;
  final Future<void> Function(String itemId, _Field field, String raw)
  onCommitText;
  final Future<void> Function(String itemId, _DateField field, DateTime? value)
  onCommitDate;
  final ValueChanged<_RowAction>? onOpenMenu;

  String get _id => item?.id ?? _ProgramTableState._draftId;

  @override
  Widget build(BuildContext context) {
    final tracking = item == null ? null : ProjectTracking.fromItem(item!);
    final isDraft = item == null;
    final stripe = index.isEven
        ? AppColors.cardInsetSurface.withValues(alpha: 0.45)
        : Colors.transparent;
    final indent = ((item?.outlineLevel ?? 1) - 1).clamp(0, 6) * 8.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: stripe,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _IdRail(
              index: index,
              draft: isDraft,
              milestone: item?.isMilestone ?? false,
              onSelected: onOpenMenu,
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppColors.cardBorder,
            ),
            Expanded(
              child: view == ProgramTableView.entry
                  ? _EntryBody(
                      id: _id,
                      index: index,
                      item: item,
                      draft: draft,
                      indent: indent,
                      editing: editing,
                      onEdit: onEdit,
                      onCommitText: onCommitText,
                      onCommitDate: onCommitDate,
                    )
                  : _TrackingBody(
                      id: _id,
                      item: item!,
                      tracking: tracking!,
                      indent: indent,
                      editing: editing,
                      onEdit: onEdit,
                      onCommitText: onCommitText,
                      onCommitDate: onCommitDate,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdRail extends StatelessWidget {
  const _IdRail({
    required this.index,
    required this.draft,
    required this.milestone,
    required this.onSelected,
  });

  final int index;
  final bool draft;
  final bool milestone;
  final ValueChanged<_RowAction>? onSelected;

  @override
  Widget build(BuildContext context) {
    final child = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          draft ? '+' : '$index',
          style: AppTypography.cardBodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.cardTextMuted,
          ),
        ),
        if (milestone)
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.flag_rounded, size: 11, color: AppColors.warning),
          ),
      ],
    );

    if (onSelected == null) {
      return SizedBox(width: 32, child: Center(child: child));
    }

    return PopupMenuButton<_RowAction>(
      tooltip: 'Satır',
      onSelected: onSelected,
      padding: EdgeInsets.zero,
      itemBuilder: (context) => const [
        PopupMenuItem(value: _RowAction.details, child: Text('Ayrıntı')),
        PopupMenuItem(
          value: _RowAction.milestone,
          child: Text('Kilometre taşı'),
        ),
        PopupMenuItem(value: _RowAction.delete, child: Text('Sil')),
      ],
      child: SizedBox(width: 32, child: Center(child: child)),
    );
  }
}

class _EntryBody extends StatelessWidget {
  const _EntryBody({
    required this.id,
    required this.index,
    required this.item,
    required this.draft,
    required this.indent,
    required this.editing,
    required this.onEdit,
    required this.onCommitText,
    required this.onCommitDate,
  });

  final String id;
  final int index;
  final ProgramItem? item;
  final _Draft? draft;
  final double indent;
  final _Edit? editing;
  final void Function(String itemId, _Field field) onEdit;
  final Future<void> Function(String itemId, _Field field, String raw)
  onCommitText;
  final Future<void> Function(String itemId, _DateField field, DateTime? value)
  onCommitDate;

  @override
  Widget build(BuildContext context) {
    final wbs = item?.wbs?.trim().isNotEmpty == true
        ? item!.wbs!.trim()
        : (draft?.wbs.isNotEmpty == true ? draft!.wbs : '$index');
    final name = item?.name ?? draft?.name ?? '';
    final duration = item == null
        ? draft!.duration
        : (item!.isMilestone ? 0 : item!.calculatedDays);
    final start = item?.startDate ?? draft!.start;
    final finish = item?.endDate ?? draft!.finish;
    final predecessors = item?.predecessors ?? draft?.predecessors ?? '';
    final resources = item?.responsible ?? draft?.resources ?? '';
    final nameStyle = AppTypography.cardBodySmall.copyWith(
      fontWeight: (item?.outlineLevel ?? 1) <= 1
          ? FontWeight.w700
          : FontWeight.w500,
    );

    return Column(
      children: [
        _GridLine(
          children: [
            _TextCell(
              flex: 2,
              text: wbs,
              hint: 'WBS',
              editing: editing?.matches(id, _Field.wbs) ?? false,
              onTap: () => onEdit(id, _Field.wbs),
              onCommit: (value) => onCommitText(id, _Field.wbs, value),
            ),
            _TextCell(
              flex: 7,
              text: name,
              hint: 'Görev adı yaz…',
              indent: indent,
              style: nameStyle,
              editing: editing?.matches(id, _Field.name) ?? false,
              onTap: () => onEdit(id, _Field.name),
              onCommit: (value) => onCommitText(id, _Field.name, value),
            ),
          ],
        ),
        Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
        _GridLine(
          children: [
            _TextCell(
              flex: 2,
              text: '$duration gün',
              editText: '$duration',
              keyboard: TextInputType.number,
              digitsOnly: true,
              editing: editing?.matches(id, _Field.duration) ?? false,
              onTap: () => onEdit(id, _Field.duration),
              onCommit: (value) => onCommitText(id, _Field.duration, value),
            ),
            _DateCell(
              flex: 4,
              value: start,
              onPick: (date) => onCommitDate(id, _DateField.start, date),
            ),
            _DateCell(
              flex: 4,
              value: finish,
              onPick: (date) => onCommitDate(id, _DateField.finish, date),
            ),
          ],
        ),
        Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
        _GridLine(
          children: [
            _TextCell(
              flex: 5,
              text: predecessors,
              hint: '2FS+1 gün',
              editing: editing?.matches(id, _Field.predecessors) ?? false,
              onTap: () => onEdit(id, _Field.predecessors),
              onCommit: (value) => onCommitText(id, _Field.predecessors, value),
            ),
            _TextCell(
              flex: 5,
              text: resources,
              hint: 'Kaynak',
              editing: editing?.matches(id, _Field.resources) ?? false,
              onTap: () => onEdit(id, _Field.resources),
              onCommit: (value) => onCommitText(id, _Field.resources, value),
            ),
          ],
        ),
      ],
    );
  }
}

class _TrackingBody extends StatelessWidget {
  const _TrackingBody({
    required this.id,
    required this.item,
    required this.tracking,
    required this.indent,
    required this.editing,
    required this.onEdit,
    required this.onCommitText,
    required this.onCommitDate,
  });

  final String id;
  final ProgramItem item;
  final ProjectTracking tracking;
  final double indent;
  final _Edit? editing;
  final void Function(String itemId, _Field field) onEdit;
  final Future<void> Function(String itemId, _Field field, String raw)
  onCommitText;
  final Future<void> Function(String itemId, _DateField field, DateTime? value)
  onCommitDate;

  @override
  Widget build(BuildContext context) {
    final statusColor = programStatusColor(tracking.status());
    final wbs = (item.wbs ?? '').trim().isEmpty ? '' : item.wbs!.trim();

    return Column(
      children: [
        _GridLine(
          children: [
            _ReadCell(flex: 2, text: wbs.isEmpty ? '—' : wbs),
            _ReadCell(
              flex: 7,
              text: item.name,
              indent: indent,
              style: AppTypography.cardBodySmall.copyWith(
                fontWeight: item.outlineLevel <= 1
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ],
        ),
        Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
        _GridLine(
          children: [
            _TextCell(
              flex: 3,
              text: '${tracking.percentComplete}%',
              editText: '${tracking.percentComplete}',
              keyboard: TextInputType.number,
              digitsOnly: true,
              style: AppTypography.cardBodySmall.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w700,
              ),
              editing: editing?.matches(id, _Field.percent) ?? false,
              onTap: () => onEdit(id, _Field.percent),
              onCommit: (value) => onCommitText(id, _Field.percent, value),
            ),
            _DateCell(
              flex: 4,
              value: tracking.actualStart,
              emptyLabel: 'NA',
              onPick: (date) => onCommitDate(id, _DateField.actualStart, date),
              onClear: () => onCommitDate(id, _DateField.actualStart, null),
            ),
            _DateCell(
              flex: 4,
              value: tracking.actualFinish,
              emptyLabel: 'NA',
              onPick: (date) => onCommitDate(id, _DateField.actualFinish, date),
              onClear: () => onCommitDate(id, _DateField.actualFinish, null),
            ),
          ],
        ),
        Divider(height: 1, thickness: 1, color: AppColors.cardBorder),
        _GridLine(
          children: [
            _TextCell(
              flex: 3,
              text: '${tracking.actualDuration} gün',
              editText: '${tracking.actualDuration}',
              keyboard: TextInputType.number,
              digitsOnly: true,
              editing: editing?.matches(id, _Field.actualDuration) ?? false,
              onTap: () => onEdit(id, _Field.actualDuration),
              onCommit: (value) =>
                  onCommitText(id, _Field.actualDuration, value),
            ),
            _TextCell(
              flex: 3,
              text: '${tracking.remainingDuration} gün',
              editText: '${tracking.remainingDuration}',
              keyboard: TextInputType.number,
              digitsOnly: true,
              editing: editing?.matches(id, _Field.remainingDuration) ?? false,
              onTap: () => onEdit(id, _Field.remainingDuration),
              onCommit: (value) =>
                  onCommitText(id, _Field.remainingDuration, value),
            ),
            _TextCell(
              flex: 2,
              text: '${tracking.actualWork}',
              keyboard: TextInputType.number,
              digitsOnly: true,
              editing: editing?.matches(id, _Field.actualWork) ?? false,
              onTap: () => onEdit(id, _Field.actualWork),
              onCommit: (value) => onCommitText(id, _Field.actualWork, value),
            ),
            _TextCell(
              flex: 2,
              text: '${tracking.remainingWork}',
              keyboard: TextInputType.number,
              digitsOnly: true,
              editing: editing?.matches(id, _Field.remainingWork) ?? false,
              onTap: () => onEdit(id, _Field.remainingWork),
              onCommit: (value) =>
                  onCommitText(id, _Field.remainingWork, value),
            ),
          ],
        ),
      ],
    );
  }
}

class _GridLine extends StatelessWidget {
  const _GridLine({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: AppColors.cardBorder,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.label, required this.flex});
  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.cardBodySmall.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.15,
            color: AppColors.cardTextMuted,
          ),
        ),
      ),
    );
  }
}

class _ReadCell extends StatelessWidget {
  const _ReadCell({
    required this.flex,
    required this.text,
    this.indent = 0,
    this.style,
  });

  final int flex;
  final String text;
  final double indent;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: EdgeInsets.fromLTRB(5 + indent, 7, 5, 7),
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: style ?? AppTypography.cardBodySmall,
        ),
      ),
    );
  }
}

class _TextCell extends StatefulWidget {
  const _TextCell({
    required this.flex,
    required this.text,
    required this.editing,
    required this.onTap,
    required this.onCommit,
    this.editText,
    this.hint,
    this.indent = 0,
    this.style,
    this.keyboard,
    this.digitsOnly = false,
  });

  final int flex;
  final String text;
  final String? editText;
  final String? hint;
  final double indent;
  final TextStyle? style;
  final bool editing;
  final TextInputType? keyboard;
  final bool digitsOnly;
  final VoidCallback onTap;
  final ValueChanged<String> onCommit;

  @override
  State<_TextCell> createState() => _TextCellState();
}

class _TextCellState extends State<_TextCell> {
  late final TextEditingController _controller;
  late final FocusNode _focus;
  var _committed = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.editText ?? widget.text);
    _focus = FocusNode();
    _focus.addListener(_onFocus);
    if (widget.editing) _armFocus();
  }

  @override
  void didUpdateWidget(_TextCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editing && !oldWidget.editing) {
      _committed = false;
      _controller.text = widget.editText ?? widget.text;
      _armFocus();
    }
    if (!widget.editing && oldWidget.editing) {
      _committed = false;
    }
  }

  void _armFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.editing) return;
      _focus.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  void _onFocus() {
    if (_focus.hasFocus || !widget.editing) return;
    _commit(_controller.text);
  }

  void _commit(String value) {
    if (_committed) return;
    _committed = true;
    widget.onCommit(value);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final empty = widget.text.trim().isEmpty;
    return Expanded(
      flex: widget.flex,
      child: Material(
        color: widget.editing
            ? AppColors.electricBlue.withValues(alpha: 0.10)
            : Colors.transparent,
        child: InkWell(
          onTap: widget.editing ? null : widget.onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(5 + widget.indent, 4, 5, 4),
            child: widget.editing
                ? TextField(
                    controller: _controller,
                    focusNode: _focus,
                    keyboardType: widget.keyboard,
                    inputFormatters: [
                      if (widget.digitsOnly)
                        FilteringTextInputFormatter.digitsOnly,
                    ],
                    style: (widget.style ?? AppTypography.cardBodySmall)
                        .copyWith(fontSize: 16, height: 1.2),
                    cursorColor: AppColors.electricBlue,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 6),
                    ),
                    onSubmitted: _commit,
                  )
                : Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      empty ? (widget.hint ?? '—') : widget.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: (widget.style ?? AppTypography.cardBodySmall)
                          .copyWith(
                            color: empty ? AppColors.cardTextMuted : null,
                          ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _DateCell extends StatelessWidget {
  const _DateCell({
    required this.flex,
    required this.value,
    required this.onPick,
    this.emptyLabel,
    this.onClear,
  });

  final int flex;
  final DateTime? value;
  final ValueChanged<DateTime> onPick;
  final VoidCallback? onClear;
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    final label = value == null
        ? (emptyLabel ?? '—')
        : ProgramTable.dayFmt.format(value!);
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2040),
          );
          if (picked != null) onPick(picked);
        },
        onLongPress: value == null ? null : onClear,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.cardBodySmall.copyWith(
              color: value == null ? AppColors.cardTextMuted : null,
            ),
          ),
        ),
      ),
    );
  }
}
