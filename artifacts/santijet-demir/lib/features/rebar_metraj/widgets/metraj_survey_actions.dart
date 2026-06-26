import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';
import 'package:santijet_demir/domain/entities/survey.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/rebar_metraj/providers/rebar_metraj_storage_provider.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';

class MetrajResultActions extends ConsumerWidget {
  const MetrajResultActions({super.key, required this.result});

  final RebarMetrajResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = ref.watch(activeProjectIdProvider);
    final canEdit = ref.watch(canEditActiveProjectProvider);
    final savedRecords = ref.watch(savedRebarMetrajProvider);
    final isSaved = savedRecords.any(
      (record) =>
          record.result.fileName == result.fileName &&
          record.result.parsedAt == result.parsedAt &&
          record.result.totalTonnage == result.totalTonnage,
    );

    final canSave = projectId != null;
    final canSend = projectId != null && canEdit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (projectId == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Kaydetmek için bir proje seçin.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.warning),
            ),
          )
        else if (!canEdit)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Keşife göndermek için düzenleme yetkisi gerekir.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: !canSave
                    ? () => _handleBlockedAction(context, ref)
                    : isSaved
                        ? () => _openSavedRecord(context, ref)
                        : () => _saveResult(context, ref),
                icon: Icon(isSaved ? Icons.check_circle : Icons.save),
                label: Text(isSaved ? 'Kaydedildi' : 'Sonucu Kaydet'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: !canSend
                    ? () => _handleBlockedAction(context, ref, forSurvey: true)
                    : () => _sendToSurvey(context, ref),
                icon: const Icon(Icons.send),
                label: const Text('Keşife Gönder'),
              ),
            ),
          ],
        ),
        if (isSaved && canSave)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Metraj kaydı "Metraj" sekmesinde.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.success),
            ),
          ),
      ],
    );
  }

  void _openSavedRecord(BuildContext context, WidgetRef ref) {
    final matches = ref.read(savedRebarMetrajProvider).where(
          (item) =>
              item.result.fileName == result.fileName &&
              item.result.parsedAt == result.parsedAt,
        );
    if (matches.isEmpty) return;
    final record = matches.first;
    ref.read(surveyTabIndexProvider.notifier).state = 2;
    context.push(AppRoutes.savedMetrajDetail(record.id));
  }

  void _handleBlockedAction(
    BuildContext context,
    WidgetRef ref, {
    bool forSurvey = false,
  }) {
    final projectId = ref.read(activeProjectIdProvider);
    if (projectId == null) {
      context.push(AppRoutes.projects);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          forSurvey
              ? 'Bu projede keşife gönderme yetkiniz yok.'
              : 'Proje seçilmedi.',
        ),
      ),
    );
  }

  Future<void> _saveResult(BuildContext context, WidgetRef ref) async {
    final saved = await ref
        .read(savedRebarMetrajProvider.notifier)
        .saveCurrentResult(result);
    if (!context.mounted || saved == null) return;

    ref.read(surveyTabIndexProvider.notifier).state = 2;
    context.push(AppRoutes.savedMetrajDetail(saved.id));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Metraj kaydı oluşturuldu.')),
    );
  }

  Future<void> _sendToSurvey(BuildContext context, WidgetRef ref) async {
    final request = await showSendMetrajToSurveyDialog(context, result);
    if (request == null || !context.mounted) return;

    final surveyNotifier = ref.read(surveyProjectProvider.notifier);
    late final SurveyImalat imalat;

    if (request.isNewImalat) {
      imalat = await surveyNotifier.createImalatFromMetraj(
        result: result,
        name: request.imalatName,
      );
    } else {
      imalat = await surveyNotifier.sendMetrajToImalat(
        result: result,
        imalatId: request.imalatId,
        replaceExisting: request.replaceExisting,
      );
    }

    final savedNotifier = ref.read(savedRebarMetrajProvider.notifier);
    var savedRecord = savedNotifier.isResultSaved(result)
        ? ref.read(savedRebarMetrajProvider).firstWhere(
              (record) =>
                  record.result.fileName == result.fileName &&
                  record.result.parsedAt == result.parsedAt,
            )
        : await savedNotifier.saveCurrentResult(result);

    if (savedRecord != null) {
      await savedNotifier.markSentToSurvey(
        recordId: savedRecord.id,
        imalatId: imalat.id,
        imalatName: imalat.name,
      );
    }

    ref.read(surveyTabIndexProvider.notifier).state = 0;

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Metraj "${imalat.name}" imalatına aktarıldı.'),
        action: SnackBarAction(
          label: 'Keşif',
          onPressed: () {
            ref.read(surveyTabIndexProvider.notifier).state = 0;
          },
        ),
      ),
    );
  }
}

enum _SendMode { existing, newImalat }

class SendMetrajToSurveyDialog extends ConsumerStatefulWidget {
  const SendMetrajToSurveyDialog({
    super.key,
    required this.result,
  });

  final RebarMetrajResult result;

  @override
  ConsumerState<SendMetrajToSurveyDialog> createState() =>
      _SendMetrajToSurveyDialogState();
}

class _SendMetrajToSurveyDialogState
    extends ConsumerState<SendMetrajToSurveyDialog> {
  _SendMode _mode = _SendMode.existing;
  String? _selectedImalatId;
  late final TextEditingController _nameController;
  bool _replaceExisting = true;

  @override
  void initState() {
    super.initState();
    final defaultName = widget.result.fileName
        .replaceAll(RegExp(r'\.(dwg|dxf)$', caseSensitive: false), '');
    _nameController = TextEditingController(text: defaultName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(surveyProjectProvider);
    final imalats = project.imalats;
    _selectedImalatId ??= imalats.isNotEmpty ? imalats.first.id : null;
    if (_mode == _SendMode.existing && imalats.isEmpty) {
      _mode = _SendMode.newImalat;
    }

    return AlertDialog(
      title: const Text('Keşife Gönder'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.result.totalTonnage.toStringAsFixed(2)} t · '
              '${widget.result.lines.length} çap',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 16),
            if (imalats.isNotEmpty) ...[
              RadioListTile<_SendMode>(
                contentPadding: EdgeInsets.zero,
                title: const Text('Mevcut imalata aktar'),
                value: _SendMode.existing,
                groupValue: _mode,
                onChanged: (value) => setState(() => _mode = value!),
              ),
              if (_mode == _SendMode.existing) ...[
                DropdownButtonFormField<String>(
                  value: _selectedImalatId,
                  decoration: const InputDecoration(
                    labelText: 'İmalat',
                    border: OutlineInputBorder(),
                  ),
                  items: imalats
                      .map(
                        (imalat) => DropdownMenuItem(
                          value: imalat.id,
                          child: Text(imalat.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedImalatId = value),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mevcut tonajın üzerine yaz'),
                  subtitle: Text(
                    _replaceExisting
                        ? 'Seçili çaplardaki keşif değerleri metraj ile değiştirilir'
                        : 'Metraj tonajı mevcut keşif değerlerine eklenir',
                    style: AppTypography.bodySmall,
                  ),
                  value: _replaceExisting,
                  onChanged: (value) => setState(() => _replaceExisting = value),
                ),
              ],
              RadioListTile<_SendMode>(
                contentPadding: EdgeInsets.zero,
                title: const Text('Yeni imalat oluştur'),
                value: _SendMode.newImalat,
                groupValue: _mode,
                onChanged: (value) => setState(() => _mode = value!),
              ),
            ],
            if (_mode == _SendMode.newImalat || imalats.isEmpty)
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'İmalat adı',
                  border: OutlineInputBorder(),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: () => _submit(context, imalats),
          child: const Text('Keşife Gönder'),
        ),
      ],
    );
  }

  void _submit(BuildContext context, List<SurveyImalat> imalats) {
    if (_mode == _SendMode.existing) {
      if (_selectedImalatId == null) return;
      Navigator.of(context).pop(
        SendMetrajToSurveyRequest.existing(
          imalatId: _selectedImalatId!,
          replaceExisting: _replaceExisting,
        ),
      );
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(
      SendMetrajToSurveyRequest.newImalat(name: name),
    );
  }
}

class SendMetrajToSurveyRequest {
  const SendMetrajToSurveyRequest._({
    required this.imalatId,
    required this.imalatName,
    required this.replaceExisting,
    required this.isNewImalat,
  });

  factory SendMetrajToSurveyRequest.existing({
    required String imalatId,
    required bool replaceExisting,
  }) {
    return SendMetrajToSurveyRequest._(
      imalatId: imalatId,
      imalatName: '',
      replaceExisting: replaceExisting,
      isNewImalat: false,
    );
  }

  factory SendMetrajToSurveyRequest.newImalat({required String name}) {
    return SendMetrajToSurveyRequest._(
      imalatId: '',
      imalatName: name,
      replaceExisting: true,
      isNewImalat: true,
    );
  }

  final String imalatId;
  final String imalatName;
  final bool replaceExisting;
  final bool isNewImalat;
}

Future<SendMetrajToSurveyRequest?> showSendMetrajToSurveyDialog(
  BuildContext context,
  RebarMetrajResult result,
) {
  return showDialog<SendMetrajToSurveyRequest>(
    context: context,
    builder: (context) => SendMetrajToSurveyDialog(result: result),
  );
}
