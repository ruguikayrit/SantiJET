import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/design_system/sj_modal.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/puantaj_date.dart';
import '../../core/utils/text_format.dart';
import '../../core/utils/id_gen.dart';
import '../../core/widgets/annotated_photo_viewer.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/active_operator_provider.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/catalog_provider.dart';
import '../../data/providers/tasks_provider.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/site_task.dart';
import '../../domain/enums/task_status.dart';
import '../../domain/permissions/role_degree.dart';
import 'widgets/task_calendar_panel.dart';

/// Saha görevleri — atayan (1. derece) + atanan görür.
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  TaskStatus? _filter;
  String? _categoryFilter;
  final _listScrollController = ScrollController();

  /// Tamamlandı seçilince 2 sn yerinde tutulan görevler.
  final Set<String> _pinnedDoneIds = {};
  final Map<String, Timer> _pinTimers = {};

  @override
  void dispose() {
    for (final t in _pinTimers.values) {
      t.cancel();
    }
    _listScrollController.dispose();
    super.dispose();
  }

  void _setTaskStatus(String id, TaskStatus status) {
    ref.read(tasksProvider.notifier).setStatus(id, status);
    _pinTimers[id]?.cancel();
    _pinTimers.remove(id);
    if (status == TaskStatus.done) {
      setState(() => _pinnedDoneIds.add(id));
      _pinTimers[id] = Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() => _pinnedDoneIds.remove(id));
        _pinTimers.remove(id);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_listScrollController.hasClients) return;
          _listScrollController.animateTo(
            _listScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
          );
        });
      });
    } else {
      setState(() => _pinnedDoneIds.remove(id));
    }
  }

  int _displayRank(SiteTask t) {
    if (_pinnedDoneIds.contains(t.id) && t.status == TaskStatus.done) {
      // Aktif bölümde kalır; 2 sn sonra alta iner.
      return 1;
    }
    return switch (t.status) {
      TaskStatus.todo => 0,
      TaskStatus.doing => 1,
      TaskStatus.done => 2,
    };
  }

  Future<void> _openTaskPhoto({
    required SiteTask task,
    required TaskPhoto photo,
    required bool canAnnotate,
  }) async {
    late final Uint8List bytes;
    try {
      bytes = base64Decode(photo.dataBase64);
    } catch (_) {
      return;
    }

    await openAnnotatedPhotoViewer(
      context,
      imageBytes: bytes,
      onSave: canAnnotate
          ? (annotated) async {
              final nextPhotos = [
                for (final p in task.photos)
                  if (p.id == photo.id)
                    TaskPhoto(
                      id: p.id,
                      dataBase64: base64Encode(annotated),
                      mimeType: 'image/png',
                      createdAt: p.createdAt,
                    )
                  else
                    p,
              ];
              ref.read(tasksProvider.notifier).upsert(
                    task.copyWith(photos: nextPhotos),
                  );
            }
          : null,
    );
  }

  List<SiteTask> _orderedTasks(List<SiteTask> tasks) {
    final list = [...tasks];
    list.sort((a, b) {
      final byRank = _displayRank(a).compareTo(_displayRank(b));
      if (byRank != 0) return byRank;
      return (b.updatedAt ?? b.createdAt ?? DateTime(1970))
          .compareTo(a.updatedAt ?? a.createdAt ?? DateTime(1970));
    });
    return list;
  }

  Future<Person?> _pickPersonSheet({
    required List<Person> people,
    required String title,
    String? subtitle,
    String? selectedId,
    bool showDegreeHint = false,
  }) {
    final sheetTheme = SJModal.sheetThemeOf(context);

    return showModalBottomSheet<Person>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: SJModal.sheetSurface,
      builder: (ctx) {
        return Theme(
          data: sheetTheme,
          child: _PersonPickSheet(
            people: people,
            title: title,
            subtitle: subtitle,
            selectedId: selectedId,
            showDegreeHint: showDegreeHint,
          ),
        );
      },
    );
  }

  Future<String?> _pickDateField({
    required BuildContext hostContext,
    required String label,
    required String current,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final first = firstDate ?? DateTime(2020);
    final last = lastDate ?? DateTime(2100);
    if (first.isAfter(last)) return null;
    var initial = PuantajDate.tryParse(current) ?? DateTime.now();
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    final picked = await showDatePicker(
      context: hostContext,
      helpText: label,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked == null) return null;
    return PuantajDate.format(picked);
  }

  Future<void> _openEditor({
    SiteTask? existing,
    required Person operator,
    required List<Person> people,
  }) async {
    final project = ref.read(activeProjectProvider);
    if (project == null) return;

    final canAssign = RoleDegree.canAssignTasks(operator);
    if (existing == null && !canAssign) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Görev atamak için 1. derece rol gerekir '
            '(ör. Saha Mühendisi, Şantiye Şefi).',
          ),
        ),
      );
      return;
    }

    final isAssigner = existing == null ||
        existing.assignerPersonId == operator.id ||
        (existing.assignerPersonId.isEmpty && canAssign);
    if (existing != null &&
        !isAssigner &&
        existing.assigneePersonId != operator.id) {
      return;
    }

    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    var earliestStart = existing?.earliestStart ?? '';
    var latestDelivery = existing?.dueDate ?? '';
    var status = existing?.status ?? TaskStatus.todo;
    var category = existing?.category.trim() ?? '';
    var photos = List<TaskPhoto>.from(existing?.photos ?? const []);
    const maxPhotos = 5;
    final picker = ImagePicker();
    Person? assignee;
    if (existing != null) {
      for (final p in people) {
        if (p.id == existing.assigneePersonId) {
          assignee = p;
          break;
        }
      }
    }

    final editorTheme = SJModal.sheetThemeOf(context);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: SJModal.sheetSurface,
      builder: (ctx) => Theme(
        data: editorTheme,
        child: Builder(builder: (ctx) {
        final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
        return StatefulBuilder(
          builder: (ctx, setModal) {
            final theme = editorTheme;
            final canEditFields = existing == null || isAssigner;

            Future<void> pickAssignee() async {
              if (!canEditFields) return;
              final picked = await _pickPersonSheet(
                people: people,
                title: 'Atanan personel',
                subtitle: 'Görevi yalnızca bu kişi ve siz görürsünüz.',
                selectedId: assignee?.id,
              );
              if (picked != null) setModal(() => assignee = picked);
            }

            Future<void> pickStart() async {
              if (!canEditFields) return;
              final due = PuantajDate.tryParse(latestDelivery);
              final value = await _pickDateField(
                hostContext: ctx,
                label: 'En erken başlangıç',
                current: earliestStart,
                lastDate: due,
              );
              if (value != null) setModal(() => earliestStart = value);
            }

            Future<void> pickDue() async {
              if (!canEditFields) return;
              final start = PuantajDate.tryParse(earliestStart);
              final value = await _pickDateField(
                hostContext: ctx,
                label: 'Planlanan bitiş',
                current: latestDelivery,
                firstDate: start,
              );
              if (value != null) setModal(() => latestDelivery = value);
            }

            Future<void> pickCategory() async {
              if (!canEditFields) return;
              final categories = [
                ...ref.read(taskCategoriesProvider),
              ];
              if (category.isNotEmpty &&
                  !categories.any(
                    (c) => c.toLowerCase() == category.toLowerCase(),
                  )) {
                categories.add(category);
                categories.sort((a, b) => a.compareTo(b));
              }
              final picked = await showModalBottomSheet<String>(
                context: ctx,
                showDragHandle: true,
                backgroundColor: SJModal.sheetSurface,
                builder: (sheetCtx) {
                  final sheetTheme = SJModal.sheetThemeOf(ctx);
                  return Theme(
                    data: sheetTheme,
                    child: SafeArea(
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
                              'Kategori seçin',
                              style: sheetTheme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Flexible(
                            child: ListView(
                              shrinkWrap: true,
                              children: [
                                ListTile(
                                  title: const Text('Kategori yok'),
                                  trailing: category.isEmpty
                                      ? Icon(
                                          Icons.check_circle,
                                          color: sheetTheme.colorScheme.primary,
                                        )
                                      : null,
                                  onTap: () => Navigator.pop(sheetCtx, ''),
                                ),
                                for (final c in categories)
                                  ListTile(
                                    title: Text(c),
                                    trailing: c == category
                                        ? Icon(
                                            Icons.check_circle,
                                            color:
                                                sheetTheme.colorScheme.primary,
                                          )
                                        : null,
                                    onTap: () => Navigator.pop(sheetCtx, c),
                                  ),
                                ListTile(
                                  leading: Icon(
                                    Icons.add,
                                    color: sheetTheme.colorScheme.primary,
                                  ),
                                  title: const Text('Yeni kategori ekle'),
                                  onTap: () async {
                                    final created =
                                        await _promptNewCategory(sheetCtx);
                                    if (created == null) return;
                                    if (sheetCtx.mounted) {
                                      Navigator.pop(sheetCtx, created);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
              if (picked != null) setModal(() => category = picked);
            }

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
                      existing == null ? 'Yeni görev ata' : 'Görevi düzenle',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Atayan: ${titleCaseTr(operator.name)}'
                      '${operator.profession.isNotEmpty ? ' · ${titleCaseTr(operator.profession)}' : ''}',
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: titleCtrl,
                      enabled: canEditFields,
                      decoration: const InputDecoration(
                        labelText: 'Görev başlığı *',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: descCtrl,
                      enabled: canEditFields,
                      decoration: const InputDecoration(
                        labelText: 'Açıklama',
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Fotoğraf', style: theme.textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.xs),
                    if (photos.isNotEmpty)
                      SizedBox(
                        height: 88,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: photos.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: AppSpacing.sm),
                          itemBuilder: (_, i) {
                            final photo = photos[i];
                            Widget image;
                            try {
                              image = Image.memory(
                                base64Decode(photo.dataBase64),
                                fit: BoxFit.cover,
                                width: 88,
                                height: 88,
                              );
                            } catch (_) {
                              image = ColoredBox(
                                color: theme.colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.broken_image_outlined),
                              );
                            }
                            return Stack(
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: AppRadii.sm,
                                    onTap: () async {
                                      late final Uint8List bytes;
                                      try {
                                        bytes = base64Decode(photo.dataBase64);
                                      } catch (_) {
                                        return;
                                      }
                                      await openAnnotatedPhotoViewer(
                                        ctx,
                                        imageBytes: bytes,
                                        onSave: canEditFields
                                            ? (annotated) async {
                                                final updated = TaskPhoto(
                                                  id: photo.id,
                                                  dataBase64:
                                                      base64Encode(annotated),
                                                  mimeType: 'image/png',
                                                  createdAt: photo.createdAt,
                                                );
                                                setModal(() {
                                                  photos = [
                                                    for (var j = 0;
                                                        j < photos.length;
                                                        j++)
                                                      if (j == i)
                                                        updated
                                                      else
                                                        photos[j],
                                                  ];
                                                });
                                              }
                                            : null,
                                      );
                                    },
                                    child: ClipRRect(
                                      borderRadius: AppRadii.sm,
                                      child: SizedBox(
                                        width: 88,
                                        height: 88,
                                        child: image,
                                      ),
                                    ),
                                  ),
                                ),
                                if (canEditFields)
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: Material(
                                      color: Colors.black54,
                                      shape: const CircleBorder(),
                                      child: InkWell(
                                        customBorder: const CircleBorder(),
                                        onTap: () => setModal(
                                          () => photos = [
                                            for (var j = 0;
                                                j < photos.length;
                                                j++)
                                              if (j != i) photos[j],
                                          ],
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.all(4),
                                          child: Icon(
                                            Icons.close,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    if (photos.isNotEmpty)
                      const SizedBox(height: AppSpacing.sm),
                    if (canEditFields)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: photos.length >= maxPhotos
                                  ? null
                                  : () async {
                                      try {
                                        final files =
                                            await picker.pickMultiImage(
                                          maxWidth: 1280,
                                          imageQuality: 72,
                                        );
                                        if (files.isEmpty) return;
                                        final added = <TaskPhoto>[];
                                        var skipped = 0;
                                        for (final file in files) {
                                          if (photos.length + added.length >=
                                              maxPhotos) {
                                            break;
                                          }
                                          try {
                                            final bytes =
                                                await file.readAsBytes();
                                            if (bytes.length >
                                                2 * 1024 * 1024) {
                                              skipped++;
                                              continue;
                                            }
                                            added.add(
                                              TaskPhoto(
                                                id: IdGen.make('tph'),
                                                dataBase64:
                                                    base64Encode(bytes),
                                                mimeType: file.mimeType ??
                                                    'image/jpeg',
                                                createdAt: DateTime.now(),
                                              ),
                                            );
                                          } catch (_) {}
                                        }
                                        if (added.isEmpty) {
                                          if (!ctx.mounted) return;
                                          ScaffoldMessenger.of(ctx)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                skipped > 0
                                                    ? 'Seçilen fotoğraflar çok büyük (en fazla ~2 MB)'
                                                    : 'Foto eklenemedi',
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        setModal(
                                          () => photos = [...photos, ...added],
                                        );
                                        if (skipped > 0 && ctx.mounted) {
                                          ScaffoldMessenger.of(ctx)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '$skipped foto boyuttan atlandı',
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (!ctx.mounted) return;
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          SnackBar(
                                            content:
                                                Text('Foto eklenemedi: $e'),
                                          ),
                                        );
                                      }
                                    },
                              icon: const Icon(
                                Icons.photo_library_outlined,
                                size: 18,
                              ),
                              label: const Text('Galeriden'),
                            ),
                          ),
                          if (!kIsWeb) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: photos.length >= maxPhotos
                                    ? null
                                    : () async {
                                        try {
                                          final file = await picker.pickImage(
                                            source: ImageSource.camera,
                                            maxWidth: 1280,
                                            imageQuality: 72,
                                          );
                                          if (file == null) return;
                                          final bytes =
                                              await file.readAsBytes();
                                          if (bytes.length >
                                              2 * 1024 * 1024) {
                                            if (!ctx.mounted) return;
                                            ScaffoldMessenger.of(ctx)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Fotoğraf çok büyük (en fazla ~2 MB)',
                                                ),
                                              ),
                                            );
                                            return;
                                          }
                                          setModal(
                                            () => photos = [
                                              ...photos,
                                              TaskPhoto(
                                                id: IdGen.make('tph'),
                                                dataBase64:
                                                    base64Encode(bytes),
                                                mimeType: file.mimeType ??
                                                    'image/jpeg',
                                                createdAt: DateTime.now(),
                                              ),
                                            ],
                                          );
                                        } catch (e) {
                                          if (!ctx.mounted) return;
                                          ScaffoldMessenger.of(ctx)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Foto çekilemedi: $e',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                icon: const Icon(
                                  Icons.photo_camera_outlined,
                                  size: 18,
                                ),
                                label: const Text('Çek'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    if (canEditFields && photos.length >= maxPhotos)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'En fazla $maxPhotos fotoğraf eklenebilir.',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                      ),
                      child: InkWell(
                        onTap: canEditFields ? pickCategory : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  category.isEmpty
                                      ? 'Kategori seçin veya oluşturun'
                                      : category,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: category.isEmpty
                                        ? theme.hintColor
                                        : null,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.expand_more,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Atanan personel *',
                      ),
                      child: InkWell(
                        onTap: canEditFields ? pickAssignee : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  assignee == null
                                      ? 'Personel seçin'
                                      : '${titleCaseTr(assignee!.name)}'
                                          '${assignee!.profession.isNotEmpty ? ' · ${titleCaseTr(assignee!.profession)}' : ''}',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: assignee == null
                                        ? theme.hintColor
                                        : null,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.expand_more,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: canEditFields ? pickStart : null,
                            icon: const Icon(Icons.play_arrow_rounded, size: 18),
                            label: Text(
                              earliestStart.isEmpty
                                  ? 'En erken başlangıç'
                                  : earliestStart,
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.success,
                              side: BorderSide(
                                color: AppColors.success.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: canEditFields ? pickDue : null,
                            icon: const Icon(Icons.flag_outlined, size: 18),
                            label: Text(
                              latestDelivery.isEmpty
                                  ? 'Planlanan bitiş'
                                  : latestDelivery,
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.critical,
                              side: BorderSide(
                                color:
                                    AppColors.critical.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Durum', style: theme.textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      children: [
                        for (final s in TaskStatus.values)
                          ChoiceChip(
                            label: Text(s.label),
                            selected: status == s,
                            onSelected: (_) => setModal(() => status = s),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: () {
                        if (titleCtrl.text.trim().isEmpty) return;
                        if (assignee == null) return;
                        if (earliestStart.isEmpty || latestDelivery.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'En erken başlangıç ve planlanan bitiş '
                                'tarihlerini seçin.',
                              ),
                            ),
                          );
                          return;
                        }
                        Navigator.pop(ctx, true);
                      },
                      child: const Text('Kaydet'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
        }),
      ),
    );

    final title = titleCtrl.text.trim();
    final description = descCtrl.text.trim();
    titleCtrl.dispose();
    descCtrl.dispose();
    if (saved != true ||
        title.isEmpty ||
        assignee == null ||
        earliestStart.isEmpty ||
        latestDelivery.isEmpty) {
      return;
    }

    if (existing == null) {
      if (category.isNotEmpty) {
        ref.read(taskCategoriesProvider.notifier).add(category);
      }
      ref.read(tasksProvider.notifier).add(
            projectId: project.id,
            title: title,
            description: description,
            category: category,
            earliestStart: earliestStart,
            dueDate: latestDelivery,
            status: status,
            assigner: operator,
            assignee: assignee!,
            photos: photos,
          );
    } else if (isAssigner) {
      if (category.isNotEmpty) {
        ref.read(taskCategoriesProvider.notifier).add(category);
      }
      ref.read(tasksProvider.notifier).upsert(
            existing.copyWith(
              title: title,
              description: description,
              category: category,
              earliestStart: earliestStart,
              dueDate: latestDelivery,
              status: status,
              photos: photos,
              assignee: assignee!.name,
              assigneePersonId: assignee!.id,
              assignerPersonId: existing.assignerPersonId.isEmpty
                  ? operator.id
                  : existing.assignerPersonId,
              assignerName: existing.assignerName.isEmpty
                  ? operator.name
                  : existing.assignerName,
            ),
          );
    } else {
      _setTaskStatus(existing.id, status);
    }
  }

  Future<String?> _promptNewCategory(BuildContext hostContext) async {
    final ctrl = TextEditingController();
    final sheetTheme = SJModal.sheetThemeOf(hostContext);
    final result = await showDialog<String>(
      context: hostContext,
      builder: (ctx) => Theme(
        data: sheetTheme,
        child: AlertDialog(
          backgroundColor: SJModal.sheetSurface,
          title: const Text('Yeni kategori'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Kategori adı',
              hintText: 'ör. Satın Alma, Saha, Ofis',
            ),
            onSubmitted: (v) {
              final t = v.trim();
              if (t.isNotEmpty) Navigator.pop(ctx, t);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () {
                final t = ctrl.text.trim();
                if (t.isEmpty) return;
                Navigator.pop(ctx, t);
              },
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
    final trimmed = result?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    ref.read(taskCategoriesProvider.notifier).add(trimmed);
    return trimmed;
  }

  Color _statusColor(TaskStatus status) => switch (status) {
        TaskStatus.todo => AppColors.info,
        TaskStatus.doing => AppColors.warning,
        TaskStatus.done => AppColors.success,
      };

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(activeProjectProvider);
    final operator = ref.watch(activeOperatorProvider);
    final people = ref.watch(activePersonnelProvider);
    final tasks = ref.watch(visibleProjectTasksProvider);
    final catalogCategories = ref.watch(taskCategoriesProvider);
    final usedCategories = {
      for (final t in tasks)
        if (t.category.trim().isNotEmpty) t.category.trim(),
    };
    final filterCategories = {
      ...catalogCategories,
      ...usedCategories,
    }.toList()
      ..sort((a, b) => a.compareTo(b));
    final statusFiltered = _filter == null
        ? tasks
        : tasks.where((t) {
            if (t.status == _filter) return true;
            // Tamamlanırken 2 sn görünür kalsın (aktif filtrelerde).
            if (_filter != TaskStatus.done &&
                _pinnedDoneIds.contains(t.id) &&
                t.status == TaskStatus.done) {
              return true;
            }
            return false;
          }).toList();
    final categoryFiltered = _categoryFilter == null
        ? statusFiltered
        : statusFiltered
            .where((t) => t.category.trim() == _categoryFilter)
            .toList();
    final filtered = _orderedTasks(categoryFiltered);
    final canAssign =
        operator != null && RoleDegree.canAssignTasks(operator);

    if (project == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SantijetHeader(subtitle: 'Görevler'),
              Expanded(
                child: SJEmptyState(
                  title: 'Önce proje ekleyin',
                  message: 'Görev tanımlamak için en az bir projeniz olmalı.',
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

    if (people.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SantijetHeader(subtitle: 'Görevler'),
              Expanded(
                child: SJEmptyState(
                  title: 'Personel yok',
                  message:
                      'Görev atamak ve görünürlük için aktif personel ekleyin.',
                  icon: Icons.groups_outlined,
                  actionLabel: 'Personele Git',
                  onAction: () => context.push(AppRoutes.personel),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      floatingActionButton: operator == null
          ? null
          : FloatingActionButton.extended(
              onPressed: canAssign
                  ? () => _openEditor(operator: operator, people: people)
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${operator.profession.isEmpty ? 'Bu rol' : operator.profession} '
                            'görev atayamaz. Size atanan görevleri görürsünüz.',
                          ),
                        ),
                      );
                    },
              icon: const Icon(Icons.add_task_outlined),
              label: const Text('Görev Ata'),
            ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SantijetHeader(subtitle: 'Görevler'),
            if (operator == null)
              Expanded(
                child: SJEmptyState(
                  title: 'Oturum gerekli',
                  message:
                      'Görev yetkisi giriş yapan hesaba göre belirlenir. '
                      'Devam etmek için Hesap üzerinden oturum açın.',
                  icon: Icons.account_circle_outlined,
                  actionLabel: 'Hesap',
                  onAction: () => context.push(AppRoutes.auth),
                ),
              )
            else ...[
              TaskCalendarPanel(tasks: tasks),
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text('Tümü (${tasks.length})'),
                        selected: _filter == null,
                        onSelected: (_) => setState(() => _filter = null),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      for (final s in TaskStatus.values) ...[
                        FilterChip(
                          label: Text(
                            '${s.label} (${tasks.where((t) => t.status == s).length})',
                          ),
                          selected: _filter == s,
                          onSelected: (_) => setState(() => _filter = s),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              avatar: Icon(
                                Icons.category_outlined,
                                size: 16,
                                color: _categoryFilter == null
                                    ? null
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                              ),
                              label: const Text('Tüm kategoriler'),
                              selected: _categoryFilter == null,
                              onSelected: (_) =>
                                  setState(() => _categoryFilter = null),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            for (final c in filterCategories) ...[
                              FilterChip(
                                label: Text(
                                  '$c (${tasks.where((t) => t.category.trim() == c).length})',
                                ),
                                selected: _categoryFilter == c,
                                onSelected: (_) =>
                                    setState(() => _categoryFilter = c),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                            ],
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Kategorileri yönet',
                      visualDensity: VisualDensity.compact,
                      onPressed: () async {
                        await context.push(AppRoutes.gorevKategorileri);
                        if (!mounted) return;
                        final cats = ref.read(taskCategoriesProvider);
                        if (_categoryFilter != null &&
                            !cats.contains(_categoryFilter)) {
                          setState(() => _categoryFilter = null);
                        }
                      },
                      icon: const Icon(Icons.tune_outlined, size: 20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: filtered.isEmpty
                    ? SJEmptyState(
                        title: tasks.isEmpty
                            ? 'Görünür görev yok'
                            : 'Bu filtrede görev yok',
                        message: canAssign
                            ? 'Personele görev atayın. Atadığınız görevleri '
                                'yalnızca siz ve atanan kişi görür. '
                                'Kategori ve durum filtrelerini birlikte kullanabilirsiniz.'
                            : 'Size atanmış görev bulunmuyor.',
                        icon: Icons.task_alt_outlined,
                        actionLabel: canAssign ? 'Görev Ata' : null,
                        onAction: canAssign
                            ? () => _openEditor(
                                  operator: operator,
                                  people: people,
                                )
                            : null,
                      )
                    : ListView.separated(
                        controller: _listScrollController,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.xs,
                          AppSpacing.md,
                          100,
                        ),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final task = filtered[index];
                          final iAmAssigner =
                              task.assignerPersonId == operator.id ||
                                  (task.assignerPersonId.isEmpty && canAssign);
                          return SJCard(
                            child: Builder(
                              builder: (context) {
                                final theme = Theme.of(context);
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      task.title,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        decoration:
                                            task.status == TaskStatus.done
                                                ? TextDecoration.lineThrough
                                                : null,
                                      ),
                                    ),
                                    if (task.category.trim().isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary
                                                .withValues(alpha: 0.12),
                                            borderRadius: AppRadii.sm,
                                            border: Border.all(
                                              color: theme.colorScheme.primary
                                                  .withValues(alpha: 0.35),
                                            ),
                                          ),
                                          child: Text(
                                            task.category.trim(),
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (task.description.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        task.description,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ],
                                    if (task.photos.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        height: 64,
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: task.photos.length,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(width: 6),
                                          itemBuilder: (_, i) {
                                            final photo = task.photos[i];
                                            try {
                                              final bytes = base64Decode(
                                                photo.dataBase64,
                                              );
                                              final canAnnotate = iAmAssigner ||
                                                  task.assigneePersonId ==
                                                      operator.id;
                                              return Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius: AppRadii.sm,
                                                  onTap: () => _openTaskPhoto(
                                                    task: task,
                                                    photo: photo,
                                                    canAnnotate: canAnnotate,
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius: AppRadii.sm,
                                                    child: Image.memory(
                                                      bytes,
                                                      width: 64,
                                                      height: 64,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            } catch (_) {
                                              return const SizedBox.shrink();
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Text(
                                      [
                                        if (task.assignee.isNotEmpty)
                                          'Atanan: ${task.assignee}',
                                        if (task.assignerName.isNotEmpty)
                                          'Atayan: ${task.assignerName}',
                                      ].join(' · '),
                                      style: theme.textTheme.labelSmall,
                                    ),
                                    if (task.earliestStart.isNotEmpty ||
                                        task.dueDate.isNotEmpty ||
                                        task.actualDeliveryDate
                                            .trim()
                                            .isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: AppSpacing.sm,
                                        runSpacing: 4,
                                        children: [
                                          if (task.earliestStart.isNotEmpty)
                                            _DateChip(
                                              label:
                                                  'Başlangıç ${task.earliestStart}',
                                              color: AppColors.success,
                                            ),
                                          if (task.dueDate.isNotEmpty)
                                            _DateChip(
                                              label:
                                                  'Planlanan bitiş ${task.dueDate}',
                                              color: AppColors.critical,
                                            ),
                                          if (task.actualDeliveryDate
                                              .trim()
                                              .isNotEmpty)
                                            _DateChip(
                                              label:
                                                  'Gerçekleşen bitiş ${task.actualDeliveryDate}',
                                              color: AppColors.success,
                                            ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: AppSpacing.sm),
                                    Row(
                                      children: [
                                        for (final s in TaskStatus.values) ...[
                                          Expanded(
                                            child: _StatusSelectButton(
                                              label: s.label,
                                              selected: task.status == s,
                                              color: _statusColor(s),
                                              onTap: () =>
                                                  _setTaskStatus(task.id, s),
                                            ),
                                          ),
                                          if (s != TaskStatus.done)
                                            const SizedBox(width: 6),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Row(
                                      children: [
                                        const Spacer(),
                                        IconButton(
                                          tooltip: 'Düzenle',
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () => _openEditor(
                                            existing: task,
                                            operator: operator,
                                            people: people,
                                          ),
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 20,
                                          ),
                                        ),
                                        if (iAmAssigner)
                                          IconButton(
                                            tooltip: 'Sil',
                                            visualDensity: VisualDensity.compact,
                                            onPressed: () async {
                                              final ok = await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  title:
                                                      const Text('Görevi sil'),
                                                  content: Text(
                                                    '“${task.title}” silinsin mi?',
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                        ctx,
                                                        false,
                                                      ),
                                                      child:
                                                          const Text('Vazgeç'),
                                                    ),
                                                    FilledButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                        ctx,
                                                        true,
                                                      ),
                                                      child: const Text('Sil'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (ok == true) {
                                                ref
                                                    .read(
                                                      tasksProvider.notifier,
                                                    )
                                                    .delete(task.id);
                                              }
                                            },
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              size: 20,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: AppRadii.sm,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Görev durumu seçici — seçili dolgulu, diğerleri yalnızca çerçeve.
class _StatusSelectButton extends StatelessWidget {
  const _StatusSelectButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = selected
        ? AppColors.readableOn(color)
        : theme.colorScheme.onSurfaceVariant;
    return Material(
      color: selected ? color : Colors.transparent,
      borderRadius: AppRadii.sm,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.sm,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            borderRadius: AppRadii.sm,
            border: Border.all(
              color: selected ? color : theme.dividerColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: ink,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Personel seçim sheet'i — arama + title case liste.
class _PersonPickSheet extends StatefulWidget {
  const _PersonPickSheet({
    required this.people,
    required this.title,
    this.subtitle,
    this.selectedId,
    this.showDegreeHint = false,
  });

  final List<Person> people;
  final String title;
  final String? subtitle;
  final String? selectedId;
  final bool showDegreeHint;

  @override
  State<_PersonPickSheet> createState() => _PersonPickSheetState();
}

class _PersonPickSheetState extends State<_PersonPickSheet> {
  final _queryCtrl = TextEditingController();

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  static String _fold(String s) => s
      .trim()
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');

  List<Person> get _filtered {
    final q = _fold(_queryCtrl.text);
    if (q.isEmpty) return widget.people;
    return widget.people.where((p) {
      final hay = _fold('${p.name} ${p.profession} ${p.team}');
      return hay.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filtered;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.62,
          child: Column(
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
                  widget.title,
                  style: theme.textTheme.headlineMedium,
                ),
              ),
              if (widget.subtitle != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(
                    widget.subtitle!,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: TextField(
                  controller: _queryCtrl,
                  textInputAction: TextInputAction.search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Personel ara…',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    suffixIcon: _queryCtrl.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Temizle',
                            onPressed: () {
                              _queryCtrl.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.clear, size: 20),
                          ),
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'Eşleşen personel yok',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final p = filtered[index];
                          final selected = p.id == widget.selectedId;
                          final degree = RoleDegree.forPerson(p);
                          return ListTile(
                            selected: selected,
                            title: Text(titleCaseTr(p.name)),
                            subtitle: Text(
                              [
                                if (p.profession.isNotEmpty)
                                  titleCaseTr(p.profession),
                                if (widget.showDegreeHint)
                                  degree == RoleDegree.first
                                      ? '1. derece · görev atayabilir'
                                      : 'Atanan görevleri görür',
                              ].join(' · '),
                            ),
                            trailing: selected
                                ? Icon(
                                    Icons.check_circle,
                                    color: theme.colorScheme.primary,
                                  )
                                : null,
                            onTap: () => Navigator.pop(context, p),
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
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
