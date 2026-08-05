import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/sj_button.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/providers/daily_report_export_sections_provider.dart';
import '../../../data/services/daily_report_export_sections.dart';

/// Çıktıda yer alacak başlık seçimi — son seçim hafızadan gelir, onayda kaydedilir.
Future<DailyReportExportSections?> showDailyReportExportSectionsPicker(
  BuildContext context,
  WidgetRef ref, {
  String title = 'Çıktıda yer alacak başlıklar',
  String? subtitle,
  String confirmLabel = 'PDF Oluştur',
}) {
  return showModalBottomSheet<DailyReportExportSections>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surfaceElevated,
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        MediaQuery.paddingOf(ctx).bottom + AppSpacing.md,
      ),
      child: _ExportSectionsPickerSheet(
        title: title,
        subtitle: subtitle,
        confirmLabel: confirmLabel,
        initial: ref.read(dailyReportExportSectionsProvider),
      ),
    ),
  );
}

class _ExportSectionsPickerSheet extends StatefulWidget {
  const _ExportSectionsPickerSheet({
    required this.title,
    required this.confirmLabel,
    required this.initial,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final String confirmLabel;
  final DailyReportExportSections initial;

  @override
  State<_ExportSectionsPickerSheet> createState() =>
      _ExportSectionsPickerSheetState();
}

class _ExportSectionsPickerSheetState
    extends State<_ExportSectionsPickerSheet> {
  late DailyReportExportSections _sections;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sections = widget.initial;
  }

  Widget _sectionTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: (v) => onChanged(v ?? false),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  void _confirm() {
    if (!_sections.hasAny) {
      setState(() => _error = 'En az bir başlık seçin.');
      return;
    }
    Navigator.of(context).pop(_sections);
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
                  () => _sections = DailyReportExportSections.all(),
                ),
                child: const Text('Tümünü seç'),
              ),
              TextButton(
                onPressed: () => setState(
                  () => _sections = DailyReportExportSections.none(),
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
                  title: 'Hava durumu',
                  subtitle: 'Sıcaklık, nem, rüzgar',
                  value: _sections.weather,
                  onChanged: (v) =>
                      setState(() => _sections = _sections.copyWith(weather: v)),
                ),
                _sectionTile(
                  title: 'Puantaj — sayılar',
                  subtitle: 'Mevcut / yarım / izin / yok özeti',
                  value: _sections.puantajCounts,
                  onChanged: (v) => setState(
                    () => _sections = _sections.copyWith(puantajCounts: v),
                  ),
                ),
                _sectionTile(
                  title: 'Puantaj — isimler',
                  subtitle: 'Personel, meslek, ekip, durum, yevmiye',
                  value: _sections.puantajNames,
                  onChanged: (v) => setState(
                    () => _sections = _sections.copyWith(puantajNames: v),
                  ),
                ),
                _sectionTile(
                  title: 'Fotoğraflar',
                  subtitle: 'Açıklamalı saha fotoğrafları',
                  value: _sections.photos,
                  onChanged: (v) =>
                      setState(() => _sections = _sections.copyWith(photos: v)),
                ),
                _sectionTile(
                  title: 'Yapılan işler',
                  subtitle: 'İnşaat / elektrik / mekanik',
                  value: _sections.workDone,
                  onChanged: (v) => setState(
                    () => _sections = _sections.copyWith(workDone: v),
                  ),
                ),
                _sectionTile(
                  title: 'Gelen malzeme',
                  subtitle: 'Tedarik kayıtları',
                  value: _sections.incomingMaterials,
                  onChanged: (v) => setState(
                    () =>
                        _sections = _sections.copyWith(incomingMaterials: v),
                  ),
                ),
                _sectionTile(
                  title: 'Giden malzeme',
                  subtitle: 'Gönderim kayıtları',
                  value: _sections.outgoingMaterials,
                  onChanged: (v) => setState(
                    () =>
                        _sections = _sections.copyWith(outgoingMaterials: v),
                  ),
                ),
                _sectionTile(
                  title: 'Sipariş verilen malzeme',
                  subtitle: 'Sipariş ve satın alma onayı',
                  value: _sections.orderedMaterials,
                  onChanged: (v) => setState(
                    () => _sections = _sections.copyWith(orderedMaterials: v),
                  ),
                ),
                _sectionTile(
                  title: 'İş makinesi puantajı',
                  subtitle: 'Makine, firma, saat',
                  value: _sections.machines,
                  onChanged: (v) => setState(
                    () => _sections = _sections.copyWith(machines: v),
                  ),
                ),
                _sectionTile(
                  title: 'Vasıta puantajı',
                  subtitle: 'Marka/model, şoför, saat',
                  value: _sections.vehicles,
                  onChanged: (v) => setState(
                    () => _sections = _sections.copyWith(vehicles: v),
                  ),
                ),
                _sectionTile(
                  title: 'Ertesi gün planı',
                  subtitle: 'Yarın yapılacak işler',
                  value: _sections.nextDayPlan,
                  onChanged: (v) => setState(
                    () => _sections = _sections.copyWith(nextDayPlan: v),
                  ),
                ),
                _sectionTile(
                  title: 'İmza alanları',
                  subtitle: 'Dolduran / inceleyen / onay',
                  value: _sections.signatures,
                  onChanged: (v) => setState(
                    () => _sections = _sections.copyWith(signatures: v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SJButton(
            label: widget.confirmLabel,
            icon: Icons.picture_as_pdf_outlined,
            expanded: true,
            onPressed: _confirm,
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
