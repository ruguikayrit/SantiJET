/**
 * DebtSummaryTable — "Borç Özeti"
 *
 * Satırlar : Borç Dökümü ile birebir senkron — her satır bir borç kaydı.
 * Sol sütunlar: ALACAKLI | BORÇ TÜRÜ (iki sabit sütun)
 * Sağ sütunlar: Borç Tutarı | Ödenen | Kalan
 * Sadece seçili ayda aktif olan borçlar gösterilir.
 */

import React, { useMemo, useState } from "react";
import {
  ScrollView,
  StyleSheet,
  Text,
  TextStyle,
  TouchableOpacity,
  View,
  ViewStyle,
} from "react-native";
import { Ionicons } from "@expo/vector-icons";
import { useTranslation } from "react-i18next";

import { useBudget } from "@/context/finans/BudgetContext";
import { useColors } from "@/hooks/finans/useColors";
import {
  findSavedCardForBankLimit,
  getAllStatementsForCard,
} from "@/utils/finans/statements";
import { useFormatAmount } from "@/hooks/finans/useFormatAmount";

// ── Layout ────────────────────────────────────────────────────────────────────

const COL_LEFT  = 110;  // Alacaklı + Borç Türü (birleşik)
const COL_NUM   = 88;   // veri sütunları
const ROW_H     = 52;
const HDR_H     = 44;

// ── YM helpers ────────────────────────────────────────────────────────────────

function todayYM(): string {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
}
function ymToNum(ym: string): number {
  const [y, m] = ym.split("-").map(Number);
  return y * 12 + (m - 1);
}
function numToYM(n: number): string {
  const y = Math.floor(n / 12);
  const m = (n % 12) + 1;
  return `${y}-${String(m).padStart(2, "0")}`;
}
function ymLabel(ym: string, lang: string): string {
  const [y, m] = ym.split("-").map(Number);
  const monthName = new Date(y, m - 1, 1).toLocaleDateString(lang, { month: "long" });
  return `${monthName} ${y}`;
}
function debtEndYM(d: { date: string; isInstallment: boolean; totalInstallments?: number; dueDate?: string }): string {
  if (d.isInstallment && d.totalInstallments) {
    const start = new Date(d.date);
    const startYM = `${start.getFullYear()}-${String(start.getMonth() + 1).padStart(2, "0")}`;
    return numToYM(ymToNum(startYM) + d.totalInstallments - 1);
  }
  if (d.dueDate) {
    const dt = new Date(d.dueDate);
    return `${dt.getFullYear()}-${String(dt.getMonth() + 1).padStart(2, "0")}`;
  }
  return numToYM(ymToNum(todayYM()) + 120); // sabit borç: uzak geleceğe kadar aktif
}

// ── Remaining helpers ─────────────────────────────────────────────────────────

function installmentRemainingAtYM(
  amount: number,
  date: string,
  totalInstallments: number,
  ym: string
): number {
  const startDate = new Date(date);
  const startYM = `${startDate.getFullYear()}-${String(startDate.getMonth() + 1).padStart(2, "0")}`;
  if (ym < startYM) return 0;
  const N = Math.max(1, totalInstallments);
  const monthly = amount / N;
  const elapsed = ymToNum(ym) - ymToNum(startYM) + 1;
  const paid = Math.min(elapsed, N);
  return Math.max(0, amount - paid * monthly);
}

function regularRemainingAtYM(
  amount: number,
  payments: { date: string; amount: number }[],
  ym: string
): number {
  const [y, m] = ym.split("-").map(Number);
  const endOfMonth = new Date(y, m, 0, 23, 59, 59, 999);
  const paidBefore = payments
    .filter((p) => new Date(p.date) <= endOfMonth)
    .reduce((s, p) => s + p.amount, 0);
  return Math.max(0, amount - paidBefore);
}

// ── Row type ──────────────────────────────────────────────────────────────────

type SummaryRow = {
  id: string;
  creditor: string;  // alacaklı
  debtType: string;  // borç türü
  label: string;     // borç adı
  toplam: number;
  odenen: number;
  kalan: number;
};

// ── Props ─────────────────────────────────────────────────────────────────────

interface Props {
  creditorFilter?: string | null;
  debtTypeFilter?: string | null;
}

// ── Component ─────────────────────────────────────────────────────────────────

export function DebtSummaryTable({ creditorFilter, debtTypeFilter }: Props = {}) {
  const formatAmount = useFormatAmount();
  const colors = useColors();
  const { t, i18n } = useTranslation();
  const { debts, bankLimits, savedCards, transactions } = useBudget();

  const currentYM = todayYM();
  const [selectedYM, setSelectedYM] = useState(currentYM);
  const isCurrent = selectedYM === currentYM;

  const goPrev = () => setSelectedYM((ym) => numToYM(ymToNum(ym) - 1));
  const goNext = () => {
    if (!isCurrent) setSelectedYM((ym) => numToYM(ymToNum(ym) + 1));
  };

  // ── Filtered source data ───────────────────────────────────────────────────

  const ccLabel = t("debts.creditCard");
  const odLabel = t("debts.overdraftAccount");

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

  // ── Compute rows (one row per debt / CC card) ──────────────────────────────

  const rows = useMemo<SummaryRow[]>(() => {
    const result: SummaryRow[] = [];

    // ── Bank limits (CC + overdraft) ────────────────────────────────────────
    for (const bl of filteredBankLimits) {
      const creditor = bl.institution || bl.bank || "—";

      if (bl.type === "overdraft") {
        if (selectedYM !== currentYM) continue; // sadece güncel ay
        const used = Math.max(0, (bl.limit ?? 0) - (bl.availableLimit ?? 0));
        if (used < 0.01) continue;
        result.push({
          id: `od-${bl.id}`,
          creditor,
          debtType: odLabel,
          label: bl.institution || bl.bank || odLabel,
          toplam: bl.limit ?? 0,
          odenen: 0,
          kalan: used,
        } as SummaryRow);
      } else if (bl.type === "credit") {
        const sc = findSavedCardForBankLimit(bl, savedCards);
        const stmts = getAllStatementsForCard({ bankLimit: bl, savedCard: sc, transactions });
        const stmt = stmts.find((s) => s.yearMonth === selectedYM);
        if (!stmt && selectedYM !== currentYM) continue; // geçmiş ay, veri yoksa atla
        const stmtAmt = stmt?.amount ?? 0;
        const fallback =
          stmtAmt === 0 && selectedYM === currentYM && typeof bl.availableLimit === "number"
            ? Math.max(0, (bl.limit ?? 0) - bl.availableLimit)
            : 0;
        const amt = stmtAmt > 0 ? stmtAmt : fallback;
        if (amt < 0.01) continue;
        const paid = stmtAmt > 0 ? (stmt?.paidAmount ?? 0) : 0;
        result.push({
          id: `cc-${bl.id}`,
          creditor,
          debtType: ccLabel,
          label: bl.institution || bl.bank || ccLabel,
          toplam: amt,
          odenen: paid,
          kalan: Math.max(0, amt - paid),
        } as SummaryRow);
      }
    }

    // ── Manual debts ────────────────────────────────────────────────────────
    for (const d of filteredDebts) {
      const startDate = new Date(d.date);
      const startYM = `${startDate.getFullYear()}-${String(startDate.getMonth() + 1).padStart(2, "0")}`;
      if (startYM > selectedYM) continue; // henüz başlamamış

      const endYM = debtEndYM(d);
      // Taksitli borçlar: bitiş ayından sonra gösterme
      if (d.isInstallment && selectedYM > endYM) continue;

      const kalan = d.isInstallment
        ? installmentRemainingAtYM(d.amount, d.date, d.totalInstallments ?? 1, selectedYM)
        : regularRemainingAtYM(d.amount, d.payments ?? [], selectedYM);

      // Geçmiş ay, kalan 0 → tamamen ödendi, gösterme
      if (selectedYM < currentYM && kalan < 0.01) continue;

      const odenen = Math.max(0, d.amount - kalan);

      result.push({
        id: d.id,
        creditor: d.creditor?.trim() || "—",
        debtType: d.category || "Diğer",
        label: d.name,
        toplam: d.amount,
        odenen,
        kalan,
      });
    }

    // Alacaklıya göre, sonra borç türüne göre sırala
    return result.sort((a, b) =>
      a.creditor.localeCompare(b.creditor, "tr") || a.debtType.localeCompare(b.debtType, "tr")
    );
  }, [
    filteredDebts,
    filteredBankLimits,
    savedCards,
    transactions,
    selectedYM,
    currentYM,
    ccLabel,
    odLabel,
  ]);

  const grandTotal = useMemo(
    () =>
      rows.reduce(
        (acc, r) => ({
          toplam: acc.toplam + r.toplam,
          odenen: acc.odenen + (r as any).odenen,
          kalan: acc.kalan + r.kalan,
        }),
        { toplam: 0, odenen: 0, kalan: 0 }
      ),
    [rows]
  );

  const isEmpty = rows.length === 0;

  const COLS: { key: "toplam" | "odenen" | "kalan"; label: string; accent?: boolean }[] = [
    { key: "toplam", label: t("debtSummary.debtAmount") },
    { key: "odenen", label: t("debtSummary.paid") },
    { key: "kalan",  label: t("debtSummary.remaining"), accent: true },
  ];

  return (
    <View style={[s.container, { borderColor: colors.border }]}>

      {/* Month Picker */}
      <View style={[s.picker, { backgroundColor: colors.card, borderBottomColor: colors.border }]}>
        <TouchableOpacity onPress={goPrev} style={s.arrowBtn} hitSlop={{ top: 8, bottom: 8, left: 12, right: 12 }}>
          <Ionicons name="chevron-back" size={18} color={colors.primary} />
        </TouchableOpacity>
        <View style={s.pickerLabel}>
          <Text style={[s.pickerText, { color: colors.foreground }]}>
            {ymLabel(selectedYM, i18n.language).toUpperCase()}
          </Text>
          {isCurrent && (
            <View style={[s.todayBadge, { backgroundColor: colors.primary + "22" }]}>
              <Text style={[s.todayBadgeText, { color: colors.primary }]}>{t("debtSummary.current")}</Text>
            </View>
          )}
        </View>
        <TouchableOpacity
          onPress={goNext}
          disabled={isCurrent}
          style={s.arrowBtn}
          hitSlop={{ top: 8, bottom: 8, left: 12, right: 12 }}
        >
          <Ionicons name="chevron-forward" size={18} color={isCurrent ? colors.mutedForeground : colors.primary} />
        </TouchableOpacity>
      </View>

      {/* Table */}
      <View style={[s.tableWrapper, { backgroundColor: colors.card }]}>
        {isEmpty ? (
          <View style={s.emptyBox}>
            <Text style={[s.emptyText, { color: colors.mutedForeground }]}>
              {t("debtSummary.noData", { month: ymLabel(selectedYM, i18n.language) })}
            </Text>
          </View>
        ) : (
          <View style={{ flexDirection: "row" }}>

            {/* ── Sabit sol: ALACAKLI / BORÇ TÜRÜ (birleşik) ───────────── */}
            <View>
              {/* Header */}
              <View style={[s.fixedHeaderRow, { height: HDR_H, backgroundColor: colors.navy }]}>
                <View style={[s.fixedHeaderCell, { width: COL_LEFT, borderRightColor: "rgba(255,255,255,0.15)", flexDirection: "column", gap: 2 }]}>
                  <Text style={[s.fixedHeaderTxt, { color: colors.primary }]}>{t("debtSummary.creditor")}</Text>
                  <Text style={[s.fixedHeaderTxt, { color: "rgba(255,255,255,0.55)", fontSize: 7 }]}>{t("debtSummary.debtType")}</Text>
                </View>
              </View>

              {/* Data rows */}
              {rows.map((row, i) => {
                const bg = i % 2 === 1 ? colors.muted + "55" : colors.card;
                return (
                  <View key={row.id} style={[s.fixedDataRow, { height: ROW_H, backgroundColor: bg, borderTopColor: colors.border }]}>
                    <View style={[s.fixedDataCell, { width: COL_LEFT, borderRightColor: colors.border, flexDirection: "column", alignItems: "center", gap: 3, paddingVertical: 6 }]}>
                      <Text style={[s.fixedCellTxt, { color: colors.foreground, fontSize: 9 }]} numberOfLines={1} adjustsFontSizeToFit>
                        {row.creditor.toUpperCase()}
                      </Text>
                      <Text style={[s.fixedCellTxt, { color: colors.primary, fontSize: 8, fontWeight: "600" }]} numberOfLines={1} adjustsFontSizeToFit>
                        {row.debtType.toUpperCase()}
                      </Text>
                    </View>
                  </View>
                );
              })}

              {/* Footer */}
              <View style={[s.fixedHeaderRow, { height: ROW_H, backgroundColor: colors.primary }]}>
                <View style={[s.fixedHeaderCell, { width: COL_LEFT }]}>
                  <Text style={s.footerTxt}>{t("debtSummary.total")}</Text>
                </View>
              </View>
            </View>

            {/* ── Kaydırılabilir sağ sütunlar ───────────────────────────── */}
            <ScrollView horizontal showsHorizontalScrollIndicator={false} bounces={false}>
              <View>
                {/* Header */}
                <View style={{ flexDirection: "row" }}>
                  {COLS.map((col) => (
                    <View
                      key={col.key}
                      style={[s.dataHeader, {
                        width: COL_NUM,
                        height: HDR_H,
                        backgroundColor: col.accent ? colors.primary + "22" : colors.navy,
                        borderLeftColor: "rgba(255,255,255,0.15)",
                      } as ViewStyle]}
                    >
                      <Text style={[s.dataHeaderTxt, { color: col.accent ? colors.primary : "#FFFFFF" } as TextStyle]}>
                        {col.label}
                      </Text>
                    </View>
                  ))}
                </View>

                {/* Data rows */}
                {rows.map((row, i) => (
                  <View key={row.id} style={{ flexDirection: "row" }}>
                    {COLS.map((col) => {
                      const val = (row as any)[col.key] as number;
                      const isKalan = col.key === "kalan";
                      const isOdenen = col.key === "odenen";
                      return (
                        <View
                          key={col.key}
                          style={{
                            width: COL_NUM,
                            height: ROW_H,
                            backgroundColor: i % 2 === 1 ? colors.muted + "55" : colors.card,
                            alignItems: "flex-end",
                            justifyContent: "center",
                            paddingHorizontal: 8,
                            borderLeftWidth: StyleSheet.hairlineWidth,
                            borderLeftColor: colors.border,
                            borderTopWidth: StyleSheet.hairlineWidth,
                            borderTopColor: colors.border,
                          } as ViewStyle}
                        >
                          {val > 0.01 ? (
                            <Text
                              style={{
                                fontSize: 10,
                                fontWeight: isKalan ? "800" : "500",
                                color: isKalan ? colors.primary : isOdenen ? "#22C55E" : colors.foreground,
                              } as TextStyle}
                              numberOfLines={1}
                              adjustsFontSizeToFit
                            >
                              {formatAmount(val)}
                            </Text>
                          ) : (
                            <Text style={{ fontSize: 10, color: colors.mutedForeground } as TextStyle}>—</Text>
                          )}
                        </View>
                      );
                    })}
                  </View>
                ))}

                {/* Footer */}
                <View style={{ flexDirection: "row" }}>
                  {COLS.map((col) => {
                    const val = (grandTotal as any)[col.key] ?? 0;
                    return (
                      <View
                        key={col.key}
                        style={{
                          width: COL_NUM,
                          height: ROW_H,
                          backgroundColor: colors.primary,
                          alignItems: "flex-end",
                          justifyContent: "center",
                          paddingHorizontal: 8,
                          borderLeftWidth: 1,
                          borderLeftColor: "rgba(255,255,255,0.2)",
                        } as ViewStyle}
                      >
                        <Text
                          style={{ fontSize: col.key === "kalan" ? 11 : 10, fontWeight: "800", color: "#0B1E33" } as TextStyle}
                          numberOfLines={1}
                          adjustsFontSizeToFit
                        >
                          {val > 0.01 ? formatAmount(val) : "—"}
                        </Text>
                      </View>
                    );
                  })}
                </View>
              </View>
            </ScrollView>
          </View>
        )}
      </View>
    </View>
  );
}

// ── Styles ────────────────────────────────────────────────────────────────────

const s = StyleSheet.create({
  container: { borderRadius: 14, overflow: "hidden", borderWidth: 1 },
  picker: {
    flexDirection: "row", alignItems: "center", justifyContent: "space-between",
    paddingVertical: 10, paddingHorizontal: 12, borderBottomWidth: StyleSheet.hairlineWidth,
  },
  arrowBtn: { padding: 4 },
  pickerLabel: { flexDirection: "row", alignItems: "center", gap: 8 },
  pickerText: { fontSize: 13, fontWeight: "800", letterSpacing: 0.5 } as TextStyle,
  todayBadge: { borderRadius: 6, paddingHorizontal: 7, paddingVertical: 2 },
  todayBadgeText: { fontSize: 10, fontWeight: "700" } as TextStyle,
  tableWrapper: { overflow: "hidden" },
  emptyBox: { padding: 24, alignItems: "center" },
  emptyText: { fontSize: 13, textAlign: "center" } as TextStyle,
  fixedHeaderRow: { flexDirection: "row" },
  fixedHeaderCell: {
    justifyContent: "center", alignItems: "center", paddingHorizontal: 6, borderRightWidth: 1,
  },
  fixedHeaderTxt: { fontSize: 8, fontWeight: "800", letterSpacing: 0.5, textAlign: "center" } as TextStyle,
  fixedDataRow: { flexDirection: "row", borderTopWidth: StyleSheet.hairlineWidth },
  fixedDataCell: {
    justifyContent: "center", alignItems: "center", paddingHorizontal: 5, borderRightWidth: StyleSheet.hairlineWidth,
  },
  fixedCellTxt: { fontSize: 8, fontWeight: "700", textAlign: "center" } as TextStyle,
  footerTxt: { fontSize: 9, fontWeight: "900", color: "#0B1E33", letterSpacing: 0.5 } as TextStyle,
  dataHeader: {
    alignItems: "center", justifyContent: "center", paddingHorizontal: 4, borderLeftWidth: 1,
  },
  dataHeaderTxt: { fontSize: 9, fontWeight: "800", letterSpacing: 0.4, textAlign: "center" } as TextStyle,
});
