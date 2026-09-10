import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../../domain/program_item.dart';
import 'program_interop.dart';

/// MS Project'in Excel içe aktarım sihirbazının kendiliğinden eşlediği sayfa
/// adı. Sayfa adı ve başlıklar Project alan adlarıyla birebir yazılır.
const _taskSheet = 'Task_Table';
const _summarySheet = 'Ozet';

/// Sırası bozulmaması gereken başlık satırı. Şantiye adı `Text2` alanında
/// taşınır; Project bunu kendi Text2 sütununa eşler.
const _headers = <String>[
  'ID',
  'Name',
  'Duration',
  'Start',
  'Finish',
  '% Complete',
  'Resource Names',
  'Predecessors',
  'Outline Level',
  'WBS',
  'Milestone',
  'Text1',
  'Text2',
  'Notes',
  'Number1',
  'Actual Start',
  'Actual Finish',
  'Actual Duration',
  'Remaining Duration',
  'Actual Work',
  'Remaining Work',
];

/// Program faaliyetlerini `.xlsx` dosyasına yazar ve aynı düzeni geri okur.
class ProgramExcelCodec {
  const ProgramExcelCodec();

  Uint8List encode(List<ProgramItem> items, {DateTime? today}) {
    final book = Excel.createExcel();
    book.rename(book.getDefaultSheet()!, _taskSheet);
    final sheet = book[_taskSheet];

    for (var column = 0; column < _headers.length; column++) {
      _write(sheet, column, 0, TextCellValue(_headers[column]));
    }

    final sorted = [...items]
      ..sort((a, b) {
        final bySite = a.santiyeId.compareTo(b.santiyeId);
        return bySite != 0 ? bySite : a.startDate.compareTo(b.startDate);
      });

    for (var index = 0; index < sorted.length; index++) {
      final item = sorted[index];
      final row = index + 1;
      final values = <CellValue?>[
        IntCellValue(index + 1),
        TextCellValue(item.name),
        IntCellValue(item.isMilestone ? 0 : item.calculatedDays),
        _date(item.startDate),
        _date(item.endDate),
        IntCellValue(item.progress),
        TextCellValue(item.responsible),
        TextCellValue(item.predecessors ?? ''),
        IntCellValue(item.outlineLevel),
        TextCellValue(item.wbs ?? '${index + 1}'),
        TextCellValue(item.isMilestone ? 'Yes' : 'No'),
        TextCellValue(item.effectiveStatus(today: today).label),
        TextCellValue(item.santiyeId),
        TextCellValue(item.notes ?? ''),
        IntCellValue(item.plannedCrew < 1 ? 1 : item.plannedCrew),
        item.actualStart == null ? null : _date(item.actualStart!),
        item.actualFinish == null ? null : _date(item.actualFinish!),
        IntCellValue(item.actualDuration ?? 0),
        IntCellValue(item.remainingDuration ?? item.calculatedDays),
        IntCellValue(item.actualWork ?? 0),
        IntCellValue(item.remainingWork ?? item.plannedManDays),
      ];
      for (var column = 0; column < values.length; column++) {
        _write(sheet, column, row, values[column]);
      }
    }

    _writeSummary(book, sorted, today);

    final bytes = book.encode();
    if (bytes == null) {
      throw const ProgramImportException('Excel dosyası oluşturulamadı.');
    }
    return Uint8List.fromList(bytes);
  }

  /// `.xlsx` dosyasını okur. Başlık adları Türkçe ya da Project alan adlarıyla
  /// yazılmış olabilir; sütun sırası önemsizdir.
  ProgramImportResult decode(
    Uint8List bytes, {
    required String fallbackSite,
    DateTime? today,
  }) {
    final Excel book;
    try {
      book = Excel.decodeBytes(bytes);
    } catch (error) {
      throw ProgramImportException(
        'Excel dosyası okunamadı. Dosya .xlsx biçiminde mi? ($error)',
      );
    }

    final sheet = _pickSheet(book);
    final rows = sheet.rows.where(_hasContent).toList(growable: false);
    if (rows.length < 2) {
      throw const ProgramImportException(
        'Sayfada başlık satırının altında veri yok.',
      );
    }

    final columns = _mapColumns(rows.first);
    if (!columns.containsKey(_Field.name)) {
      throw const ProgramImportException(
        'Faaliyet adı sütunu bulunamadı. Başlık satırında "Name" ya da '
        '"Faaliyet" yazan bir sütun olmalı.',
      );
    }
    if (!columns.containsKey(_Field.start)) {
      throw const ProgramImportException(
        'Başlangıç tarihi sütunu bulunamadı. Başlık satırında "Start" ya da '
        '"Başlangıç" yazan bir sütun olmalı.',
      );
    }

    final warnings = <String>[];
    final items = <ProgramItem>[];

    for (var index = 1; index < rows.length; index++) {
      final row = rows[index];
      final excelRow = index + 1;
      final name = _string(row, columns[_Field.name]);
      if (name.isEmpty) continue;

      final start = parseInteropDate(_raw(row, columns[_Field.start]));
      if (start == null) {
        warnings.add('$excelRow. satır: "$name" başlangıç tarihi okunamadı.');
        continue;
      }

      final outlineLevel = _int(row, columns[_Field.outlineLevel]) ?? 1;
      final isMilestone = _bool(row, columns[_Field.milestone]);
      final duration = _int(row, columns[_Field.duration]);
      var end = parseInteropDate(_raw(row, columns[_Field.finish]));
      if (end == null || end.isBefore(start)) {
        end = start.add(
          Duration(
            days: isMilestone ? 0 : ((duration ?? 1) - 1).clamp(0, 3650),
          ),
        );
        if (!isMilestone) {
          warnings.add(
            '$excelRow. satır: "$name" bitişi süreden hesaplandı '
            '(${trDate(end)}).',
          );
        }
      }

      final progress = normalizeProgress(_num(row, columns[_Field.progress]));
      final site = _string(row, columns[_Field.site]);
      final resolvedSite = site.isEmpty ? fallbackSite : site;
      final label = statusFromLabel(_string(row, columns[_Field.status]));
      final derived = statusFromProgress(
        progress: progress,
        startDate: start,
        endDate: end,
        today: today,
      );

      items.add(
        ProgramItem(
          id: interopItemId(resolvedSite, _int(row, columns[_Field.id]) ?? index),
          santiyeId: resolvedSite,
          name: name,
          startDate: start,
          endDate: end,
          plannedDays: duration == null || duration <= 0 ? null : duration,
          plannedCrew: (_int(row, columns[_Field.crew]) ?? 1).clamp(1, 200),
          progress: progress,
          status: label ?? derived,
          isStatusManual: label != null && label != derived,
          responsible: _string(row, columns[_Field.responsible]),
          notes: _optional(row, columns[_Field.notes]),
          wbs: _optional(row, columns[_Field.wbs]),
          outlineLevel: outlineLevel < 1 ? 1 : outlineLevel,
          isMilestone: isMilestone,
          predecessors: _optional(row, columns[_Field.predecessors]),
          actualStart: parseInteropDate(_raw(row, columns[_Field.actualStart])),
          actualFinish: parseInteropDate(_raw(row, columns[_Field.actualFinish])),
          actualDuration: _int(row, columns[_Field.actualDuration]),
          remainingDuration: _int(row, columns[_Field.remainingDuration]),
          actualWork: _int(row, columns[_Field.actualWork]),
          remainingWork: _int(row, columns[_Field.remainingWork]),
        ),
      );
    }

    if (items.isEmpty) {
      throw const ProgramImportException(
        'Sayfada faaliyete çevrilebilecek satır bulunamadı.',
      );
    }
    return ProgramImportResult(items: items, warnings: warnings);
  }

  // --- yazma ---------------------------------------------------------------

  void _writeSummary(Excel book, List<ProgramItem> items, DateTime? today) {
    final sheet = book[_summarySheet];
    _write(sheet, 0, 0, TextCellValue('ŞantiJET İş Programı'));
    _write(sheet, 0, 1, TextCellValue('Faaliyet sayısı'));
    _write(sheet, 1, 1, IntCellValue(items.length));

    final delayed = items
        .where(
          (item) => item.effectiveStatus(today: today) == ProgramStatus.delayed,
        )
        .length;
    _write(sheet, 0, 2, TextCellValue('Geciken faaliyet'));
    _write(sheet, 1, 2, IntCellValue(delayed));

    final average = items.isEmpty
        ? 0
        : items.fold<int>(0, (sum, item) => sum + item.progress) ~/ items.length;
    _write(sheet, 0, 3, TextCellValue('Ortalama ilerleme (%)'));
    _write(sheet, 1, 3, IntCellValue(average));

    _write(sheet, 0, 5, TextCellValue('Şantiye'));
    _write(sheet, 1, 5, TextCellValue('Faaliyet'));
    final sites = <String, int>{};
    for (final item in items) {
      sites[item.santiyeId] = (sites[item.santiyeId] ?? 0) + 1;
    }
    var row = 6;
    for (final entry in sites.entries) {
      _write(sheet, 0, row, TextCellValue(entry.key));
      _write(sheet, 1, row, IntCellValue(entry.value));
      row++;
    }
  }

  void _write(Sheet sheet, int column, int row, CellValue? value) => sheet
      .cell(CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row))
      .value = value;

  DateCellValue _date(DateTime value) =>
      DateCellValue(year: value.year, month: value.month, day: value.day);

  // --- okuma ---------------------------------------------------------------

  Sheet _pickSheet(Excel book) {
    final preferred = book.tables[_taskSheet];
    if (preferred != null) return preferred;
    for (final entry in book.tables.entries) {
      if (entry.key == _summarySheet) continue;
      if (entry.value.rows.where(_hasContent).length >= 2) return entry.value;
    }
    throw const ProgramImportException('Dosyada dolu bir sayfa bulunamadı.');
  }

  bool _hasContent(List<Data?> row) =>
      row.any((cell) => _cellText(cell).isNotEmpty);

  Map<_Field, int> _mapColumns(List<Data?> header) {
    final columns = <_Field, int>{};
    for (var index = 0; index < header.length; index++) {
      final key = _normalizeHeader(_cellText(header[index]));
      if (key.isEmpty) continue;
      final field = _fieldAliases[key];
      if (field != null) columns.putIfAbsent(field, () => index);
    }
    return columns;
  }

  String _normalizeHeader(String raw) {
    const from = 'çğıöşüâîû';
    const to = 'cgiosuaiu';
    var text = raw.toLowerCase().trim();
    for (var index = 0; index < from.length; index++) {
      text = text.replaceAll(from[index], to[index]);
    }
    text = text.replaceAll('i̇', 'i');
    return text.replaceAll(RegExp(r'[^a-z0-9%]'), '');
  }

  String _cellText(Data? cell) {
    final value = cell?.value;
    if (value == null) return '';
    if (value is TextCellValue) return value.value.text?.trim() ?? '';
    if (value is DateCellValue) {
      return value.asDateTimeLocal().toIso8601String();
    }
    if (value is DateTimeCellValue) {
      return value.asDateTimeLocal().toIso8601String();
    }
    if (value is IntCellValue) return '${value.value}';
    if (value is DoubleCellValue) return '${value.value}';
    if (value is BoolCellValue) return value.value ? 'true' : 'false';
    return value.toString().trim();
  }

  String? _raw(List<Data?> row, int? column) {
    if (column == null || column >= row.length) return null;
    final text = _cellText(row[column]);
    return text.isEmpty ? null : text;
  }

  String _string(List<Data?> row, int? column) => _raw(row, column) ?? '';

  String? _optional(List<Data?> row, int? column) {
    final text = _raw(row, column);
    return text == null || text.isEmpty ? null : text;
  }

  num? _num(List<Data?> row, int? column) {
    final text = _raw(row, column);
    if (text == null) return null;
    final cleaned = text.replaceAll('%', '').replaceAll(',', '.').trim();
    return num.tryParse(cleaned);
  }

  int? _int(List<Data?> row, int? column) {
    final value = _num(row, column);
    return value?.round();
  }

  bool _bool(List<Data?> row, int? column) {
    final text = _raw(row, column)?.toLowerCase().trim();
    if (text == null) return false;
    return text == '1' ||
        text == 'true' ||
        text == 'yes' ||
        text == 'evet' ||
        text == 'x';
  }
}

enum _Field {
  id,
  name,
  duration,
  start,
  finish,
  progress,
  responsible,
  predecessors,
  outlineLevel,
  wbs,
  milestone,
  status,
  site,
  notes,
  crew,
  actualStart,
  actualFinish,
  actualDuration,
  remainingDuration,
  actualWork,
  remainingWork,
}

/// Excel başlıklarının Türkçe ve Project karşılıkları.
const _fieldAliases = <String, _Field>{
  'id': _Field.id,
  'no': _Field.id,
  'sira': _Field.id,
  'uid': _Field.id,
  'name': _Field.name,
  'taskname': _Field.name,
  'faaliyet': _Field.name,
  'faaliyetadi': _Field.name,
  'gorev': _Field.name,
  'gorevadi': _Field.name,
  'is': _Field.name,
  'duration': _Field.duration,
  'sure': _Field.duration,
  'gun': _Field.duration,
  'planlanangun': _Field.duration,
  'start': _Field.start,
  'startdate': _Field.start,
  'baslangic': _Field.start,
  'baslangictarihi': _Field.start,
  'finish': _Field.finish,
  'finishdate': _Field.finish,
  'end': _Field.finish,
  'bitis': _Field.finish,
  'bitistarihi': _Field.finish,
  '%complete': _Field.progress,
  'percentcomplete': _Field.progress,
  'complete': _Field.progress,
  'ilerleme': _Field.progress,
  'gerceklesme': _Field.progress,
  'tamamlanma': _Field.progress,
  'resourcenames': _Field.responsible,
  'resource': _Field.responsible,
  'sorumlu': _Field.responsible,
  'ekip': _Field.responsible,
  'predecessors': _Field.predecessors,
  'oncul': _Field.predecessors,
  'oncelikli': _Field.predecessors,
  'outlinelevel': _Field.outlineLevel,
  'level': _Field.outlineLevel,
  'duzey': _Field.outlineLevel,
  'wbs': _Field.wbs,
  'wbscode': _Field.wbs,
  'isbolumu': _Field.wbs,
  'milestone': _Field.milestone,
  'kilometretasi': _Field.milestone,
  'text1': _Field.status,
  'status': _Field.status,
  'durum': _Field.status,
  'text2': _Field.site,
  'site': _Field.site,
  'santiye': _Field.site,
  'proje': _Field.site,
  'notes': _Field.notes,
  'note': _Field.notes,
  'not': _Field.notes,
  'aciklama': _Field.notes,
  'number1': _Field.crew,
  'crew': _Field.crew,
  'units': _Field.crew,
  'adam': _Field.crew,
  'ekipsayisi': _Field.crew,
  'actualstart': _Field.actualStart,
  'fiilibaslangic': _Field.actualStart,
  'actualfinish': _Field.actualFinish,
  'fiilibitis': _Field.actualFinish,
  'actualduration': _Field.actualDuration,
  'fiilisure': _Field.actualDuration,
  'remainingduration': _Field.remainingDuration,
  'kalansure': _Field.remainingDuration,
  'actualwork': _Field.actualWork,
  'fiiliis': _Field.actualWork,
  'remainingwork': _Field.remainingWork,
  'kalanis': _Field.remainingWork,
};
