import 'package:santijet_demir/core/format/app_format.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:santijet_demir/core/widgets/app_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/app_components.dart';
import 'package:santijet_demir/core/widgets/santijet_header.dart';
import 'package:santijet_demir/core/widgets/swipe_to_delete_row.dart';
import 'package:santijet_demir/data/services/export_service.dart';
import 'package:santijet_demir/domain/entities/survey.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';
import 'package:santijet_demir/features/survey/survey_table_import.dart';

class SurveyListScreen extends ConsumerStatefulWidget {
  const SurveyListScreen({super.key});

  @override
  ConsumerState<SurveyListScreen> createState() => _SurveyListScreenState();
}

class _SurveyListScreenState extends ConsumerState<SurveyListScreen> {
  late final ScrollController _imalatListScrollController;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _imalatListScrollController = ScrollController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _imalatListScrollController.dispose();
    super.dispose();
  }

  void _scrollToImalatListEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_imalatListScrollController.hasClients) return;
      _imalatListScrollController.animateTo(
        _imalatListScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _showCreateImalatDialog() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const CreateImalatDialog(),
    );
    if (!mounted || name == null) return;

    final imalat = await ref
        .read(surveyProjectProvider.notifier)
        .createImalat(name: name);

    if (!mounted) return;

    ref.read(expandedImalatProvider.notifier).state = imalat.id;
    _scrollToImalatListEnd();

    ScaffoldMessenger.of(context).showAppSnackBar(
      SnackBar(
        content: Text('"${imalat.name}" imalatı oluşturuldu'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _openImportSheet() async {
    final canEdit = ref.read(canEditActiveProjectProvider);
    if (!canEdit) {
      ScaffoldMessenger.of(context).showAppSnackBar(
        const SnackBar(content: Text('Bu projeyi düzenleme yetkiniz yok')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Excel içe aktar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1C2430),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Dosya, referans şablonun satır ve sütun düzeninde olmalıdır.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8B95A5),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.table_view_outlined),
                  title: const Text('Şablonu indir'),
                  subtitle: const Text('Keşif sayfasını bu dosyaya göre doldurun'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _downloadImportTemplate();
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.upload_file_outlined),
                  title: const Text('Dolu Excel’i içe aktar'),
                  subtitle: const Text('Yalnız .xlsx — Keşif sayfası'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickAndImportExcel();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _downloadImportTemplate() async {
    try {
      await exportService.shareExcelBytes(
        bytes: buildSurveyImportTemplateBytes(),
        fileName: surveyImportTemplateFileName,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showAppSnackBar(
        SnackBar(content: Text('Şablon indirilemedi: $error')),
      );
    }
  }

  Future<void> _pickAndImportExcel() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      withData: true,
    );
    if (!mounted || picked == null || picked.files.isEmpty) return;

    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      ScaffoldMessenger.of(context).showAppSnackBar(
        const SnackBar(content: Text('Dosya okunamadı. Lütfen tekrar deneyin.')),
      );
      return;
    }

    try {
      final incoming = parseSurveyImport(fileName: file.name, bytes: bytes);
      if (!mounted) return;
      final merged = await ref
          .read(surveyProjectProvider.notifier)
          .importPlannedImalats(incoming);
      if (!mounted) return;
      _scrollToImalatListEnd();
      ScaffoldMessenger.of(context).showAppSnackBar(
        SnackBar(
          content: Text(_importResultMessage(merged)),
          backgroundColor: AppColors.success,
        ),
      );
    } on SurveyImportException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showAppSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showAppSnackBar(
        SnackBar(content: Text('İçe aktarma hatası: $error')),
      );
    }
  }

  String _importResultMessage(SurveyImportMerge merged) {
    if (merged.added > 0 && merged.updated > 0) {
      return '${merged.added} imalat eklendi, ${merged.updated} güncellendi';
    }
    if (merged.updated > 0) {
      return '${merged.updated} imalat güncellendi';
    }
    return '${merged.added} imalat içe aktarıldı';
  }

  List<SurveyImalat> _visibleImalats(List<SurveyImalat> source) {
    final query = _foldImalat(_query.trim());
    final visible = query.isEmpty
        ? [...source]
        : source.where((imalat) => _foldImalat(imalat.name).contains(query)).toList();
    visible.sort((a, b) {
      final rank = _imalatRank(a.name).compareTo(_imalatRank(b.name));
      if (rank != 0) return rank;
      return _foldImalat(a.name).compareTo(_foldImalat(b.name));
    });
    return visible;
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(surveyProjectProvider);
    final expandedId = ref.watch(expandedImalatProvider);
    final canEdit = ref.watch(canEditActiveProjectProvider);
    final imalats = _visibleImalats(project.imalats);
    const screenBg = Color(0xFFF4F7FB);

    return Scaffold(
      backgroundColor: screenBg,
      primary: false,
      resizeToAvoidBottomInset: false,
      floatingActionButtonLocation: ShellAddFab.location,
      floatingActionButton: canEdit
          ? ShellAddFab(
              heroTag: 'new-imalat',
              onPressed: _showCreateImalatDialog,
            )
          : null,
      body: ColoredBox(
        color: screenBg,
        child: Column(
          children: [
            SantijetHeader(
              subtitle: 'Keşif',
              onImport: _openImportSheet,
            ),
            Expanded(
              child: ListView(
              controller: _imalatListScrollController,
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppFab.scrollClearanceOf(context),
              ),
              children: [
                _ImalatSearchField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 12),
                if (imalats.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                      child: Text(
                        'İmalat bulunamadı',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8B95A5),
                        ),
                      ),
                    ),
                  )
                else
                  ...imalats.map(
                    (imalat) => SwipeToDeleteRow(
                      itemKey: ValueKey('imalat-${imalat.id}'),
                      enabled: canEdit,
                      title: 'İmalatı Sil',
                      message:
                          '"${imalat.name}" imalatını silmek istediğinize emin misiniz?',
                      onDelete: () async {
                        await ref
                            .read(surveyProjectProvider.notifier)
                            .deleteImalat(imalat.id);
                        if (expandedId == imalat.id) {
                          ref.read(expandedImalatProvider.notifier).state = null;
                        }
                      },
                      child: SurveyImalatCard(
                        imalat: imalat,
                        onDetail: () {
                          ref.read(selectedImalatProvider.notifier).state =
                              imalat;
                          context.push('${AppRoutes.survey}/${imalat.id}');
                        },
                      ),
                    ),
                  ),
              ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImalatSearchField extends StatelessWidget {
  const _ImalatSearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6EBF2)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1C2430)),
        decoration: const InputDecoration(
          hintText: 'İmalat ara...',
          hintStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF8B95A5)),
          prefixIcon: Icon(Icons.search, size: 20, color: Color(0xFF8B95A5)),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class SurveyImalatCard extends StatelessWidget {
  const SurveyImalatCard({
    super.key,
    required this.imalat,
    required this.onDetail,
  });

  final SurveyImalat imalat;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    final accent = _imalatAccent(imalat.name);
    final diameters = imalat.diameters;
    final progress = imalat.progressPercent.clamp(0, 100).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EBF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C1C2430),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onDetail,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        _imalatThumb(imalat.name),
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  imalat.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1C2430),
                                    height: 1.1,
                                  ),
                                ),
                              ),
                              const Icon(Icons.chevron_right, size: 20, color: Color(0xFFB0B8C4)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  diameters.isEmpty
                                      ? 'Çap yok'
                                      : diameters.map((d) => 'Ø$d').join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF8B95A5),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F1FF),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${diameters.length} çap',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF3B82F6),
                                    height: 1.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppFormat.tonnage(imalat.planned),
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1C2430),
                                        height: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    const Text(
                                      'Planlanan',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF8B95A5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '%${progress.round()}',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: accent,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  const Text(
                                    'Keşif İlerlemesi',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF8B95A5),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 5,
                    backgroundColor: const Color(0xFFE6EBF2),
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color _imalatAccent(String name) {
  final normalized = _foldImalat(name);
  if (normalized.contains('temel') || normalized.contains('kolon')) {
    return const Color(0xFF3B82F6);
  }
  if (normalized.contains('doseme') || normalized.contains('kiris')) {
    return const Color(0xFF8B5CF6);
  }
  if (normalized.contains('merdiven') || normalized.contains('perde')) {
    return const Color(0xFFF59E0B);
  }
  return const Color(0xFF3B82F6);
}

String _imalatThumb(String name) {
  final normalized = _foldImalat(name);
  if (normalized.contains('temel')) return 'assets/images/kesif_temel.jpg';
  if (normalized.contains('kolon')) return 'assets/images/kesif_kolon.jpg';
  if (normalized.contains('perde')) return 'assets/images/kesif_perde.jpg';
  if (normalized.contains('kiris')) return 'assets/images/kesif_kiris.jpg';
  if (normalized.contains('doseme')) return 'assets/images/kesif_doseme.jpg';
  if (normalized.contains('merdiven')) return 'assets/images/kesif_merdiven.jpg';
  return 'assets/images/kesif_imalat.jpg';
}

const _standardImalatOrder = [
  'temel',
  'kolon',
  'perde',
  'kiris',
  'doseme',
  'merdiven',
];

int _imalatRank(String name) {
  final folded = _foldImalat(name);
  final index = _standardImalatOrder.indexWhere(folded.contains);
  return index < 0 ? _standardImalatOrder.length : index;
}

String _foldImalat(String name) {
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

/// İmalat adı penceresi. Denetleyici rota ile birlikte yok edilir;
/// pencere kapanırken hemen [TextEditingController.dispose] kırmızı ekran açar.
class CreateImalatDialog extends StatefulWidget {
  const CreateImalatDialog({super.key});

  @override
  State<CreateImalatDialog> createState() => _CreateImalatDialogState();
}

class _CreateImalatDialogState extends State<CreateImalatDialog> {
  late final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) return;
    Navigator.pop(context, trimmed);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceElevated,
      title: Text('Yeni İmalat', style: AppTypography.titleLarge),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'İmalat adı',
          hintText: 'Örn: Temel, Perde, Döşeme',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Oluştur'),
        ),
      ],
    );
  }
}


