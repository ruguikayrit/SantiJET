import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/design_system/sj_button.dart';
import '../../core/design_system/sj_card.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/id_gen.dart';
import '../../core/utils/puantaj_date.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/company_provider.dart';
import '../../data/providers/daily_report_provider.dart';
import '../../data/services/daily_report_export_style.dart';
import '../../data/services/daily_report_pdf_service.dart';
import '../../data/services/irsaliye_material_ocr.dart';
import '../../domain/catalogs/turkey_cities.dart';
import '../../domain/entities/company_info.dart';
import '../../domain/entities/daily_report.dart';
import '../../domain/entities/project.dart';
import '../../domain/enums/photo_work_category.dart';
import '../projects/widgets/project_switcher.dart';
import 'widgets/attendance_summary_table.dart';

/// Kart içi metin stili — renk [SJCard] DefaultTextStyle / kart Theme'den gelir.
///
/// Chrome [ThemeData] stillerini karta taşımak hibrit temalarda
/// (ŞantiJET / Pro) mürekkep çakışması yaratır.
TextStyle _cardInk(
  TextStyle? base, {
  FontWeight? fontWeight,
  FontStyle? fontStyle,
  Color? color,
}) {
  return TextStyle(
    fontSize: base?.fontSize,
    fontWeight: fontWeight ?? base?.fontWeight,
    fontStyle: fontStyle ?? base?.fontStyle,
    height: base?.height,
    letterSpacing: base?.letterSpacing,
    color: color,
    decoration: TextDecoration.none,
  );
}

/// Diyalog form satırları arasında tutarlı boşluk.
const _kDialogFieldGap = SizedBox(height: AppSpacing.sm);

InputDecoration _dialogFieldDecoration({
  required String labelText,
  String? hintText,
  String? helperText,
}) {
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    helperText: helperText,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  );
}

/// Günlük saha raporu — foto, işler, malzeme, makine, hava, puantaj snapshot.
class DailyReportScreen extends ConsumerStatefulWidget {
  const DailyReportScreen({super.key});

  @override
  ConsumerState<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends ConsumerState<DailyReportScreen> {
  final _workConstructionCtrl = TextEditingController();
  final _workElectricalCtrl = TextEditingController();
  final _workMechanicalCtrl = TextEditingController();
  final _nextDayPlanCtrl = TextEditingController();
  final _picker = ImagePicker();
  bool _weatherLoading = false;
  bool _irsaliyeBusy = false;
  bool _bootstrapped = false;
  String? _boundKey;
  Timer? _autosaveTimer;
  bool _hydrating = false;

  @override
  void initState() {
    super.initState();
    _workConstructionCtrl.addListener(_scheduleAutosave);
    _workElectricalCtrl.addListener(_scheduleAutosave);
    _workMechanicalCtrl.addListener(_scheduleAutosave);
    _nextDayPlanCtrl.addListener(_scheduleAutosave);
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _workConstructionCtrl.removeListener(_scheduleAutosave);
    _workElectricalCtrl.removeListener(_scheduleAutosave);
    _workMechanicalCtrl.removeListener(_scheduleAutosave);
    _nextDayPlanCtrl.removeListener(_scheduleAutosave);
    _workConstructionCtrl.dispose();
    _workElectricalCtrl.dispose();
    _workMechanicalCtrl.dispose();
    _nextDayPlanCtrl.dispose();
    super.dispose();
  }

  void _scheduleAutosave() {
    if (_hydrating) return;
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: 450), _autosaveText);
  }

  void _autosaveText() {
    final report = ref.read(activeDailyReportProvider);
    if (report == null) return;
    final next = report.copyWith(
      workConstruction: _workConstructionCtrl.text.trim(),
      workElectrical: _workElectricalCtrl.text.trim(),
      workMechanical: _workMechanicalCtrl.text.trim(),
      nextDayPlan: _nextDayPlanCtrl.text.trim(),
    );
    ref.read(dailyReportsProvider.notifier).upsert(next);
  }

  Future<void> _ensureAndHydrate() async {
    final project = ref.read(activeProjectProvider);
    if (project == null) return;
    final date = ref.read(dailyReportSelectedDateProvider);
    final key = '${project.id}|$date';
    if (_boundKey == key && _bootstrapped) return;

    final report = ref
        .read(dailyReportsProvider.notifier)
        .ensureDraft(projectId: project.id, date: date);

    _hydrating = true;
    _workConstructionCtrl.text = report.workConstruction;
    _workElectricalCtrl.text = report.workElectrical;
    _workMechanicalCtrl.text = report.workMechanical;
    _nextDayPlanCtrl.text = report.nextDayPlan;
    _hydrating = false;
    _boundKey = key;
    _bootstrapped = true;

    // Snapshot her açılışta canlıdan yazılır.
    syncAttendanceIntoReport(ref, report);

    // Şehir seçiliyse ve hava yok/senkron değilse güncelle.
    final city = ref.read(selectedWeatherCityProvider);
    final needsWeather =
        city != null &&
        (report.weather == null || report.weather?.synced != true);
    if (needsWeather && !_weatherLoading) {
      setState(() => _weatherLoading = true);
      try {
        await refreshReportWeather(ref, report: report, city: city);
      } finally {
        if (mounted) setState(() => _weatherLoading = false);
      }
    }
  }

  Future<void> _pickWeatherCity() async {
    final selectedId = ref.read(weatherCityIdProvider);
    final picked = await showModalBottomSheet<TurkeyCity>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _CityPickerSheet(selectedId: selectedId),
    );
    if (picked == null || !mounted) return;
    final report = ref.read(activeDailyReportProvider);
    if (report == null) return;
    setState(() => _weatherLoading = true);
    try {
      await refreshReportWeather(ref, report: report, city: picked);
    } finally {
      if (mounted) setState(() => _weatherLoading = false);
    }
  }

  Future<void> _refreshWeather() async {
    final city = ref.read(selectedWeatherCityProvider);
    if (city == null) {
      await _pickWeatherCity();
      return;
    }
    final report = ref.read(activeDailyReportProvider);
    if (report == null) return;
    setState(() => _weatherLoading = true);
    try {
      await refreshReportWeather(ref, report: report, city: city);
    } finally {
      if (mounted) setState(() => _weatherLoading = false);
    }
  }

  Future<void> _pickDate() async {
    final current = PuantajDate.parse(ref.read(dailyReportSelectedDateProvider));
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    ref.read(dailyReportSelectedDateProvider.notifier).state =
        PuantajDate.format(picked);
    _bootstrapped = false;
    _boundKey = null;
    await _ensureAndHydrate();
    setState(() {});
  }

  DailyReport? _persistDraftForExport() {
    final report = ref.read(activeDailyReportProvider);
    if (report == null) return null;
    var next = report.copyWith(
      workConstruction: _workConstructionCtrl.text.trim(),
      workElectrical: _workElectricalCtrl.text.trim(),
      workMechanical: _workMechanicalCtrl.text.trim(),
      nextDayPlan: _nextDayPlanCtrl.text.trim(),
    );
    next = syncAttendanceIntoReport(ref, next);
    ref.read(dailyReportsProvider.notifier).upsert(next);
    return next;
  }

  Future<void> _openExportSheet() async {
    final project = ref.read(activeProjectProvider);
    final report = _persistDraftForExport();
    if (project == null || report == null) return;
    final snap = ref.read(liveAttendanceSnapshotProvider);
    final company = ref.read(companyInfoProvider);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surfaceElevated,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: _DailyReportExportSheet(
          project: project,
          report: report,
          company: company,
          liveSnapshot: snap,
        ),
      ),
    );
  }

  Future<void> _addPhoto(ImageSource source) async {
    final report = ref.read(activeDailyReportProvider);
    if (report == null) return;
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 72,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 2 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fotoğraf çok büyük (en fazla ~2 MB)'),
            ),
          );
        }
        return;
      }
      final mime = file.mimeType ?? 'image/jpeg';
      final photo = DailyReportPhoto(
        id: IdGen.make('ph'),
        dataBase64: base64Encode(bytes),
        mimeType: mime,
        caption: '',
        createdAt: DateTime.now(),
      );
      ref.read(dailyReportsProvider.notifier).upsert(
            report.copyWith(photos: [...report.photos, photo]),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto eklendi — açıklama eklemeniz önerilir'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Foto eklenemedi: $e')),
        );
      }
    }
  }

  void _showPhotoSource() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeriden seç'),
              onTap: () {
                Navigator.pop(ctx);
                _addPhoto(ImageSource.gallery);
              },
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _addPhoto(ImageSource.camera);
                },
              ),
            if (kIsWeb)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  'Web’de fotoğraflar galeriden seçilir ve Hive’da '
                  'base64 olarak saklanır.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _editCaption(DailyReportPhoto photo) async {
    final report = ref.read(activeDailyReportProvider);
    if (report == null) return;
    final ctrl = TextEditingController(text: photo.caption);
    var category = photo.workCategory;
    final result = await showDialog<({String caption, PhotoWorkCategory cat})>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AlertDialog(
          title: const Text('Fotoğraf açıklaması'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<PhotoWorkCategory>(
                value: category,
                decoration: _dialogFieldDecoration(labelText: 'İmalat türü'),
                items: [
                  for (final c in PhotoWorkCategory.values)
                    DropdownMenuItem(value: c, child: Text(c.label)),
                ],
                onChanged: (v) {
                  if (v != null) setModal(() => category = v);
                },
              ),
              _kDialogFieldGap,
              TextField(
                controller: ctrl,
                maxLines: 3,
                decoration: _dialogFieldDecoration(
                  labelText: 'Açıklama',
                  hintText: 'Örn. Temel kazısı — batı cephe',
                  helperText:
                      'Seçilen türe göre yapılan işler altına senkronize olur',
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                ctx,
                (caption: ctrl.text.trim(), cat: category),
              ),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
    if (result == null) return;
    ref.read(dailyReportsProvider.notifier).upsert(
          report.copyWith(
            photos: [
              for (final p in report.photos)
                if (p.id == photo.id)
                  p.copyWith(
                    caption: result.caption,
                    workCategory: result.cat,
                  )
                else
                  p,
            ],
          ),
        );
  }

  Future<void> _upsertMaterial({
    required _MaterialList kind,
    DailyReportMaterial? existing,
  }) async {
    final report = ref.read(activeDailyReportProvider);
    if (report == null) return;
    final stockLike =
        kind == _MaterialList.incoming || kind == _MaterialList.outgoing;
    final name = TextEditingController(text: existing?.name ?? '');
    final qty = TextEditingController(text: existing?.quantity ?? '');
    final unit = TextEditingController(text: existing?.unit ?? '');
    final supplier =
        TextEditingController(text: existing?.supplierOrOrder ?? '');
    final supplyDate =
        TextEditingController(text: existing?.supplyDate ?? '');
    final price = TextEditingController(text: existing?.price ?? '');
    final note = TextEditingController(text: existing?.note ?? '');
    var purchaseApproved = existing?.purchaseApproved ?? false;

    String titleNew() => switch (kind) {
          _MaterialList.incoming => 'Gelen malzeme',
          _MaterialList.outgoing => 'Giden malzeme',
          _MaterialList.ordered => 'Sipariş malzeme',
        };
    String partyLabel() => switch (kind) {
          _MaterialList.incoming => 'Tedarik edilen firma',
          _MaterialList.outgoing => 'Alıcı / gönderilen yer',
          _MaterialList.ordered => 'Kime / sipariş no',
        };
    final nameLabel =
        kind == _MaterialList.ordered ? 'Malzeme açıklaması *' : 'Ürün adı *';

    final values = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AlertDialog(
          title: Text(existing == null ? titleNew() : 'Malzeme düzenle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (stockLike) ...[
                  TextField(
                    controller: supplyDate,
                    decoration: _dialogFieldDecoration(
                      labelText: kind == _MaterialList.outgoing
                          ? 'Gönderim tarihi'
                          : 'Tedarik tarihi',
                      hintText: 'dd.MM.yyyy',
                    ),
                  ),
                  _kDialogFieldGap,
                ],
                TextField(
                  controller: name,
                  decoration: _dialogFieldDecoration(labelText: nameLabel),
                ),
                _kDialogFieldGap,
                TextField(
                  controller: qty,
                  decoration:
                      _dialogFieldDecoration(labelText: 'Ürün miktarı'),
                  keyboardType: TextInputType.number,
                ),
                _kDialogFieldGap,
                TextField(
                  controller: unit,
                  decoration:
                      _dialogFieldDecoration(labelText: 'Ürün birimi'),
                ),
                _kDialogFieldGap,
                TextField(
                  controller: supplier,
                  decoration:
                      _dialogFieldDecoration(labelText: partyLabel()),
                ),
                if (stockLike) ...[
                  _kDialogFieldGap,
                  TextField(
                    controller: price,
                    decoration: _dialogFieldDecoration(
                      labelText: 'Ürün fiyatı (opsiyonel)',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
                if (kind == _MaterialList.ordered) ...[
                  _kDialogFieldGap,
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Satın alma onayı'),
                    value: purchaseApproved,
                    onChanged: (v) =>
                        setModal(() => purchaseApproved = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
                _kDialogFieldGap,
                TextField(
                  controller: note,
                  decoration: _dialogFieldDecoration(labelText: 'Not'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isEmpty) return;
                Navigator.pop(ctx, {
                  'name': name.text.trim(),
                  'qty': qty.text.trim(),
                  'unit': unit.text.trim(),
                  'supplier': supplier.text.trim(),
                  'supplyDate': supplyDate.text.trim(),
                  'price': price.text.trim(),
                  'note': note.text.trim(),
                  'approved': purchaseApproved ? '1' : '0',
                });
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    qty.dispose();
    unit.dispose();
    supplier.dispose();
    supplyDate.dispose();
    price.dispose();
    note.dispose();
    if (values == null) return;

    final item = DailyReportMaterial(
      id: existing?.id ?? IdGen.make('mat'),
      name: values['name']!,
      quantity: values['qty'] ?? '',
      unit: values['unit'] ?? '',
      supplierOrOrder: values['supplier'] ?? '',
      supplyDate: values['supplyDate'] ?? '',
      price: values['price'] ?? '',
      note: values['note'] ?? '',
      purchaseApproved: values['approved'] == '1',
      irsaliyePhotoId: existing?.irsaliyePhotoId ?? '',
      recordedAt: existing?.recordedAt ?? DateTime.now(),
    );

    List<DailyReportMaterial> list;
    DailyReport next;
    switch (kind) {
      case _MaterialList.incoming:
        list = [...report.incomingMaterials];
        final i = list.indexWhere((e) => e.id == item.id);
        if (i >= 0) {
          list[i] = item;
        } else {
          list.add(item);
        }
        next = report.copyWith(incomingMaterials: list);
      case _MaterialList.outgoing:
        list = [...report.outgoingMaterials];
        final i = list.indexWhere((e) => e.id == item.id);
        if (i >= 0) {
          list[i] = item;
        } else {
          list.add(item);
        }
        next = report.copyWith(outgoingMaterials: list);
      case _MaterialList.ordered:
        list = [...report.orderedMaterials];
        final i = list.indexWhere((e) => e.id == item.id);
        if (i >= 0) {
          list[i] = item;
        } else {
          list.add(item);
        }
        next = report.copyWith(orderedMaterials: list);
    }
    ref.read(dailyReportsProvider.notifier).upsert(next);
  }

  Future<void> _pickIrsaliye(ImageSource source) async {
    final report = ref.read(activeDailyReportProvider);
    if (report == null || _irsaliyeBusy) return;
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 78,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 2 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('İrsaliye görseli çok büyük (en fazla ~2 MB)'),
            ),
          );
        }
        return;
      }

      setState(() => _irsaliyeBusy = true);
      final mime = file.mimeType ?? 'image/jpeg';
      final photo = DailyReportPhoto(
        id: IdGen.make('irs'),
        dataBase64: base64Encode(bytes),
        mimeType: mime,
        caption: 'İrsaliye',
        createdAt: DateTime.now(),
      );

      final ocr = await IrsaliyeMaterialOcr.fromImageBytes(bytes, mime: mime);
      if (!mounted) return;

      final confirmed = await _confirmIrsaliyeLines(
        ocr: ocr,
        photoId: photo.id,
      );
      if (!mounted) return;
      if (confirmed == null) return; // diyalog kapatıldı — iptal

      ref.read(dailyReportsProvider.notifier).upsert(
            report.copyWith(
              irsaliyePhotos: [...report.irsaliyePhotos, photo],
              incomingMaterials: [
                ...report.incomingMaterials,
                ...confirmed,
              ],
            ),
          );

      if (!mounted) return;
      final msg = confirmed.isEmpty
          ? (ocr.error ??
              'İrsaliye kaydedildi. Malzeme satırını manuel ekleyin.')
          : '${confirmed.length} malzeme satırı irsaliyeden eklendi.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İrsaliye eklenemedi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _irsaliyeBusy = false);
    }
  }

  List<DailyReportMaterial> _materialsFromOcr(
    IrsaliyeMaterialOcrResult ocr, {
    required String photoId,
  }) {
    final lines = ocr.lines.where((l) => l.hasName).toList();
    if (lines.isEmpty &&
        (ocr.supplier.isNotEmpty || ocr.supplyDate.isNotEmpty)) {
      return [
        DailyReportMaterial(
          id: IdGen.make('mat'),
          name: '',
          supplierOrOrder: ocr.supplier,
          supplyDate: ocr.supplyDate,
          irsaliyePhotoId: photoId,
          recordedAt: DateTime.now(),
        ),
      ];
    }
    return [
      for (final line in lines)
        DailyReportMaterial(
          id: IdGen.make('mat'),
          name: line.name,
          quantity: line.quantity,
          unit: line.unit,
          price: line.price,
          supplierOrOrder: ocr.supplier,
          supplyDate: ocr.supplyDate,
          irsaliyePhotoId: photoId,
          recordedAt: DateTime.now(),
        ),
    ];
  }

  Future<List<DailyReportMaterial>?> _confirmIrsaliyeLines({
    required IrsaliyeMaterialOcrResult ocr,
    required String photoId,
  }) async {
    final drafts = List<DailyReportMaterial>.from(
      _materialsFromOcr(ocr, photoId: photoId),
    );
    if (drafts.isEmpty) {
      drafts.add(
        DailyReportMaterial(
          id: IdGen.make('mat'),
          name: '',
          supplierOrOrder: ocr.supplier,
          supplyDate: ocr.supplyDate,
          irsaliyePhotoId: photoId,
          recordedAt: DateTime.now(),
        ),
      );
    }

    final supplierCtrl = TextEditingController(text: ocr.supplier);
    final dateCtrl = TextEditingController(text: ocr.supplyDate);
    final rowCtrls = [
      for (final d in drafts)
        (
          name: TextEditingController(text: d.name),
          qty: TextEditingController(text: d.quantity),
          unit: TextEditingController(text: d.unit),
          price: TextEditingController(text: d.price),
        ),
    ];

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('İrsaliye — malzeme onayı'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (ocr.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      ocr.error!,
                      style: TextStyle(color: AppColors.warning, fontSize: 12),
                    ),
                  ),
                TextField(
                  controller: dateCtrl,
                  decoration: _dialogFieldDecoration(
                    labelText: 'Tedarik tarihi',
                    hintText: 'dd.MM.yyyy',
                  ),
                ),
                _kDialogFieldGap,
                TextField(
                  controller: supplierCtrl,
                  decoration: _dialogFieldDecoration(
                    labelText: 'Tedarik edilen firma',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                for (var i = 0; i < rowCtrls.length; i++) ...[
                  Text(
                    'Ürün ${i + 1}',
                    style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  _kDialogFieldGap,
                  TextField(
                    controller: rowCtrls[i].name,
                    decoration:
                        _dialogFieldDecoration(labelText: 'Ürün adı *'),
                  ),
                  _kDialogFieldGap,
                  TextField(
                    controller: rowCtrls[i].qty,
                    decoration:
                        _dialogFieldDecoration(labelText: 'Ürün miktarı'),
                  ),
                  _kDialogFieldGap,
                  TextField(
                    controller: rowCtrls[i].unit,
                    decoration:
                        _dialogFieldDecoration(labelText: 'Ürün birimi'),
                  ),
                  _kDialogFieldGap,
                  TextField(
                    controller: rowCtrls[i].price,
                    decoration: _dialogFieldDecoration(
                      labelText: 'Ürün fiyatı (opsiyonel)',
                    ),
                  ),
                  if (i < rowCtrls.length - 1)
                    const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Atla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Listeye ekle'),
          ),
        ],
      ),
    );

    final supplier = supplierCtrl.text.trim();
    final date = dateCtrl.text.trim();
    supplierCtrl.dispose();
    dateCtrl.dispose();

    void disposeRows() {
      for (final r in rowCtrls) {
        r.name.dispose();
        r.qty.dispose();
        r.unit.dispose();
        r.price.dispose();
      }
    }

    if (ok == null) {
      disposeRows();
      return null; // diyalog kapatıldı → tamamen iptal
    }
    if (ok == false) {
      disposeRows();
      return const []; // Atla → yalnızca irsaliye foto
    }

    final result = <DailyReportMaterial>[];
    for (final r in rowCtrls) {
      final n = r.name.text.trim();
      if (n.isNotEmpty) {
        result.add(
          DailyReportMaterial(
            id: IdGen.make('mat'),
            name: n,
            quantity: r.qty.text.trim(),
            unit: r.unit.text.trim(),
            price: r.price.text.trim(),
            supplierOrOrder: supplier,
            supplyDate: date,
            irsaliyePhotoId: photoId,
            recordedAt: DateTime.now(),
          ),
        );
      }
      r.name.dispose();
      r.qty.dispose();
      r.unit.dispose();
      r.price.dispose();
    }
    return result;
  }

  void _showIrsaliyeSource() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeriden irsaliye'),
              onTap: () {
                Navigator.pop(ctx);
                _pickIrsaliye(ImageSource.gallery);
              },
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Kamera ile irsaliye'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickIrsaliye(ImageSource.camera);
                },
              ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'İrsaliye görseli okunur; tedarik tarihi, firma, ürün adı, '
                'miktar, birim ve fiyat (varsa) listeye eklenmeden önce onaylanır.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _upsertMachine({
    DailyReportMachine? existing,
    bool vehicle = false,
  }) async {
    final report = ref.read(activeDailyReportProvider);
    if (report == null) return;
    final name = TextEditingController(text: existing?.name ?? '');
    final type = TextEditingController(text: existing?.type ?? '');
    final plate = TextEditingController(text: existing?.plateOrId ?? '');
    final hours = TextEditingController(
      text: existing == null || existing.hoursWorked == 0
          ? ''
          : existing.hoursWorked.toString(),
    );
    final work = TextEditingController(text: existing?.workDescription ?? '');
    final op = TextEditingController(text: existing?.operatorName ?? '');
    final company = TextEditingController(text: existing?.company ?? '');

    final values = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          existing == null
              ? (vehicle ? 'Vasıta' : 'İş makinesi')
              : (vehicle ? 'Vasıta düzenle' : 'Makine düzenle'),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: name,
                decoration: _dialogFieldDecoration(
                  labelText: vehicle ? 'Vasıta adı *' : 'Makine adı *',
                ),
              ),
              _kDialogFieldGap,
              TextField(
                controller: type,
                decoration: _dialogFieldDecoration(
                  labelText: vehicle ? 'Marka/Model' : 'Tip (opsiyonel)',
                ),
              ),
              if (!vehicle) ...[
                _kDialogFieldGap,
                TextField(
                  controller: company,
                  decoration: _dialogFieldDecoration(labelText: 'Firma'),
                ),
              ],
              _kDialogFieldGap,
              TextField(
                controller: plate,
                decoration:
                    _dialogFieldDecoration(labelText: 'Plaka / kimlik'),
              ),
              _kDialogFieldGap,
              TextField(
                controller: hours,
                decoration:
                    _dialogFieldDecoration(labelText: 'Çalışma saati'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              _kDialogFieldGap,
              TextField(
                controller: work,
                decoration: _dialogFieldDecoration(
                  labelText: 'Yapılan iş açıklaması',
                ),
                maxLines: 2,
              ),
              _kDialogFieldGap,
              TextField(
                controller: op,
                decoration: _dialogFieldDecoration(
                  labelText: vehicle ? 'Şoför' : 'Operatör',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              if (name.text.trim().isEmpty) return;
              Navigator.pop(ctx, {
                'name': name.text.trim(),
                'type': type.text.trim(),
                'plate': plate.text.trim(),
                'company': company.text.trim(),
                'hours': hours.text.trim(),
                'work': work.text.trim(),
                'op': op.text.trim(),
              });
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    name.dispose();
    type.dispose();
    plate.dispose();
    hours.dispose();
    work.dispose();
    op.dispose();
    company.dispose();
    if (values == null) return;

    final item = DailyReportMachine(
      id: existing?.id ?? IdGen.make(vehicle ? 'veh' : 'mch'),
      name: values['name']!,
      type: values['type'] ?? '',
      plateOrId: values['plate'] ?? '',
      company: vehicle ? '' : (values['company'] ?? ''),
      hoursWorked: double.tryParse(
            (values['hours'] ?? '').replaceAll(',', '.'),
          ) ??
          0,
      workDescription: values['work'] ?? '',
      operatorName: values['op'] ?? '',
    );
    if (vehicle) {
      final list = [...report.vehicles];
      final i = list.indexWhere((e) => e.id == item.id);
      if (i >= 0) {
        list[i] = item;
      } else {
        list.add(item);
      }
      ref
          .read(dailyReportsProvider.notifier)
          .upsert(report.copyWith(vehicles: list));
    } else {
      final list = [...report.machines];
      final i = list.indexWhere((e) => e.id == item.id);
      if (i >= 0) {
        list[i] = item;
      } else {
        list.add(item);
      }
      ref
          .read(dailyReportsProvider.notifier)
          .upsert(report.copyWith(machines: list));
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(activeProjectProvider);
    final date = ref.watch(dailyReportSelectedDateProvider);
    final report = ref.watch(activeDailyReportProvider);
    final snap = ref.watch(liveAttendanceSnapshotProvider);

    if (project != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ensureAndHydrate();
      });
    }

    if (project == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SantijetHeader(subtitle: 'Günlük Rapor'),
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: ProjectSwitcher(),
              ),
              Expanded(
                child: SJEmptyState(
                  title: 'Önce proje ekleyin',
                  message: 'Günlük rapor proje kapsamında tutulur.',
                  icon: Icons.apartment_outlined,
                  actionLabel: 'Projelere Git',
                  onAction: () => context.push(AppRoutes.projeler),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final weather = report?.weather;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SantijetHeader(subtitle: 'Günlük Rapor'),
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: ProjectSwitcher(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      ref.read(dailyReportSelectedDateProvider.notifier).state =
                          PuantajDate.shift(date, -1);
                      _bootstrapped = false;
                      _boundKey = null;
                    },
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: AppRadii.md,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          date,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ref.read(dailyReportSelectedDateProvider.notifier).state =
                          PuantajDate.shift(date, 1);
                      _bootstrapped = false;
                      _boundKey = null;
                    },
                    icon: const Icon(Icons.chevron_right),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(dailyReportSelectedDateProvider.notifier).state =
                          PuantajDate.today();
                      _bootstrapped = false;
                      _boundKey = null;
                    },
                    child: const Text('Bugün'),
                  ),
                  IconButton(
                    tooltip: 'PDF dışa aktar',
                    onPressed: _openExportSheet,
                    icon: const Icon(Icons.ios_share_outlined),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  100,
                ),
                children: [
                  _SectionCard(
                    title: 'Hava durumu',
                    icon: Icons.wb_sunny_outlined,
                    trailing: IconButton(
                      tooltip: 'Yenile',
                      onPressed: _weatherLoading ? null : _refreshWeather,
                      icon: _weatherLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh, size: 20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _weatherLoading ? null : _pickWeatherCity,
                          icon: const Icon(Icons.location_city_outlined),
                          label: Text(
                            ref.watch(selectedWeatherCityProvider)?.name ??
                                'Şehir seçin',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (_weatherLoading)
                          Text(
                            'Hava çekiliyor…',
                            style: _cardInk(theme.textTheme.bodyMedium),
                          )
                        else if (weather == null)
                          Text(
                            ref.watch(selectedWeatherCityProvider) == null
                                ? 'Hava tahmini için listeden şehir seçin.'
                                : 'Henüz hava bilgisi yok — yenileyin.',
                            style: _cardInk(theme.textTheme.bodyMedium),
                          )
                        else ...[
                          Text(
                            [
                              if (weather.temperatureC != null)
                                '${weather.temperatureC!.toStringAsFixed(0)}°C',
                              if (weather.nightTemperatureC != null)
                                'Gece ${weather.nightTemperatureC!.toStringAsFixed(0)}°C',
                              if (weather.humidityPercent != null)
                                'Nem %${weather.humidityPercent!.toStringAsFixed(0)}',
                              if (weather.description.isNotEmpty)
                                weather.description,
                              if (weather.windKmh != null)
                                'Rüzgar ${weather.windKmh!.toStringAsFixed(0)} km/s',
                            ].join(' · '),
                            style: _cardInk(
                              theme.textTheme.titleSmall,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (weather.locationLabel.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              weather.locationLabel,
                              style: _cardInk(theme.textTheme.labelSmall),
                            ),
                          ],
                          if (!weather.synced ||
                              weather.offlineNote.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              weather.offlineNote.isNotEmpty
                                  ? weather.offlineNote
                                  : 'Senkron edilemedi',
                              style: _cardInk(
                                theme.textTheme.labelSmall,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionCard(
                    title: 'Puantaj özeti',
                    icon: Icons.fact_check_outlined,
                    trailing: TextButton(
                      onPressed: () {
                        final r = ref.read(activeDailyReportProvider);
                        if (r != null) syncAttendanceIntoReport(ref, r);
                      },
                      child: const Text('Yenile'),
                    ),
                    child: snap == null
                        ? Text(
                            'Puantaj verisi yok',
                            style: _cardInk(theme.textTheme.bodyMedium),
                          )
                        : AttendanceSummaryChips(snapshot: snap),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionCard(
                    title: 'Fotoğraflar',
                    icon: Icons.photo_camera_outlined,
                    trailing: IconButton(
                      onPressed: _showPhotoSource,
                      icon: const Icon(Icons.add_a_photo_outlined),
                    ),
                    child: (report?.photos.isEmpty ?? true)
                        ? Text(
                            'Henüz foto yok. Kamera veya galeriden ekleyin.\n'
                            'Açıklama + imalat türü yapılan işlere senkronize olur.',
                            style: _cardInk(theme.textTheme.bodyMedium),
                          )
                        : Column(
                            children: [
                              for (final photo in report!.photos)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: AppRadii.sm,
                                        child: Image.memory(
                                          base64Decode(photo.dataBase64),
                                          width: 72,
                                          height: 72,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                            width: 72,
                                            height: 72,
                                            color: theme.dividerColor,
                                            child: const Icon(Icons.broken_image),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              photo.hasCaption
                                                  ? photo.caption
                                                  : '(açıklama yok — önerilir)',
                                              style: _cardInk(
                                                theme.textTheme.bodyMedium,
                                                fontStyle: photo.hasCaption
                                                    ? FontStyle.normal
                                                    : FontStyle.italic,
                                                color: photo.hasCaption
                                                    ? null
                                                    : AppColors.warning,
                                              ),
                                            ),
                                            if (photo.workCategory !=
                                                PhotoWorkCategory.none)
                                              Text(
                                                '→ ${photo.workCategory.workSectionTitle}',
                                                style: _cardInk(
                                                  theme.textTheme.labelSmall,
                                                  color: theme
                                                      .colorScheme.primary,
                                                ),
                                              ),
                                            TextButton(
                                              onPressed: () =>
                                                  _editCaption(photo),
                                              child: Text(
                                                photo.hasCaption
                                                    ? 'Düzenle'
                                                    : 'Açıklama ekle',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          ref
                                              .read(
                                                dailyReportsProvider.notifier,
                                              )
                                              .upsert(
                                                report.copyWith(
                                                  photos: report.photos
                                                      .where(
                                                        (p) => p.id != photo.id,
                                                      )
                                                      .toList(),
                                                ),
                                              );
                                        },
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionCard(
                    title: 'Yapılan işler',
                    icon: Icons.checklist_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _WorkCategoryField(
                          label: 'İnşaat işleri',
                          controller: _workConstructionCtrl,
                          hint: 'İnşaat kapsamında yapılan işler…',
                          syncedCaptions: report?.photoCaptionsFor(
                                PhotoWorkCategory.construction,
                              ) ??
                              const [],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _WorkCategoryField(
                          label: 'Elektrik işleri',
                          controller: _workElectricalCtrl,
                          hint: 'Elektrik kapsamında yapılan işler…',
                          syncedCaptions: report?.photoCaptionsFor(
                                PhotoWorkCategory.electrical,
                              ) ??
                              const [],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _WorkCategoryField(
                          label: 'Mekanik işler',
                          controller: _workMechanicalCtrl,
                          hint: 'Mekanik kapsamında yapılan işler…',
                          syncedCaptions: report?.photoCaptionsFor(
                                PhotoWorkCategory.mechanical,
                              ) ??
                              const [],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionCard(
                    title: 'Gelen malzeme',
                    icon: Icons.local_shipping_outlined,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'İrsaliye fotoğrafı',
                          onPressed:
                              _irsaliyeBusy ? null : _showIrsaliyeSource,
                          icon: _irsaliyeBusy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.receipt_long_outlined),
                        ),
                        IconButton(
                          tooltip: 'Manuel ekle',
                          onPressed: () => _upsertMaterial(
                            kind: _MaterialList.incoming,
                          ),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (report?.irsaliyePhotos.isNotEmpty == true) ...[
                          Text(
                            'İrsaliye görselleri',
                            style: _cardInk(
                              theme.textTheme.labelMedium,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          SizedBox(
                            height: 72,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: report!.irsaliyePhotos.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: AppSpacing.xs),
                              itemBuilder: (context, i) {
                                final ph = report.irsaliyePhotos[i];
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: AppRadii.sm,
                                      child: Image.memory(
                                        base64Decode(ph.dataBase64),
                                        width: 72,
                                        height: 72,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            Container(
                                          width: 72,
                                          height: 72,
                                          color: theme.dividerColor,
                                          child: const Icon(Icons.broken_image),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: IconButton(
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        constraints:
                                            const BoxConstraints.tightFor(
                                          width: 28,
                                          height: 28,
                                        ),
                                        icon: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.black54,
                                        ),
                                        onPressed: () {
                                          final r = ref.read(
                                            activeDailyReportProvider,
                                          );
                                          if (r == null) return;
                                          ref
                                              .read(
                                                dailyReportsProvider.notifier,
                                              )
                                              .upsert(
                                                r.copyWith(
                                                  irsaliyePhotos: r
                                                      .irsaliyePhotos
                                                      .where(
                                                        (p) => p.id != ph.id,
                                                      )
                                                      .toList(),
                                                ),
                                              );
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        if ((report?.incomingMaterials.isEmpty ?? true))
                          Text(
                            'Gelen malzeme kaydı yok.\n'
                            'İrsaliye fotoğrafı ekleyerek otomatik doldurun '
                            'veya + ile manuel ekleyin.',
                            style: _cardInk(theme.textTheme.bodyMedium),
                          )
                        else
                          for (final m in report!.incomingMaterials)
                            _MaterialTile(
                              item: m,
                              onEdit: () => _upsertMaterial(
                                kind: _MaterialList.incoming,
                                existing: m,
                              ),
                              onDelete: () {
                                final r =
                                    ref.read(activeDailyReportProvider);
                                if (r == null) return;
                                ref
                                    .read(dailyReportsProvider.notifier)
                                    .upsert(
                                      r.copyWith(
                                        incomingMaterials: r.incomingMaterials
                                            .where((e) => e.id != m.id)
                                            .toList(),
                                      ),
                                    );
                              },
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ListSection(
                    title: 'Giden malzeme',
                    icon: Icons.outbox_outlined,
                    onAdd: () =>
                        _upsertMaterial(kind: _MaterialList.outgoing),
                    empty: 'Giden / gönderilen malzeme kaydı yok',
                    children: [
                      for (final m in report?.outgoingMaterials ?? const [])
                        _MaterialTile(
                          item: m,
                          onEdit: () => _upsertMaterial(
                            kind: _MaterialList.outgoing,
                            existing: m,
                          ),
                          onDelete: () {
                            final r = ref.read(activeDailyReportProvider);
                            if (r == null) return;
                            ref.read(dailyReportsProvider.notifier).upsert(
                                  r.copyWith(
                                    outgoingMaterials: r.outgoingMaterials
                                        .where((e) => e.id != m.id)
                                        .toList(),
                                  ),
                                );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ListSection(
                    title: 'Sipariş verilen malzeme',
                    icon: Icons.shopping_cart_outlined,
                    onAdd: () =>
                        _upsertMaterial(kind: _MaterialList.ordered),
                    empty: 'Sipariş kaydı yok',
                    children: [
                      for (final m in report?.orderedMaterials ?? const [])
                        _MaterialTile(
                          item: m,
                          showPurchaseApproval: true,
                          onEdit: () => _upsertMaterial(
                            kind: _MaterialList.ordered,
                            existing: m,
                          ),
                          onDelete: () {
                            final r = ref.read(activeDailyReportProvider);
                            if (r == null) return;
                            ref.read(dailyReportsProvider.notifier).upsert(
                                  r.copyWith(
                                    orderedMaterials: r.orderedMaterials
                                        .where((e) => e.id != m.id)
                                        .toList(),
                                  ),
                                );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ListSection(
                    title: 'İş makinesi puantajı',
                    icon: Icons.agriculture_outlined,
                    onAdd: () => _upsertMachine(),
                    empty: 'Makine kaydı yok',
                    children: [
                      for (final m in report?.machines ?? const [])
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(m.name),
                          subtitle: Text(
                            [
                              if (m.type.isNotEmpty) m.type,
                              if (m.company.isNotEmpty) m.company,
                              if (m.plateOrId.isNotEmpty) m.plateOrId,
                              if (m.hoursWorked > 0)
                                '${m.hoursWorked} sa',
                              if (m.workDescription.isNotEmpty)
                                m.workDescription,
                              if (m.operatorName.isNotEmpty)
                                'Op: ${m.operatorName}',
                            ].join(' · '),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _upsertMachine(existing: m),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete_outline, size: 20),
                                onPressed: () {
                                  final r =
                                      ref.read(activeDailyReportProvider);
                                  if (r == null) return;
                                  ref
                                      .read(dailyReportsProvider.notifier)
                                      .upsert(
                                        r.copyWith(
                                          machines: r.machines
                                              .where((e) => e.id != m.id)
                                              .toList(),
                                        ),
                                      );
                                },
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ListSection(
                    title: 'Vasıta puantajı',
                    icon: Icons.directions_car_outlined,
                    onAdd: () => _upsertMachine(vehicle: true),
                    empty: 'Vasıta kaydı yok',
                    children: [
                      for (final m in report?.vehicles ?? const [])
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(m.name),
                          subtitle: Text(
                            [
                              if (m.type.isNotEmpty) m.type,
                              if (m.plateOrId.isNotEmpty) m.plateOrId,
                              if (m.hoursWorked > 0)
                                '${m.hoursWorked} sa',
                              if (m.workDescription.isNotEmpty)
                                m.workDescription,
                              if (m.operatorName.isNotEmpty)
                                'Şoför: ${m.operatorName}',
                            ].join(' · '),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                onPressed: () => _upsertMachine(
                                  existing: m,
                                  vehicle: true,
                                ),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete_outline, size: 20),
                                onPressed: () {
                                  final r =
                                      ref.read(activeDailyReportProvider);
                                  if (r == null) return;
                                  ref
                                      .read(dailyReportsProvider.notifier)
                                      .upsert(
                                        r.copyWith(
                                          vehicles: r.vehicles
                                              .where((e) => e.id != m.id)
                                              .toList(),
                                        ),
                                      );
                                },
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionCard(
                    title: 'Ertesi gün planı',
                    icon: Icons.event_note_outlined,
                    child: _WorkCategoryField(
                      label: 'Yarın yapılacak işler',
                      controller: _nextDayPlanCtrl,
                      hint: 'Ertesi gün planlanan işler, ekipler, malzeme…',
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: SJButton(
                label: 'PDF Rapor Dışa Aktar',
                icon: Icons.picture_as_pdf_outlined,
                expanded: true,
                onPressed: _openExportSheet,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkCategoryField extends StatelessWidget {
  const _WorkCategoryField({
    required this.label,
    required this.controller,
    required this.hint,
    this.syncedCaptions = const [],
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final List<String> syncedCaptions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: _cardInk(
            theme.textTheme.labelLarge,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        if (syncedCaptions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Fotoğraflardan senkron',
            style: _cardInk(
              theme.textTheme.labelSmall,
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          for (final c in syncedCaptions)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '• $c',
                style: _cardInk(theme.textTheme.bodySmall),
              ),
            ),
        ],
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SJCard(
      child: Builder(
        builder: (context) {
          final t = Theme.of(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: t.colorScheme.secondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      title,
                      style: t.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              child,
            ],
          );
        },
      ),
    );
  }
}

class _ListSection extends StatelessWidget {
  const _ListSection({
    required this.title,
    required this.icon,
    required this.onAdd,
    required this.empty,
    required this.children,
  });

  final String title;
  final IconData icon;
  final VoidCallback onAdd;
  final String empty;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: title,
      icon: icon,
      trailing: IconButton(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
      ),
      child: children.isEmpty
          ? Builder(
              builder: (ctx) => Text(
                empty,
                style: _cardInk(Theme.of(ctx).textTheme.bodyMedium),
              ),
            )
          : Column(children: children),
    );
  }
}

class _MaterialTile extends StatelessWidget {
  const _MaterialTile({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    this.showPurchaseApproval = false,
  });

  final DailyReportMaterial item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showPurchaseApproval;

  @override
  Widget build(BuildContext context) {
    final qty = [
      if (item.quantity.isNotEmpty) item.quantity,
      if (item.unit.isNotEmpty) item.unit,
    ].join(' ');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(item.name.isEmpty ? '(açıklama yok)' : item.name),
      subtitle: Text(
        [
          if (item.supplyDate.isNotEmpty) item.supplyDate,
          if (qty.isNotEmpty) qty,
          if (item.supplierOrOrder.isNotEmpty) item.supplierOrOrder,
          if (item.price.isNotEmpty) '₺${item.price}',
          if (showPurchaseApproval)
            item.purchaseApproved
                ? 'Satın alma: onaylı'
                : 'Satın alma: bekliyor',
          if (item.note.isNotEmpty) item.note,
          if (item.irsaliyePhotoId.isNotEmpty) 'İrsaliye',
        ].join(' · '),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showPurchaseApproval && item.purchaseApproved)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.check_circle, color: AppColors.success, size: 20),
            ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

/// Günlük rapor PDF — Özet / Standart / Gelişmiş seçimi.
class _DailyReportExportSheet extends StatefulWidget {
  const _DailyReportExportSheet({
    required this.project,
    required this.report,
    required this.company,
    this.liveSnapshot,
  });

  final Project project;
  final DailyReport report;
  final CompanyInfo company;
  final DailyReportAttendanceSnapshot? liveSnapshot;

  @override
  State<_DailyReportExportSheet> createState() =>
      _DailyReportExportSheetState();
}

class _DailyReportExportSheetState extends State<_DailyReportExportSheet> {
  DailyReportExportStyle _style = DailyReportExportStyle.standart;
  bool _busy = false;
  String? _error;

  Future<void> _export() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await dailyReportPdfService.export(
        report: widget.report,
        project: widget.project,
        company: widget.company,
        style: _style,
        liveSnapshot: widget.liveSnapshot,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_style.label} PDF dışa aktarıldı'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Günlük rapor PDF',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${widget.project.name} · ${widget.report.date}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Çıktı stili', style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          SegmentedButton<DailyReportExportStyle>(
            style: SegmentedButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurfaceVariant,
              selectedForegroundColor: Colors.white,
              selectedBackgroundColor: theme.colorScheme.secondary,
            ),
            segments: [
              for (final s in DailyReportExportStyle.values)
                ButtonSegment(
                  value: s,
                  label: Text(s.label),
                ),
            ],
            selected: {_style},
            onSelectionChanged: _busy
                ? null
                : (v) => setState(() => _style = v.first),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _style.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SJButton(
            label: 'PDF Oluştur',
            icon: Icons.picture_as_pdf_outlined,
            loading: _busy,
            expanded: true,
            onPressed: _export,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.critical,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _MaterialList { incoming, outgoing, ordered }

/// Türkiye illeri seçici — arama + alfabetik liste.
class _CityPickerSheet extends StatefulWidget {
  const _CityPickerSheet({this.selectedId});

  final String? selectedId;

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
  final _queryCtrl = TextEditingController();
  late final List<TurkeyCity> _all = turkeyCitiesSorted();

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  static String _foldTr(String s) => s
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');

  List<TurkeyCity> get _filtered {
    final q = _foldTr(_queryCtrl.text.trim());
    if (q.isEmpty) return _all;
    return _all.where((c) => _foldTr(c.name).contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final filtered = _filtered;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
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
                'Şehir seçin',
                style: theme.textTheme.headlineMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: TextField(
                controller: _queryCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'İl ara…',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final city = filtered[index];
                  final selected = city.id == widget.selectedId;
                  return ListTile(
                    title: Text(city.name),
                    trailing: selected
                        ? Icon(
                            Icons.check_circle,
                            color: theme.colorScheme.primary,
                          )
                        : null,
                    selected: selected,
                    onTap: () => Navigator.pop(context, city),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
