import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:santijet_demir/data/services/puantaj_progress_cloud_service.dart';
import 'package:santijet_demir/domain/entities/puantaj_progress_cloud.dart';
import 'package:santijet_demir/features/auth/providers/auth_provider.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/shell/puantaj_progress_matcher.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';

final puantajProgressCloudServiceProvider =
    Provider<PuantajProgressCloudService>((ref) {
  return PuantajProgressCloudService();
});

final puantajProgressSyncingProvider = StateProvider<bool>((ref) => false);

/// Puantaj bulutundan imalat ilerlemesini çeker ve aktif proje keşfine uygular.
Future<PuantajProgressImportResult> importPuantajProgressFromCloud(
  WidgetRef ref,
) async {
  final email = ref.read(authProvider).user?.email.trim() ?? '';
  final project = ref.read(activeProjectProvider);
  if (project == null) {
    throw PuantajProgressCloudException(
      'Aktarım için önce aktif proje seçin.',
    );
  }
  if (email.isEmpty) {
    throw PuantajProgressCloudException(
      'Bulut aktarımı hesap e-postanıza bağlıdır. Lütfen giriş yapın.',
    );
  }

  ref.read(puantajProgressSyncingProvider.notifier).state = true;
  try {
    final snapshot = await ref.read(puantajProgressCloudServiceProvider).sync(
          accountEmail: email,
          projectCode: project.code,
          projectName: project.name,
        );

    final survey = ref.read(surveyProjectProvider);
    final matched = matchPuantajProgressToSurvey(
      imalats: survey.imalats,
      snapshot: snapshot,
    );

    if (matched.progressByImalatId.isEmpty) {
      throw PuantajProgressCloudException(
        'Buluttan veri geldi ancak keşif imalat adlarıyla eşleşme yok. '
        'Puantaj ve Demir’de imalat adlarının aynı olduğundan emin olun.',
      );
    }

    final notifier = ref.read(surveyProjectProvider.notifier);
    for (final entry in matched.progressByImalatId.entries) {
      await notifier.updateProgressForImalats(
        imalatIds: {entry.key},
        progressPercent: entry.value,
      );
    }

    return PuantajProgressImportResult(
      updatedCount: matched.progressByImalatId.length,
      unmatchedNames: matched.unmatchedNames,
      snapshot: snapshot,
    );
  } finally {
    ref.read(puantajProgressSyncingProvider.notifier).state = false;
  }
}
