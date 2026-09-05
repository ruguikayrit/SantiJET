import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/sj_button.dart';
import '../../core/design_system/sj_empty_state.dart';
import '../../core/design_system/sj_list_item.dart';
import '../../core/design_system/sj_modal.dart';
import '../../core/design_system/sj_status_badge.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_date.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/app_data_provider.dart';
import '../../data/services/quality_export_service.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/quality_sample.dart';

enum _ElementFilter { all, temel, kolon, perde, doseme }

enum _StatusFilter { all, compliant, nonCompliant, pending }

enum _TimeFilter { all, today, last7, last30, thisMonth }

/// Laboratuvar beton basınç dayanım rapor kayıtları.
class QualityScreen extends ConsumerStatefulWidget {
  const QualityScreen({super.key});

  @override
  ConsumerState<QualityScreen> createState() => _QualityScreenState();
}

class _QualityScreenState extends ConsumerState<QualityScreen> {
  _ElementFilter _elementFilter = _ElementFilter.all;
  _StatusFilter _statusFilter = _StatusFilter.all;
  _TimeFilter _timeFilter = _TimeFilter.all;

  static const _elementLabels = {
    _ElementFilter.all: 'Tümü',
    _ElementFilter.temel: 'Temel',
    _ElementFilter.kolon: 'Kolon',
    _ElementFilter.perde: 'Perde',
    _ElementFilter.doseme: 'Döşeme',
  };

  static const _statusLabels = {
    _StatusFilter.all: 'Tümü',
    _StatusFilter.compliant: 'Uygun',
    _StatusFilter.nonCompliant: 'Uygunsuz',
    _StatusFilter.pending: 'Sonuç bekleyen',
  };

  static const _timeLabels = {
    _TimeFilter.all: 'Tümü',
    _TimeFilter.today: 'Bugün',
    _TimeFilter.last7: 'Son 7 gün',
    _TimeFilter.last30: 'Son 30 gün',
    _TimeFilter.thisMonth: 'Bu ay',
  };

  List<QualitySample> _applyFilters(List<QualitySample> samples) {
    final today = AppDate.today();
    return samples.where((s) {
      final elementOk = switch (_elementFilter) {
        _ElementFilter.all => true,
        _ElementFilter.temel => s.elementGroup == ConcreteElementGroup.temel,
        _ElementFilter.kolon => s.elementGroup == ConcreteElementGroup.kolon,
        _ElementFilter.perde => s.elementGroup == ConcreteElementGroup.perde,
        _ElementFilter.doseme => s.elementGroup == ConcreteElementGroup.doseme,
      };
      final statusOk = switch (_statusFilter) {
        _StatusFilter.all => true,
        _StatusFilter.compliant => s.isCompliant == true,
        _StatusFilter.nonCompliant => s.isCompliant == false,
        _StatusFilter.pending => s.isPending,
      };
      final timeOk = _matchesTimeFilter(s.sampleDate, today);
      return elementOk && statusOk && timeOk;
    }).toList();
  }

  bool _matchesTimeFilter(String sampleDate, DateTime today) {
    if (_timeFilter == _TimeFilter.all) return true;
    DateTime? parsed;
    try {
      parsed = AppDate.parse(sampleDate.trim());
    } catch (_) {
      return false;
    }
    final day = DateTime(parsed.year, parsed.month, parsed.day);
    return switch (_timeFilter) {
      _TimeFilter.all => true,
      _TimeFilter.today => day == today,
      _TimeFilter.last7 =>
        !day.isBefore(today.subtract(const Duration(days: 6))) &&
            !day.isAfter(today),
      _TimeFilter.last30 =>
        !day.isBefore(today.subtract(const Duration(days: 29))) &&
            !day.isAfter(today),
      _TimeFilter.thisMonth =>
        day.year == today.year && day.month == today.month,
    };
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(activeProjectProvider);
    final samples = ref.watch(activeQualityProvider);
    final filtered = _applyFilters(samples);
    final canExport = project != null && filtered.isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SantijetHeader(
              subtitle: 'Test',
              avatarInitial: 'SJ',
              actionsBeforeSettings: [
                SantijetHeaderDownloadButton(
                  tooltip: 'Rapor Al',
                  onDarkBand: true,
                  enabled: canExport,
                  onPressed: () {
                    final p = project;
                    if (p == null || filtered.isEmpty) return;
                    _raporAl(context, project: p, samples: filtered);
                  },
                ),
              ],
            ),
            Expanded(
              child: project == null
                  ? const SJEmptyState(
                      title: 'Proje seçin',
                      message:
                          'Basınç dayanım raporları proje kapsamında tutulur.',
                      icon: Icons.apartment_outlined,
                    )
                  : samples.isEmpty
                      ? const SJEmptyState(
                          title: 'Rapor yok',
                          message:
                              'Laboratuvar basınç dayanım raporundaki önemli '
                              'alanları Temel / Kolon / Perde / Döşeme '
                              'gruplarında kaydedin.',
                          icon: Icons.science_outlined,
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.md,
                                AppSpacing.sm,
                                AppSpacing.md,
                                0,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _FilterDropdown<_ElementFilter>(
                                      caption: 'Yapısal eleman',
                                      valueLabel:
                                          _elementLabels[_elementFilter]!,
                                      selected: _elementFilter,
                                      items: [
                                        for (final e in _ElementFilter.values)
                                          (value: e, label: _elementLabels[e]!),
                                      ],
                                      onSelected: (v) => setState(
                                        () => _elementFilter = v,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: _FilterDropdown<_StatusFilter>(
                                      caption: 'Durum',
                                      valueLabel: _statusLabels[_statusFilter]!,
                                      selected: _statusFilter,
                                      items: [
                                        for (final e in _StatusFilter.values)
                                          (value: e, label: _statusLabels[e]!),
                                      ],
                                      onSelected: (v) => setState(
                                        () => _statusFilter = v,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: _FilterDropdown<_TimeFilter>(
                                      caption: 'Zaman',
                                      valueLabel: _timeLabels[_timeFilter]!,
                                      selected: _timeFilter,
                                      items: [
                                        for (final e in _TimeFilter.values)
                                          (value: e, label: _timeLabels[e]!),
                                      ],
                                      onSelected: (v) => setState(
                                        () => _timeFilter = v,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: filtered.isEmpty
                                  ? const SJEmptyState(
                                      title: 'Filtrede sonuç yok',
                                      message:
                                          'Seçili yapısal eleman, durum veya '
                                          'zaman filtresine uyan rapor bulunamadı.',
                                      icon: Icons.filter_alt_off_outlined,
                                    )
                                  : ListView.separated(
                                      padding: const EdgeInsets.fromLTRB(
                                        AppSpacing.md,
                                        AppSpacing.sm,
                                        AppSpacing.md,
                                        AppSpacing.md,
                                      ),
                                      itemCount: filtered.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(
                                        height: AppSpacing.sm,
                                      ),
                                      itemBuilder: (context, index) {
                                        final s = filtered[index];
                                        final strength = s.strengthMpa == null
                                            ? 'Sonuç bekleniyor'
                                            : 'Ort. ${s.strengthMpa!.toStringAsFixed(1)} MPa';
                                        final min = s.minStrengthMpa == null
                                            ? null
                                            : 'Min ${s.minStrengthMpa!.toStringAsFixed(1)} MPa';
                                        final compliance =
                                            switch (s.isCompliant) {
                                          true => 'Uygun',
                                          false => 'Uygunsuz',
                                          null => s.isPending
                                              ? 'Bekliyor'
                                              : 'Karar yok',
                                        };
                                        return SJListItem(
                                          title: s.sampleCode.isEmpty
                                              ? (s.labReportNo.isEmpty
                                                  ? s.elementGroup.label
                                                  : s.labReportNo)
                                              : s.sampleCode,
                                          subtitle: [
                                            '${s.elementGroup.label} · ${s.concreteClass}',
                                            '${s.sampleDate} · ${s.ageDays} gün · $strength',
                                            if (min != null) min,
                                            if (s.labReportNo.isNotEmpty)
                                              'Rapor: ${s.labReportNo}',
                                          ].join('\n'),
                                          leadingIcon: Icons.science_outlined,
                                          accentColor: switch (s.isCompliant) {
                                            true => AppColors.success,
                                            false => AppColors.critical,
                                            null => s.isPending
                                                ? AppColors.partial
                                                : AppColors.info,
                                          },
                                          trailing: SJStatusBadge(
                                            label: compliance,
                                            color: switch (s.isCompliant) {
                                              true => AppColors.success,
                                              false => AppColors.critical,
                                              null => s.isPending
                                                  ? AppColors.partial
                                                  : AppColors.info,
                                            },
                                          ),
                                          onTap: () => _openEditor(
                                            context,
                                            ref,
                                            existing: s,
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
            ),
            if (project != null) _bottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _bottomActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: SizedBox(
        width: double.infinity,
        child: FloatingActionButton.extended(
          heroTag: 'test-rapor-ekle',
          onPressed: () => _openEditor(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Rapor Ekle'),
        ),
      ),
    );
  }

  Future<void> _raporAl(
    BuildContext context, {
    required Project project,
    required List<QualitySample> samples,
  }) async {
    final choice = await SJModal.showSheet<String>(
      context: context,
      title: 'Rapor Al',
      child: Builder(
        builder: (sheetContext) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SJButton(
                label: 'PDF',
                icon: Icons.picture_as_pdf_outlined,
                expanded: true,
                onPressed: () => Navigator.pop(sheetContext, 'pdf'),
              ),
              const SizedBox(height: AppSpacing.sm),
              SJButton(
                label: 'Excel',
                icon: Icons.table_chart_outlined,
                variant: SJButtonVariant.secondary,
                expanded: true,
                onPressed: () => Navigator.pop(sheetContext, 'excel'),
              ),
            ],
          );
        },
      ),
    );
    if (!context.mounted || choice == null) return;
    if (choice == 'pdf') {
      await _exportPdf(context, project: project, samples: samples);
    } else if (choice == 'excel') {
      await _exportExcel(context, project: project, samples: samples);
    }
  }

  Future<void> _exportPdf(
    BuildContext context, {
    required Project project,
    required List<QualitySample> samples,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('PDF hazırlanıyor...')),
    );
    try {
      await qualityExportService.sharePdf(
        project: project,
        samples: samples,
      );
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('PDF paylaşım için hazırlandı.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('PDF oluşturulamadı: $e')),
      );
    }
  }

  Future<void> _exportExcel(
    BuildContext context, {
    required Project project,
    required List<QualitySample> samples,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Excel hazırlanıyor...')),
    );
    try {
      await qualityExportService.shareExcel(
        project: project,
        samples: samples,
      );
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Excel paylaşım için hazırlandı.')),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Excel oluşturulamadı: $e')),
      );
    }
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    QualitySample? existing,
  }) async {
    final project = ref.read(activeProjectProvider);
    if (project == null) return;

    final dateCtrl = TextEditingController(
      text: existing?.sampleDate ?? AppDate.format(AppDate.today()),
    );
    final codeCtrl =
        TextEditingController(text: existing?.sampleCode ?? '');
    final reportCtrl =
        TextEditingController(text: existing?.labReportNo ?? '');
    final classCtrl =
        TextEditingController(text: existing?.concreteClass ?? 'C30/37');
    final strengthCtrl = TextEditingController(
      text: existing?.strengthMpa?.toStringAsFixed(1) ?? '',
    );
    final minCtrl = TextEditingController(
      text: existing?.minStrengthMpa?.toStringAsFixed(1) ?? '',
    );
    final slagCtrl = TextEditingController(text: existing?.slagNote ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    var ageDays = existing?.ageDays ?? 28;
    var elementGroup = existing?.elementGroup ?? ConcreteElementGroup.temel;
    var compliance = existing?.isCompliant; // null / true / false

    final saved = await SJModal.showSheet<bool>(
      context: context,
      title: existing == null ? 'Yeni basınç raporu' : 'Raporu düzenle',
      child: StatefulBuilder(
        builder: (ctx, setLocal) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<ConcreteElementGroup>(
                value: elementGroup,
                decoration: const InputDecoration(
                  labelText: 'Yapısal eleman grubu',
                ),
                items: [
                  for (final g in ConcreteElementGroup.values)
                    DropdownMenuItem(value: g, child: Text(g.label)),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setLocal(() => elementGroup = v);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: reportCtrl,
                decoration: const InputDecoration(
                  labelText: 'Laboratuvar rapor no',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Numune kodu',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: dateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Numune / deney tarihi (gg.aa.yyyy)',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: classCtrl,
                decoration: const InputDecoration(
                  labelText: 'Beton sınıfı',
                  hintText: 'C30/37',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<int>(
                value: ageDays,
                decoration: const InputDecoration(labelText: 'Yaş (gün)'),
                items: const [
                  DropdownMenuItem(value: 7, child: Text('7')),
                  DropdownMenuItem(value: 28, child: Text('28')),
                  DropdownMenuItem(value: 56, child: Text('56')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setLocal(() => ageDays = v);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: strengthCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ortalama basınç dayanımı (MPa)',
                  hintText: 'Boş = bekliyor',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: minCtrl,
                decoration: const InputDecoration(
                  labelText: 'En düşük deney sonucu (MPa)',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                value: switch (compliance) {
                  true => 'pass',
                  false => 'fail',
                  null => 'pending',
                },
                decoration: const InputDecoration(
                  labelText: 'Rapor sonucu',
                ),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Bekliyor')),
                  DropdownMenuItem(value: 'pass', child: Text('Uygun')),
                  DropdownMenuItem(value: 'fail', child: Text('Uygunsuz')),
                ],
                onChanged: (v) {
                  setLocal(() {
                    compliance = switch (v) {
                      'pass' => true,
                      'fail' => false,
                      _ => null,
                    };
                  });
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: slagCtrl,
                decoration: const InputDecoration(
                  labelText: 'Cüruf / katkı notu (opsiyonel)',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Not'),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: SJButton(
                      label: 'İptal',
                      variant: SJButtonVariant.secondary,
                      expanded: true,
                      onPressed: () => Navigator.pop(ctx, false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: SJButton(
                      label: 'Kaydet',
                      expanded: true,
                      onPressed: () {
                        if (codeCtrl.text.trim().isEmpty &&
                            reportCtrl.text.trim().isEmpty) {
                          return;
                        }
                        Navigator.pop(ctx, true);
                      },
                    ),
                  ),
                ],
              ),
              if (existing != null) ...[
                const SizedBox(height: AppSpacing.sm),
                SJButton(
                  label: 'Sil',
                  variant: SJButtonVariant.destructive,
                  expanded: true,
                  onPressed: () async {
                    final ok = await SJModal.confirm(
                      context: ctx,
                      title: 'Raporu sil',
                      message: 'Bu basınç dayanım kaydı silinsin mi?',
                      confirmLabel: 'Sil',
                      destructive: true,
                    );
                    if (!ok || !ctx.mounted) return;
                    ref.read(qualityProvider.notifier).delete(existing.id);
                    Navigator.pop(ctx, false);
                  },
                ),
              ],
            ],
          );
        },
      ),
    );

    if (saved != true) return;
    final strengthRaw = strengthCtrl.text.trim().replaceAll(',', '.');
    final strength =
        strengthRaw.isEmpty ? null : double.tryParse(strengthRaw);
    final minRaw = minCtrl.text.trim().replaceAll(',', '.');
    final minStrength = minRaw.isEmpty ? null : double.tryParse(minRaw);
    final code = codeCtrl.text.trim().isEmpty
        ? reportCtrl.text.trim()
        : codeCtrl.text.trim();

    var draft = QualitySample(
      id: existing?.id ?? '',
      projectId: project.id,
      pourRecordId: existing?.pourRecordId,
      elementGroup: elementGroup,
      labReportNo: reportCtrl.text.trim(),
      sampleDate: dateCtrl.text.trim(),
      sampleCode: code,
      concreteClass: classCtrl.text.trim().isEmpty
          ? 'C30/37'
          : classCtrl.text.trim(),
      ageDays: ageDays,
      strengthMpa: strength,
      minStrengthMpa: minStrength,
      isCompliant: compliance,
      slagNote: slagCtrl.text.trim(),
      notes: notesCtrl.text.trim(),
    );

    if (existing == null) {
      ref.read(qualityProvider.notifier).add(draft);
    } else {
      ref.read(qualityProvider.notifier).update(
            draft.copyWith(
              clearStrength: strength == null,
              clearMinStrength: minStrength == null,
              clearCompliance: compliance == null,
            ),
          );
    }
  }
}

/// Saha görev filtreleri ile aynı açılır menü deseni.
class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.caption,
    required this.valueLabel,
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  final String caption;
  final String valueLabel;
  final List<({T value, String label})> items;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = selected != items.first.value;

    return PopupMenuButton<T>(
      padding: EdgeInsets.zero,
      offset: const Offset(0, 44),
      onSelected: onSelected,
      itemBuilder: (ctx) => [
        for (final item in items)
          PopupMenuItem<T>(
            value: item.value,
            child: Row(
              children: [
                Expanded(child: Text(item.label)),
                if (item.value == selected)
                  Icon(
                    Icons.check,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
              ],
            ),
          ),
      ],
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.electricBlue.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: AppRadii.sm,
          border: Border.all(
            color: isActive
                ? AppColors.electricBlue.withValues(alpha: 0.85)
                : theme.dividerColor.withValues(alpha: 0.55),
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    valueLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.expand_more,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
