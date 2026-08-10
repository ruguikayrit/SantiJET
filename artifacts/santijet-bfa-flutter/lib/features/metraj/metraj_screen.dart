import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/design_system.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_format.dart';
import '../../core/utils/id_gen.dart';
import '../../core/widgets/santijet_header.dart';
import '../../data/providers/kesif_provider.dart';
import '../../domain/entities/kesif.dart';
import '../../domain/enums/app_enums.dart';
import '../kesif/kesif_poz_picker_sheet.dart';
import '../kesif/widgets/discipline_section_header.dart';

/// Metraj cetveli — boyut girdilerinden poza ait metraj hesaplanır.
class MetrajScreen extends ConsumerStatefulWidget {
  const MetrajScreen({super.key});

  @override
  ConsumerState<MetrajScreen> createState() => _MetrajScreenState();
}

class _MetrajScreenState extends ConsumerState<MetrajScreen> {
  final Set<AnalizDiscipline> _collapsed = {};

  Future<void> _addPoz(String projectId) async {
    final picked = await KesifPozPickerSheet.show(context);
    if (picked == null) return;
    ref.read(kesifProvider.notifier).addSatir(
          projectId,
          picked.analiz,
          picked.miktar,
        );
  }

  @override
  Widget build(BuildContext context) {
    final kesif = ref.watch(activeKesifProvider);
    final theme = Theme.of(context);

    if (kesif == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SantijetHeader(subtitle: 'Metraj'),
              Expanded(
                child: SJEmptyState(
                  title: 'Aktif proje yok',
                  message: 'Metraj için Projelerim’den bir proje seçin.',
                  icon: Icons.straighten_outlined,
                  actionLabel: 'Projelerim',
                  onAction: () => context.push(AppRoutes.projeler),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final projectId = kesif.id;
    final byDisc = kesif.satirlarByDiscipline;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addPoz(projectId),
        icon: const Icon(Icons.add),
        label: const Text('Poz Ekle'),
      ),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: SantijetHeader(subtitle: 'Metraj'),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.md),
              sliver: SliverList.list(
                children: [
                  Text(
                    kesif.ad,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  if (kesif.satirlar.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.lg),
                      child: SJEmptyState(
                        title: 'Henüz poz yok',
                        message:
                            'Poz Ekle ile katalogdan seçin; metraj cetveli burada doldurulur.',
                        icon: Icons.straighten_outlined,
                        actionLabel: 'Poz Ekle',
                        onAction: () => _addPoz(projectId),
                      ),
                    )
                  else
                    for (final d in AnalizDiscipline.kesifSirasi) ...[
                      if ((byDisc[d] ?? const []).isNotEmpty) ...[
                        DisciplineSectionHeader(
                          discipline: d,
                          count: byDisc[d]!.length,
                          expanded: !_collapsed.contains(d),
                          onToggle: () {
                            setState(() {
                              if (_collapsed.contains(d)) {
                                _collapsed.remove(d);
                              } else {
                                _collapsed.add(d);
                              }
                            });
                          },
                        ),
                        if (!_collapsed.contains(d))
                          for (final satir in byDisc[d]!) ...[
                            _PozCetvelCard(projectId: projectId, satir: satir),
                            const SizedBox(height: AppSpacing.xs),
                          ],
                      ],
                    ],
                  const SizedBox(height: AppSpacing.xl * 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PozCetvelCard extends ConsumerWidget {
  const _PozCetvelCard({required this.projectId, required this.satir});

  final String projectId;
  final KesifSatiri satir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final kalemler = satir.metrajKalemleri;
    final total = satir.hesaplananMetraj;

    return SJCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      satir.pozNo,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.moduleKesif,
                      ),
                    ),
                    Text(
                      satir.analizAdi,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.cardTextPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                '${AppFormat.decimal(total)} ${satir.olcuBirimi}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.cardTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (kalemler.isEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _ManuelMiktarField(projectId: projectId, satir: satir),
          ] else ...[
            const SizedBox(height: AppSpacing.sm),
            for (final k in kalemler) ...[
              _KalemRow(
                projectId: projectId,
                satirId: satir.id,
                kalem: k,
                birim: satir.olcuBirimi,
              ),
              const SizedBox(height: 4),
            ],
          ],
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _openKalemEditor(
                context,
                ref,
                projectId: projectId,
                satirId: satir.id,
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Cetvel satırı'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManuelMiktarField extends ConsumerStatefulWidget {
  const _ManuelMiktarField({required this.projectId, required this.satir});

  final String projectId;
  final KesifSatiri satir;

  @override
  ConsumerState<_ManuelMiktarField> createState() => _ManuelMiktarFieldState();
}

class _ManuelMiktarFieldState extends ConsumerState<_ManuelMiktarField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: AppFormat.decimal(widget.satir.miktar, fractionDigits: 2),
    );
  }

  @override
  void didUpdateWidget(covariant _ManuelMiktarField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.satir.miktar != widget.satir.miktar) {
      _controller.text =
          AppFormat.decimal(widget.satir.miktar, fractionDigits: 2);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Manuel miktar (${widget.satir.olcuBirimi})',
        isDense: true,
        helperText: 'Veya aşağıdan cetvel satırı ekleyin.',
      ),
      onSubmitted: (raw) {
        final value = double.tryParse(raw.replaceAll(',', '.')) ?? 0;
        ref.read(kesifProvider.notifier).updateMiktar(
              widget.projectId,
              widget.satir.id,
              value,
            );
      },
    );
  }
}

class _KalemRow extends ConsumerWidget {
  const _KalemRow({
    required this.projectId,
    required this.satirId,
    required this.kalem,
    required this.birim,
  });

  final String projectId;
  final String satirId;
  final MetrajKalemi kalem;
  final String birim;

  String get _ozet {
    final tip = kalem.tip;
    final dims = switch (tip) {
      MetrajHesapTipi.enBoy =>
        '${AppFormat.decimal(kalem.en)}×${AppFormat.decimal(kalem.boy)}',
      MetrajHesapTipi.enBoyYukseklik =>
        '${AppFormat.decimal(kalem.en)}×${AppFormat.decimal(kalem.boy)}×${AppFormat.decimal(kalem.yukseklik)}',
      MetrajHesapTipi.alan => 'A=${AppFormat.decimal(kalem.alan)}',
      MetrajHesapTipi.cevre => 'Ç=${AppFormat.decimal(kalem.cevre)}',
      MetrajHesapTipi.manuel => 'manuel',
    };
    final adet = kalem.adet != 1
        ? ' × ${AppFormat.decimal(kalem.adet, fractionDigits: 0)}'
        : '';
    final aciklama = kalem.aciklama.trim().isEmpty ? tip.label : kalem.aciklama;
    return '$aciklama · $dims$adet';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final rowBg = AppColors.cardSurfaceHighlight;
    final rowBorder = AppColors.cardBorder.withValues(alpha: 0.7);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _openKalemEditor(
          context,
          ref,
          projectId: projectId,
          satirId: satirId,
          existing: kalem,
        ),
        child: Ink(
          decoration: BoxDecoration(
            color: rowBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: rowBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.moduleKesif.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _ozet,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.cardTextSecondary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${AppFormat.decimal(kalem.miktar)} $birim',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.cardTextPrimary,
                    fontWeight: FontWeight.w600,
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

/// Cetvel düzenleyici sonucu — kaydet / sil / iptal.
class _KalemSheetOutcome {
  const _KalemSheetOutcome._({this.kalem, this.deleted = false});
  const _KalemSheetOutcome.save(MetrajKalemi kalem)
      : this._(kalem: kalem);
  const _KalemSheetOutcome.delete() : this._(deleted: true);

  final MetrajKalemi? kalem;
  final bool deleted;
}

Future<void> _openKalemEditor(
  BuildContext context,
  WidgetRef ref, {
  required String projectId,
  required String satirId,
  MetrajKalemi? existing,
}) async {
  final result = await showModalBottomSheet<_KalemSheetOutcome>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _KalemEditorSheet(initial: existing),
  );
  if (result == null) return;
  if (result.deleted) {
    if (existing == null) return;
    ref.read(kesifProvider.notifier).removeMetrajKalemi(
          projectId,
          satirId,
          existing.id,
        );
    return;
  }
  final kalem = result.kalem;
  if (kalem == null) return;
  ref.read(kesifProvider.notifier).upsertMetrajKalemi(
        projectId,
        satirId,
        kalem,
      );
}

class _KalemEditorSheet extends StatefulWidget {
  const _KalemEditorSheet({this.initial});

  final MetrajKalemi? initial;

  @override
  State<_KalemEditorSheet> createState() => _KalemEditorSheetState();
}

class _KalemEditorSheetState extends State<_KalemEditorSheet> {
  late MetrajHesapTipi _tip;
  late final TextEditingController _aciklama;
  late final TextEditingController _en;
  late final TextEditingController _boy;
  late final TextEditingController _yukseklik;
  late final TextEditingController _alan;
  late final TextEditingController _cevre;
  late final TextEditingController _adet;
  late final TextEditingController _manuel;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _tip = i?.tip ?? MetrajHesapTipi.enBoy;
    _aciklama = TextEditingController(text: i?.aciklama ?? '');
    _en = TextEditingController(text: _num(i?.en));
    _boy = TextEditingController(text: _num(i?.boy));
    _yukseklik = TextEditingController(text: _num(i?.yukseklik));
    _alan = TextEditingController(text: _num(i?.alan));
    _cevre = TextEditingController(text: _num(i?.cevre));
    _adet = TextEditingController(
      text: i == null ? '1' : AppFormat.decimal(i.adet, fractionDigits: 0),
    );
    _manuel = TextEditingController(text: _num(i?.miktar));
  }

  String _num(double? v) {
    if (v == null || v == 0) return '';
    return AppFormat.decimal(v, fractionDigits: 3);
  }

  double _parse(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.')) ?? 0;

  @override
  void dispose() {
    _aciklama.dispose();
    _en.dispose();
    _boy.dispose();
    _yukseklik.dispose();
    _alan.dispose();
    _cevre.dispose();
    _adet.dispose();
    _manuel.dispose();
    super.dispose();
  }

  double get _preview => MetrajKalemi.hesapla(
        tip: _tip,
        en: _parse(_en),
        boy: _parse(_boy),
        yukseklik: _parse(_yukseklik),
        alan: _parse(_alan),
        cevre: _parse(_cevre),
        adet: _parse(_adet) <= 0 ? 1 : _parse(_adet),
        manuelMiktar: _parse(_manuel),
      );

  void _save() {
    final kalem = MetrajKalemi(
      id: widget.initial?.id ?? IdGen.make('mk'),
      aciklama: _aciklama.text.trim(),
      tip: _tip,
      en: _parse(_en),
      boy: _parse(_boy),
      yukseklik: _parse(_yukseklik),
      alan: _parse(_alan),
      cevre: _parse(_cevre),
      adet: _parse(_adet) <= 0 ? 1 : _parse(_adet),
      miktar: _preview,
    ).withHesap(manuelMiktar: _parse(_manuel));
    Navigator.of(context).pop(_KalemSheetOutcome.save(kalem));
  }

  Future<void> _delete() async {
    final ok = await SJModal.confirm(
      context: context,
      title: 'Cetvel satırını sil',
      message: 'Bu satır listeden kaldırılsın mı?',
      confirmLabel: 'Sil',
      destructive: true,
    );
    if (!ok || !mounted) return;
    Navigator.of(context).pop(const _KalemSheetOutcome.delete());
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final theme = Theme.of(context);
    final isEditing = widget.initial != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md + bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isEditing ? 'Cetvel satırını düzenle' : 'Cetvel satırı ekle',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _aciklama,
              decoration: const InputDecoration(
                labelText: 'Açıklama',
                hintText: 'Örn. Döşeme A-1',
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<MetrajHesapTipi>(
              value: _tip,
              decoration: const InputDecoration(
                labelText: 'Hesap tipi',
                isDense: true,
              ),
              items: [
                for (final t in MetrajHesapTipi.values)
                  DropdownMenuItem(value: t, child: Text(t.label)),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _tip = v);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_tip == MetrajHesapTipi.manuel)
              TextField(
                controller: _manuel,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Miktar',
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              )
            else ...[
              if (_tip == MetrajHesapTipi.enBoy ||
                  _tip == MetrajHesapTipi.enBoyYukseklik)
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _en,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'En',
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: TextField(
                        controller: _boy,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Boy',
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    if (_tip == MetrajHesapTipi.enBoyYukseklik) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: TextField(
                          controller: _yukseklik,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Yükseklik',
                            isDense: true,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ],
                ),
              if (_tip == MetrajHesapTipi.alan)
                TextField(
                  controller: _alan,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Alan',
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              if (_tip == MetrajHesapTipi.cevre)
                TextField(
                  controller: _cevre,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Çevre',
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _adet,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Adet',
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Text(
              'Hesaplanan: ${AppFormat.decimal(_preview)}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.moduleKesif,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (isEditing) ...[
                  Expanded(
                    child: SJButton(
                      label: 'Sil',
                      icon: Icons.delete_outline,
                      variant: SJButtonVariant.destructive,
                      onPressed: _delete,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: SJButton(
                    label: 'Kaydet',
                    icon: Icons.save_outlined,
                    onPressed: _save,
                    expanded: !isEditing,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
