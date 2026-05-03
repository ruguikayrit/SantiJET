import { Feather } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import React, { useEffect, useMemo, useState } from "react";
import {
  Alert,
  FlatList,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";

import BottomSheet from "@/components/BottomSheet";
import EmptyState from "@/components/EmptyState";
import Header from "@/components/Header";
import PrimaryButton from "@/components/PrimaryButton";
import { Project, useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";
import { usePermission } from "@/hooks/usePermission";

const STATUS_LABEL: Record<Project["status"], string> = {
  active: "Aktif",
  paused: "Duraklatıldı",
  completed: "Tamamlandı",
};
const STATUS_COLOR: Record<Project["status"], string> = {
  active: "#16a34a",
  paused: "#d97706",
  completed: "#0891b2",
};

function fmtDate(d?: string): string {
  if (!d) return "—";
  const dt = new Date(d);
  if (isNaN(dt.getTime())) return d;
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${pad(dt.getDate())}.${pad(dt.getMonth() + 1)}.${dt.getFullYear()}`;
}

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

export default function ArsivScreen() {
  const colors = useColors();
  const router = useRouter();
  const {
    projects,
    unarchiveProject,
    deleteProject,
    attendance,
    productions,
    tasks,
    dailyReports,
    subcontractors,
    purchases,
    projectItems,
    surveys,
    scheduleTasks,
  } = useApp();

  const perm = usePermission("arsiv");
  const canEdit = perm === "edit";
  useEffect(() => {
    if (perm === "none") {
      if (router.canGoBack()) router.back();
      else router.replace("/" as any);
    }
  }, [perm]);

  const [search, setSearch] = useState("");
  const [detailId, setDetailId] = useState<string | null>(null);

  const archived = useMemo(() => {
    const list = projects.filter((p) => p.archived);
    list.sort((a, b) => {
      const at = a.archivedAt ? new Date(a.archivedAt).getTime() : 0;
      const bt = b.archivedAt ? new Date(b.archivedAt).getTime() : 0;
      return bt - at;
    });
    const q = norm(search);
    if (!q) return list;
    return list.filter((p) =>
      norm([p.name, p.location, p.contractor, p.description].join(" ")).includes(q)
    );
  }, [projects, search]);

  const detailProject = useMemo(
    () => archived.find((p) => p.id === detailId) || projects.find((p) => p.id === detailId) || null,
    [archived, projects, detailId]
  );

  function counts(projectId: string) {
    return {
      attendance: attendance.filter((x) => x.projectId === projectId).length,
      productions: productions.filter((x) => x.projectId === projectId).length,
      tasks: tasks.filter((x) => x.projectId === projectId).length,
      dailyReports: dailyReports.filter((x) => x.projectId === projectId).length,
      subcontractors: subcontractors.filter((x) => x.projectId === projectId).length,
      purchases: purchases.filter((x) => x.projectId === projectId).length,
      projectItems: projectItems.filter((x) => x.projectId === projectId).length,
      surveys: surveys.filter((x) => x.projectId === projectId).length,
      scheduleTasks: scheduleTasks.filter((x) => x.projectId === projectId).length,
    };
  }

  function handleRestore(id: string) {
    if (!canEdit) return;
    Alert.alert(
      "Geri Yükle",
      "Bu proje arşivden çıkarılıp aktif proje listesine geri taşınacak. Devam edilsin mi?",
      [
        { text: "Vazgeç", style: "cancel" },
        {
          text: "Geri Yükle",
          onPress: () => {
            unarchiveProject(id);
            setDetailId(null);
          },
        },
      ]
    );
  }

  function handleDelete(id: string) {
    if (!canEdit) return;
    Alert.alert(
      "Kalıcı Olarak Sil",
      "Bu proje ve tüm bağlı kayıtları (puantaj, imalat, görev, hakediş vb.) kalıcı olarak silinecek. Bu işlem GERİ ALINAMAZ. Devam edilsin mi?",
      [
        { text: "Vazgeç", style: "cancel" },
        {
          text: "Kalıcı Sil",
          style: "destructive",
          onPress: () => {
            deleteProject(id);
            setDetailId(null);
          },
        },
      ]
    );
  }

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <Header
        title="Arşiv"
        subtitle="Arşivlenen projeler"
        onBack={() => (router.canGoBack() ? router.back() : router.replace("/" as any))}
      />

      <View style={[styles.searchBar, { backgroundColor: colors.card, borderBottomColor: colors.border }]}>
        <View style={[styles.searchBox, { backgroundColor: colors.muted }]}>
          <Feather name="search" size={14} color={colors.mutedForeground} />
          <TextInput
            value={search}
            onChangeText={setSearch}
            placeholder="Arşivde ara..."
            placeholderTextColor={colors.mutedForeground}
            style={[styles.searchInput, { color: colors.foreground }]}
          />
          {search ? (
            <TouchableOpacity onPress={() => setSearch("")} hitSlop={8}>
              <Feather name="x" size={14} color={colors.mutedForeground} />
            </TouchableOpacity>
          ) : null}
        </View>
      </View>

      {archived.length === 0 ? (
        <EmptyState
          icon="archive"
          title={search ? "Sonuç yok" : "Arşiv boş"}
          description={
            search
              ? "Arama kriterine uyan arşiv kaydı bulunamadı."
              : "Henüz arşivlenmiş proje yok. Bir projeyi düzenleme ekranından 'Arşivle' düğmesi ile arşive taşıyabilirsiniz."
          }
        />
      ) : (
        <FlatList
          data={archived}
          keyExtractor={(p) => p.id}
          contentContainerStyle={styles.list}
          renderItem={({ item }) => {
            const c = counts(item.id);
            const total =
              c.attendance + c.productions + c.tasks + c.dailyReports +
              c.subcontractors + c.purchases + c.projectItems + c.surveys + c.scheduleTasks;
            return (
              <TouchableOpacity
                style={[styles.card, { backgroundColor: colors.card }]}
                activeOpacity={0.85}
                onPress={() => setDetailId(item.id)}
              >
                <View style={styles.cardHead}>
                  <View style={{ flex: 1 }}>
                    <Text style={[styles.cardTitle, { color: colors.foreground }]} numberOfLines={2}>
                      {item.name}
                    </Text>
                    {item.location ? (
                      <View style={styles.metaRow}>
                        <Feather name="map-pin" size={12} color={colors.mutedForeground} />
                        <Text style={[styles.meta, { color: colors.mutedForeground }]} numberOfLines={1}>
                          {item.location}
                        </Text>
                      </View>
                    ) : null}
                    {item.contractor ? (
                      <View style={styles.metaRow}>
                        <Feather name="briefcase" size={12} color={colors.mutedForeground} />
                        <Text style={[styles.meta, { color: colors.mutedForeground }]} numberOfLines={1}>
                          {item.contractor}
                        </Text>
                      </View>
                    ) : null}
                  </View>
                  <View style={[styles.badge, { backgroundColor: STATUS_COLOR[item.status] + "22" }]}>
                    <Text style={[styles.badgeText, { color: STATUS_COLOR[item.status] }]}>
                      {STATUS_LABEL[item.status]}
                    </Text>
                  </View>
                </View>

                <View style={[styles.archInfo, { backgroundColor: colors.muted }]}>
                  <Feather name="archive" size={12} color={colors.mutedForeground} />
                  <Text style={[styles.archInfoText, { color: colors.mutedForeground }]}>
                    Arşivlendi: {fmtDate(item.archivedAt)}
                  </Text>
                  <View style={{ flex: 1 }} />
                  <Feather name="database" size={12} color={colors.mutedForeground} />
                  <Text style={[styles.archInfoText, { color: colors.mutedForeground }]}>
                    {total} kayıt
                  </Text>
                </View>
              </TouchableOpacity>
            );
          }}
        />
      )}

      <BottomSheet
        visible={!!detailId}
        onClose={() => setDetailId(null)}
        title={detailProject?.name || "Arşiv"}
      >
        {detailProject ? (
          <>
            <View style={[styles.detailBox, { backgroundColor: colors.muted }]}>
              <View style={styles.detailRow}>
                <Feather name="archive" size={13} color={colors.mutedForeground} />
                <Text style={[styles.detailLabel, { color: colors.mutedForeground }]}>Arşivlendi:</Text>
                <Text style={[styles.detailVal, { color: colors.foreground }]}>
                  {fmtDate(detailProject.archivedAt)}
                </Text>
              </View>
              {detailProject.location ? (
                <View style={styles.detailRow}>
                  <Feather name="map-pin" size={13} color={colors.mutedForeground} />
                  <Text style={[styles.detailLabel, { color: colors.mutedForeground }]}>Konum:</Text>
                  <Text style={[styles.detailVal, { color: colors.foreground }]} numberOfLines={2}>
                    {detailProject.location}
                  </Text>
                </View>
              ) : null}
              {detailProject.contractor ? (
                <View style={styles.detailRow}>
                  <Feather name="briefcase" size={13} color={colors.mutedForeground} />
                  <Text style={[styles.detailLabel, { color: colors.mutedForeground }]}>Yüklenici:</Text>
                  <Text style={[styles.detailVal, { color: colors.foreground }]} numberOfLines={2}>
                    {detailProject.contractor}
                  </Text>
                </View>
              ) : null}
              {detailProject.startDate || detailProject.endDate ? (
                <View style={styles.detailRow}>
                  <Feather name="calendar" size={13} color={colors.mutedForeground} />
                  <Text style={[styles.detailLabel, { color: colors.mutedForeground }]}>Süre:</Text>
                  <Text style={[styles.detailVal, { color: colors.foreground }]}>
                    {fmtDate(detailProject.startDate)} → {fmtDate(detailProject.endDate)}
                  </Text>
                </View>
              ) : null}
              {detailProject.budget > 0 ? (
                <View style={styles.detailRow}>
                  <Feather name="dollar-sign" size={13} color={colors.mutedForeground} />
                  <Text style={[styles.detailLabel, { color: colors.mutedForeground }]}>Bütçe:</Text>
                  <Text style={[styles.detailVal, { color: colors.foreground }]}>
                    {detailProject.budget.toLocaleString("tr-TR")} ₺
                  </Text>
                </View>
              ) : null}
            </View>

            <Text style={[styles.sectionLabel, { color: colors.foreground }]}>Bağlı Veriler</Text>
            {(() => {
              const c = counts(detailProject.id);
              const items: { icon: string; label: string; n: number }[] = [
                { icon: "users",       label: "Puantaj",       n: c.attendance },
                { icon: "tool",        label: "İmalat",        n: c.productions },
                { icon: "check-square",label: "Görev",         n: c.tasks },
                { icon: "file-text",   label: "Günlük Rapor",  n: c.dailyReports },
                { icon: "truck",       label: "Taşeron",       n: c.subcontractors },
                { icon: "shopping-cart",label:"Satın Alma",    n: c.purchases },
                { icon: "layers",      label: "Proje Kalemi",  n: c.projectItems },
                { icon: "search",      label: "Keşif",         n: c.surveys },
                { icon: "calendar",    label: "İş Programı",   n: c.scheduleTasks },
              ];
              return (
                <View style={styles.gridStats}>
                  {items.map((it) => (
                    <View key={it.label} style={[styles.statCell, { backgroundColor: colors.muted }]}>
                      <Feather name={it.icon as any} size={14} color={colors.mutedForeground} />
                      <Text style={[styles.statN, { color: colors.foreground }]}>{it.n}</Text>
                      <Text style={[styles.statL, { color: colors.mutedForeground }]} numberOfLines={1}>
                        {it.label}
                      </Text>
                    </View>
                  ))}
                </View>
              );
            })()}

            {detailProject.description ? (
              <>
                <Text style={[styles.sectionLabel, { color: colors.foreground, marginTop: 12 }]}>Açıklama</Text>
                <Text style={[styles.descText, { color: colors.mutedForeground }]}>
                  {detailProject.description}
                </Text>
              </>
            ) : null}

            {canEdit ? (
              <PrimaryButton
                label="Arşivden Çıkar"
                onPress={() => handleRestore(detailProject.id)}
                style={{ marginTop: 14 }}
              />
            ) : null}
            {canEdit ? (
              <PrimaryButton
                label="Kalıcı Olarak Sil"
                variant="danger"
                onPress={() => handleDelete(detailProject.id)}
                style={{ marginTop: 10 }}
              />
            ) : null}
            <PrimaryButton
              label="Kapat"
              variant="secondary"
              onPress={() => setDetailId(null)}
              style={{ marginTop: 10 }}
            />
          </>
        ) : null}
      </BottomSheet>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  searchBar: { paddingHorizontal: 12, paddingVertical: 10, borderBottomWidth: StyleSheet.hairlineWidth },
  searchBox: { flexDirection: "row", alignItems: "center", gap: 8, paddingHorizontal: 12, height: 38, borderRadius: 10 },
  searchInput: { flex: 1, fontSize: 13, fontFamily: "Inter_400Regular", paddingVertical: 0 },
  list: { padding: 12, gap: 10 },
  card: { borderRadius: 12, padding: 12, marginBottom: 10 },
  cardHead: { flexDirection: "row", gap: 10, alignItems: "flex-start", marginBottom: 8 },
  cardTitle: { fontSize: 15, fontFamily: "Inter_700Bold", marginBottom: 4 },
  metaRow: { flexDirection: "row", alignItems: "center", gap: 6, marginTop: 2 },
  meta: { fontSize: 12, fontFamily: "Inter_400Regular", flex: 1 },
  badge: { paddingHorizontal: 8, paddingVertical: 3, borderRadius: 999 },
  badgeText: { fontSize: 11, fontFamily: "Inter_600SemiBold" },
  archInfo: { flexDirection: "row", alignItems: "center", gap: 6, paddingHorizontal: 10, paddingVertical: 7, borderRadius: 8 },
  archInfoText: { fontSize: 11, fontFamily: "Inter_500Medium" },
  detailBox: { borderRadius: 10, padding: 12, marginBottom: 12, gap: 8 },
  detailRow: { flexDirection: "row", alignItems: "center", gap: 8 },
  detailLabel: { fontSize: 12, fontFamily: "Inter_500Medium", minWidth: 70 },
  detailVal: { fontSize: 13, fontFamily: "Inter_600SemiBold", flex: 1 },
  sectionLabel: { fontSize: 13, fontFamily: "Inter_700Bold", marginBottom: 8 },
  gridStats: { flexDirection: "row", flexWrap: "wrap", gap: 6 },
  statCell: { width: "31%", flexGrow: 1, paddingVertical: 10, paddingHorizontal: 8, borderRadius: 10, alignItems: "center", gap: 2 },
  statN: { fontSize: 16, fontFamily: "Inter_700Bold" },
  statL: { fontSize: 10, fontFamily: "Inter_500Medium", textAlign: "center" },
  descText: { fontSize: 13, fontFamily: "Inter_400Regular", lineHeight: 18 },
});
