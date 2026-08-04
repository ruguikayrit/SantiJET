import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/production_provider.dart';
import '../../domain/entities/project.dart';

/// Proje listesi, aktif proje seçimi, ekleme / silme.
class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectsProvider);
    final activeId = ref.watch(activeProjectIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projeler'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.ayarlar),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Proje'),
      ),
      body: projects.isEmpty
          ? SJEmptyState(
              title: 'Henüz proje yok',
              message: 'Puantaj kayıtları proje kapsamında tutulur.',
              icon: Icons.apartment_outlined,
              actionLabel: 'Proje Ekle',
              onAction: () => _openEditor(context, ref),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                88,
              ),
              itemCount: projects.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final p = projects[index];
                final selected = (activeId ?? projects.first.id) == p.id;
                return SJCard(
                  selected: selected,
                  onTap: () {
                    ref.read(activeProjectIdProvider.notifier).set(p.id);
                  },
                  child: Builder(
                    builder: (context) {
                      final theme = Theme.of(context);
                      return Row(
                        children: [
                          Icon(
                            selected
                                ? Icons.check_circle
                                : Icons.apartment_outlined,
                            color: selected
                                ? AppColors.electricBlueLight
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _CompanyLogoAvatar(project: p),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  p.company.isEmpty
                                      ? 'Firma adı yok'
                                      : p.company,
                                  style: theme.textTheme.titleMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  p.name.isEmpty ? 'İşin adı yok' : p.name,
                                  style: theme.textTheme.bodyMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  p.code.isEmpty ? 'İşin kodu yok' : p.code,
                                  style: theme.textTheme.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (selected)
                                  Text(
                                    'Aktif proje',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppColors.electricBlueLight,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () =>
                                _openEditor(context, ref, existing: p),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Projeyi sil'),
                                  content: Text(
                                    '${p.name} ile bu projeye ait personel, '
                                    'puantaj ve imalat kayıtları silinsin mi?',
                                  ),
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
                              if (ok != true) return;
                              ref
                                  .read(attendanceProvider.notifier)
                                  .deleteForProject(p.id);
                              ref
                                  .read(personnelProvider.notifier)
                                  .deleteForProject(p.id);
                              ref
                                  .read(productionProvider.notifier)
                                  .deleteForProject(p.id);
                              ref.read(projectsProvider.notifier).delete(p.id);
                              if (activeId == p.id) {
                                final remaining = ref.read(projectsProvider);
                                ref
                                    .read(activeProjectIdProvider.notifier)
                                    .set(remaining.isEmpty
                                        ? null
                                        : remaining.first.id);
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

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    Project? existing,
  }) async {
    final result = await showModalBottomSheet<_ProjectEditResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _ProjectEditorSheet(existing: existing),
    );

    if (result == null) return;

    if (existing == null) {
      final created = ref.read(projectsProvider.notifier).add(
            name: result.name,
            code: result.code,
            company: result.company,
            logoBase64: result.logoBase64,
            logoMimeType: result.logoMimeType,
          );
      ref.read(activeProjectIdProvider.notifier).set(created.id);
    } else {
      ref.read(projectsProvider.notifier).update(
            existing.copyWith(
              name: result.name,
              code: result.code,
              company: result.company,
              logoBase64: result.logoBase64,
              logoMimeType: result.logoMimeType,
              clearLogo: result.logoBase64.isEmpty,
            ),
          );
    }
  }
}

class _ProjectEditResult {
  const _ProjectEditResult({
    required this.name,
    required this.code,
    required this.company,
    required this.logoBase64,
    required this.logoMimeType,
  });

  final String name;
  final String code;
  final String company;
  final String logoBase64;
  final String logoMimeType;
}

class _ProjectEditorSheet extends StatefulWidget {
  const _ProjectEditorSheet({this.existing});

  final Project? existing;

  @override
  State<_ProjectEditorSheet> createState() => _ProjectEditorSheetState();
}

class _ProjectEditorSheetState extends State<_ProjectEditorSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _codeCtrl;
  late final TextEditingController _companyCtrl;
  final _picker = ImagePicker();

  String _logoBase64 = '';
  String _logoMimeType = 'image/jpeg';
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _codeCtrl = TextEditingController(text: e?.code ?? '');
    _companyCtrl = TextEditingController(text: e?.company ?? '');
    _logoBase64 = e?.logoBase64 ?? '';
    _logoMimeType = e?.logoMimeType ?? 'image/jpeg';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _companyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 1.5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logo çok büyük (en fazla ~1.5 MB)'),
            ),
          );
        }
        return;
      }
      setState(() {
        _logoBase64 = base64Encode(bytes);
        _logoMimeType = file.mimeType ?? 'image/jpeg';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logo seçilemedi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        bottom + AppSpacing.md,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? 'Yeni proje' : 'Projeyi düzenle',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Firma logosu',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: Column(
                children: [
                  Material(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _picking ? null : _pickLogo,
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 96,
                        height: 96,
                        child: _logoBase64.isEmpty
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_picking)
                                    const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  else
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      color: theme.colorScheme.primary,
                                    ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Logo ekle',
                                    style: theme.textTheme.labelSmall,
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  base64Decode(_logoBase64),
                                  fit: BoxFit.contain,
                                  width: 96,
                                  height: 96,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.broken_image_outlined,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                  if (_logoBase64.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    TextButton.icon(
                      onPressed: () => setState(() {
                        _logoBase64 = '';
                        _logoMimeType = 'image/jpeg';
                      }),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Logoyu kaldır'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _companyCtrl,
              decoration: const InputDecoration(labelText: 'Firma adı'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'İşin adı'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _codeCtrl,
              decoration: const InputDecoration(labelText: 'İşin kodu'),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: () {
                if (_nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(
                  context,
                  _ProjectEditResult(
                    name: _nameCtrl.text.trim(),
                    code: _codeCtrl.text.trim(),
                    company: _companyCtrl.text.trim(),
                    logoBase64: _logoBase64,
                    logoMimeType: _logoMimeType,
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

class _CompanyLogoAvatar extends StatelessWidget {
  const _CompanyLogoAvatar({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!project.hasLogo) {
      return Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.business_outlined,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    try {
      final bytes = base64Decode(project.logoBase64);
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          bytes,
          width: 40,
          height: 40,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.broken_image_outlined,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    } catch (_) {
      return Icon(
        Icons.broken_image_outlined,
        size: 20,
        color: theme.colorScheme.onSurfaceVariant,
      );
    }
  }
}
