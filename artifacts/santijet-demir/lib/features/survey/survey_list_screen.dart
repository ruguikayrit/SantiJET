import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/data/services/export_service.dart';
import 'package:santijet_demir/domain/entities/survey.dart';
import 'package:santijet_demir/features/rebar_metraj/widgets/rebar_metraj_panel.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';
import 'package:santijet_demir/features/survey/saved_metraj_list_tab.dart';

class SurveyListScreen extends ConsumerStatefulWidget {
  const SurveyListScreen({super.key});

  @override
  ConsumerState<SurveyListScreen> createState() => _SurveyListScreenState();
}

class _SurveyListScreenState extends ConsumerState<SurveyListScreen>
    with SingleTickerProviderStateMixin {
  static const _tabCount = 3;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
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
            onPressed: () {},
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
            Tab(text: 'Demir Metraj'),
            Tab(text: 'Metraj'),
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
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _ProjectMetaRow(project: project),
                const SizedBox(height: 16),
                Text('İmalat Listesi', style: AppTypography.headlineMedium),
                const SizedBox(height: 12),
                ...project.imalats.map(
                  (imalat) => SurveyImalatCard(
                    imalat: imalat,
                    expanded: expandedId == imalat.id,
                    onToggle: () {
                      ref.read(expandedImalatProvider.notifier).state =
                          expandedId == imalat.id ? null : imalat.id;
                    },
                    onDetail: () {
                      ref.read(selectedImalatProvider.notifier).state = imalat;
                      context.push('${AppRoutes.survey}/${imalat.id}');
                    },
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
    required this.onToggle,
    required this.onDetail,
  });

  final SurveyImalat imalat;
  final bool expanded;
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
                      imalat.diameters.map((d) => 'Ø$d').join(' · '),
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
                children: [
                  Row(
                    children: const [
                      Expanded(child: Text('ÇAP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted))),
                      Expanded(child: Text('MİKTAR (ton)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted))),
                      Expanded(child: Text('ORAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...imalat.diameterLines.map((line) {
                    final color = AppColors.diameterColor(line.diameter);
                    final ratio = line.planned / imalat.planned * 100;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('Ø${line.diameter}', style: AppTypography.titleMedium.copyWith(color: color)),
                          ),
                          Expanded(
                            child: Text(
                              line.planned.toStringAsFixed(0),
                              style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: AppRadii.full,
                                    child: LinearProgressIndicator(
                                      value: ratio / 100,
                                      minHeight: 4,
                                      backgroundColor: AppColors.border,
                                      color: color,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${ratio.toStringAsFixed(0)}%',
                                  style: AppTypography.labelMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
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

class _BottomActions extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _ActionChip(
          icon: Icons.table_chart,
          label: 'Excel Aktar',
          onPressed: () => _exportExcel(context),
        ),
        _ActionChip(
          icon: Icons.picture_as_pdf,
          label: 'PDF Görüntüle',
          onPressed: () => _previewPdf(context),
        ),
        _ActionChip(icon: Icons.edit, label: 'Keşif Güncelle'),
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
