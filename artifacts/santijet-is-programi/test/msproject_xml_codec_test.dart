import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_is_programi/data/interop/msproject_xml_codec.dart';
import 'package:santijet_is_programi/data/interop/program_interop.dart';
import 'package:santijet_is_programi/data/interop/program_interop_service.dart';
import 'package:santijet_is_programi/domain/program_item.dart';
import 'package:xml/xml.dart';

const codec = MsProjectXmlCodec();
final today = DateTime(2026, 3, 10);

ProgramItem item({
  required String id,
  required String site,
  required String name,
  required DateTime start,
  required DateTime end,
  int progress = 0,
  String responsible = '',
  String? notes,
  bool isMilestone = false,
}) => ProgramItem(
  id: id,
  santiyeId: site,
  name: name,
  startDate: start,
  endDate: end,
  progress: progress,
  status: ProgramStatus.planned,
  responsible: responsible,
  notes: notes,
  isMilestone: isMilestone,
);

final sample = <ProgramItem>[
  item(
    id: 'a1',
    site: 'Merkez Şantiyesi',
    name: 'Hafriyat',
    start: DateTime(2026, 3, 2),
    end: DateTime(2026, 3, 11),
    progress: 100,
    responsible: 'Saha Ekibi',
    notes: 'Kot kontrolü yapıldı.',
  ),
  item(
    id: 'a2',
    site: 'Merkez Şantiyesi',
    name: 'Radye donatısı',
    start: DateTime(2026, 3, 12),
    end: DateTime(2026, 3, 21),
    progress: 40,
    responsible: 'Ahmet Usta',
  ),
  item(
    id: 'a3',
    site: 'Depo Şantiyesi',
    name: 'Çelik montaj başlangıcı',
    start: DateTime(2026, 4, 1),
    end: DateTime(2026, 4, 1),
    responsible: 'Montaj Ekibi',
    isMilestone: true,
  ),
];

XmlDocument encodeSample() => XmlDocument.parse(
  utf8.decode(codec.encode(sample, projectName: 'Test Programı', now: today)),
);

void main() {
  group('MSPDI yazımı', () {
    test('MS Project ad alanı ve sürümüyle yazılır', () {
      final root = encodeSample().rootElement;
      expect(root.name.local, 'Project');
      expect(
        root.getAttribute('xmlns'),
        'http://schemas.microsoft.com/project',
      );
      expect(root.getElement('SaveVersion')?.innerText, '14');
      expect(root.getElement('CalendarUID')?.innerText, '1');
      expect(root.getElement('MinutesPerDay')?.innerText, '480');
    });

    test('her şantiye için bir özet görev ve altına faaliyetler yazılır', () {
      final tasks = encodeSample()
          .rootElement
          .findAllElements('Task')
          .toList();

      // 2 şantiye özeti + 3 faaliyet.
      expect(tasks, hasLength(5));

      final summaries = tasks
          .where((task) => task.getElement('Summary')!.innerText == '1')
          .toList();
      expect(summaries, hasLength(2));
      expect(
        summaries.map((task) => task.getElement('Name')!.innerText),
        containsAll(['Merkez Şantiyesi', 'Depo Şantiyesi']),
      );
      for (final summary in summaries) {
        expect(summary.getElement('OutlineLevel')!.innerText, '1');
      }

      final activities = tasks
          .where((task) => task.getElement('Summary')!.innerText == '0')
          .toList();
      expect(activities, hasLength(3));
      for (final activity in activities) {
        expect(activity.getElement('OutlineLevel')!.innerText, '2');
        // Project'in planı bozmadan yeniden hesaplaması için
        // "En Erken Şu Tarihte Başla" kısıtı yazılır.
        expect(activity.getElement('ConstraintType')!.innerText, '4');
        expect(
          activity.getElement('ConstraintDate')!.innerText,
          activity.getElement('Start')!.innerText,
        );
      }
    });

    test('UID ve WBS kodları sıralı ve tekildir', () {
      final tasks = encodeSample()
          .rootElement
          .findAllElements('Task')
          .toList();
      final uids = tasks
          .map((task) => int.parse(task.getElement('UID')!.innerText))
          .toList();
      expect(uids, [1, 2, 3, 4, 5]);
      expect(
        tasks.map((task) => task.getElement('WBS')!.innerText),
        ['1', '1.1', '1.2', '2', '2.1'],
      );
    });

    test('süre gün sayısı kadar iş saati olarak yazılır', () {
      final tasks = encodeSample()
          .rootElement
          .findAllElements('Task')
          .toList();
      final hafriyat = tasks.firstWhere(
        (task) => task.getElement('Name')!.innerText == 'Hafriyat',
      );

      // 2–11 Mart arası 10 gün, günlük 8 saat.
      expect(hafriyat.getElement('Duration')!.innerText, 'PT80H0M0S');
      expect(hafriyat.getElement('Start')!.innerText, '2026-03-02T08:00:00');
      expect(hafriyat.getElement('Finish')!.innerText, '2026-03-11T17:00:00');
      expect(hafriyat.getElement('PercentComplete')!.innerText, '100');
    });

    test('kilometre taşı sıfır süreyle yazılır', () {
      final milestone = encodeSample()
          .rootElement
          .findAllElements('Task')
          .firstWhere(
            (task) =>
                task.getElement('Name')!.innerText ==
                'Çelik montaj başlangıcı',
          );
      expect(milestone.getElement('Milestone')!.innerText, '1');
      expect(milestone.getElement('Duration')!.innerText, 'PT0H0M0S');
      expect(
        milestone.getElement('Finish')!.innerText,
        '2026-04-01T17:00:00',
      );
    });

    test('takvim yedi günü de çalışma günü sayar', () {
      final weekDays = encodeSample()
          .rootElement
          .findAllElements('WeekDay')
          .toList();
      expect(weekDays, hasLength(7));
      for (final day in weekDays) {
        expect(day.getElement('DayWorking')!.innerText, '1');
        expect(day.findAllElements('WorkingTime'), hasLength(2));
      }
    });

    test('sorumlular kaynak ve atama olarak yazılır', () {
      final root = encodeSample().rootElement;
      final resources = root
          .findAllElements('Resource')
          .map((node) => node.getElement('Name')!.innerText)
          .toList();
      expect(resources, ['Saha Ekibi', 'Ahmet Usta', 'Montaj Ekibi']);

      // Kilometre taşı dahil üç faaliyetin üçünde de sorumlu var.
      final assignments = root.findAllElements('Assignment').toList();
      expect(assignments, hasLength(3));
      for (final assignment in assignments) {
        expect(assignment.getElement('Units')!.innerText, '1');
        expect(
          int.parse(assignment.getElement('ResourceUID')!.innerText),
          greaterThan(0),
        );
      }
    });

    test('öncül bağı yeniden yazıldığında Project UID’sine çevrilir', () {
      final source = [
        item(
          id: 'p1',
          site: 'A Blok',
          name: 'Kaba sıva',
          start: DateTime(2026, 3, 9),
          end: DateTime(2026, 3, 13),
          progress: 60,
        ).copyWith(msProjectUid: 10),
        item(
          id: 'p2',
          site: 'A Blok',
          name: 'Duvar örgüsü',
          start: DateTime(2026, 3, 16),
          end: DateTime(2026, 3, 20),
          progress: 25,
        ).copyWith(msProjectUid: 11, predecessors: '10FS+2 gün'),
      ];

      final document = XmlDocument.parse(
        utf8.decode(
          codec.encode(source, projectName: 'Bağ testi', now: today),
        ),
      );
      final duvar = document.rootElement.findAllElements('Task').firstWhere(
        (task) => task.getElement('Name')!.innerText == 'Duvar örgüsü',
      );
      final link = duvar.getElement('PredecessorLink')!;
      // Şantiye özeti UID 1, kaba sıva UID 2, duvar UID 3.
      expect(link.getElement('PredecessorUID')!.innerText, '2');
      expect(link.getElement('Type')!.innerText, '1');
      expect(link.getElement('LinkLag')!.innerText, '9600');
    });

    test('notlar taşınır', () {
      final hafriyat = encodeSample()
          .rootElement
          .findAllElements('Task')
          .firstWhere(
            (task) => task.getElement('Name')!.innerText == 'Hafriyat',
          );
      expect(hafriyat.getElement('Notes')!.innerText, 'Kot kontrolü yapıldı.');
    });
  });

  group('MSPDI okuması', () {
    test('yazılan dosya kayıpsız geri okunur', () {
      final decoded = codec.decode(
        codec.encode(sample, projectName: 'Test Programı', now: today),
        fallbackSite: 'Varsayılan',
        today: today,
      );

      expect(decoded.projectName, 'Test Programı');
      expect(decoded.items, hasLength(3));

      final hafriyat = decoded.items.firstWhere(
        (found) => found.name == 'Hafriyat',
      );
      expect(hafriyat.santiyeId, 'Merkez Şantiyesi');
      expect(hafriyat.startDate, DateTime(2026, 3, 2));
      expect(hafriyat.endDate, DateTime(2026, 3, 11));
      expect(hafriyat.calculatedDays, 10);
      expect(hafriyat.progress, 100);
      expect(hafriyat.responsible, 'Saha Ekibi');
      expect(hafriyat.notes, 'Kot kontrolü yapıldı.');
      expect(hafriyat.status, ProgramStatus.completed);
      expect(hafriyat.wbs, '1.1');

      final milestone = decoded.items.firstWhere((found) => found.isMilestone);
      expect(milestone.santiyeId, 'Depo Şantiyesi');
      expect(milestone.startDate, DateTime(2026, 4, 1));
      expect(milestone.endDate, DateTime(2026, 4, 1));
    });

    test('aynı dosya iki kez okunduğunda kimlikler değişmez', () {
      final bytes = codec.encode(
        sample,
        projectName: 'Test Programı',
        now: today,
      );
      final first = codec.decode(bytes, fallbackSite: 'Varsayılan');
      final second = codec.decode(bytes, fallbackSite: 'Varsayılan');
      expect(
        first.items.map((found) => found.id),
        second.items.map((found) => found.id),
      );
    });

    test('Project’ten gelen öncül bağı metin olarak korunur', () {
      final decoded = codec.decode(
        _projectFileBytes,
        fallbackSite: 'Varsayılan',
        today: today,
      );

      expect(decoded.items, hasLength(2));
      final duvar = decoded.items.firstWhere(
        (found) => found.name == 'Duvar örgüsü',
      );
      expect(duvar.santiyeId, 'A Blok');
      expect(duvar.predecessors, '1FS+2 gün');
      expect(duvar.responsible, 'Duvar Ekibi');
      expect(duvar.progress, 25);
      expect(duvar.startDate, DateTime(2026, 3, 16));
      expect(duvar.endDate, DateTime(2026, 3, 20));
    });

    test('MSPDI olmayan dosya anlaşılır hatayla reddedilir', () {
      expect(
        () => codec.decode(
          Uint8List.fromList(utf8.encode('<Workbook><Sheet/></Workbook>')),
          fallbackSite: 'Varsayılan',
        ),
        throwsA(isA<ProgramImportException>()),
      );
    });

    test('bozuk XML anlaşılır hatayla reddedilir', () {
      expect(
        () => codec.decode(
          Uint8List.fromList(utf8.encode('bu bir xml değil')),
          fallbackSite: 'Varsayılan',
        ),
        throwsA(isA<ProgramImportException>()),
      );
    });
  });

  group('süre çözümlemesi', () {
    test('ISO süre metinleri iş gününe çevrilir', () {
      expect(parseMsProjectDurationDays('PT80H0M0S'), 10);
      expect(parseMsProjectDurationDays('PT8H0M0S'), 1);
      expect(parseMsProjectDurationDays('PT0H0M0S'), 0);
      expect(parseMsProjectDurationDays('PT4H0M0S'), 1);
      expect(parseMsProjectDurationDays(null), isNull);
      expect(parseMsProjectDurationDays('elli gün'), isNull);
    });

    test('gün sayısı ISO süreye çevrilir', () {
      expect(msProjectDuration(10), 'PT80H0M0S');
      expect(msProjectDuration(0), 'PT0H0M0S');
      expect(msProjectDuration(1), 'PT8H0M0S');
    });

    test('öncül metni UID, tür ve gecikmeye ayrılır', () {
      final refs = parsePredecessorText('10FS+2 gün; 5SS');
      expect(refs, hasLength(2));
      expect(refs.first.uid, 10);
      expect(refs.first.type, 'FS');
      expect(refs.first.lagDays, 2);
      expect(refs.first.lagTenthsOfMinutes, 9600);
      expect(refs.last.uid, 5);
      expect(refs.last.type, 'SS');
      expect(refs.last.typeCode, 3);
    });
  });

  group('ProgramInteropService', () {
    final service = ProgramInteropService();

    test('.mpp ve .pdf içe aktarımda reddedilir', () {
      final empty = Uint8List(0);
      expect(
        () => service.decodeBytes(
          empty,
          extension: 'mpp',
          fallbackSite: 'Varsayılan',
        ),
        throwsA(isA<ProgramImportException>()),
      );
      expect(
        () => service.decodeBytes(
          empty,
          extension: 'pdf',
          fallbackSite: 'Varsayılan',
        ),
        throwsA(isA<ProgramImportException>()),
      );
    });
  });
}

/// MS Project'in kendi ürettiğine benzeyen, özet görev, kaynak ataması ve
/// öncül bağı taşıyan küçük bir dosya.
final _projectFileBytes = Uint8List.fromList(
  utf8.encode('''
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Project xmlns="http://schemas.microsoft.com/project">
  <Title>Konut Projesi</Title>
  <Tasks>
    <Task>
      <UID>0</UID>
      <Name>Konut Projesi</Name>
      <OutlineLevel>0</OutlineLevel>
      <Summary>1</Summary>
    </Task>
    <Task>
      <UID>1</UID>
      <Name>A Blok</Name>
      <OutlineLevel>1</OutlineLevel>
      <Summary>1</Summary>
    </Task>
    <Task>
      <UID>2</UID>
      <Name>Kaba sıva</Name>
      <OutlineLevel>2</OutlineLevel>
      <Summary>0</Summary>
      <Start>2026-03-09T08:00:00</Start>
      <Finish>2026-03-13T17:00:00</Finish>
      <Duration>PT40H0M0S</Duration>
      <PercentComplete>60</PercentComplete>
      <WBS>1.1</WBS>
    </Task>
    <Task>
      <UID>3</UID>
      <Name>Duvar örgüsü</Name>
      <OutlineLevel>2</OutlineLevel>
      <Summary>0</Summary>
      <Start>2026-03-16T08:00:00</Start>
      <Finish>2026-03-20T17:00:00</Finish>
      <Duration>PT40H0M0S</Duration>
      <PercentComplete>25</PercentComplete>
      <WBS>1.2</WBS>
      <PredecessorLink>
        <PredecessorUID>1</PredecessorUID>
        <Type>1</Type>
        <LinkLag>9600</LinkLag>
        <LagFormat>7</LagFormat>
      </PredecessorLink>
    </Task>
  </Tasks>
  <Resources>
    <Resource><UID>1</UID><Name>Sıva Ekibi</Name><Type>1</Type></Resource>
    <Resource><UID>2</UID><Name>Duvar Ekibi</Name><Type>1</Type></Resource>
  </Resources>
  <Assignments>
    <Assignment><UID>1</UID><TaskUID>2</TaskUID><ResourceUID>1</ResourceUID></Assignment>
    <Assignment><UID>2</UID><TaskUID>3</TaskUID><ResourceUID>2</ResourceUID></Assignment>
  </Assignments>
</Project>
'''),
);
