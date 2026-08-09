import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/design_system.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_format.dart';
import '../../core/utils/id_gen.dart';
import '../../data/providers/kesif_provider.dart';
import '../../domain/entities/kesif.dart';
import '../../domain/enums/app_enums.dart';
import '../kesif/widgets/discipline_section_header.dart';

/// Metraj cetveli — boyut girdilerinden poza ait metraj hesaplanır.
class MetrajScreen extends ConsumerWidget {
  const MetrajScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kesif = ref.watch(activeKesifProvider);
    final theme = Theme.of(context);

    if (kesif == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          title: const Text('Metraj Cetveli'),
          actions: [
            IconButton(
              tooltip: 'Ayarlar',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push(AppRoutes.ayarlar),
            ),
          ],
        ),
        body: SJEmptyState(
          title: 'Aktif proje yok',
          message: 'Metraj için Projelerim’den bir proje seçin.',
          icon: Icons.straighten_outlined,
          actionLabel: 'Projelerim',
          onAction: () => context.push(AppRoutes.projeler),
        ),
      );
    }

    final projectId = kesif.id;
    final byDisc = kesif.satirlarByDiscipline;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Metraj Cetveli'),
        actions: [
          IconButton(
            tooltip: 'Ayarlar',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.ayarlar),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text(
              kesif.ad,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'En, boy, yükseklik, alan veya çevre ile poza ait metrajı hesaplayın.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            if (kesif.satirlar.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: SJEmptyState(
                  title: 'Henüz poz yok',
                  message:
                      'Keşif listesine poz ekledikçe metraj cetveli burada görünür.',
                  icon: Icons.straighten_outlined,
                  actionLabel: 'Keşif’e Git',
                  onAction: () => context.go(AppRoutes.kesif),
                ),
              )
            else
              for (final d in AnalizDiscipline.kesifSirasi) ...[
                if ((byDisc[d] ?? const []).isNotEmpty) ...[
                  DisciplineSectionHeader(
                    discipline: d,
                    count: byDisc[d]!.length,
                  ),
                  for (final satir in byDisc[d]!) ...[
                    _PozCetvelCard(projectId: projectId, satir: satir),
                    const SizedBox(height: AppSpacing.xs),
                  ],
                ],
              ],
            const SizedBox(height: AppSpacing.xl),
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
    return Material(
      color: AppColors.canvas.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _openKalemEditor(
          context,
          ref,
          projectId: projectId,
          satirId: satirId,
          existing: kalem,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _ozet,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.cardTextSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${AppFormat.decimal(kalem.miktar)} $birim',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.cardTextPrimary,
                ),
              ),
              IconButton(
                tooltip: 'Sil',
                visualDensity: VisualDensity.compact,
                onPressed: () => ref
                    .read(kesifProvider.notifier)
                    .removeMetrajKalemi(projectId, satirId, kalem.id),
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _openKalemEditor(
  BuildContext context,
  WidgetRef ref, {
  required String projectId,
  required String satirId,
  MetrajKalemi? existing,
}) async {
  final result = await showModalBottomSheet<MetrajKalemi>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _KalemEditorSheet(initial: existing),
  );
  if (result == null) return;
  ref.read(kesifProvider.notifier).upsertMetrajKalemi(
        projectId,
        satirId,
        result,
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
    Navigator.of(context).pop(kalem);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final theme = Theme.of(context);
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
              widget.initial == null ? 'Cetvel satırı ekle' : 'Cetvel satırını düzenle',
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
            FilledButton(
              onPressed: _save,
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
