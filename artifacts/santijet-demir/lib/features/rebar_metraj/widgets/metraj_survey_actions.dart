import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';
import 'package:santijet_demir/domain/entities/survey.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/rebar_metraj/providers/rebar_metraj_storage_provider.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';

/// Otomatik metraj sonucu — yalnızca ön imalat listesine kaydet.
class MetrajResultActions extends ConsumerWidget {
  const MetrajResultActions({super.key, required this.result});

  final RebarMetrajResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectId = ref.watch(activeProjectIdProvider);
    final savedRecords = ref.watch(savedRebarMetrajProvider);
    final isSaved = savedRecords.any(
      (record) =>
          record.result.fileName == result.fileName &&
          record.result.parsedAt == result.parsedAt &&
          record.result.totalTonnage == result.totalTonnage,
    );

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
          ),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: projectId == null
                ? () => context.push(AppRoutes.projects)
                : isSaved
                    ? () => ref.read(surveyTabIndexProvider.notifier).state = 2
                    : () => _saveResult(context, ref),
            icon: Icon(isSaved ? Icons.check_circle : Icons.save),
            label: Text(isSaved ? 'Ön İmalat\'ta Gör' : 'Metraj Kaydet'),
          ),
        ),
        if (isSaved && projectId != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Kayıt Ön İmalat listesinde. İmalata göndermek için oradan devam edin.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.success),
            ),
          ),
      ],
    );
  }

  Future<void> _saveResult(BuildContext context, WidgetRef ref) async {
    final title = await showSaveMetrajNameDialog(context, result);
    if (title == null || !context.mounted) return;

    final saved = await ref
        .read(savedRebarMetrajProvider.notifier)
        .saveCurrentResult(result, title: title);
    if (!context.mounted || saved == null) return;

    ref.read(surveyTabIndexProvider.notifier).state = 2;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"$title" Ön İmalat listesine kaydedildi.')),
    );
  }
}

Future<void> sendMetrajRecordToSurvey(
  BuildContext context,
  WidgetRef ref,
  SavedRebarMetraj record,
) async {
  final canEdit = ref.read(canEditActiveProjectProvider);
  if (!canEdit) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('İmalata göndermek için düzenleme yetkisi gerekir.')),
    );
    return;
  }

  await _sendResultToSurvey(
    context,
    ref,
    result: record.result,
    defaultImalatName: record.displayTitle,
    sourceRecord: record,
  );
}

Future<void> sendSelectedMetrajRecordsToSurvey(
  BuildContext context,
  WidgetRef ref,
  List<SavedRebarMetraj> records,
) async {
  if (records.isEmpty) return;

  final canEdit = ref.read(canEditActiveProjectProvider);
  if (!canEdit) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('İmalata göndermek için düzenleme yetkisi gerekir.')),
    );
    return;
  }

  if (records.length == 1) {
    await sendMetrajRecordToSurvey(context, ref, records.first);
    return;
  }

  final mode = await showBulkSendMetrajDialog(context, records);
  if (mode == null || !context.mounted) return;

  switch (mode.mode) {
    case BulkSendMode.separate:
      var sent = 0;
      for (final record in records) {
        if (!context.mounted) return;
        final request = await showSendMetrajToSurveyDialog(
          context,
          record.result,
          defaultImalatName: record.displayTitle,
        );
        if (request == null) continue;
        await _applySendRequest(context, ref, record.result, request, record);
        sent++;
      }
      if (!context.mounted) return;
      if (sent > 0) {
        ref.read(selectedMetrajRecordIdsProvider.notifier).state = {};
        ref.read(surveyTabIndexProvider.notifier).state = 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$sent kayıt imalat listesine gönderildi.')),
        );
      }
    case BulkSendMode.merged:
      final merged = _mergeMetrajResults(records, mode.mergedName!);
      await _sendResultToSurvey(
        context,
        ref,
        result: merged,
        defaultImalatName: mode.mergedName!,
        sourceRecords: records,
      );
  }
}

Future<void> _sendResultToSurvey(
  BuildContext context,
  WidgetRef ref, {
  required RebarMetrajResult result,
  required String defaultImalatName,
  SavedRebarMetraj? sourceRecord,
  List<SavedRebarMetraj>? sourceRecords,
}) async {
  final request = await showSendMetrajToSurveyDialog(
    context,
    result,
    defaultImalatName: defaultImalatName,
  );
  if (request == null || !context.mounted) return;

  await _applySendRequest(
    context,
    ref,
    result,
    request,
    sourceRecord,
    sourceRecords: sourceRecords,
  );
}

Future<void> _applySendRequest(
  BuildContext context,
  WidgetRef ref,
  RebarMetrajResult result,
  SendMetrajToSurveyRequest request,
  SavedRebarMetraj? sourceRecord, {
  List<SavedRebarMetraj>? sourceRecords,
}) async {
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
  final recordsToMark = sourceRecords ??
      (sourceRecord != null ? [sourceRecord] : <SavedRebarMetraj>[]);

  for (final record in recordsToMark) {
    await savedNotifier.markSentToSurvey(
      recordId: record.id,
      imalatId: imalat.id,
      imalatName: imalat.name,
    );
  }

  ref.read(selectedMetrajRecordIdsProvider.notifier).state = {};
  ref.read(surveyTabIndexProvider.notifier).state = 0;

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Metraj "${imalat.name}" imalat listesine aktarıldı.'),
      action: SnackBarAction(
        label: 'İmalat',
        onPressed: () => ref.read(surveyTabIndexProvider.notifier).state = 0,
      ),
    ),
  );
}

RebarMetrajResult _mergeMetrajResults(
  List<SavedRebarMetraj> records,
  String mergedName,
) {
  final mergedLines = <int, RebarMetrajLine>{};
  for (final record in records) {
    for (final line in record.result.lines) {
      final existing = mergedLines[line.diameter];
      if (existing == null) {
        mergedLines[line.diameter] = line;
      } else {
        mergedLines[line.diameter] = RebarMetrajLine(
          diameter: line.diameter,
          totalLengthM: existing.totalLengthM + line.totalLengthM,
          weightKg: existing.weightKg + line.weightKg,
          barCount: existing.barCount + line.barCount,
          layerName: existing.layerName.isNotEmpty
              ? existing.layerName
              : line.layerName,
        );
      }
    }
  }

  final lines = mergedLines.values.toList()
    ..sort((a, b) => a.diameter.compareTo(b.diameter));

  return RebarMetrajResult(
    fileName: mergedName,
    sourceFormat: 'BIRLESIK',
    parsedAt: DateTime.now(),
    lines: lines,
    textDetails: const [],
    skippedEntityCount: 0,
    warnings: const [],
  );
}

enum BulkSendMode { separate, merged }

class BulkSendResult {
  const BulkSendResult.separate()
      : mode = BulkSendMode.separate,
        mergedName = null;
  const BulkSendResult.merged(this.mergedName) : mode = BulkSendMode.merged;

  final BulkSendMode mode;
  final String? mergedName;
}

Future<BulkSendResult?> showBulkSendMetrajDialog(
  BuildContext context,
  List<SavedRebarMetraj> records,
) {
  return showDialog<BulkSendResult>(
    context: context,
    builder: (context) => _BulkSendMetrajDialog(records: records),
  );
}

class _BulkSendMetrajDialog extends StatefulWidget {
  const _BulkSendMetrajDialog({required this.records});

  final List<SavedRebarMetraj> records;

  @override
  State<_BulkSendMetrajDialog> createState() => _BulkSendMetrajDialogState();
}

class _BulkSendMetrajDialogState extends State<_BulkSendMetrajDialog> {
  var _merged = false;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Birleşik Metraj');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalTonnage = widget.records.fold<double>(
      0,
      (sum, record) => sum + record.result.totalTonnage,
    );

    return AlertDialog(
      backgroundColor: AppColors.surfaceElevated,
      title: const Text('Toplu İmalata Gönder'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.records.length} kayıt · ${totalTonnage.toStringAsFixed(2)} t',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 16),
          RadioListTile<bool>(
            contentPadding: EdgeInsets.zero,
            title: const Text('Her kayıt ayrı imalat'),
            subtitle:
                const Text('Her ön imalat kaydı kendi adıyla imalat olur'),
            value: false,
            groupValue: _merged,
            onChanged: (value) => setState(() => _merged = value!),
          ),
          RadioListTile<bool>(
            contentPadding: EdgeInsets.zero,
            title: const Text('Tek imalatta birleştir'),
            subtitle: const Text('Seçili kayıtların tonajları toplanır'),
            value: true,
            groupValue: _merged,
            onChanged: (value) => setState(() => _merged = value!),
          ),
          if (_merged) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Birleşik imalat adı',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: () {
            if (_merged) {
              final name = _nameController.text.trim();
              if (name.isEmpty) return;
              Navigator.of(context).pop(BulkSendResult.merged(name));
              return;
            }
            Navigator.of(context).pop(const BulkSendResult.separate());
          },
          child: const Text('Devam'),
        ),
      ],
    );
  }
}

enum _SendMode { existing, newImalat }

class SendMetrajToSurveyDialog extends ConsumerStatefulWidget {
  const SendMetrajToSurveyDialog({
    super.key,
    required this.result,
    required this.defaultImalatName,
  });

  final RebarMetrajResult result;
  final String defaultImalatName;

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
    _nameController = TextEditingController(text: widget.defaultImalatName);
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
      title: const Text('İmalata Gönder'),
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
                  onChanged: (value) =>
                      setState(() => _selectedImalatId = value),
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
                  onChanged: (value) =>
                      setState(() => _replaceExisting = value),
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
          child: const Text('İmalata Gönder'),
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
  RebarMetrajResult result, {
  required String defaultImalatName,
}) {
  return showDialog<SendMetrajToSurveyRequest>(
    context: context,
    builder: (context) => SendMetrajToSurveyDialog(
      result: result,
      defaultImalatName: defaultImalatName,
    ),
  );
}

class SaveMetrajNameDialog extends StatefulWidget {
  const SaveMetrajNameDialog({super.key, required this.result});

  final RebarMetrajResult result;

  @override
  State<SaveMetrajNameDialog> createState() => _SaveMetrajNameDialogState();
}

class _SaveMetrajNameDialogState extends State<SaveMetrajNameDialog> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.result.fileName.replaceAll(
        RegExp(r'\.(dwg|dxf)$', caseSensitive: false),
        '',
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceElevated,
      title: const Text('Metraj Kaydet'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.result.totalTonnage.toStringAsFixed(2)} t · '
            '${widget.result.totalBarCount} çubuk',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Kayıt adı',
              hintText: 'Örn. Blok A zemin demiri',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(context),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: () => _submit(context),
          child: const Text('Kaydet'),
        ),
      ],
    );
  }

  void _submit(BuildContext context) {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
  }
}

Future<String?> showSaveMetrajNameDialog(
  BuildContext context,
  RebarMetrajResult result,
) {
  return showDialog<String>(
    context: context,
    builder: (context) => SaveMetrajNameDialog(result: result),
  );
}
