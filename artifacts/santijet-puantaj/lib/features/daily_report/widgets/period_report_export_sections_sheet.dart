import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/sj_button.dart';
import '../../../core/design_system/sj_modal.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/providers/period_site_report_export_sections_provider.dart';
import '../../../data/services/period_site_report_export_sections.dart';

/// Haftalık / aylık çıktı — günlük raporla aynı seçim kurgusu + PDF/Excel.
class PeriodReportExportChoice {
  const PeriodReportExportChoice({
    required this.sections,
    required this.pdf,
  });

  final PeriodSiteReportExportSections sections;
  final bool pdf;
}

Future<PeriodReportExportChoice?> showPeriodReportExportSectionsPicker(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  String? subtitle,
}) {
  final sheetTheme = SJModal.sheetThemeOf(context);

  return showModalBottomSheet<PeriodReportExportChoice>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: SJModal.sheetSurface,
    builder: (ctx) => Theme(
      data: sheetTheme,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          MediaQuery.paddingOf(ctx).bottom + AppSpacing.md,
        ),
        child: _PeriodExportSectionsPickerSheet(
          title: title,
          subtitle: subtitle,
          initial: ref.read(periodSiteReportExportSectionsProvider),
        ),
      ),
    ),
  );
}

class _PeriodExportSectionsPickerSheet extends StatefulWidget {
  const _PeriodExportSectionsPickerSheet({
    required this.title,
    required this.initial,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final PeriodSiteReportExportSections initial;

  @override
  State<_PeriodExportSectionsPickerSheet> createState() =>
      _PeriodExportSectionsPickerSheetState();
}

class _PeriodExportSectionsPickerSheetState
    extends State<_PeriodExportSectionsPickerSheet> {
  late PeriodSiteReportExportSections _sections;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sections = widget.initial;
  }

  Widget _sectionTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(title),
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  void _confirm({required bool pdf}) {
    if (!_sections.hasAny) {
      setState(() => _error = 'En az bir başlık seçin.');
      return;
    }
    Navigator.of(context).pop(
      PeriodReportExportChoice(sections: _sections, pdf: pdf),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              widget.subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Son rapordaki seçimler hatırlanır.',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              TextButton(
                onPressed: () => setState(
                  () => _sections = PeriodSiteReportExportSections.all(),
                ),
                child: const Text('Tümünü seç'),
              ),
              TextButton(
                onPressed: () => setState(
                  () => _sections = PeriodSiteReportExportSections.none(),
                ),
                child: const Text('Temizle'),
              ),
            ],
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.42,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                _sectionTile(
                  title: 'Puantaj özeti',
                  value: _sections.puantajCounts,
                  onChanged: (v) => setState(
                    () => _sections = _sections.copyWith(puantajCounts: v),
                  ),
                ),
                _sectionTile(
                  title: 'Personel puantajı',
                  value: _sections.personel,
                  onChanged: (v) => setState(
                    () => _sections = _sections.copyWith(personel: v),
                  ),
                ),
                _sectionTile(
                  title: 'Ekip puantajı',
                  value: _sections.ekip,
                  onChanged: (v) =>
                      setState(() => _sections = _sections.copyWith(ekip: v)),
                ),
                _sectionTile(
                  title: 'Yevmiyeli işler',
                  value: _sections.yevmiyeli,
                  onChanged: (v) => setState(
                    () => _sections = _sections.copyWith(yevmiyeli: v),
                  ),
                ),
                _sectionTile(
                  title: 'Yapılan işler (İmalat)',
                  value: _sections.imalat,
                  onChanged: (v) => setState(
                    () => _sections = _sections.copyWith(imalat: v),
                  ),
                ),
                _sectionTile(
                  title: 'Verim',
                  value: _sections.verim,
                  onChanged: (v) => setState(
                    () => _sections = _sections.copyWith(verim: v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Format', style: theme.textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: SJButton(
                  label: 'PDF',
                  icon: Icons.picture_as_pdf_outlined,
                  expanded: true,
                  onPressed: () => _confirm(pdf: true),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SJButton(
                  label: 'Excel',
                  icon: Icons.table_chart_outlined,
                  variant: SJButtonVariant.secondary,
                  expanded: true,
                  onPressed: () => _confirm(pdf: false),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.critical,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
