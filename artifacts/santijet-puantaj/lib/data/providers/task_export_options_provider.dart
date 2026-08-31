import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/theme/theme_mode_provider.dart';
import '../services/task_export_options.dart';

/// Son görev AL sütun / fotoğraf seçimleri.
class TaskExportOptionsNotifier extends StateNotifier<TaskExportOptions> {
  TaskExportOptionsNotifier(this._box) : super(_load(_box));

  final Box _box;
  static const _key = 'task_export_options';

  static TaskExportOptions _load(Box box) {
    final raw = box.get(_key);
    if (raw is String && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return TaskExportOptions.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      } catch (_) {}
    }
    return TaskExportOptions.all();
  }

  void save(TaskExportOptions options) {
    state = options;
    _box.put(_key, jsonEncode(options.toJson()));
  }
}

final taskExportOptionsProvider =
    StateNotifierProvider<TaskExportOptionsNotifier, TaskExportOptions>((ref) {
  return TaskExportOptionsNotifier(ref.watch(settingsBoxProvider));
});
