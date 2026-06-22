import 'package:santijet_demir/domain/entities/field_count.dart';

List<ReconciliationRow> getMockReconciliationRows() => const [
  ReconciliationRow(diameter: 8, survey: 70, ordered: 55, delivered: 49, used: 12, expected: 37, counted: 36),
  ReconciliationRow(diameter: 10, survey: 105, ordered: 82, delivered: 74, used: 18, expected: 56, counted: 55),
  ReconciliationRow(diameter: 12, survey: 207, ordered: 168, delivered: 142, used: 45, expected: 97, counted: 94),
  ReconciliationRow(diameter: 14, survey: 188, ordered: 145, delivered: 128, used: 38, expected: 90, counted: 88),
  ReconciliationRow(diameter: 16, survey: 484, ordered: 398, delivered: 362, used: 120, expected: 242, counted: 228),
  ReconciliationRow(diameter: 20, survey: 415, ordered: 340, delivered: 310, used: 95, expected: 215, counted: 210),
  ReconciliationRow(diameter: 22, survey: 276, ordered: 220, delivered: 198, used: 72, expected: 126, counted: 122),
  ReconciliationRow(diameter: 28, survey: 124, ordered: 98, delivered: 88, used: 30, expected: 58, counted: 55),
];

List<FieldCountRecord> getMockFieldCounts() => [
  FieldCountRecord(
    id: 'fc1',
    title: 'Kolon Bölgesi Sayımı',
    date: DateTime(2025, 5, 14),
    personnel: 'Ahmet Y.',
    region: 'Blok A — Kolon',
    expected: 86,
    actual: 83.9,
    status: 'completed',
  ),
  FieldCountRecord(
    id: 'fc2',
    title: 'Perde Bölgesi Sayımı',
    date: DateTime(2025, 5, 13),
    personnel: 'Mehmet K.',
    region: 'Blok A — Perde',
    expected: 124,
    actual: 115.5,
    status: 'critical',
  ),
  FieldCountRecord(
    id: 'fc3',
    title: 'Döşeme Sayımı',
    date: DateTime(2025, 5, 12),
    personnel: 'Ali R.',
    region: 'Blok B — Döşeme',
    expected: 68,
    actual: 68,
    status: 'completed',
  ),
  FieldCountRecord(
    id: 'fc4',
    title: 'Radye Temel Sayımı',
    date: DateTime(2025, 5, 11),
    personnel: 'Hasan D.',
    region: 'Blok A — Radye',
    expected: 98,
    actual: 96.2,
    status: 'warning',
  ),
  FieldCountRecord(
    id: 'fc5',
    title: 'Kiriş Bölgesi Sayımı',
    date: DateTime(2025, 5, 10),
    personnel: 'Ahmet Y.',
    region: 'Blok B — Kiriş',
    expected: 36,
    actual: 34.4,
    status: 'pending',
  ),
];

const reconciliationFilterLabels = ['Tümü', 'Normal', 'Uyarı', 'Kritik'];

const varianceCauses = [
  'Fire kaybı',
  'Bekleyen kayıt',
  'Hatalı giriş',
  'Taşıma kaybı',
  'Güvenlik stoğu',
];
