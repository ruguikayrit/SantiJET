import { Feather } from "@expo/vector-icons";
import * as FileSystem from "expo-file-system/legacy";
import * as Print from "expo-print";
import { useRouter } from "expo-router";
import * as Sharing from "expo-sharing";
import React, { useState } from "react";
import {
  ActivityIndicator,
  Alert,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import * as XLSX from "xlsx";

import Header from "@/components/Header";
import PrimaryButton from "@/components/PrimaryButton";
import { PAGE_LABELS, useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";

// ─── module definitions ───────────────────────────────────────────────────────
type ModKey =
  | "proje" | "kesif" | "is-programi" | "puantaj"
  | "gunluk-rapor" | "imalat" | "gorev" | "malzeme"
  | "taseron" | "butce" | "hakedis" | "kullanicilar";

const MODULES: { key: ModKey; icon: string }[] = [
  { key: "proje",        icon: "briefcase"  },
  { key: "kesif",        icon: "clipboard"  },
  { key: "is-programi",  icon: "calendar"   },
  { key: "puantaj",      icon: "check-square" },
  { key: "gunluk-rapor", icon: "sun"        },
  { key: "imalat",       icon: "tool"       },
  { key: "gorev",        icon: "list"       },
  { key: "malzeme",      icon: "package"    },
  { key: "taseron",      icon: "users"      },
  { key: "butce",        icon: "dollar-sign"},
  { key: "hakedis",      icon: "credit-card"},
  { key: "kullanicilar", icon: "user"       },
];

// ─── data builders ────────────────────────────────────────────────────────────
function formatCur(n: number) {
  return n?.toLocaleString("tr-TR", { minimumFractionDigits: 2 }) || "0,00";
}
function statusLabel(s: string) {
  const map: Record<string, string> = {
    active: "Aktif", paused: "Duraklatıldı", completed: "Tamamlandı",
    planned: "Planlandı", in_progress: "Devam Ediyor", delayed: "Gecikmiş",
    open: "Açık", done: "Tamamlandı",
    low: "Düşük", medium: "Orta", high: "Yüksek",
    present: "Mevcut", half: "Yarım", absent: "Yok",
    pending: "Bekliyor", approved: "Onaylandı", delivered: "Teslim Edildi", rejected: "Reddedildi",
    income: "Gelir", expense: "Gider",
    draft: "Taslak", submitted: "Gönderildi", paid: "Ödendi", cancelled: "İptal",
  };
  return map[s] || s;
}

function useSheetData(app: ReturnType<typeof useApp>) {
  const { projects, surveys, scheduleTasks, attendance, dailyReports, productions, tasks, materials, materialRequests, subcontractors, budget, hakedisler, appUsers, roles } = app;

  function getProjectName(id: string) { return projects.find(p => p.id === id)?.name || id; }

  function buildRows(key: ModKey): { headers: string[]; rows: (string | number)[][] } {
    switch (key) {
      case "proje":
        return {
          headers: ["Proje Adı", "Konum", "Müteahhit", "Başlangıç", "Bitiş", "Bütçe (₺)", "Durum"],
          rows: projects.map(p => [p.name, p.location, p.contractor, p.startDate, p.endDate, p.budget, statusLabel(p.status)]),
        };
      case "kesif":
        return {
          headers: ["Proje", "Keşif Başlığı", "Tarih", "Konum", "Poz Adedi", "Toplam (₺)"],
          rows: surveys.map(s => [
            getProjectName(s.projectId), s.title, s.date, s.location,
            s.items.length,
            s.items.reduce((acc, i) => acc + i.quantity * i.unitPrice, 0),
          ]),
        };
      case "is-programi":
        return {
          headers: ["Proje", "Görev Adı", "Sorumlu", "Başlangıç", "Bitiş", "İlerleme (%)", "Durum"],
          rows: scheduleTasks.map(t => [getProjectName(t.projectId), t.name, t.responsible, t.startDate, t.endDate, t.progress, statusLabel(t.status)]),
        };
      case "puantaj":
        return {
          headers: ["Proje", "Personel", "Tarih", "Durum", "Saat"],
          rows: attendance.map(a => [getProjectName(a.projectId), a.workerName, a.date, statusLabel(a.status), a.hours]),
        };
      case "gunluk-rapor":
        return {
          headers: ["Proje", "Tarih", "Hava", "Sıcaklık", "İşçi Sayısı", "Faaliyetler", "Sorunlar", "Oluşturan"],
          rows: dailyReports.map(r => [getProjectName(r.projectId), r.date, r.weather, r.temperature, r.workerCount, r.activities, r.issues, r.createdBy]),
        };
      case "imalat":
        return {
          headers: ["Proje", "İmalat Adı", "Birim", "Planlanan", "Tamamlanan", "Birim Fiyat (₺)", "Tarih"],
          rows: productions.map(p => [getProjectName(p.projectId), p.name, p.unit, p.plannedQty, p.completedQty, p.unitPrice, p.date]),
        };
      case "gorev":
        return {
          headers: ["Proje", "Görev", "Açıklama", "Atanan", "Son Tarih", "Öncelik", "Durum"],
          rows: tasks.map(t => [getProjectName(t.projectId), t.title, t.description, t.assignee, t.deadline, statusLabel(t.priority), statusLabel(t.status)]),
        };
      case "malzeme": {
        const all = [
          ...materials.map(m => ({ ...m, type: "Stok" })),
          ...materialRequests.map(m => ({ ...m, type: "Talep", quantity: m.quantity, unitPrice: 0, usedQty: 0, deliveryDate: m.requestDate, supplier: m.requestedBy })),
        ];
        return {
          headers: ["Proje", "Tür", "Malzeme Adı", "Birim", "Miktar", "Kullanılan", "Tedarikçi", "Tarih", "Birim Fiyat (₺)", "Durum"],
          rows: all.map(m => [
            getProjectName(m.projectId), (m as any).type || "", m.name, m.unit, m.quantity,
            (m as any).usedQty ?? "", (m as any).supplier || "", (m as any).deliveryDate || "",
            (m as any).unitPrice ?? "", statusLabel((m as any).status || ""),
          ]),
        };
      }
      case "taseron":
        return {
          headers: ["Proje", "Taşeron Adı", "İletişim", "Telefon", "Uzmanlık", "Sözleşme (₺)", "Başlangıç", "Bitiş", "Durum"],
          rows: subcontractors.map(s => [getProjectName(s.projectId), s.name, s.contactPerson, s.phone, s.specialty, s.contractAmount, s.startDate, s.endDate, statusLabel(s.status)]),
        };
      case "butce":
        return {
          headers: ["Proje", "Tür", "Kategori", "Açıklama", "Tutar (₺)", "Tarih"],
          rows: budget.map(b => [getProjectName(b.projectId), statusLabel(b.type), b.category, b.description, b.amount, b.date]),
        };
      case "hakedis": {
        const rows: (string | number)[][] = [];
        hakedisler.forEach(h => {
          const total = h.items.reduce((a, i) => a + i.quantity * i.unitPrice, 0);
          rows.push([getProjectName(h.projectId), h.number, h.period, h.contractor, h.date, h.items.length, formatCur(total), statusLabel(h.status)]);
        });
        return {
          headers: ["Proje", "No", "Dönem", "Müteahhit", "Tarih", "Kalem Sayısı", "Toplam (₺)", "Durum"],
          rows,
        };
      }
      case "kullanicilar":
        return {
          headers: ["Ad Soyad", "Rol", "Meslek", "Şirket", "Telefon", "Adres"],
          rows: appUsers.map(u => [u.name, roles.find(r => r.id === u.roleId)?.name || u.roleId, u.profession || "", u.company || "", u.phone || "", u.address || ""]),
        };
      default:
        return { headers: [], rows: [] };
    }
  }

  return buildRows;
}

// ─── HTML generator for PDF ───────────────────────────────────────────────────
function buildHtml(sections: { title: string; headers: string[]; rows: (string | number)[][] }[], projectsCount: number): string {
  const tableStyle = `border-collapse:collapse;width:100%;margin-bottom:32px;font-size:11px;`;
  const thStyle = `background:#e85d04;color:#fff;padding:6px 10px;text-align:left;border:1px solid #c44d00;`;
  const tdStyle = `padding:5px 10px;border:1px solid #ddd;`;
  const trEven = `background:#fdf4f0;`;

  const body = sections.map(s => `
    <h2 style="color:#16213e;font-size:14px;margin:0 0 6px 0;font-family:Arial;">${s.title}</h2>
    ${s.rows.length === 0 ? `<p style="color:#999;font-size:12px;">Kayıt bulunamadı.</p>` : `
    <table style="${tableStyle}">
      <thead><tr>${s.headers.map(h => `<th style="${thStyle}">${h}</th>`).join("")}</tr></thead>
      <tbody>${s.rows.map((row, i) => `<tr style="${i % 2 === 0 ? trEven : ""}">${row.map(c => `<td style="${tdStyle}">${c ?? ""}</td>`).join("")}</tr>`).join("")}</tbody>
    </table>`}
  `).join("");

  return `<!DOCTYPE html><html><head><meta charset="utf-8"/><style>
    body{font-family:Arial,sans-serif;margin:24px;color:#16213e;}
    h1{font-size:20px;color:#e85d04;margin-bottom:4px;}
    p{margin:0 0 24px 0;color:#666;font-size:12px;}
  </style></head><body>
    <h1>Şantiye Takip – Rapor</h1>
    <p>${new Date().toLocaleDateString("tr-TR")} · ${projectsCount} Proje</p>
    ${body}
  </body></html>`;
}

// ─── main component ────────────────────────────────────────────────────────────
export default function RaporScreen() {
  const colors = useColors();
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const app = useApp();
  const buildRows = useSheetData(app);

  const [selected, setSelected] = useState<Set<ModKey>>(new Set());
  const [format, setFormat] = useState<"pdf" | "excel">("pdf");
  const [loading, setLoading] = useState(false);

  function toggle(key: ModKey) {
    setSelected(prev => {
      const next = new Set(prev);
      if (next.has(key)) next.delete(key);
      else next.add(key);
      return next;
    });
  }

  function selectAll() {
    setSelected(new Set(MODULES.map(m => m.key)));
  }
  function clearAll() { setSelected(new Set()); }

  async function generate() {
    if (selected.size === 0) {
      Alert.alert("Seçim Gerekli", "En az bir modül seçmelisiniz.");
      return;
    }
    setLoading(true);
    try {
      const sections = Array.from(selected).map(k => ({
        title: PAGE_LABELS[k],
        ...buildRows(k),
      }));

      if (format === "pdf") {
        const html = buildHtml(sections, app.projects.length);
        const { uri } = await Print.printToFileAsync({ html, base64: false });
        const dest = `${FileSystem.cacheDirectory}santiye-rapor-${Date.now()}.pdf`;
        await FileSystem.moveAsync({ from: uri, to: dest });
        await Sharing.shareAsync(dest, { mimeType: "application/pdf", UTI: "com.adobe.pdf" });

      } else {
        const wb = XLSX.utils.book_new();
        for (const sec of sections) {
          const ws = XLSX.utils.aoa_to_sheet([sec.headers, ...sec.rows]);
          const safe = sec.title.replace(/[\\/?*[\]]/g, "").slice(0, 31);
          XLSX.utils.book_append_sheet(wb, ws, safe);
        }
        const base64 = XLSX.write(wb, { type: "base64", bookType: "xlsx" });
        const dest = `${FileSystem.cacheDirectory}santiye-rapor-${Date.now()}.xlsx`;
        await FileSystem.writeAsStringAsync(dest, base64, { encoding: FileSystem.EncodingType.Base64 });
        await Sharing.shareAsync(dest, {
          mimeType: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
          UTI: "com.microsoft.excel.xlsx",
        });
      }
    } catch (e: any) {
      Alert.alert("Hata", e?.message || "Rapor oluşturulamadı.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <Header title="Rapor Oluştur" onBack={() => router.back()} />

      <ScrollView
        contentContainerStyle={[styles.content, { paddingBottom: insets.bottom + 24 }]}
        showsVerticalScrollIndicator={false}
      >
        {/* Format toggle */}
        <Text style={[styles.sectionTitle, { color: colors.foreground }]}>Format</Text>
        <View style={[styles.formatRow, { backgroundColor: colors.card }]}>
          {(["pdf", "excel"] as const).map(f => (
            <TouchableOpacity
              key={f}
              style={[styles.formatBtn, format === f && { backgroundColor: colors.primary }]}
              onPress={() => setFormat(f)}
            >
              <Feather
                name={f === "pdf" ? "file-text" : "grid"}
                size={16}
                color={format === f ? "#fff" : colors.mutedForeground}
              />
              <Text style={[styles.formatLabel, { color: format === f ? "#fff" : colors.mutedForeground }]}>
                {f === "pdf" ? "PDF" : "Excel (.xlsx)"}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        {/* Module selection */}
        <View style={styles.moduleHeader}>
          <Text style={[styles.sectionTitle, { color: colors.foreground }]}>
            Modüller ({selected.size}/{MODULES.length})
          </Text>
          <View style={styles.quickBtns}>
            <TouchableOpacity onPress={selectAll} style={[styles.quickBtn, { backgroundColor: colors.primary + "20" }]}>
              <Text style={[styles.quickBtnText, { color: colors.primary }]}>Tümü</Text>
            </TouchableOpacity>
            <TouchableOpacity onPress={clearAll} style={[styles.quickBtn, { backgroundColor: colors.muted }]}>
              <Text style={[styles.quickBtnText, { color: colors.mutedForeground }]}>Temizle</Text>
            </TouchableOpacity>
          </View>
        </View>

        <View style={styles.moduleGrid}>
          {MODULES.map(m => {
            const checked = selected.has(m.key);
            return (
              <TouchableOpacity
                key={m.key}
                style={[
                  styles.moduleCard,
                  {
                    backgroundColor: checked ? colors.primary + "15" : colors.card,
                    borderColor: checked ? colors.primary : colors.card,
                  },
                ]}
                onPress={() => toggle(m.key)}
                activeOpacity={0.8}
              >
                <View style={[styles.moduleIcon, { backgroundColor: checked ? colors.primary : colors.muted }]}>
                  <Feather name={m.icon as any} size={16} color={checked ? "#fff" : colors.mutedForeground} />
                </View>
                <Text style={[styles.moduleLabel, { color: checked ? colors.primary : colors.foreground }]} numberOfLines={2}>
                  {PAGE_LABELS[m.key]}
                </Text>
                <View style={[styles.checkbox, {
                  backgroundColor: checked ? colors.primary : "transparent",
                  borderColor: checked ? colors.primary : colors.mutedForeground,
                }]}>
                  {checked ? <Feather name="check" size={10} color="#fff" /> : null}
                </View>
              </TouchableOpacity>
            );
          })}
        </View>

        {/* Generate button */}
        <View style={styles.footer}>
          {loading ? (
            <View style={[styles.loadingBtn, { backgroundColor: colors.primary }]}>
              <ActivityIndicator color="#fff" size="small" />
              <Text style={styles.loadingText}>Oluşturuluyor...</Text>
            </View>
          ) : (
            <PrimaryButton
              label={`${format === "pdf" ? "PDF" : "Excel"} Raporu Oluştur  →`}
              onPress={generate}
              style={{ opacity: selected.size === 0 ? 0.5 : 1 }}
            />
          )}
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  content: { padding: 16, gap: 0 },
  sectionTitle: { fontSize: 14, fontFamily: "Inter_700Bold", marginBottom: 10, marginTop: 4 },

  formatRow: { flexDirection: "row", borderRadius: 12, padding: 4, gap: 4, marginBottom: 20 },
  formatBtn: { flex: 1, flexDirection: "row", alignItems: "center", justifyContent: "center", gap: 8, paddingVertical: 12, borderRadius: 9 },
  formatLabel: { fontSize: 14, fontFamily: "Inter_600SemiBold" },

  moduleHeader: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", marginBottom: 10 },
  quickBtns: { flexDirection: "row", gap: 6 },
  quickBtn: { paddingHorizontal: 12, paddingVertical: 6, borderRadius: 999 },
  quickBtnText: { fontSize: 12, fontFamily: "Inter_600SemiBold" },

  moduleGrid: { flexDirection: "row", flexWrap: "wrap", gap: 8, marginBottom: 24 },
  moduleCard: {
    width: "47%",
    borderRadius: 12,
    padding: 12,
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
    borderWidth: 1.5,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.04,
    shadowRadius: 3,
    elevation: 1,
  },
  moduleIcon: { width: 32, height: 32, borderRadius: 8, alignItems: "center", justifyContent: "center" },
  moduleLabel: { flex: 1, fontSize: 13, fontFamily: "Inter_600SemiBold" },
  checkbox: {
    width: 18,
    height: 18,
    borderRadius: 5,
    borderWidth: 1.5,
    alignItems: "center",
    justifyContent: "center",
  },

  footer: { marginTop: 4 },
  loadingBtn: { flexDirection: "row", alignItems: "center", justifyContent: "center", gap: 10, paddingVertical: 16, borderRadius: 12 },
  loadingText: { color: "#fff", fontSize: 15, fontFamily: "Inter_600SemiBold" },
});
