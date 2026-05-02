import type { PageKey, Permission, useApp } from "@/context/AppContext";

type AppLike = ReturnType<typeof useApp>;
type RoleLike = { permissions: Record<PageKey, Permission> } | null;

export function buildAiSnapshot(app: AppLike, role: RoleLike) {
  const trim = <T,>(arr: T[], n = 200): T[] => arr.slice(0, n);
  const projectMap: Record<string, string> = {};
  for (const p of app.projects) projectMap[p.id] = p.name;
  const pn = (id: string) => projectMap[id] ?? "";
  const allowed = (k: PageKey) => (role?.permissions[k] ?? "none") !== "none";

  const out: Record<string, unknown> = {};

  if (allowed("proje")) {
    out.projeler = trim(app.projects).map((p) => ({
      ad: p.name, lokasyon: p.location, yuklenici: p.contractor,
      baslangic: p.startDate, bitis: p.endDate,
      ...(allowed("butce") ? { butce: p.budget } : {}),
      durum: p.status,
    }));
  }
  if (allowed("kesif")) {
    out.kesifler = trim(app.surveys).map((s) => ({
      proje: pn(s.projectId), baslik: s.title, tarih: s.date, lokasyon: s.location,
      kalemler: s.items.slice(0, 30).map((i) => ({
        aciklama: i.description, birim: i.unit, miktar: i.quantity, fiyat: i.unitPrice,
      })),
    }));
  }
  if (allowed("is-programi")) {
    out.is_programi = trim(app.scheduleTasks).map((t) => ({
      proje: pn(t.projectId), is: t.name, baslangic: t.startDate, bitis: t.endDate,
      ilerleme: t.progress, sorumlu: t.responsible, durum: t.status,
    }));
  }
  if (allowed("puantaj")) {
    out.iscilier = trim(app.workers).map((w) => ({
      proje: pn(w.projectId), ad: w.name, gorev: w.role, telefon: w.phone,
      gunluk_ucret: w.dailyRate, firma: w.company,
    }));
    out.puantaj = trim(app.attendance, 600).map((a) => ({
      proje: pn(a.projectId), isci: a.workerName, tarih: a.date, durum: a.status, saat: a.hours, not: a.note,
    }));
  }
  if (allowed("gunluk-rapor")) {
    out.gunluk_raporlar = trim(app.dailyReports).map((r) => ({
      proje: pn(r.projectId), tarih: r.date, hava: r.weather, sicaklik: r.temperature,
      isci_sayisi: r.workerCount, faaliyetler: r.activities, sorunlar: r.issues, hazirlayan: r.createdBy,
    }));
  }
  if (allowed("imalat")) {
    out.imalat = trim(app.productions, 400).map((p) => ({
      proje: pn(p.projectId), ad: p.name, birim: p.unit, planlanan: p.plannedQty,
      tamamlanan: p.completedQty, fiyat: p.unitPrice, tarih: p.date,
    }));
  }
  if (allowed("gorev")) {
    out.gorevler = trim(app.tasks).map((t) => ({
      proje: pn(t.projectId), baslik: t.title, aciklama: t.description, atanan: t.assignee,
      tarih: t.deadline, oncelik: t.priority, durum: t.status,
    }));
  }
  if (allowed("malzeme")) {
    out.malzeme_gelen = trim(app.materials).map((m) => ({
      proje: pn(m.projectId), ad: m.name, birim: m.unit, miktar: m.quantity,
      kullanilan: m.usedQty, tedarikci: m.supplier, teslimat: m.deliveryDate, fiyat: m.unitPrice,
    }));
    const movs = app.materialMovements ?? [];
    out.malzeme_kullanim = trim(movs.filter((m) => m.type === "kullanim"), 400).map((m) => ({
      proje: pn(m.projectId), ad: m.name, birim: m.unit, miktar: m.quantity,
      tarih: m.date, kullanan: m.person, lokasyon: m.location, not: m.note,
    }));
    out.malzeme_giden = trim(movs.filter((m) => m.type === "giden"), 400).map((m) => ({
      proje: pn(m.projectId), ad: m.name, birim: m.unit, miktar: m.quantity,
      tarih: m.date, alan_kisi: m.person, hedef: m.location, sebep: m.reason, not: m.note,
    }));
  }
  if (allowed("taseron")) {
    out.taseronlar = trim(app.subcontractors).map((s) => ({
      proje: pn(s.projectId), ad: s.name, kisi: s.contactPerson, telefon: s.phone,
      uzmanlik: s.specialty, tutar: s.contractAmount, durum: s.status,
    }));
  }
  if (allowed("butce")) {
    out.butce = trim(app.budget, 600).map((b) => ({
      proje: pn(b.projectId), tip: b.type, kategori: b.category, aciklama: b.description, tutar: b.amount, tarih: b.date,
    }));
  }
  if (allowed("hakedis")) {
    out.hakedisler = trim(app.hakedisler).map((h) => ({
      proje: pn(h.projectId), no: h.number, tarih: h.date, donem: h.period,
      yuklenici: h.contractor, durum: h.status,
      toplam: h.items.reduce((s, i) => s + i.quantity * i.unitPrice, 0),
    }));
  }
  if (allowed("kullanicilar")) {
    out.kullanicilar = trim(app.appUsers).map((u) => ({
      ad: u.name, meslek: u.profession, telefon: u.phone, firma: u.company,
      rol: app.roles.find((r) => r.id === u.roleId)?.name ?? "",
    }));
  }
  return out;
}

export function getSuggestedQuestions(app: AppLike): string[] {
  const base: string[] = [];
  const projectName = app.projects[0]?.name;

  if (app.productions.length > 0) {
    const sample = app.productions.find((p) => p.unit?.toLowerCase().includes("m3"))
      ?? app.productions[0];
    if (sample) {
      base.push(`Bu ay toplam ne kadar ${sample.name.toLowerCase()} ${sample.unit ? "(" + sample.unit + ")" : ""} üretildi?`);
    }
  } else {
    base.push("Bu ay toplam ne kadar imalat yapıldı?");
  }

  if (app.attendance.length > 0) {
    const w = app.workers[0];
    if (w) base.push(`${w.name} son 7 günde kaç gün işe geldi?`);
  } else {
    base.push("Bu hafta kim işe gelmedi?");
  }

  if (app.budget.length > 0) {
    base.push(projectName
      ? `${projectName} projesinin bu ayki harcaması ne kadar?`
      : "Bu ay en yüksek harcama kalemi nedir?");
  } else {
    base.push("En yüksek harcama hangi kategoride?");
  }

  if (app.materials.length > 0) {
    base.push("Hangi malzemelerin stoğu bitmek üzere?");
  } else {
    base.push("Hangi malzemeler eksik?");
  }

  if (app.scheduleTasks.length > 0) {
    base.push("Geciken işler hangileri?");
  } else {
    base.push("Bu hafta hangi işler bitmeli?");
  }

  if (app.dailyReports.length > 0) {
    base.push("Son 3 günde rapor edilen sorunlar neler?");
  }

  return base.slice(0, 6);
}
