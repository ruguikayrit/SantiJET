import { Feather } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import React, { useEffect, useMemo, useState } from "react";
import {
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";

import BottomSheet from "@/components/BottomSheet";
import EmptyState from "@/components/EmptyState";
import FormInput from "@/components/FormInput";
import Header from "@/components/Header";
import PrimaryButton from "@/components/PrimaryButton";
import ProjectPicker from "@/components/ProjectPicker";
import { Attendance, Worker, useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";
import { usePermission } from "@/hooks/usePermission";

function todayStr() {
  const d = new Date();
  return `${String(d.getDate()).padStart(2, "0")}.${String(d.getMonth() + 1).padStart(2, "0")}.${d.getFullYear()}`;
}

const STATUS_LABEL: Record<Attendance["status"], string> = {
  present: "Mevcut",
  absent: "Yok",
  half: "Yarım",
};
const STATUS_COLOR: Record<Attendance["status"], string> = {
  present: "#16a34a",
  absent: "#dc2626",
  half: "#d97706",
};

interface WForm {
  name: string;
  role: string;
  phone: string;
  dailyRate: string;
}

const EMPTY_W: WForm = { name: "", role: "", phone: "", dailyRate: "" };

export default function PuantajScreen() {
  const colors = useColors();
  const router = useRouter();
  const {
    projects,
    workers,
    attendance,
    addWorker,
    updateWorker,
    deleteWorker,
    addAttendance,
    updateAttendance,
  } = useApp();
  const perm = usePermission("puantaj");
  const canEdit = perm === "edit";
  useEffect(() => { if (perm === "none") router.back(); }, [perm]);

  const [filter, setFilter] = useState<string | null>(projects[0]?.id || null);
  const [date, setDate] = useState(todayStr());
  const [workerSheet, setWorkerSheet] = useState(false);
  const [editWorkerId, setEditWorkerId] = useState<string | null>(null);
  const [wForm, setWForm] = useState<WForm>(EMPTY_W);

  const projectWorkers = useMemo(() => {
    const id = filter || projects[0]?.id;
    if (!id) return [];
    return workers.filter((w) => w.projectId === id);
  }, [workers, filter, projects]);

  function attFor(workerId: string): Attendance | undefined {
    return attendance.find((a) => a.workerId === workerId && a.date === date);
  }

  function hoursFor(status: Attendance["status"]) {
    return status === "present" ? 8 : status === "half" ? 4 : 0;
  }

  function setStatus(w: Worker, status: Attendance["status"]) {
    const existing = attFor(w.id);
    if (existing) {
      updateAttendance(existing.id, { status, hours: hoursFor(status) });
    } else {
      addAttendance({
        projectId: w.projectId,
        workerId: w.id,
        workerName: w.name,
        date,
        status,
        hours: hoursFor(status),
        note: "",
      });
    }
  }

  function openWorker(w?: Worker) {
    if (w) {
      setEditWorkerId(w.id);
      setWForm({
        name: w.name,
        role: w.role,
        phone: w.phone,
        dailyRate: String(w.dailyRate || ""),
      });
    } else {
      setEditWorkerId(null);
      setWForm(EMPTY_W);
    }
    setWorkerSheet(true);
  }

  function saveWorker() {
    if (!wForm.name.trim()) return;
    const projId = filter || projects[0]?.id;
    if (!projId) return;
    const data = {
      projectId: projId,
      name: wForm.name.trim(),
      role: wForm.role.trim(),
      phone: wForm.phone.trim(),
      dailyRate: parseFloat(wForm.dailyRate) || 0,
    };
    if (editWorkerId) updateWorker(editWorkerId, data);
    else addWorker(data);
    setWorkerSheet(false);
  }

  function removeWorker() {
    if (editWorkerId) deleteWorker(editWorkerId);
    setWorkerSheet(false);
  }

  const totals = useMemo(() => {
    let p = 0, a = 0, h = 0;
    for (const w of projectWorkers) {
      const att = attFor(w.id);
      if (att?.status === "present") p++;
      else if (att?.status === "absent") a++;
      else if (att?.status === "half") h++;
    }
    return { p, a, h };
  }, [projectWorkers, attendance, date]);

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <Header
        title="Puantaj"
        onBack={() => router.back()}
        rightAction={canEdit && projects.length > 0 ? { icon: "user-plus", onPress: () => openWorker() } : undefined}
      />

      <ProjectPicker
        projects={projects}
        value={filter}
        onChange={setFilter}
        includeAll={false}
      />

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
          <View style={[styles.dateBar, { backgroundColor: colors.card }]}>
            <Feather name="calendar" size={16} color={colors.mutedForeground} />
            <FormInput
              label=""
              value={date}
              onChangeText={setDate}
              placeholder="GG.AA.YYYY"
              style={{ flex: 1, height: 36, marginBottom: 0 }}
            />
            <TouchableOpacity onPress={() => setDate(todayStr())} activeOpacity={0.8}>
              <Text style={[styles.todayBtn, { color: colors.primary }]}>Bugün</Text>
            </TouchableOpacity>
          </View>

          <View style={styles.summary}>
            <View style={[styles.sumBox, { backgroundColor: STATUS_COLOR.present + "22" }]}>
              <Text style={[styles.sumNum, { color: STATUS_COLOR.present }]}>{totals.p}</Text>
              <Text style={[styles.sumLabel, { color: colors.foreground }]}>Mevcut</Text>
            </View>
            <View style={[styles.sumBox, { backgroundColor: STATUS_COLOR.half + "22" }]}>
              <Text style={[styles.sumNum, { color: STATUS_COLOR.half }]}>{totals.h}</Text>
              <Text style={[styles.sumLabel, { color: colors.foreground }]}>Yarım</Text>
            </View>
            <View style={[styles.sumBox, { backgroundColor: STATUS_COLOR.absent + "22" }]}>
              <Text style={[styles.sumNum, { color: STATUS_COLOR.absent }]}>{totals.a}</Text>
              <Text style={[styles.sumLabel, { color: colors.foreground }]}>Devamsız</Text>
            </View>
          </View>

          {projectWorkers.length === 0 ? (
            <EmptyState
              icon="users"
              title="Personel yok"
              description="Bu projeye personel eklemek için sağ üstteki + düğmesine dokunun"
              actionLabel="Personel Ekle"
              onAction={() => openWorker()}
            />
          ) : (
            <ScrollView contentContainerStyle={styles.list}>
              {projectWorkers.map((w) => {
                const att = attFor(w.id);
                return (
                  <View
                    key={w.id}
                    style={[styles.card, { backgroundColor: colors.card }]}
                  >
                    <TouchableOpacity
                      style={styles.cardLeft}
                      onPress={canEdit ? () => openWorker(w) : undefined}
                      activeOpacity={0.8}
                    >
                      <Text style={[styles.wname, { color: colors.foreground }]}>
                        {w.name}
                      </Text>
                      {w.role ? (
                        <Text style={[styles.wmeta, { color: colors.mutedForeground }]}>
                          {w.role}
                          {w.dailyRate ? ` · ${w.dailyRate} ₺/gün` : ""}
                        </Text>
                      ) : null}
                    </TouchableOpacity>

                    <View style={styles.statusRow}>
                      {(["present", "half", "absent"] as const).map((s) => (
                        <TouchableOpacity
                          key={s}
                          onPress={canEdit ? () => setStatus(w, s) : undefined}
                          style={[
                            styles.statBtn,
                            {
                              backgroundColor:
                                att?.status === s ? STATUS_COLOR[s] : colors.muted,
                            },
                          ]}
                          activeOpacity={0.8}
                        >
                          <Text
                            style={[
                              styles.statText,
                              {
                                color: att?.status === s ? "#fff" : colors.foreground,
                              },
                            ]}
                          >
                            {STATUS_LABEL[s]}
                          </Text>
                        </TouchableOpacity>
                      ))}
                    </View>
                  </View>
                );
              })}
            </ScrollView>
          )}
        </>
      )}

      <BottomSheet
        visible={workerSheet}
        onClose={() => setWorkerSheet(false)}
        title={editWorkerId ? "Personeli Düzenle" : "Yeni Personel"}
      >
        <FormInput
          label="Ad Soyad"
          value={wForm.name}
          onChangeText={(v) => setWForm({ ...wForm, name: v })}
        />
        <FormInput
          label="Görev"
          value={wForm.role}
          onChangeText={(v) => setWForm({ ...wForm, role: v })}
          placeholder="Örn: Kalıpçı, Demirci"
        />
        <FormInput
          label="Telefon"
          value={wForm.phone}
          onChangeText={(v) => setWForm({ ...wForm, phone: v })}
          keyboardType="phone-pad"
        />
        <FormInput
          label="Günlük Yevmiye (₺)"
          value={wForm.dailyRate}
          onChangeText={(v) => setWForm({ ...wForm, dailyRate: v })}
          keyboardType="numeric"
        />
        {canEdit ? <PrimaryButton label="Kaydet" onPress={saveWorker} style={{ marginTop: 8 }} /> : null}
        {canEdit && editWorkerId ? (
          <PrimaryButton label="Sil" variant="danger" onPress={removeWorker} style={{ marginTop: 10 }} />
        ) : null}
        {!canEdit ? <PrimaryButton label="Kapat" onPress={() => setWorkerSheet(false)} style={{ marginTop: 8 }} /> : null}
      </BottomSheet>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  dateBar: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 12,
    gap: 8,
    marginHorizontal: 16,
    marginTop: 12,
    paddingVertical: 6,
    borderRadius: 10,
  },
  todayBtn: {
    fontSize: 13,
    fontFamily: "Inter_600SemiBold",
    paddingHorizontal: 8,
  },
  summary: {
    flexDirection: "row",
    gap: 8,
    paddingHorizontal: 16,
    marginTop: 12,
  },
  sumBox: {
    flex: 1,
    padding: 12,
    borderRadius: 10,
    alignItems: "center",
  },
  sumNum: { fontSize: 22, fontFamily: "Inter_700Bold" },
  sumLabel: { fontSize: 12, fontFamily: "Inter_500Medium", marginTop: 2 },
  list: { padding: 16, gap: 10 },
  card: {
    borderRadius: 12,
    padding: 12,
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  cardLeft: { flex: 1 },
  wname: { fontSize: 15, fontFamily: "Inter_600SemiBold" },
  wmeta: { fontSize: 12, fontFamily: "Inter_400Regular", marginTop: 2 },
  statusRow: { flexDirection: "row", gap: 4 },
  statBtn: {
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 8,
    minWidth: 52,
    alignItems: "center",
  },
  statText: { fontSize: 11, fontFamily: "Inter_600SemiBold" },
});
