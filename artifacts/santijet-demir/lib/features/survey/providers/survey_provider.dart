import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/data/repositories/survey_repository.dart';
import 'package:santijet_demir/data/services/rebar_survey_mapper.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';
import 'package:santijet_demir/domain/entities/survey.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';

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
  }

  Future<void> _persist() async {
    final projectId = _ref.read(activeProjectIdProvider);
    if (projectId == null) return;
    await _repo.write(projectId, state);
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
    final index = state.imalats.indexWhere((item) => item.id == imalatId);
    if (index < 0) return;

    final imalat = state.imalats[index];
    final clamped = progressPercent.clamp(0.0, 100.0);

    if (imalat.diameterLines.isNotEmpty) {
      await updateDiameterLineProgress(
        imalatId: imalatId,
        diameter: imalat.diameterLines.first.diameter,
        progressPercent: clamped,
      );
      return;
    }

    final imalats = List<SurveyImalat>.from(state.imalats);
    imalats[index] = imalat.copyWith(progressPercent: clamped);

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
