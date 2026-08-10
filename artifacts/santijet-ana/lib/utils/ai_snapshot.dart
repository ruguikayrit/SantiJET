import '../data/providers/app_state_provider.dart';
import '../domain/models/page_key.dart';
import '../domain/models/role.dart';

List<T> _trim<T>(List<T> arr, [int n = 200]) =>
    arr.length <= n ? arr : arr.sublist(0, n);

/// Asistan API için kompakt yerel veri özeti (RN buildAiSnapshot).
Map<String, dynamic> buildAiSnapshot(AppState app, Role? role) {
  String pn(String id) {
    for (final p in app.projects) {
      if (p.id == id) return p.name;
    }
    return id;
  }

  bool allowed(String k) =>
      (role?.permissions[k] ?? Permission.none) != Permission.none;

  final out = <String, dynamic>{};

  if (allowed('proje')) {
    out['projeler'] = _trim(app.projects)
        .map((p) => {
              'ad': p.name,
              'lokasyon': p.location,
              'yuklenici': p.contractor,
              'baslangic': p.startDate,
              'bitis': p.endDate,
              if (allowed('butce')) 'butce': p.budget,
              'durum': p.status,
            })
        .toList();
  }
  if (allowed('kesif')) {
    out['kesifler'] = _trim(app.surveys)
        .map((s) => {
              'proje': pn(s.projectId),
              'baslik': s.title,
              'tarih': s.date,
              'lokasyon': s.location,
              'kalemler': s.items
                  .take(30)
                  .map((i) => {
                        'aciklama': i.description,
                        'birim': i.unit,
                        'miktar': i.quantity,
                        'fiyat': i.unitPrice,
                      })
                  .toList(),
            })
        .toList();
  }
  if (allowed('is-programi')) {
    out['is_programi'] = _trim(app.scheduleTasks)
        .map((t) => {
              'proje': pn(t.projectId),
              'is': t.name,
              'baslangic': t.startDate,
              'bitis': t.endDate,
              'ilerleme': t.progress,
              'sorumlu': t.responsible,
              'durum': t.status,
            })
        .toList();
  }
  if (allowed('puantaj')) {
    out['iscilier'] = _trim(app.workers)
        .map((w) => {
              'proje': pn(w.projectId),
              'ad': w.name,
              'gorev': w.role,
              'telefon': w.phone,
              'gunluk_ucret': w.dailyRate,
              'firma': w.company,
            })
        .toList();
    out['puantaj'] = _trim(app.attendance, 600)
        .map((a) => {
              'proje': pn(a.projectId),
              'isci': a.workerName,
              'tarih': a.date,
              'durum': a.status,
              'saat': a.hours,
              'not': a.note,
            })
        .toList();
  }
  if (allowed('gunluk-rapor')) {
    out['gunluk_raporlar'] = _trim(app.dailyReports)
        .map((r) => {
              'proje': pn(r.projectId),
              'tarih': r.date,
              'hava': r.weather,
              'sicaklik': r.temperature,
              'isci_sayisi': r.workerCount,
              'faaliyetler': r.activities,
              'sorunlar': r.issues,
              'hazirlayan': r.createdBy,
            })
        .toList();
  }
  if (allowed('imalat')) {
    out['imalat'] = _trim(app.productions, 400)
        .map((p) => {
              'proje': pn(p.projectId),
              'ad': p.name,
              'birim': p.unit,
              'planlanan': p.plannedQty,
              'tamamlanan': p.completedQty,
              'fiyat': p.unitPrice,
              'tarih': p.date,
            })
        .toList();
  }
  if (allowed('gorev')) {
    out['gorevler'] = _trim(app.tasks)
        .map((t) => {
              'proje': pn(t.projectId),
              'baslik': t.title,
              'aciklama': t.description,
              'atanan': t.assignee,
              'tarih': t.deadline,
              'oncelik': t.priority,
              'durum': t.status,
            })
        .toList();
  }
  if (allowed('malzeme')) {
    out['malzeme_gelen'] = _trim(app.materials)
        .map((m) => {
              'proje': pn(m.projectId),
              'ad': m.name,
              'birim': m.unit,
              'miktar': m.quantity,
              'kullanilan': m.usedQty,
              'tedarikci': m.supplier,
              'teslimat': m.deliveryDate,
              'fiyat': m.unitPrice,
            })
        .toList();
    final movs = app.materialMovements;
    out['malzeme_kullanim'] = _trim(
      movs.where((m) => m.type == 'kullanim').toList(),
      400,
    )
        .map((m) => {
              'proje': pn(m.projectId),
              'ad': m.name,
              'birim': m.unit,
              'miktar': m.quantity,
              'tarih': m.date,
              'kullanan': m.person,
              'lokasyon': m.location,
              'not': m.note,
            })
        .toList();
    out['malzeme_giden'] = _trim(
      movs.where((m) => m.type == 'giden').toList(),
      400,
    )
        .map((m) => {
              'proje': pn(m.projectId),
              'ad': m.name,
              'birim': m.unit,
              'miktar': m.quantity,
              'tarih': m.date,
              'alan_kisi': m.person,
              'hedef': m.location,
              'sebep': m.reason,
              'not': m.note,
            })
        .toList();
  }
  if (allowed('taseron')) {
    out['taseronlar'] = _trim(app.subcontractors)
        .map((s) => {
              'proje': pn(s.projectId),
              'ad': s.name,
              'kisi': s.contactPerson,
              'telefon': s.phone,
              'uzmanlik': s.specialty,
              'tutar': s.contractAmount,
              'durum': s.status,
            })
        .toList();
  }
  if (allowed('butce')) {
    out['butce'] = _trim(app.budget, 600)
        .map((b) => {
              'proje': pn(b.projectId),
              'tip': b.type,
              'kategori': b.category,
              'aciklama': b.description,
              'tutar': b.amount,
              'tarih': b.date,
            })
        .toList();
  }
  if (allowed('hakedis')) {
    out['hakedisler'] = _trim(app.hakedisler)
        .map((h) => {
              'proje': pn(h.projectId),
              'no': h.number,
              'tarih': h.date,
              'donem': h.period,
              'yuklenici': h.contractor,
              'durum': h.status,
              'toplam': h.items.fold<double>(
                0,
                (s, i) => s + i.quantity * i.unitPrice,
              ),
            })
        .toList();
  }
  if (allowed('kullanicilar')) {
    out['kullanicilar'] = _trim(app.appUsers)
        .map((u) => {
              'ad': u.name,
              'meslek': u.profession,
              'telefon': u.phone,
              'firma': u.company,
              'rol': app.roles
                      .where((r) => r.id == u.roleId)
                      .map((r) => r.name)
                      .firstOrNull ??
                  '',
            })
        .toList();
  }
  return out;
}

List<String> getSuggestedQuestions(AppState app) {
  final base = <String>[];
  if (app.productions.isNotEmpty) {
    final sample = app.productions.firstWhere(
      (p) => p.unit.toLowerCase().contains('m3'),
      orElse: () => app.productions.first,
    );
    base.add(
      'Bu ay toplam ne kadar ${sample.name.toLowerCase()} '
      '(${sample.unit}) üretildi?',
    );
  } else {
    base.add('Bu ay toplam ne kadar imalat yapıldı?');
  }
  if (app.attendance.isNotEmpty) {
    base.add('Bu hafta puantaj durumu nasıl?');
  } else {
    base.add('Projelerde kaç işçi kayıtlı?');
  }
  if (app.budget.isNotEmpty) {
    base.add('Bütçe özeti nedir?');
  }
  if (app.tasks.isNotEmpty) {
    base.add('Açık görevler neler?');
  }
  if (app.projects.isNotEmpty) {
    base.add('${app.projects.first.name} projesi hakkında özet ver.');
  }
  return base.take(4).toList();
}
