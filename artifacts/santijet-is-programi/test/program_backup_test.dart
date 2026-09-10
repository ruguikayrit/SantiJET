import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_is_programi/data/backup/program_backup.dart';
import 'package:santijet_is_programi/domain/daily_crew_entry.dart';
import 'package:santijet_is_programi/domain/program_item.dart';
import 'package:santijet_is_programi/domain/program_project.dart';

void main() {
  test('yedek yuvarlak yol ile aynı veriyi döndürür', () {
    final backup = ProgramBackup(
      projects: const [
        ProgramProject(id: 'p1', name: 'Merkez Şantiyesi', code: 'SJAB12'),
      ],
      items: [
        ProgramItem(
          id: 'i1',
          santiyeId: 'Merkez Şantiyesi',
          name: 'Kalıp',
          startDate: DateTime(2026, 3, 1),
          endDate: DateTime(2026, 3, 5),
          plannedDays: 5,
          plannedCrew: 4,
          progress: 20,
          status: ProgramStatus.inProgress,
          responsible: 'Şef',
        ),
      ],
      dailyCrew: [
        DailyCrewEntry(
          id: 'c1',
          itemId: 'i1',
          date: DateTime(2026, 3, 2),
          workers: 3,
        ),
      ],
      profile: const LocalProfile(displayName: 'Ayşe', role: 'Şef'),
      activeProjectId: 'p1',
      themeMode: 'santijet_pro',
    );

    final restored = ProgramBackup.decode(backup.encode());
    expect(restored.projects.single.code, 'SJAB12');
    expect(restored.items.single.name, 'Kalıp');
    expect(restored.dailyCrew.single.workers, 3);
    expect(restored.profile.displayName, 'Ayşe');
    expect(restored.activeProjectId, 'p1');
    expect(restored.themeMode, 'santijet_pro');
  });

  test('başka uygulama yedeğini reddeder', () {
    expect(
      () => ProgramBackup.fromJson({'app': 'santijet_puantaj'}),
      throwsFormatException,
    );
  });
}
