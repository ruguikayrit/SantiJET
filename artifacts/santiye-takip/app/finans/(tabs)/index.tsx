import { Feather } from "@expo/vector-icons";
import * as Haptics from "expo-haptics";
import { router } from "expo-router";
import React, { useMemo, useState } from "react";
import {
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useTranslation } from "react-i18next";

import NotificationsModal, { buildAlerts } from "@/components/finans/NotificationsModal";
import PieChart, { PieSlice } from "@/components/finans/PieChart";
import TransactionCard from "@/components/finans/TransactionCard";
import { useBudget } from "@/context/finans/BudgetContext";
import { useColors } from "@/hooks/finans/useColors";
import { useFormatAmount } from "@/hooks/finans/useFormatAmount";

const EXPENSE_COLORS = [
  "#FF4D6D",
  "#FF8A5C",
  "#FFB547",
  "#7B61FF",
  "#3B82F6",
  "#06B6D4",
  "#22C55E",
  "#EAB308",
  "#EC4899",
  "#94A3B8",
];
const INCOME_COLORS = [
  "#00C896",
  "#22C55E",
  "#06B6D4",
  "#3B82F6",
  "#7B61FF",
  "#94A3B8",
];

function aggregateByCategory(
  items: { category: string; amount: number }[],
  palette: string[]
): PieSlice[] {
  const map = new Map<string, number>();
  items.forEach((t) => {
    map.set(t.category, (map.get(t.category) ?? 0) + t.amount);
  });
  return Array.from(map.entries())
    .sort((a, b) => b[1] - a[1])
    .map(([label, value], i) => ({
      label,
      value,
      color: palette[i % palette.length],
    }));
}

export default function DashboardScreen() {
  const formatAmount = useFormatAmount();
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const { t, i18n } = useTranslation();
  const {
    transactions,
    totalIncome,
    totalExpense,
    debts,
    bankLimits,
    totalDebtRemaining,
    assetEntries,
  } = useBudget();

  const [chartType, setChartType] = useState<"expense" | "income">("expense");
  const [chartFilter, setChartFilter] = useState<"gunluk" | "haftalik" | "aylik" | "tumzamanlar" | "manuel">("aylik");
  const [notifModalOpen, setNotifModalOpen] = useState(false);
  const [hideNetWorth, setHideNetWorth] = useState(false);

  const now = new Date();
  const currentYear = now.getFullYear();
  const currentMonth = now.getMonth();

  const [manualYear, setManualYear] = useState(currentYear);
  const [manualMonth, setManualMonth] = useState(currentMonth);

  const monthLabel = now.toLocaleDateString(i18n.language, {
    month: "long",
    year: "numeric",
  });
  const { monthlyIncome, monthlyExpense } =
    useMemo(() => {
      let mInc = 0, mExp = 0;
      for (const t of transactions) {
        const d = new Date(t.date);
        const sameMonth = d.getFullYear() === currentYear && d.getMonth() === currentMonth;
        if (!sameMonth) continue;
        if (t.type === "income") mInc += t.amount;
        else if (t.type === "expense") mExp += t.amount;
      }
      return { monthlyIncome: mInc, monthlyExpense: mExp };
    }, [transactions, currentYear, currentMonth]);

  const ozSermaye = useMemo(() => {
    const bankLimitDebt = bankLimits
      .filter((b) => b.type === "credit")
      .reduce((s, b) => s + Math.max(0, b.limit - (b.availableLimit ?? b.limit)), 0);
    const totalAssets = assetEntries.reduce((s, e) => s + e.amount, 0);
    return (totalIncome - totalExpense) - totalDebtRemaining - bankLimitDebt + totalAssets;
  }, [totalIncome, totalExpense, totalDebtRemaining, bankLimits, assetEntries]);

  const filteredChartTransactions = useMemo(() => {
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const startOfWeek = new Date(startOfDay);
    const dow = startOfDay.getDay();
    startOfWeek.setDate(startOfDay.getDate() - (dow === 0 ? 6 : dow - 1));
    return transactions.filter((tr) => {
      const d = new Date(tr.date);
      switch (chartFilter) {
        case "gunluk":       return d >= startOfDay;
        case "haftalik":     return d >= startOfWeek;
        case "aylik":        return d.getFullYear() === currentYear && d.getMonth() === currentMonth;
        case "tumzamanlar":  return true;
        case "manuel":       return d.getFullYear() === manualYear && d.getMonth() === manualMonth;
      }
    });
  }, [transactions, chartFilter, currentYear, currentMonth, manualYear, manualMonth]);

  const expenseSlices = useMemo(
    () =>
      aggregateByCategory(
        filteredChartTransactions.filter((t) => t.type === "expense"),
        EXPENSE_COLORS
      ),
    [filteredChartTransactions]
  );
  const incomeSlices = useMemo(
    () =>
      aggregateByCategory(
        filteredChartTransactions.filter((t) => t.type === "income"),
        INCOME_COLORS
      ),
    [filteredChartTransactions]
  );

  const urgentCount = useMemo(() => {
    const alerts = buildAlerts(debts, colors, t);
    return alerts.filter((a) => a.days !== null && a.days <= 7).length;
  }, [debts, colors, t]);

  // İşlem sayıları
  const monthlyIncomeCount = useMemo(
    () => transactions.filter(t => {
      const d = new Date(t.date);
      return t.type === "income" && d.getFullYear() === currentYear && d.getMonth() === currentMonth;
    }).length,
    [transactions, currentYear, currentMonth]
  );
  const monthlyExpenseCount = useMemo(
    () => transactions.filter(t => {
      const d = new Date(t.date);
      return t.type === "expense" && d.getFullYear() === currentYear && d.getMonth() === currentMonth;
    }).length,
    [transactions, currentYear, currentMonth]
  );

  // Geçen ay
  const prevYear  = currentMonth === 0 ? currentYear - 1 : currentYear;
  const prevMonth = currentMonth === 0 ? 11 : currentMonth - 1;
  const { prevIncome, prevExpense } = useMemo(() => {
    let pInc = 0, pExp = 0;
    for (const t of transactions) {
      const d = new Date(t.date);
      if (d.getFullYear() === prevYear && d.getMonth() === prevMonth) {
        if (t.type === "income") pInc += t.amount;
        else if (t.type === "expense") pExp += t.amount;
      }
    }
    return { prevIncome: pInc, prevExpense: pExp };
  }, [transactions, prevYear, prevMonth]);

  // Trend yüzdeleri (geçen aya göre)
  const incomeTrend  = prevIncome  > 0 ? ((monthlyIncome  - prevIncome)  / prevIncome)  * 100 : null;
  const expenseTrend = prevExpense > 0 ? ((monthlyExpense - prevExpense) / prevExpense) * 100 : null;

  // Katkı oranı — gelir içinde gider payı (bar için)
  const spendRatio = monthlyIncome > 0 ? Math.min(1, monthlyExpense / monthlyIncome) : 0;

  const monthlyBalance = monthlyIncome - monthlyExpense;
  const isMonthlyPositive = monthlyBalance >= 0;
  const topInset = Platform.OS === "web" ? 67 : insets.top;
  const bottomInset = Platform.OS === "web" ? 34 : insets.bottom;

  const filteredTotal = useMemo(() => {
    let inc = 0, exp = 0;
    for (const tr of filteredChartTransactions) {
      if (tr.type === "income") inc += tr.amount;
      else if (tr.type === "expense") exp += tr.amount;
    }
    return { inc, exp };
  }, [filteredChartTransactions]);

  const slices = chartType === "expense" ? expenseSlices : incomeSlices;
  const chartTotal = chartType === "expense" ? filteredTotal.exp : filteredTotal.inc;

  const styles = StyleSheet.create({
    container: { flex: 1, backgroundColor: colors.background },
    header: {
      backgroundColor: colors.navy,
      paddingTop: topInset + 16,
      paddingBottom: 32,
      paddingHorizontal: 24,
      borderBottomLeftRadius: 28,
      borderBottomRightRadius: 28,
    },
    headerTopRow: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      marginBottom: 4,
    },
    bellBtn: {
      width: 38,
      height: 38,
      borderRadius: 19,
      backgroundColor: "rgba(255,255,255,0.12)",
      alignItems: "center",
      justifyContent: "center",
    },
    badge: {
      position: "absolute",
      top: 4,
      right: 4,
      minWidth: 16,
      height: 16,
      borderRadius: 8,
      backgroundColor: colors.expense,
      alignItems: "center",
      justifyContent: "center",
      paddingHorizontal: 3,
    },
    badgeText: {
      fontSize: 9,
      fontWeight: "800",
      color: "#FFFFFF",
    },
    headerTitle: {
      fontSize: 14,
      color: "rgba(255,255,255,0.6)",
      fontWeight: "500" as const,
      marginBottom: 4,
    },
    balanceLabel: {
      fontSize: 13,
      color: "rgba(255,255,255,0.5)",
      marginBottom: 6,
    },
    balanceAmount: {
      fontSize: 38,
      fontWeight: "800" as const,
      color: "#FFFFFF",
      marginBottom: 4,
    },
    balanceSub: {
      fontSize: 13,
      color: isMonthlyPositive ? colors.primary : colors.expense,
      fontWeight: "600" as const,
    },
    headerDivider: {
      height: 1,
      backgroundColor: "rgba(255,255,255,0.12)",
      marginVertical: 14,
    },
    cardsRow: {
      flexDirection: "row",
      marginTop: -24,
      paddingHorizontal: 20,
      gap: 12,
    },
    summaryCard: {
      flex: 1,
      backgroundColor: colors.card,
      borderRadius: colors.radius,
      padding: 14,
      shadowColor: "#000",
      shadowOffset: { width: 0, height: 4 },
      shadowOpacity: 0.08,
      shadowRadius: 12,
      elevation: 3,
    },
    summaryCardHeader: {
      flexDirection: "row",
      alignItems: "center",
      marginBottom: 10,
      gap: 6,
    },
    summaryIconBg: {
      width: 32,
      height: 32,
      borderRadius: 9,
      alignItems: "center",
      justifyContent: "center",
    },
    summaryLabel: {
      flex: 1,
      fontSize: 11,
      color: colors.mutedForeground,
      fontWeight: "700" as const,
      letterSpacing: 0.4,
    },
    trendBadge: {
      flexDirection: "row",
      alignItems: "center",
      gap: 2,
      paddingHorizontal: 5,
      paddingVertical: 2,
      borderRadius: 6,
    },
    trendText: {
      fontSize: 10,
      fontWeight: "700" as const,
    },
    summaryAmount: {
      fontSize: 18,
      fontWeight: "800" as const,
      marginBottom: 2,
    },
    summaryDivider: {
      height: 1,
      backgroundColor: colors.border,
      marginVertical: 8,
    },
    summaryFooter: {
      flexDirection: "row",
      alignItems: "center",
      gap: 4,
    },
    summaryRowLabel: {
      fontSize: 10,
      color: colors.mutedForeground,
      fontWeight: "500" as const,
    },
    spendBar: {
      height: 4,
      backgroundColor: colors.border,
      borderRadius: 2,
      marginTop: 8,
      overflow: "hidden" as const,
    },
    spendBarFill: {
      height: 4,
      borderRadius: 2,
    },
    spendBarLabel: {
      fontSize: 9,
      color: colors.mutedForeground,
      marginTop: 4,
      fontWeight: "500" as const,
    },
    section: { paddingHorizontal: 20, marginTop: 24 },
    sectionHeader: {
      flexDirection: "row",
      justifyContent: "space-between",
      alignItems: "center",
      marginBottom: 14,
    },
    sectionTitle: {
      fontSize: 17,
      fontWeight: "700" as const,
      color: colors.foreground,
    },
    chartCard: {
      backgroundColor: colors.card,
      borderRadius: colors.radius,
      padding: 18,
    },
    toggleRow: {
      flexDirection: "row",
      gap: 10,
      marginBottom: 18,
    },
    toggleBtn: {
      flex: 1,
      paddingVertical: 10,
      borderRadius: 12,
      alignItems: "center",
    },
    toggleBtnActive: {},
    toggleText: {
      fontSize: 13,
      fontWeight: "700" as const,
      color: "#FFFFFF",
    },
    toggleTextActive: { color: "#FFFFFF" },
    emptyContainer: { alignItems: "center", paddingVertical: 32 },
    emptyIcon: { marginBottom: 12 },
    emptyText: {
      fontSize: 15,
      color: colors.mutedForeground,
      textAlign: "center" as const,
    },
    emptySubText: {
      fontSize: 13,
      color: colors.mutedForeground,
      textAlign: "center" as const,
      marginTop: 4,
      opacity: 0.7,
    },
    scroll: { flex: 1 },
    ioRow: {
      flexDirection: "row",
      gap: 10,
    },
    ioBtn: {
      flex: 1,
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "center",
      gap: 8,
      paddingVertical: 14,
      borderRadius: colors.radius,
      backgroundColor: colors.card,
      borderWidth: 1,
      borderColor: colors.border,
    },
    ioBtnText: {
      fontSize: 14,
      fontWeight: "600" as const,
      color: colors.foreground,
    },
    ioHint: {
      fontSize: 12,
      color: colors.mutedForeground,
      marginTop: 10,
      textAlign: "center" as const,
    },
    filterRow: {
      flexDirection: "row" as const,
      gap: 6,
      marginBottom: 14,
    },
    filterChip: {
      flex: 1,
      paddingHorizontal: 4,
      paddingVertical: 8,
      borderRadius: 12,
      backgroundColor: colors.muted,
      borderWidth: 1.5,
      borderColor: "transparent",
      alignItems: "center" as const,
      justifyContent: "center" as const,
    },
    filterChipActive: {
      backgroundColor: colors.primary + "18",
      borderColor: colors.primary,
    },
    filterChipText: {
      fontSize: 11,
      fontWeight: "600" as const,
      color: colors.mutedForeground,
      textAlign: "center" as const,
    },
    filterChipTextActive: {
      color: colors.primary,
    },
    manualPicker: {
      flexDirection: "row" as const,
      alignItems: "center" as const,
      justifyContent: "space-between" as const,
      backgroundColor: colors.muted,
      borderRadius: 12,
      paddingHorizontal: 12,
      paddingVertical: 10,
      marginBottom: 14,
    },
    manualPickerText: {
      fontSize: 14,
      fontWeight: "700" as const,
      color: colors.foreground,
    },
    manualPickerArrow: {
      width: 32,
      height: 32,
      borderRadius: 10,
      backgroundColor: colors.card,
      alignItems: "center" as const,
      justifyContent: "center" as const,
    },
  });

  return (
    <View style={styles.container}>
      <ScrollView
        showsVerticalScrollIndicator={false}
        style={{ flex: 1 }}
        keyboardShouldPersistTaps="handled"
        contentContainerStyle={{ paddingBottom: bottomInset + 100 }}
      >
        <View style={styles.header}>
          <View style={styles.headerTopRow}>
            <Text style={styles.headerTitle}>{t("home.financialStatus")}</Text>
            <TouchableOpacity
              style={styles.bellBtn}
              activeOpacity={0.75}
              onPress={() => setNotifModalOpen(true)}
            >
              <Feather name="bell" size={18} color="#FFFFFF" />
              {urgentCount > 0 && (
                <View style={styles.badge}>
                  <Text style={styles.badgeText}>{urgentCount}</Text>
                </View>
              )}
            </TouchableOpacity>
          </View>
          <Text style={styles.balanceLabel}>{t("home.netWorth")}</Text>
          <View style={{ flexDirection: "row", alignItems: "center", gap: 10 }}>
            <Text style={[
              styles.balanceAmount,
              { color: hideNetWorth ? "rgba(255,255,255,0.4)" : ozSermaye >= 0 ? colors.income : colors.expense },
            ]}>
              {hideNetWorth ? "••••••••" : formatAmount(ozSermaye)}
            </Text>
            <TouchableOpacity
              onPress={() => { Haptics.selectionAsync(); setHideNetWorth((v) => !v); }}
              hitSlop={{ top: 12, bottom: 12, left: 12, right: 12 }}
              activeOpacity={0.65}
              style={{
                width: 34,
                height: 34,
                borderRadius: 10,
                backgroundColor: "rgba(255,255,255,0.1)",
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              <Feather name={hideNetWorth ? "eye-off" : "eye"} size={16} color="rgba(255,255,255,0.7)" />
            </TouchableOpacity>
          </View>
          <View style={styles.headerDivider} />
          <Text style={styles.balanceLabel}>{t("home.monthlyBalance", { month: monthLabel })}</Text>
          <Text style={[styles.balanceAmount, { color: isMonthlyPositive ? colors.income : colors.expense }]}>
            {formatAmount(monthlyBalance)}
          </Text>
          <Text style={styles.balanceSub}>
            {isMonthlyPositive ? t("home.positiveBalance") : t("home.negativeBalance")}
          </Text>
        </View>

        <View style={styles.cardsRow}>
          {/* GELİR KARTI */}
          <TouchableOpacity
            style={styles.summaryCard}
            activeOpacity={0.75}
            onPress={() => router.push({ pathname: "/finans/add", params: { type: "income" } })}
          >
            {/* Üst: ikon + etiket + trend */}
            <View style={styles.summaryCardHeader}>
              <View style={[styles.summaryIconBg, { backgroundColor: colors.incomeBg }]}>
                <Feather name="arrow-down-left" size={16} color={colors.income} />
              </View>
              <Text style={styles.summaryLabel}>{t("home.income")}</Text>
              {incomeTrend !== null && (
                <View style={[styles.trendBadge, { backgroundColor: incomeTrend >= 0 ? colors.incomeBg : colors.expenseBg }]}>
                  <Feather name={incomeTrend >= 0 ? "trending-up" : "trending-down"} size={10} color={incomeTrend >= 0 ? colors.income : colors.expense} />
                  <Text style={[styles.trendText, { color: incomeTrend >= 0 ? colors.income : colors.expense }]}>
                    {Math.abs(Math.round(incomeTrend))}%
                  </Text>
                </View>
              )}
            </View>

            {/* Tutar */}
            <Text style={[styles.summaryAmount, { color: colors.income }]}>
              {formatAmount(monthlyIncome)}
            </Text>

            {/* Alt: işlem sayısı + ay */}
            <View style={styles.summaryDivider} />
            <View style={styles.summaryFooter}>
              <Feather name="repeat" size={10} color={colors.mutedForeground} />
              <Text style={styles.summaryRowLabel}>{t("home.transactions_count", { count: monthlyIncomeCount })}</Text>
            </View>
          </TouchableOpacity>

          {/* GİDER KARTI */}
          <TouchableOpacity
            style={styles.summaryCard}
            activeOpacity={0.75}
            onPress={() => router.push({ pathname: "/finans/add", params: { type: "expense" } })}
          >
            {/* Üst: ikon + etiket + trend */}
            <View style={styles.summaryCardHeader}>
              <View style={[styles.summaryIconBg, { backgroundColor: colors.expenseBg }]}>
                <Feather name="arrow-up-right" size={16} color={colors.expense} />
              </View>
              <Text style={styles.summaryLabel}>{t("home.expense")}</Text>
              {expenseTrend !== null && (
                <View style={[styles.trendBadge, { backgroundColor: expenseTrend > 0 ? colors.expenseBg : colors.incomeBg }]}>
                  <Feather name={expenseTrend > 0 ? "trending-up" : "trending-down"} size={10} color={expenseTrend > 0 ? colors.expense : colors.income} />
                  <Text style={[styles.trendText, { color: expenseTrend > 0 ? colors.expense : colors.income }]}>
                    {Math.abs(Math.round(expenseTrend))}%
                  </Text>
                </View>
              )}
            </View>

            {/* Tutar */}
            <Text style={[styles.summaryAmount, { color: colors.expense }]}>
              {formatAmount(monthlyExpense)}
            </Text>

            {/* Alt: işlem sayısı + harcama oranı bar */}
            <View style={styles.summaryDivider} />
            <View style={styles.summaryFooter}>
              <Feather name="repeat" size={10} color={colors.mutedForeground} />
              <Text style={styles.summaryRowLabel}>{t("home.transactions_count", { count: monthlyExpenseCount })}</Text>
            </View>
            {/* Harcama oranı bar */}
            <View style={styles.spendBar}>
              <View style={[styles.spendBarFill, {
                width: `${Math.round(spendRatio * 100)}%` as any,
                backgroundColor: spendRatio > 0.8 ? colors.expense : spendRatio > 0.5 ? "#F59E0B" : colors.income,
              }]} />
            </View>
            <Text style={styles.spendBarLabel}>
              {t("home.spentOfIncome", { percent: Math.round(spendRatio * 100) })}
            </Text>
          </TouchableOpacity>
        </View>

        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>{t("home.categoryDistribution")}</Text>
          </View>
          <View style={styles.chartCard}>

            {/* Zaman Filtresi */}
            <View style={styles.filterRow}>
              {(
                [
                  { key: "gunluk",      label: "Günlük" },
                  { key: "haftalik",    label: "Haftalık" },
                  { key: "aylik",       label: "Aylık" },
                  { key: "tumzamanlar", label: "Tüm" },
                  { key: "manuel",      label: "Ay Seç" },
                ] as const
              ).map((f) => (
                <TouchableOpacity
                  key={f.key}
                  style={[styles.filterChip, chartFilter === f.key && styles.filterChipActive]}
                  onPress={() => {
                    Haptics.selectionAsync();
                    setChartFilter(f.key);
                    if (f.key === "manuel") { setManualYear(currentYear); setManualMonth(currentMonth); }
                  }}
                  activeOpacity={0.75}
                >
                  <Text style={[styles.filterChipText, chartFilter === f.key && styles.filterChipTextActive]} numberOfLines={1}>
                    {f.label}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>

            {/* Manuel Ay Seçici */}
            {chartFilter === "manuel" && (
              <View style={styles.manualPicker}>
                <TouchableOpacity
                  style={styles.manualPickerArrow}
                  onPress={() => {
                    Haptics.selectionAsync();
                    if (manualMonth === 0) { setManualMonth(11); setManualYear((y) => y - 1); }
                    else setManualMonth((m) => m - 1);
                  }}
                >
                  <Feather name="chevron-left" size={18} color={colors.foreground} />
                </TouchableOpacity>
                <Text style={styles.manualPickerText}>
                  {new Date(manualYear, manualMonth, 1).toLocaleDateString(i18n.language, { month: "long", year: "numeric" })}
                </Text>
                <TouchableOpacity
                  style={[styles.manualPickerArrow, (manualYear === currentYear && manualMonth === currentMonth) && { opacity: 0.35 }]}
                  disabled={manualYear === currentYear && manualMonth === currentMonth}
                  onPress={() => {
                    Haptics.selectionAsync();
                    if (manualMonth === 11) { setManualMonth(0); setManualYear((y) => y + 1); }
                    else setManualMonth((m) => m + 1);
                  }}
                >
                  <Feather name="chevron-right" size={18} color={colors.foreground} />
                </TouchableOpacity>
              </View>
            )}

            {/* Gider / Gelir Seçici */}
            <View style={styles.toggleRow}>
              <TouchableOpacity
                style={[
                  styles.toggleBtn,
                  {
                    backgroundColor: colors.expense,
                    opacity: chartType === "expense" ? 1 : 0.35,
                  },
                ]}
                onPress={() => { Haptics.selectionAsync(); setChartType("expense"); }}
                activeOpacity={0.8}
              >
                <Text style={styles.toggleText}>{t("home.expenses")}</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[
                  styles.toggleBtn,
                  {
                    backgroundColor: colors.income,
                    opacity: chartType === "income" ? 1 : 0.35,
                  },
                ]}
                onPress={() => { Haptics.selectionAsync(); setChartType("income"); }}
                activeOpacity={0.8}
              >
                <Text style={styles.toggleText}>{t("home.incomes")}</Text>
              </TouchableOpacity>
            </View>

            <PieChart
              data={slices}
              size={180}
              centerLabel={t("home.totalLabel")}
              centerValue={formatAmount(chartTotal)}
            />
          </View>
        </View>

      </ScrollView>

      <NotificationsModal
        visible={notifModalOpen}
        onClose={() => setNotifModalOpen(false)}
      />
    </View>
  );
}
