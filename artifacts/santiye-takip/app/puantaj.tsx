import { Feather } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import React, { useEffect, useMemo, useState } from "react";
import {
  Alert,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import DatePickerInput from "@/components/DatePickerInput";
import EmptyState from "@/components/EmptyState";
import Header from "@/components/Header";
import ProjectPicker from "@/components/ProjectPicker";
import { AppUser, Attendance, useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";
import { usePermission } from "@/hooks/usePermission";

// ─── date helpers ─────────────────────────────────────────────────────────────
function formatDate(d: Date) {
  return `${String(d.getDate()).padStart(2, "0")}.${String(d.getMonth() + 1).padStart(2, "0")}.${d.getFullYear()}`;
}
function parseDate(s: string): Date {
  const [dd, mm, yyyy] = s.split(".");
  return new Date(+yyyy, +mm - 1, +dd);
}
function todayStr() { return formatDate(new Date()); }
function getWeekDays(dateStr: string): string[] {
  const d = parseDate(dateStr);
  const dow = d.getDay();
  const mon = new Date(d);
  mon.setDate(d.getDate() - (dow === 0 ? 6 : dow - 1));
  return Array.from({ length: 7 }, (_, i) => {
    const x = new Date(mon); x.setDate(mon.getDate() + i); return formatDate(x);
  });
}
function getMonthDays(dateStr: string): string[] {
  const d = parseDate(dateStr);
  const n = new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate();
  return Array.from({ length: n }, (_, i) => formatDate(new Date(d.getFullYear(), d.getMonth(), i + 1)));
}
function shiftDate(dateStr: string, days: number): string {
  const d = parseDate(dateStr); d.setDate(d.getDate() + days); return formatDate(d);
}
const TR_DAYS_SHORT = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"];
const TR_MONTHS = ["Ocak","Şubat","Mart","Nisan","Mayıs","Haziran","Temmuz","Ağustos","Eylül","Ekim","Kasım","Aralık"];

// ─── status definitions ───────────────────────────────────────────────────────
type AttStatus = Attendance["status"];
type ViewMode = "daily" | "weekly" | "monthly";

const STATUS_OPTS: { value: AttStatus; label: string; color: string; short: string; hours: number }[] = [
  { value: "present", label: "Mevcut",      color: "#16a34a", short: "M",  hours: 8 },
  { value: "half",    label: "Yarım Gün",   color: "#d97706", short: "Y",  hours: 4 },
  { value: "izinli",  label: "İzinli",      color: "#0ea5e9", short: "İ",  hours: 0 },
  { value: "raporlu", label: "Raporlu",     color: "#8b5cf6", short: "R",  hours: 0 },
  { value: "mazeret", label: "Mazeret",     color: "#f59e0b", short: "Mz", hours: 0 },
  { value: "tatil",   label: "Res. Tatil",  color: "#64748b", short: "T",  hours: 0 },
  { value: "absent",  label: "Yok",         color: "#dc2626", short: "X",  hours: 0 },
];
function statusFor(s: AttStatus | undefined) { return STATUS_OPTS.find(o => o.value === s); }
function hoursFor(s: AttStatus): number { return STATUS_OPTS.find(o => o.value === s)?.hours ?? 0; }

// ─── main component ───────────────────────────────────────────────────────────
export default function PuantajScreen() {
  const colors = useColors();
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const { projects, appUsers, attendance, addAttendance, updateAttendance } = useApp();

  const perm = usePermission("puantaj");
  const canEdit = perm === "edit";
  useEffect(() => { if (perm === "none") router.back(); }, [perm]);

  const [filter, setFilter] = useState<string | null>(projects[0]?.id || null);
  const [date, setDate] = useState(todayStr());
  const [viewMode, setViewMode] = useState<ViewMode>("daily");
  const [openDropdown, setOpenDropdown] = useState<string | null>(null);
  const [openNote, setOpenNote] = useState<string | null>(null);
  const [noteText, setNoteText] = useState("");

  const projectId = filter || projects[0]?.id || "";
  const weekDays  = useMemo(() => getWeekDays(date),  [date]);
  const monthDays = useMemo(() => getMonthDays(date), [date]);

  const groupedUsers = useMemo(() => {
    const map: Record<string, AppUser[]> = {};
    for (const u of appUsers) {
      const key = u.company?.trim() || "";
      if (!map[key]) map[key] = [];
      map[key].push(u);
    }
    const keys = Object.keys(map).sort((a, b) => {
      if (!a && b) return 1; if (a && !b) return -1; return a.localeCompare(b, "tr");
    });
    return keys.map(k => ({ company: k || "Diğer", users: map[k] }));
  }, [appUsers]);

  // ── attendance helpers ──
  function getAtt(userId: string, d: string): Attendance | undefined {
    return attendance.find(a => a.workerId === userId && a.date === d && a.projectId === projectId);
  }
  function attFor(userId: string) { return getAtt(userId, date); }

  function setStatus(u: AppUser, s: AttStatus, d = date) {
    if (!projectId) return;
    const existing = getAtt(u.id, d);
    if (existing) {
      updateAttendance(existing.id, { status: s, hours: hoursFor(s) });
    } else {
      addAttendance({ projectId, workerId: u.id, workerName: u.name, date: d, status: s, hours: hoursFor(s), note: "" });
    }
    setOpenDropdown(null);
  }

  function bulkSetStatus(s: AttStatus) {
    if (!projectId) return;
    for (const u of appUsers) {
      const existing = getAtt(u.id, date);
      if (existing) {
        updateAttendance(existing.id, { status: s, hours: hoursFor(s) });
      } else {
        addAttendance({ projectId, workerId: u.id, workerName: u.name, date, status: s, hours: hoursFor(s), note: "" });
      }
    }
    setOpenDropdown(null);
  }

  function copyFromYesterday() {
    if (!projectId) return;
    const yesterday = shiftDate(date, -1);
    let copied = 0;
    for (const u of appUsers) {
      const prev = getAtt(u.id, yesterday);
      if (!prev) continue;
      const existing = getAtt(u.id, date);
      if (existing) {
        updateAttendance(existing.id, { status: prev.status, hours: prev.hours, note: prev.note });
      } else {
        addAttendance({ projectId, workerId: u.id, workerName: u.name, date, status: prev.status, hours: prev.hours, note: prev.note || "" });
      }
      copied++;
    }
    if (copied === 0) Alert.alert("Bilgi", "Önceki gün için kayıt bulunamadı.");
  }

  function openNoteFor(u: AppUser) {
    const att = attFor(u.id);
    setNoteText(att?.note || "");
    setOpenNote(u.id);
    setOpenDropdown(null);
  }
  function saveNote(u: AppUser) {
    const att = attFor(u.id);
    if (att) {
      updateAttendance(att.id, { note: noteText.trim() });
    } else if (noteText.trim()) {
      addAttendance({ projectId, workerId: u.id, workerName: u.name, date, status: "absent", hours: 0, note: noteText.trim() });
    }
    setOpenNote(null);
  }

  // ── daily summary counts ──
  const dailyCounts = useMemo(() => {
    const c: Record<string, number> = {};
    for (const o of STATUS_OPTS) c[o.value] = 0;
    c["none"] = 0;
    for (const u of appUsers) {
      const att = attFor(u.id);
      if (att) c[att.status] = (c[att.status] || 0) + 1;
      else c["none"]++;
    }
    return c;
  }, [appUsers, attendance, date, projectId]);

  // ── missing entry warning ──
  const missingCount = useMemo(
    () => appUsers.filter(u => !getAtt(u.id, date)).length,
    [appUsers, attendance, date, projectId]
  );

  // ── nav labels ──
  function weekLabel() {
    const [d1, m1] = weekDays[0].split(".");
    const [d2, m2, y2] = weekDays[6].split(".");
    return `${d1}.${m1} – ${d2}.${m2}.${y2}`;
  }
  function monthLabel() {
    const d = parseDate(date);
    return `${TR_MONTHS[d.getMonth()]} ${d.getFullYear()}`;
  }

  function NavHeader({ label, onPrev, onNext }: { label: string; onPrev: () => void; onNext: () => void }) {
    return (
      <View style={[styles.navRow, { backgroundColor: colors.card }]}>
        <TouchableOpacity style={styles.navBtn} onPress={onPrev}>
          <Feather name="chevron-left" size={20} color={colors.foreground} />
        </TouchableOpacity>
        <Text style={[styles.navLabel, { color: colors.foreground }]}>{label}</Text>
        <TouchableOpacity style={styles.navBtn} onPress={onNext}>
          <Feather name="chevron-right" size={20} color={colors.foreground} />
        </TouchableOpacity>
      </View>
    );
  }

  // ── cetvel table ──
  function CetvelTable({ days, showSummary }: { days: string[]; showSummary?: boolean }) {
    const isWeekly = days.length === 7;
    const CELL = isWeekly ? 36 : 26;
    const NAME_W = 88;
    const TOTAL_W = 36;

    return (
      <ScrollView style={{ flex: 1 }} contentContainerStyle={{ paddingBottom: insets.bottom + 24 }}>
        {/* Legend */}
        <View style={styles.legendWrap}>
          {STATUS_OPTS.map(o => (
            <View key={o.value} style={styles.legendItem}>
              <View style={[styles.legendDot, { backgroundColor: o.color }]}>
                <Text style={[styles.legendShort, { fontSize: o.short.length > 1 ? 7 : 9 }]}>{o.short}</Text>
              </View>
              <Text style={[styles.legendLabel, { color: colors.mutedForeground }]}>{o.label}</Text>
            </View>
          ))}
          <View style={styles.legendItem}>
            <View style={[styles.legendDot, { backgroundColor: colors.muted }]}>
              <Text style={[styles.legendShort, { color: colors.mutedForeground }]}>–</Text>
            </View>
            <Text style={[styles.legendLabel, { color: colors.mutedForeground }]}>Girilmedi</Text>
          </View>
        </View>

        <ScrollView horizontal showsHorizontalScrollIndicator={false}>
          <View>
            {/* Header */}
            <View style={[styles.tableRow, { backgroundColor: colors.card }]}>
              <View style={[styles.nameCell, { width: NAME_W, borderRightColor: colors.border }]}>
                <Text style={[styles.headerText, { color: colors.mutedForeground }]}>Personel</Text>
              </View>
              {days.map((d, i) => {
                const isToday = d === todayStr();
                const dow = isWeekly ? i : parseDate(d).getDay();
                const isSun = dow === 0; const isSat = dow === 6;
                const label = isWeekly ? `${TR_DAYS_SHORT[i]}\n${d.split(".")[0]}` : d.split(".")[0];
                return (
                  <View key={d} style={[styles.dayHeaderCell, { width: CELL, borderRightColor: colors.border }, isToday && { backgroundColor: colors.primary + "22" }]}>
                    <Text style={[styles.dayHeaderText, { color: isToday ? colors.primary : isSun ? "#dc2626" : isSat ? "#f59e0b" : colors.mutedForeground }]} numberOfLines={2}>{label}</Text>
                  </View>
                );
              })}
              <View style={[styles.totalCell, { width: TOTAL_W }]}>
                <Text style={[styles.headerText, { color: colors.mutedForeground }]}>Top.</Text>
              </View>
            </View>

            {/* Data rows */}
            {groupedUsers.map(group => (
              <View key={group.company}>
                <View style={[styles.companyRow, { backgroundColor: colors.primary + "12" }]}>
                  <Text style={[styles.companyRowText, { color: colors.primary, width: NAME_W + days.length * CELL + TOTAL_W }]}>{group.company}</Text>
                </View>
                {group.users.map(u => {
                  let workCount = 0;
                  return (
                    <View key={u.id} style={[styles.tableRow, { borderBottomColor: colors.muted }]}>
                      <View style={[styles.nameCell, { width: NAME_W, borderRightColor: colors.border }]}>
                        <Text style={[styles.nameCellText, { color: colors.foreground }]} numberOfLines={2}>{u.name}</Text>
                      </View>
                      {days.map(d => {
                        const att = getAtt(u.id, d);
                        const opt = statusFor(att?.status);
                        if (att?.status === "present" || att?.status === "half") workCount++;
                        return (
                          <View key={d} style={[styles.dataCell, { width: CELL, borderRightColor: colors.border }]}>
                            <View style={[styles.cellBadge, { backgroundColor: opt ? opt.color : colors.muted }]}>
                              <Text style={[styles.cellText, { color: opt ? "#fff" : colors.mutedForeground, fontSize: opt?.short && opt.short.length > 1 ? 7 : 9 }]}>
                                {opt ? opt.short : "–"}
                              </Text>
                            </View>
                          </View>
                        );
                      })}
                      <View style={[styles.totalCell, { width: TOTAL_W }]}>
                        <Text style={[styles.totalNum, { color: workCount > 0 ? "#16a34a" : colors.mutedForeground }]}>{workCount > 0 ? workCount : "–"}</Text>
                      </View>
                    </View>
                  );
                })}
              </View>
            ))}

            {/* Mevcut summary row */}
            <View style={[styles.tableRow, { backgroundColor: colors.card }]}>
              <View style={[styles.nameCell, { width: NAME_W, borderRightColor: colors.border }]}>
                <Text style={[styles.headerText, { color: colors.foreground }]}>Mevcut</Text>
              </View>
              {days.map(d => {
                const count = appUsers.filter(u => { const s = getAtt(u.id, d)?.status; return s === "present" || s === "half"; }).length;
                return (
                  <View key={d} style={[styles.dataCell, { width: CELL, borderRightColor: colors.border }]}>
                    <Text style={[styles.sumCount, { color: count > 0 ? "#16a34a" : colors.mutedForeground }]}>{count > 0 ? count : "–"}</Text>
                  </View>
                );
              })}
              <View style={[styles.totalCell, { width: TOTAL_W }]} />
            </View>
          </View>
        </ScrollView>

        {/* ── Personel Özeti (only monthly) ── */}
        {showSummary && appUsers.length > 0 && (
          <View style={[styles.ozet, { backgroundColor: colors.card, borderColor: colors.border }]}>
            <Text style={[styles.ozetTitle, { color: colors.foreground }]}>Personel Özeti — {monthLabel()}</Text>
            <View style={[styles.ozetHeaderRow, { borderBottomColor: colors.border }]}>
              <Text style={[styles.ozetHCell, { flex: 2, color: colors.mutedForeground }]}>Ad</Text>
              <Text style={[styles.ozetHCell, { color: colors.mutedForeground }]}>Gün</Text>
              <Text style={[styles.ozetHCell, { color: colors.mutedForeground }]}>Saat</Text>
              <Text style={[styles.ozetHCell, { color: colors.mutedForeground }]}>Devam</Text>
            </View>
            {appUsers.map(u => {
              let workDays = 0, totalHours = 0;
              const workingDays = days.filter(d => { const dow = parseDate(d).getDay(); return dow !== 0; });
              for (const d of days) {
                const att = getAtt(u.id, d);
                if (att?.status === "present" || att?.status === "half") workDays++;
                totalHours += att ? hoursFor(att.status) : 0;
              }
              const pct = workingDays.length > 0 ? Math.round((workDays / workingDays.length) * 100) : 0;
              const pctColor = pct >= 80 ? "#16a34a" : pct >= 50 ? "#d97706" : "#dc2626";
              return (
                <View key={u.id} style={[styles.ozetRow, { borderBottomColor: colors.border }]}>
                  <Text style={[styles.ozetCell, { flex: 2, color: colors.foreground, fontFamily: "Inter_600SemiBold" }]} numberOfLines={1}>{u.name}</Text>
                  <Text style={[styles.ozetCell, { color: colors.foreground }]}>{workDays}</Text>
                  <Text style={[styles.ozetCell, { color: colors.foreground }]}>{totalHours}s</Text>
                  <Text style={[styles.ozetCell, { color: pctColor, fontFamily: "Inter_700Bold" }]}>%{pct}</Text>
                </View>
              );
            })}
          </View>
        )}
      </ScrollView>
    );
  }

  // ─── render ───────────────────────────────────────────────────────────────
  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <Header title="Puantaj" onBack={() => router.back()} />
      <ProjectPicker projects={projects} value={filter} onChange={setFilter} includeAll={false} />

      {projects.length === 0 ? (
        <EmptyState icon="briefcase" title="Önce proje ekleyin" description="Puantaj tutmak için en az bir projeniz olmalı" actionLabel="Projelere Git" onAction={() => router.push("/proje" as any)} />
      ) : (
        <>
          {/* View mode tabs */}
          <View style={[styles.modeTabs, { backgroundColor: colors.card }]}>
            {(["daily", "weekly", "monthly"] as ViewMode[]).map(m => {
              const labels = { daily: "Günlük", weekly: "Haftalık", monthly: "Aylık" };
              return (
                <TouchableOpacity key={m} style={[styles.modeTab, viewMode === m && { backgroundColor: colors.primary }]} onPress={() => setViewMode(m)}>
                  <Text style={[styles.modeTabText, { color: viewMode === m ? "#fff" : colors.mutedForeground }]}>{labels[m]}</Text>
                </TouchableOpacity>
              );
            })}
          </View>

          {/* ── GÜNLÜK ── */}
          {viewMode === "daily" && (
            <>
              {/* Date bar + copy yesterday */}
              <View style={styles.dateBar}>
                <View style={{ flex: 1 }}>
                  <DatePickerInput value={date} onChange={setDate} />
                </View>
                {canEdit && (
                  <TouchableOpacity style={[styles.copyBtn, { backgroundColor: colors.card, borderColor: colors.border }]} onPress={copyFromYesterday} activeOpacity={0.8}>
                    <Feather name="copy" size={13} color={colors.mutedForeground} />
                    <Text style={[styles.copyBtnText, { color: colors.mutedForeground }]}>Dünden Kopyala</Text>
                  </TouchableOpacity>
                )}
              </View>

              {/* Missing entry warning */}
              {missingCount > 0 && appUsers.length > 0 && (
                <View style={[styles.warningBar, { backgroundColor: "#f59e0b18", borderColor: "#f59e0b50" }]}>
                  <Feather name="alert-triangle" size={13} color="#f59e0b" />
                  <Text style={[styles.warningText, { color: "#f59e0b" }]}>{missingCount} personelin puantajı girilmedi</Text>
                </View>
              )}

              {/* Summary chips */}
              <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.summaryScroll} contentContainerStyle={styles.summaryRow}>
                {STATUS_OPTS.map(opt => (
                  <View key={opt.value} style={[styles.sumChip, { backgroundColor: opt.color + "18", borderColor: opt.color + "50" }]}>
                    <Text style={[styles.sumChipNum, { color: opt.color }]}>{dailyCounts[opt.value] || 0}</Text>
                    <Text style={[styles.sumChipLabel, { color: opt.color }]}>{opt.short}</Text>
                  </View>
                ))}
                <View style={[styles.sumChip, { backgroundColor: colors.muted, borderColor: colors.border }]}>
                  <Text style={[styles.sumChipNum, { color: colors.foreground }]}>{appUsers.length}</Text>
                  <Text style={[styles.sumChipLabel, { color: colors.mutedForeground }]}>Top</Text>
                </View>
              </ScrollView>

              {/* Bulk entry buttons */}
              {canEdit && appUsers.length > 0 && (
                <View style={styles.bulkRow}>
                  <TouchableOpacity style={[styles.bulkBtn, { backgroundColor: "#16a34a18", borderColor: "#16a34a50" }]} onPress={() => bulkSetStatus("present")} activeOpacity={0.8}>
                    <Feather name="check-circle" size={13} color="#16a34a" />
                    <Text style={[styles.bulkBtnText, { color: "#16a34a" }]}>Tümünü Mevcut</Text>
                  </TouchableOpacity>
                  <TouchableOpacity style={[styles.bulkBtn, { backgroundColor: "#dc262618", borderColor: "#dc262650" }]} onPress={() => bulkSetStatus("absent")} activeOpacity={0.8}>
                    <Feather name="x-circle" size={13} color="#dc2626" />
                    <Text style={[styles.bulkBtnText, { color: "#dc2626" }]}>Tümünü Yok</Text>
                  </TouchableOpacity>
                </View>
              )}

              {appUsers.length === 0 ? (
                <EmptyState icon="users" title="Kayıtlı personel yok" description="Kullanıcı yönetiminden personel ekleyin" actionLabel="Kullanıcılara Git" onAction={() => router.push("/kullanicilar" as any)} />
              ) : (
                <ScrollView contentContainerStyle={[styles.list, { paddingBottom: insets.bottom + 24 }]}>
                  {groupedUsers.map(group => (
                    <View key={group.company}>
                      <View style={[styles.groupHeader, { borderLeftColor: colors.primary }]}>
                        <Feather name="briefcase" size={13} color={colors.primary} />
                        <Text style={[styles.groupTitle, { color: colors.foreground }]}>{group.company}</Text>
                        <View style={[styles.groupCount, { backgroundColor: colors.muted }]}>
                          <Text style={[styles.groupCountText, { color: colors.mutedForeground }]}>{group.users.length} kişi</Text>
                        </View>
                      </View>
                      <View style={styles.groupCards}>
                        {group.users.map(u => {
                          const att = attFor(u.id);
                          const opted = statusFor(att?.status);
                          const isOpen = openDropdown === u.id;
                          const isNoteOpen = openNote === u.id;
                          return (
                            <View key={u.id} style={[styles.card, { backgroundColor: colors.card }]}>
                              {/* Card top row */}
                              <View style={styles.cardTop}>
                                <View style={styles.cardLeft}>
                                  <Text style={[styles.wname, { color: colors.foreground }]}>{u.name}</Text>
                                  {(u.profession || u.phone) ? (
                                    <Text style={[styles.wmeta, { color: colors.mutedForeground }]}>{[u.profession, u.phone].filter(Boolean).join(" · ")}</Text>
                                  ) : null}
                                </View>
                                <View style={styles.cardActions}>
                                  {canEdit && (
                                    <TouchableOpacity
                                      onPress={() => isNoteOpen ? setOpenNote(null) : openNoteFor(u)}
                                      style={[styles.noteIconBtn, { backgroundColor: att?.note ? colors.primary + "25" : colors.muted }]}
                                      activeOpacity={0.8}
                                    >
                                      <Feather name="edit-3" size={13} color={att?.note ? colors.primary : colors.mutedForeground} />
                                    </TouchableOpacity>
                                  )}
                                  <TouchableOpacity
                                    onPress={canEdit ? () => { setOpenDropdown(isOpen ? null : u.id); setOpenNote(null); } : undefined}
                                    activeOpacity={canEdit ? 0.8 : 1}
                                    style={[styles.statusBtn, { backgroundColor: opted ? opted.color + "20" : colors.muted, borderColor: opted ? opted.color : colors.muted }]}
                                  >
                                    <View style={[styles.statusDot, { backgroundColor: opted ? opted.color : colors.mutedForeground }]} />
                                    <Text style={[styles.statusBtnText, { color: opted ? opted.color : colors.mutedForeground }]}>{opted ? opted.label : "Seçilmedi"}</Text>
                                    {canEdit && <Feather name={isOpen ? "chevron-up" : "chevron-down"} size={13} color={opted ? opted.color : colors.mutedForeground} />}
                                  </TouchableOpacity>
                                </View>
                              </View>

                              {/* Note display */}
                              {att?.note && !isNoteOpen && (
                                <View style={[styles.noteDisplay, { backgroundColor: colors.muted }]}>
                                  <Feather name="message-square" size={11} color={colors.mutedForeground} />
                                  <Text style={[styles.noteDisplayText, { color: colors.mutedForeground }]}>{att.note}</Text>
                                </View>
                              )}

                              {/* Note editor */}
                              {isNoteOpen && canEdit && (
                                <View style={[styles.noteEditor, { borderTopColor: colors.border }]}>
                                  <TextInput
                                    style={[styles.noteInput, { color: colors.foreground, backgroundColor: colors.muted, borderColor: colors.border }]}
                                    value={noteText}
                                    onChangeText={setNoteText}
                                    placeholder="Not ekle..."
                                    placeholderTextColor={colors.mutedForeground}
                                    multiline
                                    autoFocus
                                  />
                                  <TouchableOpacity style={[styles.noteSaveBtn, { backgroundColor: colors.primary }]} onPress={() => saveNote(u)}>
                                    <Text style={styles.noteSaveBtnText}>Kaydet</Text>
                                  </TouchableOpacity>
                                </View>
                              )}

                              {/* Status dropdown */}
                              {isOpen && canEdit && (
                                <View style={[styles.dropdown, { backgroundColor: colors.card, borderColor: colors.muted }]}>
                                  {STATUS_OPTS.map(opt => (
                                    <TouchableOpacity key={opt.value} style={[styles.dropdownItem, att?.status === opt.value && { backgroundColor: opt.color + "15" }]} onPress={() => setStatus(u, opt.value)} activeOpacity={0.8}>
                                      <View style={[styles.dropdownDot, { backgroundColor: opt.color }]} />
                                      <Text style={[styles.dropdownText, { color: opt.color }]}>{opt.label}</Text>
                                      {att?.status === opt.value && <Feather name="check" size={13} color={opt.color} />}
                                    </TouchableOpacity>
                                  ))}
                                </View>
                              )}
                            </View>
                          );
                        })}
                      </View>
                    </View>
                  ))}
                </ScrollView>
              )}
            </>
          )}

          {/* ── HAFTALIK ── */}
          {viewMode === "weekly" && (
            <>
              <NavHeader label={weekLabel()} onPrev={() => setDate(shiftDate(date, -7))} onNext={() => setDate(shiftDate(date, 7))} />
              {appUsers.length === 0 ? (
                <EmptyState icon="users" title="Kayıtlı personel yok" description="Kullanıcı yönetiminden personel ekleyin" />
              ) : (
                <CetvelTable days={weekDays} />
              )}
            </>
          )}

          {/* ── AYLIK ── */}
          {viewMode === "monthly" && (
            <>
              <NavHeader
                label={monthLabel()}
                onPrev={() => { const d = parseDate(date); d.setMonth(d.getMonth() - 1); setDate(formatDate(d)); }}
                onNext={() => { const d = parseDate(date); d.setMonth(d.getMonth() + 1); setDate(formatDate(d)); }}
              />
              {appUsers.length === 0 ? (
                <EmptyState icon="users" title="Kayıtlı personel yok" description="Kullanıcı yönetiminden personel ekleyin" />
              ) : (
                <CetvelTable days={monthDays} showSummary />
              )}
            </>
          )}
        </>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  modeTabs: { flexDirection: "row", marginHorizontal: 16, marginTop: 12, borderRadius: 10, padding: 4, gap: 4 },
  modeTab: { flex: 1, paddingVertical: 8, borderRadius: 8, alignItems: "center" },
  modeTabText: { fontSize: 13, fontFamily: "Inter_600SemiBold" },

  dateBar: { flexDirection: "row", alignItems: "center", paddingHorizontal: 16, marginTop: 12, gap: 8 },
  copyBtn: { flexDirection: "row", alignItems: "center", gap: 5, paddingHorizontal: 10, paddingVertical: 9, borderRadius: 9, borderWidth: 1 },
  copyBtnText: { fontSize: 12, fontFamily: "Inter_500Medium" },

  warningBar: { flexDirection: "row", alignItems: "center", gap: 7, marginHorizontal: 16, marginTop: 8, paddingHorizontal: 12, paddingVertical: 8, borderRadius: 9, borderWidth: 1 },
  warningText: { fontSize: 12, fontFamily: "Inter_500Medium" },

  summaryScroll: { marginTop: 10 },
  summaryRow: { paddingHorizontal: 16, gap: 6, paddingRight: 16 },
  sumChip: { alignItems: "center", paddingHorizontal: 10, paddingVertical: 8, borderRadius: 10, borderWidth: 1, minWidth: 46 },
  sumChipNum: { fontSize: 17, fontFamily: "Inter_700Bold" },
  sumChipLabel: { fontSize: 10, fontFamily: "Inter_600SemiBold", marginTop: 1 },

  bulkRow: { flexDirection: "row", gap: 8, paddingHorizontal: 16, marginTop: 10 },
  bulkBtn: { flex: 1, flexDirection: "row", alignItems: "center", justifyContent: "center", gap: 6, paddingVertical: 9, borderRadius: 9, borderWidth: 1 },
  bulkBtnText: { fontSize: 13, fontFamily: "Inter_600SemiBold" },

  list: { padding: 16, gap: 4 },
  groupHeader: { flexDirection: "row", alignItems: "center", gap: 7, marginTop: 16, marginBottom: 8, paddingLeft: 10, borderLeftWidth: 3 },
  groupTitle: { fontSize: 14, fontFamily: "Inter_700Bold", flex: 1 },
  groupCount: { paddingHorizontal: 8, paddingVertical: 2, borderRadius: 999 },
  groupCountText: { fontSize: 11, fontFamily: "Inter_500Medium" },
  groupCards: { gap: 6 },

  card: { borderRadius: 12, padding: 12, elevation: 2, shadowColor: "#000", shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.05, shadowRadius: 4 },
  cardTop: { flexDirection: "row", alignItems: "flex-start", gap: 8 },
  cardLeft: { flex: 1 },
  wname: { fontSize: 15, fontFamily: "Inter_600SemiBold" },
  wmeta: { fontSize: 12, fontFamily: "Inter_400Regular", marginTop: 2 },
  cardActions: { flexDirection: "row", alignItems: "center", gap: 6 },
  noteIconBtn: { width: 30, height: 30, borderRadius: 8, alignItems: "center", justifyContent: "center" },

  statusBtn: { flexDirection: "row", alignItems: "center", gap: 5, paddingHorizontal: 10, paddingVertical: 7, borderRadius: 8, borderWidth: 1 },
  statusDot: { width: 7, height: 7, borderRadius: 4 },
  statusBtnText: { fontSize: 12, fontFamily: "Inter_600SemiBold" },

  noteDisplay: { flexDirection: "row", alignItems: "center", gap: 6, marginTop: 8, paddingHorizontal: 8, paddingVertical: 5, borderRadius: 7 },
  noteDisplayText: { fontSize: 12, fontFamily: "Inter_400Regular", flex: 1 },

  noteEditor: { marginTop: 8, borderTopWidth: StyleSheet.hairlineWidth, paddingTop: 8 },
  noteInput: { borderRadius: 9, paddingHorizontal: 10, paddingVertical: 8, fontSize: 13, fontFamily: "Inter_400Regular", borderWidth: 1, minHeight: 56, marginBottom: 6 },
  noteSaveBtn: { alignSelf: "flex-end", paddingHorizontal: 14, paddingVertical: 7, borderRadius: 8 },
  noteSaveBtnText: { color: "#fff", fontSize: 13, fontFamily: "Inter_600SemiBold" },

  dropdown: { marginTop: 8, borderRadius: 10, borderWidth: 1, overflow: "hidden" },
  dropdownItem: { flexDirection: "row", alignItems: "center", gap: 10, paddingVertical: 10, paddingHorizontal: 14 },
  dropdownDot: { width: 8, height: 8, borderRadius: 4 },
  dropdownText: { fontSize: 14, fontFamily: "Inter_600SemiBold", flex: 1 },

  // Cetvel
  navRow: { flexDirection: "row", alignItems: "center", marginHorizontal: 16, marginTop: 12, borderRadius: 10, paddingVertical: 6 },
  navBtn: { paddingHorizontal: 14, paddingVertical: 8 },
  navLabel: { flex: 1, textAlign: "center", fontSize: 14, fontFamily: "Inter_600SemiBold" },

  legendWrap: { flexDirection: "row", flexWrap: "wrap", gap: 8, paddingHorizontal: 16, paddingVertical: 10 },
  legendItem: { flexDirection: "row", alignItems: "center", gap: 4 },
  legendDot: { width: 20, height: 20, borderRadius: 5, alignItems: "center", justifyContent: "center" },
  legendShort: { color: "#fff", fontFamily: "Inter_700Bold", fontSize: 9 },
  legendLabel: { fontSize: 11, fontFamily: "Inter_400Regular" },

  tableRow: { flexDirection: "row", borderBottomWidth: StyleSheet.hairlineWidth },
  nameCell: { paddingHorizontal: 8, paddingVertical: 8, justifyContent: "center", borderRightWidth: StyleSheet.hairlineWidth },
  headerText: { fontSize: 10, fontFamily: "Inter_600SemiBold" },
  nameCellText: { fontSize: 10, fontFamily: "Inter_500Medium" },
  dayHeaderCell: { alignItems: "center", justifyContent: "center", paddingVertical: 6, borderRightWidth: StyleSheet.hairlineWidth },
  dayHeaderText: { fontSize: 9, fontFamily: "Inter_600SemiBold", textAlign: "center" },
  totalCell: { alignItems: "center", justifyContent: "center", paddingHorizontal: 4 },
  totalNum: { fontSize: 11, fontFamily: "Inter_700Bold" },
  dataCell: { alignItems: "center", justifyContent: "center", paddingVertical: 6, borderRightWidth: StyleSheet.hairlineWidth },
  cellBadge: { width: 18, height: 18, borderRadius: 4, alignItems: "center", justifyContent: "center" },
  cellText: { fontFamily: "Inter_700Bold" },
  sumCount: { fontSize: 11, fontFamily: "Inter_700Bold" },
  companyRow: { paddingHorizontal: 8, paddingVertical: 4 },
  companyRowText: { fontSize: 10, fontFamily: "Inter_700Bold" },

  // Personel Özeti
  ozet: { margin: 16, borderRadius: 14, borderWidth: 1, overflow: "hidden" },
  ozetTitle: { fontSize: 14, fontFamily: "Inter_700Bold", paddingHorizontal: 14, paddingVertical: 12 },
  ozetHeaderRow: { flexDirection: "row", paddingHorizontal: 14, paddingVertical: 8, borderBottomWidth: StyleSheet.hairlineWidth },
  ozetHCell: { flex: 1, fontSize: 11, fontFamily: "Inter_600SemiBold", textAlign: "center" },
  ozetRow: { flexDirection: "row", paddingHorizontal: 14, paddingVertical: 10, borderBottomWidth: StyleSheet.hairlineWidth, alignItems: "center" },
  ozetCell: { flex: 1, fontSize: 12, fontFamily: "Inter_400Regular", textAlign: "center" },
});
