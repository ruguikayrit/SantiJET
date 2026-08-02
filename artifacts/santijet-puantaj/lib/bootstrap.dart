import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/theme/theme_mode_provider.dart';
import 'data/providers/app_data_provider.dart';
import 'data/providers/production_provider.dart';
import 'data/providers/verim_provider.dart';

/// Uygulama başlatma — Demir / BFA `bootstrap()` deseniyle hizalı.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final boxes = await Future.wait([
    Hive.openBox('settings'),
    Hive.openBox('projects'),
    Hive.openBox('personnel'),
    Hive.openBox('attendance'),
    Hive.openBox('production'),
    Hive.openBox('work_schedule_cloud'),
    Hive.openBox('kesif_cloud'),
  ]);

  _migratePersonnelToProjects(boxes[2], boxes[1], boxes[0]);

  runApp(
    ProviderScope(
      overrides: [
        settingsBoxProvider.overrideWithValue(boxes[0]),
        projectsBoxProvider.overrideWithValue(boxes[1]),
        personnelBoxProvider.overrideWithValue(boxes[2]),
        attendanceBoxProvider.overrideWithValue(boxes[3]),
        productionBoxProvider.overrideWithValue(boxes[4]),
        workScheduleCacheBoxProvider.overrideWithValue(boxes[5]),
        kesifCacheBoxProvider.overrideWithValue(boxes[6]),
      ],
      child: const SantijetPuantajApp(),
    ),
  );
}

/// Eski global personeli ilk/aktif projeye bağlar (projectId yoksa).
void _migratePersonnelToProjects(
  Box personnelBox,
  Box projectsBox,
  Box settingsBox,
) {
  List<Map<String, dynamic>> read(Box box, String key) {
    final raw = box.get(key);
    if (raw is String && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .cast<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    if (raw is List) {
      return raw
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return [];
  }

  final projects = read(projectsBox, 'items');
  if (projects.isEmpty) return;

  final people = read(personnelBox, 'items');
  if (people.isEmpty) return;
  if (!people.any((p) => (p['projectId'] as String?)?.isNotEmpty != true)) {
    return;
  }

  final activeId = settingsBox.get('activeProjectId') as String?;
  var targetId = projects.first['id'] as String;
  if (activeId != null) {
    for (final p in projects) {
      if (p['id'] == activeId) {
        targetId = activeId;
        break;
      }
    }
  }

  var changed = false;
  final migrated = <Map<String, dynamic>>[];
  for (final p in people) {
    if ((p['projectId'] as String?)?.isNotEmpty == true) {
      migrated.add(p);
    } else {
      changed = true;
      migrated.add({...p, 'projectId': targetId});
    }
  }
  if (changed) {
    personnelBox.put('items', jsonEncode(migrated));
  }
}
