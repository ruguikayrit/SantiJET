import { Feather } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import React, { useEffect, useMemo, useState } from "react";
import {
  Alert,
  FlatList,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";

import BottomSheet from "@/components/BottomSheet";
import EmptyState from "@/components/EmptyState";
import DatePickerInput from "@/components/DatePickerInput";
import FormInput from "@/components/FormInput";
import Header from "@/components/Header";
import PrimaryButton from "@/components/PrimaryButton";
import ProjectPicker from "@/components/ProjectPicker";
import { ProjectItem, useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";
import { usePermission } from "@/hooks/usePermission";

const STATUS_LABEL: Record<ProjectItem["status"], string> = {
  planned: "Planlanıyor",
  active: "Devam",
  paused: "Askıda",
  completed: "Tamamlandı",
};
const STATUS_COLOR: Record<ProjectItem["status"], string> = {
  planned: "#64748b",
  active: "#16a34a",
  paused: "#d97706",
  completed: "#0891b2",
};

interface F {
  projectId: string;
  name: string;
  tradeGroup: string;
  status: ProjectItem["status"];
  progressPct: string;
  startDate: string;
  endDate: string;
  responsibleUserId: string;
  subcontractorName: string;
  contractAmount: string;
  note: string;
}

const EMPTY: F = {
  projectId: "",
  name: "",
  tradeGroup: "",
  status: "planned",
  progressPct: "",
  startDate: "",
  endDate: "",
  responsibleUserId: "",
  subcontractorName: "",
  contractAmount: "",
  note: "",
};

export default function ProjeKalemleriScreen() {
  const colors = useColors();
  const router = useRouter();
  const {
    projects,
    projectItems,
    addProjectItem,
    updateProjectItem,
    deleteProjectItem,
    seedDefaultProjectItems,
    tradeGroups,
    appUsers,
    subcontractors,
  } = useApp();

  const perm = usePermission("proje-kalemleri");
  const canEdit = perm === "edit";
  useEffect(() => {
    if (perm === "none") {
      if (router.canGoBack()) router.back();
      else router.replace("/" as any);
    }
  }, [perm]);

  const [filter, setFilter] = useState<string | null>(projects[0]?.id || null);
  useEffect(() => {
    if (filter && !projects.some((p) => p.id === filter)) {
      setFilter(projects[0]?.id || null);
    }
    if (!filter && projects.length > 0) setFilter(projects[0].id);
  }, [projects]);

  const [visible, setVisible] = useState(false);
  const [editId, setEditId] = useState<string | null>(null);
  const [form, setForm] = useState<F>(EMPTY);
  const [tgOpen, setTgOpen] = useState(false);
  const [respOpen, setRespOpen] = useState(false);
  const [subOpen, setSubOpen] = useState(false);

  const list = useMemo(() => {
    return filter ? projectItems.filter((x) => x.projectId === filter) : projectItems;
  }, [projectItems, filter]);

  const subcontractorNames = useMemo(() => {
    const s = new Set<string>();
    for (const sc of subcontractors) {
      const n = (sc.name || "").trim();
      if (n) s.add(n);
    }
    for (const p of projects) {
      const c = ((p as any).contractor || "").trim();
      if (c) s.add(c);
    }
    return Array.from(s).sort((a, b) => a.localeCompare(b, "tr"));
  }, [subcontractors, projects]);

  function open(it?: ProjectItem) {
    if (it) {
      setEditId(it.id);
      setForm({
        projectId: it.projectId,
        name: it.name,
        tradeGroup: it.tradeGroup || "",
        status: it.status,
        progressPct: it.progressPct ? String(it.progressPct) : "",
        startDate: it.startDate || "",
        endDate: it.endDate || "",
        responsibleUserId: it.responsibleUserId || "",
        subcontractorName: it.subcontractorName || "",
        contractAmount: it.contractAmount ? String(it.contractAmount) : "",
        note: it.note || "",
      });
    } else {
      setEditId(null);
      setForm({ ...EMPTY, projectId: filter || projects[0]?.id || "" });
    }
    setTgOpen(false);
    setRespOpen(false);
    setSubOpen(false);
    setVisible(true);
  }

  function save() {
    if (!form.projectId || !form.name.trim()) {
      Alert.alert("Eksik", "Proje ve kalem adı zorunludur.");
      return;
    }
    let pct = parseFloat(form.progressPct.replace(",", ".")) || 0;
    if (pct < 0) pct = 0;
    if (pct > 100) pct = 100;
    const data = {
      projectId: form.projectId,
      name: form.name.trim(),
      tradeGroup: form.tradeGroup.trim(),
      status: form.status,
      progressPct: pct,
      startDate: form.startDate.trim(),
      endDate: form.endDate.trim(),
      responsibleUserId: form.responsibleUserId,
      subcontractorName: form.subcontractorName.trim(),
      contractAmount: parseFloat(form.contractAmount.replace(",", ".")) || 0,
      note: form.note.trim(),
    };
    if (editId) updateProjectItem(editId, data);
    else addProjectItem(data);
    setVisible(false);
  }

  function remove() {
    if (!editId) return;
    Alert.alert("Sil", "Bu kalemi silmek istiyor musunuz?", [
      { text: "Vazgeç", style: "cancel" },
      {
        text: "Sil",
        style: "destructive",
        onPress: () => {
          deleteProjectItem(editId);
          setVisible(false);
        },
      },
    ]);
  }

  function seed() {
    if (!filter) return;
    Alert.alert(
      "Varsayılan Şablon",
      "Hafriyat, Betonarme, Çelik, Mekanik, Elektrik vb. standart kalemler bu projeye eklensin mi? (Aynı isimler atlanır.)",
      [
        { text: "Vazgeç", style: "cancel" },
        {
          text: "Ekle",
          onPress: () => {
            const n = seedDefaultProjectItems(filter);
            Alert.alert("Tamam", n > 0 ? `${n} kalem eklendi.` : "Eklenecek yeni kalem yok.");
          },
        },
      ]
    );
  }

  function projectName(id: string) {
    return projects.find((p) => p.id === id)?.name || "—";
  }

  function userName(id: string) {
    return appUsers.find((u) => u.id === id)?.name || "";
  }

  if (projects.length === 0) {
    return (
      <View style={[styles.root, { backgroundColor: colors.background }]}>
        <Header
          title="Proje Kalemleri"
          onBack={() => (router.canGoBack() ? router.back() : router.replace("/" as any))}
        />
        <EmptyState
          icon="briefcase"
          title="Önce proje ekleyin"
          description="Proje kalemleri için en az bir projeniz olmalı"
          actionLabel="Projelere Git"
          onAction={() => router.push("/proje" as any)}
        />
      </View>
    );
  }

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <Header
        title="Proje Kalemleri"
        onBack={() => (router.canGoBack() ? router.back() : router.replace("/" as any))}
        rightAction={canEdit ? { icon: "plus", onPress: () => open() } : undefined}
      />

      <ProjectPicker projects={projects} value={filter} onChange={setFilter} includeAll={false} />

      {canEdit && filter ? (
        <View style={[styles.seedBar, { backgroundColor: colors.card, borderBottomColor: colors.border }]}>
          <TouchableOpacity onPress={seed} activeOpacity={0.8} style={[styles.seedBtn, { borderColor: colors.primary }]}>
            <Feather name="layers" size={14} color={colors.primary} />
            <Text style={[styles.seedBtnText, { color: colors.primary }]}>Varsayılan Şablonu Ekle</Text>
          </TouchableOpacity>
        </View>
      ) : null}

      {list.length === 0 ? (
        <EmptyState
          icon="layers"
          title="Kalem yok"
          description={canEdit ? "Yeni kalem eklemek için + düğmesine veya 'Varsayılan Şablonu Ekle' düğmesine dokunun" : "Bu projede henüz kalem yok"}
          actionLabel={canEdit ? "Kalem Ekle" : undefined}
          onAction={canEdit ? () => open() : undefined}
        />
      ) : (
        <FlatList
          data={list}
          keyExtractor={(x) => x.id}
          contentContainerStyle={styles.list}
          renderItem={({ item }) => {
            const pct = Math.max(0, Math.min(100, Math.round(item.progressPct || 0)));
            return (
              <TouchableOpacity
                style={[styles.card, { backgroundColor: colors.card }]}
                activeOpacity={0.85}
                onPress={() => (canEdit ? open(item) : null)}
              >
                <View style={styles.cardHead}>
                  <View style={{ flex: 1 }}>
                    <Text style={[styles.proj, { color: colors.mutedForeground }]} numberOfLines={1}>
                      {projectName(item.projectId)}
                    </Text>
                    <Text style={[styles.title, { color: colors.foreground }]} numberOfLines={2}>
                      {item.name}
                    </Text>
                    {item.tradeGroup ? (
                      <Text style={[styles.tg, { color: colors.primary }]} numberOfLines={1}>
                        {item.tradeGroup}
                      </Text>
                    ) : null}
                  </View>
                  <View style={[styles.statusPill, { backgroundColor: STATUS_COLOR[item.status] + "20" }]}>
                    <Text style={[styles.statusText, { color: STATUS_COLOR[item.status] }]}>
                      {STATUS_LABEL[item.status]}
                    </Text>
                  </View>
                </View>

                <View style={styles.progressWrap}>
                  <View style={[styles.progressTrack, { backgroundColor: colors.muted }]}>
                    <View style={[styles.progressFill, { backgroundColor: STATUS_COLOR[item.status], width: `${pct}%` }]} />
                  </View>
                  <Text style={[styles.progressText, { color: colors.mutedForeground }]}>%{pct}</Text>
                </View>

                {(item.responsibleUserId || item.subcontractorName || item.startDate || item.endDate) ? (
                  <View style={styles.metaRow}>
                    {item.responsibleUserId ? (
                      <View style={styles.metaItem}>
                        <Feather name="user" size={11} color={colors.mutedForeground} />
                        <Text style={[styles.metaText, { color: colors.mutedForeground }]} numberOfLines={1}>
                          {userName(item.responsibleUserId) || "—"}
                        </Text>
                      </View>
                    ) : null}
                    {item.subcontractorName ? (
                      <View style={styles.metaItem}>
                        <Feather name="truck" size={11} color={colors.mutedForeground} />
                        <Text style={[styles.metaText, { color: colors.mutedForeground }]} numberOfLines={1}>
                          {item.subcontractorName}
                        </Text>
                      </View>
                    ) : null}
                    {item.startDate || item.endDate ? (
                      <View style={styles.metaItem}>
                        <Feather name="calendar" size={11} color={colors.mutedForeground} />
                        <Text style={[styles.metaText, { color: colors.mutedForeground }]} numberOfLines={1}>
                          {item.startDate || "?"} - {item.endDate || "?"}
                        </Text>
                      </View>
                    ) : null}
                  </View>
                ) : null}
              </TouchableOpacity>
            );
          }}
        />
      )}

      <BottomSheet
        visible={visible}
        onClose={() => setVisible(false)}
        title={editId ? "Kalemi Düzenle" : "Yeni Kalem"}
      >
        <Text style={[styles.label, { color: colors.foreground }]}>Proje</Text>
        <View style={styles.chipRow}>
          {projects.map((p) => (
            <TouchableOpacity
              key={p.id}
              onPress={() => setForm({ ...form, projectId: p.id })}
              style={[styles.chip, { backgroundColor: form.projectId === p.id ? colors.primary : colors.muted }]}
              activeOpacity={0.8}
            >
              <Text style={[styles.chipText, { color: form.projectId === p.id ? "#fff" : colors.foreground }]}>
                {p.name}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        <FormInput
          label="Kalem Adı"
          value={form.name}
          onChangeText={(v) => setForm({ ...form, name: v })}
          placeholder="Örn: Betonarme, Çelik, Mekanik Tesisat..."
        />

        <Text style={[styles.label, { color: colors.foreground, marginTop: 8 }]}>Meslek Grubu</Text>
        <TouchableOpacity
          style={[styles.dropTrigger, { backgroundColor: colors.muted, borderColor: tgOpen ? colors.primary : colors.border }]}
          onPress={() => setTgOpen((v) => !v)}
          activeOpacity={0.8}
        >
          <Text style={{ flex: 1, color: form.tradeGroup ? colors.foreground : colors.mutedForeground, fontFamily: "Inter_400Regular", fontSize: 14 }} numberOfLines={1}>
            {form.tradeGroup || "Meslek grubu seçin..."}
          </Text>
          <Feather name={tgOpen ? "chevron-up" : "chevron-down"} size={16} color={colors.mutedForeground} />
        </TouchableOpacity>
        {tgOpen ? (
          <View style={[styles.dropList, { backgroundColor: colors.muted, borderColor: colors.primary }]}>
            {tradeGroups.length === 0 ? (
              <View style={styles.dropItem}>
                <Text style={{ color: colors.mutedForeground, fontFamily: "Inter_400Regular", fontSize: 13 }}>
                  Meslek grubu tanımlı değil. Ayarlar &gt; Meslek Grubu menüsünden ekleyin.
                </Text>
              </View>
            ) : tradeGroups.map((tm, i) => {
              const isSel = form.tradeGroup === tm;
              return (
                <TouchableOpacity
                  key={tm}
                  style={[styles.dropItem, { borderBottomColor: colors.border }, i === tradeGroups.length - 1 && { borderBottomWidth: 0 }, isSel && { backgroundColor: colors.primary + "20" }]}
                  onPress={() => { setForm({ ...form, tradeGroup: tm }); setTgOpen(false); }}
                  activeOpacity={0.75}
                >
                  <Text style={{ flex: 1, color: isSel ? colors.primary : colors.foreground, fontFamily: isSel ? "Inter_600SemiBold" : "Inter_400Regular", fontSize: 14 }}>
                    {tm}
                  </Text>
                  {isSel ? <Feather name="check" size={14} color={colors.primary} /> : null}
                </TouchableOpacity>
              );
            })}
          </View>
        ) : null}

        <Text style={[styles.label, { color: colors.foreground, marginTop: 12 }]}>Durum</Text>
        <View style={styles.chipRow}>
          {(["planned", "active", "paused", "completed"] as const).map((s) => (
            <TouchableOpacity
              key={s}
              onPress={() => setForm({ ...form, status: s })}
              style={[styles.chip, { backgroundColor: form.status === s ? STATUS_COLOR[s] : colors.muted }]}
              activeOpacity={0.8}
            >
              <Text style={[styles.chipText, { color: form.status === s ? "#fff" : colors.foreground }]}>
                {STATUS_LABEL[s]}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        <View style={styles.row2}>
          <View style={{ flex: 1 }}>
            <FormInput
              label="İlerleme (%)"
              value={form.progressPct}
              onChangeText={(v) => setForm({ ...form, progressPct: v })}
              placeholder="0-100"
              keyboardType="numeric"
            />
          </View>
          <View style={{ flex: 1 }}>
            <FormInput
              label="Sözleşme Bedeli (₺)"
              value={form.contractAmount}
              onChangeText={(v) => setForm({ ...form, contractAmount: v })}
              placeholder="0"
              keyboardType="numeric"
            />
          </View>
        </View>

        <View style={styles.row2}>
          <View style={{ flex: 1 }}>
            <DatePickerInput
              label="Başlangıç"
              value={form.startDate}
              onChange={(v) => setForm({ ...form, startDate: v })}
            />
          </View>
          <View style={{ flex: 1 }}>
            <DatePickerInput
              label="Bitiş"
              value={form.endDate}
              onChange={(v) => setForm({ ...form, endDate: v })}
            />
          </View>
        </View>

        <Text style={[styles.label, { color: colors.foreground, marginTop: 8 }]}>Sorumlu</Text>
        <TouchableOpacity
          style={[styles.dropTrigger, { backgroundColor: colors.muted, borderColor: respOpen ? colors.primary : colors.border }]}
          onPress={() => setRespOpen((v) => !v)}
          activeOpacity={0.8}
        >
          <Text style={{ flex: 1, color: form.responsibleUserId ? colors.foreground : colors.mutedForeground, fontFamily: "Inter_400Regular", fontSize: 14 }} numberOfLines={1}>
            {userName(form.responsibleUserId) || "Sorumlu kullanıcı seçin..."}
          </Text>
          <Feather name={respOpen ? "chevron-up" : "chevron-down"} size={16} color={colors.mutedForeground} />
        </TouchableOpacity>
        {respOpen ? (
          <View style={[styles.dropList, { backgroundColor: colors.muted, borderColor: colors.primary, maxHeight: 240 }]}>
            <ScrollView nestedScrollEnabled>
              {form.responsibleUserId ? (
                <TouchableOpacity
                  style={[styles.dropItem, { borderBottomColor: colors.border }]}
                  onPress={() => { setForm({ ...form, responsibleUserId: "" }); setRespOpen(false); }}
                  activeOpacity={0.75}
                >
                  <Text style={{ flex: 1, color: colors.mutedForeground, fontFamily: "Inter_500Medium", fontSize: 13 }}>— Seçimi temizle —</Text>
                  <Feather name="x" size={14} color={colors.mutedForeground} />
                </TouchableOpacity>
              ) : null}
              {appUsers.length === 0 ? (
                <View style={styles.dropItem}>
                  <Text style={{ color: colors.mutedForeground, fontFamily: "Inter_400Regular", fontSize: 13 }}>
                    Kullanıcı yok.
                  </Text>
                </View>
              ) : appUsers.map((u, i) => {
                const isSel = form.responsibleUserId === u.id;
                return (
                  <TouchableOpacity
                    key={u.id}
                    style={[styles.dropItem, { borderBottomColor: colors.border }, i === appUsers.length - 1 && { borderBottomWidth: 0 }, isSel && { backgroundColor: colors.primary + "20" }]}
                    onPress={() => { setForm({ ...form, responsibleUserId: u.id }); setRespOpen(false); }}
                    activeOpacity={0.75}
                  >
                    <View style={{ flex: 1 }}>
                      <Text style={{ color: isSel ? colors.primary : colors.foreground, fontFamily: isSel ? "Inter_600SemiBold" : "Inter_400Regular", fontSize: 14 }}>
                        {u.name}
                      </Text>
                      {u.profession ? (
                        <Text style={{ color: colors.mutedForeground, fontFamily: "Inter_400Regular", fontSize: 11, marginTop: 2 }}>
                          {u.profession}
                        </Text>
                      ) : null}
                    </View>
                    {isSel ? <Feather name="check" size={14} color={colors.primary} /> : null}
                  </TouchableOpacity>
                );
              })}
            </ScrollView>
          </View>
        ) : null}

        <Text style={[styles.label, { color: colors.foreground, marginTop: 8 }]}>Taşeron Firma</Text>
        <TouchableOpacity
          style={[styles.dropTrigger, { backgroundColor: colors.muted, borderColor: subOpen ? colors.primary : colors.border }]}
          onPress={() => setSubOpen((v) => !v)}
          activeOpacity={0.8}
        >
          <Text style={{ flex: 1, color: form.subcontractorName ? colors.foreground : colors.mutedForeground, fontFamily: "Inter_400Regular", fontSize: 14 }} numberOfLines={1}>
            {form.subcontractorName || "Taşeron firma seçin..."}
          </Text>
          <Feather name={subOpen ? "chevron-up" : "chevron-down"} size={16} color={colors.mutedForeground} />
        </TouchableOpacity>
        {subOpen ? (
          <View style={[styles.dropList, { backgroundColor: colors.muted, borderColor: colors.primary }]}>
            {form.subcontractorName ? (
              <TouchableOpacity
                style={[styles.dropItem, { borderBottomColor: colors.border }]}
                onPress={() => { setForm({ ...form, subcontractorName: "" }); setSubOpen(false); }}
                activeOpacity={0.75}
              >
                <Text style={{ flex: 1, color: colors.mutedForeground, fontFamily: "Inter_500Medium", fontSize: 13 }}>— Seçimi temizle —</Text>
                <Feather name="x" size={14} color={colors.mutedForeground} />
              </TouchableOpacity>
            ) : null}
            {subcontractorNames.length === 0 ? (
              <View style={styles.dropItem}>
                <Text style={{ color: colors.mutedForeground, fontFamily: "Inter_400Regular", fontSize: 13 }}>
                  Taşeron tanımlı değil. Taşeron veya Proje modülünden ekleyin.
                </Text>
              </View>
            ) : subcontractorNames.map((nm, i) => {
              const isSel = form.subcontractorName === nm;
              return (
                <TouchableOpacity
                  key={nm}
                  style={[styles.dropItem, { borderBottomColor: colors.border }, i === subcontractorNames.length - 1 && { borderBottomWidth: 0 }, isSel && { backgroundColor: colors.primary + "20" }]}
                  onPress={() => { setForm({ ...form, subcontractorName: nm }); setSubOpen(false); }}
                  activeOpacity={0.75}
                >
                  <Text style={{ flex: 1, color: isSel ? colors.primary : colors.foreground, fontFamily: isSel ? "Inter_600SemiBold" : "Inter_400Regular", fontSize: 14 }}>
                    {nm}
                  </Text>
                  {isSel ? <Feather name="check" size={14} color={colors.primary} /> : null}
                </TouchableOpacity>
              );
            })}
          </View>
        ) : null}

        <FormInput
          label="Not"
          value={form.note}
          onChangeText={(v) => setForm({ ...form, note: v })}
          placeholder="Açıklama, kapsam, özel koşullar..."
          multiline
          numberOfLines={3}
          style={{ minHeight: 70, paddingTop: 10 }}
        />

        {canEdit ? <PrimaryButton label="Kaydet" onPress={save} style={{ marginTop: 8 }} /> : null}
        {canEdit && editId ? (
          <PrimaryButton label="Sil" variant="danger" onPress={remove} style={{ marginTop: 10 }} />
        ) : null}
        {!canEdit ? <PrimaryButton label="Kapat" onPress={() => setVisible(false)} style={{ marginTop: 8 }} /> : null}
      </BottomSheet>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  seedBar: { paddingHorizontal: 12, paddingVertical: 10, borderBottomWidth: StyleSheet.hairlineWidth },
  seedBtn: { flexDirection: "row", alignItems: "center", gap: 8, paddingHorizontal: 12, paddingVertical: 8, borderRadius: 999, borderWidth: 1, alignSelf: "flex-start" },
  seedBtnText: { fontSize: 13, fontFamily: "Inter_600SemiBold" },
  list: { padding: 12, gap: 10 },
  card: { borderRadius: 14, padding: 12, marginBottom: 10 },
  cardHead: { flexDirection: "row", gap: 10, alignItems: "flex-start" },
  proj: { fontSize: 11, fontFamily: "Inter_500Medium", marginBottom: 2 },
  title: { fontSize: 15, fontFamily: "Inter_700Bold" },
  tg: { fontSize: 12, fontFamily: "Inter_500Medium", marginTop: 2 },
  statusPill: { paddingHorizontal: 10, paddingVertical: 4, borderRadius: 999 },
  statusText: { fontSize: 11, fontFamily: "Inter_600SemiBold" },
  progressWrap: { flexDirection: "row", alignItems: "center", gap: 8, marginTop: 10 },
  progressTrack: { flex: 1, height: 8, borderRadius: 4, overflow: "hidden" },
  progressFill: { height: "100%", borderRadius: 4 },
  progressText: { fontSize: 11, fontFamily: "Inter_600SemiBold", minWidth: 36, textAlign: "right" },
  metaRow: { flexDirection: "row", flexWrap: "wrap", gap: 10, marginTop: 8 },
  metaItem: { flexDirection: "row", alignItems: "center", gap: 4 },
  metaText: { fontSize: 11, fontFamily: "Inter_400Regular", maxWidth: 180 },
  label: { fontSize: 13, fontFamily: "Inter_600SemiBold", marginBottom: 6, marginTop: 4 },
  chipRow: { flexDirection: "row", flexWrap: "wrap", gap: 6, marginBottom: 6 },
  chip: { paddingHorizontal: 12, paddingVertical: 7, borderRadius: 999 },
  chipText: { fontSize: 12, fontFamily: "Inter_500Medium" },
  row2: { flexDirection: "row", gap: 10 },
  dropTrigger: { flexDirection: "row", alignItems: "center", gap: 8, borderWidth: 1, borderRadius: 10, paddingHorizontal: 12, height: 44 },
  dropList: { borderWidth: 1.5, borderRadius: 10, marginTop: 6, overflow: "hidden" },
  dropItem: { flexDirection: "row", alignItems: "center", gap: 8, paddingHorizontal: 12, paddingVertical: 11, borderBottomWidth: StyleSheet.hairlineWidth },
});
