import { Feather } from "@expo/vector-icons";
import * as Haptics from "expo-haptics";
import React, { useMemo, useState } from "react";
import {
  FlatList,
  Modal,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useTranslation } from "react-i18next";

import TransactionCard from "@/components/finans/TransactionCard";
import { useBudget } from "@/context/finans/BudgetContext";
import { useColors } from "@/hooks/finans/useColors";
import { useFormatAmount } from "@/hooks/finans/useFormatAmount";

type TypeFilter = "all" | "income" | "expense" | "transfer";
type PeriodMode = "all" | "monthly" | "yearly";
type SortKey = "date-desc" | "date-asc" | "amount-desc" | "amount-asc";

const CURRENT_YEAR = new Date().getFullYear();
const YEARS = Array.from({ length: 10 }, (_, i) => CURRENT_YEAR - 9 + i).reverse();

export default function TransactionsScreen() {
  const formatAmount = useFormatAmount();
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const { transactions } = useBudget();
  const { t, i18n } = useTranslation();

  const [typeFilter, setTypeFilter] = useState<TypeFilter>("all");
  const [periodMode, setPeriodMode] = useState<PeriodMode>("monthly");
  const [refDate, setRefDate] = useState(() => new Date());
  const [pickerOpen, setPickerOpen] = useState(false);
  const [pickerYear, setPickerYear] = useState(() => new Date().getFullYear());
  const [sortKey, setSortKey] = useState<SortKey>("date-desc");
  const [sortSheetOpen, setSortSheetOpen] = useState(false);

  const topInset = Platform.OS === "web" ? 67 : insets.top;
  const bottomInset = Platform.OS === "web" ? 34 : insets.bottom;

  const MONTHS = useMemo(
    () => Array.from({ length: 12 }, (_, i) => {
      // 'long' format is reliable across all platforms/locales; 'short' can be
      // misordered on certain React Native runtimes (e.g. Android Intl polyfill).
      // Derive a 3-char abbreviation from the full name instead.
      const full = new Date(2000, i, 15).toLocaleDateString(i18n.language, { month: "long" });
      return (full.charAt(0).toUpperCase() + full.slice(1)).slice(0, 3);
    }),
    [i18n.language]
  );

  const periodLabel = useMemo(() => {
    if (periodMode === "all") return t("transactions.allTime");
    if (periodMode === "yearly") return String(refDate.getFullYear());
    return refDate.toLocaleDateString(i18n.language, { month: "long", year: "numeric" });
  }, [periodMode, refDate, i18n.language, t]);

  const TYPE_FILTERS: { key: TypeFilter; label: string; activeColor: string; tintColor: string; textColor: string }[] = [
    {
      key: "all",
      label: t("common.all"),
      activeColor: colors.primary,
      tintColor: colors.primary + "22",
      textColor: colors.primary,
    },
    {
      key: "income",
      label: t("transactions.income"),
      activeColor: colors.income ?? "#00C896",
      tintColor: (colors.income ?? "#00C896") + "22",
      textColor: colors.income ?? "#00C896",
    },
    {
      key: "expense",
      label: t("transactions.expense"),
      activeColor: colors.expense ?? "#FF4D6D",
      tintColor: (colors.expense ?? "#FF4D6D") + "22",
      textColor: colors.expense ?? "#FF4D6D",
    },
    {
      key: "transfer",
      label: "Transfer",
      activeColor: "#7C5CBF",
      tintColor: "#7C5CBF22",
      textColor: "#7C5CBF",
    },
  ];

  const PERIOD_MODES: { key: PeriodMode; label: string }[] = [
    { key: "all", label: t("transactions.allTime") },
    { key: "monthly", label: t("transactions.monthly") },
    { key: "yearly", label: t("transactions.yearly") },
  ];

  const SORT_OPTIONS: { key: SortKey; label: string; icon: string }[] = [
    { key: "date-desc", label: t("transactions.sortDateDesc"), icon: "arrow-down" },
    { key: "date-asc",  label: t("transactions.sortDateAsc"),  icon: "arrow-up" },
    { key: "amount-desc", label: t("transactions.sortAmountDesc"), icon: "arrow-down" },
    { key: "amount-asc",  label: t("transactions.sortAmountAsc"),  icon: "arrow-up" },
  ];

  const openPicker = () => {
    Haptics.selectionAsync();
    setPickerYear(refDate.getFullYear());
    setPickerOpen(true);
  };

  const selectMonth = (month: number) => {
    Haptics.selectionAsync();
    const d = new Date(refDate);
    d.setFullYear(pickerYear);
    d.setMonth(month);
    setRefDate(d);
    setPickerOpen(false);
  };

  const selectYear = (year: number) => {
    Haptics.selectionAsync();
    const d = new Date(refDate);
    d.setFullYear(year);
    setRefDate(d);
    setPickerOpen(false);
  };

  const filtered = useMemo(() => {
    let list = transactions;
    if (periodMode === "monthly") {
      list = list.filter((tx) => {
        const d = new Date(tx.date);
        return (
          d.getFullYear() === refDate.getFullYear() &&
          d.getMonth() === refDate.getMonth()
        );
      });
    } else if (periodMode === "yearly") {
      list = list.filter(
        (tx) => new Date(tx.date).getFullYear() === refDate.getFullYear()
      );
    }
    if (typeFilter !== "all") {
      list = list.filter((tx) => tx.type === typeFilter);
    }
    return [...list].sort((a, b) => {
      if (sortKey === "date-desc") {
        const diff = new Date(b.date).getTime() - new Date(a.date).getTime();
        return diff !== 0 ? diff : parseInt(b.id, 10) - parseInt(a.id, 10);
      }
      if (sortKey === "date-asc") {
        const diff = new Date(a.date).getTime() - new Date(b.date).getTime();
        return diff !== 0 ? diff : parseInt(a.id, 10) - parseInt(b.id, 10);
      }
      if (sortKey === "amount-desc") return b.amount - a.amount;
      if (sortKey === "amount-asc") return a.amount - b.amount;
      return 0;
    });
  }, [transactions, periodMode, refDate, typeFilter, sortKey]);

  const summary = useMemo(() => {
    const inc = filtered
      .filter((tx) => tx.type === "income")
      .reduce((s, tx) => s + tx.amount, 0);
    const exp = filtered
      .filter((tx) => tx.type === "expense")
      .reduce((s, tx) => s + tx.amount, 0);
    const trf = filtered
      .filter((tx) => tx.type === "transfer")
      .reduce((s, tx) => s + tx.amount, 0);
    return { inc, exp, bal: inc - exp, trf };
  }, [filtered]);

  const activeSortLabel = SORT_OPTIONS.find((o) => o.key === sortKey)?.label ?? "";
  const sortIsCustom = sortKey !== "date-desc";

  const styles = StyleSheet.create({
    container: { flex: 1, backgroundColor: colors.background },
    header: {
      paddingTop: topInset + 12,
      paddingHorizontal: 20,
      paddingBottom: 16,
      backgroundColor: colors.navy,
      borderBottomLeftRadius: 24,
      borderBottomRightRadius: 24,
    },
    headerTitle: {
      fontSize: 22,
      fontWeight: "800" as const,
      color: "#FFFFFF",
      marginBottom: 12,
    },
    periodModeRow: {
      flexDirection: "row",
      backgroundColor: "rgba(255,255,255,0.1)",
      borderRadius: 14,
      padding: 3,
      marginBottom: 12,
    },
    periodModeBtn: {
      flex: 1,
      paddingVertical: 7,
      borderRadius: 11,
      alignItems: "center",
    },
    periodModeBtnActive: { backgroundColor: colors.primary },
    periodModeBtnText: {
      fontSize: 12,
      fontWeight: "600" as const,
      color: "rgba(255,255,255,0.6)",
    },
    periodModeBtnTextActive: { color: "#FFFFFF" },
    pickerTrigger: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "center",
      gap: 8,
      backgroundColor: "rgba(255,255,255,0.12)",
      borderRadius: 14,
      paddingVertical: 10,
      paddingHorizontal: 20,
      marginBottom: 12,
      alignSelf: "center",
    },
    pickerTriggerText: {
      fontSize: 16,
      fontWeight: "700" as const,
      color: "#FFFFFF",
    },
    summaryRow: {
      flexDirection: "row",
      gap: 8,
      marginBottom: 12,
    },
    summaryCard: {
      flex: 1,
      backgroundColor: "rgba(255,255,255,0.1)",
      borderRadius: 12,
      padding: 10,
      alignItems: "center",
    },
    summaryCardLabel: {
      fontSize: 10,
      color: "rgba(255,255,255,0.6)",
      marginBottom: 3,
      fontWeight: "600" as const,
    },
    summaryCardValue: {
      fontSize: 13,
      fontWeight: "800" as const,
      color: "#FFFFFF",
    },
    filterRow: {
      flexDirection: "row",
      gap: 8,
      alignItems: "center",
    },
    cancelBtn: {
      marginTop: 12,
      borderRadius: 14,
      paddingVertical: 14,
      alignItems: "center" as const,
      backgroundColor: colors.muted,
    },
    cancelBtnText: { fontSize: 15, fontWeight: "700" as const, color: colors.foreground },
    filterBtn: {
      paddingHorizontal: 16,
      paddingVertical: 8,
      borderRadius: 20,
    },
    filterBtnText: { fontSize: 13, fontWeight: "700" as const },
    sortBtn: {
      marginLeft: "auto" as any,
      flexDirection: "row",
      alignItems: "center",
      gap: 4,
      paddingHorizontal: 10,
      paddingVertical: 8,
      borderRadius: 20,
      backgroundColor: sortIsCustom ? colors.primary : "rgba(255,255,255,0.15)",
    },
    sortBtnText: {
      fontSize: 12,
      fontWeight: "600" as const,
      color: sortIsCustom ? "#fff" : "rgba(255,255,255,0.7)",
    },
    list: { padding: 20 },
    emptyContainer: {
      flex: 1,
      alignItems: "center",
      justifyContent: "center",
      paddingVertical: 60,
    },
    emptyText: { fontSize: 16, color: colors.mutedForeground, marginTop: 12 },
    emptyCount: {
      fontSize: 13,
      color: colors.mutedForeground,
      marginTop: 4,
      textAlign: "center",
    },
    backdrop: {
      flex: 1,
      backgroundColor: "rgba(0,0,0,0.45)",
      justifyContent: "flex-end",
    },
    sheet: {
      backgroundColor: colors.background,
      borderTopLeftRadius: 22,
      borderTopRightRadius: 22,
      paddingTop: 8,
      paddingHorizontal: 16,
      paddingBottom: Math.max(insets.bottom, 16) + 8,
    },
    handle: {
      width: 40,
      height: 4,
      borderRadius: 2,
      backgroundColor: colors.border,
      alignSelf: "center",
      marginBottom: 16,
    },
    sheetTitle: {
      fontSize: 16,
      fontWeight: "700" as const,
      color: colors.foreground,
      textAlign: "center",
      marginBottom: 16,
    },
    yearNavRow: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      marginBottom: 16,
      paddingHorizontal: 4,
    },
    yearNavBtn: {
      width: 36,
      height: 36,
      borderRadius: 10,
      backgroundColor: colors.muted,
      alignItems: "center",
      justifyContent: "center",
    },
    yearNavLabel: {
      fontSize: 18,
      fontWeight: "800" as const,
      color: colors.foreground,
    },
    monthGrid: {
      flexDirection: "row",
      flexWrap: "wrap",
      gap: 8,
    },
    monthBtn: {
      width: "30%",
      paddingVertical: 14,
      borderRadius: 14,
      backgroundColor: colors.muted,
      alignItems: "center",
      flexGrow: 1,
    },
    monthBtnActive: { backgroundColor: colors.primary },
    monthBtnText: {
      fontSize: 14,
      fontWeight: "600" as const,
      color: colors.foreground,
    },
    monthBtnTextActive: { color: "#FFFFFF" },
    yearList: { maxHeight: 320 },
    yearItem: {
      paddingVertical: 14,
      paddingHorizontal: 16,
      borderRadius: 14,
      marginBottom: 6,
      backgroundColor: colors.muted,
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
    },
    yearItemActive: { backgroundColor: colors.primary },
    yearItemText: {
      fontSize: 16,
      fontWeight: "600" as const,
      color: colors.foreground,
    },
    yearItemTextActive: { color: "#FFFFFF" },
    sortOptionBtn: {
      flexDirection: "row",
      alignItems: "center",
      gap: 12,
      paddingVertical: 14,
      paddingHorizontal: 16,
      borderRadius: 14,
      marginBottom: 8,
    },
    sortOptionIcon: {
      width: 36,
      height: 36,
      borderRadius: 10,
      alignItems: "center",
      justifyContent: "center",
    },
    sortOptionLabel: {
      flex: 1,
      fontSize: 15,
      fontWeight: "600" as const,
    },
  });

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>{t("transactions.title")}</Text>

        <View style={styles.periodModeRow}>
          {PERIOD_MODES.map((pm) => {
            const active = periodMode === pm.key;
            return (
              <TouchableOpacity
                key={pm.key}
                style={[styles.periodModeBtn, active && styles.periodModeBtnActive]}
                onPress={() => {
                  Haptics.selectionAsync();
                  setPeriodMode(pm.key);
                }}
              >
                <Text style={[styles.periodModeBtnText, active && styles.periodModeBtnTextActive]}>
                  {pm.label}
                </Text>
              </TouchableOpacity>
            );
          })}
        </View>

        {periodMode !== "all" && (
          <TouchableOpacity style={styles.pickerTrigger} onPress={openPicker}>
            <Feather name="calendar" size={16} color="#FFFFFF" />
            <Text style={styles.pickerTriggerText}>{periodLabel}</Text>
            <Feather name="chevron-down" size={16} color="rgba(255,255,255,0.7)" />
          </TouchableOpacity>
        )}

        <View style={styles.summaryRow}>
          {typeFilter === "transfer" ? (
            <View style={[styles.summaryCard, { flex: 1 }]}>
              <Text style={styles.summaryCardLabel}>Transfer Tutarı</Text>
              <Text style={[styles.summaryCardValue, { color: "#B39DDB" }]}>
                {formatAmount(summary.trf)}
              </Text>
            </View>
          ) : (
            <>
              <View style={styles.summaryCard}>
                <Text style={styles.summaryCardLabel}>{t("transactions.income")}</Text>
                <Text style={[styles.summaryCardValue, { color: "#4DF5C8" }]}>
                  {formatAmount(summary.inc)}
                </Text>
              </View>
              <View style={styles.summaryCard}>
                <Text style={styles.summaryCardLabel}>{t("transactions.expense")}</Text>
                <Text style={[styles.summaryCardValue, { color: "#FF7F9A" }]}>
                  {formatAmount(summary.exp)}
                </Text>
              </View>
              <View style={styles.summaryCard}>
                <Text style={styles.summaryCardLabel}>{t("transactions.balance")}</Text>
                <Text style={[styles.summaryCardValue, { color: summary.bal >= 0 ? "#4DF5C8" : "#FF7F9A" }]}>
                  {formatAmount(Math.abs(summary.bal))}
                </Text>
              </View>
            </>
          )}
        </View>

        {/* Filter + Sort row */}
        <View style={styles.filterRow}>
          {TYPE_FILTERS.map((f) => {
            const isActive = typeFilter === f.key;
            return (
              <TouchableOpacity
                key={f.key}
                style={[
                  styles.filterBtn,
                  {
                    backgroundColor: isActive ? f.activeColor : f.tintColor,
                    borderWidth: 1.5,
                    borderColor: isActive ? f.activeColor : f.activeColor + "55",
                  },
                ]}
                onPress={() => { Haptics.selectionAsync(); setTypeFilter(f.key); }}
              >
                <Text
                  style={[
                    styles.filterBtnText,
                    { color: isActive ? "#FFFFFF" : f.textColor },
                  ]}
                >
                  {f.label}
                </Text>
              </TouchableOpacity>
            );
          })}

          {/* Sort button */}
          <TouchableOpacity
            style={styles.sortBtn}
            onPress={() => { Haptics.selectionAsync(); setSortSheetOpen(true); }}
          >
            <Feather
              name={sortKey.includes("desc") ? "arrow-down" : "arrow-up"}
              size={13}
              color={sortIsCustom ? "#fff" : "rgba(255,255,255,0.7)"}
            />
            <Text style={styles.sortBtnText}>{t("transactions.sortBy")}</Text>
          </TouchableOpacity>
        </View>
      </View>

      <FlatList
        data={filtered}
        keyExtractor={(item) => item.id}
        contentContainerStyle={[
          styles.list,
          { paddingBottom: bottomInset + 100 },
          filtered.length === 0 && { flex: 1 },
        ]}
        scrollEnabled={!!filtered.length}
        showsVerticalScrollIndicator={false}
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Feather name="list" size={44} color={colors.mutedForeground} />
            <Text style={styles.emptyText}>{t("transactions.notFound")}</Text>
            <Text style={styles.emptyCount}>
              {periodMode === "all"
                ? t("transactions.addHint")
                : t("transactions.noPeriodData", { period: periodLabel })}
            </Text>
          </View>
        }
        renderItem={({ item }) => <TransactionCard transaction={item} />}
      />

      {/* Date / Month Picker Modal */}
      <Modal
        visible={pickerOpen}
        transparent
        animationType="slide"
        onRequestClose={() => setPickerOpen(false)}
      >
        <Pressable style={styles.backdrop} onPress={() => setPickerOpen(false)}>
          <Pressable style={styles.sheet} onPress={() => {}}>
            <View style={styles.handle} />

            {periodMode === "monthly" ? (
              <>
                <Text style={styles.sheetTitle}>{t("transactions.selectMonth")}</Text>
                <View style={styles.yearNavRow}>
                  <TouchableOpacity
                    style={styles.yearNavBtn}
                    onPress={() => { Haptics.selectionAsync(); setPickerYear((y) => y - 1); }}
                  >
                    <Feather name="chevron-left" size={20} color={colors.foreground} />
                  </TouchableOpacity>
                  <Text style={styles.yearNavLabel}>{pickerYear}</Text>
                  <TouchableOpacity
                    style={styles.yearNavBtn}
                    onPress={() => { Haptics.selectionAsync(); setPickerYear((y) => y + 1); }}
                  >
                    <Feather name="chevron-right" size={20} color={colors.foreground} />
                  </TouchableOpacity>
                </View>
                <View style={styles.monthGrid}>
                  {MONTHS.map((name, idx) => {
                    const isActive =
                      idx === refDate.getMonth() &&
                      pickerYear === refDate.getFullYear();
                    return (
                      <TouchableOpacity
                        key={idx}
                        style={[styles.monthBtn, isActive && styles.monthBtnActive]}
                        onPress={() => selectMonth(idx)}
                      >
                        <Text style={[styles.monthBtnText, isActive && styles.monthBtnTextActive]}>
                          {name}
                        </Text>
                      </TouchableOpacity>
                    );
                  })}
                </View>
              </>
            ) : (
              <>
                <Text style={styles.sheetTitle}>{t("transactions.selectYear")}</Text>
                <ScrollView style={styles.yearList} showsVerticalScrollIndicator={false}>
                  {YEARS.map((year) => {
                    const isActive = year === refDate.getFullYear();
                    return (
                      <TouchableOpacity
                        key={year}
                        style={[styles.yearItem, isActive && styles.yearItemActive]}
                        onPress={() => selectYear(year)}
                      >
                        <Text style={[styles.yearItemText, isActive && styles.yearItemTextActive]}>
                          {year}
                        </Text>
                        {isActive && <Feather name="check" size={18} color="#FFFFFF" />}
                      </TouchableOpacity>
                    );
                  })}
                </ScrollView>
              </>
            )}

            <TouchableOpacity
              style={styles.cancelBtn}
              onPress={() => setPickerOpen(false)}
            >
              <Text style={styles.cancelBtnText}>{t("common.cancel")}</Text>
            </TouchableOpacity>
          </Pressable>
        </Pressable>
      </Modal>

      {/* Sort Sheet Modal */}
      <Modal
        visible={sortSheetOpen}
        transparent
        animationType="slide"
        onRequestClose={() => setSortSheetOpen(false)}
      >
        <Pressable style={styles.backdrop} onPress={() => setSortSheetOpen(false)}>
          <Pressable style={styles.sheet} onPress={() => {}}>
            <View style={styles.handle} />
            <Text style={styles.sheetTitle}>{t("transactions.sortBy")}</Text>

            {SORT_OPTIONS.map((opt) => {
              const isActive = sortKey === opt.key;
              const isDate = opt.key.startsWith("date");
              const iconColor = isDate ? colors.primary : (colors.income ?? "#00C896");
              return (
                <TouchableOpacity
                  key={opt.key}
                  style={[
                    styles.sortOptionBtn,
                    {
                      backgroundColor: isActive ? colors.primary + "18" : colors.muted,
                      borderWidth: isActive ? 1.5 : 0,
                      borderColor: colors.primary,
                    },
                  ]}
                  onPress={() => {
                    Haptics.selectionAsync();
                    setSortKey(opt.key);
                    setSortSheetOpen(false);
                  }}
                >
                  <View style={[styles.sortOptionIcon, { backgroundColor: isActive ? colors.primary + "25" : colors.background }]}>
                    <Feather
                      name={isDate ? "calendar" : "dollar-sign"}
                      size={16}
                      color={isActive ? colors.primary : iconColor}
                    />
                  </View>
                  <Text style={[styles.sortOptionLabel, { color: isActive ? colors.primary : colors.foreground }]}>
                    {opt.label}
                  </Text>
                  {isActive && <Feather name="check-circle" size={18} color={colors.primary} />}
                </TouchableOpacity>
              );
            })}

            <TouchableOpacity
              style={[styles.cancelBtn, { marginTop: 4 }]}
              onPress={() => setSortSheetOpen(false)}
            >
              <Text style={styles.cancelBtnText}>{t("common.cancel")}</Text>
            </TouchableOpacity>
          </Pressable>
        </Pressable>
      </Modal>
    </View>
  );
}
