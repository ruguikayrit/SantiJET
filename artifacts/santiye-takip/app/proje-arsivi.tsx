import { Feather } from "@expo/vector-icons";
import * as DocumentPicker from "expo-document-picker";
import { useRouter } from "expo-router";
import React, { useEffect, useMemo, useState } from "react";
import {
  ActivityIndicator,
  Alert,
  FlatList,
  Platform,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";

import BottomSheet from "@/components/BottomSheet";
import EmptyState from "@/components/EmptyState";
import FormInput from "@/components/FormInput";
import Header from "@/components/Header";
import PrimaryButton from "@/components/PrimaryButton";
import ProjectPicker from "@/components/ProjectPicker";
import { ArchiveFile, useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";
import { usePermission } from "@/hooks/usePermission";
import {
  deleteAsset,
  formatBytes,
  openAsset,
  saveAsset,
} from "@/lib/archiveStorage";

const ALLOWED_EXTS = ["pdf", "dwg", "xlsx", "xls"];
const MIME_BY_EXT: Record<string, string> = {
  pdf: "application/pdf",
  dwg: "application/acad",
  xlsx: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  xls: "application/vnd.ms-excel",
};
const EXT_COLOR: Record<string, string> = {
  pdf: "#dc2626",
  dwg: "#0369a1",
  xlsx: "#16a34a",
  xls: "#16a34a",
};
type ExtFilter = "all" | "pdf" | "dwg" | "excel";

function fmtDate(d?: string): string {
  if (!d) return "—";
  const dt = new Date(d);
  if (isNaN(dt.getTime())) return d;
  const pad = (n: number) => String(n).padStart(2, "0");
  return `${pad(dt.getDate())}.${pad(dt.getMonth() + 1)}.${dt.getFullYear()}`;
}

function norm(s: string): string {
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

function getExt(name: string): string {
  const i = name.lastIndexOf(".");
  if (i < 0) return "";
  return name.slice(i + 1).toLowerCase();
}

function genId(): string {
  return `af_${Date.now().toString(36)}_${Math.random().toString(36).slice(2, 8)}`;
}

function notify(title: string, msg: string) {
  if (Platform.OS === "web") {
    if (typeof window !== "undefined") window.alert(`${title}\n\n${msg}`);
  } else {
    Alert.alert(title, msg);
  }
}

export default function ProjeArsiviScreen() {
  const colors = useColors();
  const router = useRouter();
  const { projects, archiveFiles, addArchiveFile, updateArchiveFile, deleteArchiveFile } = useApp();
  const perm = usePermission("proje-arsivi");
  const canEdit = perm === "edit";

  useEffect(() => {
    if (perm === "none") {
      if (router.canGoBack()) router.back();
      else router.replace("/" as any);
    }
  }, [perm]);

  const [projectId, setProjectId] = useState<string>(() => projects[0]?.id ?? "");
  const [search, setSearch] = useState("");
  const [extFilter, setExtFilter] = useState<ExtFilter>("all");
  const [busy, setBusy] = useState(false);
  const [openingId, setOpeningId] = useState<string | null>(null);
  const [editFile, setEditFile] = useState<ArchiveFile | null>(null);
  const [editNote, setEditNote] = useState("");

  useEffect(() => {
    if (!projectId && projects[0]) setProjectId(projects[0].id);
  }, [projects, projectId]);

  const filtered = useMemo(() => {
    let list = archiveFiles.filter((f) => f.projectId === projectId);
    if (extFilter === "excel") list = list.filter((f) => f.ext === "xlsx" || f.ext === "xls");
    else if (extFilter !== "all") list = list.filter((f) => f.ext === extFilter);
    const q = norm(search);
    if (q) list = list.filter((f) => norm([f.name, f.note].join(" ")).includes(q));
    list.sort((a, b) => {
      const at = a.addedAt ? new Date(a.addedAt).getTime() : 0;
      const bt = b.addedAt ? new Date(b.addedAt).getTime() : 0;
      return bt - at;
    });
    return list;
  }, [archiveFiles, projectId, extFilter, search]);

  const totals = useMemo(() => {
    const list = archiveFiles.filter((f) => f.projectId === projectId);
    const size = list.reduce((s, f) => s + (f.size || 0), 0);
    const pdf = list.filter((f) => f.ext === "pdf").length;
    const dwg = list.filter((f) => f.ext === "dwg").length;
    const xls = list.filter((f) => f.ext === "xlsx" || f.ext === "xls").length;
    return { count: list.length, size, pdf, dwg, xls };
  }, [archiveFiles, projectId]);

  async function handlePick() {
    if (!canEdit) return;
    if (!projectId) {
      notify("Proje seçin", "Önce dosya yükleyeceğiniz projeyi seçin.");
      return;
    }
    setBusy(true);
    try {
      const res = await DocumentPicker.getDocumentAsync({
        type: [
          "application/pdf",
          "application/acad",
          "image/vnd.dwg",
          "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
          "application/vnd.ms-excel",
          "*/*",
        ],
        multiple: true,
        copyToCacheDirectory: true,
      });
      if (res.canceled) {
        setBusy(false);
        return;
      }
      const assets = (res as any).assets as { uri: string; name: string; mimeType?: string | null; size?: number | null }[];
      let added = 0;
      let rejected = 0;
      for (const a of assets) {
        const ext = getExt(a.name);
        if (!ALLOWED_EXTS.includes(ext)) {
          rejected++;
          continue;
        }
        const id = genId();
        try {
          const r = await saveAsset(id, a, ext);
          addArchiveFile({
            projectId,
            name: a.name,
            ext,
            mime: MIME_BY_EXT[ext] || a.mimeType || "application/octet-stream",
            size: r.size,
            storageKey: r.storageKey,
            addedAt: new Date().toISOString(),
            note: "",
          });
          added++;
        } catch (e: any) {
          notify("Yükleme hatası", `${a.name}: ${e?.message || "Bilinmeyen hata"}`);
        }
      }
      if (rejected > 0) {
        notify(
          "Bazı dosyalar atlandı",
          `${rejected} dosya desteklenmeyen uzantıya sahip. Yalnızca .pdf, .dwg, .xlsx ve .xls kabul edilir.`
        );
      }
      if (added > 0 && rejected === 0) {
        // sessiz başarı
      }
    } catch (e: any) {
      notify("Hata", e?.message || "Dosya seçilirken bir hata oluştu.");
    } finally {
      setBusy(false);
    }
  }

  async function handleOpen(f: ArchiveFile) {
    setOpeningId(f.id);
    try {
      await openAsset(f.storageKey, f.name, f.mime);
    } catch (e: any) {
      notify("Açma hatası", e?.message || "Dosya açılamadı.");
    } finally {
      setOpeningId(null);
    }
  }

  function handleDelete(f: ArchiveFile) {
    if (!canEdit) return;
    Alert.alert(
      "Dosyayı Sil",
      `"${f.name}" arşivden ve depolamadan kalıcı olarak silinecek. Devam edilsin mi?`,
      [
        { text: "Vazgeç", style: "cancel" },
        {
          text: "Sil",
          style: "destructive",
          onPress: async () => {
            await deleteAsset(f.storageKey);
            deleteArchiveFile(f.id);
            setEditFile(null);
          },
        },
      ]
    );
  }

  function openEdit(f: ArchiveFile) {
    setEditFile(f);
    setEditNote(f.note || "");
  }

  function saveEdit() {
    if (!editFile) return;
    updateArchiveFile(editFile.id, { note: editNote.trim() });
    setEditFile(null);
  }

  const noProjects = projects.length === 0;

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <Header
        title="Dosyalar"
        subtitle="PDF · DWG · Excel"
        onBack={() => (router.canGoBack() ? router.back() : router.replace("/" as any))}
        rightAction={canEdit && !noProjects ? { icon: "upload", onPress: handlePick } : undefined}
      />

      {noProjects ? (
        <EmptyState
          icon="folder"
          title="Önce proje oluşturun"
          description="Dosya yükleyebilmek için sistemde en az bir proje bulunmalıdır."
          actionLabel="Projelere Git"
          onAction={() => router.push("/proje" as any)}
        />
      ) : (
        <>
          <View style={[styles.topBar, { backgroundColor: colors.card, borderBottomColor: colors.border }]}>
            <ProjectPicker
              projects={projects}
              value={projectId || null}
              onChange={(v) => setProjectId(v ?? "")}
              includeAll={false}
            />

            <View style={styles.statsRow}>
              <View style={[styles.statCell, { backgroundColor: colors.muted }]}>
                <Text style={[styles.statN, { color: colors.foreground }]}>{totals.count}</Text>
                <Text style={[styles.statL, { color: colors.mutedForeground }]}>Dosya</Text>
              </View>
              <View style={[styles.statCell, { backgroundColor: colors.muted }]}>
                <Text style={[styles.statN, { color: colors.foreground }]}>{totals.pdf}</Text>
                <Text style={[styles.statL, { color: colors.mutedForeground }]}>PDF</Text>
              </View>
              <View style={[styles.statCell, { backgroundColor: colors.muted }]}>
                <Text style={[styles.statN, { color: colors.foreground }]}>{totals.dwg}</Text>
                <Text style={[styles.statL, { color: colors.mutedForeground }]}>DWG</Text>
              </View>
              <View style={[styles.statCell, { backgroundColor: colors.muted }]}>
                <Text style={[styles.statN, { color: colors.foreground }]}>{totals.xls}</Text>
                <Text style={[styles.statL, { color: colors.mutedForeground }]}>EXCEL</Text>
              </View>
              <View style={[styles.statCell, { backgroundColor: colors.muted }]}>
                <Text style={[styles.statN, { color: colors.foreground }]}>{formatBytes(totals.size)}</Text>
                <Text style={[styles.statL, { color: colors.mutedForeground }]}>Boyut</Text>
              </View>
            </View>

            <View style={styles.filterRow}>
              <View style={[styles.searchBox, { backgroundColor: colors.muted, flex: 1 }]}>
                <Feather name="search" size={14} color={colors.mutedForeground} />
                <TextInput
                  value={search}
                  onChangeText={setSearch}
                  placeholder="Dosya ara..."
                  placeholderTextColor={colors.mutedForeground}
                  style={[styles.searchInput, { color: colors.foreground }]}
                />
                {search ? (
                  <TouchableOpacity onPress={() => setSearch("")} hitSlop={8}>
                    <Feather name="x" size={14} color={colors.mutedForeground} />
                  </TouchableOpacity>
                ) : null}
              </View>

              {(["all", "pdf", "dwg", "excel"] as const).map((k) => (
                <TouchableOpacity
                  key={k}
                  onPress={() => setExtFilter(k)}
                  style={[
                    styles.chip,
                    {
                      backgroundColor: extFilter === k ? colors.primary : colors.muted,
                    },
                  ]}
                  activeOpacity={0.85}
                >
                  <Text
                    style={[
                      styles.chipText,
                      { color: extFilter === k ? "#fff" : colors.foreground },
                    ]}
                  >
                    {k === "all" ? "Tümü" : k.toUpperCase()}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>

            {canEdit ? (
              <TouchableOpacity
                onPress={handlePick}
                disabled={busy}
                style={[styles.uploadBtn, { backgroundColor: colors.primary, opacity: busy ? 0.6 : 1 }]}
                activeOpacity={0.85}
              >
                {busy ? (
                  <ActivityIndicator color="#fff" size="small" />
                ) : (
                  <Feather name="upload" size={16} color="#fff" />
                )}
                <Text style={styles.uploadBtnText}>
                  {busy ? "Yükleniyor..." : "Dosya Yükle (PDF / DWG / Excel)"}
                </Text>
              </TouchableOpacity>
            ) : null}
          </View>

          {filtered.length === 0 ? (
            <EmptyState
              icon="folder"
              title={search || extFilter !== "all" ? "Sonuç yok" : "Arşiv boş"}
              description={
                search || extFilter !== "all"
                  ? "Arama kriterine uyan dosya bulunamadı."
                  : canEdit
                  ? "Üstteki 'Dosya Yükle' düğmesi ile bu projeye .pdf, .dwg, .xlsx veya .xls dosyaları ekleyebilirsiniz."
                  : "Bu projede henüz arşivlenmiş dosya yok."
              }
            />
          ) : (
            <FlatList
              data={filtered}
              keyExtractor={(f) => f.id}
              contentContainerStyle={styles.list}
              renderItem={({ item }) => {
                const opening = openingId === item.id;
                const color = EXT_COLOR[item.ext] || "#475569";
                const label = item.ext === "xlsx" || item.ext === "xls" ? "XLS" : item.ext.toUpperCase();
                return (
                  <TouchableOpacity
                    style={[styles.card, { backgroundColor: colors.card }]}
                    activeOpacity={0.85}
                    onPress={() => handleOpen(item)}
                    onLongPress={canEdit ? () => openEdit(item) : undefined}
                  >
                    <View style={[styles.fileIcon, { backgroundColor: color + "22" }]}>
                      {opening ? (
                        <ActivityIndicator size="small" color={color} />
                      ) : (
                        <Text style={[styles.fileExt, { color }]}>
                          {label}
                        </Text>
                      )}
                    </View>
                    <View style={{ flex: 1, minWidth: 0 }}>
                      <Text style={[styles.fileName, { color: colors.foreground }]} numberOfLines={2}>
                        {item.name}
                      </Text>
                      <View style={styles.metaRow}>
                        <Feather name="hard-drive" size={11} color={colors.mutedForeground} />
                        <Text style={[styles.meta, { color: colors.mutedForeground }]}>
                          {formatBytes(item.size)}
                        </Text>
                        <Feather name="calendar" size={11} color={colors.mutedForeground} style={{ marginLeft: 8 }} />
                        <Text style={[styles.meta, { color: colors.mutedForeground }]}>
                          {fmtDate(item.addedAt)}
                        </Text>
                      </View>
                      {item.note ? (
                        <Text style={[styles.note, { color: colors.mutedForeground }]} numberOfLines={2}>
                          {item.note}
                        </Text>
                      ) : null}
                    </View>
                    <View style={styles.actions}>
                      <TouchableOpacity
                        onPress={() => handleOpen(item)}
                        style={[styles.actionBtn, { backgroundColor: colors.muted }]}
                        hitSlop={6}
                      >
                        <Feather name="external-link" size={14} color={colors.foreground} />
                      </TouchableOpacity>
                      {canEdit ? (
                        <TouchableOpacity
                          onPress={() => openEdit(item)}
                          style={[styles.actionBtn, { backgroundColor: colors.muted }]}
                          hitSlop={6}
                        >
                          <Feather name="more-horizontal" size={14} color={colors.foreground} />
                        </TouchableOpacity>
                      ) : null}
                    </View>
                  </TouchableOpacity>
                );
              }}
            />
          )}
        </>
      )}

      <BottomSheet
        visible={!!editFile}
        onClose={() => setEditFile(null)}
        title={editFile?.name || "Dosya"}
      >
        {editFile ? (
          <>
            <View style={[styles.detailBox, { backgroundColor: colors.muted }]}>
              <View style={styles.detailRow}>
                <Feather name="file" size={13} color={colors.mutedForeground} />
                <Text style={[styles.detailLabel, { color: colors.mutedForeground }]}>Tür:</Text>
                <Text style={[styles.detailVal, { color: colors.foreground }]}>
                  {editFile.ext.toUpperCase()}
                </Text>
              </View>
              <View style={styles.detailRow}>
                <Feather name="hard-drive" size={13} color={colors.mutedForeground} />
                <Text style={[styles.detailLabel, { color: colors.mutedForeground }]}>Boyut:</Text>
                <Text style={[styles.detailVal, { color: colors.foreground }]}>
                  {formatBytes(editFile.size)}
                </Text>
              </View>
              <View style={styles.detailRow}>
                <Feather name="calendar" size={13} color={colors.mutedForeground} />
                <Text style={[styles.detailLabel, { color: colors.mutedForeground }]}>Yüklenme:</Text>
                <Text style={[styles.detailVal, { color: colors.foreground }]}>
                  {fmtDate(editFile.addedAt)}
                </Text>
              </View>
            </View>

            <FormInput
              label="Not"
              value={editNote}
              onChangeText={setEditNote}
              placeholder="Açıklama (opsiyonel)"
              multiline
              style={{ height: 80, textAlignVertical: "top" }}
            />

            <PrimaryButton
              label="Aç / İndir"
              onPress={() => {
                const f = editFile;
                setEditFile(null);
                if (f) handleOpen(f);
              }}
              style={{ marginTop: 8 }}
            />
            {canEdit ? (
              <PrimaryButton
                label="Notu Kaydet"
                variant="secondary"
                onPress={saveEdit}
                style={{ marginTop: 10 }}
              />
            ) : null}
            {canEdit ? (
              <PrimaryButton
                label="Sil"
                variant="danger"
                onPress={() => handleDelete(editFile)}
                style={{ marginTop: 10 }}
              />
            ) : null}
          </>
        ) : null}
      </BottomSheet>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  topBar: { padding: 12, gap: 10, borderBottomWidth: StyleSheet.hairlineWidth },
  statsRow: { flexDirection: "row", gap: 6 },
  statCell: { flex: 1, paddingVertical: 8, borderRadius: 10, alignItems: "center" },
  statN: { fontSize: 14, fontFamily: "Inter_700Bold" },
  statL: { fontSize: 10, fontFamily: "Inter_500Medium", marginTop: 2 },
  filterRow: { flexDirection: "row", alignItems: "center", gap: 6 },
  searchBox: { flexDirection: "row", alignItems: "center", gap: 8, paddingHorizontal: 12, height: 36, borderRadius: 10 },
  searchInput: { flex: 1, fontSize: 13, fontFamily: "Inter_400Regular", paddingVertical: 0 },
  chip: { paddingHorizontal: 12, height: 36, borderRadius: 999, justifyContent: "center" },
  chipText: { fontSize: 12, fontFamily: "Inter_600SemiBold" },
  uploadBtn: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 8,
    height: 42,
    borderRadius: 10,
  },
  uploadBtnText: { color: "#fff", fontSize: 14, fontFamily: "Inter_600SemiBold" },
  list: { padding: 12, gap: 10 },
  card: {
    borderRadius: 12,
    padding: 12,
    flexDirection: "row",
    gap: 10,
    alignItems: "center",
    marginBottom: 10,
  },
  fileIcon: {
    width: 48,
    height: 48,
    borderRadius: 10,
    alignItems: "center",
    justifyContent: "center",
  },
  fileExt: { fontSize: 12, fontFamily: "Inter_700Bold" },
  fileName: { fontSize: 14, fontFamily: "Inter_600SemiBold", marginBottom: 4 },
  metaRow: { flexDirection: "row", alignItems: "center", gap: 4, flexWrap: "wrap" },
  meta: { fontSize: 11, fontFamily: "Inter_500Medium" },
  note: { fontSize: 12, fontFamily: "Inter_400Regular", marginTop: 4 },
  actions: { flexDirection: "row", gap: 6 },
  actionBtn: { width: 32, height: 32, borderRadius: 8, alignItems: "center", justifyContent: "center" },
  detailBox: { borderRadius: 10, padding: 12, marginBottom: 12, gap: 8 },
  detailRow: { flexDirection: "row", alignItems: "center", gap: 8 },
  detailLabel: { fontSize: 12, fontFamily: "Inter_500Medium", minWidth: 70 },
  detailVal: { fontSize: 13, fontFamily: "Inter_600SemiBold", flex: 1 },
});
