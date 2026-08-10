import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:santijet_ana/core/routing/app_routes.dart';
import 'package:santijet_ana/core/theme/theme_colors.dart';
import 'package:santijet_ana/core/theme/theme_provider.dart';
import 'package:santijet_ana/core/widgets/sj_header.dart';
import 'package:santijet_ana/data/providers/app_state_provider.dart';
import 'package:santijet_ana/domain/models/catalog_models.dart';

/// İmalat pozları ve kullanıcı poz analizleri — basit liste CRUD.
class ImalatPozlariScreen extends ConsumerStatefulWidget {
  const ImalatPozlariScreen({super.key});

  @override
  ConsumerState<ImalatPozlariScreen> createState() =>
      _ImalatPozlariScreenState();
}

class _ImalatPozlariScreenState extends ConsumerState<ImalatPozlariScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs =
      TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _addPoz([ImalatPoz? existing]) async {
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final catCtrl = TextEditingController(text: existing?.category ?? '');
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final unitCtrl = TextEditingController(text: existing?.unit ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Poz ekle' : 'Poz düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(labelText: 'Poz no'),
                enabled: existing == null,
              ),
              TextField(
                controller: catCtrl,
                decoration: const InputDecoration(labelText: 'Kategori'),
              ),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Ad'),
              ),
              TextField(
                controller: unitCtrl,
                decoration: const InputDecoration(labelText: 'Birim'),
              ),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Açıklama'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    final code = codeCtrl.text.trim();
    final cat = catCtrl.text.trim();
    final name = nameCtrl.text.trim();
    final unit = unitCtrl.text.trim();
    final desc = descCtrl.text.trim();
    codeCtrl.dispose();
    catCtrl.dispose();
    nameCtrl.dispose();
    unitCtrl.dispose();
    descCtrl.dispose();
    if (ok != true || code.isEmpty || name.isEmpty) return;

    final n = ref.read(appStateProvider.notifier);
    final poz = ImalatPoz(
      code: code,
      category: cat,
      name: name,
      unit: unit,
      description: desc.isEmpty ? null : desc,
    );
    if (existing == null) {
      n.addImalatPoz(poz);
    } else {
      n.updateImalatPoz(existing.code, (_) => poz);
    }
  }

  Future<void> _addAnaliz([PozAnaliz? existing]) async {
    final pozNoCtrl = TextEditingController(text: existing?.pozNo ?? '');
    final adCtrl = TextEditingController(text: existing?.analizAdi ?? '');
    final birimCtrl = TextEditingController(text: existing?.olcuBirimi ?? '');
    final katCtrl = TextEditingController(text: existing?.kategori ?? '');
    final fiyatCtrl = TextEditingController(
      text: existing != null ? existing.birimFiyati.toStringAsFixed(2) : '',
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Analiz ekle' : 'Analiz düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pozNoCtrl,
                decoration: const InputDecoration(labelText: 'Poz no'),
              ),
              TextField(
                controller: adCtrl,
                decoration: const InputDecoration(labelText: 'Analiz adı'),
              ),
              TextField(
                controller: birimCtrl,
                decoration: const InputDecoration(labelText: 'Ölçü birimi'),
              ),
              TextField(
                controller: katCtrl,
                decoration: const InputDecoration(labelText: 'Kategori'),
              ),
              TextField(
                controller: fiyatCtrl,
                decoration: const InputDecoration(labelText: 'Birim fiyat'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    final pozNo = pozNoCtrl.text.trim();
    final ad = adCtrl.text.trim();
    final birim = birimCtrl.text.trim();
    final kat = katCtrl.text.trim();
    final fiyat = double.tryParse(fiyatCtrl.text.trim().replaceAll(',', '.')) ??
        0;
    pozNoCtrl.dispose();
    adCtrl.dispose();
    birimCtrl.dispose();
    katCtrl.dispose();
    fiyatCtrl.dispose();
    if (ok != true || pozNo.isEmpty || ad.isEmpty) return;

    final n = ref.read(appStateProvider.notifier);
    final now = DateTime.now().toIso8601String();
    if (existing == null) {
      n.addPozAnaliz(
        PozAnaliz(
          id: '',
          pozNo: pozNo,
          analizAdi: ad,
          olcuBirimi: birim,
          kategori: kat,
          kalemler: const [],
          pozTarifi: '',
          yapimSartlari: '',
          olcusu: '',
          malzemeIscilikToplami: fiyat,
          yukleniciKarOrani: 0,
          yukleniciKarTutari: 0,
          birimFiyati: fiyat,
          olusturmaTarihi: now,
          guncellemeTarihi: now,
          kaynakTip: 'kullanici',
        ),
      );
    } else {
      n.updatePozAnaliz(
        existing.id,
        (e) => e.copyWith(
          pozNo: pozNo,
          analizAdi: ad,
          olcuBirimi: birim,
          kategori: kat,
          birimFiyati: fiyat,
          malzemeIscilikToplami: fiyat,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(themeDefinitionProvider).colors;
    final state = ref.watch(appStateProvider);

    return Scaffold(
      backgroundColor: c.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabs.index == 0) {
            _addPoz();
          } else {
            _addAnaliz();
          }
        },
        backgroundColor: c.primary,
        child: Icon(Icons.add, color: c.primaryForeground),
      ),
      body: Column(
        children: [
          SjHeader(
            title: 'İmalat Pozları',
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.ayarlar);
              }
            },
          ),
          Material(
            color: c.card,
            child: TabBar(
              controller: _tabs,
              labelColor: c.primary,
              unselectedLabelColor: c.mutedForeground,
              indicatorColor: c.primary,
              tabs: const [
                Tab(text: 'Pozlar'),
                Tab(text: 'Analizler'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _list(
                  c,
                  empty: 'Poz kaydı yok',
                  count: state.imalatPozlari.length,
                  builder: (i) {
                    final p = state.imalatPozlari[i];
                    return _card(
                      c,
                      title: '${p.code} — ${p.name}',
                      subtitle: '${p.category} · ${p.unit}',
                      onEdit: () => _addPoz(p),
                      onDelete: () => ref
                          .read(appStateProvider.notifier)
                          .deleteImalatPoz(p.code),
                    );
                  },
                ),
                _list(
                  c,
                  empty: 'Analiz kaydı yok',
                  count: state.pozAnalizleri.length,
                  builder: (i) {
                    final a = state.pozAnalizleri[i];
                    return _card(
                      c,
                      title: '${a.pozNo} — ${a.analizAdi}',
                      subtitle:
                          '${a.kategori} · ${a.olcuBirimi} · ${a.birimFiyati.toStringAsFixed(2)} ₺',
                      onEdit: () => _addAnaliz(a),
                      onDelete: () => ref
                          .read(appStateProvider.notifier)
                          .deletePozAnaliz(a.id),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(
    ThemeColors c, {
    required String empty,
    required int count,
    required Widget Function(int i) builder,
  }) {
    if (count == 0) {
      return Center(
        child: Text(
          empty,
          style: TextStyle(color: c.mutedForeground, fontFamily: 'Inter'),
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.paddingOf(context).bottom + 80,
      ),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => builder(i),
    );
  }

  Widget _card(
    ThemeColors c, {
    required String title,
    required String subtitle,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: c.border),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: c.foreground,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: c.mutedForeground,
            fontSize: 12,
            fontFamily: 'Inter',
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: onEdit,
              icon: Icon(Icons.edit_outlined, color: c.mutedForeground),
            ),
            IconButton(
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline, color: c.destructive),
            ),
          ],
        ),
      ),
    );
  }
}
