import { Feather } from "@expo/vector-icons";
import * as FileSystem from "expo-file-system/legacy";
import * as Print from "expo-print";
import { useRouter } from "expo-router";
import * as Sharing from "expo-sharing";
import React, { useMemo, useState } from "react";
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

// ─── date helpers ─────────────────────────────────────────────────────────────
function formatDate(d: Date) {
  return `${String(d.getDate()).padStart(2, "0")}.${String(d.getMonth() + 1).padStart(2, "0")}.${d.getFullYear()}`;
}
function parseDate(s: string): Date {
  const [dd, mm, yyyy] = s.split(".");
  return new Date(+yyyy, +mm - 1, +dd);
}
function todayStr() { return formatDate(new Date()); }
function shiftDate(s: string, days: number) {
  const d = parseDate(s); d.setDate(d.getDate() + days); return formatDate(d);
}
function getWeekDays(s: string) {
  const d = parseDate(s), dow = d.getDay();
  const mon = new Date(d); mon.setDate(d.getDate() - (dow === 0 ? 6 : dow - 1));
  return Array.from({ length: 7 }, (_, i) => { const x = new Date(mon); x.setDate(mon.getDate() + i); return formatDate(x); });
}
function getMonthDays(s: string) {
  const d = parseDate(s), n = new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate();
  return Array.from({ length: n }, (_, i) => formatDate(new Date(d.getFullYear(), d.getMonth(), i + 1)));
}
const TR_DAYS_SHORT = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"];
const TR_MONTHS = ["Ocak","Şubat","Mart","Nisan","Mayıs","Haziran","Temmuz","Ağustos","Eylül","Ekim","Kasım","Aralık"];

type PuantajView = "daily" | "weekly" | "monthly";

const STATUS_OPTS = [
  { value: "present" as const, label: "Mevcut", color: "#16a34a", short: "M" },
  { value: "half"    as const, label: "Yarım",  color: "#d97706", short: "Y" },
  { value: "absent"  as const, label: "Yok",    color: "#dc2626", short: "X" },
];
function statusFor(s: string | undefined) { return STATUS_OPTS.find(o => o.value === s); }

// ─── module definitions ───────────────────────────────────────────────────────
type ModKey = "proje"|"kesif"|"is-programi"|"puantaj"|"gunluk-rapor"|"imalat"|"gorev"|"malzeme"|"taseron"|"butce"|"hakedis"|"kullanicilar";

const MODULES: { key: ModKey; icon: string }[] = [
  { key: "proje",        icon: "briefcase"   },
  { key: "kesif",        icon: "clipboard"   },
  { key: "is-programi",  icon: "calendar"    },
  { key: "puantaj",      icon: "check-square"},
  { key: "gunluk-rapor", icon: "sun"         },
  { key: "imalat",       icon: "tool"        },
  { key: "gorev",        icon: "list"        },
  { key: "malzeme",      icon: "package"     },
  { key: "taseron",      icon: "users"       },
  { key: "butce",        icon: "dollar-sign" },
  { key: "hakedis",      icon: "credit-card" },
  { key: "kullanicilar", icon: "user"        },
];

function statusLabel(s: string) {
  const map: Record<string, string> = {
    active:"Aktif", paused:"Duraklatıldı", completed:"Tamamlandı",
    planned:"Planlandı", in_progress:"Devam Ediyor", delayed:"Gecikmiş",
    open:"Açık", done:"Tamamlandı", low:"Düşük", medium:"Orta", high:"Yüksek",
    present:"Mevcut", half:"Yarım", absent:"Yok",
    pending:"Bekliyor", approved:"Onaylandı", delivered:"Teslim Edildi", rejected:"Reddedildi",
    income:"Gelir", expense:"Gider", draft:"Taslak", submitted:"Gönderildi", paid:"Ödendi", cancelled:"İptal",
  };
  return map[s] || s;
}

// ─── inline cetvel component ──────────────────────────────────────────────────
function CetvelTable({ days, appUsers, attendance, projectId, isWeekly }: {
  days: string[];
  appUsers: ReturnType<typeof useApp>["appUsers"];
  attendance: ReturnType<typeof useApp>["attendance"];
  projectId: string;
  isWeekly: boolean;
}) {
  const colors = useColors();
  const CELL = isWeekly ? 34 : 26;
  const NAME_W = 84;

  function getAtt(uid: string, d: string) {
    return attendance.find(a => a.workerId === uid && a.date === d && a.projectId === projectId);
  }

  const groups = useMemo(() => {
    const map: Record<string, typeof appUsers> = {};
    for (const u of appUsers) {
      const k = u.company?.trim() || "";
      if (!map[k]) map[k] = [];
      map[k].push(u);
    }
    return Object.entries(map).sort(([a], [b]) => (!a && b ? 1 : a && !b ? -1 : a.localeCompare(b, "tr")))
      .map(([k, u]) => ({ company: k || "Diğer", users: u }));
  }, [appUsers]);

  return (
    <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginTop: 8 }}>
      <View>
        {/* header */}
        <View style={[styles.tRow, { backgroundColor: colors.card }]}>
          <View style={[styles.tNameCell, { width: NAME_W, borderRightColor: colors.border }]}>
            <Text style={[styles.tHdr, { color: colors.mutedForeground }]}>Personel</Text>
          </View>
          {days.map((d, i) => {
            const isToday = d === todayStr();
            const label = isWeekly ? `${TR_DAYS_SHORT[i]}\n${d.split(".")[0]}` : d.split(".")[0];
            return (
              <View key={d} style={[styles.tDayCell, { width: CELL, borderRightColor: colors.border, backgroundColor: isToday ? colors.primary + "22" : undefined }]}>
                <Text style={[styles.tDayTxt, { color: isToday ? colors.primary : colors.mutedForeground }]} numberOfLines={2}>{label}</Text>
              </View>
            );
          })}
          <View style={[styles.tTotalCell, { width: 34 }]}>
            <Text style={[styles.tHdr, { color: colors.mutedForeground }]}>Top.</Text>
          </View>
        </View>

        {/* rows */}
        {groups.map(group => (
          <View key={group.company}>
            <View style={[styles.tCompRow, { backgroundColor: colors.primary + "12", width: NAME_W + days.length * CELL + 34 }]}>
              <Text style={[styles.tCompTxt, { color: colors.primary }]}>{group.company}</Text>
            </View>
            {group.users.map(u => {
              let cnt = 0;
              return (
                <View key={u.id} style={[styles.tRow, { borderBottomColor: colors.muted }]}>
                  <View style={[styles.tNameCell, { width: NAME_W, borderRightColor: colors.border }]}>
                    <Text style={[styles.tNameTxt, { color: colors.foreground }]} numberOfLines={2}>{u.name}</Text>
                  </View>
                  {days.map(d => {
                    const att = getAtt(u.id, d);
                    const opt = statusFor(att?.status);
                    if (att?.status === "present" || att?.status === "half") cnt++;
                    return (
                      <View key={d} style={[styles.tDayCell, { width: CELL, borderRightColor: colors.border }]}>
                        <View style={[styles.tBadge, { backgroundColor: opt ? opt.color : colors.muted }]}>
                          <Text style={[styles.tBadgeTxt, { color: opt ? "#fff" : colors.mutedForeground }]}>{opt ? opt.short : "–"}</Text>
                        </View>
                      </View>
                    );
                  })}
                  <View style={[styles.tTotalCell, { width: 34 }]}>
                    <Text style={[styles.tTotalNum, { color: cnt > 0 ? "#16a34a" : colors.mutedForeground }]}>{cnt > 0 ? cnt : "–"}</Text>
                  </View>
                </View>
              );
            })}
          </View>
        ))}

        {/* summary */}
        <View style={[styles.tRow, { backgroundColor: colors.card }]}>
          <View style={[styles.tNameCell, { width: NAME_W, borderRightColor: colors.border }]}>
            <Text style={[styles.tHdr, { color: colors.foreground }]}>Mevcut</Text>
          </View>
          {days.map(d => {
            const cnt = appUsers.filter(u => { const s = getAtt(u.id, d)?.status; return s === "present" || s === "half"; }).length;
            return (
              <View key={d} style={[styles.tDayCell, { width: CELL, borderRightColor: colors.border }]}>
                <Text style={[styles.tTotalNum, { color: cnt > 0 ? "#16a34a" : colors.mutedForeground }]}>{cnt > 0 ? cnt : "–"}</Text>
              </View>
            );
          })}
          <View style={[styles.tTotalCell, { width: 34 }]} />
        </View>
      </View>
    </ScrollView>
  );
}

// ─── HTML generator ───────────────────────────────────────────────────────────
function buildPuantajHtml(
  days: string[],
  label: string,
  appUsers: ReturnType<typeof useApp>["appUsers"],
  attendance: ReturnType<typeof useApp>["attendance"],
  projectId: string,
  isWeekly: boolean,
): string {
  const groups: Record<string, typeof appUsers> = {};
  for (const u of appUsers) {
    const k = u.company?.trim() || "Diğer";
    if (!groups[k]) groups[k] = [];
    groups[k].push(u);
  }

  const dayHeaders = days.map((d, i) =>
    `<th style="background:#e85d04;color:#fff;padding:5px 3px;text-align:center;font-size:9px;min-width:24px;border:1px solid #c44d00;">
      ${isWeekly ? `${TR_DAYS_SHORT[i]}<br/>${d.split(".")[0]}` : d.split(".")[0]}
    </th>`
  ).join("");

  const groupRows = Object.entries(groups).sort(([a],[b]) => (!a&&b?1:a&&!b?-1:a.localeCompare(b,"tr"))).map(([comp, users]) => {
    const colspan = days.length + 2;
    const compRow = `<tr><td colspan="${colspan}" style="background:#fff5f0;color:#e85d04;padding:5px 8px;font-size:10px;font-weight:bold;border-bottom:1px solid #eee;">${comp || "Diğer"}</td></tr>`;
    const userRows = users.map(u => {
      let cnt = 0;
      const cells = days.map(d => {
        const att = attendance.find(a => a.workerId === u.id && a.date === d && a.projectId === projectId);
        const opt = statusFor(att?.status);
        if (att?.status === "present" || att?.status === "half") cnt++;
        const bg = opt ? opt.color : "#f1f5f9";
        const txt = opt ? opt.short : "–";
        const textColor = opt ? "#fff" : "#94a3b8";
        return `<td style="text-align:center;padding:4px 2px;border:1px solid #e2e8f0;"><span style="display:inline-block;width:18px;height:18px;border-radius:3px;background:${bg};color:${textColor};font-size:9px;font-weight:bold;line-height:18px;">${txt}</span></td>`;
      }).join("");
      return `<tr><td style="padding:5px 8px;font-size:10px;border:1px solid #e2e8f0;white-space:nowrap;">${u.name}${u.profession ? `<br/><span style="color:#94a3b8;font-size:8px;">${u.profession}</span>` : ""}</td>${cells}<td style="text-align:center;font-size:11px;font-weight:bold;color:${cnt>0?"#16a34a":"#94a3b8"};border:1px solid #e2e8f0;">${cnt>0?cnt:"–"}</td></tr>`;
    }).join("");
    return compRow + userRows;
  }).join("");

  const summaryRow = `<tr style="background:#f8fafc;"><td style="padding:5px 8px;font-size:10px;font-weight:bold;border:1px solid #e2e8f0;">Mevcut</td>${days.map(d => {
    const cnt = appUsers.filter(u => { const s = attendance.find(a => a.workerId===u.id&&a.date===d&&a.projectId===projectId)?.status; return s==="present"||s==="half"; }).length;
    return `<td style="text-align:center;font-size:11px;font-weight:bold;color:${cnt>0?"#16a34a":"#94a3b8"};border:1px solid #e2e8f0;">${cnt>0?cnt:"–"}</td>`;
  }).join("")}<td style="border:1px solid #e2e8f0;"></td></tr>`;

  return `<h3 style="color:#16213e;font-size:13px;margin:16px 0 6px 0;">Puantaj – ${label}</h3>
<div style="font-size:11px;color:#666;margin-bottom:8px;">Personel: ${appUsers.length} kişi · Günler: ${days[0]} – ${days[days.length-1]}</div>
<table style="border-collapse:collapse;font-family:Arial;margin-bottom:24px;width:100%;">
  <thead><tr><th style="background:#16213e;color:#fff;padding:5px 8px;text-align:left;font-size:10px;border:1px solid #0a1628;">Personel</th>${dayHeaders}<th style="background:#16213e;color:#fff;padding:5px 3px;text-align:center;font-size:9px;border:1px solid #0a1628;">Top.</th></tr></thead>
  <tbody>${groupRows}${summaryRow}</tbody>
</table>
<div style="font-size:9px;color:#666;margin-bottom:8px;">
  <span style="display:inline-block;width:14px;height:14px;background:#16a34a;border-radius:2px;vertical-align:middle;margin-right:4px;"></span>M=Mevcut &nbsp;
  <span style="display:inline-block;width:14px;height:14px;background:#d97706;border-radius:2px;vertical-align:middle;margin-right:4px;"></span>Y=Yarım &nbsp;
  <span style="display:inline-block;width:14px;height:14px;background:#dc2626;border-radius:2px;vertical-align:middle;margin-right:4px;"></span>X=Yok
</div>`;
}

function buildPuantajXlsx(
  days: string[],
  appUsers: ReturnType<typeof useApp>["appUsers"],
  attendance: ReturnType<typeof useApp>["attendance"],
  projectId: string,
  isWeekly: boolean,
) {
  const headers = ["Personel", "Şirket", "Meslek", ...days, "Toplam"];
  const rows: (string | number)[][] = appUsers.map(u => {
    let cnt = 0;
    const cells = days.map(d => {
      const att = attendance.find(a => a.workerId === u.id && a.date === d && a.projectId === projectId);
      const opt = statusFor(att?.status);
      if (att?.status === "present" || att?.status === "half") cnt++;
      return opt ? opt.short : "–";
    });
    return [u.name, u.company || "", u.profession || "", ...cells, cnt];
  });
  const summaryRow = ["Mevcut Sayısı", "", "", ...days.map(d => {
    return appUsers.filter(u => { const s = attendance.find(a => a.workerId===u.id&&a.date===d&&a.projectId===projectId)?.status; return s==="present"||s==="half"; }).length;
  }), ""];
  return { headers, rows: [...rows, summaryRow] };
}

function buildHtml(sections: { title: string; headers: string[]; rows: (string | number)[][]; raw?: string }[], projectsCount: number) {
  const thS = `background:#e85d04;color:#fff;padding:6px 10px;text-align:left;border:1px solid #c44d00;font-size:11px;`;
  const tdS = `padding:5px 10px;border:1px solid #ddd;font-size:11px;`;

  const body = sections.map(s => {
    if (s.raw) return s.raw;
    return `<h2 style="color:#16213e;font-size:14px;margin:0 0 6px 0;font-family:Arial;">${s.title}</h2>
    ${s.rows.length === 0 ? `<p style="color:#999;font-size:12px;">Kayıt bulunamadı.</p>` :
    `<table style="border-collapse:collapse;width:100%;margin-bottom:32px;">
      <thead><tr>${s.headers.map(h => `<th style="${thS}">${h}</th>`).join("")}</tr></thead>
      <tbody>${s.rows.map((row, i) => `<tr style="${i%2===0?"background:#fdf4f0;":""}">${row.map(c => `<td style="${tdS}">${c??""}</td>`).join("")}</tr>`).join("")}</tbody>
    </table>`}`;
  }).join("");

  return `<!DOCTYPE html><html><head><meta charset="utf-8"/><style>body{font-family:Arial,sans-serif;margin:24px;color:#16213e;}h1{font-size:20px;color:#e85d04;margin-bottom:4px;}p{margin:0 0 24px 0;color:#666;font-size:12px;}</style></head><body>
<h1>ŞantiJET – Rapor</h1><p>${new Date().toLocaleDateString("tr-TR")} · ${projectsCount} Proje</p>${body}</body></html>`;
}

// ─── main component ───────────────────────────────────────────────────────────
export default function RaporScreen() {
  const colors = useColors();
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const app = useApp();

  const { projects, surveys, scheduleTasks, attendance, dailyReports, productions, tasks, materials, materialRequests, subcontractors, budget, hakedisler, appUsers, roles } = app;

  const [selectedOrder, setSelectedOrder] = useState<ModKey[]>([]);
  const selected = useMemo(() => new Set(selectedOrder), [selectedOrder]);
  const [format, setFormat] = useState<"pdf" | "excel">("pdf");
  const [loading, setLoading] = useState(false);

  // Puantaj-specific
  const [puantajView, setPuantajView] = useState<PuantajView>("weekly");
  const [puantajDate, setPuantajDate] = useState(todayStr());
  const [puantajProject, setPuantajProject] = useState<string>(projects[0]?.id || "");

  const weekDays  = useMemo(() => getWeekDays(puantajDate),  [puantajDate]);
  const monthDays = useMemo(() => getMonthDays(puantajDate), [puantajDate]);
  const cetvelDays = puantajView === "daily"   ? [puantajDate]
                   : puantajView === "weekly"  ? weekDays
                   : monthDays;

  function weekLabel() {
    const [d1,m1] = weekDays[0].split("."); const [d2,m2,y2] = weekDays[6].split(".");
    return `${d1}.${m1} – ${d2}.${m2}.${y2}`;
  }
  function monthLabel() {
    const d = parseDate(puantajDate); return `${TR_MONTHS[d.getMonth()]} ${d.getFullYear()}`;
  }
  function navLabel() {
    return puantajView === "daily" ? puantajDate : puantajView === "weekly" ? weekLabel() : monthLabel();
  }
  function navPrev() {
    if (puantajView === "daily")   setPuantajDate(shiftDate(puantajDate, -1));
    if (puantajView === "weekly")  setPuantajDate(shiftDate(puantajDate, -7));
    if (puantajView === "monthly") { const d = parseDate(puantajDate); d.setMonth(d.getMonth()-1); setPuantajDate(formatDate(d)); }
  }
  function navNext() {
    if (puantajView === "daily")   setPuantajDate(shiftDate(puantajDate, 1));
    if (puantajView === "weekly")  setPuantajDate(shiftDate(puantajDate, 7));
    if (puantajView === "monthly") { const d = parseDate(puantajDate); d.setMonth(d.getMonth()+1); setPuantajDate(formatDate(d)); }
  }

  function toggle(key: ModKey) {
    setSelectedOrder(prev => prev.includes(key) ? prev.filter(k => k !== key) : [...prev, key]);
  }
  function selectAll() { setSelectedOrder(MODULES.map(m => m.key)); }
  function clearAll()  { setSelectedOrder([]); }
  function moveUp(idx: number) {
    if (idx === 0) return;
    setSelectedOrder(prev => { const n = [...prev]; [n[idx-1], n[idx]] = [n[idx], n[idx-1]]; return n; });
  }
  function moveDown(idx: number) {
    setSelectedOrder(prev => { if (idx === prev.length - 1) return prev; const n = [...prev]; [n[idx], n[idx+1]] = [n[idx+1], n[idx]]; return n; });
  }
  function removeFromOrder(key: ModKey) {
    setSelectedOrder(prev => prev.filter(k => k !== key));
  }

  function getProjectName(id: string) { return projects.find(p => p.id === id)?.name || id; }

  function buildSection(key: ModKey): { title: string; headers: string[]; rows: (string|number)[][]; raw?: string } {
    const title = PAGE_LABELS[k = key];
    switch (key) {
      case "proje": return { title, headers: ["Proje Adı","Konum","Müteahhit","Başlangıç","Bitiş","Bütçe (₺)","Durum"], rows: projects.map(p=>[p.name,p.location,p.contractor,p.startDate,p.endDate,p.budget,statusLabel(p.status)]) };
      case "kesif": return { title, headers: ["Proje","Başlık","Tarih","Konum","Poz Adedi","Toplam (₺)"], rows: surveys.map(s=>[getProjectName(s.projectId),s.title,s.date,s.location,s.items.length,s.items.reduce((a,i)=>a+i.quantity*i.unitPrice,0)]) };
      case "is-programi": return { title, headers: ["Proje","Görev","Sorumlu","Başlangıç","Bitiş","İlerleme (%)","Durum"], rows: scheduleTasks.map(t=>[getProjectName(t.projectId),t.name,t.responsible,t.startDate,t.endDate,t.progress,statusLabel(t.status)]) };
      case "puantaj": {
        const isW = puantajView !== "monthly";
        if (format === "pdf") {
          const raw = buildPuantajHtml(cetvelDays, navLabel(), appUsers, attendance, puantajProject, puantajView === "weekly");
          return { title, headers: [], rows: [], raw };
        } else {
          const { headers, rows } = buildPuantajXlsx(cetvelDays, appUsers, attendance, puantajProject, puantajView === "weekly");
          return { title, headers, rows };
        }
      }
      case "gunluk-rapor": return { title, headers: ["Proje","Tarih","Hava","Sıcaklık","İşçi","Faaliyetler","Sorunlar","Oluşturan"], rows: dailyReports.map(r=>[getProjectName(r.projectId),r.date,r.weather,r.temperature,r.workerCount,r.activities,r.issues,r.createdBy]) };
      case "imalat": return { title, headers: ["Proje","İmalat","Birim","Planlanan","Tamamlanan","Birim Fiyat (₺)","Tarih"], rows: productions.map(p=>[getProjectName(p.projectId),p.name,p.unit,p.plannedQty,p.completedQty,p.unitPrice,p.date]) };
      case "gorev": return { title, headers: ["Proje","Görev","Açıklama","Atanan","Son Tarih","Öncelik","Durum"], rows: tasks.map(t=>[getProjectName(t.projectId),t.title,t.description,t.assignee,t.deadline,statusLabel(t.priority),statusLabel(t.status)]) };
      case "malzeme": {
        const all = [...materials.map(m=>({...m,type:"Stok"})),...materialRequests.map(m=>({...m,type:"Talep",usedQty:0,unitPrice:0,deliveryDate:m.requestDate,supplier:m.requestedBy}))];
        return { title, headers: ["Proje","Tür","Malzeme","Birim","Miktar","Kullanılan","Tedarikçi","Tarih","Birim Fiyat (₺)","Durum"], rows: all.map(m=>[getProjectName(m.projectId),(m as any).type,m.name,m.unit,m.quantity,(m as any).usedQty??"",(m as any).supplier||"",(m as any).deliveryDate||"",(m as any).unitPrice??"",statusLabel((m as any).status||"")]) };
      }
      case "taseron": return { title, headers: ["Proje","Taşeron","İletişim","Telefon","Uzmanlık","Sözleşme (₺)","Başlangıç","Bitiş","Durum"], rows: subcontractors.map(s=>[getProjectName(s.projectId),s.name,s.contactPerson,s.phone,s.specialty,s.contractAmount,s.startDate,s.endDate,statusLabel(s.status)]) };
      case "butce": return { title, headers: ["Proje","Tür","Kategori","Açıklama","Tutar (₺)","Tarih"], rows: budget.map(b=>[getProjectName(b.projectId),statusLabel(b.type),b.category,b.description,b.amount,b.date]) };
      case "hakedis": return { title, headers: ["Proje","No","Dönem","Müteahhit","Tarih","Kalem","Toplam (₺)","Durum"], rows: hakedisler.map(h=>[getProjectName(h.projectId),h.number,h.period,h.contractor,h.date,h.items.length,h.items.reduce((a,i)=>a+i.quantity*i.unitPrice,0).toFixed(2),statusLabel(h.status)]) };
      case "kullanicilar": return { title, headers: ["Ad Soyad","Rol","Meslek","Şirket","Telefon","Adres"], rows: appUsers.map(u=>[u.name,roles.find(r=>r.id===u.roleId)?.name||u.roleId,u.profession||"",u.company||"",u.phone||"",u.address||""]) };
      default: return { title, headers: [], rows: [] };
    }
    var k: ModKey; // satisfy ts
  }

  async function generate() {
    if (selectedOrder.length === 0) { Alert.alert("Seçim Gerekli", "En az bir modül seçmelisiniz."); return; }
    setLoading(true);
    try {
      const sections = selectedOrder.map(k => buildSection(k));

      if (format === "pdf") {
        const html = buildHtml(sections, projects.length);
        const { uri } = await Print.printToFileAsync({ html, base64: false });
        const dest = `${FileSystem.cacheDirectory}santiye-rapor-${Date.now()}.pdf`;
        await FileSystem.moveAsync({ from: uri, to: dest });
        await Sharing.shareAsync(dest, { mimeType: "application/pdf", UTI: "com.adobe.pdf" });
      } else {
        const wb = XLSX.utils.book_new();
        for (const sec of sections) {
          const ws = XLSX.utils.aoa_to_sheet([sec.headers, ...sec.rows]);
          XLSX.utils.book_append_sheet(wb, ws, sec.title.replace(/[\\/?*[\]]/g,"").slice(0,31));
        }
        const base64 = XLSX.write(wb, { type: "base64", bookType: "xlsx" });
        const dest = `${FileSystem.cacheDirectory}santiye-rapor-${Date.now()}.xlsx`;
        await FileSystem.writeAsStringAsync(dest, base64, { encoding: FileSystem.EncodingType.Base64 });
        await Sharing.shareAsync(dest, { mimeType: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", UTI: "com.microsoft.excel.xlsx" });
      }
    } catch (e: any) {
      Alert.alert("Hata", e?.message || "Rapor oluşturulamadı.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <Header title="Rapor Oluştur" onBack={() => (router.canGoBack() ? router.back() : router.replace("/"))} />

      <ScrollView contentContainerStyle={[styles.content, { paddingBottom: insets.bottom + 24 }]} showsVerticalScrollIndicator={false}>

        {/* Format */}
        <Text style={[styles.sectionTitle, { color: colors.foreground }]}>Format</Text>
        <View style={[styles.formatRow, { backgroundColor: colors.card }]}>
          {(["pdf","excel"] as const).map(f => (
            <TouchableOpacity key={f} style={[styles.formatBtn, format===f && { backgroundColor: colors.primary }]} onPress={() => setFormat(f)}>
              <Feather name={f==="pdf" ? "file-text" : "grid"} size={16} color={format===f?"#fff":colors.mutedForeground} />
              <Text style={[styles.formatLabel, { color: format===f?"#fff":colors.mutedForeground }]}>{f==="pdf"?"PDF":"Excel (.xlsx)"}</Text>
            </TouchableOpacity>
          ))}
        </View>

        {/* Modules */}
        <View style={styles.moduleHeader}>
          <Text style={[styles.sectionTitle, { color: colors.foreground }]}>Modüller ({selectedOrder.length}/{MODULES.length})</Text>
          <View style={styles.quickBtns}>
            <TouchableOpacity onPress={selectAll} style={[styles.quickBtn, { backgroundColor: colors.primary+"20" }]}>
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
              <TouchableOpacity key={m.key} style={[styles.moduleCard, { backgroundColor: checked?colors.primary+"15":colors.card, borderColor: checked?colors.primary:colors.card }]} onPress={() => toggle(m.key)} activeOpacity={0.8}>
                <View style={[styles.moduleIcon, { backgroundColor: checked?colors.primary:colors.muted }]}>
                  <Feather name={m.icon as any} size={16} color={checked?"#fff":colors.mutedForeground} />
                </View>
                <Text style={[styles.moduleLabel, { color: checked?colors.primary:colors.foreground }]} numberOfLines={2}>{PAGE_LABELS[m.key]}</Text>
                <View style={[styles.checkbox, { backgroundColor: checked?colors.primary:"transparent", borderColor: checked?colors.primary:colors.mutedForeground }]}>
                  {checked ? <Feather name="check" size={10} color="#fff" /> : null}
                </View>
              </TouchableOpacity>
            );
          })}
        </View>

        {/* ── Rapor sırası paneli ── */}
        {selectedOrder.length > 0 && (
          <View style={[styles.orderBox, { backgroundColor: colors.card, borderColor: colors.border }]}>
            <View style={styles.orderBoxHeader}>
              <Feather name="list" size={15} color={colors.primary} />
              <Text style={[styles.orderBoxTitle, { color: colors.foreground }]}>
                Rapor Sırası
              </Text>
              <Text style={[styles.orderBoxHint, { color: colors.mutedForeground }]}>
                Sırayı değiştirmek için ↑ ↓ kullanın
              </Text>
            </View>

            {selectedOrder.map((key, idx) => {
              const mod = MODULES.find(m => m.key === key)!;
              return (
                <View
                  key={key}
                  style={[
                    styles.orderItem,
                    { borderBottomColor: colors.muted },
                    idx === selectedOrder.length - 1 && { borderBottomWidth: 0 },
                  ]}
                >
                  {/* Index badge */}
                  <View style={[styles.orderBadge, { backgroundColor: colors.primary }]}>
                    <Text style={styles.orderBadgeText}>{idx + 1}</Text>
                  </View>

                  {/* Icon + label */}
                  <View style={[styles.orderIcon, { backgroundColor: colors.muted }]}>
                    <Feather name={mod.icon as any} size={14} color={colors.mutedForeground} />
                  </View>
                  <Text style={[styles.orderLabel, { color: colors.foreground }]} numberOfLines={1}>
                    {PAGE_LABELS[key]}
                  </Text>

                  {/* Controls */}
                  <View style={styles.orderControls}>
                    <TouchableOpacity
                      onPress={() => moveUp(idx)}
                      style={[styles.orderBtn, { backgroundColor: idx === 0 ? colors.muted + "60" : colors.muted }]}
                      disabled={idx === 0}
                    >
                      <Feather name="chevron-up" size={14} color={idx === 0 ? colors.mutedForeground + "60" : colors.foreground} />
                    </TouchableOpacity>
                    <TouchableOpacity
                      onPress={() => moveDown(idx)}
                      style={[styles.orderBtn, { backgroundColor: idx === selectedOrder.length - 1 ? colors.muted + "60" : colors.muted }]}
                      disabled={idx === selectedOrder.length - 1}
                    >
                      <Feather name="chevron-down" size={14} color={idx === selectedOrder.length - 1 ? colors.mutedForeground + "60" : colors.foreground} />
                    </TouchableOpacity>
                    <TouchableOpacity
                      onPress={() => removeFromOrder(key)}
                      style={[styles.orderBtn, { backgroundColor: "#dc262620" }]}
                    >
                      <Feather name="x" size={14} color="#dc2626" />
                    </TouchableOpacity>
                  </View>
                </View>
              );
            })}
          </View>
        )}

        {/* ── Puantaj cetvel options (shown when puantaj is selected) ── */}
        {selected.has("puantaj") && (
          <View style={[styles.puantajBox, { backgroundColor: colors.card, borderColor: colors.primary + "40" }]}>
            <View style={styles.puantajBoxHeader}>
              <Feather name="check-square" size={15} color={colors.primary} />
              <Text style={[styles.puantajBoxTitle, { color: colors.primary }]}>Puantaj Cetveli</Text>
            </View>

            {/* Project picker */}
            {projects.length > 0 && (
              <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginBottom: 10 }}>
                <View style={{ flexDirection: "row", gap: 6 }}>
                  {projects.map(p => (
                    <TouchableOpacity key={p.id} onPress={() => setPuantajProject(p.id)}
                      style={[styles.projChip, { backgroundColor: puantajProject===p.id?colors.primary:colors.muted }]}>
                      <Text style={[styles.projChipText, { color: puantajProject===p.id?"#fff":colors.mutedForeground }]} numberOfLines={1}>{p.name}</Text>
                    </TouchableOpacity>
                  ))}
                </View>
              </ScrollView>
            )}

            {/* View mode tabs */}
            <View style={[styles.viewTabs, { backgroundColor: colors.muted }]}>
              {([["daily","Günlük"],["weekly","Haftalık"],["monthly","Aylık"]] as [PuantajView,string][]).map(([v,l]) => (
                <TouchableOpacity key={v} style={[styles.viewTab, puantajView===v&&{ backgroundColor: colors.primary }]} onPress={() => setPuantajView(v)}>
                  <Text style={[styles.viewTabText, { color: puantajView===v?"#fff":colors.mutedForeground }]}>{l}</Text>
                </TouchableOpacity>
              ))}
            </View>

            {/* Navigation */}
            <View style={[styles.navRow, { backgroundColor: colors.muted }]}>
              <TouchableOpacity style={styles.navBtn} onPress={navPrev}>
                <Feather name="chevron-left" size={18} color={colors.foreground} />
              </TouchableOpacity>
              <Text style={[styles.navLabel, { color: colors.foreground }]}>{navLabel()}</Text>
              <TouchableOpacity style={styles.navBtn} onPress={navNext}>
                <Feather name="chevron-right" size={18} color={colors.foreground} />
              </TouchableOpacity>
            </View>

            {/* Legend */}
            <View style={styles.legend}>
              {STATUS_OPTS.map(o => (
                <View key={o.value} style={styles.legendItem}>
                  <View style={[styles.legendDot, { backgroundColor: o.color }]}><Text style={styles.legendShort}>{o.short}</Text></View>
                  <Text style={[styles.legendLbl, { color: colors.mutedForeground }]}>{o.label}</Text>
                </View>
              ))}
            </View>

            {/* Cetvel table */}
            {appUsers.length === 0 ? (
              <Text style={[styles.emptyNote, { color: colors.mutedForeground }]}>Kayıtlı personel yok.</Text>
            ) : (
              <CetvelTable
                days={cetvelDays}
                appUsers={appUsers}
                attendance={attendance}
                projectId={puantajProject}
                isWeekly={puantajView === "weekly"}
              />
            )}
          </View>
        )}

        {/* Generate */}
        <View style={styles.footer}>
          {loading ? (
            <View style={[styles.loadingBtn, { backgroundColor: colors.primary }]}>
              <ActivityIndicator color="#fff" size="small" />
              <Text style={styles.loadingText}>Oluşturuluyor...</Text>
            </View>
          ) : (
            <PrimaryButton label={`${format==="pdf"?"PDF":"Excel"} Raporu Oluştur  →`} onPress={generate} style={{ opacity: selectedOrder.length===0?0.5:1 }} />
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
  moduleGrid: { flexDirection: "row", flexWrap: "wrap", gap: 8, marginBottom: 16 },
  moduleCard: { width: "47%", borderRadius: 12, padding: 12, flexDirection: "row", alignItems: "center", gap: 10, borderWidth: 1.5, shadowColor: "#000", shadowOffset:{width:0,height:1}, shadowOpacity:0.04, shadowRadius:3, elevation:1 },
  moduleIcon: { width: 32, height: 32, borderRadius: 8, alignItems: "center", justifyContent: "center" },
  moduleLabel: { flex: 1, fontSize: 13, fontFamily: "Inter_600SemiBold" },
  checkbox: { width: 18, height: 18, borderRadius: 5, borderWidth: 1.5, alignItems: "center", justifyContent: "center" },

  puantajBox: { borderRadius: 14, borderWidth: 1.5, padding: 14, marginBottom: 16 },
  puantajBoxHeader: { flexDirection: "row", alignItems: "center", gap: 7, marginBottom: 12 },
  puantajBoxTitle: { fontSize: 14, fontFamily: "Inter_700Bold" },
  projChip: { paddingHorizontal: 12, paddingVertical: 6, borderRadius: 999 },
  projChipText: { fontSize: 12, fontFamily: "Inter_600SemiBold" },
  viewTabs: { flexDirection: "row", borderRadius: 10, padding: 3, gap: 3, marginBottom: 8 },
  viewTab: { flex: 1, alignItems: "center", paddingVertical: 7, borderRadius: 8 },
  viewTabText: { fontSize: 12, fontFamily: "Inter_600SemiBold" },
  navRow: { flexDirection: "row", alignItems: "center", borderRadius: 10, marginBottom: 10 },
  navBtn: { paddingHorizontal: 14, paddingVertical: 8 },
  navLabel: { flex: 1, textAlign: "center", fontSize: 13, fontFamily: "Inter_600SemiBold" },
  legend: { flexDirection: "row", gap: 10, marginBottom: 8, flexWrap: "wrap" },
  legendItem: { flexDirection: "row", alignItems: "center", gap: 4 },
  legendDot: { width: 18, height: 18, borderRadius: 3, alignItems: "center", justifyContent: "center" },
  legendShort: { fontSize: 9, fontFamily: "Inter_700Bold", color: "#fff" },
  legendLbl: { fontSize: 11, fontFamily: "Inter_400Regular" },
  emptyNote: { fontSize: 13, fontFamily: "Inter_400Regular", textAlign: "center", paddingVertical: 16 },

  // table
  tRow: { flexDirection: "row", alignItems: "center", borderBottomWidth: StyleSheet.hairlineWidth },
  tNameCell: { paddingHorizontal: 6, paddingVertical: 8, borderRightWidth: StyleSheet.hairlineWidth, justifyContent: "center" },
  tHdr: { fontSize: 9, fontFamily: "Inter_600SemiBold", textAlign: "center" },
  tNameTxt: { fontSize: 10, fontFamily: "Inter_500Medium" },
  tDayCell: { alignItems: "center", justifyContent: "center", paddingVertical: 6, borderRightWidth: StyleSheet.hairlineWidth },
  tDayTxt: { fontSize: 8, fontFamily: "Inter_600SemiBold", textAlign: "center" },
  tBadge: { width: 18, height: 18, borderRadius: 3, alignItems: "center", justifyContent: "center" },
  tBadgeTxt: { fontSize: 9, fontFamily: "Inter_700Bold" },
  tTotalCell: { alignItems: "center", justifyContent: "center", paddingVertical: 6 },
  tTotalNum: { fontSize: 11, fontFamily: "Inter_700Bold" },
  tCompRow: { paddingHorizontal: 6, paddingVertical: 4 },
  tCompTxt: { fontSize: 10, fontFamily: "Inter_700Bold" },

  orderBox: { borderRadius: 14, borderWidth: 1, marginBottom: 16, overflow: "hidden" },
  orderBoxHeader: { flexDirection: "row", alignItems: "center", gap: 7, paddingHorizontal: 14, paddingVertical: 12, borderBottomWidth: StyleSheet.hairlineWidth, borderBottomColor: "#e2e8f020" },
  orderBoxTitle: { fontSize: 14, fontFamily: "Inter_700Bold" },
  orderBoxHint: { flex: 1, fontSize: 11, fontFamily: "Inter_400Regular", textAlign: "right" },
  orderItem: { flexDirection: "row", alignItems: "center", paddingHorizontal: 12, paddingVertical: 10, gap: 9, borderBottomWidth: StyleSheet.hairlineWidth },
  orderBadge: { width: 22, height: 22, borderRadius: 6, alignItems: "center", justifyContent: "center" },
  orderBadgeText: { fontSize: 11, fontFamily: "Inter_700Bold", color: "#fff" },
  orderIcon: { width: 28, height: 28, borderRadius: 7, alignItems: "center", justifyContent: "center" },
  orderLabel: { flex: 1, fontSize: 13, fontFamily: "Inter_600SemiBold" },
  orderControls: { flexDirection: "row", gap: 5 },
  orderBtn: { width: 28, height: 28, borderRadius: 7, alignItems: "center", justifyContent: "center" },

  footer: { marginTop: 8 },
  loadingBtn: { flexDirection: "row", alignItems: "center", justifyContent: "center", gap: 10, paddingVertical: 16, borderRadius: 12 },
  loadingText: { color: "#fff", fontSize: 15, fontFamily: "Inter_600SemiBold" },
});
