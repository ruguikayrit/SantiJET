import { Feather } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import React, { useState } from "react";
import {
  Alert,
  FlatList,
  Platform,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import PrimaryButton from "@/components/PrimaryButton";
import { useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";

export default function MeslekGrubuScreen() {
  const colors = useColors();
  const router = useRouter();
  const {
    tradeGroups,
    addTradeGroup,
    updateTradeGroup,
    deleteTradeGroup,
    moveTradeGroup,
    resetTradeGroups,
    currentRole,
  } = useApp();
  const isAdmin = currentRole?.isAdmin === true;
  const insets = useSafeAreaInsets();
  const topPad = Platform.OS === "web" ? 16 : insets.top;
  const [newName, setNewName] = useState("");
  const [editName, setEditName] = useState<string | null>(null);
  const [editValue, setEditValue] = useState("");

  function handleAdd() {
    const name = newName.trim();
    if (!name) return;
    if (tradeGroups.some((p) => p.toLowerCase() === name.toLowerCase())) {
      Alert.alert("Meslek Grubu", "Bu grup zaten var.");
      return;
    }
    addTradeGroup(name);
    setNewName("");
  }

  function startEdit(name: string) {
    setEditName(name);
    setEditValue(name);
  }

  function saveEdit() {
    if (!editName) return;
    const v = editValue.trim();
    if (!v) return;
    if (v !== editName && tradeGroups.some((p) => p.toLowerCase() === v.toLowerCase())) {
      Alert.alert("Meslek Grubu", "Bu grup zaten var.");
      return;
    }
    updateTradeGroup(editName, v);
    setEditName(null);
    setEditValue("");
  }

  function handleDelete(name: string) {
    Alert.alert("Sil", `"${name}" grubunu silmek istediğinize emin misiniz?`, [
      { text: "Vazgeç", style: "cancel" },
      { text: "Sil", style: "destructive", onPress: () => deleteTradeGroup(name) },
    ]);
  }

  function handleReset() {
    Alert.alert(
      "Varsayılana Dön",
      "Tüm meslek grubu listesi varsayılan inşaat gruplarına (Kalıp, Demir, Duvar, Çelik vb.) sıfırlanacak. Devam edilsin mi?",
      [
        { text: "Vazgeç", style: "cancel" },
        { text: "Sıfırla", style: "destructive", onPress: () => resetTradeGroups() },
      ]
    );
  }

  if (!isAdmin) {
    return (
      <View style={[styles.root, { backgroundColor: colors.background, alignItems: "center", justifyContent: "center", padding: 24 }]}>
        <Text style={{ color: colors.mutedForeground, textAlign: "center" }}>Bu sayfa yalnızca yönetici rollerine açıktır.</Text>
        <TouchableOpacity onPress={() => router.back()} style={{ marginTop: 16 }}>
          <Text style={{ color: colors.primary, fontFamily: "Inter_600SemiBold" }}>Geri</Text>
        </TouchableOpacity>
      </View>
    );
  }

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <View
        style={[
          styles.header,
          { backgroundColor: colors.secondary, paddingTop: topPad + 12 },
        ]}
      >
        <TouchableOpacity
          onPress={() => (router.canGoBack() ? router.back() : router.replace("/" as any))}
          style={styles.backBtn}
        >
          <Feather name="arrow-left" size={22} color={colors.secondaryForeground} />
        </TouchableOpacity>
        <Text style={[styles.headerTitle, { color: colors.secondaryForeground }]}>
          Meslek Grubu
        </Text>
        <TouchableOpacity onPress={handleReset} style={styles.backBtn} accessibilityLabel="Varsayılana dön">
          <Feather name="refresh-cw" size={20} color={colors.secondaryForeground} />
        </TouchableOpacity>
      </View>

      <View style={[styles.addBar, { backgroundColor: colors.card, borderColor: colors.border }]}>
        <TextInput
          value={newName}
          onChangeText={setNewName}
          placeholder="Yeni grup (örn: Kalıp, Demir, Duvar...)"
          placeholderTextColor={colors.mutedForeground}
          style={[styles.input, { color: colors.foreground, borderColor: colors.border, backgroundColor: colors.background }]}
          onSubmitEditing={handleAdd}
        />
        <PrimaryButton label="Ekle" onPress={handleAdd} />
      </View>

      <FlatList
        data={tradeGroups}
        keyExtractor={(item) => item}
        contentContainerStyle={{ padding: 16, paddingBottom: insets.bottom + 24 }}
        ListEmptyComponent={
          <View style={{ alignItems: "center", marginTop: 32, gap: 12 }}>
            <Text style={{ color: colors.mutedForeground, textAlign: "center" }}>
              Henüz grup yok. Üstte "Yenile" simgesi ile varsayılan inşaat gruplarını yükleyebilirsiniz.
            </Text>
            <PrimaryButton label="Varsayılan Grupları Yükle" onPress={() => resetTradeGroups()} />
          </View>
        }
        renderItem={({ item, index }) => {
          const isEditing = editName === item;
          const isFirst = index === 0;
          const isLast = index === tradeGroups.length - 1;
          return (
            <View style={[styles.row, { backgroundColor: colors.card, borderColor: colors.border }]}>
              <View style={styles.orderCol}>
                <TouchableOpacity
                  disabled={isFirst}
                  onPress={() => moveTradeGroup(item, -1)}
                  style={[styles.orderBtn, { opacity: isFirst ? 0.3 : 1 }]}
                >
                  <Feather name="chevron-up" size={18} color={colors.foreground} />
                </TouchableOpacity>
                <TouchableOpacity
                  disabled={isLast}
                  onPress={() => moveTradeGroup(item, 1)}
                  style={[styles.orderBtn, { opacity: isLast ? 0.3 : 1 }]}
                >
                  <Feather name="chevron-down" size={18} color={colors.foreground} />
                </TouchableOpacity>
              </View>

              {isEditing ? (
                <TextInput
                  value={editValue}
                  onChangeText={setEditValue}
                  autoFocus
                  onSubmitEditing={saveEdit}
                  style={[styles.editInput, { color: colors.foreground, borderColor: colors.primary, backgroundColor: colors.background }]}
                />
              ) : (
                <Text style={[styles.rowText, { color: colors.foreground }]} numberOfLines={1}>
                  {item}
                </Text>
              )}

              {isEditing ? (
                <>
                  <TouchableOpacity onPress={saveEdit} style={[styles.iconBtn, { backgroundColor: "#16a34a" + "15" }]}>
                    <Feather name="check" size={18} color="#16a34a" />
                  </TouchableOpacity>
                  <TouchableOpacity onPress={() => { setEditName(null); setEditValue(""); }} style={[styles.iconBtn, { backgroundColor: colors.muted }]}>
                    <Feather name="x" size={18} color={colors.foreground} />
                  </TouchableOpacity>
                </>
              ) : (
                <>
                  <TouchableOpacity onPress={() => startEdit(item)} style={[styles.iconBtn, { backgroundColor: colors.primary + "15" }]}>
                    <Feather name="edit-2" size={16} color={colors.primary} />
                  </TouchableOpacity>
                  <TouchableOpacity onPress={() => handleDelete(item)} style={[styles.iconBtn, { backgroundColor: "#ef4444" + "15" }]}>
                    <Feather name="trash-2" size={16} color="#ef4444" />
                  </TouchableOpacity>
                </>
              )}
            </View>
          );
        }}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  header: { flexDirection: "row", alignItems: "center", paddingHorizontal: 12, paddingBottom: 14, gap: 8 },
  backBtn: { width: 40, height: 40, borderRadius: 20, alignItems: "center", justifyContent: "center" },
  headerTitle: { flex: 1, fontSize: 18, fontWeight: "700", textAlign: "center", fontFamily: "Inter_700Bold" },
  addBar: { flexDirection: "row", gap: 10, padding: 12, alignItems: "center", borderBottomWidth: 1 },
  input: { flex: 1, height: 42, borderWidth: 1, borderRadius: 10, paddingHorizontal: 12, fontSize: 14, fontFamily: "Inter_400Regular" },
  row: { flexDirection: "row", alignItems: "center", padding: 10, marginBottom: 8, borderRadius: 12, borderWidth: 1, gap: 8 },
  orderCol: { gap: 2 },
  orderBtn: { width: 28, height: 22, alignItems: "center", justifyContent: "center", borderRadius: 6 },
  rowText: { fontSize: 14, fontFamily: "Inter_600SemiBold", flex: 1 },
  editInput: { flex: 1, height: 38, borderWidth: 1.5, borderRadius: 8, paddingHorizontal: 10, fontSize: 14, fontFamily: "Inter_500Medium" },
  iconBtn: { width: 36, height: 36, borderRadius: 18, alignItems: "center", justifyContent: "center" },
});
