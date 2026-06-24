import { Feather } from "@expo/vector-icons";
import React, { useMemo, useState } from "react";
import {
  FlatList,
  Modal,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import { ImalatPoz } from "@/constants/imalatPozlari";
import { useMergedPozAnalizleri } from "@/hooks/useMergedPozAnalizleri";
import { useColors } from "@/hooks/useColors";

interface Props {
  label: string;
  value: string;
  onChange: (poz: ImalatPoz) => void;
  placeholder?: string;
}

type Row =
  | { type: "header"; label: string }
  | { type: "item"; poz: ImalatPoz };

export default function PozPicker({
  label,
  value,
  onChange,
  placeholder = "Poz seçin veya arayın",
}: Props) {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const { pozAnalizleri, loading } = useMergedPozAnalizleri();
  const [open, setOpen] = useState(false);
  const [search, setSearch] = useState("");
  const [activeCat, setActiveCat] = useState<string | null>(null);

  // pozAnalizleri → ImalatPoz formatına dönüştür
  const items = useMemo<ImalatPoz[]>(
    () =>
      pozAnalizleri.map((a) => ({
        code: a.pozNo,
        category: a.kategori,
        name: a.analizAdi,
        unit: a.olcuBirimi,
      })),
    [pozAnalizleri]
  );

  const selected = useMemo(
    () => items.find((p) => p.code === value) || null,
    [items, value]
  );

  const matches = useMemo(() => {
    const q = search.trim().toLowerCase();
    let list = items;
    if (activeCat) list = list.filter((m) => m.category === activeCat);
    if (q) {
      list = list.filter(
        (m) =>
          m.name.toLowerCase().includes(q) ||
          m.code.toLowerCase().includes(q) ||
          m.category.toLowerCase().includes(q)
      );
    }
    return list;
  }, [search, activeCat, items]);

  const rows = useMemo<Row[]>(() => {
    if (activeCat) {
      return matches.map((m) => ({ type: "item" as const, poz: m }));
    }
    const out: Row[] = [];
    let lastCat = "";
    const sorted = [...matches].sort((a, b) =>
      a.category === b.category
        ? a.code.localeCompare(b.code)
        : a.category.localeCompare(b.category)
    );
    for (const m of sorted) {
      if (m.category !== lastCat) {
        out.push({ type: "header", label: m.category });
        lastCat = m.category;
      }
      out.push({ type: "item", poz: m });
    }
    return out;
  }, [matches, activeCat]);

  const categories = useMemo(
    () => Array.from(new Set(items.map((p) => p.category))).sort(),
    [items]
  );

  function pick(p: ImalatPoz) {
    onChange(p);
    close();
  }

  function addManual() {
    const text = search.trim();
    const name = text.length > 0 ? text : "Yeni Poz";
    const code = `MAN-${Date.now().toString(36).toUpperCase().slice(-6)}`;
    pick({
      code,
      name,
      category: activeCat ?? "Diğer",
      unit: "br",
    });
  }

  function close() {
    setOpen(false);
    setSearch("");
    setActiveCat(null);
  }

  return (
    <View style={styles.wrap}>
      <Text style={[styles.label, { color: colors.foreground }]}>{label}</Text>
      <TouchableOpacity
        activeOpacity={0.75}
        onPress={() => setOpen(true)}
        style={[
          styles.input,
          { backgroundColor: colors.background, borderColor: colors.border },
        ]}
      >
        <View style={{ flex: 1 }}>
          <Text
            style={[
              styles.value,
              { color: selected ? colors.foreground : colors.mutedForeground },
            ]}
            numberOfLines={1}
          >
            {selected ? selected.name : placeholder}
          </Text>
          {selected ? (
            <Text style={[styles.subValue, { color: colors.mutedForeground }]} numberOfLines={1}>
              {selected.code} · {selected.category} · {selected.unit}
            </Text>
          ) : null}
        </View>
        <Feather name="chevron-down" size={18} color={colors.mutedForeground} />
      </TouchableOpacity>

      <Modal
        visible={open}
        animationType="fade"
        transparent
        onRequestClose={close}
      >
        <Pressable style={styles.backdrop} onPress={close}>
          <Pressable
            onPress={() => {}}
            style={[
              styles.sheet,
              {
                backgroundColor: colors.card,
                paddingBottom: Math.max(insets.bottom, 12),
              },
            ]}
          >
            <View style={styles.handle} />
            <View style={styles.headerRow}>
              <Text style={[styles.title, { color: colors.foreground }]}>
                Poz Tarifi Seç
              </Text>
              <TouchableOpacity onPress={close} hitSlop={10}>
                <Feather name="x" size={22} color={colors.mutedForeground} />
              </TouchableOpacity>
            </View>

            <View style={[styles.searchBox, { backgroundColor: colors.muted }]}>
              <Feather name="search" size={14} color={colors.mutedForeground} />
              <TextInput
                value={search}
                onChangeText={setSearch}
                placeholder="Kod, ad veya kategori ara..."
                placeholderTextColor={colors.mutedForeground}
                style={[styles.searchInput, { color: colors.foreground }]}
                autoFocus
                autoCorrect={false}
                returnKeyType="search"
              />
              {search.length > 0 ? (
                <TouchableOpacity onPress={() => setSearch("")} hitSlop={10}>
                  <Feather name="x-circle" size={14} color={colors.mutedForeground} />
                </TouchableOpacity>
              ) : null}
            </View>

            <View style={styles.catRow}>
              <FlatList
                horizontal
                showsHorizontalScrollIndicator={false}
                data={[null, ...categories]}
                keyExtractor={(c) => c ?? "__all"}
                contentContainerStyle={{ gap: 6 }}
                renderItem={({ item }) => {
                  const sel = item === activeCat;
                  return (
                    <TouchableOpacity
                      onPress={() => setActiveCat(item)}
                      style={[
                        styles.catChip,
                        { backgroundColor: sel ? colors.primary : colors.muted },
                      ]}
                      activeOpacity={0.7}
                    >
                      <Text
                        style={[
                          styles.catChipText,
                          { color: sel ? "#fff" : colors.foreground },
                        ]}
                      >
                        {item ?? "Tümü"}
                      </Text>
                    </TouchableOpacity>
                  );
                }}
              />
            </View>

            <FlatList
              data={rows}
              keyExtractor={(r, i) =>
                r.type === "header" ? `h_${r.label}_${i}` : `p_${r.poz.code}_${i}`
              }
              keyboardShouldPersistTaps="handled"
              renderItem={({ item }) => {
                if (item.type === "header") {
                  return (
                    <View
                      style={[
                        styles.headerSection,
                        { backgroundColor: colors.background },
                      ]}
                    >
                      <Text
                        style={[
                          styles.headerSectionText,
                          { color: colors.mutedForeground },
                        ]}
                      >
                        {item.label}
                      </Text>
                    </View>
                  );
                }
                const m = item.poz;
                const sel = m.code === value;
                return (
                  <TouchableOpacity
                    onPress={() => pick(m)}
                    style={[
                      styles.row,
                      {
                        borderBottomColor: colors.border,
                        backgroundColor: sel ? colors.primary + "12" : "transparent",
                      },
                    ]}
                    activeOpacity={0.7}
                  >
                    <View
                      style={[
                        styles.codeBadge,
                        { backgroundColor: sel ? colors.primary : colors.muted },
                      ]}
                    >
                      <Text
                        style={[
                          styles.codeBadgeText,
                          { color: sel ? "#fff" : colors.foreground },
                        ]}
                        numberOfLines={1}
                      >
                        {m.code}
                      </Text>
                    </View>
                    <View style={{ flex: 1 }}>
                      <Text
                        style={[
                          styles.rowName,
                          {
                            color: sel ? colors.primary : colors.foreground,
                            fontFamily: sel ? "Inter_600SemiBold" : "Inter_500Medium",
                          },
                        ]}
                        numberOfLines={2}
                      >
                        {m.name}
                      </Text>
                      <Text
                        style={[styles.rowCat, { color: colors.mutedForeground }]}
                        numberOfLines={1}
                      >
                        {m.category} · {m.unit}
                      </Text>
                    </View>
                    {sel ? (
                      <Feather name="check" size={18} color={colors.primary} />
                    ) : null}
                  </TouchableOpacity>
                );
              }}
              ListEmptyComponent={
                <View style={styles.empty}>
                  <Text style={{ color: colors.mutedForeground, marginBottom: 12 }}>
                    {loading ? "Poz listesi yükleniyor…" : "Poz bulunamadı"}
                  </Text>
                  <TouchableOpacity
                    onPress={addManual}
                    style={[styles.manualBtn, { backgroundColor: colors.primary }]}
                    activeOpacity={0.8}
                  >
                    <Feather name="plus" size={16} color="#fff" />
                    <Text style={styles.manualBtnText} numberOfLines={1}>
                      {search.trim().length > 0
                        ? `Manuel ekle: "${search.trim()}"`
                        : "Manuel Poz Girişi"}
                    </Text>
                  </TouchableOpacity>
                </View>
              }
              style={{ maxHeight: 420 }}
            />
            <TouchableOpacity
              onPress={addManual}
              style={[styles.manualFooter, { borderTopColor: colors.border }]}
              activeOpacity={0.7}
            >
              <Feather name="edit-3" size={14} color={colors.primary} />
              <Text style={[styles.manualFooterText, { color: colors.primary }]}>
                Listede yok — Manuel Poz Girişi
              </Text>
            </TouchableOpacity>
          </Pressable>
        </Pressable>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { marginBottom: 14 },
  label: { fontSize: 14, fontFamily: "Inter_600SemiBold", marginBottom: 6 },
  input: {
    borderWidth: 1,
    borderRadius: 10,
    paddingHorizontal: 14,
    paddingVertical: 10,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    minHeight: 50,
    gap: 8,
  },
  value: { fontSize: 15, fontFamily: "Inter_500Medium" },
  subValue: { fontSize: 11, fontFamily: "Inter_400Regular", marginTop: 2 },
  backdrop: {
    flex: 1,
    backgroundColor: "rgba(0,0,0,0.45)",
    justifyContent: "flex-end",
  },
  sheet: {
    borderTopLeftRadius: 20,
    borderTopRightRadius: 20,
    paddingTop: 8,
    paddingHorizontal: 16,
  },
  handle: {
    width: 40,
    height: 4,
    borderRadius: 2,
    backgroundColor: "#cbd5e1",
    alignSelf: "center",
    marginBottom: 12,
  },
  headerRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: 12,
  },
  title: { fontSize: 17, fontFamily: "Inter_700Bold" },
  searchBox: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 10,
    marginBottom: 8,
  },
  searchInput: {
    flex: 1,
    fontSize: 15,
    fontFamily: "Inter_500Medium",
    padding: 0,
  },
  catRow: { marginBottom: 8 },
  catChip: { paddingHorizontal: 12, paddingVertical: 6, borderRadius: 999 },
  catChipText: { fontSize: 12, fontFamily: "Inter_600SemiBold" },
  row: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
    paddingVertical: 10,
    paddingHorizontal: 4,
    borderBottomWidth: StyleSheet.hairlineWidth,
  },
  codeBadge: {
    minWidth: 76,
    paddingHorizontal: 8,
    paddingVertical: 6,
    borderRadius: 6,
    alignItems: "center",
    justifyContent: "center",
  },
  codeBadgeText: { fontSize: 11, fontFamily: "Inter_700Bold" },
  rowName: { fontSize: 14, marginBottom: 2 },
  rowCat: { fontSize: 11, fontFamily: "Inter_400Regular" },
  headerSection: { paddingVertical: 6, paddingHorizontal: 4 },
  headerSectionText: {
    fontSize: 11,
    fontFamily: "Inter_700Bold",
    textTransform: "uppercase",
    letterSpacing: 0.5,
  },
  empty: { paddingVertical: 24, alignItems: "center" },
  manualBtn: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    paddingHorizontal: 14,
    paddingVertical: 10,
    borderRadius: 10,
  },
  manualBtnText: { color: "#fff", fontSize: 13, fontFamily: "Inter_600SemiBold" },
  manualFooter: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 6,
    paddingVertical: 12,
    marginTop: 4,
    borderTopWidth: StyleSheet.hairlineWidth,
  },
  manualFooterText: { fontSize: 13, fontFamily: "Inter_600SemiBold" },
});
