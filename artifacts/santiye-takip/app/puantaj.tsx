import { Feather } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import React, { useEffect, useMemo, useState } from "react";
import {
  Modal,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";

import DatePickerInput from "@/components/DatePickerInput";
import EmptyState from "@/components/EmptyState";
import Header from "@/components/Header";
import ProjectPicker from "@/components/ProjectPicker";
import { AppUser, Attendance, useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";
import { usePermission } from "@/hooks/usePermission";

function todayStr() {
  const d = new Date();
  return `${String(d.getDate()).padStart(2, "0")}.${String(d.getMonth() + 1).padStart(2, "0")}.${d.getFullYear()}`;
}

type AttStatus = Attendance["status"];

const STATUS_OPTS: { value: AttStatus; label: string; color: string }[] = [
  { value: "present", label: "Mevcut",  color: "#16a34a" },
  { value: "half",    label: "Yarım",   color: "#d97706" },
  { value: "absent",  label: "Yok",     color: "#dc2626" },
];

function statusFor(s: AttStatus | undefined) {
  return STATUS_OPTS.find((o) => o.value === s);
}

export default function PuantajScreen() {
  const colors = useColors();
  const router = useRouter();
  const {
    projects,
    appUsers,
    attendance,
    addAttendance,
    updateAttendance,
  } = useApp();

  const perm = usePermission("puantaj");
  const canEdit = perm === "edit";
  useEffect(() => { if (perm === "none") router.back(); }, [perm]);

  const [filter, setFilter] = useState<string | null>(projects[0]?.id || null);
  const [date, setDate] = useState(todayStr());
  const [openDropdown, setOpenDropdown] = useState<string | null>(null);

  const projectId = filter || projects[0]?.id || "";

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
    return keys.map((key) => ({
      company: key || "Diğer",
      users: map[key],
    }));
  }, [appUsers]);

  function attFor(userId: string): Attendance | undefined {
    return attendance.find(
      (a) => a.workerId === userId && a.date === date && a.projectId === projectId
    );
  }

  function hoursFor(s: AttStatus) {
    return s === "present" ? 8 : s === "half" ? 4 : 0;
  }

  function setStatus(u: AppUser, s: AttStatus) {
    if (!projectId) return;
    const existing = attFor(u.id);
    if (existing) {
      updateAttendance(existing.id, { status: s, hours: hoursFor(s) });
    } else {
      addAttendance({
        projectId,
        workerId: u.id,
        workerName: u.name,
        date,
        status: s,
        hours: hoursFor(s),
        note: "",
      });
    }
    setOpenDropdown(null);
  }

  const totals = useMemo(() => {
    let p = 0, h = 0, a = 0;
    for (const u of appUsers) {
      const att = attFor(u.id);
      if (att?.status === "present") p++;
      else if (att?.status === "half") h++;
      else if (att?.status === "absent") a++;
    }
    return { p, h, a };
  }, [appUsers, attendance, date, projectId]);

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
          <View style={styles.dateBar}>
            <DatePickerInput value={date} onChange={setDate} />
          </View>

          <View style={styles.summary}>
            {STATUS_OPTS.map((opt) => (
              <View key={opt.value} style={[styles.sumBox, { backgroundColor: opt.color + "22" }]}>
                <Text style={[styles.sumNum, { color: opt.color }]}>
                  {opt.value === "present" ? totals.p : opt.value === "half" ? totals.h : totals.a}
                </Text>
                <Text style={[styles.sumLabel, { color: colors.foreground }]}>{opt.label}</Text>
              </View>
            ))}
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
            <ScrollView contentContainerStyle={styles.list}>
              {groupedUsers.map((group) => (
                <View key={group.company}>
                  <View style={[styles.groupHeader, { borderLeftColor: colors.primary }]}>
                    <Feather name="briefcase" size={13} color={colors.primary} />
                    <Text style={[styles.groupTitle, { color: colors.foreground }]}>
                      {group.company}
                    </Text>
                    <View style={[styles.groupCount, { backgroundColor: colors.muted }]}>
                      <Text style={[styles.groupCountText, { color: colors.mutedForeground }]}>
                        {group.users.length} kişi
                      </Text>
                    </View>
                  </View>

                  <View style={styles.groupCards}>
                    {group.users.map((u) => {
                      const att = attFor(u.id);
                      const opted = statusFor(att?.status);
                      const isOpen = openDropdown === u.id;

                      return (
                        <View key={u.id} style={[styles.card, { backgroundColor: colors.card }]}>
                          <View style={styles.cardLeft}>
                            <Text style={[styles.wname, { color: colors.foreground }]}>
                              {u.name}
                            </Text>
                            {(u.profession || u.phone) ? (
                              <Text style={[styles.wmeta, { color: colors.mutedForeground }]}>
                                {[u.profession, u.phone].filter(Boolean).join(" · ")}
                              </Text>
                            ) : null}
                          </View>

                          <TouchableOpacity
                            onPress={canEdit ? () => setOpenDropdown(isOpen ? null : u.id) : undefined}
                            activeOpacity={canEdit ? 0.8 : 1}
                            style={[
                              styles.statusBtn,
                              {
                                backgroundColor: opted
                                  ? opted.color + "20"
                                  : colors.muted,
                                borderColor: opted ? opted.color : colors.muted,
                              },
                            ]}
                          >
                            <View
                              style={[
                                styles.statusDot,
                                { backgroundColor: opted ? opted.color : colors.mutedForeground },
                              ]}
                            />
                            <Text
                              style={[
                                styles.statusBtnText,
                                { color: opted ? opted.color : colors.mutedForeground },
                              ]}
                            >
                              {opted ? opted.label : "Seçilmedi"}
                            </Text>
                            {canEdit ? (
                              <Feather
                                name={isOpen ? "chevron-up" : "chevron-down"}
                                size={13}
                                color={opted ? opted.color : colors.mutedForeground}
                              />
                            ) : null}
                          </TouchableOpacity>

                          {isOpen && canEdit ? (
                            <View
                              style={[
                                styles.dropdown,
                                { backgroundColor: colors.card, borderColor: colors.muted },
                              ]}
                            >
                              {STATUS_OPTS.map((opt) => (
                                <TouchableOpacity
                                  key={opt.value}
                                  style={[
                                    styles.dropdownItem,
                                    att?.status === opt.value && { backgroundColor: opt.color + "15" },
                                  ]}
                                  onPress={() => setStatus(u, opt.value)}
                                  activeOpacity={0.8}
                                >
                                  <View style={[styles.dropdownDot, { backgroundColor: opt.color }]} />
                                  <Text style={[styles.dropdownText, { color: opt.color }]}>
                                    {opt.label}
                                  </Text>
                                  {att?.status === opt.value ? (
                                    <Feather name="check" size={13} color={opt.color} />
                                  ) : null}
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
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  dateBar: { paddingHorizontal: 16, marginTop: 12 },
  summary: { flexDirection: "row", gap: 8, paddingHorizontal: 16, marginTop: 12 },
  sumBox: { flex: 1, padding: 12, borderRadius: 10, alignItems: "center" },
  sumNum: { fontSize: 22, fontFamily: "Inter_700Bold" },
  sumLabel: { fontSize: 12, fontFamily: "Inter_500Medium", marginTop: 2 },
  list: { padding: 16, paddingBottom: 32 },
  groupHeader: {
    flexDirection: "row",
    alignItems: "center",
    gap: 7,
    marginTop: 16,
    marginBottom: 8,
    paddingLeft: 10,
    borderLeftWidth: 3,
  },
  groupTitle: { fontSize: 14, fontFamily: "Inter_700Bold", flex: 1 },
  groupCount: { paddingHorizontal: 8, paddingVertical: 2, borderRadius: 999 },
  groupCountText: { fontSize: 11, fontFamily: "Inter_500Medium" },
  groupCards: { gap: 6 },
  card: {
    borderRadius: 12,
    padding: 12,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  cardLeft: { flex: 1, marginBottom: 8 },
  wname: { fontSize: 15, fontFamily: "Inter_600SemiBold" },
  wmeta: { fontSize: 12, fontFamily: "Inter_400Regular", marginTop: 2 },
  statusBtn: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 8,
    borderWidth: 1,
    alignSelf: "flex-start",
  },
  statusDot: { width: 7, height: 7, borderRadius: 4 },
  statusBtnText: { fontSize: 13, fontFamily: "Inter_600SemiBold" },
  dropdown: {
    marginTop: 6,
    borderRadius: 10,
    borderWidth: 1,
    overflow: "hidden",
  },
  dropdownItem: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
    paddingVertical: 11,
    paddingHorizontal: 14,
  },
  dropdownDot: { width: 8, height: 8, borderRadius: 4 },
  dropdownText: { fontSize: 14, fontFamily: "Inter_600SemiBold", flex: 1 },
});
