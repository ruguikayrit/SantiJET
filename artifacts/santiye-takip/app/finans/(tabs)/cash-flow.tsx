import { Feather } from "@expo/vector-icons";
import * as Haptics from "expo-haptics";
import { useRouter } from "expo-router";
import React, { useMemo, useRef, useState } from "react";
import {
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import { Debt, useBudget } from "@/context/finans/BudgetContext";
import { useColors } from "@/hooks/finans/useColors";
import { useFormatAmount } from "@/hooks/finans/useFormatAmount";
import {
  findSavedCardForBankLimit,
  formatStatementYearMonth,
  getAllStatementsForCard,
  type ResolvedStatement,
} from "@/utils/finans/statements";

function toYearMonth(date: Date): string {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, "0");
  return `${y}-${m}`;
}

function addMonths(ym: string, delta: number): string {
  const [y, m] = ym.split("-").map(Number);
  const d = new Date(y, m - 1 + delta, 1);
  return toYearMonth(d);
}

function formatYearMonth(ym: string): string {
  const [y, m] = ym.split("-").map(Number);
  const months = [
    "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
    "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık",
  ];
  return `${months[m - 1]} ${y}`;
}

function formatYearMonthShort(ym: string): string {
  const [y, m] = ym.split("-").map(Number);
  const months = ["Oca","Şub","Mar","Nis","May","Haz","Tem","Ağu","Eyl","Eki","Kas","Ara"];
  return `${months[m - 1]}\n${y}`;
}

function installmentDate(startIso: string, index: number): Date {
  const d = new Date(startIso);
  d.setMonth(d.getMonth() + index);
  return d;
}

function getPaidSet(d: Debt): Set<number> {
  if (Array.isArray(d.paidInstallmentIndices) && d.paidInstallmentIndices.length > 0) {
    return new Set(d.paidInstallmentIndices);
  }
  return new Set(Array.from({ length: d.paidInstallments ?? 0 }, (_, i) => i));
}

type InstallmentItem = { debt: Debt; index: number; amount: number; paid: boolean };

// A scheduled CC statement payment that lives in cash-flow rows.
type StatementItem = {
  bankLimitId: string;
  cardName: string;
  yearMonth: string;          // statement period YM (= "Nisan ekstresi" identifier)
  dueDate: Date;
  amount: number;             // total amount to be paid in dueDate's month
  remaining: number;
  isFullyPaid: boolean;
  hasManualOverride: boolean;
  isAuto: boolean;            // computed from transactions, no manual entry
};

// A past period that has neither manual override nor any transactions.
type MissingStatement = {
  bankLimitId: string;
  cardName: string;
  yearMonth: string;
};

type FilterType = "all" | "installment" | "statement";

const TIMELINE_MONTHS = 24;

export default function CashFlowScreen() {
  const formatAmount = useFormatAmount();
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const { debts, bankLimits, savedCards, transactions } = useBudget();

  const topInset = Platform.OS === "web" ? 67 : insets.top;
  const bottomInset = Platform.OS === "web" ? 34 : insets.bottom;

  const timelineRef = useRef<ScrollView>(null);
  const todayYM = toYearMonth(new Date());
  const [selectedYM, setSelectedYM] = useState(todayYM);
  const [filterType, setFilterType] = useState<FilterType>("all");
  const [instExpanded, setInstExpanded] = useState(true);
  const [stExpanded, setStExpanded] = useState(true);

  const allExpanded = instExpanded && stExpanded;
  const toggleAll = () => {
    Haptics.selectionAsync();
    const next = !allExpanded;
    setInstExpanded(next);
    setStExpanded(next);
  };

  // Resolve all statements across all CC cards once
  const allCardStatements = useMemo(() => {
    const map = new Map<
      string,
      { bankLimitId: string; cardName: string; statements: ResolvedStatement[] }
    >();
    for (const bl of bankLimits) {
      const sc = findSavedCardForBankLimit(bl, savedCards);
      const stmts = getAllStatementsForCard({
        bankLimit: bl,
        savedCard: sc,
        transactions,
      });
      map.set(bl.id, {
        bankLimitId: bl.id,
        cardName: bl.bank,
        statements: stmts,
      });
    }
    return map;
  }, [bankLimits, savedCards, transactions]);

  // Past periods that have no auto and no manual data → user needs to enter manually
  const missingStatements = useMemo<MissingStatement[]>(() => {
    const out: MissingStatement[] = [];
    for (const { bankLimitId, cardName, statements } of allCardStatements.values()) {
      for (const s of statements) {
        if (s.isActive || s.isFuture) continue; // only past
        if (s.hasData) continue;                  // already has amount
        out.push({ bankLimitId, cardName, yearMonth: s.yearMonth });
      }
    }
    out.sort((a, b) => a.yearMonth.localeCompare(b.yearMonth));
    return out;
  }, [allCardStatements]);

  // Statement items bucketed by dueDate's YM (when money actually leaves)
  const statementsForMonth = useMemo<StatementItem[]>(() => {
    const out: StatementItem[] = [];
    for (const { bankLimitId, cardName, statements } of allCardStatements.values()) {
      for (const s of statements) {
        if (s.isFuture) continue; // future periods aren't real bills yet
        if (!s.hasData) continue; // skip empty
        const dueYM = toYearMonth(s.dueDate);
        if (dueYM !== selectedYM) continue;
        out.push({
          bankLimitId,
          cardName,
          yearMonth: s.yearMonth,
          dueDate: s.dueDate,
          amount: s.amount,
          remaining: s.remaining,
          isFullyPaid: s.isFullyPaid,
          hasManualOverride: s.manualAmount !== undefined,
          isAuto: s.manualAmount === undefined,
        });
      }
    }
    out.sort((a, b) => a.dueDate.getTime() - b.dueDate.getTime());
    return out;
  }, [allCardStatements, selectedYM]);

  // 24-month timeline data
  const timeline = useMemo(() => {
    // Pre-bucket statements by dueDate YM
    const stByMonth = new Map<string, number>();
    for (const { statements } of allCardStatements.values()) {
      for (const s of statements) {
        if (s.isFuture) continue;
        if (!s.hasData) continue;
        const dueYM = toYearMonth(s.dueDate);
        stByMonth.set(dueYM, (stByMonth.get(dueYM) ?? 0) + s.remaining);
      }
    }

    const result: { ym: string; instTotal: number; stTotal: number }[] = [];
    for (let delta = 0; delta < TIMELINE_MONTHS; delta++) {
      const ym = addMonths(todayYM, delta);
      let instTotal = 0;
      for (const d of debts) {
        if (!d.isInstallment || !d.totalInstallments) continue;
        const perAmount = d.amount / d.totalInstallments;
        const paidSet = getPaidSet(d);
        for (let i = 0; i < d.totalInstallments; i++) {
          const due = installmentDate(d.date, i);
          if (toYearMonth(due) === ym && !paidSet.has(i)) {
            instTotal += perAmount;
          }
        }
      }
      const stTotal = stByMonth.get(ym) ?? 0;
      result.push({ ym, instTotal, stTotal });
    }
    return result;
  }, [debts, todayYM, allCardStatements]);

  // Installment items for selected month
  const installmentItems = useMemo<InstallmentItem[]>(() => {
    const result: InstallmentItem[] = [];
    for (const d of debts) {
      if (!d.isInstallment || !d.totalInstallments) continue;
      const perAmount = d.amount / d.totalInstallments;
      const paidSet = getPaidSet(d);
      for (let i = 0; i < d.totalInstallments; i++) {
        const due = installmentDate(d.date, i);
        if (toYearMonth(due) === selectedYM) {
          result.push({ debt: d, index: i, amount: perAmount, paid: paidSet.has(i) });
        }
      }
    }
    return result.sort((a, b) => a.debt.name.localeCompare(b.debt.name, "tr"));
  }, [debts, selectedYM]);

  const showInst = filterType === "all" || filterType === "installment";
  const showSt = filterType === "all" || filterType === "statement";

  const totalInstallments = installmentItems.reduce(
    (s, it) => s + (it.paid ? 0 : it.amount),
    0
  );
  const totalStatements = statementsForMonth.reduce(
    (s, it) => s + (it.isFullyPaid ? 0 : it.remaining),
    0
  );
  const totalCashNeed = totalInstallments + totalStatements;

  const styles = StyleSheet.create({
    container: { flex: 1, backgroundColor: colors.background },
    header: {
      backgroundColor: colors.navy,
      paddingTop: topInset + 16,
      paddingBottom: 20,
      paddingHorizontal: 20,
    },
    headerTopRow: {
      flexDirection: "row", alignItems: "center",
      justifyContent: "space-between", marginBottom: 16,
    },
    headerLeft: { flexDirection: "row", alignItems: "center", gap: 10 },
    backBtn: {
      width: 36, height: 36, borderRadius: 18,
      backgroundColor: "rgba(255,255,255,0.12)",
      alignItems: "center", justifyContent: "center",
    },
    headerTitle: { fontSize: 20, fontWeight: "800", color: "#FFFFFF" },
    summaryRow: { flexDirection: "row", gap: 10 },
    summaryCard: {
      flex: 1, backgroundColor: "rgba(255,255,255,0.08)", borderRadius: 14,
      paddingVertical: 12, paddingHorizontal: 12,
    },
    summaryLabel: { fontSize: 10, fontWeight: "600", color: "rgba(255,255,255,0.65)", marginBottom: 4 },
    summaryValue: { fontSize: 15, fontWeight: "800", color: "#FFFFFF" },
    body: { paddingHorizontal: 16, paddingTop: 20 },
    // Warning bar
    warnCard: {
      backgroundColor: "#FF4D6D14",
      borderWidth: 1,
      borderColor: "#FF4D6D40",
      borderRadius: 12,
      padding: 12,
      marginBottom: 16,
    },
    warnTitle: {
      fontSize: 12,
      fontWeight: "800" as const,
      color: colors.expense,
      marginBottom: 6,
      letterSpacing: 0.4,
    },
    warnRow: {
      flexDirection: "row",
      alignItems: "center",
      gap: 8,
      paddingVertical: 6,
    },
    warnText: {
      flex: 1,
      fontSize: 13,
      color: colors.foreground,
      fontWeight: "500" as const,
    },
    warnLink: {
      fontSize: 12,
      fontWeight: "700" as const,
      color: colors.primary,
    },
    // Timeline
    upcomingTitle: {
      fontSize: 11, fontWeight: "800", color: colors.mutedForeground,
      letterSpacing: 0.5, marginBottom: 10,
    },
    timelineScroll: { marginBottom: 20 },
    timelineCard: {
      backgroundColor: colors.card, borderRadius: 12, padding: 10,
      marginRight: 8, width: 88, borderWidth: 1, borderColor: colors.border,
      alignItems: "center",
    },
    timelineCardActive: { borderColor: colors.primary, backgroundColor: colors.primary + "10" },
    timelineMonth: { fontSize: 11, fontWeight: "700", color: colors.foreground, marginBottom: 6, textAlign: "center" },
    timelineMonthActive: { color: colors.primary },
    timelineBar: { width: "100%", marginTop: 4 },
    timelineBarLabel: { fontSize: 9, color: colors.mutedForeground, textAlign: "center" },
    timelineBarValue: { fontSize: 10, fontWeight: "700", textAlign: "center" },
    timelineTotal: {
      fontSize: 10, fontWeight: "800", color: colors.foreground,
      marginTop: 6, paddingTop: 4,
      borderTopWidth: 1, borderTopColor: colors.border, textAlign: "center", width: "100%",
    },
    // Filter chips
    filterRow: {
      flexDirection: "row", gap: 8, marginBottom: 16, flexWrap: "wrap",
    },
    chip: {
      flexDirection: "row", alignItems: "center", gap: 5,
      paddingHorizontal: 12, paddingVertical: 7, borderRadius: 20,
      backgroundColor: colors.muted, borderWidth: 1, borderColor: colors.border,
    },
    chipActive: {
      backgroundColor: colors.primary + "20", borderColor: colors.primary,
    },
    chipText: { fontSize: 12, fontWeight: "600", color: colors.mutedForeground },
    chipTextActive: { color: colors.primary },
    // Section
    sectionHeader: {
      flexDirection: "row", alignItems: "center", justifyContent: "space-between",
      marginBottom: 10,
    },
    sectionLeft: { flexDirection: "row", alignItems: "center", gap: 8 },
    sectionTitle: {
      fontSize: 11, fontWeight: "800", color: colors.mutedForeground,
      letterSpacing: 0.5,
    },
    sectionCount: {
      fontSize: 10, fontWeight: "700", color: colors.primary,
      backgroundColor: colors.primary + "20", paddingHorizontal: 6,
      paddingVertical: 2, borderRadius: 8,
    },
    chevronBtn: {
      width: 28, height: 28, borderRadius: 8, backgroundColor: colors.muted,
      alignItems: "center", justifyContent: "center",
    },
    // Cards
    card: {
      backgroundColor: colors.card, borderRadius: 14, padding: 14,
      flexDirection: "row", alignItems: "center", gap: 12,
      marginBottom: 8, borderWidth: 1, borderColor: colors.border,
    },
    cardIconBg: {
      width: 38, height: 38, borderRadius: 12,
      alignItems: "center", justifyContent: "center",
    },
    cardBody: { flex: 1 },
    cardName: { fontSize: 14, fontWeight: "600", color: colors.foreground },
    cardSub: { fontSize: 12, color: colors.mutedForeground, marginTop: 1 },
    cardSubRow: { flexDirection: "row", alignItems: "center", gap: 6, marginTop: 2 },
    autoBadge: {
      fontSize: 9, fontWeight: "700" as const, color: colors.primary,
      backgroundColor: colors.primary + "18", paddingHorizontal: 5,
      paddingVertical: 1, borderRadius: 5, overflow: "hidden",
    },
    manualBadge: {
      fontSize: 9, fontWeight: "700" as const, color: "#7C3AED",
      backgroundColor: "#7C3AED18", paddingHorizontal: 5,
      paddingVertical: 1, borderRadius: 5, overflow: "hidden",
    },
    cardRight: { alignItems: "flex-end", gap: 4 },
    cardAmount: { fontSize: 14, fontWeight: "700", color: colors.foreground },
    paidBadge: {
      fontSize: 10, fontWeight: "700", color: colors.income,
      backgroundColor: colors.income + "22", paddingHorizontal: 6,
      paddingVertical: 2, borderRadius: 6, overflow: "hidden",
    },
    unpaidBadge: {
      fontSize: 10, fontWeight: "700", color: "#F59E0B",
      backgroundColor: "#F59E0B22", paddingHorizontal: 6,
      paddingVertical: 2, borderRadius: 6, overflow: "hidden",
    },
    emptyText: {
      textAlign: "center", color: colors.mutedForeground, fontSize: 13,
      paddingVertical: 16, fontStyle: "italic",
    },
    divider: { height: 1, backgroundColor: colors.border, marginVertical: 18 },
    totalCard: {
      backgroundColor: colors.navy + "18", borderRadius: 14, padding: 16,
      flexDirection: "row", justifyContent: "space-between", alignItems: "center",
      marginBottom: 18, borderWidth: 1, borderColor: colors.navy + "30",
    },
    totalLabel: { fontSize: 14, fontWeight: "700", color: colors.foreground },
    totalAmount: { fontSize: 18, fontWeight: "800", color: colors.navy },
    expandAllBtn: {
      width: 34, height: 34, borderRadius: 10,
      backgroundColor: colors.muted, borderWidth: 1, borderColor: colors.border,
      alignItems: "center", justifyContent: "center",
    },
  });

  const filterChips: { key: FilterType; label: string; icon: string }[] = [
    { key: "all", label: "Tümü", icon: "list" },
    { key: "installment", label: "Taksitler", icon: "layers" },
    { key: "statement", label: "Kart Ekstreleri", icon: "credit-card" },
  ];

  return (
    <View style={styles.container}>
      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={{ paddingBottom: bottomInset + 100 }}
      >
        {/* Header */}
        <View style={styles.header}>
          <View style={styles.headerTopRow}>
            <View style={styles.headerLeft}>
              <TouchableOpacity style={styles.backBtn} onPress={() => { Haptics.selectionAsync(); router.back(); }}>
                <Feather name="chevron-left" size={22} color="#FFFFFF" />
              </TouchableOpacity>
              <Text style={styles.headerTitle}>Nakit Akışı</Text>
            </View>
          </View>

          {/* Summary cards */}
          <View style={styles.summaryRow}>
            <View style={styles.summaryCard}>
              <Text style={styles.summaryLabel}>TAKSİT</Text>
              <Text style={styles.summaryValue}>{formatAmount(totalInstallments)}</Text>
            </View>
            <View style={styles.summaryCard}>
              <Text style={styles.summaryLabel}>KART EKSTRELERİ</Text>
              <Text style={styles.summaryValue}>{formatAmount(totalStatements)}</Text>
            </View>
            <View style={styles.summaryCard}>
              <Text style={styles.summaryLabel}>TOPLAM İHTİYAÇ</Text>
              <Text style={[styles.summaryValue, { color: "#FF6B8A" }]}>{formatAmount(totalCashNeed)}</Text>
            </View>
          </View>
        </View>

        <View style={styles.body}>
          {/* Missing statement warnings */}
          {missingStatements.length > 0 && (
            <View style={styles.warnCard}>
              <Text style={styles.warnTitle}>EKSİK EKSTRE UYARISI</Text>
              {missingStatements.map((m) => (
                <TouchableOpacity
                  key={`${m.bankLimitId}-${m.yearMonth}`}
                  style={styles.warnRow}
                  onPress={() => {
                    Haptics.selectionAsync();
                    router.push(`/debts?cardId=${m.bankLimitId}` as any);
                  }}
                >
                  <Feather name="alert-triangle" size={16} color={colors.expense} />
                  <Text style={styles.warnText}>
                    {m.cardName} için {formatStatementYearMonth(m.yearMonth)}{" "}
                    ekstresi girilmemiş
                  </Text>
                  <Text style={styles.warnLink}>Gir →</Text>
                </TouchableOpacity>
              ))}
            </View>
          )}

          {/* 24-month timeline */}
          <Text style={styles.upcomingTitle}>24 AYLIK ÖZET — AY SEÇ</Text>
          <ScrollView
            ref={timelineRef}
            horizontal
            showsHorizontalScrollIndicator={false}
            style={styles.timelineScroll}
          >
            {timeline.map(({ ym, instTotal, stTotal }) => {
              const isActive = ym === selectedYM;
              const grandTotal = instTotal + stTotal;
              const isToday = ym === todayYM;
              return (
                <TouchableOpacity
                  key={ym}
                  style={[styles.timelineCard, isActive && styles.timelineCardActive]}
                  onPress={() => { Haptics.selectionAsync(); setSelectedYM(ym); }}
                >
                  <Text style={[styles.timelineMonth, isActive && styles.timelineMonthActive]}>
                    {formatYearMonthShort(ym)}
                    {isToday ? "\n●" : ""}
                  </Text>
                  {instTotal > 0 && (
                    <View style={styles.timelineBar}>
                      <Text style={styles.timelineBarLabel}>Taksit</Text>
                      <Text style={[styles.timelineBarValue, { color: "#F59E0B" }]}>
                        {formatAmount(instTotal)}
                      </Text>
                    </View>
                  )}
                  {stTotal > 0 && (
                    <View style={styles.timelineBar}>
                      <Text style={styles.timelineBarLabel}>Kart</Text>
                      <Text style={[styles.timelineBarValue, { color: colors.expense }]}>
                        {formatAmount(stTotal)}
                      </Text>
                    </View>
                  )}
                  {grandTotal > 0 ? (
                    <Text style={[styles.timelineTotal, isActive && { color: colors.primary }]}>
                      {formatAmount(grandTotal)}
                    </Text>
                  ) : (
                    <Text style={[styles.timelineTotal, { color: colors.mutedForeground, fontWeight: "400" }]}>—</Text>
                  )}
                </TouchableOpacity>
              );
            })}
          </ScrollView>

          {/* Filter chips + Expand all */}
          <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 12 }}>
            <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.filterRow}>
              {filterChips.map((fc) => {
                const active = filterType === fc.key;
                return (
                  <TouchableOpacity
                    key={fc.key}
                    style={[styles.chip, active && styles.chipActive]}
                    onPress={() => { Haptics.selectionAsync(); setFilterType(fc.key); }}
                  >
                    <Feather name={fc.icon as any} size={11} color={active ? colors.primary : colors.mutedForeground} />
                    <Text style={[styles.chipText, active && styles.chipTextActive]}>{fc.label}</Text>
                  </TouchableOpacity>
                );
              })}
            </ScrollView>
            <TouchableOpacity style={styles.expandAllBtn} onPress={toggleAll}>
              <Feather name={allExpanded ? "chevrons-up" : "chevrons-down"} size={16} color={colors.primary} />
            </TouchableOpacity>
          </View>

          {/* Taksitli ödemeler section */}
          {showInst && (
            <>
              <View style={styles.sectionHeader}>
                <View style={styles.sectionLeft}>
                  <Text style={styles.sectionTitle}>TAKSİTLİ ÖDEMELER</Text>
                  <Text style={styles.sectionCount}>{installmentItems.length}</Text>
                </View>
                <TouchableOpacity
                  style={styles.chevronBtn}
                  onPress={() => { Haptics.selectionAsync(); setInstExpanded((v) => !v); }}
                >
                  <Feather name={instExpanded ? "chevron-up" : "chevron-down"} size={16} color={colors.foreground} />
                </TouchableOpacity>
              </View>

              {instExpanded && (
                installmentItems.length === 0 ? (
                  <Text style={styles.emptyText}>Bu ay taksit ödemesi yok</Text>
                ) : (
                  installmentItems.map((it) => (
                    <View key={`${it.debt.id}-${it.index}`} style={[styles.card, it.paid && { opacity: 0.55 }]}>
                      <View style={[styles.cardIconBg, { backgroundColor: it.paid ? colors.income + "22" : "#F59E0B22" }]}>
                        <Feather name="layers" size={18} color={it.paid ? colors.income : "#F59E0B"} />
                      </View>
                      <View style={styles.cardBody}>
                        <Text style={styles.cardName}>{it.debt.name}</Text>
                        <Text style={styles.cardSub}>
                          {it.debt.creditor ? `${it.debt.creditor} • ` : ""}
                          {it.index + 1}/{it.debt.totalInstallments}. taksit
                        </Text>
                      </View>
                      <View style={styles.cardRight}>
                        <Text style={styles.cardAmount}>{formatAmount(it.amount)}</Text>
                        <Text style={it.paid ? styles.paidBadge : styles.unpaidBadge}>
                          {it.paid ? "Ödendi" : "Bekliyor"}
                        </Text>
                      </View>
                    </View>
                  ))
                )
              )}

              {showSt && <View style={styles.divider} />}
            </>
          )}

          {/* Kart ekstre ödemeleri section */}
          {showSt && (
            <>
              <View style={styles.sectionHeader}>
                <View style={styles.sectionLeft}>
                  <Text style={styles.sectionTitle}>KART EKSTRE ÖDEMELERİ</Text>
                  <Text style={styles.sectionCount}>{statementsForMonth.length}</Text>
                </View>
                <TouchableOpacity
                  style={styles.chevronBtn}
                  onPress={() => { Haptics.selectionAsync(); setStExpanded((v) => !v); }}
                >
                  <Feather name={stExpanded ? "chevron-up" : "chevron-down"} size={16} color={colors.foreground} />
                </TouchableOpacity>
              </View>

              {stExpanded && (
                statementsForMonth.length === 0 ? (
                  <Text style={styles.emptyText}>
                    Bu ay vadesi gelen kart ekstresi yok.
                  </Text>
                ) : (
                  statementsForMonth.map((it) => (
                    <View
                      key={`${it.bankLimitId}-${it.yearMonth}`}
                      style={[styles.card, it.isFullyPaid && { opacity: 0.55 }]}
                    >
                      <View style={[styles.cardIconBg, { backgroundColor: it.isFullyPaid ? colors.income + "22" : colors.expense + "18" }]}>
                        <Feather name="credit-card" size={18} color={it.isFullyPaid ? colors.income : colors.expense} />
                      </View>
                      <View style={styles.cardBody}>
                        <Text style={styles.cardName}>{it.cardName}</Text>
                        <Text style={styles.cardSub}>
                          {formatStatementYearMonth(it.yearMonth)} ekstresi •
                          {" "}vade {it.dueDate.toLocaleDateString("tr-TR", { day: "numeric", month: "short" })}
                        </Text>
                        <View style={styles.cardSubRow}>
                          <Text style={it.hasManualOverride ? styles.manualBadge : styles.autoBadge}>
                            {it.hasManualOverride ? "MANUEL" : "OTOMATİK"}
                          </Text>
                        </View>
                      </View>
                      <View style={styles.cardRight}>
                        <Text style={[styles.cardAmount, { color: it.isFullyPaid ? colors.income : colors.expense }]}>
                          {formatAmount(it.isFullyPaid ? it.amount : it.remaining)}
                        </Text>
                        <Text style={it.isFullyPaid ? styles.paidBadge : styles.unpaidBadge}>
                          {it.isFullyPaid ? "Ödendi" : "Bekliyor"}
                        </Text>
                      </View>
                    </View>
                  ))
                )
              )}
            </>
          )}

          {/* Total card */}
          {totalCashNeed > 0 && (
            <View style={[styles.totalCard, { marginTop: 20 }]}>
              <View>
                <Text style={styles.totalLabel}>Bu Ay Toplam Nakit İhtiyacı</Text>
                <Text style={[styles.cardSub, { marginTop: 2, color: colors.mutedForeground }]}>
                  {formatYearMonth(selectedYM)}
                </Text>
              </View>
              <Text style={styles.totalAmount}>{formatAmount(totalCashNeed)}</Text>
            </View>
          )}
        </View>
      </ScrollView>
    </View>
  );
}
