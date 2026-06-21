import { Feather } from "@expo/vector-icons";
import React, { useState } from "react";
import {
  ActivityIndicator,
  Alert,
  KeyboardAvoidingView,
  Modal,
  Platform,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";

import { useApp } from "@/context/AppContext";
import { useKesif } from "@/context/KesifContext";
import { useBfaCatalog } from "@/hooks/useBfaCatalog";
import { useColors } from "@/hooks/useColors";
import {
  buildCatalogAnalizFromImportRow,
  defaultImportProjectName,
  inferKategoriFromImportRow,
  inferDisciplineFromPoz,
  matchImportRows,
  mergeImportRowsByPoz,
  parseKesifImportContent,
  pickKesifImportFile,
  readKesifImportFile,
} from "@/lib/kesifImport";

const KESIF_COLOR = "#7c3aed";

interface KesifImportModalProps {
  visible: boolean;
  onClose: () => void;
  onImported: (projectId: string) => void;
  /** Verilirse yeni proje oluşturmak yerine mevcut keşife aktarılır. */
  projectId?: string;
}

export function KesifImportModal({ visible, onClose, onImported, projectId }: KesifImportModalProps) {
  const colors = useColors();
  const { addPozAnaliz } = useApp();
  const { createProject, importSatirlar } = useKesif();
  const { all: catalog } = useBfaCatalog();

  const [busy, setBusy] = useState(false);
  const [namePromptVisible, setNamePromptVisible] = useState(false);
  const [projectName, setProjectName] = useState("");
  const [pendingImport, setPendingImport] = useState<{
    rows: ReturnType<typeof mergeImportRowsByPoz>;
    projectAciklama?: string;
    fileName: string;
    addUnmatchedToCatalog: boolean;
  } | null>(null);

  function resetState() {
    setBusy(false);
    setNamePromptVisible(false);
    setProjectName("");
    setPendingImport(null);
  }

  function handleClose() {
    if (busy) return;
    resetState();
    onClose();
  }

  async function finalizeImport(
    rows: ReturnType<typeof mergeImportRowsByPoz>,
    fileName: string,
    addUnmatchedToCatalog: boolean,
    projectAciklama: string | undefined,
    ad: string,
  ) {
    const workingCatalog = [...catalog];
    const catalogByPoz = new Map(workingCatalog.map((a) => [a.pozNo, a]));

    if (addUnmatchedToCatalog) {
      for (const row of rows) {
        const { unmatched } = matchImportRows([row], workingCatalog);
        for (const missing of unmatched) {
          const payload = buildCatalogAnalizFromImportRow(missing);
          const id = addPozAnaliz(payload);
          if (!id) continue;
          const created = { ...payload, id, olusturmaTarihi: "", guncellemeTarihi: "" };
          workingCatalog.push(created as (typeof workingCatalog)[number]);
          catalogByPoz.set(created.pozNo, created as (typeof workingCatalog)[number]);
        }
      }
    }

    const { matched, unmatched } = matchImportRows(rows, workingCatalog);
    if (!matched.length) {
      Alert.alert(
        "İçe Aktarma",
        unmatched.length
          ? "Eşleşen poz bulunamadı. Kataloğa eklemeden devam edilemiyor."
          : "İçe aktarılacak geçerli satır yok.",
      );
      return;
    }

    const skipped = unmatched.length;
    const targetProjectId =
      projectId ||
      createProject(ad, projectAciklama ?? "");
    if (!targetProjectId) {
      Alert.alert("Hata", projectId ? "Keşif bulunamadı." : "Keşif projesi oluşturulamadı.");
      return;
    }

    importSatirlar(
      targetProjectId,
      matched.map(({ row, analiz }) => ({ analiz, miktar: row.miktar })),
    );

    resetState();
    onClose();
    onImported(targetProjectId);

    const lines = [`${matched.length} poz keşife eklendi.`];
    if (addUnmatchedToCatalog && skipped === 0 && unmatched.length === 0) {
      lines.push("Eşleşmeyen pozlar kataloğa eklendi.");
    } else if (skipped > 0) {
      lines.push(`${skipped} poz atlandı (katalogda eşleşme yok).`);
    }
    Alert.alert("İçe Aktarma Tamamlandı", lines.join("\n"));
  }

  function askProjectName(
    payload: NonNullable<typeof pendingImport>,
    addUnmatchedToCatalog: boolean,
  ) {
    const suggested = defaultImportProjectName(payload.fileName, {
      rows: payload.rows,
      projectName: payload.rows.find((r) => r.projeAdi)?.projeAdi,
      projectAciklama: payload.projectAciklama,
      errors: [],
      sourceLabel: payload.fileName,
    });

    setPendingImport({ ...payload, addUnmatchedToCatalog });
    setProjectName(suggested);
    setNamePromptVisible(true);
  }

  function proceedAfterCatalogDecision(
    rows: ReturnType<typeof mergeImportRowsByPoz>,
    fileName: string,
    projectAciklama: string | undefined,
    addUnmatchedToCatalog: boolean,
  ) {
    if (projectId) {
      void finalizeImport(rows, fileName, addUnmatchedToCatalog, projectAciklama, "");
      return;
    }

    const hasProjectColumn = rows.some((r) => r.projeAdi?.trim());
    const suggested = defaultImportProjectName(fileName, {
      rows,
      projectName: rows.find((r) => r.projeAdi)?.projeAdi,
      projectAciklama,
      errors: [],
      sourceLabel: fileName,
    });

    if (hasProjectColumn && suggested) {
      void finalizeImport(rows, fileName, addUnmatchedToCatalog, projectAciklama, suggested);
      return;
    }

    askProjectName({ rows, projectAciklama, fileName, addUnmatchedToCatalog }, addUnmatchedToCatalog);
  }

  function promptCatalogAdd(
    rows: ReturnType<typeof mergeImportRowsByPoz>,
    fileName: string,
    projectAciklama: string | undefined,
    unmatchedCount: number,
  ) {
    const preview = rows
      .filter((row) => !matchImportRows([row], catalog).matched.length)
      .slice(0, 3)
      .map((row) => {
        const discipline = inferDisciplineFromPoz(row.pozNo);
        const kategori = inferKategoriFromImportRow(row.pozNo, row.analizAdi, discipline);
        return `• ${row.pozNo} — ${kategori}`;
      })
      .join("\n");

    Alert.alert(
      "Katalogda Bulunamayan Pozlar",
      `${unmatchedCount} poz katalogda eşleşmedi.\n\n${preview}${unmatchedCount > 3 ? "\n…" : ""}\n\nBu pozlar kataloğa eklensin mi? Uygulama kategori ve disiplini otomatik belirler.`,
      [
        {
          text: "Evet, Kataloğa Ekle",
          onPress: () => proceedAfterCatalogDecision(rows, fileName, projectAciklama, true),
        },
        {
          text: "Hayır, Yalnızca Eşleşenler",
          onPress: () => proceedAfterCatalogDecision(rows, fileName, projectAciklama, false),
        },
        { text: "İptal", style: "cancel" },
      ],
    );
  }

  async function handlePickAndImport() {
    if (busy) return;
    setBusy(true);
    try {
      const picked = await pickKesifImportFile();
      if (!picked) return;

      const content = await readKesifImportFile(picked.uri, picked.name);
      const parsed = parseKesifImportContent(content, picked.name);
      if (parsed.errors.length && !parsed.rows.length) {
        Alert.alert("Dosya Okunamadı", parsed.errors.join("\n"));
        return;
      }

      const rows = mergeImportRowsByPoz(parsed.rows);
      if (!rows.length) {
        Alert.alert("Boş Dosya", "İçe aktarılabilir satır bulunamadı.");
        return;
      }

      const { unmatched } = matchImportRows(rows, catalog);
      if (unmatched.length > 0) {
        promptCatalogAdd(rows, picked.name, parsed.projectAciklama, unmatched.length);
        return;
      }

      proceedAfterCatalogDecision(rows, picked.name, parsed.projectAciklama, false);
    } finally {
      setBusy(false);
    }
  }

  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={handleClose}>
      <Pressable style={styles.overlay} onPress={handleClose}>
        <Pressable
          style={[styles.card, { backgroundColor: colors.card, borderColor: colors.border }]}
          onPress={(e) => e.stopPropagation()}
        >
          <Text style={[styles.title, { color: colors.foreground }]}>Keşif İçe Aktar</Text>
          <Text style={[styles.subtitle, { color: colors.mutedForeground }]}>
            {projectId
              ? "Excel (.xlsx, .xls) ve CSV dosyalarından pozları bu keşife aktarın."
              : "Excel (.xlsx, .xls) ve CSV dosyalarından metraj satırlarını yeni bir keşif projesine aktarın."}
          </Text>

          <View style={[styles.infoBox, { backgroundColor: KESIF_COLOR + "10", borderColor: KESIF_COLOR + "33" }]}>
            <Text style={[styles.infoText, { color: colors.foreground }]}>
              Beklenen sütunlar: Poz No, Tanım/Açıklama, Birim, Miktar. Birim fiyat ve proje adı isteğe bağlıdır.
            </Text>
          </View>

          <TouchableOpacity
            activeOpacity={0.85}
            style={[styles.primaryBtn, { backgroundColor: KESIF_COLOR }]}
            onPress={handlePickAndImport}
            disabled={busy}
          >
            {busy ? (
              <ActivityIndicator color="#fff" />
            ) : (
              <>
                <Feather name="upload" size={18} color="#fff" />
                <Text style={styles.primaryBtnLabel}>Dosya Seç ve İçe Aktar</Text>
              </>
            )}
          </TouchableOpacity>

          <TouchableOpacity
            style={[styles.cancelBtn, { backgroundColor: colors.border }]}
            onPress={handleClose}
            disabled={busy}
          >
            <Text style={{ color: colors.foreground, fontFamily: "Inter_500Medium" }}>Kapat</Text>
          </TouchableOpacity>
        </Pressable>
      </Pressable>

      <Modal
        visible={namePromptVisible}
        transparent
        animationType="fade"
        onRequestClose={() => setNamePromptVisible(false)}
      >
        <KeyboardAvoidingView
          style={styles.overlay}
          behavior={Platform.OS === "ios" ? "padding" : undefined}
        >
          <View style={[styles.card, { backgroundColor: colors.card, borderColor: colors.border }]}>
            <Text style={[styles.title, { color: colors.foreground }]}>Keşif Adı</Text>
            <Text style={[styles.subtitle, { color: colors.mutedForeground }]}>
              İçe aktarılan keşif projesi için bir ad girin.
            </Text>
            <TextInput
              style={[styles.input, { color: colors.foreground, borderColor: colors.border }]}
              value={projectName}
              onChangeText={setProjectName}
              placeholder="Keşif proje adı"
              placeholderTextColor={colors.mutedForeground}
              autoFocus
            />
            <View style={styles.rowBtns}>
              <TouchableOpacity
                style={[styles.rowBtn, { backgroundColor: colors.border }]}
                onPress={() => {
                  setNamePromptVisible(false);
                  setPendingImport(null);
                }}
              >
                <Text style={{ color: colors.foreground }}>İptal</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.rowBtn, { backgroundColor: KESIF_COLOR }]}
                onPress={() => {
                  if (!pendingImport || !projectName.trim()) {
                    Alert.alert("Hata", "Proje adı zorunlu.");
                    return;
                  }
                  setNamePromptVisible(false);
                  void finalizeImport(
                    pendingImport.rows,
                    pendingImport.fileName,
                    pendingImport.addUnmatchedToCatalog,
                    pendingImport.projectAciklama,
                    projectName.trim(),
                  );
                }}
              >
                <Text style={{ color: "#fff", fontFamily: "Inter_700Bold" }}>Oluştur</Text>
              </TouchableOpacity>
            </View>
          </View>
        </KeyboardAvoidingView>
      </Modal>
    </Modal>
  );
}

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: "rgba(15, 23, 42, 0.45)",
    justifyContent: "center",
    alignItems: "center",
    padding: 24,
  },
  card: {
    width: "100%",
    maxWidth: 400,
    borderRadius: 16,
    borderWidth: 1,
    padding: 18,
    gap: 12,
  },
  title: {
    fontSize: 17,
    fontFamily: "Inter_700Bold",
  },
  subtitle: {
    fontSize: 13,
    fontFamily: "Inter_400Regular",
    lineHeight: 19,
  },
  infoBox: {
    borderWidth: 1,
    borderRadius: 10,
    padding: 12,
  },
  infoText: {
    fontSize: 12,
    fontFamily: "Inter_400Regular",
    lineHeight: 18,
  },
  primaryBtn: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 8,
    minHeight: 48,
    borderRadius: 12,
  },
  primaryBtnLabel: {
    color: "#fff",
    fontFamily: "Inter_700Bold",
    fontSize: 14,
  },
  cancelBtn: {
    paddingVertical: 12,
    borderRadius: 10,
    alignItems: "center",
  },
  input: {
    borderWidth: 1,
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 10,
    fontSize: 14,
    fontFamily: "Inter_400Regular",
  },
  rowBtns: {
    flexDirection: "row",
    gap: 10,
    marginTop: 4,
  },
  rowBtn: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 10,
    alignItems: "center",
  },
});
