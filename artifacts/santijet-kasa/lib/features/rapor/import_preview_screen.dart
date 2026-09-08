import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/design_system/sj_button.dart';
import '../../core/design_system/sj_card.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/kasa_hareket.dart';
import '../../domain/money_format.dart';

/// OCR / Excel içe aktarım önizlemesi — satır seç / ele / onayla.
class ImportPreviewScreen extends StatefulWidget {
  const ImportPreviewScreen({
    required this.title,
    required this.hareketler,
    required this.skipped,
    this.rawHint,
    super.key,
  });

  final String title;
  final List<KasaHareket> hareketler;
  final int skipped;
  final String? rawHint;

  @override
  State<ImportPreviewScreen> createState() => _ImportPreviewScreenState();
}

class _ImportPreviewScreenState extends State<ImportPreviewScreen> {
  late final List<bool> _selected;
  static final _date = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    _selected = List<bool>.filled(widget.hareketler.length, true);
  }

  int get _count => _selected.where((e) => e).length;

  List<KasaHareket> get _chosen {
    final out = <KasaHareket>[];
    for (var i = 0; i < widget.hareketler.length; i++) {
      if (_selected[i]) out.add(widget.hareketler[i]);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.title,
          style: AppTypography.headlineMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                final allOn = _selected.every((e) => e);
                for (var i = 0; i < _selected.length; i++) {
                  _selected[i] = !allOn;
                }
              });
            },
            child: Text(
              _selected.every((e) => e) ? 'Hiçbiri' : 'Tümü',
              style: TextStyle(color: AppColors.electricBlue),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              '${widget.hareketler.length} satır okundu'
              '${widget.skipped > 0 ? ' · ${widget.skipped} atlandı' : ''}. '
              'Eklemek istemediklerinizin işaretini kaldırın.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
          if (widget.rawHint != null && widget.rawHint!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                widget.rawHint!,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: widget.hareketler.length,
              itemBuilder: (context, index) {
                final h = widget.hareketler[index];
                final selected = _selected[index];
                final amount = h.isGelir
                    ? '+${MoneyFormat.format(h.gelir!)}'
                    : '-${MoneyFormat.format(h.gider ?? 0)}';
                final amountColor =
                    h.isGelir ? AppColors.electricBlue : AppColors.critical;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: SJCard(
                    onTap: () => setState(() => _selected[index] = !selected),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: selected,
                          onChanged: (v) => setState(
                            () => _selected[index] = v ?? false,
                          ),
                          activeColor: AppColors.electricBlue,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                h.tedarikci.isNotEmpty
                                    ? h.tedarikci
                                    : h.aciklama,
                                style: AppTypography.cardTitleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                h.aciklama,
                                style: AppTypography.cardBodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                [
                                  _date.format(h.tarih),
                                  if (h.santiye.isNotEmpty) h.santiye,
                                  if (h.odemeSekli.isNotEmpty) h.odemeSekli,
                                  if (h.belgeTuru.isNotEmpty) h.belgeTuru,
                                ].join(' · '),
                                style: AppTypography.cardLabelMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Text(
                          amount,
                          style: AppTypography.titleMedium.copyWith(
                            color: amountColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: SJButton(
                      label: 'Vazgeç',
                      variant: SJButtonVariant.secondary,
                      expanded: true,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: SJButton(
                      label: '$_count satırı ekle',
                      expanded: true,
                      onPressed: _count == 0
                          ? null
                          : () => Navigator.pop(context, _chosen),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
