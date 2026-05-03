import { Feather } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import React, { useMemo, useState } from "react";
import {
  ActivityIndicator,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";

import BottomSheet from "@/components/BottomSheet";
import { PageKey, Permission, useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";

interface IndexEntry {
  id: string;
  type: PageKey;
  label: string;
  sublabel: string;
  route: string;
  haystack: string;
}

const TYPE_META: Record<PageKey, { label: string; icon: string; color: string; bg: string }> = {
  proje:        { label: "Proje",        icon: "briefcase",   color: "#e85d04", bg: "#fef3e2" },
  "proje-arsivi": { label: "Proje Arşivi", icon: "folder",     color: "#475569", bg: "#e2e8f0" },
  kesif:        { label: "Keşif",         icon: "search",      color: "#0ea5e9", bg: "#e0f2fe" },
  "is-programi":{ label: "İş Programı",   icon: "calendar",    color: "#8b5cf6", bg: "#ede9fe" },
  puantaj:      { label: "Puantaj",       icon: "users",       color: "#16a34a", bg: "#dcfce7" },
  "gunluk-rapor":{label: "Günlük Rapor",  icon: "file-text",   color: "#0891b2", bg: "#cffafe" },
  imalat:       { label: "İmalat",        icon: "tool",        color: "#d97706", bg: "#fef3c7" },
  gorev:        { label: "Görev",         icon: "check-square",color: "#dc2626", bg: "#fee2e2" },
  malzeme:      { label: "Malzeme",       icon: "package",     color: "#059669", bg: "#d1fae5" },
  taseron:      { label: "Taşeron",       icon: "truck",       color: "#7c3aed", bg: "#ede9fe" },
  "satin-alma": { label: "Satın Alma",    icon: "shopping-cart", color: "#ea580c", bg: "#ffedd5" },
  kantar:       { label: "Kantar",        icon: "truck",       color: "#0d9488", bg: "#ccfbf1" },
  butce:        { label: "Bütçe",         icon: "dollar-sign", color: "#16213e", bg: "#e0e7ff" },
  hakedis:      { label: "Hakediş",       icon: "file-text",   color: "#be185d", bg: "#fce7f3" },
  ilerleme:     { label: "İlerleme",      icon: "trending-up", color: "#0d9488", bg: "#ccfbf1" },
  finans:       { label: "Finans",        icon: "credit-card", color: "#00C896", bg: "#d1fae5" },
  kullanicilar: { label: "Kullanıcılar",  icon: "shield",      color: "#7c3aed", bg: "#ede9fe" },
};

// Türkçe karakterleri normalize et + lowercase (İ/ı ayrımı için locale aware)
function norm(s: unknown): string {
  if (typeof s !== "string") return "";
  return s
    .replace(/İ/g, "I")
    .toLocaleLowerCase("tr-TR")
    .replace(/ı/g, "i")
    .replace(/ğ/g, "g")
    .replace(/ü/g, "u")
    .replace(/ş/g, "s")
    .replace(/ö/g, "o")
    .replace(/ç/g, "c")
    .trim();
}

function fmtTL(n: number | undefined): string {
  if (typeof n !== "number" || isNaN(n)) return "";
  return new Intl.NumberFormat("tr-TR", { maximumFractionDigits: 0 }).format(n) + " ₺";
}

function fmtDate(d: string | undefined): string {
  if (!d || typeof d !== "string") return "";
  const m = d.match(/^(\d{4})-(\d{2})-(\d{2})/);
  if (!m) return d;
  return `${m[3]}.${m[2]}.${m[1]}`;
}

function buildIndex(app: ReturnType<typeof useApp>): IndexEntry[] {
  const idx: IndexEntry[] = [];
  const projectName = (id: string) =>
    app.projects.find((p) => p.id === id)?.name ?? "";

  for (const p of app.projects) {
    idx.push({
      id: p.id, type: "proje", label: p.name,
      sublabel: [p.location, p.contractor].filter(Boolean).join(" · "),
      route: "/proje",
      haystack: norm([p.name, p.location, p.contractor, p.description, p.status].join(" ")),
    });
  }
  for (const f of app.archiveFiles) {
    idx.push({
      id: f.id, type: "proje-arsivi", label: f.name,
      sublabel: [projectName(f.projectId), (f.ext || "").toUpperCase(), fmtDate(f.addedAt)].filter(Boolean).join(" · "),
      route: "/proje-arsivi",
      haystack: norm([f.name, f.ext, f.note, projectName(f.projectId)].join(" ")),
    });
  }
  for (const s of app.surveys) {
    idx.push({
      id: s.id, type: "kesif", label: s.title || "(başlıksız keşif)",
      sublabel: [projectName(s.projectId), fmtDate(s.date), s.location].filter(Boolean).join(" · "),
      route: "/kesif",
      haystack: norm([s.title, s.location, s.notes, projectName(s.projectId), ...s.items.map((i) => i.description)].join(" ")),
    });
  }
  for (const t of app.scheduleTasks) {
    idx.push({
      id: t.id, type: "is-programi", label: t.name,
      sublabel: [projectName(t.projectId), t.responsible, `${t.progress}%`].filter(Boolean).join(" · "),
      route: "/is-programi",
      haystack: norm([t.name, t.responsible, t.status, projectName(t.projectId)].join(" ")),
    });
  }
  for (const w of app.workers) {
    idx.push({
      id: w.id, type: "puantaj", label: w.name,
      sublabel: [w.role, w.company, projectName(w.projectId)].filter(Boolean).join(" · "),
      route: "/puantaj",
      haystack: norm([w.name, w.role, w.phone, w.company, projectName(w.projectId)].join(" ")),
    });
  }
  for (const a of app.attendance) {
    idx.push({
      id: a.id, type: "puantaj", label: `${a.workerName} (${fmtDate(a.date)})`,
      sublabel: [a.status, `${a.hours} saat`, a.note, projectName(a.projectId)].filter(Boolean).join(" · "),
      route: "/puantaj",
      haystack: norm([a.workerName, a.status, a.note, projectName(a.projectId)].join(" ")),
    });
  }
  for (const r of app.dailyReports) {
    idx.push({
      id: r.id, type: "gunluk-rapor", label: `${fmtDate(r.date)} raporu`,
      sublabel: [projectName(r.projectId), r.weather, r.createdBy].filter(Boolean).join(" · "),
      route: "/gunluk-rapor",
      haystack: norm([r.weather, r.activities, r.issues, r.createdBy, projectName(r.projectId)].join(" ")),
    });
  }
  for (const p of app.productions) {
    idx.push({
      id: p.id, type: "imalat", label: p.name,
      sublabel: [projectName(p.projectId), `${p.completedQty}/${p.plannedQty} ${p.unit}`].filter(Boolean).join(" · "),
      route: "/imalat",
      haystack: norm([p.name, p.unit, projectName(p.projectId)].join(" ")),
    });
  }
  for (const t of app.tasks) {
    idx.push({
      id: t.id, type: "gorev", label: t.title,
      sublabel: [projectName(t.projectId), t.assignee, t.priority, t.status].filter(Boolean).join(" · "),
      route: "/gorev",
      haystack: norm([t.title, t.description, t.assignee, t.status, projectName(t.projectId)].join(" ")),
    });
  }
  for (const m of app.materials) {
    idx.push({
      id: m.id, type: "malzeme", label: m.name,
      sublabel: [projectName(m.projectId), m.supplier, `${m.quantity} ${m.unit}`].filter(Boolean).join(" · "),
      route: "/malzeme",
      haystack: norm([m.name, m.unit, m.supplier, projectName(m.projectId)].join(" ")),
    });
  }
  for (const s of app.subcontractors) {
    idx.push({
      id: s.id, type: "taseron", label: s.name,
      sublabel: [s.specialty, s.contactPerson, projectName(s.projectId)].filter(Boolean).join(" · "),
      route: "/taseron",
      haystack: norm([s.name, s.contactPerson, s.phone, s.email, s.specialty, s.notes, projectName(s.projectId)].join(" ")),
    });
  }
  for (const pu of app.purchases) {
    const total = (pu.quantity || 0) * (pu.unitPrice || 0) * (1 + (pu.vatRate || 0) / 100);
    const statusLabel =
      pu.status === "paid" ? "Ödendi"
        : pu.status === "approved" ? "Onaylandı"
        : pu.status === "cancelled" ? "İptal" : "Bekliyor";
    idx.push({
      id: pu.id, type: "satin-alma", label: `${pu.itemName} (${fmtTL(total)})`,
      sublabel: [projectName(pu.projectId), pu.supplier, statusLabel, fmtDate(pu.date)].filter(Boolean).join(" · "),
      route: "/satin-alma",
      haystack: norm([pu.itemName, pu.supplier, pu.category, pu.invoiceNo, pu.notes, statusLabel, projectName(pu.projectId)].join(" ")),
    });
  }
  for (const w of app.weighbridges) {
    idx.push({
      id: w.id, type: "kantar",
      label: `${w.materialName} (${w.netWeight} ${w.unit || "kg"} net)`,
      sublabel: [projectName(w.projectId), w.supplier, w.plate, w.irsaliyeNo ? `İrs: ${w.irsaliyeNo}` : "", fmtDate(w.date)].filter(Boolean).join(" · "),
      route: "/kantar",
      haystack: norm([w.materialName, w.supplier, w.plate, w.driver, w.irsaliyeNo, w.notes, projectName(w.projectId)].join(" ")),
    });
  }
  for (const b of app.budget) {
    idx.push({
      id: b.id, type: "butce", label: `${b.category} (${fmtTL(b.amount)})`,
      sublabel: [projectName(b.projectId), b.type === "income" ? "Gelir" : "Gider", fmtDate(b.date)].filter(Boolean).join(" · "),
      route: "/butce",
      haystack: norm([b.category, b.description, b.type, projectName(b.projectId)].join(" ")),
    });
  }
  for (const h of app.hakedisler) {
    idx.push({
      id: h.id, type: "hakedis", label: `Hakediş #${h.number}`,
      sublabel: [projectName(h.projectId), h.contractor, h.status, fmtDate(h.date)].filter(Boolean).join(" · "),
      route: "/hakedis",
      haystack: norm([h.number, h.contractor, h.notes, h.status, h.period, projectName(h.projectId), ...h.items.map((i) => i.description)].join(" ")),
    });
  }
  for (const u of app.appUsers) {
    const role = app.roles.find((r) => r.id === u.roleId);
    idx.push({
      id: u.id, type: "kullanicilar", label: u.name,
      sublabel: [role?.name, u.profession, u.company].filter(Boolean).join(" · "),
      route: "/kullanicilar",
      haystack: norm([u.name, u.profession, u.phone, u.company, role?.name].join(" ")),
    });
  }
  return idx;
}

function search(idx: IndexEntry[], query: string, isPermitted: (k: PageKey) => boolean): IndexEntry[] {
  const q = norm(query);
  if (q.length < 2) return [];
  const tokens = q.split(/\s+/).filter((t) => t.length > 0);
  const scored: Array<{ entry: IndexEntry; score: number }> = [];
  for (const entry of idx) {
    if (!isPermitted(entry.type)) continue;
    let score = 0;
    let allMatch = true;
    for (const t of tokens) {
      const pos = entry.haystack.indexOf(t);
      if (pos < 0) { allMatch = false; break; }
      score += t.length * 2;
      if (pos === 0) score += 5;
      if (norm(entry.label).indexOf(t) >= 0) score += 8;
    }
    if (allMatch) scored.push({ entry, score });
  }
  scored.sort((a, b) => b.score - a.score);
  return scored.slice(0, 30).map((s) => s.entry);
}

function buildAiSnapshot(app: ReturnType<typeof useApp>, role: { permissions: Record<PageKey, Permission> } | null) {
  const trim = <T,>(arr: T[], n = 150): T[] => arr.slice(0, n);
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
      kalemler: s.items.slice(0, 20).map((i) => ({ aciklama: i.description, birim: i.unit, miktar: i.quantity, fiyat: i.unitPrice })),
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
    out.puantaj = trim(app.attendance, 400).map((a) => ({
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
    out.imalat = trim(app.productions).map((p) => ({
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
    out.malzemeler = trim(app.materials).map((m) => ({
      proje: pn(m.projectId), ad: m.name, birim: m.unit, miktar: m.quantity,
      kullanilan: m.usedQty, tedarikci: m.supplier, teslimat: m.deliveryDate, fiyat: m.unitPrice,
    }));
  }
  if (allowed("taseron")) {
    out.taseronlar = trim(app.subcontractors).map((s) => ({
      proje: pn(s.projectId), ad: s.name, kisi: s.contactPerson, telefon: s.phone,
      uzmanlik: s.specialty, tutar: s.contractAmount, durum: s.status,
    }));
  }
  if (allowed("butce")) {
    out.butce = trim(app.budget, 400).map((b) => ({
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

interface Props {
  topInset: number;
}

export default function SmartSearch({ topInset }: Props) {
  const colors = useColors();
  const router = useRouter();
  const app = useApp();
  const [query, setQuery] = useState("");
  const [aiOpen, setAiOpen] = useState(false);
  const [aiLoading, setAiLoading] = useState(false);
  const [aiAnswer, setAiAnswer] = useState<string | null>(null);
  const [aiError, setAiError] = useState<string | null>(null);

  const { workspaceInfo, currentRole } = app;

  const isPermitted = (k: PageKey) => {
    if (!currentRole) return false;
    return (currentRole.permissions[k] ?? "none") !== "none";
  };

  const index = useMemo(() => buildIndex(app), [
    app.projects, app.surveys, app.scheduleTasks, app.workers, app.attendance,
    app.dailyReports, app.productions, app.tasks, app.materials, app.subcontractors,
    app.purchases, app.budget, app.hakedisler, app.appUsers, app.roles,
  ]);

  const results = useMemo(() => search(index, query, isPermitted), [index, query, currentRole]);

  const grouped = useMemo(() => {
    const m: Record<string, IndexEntry[]> = {};
    for (const r of results) {
      if (!m[r.type]) m[r.type] = [];
      m[r.type].push(r);
    }
    return m;
  }, [results]);

  const trimmed = query.trim();
  const showAiButton = trimmed.length >= 2;
  const cloudReady = workspaceInfo && workspaceInfo.id !== "local" && !!workspaceInfo.auth_token;

  function clearQuery() {
    setQuery("");
  }

  function goTo(route: string) {
    setQuery("");
    router.push(route as any);
  }

  async function askAi() {
    if (!trimmed || aiLoading) return;
    if (!cloudReady) {
      setAiError("Yapay zeka için önce Çalışma Alanına bağlanın.");
      setAiAnswer(null);
      setAiOpen(true);
      return;
    }
    setAiOpen(true);
    setAiLoading(true);
    setAiAnswer(null);
    setAiError(null);
    try {
      const snapshot = buildAiSnapshot(app, currentRole);
      const res = await fetch(
        `${workspaceInfo!.api_url}/api/workspaces/${workspaceInfo!.invite_code}/ask`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${workspaceInfo!.auth_token}`,
          },
          body: JSON.stringify({ question: trimmed, snapshot }),
        }
      );
      const json = await res.json().catch(() => ({}));
      if (!res.ok) {
        setAiError(json?.error || "Cevap alınamadı.");
      } else {
        setAiAnswer(typeof json.answer === "string" ? json.answer : "");
      }
    } catch (e: any) {
      setAiError(e?.message || "Bağlantı hatası.");
    } finally {
      setAiLoading(false);
    }
  }

  return (
    <View style={styles.container}>
      <View style={[styles.searchBox, { backgroundColor: "#ffffff" }]}>
        <Feather name="search" size={16} color="#94a3b8" />
        <TextInput
          value={query}
          onChangeText={setQuery}
          placeholder="Ara: işçi, proje, malzeme, hakediş..."
          placeholderTextColor="#94a3b8"
          style={styles.input}
          autoCorrect={false}
          autoCapitalize="none"
          returnKeyType="search"
          onSubmitEditing={askAi}
        />
        {trimmed.length > 0 && (
          <TouchableOpacity onPress={clearQuery} hitSlop={10}>
            <Feather name="x-circle" size={16} color="#94a3b8" />
          </TouchableOpacity>
        )}
      </View>

      {trimmed.length >= 2 && (
        <View style={[styles.resultsCard, { backgroundColor: colors.card }]}>
          {results.length === 0 ? (
            <View style={styles.empty}>
              <Feather name="info" size={14} color="#94a3b8" />
              <Text style={[styles.emptyText, { color: colors.mutedForeground }]}>
                Eşleşen kayıt yok. Yapay zekaya sorabilirsiniz.
              </Text>
            </View>
          ) : (
            <ScrollView
              style={{ maxHeight: 320 }}
              keyboardShouldPersistTaps="handled"
              showsVerticalScrollIndicator={false}
              nestedScrollEnabled
            >
              {Object.entries(grouped).map(([type, items]) => {
                const meta = TYPE_META[type as PageKey];
                return (
                  <View key={type} style={styles.group}>
                    <View style={styles.groupHeader}>
                      <View style={[styles.groupIcon, { backgroundColor: meta.bg }]}>
                        <Feather name={meta.icon as any} size={11} color={meta.color} />
                      </View>
                      <Text style={[styles.groupLabel, { color: colors.mutedForeground }]}>
                        {meta.label}
                      </Text>
                      <Text style={[styles.groupCount, { color: colors.mutedForeground }]}>
                        {items.length}
                      </Text>
                    </View>
                    {items.slice(0, 6).map((it) => (
                      <TouchableOpacity
                        key={`${it.type}-${it.id}`}
                        style={styles.row}
                        onPress={() => goTo(it.route)}
                        activeOpacity={0.7}
                      >
                        <View style={{ flex: 1 }}>
                          <Text style={[styles.rowLabel, { color: colors.foreground }]} numberOfLines={1}>
                            {it.label}
                          </Text>
                          {it.sublabel ? (
                            <Text style={[styles.rowSub, { color: colors.mutedForeground }]} numberOfLines={1}>
                              {it.sublabel}
                            </Text>
                          ) : null}
                        </View>
                        <Feather name="chevron-right" size={16} color="#94a3b8" />
                      </TouchableOpacity>
                    ))}
                  </View>
                );
              })}
            </ScrollView>
          )}

          {showAiButton && (
            <TouchableOpacity
              style={[styles.aiBtn, { backgroundColor: colors.primary }]}
              onPress={askAi}
              activeOpacity={0.85}
              disabled={aiLoading}
            >
              {aiLoading ? (
                <ActivityIndicator size="small" color="#ffffff" />
              ) : (
                <Feather name="cpu" size={14} color="#ffffff" />
              )}
              <Text style={styles.aiBtnText}>
                {aiLoading ? "Düşünüyor..." : "Yapay Zekaya Sor"}
              </Text>
            </TouchableOpacity>
          )}
        </View>
      )}

      <BottomSheet
        visible={aiOpen}
        onClose={() => { setAiOpen(false); setAiError(null); setAiAnswer(null); }}
        title="Yapay Zeka Cevabı"
      >
        <View style={styles.aiQuestion}>
          <Feather name="help-circle" size={14} color={colors.primary} />
          <Text style={[styles.aiQuestionText, { color: colors.foreground }]} numberOfLines={3}>
            {trimmed}
          </Text>
        </View>

        {aiLoading && (
          <View style={styles.aiLoading}>
            <ActivityIndicator color={colors.primary} />
            <Text style={[styles.aiLoadingText, { color: colors.mutedForeground }]}>
              Veriler taranıyor...
            </Text>
          </View>
        )}

        {aiError && (
          <View style={[styles.aiErrorBox, { borderColor: "#fecaca" }]}>
            <Feather name="alert-circle" size={14} color="#dc2626" />
            <Text style={styles.aiErrorText}>{aiError}</Text>
          </View>
        )}

        {aiAnswer && (
          <ScrollView
            style={[styles.aiAnswerBox, { backgroundColor: colors.muted }]}
            showsVerticalScrollIndicator={false}
          >
            <Text style={[styles.aiAnswerText, { color: colors.foreground }]} selectable>
              {aiAnswer}
            </Text>
          </ScrollView>
        )}

        {!aiLoading && !cloudReady && (
          <Text style={[styles.aiHint, { color: colors.mutedForeground }]}>
            Yapay zeka bulutta çalışır. Yerel modda kullanılamaz.
          </Text>
        )}

        {Platform.OS !== "web" && <View style={{ height: topInset }} />}
      </BottomSheet>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { paddingHorizontal: 16, paddingTop: 8, paddingBottom: 4 },
  searchBox: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    paddingHorizontal: 12,
    paddingVertical: Platform.OS === "web" ? 10 : 9,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: "#e5e7eb",
  },
  input: { flex: 1, fontSize: 14, color: "#0f172a", paddingVertical: 0 },
  resultsCard: {
    marginTop: 8,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: "#e5e7eb",
    overflow: "hidden",
  },
  empty: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    paddingVertical: 14,
    paddingHorizontal: 14,
  },
  emptyText: { fontSize: 13 },
  group: { borderTopWidth: 1, borderTopColor: "#f1f5f9" },
  groupHeader: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    paddingHorizontal: 12,
    paddingTop: 8,
    paddingBottom: 4,
  },
  groupIcon: {
    width: 18, height: 18, borderRadius: 5,
    alignItems: "center", justifyContent: "center",
  },
  groupLabel: { flex: 1, fontSize: 11, fontWeight: "600", textTransform: "uppercase", letterSpacing: 0.5 },
  groupCount: { fontSize: 11, fontWeight: "600" },
  row: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 14,
    paddingVertical: 10,
    gap: 8,
  },
  rowLabel: { fontSize: 14, fontWeight: "600" },
  rowSub: { fontSize: 12, marginTop: 1 },
  aiBtn: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 8,
    paddingVertical: 11,
    margin: 8,
    borderRadius: 8,
  },
  aiBtnText: { color: "#ffffff", fontSize: 13, fontWeight: "700" },
  aiQuestion: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    paddingVertical: 8,
    paddingHorizontal: 12,
    backgroundColor: "#fef3e2",
    borderRadius: 8,
    marginBottom: 10,
  },
  aiQuestionText: { fontSize: 13, fontWeight: "600", flex: 1 },
  aiLoading: { paddingVertical: 24, alignItems: "center", gap: 8 },
  aiLoadingText: { fontSize: 12 },
  aiErrorBox: {
    flexDirection: "row",
    alignItems: "flex-start",
    gap: 8,
    padding: 12,
    borderRadius: 8,
    borderWidth: 1,
    backgroundColor: "#fef2f2",
  },
  aiErrorText: { color: "#dc2626", fontSize: 13, flex: 1 },
  aiAnswerBox: {
    padding: 12,
    borderRadius: 8,
    maxHeight: 320,
  },
  aiAnswerText: { fontSize: 14, lineHeight: 21 },
  aiHint: { fontSize: 11, marginTop: 10, textAlign: "center", fontStyle: "italic" },
});
