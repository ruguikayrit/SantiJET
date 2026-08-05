import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/theme/theme_mode_provider.dart';
import '../services/daily_report_export_sections.dart';

/// Son PDF çıktısındaki başlık seçimleri — sonraki raporda varsayılan olur.
class DailyReportExportSectionsNotifier
    extends StateNotifier<DailyReportExportSections> {
  DailyReportExportSectionsNotifier(this._box) : super(_load(_box));

  final Box _box;
  static const _key = 'daily_report_export_sections';

  static DailyReportExportSections _load(Box box) {
    final raw = box.get(_key);
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return DailyReportExportSections.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      } catch (_) {}
    }
    return DailyReportExportSections.all();
  }

  void save(DailyReportExportSections sections) {
    state = sections;
    _box.put(_key, jsonEncode(sections.toJson()));
  }
}

final dailyReportExportSectionsProvider = StateNotifierProvider<
    DailyReportExportSectionsNotifier, DailyReportExportSections>((ref) {
  return DailyReportExportSectionsNotifier(ref.watch(settingsBoxProvider));
});
