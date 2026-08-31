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
import '../../core/theme/app_layout.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/puantaj_date.dart';
import '../../core/utils/text_format.dart';
import '../../core/utils/id_gen.dart';
import '../../core/utils/image_rotate.dart';
import '../../core/widgets/annotated_photo_viewer.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/active_operator_provider.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/catalog_provider.dart';
import '../../data/providers/tasks_provider.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/site_task.dart';
import '../../domain/enums/task_status.dart';
import '../../domain/catalogs/task_tags.dart';
import '../../domain/permissions/role_degree.dart';
import 'widgets/task_actual_date_sheet.dart';
import 'widgets/task_calendar_panel.dart';
import 'widgets/task_export_sheet.dart';

/// Saha görevleri — atayan (1. derece) + atanan görür.
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  TaskStatus? _filter;
  String? _categoryFilter;
  String? _tagFilter;
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

  Future<void> _changeTaskStatus(SiteTask task, TaskStatus status) async {
    final operator = ref.read(activeOperatorProvider);
    if (operator == null) return;
    if (task.status == status) return;
    if (!TaskStatusRules.canTransition(task.status, status)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bu geçiş yapılamaz. Sıra: Yapılacak → Başlandı → '
            'Devam ediyor → Tamamlandı.',
          ),
        ),
      );
      return;
    }

    String? actualStart;
    String? actualDelivery;
    if (TaskStatusRules.needsActualDate(status)) {
      final picked = await showTaskActualDateSheet(
        context,
        forStatus: status,
      );
      if (picked == null || !mounted) return;
      if (status == TaskStatus.started) {
        actualStart = picked;
      } else {
        actualDelivery = picked;
      }
    }

    final result = ref.read(tasksProvider.notifier).applyOrRequestStatus(
          id: task.id,
          status: status,
          actor: operator,
          actualStartDate: actualStart,
          actualDeliveryDate: actualDelivery,
        );

    if (!mounted) return;
    if (result == 'rejected') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Durum güncellenemedi.')),
      );
      return;
    }
    if (result == 'pending') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Durum değişikliği atayana onay için gönderildi'
            '${task.assignerName.isNotEmpty ? ' (${task.assignerName})' : ''}.',
          ),
        ),
      );
      return;
    }

    _pinTimers[task.id]?.cancel();
    _pinTimers.remove(task.id);
    if (status == TaskStatus.done) {
      setState(() => _pinnedDoneIds.add(task.id));
      _pinTimers[task.id] = Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() => _pinnedDoneIds.remove(task.id));
        _pinTimers.remove(task.id);
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
      setState(() => _pinnedDoneIds.remove(task.id));
    }
  }

  int _displayRank(SiteTask t) {
    if (_pinnedDoneIds.contains(t.id) && t.status == TaskStatus.done) {
      return 1;
    }
    return switch (t.status) {
      TaskStatus.todo => 0,
      TaskStatus.started => 1,
      TaskStatus.doing => 2,
      TaskStatus.done => 3,
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
      // Tamamlanan pin: kısa süre aynı blokta kalsın, sonra alfabetik.
      final ra = _displayRank(a);
      final rb = _displayRank(b);
      if (ra != rb &&
          (_pinnedDoneIds.contains(a.id) || _pinnedDoneIds.contains(b.id))) {
        return ra.compareTo(rb);
      }
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
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
    var category = existing?.category.trim() ?? '';
    var tag = TaskTagCatalog.normalize(
      existing?.tag ?? TaskTagCatalog.insaat,
    );
    if (existing == null && category.isEmpty) {
      category = 'Saha';
    }
    if (tag.isEmpty) tag = TaskTagCatalog.insaat;
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
                label: 'Planlanan başlangıç',
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
                                if (canEditFields)
                                  Positioned(
                                    bottom: 2,
                                    left: 2,
                                    child: Material(
                                      color: Colors.black54,
                                      shape: const CircleBorder(),
                                      child: InkWell(
                                        customBorder: const CircleBorder(),
                                        onTap: () async {
                                          late final Uint8List bytes;
                                          try {
                                            bytes =
                                                base64Decode(photo.dataBase64);
                                          } catch (_) {
                                            return;
                                          }
                                          final rotated =
                                              await rotateImageBytesCw90(bytes);
                                          if (rotated == null) return;
                                          final updated = TaskPhoto(
                                            id: photo.id,
                                            dataBase64: base64Encode(rotated),
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
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.all(4),
                                          child: Icon(
                                            Icons.rotate_90_degrees_cw,
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
                    Text('Etiket *', style: theme.textTheme.labelLarge),
                    const SizedBox(height: AppSpacing.xs),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (var i = 0; i < TaskTagCatalog.all.length; i++) ...[
                            if (i > 0) const SizedBox(width: AppSpacing.xs),
                            ChoiceChip(
                              label: Text(TaskTagCatalog.all[i]),
                              selected: tag == TaskTagCatalog.all[i],
                              onSelected: canEditFields
                                  ? (_) => setModal(
                                        () => tag = TaskTagCatalog.all[i],
                                      )
                                  : null,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Kategori *',
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              OutlinedButton.icon(
                                onPressed: canEditFields ? pickStart : null,
                                icon: const Icon(
                                  Icons.play_arrow_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  earliestStart.isEmpty
                                      ? 'Planlanan başlangıç'
                                      : earliestStart,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.success,
                                  side: BorderSide(
                                    color: AppColors.success
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Row(
                                children: [
                                  Expanded(
                                    child: _TaskDateQuickChip(
                                      label: 'Bugün',
                                      color: AppColors.success,
                                      selected: earliestStart ==
                                          PuantajDate.today(),
                                      onTap: canEditFields
                                          ? () => setModal(() {
                                                final d = PuantajDate.today();
                                                earliestStart = d;
                                                final due = PuantajDate
                                                    .tryParse(latestDelivery);
                                                final start =
                                                    PuantajDate.tryParse(d);
                                                if (due != null &&
                                                    start != null &&
                                                    start.isAfter(due)) {
                                                  latestDelivery = d;
                                                }
                                              })
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: _TaskDateQuickChip(
                                      label: 'Yarın',
                                      color: AppColors.success,
                                      selected: earliestStart ==
                                          PuantajDate.shift(
                                            PuantajDate.today(),
                                            1,
                                          ),
                                      onTap: canEditFields
                                          ? () => setModal(() {
                                                final d = PuantajDate.shift(
                                                  PuantajDate.today(),
                                                  1,
                                                );
                                                earliestStart = d;
                                                final due = PuantajDate
                                                    .tryParse(latestDelivery);
                                                final start =
                                                    PuantajDate.tryParse(d);
                                                if (due != null &&
                                                    start != null &&
                                                    start.isAfter(due)) {
                                                  latestDelivery = d;
                                                }
                                              })
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              OutlinedButton.icon(
                                onPressed: canEditFields ? pickDue : null,
                                icon: const Icon(
                                  Icons.flag_outlined,
                                  size: 18,
                                ),
                                label: Text(
                                  latestDelivery.isEmpty
                                      ? 'Planlanan bitiş'
                                      : latestDelivery,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.critical,
                                  side: BorderSide(
                                    color: AppColors.critical
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Row(
                                children: [
                                  Expanded(
                                    child: _TaskDateQuickChip(
                                      label: 'Bugün',
                                      color: AppColors.critical,
                                      selected: latestDelivery ==
                                          PuantajDate.today(),
                                      onTap: canEditFields
                                          ? () => setModal(() {
                                                final d = PuantajDate.today();
                                                latestDelivery = d;
                                                final start = PuantajDate
                                                    .tryParse(earliestStart);
                                                final due =
                                                    PuantajDate.tryParse(d);
                                                if (start != null &&
                                                    due != null &&
                                                    due.isBefore(start)) {
                                                  earliestStart = d;
                                                }
                                              })
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: _TaskDateQuickChip(
                                      label: 'Yarın',
                                      color: AppColors.critical,
                                      selected: latestDelivery ==
                                          PuantajDate.shift(
                                            PuantajDate.today(),
                                            1,
                                          ),
                                      onTap: canEditFields
                                          ? () => setModal(() {
                                                final d = PuantajDate.shift(
                                                  PuantajDate.today(),
                                                  1,
                                                );
                                                latestDelivery = d;
                                                final start = PuantajDate
                                                    .tryParse(earliestStart);
                                                final due =
                                                    PuantajDate.tryParse(d);
                                                if (start != null &&
                                                    due != null &&
                                                    due.isBefore(start)) {
                                                  earliestStart = d;
                                                }
                                              })
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      onPressed: () {
                        if (titleCtrl.text.trim().isEmpty) return;
                        if (assignee == null) return;
                        if (tag.isEmpty || !TaskTagCatalog.isKnown(tag)) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Etiket seçin (İnşaat / Elektrik / Mekanik).',
                              ),
                            ),
                          );
                          return;
                        }
                        if (category.trim().isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Kategori seçin veya oluşturun.'),
                            ),
                          );
                          return;
                        }
                        if (earliestStart.isEmpty || latestDelivery.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Planlanan başlangıç ve bitiş '
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
        category.trim().isEmpty ||
        tag.isEmpty ||
        !TaskTagCatalog.isKnown(tag) ||
        earliestStart.isEmpty ||
        latestDelivery.isEmpty) {
      return;
    }

    if (existing == null) {
      ref.read(taskCategoriesProvider.notifier).add(category);
      ref.read(tasksProvider.notifier).add(
            projectId: project.id,
            title: title,
            description: description,
            category: category,
            tag: tag,
            earliestStart: earliestStart,
            dueDate: latestDelivery,
            assigner: operator,
            assignee: assignee!,
            photos: photos,
          );
    } else if (isAssigner) {
      ref.read(taskCategoriesProvider.notifier).add(category);
      ref.read(tasksProvider.notifier).upsert(
            existing.copyWith(
              title: title,
              description: description,
              category: category,
              tag: tag,
              earliestStart: earliestStart,
              dueDate: latestDelivery,
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
      ref.read(tasksProvider.notifier).upsert(
            existing.copyWith(photos: photos),
          );
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
        TaskStatus.started => AppColors.partial,
        TaskStatus.doing => AppColors.warning,
        TaskStatus.done => AppColors.success,
      };

  Future<void> _openExportSheet({
    required Project project,
    required List<SiteTask> tasks,
  }) {
    return SJModal.showSheet(
      context: context,
      title: 'Görev AL',
      child: TaskExportSheet(
        projectName: project.name,
        tasks: tasks,
        initialTag: _tagFilter,
      ),
    );
  }

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
    final tagFiltered = _tagFilter == null
        ? categoryFiltered
        : categoryFiltered
            .where((t) => TaskTagCatalog.normalize(t.tag) == _tagFilter)
            .toList();
    final filtered = _orderedTasks(tagFiltered);
    final canAssign =
        operator != null && RoleDegree.canAssignTasks(operator);

    if (project == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SantijetHeader(subtitle: 'Görev'),
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
              const SantijetHeader(subtitle: 'Görev'),
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
              heroTag: 'task_assign',
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
              label: const Text('Görev Ekle'),
            ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SantijetHeader(
              subtitle: 'Görev',
              actionsBeforeSettings: [
                SantijetHeaderDownloadButton(
                  tooltip: 'Görev AL',
                  onPressed: () => _openExportSheet(
                    project: project,
                    tasks: tasks,
                  ),
                ),
              ],
            ),
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
                child: Row(
                  children: [
                    Expanded(
                      child: _TaskFilterDropdown<TaskStatus?>(
                        caption: 'Durum',
                        valueLabel: _filter == null
                            ? 'Tümü (${tasks.length})'
                            : '${_filter!.shortLabel} (${tasks.where((t) => t.status == _filter).length})',
                        items: [
                          (
                            value: null,
                            label: 'Tümü (${tasks.length})',
                          ),
                          for (final s in TaskStatus.values)
                            (
                              value: s,
                              label:
                                  '${s.label} (${tasks.where((t) => t.status == s).length})',
                            ),
                        ],
                        selected: _filter,
                        onSelected: (v) => setState(() => _filter = v),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: _TaskFilterDropdown<String?>(
                        caption: 'Etiket',
                        valueLabel: _tagFilter == null
                            ? 'Tümü'
                            : '${TaskTagCatalog.cardLabel(_tagFilter!)} '
                                '(${tasks.where((t) => TaskTagCatalog.normalize(t.tag) == _tagFilter).length})',
                        accent: _tagFilter == null
                            ? null
                            : TaskTagCatalog.accentFor(_tagFilter!),
                        items: [
                          (value: null, label: 'Tüm etiketler'),
                          for (final t in TaskTagCatalog.all)
                            (
                              value: t,
                              label:
                                  '${TaskTagCatalog.cardLabel(t)} (${tasks.where((task) => TaskTagCatalog.normalize(task.tag) == t).length})',
                            ),
                        ],
                        selected: _tagFilter,
                        onSelected: (v) => setState(() => _tagFilter = v),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: _TaskFilterDropdown<String?>(
                        caption: 'Kategori',
                        valueLabel: _categoryFilter == null
                            ? 'Tümü'
                            : '$_categoryFilter (${tasks.where((t) => t.category.trim() == _categoryFilter).length})',
                        items: [
                          (value: null, label: 'Tüm kategoriler'),
                          for (final c in filterCategories)
                            (
                              value: c,
                              label:
                                  '$c (${tasks.where((t) => t.category.trim() == c).length})',
                            ),
                        ],
                        selected: _categoryFilter,
                        onSelected: (v) =>
                            setState(() => _categoryFilter = v),
                      ),
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
                                'Kategori, etiket ve durum filtrelerini birlikte kullanabilirsiniz.'
                            : 'Size atanmış görev bulunmuyor.',
                        icon: Icons.task_alt_outlined,
                        actionLabel: canAssign ? 'Görev Ekle' : null,
                        onAction: canAssign
                            ? () => _openEditor(
                                  operator: operator,
                                  people: people,
                                )
                            : null,
                      )
                    : ListView.separated(
                        controller: _listScrollController,
                        padding: AppLayout.scrollPadding(
                          top: AppSpacing.xs,
                          clearFab: true,
                          extraBottom: 72,
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
                                    if (task.category.trim().isNotEmpty ||
                                        TaskTagCatalog.normalize(task.tag)
                                            .isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          if (TaskTagCatalog.normalize(task.tag)
                                              .isNotEmpty)
                                            _TaskTagBadge(
                                              tag: TaskTagCatalog.normalize(
                                                task.tag,
                                              ),
                                            ),
                                          if (task.category.trim().isNotEmpty)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.primary
                                                    .withValues(alpha: 0.12),
                                                borderRadius: AppRadii.sm,
                                                border: Border.all(
                                                  color: theme
                                                      .colorScheme.primary
                                                      .withValues(alpha: 0.35),
                                                ),
                                              ),
                                              child: Text(
                                                task.category.trim(),
                                                style: theme
                                                    .textTheme.labelSmall
                                                    ?.copyWith(
                                                  color: theme
                                                      .colorScheme.primary,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                        ],
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
                                        task.actualStartDate.trim().isNotEmpty ||
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
                                                  'Planlanan başlangıç ${task.earliestStart}',
                                              color: AppColors.electricBlue,
                                            ),
                                          if (task.dueDate.isNotEmpty)
                                            _DateChip(
                                              label:
                                                  'Planlanan bitiş ${task.dueDate}',
                                              color: AppColors.critical,
                                            ),
                                          if (task.actualStartDate
                                              .trim()
                                              .isNotEmpty)
                                            _DateChip(
                                              label:
                                                  'Gerçekleşen başlangıç ${task.actualStartDate}',
                                              color: AppColors.partial,
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
                                    if (task.hasPendingStatusChange) ...[
                                      const SizedBox(height: AppSpacing.sm),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(
                                          AppSpacing.sm,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.warning
                                              .withValues(alpha: 0.12),
                                          borderRadius: AppRadii.sm,
                                          border: Border.all(
                                            color: AppColors.warning
                                                .withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Text(
                                              iAmAssigner
                                                  ? 'Onay bekleyen durum: ${task.pendingStatus!.label}'
                                                  : 'Durum değişikliği onay bekliyor: ${task.pendingStatus!.label}',
                                              style: theme.textTheme.labelMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            if (iAmAssigner) ...[
                                              const SizedBox(height: 6),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: OutlinedButton(
                                                      onPressed: () {
                                                        ref
                                                            .read(
                                                              tasksProvider
                                                                  .notifier,
                                                            )
                                                            .rejectPending(
                                                              id: task.id,
                                                              actor: operator,
                                                            );
                                                      },
                                                      child: const Text('Reddet'),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: FilledButton(
                                                      onPressed: () {
                                                        final pending =
                                                            task.pendingStatus;
                                                        final ok = ref
                                                            .read(
                                                              tasksProvider
                                                                  .notifier,
                                                            )
                                                            .approvePending(
                                                              id: task.id,
                                                              actor: operator,
                                                            );
                                                        if (ok &&
                                                            pending ==
                                                                TaskStatus
                                                                    .done) {
                                                          setState(
                                                            () =>
                                                                _pinnedDoneIds
                                                                    .add(
                                                              task.id,
                                                            ),
                                                          );
                                                          _pinTimers[task.id]
                                                              ?.cancel();
                                                          _pinTimers[task.id] =
                                                              Timer(
                                                            const Duration(
                                                              seconds: 2,
                                                            ),
                                                            () {
                                                              if (!mounted) {
                                                                return;
                                                              }
                                                              setState(
                                                                () =>
                                                                    _pinnedDoneIds
                                                                        .remove(
                                                                  task.id,
                                                                ),
                                                              );
                                                              _pinTimers
                                                                  .remove(
                                                                task.id,
                                                              );
                                                            },
                                                          );
                                                        }
                                                      },
                                                      child: const Text('Onayla'),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: AppSpacing.sm),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        for (final s in TaskStatus.values)
                                          SizedBox(
                                            width: (MediaQuery.sizeOf(context)
                                                        .width -
                                                    AppSpacing.md * 4 -
                                                    6) /
                                                2,
                                            child: _StatusSelectButton(
                                              label: s.shortLabel,
                                              selected: task.status == s,
                                              color: _statusColor(s),
                                              enabled: task.status == s ||
                                                  TaskStatusRules.canTransition(
                                                    task.status,
                                                    s,
                                                  ),
                                              onTap: () =>
                                                  _changeTaskStatus(task, s),
                                            ),
                                          ),
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

/// Tek satırda yan yana açılır filtre (Durum / Etiket / Kategori).
class _TaskFilterDropdown<T> extends StatelessWidget {
  const _TaskFilterDropdown({
    required this.caption,
    required this.valueLabel,
    required this.items,
    required this.selected,
    required this.onSelected,
    this.accent,
  });

  final String caption;
  final String valueLabel;
  final List<({T value, String label})> items;
  final T selected;
  final ValueChanged<T> onSelected;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasSelection = selected != null;
    final borderColor = accent ??
        (hasSelection
            ? theme.colorScheme.primary
            : theme.colorScheme.outlineVariant);

    return PopupMenuButton<T>(
      padding: EdgeInsets.zero,
      offset: const Offset(0, 40),
      onSelected: onSelected,
      itemBuilder: (ctx) => [
        for (final item in items)
          PopupMenuItem<T>(
            value: item.value,
            child: Row(
              children: [
                Expanded(child: Text(item.label)),
                if (item.value == selected)
                  Icon(
                    Icons.check,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
        decoration: BoxDecoration(
          color: hasSelection && accent != null
              ? accent!.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: AppRadii.sm,
          border: Border.all(
            color: borderColor.withValues(alpha: hasSelection ? 0.85 : 0.55),
            width: hasSelection ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    valueLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: accent ?? theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  Icons.expand_more,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
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
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = !enabled
        ? theme.disabledColor
        : selected
            ? AppColors.readableOn(color)
            : theme.colorScheme.onSurfaceVariant;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: selected ? color : Colors.transparent,
        borderRadius: AppRadii.sm,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: AppRadii.sm,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: AppRadii.sm,
              border: Border.all(
                color: selected
                    ? color
                    : (enabled ? color.withValues(alpha: 0.45) : theme.dividerColor),
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
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
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

class _TaskDateQuickChip extends StatelessWidget {
  const _TaskDateQuickChip({
    required this.label,
    required this.color,
    required this.selected,
    this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.sm,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.18)
                : color.withValues(alpha: enabled ? 0.08 : 0.04),
            borderRadius: AppRadii.sm,
            border: Border.all(
              color: color.withValues(
                alpha: selected ? 0.7 : (enabled ? 0.4 : 0.2),
              ),
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: enabled
                  ? color
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskTagBadge extends StatelessWidget {
  const _TaskTagBadge({required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    final accent = TaskTagCatalog.accentFor(tag);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: AppRadii.sm,
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Text(
        TaskTagCatalog.cardLabel(tag),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.statusInkOnCard(accent),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
      ),
    );
  }
}
