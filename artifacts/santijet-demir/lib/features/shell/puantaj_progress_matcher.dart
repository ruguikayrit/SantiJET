import 'package:santijet_demir/domain/entities/puantaj_progress_cloud.dart';
import 'package:santijet_demir/domain/entities/survey.dart';

/// Puantaj imalat adlarını Demir keşif imalatlarıyla eşler.
String normalizeImalatName(String raw) {
  return raw
      .trim()
      .toLocaleLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ');
}

extension on String {
  /// Türkçe I/İ farkını kabaca normalize eder.
  String toLocaleLowerCase() {
    return replaceAll('İ', 'i')
        .replaceAll('I', 'ı')
        .toLowerCase();
  }
}

/// [snapshot] içindeki ilerlemeyi isim eşleşmesiyle Demir imalatlarına uygular.
/// Dönüş: güncellenecek imalatId → progressPercent ve eşleşmeyen Puantaj adları.
({
  Map<String, double> progressByImalatId,
  List<String> unmatchedNames,
}) matchPuantajProgressToSurvey({
  required List<SurveyImalat> imalats,
  required PuantajProgressSnapshot snapshot,
}) {
  final byName = <String, String>{};
  for (final imalat in imalats) {
    final key = normalizeImalatName(imalat.name);
    if (key.isEmpty) continue;
    byName.putIfAbsent(key, () => imalat.id);
  }

  final progressByImalatId = <String, double>{};
  final unmatched = <String>[];

  for (final item in snapshot.items) {
    final key = normalizeImalatName(item.imalatName);
    final id = byName[key];
    if (id == null) {
      unmatched.add(item.imalatName);
      continue;
    }
    progressByImalatId[id] = item.progressPercent;
  }

  return (
    progressByImalatId: progressByImalatId,
    unmatchedNames: unmatched,
  );
}
