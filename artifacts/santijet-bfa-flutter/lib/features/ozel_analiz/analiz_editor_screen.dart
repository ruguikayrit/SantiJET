import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/poz_constants.dart';
import '../../core/design_system/design_system.dart';
import '../../core/routing/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/app_format.dart';
import '../../core/widgets/cost_summary_card.dart';
import '../../data/providers/catalog_provider.dart';
import '../../data/providers/user_analiz_provider.dart';
import '../../domain/calc/analiz_draft_helpers.dart';
import '../../domain/calc/analiz_hesap.dart';
import '../../domain/entities/analiz_kalemi.dart';
import '../../domain/entities/poz_analiz.dart';
import '../../domain/enums/app_enums.dart';

/// Özel analiz oluşturma ve düzenleme ekranı.
class AnalizEditorScreen extends ConsumerStatefulWidget {
  const AnalizEditorScreen({
    this.analizId,
    this.discipline,
    super.key,
  });

  /// Düzenleme modu — mevcut analiz kimliği.
  final String? analizId;

  /// Yeni analiz modu — disiplin.
  final AnalizDiscipline? discipline;

  @override
  ConsumerState<AnalizEditorScreen> createState() => _AnalizEditorScreenState();
}

class _AnalizEditorScreenState extends ConsumerState<AnalizEditorScreen> {
  PozAnaliz? _draft;
  final _pozNoCtrl = TextEditingController();
  final _adCtrl = TextEditingController();
  final _tarifCtrl = TextEditingController();
  final _sartCtrl = TextEditingController();
  final _notCtrl = TextEditingController();
  final _karCtrl = TextEditingController();
  String _olcuBirimi = PozConstants.olcuBirimleri[2];
  String _kategori = PozConstants.kategoriler.first;

  @override
  void initState() {
    super.initState();
    if (widget.analizId == null) {
      final discipline = widget.discipline ?? AnalizDiscipline.insaat;
      _bindDraft(AnalizDraftHelpers.emptyTemplate(discipline));
    }
  }

  @override
  void dispose() {
    _pozNoCtrl.dispose();
    _adCtrl.dispose();
    _tarifCtrl.dispose();
    _sartCtrl.dispose();
    _notCtrl.dispose();
    _karCtrl.dispose();
    super.dispose();
  }

  void _bindDraft(PozAnaliz analiz) {
    _draft = analiz;
    _pozNoCtrl.text = analiz.pozNo;
    _adCtrl.text = analiz.analizAdi;
    _tarifCtrl.text = analiz.pozTarifi;
    _sartCtrl.text = analiz.yapimSartlari;
    _notCtrl.text = analiz.notlar ?? '';
    _karCtrl.text = AppFormat.decimal(analiz.yukleniciKarOrani, fractionDigits: 0);
    _olcuBirimi = analiz.olcuBirimi.isNotEmpty
        ? analiz.olcuBirimi
        : PozConstants.olcuBirimleri[2];
    _kategori = analiz.kategori.isNotEmpty
        ? analiz.kategori
        : PozConstants.kategoriler.first;
  }

  PozAnaliz _collectDraft() {
    final base = _draft!;
    final kar = AnalizDraftHelpers.parseNum(_karCtrl.text);
    return AnalizDraftHelpers.applyTotals(
      base.copyWith(
        pozNo: _pozNoCtrl.text.trim(),
        analizAdi: _adCtrl.text.trim(),
        olcuBirimi: _olcuBirimi,
        kategori: _kategori,
        pozTarifi: _tarifCtrl.text,
        yapimSartlari: _sartCtrl.text,
        notlar: _notCtrl.text.trim().isEmpty ? null : _notCtrl.text.trim(),
        yukleniciKarOrani: kar,
      ),
    );
  }

  void _updateKalem(int index, AnalizKalemi kalem) {
    final list = [..._draft!.kalemler];
    list[index] = AnalizDraftHelpers.recalcKalem(kalem);
    setState(() => _draft = _collectDraft().copyWith(kalemler: list));
  }

  void _addKalem(AnalizKalemTip tip) {
    setState(() {
      _draft = _collectDraft().copyWith(
        kalemler: [..._draft!.kalemler, AnalizDraftHelpers.newKalem(tip)],
      );
    });
  }

  void _removeKalem(int index) {
    final list = [..._draft!.kalemler]..removeAt(index);
    setState(() => _draft = _collectDraft().copyWith(kalemler: list));
  }

  Future<void> _save() async {
    final draft = _collectDraft();
    if (draft.pozNo.trim().isEmpty || draft.analizAdi.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Poz No ve Analiz Adı zorunludur.')),
      );
      return;
    }

    final notifier = ref.read(userAnalizProvider.notifier);
    if (widget.analizId != null && widget.analizId!.isNotEmpty) {
      notifier.update(widget.analizId!, draft);
      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Analiz güncellendi.')),
      );
      return;
    }

    final id = notifier.add(draft);
    if (!mounted) return;
    context.go(AppRoutes.pozDetay(id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Yeni analiz oluşturuldu.')),
    );
  }

  void _ensureEditDraft(CatalogData catalog) {
    if (_draft != null || widget.analizId == null) return;
    final analiz = catalog.byIdOrNull(widget.analizId!);
    if (analiz == null) return;
    final editable = analiz.kaynakTip == KaynakTip.sistem
        ? ref.read(userAnalizProvider.notifier).clone(analiz)
        : analiz;
    _bindDraft(editable);
    if (analiz.kaynakTip == KaynakTip.sistem && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resmi analiz kopyalandı; kopya üzerinde düzenleyebilirsiniz.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(catalogProvider);

    if (widget.analizId != null) {
      return catalogAsync.when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Düzenle')),
          body: SJEmptyState(
            title: 'Yüklenemedi',
            message: '$e',
            icon: Icons.error_outline,
          ),
        ),
        data: (catalog) {
          final analiz = catalog.byIdOrNull(widget.analizId!);
          if (analiz == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Düzenle')),
              body: const SJEmptyState(
                title: 'Analiz bulunamadı',
                message: 'Kayıt silinmiş olabilir.',
                icon: Icons.error_outline,
              ),
            );
          }
          _ensureEditDraft(catalog);
          if (_draft == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return _editorBody(context);
        },
      );
    }

    if (_draft == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return _editorBody(context);
  }

  Widget _editorBody(BuildContext context) {
    final theme = Theme.of(context);
    final draft = _collectDraft();
    final isNew = widget.analizId == null || widget.analizId!.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'Yeni Analiz' : 'Analizi Düzenle'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Kaydet')),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text('Temel Bilgiler', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            SJInput(controller: _pozNoCtrl, label: 'Poz No'),
            const SizedBox(height: AppSpacing.xs),
            SJInput(controller: _adCtrl, label: 'Analiz Adı'),
            const SizedBox(height: AppSpacing.xs),
            _dropdown(
              label: 'Ölçü Birimi',
              value: _olcuBirimi,
              items: PozConstants.olcuBirimleri,
              onChanged: (v) => setState(() => _olcuBirimi = v),
            ),
            const SizedBox(height: AppSpacing.xs),
            _dropdown(
              label: 'Kategori',
              value: _kategori,
              items: PozConstants.kategoriler,
              onChanged: (v) => setState(() => _kategori = v),
            ),
            const SizedBox(height: AppSpacing.xs),
            SJInput(
              controller: _karCtrl,
              label: 'Yüklenici Karı (%)',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Kalemler', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              children: [
                for (final tip in AnalizKalemTip.values)
                  OutlinedButton.icon(
                    onPressed: () => _addKalem(tip),
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(_tipLabel(tip)),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (draft.kalemler.isEmpty)
              const SJEmptyState(
                title: 'Henüz kalem yok',
                message: 'Malzeme, işçilik veya ekipman kalemi ekleyin.',
                icon: Icons.table_rows,
              )
            else
              ...draft.kalemler.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: _KalemEditorCard(
                        key: ValueKey(e.value.id),
                        kalem: e.value,
                        onChanged: (k) => _updateKalem(e.key, k),
                        onDelete: () => _removeKalem(e.key),
                      ),
                    ),
                  ),
            const SizedBox(height: AppSpacing.md),
            CostSummaryCard(analiz: draft),
            const SizedBox(height: AppSpacing.lg),
            SJInput(controller: _tarifCtrl, label: 'Poz Tarifi', maxLines: 4),
            const SizedBox(height: AppSpacing.xs),
            SJInput(
              controller: _sartCtrl,
              label: 'Yapım Şartları',
              maxLines: 4,
            ),
            const SizedBox(height: AppSpacing.xs),
            SJInput(controller: _notCtrl, label: 'Notlar', maxLines: 3),
            const SizedBox(height: AppSpacing.lg),
            SJButton(label: 'Kaydet', icon: Icons.save, onPressed: _save),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: items.contains(value) ? value : items.first,
          items: [
            for (final item in items)
              DropdownMenuItem(value: item, child: Text(item)),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  String _tipLabel(AnalizKalemTip tip) => switch (tip) {
        AnalizKalemTip.malzeme => 'Malzeme',
        AnalizKalemTip.iscilik => 'İşçilik',
        AnalizKalemTip.ekipman => 'Ekipman',
      };
}

class _KalemEditorCard extends StatefulWidget {
  const _KalemEditorCard({
    super.key,
    required this.kalem,
    required this.onChanged,
    required this.onDelete,
  });

  final AnalizKalemi kalem;
  final ValueChanged<AnalizKalemi> onChanged;
  final VoidCallback onDelete;

  @override
  State<_KalemEditorCard> createState() => _KalemEditorCardState();
}

class _KalemEditorCardState extends State<_KalemEditorCard> {
  late final TextEditingController _pozCtrl;
  late final TextEditingController _tanimCtrl;
  late final TextEditingController _birimCtrl;
  late final TextEditingController _miktarCtrl;
  late final TextEditingController _bfCtrl;

  @override
  void initState() {
    super.initState();
    _pozCtrl = TextEditingController(text: widget.kalem.pozNo);
    _tanimCtrl = TextEditingController(text: widget.kalem.tanim);
    _birimCtrl = TextEditingController(text: widget.kalem.olcuBirimi);
    _miktarCtrl = TextEditingController(
      text: AppFormat.decimal(widget.kalem.miktar, fractionDigits: 4),
    );
    _bfCtrl = TextEditingController(
      text: AppFormat.decimal(widget.kalem.birimFiyati, fractionDigits: 2),
    );
  }

  @override
  void dispose() {
    _pozCtrl.dispose();
    _tanimCtrl.dispose();
    _birimCtrl.dispose();
    _miktarCtrl.dispose();
    _bfCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      widget.kalem.copyWith(
        pozNo: _pozCtrl.text.trim(),
        tanim: _tanimCtrl.text.trim(),
        olcuBirimi: _birimCtrl.text.trim(),
        miktar: AnalizDraftHelpers.parseNum(_miktarCtrl.text),
        birimFiyati: AnalizDraftHelpers.parseNum(_bfCtrl.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tutar = AnalizHesap.satirTutar(
      AnalizDraftHelpers.parseNum(_miktarCtrl.text),
      AnalizDraftHelpers.parseNum(_bfCtrl.text),
    );
    return SJCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _tipLabel(widget.kalem.tip),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(AppFormat.currency(tutar)),
              IconButton(
                tooltip: 'Sil',
                onPressed: widget.onDelete,
                icon: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
          SJInput(controller: _pozCtrl, label: 'Poz No', onChanged: (_) => _emit()),
          const SizedBox(height: AppSpacing.xxs),
          SJInput(controller: _tanimCtrl, label: 'Tanım', onChanged: (_) => _emit()),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            children: [
              Expanded(
                child: SJInput(
                  controller: _birimCtrl,
                  label: 'Birim',
                  onChanged: (_) => _emit(),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: SJInput(
                  controller: _miktarCtrl,
                  label: 'Miktar',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => _emit(),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: SJInput(
                  controller: _bfCtrl,
                  label: 'Birim Fiyat',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => _emit(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _tipLabel(AnalizKalemTip tip) => switch (tip) {
        AnalizKalemTip.malzeme => 'Malzeme Kalemi',
        AnalizKalemTip.iscilik => 'İşçilik Kalemi',
        AnalizKalemTip.ekipman => 'Ekipman Kalemi',
      };
}
