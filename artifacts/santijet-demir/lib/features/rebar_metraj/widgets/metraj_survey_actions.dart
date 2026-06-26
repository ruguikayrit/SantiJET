import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';
import 'package:santijet_demir/domain/entities/survey.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/rebar_metraj/providers/rebar_metraj_provider.dart';
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

    if (projectId == null) {
      return _InfoBox(
        message: 'Metraj sonucunu kaydetmek için önce bir proje seçin.',
        color: AppColors.warning,
      );
    }

    if (!canEdit) {
      return _InfoBox(
        message: 'Bu projede kaydetme ve keşife gönderme yetkiniz yok.',
        color: AppColors.textMuted,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: isSaved ? null : () => _saveResult(context, ref),
              icon: Icon(isSaved ? Icons.check_circle : Icons.save),
              label: Text(isSaved ? 'Kaydedildi' : 'Sonucu Kaydet'),
            ),
            OutlinedButton.icon(
              onPressed: () => _sendToSurvey(context, ref),
              icon: const Icon(Icons.send),
              label: const Text('Keşife Gönder'),
            ),
          ],
        ),
        if (isSaved)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Metraj sonucu projeye kaydedildi.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.success),
            ),
          ),
      ],
    );
  }

  Future<void> _saveResult(BuildContext context, WidgetRef ref) async {
    final saved = await ref
        .read(savedRebarMetrajProvider.notifier)
        .saveCurrentResult(result);
    if (!context.mounted || saved == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Metraj sonucu kaydedildi.')),
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

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.message, required this.color});

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadii.md,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(message, style: AppTypography.bodySmall),
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

class SavedMetrajHistorySection extends ConsumerWidget {
  const SavedMetrajHistorySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedRecords = ref.watch(savedRebarMetrajProvider);
    if (savedRecords.isEmpty) return const SizedBox.shrink();

    final dateFormat = DateFormat('dd.MM.yyyy HH:mm', 'tr_TR');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kayıtlı Metrajlar', style: AppTypography.headlineMedium),
        const SizedBox(height: 8),
        ...savedRecords.take(5).map(
              (record) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: AppRadii.md,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.result.fileName,
                            style: AppTypography.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${record.result.totalTonnage.toStringAsFixed(2)} t · '
                            '${dateFormat.format(record.savedAt)}',
                            style: AppTypography.bodySmall,
                          ),
                          if (record.surveyImalatName != null)
                            Text(
                              'Keşif: ${record.surveyImalatName}',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Sonucu yükle',
                      onPressed: () {
                        ref.read(rebarMetrajResultProvider.notifier).state =
                            record.result;
                      },
                      icon: const Icon(Icons.restore),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
