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
import '../../core/utils/id_gen.dart';
import '../../core/utils/puantaj_date.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/providers/company_provider.dart';
import '../../data/providers/daily_report_export_sections_provider.dart';
import '../../data/providers/daily_report_provider.dart';
import '../../data/providers/period_site_report_export_sections_provider.dart';
import '../../data/providers/period_site_report_provider.dart';
import '../../data/services/daily_report_pdf_service.dart';
import '../../data/services/period_site_report_builder.dart';
import '../../data/services/period_site_report_export_service.dart';
import '../../data/services/puantaj_report_builder.dart';
import '../../data/services/irsaliye_material_ocr.dart';
import '../../domain/catalogs/turkey_cities.dart';
import '../../domain/daily_report/daily_report_copy.dart';
import '../../domain/entities/daily_report.dart';
import '../../domain/entities/project.dart';
import '../../domain/enums/photo_work_category.dart';
import 'widgets/attendance_summary_table.dart';
import 'widgets/daily_report_entry_page.dart';
import 'widgets/daily_report_export_sections_sheet.dart';
import 'widgets/monthly_report_view.dart';
import '../../data/providers/yevmiyeli_is_provider.dart';
import 'widgets/period_report_export_sections_sheet.dart';
import 'widgets/weather_compact_card.dart';
import 'widgets/weekly_report_view.dart';

enum _ReportViewMode { daily, weekly, monthly }

/// Kart içi metin stili — chrome textTheme renklerini atar; kart mürekkebi kullanır.
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
    color: color ?? AppColors.cardTextPrimary,
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
  final _planConstructionCtrl = TextEditingController();
  final _planElectricalCtrl = TextEditingController();
  final _planMechanicalCtrl = TextEditingController();
  final _picker = ImagePicker();
  bool _weatherLoading = false;
  bool _irsaliyeBusy = false;
  bool _bootstrapped = false;
  String? _boundKey;
  Timer? _autosaveTimer;
  bool _hydrating = false;
  _ReportViewMode _viewMode = _ReportViewMode.daily;

  @override
  void initState() {
    super.initState();
    _workConstructionCtrl.addListener(_scheduleAutosave);
    _workElectricalCtrl.addListener(_scheduleAutosave);
    _workMechanicalCtrl.addListener(_scheduleAutosave);
    _planConstructionCtrl.addListener(_scheduleAutosave);
    _planElectricalCtrl.addListener(_scheduleAutosave);
    _planMechanicalCtrl.addListener(_scheduleAutosave);
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _workConstructionCtrl.removeListener(_scheduleAutosave);
    _workElectricalCtrl.removeListener(_scheduleAutosave);
    _workMechanicalCtrl.removeListener(_scheduleAutosave);
    _planConstructionCtrl.removeListener(_scheduleAutosave);
    _planElectricalCtrl.removeListener(_scheduleAutosave);
    _planMechanicalCtrl.removeListener(_scheduleAutosave);
    _workConstructionCtrl.dispose();
    _workElectricalCtrl.dispose();
    _workMechanicalCtrl.dispose();
    _planConstructionCtrl.dispose();
    _planElectricalCtrl.dispose();
    _planMechanicalCtrl.dispose();
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
      planConstruction: _planConstructionCtrl.text.trim(),
      planElectrical: _planElectricalCtrl.text.trim(),
      planMechanical: _planMechanicalCtrl.text.trim(),
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
    _planConstructionCtrl.text = report.planConstruction;
    _planElectricalCtrl.text = report.planElectrical;
    _planMechanicalCtrl.text = report.planMechanical;
    _hydrating = false;
    _boundKey = key;
    _bootstrapped = true;

    // Snapshot her açılışta canlıdan yazılır.
    syncAttendanceIntoReport(ref, report);

    // Otomatik hava: yoksa veya senkron değilse çek.
    // Geçmiş günde kilitli otomatik kayıt varsa dokunma.
    final city = ref.read(selectedWeatherCityProvider);
    final w = report.weather;
    final locked = w != null && w.isAutoLocked(report.date);
    final needsWeather = city != null &&
        !locked &&
        (w == null || (!w.isManual && !w.synced));
    if (needsWeather && !_weatherLoading) {
      setState(() => _weatherLoading = true);
      try {
        await refreshReportWeather(ref, report: report, city: city);
      } finally {
        if (mounted) setState(() => _weatherLoading = false);
      }
    }
  }

  void _hydrateTextControllers(DailyReport report) {
    _hydrating = true;
    _workConstructionCtrl.text = report.workConstruction;
    _workElectricalCtrl.text = report.workElectrical;
    _workMechanicalCtrl.text = report.workMechanical;
    _planConstructionCtrl.text = report.planConstruction;
    _planElectricalCtrl.text = report.planElectrical;
    _planMechanicalCtrl.text = report.planMechanical;
    _hydrating = false;
  }

  void _copyFromYesterday(Set<DailyReportCopyField> fields) {
    final project = ref.read(activeProjectProvider);
    if (project == null) return;
    final date = ref.read(dailyReportSelectedDateProvider);
    final result = ref.read(dailyReportsProvider.notifier).copyFromPreviousDay(
          projectId: project.id,
          date: date,
          previousDate: PuantajDate.shift(date, -1),
          fields: fields,
        );

    if (result.workTexts || result.nextDayPlan) {
      final updated = ref.read(activeDailyReportProvider);
      if (updated != null) _hydrateTextControllers(updated);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  Future<void> _pickWeatherCity() async {
    final report = ref.read(activeDailyReportProvider);
    if (report != null &&
        report.weather?.isAutoLocked(report.date) == true) {
      final unlock = await _confirmManualWeatherOverride();
      if (!unlock || !mounted) return;
    }
    final selectedId = ref.read(weatherCityIdProvider);
    final picked = await showModalBottomSheet<TurkeyCity>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _CityPickerSheet(selectedId: selectedId),
    );
    if (picked == null || !mounted) return;
    final current = ref.read(activeDailyReportProvider);
    if (current == null) return;
    setState(() => _weatherLoading = true);
    try {
      await refreshReportWeather(
        ref,
        report: current,
        city: picked,
        force: true,
      );
    } finally {
      if (mounted) setState(() => _weatherLoading = false);
    }
  }

  Future<void> _refreshWeather({bool force = false}) async {
    final report = ref.read(activeDailyReportProvider);
    if (report == null) return;
    final locked = report.weather?.isAutoLocked(report.date) == true;
    if (locked && !force) {
      final unlock = await _confirmManualWeatherOverride();
      if (!unlock || !mounted) return;
      force = true;
    }
    final city = ref.read(selectedWeatherCityProvider);
    if (city == null) {
      await _pickWeatherCity();
      return;
    }
    setState(() => _weatherLoading = true);
    try {
      await refreshReportWeather(
        ref,
        report: report,
        city: city,
        force: force,
      );
    } finally {
      if (mounted) setState(() => _weatherLoading = false);
    }
  }

  Future<bool> _confirmManualWeatherOverride() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Manuel müdahale'),
        content: const Text(
          'Bu güne ait hava durumu otomatik kaydedilmiş ve kilitlenmiş. '
          'Manuel müdahale ile değiştirebilirsiniz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Müdahale et'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _editManualWeather() async {
    final report = ref.read(activeDailyReportProvider);
    if (report == null) return;
    final locked = report.weather?.isAutoLocked(report.date) == true;
    if (locked) {
      final unlock = await _confirmManualWeatherOverride();
      if (!unlock || !mounted) return;
    }
    final current = report.weather ?? const DailyReportWeather(isManual: true);
    final temp = TextEditingController(
      text: current.temperatureC?.toStringAsFixed(0) ?? '',
    );
    final night = TextEditingController(
      text: current.nightTemperatureC?.toStringAsFixed(0) ?? '',
    );
    final humidity = TextEditingController(
      text: current.humidityPercent?.toStringAsFixed(0) ?? '',
    );
    final maxHumidity = TextEditingController(
      text: current.maxHumidityPercent?.toStringAsFixed(0) ?? '',
    );
    final wind = TextEditingController(
      text: current.windKmh?.toStringAsFixed(0) ?? '',
    );
    final gust = TextEditingController(
      text: current.windGustKmh?.toStringAsFixed(0) ?? '',
    );
    final desc = TextEditingController(text: current.description);
    final location = TextEditingController(text: current.locationLabel);

    double? parse(String raw) {
      final t = raw.trim().replaceAll(',', '.');
      if (t.isEmpty) return null;
      return double.tryParse(t);
    }

    final result = await showDailyReportEntryPage<DailyReportWeather>(
      context: context,
      title: 'Hava durumu',
      formBuilder: (ctx, setModal) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: temp,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      _dialogFieldDecoration(labelText: 'Gündüz (°C)'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: night,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: _dialogFieldDecoration(labelText: 'Gece (°C)'),
                ),
              ),
            ],
          ),
          _kDialogFieldGap,
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: humidity,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: _dialogFieldDecoration(labelText: 'Nem (%)'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: maxHumidity,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      _dialogFieldDecoration(labelText: 'Max nem (%)'),
                ),
              ),
            ],
          ),
          _kDialogFieldGap,
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: wind,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      _dialogFieldDecoration(labelText: 'Rüzgar (km/s)'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: gust,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      _dialogFieldDecoration(labelText: 'Ani rüzgar (km/s)'),
                ),
              ),
            ],
          ),
          _kDialogFieldGap,
          TextField(
            controller: desc,
            decoration: _dialogFieldDecoration(labelText: 'Açıklama'),
          ),
          _kDialogFieldGap,
          TextField(
            controller: location,
            decoration: _dialogFieldDecoration(labelText: 'Konum / şehir'),
          ),
        ],
      ),
      onSave: () => DailyReportWeather(
        temperatureC: parse(temp.text),
        nightTemperatureC: parse(night.text),
        humidityPercent: parse(humidity.text),
        maxHumidityPercent: parse(maxHumidity.text),
        windKmh: parse(wind.text),
        windGustKmh: parse(gust.text),
        description: desc.text.trim(),
        locationLabel: location.text.trim(),
        fetchedAt: DateTime.now(),
        synced: true,
        offlineNote: '',
        isManual: true,
      ),
    );

    temp.dispose();
    night.dispose();
    humidity.dispose();
    maxHumidity.dispose();
    wind.dispose();
    gust.dispose();
    desc.dispose();
    location.dispose();
    if (result == null || !mounted) return;
    saveManualWeather(ref, report: report, weather: result);
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
      planConstruction: _planConstructionCtrl.text.trim(),
      planElectrical: _planElectricalCtrl.text.trim(),
      planMechanical: _planMechanicalCtrl.text.trim(),
    );
    next = syncAttendanceIntoReport(ref, next);
    ref.read(dailyReportsProvider.notifier).upsert(next);
    return next;
  }

  Future<void> _openExportSheet() async {
    final project = ref.read(activeProjectProvider);
    if (project == null) return;

    if (_viewMode == _ReportViewMode.daily) {
      await _exportDailyPdf(project);
      return;
    }
    await _exportPeriodReport(project);
  }

  PeriodSiteReportData? _buildPeriodSiteReport(Project project) {
    final anchor = ref.read(dailyReportSelectedDateProvider);
    final period = switch (_viewMode) {
      _ReportViewMode.weekly => PuantajReportPeriod.weekly,
      _ReportViewMode.monthly => PuantajReportPeriod.monthly,
      _ReportViewMode.daily => PuantajReportPeriod.daily,
    };
    return ref.read(
      periodSiteReportProvider((
        projectId: project.id,
        anchorDate: anchor,
        period: period,
      )),
    );
  }

  Future<void> _exportPeriodReport(Project project) async {
    final report = _buildPeriodSiteReport(project);
    if (report == null) return;

    final periodLabel = report.periodLabel;
    final choice = await showPeriodReportExportSectionsPicker(
      context,
      ref,
      title: 'Rapor AL',
      subtitle: '${project.name} · ${report.rangeLabel}',
    );
    if (choice == null || !mounted) return;

    ref.read(periodSiteReportExportSectionsProvider.notifier).save(choice.sections);

    final company = ref.read(companyInfoProvider);
    try {
      if (choice.pdf) {
        await periodSiteReportExportService.exportPdf(
          report,
          projectName: project.name,
          companyName: company.name,
          sections: choice.sections,
        );
      } else {
        await periodSiteReportExportService.exportExcel(
          report,
          projectName: project.name,
          sections: choice.sections,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            choice.pdf
                ? '$periodLabel PDF dışa aktarıldı'
                : '$periodLabel Excel dışa aktarıldı',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dışa aktarılamadı: $e')),
      );
    }
  }

  Future<void> _exportDailyPdf(Project project) async {
    final report = _persistDraftForExport();
    if (report == null) return;
    final snap = ref.read(liveAttendanceSnapshotProvider);
    final company = ref.read(companyInfoProvider);
    final yevmiyeli = ref
        .read(yevmiyeliIsProvider)
        .where((e) => e.projectId == project.id)
        .toList();

    final sections = await showDailyReportExportSectionsPicker(
      context,
      ref,
      title: 'PDF Rapor Dışa Aktar',
      subtitle: '${project.name} · ${report.date}',
    );
    if (sections == null || !mounted) return;

    ref.read(dailyReportExportSectionsProvider.notifier).save(sections);

    try {
      await dailyReportPdfService.export(
        report: report,
        project: project,
        company: company,
        sections: sections,
        liveSnapshot: snap,
        yevmiyeliEntries: yevmiyeli,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF rapor dışa aktarıldı')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF oluşturulamadı: $e')),
      );
    }
  }

  Future<void> _addPhotosFromFiles(List<XFile> files) async {
    final report = ref.read(activeDailyReportProvider);
    if (report == null || files.isEmpty) return;

    final added = <DailyReportPhoto>[];
    var skippedLarge = 0;

    for (final file in files) {
      try {
        final bytes = await file.readAsBytes();
        if (bytes.length > 2 * 1024 * 1024) {
          skippedLarge++;
          continue;
        }
        added.add(
          DailyReportPhoto(
            id: IdGen.make('ph'),
            dataBase64: base64Encode(bytes),
            mimeType: file.mimeType ?? 'image/jpeg',
            caption: '',
            createdAt: DateTime.now(),
          ),
        );
      } catch (_) {
        // Tek dosya hatası diğerlerini engellemesin.
      }
    }

    if (added.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            skippedLarge > 0
                ? 'Seçilen fotoğraflar çok büyük (en fazla ~2 MB)'
                : 'Foto eklenemedi',
          ),
        ),
      );
      return;
    }

    ref.read(dailyReportsProvider.notifier).upsert(
          report.copyWith(
            photos: DailyReport.sortPhotosByWorkCategory([
              ...report.photos,
              ...added,
            ]),
          ),
        );

    if (!mounted) return;
    final msg = skippedLarge > 0
        ? '${added.length} foto eklendi, $skippedLarge tanesi boyuttan atlandı'
        : added.length == 1
            ? 'Foto eklendi — açıklama eklemeniz önerilir'
            : '${added.length} foto eklendi — açıklama eklemeniz önerilir';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _addPhotoFromCamera() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        imageQuality: 72,
      );
      if (file == null) return;
      await _addPhotosFromFiles([file]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Foto eklenemedi: $e')),
        );
      }
    }
  }

  Future<void> _addPhotosFromGallery() async {
    try {
      final files = await _picker.pickMultiImage(
        maxWidth: 1280,
        imageQuality: 72,
      );
      if (files.isEmpty) return;
      await _addPhotosFromFiles(files);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Foto eklenemedi: $e')),
        );
      }
    }
  }

  void _showPhotoSource() {
    final sheetTheme = SJModal.sheetThemeOf(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: SJModal.sheetSurface,
      builder: (ctx) => Theme(
        data: sheetTheme,
        child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeriden seç'),
              subtitle: const Text('Birden fazla fotoğraf seçebilirsiniz'),
              onTap: () {
                Navigator.pop(ctx);
                _addPhotosFromGallery();
              },
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _addPhotoFromCamera();
                },
              ),
            if (kIsWeb)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  'Web’de birden fazla fotoğraf seçebilirsiniz; '
                  'Hive’da base64 olarak saklanır.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
        ),
      ),
    );
  }

  /// Tam ekran not girişi — yapılan işler / planlı işler için.
  Future<void> _editWorkNotes({
    required String title,
    required String hint,
    required TextEditingController target,
    List<String> syncedCaptions = const [],
  }) async {
    final ctrl = TextEditingController(text: target.text);
    final focus = FocusNode();

    void insertBullet() {
      final text = ctrl.text;
      final sel = ctrl.selection;
      final start = sel.isValid ? sel.start : text.length;
      final end = sel.isValid ? sel.end : text.length;
      final atLineStart = start == 0 || text[start - 1] == '\n';
      final insert = atLineStart ? '• ' : '\n• ';
      final next = text.replaceRange(start, end, insert);
      final caret = start + insert.length;
      ctrl.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: caret),
      );
      focus.requestFocus();
    }

    void appendSynced(String caption) {
      final line = caption.trim();
      if (line.isEmpty) return;
      final text = ctrl.text.trimRight();
      final next = text.isEmpty ? '• $line' : '$text\n• $line';
      ctrl.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
      focus.requestFocus();
    }

    final result = await showDailyReportEntryPage<String>(
      context: context,
      title: title,
      scrollable: false,
      saveLabel: 'Kaydet',
      formBuilder: (ctx, setModal) {
        final theme = Theme.of(ctx);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.format_list_bulleted, size: 18),
                    label: const Text('Madde ekle'),
                    onPressed: () {
                      insertBullet();
                      setModal(() {});
                    },
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  ActionChip(
                    avatar: const Icon(Icons.backspace_outlined, size: 18),
                    label: const Text('Temizle'),
                    onPressed: () {
                      ctrl.clear();
                      setModal(() {});
                      focus.requestFocus();
                    },
                  ),
                ],
              ),
            ),
            if (syncedCaptions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Fotoğraf açıklamalarından ekle',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in syncedCaptions)
                    ActionChip(
                      label: Text(
                        c.length > 42 ? '${c.substring(0, 42)}…' : c,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: () {
                        appendSynced(c);
                        setModal(() {});
                      },
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: ctrl,
                focusNode: focus,
                maxLines: null,
                expands: true,
                autofocus: true,
                textAlignVertical: TextAlignVertical.top,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: _dialogFieldDecoration(
                  labelText: 'Notlar',
                  hintText: hint,
                ).copyWith(alignLabelWithHint: true),
              ),
            ),
          ],
        );
      },
      onSave: () => ctrl.text,
    );
    focus.dispose();
    ctrl.dispose();
    if (result == null || !mounted) return;
    setState(() => target.text = result.trimRight());
  }

  void _openFullscreenPhoto(String dataBase64) {
    late final Uint8List bytes;
    try {
      bytes = base64Decode(dataBase64);
    } catch (_) {
      return;
    }
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.92),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: InteractiveViewer(
                        minScale: 0.8,
                        maxScale: 5,
                        child: Center(
                          child: Image.memory(
                            bytes,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image,
                              color: Colors.white70,
                              size: 64,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _editCaption(DailyReportPhoto photo) async {
    final report = ref.read(activeDailyReportProvider);
    if (report == null) return;
    final ctrl = TextEditingController(text: photo.caption);
    var category = photo.workCategory;
    final result =
        await showDailyReportEntryPage<({String caption, PhotoWorkCategory cat})>(
      context: context,
      title: 'Fotoğraf açıklaması',
      scrollable: false,
      formBuilder: (ctx, setModal) => Column(
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
          Expanded(
            child: TextField(
              controller: ctrl,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: _dialogFieldDecoration(
                labelText: 'Açıklama',
                hintText: 'Örn. Temel kazısı — batı cephe',
              ).copyWith(
                alignLabelWithHint: true,
              ),
              autofocus: true,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Seçilen türe göre yapılan işler altına senkronize olur',
            style: Theme.of(ctx).textTheme.bodySmall,
          ),
        ],
      ),
      onSave: () => (caption: ctrl.text.trim(), cat: category),
    );
    ctrl.dispose();
    if (result == null) return;
    ref.read(dailyReportsProvider.notifier).upsert(
          report.copyWith(
            photos: DailyReport.sortPhotosByWorkCategory([
              for (final p in report.photos)
                if (p.id == photo.id)
                  p.copyWith(
                    caption: result.caption,
                    workCategory: result.cat,
                  )
                else
                  p,
            ]),
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

    final values = await showDailyReportEntryPage<Map<String, String>>(
      context: context,
      title: existing == null ? titleNew() : 'Malzeme düzenle',
      formBuilder: (ctx, setModal) => Column(
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
            decoration: _dialogFieldDecoration(labelText: 'Ürün miktarı'),
            keyboardType: TextInputType.number,
          ),
          _kDialogFieldGap,
          TextField(
            controller: unit,
            decoration: _dialogFieldDecoration(labelText: 'Ürün birimi'),
          ),
          _kDialogFieldGap,
          TextField(
            controller: supplier,
            decoration: _dialogFieldDecoration(labelText: partyLabel()),
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
              onChanged: (v) => setModal(() => purchaseApproved = v ?? false),
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
      onSave: () {
        if (name.text.trim().isEmpty) return null;
        return {
          'name': name.text.trim(),
          'qty': qty.text.trim(),
          'unit': unit.text.trim(),
          'supplier': supplier.text.trim(),
          'supplyDate': supplyDate.text.trim(),
          'price': price.text.trim(),
          'note': note.text.trim(),
          'approved': purchaseApproved ? '1' : '0',
        };
      },
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

    final ok = await showDailyReportEntryPage<bool>(
      context: context,
      title: 'İrsaliye — malzeme onayı',
      cancelLabel: 'Atla',
      saveLabel: 'Listeye ekle',
      onCancel: () => false,
      onSave: () => true,
      formBuilder: (ctx, setModal) => Column(
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
              decoration: _dialogFieldDecoration(labelText: 'Ürün adı *'),
            ),
            _kDialogFieldGap,
            TextField(
              controller: rowCtrls[i].qty,
              decoration: _dialogFieldDecoration(labelText: 'Ürün miktarı'),
            ),
            _kDialogFieldGap,
            TextField(
              controller: rowCtrls[i].unit,
              decoration: _dialogFieldDecoration(labelText: 'Ürün birimi'),
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
    final sheetTheme = SJModal.sheetThemeOf(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: SJModal.sheetSurface,
      builder: (ctx) => Theme(
        data: sheetTheme,
        child: SafeArea(
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

    final values = await showDailyReportEntryPage<Map<String, String>>(
      context: context,
      title: existing == null
          ? (vehicle ? 'Vasıta' : 'İş makinesi')
          : (vehicle ? 'Vasıta düzenle' : 'Makine düzenle'),
      formBuilder: (ctx, setModal) => Column(
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
            decoration: _dialogFieldDecoration(labelText: 'Plaka / kimlik'),
          ),
          _kDialogFieldGap,
          TextField(
            controller: hours,
            decoration: _dialogFieldDecoration(labelText: 'Çalışma saati'),
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
      onSave: () {
        if (name.text.trim().isEmpty) return null;
        return {
          'name': name.text.trim(),
          'type': type.text.trim(),
          'plate': plate.text.trim(),
          'company': company.text.trim(),
          'hours': hours.text.trim(),
          'work': work.text.trim(),
          'op': op.text.trim(),
        };
      },
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

  void _openDailyDate(String date) {
    ref.read(dailyReportSelectedDateProvider.notifier).state = date;
    _bootstrapped = false;
    _boundKey = null;
    setState(() => _viewMode = _ReportViewMode.daily);
  }

  Widget _reportModeTabs(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.afterHeader,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderRadius: AppRadii.md,
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            for (final m in _ReportViewMode.values)
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _viewMode = m),
                  borderRadius: AppRadii.md,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _viewMode == m
                          ? theme.colorScheme.secondary
                          : Colors.transparent,
                      borderRadius: AppRadii.md,
                    ),
                    child: Text(
                      switch (m) {
                        _ReportViewMode.daily => 'Günlük rapor',
                        _ReportViewMode.weekly => 'Haftalık rapor',
                        _ReportViewMode.monthly => 'Aylık rapor',
                      },
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: _viewMode == m
                            ? theme.colorScheme.onSecondary
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(activeProjectProvider);
    final date = ref.watch(dailyReportSelectedDateProvider);
    final report = ref.watch(activeDailyReportProvider);
    final snap = ref.watch(liveAttendanceSnapshotProvider);

    if (project != null && _viewMode == _ReportViewMode.daily) {
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
              const SantijetHeader(subtitle: 'Rapor'),
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
    final isToday = date == PuantajDate.today();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SantijetHeader(
              subtitle: 'Rapor',
              actionsBeforeSettings: [
                SantijetHeaderDownloadButton(
                  tooltip: 'Rapor AL',
                  onPressed: _openExportSheet,
                ),
              ],
            ),
            _reportModeTabs(theme),
            if (_viewMode == _ReportViewMode.daily) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                0,
              ),
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isToday)
                              Text(
                                'Bugün',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: AppColors.electricBlue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            Text(
                              PuantajDate.withDayName(date),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
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
                  if (!isToday)
                    TextButton(
                      onPressed: () {
                        ref
                            .read(dailyReportSelectedDateProvider.notifier)
                            .state = PuantajDate.today();
                        _bootstrapped = false;
                        _boundKey = null;
                      },
                      child: const Text('Bugün'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: AppLayout.scrollPadding(
                  top: AppSpacing.sm,
                  clearFab: true,
                  extraBottom: MediaQuery.viewInsetsOf(context).bottom,
                ),
                children: [
                  WeatherCompactCard(
                    weather: weather,
                    date: date,
                    loading: _weatherLoading,
                    cityName: ref.watch(selectedWeatherCityProvider)?.name,
                    onPickCity: _pickWeatherCity,
                    onEdit: _editManualWeather,
                    onRefresh: () => _refreshWeather(),
                  ),
                  if (snap != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    AttendanceSummaryTables(snapshot: snap),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Builder(
                    builder: (context) {
                      final project = ref.watch(activeProjectProvider);
                      if (project == null) return const SizedBox.shrink();
                      final entries = ref
                          .watch(yevmiyeliIsProvider)
                          .where(
                            (e) =>
                                e.projectId == project.id && e.date == date,
                          )
                          .toList();
                      final data = PuantajReportBuilder.buildYevmiyeli(
                        projectName: project.name,
                        projectId: project.id,
                        period: PuantajReportPeriod.daily,
                        anchorDate: date,
                        entries: entries,
                      );
                      return DailyReportCollapsibleSection(
                        icon: Icons.handyman_outlined,
                        title: 'Yevmiyeli işler',
                        child: PeriodTeamSummaryTable(
                          headers: data.headers,
                          rows: data.rows,
                          emptyMessage:
                              'Bu gün için yevmiyeli iş kaydı yok',
                          sumColumnIndexes: data.sumColumnIndexes,
                        ),
                      );
                    },
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
                            'Açıklama + imalat türü yapılan işlere senkronize olur.\n'
                            'Sıra: inşaat → elektrik → mekanik.',
                            style: _cardInk(theme.textTheme.bodyMedium),
                          )
                        : Builder(
                            builder: (context) {
                              final photos = report!.photosByWorkCategory;
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: photos.length,
                                itemBuilder: (context, index) {
                                  final photo = photos[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () => _openFullscreenPhoto(
                                              photo.dataBase64,
                                            ),
                                            borderRadius: AppRadii.sm,
                                            child: ClipRRect(
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
                                                  child: const Icon(
                                                    Icons.broken_image,
                                                  ),
                                                ),
                                              ),
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
                                                  dailyReportsProvider
                                                      .notifier,
                                                )
                                                .upsert(
                                                  report.copyWith(
                                                    photos: report.photos
                                                        .where(
                                                          (p) =>
                                                              p.id != photo.id,
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
                                  );
                                },
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionCard(
                    title: 'Yapılan işler',
                    icon: Icons.checklist_outlined,
                    onCopyYesterday: () => _copyFromYesterday({
                      DailyReportCopyField.workTexts,
                    }),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _WorkNotesTile(
                          label: 'İnşaat işleri',
                          text: _workConstructionCtrl.text,
                          emptyHint: 'İnşaat kapsamında yapılan işler…',
                          syncedCaptions: report?.syncedCaptionsFor(
                                PhotoWorkCategory.construction,
                              ) ??
                              const [],
                          onEdit: () => _editWorkNotes(
                            title: 'İnşaat işleri',
                            hint: 'İnşaat kapsamında yapılan işler…',
                            target: _workConstructionCtrl,
                            syncedCaptions: report?.syncedCaptionsFor(
                                  PhotoWorkCategory.construction,
                                ) ??
                                const [],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _WorkNotesTile(
                          label: 'Elektrik işleri',
                          text: _workElectricalCtrl.text,
                          emptyHint: 'Elektrik kapsamında yapılan işler…',
                          syncedCaptions: report?.syncedCaptionsFor(
                                PhotoWorkCategory.electrical,
                              ) ??
                              const [],
                          onEdit: () => _editWorkNotes(
                            title: 'Elektrik işleri',
                            hint: 'Elektrik kapsamında yapılan işler…',
                            target: _workElectricalCtrl,
                            syncedCaptions: report?.syncedCaptionsFor(
                                  PhotoWorkCategory.electrical,
                                ) ??
                                const [],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _WorkNotesTile(
                          label: 'Mekanik işler',
                          text: _workMechanicalCtrl.text,
                          emptyHint: 'Mekanik kapsamında yapılan işler…',
                          syncedCaptions: report?.syncedCaptionsFor(
                                PhotoWorkCategory.mechanical,
                              ) ??
                              const [],
                          onEdit: () => _editWorkNotes(
                            title: 'Mekanik işler',
                            hint: 'Mekanik kapsamında yapılan işler…',
                            target: _workMechanicalCtrl,
                            syncedCaptions: report?.syncedCaptionsFor(
                                  PhotoWorkCategory.mechanical,
                                ) ??
                                const [],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionCard(
                    title: 'Planlı işler listesi',
                    icon: Icons.event_note_outlined,
                    onCopyYesterday: () => _copyFromYesterday({
                      DailyReportCopyField.nextDayPlan,
                    }),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _WorkNotesTile(
                          label: 'İnşaat işleri',
                          text: _planConstructionCtrl.text,
                          emptyHint: 'İnşaat kapsamında planlanan işler…',
                          onEdit: () => _editWorkNotes(
                            title: 'İnşaat işleri',
                            hint: 'İnşaat kapsamında planlanan işler…',
                            target: _planConstructionCtrl,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _WorkNotesTile(
                          label: 'Elektrik işleri',
                          text: _planElectricalCtrl.text,
                          emptyHint: 'Elektrik kapsamında planlanan işler…',
                          onEdit: () => _editWorkNotes(
                            title: 'Elektrik işleri',
                            hint: 'Elektrik kapsamında planlanan işler…',
                            target: _planElectricalCtrl,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _WorkNotesTile(
                          label: 'Mekanik işler',
                          text: _planMechanicalCtrl.text,
                          emptyHint: 'Mekanik kapsamında planlanan işler…',
                          onEdit: () => _editWorkNotes(
                            title: 'Mekanik işler',
                            hint: 'Mekanik kapsamında planlanan işler…',
                            target: _planMechanicalCtrl,
                          ),
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
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () =>
                                            _openFullscreenPhoto(ph.dataBase64),
                                        borderRadius: AppRadii.sm,
                                        child: ClipRRect(
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
                                              child: const Icon(
                                                Icons.broken_image,
                                              ),
                                            ),
                                          ),
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
                    onCopyYesterday: () => _copyFromYesterday({
                      DailyReportCopyField.orderedMaterials,
                    }),
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
                    onCopyYesterday: () => _copyFromYesterday({
                      DailyReportCopyField.machines,
                    }),
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
                    onCopyYesterday: () => _copyFromYesterday({
                      DailyReportCopyField.vehicles,
                    }),
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
                ],
              ),
            ),
            ] else if (_viewMode == _ReportViewMode.weekly)
              Expanded(
                child: WeeklyReportView(
                  projectId: project.id,
                  anchorDate: date,
                  onAnchorChanged: (d) {
                    ref.read(dailyReportSelectedDateProvider.notifier).state =
                        d;
                  },
                  onOpenDaily: _openDailyDate,
                ),
              )
            else
              Expanded(
                child: MonthlyReportView(
                  projectId: project.id,
                  anchorDate: date,
                  onAnchorChanged: (d) {
                    ref.read(dailyReportSelectedDateProvider.notifier).state =
                        d;
                  },
                  onOpenDaily: _openDailyDate,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WorkNotesTile extends StatelessWidget {
  const _WorkNotesTile({
    required this.label,
    required this.text,
    required this.emptyHint,
    required this.onEdit,
    this.syncedCaptions = const [],
  });

  final String label;
  final String text;
  final String emptyHint;
  final VoidCallback onEdit;
  final List<String> syncedCaptions;

  @override
  Widget build(BuildContext context) {
    final trimmed = text.trim();
    final empty = trimmed.isEmpty;
    final preview = empty
        ? emptyHint
        : (trimmed.length > 220 ? '${trimmed.substring(0, 220)}…' : trimmed);

    // Kart yüzeyi: chrome Theme kapanmasın — mürekkep cardText* / kart teması.
    return Theme(
      data: SJCard.cardContrastTheme(Theme.of(context)),
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Material(
            color: AppColors.cardSurface,
            borderRadius: AppRadii.md,
            child: InkWell(
              onTap: onEdit,
              borderRadius: AppRadii.md,
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: AppRadii.md,
                  border: Border.all(
                    color: AppColors.cardBorder.withValues(alpha: 0.7),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: _cardInk(
                                theme.textTheme.labelLarge,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Düzenle',
                            onPressed: onEdit,
                            icon: Icon(
                              Icons.edit_note_outlined,
                              size: 22,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      Text(
                        preview,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: _cardInk(
                          theme.textTheme.bodyMedium,
                          color: empty
                              ? AppColors.cardTextSecondary
                              : AppColors.cardTextPrimary,
                          fontStyle: empty ? FontStyle.italic : null,
                        ),
                      ),
                      if (syncedCaptions.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Fotoğraflardan ${syncedCaptions.length} açıklama hazır',
                          style: _cardInk(
                            theme.textTheme.labelSmall,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
    this.onCopyYesterday,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onCopyYesterday;

  @override
  Widget build(BuildContext context) {
    return DailyReportCollapsibleSection(
      icon: icon,
      title: title,
      trailing: trailing,
      onCopyYesterday: onCopyYesterday,
      child: child,
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
    this.onCopyYesterday,
  });

  final String title;
  final IconData icon;
  final VoidCallback onAdd;
  final VoidCallback? onCopyYesterday;
  final String empty;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: title,
      icon: icon,
      onCopyYesterday: onCopyYesterday,
      trailing: IconButton(
        tooltip: 'Ekle',
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
