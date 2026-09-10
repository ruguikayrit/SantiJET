import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/design_system/sj_button.dart';
import '../../core/design_system/sj_card.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/import_row_check.dart';
import '../../domain/kasa_hareket.dart';
import '../../domain/kasa_lookups.dart';
import '../../domain/money_format.dart';

/// OCR / Excel içe aktarım önizlemesi — satır düzelt / ele / onayla.
class ImportPreviewScreen extends StatefulWidget {
  const ImportPreviewScreen({
    required this.title,
    required this.hareketler,
    required this.skipped,
    this.existing = const [],
    this.rawHint,
    super.key,
  });

  final String title;
  final List<KasaHareket> hareketler;
  final int skipped;

  /// Mükerrer kontrolü için kasadaki mevcut hareketler.
  final List<KasaHareket> existing;
  final String? rawHint;

  @override
  State<ImportPreviewScreen> createState() => _ImportPreviewScreenState();
}

class _ImportPreviewScreenState extends State<ImportPreviewScreen> {
  late List<KasaHareket> _rows;
  late List<bool> _selected;
  late List<Set<ImportIssue>> _issues;
  bool _onlyFlagged = false;

  @override
  void initState() {
    super.initState();
    _rows = [...widget.hareketler];
    _selected = List<bool>.filled(_rows.length, true);
    _recheck();
  }

  void _recheck() {
    _issues = analyzeImportRows(
      rows: _rows,
      existing: widget.existing,
    );
  }

  int get _flaggedCount =>
      _issues.where((issues) => issues.isNotEmpty).length;

  List<int> get _visibleIndexes {
    final all = List<int>.generate(_rows.length, (i) => i);
    if (!_onlyFlagged) return all;
    return all.where((i) => _issues[i].isNotEmpty).toList();
  }

  List<KasaHareket> get _chosen {
    final out = <KasaHareket>[];
    for (var i = 0; i < _rows.length; i++) {
      if (_selected[i]) out.add(_rows[i]);
    }
    return out;
  }

  ({double gelir, double gider}) get _totals {
    var gelir = 0.0;
    var gider = 0.0;
    for (var i = 0; i < _rows.length; i++) {
      if (!_selected[i]) continue;
      gelir += _rows[i].gelir ?? 0;
      gider += _rows[i].gider ?? 0;
    }
    return (gelir: gelir, gider: gider);
  }

  Future<void> _edit(int index) async {
    final updated = await showModalBottomSheet<KasaHareket>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _EditRowSheet(hareket: _rows[index]),
    );
    if (updated == null) return;
    setState(() {
      _rows[index] = updated;
      _selected[index] = true;
      _recheck();
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleIndexes;
    final count = _selected.where((e) => e).length;
    final totals = _totals;

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
              '${_rows.length} satır okundu'
              '${widget.skipped > 0 ? ' · ${widget.skipped} atlandı' : ''}. '
              'Satıra dokunup düzeltin, istemediğinizin işaretini kaldırın.',
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
          if (_flaggedCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$_flaggedCount satır kontrol istiyor',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                  FilterChip(
                    label: const Text('Sadece bunlar'),
                    selected: _onlyFlagged,
                    onSelected: (v) => setState(() => _onlyFlagged = v),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: visible.length,
              itemBuilder: (context, position) {
                final index = visible[position];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _RowCard(
                    hareket: _rows[index],
                    issues: _issues[index],
                    selected: _selected[index],
                    onToggle: (v) => setState(() => _selected[index] = v),
                    onEdit: () => _edit(index),
                  ),
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Column(
                  children: [
                    _TotalsRow(gelir: totals.gelir, gider: totals.gider),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
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
                            label: '$count satırı ekle',
                            expanded: true,
                            onPressed: count == 0
                                ? null
                                : () => Navigator.pop(context, _chosen),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalsRow extends StatelessWidget {
  const _TotalsRow({required this.gelir, required this.gider});

  final double gelir;
  final double gider;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Seçili toplam',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        const Spacer(),
        Text(
          '+${MoneyFormat.format(gelir)}',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.electricBlue,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '-${MoneyFormat.format(gider)}',
          style: AppTypography.bodySmall.copyWith(color: AppColors.critical),
        ),
      ],
    );
  }
}

class _RowCard extends StatelessWidget {
  const _RowCard({
    required this.hareket,
    required this.issues,
    required this.selected,
    required this.onToggle,
    required this.onEdit,
  });

  static final _date = DateFormat('dd.MM.yyyy');

  final KasaHareket hareket;
  final Set<ImportIssue> issues;
  final bool selected;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final h = hareket;
    final amount = h.isGelir
        ? '+${MoneyFormat.format(h.gelir!)}'
        : '-${MoneyFormat.format(h.gider ?? 0)}';
    final amountColor =
        h.isGelir ? AppColors.electricBlue : AppColors.critical;

    return SJCard(
      onTap: onEdit,
      accentColor: issues.isEmpty ? null : AppColors.warning,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: selected,
            onChanged: (v) => onToggle(v ?? false),
            activeColor: AppColors.electricBlue,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  h.tedarikci.isNotEmpty ? h.tedarikci : h.aciklama,
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
                if (issues.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: issues
                        .map((i) => _IssueChip(label: i.label))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: AppTypography.titleMedium.copyWith(color: amountColor),
              ),
              const SizedBox(height: 2),
              Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IssueChip extends StatelessWidget {
  const _IssueChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(color: AppColors.warning),
      ),
    );
  }
}

/// Tek satır düzeltme — OCR hatasını aktarımdan önce elle giderir.
class _EditRowSheet extends StatefulWidget {
  const _EditRowSheet({required this.hareket});

  final KasaHareket hareket;

  @override
  State<_EditRowSheet> createState() => _EditRowSheetState();
}

class _EditRowSheetState extends State<_EditRowSheet> {
  static final _date = DateFormat('dd.MM.yyyy');

  late DateTime _tarih;
  late bool _isGelir;
  late final TextEditingController _tedarikci;
  late final TextEditingController _aciklama;
  late final TextEditingController _tutar;
  late final TextEditingController _ek;
  late String _odeme;
  late String _belge;
  String? _error;

  @override
  void initState() {
    super.initState();
    final h = widget.hareket;
    _tarih = h.tarih;
    _isGelir = h.isGelir;
    _tedarikci = TextEditingController(text: h.tedarikci);
    _aciklama = TextEditingController(text: h.aciklama);
    _tutar = TextEditingController(
      text: h.tutar > 0 ? h.tutar.toStringAsFixed(2).replaceAll('.', ',') : '',
    );
    _ek = TextEditingController(text: h.ekAciklama);
    _odeme = OdemeSekli.all.contains(h.odemeSekli)
        ? h.odemeSekli
        : OdemeSekli.nakit;
    _belge =
        BelgeTuru.all.contains(h.belgeTuru) ? h.belgeTuru : BelgeTuru.yok;
  }

  @override
  void dispose() {
    _tedarikci.dispose();
    _aciklama.dispose();
    _tutar.dispose();
    _ek.dispose();
    super.dispose();
  }

  void _save() {
    final tutar = MoneyFormat.tryParse(_tutar.text);
    if (_aciklama.text.trim().isEmpty) {
      setState(() => _error = 'Açıklama boş olamaz.');
      return;
    }
    if (tutar == null || tutar <= 0) {
      setState(() => _error = 'Geçerli bir tutar girin.');
      return;
    }
    Navigator.pop(
      context,
      widget.hareket.copyWith(
        tarih: _tarih,
        tedarikci: _tedarikci.text.trim(),
        aciklama: _aciklama.text.trim(),
        gelir: _isGelir ? tutar : null,
        gider: _isGelir ? null : tutar,
        clearGelir: !_isGelir,
        clearGider: _isGelir,
        odemeSekli: _odeme,
        belgeTuru: _belge,
        ekAciklama: _ek.text.trim(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Satırı düzelt', style: AppTypography.cardLabelMedium),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _tarih,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2035),
                );
                if (picked != null) setState(() => _tarih = picked);
              },
              icon: const Icon(Icons.event_outlined, size: 18),
              label: Text(_date.format(_tarih)),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _tedarikci,
              decoration: const InputDecoration(labelText: 'Tedarikçi'),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _aciklama,
              decoration: const InputDecoration(labelText: 'Açıklama'),
            ),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Gider')),
                ButtonSegment(value: true, label: Text('Gelir')),
              ],
              selected: {_isGelir},
              onSelectionChanged: (s) => setState(() => _isGelir = s.first),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _tutar,
              decoration: const InputDecoration(
                labelText: 'Tutar',
                prefixText: '₺ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: _odeme,
              decoration: const InputDecoration(labelText: 'Ödeme şekli'),
              items: OdemeSekli.all
                  .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                  .toList(),
              onChanged: (v) => setState(() => _odeme = v ?? _odeme),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: _belge,
              decoration: const InputDecoration(labelText: 'Belge türü'),
              items: BelgeTuru.all
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
              onChanged: (v) => setState(() => _belge = v ?? _belge),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _ek,
              decoration: const InputDecoration(labelText: 'Ek açıklama'),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.critical,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            SJButton(label: 'Kaydet', expanded: true, onPressed: _save),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}
