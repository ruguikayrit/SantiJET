import 'dart:convert';
import 'dart:typed_data';

import 'package:xml/xml.dart';

import '../../domain/program_item.dart';
import 'program_interop.dart';

/// MS Project'in içe/dışa aktarımda kullandığı MSPDI ad alanı.
const _mspdiNamespace = 'http://schemas.microsoft.com/project';

/// Faaliyetin gün süresini `Duration` alanına çeviren gün uzunluğu 8 saattir.
const _dayStart = '08:00:00';
const _dayFinish = '17:00:00';

/// Program dosyası, günün her gününü çalışma günü sayan tek bir takvim yazar.
/// Böylece MS Project'in yeniden hesapladığı bitiş tarihleri uygulamada
/// görünen tarihlerle birebir örtüşür.
const _calendarName = 'ŞantiJET Saha Takvimi';
const _calendarUid = 1;

/// `ProgramItem` listesini MS Project'te açılıp yeniden hesaplanabilen
/// MSPDI (`.xml`) dosyasına yazar.
class MsProjectXmlCodec {
  const MsProjectXmlCodec();

  Uint8List encode(
    List<ProgramItem> items, {
    required String projectName,
    DateTime? now,
  }) {
    final createdAt = now ?? DateTime.now();
    final rows = _buildRows(items);
    final resources = _buildResources(items);

    final projectStart = rows.isEmpty
        ? dateOnly(createdAt)
        : rows.map((row) => row.start).reduce((a, b) => a.isBefore(b) ? a : b);
    final projectFinish = rows.isEmpty
        ? dateOnly(createdAt)
        : rows.map((row) => row.finish).reduce((a, b) => a.isAfter(b) ? a : b);

    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8" standalone="yes"');
    builder.element(
      'Project',
      attributes: {'xmlns': _mspdiNamespace},
      nest: () {
        _text(builder, 'SaveVersion', '14');
        _text(builder, 'Name', '$projectName.xml');
        _text(builder, 'Title', projectName);
        _text(builder, 'Company', 'ŞantiJET');
        _text(builder, 'Author', 'ŞantiJET İş Programı');
        _text(builder, 'CreationDate', _dateTime(createdAt, _dayStart));
        _text(builder, 'ScheduleFromStart', '1');
        _text(builder, 'StartDate', _dateTime(projectStart, _dayStart));
        _text(builder, 'FinishDate', _dateTime(projectFinish, _dayFinish));
        _text(builder, 'FYStartDate', '1');
        _text(builder, 'CriticalSlackLimit', '0');
        _text(builder, 'CurrencyDigits', '2');
        _text(builder, 'CurrencySymbol', 'TL');
        _text(builder, 'CurrencyCode', 'TRY');
        _text(builder, 'CurrencySymbolPosition', '1');
        _text(builder, 'CalendarUID', '$_calendarUid');
        _text(builder, 'DefaultStartTime', _dayStart);
        _text(builder, 'DefaultFinishTime', _dayFinish);
        _text(builder, 'MinutesPerDay', '$minutesPerWorkDay');
        _text(builder, 'MinutesPerWeek', '${minutesPerWorkDay * 7}');
        _text(builder, 'DaysPerMonth', '30');
        _text(builder, 'DefaultTaskType', '0');
        _text(builder, 'DefaultFixedCostAccrual', '3');
        _text(builder, 'DurationFormat', '7');
        _text(builder, 'WorkFormat', '2');
        _text(builder, 'EditableActualCosts', '0');
        _text(builder, 'HonorConstraints', '1');
        _text(builder, 'EarnedValueMethod', '0');
        _text(builder, 'InsertedProjectsLikeSummary', '1');
        _text(builder, 'MultipleCriticalPaths', '0');
        _text(builder, 'NewTasksEffortDriven', '0');
        _text(builder, 'NewTasksEstimated', '0');
        _text(builder, 'SplitsInProgressTasks', '1');
        _text(builder, 'SpreadActualCost', '0');
        _text(builder, 'SpreadPercentComplete', '0');
        _text(builder, 'TaskUpdatesResource', '1');
        _text(builder, 'FiscalYearStart', '0');
        _text(builder, 'WeekStartDay', '1');
        _text(builder, 'MoveCompletedEndsBack', '0');
        _text(builder, 'MoveRemainingStartsBack', '0');
        _text(builder, 'MoveRemainingStartsForward', '0');
        _text(builder, 'MoveCompletedEndsForward', '0');
        _text(builder, 'BaselineForEarnedValue', '0');
        _text(builder, 'AutoAddNewResourcesAndTasks', '1');
        _text(builder, 'CurrentDate', _dateTime(createdAt, _dayStart));
        _text(builder, 'MicrosoftProjectServerURL', '0');
        _text(builder, 'Autolink', '0');
        _text(builder, 'NewTaskStartDate', '0');
        _text(builder, 'DefaultTaskEVMethod', '0');
        _text(builder, 'ProjectExternallyEdited', '0');
        _text(builder, 'ActualsInSync', '1');
        _text(builder, 'RemoveFileProperties', '0');
        _text(builder, 'AdminProject', '0');

        _writeCalendars(builder);
        _writeTasks(builder, rows);
        _writeResources(builder, resources);
        _writeAssignments(builder, rows, resources);
      },
    );

    final xml = builder.buildDocument().toXmlString(pretty: true, indent: '  ');
    return Uint8List.fromList(utf8.encode(xml));
  }

  /// MSPDI dosyasını okuyup uygulama faaliyetlerine çevirir. Özet görevler,
  /// boş satırlar ve proje kök görevi atlanır; öncül metni korunur.
  ProgramImportResult decode(
    Uint8List bytes, {
    required String fallbackSite,
    DateTime? today,
  }) {
    final XmlDocument document;
    try {
      document = XmlDocument.parse(utf8.decode(bytes, allowMalformed: true));
    } on XmlException catch (error) {
      throw ProgramImportException(
        'Dosya geçerli bir XML değil: ${error.message}',
      );
    }

    final root = document.rootElement;
    if (root.name.local != 'Project') {
      throw const ProgramImportException(
        'Bu dosya MS Project XML (MSPDI) değil. Project içinden '
        '"Farklı Kaydet → XML" ile kaydedilmiş bir dosya seçin.',
      );
    }

    final projectName = _child(root, 'Title') ?? _child(root, 'Name');
    final taskElements = root
        .findAllElements('Task', namespace: '*')
        .toList(growable: false);
    if (taskElements.isEmpty) {
      throw const ProgramImportException(
        'Dosyada faaliyet bulunamadı. Project dosyasında görev satırı yok.',
      );
    }

    final resourceNames = _readResourceNames(root);
    final assignments = _readAssignments(root);
    final summaryNames = <int, String>{};
    final warnings = <String>[];
    final items = <ProgramItem>[];
    var skippedSummaries = 0;

    for (final task in taskElements) {
      final uid = int.tryParse(_child(task, 'UID') ?? '');
      if (uid == null) continue;
      if (_flag(task, 'IsNull')) continue;

      final name = (_child(task, 'Name') ?? '').trim();
      final outlineLevel = int.tryParse(_child(task, 'OutlineLevel') ?? '') ?? 1;

      if (_flag(task, 'Summary') || outlineLevel == 0) {
        if (name.isNotEmpty) summaryNames[uid] = name;
        if (outlineLevel > 0) skippedSummaries++;
        continue;
      }
      if (name.isEmpty) {
        warnings.add('Adı olmayan bir görev (UID $uid) atlandı.');
        continue;
      }

      final start = parseInteropDate(_child(task, 'Start'));
      final finish = parseInteropDate(_child(task, 'Finish'));
      if (start == null) {
        warnings.add('"$name" görevinin başlangıç tarihi okunamadı, atlandı.');
        continue;
      }

      final durationDays = parseMsProjectDurationDays(_child(task, 'Duration'));
      final isMilestone = _flag(task, 'Milestone');
      final end = finish != null && !finish.isBefore(start)
          ? finish
          : start.add(
              Duration(
                days: isMilestone ? 0 : ((durationDays ?? 1) - 1).clamp(0, 3650),
              ),
            );

      final progress = normalizeProgress(
        int.tryParse(_child(task, 'PercentComplete') ?? ''),
      );
      final site = _siteFor(task, summaryNames, fallbackSite);

      items.add(
        ProgramItem(
          id: interopItemId(site, uid),
          santiyeId: site,
          name: name,
          startDate: start,
          endDate: end,
          plannedDays: durationDays == null || durationDays <= 0
              ? null
              : durationDays,
          progress: progress,
          status: statusFromProgress(
            progress: progress,
            startDate: start,
            endDate: end,
            today: today,
          ),
          responsible: _responsibleFor(uid, assignments, resourceNames),
          notes: _notes(task),
          wbs: _child(task, 'WBS'),
          outlineLevel: outlineLevel,
          isMilestone: isMilestone,
          msProjectUid: uid,
          predecessors: _predecessorText(task),
        ),
      );
    }

    if (items.isEmpty) {
      throw const ProgramImportException(
        'Dosyadaki görevlerden hiçbiri faaliyete çevrilemedi. '
        'Görevlerin ad ve başlangıç tarihi taşıdığından emin olun.',
      );
    }
    if (skippedSummaries > 0) {
      warnings.add(
        '$skippedSummaries özet görev şantiye başlığı olarak kullanıldı.',
      );
    }

    return ProgramImportResult(
      items: items,
      warnings: warnings,
      projectName: projectName,
    );
  }

  // --- yazma yardımcıları ---------------------------------------------------

  void _writeCalendars(XmlBuilder builder) {
    builder.element(
      'Calendars',
      nest: () => builder.element(
        'Calendar',
        nest: () {
          _text(builder, 'UID', '$_calendarUid');
          _text(builder, 'Name', _calendarName);
          _text(builder, 'IsBaseCalendar', '1');
          _text(builder, 'BaseCalendarUID', '-1');
          builder.element(
            'WeekDays',
            nest: () {
              for (var dayType = 1; dayType <= 7; dayType++) {
                builder.element(
                  'WeekDay',
                  nest: () {
                    _text(builder, 'DayType', '$dayType');
                    _text(builder, 'DayWorking', '1');
                    builder.element(
                      'WorkingTimes',
                      nest: () {
                        _workingTime(builder, '08:00:00', '12:00:00');
                        _workingTime(builder, '13:00:00', '17:00:00');
                      },
                    );
                  },
                );
              }
            },
          );
        },
      ),
    );
  }

  void _workingTime(XmlBuilder builder, String from, String to) {
    builder.element(
      'WorkingTime',
      nest: () {
        _text(builder, 'FromTime', from);
        _text(builder, 'ToTime', to);
      },
    );
  }

  void _writeTasks(XmlBuilder builder, List<_TaskRow> rows) {
    builder.element(
      'Tasks',
      nest: () {
        for (final row in rows) {
          builder.element(
            'Task',
            nest: () {
              _text(builder, 'UID', '${row.uid}');
              _text(builder, 'ID', '${row.uid}');
              _text(builder, 'Name', row.name);
              _text(builder, 'Active', '1');
              _text(builder, 'Manual', '0');
              _text(builder, 'Type', '0');
              _text(builder, 'IsNull', '0');
              _text(builder, 'WBS', row.wbs);
              _text(builder, 'OutlineNumber', row.wbs);
              _text(builder, 'OutlineLevel', '${row.outlineLevel}');
              _text(builder, 'Priority', '500');
              _text(builder, 'Start', _dateTime(row.start, _dayStart));
              _text(builder, 'Finish', _dateTime(row.finish, _dayFinish));
              _text(builder, 'Duration', msProjectDuration(row.durationDays));
              _text(builder, 'DurationFormat', '7');
              _text(builder, 'Estimated', '0');
              _text(builder, 'Milestone', row.isMilestone ? '1' : '0');
              _text(builder, 'Summary', row.isSummary ? '1' : '0');
              _text(builder, 'PercentComplete', '${row.progress}');
              _text(builder, 'PercentWorkComplete', '${row.progress}');
              if (row.isSummary) {
                // Özet görevin tarihleri alt faaliyetlerden gelir.
                _text(builder, 'ConstraintType', '0');
              } else {
                // "En erken şu tarihte başla" kısıtı, Project yeniden
                // hesaplarken planlanan başlangıcı korur.
                _text(builder, 'ConstraintType', '4');
                _text(builder, 'CalendarUID', '-1');
                _text(
                  builder,
                  'ConstraintDate',
                  _dateTime(row.start, _dayStart),
                );
              }
              if (row.notes != null && row.notes!.trim().isNotEmpty) {
                _text(builder, 'Notes', row.notes!.trim());
              }
              _writePredecessorLinks(builder, row, rows);
            },
          );
        }
      },
    );
  }

  /// İçe aktarılan öncül metnini MSPDI bağlarına geri yazar. Eski UID'ler
  /// bu dosyadaki yeni görev numaralarına çevrilir; eşleşmeyen bağ atlanır.
  void _writePredecessorLinks(
    XmlBuilder builder,
    _TaskRow row,
    List<_TaskRow> rows,
  ) {
    if (row.isSummary) return;
    final refs = parsePredecessorText(row.predecessors);
    if (refs.isEmpty) return;

    final uidByOriginal = <int, int>{
      for (final other in rows)
        if (other.originalUid != null) other.originalUid!: other.uid,
    };
    final liveUids = {for (final other in rows) other.uid};

    for (final ref in refs) {
      final target = uidByOriginal[ref.uid] ??
          (liveUids.contains(ref.uid) ? ref.uid : null);
      if (target == null || target == row.uid) continue;
      builder.element(
        'PredecessorLink',
        nest: () {
          _text(builder, 'PredecessorUID', '$target');
          _text(builder, 'Type', '${ref.typeCode}');
          _text(builder, 'LinkLag', '${ref.lagTenthsOfMinutes}');
          _text(builder, 'LagFormat', '7');
        },
      );
    }
  }

  void _writeResources(XmlBuilder builder, List<String> resources) {
    builder.element(
      'Resources',
      nest: () {
        for (var index = 0; index < resources.length; index++) {
          builder.element(
            'Resource',
            nest: () {
              _text(builder, 'UID', '${index + 1}');
              _text(builder, 'ID', '${index + 1}');
              _text(builder, 'Name', resources[index]);
              _text(builder, 'Type', '1');
              _text(builder, 'IsNull', '0');
              _text(builder, 'MaxUnits', '1');
              _text(builder, 'CanLevel', '1');
              _text(builder, 'AccrueAt', '3');
            },
          );
        }
      },
    );
  }

  void _writeAssignments(
    XmlBuilder builder,
    List<_TaskRow> rows,
    List<String> resources,
  ) {
    builder.element(
      'Assignments',
      nest: () {
        var assignmentUid = 1;
        for (final row in rows) {
          final resourceIndex = row.responsible == null
              ? -1
              : resources.indexOf(row.responsible!);
          if (row.isSummary || resourceIndex < 0) continue;

          final totalMinutes = row.durationDays * minutesPerWorkDay;
          final actualMinutes = (totalMinutes * row.progress / 100).round();
          builder.element(
            'Assignment',
            nest: () {
              _text(builder, 'UID', '${assignmentUid++}');
              _text(builder, 'TaskUID', '${row.uid}');
              _text(builder, 'ResourceUID', '${resourceIndex + 1}');
              _text(builder, 'PercentWorkComplete', '${row.progress}');
              _text(builder, 'ActualCost', '0');
              _text(builder, 'ActualWork', _minutes(actualMinutes));
              _text(builder, 'Cost', '0');
              _text(builder, 'Delay', '0');
              _text(builder, 'Finish', _dateTime(row.finish, _dayFinish));
              _text(builder, 'Milestone', row.isMilestone ? '1' : '0');
              _text(builder, 'PeakUnits', '1');
              _text(builder, 'RegularWork', _minutes(totalMinutes));
              _text(builder, 'RemainingCost', '0');
              _text(
                builder,
                'RemainingWork',
                _minutes(totalMinutes - actualMinutes),
              );
              _text(builder, 'Start', _dateTime(row.start, _dayStart));
              _text(builder, 'Units', '1');
              _text(builder, 'Work', _minutes(totalMinutes));
              _text(builder, 'WorkContour', '0');
            },
          );
        }
      },
    );
  }

  /// Faaliyetleri şantiyeye göre gruplar; her şantiye bir özet görev olur ve
  /// altındaki faaliyetler ikinci anahat düzeyine yazılır.
  List<_TaskRow> _buildRows(List<ProgramItem> items) {
    final groups = <String, List<ProgramItem>>{};
    for (final item in items) {
      groups.putIfAbsent(item.santiyeId, () => []).add(item);
    }

    final rows = <_TaskRow>[];
    var uid = 1;
    var groupIndex = 0;

    for (final entry in groups.entries) {
      final children = [...entry.value]
        ..sort((a, b) => a.startDate.compareTo(b.startDate));
      groupIndex++;
      final start = children
          .map((item) => dateOnly(item.startDate))
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final finish = children
          .map((item) => dateOnly(item.endDate))
          .reduce((a, b) => a.isAfter(b) ? a : b);
      final weightedDays = children.fold<int>(
        0,
        (sum, item) => sum + item.calculatedDays,
      );
      final weightedProgress = weightedDays == 0
          ? 0
          : children.fold<int>(
                  0,
                  (sum, item) => sum + item.progress * item.calculatedDays,
                ) ~/
                weightedDays;

      rows.add(
        _TaskRow(
          uid: uid++,
          name: entry.key,
          wbs: '$groupIndex',
          outlineLevel: 1,
          start: start,
          finish: finish,
          durationDays: finish.difference(start).inDays + 1,
          progress: weightedProgress,
          isSummary: true,
        ),
      );

      for (var index = 0; index < children.length; index++) {
        final item = children[index];
        final itemStart = dateOnly(item.startDate);
        final itemFinish = dateOnly(item.endDate);
        rows.add(
          _TaskRow(
            uid: uid++,
            name: item.name,
            wbs: '$groupIndex.${index + 1}',
            outlineLevel: 2,
            start: itemStart,
            finish: item.isMilestone ? itemStart : itemFinish,
            durationDays: item.isMilestone ? 0 : item.calculatedDays,
            progress: item.progress,
            isMilestone: item.isMilestone,
            responsible: item.responsible.trim().isEmpty
                ? null
                : item.responsible.trim(),
            notes: item.notes,
            originalUid: item.msProjectUid,
            predecessors: item.predecessors,
          ),
        );
      }
    }
    return rows;
  }

  List<String> _buildResources(List<ProgramItem> items) {
    final names = <String>{};
    for (final item in items) {
      final name = item.responsible.trim();
      if (name.isNotEmpty) names.add(name);
    }
    return names.toList(growable: false);
  }

  // --- okuma yardımcıları --------------------------------------------------

  Map<int, String> _readResourceNames(XmlElement root) {
    final map = <int, String>{};
    for (final resource in root.findAllElements('Resource', namespace: '*')) {
      final uid = int.tryParse(_child(resource, 'UID') ?? '');
      final name = _child(resource, 'Name');
      if (uid != null && name != null && name.trim().isNotEmpty) {
        map[uid] = name.trim();
      }
    }
    return map;
  }

  Map<int, List<int>> _readAssignments(XmlElement root) {
    final map = <int, List<int>>{};
    for (final assignment in root.findAllElements(
      'Assignment',
      namespace: '*',
    )) {
      final taskUid = int.tryParse(_child(assignment, 'TaskUID') ?? '');
      final resourceUid = int.tryParse(_child(assignment, 'ResourceUID') ?? '');
      if (taskUid == null || resourceUid == null || resourceUid <= 0) continue;
      map.putIfAbsent(taskUid, () => []).add(resourceUid);
    }
    return map;
  }

  String _responsibleFor(
    int taskUid,
    Map<int, List<int>> assignments,
    Map<int, String> resourceNames,
  ) {
    final uids = assignments[taskUid];
    if (uids == null || uids.isEmpty) return '';
    return uids
        .map((uid) => resourceNames[uid])
        .whereType<String>()
        .toSet()
        .join(', ');
  }

  /// Faaliyetin şantiyesi, üstündeki özet görevin adıdır. Özet görev yoksa
  /// kullanıcının seçtiği varsayılan şantiye kullanılır.
  String _siteFor(
    XmlElement task,
    Map<int, String> summaryNames,
    String fallbackSite,
  ) {
    if (summaryNames.isEmpty) return fallbackSite;
    var previous = task.previousElementSibling;
    while (previous != null) {
      final uid = int.tryParse(_child(previous, 'UID') ?? '');
      if (uid != null && summaryNames.containsKey(uid)) {
        return summaryNames[uid]!;
      }
      previous = previous.previousElementSibling;
    }
    return fallbackSite;
  }

  String? _notes(XmlElement task) {
    final raw = _child(task, 'Notes') ?? _child(task, 'NotesText');
    if (raw == null) return null;
    final text = raw.trim();
    return text.isEmpty ? null : text;
  }

  /// `<PredecessorLink>` düğümlerini `4FS+2 gün` gibi okunur metne çevirir.
  /// Uygulama bu bağı hesaplamaz, yalnız dosyalar arasında taşır.
  String? _predecessorText(XmlElement task) {
    final links = task
        .findElements('PredecessorLink', namespace: '*')
        .toList(growable: false);
    if (links.isEmpty) return null;

    final parts = <String>[];
    for (final link in links) {
      final uid = _child(link, 'PredecessorUID');
      if (uid == null) continue;
      final type = int.tryParse(_child(link, 'Type') ?? '1') ?? 1;
      final lagDays =
          parseMsProjectDurationDays(_child(link, 'LinkLag')) ??
          _lagFromTenthsOfMinutes(_child(link, 'LinkLag'));
      final suffix = lagDays == null || lagDays == 0
          ? ''
          : '${lagDays > 0 ? '+' : ''}$lagDays gün';
      parts.add('$uid${_linkTypeLabel(type)}$suffix');
    }
    return parts.isEmpty ? null : parts.join('; ');
  }

  int? _lagFromTenthsOfMinutes(String? raw) {
    final minutes = int.tryParse(raw?.trim() ?? '');
    if (minutes == null) return null;
    return (minutes / 10 / minutesPerWorkDay).round();
  }

  /// MSPDI bağ türleri: 0 bitiş-bitiş, 1 bitiş-başlangıç, 2 başlangıç-bitiş,
  /// 3 başlangıç-başlangıç.
  String _linkTypeLabel(int type) => switch (type) {
    0 => 'FF',
    2 => 'SF',
    3 => 'SS',
    _ => 'FS',
  };

  // --- ortak yardımcılar ---------------------------------------------------

  void _text(XmlBuilder builder, String name, String value) =>
      builder.element(name, nest: () => builder.text(value));

  String _dateTime(DateTime date, String time) => '${isoDate(date)}T$time';

  String _minutes(int minutes) {
    final safe = minutes < 0 ? 0 : minutes;
    return 'PT${safe ~/ 60}H${safe % 60}M0S';
  }

  String? _child(XmlElement parent, String name) =>
      parent.getElement(name, namespace: '*')?.innerText;

  /// MSPDI mantıksal alanları `1`/`0` ya da `true`/`false` yazılabilir.
  bool _flag(XmlElement parent, String name) {
    final value = _child(parent, name)?.trim().toLowerCase();
    return value == '1' || value == 'true';
  }
}

/// MSPDI `Tasks` listesine yazılacak tek satır.
class _TaskRow {
  _TaskRow({
    required this.uid,
    required this.name,
    required this.wbs,
    required this.outlineLevel,
    required this.start,
    required this.finish,
    required this.durationDays,
    required this.progress,
    this.isSummary = false,
    this.isMilestone = false,
    this.responsible,
    this.notes,
    this.originalUid,
    this.predecessors,
  });

  final int uid;
  final String name;
  final String wbs;
  final int outlineLevel;
  final DateTime start;
  final DateTime finish;
  final int durationDays;
  final int progress;
  final bool isSummary;
  final bool isMilestone;
  final String? responsible;
  final String? notes;
  final int? originalUid;
  final String? predecessors;
}
