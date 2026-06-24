import { Feather } from "@expo/vector-icons";
import React, { useState } from "react";
import {
  ActivityIndicator,
  Alert,
  KeyboardAvoidingView,
  Modal,
  Platform,
  Pressable,
  ScrollView,
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
  KesifImportResolvedRow,
  KesifImportValidationResult,
  ValidatedImportRow,
  buildCatalogAnalizFromImportRow,
  defaultImportProjectName,
  mergeImportRowsByPoz,
  parseKesifImportContent,
  pickKesifImportFile,
  readKesifImportFile,
  resolveTypoImportRows,
  truncateImportText,
  validateImportRows,
  validationToResolved,
} from "@/lib/kesifImport";
import type { KesifImportRow } from "@/lib/kesifImport";

const KESIF_COLOR = "#7c3aed";

interface KesifImportModalProps {
  visible: boolean;
  onClose: () => void;
  onImported: (projectId: string) => void;
  /** Verilirse yeni proje oluşturmak yerine mevcut keşife aktarılır. */
  projectId?: string;
}

type ReviewMode = "poz_typo" | "both_missing";

interface PendingImportContext {
  fileName: string;
  projectAciklama?: string;
  validation: KesifImportValidationResult;
  resolved: KesifImportResolvedRow[];
}

export function KesifImportModal({ visible, onClose, onImported, projectId }: KesifImportModalProps) {
  const colors = useColors();
  const { addPozAnaliz } = useApp();
  const { createProject, importSatirlar } = useKesif();
  const { all: catalog } = useBfaCatalog();

  const [busy, setBusy] = useState(false);
  const [namePromptVisible, setNamePromptVisible] = useState(false);
  const [projectName, setProjectName] = useState("");
  const [reviewVisible, setReviewVisible] = useState(false);
  const [reviewMode, setReviewMode] = useState<ReviewMode>("poz_typo");
  const [pendingContext, setPendingContext] = useState<PendingImportContext | null>(null);
  const [pendingImport, setPendingImport] = useState<{
    resolved: KesifImportResolvedRow[];
    bothMissing: KesifImportRow[];
    projectAciklama?: string;
    fileName: string;
    addUnmatchedToCatalog: boolean;
  } | null>(null);

  function resetState() {
    setBusy(false);
    setNamePromptVisible(false);
    setProjectName("");
    setReviewVisible(false);
    setPendingContext(null);
    setPendingImport(null);
  }

  function handleClose() {
    if (busy) return;
    resetState();
    onClose();
  }

  async function finalizeImport(
    resolved: KesifImportResolvedRow[],
    bothMissing: KesifImportRow[],
    addUnmatchedToCatalog: boolean,
    projectAciklama: string | undefined,
    ad: string,
  ) {
    const importItems: KesifImportResolvedRow[] = [...resolved];
    let catalogAdded = 0;

    if (addUnmatchedToCatalog && bothMissing.length) {
      for (const row of bothMissing) {
        const payload = buildCatalogAnalizFromImportRow(row);
        const id = addPozAnaliz(payload);
        if (!id) continue;
        const created = {
          ...payload,
          id,
          olusturmaTarihi: "",
          guncellemeTarihi: "",
        };
        importItems.push({ row, analiz: created });
        catalogAdded += 1;
      }
    }

    if (!importItems.length) {
      Alert.alert(
        "İçe Aktarma İptal",
        bothMissing.length
          ? "İçe aktarılacak eşleşen poz kalmadı. Hatalı satırlar kataloğa eklenmedi."
          : "İçe aktarılacak geçerli satır yok.",
      );
      return;
    }

    const skipped = bothMissing.length - catalogAdded;
    const targetProjectId = projectId || createProject(ad, projectAciklama ?? "");
    if (!targetProjectId) {
      Alert.alert("Hata", projectId ? "Keşif bulunamadı." : "Keşif projesi oluşturulamadı.");
      return;
    }

    importSatirlar(
      targetProjectId,
      importItems.map(({ row, analiz }) => ({ analiz, miktar: row.miktar })),
    );

    resetState();
    onClose();
    onImported(targetProjectId);

    const lines = [`${importItems.length} poz keşife eklendi.`];
    if (catalogAdded > 0) lines.push(`${catalogAdded} yeni poz kataloğa eklendi.`);
    if (skipped > 0) lines.push(`${skipped} poz atlandı (katalogda eşleşme yok).`);
    Alert.alert("İçe Aktarma Tamamlandı", lines.join("\n"));
  }

  function askProjectName(payload: NonNullable<typeof pendingImport>) {
    const suggested = defaultImportProjectName(payload.fileName, {
      rows: payload.resolved.map((r) => r.row),
      projectName: payload.resolved.find((r) => r.row.projeAdi)?.row.projeAdi,
      projectAciklama: payload.projectAciklama,
      errors: [],
      sourceLabel: payload.fileName,
    });

    setProjectName(suggested);
    setNamePromptVisible(true);
  }

  function proceedAfterCatalogDecision(
    resolved: KesifImportResolvedRow[],
    bothMissing: KesifImportRow[],
    fileName: string,
    projectAciklama: string | undefined,
    addUnmatchedToCatalog: boolean,
  ) {
    const payload = { resolved, bothMissing, fileName, projectAciklama, addUnmatchedToCatalog };
    setPendingImport(payload);

    if (projectId) {
      void finalizeImport(resolved, bothMissing, addUnmatchedToCatalog, projectAciklama, "");
      return;
    }

    const hasProjectColumn = resolved.some((r) => r.row.projeAdi?.trim());
    const suggested = defaultImportProjectName(fileName, {
      rows: resolved.map((r) => r.row),
      projectName: resolved.find((r) => r.row.projeAdi)?.row.projeAdi,
      projectAciklama,
      errors: [],
      sourceLabel: fileName,
    });

    if (hasProjectColumn && suggested) {
      void finalizeImport(resolved, bothMissing, addUnmatchedToCatalog, projectAciklama, suggested);
      return;
    }

    askProjectName(payload);
  }

  function continueAfterTypoFix(context: PendingImportContext) {
    const corrected = resolveTypoImportRows(context.validation.pozTypo);
    const resolved = [...context.resolved, ...corrected];

    if (context.validation.bothMissing.length > 0) {
      setPendingContext({
        ...context,
        resolved,
        validation: { ...context.validation, matched: context.validation.matched, pozTypo: [] },
      });
      setReviewMode("both_missing");
      setReviewVisible(true);
      return;
    }

    proceedAfterCatalogDecision(resolved, [], context.fileName, context.projectAciklama, false);
  }

  function continueAfterMissingReview(context: PendingImportContext, addToCatalog: boolean) {
    setReviewVisible(false);
    const bothMissing = context.validation.bothMissing.map((item) => item.row);
    proceedAfterCatalogDecision(context.resolved, bothMissing, context.fileName, context.projectAciklama, addToCatalog);
  }

  function startValidationFlow(
    rows: ReturnType<typeof mergeImportRowsByPoz>,
    fileName: string,
    projectAciklama?: string,
  ) {
    const validation = validateImportRows(rows, catalog);
    const resolved = validationToResolved(validation);
    const context: PendingImportContext = { fileName, projectAciklama, validation, resolved };

    if (validation.pozTypo.length > 0) {
      setPendingContext(context);
      setReviewMode("poz_typo");
      setReviewVisible(true);
      return;
    }

    if (validation.bothMissing.length > 0) {
      setPendingContext(context);
      setReviewMode("both_missing");
      setReviewVisible(true);
      return;
    }

    proceedAfterCatalogDecision(resolved, [], fileName, projectAciklama, false);
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

      startValidationFlow(rows, picked.name, parsed.projectAciklama);
    } finally {
      setBusy(false);
    }
  }

  function renderTypoReviewItem(item: ValidatedImportRow) {
    const suggested = item.suggestedAnaliz;
    if (!suggested) return null;

    return (
      <View
        key={`${item.row.pozNo}-${item.row.analizAdi}`}
        style={[styles.reviewItem, { borderColor: colors.border, backgroundColor: colors.background }]}
      >
        <Text style={[styles.reviewItemTitle, { color: colors.foreground }]}>
          {truncateImportText(item.row.analizAdi, 80)}
        </Text>
        <View style={styles.reviewCompareRow}>
          <View style={styles.reviewCompareCol}>
            <Text style={[styles.reviewLabel, { color: colors.mutedForeground }]}>Excel Poz No</Text>
            <Text style={[styles.reviewBad, { color: "#dc2626" }]}>{item.row.pozNo}</Text>
          </View>
          <Feather name="arrow-right" size={16} color={KESIF_COLOR} style={{ marginTop: 14 }} />
          <View style={styles.reviewCompareCol}>
            <Text style={[styles.reviewLabel, { color: colors.mutedForeground }]}>Önerilen Poz No</Text>
            <Text style={[styles.reviewGood, { color: KESIF_COLOR }]}>{suggested.pozNo}</Text>
          </View>
        </View>
        <Text style={[styles.reviewHint, { color: colors.mutedForeground }]}>
          Tanım katalogda eşleşti. Poz numarası hatalı olabilir; düzeltme öneriliyor.
        </Text>
      </View>
    );
  }

  function renderMissingReviewItem(item: ValidatedImportRow) {
    return (
      <View
        key={`${item.row.pozNo}-${item.row.analizAdi}`}
        style={[styles.reviewItem, { borderColor: colors.border, backgroundColor: colors.background }]}
      >
        <View style={styles.reviewIssueBlock}>
          <Text style={[styles.reviewLabel, { color: colors.mutedForeground }]}>Poz No — sistemde yok</Text>
          <Text style={[styles.reviewBad, { color: "#dc2626" }]}>{item.row.pozNo}</Text>
        </View>
        <View style={[styles.reviewIssueBlock, { marginTop: 8 }]}>
          <Text style={[styles.reviewLabel, { color: colors.mutedForeground }]}>Tanım — sistemde yok</Text>
          <Text style={[styles.reviewItemTitle, { color: colors.foreground }]}>
            {truncateImportText(item.row.analizAdi, 100)}
          </Text>
        </View>
      </View>
    );
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
              Poz no ve tanım katalogla karşılaştırılır. Hatalı poz numaraları tanıma göre düzeltilir; eşleşmeyen
              satırlar için ayrı uyarı verilir.
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
        visible={reviewVisible && pendingContext !== null}
        transparent
        animationType="fade"
        onRequestClose={() => setReviewVisible(false)}
      >
        <View style={styles.reviewOverlay}>
          <View style={[styles.reviewCard, { backgroundColor: colors.card, borderColor: colors.border }]}>
            {reviewMode === "poz_typo" ? (
              <>
                <Text style={[styles.title, { color: colors.foreground }]}>Poz No Düzeltme Önerisi</Text>
                <Text style={[styles.subtitle, { color: colors.mutedForeground }]}>
                  {pendingContext?.validation.pozTypo.length ?? 0} satırda poz numarası hatalı; tanım katalogda
                  bulundu. Devam etmek için düzeltmeyi onaylayın.
                </Text>
                <ScrollView style={styles.reviewScroll} nestedScrollEnabled>
                  {pendingContext?.validation.pozTypo.map(renderTypoReviewItem)}
                </ScrollView>
                <View style={styles.rowBtns}>
                  <TouchableOpacity
                    style={[styles.rowBtn, { backgroundColor: colors.border }]}
                    onPress={() => {
                      setReviewVisible(false);
                      setPendingContext(null);
                    }}
                  >
                    <Text style={{ color: colors.foreground }}>İptal</Text>
                  </TouchableOpacity>
                  <TouchableOpacity
                    style={[styles.rowBtn, { backgroundColor: KESIF_COLOR }]}
                    onPress={() => {
                      if (!pendingContext) return;
                      setReviewVisible(false);
                      continueAfterTypoFix(pendingContext);
                    }}
                  >
                    <Text style={{ color: "#fff", fontFamily: "Inter_700Bold" }}>Düzelt ve Devam</Text>
                  </TouchableOpacity>
                </View>
              </>
            ) : (
              <>
                <Text style={[styles.title, { color: colors.foreground }]}>Katalogda Bulunamayan Satırlar</Text>
                <Text style={[styles.subtitle, { color: colors.mutedForeground }]}>
                  Aşağıdaki satırlar için hem poz numarası hem tanım sistemde bulunamadı.
                </Text>
                <ScrollView style={styles.reviewScroll} nestedScrollEnabled>
                  {pendingContext?.validation.bothMissing.map(renderMissingReviewItem)}
                </ScrollView>
                <View style={[styles.infoBox, { backgroundColor: "#fef3c7", borderColor: "#f59e0b55" }]}>
                  <Text style={[styles.infoText, { color: "#92400e" }]}>
                    Bu satırlar onay olmadan içe aktarılmaz. Kataloğa eklemek için onay verin veya yalnızca eşleşen
                    pozlarla devam edin.
                  </Text>
                </View>
                <View style={styles.rowBtns}>
                  <TouchableOpacity
                    style={[styles.rowBtn, { backgroundColor: colors.border }]}
                    onPress={() => {
                      setReviewVisible(false);
                      setPendingContext(null);
                    }}
                  >
                    <Text style={{ color: colors.foreground }}>İptal</Text>
                  </TouchableOpacity>
                  <TouchableOpacity
                    style={[styles.rowBtn, { backgroundColor: colors.border }]}
                    onPress={() => {
                      if (!pendingContext) return;
                      continueAfterMissingReview(pendingContext, false);
                    }}
                  >
                    <Text style={{ color: colors.foreground, fontFamily: "Inter_600SemiBold" }}>Atla</Text>
                  </TouchableOpacity>
                  <TouchableOpacity
                    style={[styles.rowBtn, { backgroundColor: KESIF_COLOR }]}
                    onPress={() => {
                      if (!pendingContext) return;
                      continueAfterMissingReview(pendingContext, true);
                    }}
                  >
                    <Text style={{ color: "#fff", fontFamily: "Inter_700Bold" }}>Kataloğa Ekle</Text>
                  </TouchableOpacity>
                </View>
              </>
            )}
          </View>
        </View>
      </Modal>

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
                    pendingImport.resolved,
                    pendingImport.bothMissing,
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
  reviewOverlay: {
    flex: 1,
    backgroundColor: "rgba(15, 23, 42, 0.45)",
    justifyContent: "center",
    padding: 16,
  },
  card: {
    width: "100%",
    maxWidth: 400,
    borderRadius: 16,
    borderWidth: 1,
    padding: 18,
    gap: 12,
  },
  reviewCard: {
    width: "100%",
    maxWidth: 480,
    maxHeight: "88%",
    alignSelf: "center",
    borderRadius: 16,
    borderWidth: 1,
    padding: 18,
    gap: 10,
  },
  reviewScroll: {
    maxHeight: 340,
  },
  reviewItem: {
    borderWidth: 1,
    borderRadius: 10,
    padding: 12,
    marginBottom: 8,
    gap: 6,
  },
  reviewItemTitle: {
    fontSize: 13,
    fontFamily: "Inter_500Medium",
    lineHeight: 18,
  },
  reviewCompareRow: {
    flexDirection: "row",
    alignItems: "flex-start",
    gap: 10,
    marginTop: 4,
  },
  reviewCompareCol: {
    flex: 1,
    gap: 2,
  },
  reviewIssueBlock: {
    gap: 2,
  },
  reviewLabel: {
    fontSize: 10,
    fontFamily: "Inter_600SemiBold",
    textTransform: "uppercase",
    letterSpacing: 0.3,
  },
  reviewBad: {
    fontSize: 14,
    fontFamily: "Inter_700Bold",
  },
  reviewGood: {
    fontSize: 14,
    fontFamily: "Inter_700Bold",
  },
  reviewHint: {
    fontSize: 11,
    fontFamily: "Inter_400Regular",
    lineHeight: 16,
    marginTop: 2,
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
