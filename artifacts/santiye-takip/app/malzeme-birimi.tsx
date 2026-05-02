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
import { useI18n } from "@/context/I18nContext";
import { useColors } from "@/hooks/useColors";

export default function MalzemeBirimiScreen() {
  const colors = useColors();
  const router = useRouter();
  const { t } = useI18n();
  const {
    materialUnits,
    addMaterialUnit,
    deleteMaterialUnit,
    materialList,
    materials,
    materialRequests,
    materialMovements,
    currentRole,
  } = useApp();
  const isAdmin = currentRole?.isAdmin === true;
  const insets = useSafeAreaInsets();
  const topPad = Platform.OS === "web" ? 16 : insets.top;
  const [code, setCode] = useState("");
  const [label, setLabel] = useState("");

  function handleAdd() {
    const c = code.trim().toUpperCase();
    const l = label.trim() || c;
    if (!c) return;
    if (materialUnits.some((u) => u.code.toUpperCase() === c)) {
      Alert.alert(t("settings.matUnit.title"), t("settings.matUnit.exists"));
      return;
    }
    addMaterialUnit({ code: c, label: l });
    setCode("");
    setLabel("");
  }

  function handleDelete(c: string) {
    const refs =
      materialList.filter((m) => (m.defaultUnit || "").toUpperCase() === c.toUpperCase()).length +
      materials.filter((m) => (m.unit || "").toUpperCase() === c.toUpperCase()).length +
      materialRequests.filter((m) => (m.unit || "").toUpperCase() === c.toUpperCase()).length +
      materialMovements.filter((m) => (m.unit || "").toUpperCase() === c.toUpperCase()).length;
    const msg =
      t("settings.matUnit.confirmDelete").replace("{name}", c) +
      (refs > 0 ? "\n\n" + t("settings.refWarn").replace("{count}", String(refs)) : "");
    Alert.alert(t("common.delete"), msg, [
      { text: t("common.cancel"), style: "cancel" },
      { text: t("common.delete"), style: "destructive", onPress: () => deleteMaterialUnit(c) },
    ]);
  }

  if (!isAdmin) {
    return (
      <View style={[styles.root, { backgroundColor: colors.background, alignItems: "center", justifyContent: "center", padding: 24 }]}>
        <Text style={{ color: colors.mutedForeground, textAlign: "center" }}>{t("settings.adminOnly")}</Text>
        <TouchableOpacity onPress={() => router.back()} style={{ marginTop: 16 }}>
          <Text style={{ color: colors.primary, fontFamily: "Inter_600SemiBold" }}>{t("common.back")}</Text>
        </TouchableOpacity>
      </View>
    );
  }

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <View style={[styles.header, { backgroundColor: colors.secondary, paddingTop: topPad + 12 }]}>
        <TouchableOpacity
          onPress={() => (router.canGoBack() ? router.back() : router.replace("/" as any))}
          style={styles.backBtn}
          accessibilityLabel={t("common.back")}
        >
          <Feather name="arrow-left" size={22} color={colors.secondaryForeground} />
        </TouchableOpacity>
        <Text style={[styles.headerTitle, { color: colors.secondaryForeground }]}>
          {t("settings.matUnit.title")}
        </Text>
        <View style={{ width: 40 }} />
      </View>

      <View style={[styles.addBar, { backgroundColor: colors.card, borderColor: colors.border }]}>
        <TextInput
          value={code}
          onChangeText={setCode}
          placeholder={t("settings.matUnit.codePlaceholder")}
          placeholderTextColor={colors.mutedForeground}
          autoCapitalize="characters"
          style={[styles.inputCode, { color: colors.foreground, borderColor: colors.border, backgroundColor: colors.background }]}
        />
        <TextInput
          value={label}
          onChangeText={setLabel}
          placeholder={t("settings.matUnit.labelPlaceholder")}
          placeholderTextColor={colors.mutedForeground}
          style={[styles.inputLabel, { color: colors.foreground, borderColor: colors.border, backgroundColor: colors.background }]}
        />
        <PrimaryButton label={t("common.add")} onPress={handleAdd} />
      </View>

      <FlatList
        data={materialUnits}
        keyExtractor={(item) => item.code}
        contentContainerStyle={{ padding: 16, paddingBottom: insets.bottom + 24 }}
        ListEmptyComponent={
          <Text style={{ color: colors.mutedForeground, textAlign: "center", marginTop: 24 }}>
            {t("settings.matUnit.empty")}
          </Text>
        }
        renderItem={({ item }) => (
          <View style={[styles.row, { backgroundColor: colors.card, borderColor: colors.border }]}>
            <View style={{ flex: 1 }}>
              <Text style={[styles.code, { color: colors.foreground }]}>{item.code}</Text>
              {item.label && item.label !== item.code ? (
                <Text style={[styles.label, { color: colors.mutedForeground }]}>{item.label}</Text>
              ) : null}
            </View>
            <TouchableOpacity
              onPress={() => handleDelete(item.code)}
              style={[styles.delBtn, { backgroundColor: "#ef4444" + "15" }]}
              accessibilityLabel={t("common.delete")}
            >
              <Feather name="trash-2" size={18} color="#ef4444" />
            </TouchableOpacity>
          </View>
        )}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  header: { flexDirection: "row", alignItems: "center", paddingHorizontal: 12, paddingBottom: 14, gap: 8 },
  backBtn: { width: 40, height: 40, borderRadius: 20, alignItems: "center", justifyContent: "center" },
  headerTitle: { flex: 1, fontSize: 18, fontWeight: "700", textAlign: "center", fontFamily: "Inter_700Bold" },
  addBar: { flexDirection: "row", gap: 8, padding: 12, alignItems: "center", borderBottomWidth: 1, flexWrap: "wrap" },
  inputCode: { width: 90, height: 42, borderWidth: 1, borderRadius: 10, paddingHorizontal: 10, fontSize: 14, fontFamily: "Inter_700Bold" },
  inputLabel: { flex: 1, minWidth: 140, height: 42, borderWidth: 1, borderRadius: 10, paddingHorizontal: 12, fontSize: 14, fontFamily: "Inter_400Regular" },
  row: { flexDirection: "row", alignItems: "center", padding: 14, marginBottom: 8, borderRadius: 12, borderWidth: 1 },
  code: { fontSize: 15, fontFamily: "Inter_700Bold" },
  label: { fontSize: 12, fontFamily: "Inter_400Regular", marginTop: 2 },
  delBtn: { width: 36, height: 36, borderRadius: 18, alignItems: "center", justifyContent: "center" },
});
