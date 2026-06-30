import 'package:flutter_test/flutter_test.dart';
import 'package:santijet_demir/data/services/project_backup_service.dart';

void main() {
  group('parseBackupPayload', () {
    test('parses survey backup', () {
      const raw = '''
{
  "format": "santijet-demir-backup",
  "scope": "survey",
  "version": 1,
  "exportedAt": "2026-06-28T10:00:00.000",
  "projectId": "p1",
  "projectName": "Test Proje",
  "domains": {
    "survey": {
      "projectName": "Test Proje",
      "imalats": []
    }
  }
}
''';

      final payload = parseBackupPayload(raw);

      expect(payload.scope, BackupScope.survey);
      expect(payload.projectName, 'Test Proje');
      expect(payload.domains.containsKey('survey'), isTrue);
    });

    test('rejects unknown format', () {
      expect(
        () => parseBackupPayload('{"format":"other"}'),
        throwsA(isA<BackupParseException>()),
      );
    });

    test('rejects survey-only import from wrong scope hint', () {
      const raw = '''
{
  "format": "santijet-demir-backup",
  "scope": "project",
  "version": 1,
  "exportedAt": "2026-06-28T10:00:00.000",
  "domains": {
    "survey": {"imalats": []},
    "orders": {"items": []}
  }
}
''';

      final payload = parseBackupPayload(raw);
      expect(payload.scope, BackupScope.project);
      expect(payload.domains.length, 2);
    });
  });
}
