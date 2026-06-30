import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/core/widgets/swipe_to_delete_row.dart';
import 'package:santijet_demir/data/services/export_service.dart';
import 'package:santijet_demir/domain/entities/survey.dart';
import 'package:santijet_demir/data/services/project_backup_service.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/settings/providers/backup_provider.dart';
import 'package:santijet_demir/features/rebar_metraj/widgets/rebar_metraj_panel.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';
import 'package:santijet_demir/features/survey/saved_metraj_list_tab.dart';
import 'package:santijet_demir/features/survey/widgets/imalat_diameter_editor.dart';

class SurveyListScreen extends ConsumerStatefulWidget {
  const SurveyListScreen({super.key});

  @override
  ConsumerState<SurveyListScreen> createState() => _SurveyListScreenState();
}

class _SurveyListScreenState extends ConsumerState<SurveyListScreen>
    with SingleTickerProviderStateMixin {
  static const _tabCount = 3;
  late final TabController _tabController;
  late final ScrollController _imalatListScrollController;

  @override
  void initState() {
    super.initState();
    _imalatListScrollController = ScrollController();
    final initialTab = ref.read(surveyTabIndexProvider);
    _tabController = TabController(
      length: _tabCount,
      vsync: this,
      initialIndex: initialTab.clamp(0, _tabCount - 1),
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(surveyTabIndexProvider.notifier).state = _tabController.index;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tab = GoRouterState.of(context).uri.queryParameters['tab'];
    final targetIndex = switch (tab) {
      'cad' || 'metraj' => 1,
      'records' || 'kayit' => 2,
      _ => null,
    };
    if (targetIndex != null && _tabController.index != targetIndex) {
      _tabController.index = targetIndex;
      ref.read(surveyTabIndexProvider.notifier).state = targetIndex;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
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
    ref.read(surveyTabIndexProvider.notifier).state = 0;
    _scrollToImalatListEnd();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${imalat.name}" imalatı oluşturuldu'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(surveyTabIndexProvider, (previous, next) {
      if (_tabController.index != next) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _tabController.index != next) {
            _tabController.animateTo(next.clamp(0, _tabCount - 1));
          }
        });
      }
    });

    final project = ref.watch(surveyProjectProvider);
    final expandedId = ref.watch(expandedImalatProvider);
    final tabIndex = ref.watch(surveyTabIndexProvider);
    final canEdit = ref.watch(canEditActiveProjectProvider);
    final screenBg = AppColors.canvas;

    return Scaffold(
      backgroundColor: screenBg,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: screenBg,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Keşif', style: AppTypography.titleLarge),
            Text(project.projectName, style: AppTypography.labelMedium),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: canEdit ? _showCreateImalatDialog : null,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Yeni İmalat'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.electricBlueLight,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.electricBlueLight,
          tabs: const [
            Tab(text: 'İmalat Listesi'),
            Tab(text: 'Otomatik Metraj'),
            Tab(text: 'Ön İmalat'),
          ],
        ),
      ),
      body: ColoredBox(
        color: screenBg,
        child: IndexedStack(
          index: tabIndex.clamp(0, _tabCount - 1),
          children: [
            Material(
              color: screenBg,
              child: ListView(
              controller: _imalatListScrollController,
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _ProjectMetaRow(project: project),
                const SizedBox(height: 16),
                Text('İmalat Listesi', style: AppTypography.headlineMedium),
                const SizedBox(height: 12),
                ...project.imalats.map(
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
                      expanded: expandedId == imalat.id,
                      canEdit: canEdit,
                      onToggle: () {
                        final currentExpanded =
                            ref.read(expandedImalatProvider);
                        ref.read(expandedImalatProvider.notifier).state =
                            currentExpanded == imalat.id ? null : imalat.id;
                      },
                      onDetail: () {
                        ref.read(selectedImalatProvider.notifier).state =
                            imalat;
                        context.push('${AppRoutes.survey}/${imalat.id}');
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _BottomActions(project: project),
              ],
              ),
            ),
            const SizedBox.expand(child: RebarMetrajPanel()),
            const SizedBox.expand(child: SavedMetrajListTab()),
          ],
        ),
      ),
    );
  }
}

class _ProjectMetaRow extends StatelessWidget {
  const _ProjectMetaRow({required this.project});

  final SurveyProject project;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _MetaItem(label: 'Proje', value: project.projectName),
          _MetaItem(
            label: 'Tarih',
            value:
                '${project.date.day}.${project.date.month}.${project.date.year}',
          ),
          _MetaItem(label: 'Revizyon', value: project.revision),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.labelMedium),
          Text(value, style: AppTypography.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class SurveyImalatCard extends StatelessWidget {
  const SurveyImalatCard({
    super.key,
    required this.imalat,
    required this.expanded,
    required this.canEdit,
    required this.onToggle,
    required this.onDetail,
  });

  final SurveyImalat imalat;
  final bool expanded;
  final bool canEdit;
  final VoidCallback onToggle;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              borderRadius: AppRadii.md,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(imalat.name, style: AppTypography.titleLarge),
                        Icon(
                          expanded ? Icons.expand_less : Icons.expand_more,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${imalat.totalTonnage.toStringAsFixed(0)}t',
                          style: AppTypography.kpiValue.copyWith(fontSize: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '%${imalat.progressPercent.toStringAsFixed(0)}',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.electricBlueLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      imalat.diameterLines.isEmpty
                          ? 'Çap/miktar girilmedi'
                          : imalat.diameters.map((d) => 'Ø$d').join(' · '),
                      style: AppTypography.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: AppRadii.full,
                      child: LinearProgressIndicator(
                        value: imalat.progressPercent / 100,
                        minHeight: 4,
                        backgroundColor: AppColors.border,
                        color: AppColors.electricBlueLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ImalatDiameterEditor(
                    imalat: imalat,
                    canEdit: canEdit,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onDetail,
                      child: const Text('İmalat Detayı →'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BottomActions extends ConsumerWidget {
  const _BottomActions({required this.project});

  final SurveyProject project;

  List<String> get _headers => const ['İmalat', 'Çap', 'Miktar (ton)', 'Oran (%)'];

  List<List<String>> _buildRows() {
    final rows = <List<String>>[];
    for (final imalat in project.imalats) {
      for (final line in imalat.diameterLines) {
        final ratio = imalat.planned > 0
            ? (line.planned / imalat.planned * 100).toStringAsFixed(0)
            : '0';
        rows.add([
          imalat.name,
          'Ø${line.diameter}',
          line.planned.toStringAsFixed(0),
          ratio,
        ]);
      }
    }
    return rows;
  }

  Future<void> _exportExcel(BuildContext context) async {
    try {
      await exportService.shareExcel(
        title: 'Keşif Raporu',
        headers: _headers,
        rows: _buildRows(),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Keşif Excel olarak dışa aktarıldı')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dışa aktarma hatası: $e')),
        );
      }
    }
  }

  Future<void> _exportSurveyJson(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(projectBackupControllerProvider).exportSurvey();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Keşif verisi JSON olarak dışa aktarıldı')),
        );
      }
    } on BackupParseException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dışa aktarma hatası: $e')),
        );
      }
    }
  }

  Future<void> _importSurveyJson(BuildContext context, WidgetRef ref) async {
    final canEdit = ref.read(canEditActiveProjectProvider);
    if (!canEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İçe aktarmak için düzenleme yetkisi gerekir')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text('Keşif Verisini İçe Aktar'),
        content: const Text(
          'Seçilen keşif yedeği aktif projeye yazılır. Mevcut imalat listesi '
          've çap/miktar verileri değiştirilir. Devam edilsin mi?',
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

    if (confirmed != true || !context.mounted) return;

    try {
      final summary = await ref.read(projectBackupControllerProvider).importBackup(
            expectedScope: BackupScope.survey,
          );
      if (!context.mounted || summary.cancelled) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keşif verisi içe aktarıldı')),
      );
    } on BackupParseException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('İçe aktarma hatası: $e')),
        );
      }
    }
  }

  Future<void> _previewPdf(BuildContext context) async {
    try {
      await exportService.previewPdf(
        title: 'Keşif Raporu — ${project.projectName}',
        headers: _headers,
        rows: _buildRows(),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF önizleme hatası: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canEdit = ref.watch(canEditActiveProjectProvider);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ActionChip(
          icon: Icons.upload,
          label: 'Dışa Aktar',
          onPressed: () => _exportSurveyJson(context, ref),
        ),
        _ActionChip(
          icon: Icons.download,
          label: 'İçe Aktar',
          onPressed: canEdit ? () => _importSurveyJson(context, ref) : null,
        ),
        _ActionChip(
          icon: Icons.table_chart,
          label: 'Excel Dışa Aktar',
          onPressed: () => _exportExcel(context),
        ),
        _ActionChip(
          icon: Icons.picture_as_pdf,
          label: 'PDF Görüntüle',
          onPressed: () => _previewPdf(context),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppColors.electricBlueLight),
      label: Text(label, style: AppTypography.labelMedium),
      backgroundColor: AppColors.surfaceElevated,
      side: const BorderSide(color: AppColors.border),
      onPressed: onPressed,
    );
  }
}
