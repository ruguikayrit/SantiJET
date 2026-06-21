import { Feather } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import React, { useState } from "react";
import {
  Alert,
  FlatList,
  KeyboardAvoidingView,
  Modal,
  Platform,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import { KesifImportModal } from "@/components/KesifImportModal";
import { hesaplaKesifToplam, trFmtKesif } from "@/constants/kesif";
import { useKesif } from "@/context/KesifContext";
import { useColors } from "@/hooks/useColors";

const KESIF_COLOR = "#7c3aed";

export default function KesifListScreen() {
  const colors = useColors();
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const topPad = Platform.OS === "web" ? 16 : insets.top;
  const { projects, loaded, createProject, deleteProject } = useKesif();

  const [newVisible, setNewVisible] = useState(false);
  const [importVisible, setImportVisible] = useState(false);
  const [newAd, setNewAd] = useState("");
  const [newAciklama, setNewAciklama] = useState("");

  function openProject(id: string) {
    router.push({ pathname: "/kesif/[id]", params: { id } } as any);
  }

  function handleCreate() {
    if (!newAd.trim()) {
      Alert.alert("Hata", "Proje adı zorunlu");
      return;
    }
    const id = createProject(newAd.trim(), newAciklama.trim());
    setNewVisible(false);
    setNewAd("");
    setNewAciklama("");
    openProject(id);
  }

  function handleDelete(id: string, ad: string) {
    Alert.alert("Keşifi Sil", `"${ad}" silinsin mi?`, [
      { text: "İptal", style: "cancel" },
      { text: "Sil", style: "destructive", onPress: () => deleteProject(id) },
    ]);
  }

  return (
    <View style={{ flex: 1, backgroundColor: colors.background }}>
      <View
        style={[styles.header, { backgroundColor: colors.secondary, paddingTop: topPad + 12 }]}
      >
        <TouchableOpacity onPress={() => router.back()} style={styles.backBtn}>
          <Feather name="arrow-left" size={22} color={colors.secondaryForeground} />
        </TouchableOpacity>
        <View style={{ flex: 1, alignItems: "center" }}>
          <Text style={[styles.headerTitle, { color: colors.secondaryForeground }]}>Keşif</Text>
          <Text style={[styles.headerSub, { color: colors.secondaryForeground + "aa" }]}>
            Metraj cetveli ve proje toplamı
          </Text>
        </View>
        <TouchableOpacity
          onPress={() => setImportVisible(true)}
          style={styles.backBtn}
          accessibilityLabel="Keşif içe aktar"
        >
          <Feather name="upload" size={20} color={colors.secondaryForeground} />
        </TouchableOpacity>
      </View>

      <FlatList
        data={projects}
        keyExtractor={(item) => item.id}
        contentContainerStyle={{ padding: 12, paddingBottom: insets.bottom + 80, flexGrow: 1 }}
        ListEmptyComponent={
          <View style={styles.empty}>
            <Feather name="clipboard" size={44} color={colors.mutedForeground} />
            <Text style={[styles.emptyTitle, { color: colors.foreground }]}>Henüz keşif yok</Text>
            <Text style={[styles.emptySub, { color: colors.mutedForeground }]}>
              Excel dosyasından içe aktarabilir veya yeni keşif oluşturup katalogdan poz ekleyebilirsiniz.
            </Text>
            <TouchableOpacity
              style={[styles.emptyImportBtn, { borderColor: KESIF_COLOR, backgroundColor: KESIF_COLOR + "12" }]}
              onPress={() => setImportVisible(true)}
              activeOpacity={0.85}
            >
              <Feather name="upload" size={16} color={KESIF_COLOR} />
              <Text style={[styles.emptyImportBtnText, { color: KESIF_COLOR }]}>Excel&apos;den İçe Aktar</Text>
            </TouchableOpacity>
          </View>
        }
        renderItem={({ item }) => {
          const toplam = hesaplaKesifToplam(item.satirlar);
          const tarih = new Date(item.guncellemeTarihi).toLocaleDateString("tr-TR");
          return (
            <TouchableOpacity
              style={[styles.card, { backgroundColor: colors.card, borderColor: colors.border }]}
              onPress={() => openProject(item.id)}
              onLongPress={() => handleDelete(item.id, item.ad)}
              activeOpacity={0.85}
            >
              <View style={[styles.cardIcon, { backgroundColor: KESIF_COLOR + "18" }]}>
                <Feather name="file-text" size={20} color={KESIF_COLOR} />
              </View>
              <View style={styles.cardBody}>
                <Text style={[styles.cardTitle, { color: colors.foreground }]} numberOfLines={1}>
                  {item.ad}
                </Text>
                <Text style={[styles.cardMeta, { color: colors.mutedForeground }]}>
                  {item.satirlar.length} poz · {tarih}
                </Text>
                <Text style={[styles.cardTotal, { color: KESIF_COLOR }]}>
                  {trFmtKesif(toplam)} TL
                </Text>
              </View>
              <Feather name="chevron-right" size={18} color={colors.mutedForeground} />
            </TouchableOpacity>
          );
        }}
      />

      <TouchableOpacity
        style={[styles.fab, { backgroundColor: KESIF_COLOR, bottom: insets.bottom + 16 }]}
        onPress={() => setNewVisible(true)}
      >
        <Feather name="plus" size={24} color="#fff" />
      </TouchableOpacity>

      <Modal visible={newVisible} transparent animationType="fade" onRequestClose={() => setNewVisible(false)}>
        <KeyboardAvoidingView
          style={styles.modalHost}
          behavior={Platform.OS === "ios" ? "padding" : undefined}
        >
          <TouchableOpacity style={styles.modalBackdrop} activeOpacity={1} onPress={() => setNewVisible(false)} />
          <View style={[styles.modalCard, { backgroundColor: colors.card, borderColor: colors.border }]}>
            <Text style={[styles.modalTitle, { color: colors.foreground }]}>Yeni Keşif</Text>
            <Text style={[styles.modalLabel, { color: colors.mutedForeground }]}>Proje Adı</Text>
            <TextInput
              style={[styles.modalInput, { color: colors.foreground, borderColor: colors.border }]}
              value={newAd}
              onChangeText={setNewAd}
              placeholder="ör. A Blok İnşaat Keşfi"
              placeholderTextColor={colors.mutedForeground}
              autoFocus
            />
            <Text style={[styles.modalLabel, { color: colors.mutedForeground }]}>Açıklama (isteğe bağlı)</Text>
            <TextInput
              style={[styles.modalInput, { color: colors.foreground, borderColor: colors.border }]}
              value={newAciklama}
              onChangeText={setNewAciklama}
              placeholder="Kısa not"
              placeholderTextColor={colors.mutedForeground}
            />
            <View style={styles.modalBtns}>
              <TouchableOpacity
                style={[styles.modalBtn, { backgroundColor: colors.border }]}
                onPress={() => setNewVisible(false)}
              >
                <Text style={{ color: colors.foreground }}>İptal</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.modalBtn, { backgroundColor: KESIF_COLOR }]}
                onPress={handleCreate}
              >
                <Text style={{ color: "#fff", fontFamily: "Inter_700Bold" }}>Oluştur</Text>
              </TouchableOpacity>
            </View>
          </View>
        </KeyboardAvoidingView>
      </Modal>

      <KesifImportModal
        visible={importVisible}
        onClose={() => setImportVisible(false)}
        onImported={(projectId) => {
          setImportVisible(false);
          openProject(projectId);
        }}
      />

      {!loaded && (
        <View style={styles.loadingOverlay}>
          <Text style={{ color: colors.mutedForeground }}>Yükleniyor…</Text>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  header: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 12,
    paddingBottom: 14,
    gap: 8,
  },
  backBtn: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: "center",
    justifyContent: "center",
  },
  headerTitle: {
    fontSize: 17,
    fontFamily: "Inter_700Bold",
  },
  headerSub: {
    fontSize: 11,
    fontFamily: "Inter_400Regular",
    marginTop: 2,
  },
  card: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    padding: 14,
    borderRadius: 12,
    borderWidth: 1,
    marginBottom: 10,
  },
  cardIcon: {
    width: 42,
    height: 42,
    borderRadius: 21,
    alignItems: "center",
    justifyContent: "center",
  },
  cardBody: { flex: 1, gap: 3 },
  cardTitle: { fontSize: 15, fontFamily: "Inter_700Bold" },
  cardMeta: { fontSize: 11, fontFamily: "Inter_400Regular" },
  cardTotal: { fontSize: 14, fontFamily: "Inter_700Bold", marginTop: 2 },
  empty: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: 32,
    paddingTop: 80,
    gap: 10,
  },
  emptyTitle: { fontSize: 17, fontFamily: "Inter_700Bold" },
  emptySub: { fontSize: 13, fontFamily: "Inter_400Regular", textAlign: "center", lineHeight: 20 },
  emptyImportBtn: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    marginTop: 8,
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 10,
    borderWidth: 1,
  },
  emptyImportBtnText: { fontSize: 14, fontFamily: "Inter_600SemiBold" },
  fab: {
    position: "absolute",
    right: 20,
    width: 52,
    height: 52,
    borderRadius: 26,
    alignItems: "center",
    justifyContent: "center",
    elevation: 4,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.2,
    shadowRadius: 4,
  },
  modalHost: { flex: 1, justifyContent: "center", padding: 24 },
  modalBackdrop: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "rgba(15,23,42,0.45)",
  },
  modalCard: {
    borderRadius: 16,
    borderWidth: 1,
    padding: 18,
    gap: 8,
  },
  modalTitle: { fontSize: 17, fontFamily: "Inter_700Bold", marginBottom: 4 },
  modalLabel: { fontSize: 11, fontFamily: "Inter_600SemiBold", textTransform: "uppercase" },
  modalInput: {
    borderWidth: 1,
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 10,
    fontSize: 14,
    fontFamily: "Inter_400Regular",
    marginBottom: 4,
  },
  modalBtns: { flexDirection: "row", gap: 10, marginTop: 8 },
  modalBtn: {
    flex: 1,
    paddingVertical: 12,
    borderRadius: 10,
    alignItems: "center",
  },
  loadingOverlay: {
    ...StyleSheet.absoluteFillObject,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: "rgba(255,255,255,0.6)",
  },
});
