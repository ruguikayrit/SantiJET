import { Feather } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import React, { useEffect, useMemo, useRef, useState } from "react";
import {
  ScrollView,
  StyleSheet,
  Text,
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

// ─── date helpers ────────────────────────────────────────────────────────────
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
    const x = new Date(mon);
    x.setDate(mon.getDate() + i);
    return formatDate(x);
  });
}
function getMonthDays(dateStr: string): string[] {
  const d = parseDate(dateStr);
  const n = new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate();
  return Array.from({ length: n }, (_, i) => formatDate(new Date(d.getFullYear(), d.getMonth(), i + 1)));
}
function shiftDate(dateStr: string, days: number): string {
  const d = parseDate(dateStr);
  d.setDate(d.getDate() + days);
  return formatDate(d);
}

const TR_DAYS_SHORT = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"];
const TR_MONTHS = ["Ocak","Şubat","Mart","Nisan","Mayıs","Haziran","Temmuz","Ağustos","Eylül","Ekim","Kasım","Aralık"];

// ─── attendance types ─────────────────────────────────────────────────────────
type AttStatus = Attendance["status"];
type ViewMode = "daily" | "weekly" | "monthly";

const STATUS_OPTS: { value: AttStatus; label: string; color: string; short: string }[] = [
  { value: "present", label: "Mevcut", color: "#16a34a", short: "M" },
  { value: "half",    label: "Yarım",  color: "#d97706", short: "Y" },
  { value: "absent",  label: "Yok",    color: "#dc2626", short: "X" },
];
function statusFor(s: AttStatus | undefined) { return STATUS_OPTS.find(o => o.value === s); }
function hoursFor(s: AttStatus) { return s === "present" ? 8 : s === "half" ? 4 : 0; }

// ─── component ───────────────────────────────────────────────────────────────
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

  const projectId = filter || projects[0]?.id || "";

  // date ranges
  const weekDays  = useMemo(() => getWeekDays(date),  [date]);
  const monthDays = useMemo(() => getMonthDays(date), [date]);

  // grouped users
  const groupedUsers = useMemo(() => {
    const map: Record<string, AppUser[]> = {};
    for (const u of appUsers) {
      const key = u.company?.trim() || "";
      if (!map[key]) map[key] = [];
      map[key].push(u);
    }
    const keys = Object.keys(map).sort((a, b) => {
      if (!a && b) return 1;
      if (a && !b) return -1;
      return a.localeCompare(b, "tr");
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

  // ── daily summary ──
  const dailyTotals = useMemo(() => {
    let p = 0, h = 0, a = 0;
    for (const u of appUsers) {
      const att = attFor(u.id);
      if (att?.status === "present") p++;
      else if (att?.status === "half") h++;
      else if (att?.status === "absent") a++;
    }
    return { p, h, a };
  }, [appUsers, attendance, date, projectId]);

  // ── header labels ──
  function weekLabel() {
    const days = weekDays;
    const [d1, m1] = days[0].split(".");
    const [d2, m2, y2] = days[6].split(".");
    return `${d1}.${m1} – ${d2}.${m2}.${y2}`;
  }
  function monthLabel() {
    const d = parseDate(date);
    return `${TR_MONTHS[d.getMonth()]} ${d.getFullYear()}`;
  }

  // ── cetvel table ──
  function CetvelTable({ days }: { days: string[] }) {
    const isWeekly = days.length === 7;
    const CELL = isWeekly ? 36 : 28;
    const NAME_W = 88;
    const TOTAL_W = 36;

    return (
      <ScrollView style={{ flex: 1 }} contentContainerStyle={{ paddingBottom: insets.bottom + 24 }}>
        {/* Legend */}
        <View style={styles.legend}>
          {STATUS_OPTS.map(o => (
            <View key={o.value} style={styles.legendItem}>
              <View style={[styles.legendDot, { backgroundColor: o.color }]}>
                <Text style={styles.legendShort}>{o.short}</Text>
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
            {/* Header row */}
            <View style={[styles.tableRow, { backgroundColor: colors.card }]}>
              <View style={[styles.nameCell, { width: NAME_W, borderRightColor: colors.border }]}>
                <Text style={[styles.headerText, { color: colors.mutedForeground }]}>Personel</Text>
              </View>
              {days.map((d, i) => {
                const isToday = d === todayStr();
                const dayOfWeek = isWeekly ? i : parseDate(d).getDay();
                const isSunday = dayOfWeek === 0;
                const label = isWeekly
                  ? `${TR_DAYS_SHORT[i]}\n${d.split(".")[0]}`
                  : d.split(".")[0];
                return (
                  <View key={d} style={[
                    styles.dayHeaderCell,
                    { width: CELL, borderRightColor: colors.border },
                    isToday && { backgroundColor: colors.primary + "22" },
                  ]}>
                    <Text style={[
                      styles.dayHeaderText,
                      { color: isToday ? colors.primary : isSunday ? "#dc2626" : colors.mutedForeground },
                    ]} numberOfLines={2}>{label}</Text>
                  </View>
                );
              })}
              <View style={[styles.totalCell, { width: TOTAL_W, borderRightColor: colors.border }]}>
                <Text style={[styles.headerText, { color: colors.mutedForeground }]}>Top.</Text>
              </View>
            </View>

            {/* Data rows - per company group */}
            {groupedUsers.map((group) => (
              <View key={group.company}>
                {/* Company header row */}
                <View style={[styles.companyRow, { backgroundColor: colors.primary + "12" }]}>
                  <Text style={[styles.companyRowText, { color: colors.primary, width: NAME_W + days.length * CELL + TOTAL_W }]}>
                    {group.company}
                  </Text>
                </View>
                {group.users.map((u) => {
                  let presentCount = 0;
                  return (
                    <View key={u.id} style={[styles.tableRow, { borderBottomColor: colors.muted }]}>
                      <View style={[styles.nameCell, { width: NAME_W, borderRightColor: colors.border }]}>
                        <Text style={[styles.nameCellText, { color: colors.foreground }]} numberOfLines={2}>{u.name}</Text>
                      </View>
                      {days.map(d => {
                        const att = getAtt(u.id, d);
                        const opt = statusFor(att?.status);
                        if (att?.status === "present" || att?.status === "half") presentCount++;
                        return (
                          <View key={d} style={[styles.dataCell, { width: CELL, borderRightColor: colors.border }]}>
                            <View style={[styles.cellBadge, {
                              backgroundColor: opt ? opt.color : colors.muted,
                            }]}>
                              <Text style={[styles.cellText, {
                                color: opt ? "#fff" : colors.mutedForeground,
                              }]}>{opt ? opt.short : "–"}</Text>
                            </View>
                          </View>
                        );
                      })}
                      <View style={[styles.totalCell, { width: TOTAL_W }]}>
                        <Text style={[styles.totalNum, { color: presentCount > 0 ? "#16a34a" : colors.mutedForeground }]}>
                          {presentCount > 0 ? presentCount : "–"}
                        </Text>
                      </View>
                    </View>
                  );
                })}
              </View>
            ))}

            {/* Summary row */}
            <View style={[styles.tableRow, { backgroundColor: colors.card }]}>
              <View style={[styles.nameCell, { width: NAME_W, borderRightColor: colors.border }]}>
                <Text style={[styles.headerText, { color: colors.foreground }]}>Mevcut</Text>
              </View>
              {days.map(d => {
                const count = appUsers.filter(u => {
                  const s = getAtt(u.id, d)?.status;
                  return s === "present" || s === "half";
                }).length;
                return (
                  <View key={d} style={[styles.dataCell, { width: CELL, borderRightColor: colors.border }]}>
                    <Text style={[styles.sumCount, { color: count > 0 ? "#16a34a" : colors.mutedForeground }]}>
                      {count > 0 ? count : "–"}
                    </Text>
                  </View>
                );
              })}
              <View style={[styles.totalCell, { width: TOTAL_W }]} />
            </View>
          </View>
        </ScrollView>
      </ScrollView>
    );
  }

  // ─── navigation for week/month ────────────────────────────────────────────
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

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <Header title="Puantaj" onBack={() => router.back()} />

      <ProjectPicker projects={projects} value={filter} onChange={setFilter} includeAll={false} />

      {projects.length === 0 ? (
        <EmptyState
          icon="briefcase"
          title="Önce proje ekleyin"
          description="Puantaj tutmak için en az bir projeniz olmalı"
          actionLabel="Projelere Git"
          onAction={() => router.push("/proje" as any)}
        />
      ) : (
        <>
          {/* View mode toggle */}
          <View style={[styles.modeTabs, { backgroundColor: colors.card }]}>
            {(["daily", "weekly", "monthly"] as ViewMode[]).map((m) => {
              const labels = { daily: "Günlük", weekly: "Haftalık", monthly: "Aylık" };
              return (
                <TouchableOpacity
                  key={m}
                  style={[styles.modeTab, viewMode === m && { backgroundColor: colors.primary }]}
                  onPress={() => setViewMode(m)}
                >
                  <Text style={[styles.modeTabText, { color: viewMode === m ? "#fff" : colors.mutedForeground }]}>
                    {labels[m]}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </View>

          {/* ── GÜNLÜK ── */}
          {viewMode === "daily" && (
            <>
              <View style={styles.dateBar}>
                <DatePickerInput value={date} onChange={setDate} />
              </View>
              <View style={styles.summary}>
                {STATUS_OPTS.map(opt => (
                  <View key={opt.value} style={[styles.sumBox, { backgroundColor: opt.color + "22" }]}>
                    <Text style={[styles.sumNum, { color: opt.color }]}>
                      {opt.value === "present" ? dailyTotals.p : opt.value === "half" ? dailyTotals.h : dailyTotals.a}
                    </Text>
                    <Text style={[styles.sumLabel, { color: colors.foreground }]}>{opt.label}</Text>
                  </View>
                ))}
                <View style={[styles.sumBox, { backgroundColor: colors.muted }]}>
                  <Text style={[styles.sumNum, { color: colors.foreground }]}>{appUsers.length}</Text>
                  <Text style={[styles.sumLabel, { color: colors.foreground }]}>Toplam</Text>
                </View>
              </View>

              {appUsers.length === 0 ? (
                <EmptyState
                  icon="users"
                  title="Kayıtlı personel yok"
                  description="Kullanıcı yönetiminden personel ekleyin"
                  actionLabel="Kullanıcılara Git"
                  onAction={() => router.push("/kullanicilar" as any)}
                />
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
                          return (
                            <View key={u.id} style={[styles.card, { backgroundColor: colors.card }]}>
                              <View style={styles.cardLeft}>
                                <Text style={[styles.wname, { color: colors.foreground }]}>{u.name}</Text>
                                {(u.profession || u.phone) ? (
                                  <Text style={[styles.wmeta, { color: colors.mutedForeground }]}>
                                    {[u.profession, u.phone].filter(Boolean).join(" · ")}
                                  </Text>
                                ) : null}
                              </View>
                              <TouchableOpacity
                                onPress={canEdit ? () => setOpenDropdown(isOpen ? null : u.id) : undefined}
                                activeOpacity={canEdit ? 0.8 : 1}
                                style={[styles.statusBtn, {
                                  backgroundColor: opted ? opted.color + "20" : colors.muted,
                                  borderColor: opted ? opted.color : colors.muted,
                                }]}
                              >
                                <View style={[styles.statusDot, { backgroundColor: opted ? opted.color : colors.mutedForeground }]} />
                                <Text style={[styles.statusBtnText, { color: opted ? opted.color : colors.mutedForeground }]}>
                                  {opted ? opted.label : "Seçilmedi"}
                                </Text>
                                {canEdit ? (
                                  <Feather name={isOpen ? "chevron-up" : "chevron-down"} size={13} color={opted ? opted.color : colors.mutedForeground} />
                                ) : null}
                              </TouchableOpacity>
                              {isOpen && canEdit ? (
                                <View style={[styles.dropdown, { backgroundColor: colors.card, borderColor: colors.muted }]}>
                                  {STATUS_OPTS.map(opt => (
                                    <TouchableOpacity
                                      key={opt.value}
                                      style={[styles.dropdownItem, att?.status === opt.value && { backgroundColor: opt.color + "15" }]}
                                      onPress={() => setStatus(u, opt.value)}
                                      activeOpacity={0.8}
                                    >
                                      <View style={[styles.dropdownDot, { backgroundColor: opt.color }]} />
                                      <Text style={[styles.dropdownText, { color: opt.color }]}>{opt.label}</Text>
                                      {att?.status === opt.value ? <Feather name="check" size={13} color={opt.color} /> : null}
                                    </TouchableOpacity>
                                  ))}
                                </View>
                              ) : null}
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
              <NavHeader
                label={weekLabel()}
                onPrev={() => setDate(shiftDate(date, -7))}
                onNext={() => setDate(shiftDate(date, 7))}
              />
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
                <CetvelTable days={monthDays} />
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
  modeTabs: {
    flexDirection: "row",
    marginHorizontal: 16,
    marginTop: 12,
    borderRadius: 10,
    padding: 4,
    gap: 4,
  },
  modeTab: {
    flex: 1,
    paddingVertical: 8,
    borderRadius: 8,
    alignItems: "center",
  },
  modeTabText: { fontSize: 13, fontFamily: "Inter_600SemiBold" },

  dateBar: { paddingHorizontal: 16, marginTop: 12 },
  summary: { flexDirection: "row", gap: 6, paddingHorizontal: 16, marginTop: 12 },
  sumBox: { flex: 1, padding: 10, borderRadius: 10, alignItems: "center" },
  sumNum: { fontSize: 20, fontFamily: "Inter_700Bold" },
  sumLabel: { fontSize: 11, fontFamily: "Inter_500Medium", marginTop: 2 },

  list: { padding: 16 },
  groupHeader: { flexDirection: "row", alignItems: "center", gap: 7, marginTop: 16, marginBottom: 8, paddingLeft: 10, borderLeftWidth: 3 },
  groupTitle: { fontSize: 14, fontFamily: "Inter_700Bold", flex: 1 },
  groupCount: { paddingHorizontal: 8, paddingVertical: 2, borderRadius: 999 },
  groupCountText: { fontSize: 11, fontFamily: "Inter_500Medium" },
  groupCards: { gap: 6 },
  card: { borderRadius: 12, padding: 12, shadowColor: "#000", shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.05, shadowRadius: 4, elevation: 2 },
  cardLeft: { flex: 1, marginBottom: 8 },
  wname: { fontSize: 15, fontFamily: "Inter_600SemiBold" },
  wmeta: { fontSize: 12, fontFamily: "Inter_400Regular", marginTop: 2 },
  statusBtn: { flexDirection: "row", alignItems: "center", gap: 6, paddingHorizontal: 12, paddingVertical: 8, borderRadius: 8, borderWidth: 1, alignSelf: "flex-start" },
  statusDot: { width: 7, height: 7, borderRadius: 4 },
  statusBtnText: { fontSize: 13, fontFamily: "Inter_600SemiBold" },
  dropdown: { marginTop: 6, borderRadius: 10, borderWidth: 1, overflow: "hidden" },
  dropdownItem: { flexDirection: "row", alignItems: "center", gap: 10, paddingVertical: 11, paddingHorizontal: 14 },
  dropdownDot: { width: 8, height: 8, borderRadius: 4 },
  dropdownText: { fontSize: 14, fontFamily: "Inter_600SemiBold", flex: 1 },

  // Cetvel
  navRow: { flexDirection: "row", alignItems: "center", marginHorizontal: 16, marginTop: 12, borderRadius: 10, paddingVertical: 6 },
  navBtn: { paddingHorizontal: 14, paddingVertical: 8 },
  navLabel: { flex: 1, textAlign: "center", fontSize: 14, fontFamily: "Inter_600SemiBold" },

  legend: { flexDirection: "row", gap: 12, paddingHorizontal: 16, paddingVertical: 10, flexWrap: "wrap" },
  legendItem: { flexDirection: "row", alignItems: "center", gap: 5 },
  legendDot: { width: 20, height: 20, borderRadius: 4, alignItems: "center", justifyContent: "center" },
  legendShort: { fontSize: 10, fontFamily: "Inter_700Bold", color: "#fff" },
  legendLabel: { fontSize: 12, fontFamily: "Inter_400Regular" },

  tableRow: { flexDirection: "row", alignItems: "center", borderBottomWidth: StyleSheet.hairlineWidth },
  nameCell: { paddingHorizontal: 8, paddingVertical: 10, borderRightWidth: StyleSheet.hairlineWidth, justifyContent: "center" },
  nameCellText: { fontSize: 11, fontFamily: "Inter_500Medium" },
  headerText: { fontSize: 10, fontFamily: "Inter_600SemiBold", textAlign: "center" },
  dayHeaderCell: { alignItems: "center", justifyContent: "center", paddingVertical: 8, borderRightWidth: StyleSheet.hairlineWidth },
  dayHeaderText: { fontSize: 9, fontFamily: "Inter_600SemiBold", textAlign: "center" },
  dataCell: { alignItems: "center", justifyContent: "center", paddingVertical: 7, borderRightWidth: StyleSheet.hairlineWidth },
  cellBadge: { width: 20, height: 20, borderRadius: 4, alignItems: "center", justifyContent: "center" },
  cellText: { fontSize: 10, fontFamily: "Inter_700Bold" },
  totalCell: { alignItems: "center", justifyContent: "center", paddingVertical: 7 },
  totalNum: { fontSize: 12, fontFamily: "Inter_700Bold" },
  sumCount: { fontSize: 12, fontFamily: "Inter_700Bold" },
  companyRow: { paddingHorizontal: 8, paddingVertical: 5 },
  companyRowText: { fontSize: 11, fontFamily: "Inter_700Bold" },
});
