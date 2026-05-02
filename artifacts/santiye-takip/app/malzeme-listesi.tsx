import { Feather } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import React, { useMemo, useState } from "react";
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

import CategoryPicker from "@/components/CategoryPicker";
import PrimaryButton from "@/components/PrimaryButton";
import UnitPicker from "@/components/UnitPicker";
import { useApp } from "@/context/AppContext";
import { useI18n } from "@/context/I18nContext";
import { useColors } from "@/hooks/useColors";

export default function MalzemeListesiScreen() {
  const colors = useColors();
  const router = useRouter();
  const { t } = useI18n();
  const {
    materialList,
    addMaterialItem,
    deleteMaterialItem,
    materials,
    materialRequests,
    materialMovements,
    currentRole,
  } = useApp();
  const isAdmin = currentRole?.isAdmin === true;
  const insets = useSafeAreaInsets();
  const topPad = Platform.OS === "web" ? 16 : insets.top;
  const [name, setName] = useState("");
  const [category, setCategory] = useState("");
  const [unit, setUnit] = useState("");
  const [search, setSearch] = useState("");
  const [filterCat, setFilterCat] = useState("");

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    return materialList.filter((m) => {
      if (filterCat && m.category !== filterCat) return false;
      if (!q) return true;
      return (
        m.name.toLowerCase().includes(q) ||
        m.category.toLowerCase().includes(q)
      );
    });
  }, [materialList, search, filterCat]);

  function handleAdd() {
    const n = name.trim();
    const c = (category.trim() || "Diğer");
    if (!n) return;
    if (materialList.some((m) => m.name.toLowerCase() === n.toLowerCase())) {
      Alert.alert(t("settings.matList.title"), t("settings.matList.exists"));
      return;
    }
    addMaterialItem({ name: n, category: c, defaultUnit: unit.trim() || undefined });
    setName("");
    setCategory("");
    setUnit("");
  }

  function handleDelete(n: string) {
    const refs =
      materials.filter((m) => m.name === n).length +
      materialRequests.filter((m) => m.name === n).length +
      materialMovements.filter((m) => m.name === n).length;
    const msg =
      t("settings.matList.confirmDelete").replace("{name}", n) +
      (refs > 0 ? "\n\n" + t("settings.refWarn").replace("{count}", String(refs)) : "");
    Alert.alert(t("common.delete"), msg, [
      { text: t("common.cancel"), style: "cancel" },
      { text: t("common.delete"), style: "destructive", onPress: () => deleteMaterialItem(n) },
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
          {t("settings.matList.title")}
        </Text>
        <View style={{ width: 40 }} />
      </View>

      <View style={[styles.addCard, { backgroundColor: colors.card, borderColor: colors.border }]}>
        <TextInput
          value={name}
          onChangeText={setName}
          placeholder={t("settings.matList.namePlaceholder")}
          placeholderTextColor={colors.mutedForeground}
          style={[styles.input, { color: colors.foreground, borderColor: colors.border, backgroundColor: colors.background }]}
        />
        <CategoryPicker
          label={t("settings.matList.category")}
          value={category}
          onChange={setCategory}
        />
        <UnitPicker
          label={t("settings.matList.unit")}
          value={unit}
          onChange={setUnit}
        />
        <PrimaryButton label={t("common.add")} onPress={handleAdd} />
      </View>

      <View style={[styles.filterBar, { borderColor: colors.border }]}>
        <View style={{ flex: 1 }}>
          <TextInput
            value={search}
            onChangeText={setSearch}
            placeholder={t("common.search")}
            placeholderTextColor={colors.mutedForeground}
            style={[styles.searchInput, { color: colors.foreground, borderColor: colors.border, backgroundColor: colors.background }]}
          />
        </View>
        {filterCat ? (
          <TouchableOpacity
            onPress={() => setFilterCat("")}
            style={[styles.filterChip, { backgroundColor: colors.primary }]}
          >
            <Text style={{ color: colors.primaryForeground, fontSize: 12, fontFamily: "Inter_600SemiBold" }}>{filterCat}</Text>
            <Feather name="x" size={14} color={colors.primaryForeground} />
          </TouchableOpacity>
        ) : null}
      </View>

      <FlatList
        data={filtered}
        keyExtractor={(item) => item.name}
        contentContainerStyle={{ padding: 16, paddingBottom: insets.bottom + 24 }}
        ListEmptyComponent={
          <Text style={{ color: colors.mutedForeground, textAlign: "center", marginTop: 24 }}>
            {t("settings.matList.empty")}
          </Text>
        }
        renderItem={({ item }) => (
          <View style={[styles.row, { backgroundColor: colors.card, borderColor: colors.border }]}>
            <View style={{ flex: 1 }}>
              <Text style={[styles.itemName, { color: colors.foreground }]}>{item.name}</Text>
              <View style={styles.metaRow}>
                <TouchableOpacity onPress={() => setFilterCat(item.category)}>
                  <Text style={[styles.itemMeta, { color: colors.primary }]}>{item.category}</Text>
                </TouchableOpacity>
                {item.defaultUnit ? (
                  <Text style={[styles.itemMeta, { color: colors.mutedForeground }]}> · {item.defaultUnit}</Text>
                ) : null}
              </View>
            </View>
            <TouchableOpacity
              onPress={() => handleDelete(item.name)}
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
  addCard: { padding: 12, borderBottomWidth: 1, gap: 10 },
  input: { height: 42, borderWidth: 1, borderRadius: 10, paddingHorizontal: 12, fontSize: 14, fontFamily: "Inter_400Regular" },
  filterBar: { flexDirection: "row", gap: 8, padding: 12, alignItems: "center", borderBottomWidth: 1 },
  searchInput: { height: 38, borderWidth: 1, borderRadius: 10, paddingHorizontal: 12, fontSize: 13, fontFamily: "Inter_400Regular" },
  filterChip: { flexDirection: "row", alignItems: "center", gap: 6, paddingHorizontal: 10, paddingVertical: 8, borderRadius: 16 },
  row: { flexDirection: "row", alignItems: "center", padding: 14, marginBottom: 8, borderRadius: 12, borderWidth: 1 },
  itemName: { fontSize: 15, fontFamily: "Inter_600SemiBold" },
  metaRow: { flexDirection: "row", alignItems: "center", marginTop: 4 },
  itemMeta: { fontSize: 12, fontFamily: "Inter_400Regular" },
  delBtn: { width: 36, height: 36, borderRadius: 18, alignItems: "center", justifyContent: "center" },
});
