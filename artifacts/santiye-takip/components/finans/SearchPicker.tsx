import { Feather } from "@expo/vector-icons";
import React, { useCallback, useMemo, useState } from "react";
import {
  FlatList,
  Modal,
  Platform,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import { KeyboardAvoidingView } from "react-native-keyboard-controller";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import { useTranslation } from "react-i18next";

import { useColors } from "@/hooks/finans/useColors";

interface Option {
  label: string;
  sublabel?: string;
}

interface SearchPickerProps {
  value: string;
  onSelect: (value: string) => void;
  options: Option[];
  placeholder?: string;
  modalTitle?: string;
  emptyText?: string;
  allowCustom?: boolean;
}

export default function SearchPicker({
  value,
  onSelect,
  options,
  placeholder,
  modalTitle,
  emptyText,
  allowCustom = false,
}: SearchPickerProps) {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const { t } = useTranslation();

  const effectivePlaceholder = placeholder ?? t("searchPicker.placeholder");
  const effectiveTitle = modalTitle ?? t("searchPicker.title");
  const effectiveEmpty = emptyText ?? t("searchPicker.noResults");
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState("");

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return options;
    return options.filter(
      (o) =>
        o.label.toLowerCase().includes(q) ||
        (o.sublabel && o.sublabel.toLowerCase().includes(q))
    );
  }, [options, query]);

  const pick = useCallback(
    (val: string) => {
      onSelect(val);
      setOpen(false);
      setQuery("");
    },
    [onSelect]
  );

  const styles = StyleSheet.create({
    trigger: {
      flexDirection: "row",
      alignItems: "center",
      backgroundColor: colors.muted,
      borderRadius: 12,
      paddingVertical: 12,
      paddingHorizontal: 14,
      gap: 8,
      marginBottom: 12,
    },
    triggerText: {
      flex: 1,
      fontSize: 15,
      color: value ? colors.foreground : colors.mutedForeground,
    },
    backdrop: {
      flex: 1,
      backgroundColor: "rgba(0,0,0,0.55)",
      justifyContent: "flex-end",
    },
    sheet: {
      backgroundColor: colors.card,
      borderTopLeftRadius: 24,
      borderTopRightRadius: 24,
      paddingTop: 12,
      maxHeight: "80%",
    },
    handle: {
      width: 40,
      height: 4,
      borderRadius: 2,
      backgroundColor: colors.border,
      alignSelf: "center",
      marginBottom: 12,
    },
    header: {
      paddingHorizontal: 16,
      paddingBottom: 10,
      borderBottomWidth: 1,
      borderBottomColor: colors.border,
    },
    modalTitle: {
      fontSize: 16,
      fontWeight: "700",
      color: colors.foreground,
      marginBottom: 10,
    },
    searchRow: {
      flexDirection: "row",
      alignItems: "center",
      backgroundColor: colors.muted,
      borderRadius: 10,
      paddingHorizontal: 10,
      gap: 6,
    },
    searchInput: {
      flex: 1,
      fontSize: 14,
      color: colors.foreground,
      paddingVertical: 9,
    },
    item: {
      paddingHorizontal: 16,
      paddingVertical: 12,
      borderBottomWidth: 1,
      borderBottomColor: colors.border + "55",
    },
    itemLabel: {
      fontSize: 14,
      color: colors.foreground,
      fontWeight: "500",
    },
    itemSublabel: {
      fontSize: 12,
      color: colors.mutedForeground,
      marginTop: 2,
    },
    empty: {
      alignItems: "center",
      padding: 32,
    },
    emptyText: {
      color: colors.mutedForeground,
      fontSize: 14,
    },
    customBtn: {
      margin: 16,
      padding: 12,
      borderRadius: 12,
      backgroundColor: colors.muted,
      alignItems: "center",
    },
    customBtnText: {
      color: colors.foreground,
      fontSize: 14,
      fontWeight: "600",
    },
  });

  return (
    <>
      <TouchableOpacity style={styles.trigger} onPress={() => setOpen(true)} activeOpacity={0.7}>
        <Text style={styles.triggerText} numberOfLines={1}>
          {value || effectivePlaceholder}
        </Text>
        <Feather name="chevron-down" size={16} color={colors.mutedForeground} />
      </TouchableOpacity>

      <Modal
        visible={open}
        transparent
        animationType="slide"
        onRequestClose={() => { setOpen(false); setQuery(""); }}
      >
        <KeyboardAvoidingView
          behavior={Platform.OS === "ios" ? "padding" : undefined}
          style={{ flex: 1 }}
        >
          <Pressable style={styles.backdrop} onPress={() => { setOpen(false); setQuery(""); }}>
            <Pressable style={[styles.sheet, { paddingBottom: insets.bottom + 12 }]} onPress={() => {}}>
              <View style={styles.handle} />

              <View style={styles.header}>
                <Text style={styles.modalTitle}>{effectiveTitle}</Text>
                <View style={styles.searchRow}>
                  <Feather name="search" size={15} color={colors.mutedForeground} />
                  <TextInput
                    style={styles.searchInput}
                    value={query}
                    onChangeText={setQuery}
                    placeholder={t("searchPicker.search")}
                    placeholderTextColor={colors.mutedForeground}
                    autoFocus
                    clearButtonMode="while-editing"
                  />
                  {query.length > 0 && Platform.OS !== "ios" && (
                    <TouchableOpacity onPress={() => setQuery("")}>
                      <Feather name="x" size={14} color={colors.mutedForeground} />
                    </TouchableOpacity>
                  )}
                </View>
              </View>

              <FlatList
                data={filtered}
                keyExtractor={(_, i) => String(i)}
                keyboardShouldPersistTaps="handled"
                renderItem={({ item }) => (
                  <TouchableOpacity style={styles.item} onPress={() => pick(item.label)}>
                    <Text style={styles.itemLabel}>{item.label}</Text>
                    {!!item.sublabel && (
                      <Text style={styles.itemSublabel}>{item.sublabel}</Text>
                    )}
                  </TouchableOpacity>
                )}
                ListEmptyComponent={
                  <View style={styles.empty}>
                    <Text style={styles.emptyText}>{effectiveEmpty}</Text>
                  </View>
                }
              />

              {allowCustom && query.trim().length > 0 && (
                <TouchableOpacity
                  style={styles.customBtn}
                  onPress={() => pick(query.trim())}
                >
                  <Text style={styles.customBtnText}>{t("searchPicker.addCustom", { value: query.trim() })}</Text>
                </TouchableOpacity>
              )}
            </Pressable>
          </Pressable>
        </KeyboardAvoidingView>
      </Modal>
    </>
  );
}
