/**
 * DebtSummaryVisual — "Borç Özeti" görsel versiyonu
 *
 * Tablo yerine:
 *  • Ay navigasyonu
 *  • 3 özet kart (Toplam / Ödenen / Kalan)
 *  • Donut ring (borç türüne göre renk kodlu)
 *  • Her borç için yatay ödeme progress bar'ı
 */

import React, { useMemo, useState } from "react";
import {
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { Feather } from "@expo/vector-icons";
import { LinearGradient } from "expo-linear-gradient";
import { useTranslation } from "react-i18next";
import Svg, { Circle, G } from "react-native-svg";

// ── Ring constants ─────────────────────────────────────────────────────────────
const RING_SIZE   = 76;
const RING_STROKE = 8;
const RING_R      = (RING_SIZE - RING_STROKE) / 2;
const RING_C      = 2 * Math.PI * RING_R;

import { useBudget } from "@/context/finans/BudgetContext";
import { useColors } from "@/hooks/finans/useColors";
import { useFormatAmount } from "@/hooks/finans/useFormatAmount";
import {
  findSavedCardForBankLimit,
  getAllStatementsForCard,
} from "@/utils/finans/statements";
import { getDebtCategoryColor } from "@/utils/finans/categories";
import {
  todayYM,
  ymToNum,
  numToYM,
  installmentRemainingAtYM,
  regularRemainingAtYM,
} from "@/utils/finans/debtCalc";

function ymLabel(ym: string, lang: string): string {
  const [y, m] = ym.split("-").map(Number);
  const monthName = new Date(y, m - 1, 1).toLocaleDateString(lang, { month: "long" });
  return `${monthName} ${y}`;
}
function debtEndYM(d: {
  date: string;
  isInstallment: boolean;
  totalInstallments?: number;
  dueDate?: string;
}): string {
  if (d.isInstallment && d.totalInstallments) {
    const start = new Date(d.date);
    const startYM = `${start.getFullYear()}-${String(start.getMonth() + 1).padStart(2, "0")}`;
    return numToYM(ymToNum(startYM) + d.totalInstallments - 1);
  }
  if (d.dueDate) {
    const dt = new Date(d.dueDate);
    return `${dt.getFullYear()}-${String(dt.getMonth() + 1).padStart(2, "0")}`;
  }
  return numToYM(ymToNum(todayYM()) + 120);
}

// ── Row type ──────────────────────────────────────────────────────────────────

type SummaryRow = {
  id: string;
  creditor: string;
  debtType: string;
  debtName: string;
  toplam: number;
  odenen: number;
  kalan: number;
};

// ── Debt-type color palette ───────────────────────────────────────────────────

function buildColorMap(
  types: string[],
  ccLabel: string,
  odLabel: string,
  _primary: string
): Record<string, string> {
  const map: Record<string, string> = {};
  for (const t of types) {
    map[t] = getDebtCategoryColor(t, "#6366F1");
  }
  return map;
}

// ── Props ─────────────────────────────────────────────────────────────────────

interface Props {
  creditorFilter?: string | null;
  debtTypeFilter?: string | null;
}

// ── Component ─────────────────────────────────────────────────────────────────

export function DebtSummaryVisual({ creditorFilter, debtTypeFilter }: Props = {}) {
  const formatAmount = useFormatAmount();
  const colors = useColors();
  const { t, i18n } = useTranslation();
  const { debts, bankLimits, savedCards, transactions } = useBudget();

  const currentYM = todayYM();
  const [selectedYM, setSelectedYM] = useState(currentYM);
  const isCurrent = selectedYM === currentYM;

  const ccLabel = t("debts.creditCard");
  const odLabel = t("debts.overdraftAccount");

  // ── Filter source data (same logic as DebtSummaryTable) ───────────────────

  const filteredDebts = useMemo(() => {
    let arr = debts.filter((d) => !d.bankLimitId);
    if (creditorFilter) arr = arr.filter((d) => d.creditor?.trim() === creditorFilter);
    if (debtTypeFilter === ccLabel || debtTypeFilter === odLabel) return [];
    if (debtTypeFilter) arr = arr.filter((d) => (d.category || "Diğer") === debtTypeFilter);
    return arr;
  }, [debts, creditorFilter, debtTypeFilter, ccLabel, odLabel]);

  const filteredBankLimits = useMemo(() => {
    let arr = bankLimits;
    if (creditorFilter)
      arr = arr.filter((bl) => (bl.institution || bl.bank || "").trim() === creditorFilter);
    if (debtTypeFilter) {
      if (debtTypeFilter === odLabel) arr = arr.filter((bl) => bl.type === "overdraft");
      else if (debtTypeFilter === ccLabel) arr = arr.filter((bl) => bl.type === "credit");
      else arr = [];
    }
    return arr;
  }, [bankLimits, creditorFilter, debtTypeFilter, ccLabel, odLabel]);

  // ── Build rows ─────────────────────────────────────────────────────────────

  const rows = useMemo<SummaryRow[]>(() => {
    const result: SummaryRow[] = [];

    for (const bl of filteredBankLimits) {
      if (bl.type === "overdraft") {
        if (selectedYM !== currentYM) continue;
        const used = Math.max(0, (bl.limit ?? 0) - (bl.availableLimit ?? 0));
        if (used < 0.01) continue;
        result.push({
          id: `od-${bl.id}`,
          creditor: bl.institution || bl.bank || odLabel,
          debtType: odLabel,
          debtName: "",
          toplam: used,
          odenen: 0,
          kalan: used,
        });
      } else if (bl.type === "credit") {
        const sc = findSavedCardForBankLimit(bl, savedCards);
        const stmts = getAllStatementsForCard({ bankLimit: bl, savedCard: sc, transactions });
        const stmt = stmts.find((s) => s.yearMonth === selectedYM);
        if (!stmt && selectedYM !== currentYM) continue;
        const stmtAmt = stmt?.amount ?? 0;
        const fallback =
          stmtAmt === 0 &&
          selectedYM === currentYM &&
          typeof bl.availableLimit === "number"
            ? Math.max(0, (bl.limit ?? 0) - bl.availableLimit)
            : 0;
        const amt = stmtAmt > 0 ? stmtAmt : fallback;
        if (amt < 0.01) continue;
        const paid = stmtAmt > 0 ? (stmt?.paidAmount ?? 0) : 0;
        result.push({
          id: `cc-${bl.id}`,
          creditor: bl.institution || bl.bank || ccLabel,
          debtType: ccLabel,
          debtName: "",
          toplam: amt,
          odenen: paid,
          kalan: Math.max(0, amt - paid),
        });
      }
    }

    for (const d of filteredDebts) {
      const startDate = new Date(d.date);
      const startYM = `${startDate.getFullYear()}-${String(startDate.getMonth() + 1).padStart(2, "0")}`;
      if (startYM > selectedYM) continue;
      const endYM = debtEndYM(d);
      if (d.isInstallment && selectedYM > endYM) continue;
      const kalan = d.isInstallment
        ? installmentRemainingAtYM(d.amount, d.date, d.totalInstallments ?? 1, selectedYM)
        : regularRemainingAtYM(d.amount, d.payments ?? [], selectedYM);
      if (selectedYM < currentYM && kalan < 0.01) continue;
      const odenen = Math.max(0, d.amount - kalan);
      result.push({
        id: d.id,
        creditor: d.creditor?.trim() || d.name,
        debtType: d.category || "Diğer",
        debtName: d.name,
        toplam: d.amount,
        odenen,
        kalan,
      });
    }

    return result.sort((a, b) => a.creditor.localeCompare(b.creditor));
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

  // ── Aggregates ─────────────────────────────────────────────────────────────

  const grandToplam = rows.reduce((s, r) => s + r.toplam, 0);
  const grandOdenen = rows.reduce((s, r) => s + r.odenen, 0);
  const grandKalan  = rows.reduce((s, r) => s + r.kalan, 0);

  // ── Colors per type ────────────────────────────────────────────────────────

  const allTypes = Array.from(new Set(rows.map((r) => r.debtType)));
  const colorMap = buildColorMap(allTypes, ccLabel, odLabel, colors.primary);

  // ── Waterfall: türe göre toplam / ödenen / kalan ──────────────────────────

  const waterfallTypes = useMemo(() => {
    const byType: Record<string, { total: number; paid: number }> = {};
    for (const r of rows) {
      if (!byType[r.debtType]) byType[r.debtType] = { total: 0, paid: 0 };
      byType[r.debtType].total += r.toplam;
      byType[r.debtType].paid  += r.odenen;
    }
    return Object.entries(byType)
      .map(([type, v]) => ({
        type,
        total: v.total,
        paid:  v.paid,
        kalan: v.total - v.paid,
        color: colorMap[type] ?? "#94A3B8",
      }))
      .filter((d) => d.total > 0.01)
      .sort((a, b) => b.total - a.total);
  }, [rows, colorMap]);

  // ── Styles ─────────────────────────────────────────────────────────────────

  const s = useMemo(
    () =>
      StyleSheet.create({
        root: { gap: 16 },
        monthNav: {
          flexDirection: "row",
          alignItems: "center",
          justifyContent: "center",
          gap: 12,
        },
        monthLabel: {
          fontSize: 14,
          fontWeight: "700",
          color: colors.foreground,
          minWidth: 130,
          textAlign: "center",
        },
        navBtn: {
          width: 30,
          height: 30,
          borderRadius: 15,
          backgroundColor: colors.muted,
          alignItems: "center",
          justifyContent: "center",
        },
        cardsRow: { flexDirection: "row", gap: 8 },
        card: {
          flex: 1,
          borderRadius: 14,
          paddingVertical: 12,
          paddingHorizontal: 8,
          alignItems: "center",
          gap: 3,
          overflow: "hidden",
        },
        cardLabel: { fontSize: 9, fontWeight: "700", letterSpacing: 0.5 },
        cardValue: { fontSize: 12, fontWeight: "800" },
        schemaWrap: {
          backgroundColor: colors.card,
          borderRadius: 16,
          borderWidth: 1,
          borderColor: colors.border,
          paddingVertical: 20,
          paddingHorizontal: 16,
          gap: 20,
        },
        // ── Ring Cards styles ──────────────────────────────────────────────
        rcGrid: {
          flexDirection: "row",
          flexWrap: "wrap",
          gap: 10,
        },
        rcCard: {
          flexBasis: "47%",
          flexGrow: 1,
          borderRadius: 14,
          padding: 12,
          borderWidth: 1,
          gap: 10,
          minWidth: 140,
        },
        rcHead: {
          flexDirection: "row",
          alignItems: "center",
          gap: 6,
        },
        rcDot: {
          width: 8,
          height: 8,
          borderRadius: 4,
        },
        rcLabel: {
          fontSize: 11,
          fontWeight: "700",
          color: colors.foreground,
          flex: 1,
        },
        rcBody: {
          flexDirection: "row",
          alignItems: "center",
          gap: 8,
        },
        rcRingWrap: {
          width: RING_SIZE,
          height: RING_SIZE,
          alignItems: "center",
          justifyContent: "center",
        },
        rcRingCenter: {
          position: "absolute",
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          alignItems: "center",
          justifyContent: "center",
        },
        rcRingPct: {
          fontSize: 14,
          fontWeight: "800",
          color: colors.foreground,
        },
        rcRingSub: {
          fontSize: 7,
          fontWeight: "700",
          color: colors.mutedForeground,
          textTransform: "uppercase",
          letterSpacing: 0.4,
          marginTop: 1,
        },
        rcInfo: {
          flex: 1,
          minWidth: 0,
        },
        rcInfoLabel: {
          fontSize: 8,
          fontWeight: "700",
          color: colors.mutedForeground,
          letterSpacing: 0.5,
          textTransform: "uppercase",
        },
        rcInfoVal: {
          fontSize: 13,
          fontWeight: "800",
          marginTop: 2,
          marginBottom: 5,
        },
        rcInfoSub: {
          fontSize: 11,
          fontWeight: "600",
          color: colors.mutedForeground,
          marginTop: 2,
        },
        rcSummary: {
          backgroundColor: colors.muted,
          borderRadius: 12,
          paddingVertical: 12,
          paddingHorizontal: 12,
          flexDirection: "row",
          justifyContent: "space-between",
          alignItems: "center",
          gap: 8,
        },
        rcSumCol: {
          flex: 1,
          gap: 3,
        },
        rcSumColCenter: {
          alignItems: "center",
        },
        rcSumLabel: {
          fontSize: 8,
          fontWeight: "700",
          color: colors.mutedForeground,
          letterSpacing: 0.5,
          textTransform: "uppercase",
        },
        rcSumVal: {
          fontSize: 14,
          fontWeight: "800",
        },
        dividerH: {
          height: 1,
          backgroundColor: colors.border,
        },
        sectionTitle: {
          fontSize: 11,
          fontWeight: "700",
          color: colors.mutedForeground,
          letterSpacing: 0.8,
          textTransform: "uppercase",
          alignSelf: "flex-start",
          marginBottom: 12,
        },
        barsWrap: {
          backgroundColor: colors.card,
          borderRadius: 16,
          borderWidth: 1,
          borderColor: colors.border,
          paddingVertical: 16,
          paddingHorizontal: 16,
          gap: 14,
        },
        barRow: { gap: 5 },
        barMeta: {
          flexDirection: "row",
          alignItems: "center",
          justifyContent: "space-between",
          gap: 6,
        },
        barLabelLeft: {
          flexDirection: "row",
          alignItems: "flex-start",
          gap: 5,
          flex: 1,
          minWidth: 0,
        },
        barDot: { width: 8, height: 8, borderRadius: 4, flexShrink: 0 },
        barName: {
          fontSize: 12,
          fontWeight: "600",
          color: colors.foreground,
          flexShrink: 1,
        },
        barTypeBadge: {
          fontSize: 10,
          fontWeight: "500",
          color: colors.mutedForeground,
          marginTop: 1,
        },
        barDebtName: {
          fontSize: 10,
          fontWeight: "500",
          color: colors.foreground,
          marginTop: 1,
          opacity: 0.75,
        },
        barRight: { flexDirection: "row", alignItems: "center", gap: 2 },
        barKalan: { fontSize: 11, fontWeight: "700", color: colors.foreground },
        barToplam: { fontSize: 10, color: colors.mutedForeground },
        barTrack: {
          height: 6,
          backgroundColor: colors.muted,
          borderRadius: 3,
          overflow: "hidden",
        },
        barFooter: {
          flexDirection: "row",
          justifyContent: "space-between",
          marginTop: 1,
        },
        barPct: { fontSize: 9, color: colors.mutedForeground },
        emptyWrap: { alignItems: "center", paddingVertical: 28, gap: 8 },
        emptyText: { fontSize: 14, color: colors.mutedForeground, fontWeight: "500" },
      }),
    [colors]
  );

  return (
    <View style={s.root}>
      {/* ── Month navigation ─────────────────────────────────────────── */}
      <View style={s.monthNav}>
        <TouchableOpacity style={s.navBtn} onPress={() => setSelectedYM((ym) => numToYM(ymToNum(ym) - 1))} activeOpacity={0.7}>
          <Feather name="chevron-left" size={16} color={colors.foreground} />
        </TouchableOpacity>
        <Text style={s.monthLabel}>{ymLabel(selectedYM, i18n.language)}</Text>
        <TouchableOpacity
          style={[s.navBtn, isCurrent && { opacity: 0.3 }]}
          onPress={() => { if (!isCurrent) setSelectedYM((ym) => numToYM(ymToNum(ym) + 1)); }}
          activeOpacity={0.7}
          disabled={isCurrent}
        >
          <Feather name="chevron-right" size={16} color={colors.foreground} />
        </TouchableOpacity>
      </View>

      {rows.length === 0 ? (
        <View style={s.emptyWrap}>
          <Feather name="check-circle" size={38} color={colors.mutedForeground} />
          <Text style={s.emptyText}>{t("debts.noDebtsFilter")}</Text>
        </View>
      ) : (
        <>
          {/* ── 3 Summary cards ──────────────────────────────────────── */}
          <View style={s.cardsRow}>
            <LinearGradient
              colors={["#DC2626", "#EF4444"]}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 1 }}
              style={s.card}
            >
              <Text style={[s.cardLabel, { color: "rgba(255,255,255,0.8)" }]}>
                {t("debts.totalDebt").toUpperCase()}
              </Text>
              <Text style={[s.cardValue, { color: "#fff" }]} numberOfLines={1} adjustsFontSizeToFit>
                {formatAmount(grandToplam)}
              </Text>
            </LinearGradient>

            <LinearGradient
              colors={["#059669", "#10B981"]}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 1 }}
              style={s.card}
            >
              <Text style={[s.cardLabel, { color: "rgba(255,255,255,0.8)" }]}>
                {t("debts.paid").toUpperCase()}
              </Text>
              <Text style={[s.cardValue, { color: "#fff" }]} numberOfLines={1} adjustsFontSizeToFit>
                {formatAmount(grandOdenen)}
              </Text>
            </LinearGradient>

            <LinearGradient
              colors={[colors.primary, colors.primary + "BB"]}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 1 }}
              style={s.card}
            >
              <Text style={[s.cardLabel, { color: "rgba(255,255,255,0.8)" }]}>
                {t("debts.remainingLabel").toUpperCase()}
              </Text>
              <Text style={[s.cardValue, { color: "#fff" }]} numberOfLines={1} adjustsFontSizeToFit>
                {formatAmount(grandKalan)}
              </Text>
            </LinearGradient>
          </View>

          {/* ── Borç Özet Şeması — Ring Cards ────────────────────────── */}
          {waterfallTypes.length > 0 && (
            <View style={s.schemaWrap}>
              <Text style={s.sectionTitle}>{t("debts.debtSchemaSummary")}</Text>

              {/* ── 2x2 Ring cards grid ── */}
              <View style={s.rcGrid}>
                {waterfallTypes.map((d) => {
                  const pct  = d.total > 0 ? d.paid / d.total : 0;
                  const pctN = Math.round(pct * 100);
                  const dash = Math.min(pct, 0.9999) * RING_C;
                  return (
                    <View
                      key={d.type}
                      style={[
                        s.rcCard,
                        { borderColor: d.color + "55", backgroundColor: d.color + "10" },
                      ]}
                    >
                      {/* Header: dot + type name */}
                      <View style={s.rcHead}>
                        <View style={[s.rcDot, { backgroundColor: d.color }]} />
                        <Text style={s.rcLabel} numberOfLines={1}>{d.type}</Text>
                      </View>

                      {/* Body: ring on left + info on right */}
                      <View style={s.rcBody}>
                        <View style={s.rcRingWrap}>
                          <Svg width={RING_SIZE} height={RING_SIZE}>
                            <G rotation={-90} origin={`${RING_SIZE / 2}, ${RING_SIZE / 2}`}>
                              {/* Track */}
                              <Circle
                                cx={RING_SIZE / 2} cy={RING_SIZE / 2} r={RING_R}
                                fill="none"
                                stroke={d.color}
                                strokeOpacity={0.18}
                                strokeWidth={RING_STROKE}
                              />
                              {/* Progress */}
                              {pct > 0 && (
                                <Circle
                                  cx={RING_SIZE / 2} cy={RING_SIZE / 2} r={RING_R}
                                  fill="none"
                                  stroke={d.color}
                                  strokeWidth={RING_STROKE}
                                  strokeLinecap="round"
                                  strokeDasharray={`${dash} ${RING_C}`}
                                />
                              )}
                            </G>
                          </Svg>
                          <View style={s.rcRingCenter} pointerEvents="none">
                            <Text style={s.rcRingPct}>%{pctN}</Text>
                            <Text style={s.rcRingSub}>{t("debts.paid").toLowerCase()}</Text>
                          </View>
                        </View>

                        <View style={s.rcInfo}>
                          <Text style={s.rcInfoLabel}>{t("debts.remainingLabel").toUpperCase()}</Text>
                          <Text
                            style={[s.rcInfoVal, { color: d.color }]}
                            numberOfLines={1}
                            adjustsFontSizeToFit
                          >
                            {formatAmount(d.kalan)}
                          </Text>
                          <Text style={s.rcInfoLabel}>{t("debts.totalDebt").toUpperCase()}</Text>
                          <Text
                            style={s.rcInfoSub}
                            numberOfLines={1}
                            adjustsFontSizeToFit
                          >
                            {formatAmount(d.total)}
                          </Text>
                        </View>
                      </View>
                    </View>
                  );
                })}
              </View>

              {/* ── Genel summary strip ── */}
              <View style={s.rcSummary}>
                <View style={s.rcSumCol}>
                  <Text style={s.rcSumLabel}>{t("debts.remainingLabel").toUpperCase()}</Text>
                  <Text
                    style={[s.rcSumVal, { color: colors.primary }]}
                    numberOfLines={1}
                    adjustsFontSizeToFit
                  >
                    {formatAmount(grandKalan)}
                  </Text>
                </View>
                <View style={[s.rcSumCol, s.rcSumColCenter]}>
                  <Text style={s.rcSumLabel}>{t("debts.paid").toUpperCase()}</Text>
                  <Text
                    style={[s.rcSumVal, { color: "#10B981" }]}
                    numberOfLines={1}
                    adjustsFontSizeToFit
                  >
                    %{grandToplam > 0 ? Math.round((grandOdenen / grandToplam) * 100) : 0}
                  </Text>
                </View>
                <View style={s.rcSumCol}>
                  <Text style={s.rcSumLabel}>{t("debts.totalDebt").toUpperCase()}</Text>
                  <Text
                    style={[s.rcSumVal, { color: colors.expense }]}
                    numberOfLines={1}
                    adjustsFontSizeToFit
                  >
                    {formatAmount(grandToplam)}
                  </Text>
                </View>
              </View>
            </View>
          )}

          {/* ── Per-debt progress bars ────────────────────────────────── */}
          <View style={s.barsWrap}>
            <Text style={s.sectionTitle}>{t("debts.debtProgress")}</Text>
            {rows.map((r) => {
              const barColor = colorMap[r.debtType] ?? "#94A3B8";
              const paidRatio = r.toplam > 0 ? Math.min(1, r.odenen / r.toplam) : 0;
              const paidPct = Math.round(paidRatio * 100);
              return (
                <View key={r.id} style={s.barRow}>
                  {/* Name + amounts */}
                  <View style={s.barMeta}>
                    <View style={s.barLabelLeft}>
                      <View style={[s.barDot, { backgroundColor: barColor }]} />
                      <View style={{ flex: 1, minWidth: 0 }}>
                        <Text style={s.barName} numberOfLines={1}>{r.creditor}</Text>
                        <Text style={s.barTypeBadge} numberOfLines={1}>{r.debtType}</Text>
                        {!!r.debtName && (
                          <Text style={s.barDebtName} numberOfLines={1}>{r.debtName}</Text>
                        )}
                      </View>
                    </View>
                    <View style={s.barRight}>
                      <Text style={s.barKalan}>{formatAmount(r.kalan)}</Text>
                      <Text style={s.barToplam}> / {formatAmount(r.toplam)}</Text>
                    </View>
                  </View>
                  {/* Progress track */}
                  <View style={s.barTrack}>
                    <View
                      style={{
                        height: 6,
                        borderRadius: 3,
                        backgroundColor: barColor,
                        width: `${paidPct}%`,
                      }}
                    />
                  </View>
                  {/* Footer */}
                  <View style={s.barFooter}>
                    <Text style={s.barPct}>%{paidPct} {t("debts.paidPercent")}</Text>
                    {r.kalan < 0.01 && (
                      <Text style={[s.barPct, { color: "#10B981", fontWeight: "700" }]}>
                        {t("debts.fullyPaid")} ✓
                      </Text>
                    )}
                  </View>
                </View>
              );
            })}
          </View>
        </>
      )}
    </View>
  );
}
