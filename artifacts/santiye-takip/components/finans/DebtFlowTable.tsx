/**
 * DebtFlowTable — "Nakit Akışı"
 *
 * Satırlar : Borç Dökümü ile birebir senkron — her satır bir borç/kart.
 * Sol sütun: BORÇ ADI + Alacaklı · Tür (iki satır, geniş sütun)
 * Aylık sütunlar: O ay için aylık ödeme tutarı (nakit çıkışı)
 *   - Taksitli borç: tutar / taksit sayısı
 *   - Tek borç    : başlangıç ayında tam tutar
 *   - Sabit borç  : her aktif ayda tutar
 *   - Borç aktif değilse: boş (—)
 * Geçmiş aylar: gerçek ödeme kaydı varsa göster, yoksa projeksiyon (soluk)
 */

import React, { useEffect, useMemo, useRef } from "react";
import {
  ScrollView,
  StyleSheet,
  Text,
  TextStyle,
  View,
  ViewStyle,
} from "react-native";
import { useTranslation } from "react-i18next";

import { Debt, useBudget } from "@/context/finans/BudgetContext";
import { useColors } from "@/hooks/finans/useColors";
import {
  findSavedCardForBankLimit,
  getAllStatementsForCard,
} from "@/utils/finans/statements";
import { useFormatAmount } from "@/hooks/finans/useFormatAmount";

// ── Layout ────────────────────────────────────────────────────────────────────

const FIXED_COL = 120;
const DATA_COL  = 84;
const ROW_H     = 44;
const MONTH_H   = 34;

// ── YM helpers ────────────────────────────────────────────────────────────────

function ymToNum(ym: string): number {
  const [y, m] = ym.split("-").map(Number);
  return y * 12 + (m - 1);
}
function numToYM(n: number): string {
  const y = Math.floor(n / 12);
  const m = (n % 12) + 1;
  return `${y}-${String(m).padStart(2, "0")}`;
}
function todayYM(): string {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
}
function dateToYM(date: string): string {
  const d = new Date(date);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
}

// ── Debt active range helpers ─────────────────────────────────────────────────

function debtStartYM(d: Debt): string { return dateToYM(d.date); }

function debtEndYM(d: Debt): string {
  if (d.isInstallment && d.totalInstallments) {
    return numToYM(ymToNum(debtStartYM(d)) + d.totalInstallments - 1);
  }
  if (d.dueDate) return dateToYM(d.dueDate);
  // Sabit borç: 60 ay ileri (5 yıl — pratikte "açık uçlu")
  return numToYM(ymToNum(todayYM()) + 60);
}

// ── Monthly cash-out for a debt in a given YM ─────────────────────────────────

/**
 * Returns { amount, isProjected } for the given YM.
 * amount = 0 means debt is not active that month → show "—"
 * isProjected = true → soft styling (gelecek tahmin)
 */
function monthlyPayment(
  d: Debt,
  ym: string,
  today: string,
  paymentsInMonth: number // actual payments recorded for this ym
): { amount: number; isProjected: boolean } {
  const startYM = debtStartYM(d);
  const endYM   = debtEndYM(d);

  // Borç bu ayda aktif değil
  if (ym < startYM || ym > endYM) return { amount: 0, isProjected: false };

  const isPast   = ym < today;
  const isFuture = ym > today;

  if (d.isInstallment && d.totalInstallments) {
    const monthly = d.amount / d.totalInstallments;
    // Geçmiş ay: gerçek ödeme kaydı varsa onu göster; yoksa projeksiyon
    if (isPast) {
      if (paymentsInMonth > 0.01) return { amount: paymentsInMonth, isProjected: false };
      return { amount: monthly, isProjected: true };
    }
    return { amount: monthly, isProjected: isFuture };
  }

  // Tek borç (single) — sadece başlangıç ayında
  if (!d.isInstallment && !d.dueDate && d.category !== "Sabit Borç") {
    if (ym === startYM) {
      const isProj = isFuture && paymentsInMonth < 0.01;
      return { amount: d.amount, isProjected: isProj };
    }
    return { amount: 0, isProjected: false };
  }

  // Sabit borç & diğer — her aktif ayda tutar
  if (isPast) {
    if (paymentsInMonth > 0.01) return { amount: paymentsInMonth, isProjected: false };
    return { amount: d.amount, isProjected: true };
  }
  return { amount: d.amount, isProjected: isFuture };
}

// ── Props ─────────────────────────────────────────────────────────────────────

interface Props {
  creditorFilter?: string | null;
  debtTypeFilter?: string | null;
}

// ── Row descriptor ────────────────────────────────────────────────────────────

type FlowRow =
  | { kind: "debt"; debt: Debt }
  | { kind: "cc"; id: string; label: string; creditor: string; startYM: string; endYM: string; stmtMap: Map<string, number> }
  | { kind: "od"; id: string; label: string; creditor: string; todayYM: string; usedAmount: number };

// ── Component ─────────────────────────────────────────────────────────────────

export function DebtFlowTable({ creditorFilter, debtTypeFilter }: Props = {}) {
  const { t, i18n } = useTranslation();
  const formatAmount = useFormatAmount();
  const colors = useColors();
  const { debts, bankLimits, savedCards, transactions } = useBudget();
  const scrollRef = useRef<ScrollView>(null);

  const today = todayYM();
  const todayN = ymToNum(today);

  const ccLabel = t("debts.creditCard");
  const odLabel = t("debts.overdraftAccount");

  // ── Filter source data ─────────────────────────────────────────────────────

  const filteredDebts = useMemo(() => {
    let arr = debts.filter((d) => !d.bankLimitId);
    if (creditorFilter) arr = arr.filter((d) => d.creditor?.trim() === creditorFilter);
    // CC or OD type filter → hide ALL manual debts (they are bank-limit rows only)
    if (debtTypeFilter === ccLabel || debtTypeFilter === odLabel) return [];
    if (debtTypeFilter) arr = arr.filter((d) => (d.category || "Diğer") === debtTypeFilter);
    return arr;
  }, [debts, creditorFilter, debtTypeFilter, ccLabel, odLabel]);

  const filteredBankLimits = useMemo(() => {
    let arr = bankLimits;
    if (creditorFilter) arr = arr.filter((bl) => (bl.institution || bl.bank || "").trim() === creditorFilter);
    if (debtTypeFilter) {
      if (debtTypeFilter === odLabel) arr = arr.filter((bl) => bl.type === "overdraft");
      else if (debtTypeFilter === ccLabel) arr = arr.filter((bl) => bl.type === "credit");
      else arr = [];
    }
    return arr;
  }, [bankLimits, creditorFilter, debtTypeFilter, ccLabel, odLabel]);

  // ── Build rows ─────────────────────────────────────────────────────────────

  const rows = useMemo<FlowRow[]>(() => {
    const result: FlowRow[] = [];

    for (const bl of filteredBankLimits) {
      if (bl.type === "overdraft") {
        const used = Math.max(0, (bl.limit ?? 0) - (bl.availableLimit ?? 0));
        if (used < 0.01) continue;
        result.push({
          kind: "od",
          id: bl.id,
          label: bl.institution || bl.bank || odLabel,
          creditor: bl.institution || bl.bank || "—",
          todayYM: today,
          usedAmount: used,
        });
      } else if (bl.type === "credit") {
        const sc = findSavedCardForBankLimit(bl, savedCards);
        const stmts = getAllStatementsForCard({ bankLimit: bl, savedCard: sc, transactions });
        const stmtMap = new Map<string, number>();
        for (const s of stmts) if (s.amount > 0) stmtMap.set(s.yearMonth, s.amount);
        if (stmtMap.size === 0) {
          // Güncel ay için fallback
          const used = typeof bl.availableLimit === "number"
            ? Math.max(0, (bl.limit ?? 0) - bl.availableLimit)
            : 0;
          if (used < 0.01) continue;
          stmtMap.set(today, used);
        }
        const ymNums = Array.from(stmtMap.keys()).map(ymToNum);
        const startYM = numToYM(Math.min(...ymNums));
        const endYM   = numToYM(Math.max(...ymNums));
        result.push({
          kind: "cc",
          id: bl.id,
          label: bl.institution || bl.bank || ccLabel,
          creditor: bl.institution || bl.bank || "—",
          startYM,
          endYM,
          stmtMap,
        });
      }
    }

    for (const d of filteredDebts) {
      result.push({ kind: "debt", debt: d });
    }

    // Alacaklıya göre sırala
    return result.sort((a, b) => {
      const ca = a.kind === "debt" ? (a.debt.creditor || "—") : a.creditor;
      const cb = b.kind === "debt" ? (b.debt.creditor || "—") : b.creditor;
      return ca.localeCompare(cb, "tr");
    });
  }, [filteredDebts, filteredBankLimits, savedCards, transactions, today, ccLabel, odLabel]);

  // ── Column range ───────────────────────────────────────────────────────────

  const columns = useMemo<string[]>(() => {
    if (rows.length === 0) return [];
    let fromN = todayN;
    let toN   = todayN;

    for (const row of rows) {
      if (row.kind === "debt") {
        fromN = Math.min(fromN, ymToNum(debtStartYM(row.debt)));
        toN   = Math.max(toN,   ymToNum(debtEndYM(row.debt)));
      } else if (row.kind === "cc") {
        fromN = Math.min(fromN, ymToNum(row.startYM));
        toN   = Math.max(toN,   ymToNum(row.endYM));
      } else {
        // overdraft: only today
      }
    }

    toN   = Math.min(toN,   todayN + 36); // max 3 yıl ileri
    fromN = Math.max(fromN, todayN - 12); // max 12 ay geri

    const result: string[] = [];
    for (let n = fromN; n <= toN; n++) result.push(numToYM(n));
    return result;
  }, [rows, todayN]);

  // ── Column totals ──────────────────────────────────────────────────────────

  const colTotals = useMemo<Record<string, number>>(() => {
    const t: Record<string, number> = {};
    for (const ym of columns) {
      let sum = 0;
      for (const row of rows) {
        if (row.kind === "debt") {
          const pymInMonth = (row.debt.payments ?? [])
            .filter((p) => dateToYM(p.date) === ym)
            .reduce((s, p) => s + p.amount, 0);
          const { amount } = monthlyPayment(row.debt, ym, today, pymInMonth);
          sum += amount;
        } else if (row.kind === "cc") {
          sum += row.stmtMap.get(ym) ?? 0;
        } else if (row.kind === "od" && ym === today) {
          sum += row.usedAmount;
        }
      }
      t[ym] = sum;
    }
    return t;
  }, [rows, columns, today]);

  // ── Bugüne otomatik scroll ─────────────────────────────────────────────────

  useEffect(() => {
    if (columns.length === 0) return;
    const todayIdx = columns.indexOf(today);
    if (todayIdx < 0) return;
    // Bugünü soldan 1 kolon boşlukla görünür yap (biraz öncesi de gözüksün)
    const x = Math.max(0, (todayIdx - 1) * DATA_COL);
    setTimeout(() => scrollRef.current?.scrollTo({ x, animated: false }), 50);
  }, [columns, today]);

  // ── Empty state ────────────────────────────────────────────────────────────

  if (rows.length === 0) {
    return (
      <View style={[st.wrapper, { borderColor: colors.border, padding: 24, alignItems: "center" }]}>
        <Text style={{ color: colors.mutedForeground, fontSize: 13, textAlign: "center" } as TextStyle}>
          {t("debtFlow.noDebts")}
        </Text>
      </View>
    );
  }

  // ── Render ─────────────────────────────────────────────────────────────────

  return (
    <View style={[st.wrapper, { borderColor: colors.border }]}>
      <View style={st.row}>

        {/* ── Sabit sol sütun ────────────────────────────────────────── */}
        <View>
          {/* Header */}
          <View style={[st.fixedHeader, { backgroundColor: colors.navy, height: MONTH_H, borderRightColor: "rgba(255,255,255,0.15)" }]}>
            <Text style={[st.fixedHeaderTxt, { color: colors.primary }]}>{t("debtFlow.creditorHeader")}</Text>
          </View>

          {/* Data rows */}
          {rows.map((row, idx) => {
            let name = "";
            let sub  = "";
            if (row.kind === "debt") {
              name = row.debt.name;
              const parts = [row.debt.creditor, row.debt.category].filter(Boolean);
              sub = parts.join(" · ");
            } else if (row.kind === "cc") {
              name = row.label;
              sub  = ccLabel;
            } else {
              name = row.label;
              sub  = odLabel;
            }
            return (
              <View
                key={row.kind === "debt" ? row.debt.id : row.id}
                style={[st.fixedCell, {
                  backgroundColor: colors.navy,
                  height: ROW_H,
                  borderRightColor: "rgba(255,255,255,0.12)",
                  borderTopColor: "rgba(255,255,255,0.08)",
                }]}
              >
                <Text style={st.fixedCellName} numberOfLines={1} adjustsFontSizeToFit>
                  {name.toUpperCase()}
                </Text>
                {sub ? (
                  <Text style={st.fixedCellSub} numberOfLines={1}>
                    {sub}
                  </Text>
                ) : null}
              </View>
            );
          })}

          {/* Footer */}
          <View style={[st.fixedFooter, { backgroundColor: colors.primary, height: ROW_H }]}>
            <Text style={st.fixedFooterTxt}>{t("debtFlow.total")}</Text>
          </View>
        </View>

        {/* ── Kaydırılabilir aylık sütunlar ──────────────────────────── */}
        <ScrollView ref={scrollRef} horizontal showsHorizontalScrollIndicator={false} bounces={false}>
          <View>

            {/* Month headers */}
            <View style={st.row}>
              {columns.map((ym) => {
                const isCurr = ym === today;
                const [ymYear, ymMon] = ym.split("-").map(Number);
                return (
                  <View
                    key={ym}
                    style={{
                      width: DATA_COL,
                      height: MONTH_H,
                      backgroundColor: isCurr ? colors.primary : colors.navy,
                      alignItems: "center",
                      justifyContent: "center",
                      borderLeftWidth: 1,
                      borderLeftColor: "rgba(255,255,255,0.12)",
                    } as ViewStyle}
                  >
                    <Text style={{ fontSize: 9, fontWeight: "700", color: isCurr ? "#0B1E33" : "#FFFFFF", letterSpacing: 0.3 } as TextStyle}>
                      {`${new Date(ymYear, ymMon - 1, 1).toLocaleDateString(i18n.language, { month: "short" }).toUpperCase()} ${ymYear}`}
                    </Text>
                    {isCurr && (
                      <Text style={{ fontSize: 7, fontWeight: "800", color: "#0B1E33", opacity: 0.65 } as TextStyle}>
                        {t("debtFlow.today")}
                      </Text>
                    )}
                  </View>
                );
              })}
            </View>

            {/* Data rows */}
            {rows.map((row, rowIdx) => {
              const isAlt = rowIdx % 2 === 1;
              return (
                <View key={row.kind === "debt" ? row.debt.id : row.id} style={st.row}>
                  {columns.map((ym) => {
                    const isCurr   = ym === today;
                    const isFuture = ym > today;
                    let amount = 0;
                    let isProjected = false;
                    let hasData = false;

                    if (row.kind === "debt") {
                      const pymInMonth = (row.debt.payments ?? [])
                        .filter((p) => dateToYM(p.date) === ym)
                        .reduce((s, p) => s + p.amount, 0);
                      const result = monthlyPayment(row.debt, ym, today, pymInMonth);
                      amount = result.amount;
                      isProjected = result.isProjected;
                      hasData = amount > 0.01;
                    } else if (row.kind === "cc") {
                      amount = row.stmtMap.get(ym) ?? 0;
                      hasData = amount > 0.01;
                      isProjected = false;
                    } else if (row.kind === "od") {
                      amount = ym === today ? row.usedAmount : 0;
                      hasData = amount > 0.01;
                    }

                    return (
                      <View
                        key={ym}
                        style={{
                          width: DATA_COL,
                          height: ROW_H,
                          backgroundColor: isCurr
                            ? colors.primary + "18"
                            : isAlt
                            ? colors.muted + "55"
                            : colors.card,
                          alignItems: "flex-end",
                          justifyContent: "center",
                          paddingHorizontal: 6,
                          borderLeftWidth: StyleSheet.hairlineWidth,
                          borderLeftColor: isCurr ? colors.primary + "44" : colors.border,
                          borderTopWidth: StyleSheet.hairlineWidth,
                          borderTopColor: colors.border,
                        } as ViewStyle}
                      >
                        {hasData ? (
                          <Text
                            style={{
                              fontSize: 10,
                              fontWeight: isProjected ? "400" : "600",
                              color: isProjected
                                ? colors.mutedForeground
                                : isFuture
                                ? colors.foreground + "AA"
                                : colors.foreground,
                              fontStyle: isProjected ? "italic" : "normal",
                            } as TextStyle}
                            numberOfLines={1}
                            adjustsFontSizeToFit
                          >
                            {formatAmount(amount)}
                          </Text>
                        ) : (
                          <Text style={{ fontSize: 10, color: colors.border } as TextStyle}>—</Text>
                        )}
                      </View>
                    );
                  })}
                </View>
              );
            })}

            {/* Total footer row */}
            <View style={st.row}>
              {columns.map((ym) => {
                const total  = colTotals[ym] ?? 0;
                const isCurr = ym === today;
                return (
                  <View
                    key={ym}
                    style={{
                      width: DATA_COL,
                      height: ROW_H,
                      backgroundColor: isCurr ? colors.primary : colors.primary + "CC",
                      alignItems: "flex-end",
                      justifyContent: "center",
                      paddingHorizontal: 6,
                      borderLeftWidth: 1,
                      borderLeftColor: "rgba(255,255,255,0.2)",
                    } as ViewStyle}
                  >
                    <Text
                      style={{ fontSize: isCurr ? 11 : 10, fontWeight: "800", color: "#0B1E33" } as TextStyle}
                      numberOfLines={1}
                      adjustsFontSizeToFit
                    >
                      {total > 0.5 ? formatAmount(total) : "—"}
                    </Text>
                  </View>
                );
              })}
            </View>

          </View>
        </ScrollView>
      </View>
    </View>
  );
}

// ── Static styles ─────────────────────────────────────────────────────────────

const st = StyleSheet.create({
  wrapper: { borderRadius: 14, overflow: "hidden", borderWidth: 1 },
  row: { flexDirection: "row" },
  fixedHeader: {
    width: FIXED_COL, alignItems: "center", justifyContent: "center",
    borderRightWidth: 1, paddingHorizontal: 6,
  },
  fixedHeaderTxt: { fontSize: 8, fontWeight: "800", letterSpacing: 0.5, textTransform: "uppercase" } as TextStyle,
  fixedCell: {
    width: FIXED_COL, justifyContent: "center", paddingHorizontal: 8,
    borderRightWidth: 1, borderTopWidth: StyleSheet.hairlineWidth,
  },
  fixedCellName: { fontSize: 9, fontWeight: "800", color: "#FFFFFF", letterSpacing: 0.2 } as TextStyle,
  fixedCellSub: { fontSize: 8, fontWeight: "500", color: "rgba(255,255,255,0.55)", marginTop: 1 } as TextStyle,
  fixedFooter: { width: FIXED_COL, justifyContent: "center", paddingHorizontal: 8 },
  fixedFooterTxt: { fontSize: 9, fontWeight: "900", color: "#0B1E33", letterSpacing: 0.5 } as TextStyle,
});
