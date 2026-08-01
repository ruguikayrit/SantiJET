import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/design_system/sj_button.dart';
import '../../core/design_system/sj_modal.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_date.dart';
import '../../core/utils/id_gen.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/services/waybill_ocr.dart';
import '../../domain/beton_progress.dart';
import '../../domain/entities/concrete_order.dart';
import '../../domain/entities/concrete_pour.dart';
import '../../domain/entities/mixer_entry.dart';
import '../../domain/entities/project.dart';

/// Sipariş özeti — koyu lacivert zemin.
const _navySummary = Color(0xFF0A1A33);
const _navySummaryText = Color(0xFFFFFFFF);
const _navySummaryMuted = Color(0xB3FFFFFF);

/// Form satır aralığı (sıkışıklığı açar).
const _fieldGap = AppSpacing.md;

Future<bool?> openDokumEditor(
  BuildContext context,
  WidgetRef ref, {
  ConcretePour? existing,
}) {
  return SJModal.showSheet<bool>(
    context: context,
    title: existing == null ? 'Yeni Döküm' : 'Dökümü Düzenle',
    child: _DokumEditorBody(existing: existing),
  );
}

class _MixerDraft {
  _MixerDraft({
    required this.id,
    Uint8List? imageBytes,
    this.ocrBusy = false,
    this.ocrMessage = '',
    String ticketNo = '',
    String plate = '',
    String volume = '',
    String slump = '',
    String note = '',
    this.ocrRawText = '',
  })  : imageBytes = imageBytes,
        ticketCtrl = TextEditingController(text: ticketNo),
        plateCtrl = TextEditingController(text: plate),
        volumeCtrl = TextEditingController(text: volume),
        slumpCtrl = TextEditingController(text: slump),
        noteCtrl = TextEditingController(text: note);

  factory _MixerDraft.fromEntry(MixerEntry e) {
    Uint8List? bytes;
    if (e.waybillImageBase64.isNotEmpty) {
      try {
        bytes = base64Decode(e.waybillImageBase64);
      } catch (_) {}
    }
    return _MixerDraft(
      id: e.id,
      imageBytes: bytes,
      ticketNo: e.ticketNo,
      plate: e.plate,
      volume: e.volumeM3 > 0 ? BetonProgress.fmtM3(e.volumeM3) : '',
      slump: e.slumpCm == null ? '' : BetonProgress.fmtM3(e.slumpCm!),
      note: e.note,
      ocrRawText: e.ocrRawText,
    );
  }

  final String id;
  Uint8List? imageBytes;
  bool ocrBusy;
  String ocrMessage;
  String ocrRawText;
  final TextEditingController ticketCtrl;
  final TextEditingController plateCtrl;
  final TextEditingController volumeCtrl;
  final TextEditingController slumpCtrl;
  final TextEditingController noteCtrl;

  void dispose() {
    ticketCtrl.dispose();
    plateCtrl.dispose();
    volumeCtrl.dispose();
    slumpCtrl.dispose();
    noteCtrl.dispose();
  }

  MixerEntry toEntry() {
    return MixerEntry(
      id: id,
      ticketNo: ticketCtrl.text.trim(),
      plate: plateCtrl.text.trim(),
      volumeM3:
          double.tryParse(volumeCtrl.text.trim().replaceAll(',', '.')) ?? 0,
      slumpCm: double.tryParse(slumpCtrl.text.trim().replaceAll(',', '.')),
      note: noteCtrl.text.trim(),
      waybillImageBase64:
          imageBytes == null ? '' : base64Encode(imageBytes!),
      ocrRawText: ocrRawText,
    );
  }
}

class _DokumEditorBody extends ConsumerStatefulWidget {
  const _DokumEditorBody({this.existing});

  final ConcretePour? existing;

  @override
  ConsumerState<_DokumEditorBody> createState() => _DokumEditorBodyState();
}

class _DokumEditorBodyState extends ConsumerState<_DokumEditorBody> {
  late ConcreteOrder? _selectedOrder;
  late List<ConcreteOrder> _orders;
  late Project _project;
  late bool _isExtra;
  late final TextEditingController _extraElementCtrl;
  late final TextEditingController _extraBlockCtrl;
  late final TextEditingController _extraFloorCtrl;
  late final TextEditingController _pumpCountCtrl;
  late final TextEditingController _pumpTypeCtrl;
  late final TextEditingController _pumpNoteCtrl;
  late final List<_MixerDraft> _mixers;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final project = ref.read(activeProjectProvider);
    if (project == null) {
      throw StateError('Aktif proje yok');
    }
    _project = project;

    _orders = List<ConcreteOrder>.from(ref.read(activeOrdersProvider))
      ..sort((a, b) {
        final today = AppDate.format(AppDate.today());
        final aToday = a.plannedDate == today ? 0 : 1;
        final bToday = b.plannedDate == today ? 0 : 1;
        if (aToday != bToday) return aToday.compareTo(bToday);
        return a.plannedDate.compareTo(b.plannedDate);
      });

    final existing = widget.existing;
    ConcreteOrder? selected;
    if (existing?.orderId != null) {
      for (final o in _orders) {
        if (o.id == existing!.orderId) {
          selected = o;
          break;
        }
      }
    }
    selected ??= _orders.isNotEmpty ? _orders.first : null;
    if (selected == null && existing != null) {
      selected = ConcreteOrder(
        id: existing.orderId ?? existing.id,
        projectId: _project.id,
        plannedDate: existing.date,
        plannedM3: existing.volumeM3,
        elementName: existing.elementName,
        block: existing.block,
        floor: existing.floor,
        concreteClass: existing.concreteClass,
        supplier: existing.supplier,
      );
    }
    if (_orders.isNotEmpty &&
        (selected == null || !_orders.any((o) => o.id == selected!.id))) {
      selected = _orders.first;
    }
    _selectedOrder = selected;

    _isExtra = existing?.isExtraPour ?? false;
    _extraElementCtrl = TextEditingController(
      text: _isExtra ? (existing?.elementName ?? '') : '',
    );
    _extraBlockCtrl =
        TextEditingController(text: _isExtra ? (existing?.block ?? '') : '');
    _extraFloorCtrl =
        TextEditingController(text: _isExtra ? (existing?.floor ?? '') : '');
    _pumpCountCtrl = TextEditingController(
      text: existing?.pumpCount?.toString() ?? '',
    );
    _pumpTypeCtrl = TextEditingController(text: existing?.pumpType ?? '');
    _pumpNoteCtrl = TextEditingController(text: existing?.pumpNote ?? '');

    if (existing != null && existing.mixers.isNotEmpty) {
      _mixers = existing.mixers.map(_MixerDraft.fromEntry).toList();
    } else if (existing != null &&
        (existing.ticketNo.isNotEmpty ||
            existing.mixerPlate.isNotEmpty ||
            existing.volumeM3 > 0)) {
      _mixers = [
        _MixerDraft(
          id: IdGen.make('mx'),
          ticketNo: existing.ticketNo,
          plate: existing.mixerPlate,
          volume: BetonProgress.fmtM3(existing.volumeM3),
          slump: existing.slumpCm == null
              ? ''
              : BetonProgress.fmtM3(existing.slumpCm!),
          note: existing.mixerNote,
        ),
      ];
    } else {
      _mixers = [_MixerDraft(id: IdGen.make('mx'))];
    }
  }

  @override
  void dispose() {
    _extraElementCtrl.dispose();
    _extraBlockCtrl.dispose();
    _extraFloorCtrl.dispose();
    _pumpCountCtrl.dispose();
    _pumpTypeCtrl.dispose();
    _pumpNoteCtrl.dispose();
    for (final m in _mixers) {
      m.dispose();
    }
    super.dispose();
  }

  Future<void> _pickWaybill(_MixerDraft draft, ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 72,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        draft.imageBytes = bytes;
        draft.ocrBusy = true;
        draft.ocrMessage = 'İrsaliye okunuyor…';
      });

      final result = await WaybillOcr.fromImageBytes(bytes);
      if (!mounted) return;
      setState(() {
        draft.ocrBusy = false;
        draft.ocrRawText = result.rawText;
        if (result.error != null && !result.hasAnyField) {
          draft.ocrMessage = result.error!;
          return;
        }
        if (result.ticketNo.isNotEmpty) {
          draft.ticketCtrl.text = result.ticketNo;
        }
        if (result.plate.isNotEmpty) {
          draft.plateCtrl.text = result.plate;
        }
        if (result.volumeM3 != null) {
          draft.volumeCtrl.text = BetonProgress.fmtM3(result.volumeM3!);
        }
        if (result.slumpCm != null) {
          draft.slumpCtrl.text = BetonProgress.fmtM3(result.slumpCm!);
        }
        draft.ocrMessage = result.hasAnyField
            ? 'Otomatik okundu — gerekirse düzeltin'
            : (result.error ?? 'Alanları manuel girebilirsiniz');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        draft.ocrBusy = false;
        draft.ocrMessage =
            'Fotoğraf alınamadı. Alanları manuel girebilirsiniz.';
      });
    }
  }

  void _addMixer() {
    setState(() => _mixers.add(_MixerDraft(id: IdGen.make('mx'))));
  }

  void _removeMixer(int index) {
    if (_mixers.length <= 1) return;
    setState(() {
      _mixers[index].dispose();
      _mixers.removeAt(index);
    });
  }

  void _save() {
    final order = _selectedOrder;
    if (order == null) return;

    final entries = _mixers.map((m) => m.toEntry()).toList();
    final totalVol = entries.fold<double>(0, (s, e) => s + e.volumeM3);
    if (totalVol <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir mikserde hacim (m³) girin')),
      );
      return;
    }

    final element =
        _isExtra ? _extraElementCtrl.text.trim() : order.elementName;
    final block = _isExtra ? _extraBlockCtrl.text.trim() : order.block;
    final floor = _isExtra ? _extraFloorCtrl.text.trim() : order.floor;
    if (_isExtra && element.isEmpty) return;

    final first = entries.first;
    final draft = ConcretePour(
      id: widget.existing?.id ?? '',
      projectId: _project.id,
      date: order.plannedDate,
      volumeM3: totalVol,
      elementName: element,
      block: block,
      floor: floor,
      concreteClass: order.concreteClass,
      supplier: order.supplier,
      ticketNo: first.ticketNo,
      mixerCount: entries.length,
      mixerPlate: first.plate,
      mixerNote: first.note,
      mixers: entries,
      pumpCount: int.tryParse(_pumpCountCtrl.text.trim()),
      pumpType: _pumpTypeCtrl.text.trim(),
      pumpNote: _pumpNoteCtrl.text.trim(),
      slumpCm: first.slumpCm,
      pourStart: widget.existing?.pourStart ?? DateTime.now(),
      orderId: order.id,
      isExtraPour: _isExtra,
    );

    if (widget.existing == null) {
      ref.read(poursProvider.notifier).add(draft);
    } else {
      ref.read(poursProvider.notifier).update(draft);
    }
    Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final ok = await SJModal.confirm(
      context: context,
      title: 'Dökümü sil',
      message: 'Bu döküm kaydı silinsin mi?',
      confirmLabel: 'Sil',
      destructive: true,
    );
    if (!ok || !mounted) return;
    ref.read(poursProvider.notifier).delete(existing.id);
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = _selectedOrder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_orders.isNotEmpty) ...[
          DropdownButtonFormField<String>(
            value: order?.id,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Aktif sipariş'),
            items: [
              for (final o in _orders)
                DropdownMenuItem(
                  value: o.id,
                  child: Text(
                    _orderLabel(o),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (id) {
              if (id == null) return;
              setState(() {
                _selectedOrder = _orders.firstWhere((o) => o.id == id);
              });
            },
          ),
          const SizedBox(height: _fieldGap),
          if (order != null) _OrderSummaryBox(order: order),
        ] else if (order != null) ...[
          _OrderSummaryBox(order: order),
        ] else
          Text(
            'Sipariş bulunamadı',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.critical,
            ),
          ),
        const SizedBox(height: _fieldGap),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Ek döküm'),
          subtitle: const Text(
            'Beton sipariş dışı bir yere döküldüyse açın',
          ),
          value: _isExtra,
          onChanged: (v) => setState(() => _isExtra = v),
        ),
        if (_isExtra) ...[
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _extraElementCtrl,
            decoration: const InputDecoration(
              labelText: 'Dökülen yapısal eleman',
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: _fieldGap),
          TextField(
            controller: _extraBlockCtrl,
            decoration: const InputDecoration(
              labelText: 'Blok',
              hintText: 'örn. A Blok',
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: _fieldGap),
          TextField(
            controller: _extraFloorCtrl,
            decoration: const InputDecoration(
              labelText: 'Kat',
              hintText: 'örn. Bodrum Kat',
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Text(
                'Mikser verileri',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '${_mixers.length} mikser',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Her gelen mikser için ayrı kayıt ekleyin. İrsaliye fotoğrafından '
          'veriler otomatik okunur; isteğe göre manuel düzeltebilirsiniz.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: _fieldGap),
        for (var i = 0; i < _mixers.length; i++) ...[
          if (i > 0) const SizedBox(height: _fieldGap),
          _MixerCard(
            index: i,
            draft: _mixers[i],
            canRemove: _mixers.length > 1,
            onRemove: () => _removeMixer(i),
            onCamera: () => _pickWaybill(_mixers[i], ImageSource.camera),
            onGallery: () => _pickWaybill(_mixers[i], ImageSource.gallery),
            onClearImage: () => setState(() {
              _mixers[i].imageBytes = null;
              _mixers[i].ocrMessage = '';
            }),
          ),
        ],
        const SizedBox(height: _fieldGap),
        SJButton(
          label: 'Mikser Ekle',
          icon: Icons.add,
          variant: SJButtonVariant.secondary,
          expanded: true,
          onPressed: _addMixer,
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Pompa verileri',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: _fieldGap),
        TextField(
          controller: _pumpCountCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Pompa adedi'),
        ),
        const SizedBox(height: _fieldGap),
        TextField(
          controller: _pumpTypeCtrl,
          decoration: const InputDecoration(
            labelText: 'Pompa tipi',
            hintText: 'örn. Sabit / Mobil',
          ),
        ),
        const SizedBox(height: _fieldGap),
        TextField(
          controller: _pumpNoteCtrl,
          decoration: const InputDecoration(labelText: 'Pompa notu'),
          maxLines: 2,
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: SJButton(
                label: 'İptal',
                variant: SJButtonVariant.secondary,
                expanded: true,
                onPressed: () => Navigator.pop(context, false),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SJButton(
                label: 'Kaydet',
                expanded: true,
                onPressed: _save,
              ),
            ),
          ],
        ),
        if (widget.existing != null) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: _delete,
            child: Text(
              'Sil',
              style: TextStyle(color: AppColors.critical),
            ),
          ),
        ],
      ],
    );
  }

  static String _orderLabel(ConcreteOrder o) {
    final name = o.elementName.isEmpty ? 'Sipariş' : o.elementName;
    final loc = o.locationSummary;
    return [
      o.plannedDate,
      name,
      if (loc.isNotEmpty) loc,
      '${BetonProgress.fmtM3(o.plannedM3)} m³',
    ].join(' · ');
  }
}

class _OrderSummaryBox extends StatelessWidget {
  const _OrderSummaryBox({required this.order});

  final ConcreteOrder order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <String>[
      if (order.elementName.isNotEmpty)
        'Yapısal eleman: ${order.elementName}',
      if (order.block.isNotEmpty) 'Blok: ${order.block}',
      if (order.floor.isNotEmpty) 'Kat: ${order.floor}',
      'Sınıf: ${order.concreteClass}',
      if (order.supplier.isNotEmpty) 'Firma: ${order.supplier}',
      'Plan: ${BetonProgress.fmtM3(order.plannedM3)} m³',
      if (order.plannedStartHour.isNotEmpty) 'Saat: ${order.plannedStartHour}',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _navySummary,
        borderRadius: AppRadii.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sipariş özeti (otomatik)',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: _navySummaryMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final line in rows)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                line,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _navySummaryText,
                  height: 1.35,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MixerCard extends StatelessWidget {
  const _MixerCard({
    required this.index,
    required this.draft,
    required this.canRemove,
    required this.onRemove,
    required this.onCamera,
    required this.onGallery,
    required this.onClearImage,
  });

  final int index;
  final _MixerDraft draft;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onClearImage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Mikser ${index + 1}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (canRemove)
                IconButton(
                  onPressed: onRemove,
                  tooltip: 'Mikseri kaldır',
                  icon: Icon(Icons.close, color: AppColors.critical),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'İrsaliye fotoğrafı',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (draft.imageBytes != null) ...[
            ClipRRect(
              borderRadius: AppRadii.sm,
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.memory(
                  draft.imageBytes!,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onClearImage,
                child: const Text('Fotoğrafı kaldır'),
              ),
            ),
          ] else
            Container(
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: AppRadii.sm,
                border: Border.all(
                  color: AppColors.borderSubtle,
                  style: BorderStyle.solid,
                ),
              ),
              child: Text(
                'Kamera veya galeriden irsaliye yükleyin',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: SJButton(
                  label: 'Kamera',
                  icon: Icons.photo_camera_outlined,
                  variant: SJButtonVariant.secondary,
                  expanded: true,
                  loading: draft.ocrBusy,
                  onPressed: onCamera,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SJButton(
                  label: 'Galeri',
                  icon: Icons.photo_library_outlined,
                  variant: SJButtonVariant.secondary,
                  expanded: true,
                  loading: draft.ocrBusy,
                  onPressed: onGallery,
                ),
              ),
            ],
          ),
          if (draft.ocrBusy || draft.ocrMessage.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            if (draft.ocrBusy)
              const LinearProgressIndicator(minHeight: 3)
            else
              Text(
                draft.ocrMessage,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
          ],
          const SizedBox(height: _fieldGap),
          TextField(
            controller: draft.ticketCtrl,
            decoration: const InputDecoration(labelText: 'İrsaliye no'),
          ),
          const SizedBox(height: _fieldGap),
          TextField(
            controller: draft.plateCtrl,
            decoration: const InputDecoration(labelText: 'Plaka'),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: _fieldGap),
          TextField(
            controller: draft.volumeCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Hacim (m³)'),
          ),
          const SizedBox(height: _fieldGap),
          TextField(
            controller: draft.slumpCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Çökme / Slump'),
          ),
          const SizedBox(height: _fieldGap),
          TextField(
            controller: draft.noteCtrl,
            decoration: const InputDecoration(
              labelText: 'Özel not (isteğe bağlı)',
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
