import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/sj_button.dart';
import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/id_gen.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/catalog_provider.dart';
import '../../data/providers/company_provider.dart';
import '../../data/services/personnel_import_service.dart';
import '../../domain/entities/person.dart';

/// Personel listesi — aktif projeye özel.
class PersonnelScreen extends ConsumerWidget {
  const PersonnelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(activeProjectProvider);
    final people = ref.watch(projectPersonnelProvider);
    final theme = Theme.of(context);

    if (project == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Personel'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(AppRoutes.yonetim),
          ),
        ),
        body: SJEmptyState(
          title: 'Önce proje ekleyin',
          message: 'Personel her proje için ayrı tutulur.',
          icon: Icons.apartment_outlined,
          actionLabel: 'Projelere Git',
          onAction: () => context.go(AppRoutes.projeler),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personel'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.yonetim),
        ),
        actions: [
          IconButton(
            tooltip: 'PDF / Excel’den veri al',
            onPressed: () => _importFromFile(
              context,
              ref,
              projectId: project.id,
            ),
            icon: const Icon(Icons.upload_file_outlined),
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Center(
              child: Text(project.name, style: theme.textTheme.labelMedium),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'personnel_import',
            onPressed: () => _importFromFile(
              context,
              ref,
              projectId: project.id,
            ),
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text('PDF / Excel’den veri al'),
          ),
          const SizedBox(height: AppSpacing.sm),
          FloatingActionButton.extended(
            heroTag: 'personnel_add',
            onPressed: () => _openEditor(context, ref, projectId: project.id),
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Ekle'),
          ),
        ],
      ),
      body: people.isEmpty
          ? SJEmptyState(
              title: 'Bu projede personel yok',
              message:
                  '${project.name} için personel ekleyin veya '
                  'PDF / Excel’den liste yükleyin.',
              icon: Icons.groups_outlined,
              actionLabel: 'Personel Ekle',
              onAction: () =>
                  _openEditor(context, ref, projectId: project.id),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                160,
              ),
              itemCount: people.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final p = people[index];
                final meta = [
                  if (p.company.isNotEmpty) p.company,
                  if (p.profession.isNotEmpty) p.profession,
                  if (p.team.isNotEmpty) p.team,
                  if (p.tc.isNotEmpty) 'TC ${p.tc}',
                ].join(' · ');
                return SJCard(
                  onTap: () => _openEditor(
                    context,
                    ref,
                    projectId: project.id,
                    existing: p,
                  ),
                  child: Builder(
                    builder: (context) {
                      final theme = Theme.of(context);
                      return Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: theme.colorScheme.primary
                                .withValues(alpha: 0.15),
                            child: Text(
                              p.name.isNotEmpty
                                  ? p.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: theme.textTheme.titleMedium,
                                ),
                                if (meta.isNotEmpty)
                                  Text(meta, style: theme.textTheme.bodySmall),
                                if (p.phone.isNotEmpty ||
                                    p.hireDate.isNotEmpty)
                                  Text(
                                    [
                                      if (p.phone.isNotEmpty) p.phone,
                                      if (p.hireDate.isNotEmpty)
                                        'Giriş ${p.hireDate}',
                                      if (p.leaveDate.isNotEmpty)
                                        'Çıkış ${p.leaveDate}',
                                    ].join(' · '),
                                    style: theme.textTheme.labelSmall,
                                  ),
                              ],
                            ),
                          ),
                          if (!p.active)
                            Text(
                              'Pasif',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Personeli sil'),
                                  content: Text('${p.name} silinsin mi?'),
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
                      );
                    },
                  ),
                );
              },
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

      final people = [for (final r in rows) r.toPerson(projectId)];
      ref.read(personnelProvider.notifier).addAll(people);

      // Kataloglara yeni meslek / ekip ekle
      final professions = ref.read(professionsProvider.notifier);
      final teams = ref.read(teamsProvider.notifier);
      for (final p in people) {
        if (p.profession.isNotEmpty) professions.add(p.profession);
        if (p.team.isNotEmpty) teams.add(p.team);
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${people.length} personel yüklendi')),
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
              'PDF / Excel’den veri al',
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
                color: AppColors.canvas,
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
                              Text(cell, style: theme.textTheme.labelSmall),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Desteklenen: .xlsx · .xls · .csv · .pdf',
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
                    title: Text(r.displayName),
                    subtitle: Text(
                      [
                        if (r.company.isNotEmpty) r.company,
                        if (r.profession.isNotEmpty) r.profession,
                        if (r.team.isNotEmpty) r.team,
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
  late final TextEditingController _hireDate;
  late final TextEditingController _leaveDate;
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
    _hireDate = TextEditingController(text: e?.hireDate ?? '');
    _leaveDate = TextEditingController(text: e?.leaveDate ?? '');
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
    _hireDate.dispose();
    _leaveDate.dispose();
    super.dispose();
  }

  /// Firma Bilgileri + proje firmaları + mevcut personel firmaları.
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
    // Firma listesi değişince alan yeniden çizilsin.
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
              decoration: const InputDecoration(labelText: 'TC'),
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
              controller: _hireDate,
              decoration: const InputDecoration(
                labelText: 'İşe giriş',
                hintText: 'yyyy-MM-dd',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _leaveDate,
              decoration: const InputDecoration(
                labelText: 'İşten çıkış',
                hintText: 'yyyy-MM-dd',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Adres'),
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
                    hireDate: _hireDate.text.trim(),
                    leaveDate: _leaveDate.text.trim(),
                    active: _active,
                  ),
                );
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
