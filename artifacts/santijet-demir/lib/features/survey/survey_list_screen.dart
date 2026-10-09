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
  var _ensuredTypes = false;

  @override
  void initState() {
    super.initState();
    _imalatListScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _ensuredTypes) return;
      _ensuredTypes = true;
      ref.read(surveyProjectProvider.notifier).ensureStandardImalats();
    });
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
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text('Yeni İmalat', style: AppTypography.titleLarge),
        content: TextField(
          controller: nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'İmalat adı',
            hintText: 'Örn: Temel, Perde, Döşeme',
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(ctx, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              final trimmed = nameController.text.trim();
              if (trimmed.isEmpty) return;
              Navigator.pop(ctx, trimmed);
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );

    nameController.dispose();
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

  Future<void> _importSurveyTable() async {
    final canEdit = ref.read(canEditActiveProjectProvider);
    if (!canEdit) {
      ScaffoldMessenger.of(context).showAppSnackBar(
        const SnackBar(content: Text('İçe aktarmak için düzenleme yetkisi gerekir')),
      );
      return;
    }

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx', 'xls', 'csv'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty || !mounted) return;
    final file = picked.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      ScaffoldMessenger.of(context).showAppSnackBar(
        const SnackBar(content: Text('Dosya okunamadı')),
      );
      return;
    }

    final List<SurveyImalat> imalats;
    try {
      imalats = parseSurveyImport(fileName: file.name, bytes: bytes);
    } on SurveyImportException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showAppSnackBar(
        SnackBar(content: Text(error.message)),
      );
      return;
    }

    final hasExisting = ref.read(surveyProjectProvider).imalats.isNotEmpty;
    if (hasExisting) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          title: const Text('İmalat listesini değiştir'),
          content: Text(
            '${imalats.length} imalat içe aktarılacak. Mevcut imalat listesi '
            'bu dosyayla değiştirilir.\n\n$surveyImportFormatHint',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('İçe Aktar'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    await ref.read(surveyProjectProvider.notifier).replaceImportedImalats(imalats);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showAppSnackBar(
      SnackBar(content: Text('${imalats.length} imalat içe aktarıldı')),
    );
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
      floatingActionButton: canEdit
          ? AppFab(
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
              onImport: canEdit ? _importSurveyTable : null,
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
    final orderedShare = _share(imalat.ordered, imalat.planned);
    final deliveredShare = _share(imalat.delivered, imalat.planned);
    final pendingShare = _share(imalat.pending, imalat.planned);
    final remaining = imalat.planned - imalat.delivered;
    final remainingShare = _share(remaining < 0 ? 0 : remaining, imalat.planned);
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
                                      '${AppFormat.tonnage(imalat.planned)} t',
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        value: imalat.ordered,
                        label: 'Sipariş Edilen',
                        percent: orderedShare,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _MiniStat(
                        value: imalat.delivered,
                        label: 'Teslim Alınan',
                        percent: deliveredShare,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _MiniStat(
                        value: imalat.pending,
                        label: 'Bekleyen',
                        percent: pendingShare,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _MiniStat(
                        value: remaining < 0 ? 0 : remaining,
                        label: 'Kalan İhtiyaç',
                        percent: remainingShare,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.value,
    required this.label,
    required this.percent,
    required this.color,
  });

  final double value;
  final String label;
  final int percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${AppFormat.tonnage(value)} t',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8B95A5),
              height: 1.15,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '%$percent',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

int _share(double part, double whole) {
  if (whole <= 0) return 0;
  return (part / whole * 100).round().clamp(0, 999);
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


