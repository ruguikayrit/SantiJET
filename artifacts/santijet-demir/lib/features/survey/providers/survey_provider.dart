import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/data/repositories/survey_repository.dart';
import 'package:santijet_demir/data/services/rebar_survey_mapper.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';
import 'package:santijet_demir/domain/entities/survey.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';

class _StandardImalatSpec {
  const _StandardImalatSpec({
    required this.name,
    required this.progressPercent,
    required this.lines,
  });

  final String name;
  final double progressPercent;
  final List<DiameterLine> lines;
}

const _standardImalatSpecs = <_StandardImalatSpec>[
  _StandardImalatSpec(
    name: 'Temel',
    progressPercent: 62,
    lines: [
      DiameterLine(diameter: 12, planned: 80, ordered: 50, delivered: 42, progressPercent: 62),
      DiameterLine(diameter: 14, planned: 70, ordered: 42, delivered: 36, progressPercent: 62),
      DiameterLine(diameter: 16, planned: 70, ordered: 42, delivered: 36, progressPercent: 62),
      DiameterLine(diameter: 20, planned: 60, ordered: 38, delivered: 34, progressPercent: 62),
    ],
  ),
  _StandardImalatSpec(
    name: 'Döşeme',
    progressPercent: 40,
    lines: [
      DiameterLine(diameter: 8, planned: 70, ordered: 28, delivered: 16, progressPercent: 40),
      DiameterLine(diameter: 10, planned: 60, ordered: 24, delivered: 14, progressPercent: 40),
      DiameterLine(diameter: 12, planned: 70, ordered: 28, delivered: 16, progressPercent: 40),
      DiameterLine(diameter: 14, planned: 60, ordered: 24, delivered: 14, progressPercent: 40),
      DiameterLine(diameter: 16, planned: 60, ordered: 24, delivered: 12, progressPercent: 40),
    ],
  ),
  _StandardImalatSpec(
    name: 'Merdiven',
    progressPercent: 35,
    lines: [
      DiameterLine(diameter: 10, planned: 30, ordered: 12, delivered: 8, progressPercent: 35),
      DiameterLine(diameter: 12, planned: 30, ordered: 12, delivered: 8, progressPercent: 35),
      DiameterLine(diameter: 14, planned: 25, ordered: 10, delivered: 6, progressPercent: 35),
    ],
  ),
];

SurveyImalat _imalatFromSpec(_StandardImalatSpec spec, Set<String> usedIds) {
  final planned = spec.lines.fold<double>(0, (sum, line) => sum + line.planned);
  final ordered = spec.lines.fold<double>(0, (sum, line) => sum + line.ordered);
  final delivered = spec.lines.fold<double>(0, (sum, line) => sum + line.delivered);
  final baseId = RebarSurveyMapper.slugifyImalatId(spec.name);
  var id = baseId;
  var suffix = 1;
  while (usedIds.contains(id)) {
    id = '$baseId-$suffix';
    suffix++;
  }
  usedIds.add(id);
  return SurveyImalat(
    id: id,
    name: spec.name,
    totalTonnage: planned,
    progressPercent: spec.progressPercent,
    diameters: spec.lines.map((line) => line.diameter).toList(),
    diameterLines: spec.lines,
    planned: planned,
    ordered: ordered,
    delivered: delivered,
    pending: (ordered - delivered).clamp(0, double.infinity),
  );
}

String _foldImalatName(String name) {
  const map = {
    'ş': 's',
    'Ş': 's',
    'ı': 'i',
    'I': 'i',
    'İ': 'i',
    'i': 'i',
    'ö': 'o',
    'Ö': 'o',
    'ü': 'u',
    'Ü': 'u',
    'ğ': 'g',
    'Ğ': 'g',
    'ç': 'c',
    'Ç': 'c',
  };
  final buffer = StringBuffer();
  for (final rune in name.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(map[char] ?? char.toLowerCase());
  }
  return buffer.toString();
}

final surveyRepositoryProvider = Provider<SurveyRepository>((ref) {
  return SurveyRepository(ref.watch(projectDataRepositoryProvider));
});

final surveyProjectProvider =
    StateNotifierProvider<SurveyProjectNotifier, SurveyProject>((ref) {
  final notifier = SurveyProjectNotifier(ref);
  ref.listen(activeProjectIdProvider, (previous, next) {
    if (previous != next) {
      notifier.loadForProject(next);
    }
  });
  ref.listen(activeProjectProvider, (previous, next) {
    if (previous?.name != next?.name && next != null) {
      notifier.updateProjectName(next.name);
    }
  });
  return notifier;
});

class SurveyProjectNotifier extends StateNotifier<SurveyProject> {
  SurveyProjectNotifier(this._ref) : super(_initialProject(_ref)) {
    loadForProject(_ref.read(activeProjectIdProvider));
  }

  final Ref _ref;
  String? _loadedProjectId;

  SurveyRepository get _repo => _ref.read(surveyRepositoryProvider);

  static SurveyProject _initialProject(Ref ref) {
    final activeProject = ref.read(activeProjectProvider);
    return ref.read(surveyRepositoryProvider).defaultProject(
          projectName: activeProject?.name ?? '',
        );
  }

  void reloadForProject(String? projectId) {
    _loadedProjectId = null;
    loadForProject(projectId);
  }

  void loadForProject(String? projectId) {
    if (projectId == null) {
      _loadedProjectId = null;
      state = _repo.defaultProject(
        projectName: _ref.read(activeProjectProvider)?.name ?? '',
      );
      return;
    }

    if (_loadedProjectId == projectId) return;

    final saved = _repo.read(projectId);
    final activeName = _ref.read(activeProjectProvider)?.name ?? '';
    if (saved != null) {
      state = saved.copyWith(
        projectName: activeName.isEmpty ? saved.projectName : activeName,
      );
    } else {
      state = _repo.defaultProject(projectName: activeName);
    }
    _loadedProjectId = projectId;
    ensureStandardImalats();
  }

  Future<void> _persist() async {
    final projectId = _ref.read(activeProjectIdProvider);
    if (projectId == null) return;
    try {
      await _repo.write(projectId, state);
    } catch (_) {
      throw StateError('İlerleme kaydedilemedi');
    }
  }

  void updateProjectName(String projectName) {
    if (projectName.isEmpty || state.projectName == projectName) return;
    state = state.copyWith(projectName: projectName);
    _persist();
  }

  Future<SurveyImalat> sendMetrajToImalat({
    required RebarMetrajResult result,
    required String imalatId,
    required bool replaceExisting,
  }) async {
    final imalat = state.imalats.firstWhere((item) => item.id == imalatId);
    final updated = RebarSurveyMapper.applyMetrajToImalat(
      imalat: imalat,
      lines: result.lines,
      replaceExisting: replaceExisting,
    );

    state = state.copyWith(
      imalats: state.imalats
          .map((item) => item.id == imalatId ? updated : item)
          .toList(),
    );
    await _persist();
    return updated;
  }

  /// Eksik standart imalatları ekler. Aynı adlı kayıt varsa dokunulmaz.
  Future<void> ensureStandardImalats() async {
    if (_ref.read(activeProjectIdProvider) == null) return;
    final present = state.imalats.map((imalat) => _foldImalatName(imalat.name)).toSet();
    final usedIds = state.imalats.map((imalat) => imalat.id).toSet();
    final missing = <SurveyImalat>[];
    for (final spec in _standardImalatSpecs) {
      if (present.contains(_foldImalatName(spec.name))) continue;
      missing.add(_imalatFromSpec(spec, usedIds));
    }
    if (missing.isEmpty) return;
    state = state.copyWith(imalats: [...state.imalats, ...missing]);
    await _persist();
  }

  Future<SurveyImalat> createImalat({required String name}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(name, 'name', 'İmalat adı boş olamaz');
    }

    final baseId = RebarSurveyMapper.slugifyImalatId(trimmed);
    var id = baseId;
    var suffix = 1;
    while (state.imalats.any((imalat) => imalat.id == id)) {
      id = '$baseId-$suffix';
      suffix++;
    }

    final imalat = RebarSurveyMapper.createImalatFromMetraj(
      id: id,
      name: trimmed,
      lines: const [],
    );

    state = state.copyWith(
      imalats: [...state.imalats, imalat],
    );
    await _persist();
    return imalat;
  }

  Future<SurveyImalat> createImalatFromMetraj({
    required RebarMetrajResult result,
    required String name,
  }) async {
    final baseId = RebarSurveyMapper.slugifyImalatId(name);
    var id = baseId;
    var suffix = 1;
    while (state.imalats.any((imalat) => imalat.id == id)) {
      id = '$baseId-$suffix';
      suffix++;
    }

    final imalat = RebarSurveyMapper.createImalatFromMetraj(
      id: id,
      name: name.trim(),
      lines: result.lines,
    );

    state = state.copyWith(
      imalats: [...state.imalats, imalat],
    );
    await _persist();
    return imalat;
  }

  Future<void> updateImalatPlanned({
    required String imalatId,
    required Map<int, double> plannedByDiameter,
  }) async {
    final index = state.imalats.indexWhere((item) => item.id == imalatId);
    if (index < 0) return;

    final imalat = state.imalats[index];
    final existing = {
      for (final line in imalat.diameterLines) line.diameter: line,
    };

    final lines = plannedByDiameter.entries
        .where((entry) => entry.value > 0)
        .map(
          (entry) => DiameterLine(
            diameter: entry.key,
            planned: entry.value,
            ordered: existing[entry.key]?.ordered ?? 0,
            delivered: existing[entry.key]?.delivered ?? 0,
            progressPercent: existing[entry.key]?.progressPercent ?? 0,
          ),
        )
        .toList()
      ..sort((a, b) => a.diameter.compareTo(b.diameter));

    final updated = RebarSurveyMapper.rebuildImalat(
      imalat: imalat,
      diameterLines: lines,
    );

    final imalats = List<SurveyImalat>.from(state.imalats);
    imalats[index] = updated;
    state = state.copyWith(imalats: imalats);
    await _persist();
  }

  Future<void> addOrderedTonnages(Map<String, double> tonnages) async {
    if (tonnages.isEmpty) return;

    final updatedImalats = state.imalats.map((imalat) {
      final add = tonnages[imalat.name] ?? 0;
      if (add <= 0) return imalat;

      if (imalat.diameterLines.isEmpty) {
        return imalat.copyWith(
          ordered: imalat.ordered + add,
          totalTonnage: imalat.planned,
        );
      }

      final updatedLines = imalat.diameterLines.map((line) {
        if (imalat.planned <= 0) return line;
        final share = line.planned / imalat.planned;
        return line.copyWith(ordered: line.ordered + add * share);
      }).toList();

      return RebarSurveyMapper.rebuildImalat(
        imalat: imalat,
        diameterLines: updatedLines,
      );
    }).toList();

    state = state.copyWith(imalats: updatedImalats);
    await _persist();
  }

  Future<void> subtractOrderedTonnages(Map<String, double> tonnages) async {
    if (tonnages.isEmpty) return;

    final updatedImalats = state.imalats.map((imalat) {
      final remove = tonnages[imalat.name] ?? 0;
      if (remove <= 0) return imalat;

      if (imalat.diameterLines.isEmpty) {
        return imalat.copyWith(
          ordered: (imalat.ordered - remove).clamp(0.0, double.infinity),
          totalTonnage: imalat.planned,
        );
      }

      final updatedLines = imalat.diameterLines.map((line) {
        if (imalat.planned <= 0) return line;
        final share = line.planned / imalat.planned;
        return line.copyWith(
          ordered: (line.ordered - remove * share).clamp(0.0, double.infinity),
        );
      }).toList();

      return RebarSurveyMapper.rebuildImalat(
        imalat: imalat,
        diameterLines: updatedLines,
      );
    }).toList();

    state = state.copyWith(imalats: updatedImalats);
    await _persist();
  }

  Future<void> addDeliveredTonnages(Map<String, double> tonnages) async {
    if (tonnages.isEmpty) return;

    final updatedImalats = state.imalats.map((imalat) {
      final add = tonnages[imalat.name] ?? 0;
      if (add <= 0) return imalat;

      if (imalat.diameterLines.isEmpty) {
        return imalat.copyWith(
          delivered: imalat.delivered + add,
          totalTonnage: imalat.planned,
        );
      }

      final updatedLines = imalat.diameterLines.map((line) {
        if (imalat.planned <= 0) return line;
        final share = line.planned / imalat.planned;
        return line.copyWith(delivered: line.delivered + add * share);
      }).toList();

      return RebarSurveyMapper.rebuildImalat(
        imalat: imalat,
        diameterLines: updatedLines,
      );
    }).toList();

    state = state.copyWith(imalats: updatedImalats);
    await _persist();
  }

  Future<void> updateProgressForImalats({
    required Set<String> imalatIds,
    required double progressPercent,
  }) async {
    if (imalatIds.isEmpty) return;

    final clamped = progressPercent.clamp(0.0, 100.0);
    final imalats = List<SurveyImalat>.from(state.imalats);

    for (var i = 0; i < imalats.length; i++) {
      final imalat = imalats[i];
      if (!imalatIds.contains(imalat.id)) continue;

      if (imalat.diameterLines.isEmpty) {
        imalats[i] = imalat.copyWith(progressPercent: clamped);
        continue;
      }

      final updatedLines = imalat.diameterLines
          .map((line) => line.copyWith(progressPercent: clamped))
          .toList();
      imalats[i] = imalat.copyWith(
        diameterLines: updatedLines,
        progressPercent: clamped,
      );
    }

    state = state.copyWith(imalats: imalats);
    await _persist();
  }

  Future<void> updateDiameterLineProgress({
    required String imalatId,
    required int diameter,
    required double progressPercent,
  }) async {
    final index = state.imalats.indexWhere((item) => item.id == imalatId);
    if (index < 0) return;

    final imalat = state.imalats[index];
    final clamped = progressPercent.clamp(0.0, 100.0);
    final updatedLines = imalat.diameterLines
        .map(
          (line) => line.diameter == diameter
              ? line.copyWith(progressPercent: clamped)
              : line,
        )
        .toList();

    final weightedProgress = imalat.planned > 0
        ? updatedLines.fold(
              0.0,
              (sum, line) => sum + line.planned * line.progressPercent,
            ) /
            imalat.planned
        : 0.0;

    final imalats = List<SurveyImalat>.from(state.imalats);
    imalats[index] = imalat.copyWith(
      diameterLines: updatedLines,
      progressPercent: weightedProgress,
    );

    state = state.copyWith(imalats: imalats);
    await _persist();
  }

  Future<void> updateImalatProgress({
    required String imalatId,
    required double progressPercent,
  }) async {
    await updateProgressForImalats(
      imalatIds: {imalatId},
      progressPercent: progressPercent,
    );
  }

  Future<void> saveImalatBlocks({
    required String imalatId,
    required List<ImalatBlock> blocks,
  }) async {
    final index = state.imalats.indexWhere((item) => item.id == imalatId);
    if (index < 0) return;
    final imalat = state.imalats[index];
    final plannedByDiameter = <int, double>{};
    for (final block in blocks) {
      for (final item in block.items) {
        for (final line in item.lines) {
          if (line.planned <= 0) continue;
          plannedByDiameter.update(
            line.diameter,
            (value) => value + line.planned,
            ifAbsent: () => line.planned,
          );
        }
      }
    }
    final planned = plannedByDiameter.values.fold<double>(0, (sum, value) => sum + value);
    final lines = plannedByDiameter.entries
        .map((entry) {
          final share = planned > 0 ? entry.value / planned : 0.0;
          return DiameterLine(
            diameter: entry.key,
            planned: entry.value,
            ordered: imalat.ordered * share,
            delivered: imalat.delivered * share,
            progressPercent: imalat.progressPercent,
          );
        })
        .toList()
      ..sort((a, b) => a.diameter.compareTo(b.diameter));

    final imalats = List<SurveyImalat>.from(state.imalats);
    imalats[index] = imalat.copyWith(
      blocks: blocks,
      diameterLines: lines,
      diameters: lines.map((line) => line.diameter).toList(),
      planned: planned,
      totalTonnage: planned,
      pending: (imalat.ordered - imalat.delivered).clamp(0, double.infinity),
    );
    state = state.copyWith(imalats: imalats);
    await _persist();
  }

  Future<void> replaceImportedImalats(List<SurveyImalat> imalats) async {
    state = state.copyWith(imalats: imalats);
    await _persist();
  }

  Future<void> deleteImalat(String imalatId) async {
    state = state.copyWith(
      imalats: state.imalats.where((item) => item.id != imalatId).toList(),
    );
    await _persist();
  }
}

final expandedImalatProvider = StateProvider<String?>((ref) => null);

final expandedMetrajRecordProvider = StateProvider<String?>((ref) => null);

final selectedMetrajRecordIdsProvider =
    StateProvider<Set<String>>((ref) => {});

final selectedImalatProvider = StateProvider<SurveyImalat?>((ref) => null);

final surveyTabIndexProvider = StateProvider<int>((ref) => 0);

class SurveyDashboardSummary {
  const SurveyDashboardSummary({
    required this.totalTonnage,
    required this.imalatCount,
  });

  final double totalTonnage;
  final int imalatCount;
}

/// Ana sayfa keşif KPI — imalat listesi ile senkron.
final surveyDashboardSummaryProvider = Provider<SurveyDashboardSummary>((ref) {
  final project = ref.watch(surveyProjectProvider);
  return SurveyDashboardSummary(
    totalTonnage: project.totalPlanned,
    imalatCount: project.imalats.length,
  );
});
