import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/core/theme/app_colors.dart';
import 'package:santijet_demir/core/theme/app_radii.dart';
import 'package:santijet_demir/core/theme/app_spacing.dart';
import 'package:santijet_demir/core/theme/app_typography.dart';
import 'package:santijet_demir/data/services/dxf_rebar_parser.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';
import 'package:santijet_demir/features/projects/providers/project_provider.dart';
import 'package:santijet_demir/features/rebar_metraj/providers/rebar_metraj_provider.dart';
import 'package:santijet_demir/features/rebar_metraj/providers/rebar_metraj_storage_provider.dart';
import 'package:santijet_demir/features/rebar_metraj/widgets/metraj_survey_actions.dart';
import 'package:santijet_demir/features/rebar_metraj/widgets/rebar_label_details_section.dart';
import 'package:santijet_demir/features/survey/providers/survey_provider.dart';

class RebarMetrajPanel extends ConsumerStatefulWidget {
  const RebarMetrajPanel({super.key});

  @override
  ConsumerState<RebarMetrajPanel> createState() => _RebarMetrajPanelState();
}

class _RebarMetrajPanelState extends ConsumerState<RebarMetrajPanel>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureActiveProject());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _ensureActiveProject() async {
    if (ref.read(activeProjectIdProvider) != null) return;

    final projects = ref.read(userProjectsProvider);
    if (projects.isEmpty) {
      try {
        await ref.read(projectsControllerProvider).ensureMigratedFromLegacy();
      } catch (_) {
        // Yerel proje oluşturulamazsa kullanıcı proje listesine yönlendirilir.
      }
    }

    final activeId = ref.read(activeProjectIdProvider);
    if (activeId != null) return;

    final nextProjects = ref.read(userProjectsProvider);
    if (nextProjects.isNotEmpty) {
      await ref.read(projectsControllerProvider).switchProject(nextProjects.first.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    ref.listen(rebarMetrajResultProvider, (previous, next) {
      if (next != null && previous != next && !ref.read(rebarMetrajLoadingProvider)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(0);
          }
        });
      }
    });

    final result = ref.watch(rebarMetrajResultProvider);
    final loading = ref.watch(rebarMetrajLoadingProvider);
    final error = ref.watch(rebarMetrajErrorProvider);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final showResults = result != null && !loading;

    return Material(
      color: AppColors.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md + bottomInset,
              ),
              children: [
                const _InfoBanner(),
                const SizedBox(height: 16),
                _UploadCard(
                  loading: loading,
                  canClear: result != null,
                  onPickFile: () => _pickAndParse(context, ref),
                  onClear: () => _clearMetraj(ref),
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  _ErrorBanner(message: error),
                ],
                if (showResults) ...[
                  const SizedBox(height: 20),
                  _ResultSummaryBar(result: result),
                  const SizedBox(height: 6),
                  Text(
                    '${result.fileName} · ${result.sourceFormat}',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  Text('Çap Bazlı Metraj', style: AppTypography.headlineMedium),
                  const SizedBox(height: 12),
                  ...result.lines.map((line) => _MetrajLineCard(line: line)),
                  if (result.textDetails.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    RebarLabelDetailsSection(details: result.textDetails),
                  ],
                  if (result.warnings.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _WarningsCard(warnings: result.warnings),
                  ],
                  if (result.skippedEntityCount > 0) ...[
                    const SizedBox(height: 12),
                    _SkippedHint(count: result.skippedEntityCount),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndParse(BuildContext context, WidgetRef ref) async {
    await _ensureActiveProject();

    ref.read(rebarMetrajErrorProvider.notifier).state = null;

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['dwg'],
      withData: true,
    );

    if (picked == null || picked.files.isEmpty) return;

    final file = picked.files.first;
    final fileName = file.name;
    final extension = fileName.split('.').last.toLowerCase();

    final bytes = file.bytes;
    if (bytes == null) {
      ref.read(rebarMetrajErrorProvider.notifier).state =
          'Dosya okunamadı. Lütfen tekrar deneyin.';
      return;
    }

    if (extension != 'dwg') {
      ref.read(rebarMetrajErrorProvider.notifier).state =
          'Yalnızca DWG dosyaları desteklenir.';
      return;
    }

    ref.read(rebarMetrajLoadingProvider.notifier).state = true;
    try {
      if (!DxfRebarParser.isDwgBytes(bytes)) {
        throw const FormatException('Geçerli bir DWG dosyası seçin.');
      }
      final parser = ref.read(dxfRebarParserProvider);
      final result =
          await parser.parseDwgBytes(fileName: fileName, bytes: bytes);
      ref.read(rebarMetrajResultProvider.notifier).state = result;
    } on FormatException catch (e) {
      ref.read(rebarMetrajErrorProvider.notifier).state = e.message;
    } catch (e) {
      ref.read(rebarMetrajErrorProvider.notifier).state =
          'DWG dosyası işlenemedi. Sayfayı yenileyip tekrar deneyin. '
          'Etiketlerde adet, çap (FI/Ø) ve l= boy birlikte olmalı '
          '(ör. üst.334Ø22/15 l=1200).';
    } finally {
      ref.read(rebarMetrajLoadingProvider.notifier).state = false;
    }
  }

  void _clearMetraj(WidgetRef ref) {
    ref.read(rebarMetrajResultProvider.notifier).state = null;
    ref.read(rebarMetrajErrorProvider.notifier).state = null;
    ref.read(rebarMetrajLoadingProvider.notifier).state = false;
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.electricBlue.withValues(alpha: 0.08),
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.electricBlue.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.architecture, color: AppColors.electricBlueLight, size: 20),
              const SizedBox(width: 8),
              Text('CAD\'den otomatik metraj', style: AppTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '1. AutoCAD/BricsCAD projesini DWG olarak yükleyin\n'
            '2. üst.334Ø22/15 l=1200 → 334 ad × 12 m (aralık hesaba katılmaz)\n'
            '3. 15000Ø16 l=200 → 15000 ad × 2 m\n'
            '4. Tonaj = adet × boy × birim ağırlık (kg/m)\n'
            '5. Analiz sonuçlarını kaydırın; üstte Ön İmalata Gönder\n'
            '6. Ön İmalat sekmesinde analiz onayı verin; Hesap ve Analiz sayfasından yükleyin',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'DWG dosyaları web tarayıcıda doğrudan okunur.',
            style: AppTypography.labelMedium.copyWith(color: AppColors.success),
          ),
        ],
      ),
    );
  }
}

class _UploadCard extends StatelessWidget {
  const _UploadCard({
    required this.loading,
    required this.canClear,
    required this.onPickFile,
    required this.onClear,
  });

  final bool loading;
  final bool canClear;
  final VoidCallback onPickFile;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.upload_file, size: 48, color: AppColors.electricBlueLight),
          const SizedBox(height: 12),
          Text('CAD Dosyası Yükle', style: AppTypography.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'DWG',
            style: AppTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: loading ? null : onPickFile,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(borderRadius: AppRadii.sm),
                  ),
                  icon: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.folder_open, size: 18),
                  label: Text(loading ? 'İşleniyor...' : 'Dosya Seç'),
                ),
              ),
              if (canClear) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: loading ? null : onClear,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.diameter28,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.diameter28.withValues(alpha: 0.38),
                      disabledForegroundColor:
                          Colors.white.withValues(alpha: 0.72),
                      elevation: 0,
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      shape: RoundedRectangleBorder(borderRadius: AppRadii.sm),
                    ),
                    icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                    label: Text(
                      'Metrajı Temizle',
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.critical.withValues(alpha: 0.1),
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.critical.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.critical, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: AppTypography.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _ResultSummaryBar extends ConsumerWidget {
  const _ResultSummaryBar({required this.result});

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
    final tonnageLabel = AppFormat.tonnage(result.totalTonnage);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: AppColors.electricBlueGlow,
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadii.md,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.electricBlue.withValues(alpha: 0.9),
                    AppColors.electricBlueLight.withValues(alpha: 0.45),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.electricBlue.withValues(alpha: 0.22),
                              AppColors.electricBlue.withValues(alpha: 0.06),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.electricBlue.withValues(alpha: 0.28),
                          ),
                        ),
                        child: const Icon(
                          Icons.analytics_outlined,
                          color: AppColors.electricBlueLight,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Toplam Tonaj',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  tonnageLabel,
                                  style: AppTypography.displaySmall.copyWith(
                                    color: AppColors.electricBlueLight,
                                    fontSize: 28,
                                    height: 1,
                                  ),
                                ),
                                Text(
                                  ' t',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isSaved)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: AppRadii.full,
                            border: Border.all(
                              color: AppColors.success.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            'Kayıtlı',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 14),
                  Text('Aktarım', style: AppTypography.labelMedium),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: projectId == null
                        ? () => context.push(AppRoutes.projects)
                        : isSaved
                            ? () =>
                                ref.read(surveyTabIndexProvider.notifier).state =
                                    2
                            : () => saveMetrajResultToPreProduction(
                                  context,
                                  ref,
                                  result,
                                ),
                    icon: Icon(
                      projectId == null
                          ? Icons.folder_open_outlined
                          : isSaved
                              ? Icons.check_circle_outline
                              : Icons.send_outlined,
                      size: 18,
                    ),
                    label: Text(
                      projectId == null
                          ? 'Proje Seç'
                          : isSaved
                              ? 'Ön İmalat\'ta Gör'
                              : 'Ön İmalata Gönder',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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

class _MetrajLineCard extends StatelessWidget {
  const _MetrajLineCard({required this.line});

  final RebarMetrajLine line;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00', 'tr_TR');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.electricBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Ø${line.diameter}',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.electricBlueLight,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ø${line.diameter} demir', style: AppTypography.titleMedium),
                Text(
                  '${line.barCount} çubuk · ${formatter.format(line.totalLengthM)} m',
                  style: AppTypography.bodySmall,
                ),
                if (line.layerName.isNotEmpty)
                  Text(
                    line.layerName,
                    style: AppTypography.labelMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${formatter.format(line.tonnage)} t',
                style: AppTypography.titleMedium.copyWith(color: AppColors.success),
              ),
              Text(
                '${formatter.format(line.weightKg)} kg',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WarningsCard extends StatelessWidget {
  const _WarningsCard({required this.warnings});

  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: AppRadii.md,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Uyarılar', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          ...warnings.map(
            (warning) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $warning', style: AppTypography.bodySmall),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkippedHint extends StatelessWidget {
  const _SkippedHint({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$count CAD metni demir etiketi olarak tanınmadı (adet + çap + boy yok).',
      style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
    );
  }
}
