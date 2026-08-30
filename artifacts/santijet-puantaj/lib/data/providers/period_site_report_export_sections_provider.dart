import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/theme/theme_mode_provider.dart';
import '../services/period_site_report_export_sections.dart';

/// Son haftalık/aylık çıktı başlık seçimleri.
class PeriodSiteReportExportSectionsNotifier
    extends StateNotifier<PeriodSiteReportExportSections> {
  PeriodSiteReportExportSectionsNotifier(this._box) : super(_load(_box));

  final Box _box;
  static const _key = 'period_site_report_export_sections';

  static PeriodSiteReportExportSections _load(Box box) {
    final raw = box.get(_key);
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return PeriodSiteReportExportSections.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      } catch (_) {}
    }
    return PeriodSiteReportExportSections.all();
  }

  void save(PeriodSiteReportExportSections sections) {
    state = sections;
    _box.put(_key, jsonEncode(sections.toJson()));
  }
}

final periodSiteReportExportSectionsProvider = StateNotifierProvider<
    PeriodSiteReportExportSectionsNotifier, PeriodSiteReportExportSections>(
  (ref) {
    return PeriodSiteReportExportSectionsNotifier(
      ref.watch(settingsBoxProvider),
    );
  },
);
