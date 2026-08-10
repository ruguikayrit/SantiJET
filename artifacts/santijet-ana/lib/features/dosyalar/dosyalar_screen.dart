import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/sj_empty_state.dart';
import '../../core/widgets/sj_form_field.dart';
import '../../core/widgets/sj_primary_button.dart';
import '../../data/providers/app_state_provider.dart';
import '../../domain/models/archive_file.dart';
import '../../domain/models/page_key.dart';
import '../common/module_helpers.dart';

class DosyalarScreen extends ConsumerStatefulWidget {
  const DosyalarScreen({super.key});

  @override
  ConsumerState<DosyalarScreen> createState() => _DosyalarScreenState();
}

class _DosyalarScreenState extends ConsumerState<DosyalarScreen> {
  String? _projectFilter;
  bool _canEdit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _canEdit = guardPage(context, ref, 'dosyalar');
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final colors = ref.watch(themeDefinitionProvider).colors;
    final perm = state.getPermission('dosyalar');
    if (perm == Permission.none) return const SizedBox.shrink();
    _canEdit = perm == Permission.edit;

    if (state.projects.isEmpty) {
      return const ModuleScaffold(
        title: 'Dosyalar',
        body: SjEmptyState(
          title: 'Önce proje ekleyin',
          message: 'Dosya arşivi için en az bir proje gerekli.',
          icon: Icons.folder_outlined,
        ),
      );
    }

    final items = state.archiveFiles
        .where((f) => _projectFilter == null || f.projectId == _projectFilter)
        .toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));

    return ModuleScaffold(
      title: 'Dosyalar',
      floatingActionButton: _canEdit
          ? FloatingActionButton(
              onPressed: _pickAndAdd,
              backgroundColor: colors.primary,
              child: const Icon(Icons.upload_file, color: Colors.white),
            )
          : null,
      bottom: ProjectFilterBar(
        value: _projectFilter,
        onChanged: (v) => setState(() => _projectFilter = v),
      ),
      body: items.isEmpty
          ? const SjEmptyState(
              title: 'Dosya yok',
              message: 'Arşive dosya eklemek için + butonunu kullanın.',
              icon: Icons.insert_drive_file_outlined,
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 88),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final f = items[i];
                return EntityCard(
                  title: f.name,
                  subtitle:
                      '${projectNameOf(state.projects, f.projectId)} · ${f.ext.toUpperCase()}'
                      ' · ${_fmtSize(f.size)} · ${f.addedAt}',
                  onTap: _canEdit ? () => _editNote(f) : null,
                  onDelete: _canEdit
                      ? () async {
                          if (await confirmDelete(context, 'Dosyayı sil')) {
                            ref
                                .read(appStateProvider.notifier)
                                .deleteArchiveFile(f.id);
                          }
                        }
                      : null,
                  extra: f.note.isNotEmpty
                      ? Text(f.note, style: AppTypography.bodySmall)
                      : null,
                );
              },
            ),
    );
  }

  String _fmtSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _pickAndAdd() async {
    final state = ref.read(appStateProvider);
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final name = file.name;
    final ext = name.contains('.')
        ? name.split('.').last.toLowerCase()
        : (file.extension ?? '');
    final mime = _mimeFor(ext);
    final storageKey = file.path ?? name;
    final projectId = _projectFilter ?? state.projects.first.id;
    final noteCtrl = TextEditingController();

    if (!mounted) return;
    await showFormSheet(
      context: context,
      ref: ref,
      title: 'Dosya Ekle',
      heightFactor: 0.5,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(name, style: AppTypography.titleMedium),
            const SizedBox(height: 4),
            Text(
              '${ext.toUpperCase()} · ${_fmtSize(file.size)}',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            SjFormField(label: 'Not', controller: noteCtrl, maxLines: 3),
            const Spacer(),
            SjPrimaryButton(
              label: 'Arşive Ekle',
              onPressed: () {
                ref.read(appStateProvider.notifier).addArchiveFile(
                      ArchiveFile(
                        id: '',
                        projectId: projectId,
                        name: name,
                        ext: ext,
                        mime: mime,
                        size: file.size,
                        storageKey: storageKey,
                        addedAt: todayIso(),
                        note: noteCtrl.text.trim(),
                      ),
                    );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editNote(ArchiveFile f) async {
    final noteCtrl = TextEditingController(text: f.note);
    await showFormSheet(
      context: context,
      ref: ref,
      title: 'Dosya Notu',
      heightFactor: 0.45,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(f.name, style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.md),
            SjFormField(label: 'Not', controller: noteCtrl, maxLines: 4),
            const Spacer(),
            SjPrimaryButton(
              label: 'Kaydet',
              onPressed: () {
                ref.read(appStateProvider.notifier).updateArchiveFile(
                      f.id,
                      (x) => x.copyWith(note: noteCtrl.text.trim()),
                    );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _mimeFor(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'xlsx':
      case 'xls':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'docx':
      case 'doc':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'dwg':
        return 'application/acad';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
}
