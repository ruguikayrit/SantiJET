import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_button.dart';
import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/id_gen.dart';
import '../../core/utils/puantaj_date.dart';
import '../../core/utils/text_format.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/catalog_provider.dart';
import '../../data/providers/company_provider.dart';
import '../../data/services/personnel_import_service.dart';
import '../../domain/entities/person.dart';

/// Personel listesi — aktif projeye özel; firmaya göre gruplu.
class PersonnelScreen extends ConsumerStatefulWidget {
  const PersonnelScreen({super.key});

  @override
  ConsumerState<PersonnelScreen> createState() => _PersonnelScreenState();
}

class _PersonnelScreenState extends ConsumerState<PersonnelScreen> {
  /// Kapalı firma başlıkları (varsayılan: hepsi açık).
  final Set<String> _collapsedCompanies = {};
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  List<({String company, List<Person> people})> _groupByCompany(
    List<Person> people,
  ) {
    final map = <String, List<Person>>{};
    for (final p in people) {
      final key = p.company.trim();
      map.putIfAbsent(key, () => []).add(p);
    }
    for (final list in map.values) {
      list.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    }
    final keys = map.keys.toList()
      ..sort((a, b) {
        if (a.isEmpty && b.isNotEmpty) return 1;
        if (b.isEmpty && a.isNotEmpty) return -1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });
    return [
      for (final k in keys) (company: k, people: map[k]!),
    ];
  }

  String _companyLabel(String key) =>
      key.isEmpty ? 'Firma belirtilmemiş' : key;

  void _toggleCompany(String key) {
    setState(() {
      if (_collapsedCompanies.contains(key)) {
        _collapsedCompanies.remove(key);
      } else {
        _collapsedCompanies.add(key);
      }
    });
  }

  void _exitSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _enterSelection([String? initialId]) {
    setState(() {
      _selectionMode = true;
      _selectedIds.clear();
      if (initialId != null) _selectedIds.add(initialId);
    });
  }

  void _toggleSelected(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectionMode = true;
        _selectedIds.add(id);
      }
    });
  }

  void _toggleSelectGroup(List<Person> group) {
    setState(() {
      final ids = group.map((p) => p.id).toList();
      final allSelected =
          ids.isNotEmpty && ids.every(_selectedIds.contains);
      if (allSelected) {
        _selectedIds.removeAll(ids);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectionMode = true;
        _selectedIds.addAll(ids);
      }
    });
  }

  void _selectAll(List<Person> people) {
    setState(() {
      final ids = people.map((p) => p.id).toList();
      final allSelected =
          ids.isNotEmpty && ids.every(_selectedIds.contains);
      if (allSelected) {
        _selectedIds.clear();
        _selectionMode = false;
      } else {
        _selectionMode = true;
        _selectedIds
          ..clear()
          ..addAll(ids);
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Toplu sil'),
        content: Text('$count personel silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    ref.read(personnelProvider.notifier).deleteMany(_selectedIds);
    _exitSelection();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$count personel silindi')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(activeProjectProvider);
    final people = ref.watch(projectPersonnelProvider);
    final theme = Theme.of(context);

    if (project == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SantijetHeader(subtitle: 'Personel'),
              Expanded(
                child: SJEmptyState(
                  title: 'Önce proje ekleyin',
                  message: 'Personel her proje için ayrı tutulur.',
                  icon: Icons.apartment_outlined,
                  actionLabel: 'Projelere Git',
                  onAction: () => context.go(AppRoutes.projeler),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final groups = _groupByCompany(people);

    final canPop = context.canPop();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: _selectionMode
          ? AppBar(
              title: Text('${_selectedIds.length} seçili'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelection,
              ),
              actions: [
                IconButton(
                  tooltip: 'Tümünü seç',
                  onPressed: people.isEmpty ? null : () => _selectAll(people),
                  icon: const Icon(Icons.select_all),
                ),
                IconButton(
                  tooltip: 'Seçilenleri sil',
                  onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            )
          : canPop
              ? AppBar(
                  title: const Text('Personel'),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
                )
              : null,
      floatingActionButton: _selectionMode
          ? null
          : FloatingActionButton.extended(
              heroTag: 'personnel_add',
              onPressed: () =>
                  _openEditor(context, ref, projectId: project.id),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Ekle'),
            ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_selectionMode && !canPop) ...[
              const SantijetHeader(subtitle: 'Personel'),
            ],
            if (!_selectionMode) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.afterHeader,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.name,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.useDarkChrome
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (people.isNotEmpty)
                      IconButton(
                        tooltip: 'Seç',
                        onPressed: () => _enterSelection(),
                        icon: const Icon(Icons.checklist_rtl),
                      ),
                    IconButton(
                      tooltip: 'Excel’den içe aktar',
                      onPressed: () => _importFromFile(
                        context,
                        ref,
                        projectId: project.id,
                      ),
                      icon: const Icon(Icons.upload_file_outlined),
                    ),
                  ],
                ),
              ),
            ],
            Expanded(
              child: people.isEmpty
                  ? SJEmptyState(
                      title: 'Bu projede personel yok',
                      message:
                          '${project.name} için personel ekleyin veya '
                          'Excel’den liste yükleyin.',
                      icon: Icons.groups_outlined,
                      actionLabel: 'Personel Ekle',
                      onAction: () =>
                          _openEditor(context, ref, projectId: project.id),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.md,
                        88,
                      ),
                      itemCount: groups.length,
                      itemBuilder: (context, gi) {
                        final g = groups[gi];
                        final key = g.company;
                        final expanded = !_collapsedCompanies.contains(key);
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom:
                                gi == groups.length - 1 ? 0 : AppSpacing.md,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _CompanyHeader(
                                label: _companyLabel(key),
                                count: g.people.length,
                                expanded: expanded,
                                selectionMode: _selectionMode,
                                selectedInGroup: g.people
                                    .where((p) => _selectedIds.contains(p.id))
                                    .length,
                                onToggle: () => _toggleCompany(key),
                                onSelectGroup: () =>
                                    _toggleSelectGroup(g.people),
                              ),
                              if (expanded) ...[
                                const SizedBox(height: AppSpacing.xs),
                                for (var i = 0; i < g.people.length; i++) ...[
                                  if (i > 0)
                                    const SizedBox(height: AppSpacing.xs),
                                  _PersonTile(
                                    index: i + 1,
                                    person: g.people[i],
                                    selectionMode: _selectionMode,
                                    selected: _selectedIds
                                        .contains(g.people[i].id),
                                    onTap: () {
                                      if (_selectionMode) {
                                        _toggleSelected(g.people[i].id);
                                      } else {
                                        _openEditor(
                                          context,
                                          ref,
                                          projectId: project.id,
                                          existing: g.people[i],
                                        );
                                      }
                                    },
                                    onLongPress: () {
                                      if (!_selectionMode) {
                                        _enterSelection(g.people[i].id);
                                      }
                                    },
                                    onDelete: () async {
                                      final p = g.people[i];
                                      final ok = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Personeli sil'),
                                          content:
                                              Text('${p.name} silinsin mi?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text('Vazgeç'),
                                            ),
                                            FilledButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: const Text('Sil'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (ok == true) {
                                        ref
                                            .read(personnelProvider.notifier)
                                            .delete(p.id);
                                      }
                                    },
                                  ),
                                ],
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importFromFile(
    BuildContext context,
    WidgetRef ref, {
    required String projectId,
  }) async {
    final proceed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => const _PersonnelImportPreviewSheet(),
    );
    if (proceed != true || !context.mounted) return;

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: PersonnelImportService.allowedExtensions,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty || !context.mounted) return;
    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dosya okunamadı.')),
      );
      return;
    }

    try {
      final rows = PersonnelImportService().parseBytes(
        bytes: bytes,
        fileName: file.name,
      );
      final confirm = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (ctx) => _PersonnelImportConfirmSheet(rows: rows),
      );
      if (confirm != true || !context.mounted) return;

      final imported = [for (final r in rows) r.toPerson(projectId)];
      ref.read(personnelProvider.notifier).addAll(imported);

      final professions = ref.read(professionsProvider.notifier);
      final teams = ref.read(teamsProvider.notifier);
      for (final p in imported) {
        if (p.profession.isNotEmpty) professions.add(p.profession);
        if (p.team.isNotEmpty) teams.add(p.team);
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${imported.length} personel yüklendi')),
      );
    } on PersonnelImportException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İçe aktarma başarısız: $e')),
      );
    }
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    required String projectId,
    Person? existing,
  }) async {
    final result = await showModalBottomSheet<Person>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _PersonEditorSheet(
        projectId: projectId,
        existing: existing,
      ),
    );
    if (result == null) return;
    final notifier = ref.read(personnelProvider.notifier);
    if (existing == null) {
      notifier.add(result);
    } else {
      notifier.update(result);
    }
  }
}

class _CompanyHeader extends StatelessWidget {
  const _CompanyHeader({
    required this.label,
    required this.count,
    required this.expanded,
    required this.selectionMode,
    required this.selectedInGroup,
    required this.onToggle,
    required this.onSelectGroup,
  });

  final String label;
  final int count;
  final bool expanded;
  final bool selectionMode;
  final int selectedInGroup;
  final VoidCallback onToggle;
  final VoidCallback onSelectGroup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Chrome üzerinde: koyu iskelette açık mavi, açık iskelette marka mavisi.
    final accent = AppColors.useDarkChrome
        ? AppColors.electricBlueLight
        : AppColors.electricBlue;
    final headerBg = AppColors.surfaceElevated;
    final countInk = AppColors.readableSecondaryOn(headerBg);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadii.md,
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadii.md,
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.5),
            ),
            color: headerBg,
          ),
          child: Row(
            children: [
              Icon(
                expanded
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.keyboard_arrow_right_rounded,
                color: accent,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
              Text(
                selectionMode && selectedInGroup > 0
                    ? '$selectedInGroup / $count'
                    : '$count',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: countInk,
                ),
              ),
              IconButton(
                tooltip: selectedInGroup == count && count > 0
                    ? 'Grup seçimini kaldır'
                    : 'Grubu seç',
                visualDensity: VisualDensity.compact,
                onPressed: onSelectGroup,
                icon: Icon(
                  selectedInGroup == count && count > 0
                      ? Icons.check_box
                      : selectedInGroup > 0
                          ? Icons.indeterminate_check_box
                          : Icons.check_box_outline_blank,
                  size: 22,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({
    required this.index,
    required this.person,
    required this.selectionMode,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
  });

  /// Firma içi sıra numarası (1’den başlar).
  final int index;
  final Person person;
  final bool selectionMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = person;
    final meta = [
      if (p.profession.isNotEmpty) titleCaseTr(p.profession),
      if (p.team.isNotEmpty) titleCaseTr(p.team),
    ].join(' · ');

    return GestureDetector(
      onLongPress: onLongPress,
      child: SJCard(
        onTap: onTap,
        selected: selected,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        // Kart kontrast teması — Theme.of dış context'ten alınmamalı.
        child: Builder(
          builder: (context) {
            final theme = Theme.of(context);
            return Row(
              children: [
                if (selectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: Icon(
                      selected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 22,
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  )
                else
                  CircleAvatar(
                    radius: 14,
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.15),
                    child: Text(
                      '$index',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: index >= 100 ? 10 : 12,
                        height: 1,
                      ),
                    ),
                  ),
                if (!selectionMode) const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        titleCaseTr(p.name),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                      if (meta.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.15,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!p.active)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xxs),
                    child: Text(
                      'Pasif',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error,
                        height: 1,
                      ),
                    ),
                  ),
                if (!selectionMode)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                    tooltip: 'Sil',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 36,
                      height: 36,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Yüklemeden önce örnek sütun / satır önizlemesi.
class _PersonnelImportPreviewSheet extends StatelessWidget {
  const _PersonnelImportPreviewSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Excel’den içe aktar',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Yüklemeden önce örnek liste formatı. Sütunlar yalnızca bunlar '
              'olabilir; diğer sütunlar yok sayılır.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(8),
                color: AppColors.surfaceElevated,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 36,
                  dataRowMinHeight: 32,
                  dataRowMaxHeight: 40,
                  columnSpacing: 16,
                  columns: [
                    for (final h in PersonnelImportSample.headers)
                      DataColumn(
                        label: Text(
                          h,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.readableOn(
                              AppColors.surfaceElevated,
                            ),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                  rows: [
                    for (final row in PersonnelImportSample.rows)
                      DataRow(
                        cells: [
                          for (final cell in row)
                            DataCell(
                              Text(
                                cell,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.readableSecondaryOn(
                                    AppColors.surfaceElevated,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Desteklenen: .xlsx · .xls · .csv',
              style: theme.textTheme.labelSmall,
            ),
            const SizedBox(height: AppSpacing.md),
            SJButton(
              label: 'Dosya seç ve yükle',
              icon: Icons.upload_file_outlined,
              expanded: true,
              onPressed: () => Navigator.pop(context, true),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonnelImportConfirmSheet extends StatelessWidget {
  const _PersonnelImportConfirmSheet({required this.rows});

  final List<PersonnelImportRow> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${rows.length} satır bulundu',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.4,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: rows.length.clamp(0, 50),
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final r = rows[i];
                  return ListTile(
                    dense: true,
                    title: Text(titleCaseTr(r.displayName)),
                    subtitle: Text(
                      [
                        if (r.company.isNotEmpty) titleCaseTr(r.company),
                        if (r.profession.isNotEmpty) titleCaseTr(r.profession),
                        if (r.team.isNotEmpty) titleCaseTr(r.team),
                        if (r.phone.isNotEmpty) r.phone,
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
            if (rows.length > 50)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '… ve ${rows.length - 50} satır daha',
                  style: theme.textTheme.labelSmall,
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            SJButton(
              label: 'İçe aktar',
              icon: Icons.check,
              expanded: true,
              onPressed: () => Navigator.pop(context, true),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonEditorSheet extends ConsumerStatefulWidget {
  const _PersonEditorSheet({
    required this.projectId,
    this.existing,
  });

  final String projectId;
  final Person? existing;

  @override
  ConsumerState<_PersonEditorSheet> createState() => _PersonEditorSheetState();
}

class _PersonEditorSheetState extends ConsumerState<_PersonEditorSheet> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _company;
  late final TextEditingController _address;
  late final TextEditingController _tc;
  late final TextEditingController _iban;
  late final TextEditingController _bankName;
  String _hireDate = '';
  String _leaveDate = '';
  String _profession = '';
  String _team = '';
  bool _active = true;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _company = TextEditingController(text: e?.company ?? '');
    _address = TextEditingController(text: e?.address ?? '');
    _tc = TextEditingController(text: e?.tc ?? '');
    _iban = TextEditingController(text: e?.iban ?? '');
    _bankName = TextEditingController(text: e?.bankName ?? '');
    _hireDate = e?.hireDate ?? '';
    _leaveDate = e?.leaveDate ?? '';
    _profession = e?.profession ?? '';
    _team = e?.team ?? '';
    _active = e?.active ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _company.dispose();
    _address.dispose();
    _tc.dispose();
    _iban.dispose();
    _bankName.dispose();
    super.dispose();
  }

  static DateTime? _parseStoredDate(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    final iso = DateTime.tryParse(s);
    if (iso != null) return DateTime(iso.year, iso.month, iso.day);
    return PuantajDate.tryParse(s);
  }

  static String _storeDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  static String _displayDate(String raw) {
    final d = _parseStoredDate(raw);
    return d == null ? '' : PuantajDate.format(d);
  }

  Future<void> _pickDate({required bool hire}) async {
    final current = _parseStoredDate(hire ? _hireDate : _leaveDate);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(1990),
      lastDate: DateTime(now.year + 5),
      helpText: hire ? 'İşe giriş tarihi' : 'İşten çıkış tarihi',
      cancelText: 'Vazgeç',
      confirmText: 'Seç',
      fieldLabelText: 'Tarih',
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (hire) {
        _hireDate = _storeDate(picked);
      } else {
        _leaveDate = _storeDate(picked);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final leaveDay = DateTime(picked.year, picked.month, picked.day);
        if (leaveDay.isBefore(today)) {
          _active = false;
        }
      }
    });
  }

  List<String> _registeredCompanies() {
    final names = <String>{};
    final companyInfo = ref.read(companyInfoProvider).name.trim();
    if (companyInfo.isNotEmpty) names.add(companyInfo);
    for (final p in ref.read(projectsProvider)) {
      final c = p.company.trim();
      if (c.isNotEmpty) names.add(c);
    }
    for (final p in ref.read(personnelProvider)) {
      final c = p.company.trim();
      if (c.isNotEmpty) names.add(c);
    }
    final list = names.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  Future<void> _pickCompany() async {
    final companies = _registeredCompanies();
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Text(
                  'Kayıtlı firmalar',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (companies.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    'Henüz kayıtlı firma yok.\n'
                    'Ayarlar → Yönetim → Firma Bilgileri veya proje firma adından eklenir.',
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(ctx).height * 0.45,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: companies.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final name = companies[i];
                      final selected = _company.text.trim() == name;
                      return ListTile(
                        title: Text(name),
                        trailing: selected
                            ? Icon(
                                Icons.check,
                                color: theme.colorScheme.primary,
                              )
                            : null,
                        onTap: () => Navigator.pop(ctx, name),
                      );
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx, ''),
                  child: const Text('Temizle'),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || selected == null) return;
    setState(() => _company.text = selected);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final professions = ref.watch(professionsProvider);
    final teams = ref.watch(teamsProvider);
    ref.watch(companyInfoProvider);
    ref.watch(projectsProvider);
    ref.watch(personnelProvider);
    final professionItems = [
      ...professions,
      if (_profession.isNotEmpty && !professions.contains(_profession))
        _profession,
    ];
    final teamItems = [
      ...teams,
      if (_team.isNotEmpty && !teams.contains(_team)) _team,
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        bottom + AppSpacing.md,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? 'Yeni personel' : 'Personeli düzenle',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Ad Soyad'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              value: _profession.isEmpty ? null : _profession,
              decoration: const InputDecoration(
                labelText: 'Meslek',
                helperText: 'Listeyi Ayarlar → Meslekler’den düzenleyin',
              ),
              items: [
                for (final p in professionItems)
                  DropdownMenuItem(value: p, child: Text(p)),
              ],
              onChanged: (v) => setState(() => _profession = v ?? ''),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              value: _team.isEmpty ? null : _team,
              decoration: const InputDecoration(
                labelText: 'Ekip',
                helperText: 'Listeyi Ayarlar → Ekipler’den düzenleyin',
              ),
              items: [
                for (final t in teamItems)
                  DropdownMenuItem(value: t, child: Text(t)),
              ],
              onChanged: (v) => setState(() => _team = v ?? ''),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _company,
              readOnly: true,
              onTap: _pickCompany,
              decoration: const InputDecoration(
                labelText: 'Firma',
                hintText: 'Kayıtlı firmadan seçin',
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _tc,
              decoration: const InputDecoration(labelText: 'TC No'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Telefon'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Adres'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _iban,
              decoration: const InputDecoration(
                labelText: 'IBAN No',
                hintText: 'TR00 0000 0000 0000 0000 0000 00',
              ),
              textCapitalization: TextCapitalization.characters,
              keyboardType: TextInputType.visiblePassword,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _bankName,
              decoration: const InputDecoration(labelText: 'Banka adı'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: AppSpacing.sm),
            _DatePickerField(
              label: 'İşe giriş',
              value: _displayDate(_hireDate),
              emptyHint: 'Tarih seçin',
              onTap: () => _pickDate(hire: true),
              onClear: _hireDate.isEmpty
                  ? null
                  : () => setState(() => _hireDate = ''),
            ),
            const SizedBox(height: AppSpacing.sm),
            _DatePickerField(
              label: 'İşten çıkış',
              value: _displayDate(_leaveDate),
              emptyHint: 'Tarih seçin (opsiyonel)',
              onTap: () => _pickDate(hire: false),
              onClear: _leaveDate.isEmpty
                  ? null
                  : () => setState(() => _leaveDate = ''),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Aktif'),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            FilledButton(
              onPressed: () {
                final name = _name.text.trim();
                if (name.isEmpty) return;
                final leave = _leaveDate.trim();
                final leaveDay = Person.parseEmploymentDate(leave);
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                // Çıkış gününden sonraki takvim günlerinde otomatik pasif.
                final active = leaveDay != null && leaveDay.isBefore(today)
                    ? false
                    : _active;
                Navigator.pop(
                  context,
                  Person(
                    id: widget.existing?.id ?? IdGen.make('per'),
                    projectId: widget.existing?.projectId ?? widget.projectId,
                    name: name,
                    profession: _profession,
                    phone: _phone.text.trim(),
                    company: _company.text.trim(),
                    team: _team,
                    address: _address.text.trim(),
                    tc: _tc.text.trim(),
                    iban: _iban.text.trim().toUpperCase(),
                    bankName: _bankName.text.trim(),
                    hireDate: _hireDate.trim(),
                    leaveDate: leave,
                    active: active,
                  ),
                );
              },
              child: const Text('Kaydet'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Takvimden tarih seçimi — klavye ile yazım yok.
class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.value,
    required this.emptyHint,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String value;
  final String emptyHint;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final empty = value.isEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.sm,
      child: InputDecorator(
        isEmpty: empty,
        decoration: InputDecoration(
          labelText: label,
          hintText: emptyHint,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onClear != null)
                IconButton(
                  tooltip: 'Temizle',
                  onPressed: onClear,
                  icon: const Icon(Icons.clear, size: 20),
                ),
              IconButton(
                tooltip: 'Takvim',
                onPressed: onTap,
                icon: const Icon(Icons.calendar_today_outlined, size: 20),
              ),
            ],
          ),
        ),
        // Boşken görünür metin yok — hintText kullanılır (etiket çakışmaz).
        child: empty
            ? const SizedBox(width: double.infinity, height: 24)
            : Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge,
              ),
      ),
    );
  }
}
