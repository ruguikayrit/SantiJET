import { Feather } from "@expo/vector-icons";
import * as Haptics from "expo-haptics";
import React, { useEffect, useMemo, useState } from "react";
import {
  Keyboard,
  KeyboardEvent,
  Modal,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useTranslation } from "react-i18next";

import Calendar from "@/components/finans/Calendar";
import { KeyboardAwareScrollViewCompat } from "@/components/finans/KeyboardAwareScrollViewCompat";
import { useBudget } from "@/context/finans/BudgetContext";
import { useColors } from "@/hooks/finans/useColors";
import {
  findSavedCardForBankLimit,
  formatStatementYearMonth,
  getAllStatementsForCard,
} from "@/utils/finans/statements";
import { getDebtCategoryColor, getDebtCategoryIcon } from "@/utils/finans/categories";
import { useFormatAmount } from "@/hooks/finans/useFormatAmount";

// ---- Helpers -----------------------------------------------------------------

function toYM(date: Date): string {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;
}

/** toISOString() UTC'ye çevirdiği için Türkiye'de gece yarısı oluşturulan
 *  tarihler bir gün geriye kayar. Bu helper yerel saatle YYYY-MM-DD döndürür. */
function toLocalDateStr(date: Date): string {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}-${String(date.getDate()).padStart(2, "0")}`;
}

function isInstallmentPayable(p: { kind: string; installmentIndex?: number }): boolean {
  return p.kind === "debt" && (p as any).installmentIndex != null;
}

// ---- Types ------------------------------------------------------------------

type DebtPayable = {
  kind: "debt";
  id: string;
  debtId: string;
  label: string;
  category: string;
  creditor: string;
  totalAmount: number;
  paidAmount: number;
  remaining: number;
  dueDate: Date | null;
  dueDateISO: string | null;
  // Only for installment debts
  installmentIndex?: number;
  installmentTotal?: number;
};

type StatementPayable = {
  kind: "statement";
  id: string;
  bankLimitId: string;
  yearMonth: string;
  label: string;
  cardName: string;
  category: string;
  creditor: string;
  totalAmount: number;
  paidAmount: number;
  remaining: number;
  dueDate: Date;
  dueDateISO: string;
};

type BankLimitPayable = {
  kind: "banklimit";
  id: string;
  bankLimitId: string;
  label: string;
  category: string;
  creditor: string;
  blType: "credit" | "overdraft";
  totalAmount: number;
  paidAmount: number;
  remaining: number;
  dueDate: Date | null;
  dueDateISO: string | null;
};

type Payable = DebtPayable | StatementPayable | BankLimitPayable;

type Section = { id: string; label: string; icon: string; color: string; items: Payable[] };

// ---- Screen -----------------------------------------------------------------

export default function PaymentsScreen() {
  const { t, i18n } = useTranslation();
  const formatAmount = useFormatAmount();
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const {
    debts,
    addPayment,
    bankLimits,
    savedCards,
    transactions,
    recordStatementPayment,
    updateBankLimit,
    toggleInstallmentPaid,
  } = useBudget();

  const topInset = 0;
  const bottomInset = Platform.OS === "web" ? 34 : insets.bottom;

  // Takvim görüntülenen ay (payables hesabında da gerekli olduğu için yukarıda)
  const [calendarViewYM, setCalendarViewYM] = useState<string>(toYM(new Date()));

  // ---- Build payable list ---------------------------------------------------

  const payables = useMemo<Payable[]>(() => {
    const items: Payable[] = [];

    // 1) Manual debts (not linked to a bank limit)
    for (const d of debts) {
      if (d.bankLimitId) continue;

      // ── Taksitli borçlar ─────────────────────────────────────────────────
      if (d.isInstallment && d.totalInstallments && d.totalInstallments > 0) {
        const total = d.totalInstallments;
        const perInstallment = d.amount / total;
        const paidSet = new Set<number>(
          d.paidInstallmentIndices ??
            Array.from({ length: d.paidInstallments ?? 0 }, (_, i) => i)
        );

        for (let i = 0; i < total; i++) {
          if (paidSet.has(i)) continue; // bu taksit zaten ödenmiş

          // Bu taksitin ayı: borç başlangıç tarihi + i ay
          const instDate = new Date(d.date);
          instDate.setMonth(instDate.getMonth() + i);

          items.push({
            kind: "debt",
            id: `${d.id}::inst-${i}`,
            debtId: d.id,
            installmentIndex: i,
            installmentTotal: total,
            label: `${d.name} — Taksit ${i + 1}/${total}`,
            category: d.category || "Diğer",
            creditor: d.creditor || "—",
            totalAmount: perInstallment,
            paidAmount: 0,
            remaining: perInstallment,
            dueDate: instDate,
            dueDateISO: toLocalDateStr(instDate),
          });
        }
        continue; // taksitli borcu normal olarak da ekleme
      }

      // ── Normal (tek seferlik) borçlar ────────────────────────────────────
      const totalPaid = (d.payments ?? []).reduce((s, p) => s + (p.amount || 0), 0);
      const remaining = Math.max(0, d.amount - totalPaid);
      if (remaining <= 0.005) continue;
      // Vadesi yoksa borç tarihini (d.date) takvimde göstermek için fallback kullan
      const fallbackDateISO = d.date ? toLocalDateStr(new Date(d.date)) : null;
      items.push({
        kind: "debt",
        id: d.id,
        debtId: d.id,
        label: d.name,
        category: d.category || "Diğer",
        creditor: d.creditor || "—",
        totalAmount: d.amount,
        paidAmount: totalPaid,
        remaining,
        dueDate: d.dueDate ? new Date(d.dueDate) : null,
        dueDateISO: d.dueDate ?? fallbackDateISO,
      });
    }

    // 2) CC issued statements (past, unpaid)
    const blIdsWithStatements = new Set<string>();
    for (const bl of bankLimits) {
      const sc = findSavedCardForBankLimit(bl, savedCards);
      const stmts = getAllStatementsForCard({ bankLimit: bl, savedCard: sc, transactions });
      for (const s of stmts) {
        if (s.isActive || s.isFuture) continue;
        if (!s.hasData) continue;
        if (s.remaining <= 0.005) continue;
        blIdsWithStatements.add(bl.id);
        items.push({
          kind: "statement",
          id: `${bl.id}::${s.yearMonth}`,
          bankLimitId: bl.id,
          yearMonth: s.yearMonth,
          label: `${bl.institution || bl.bank} — ${formatStatementYearMonth(s.yearMonth)}`,
          cardName: bl.bank,
          category: "Kredi Kartı",
          creditor: bl.institution || bl.bank,
          totalAmount: s.amount,
          paidAmount: s.paidAmount,
          remaining: s.remaining,
          dueDate: s.dueDate,
          dueDateISO: toLocalDateStr(s.dueDate),
        });
      }
    }

    // 3) Bank limits with outstanding balance not covered by statements
    //    Vade günü (dueDay) varsa, görüntülenen aya göre sanal vade tarihi ata
    const [viewYear, viewMonth] = calendarViewYM.split("-").map(Number);
    for (const bl of bankLimits) {
      if (bl.availableLimit === undefined) continue;
      const remaining = Math.max(0, bl.limit - bl.availableLimit);
      if (remaining <= 0.005) continue;
      // Credit cards: skip if already covered by issued statements above
      if (bl.type === "credit" && blIdsWithStatements.has(bl.id)) continue;

      // Görüntülenen aya göre sanal vade tarihi (kayıtlı kartın dueDay'i var ise)
      const blSavedCard = findSavedCardForBankLimit(bl, savedCards);
      const dueDay = blSavedCard?.dueDay;
      let virtualDueDate: Date | null = null;
      if (dueDay && dueDay >= 1 && dueDay <= 31) {
        const d = new Date(viewYear, viewMonth - 1, dueDay);
        // Geçersiz gün kontrolü (örn. Şubat 30)
        if (d.getMonth() === viewMonth - 1 && d.getDate() === dueDay) {
          virtualDueDate = d;
        }
      }

      items.push({
        kind: "banklimit",
        id: bl.id,
        bankLimitId: bl.id,
        label: bl.institution ? `${bl.institution} (${bl.bank})` : bl.bank,
        category: bl.type === "credit" ? "Kredi Kartı" : "Ek Hesap",
        creditor: bl.institution || bl.bank,
        blType: bl.type,
        totalAmount: bl.limit,
        paidAmount: bl.availableLimit,
        remaining,
        dueDate: virtualDueDate,
        dueDateISO: virtualDueDate ? toLocalDateStr(virtualDueDate) : null,
      });
    }

    // Sort: due date ascending, nulls last, then alpha
    items.sort((a, b) => {
      const ad = a.dueDate ? a.dueDate.getTime() : Number.POSITIVE_INFINITY;
      const bd = b.dueDate ? b.dueDate.getTime() : Number.POSITIVE_INFINITY;
      if (ad !== bd) return ad - bd;
      return a.label.localeCompare(b.label, i18n.language);
    });

    return items;
  }, [debts, bankLimits, savedCards, transactions, calendarViewYM]);


  const highlightedDates = useMemo(() => {
    const m = new Map<string, string[]>();

    const addColor = (dateStr: string, color: string) => {
      const prev = m.get(dateStr) ?? [];
      prev.push(color);
      m.set(dateStr, prev);
    };

    // Payables with explicit due dates — color by category
    for (const p of payables) {
      if (p.dueDateISO) {
        addColor(p.dueDateISO.slice(0, 10), getDebtCategoryColor(p.category));
      }
    }

    // Recurring monthly due days from bank limits (kayıtlı kartın dueDay'i ile)
    const today = new Date();
    for (const bl of bankLimits) {
      const sc = findSavedCardForBankLimit(bl, savedCards);
      const dueDay = sc?.dueDay;
      if (!dueDay || dueDay < 1 || dueDay > 31) continue;
      const blCategory = bl.type === "credit" ? "Kredi Kartı" : "Ek Hesap";
      const blColor = getDebtCategoryColor(blCategory);
      // Add the day for current month ±2 months so calendar navigation works
      for (let offset = -1; offset <= 3; offset++) {
        const d: Date = new Date(today.getFullYear(), today.getMonth() + offset, dueDay);
        if (d.getDate() === dueDay) {
          addColor(
            `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`,
            blColor
          );
        }
      }
    }

    return m;
  }, [payables, bankLimits, savedCards]);

  // ---- UI state -------------------------------------------------------------

  const [calendarDate, setCalendarDate] = useState<string | null>(null);
  // Tüm bölümler varsayılan olarak kapalı; kullanıcı tıklayınca açılır
  const [collapsedSections, setCollapsedSections] = useState<
    Record<string, boolean>
  >({
    installments: true,
    debts: true,
    statements: true,
    creditbl: true,
    overdraft: true,
  });

  // Payment bottom-sheet
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [payModal, setPayModal] = useState(false);
  const [amountInput, setAmountInput] = useState("");
  const [paymentDate, setPaymentDate] = useState<Date>(new Date());
  const [dateModalOpen, setDateModalOpen] = useState(false);
  // Overdraft payment mode: "choose" = show 2 buttons, "full" = pay all, "manual" = custom amount
  const [overdraftMode, setOverdraftMode] = useState<"choose" | "full" | "manual">("choose");

  // Klavye yüksekliği — Ödeme Yap modal'ı için
  const [kbHeight, setKbHeight] = useState(0);
  useEffect(() => {
    const showEv = Platform.OS === "ios" ? "keyboardWillShow" : "keyboardDidShow";
    const hideEv = Platform.OS === "ios" ? "keyboardWillHide" : "keyboardDidHide";
    const s1 = Keyboard.addListener(showEv, (e: KeyboardEvent) => setKbHeight(e.endCoordinates.height));
    const s2 = Keyboard.addListener(hideEv, () => setKbHeight(0));
    return () => { s1.remove(); s2.remove(); };
  }, []);

  // ---- Derived -------------------------------------------------------

  const filteredPayables = useMemo(() => {
    return payables.filter((p) => {
      if (calendarDate) {
        // Belirli bir gün seçildiyse: o güne ait olanlar + vadesi olmayan borçlar
        if (!p.dueDateISO) return false;
        return p.dueDateISO.slice(0, 10) === calendarDate;
      } else {
        // Ay görünümü: o aya ait olanlar + vadesi belirsiz (undated) borçlar
        // Vadesi olmayan tek seferlik borçlar ödenene kadar her ayda görünür
        if (!p.dueDateISO) return true;
        return p.dueDateISO.slice(0, 7) === calendarViewYM;
      }
    });
  }, [payables, calendarDate, calendarViewYM]);

  const sections = useMemo<Section[]>(() => {
    const instItems = filteredPayables.filter(
      (p) => p.kind === "debt" && (p as DebtPayable).installmentIndex != null
    );
    const debtItems = filteredPayables.filter(
      (p) => p.kind === "debt" && (p as DebtPayable).installmentIndex == null
    );
    const stmtItems = filteredPayables.filter((p) => p.kind === "statement");
    const overdraftItems = filteredPayables.filter(
      (p) => p.kind === "banklimit" && (p as BankLimitPayable).blType === "overdraft"
    );
    const creditBLItems = filteredPayables.filter(
      (p) => p.kind === "banklimit" && (p as BankLimitPayable).blType === "credit"
    );
    return [
      {
        id: "installments",
        label: t("payments.groupInstallments"),
        icon: "layers",
        color: getDebtCategoryColor("Banka Kredisi"),
        items: instItems,
      },
      {
        id: "debts",
        label: t("payments.groupDebts"),
        icon: "file-text",
        color: getDebtCategoryColor("Kişisel Borç"),
        items: debtItems,
      },
      {
        id: "statements",
        label: t("payments.groupStatements"),
        icon: "credit-card",
        color: getDebtCategoryColor("Kredi Kartı"),
        items: stmtItems,
      },
      {
        id: "creditbl",
        label: t("payments.groupCreditBL"),
        icon: "credit-card",
        color: getDebtCategoryColor("Kredi Kartı"),
        items: creditBLItems,
      },
      {
        id: "overdraft",
        label: t("payments.groupOverdraft"),
        icon: "dollar-sign",
        color: getDebtCategoryColor("Ek Hesap"),
        items: overdraftItems,
      },
    ].filter((s) => s.items.length > 0);
  }, [filteredPayables, t]);

  const stats = useMemo(() => {
    const monthlyItems = payables.filter(
      (p) => p.dueDateISO && p.dueDateISO.slice(0, 7) === calendarViewYM
    );
    // Human-readable month label (locale-aware)
    const [y, m] = calendarViewYM.split("-").map(Number);
    const monthLabel = new Date(y, (m ?? 1) - 1, 1)
      .toLocaleDateString(i18n.language, { month: "long" });
    return {
      monthlyCount: monthlyItems.length,
      totalCount: payables.length,
      monthlyRemaining: monthlyItems.reduce((s, p) => s + p.remaining, 0),
      totalRemaining: payables.reduce((s, p) => s + p.remaining, 0),
      monthLabel,
    };
  }, [payables, calendarViewYM, i18n.language]);

  const totalRemaining = stats.totalRemaining;

  const selected = payables.find((p) => p.id === selectedId) || null;

  React.useEffect(() => {
    if (selected) {
      setAmountInput(
        selected.remaining.toFixed(2).replace(/\.00$/, "").replace(".", ",")
      );
    } else {
      setAmountInput("");
    }
  }, [selectedId]);

  const isOverdraftSelected =
    selected?.kind === "banklimit" &&
    (selected as BankLimitPayable).blType === "overdraft";

  const numericAmount = parseFloat(amountInput.replace(",", "."));
  const isAmountValid =
    selected != null &&
    (isInstallmentPayable(selected)
      ? true
      : isOverdraftSelected && overdraftMode === "full"
      ? true
      : Number.isFinite(numericAmount) &&
        numericAmount > 0 &&
        numericAmount <= selected.remaining + 0.005);

  // ---- Actions --------------------------------------------------------------

  const handlePay = () => {
    if (!selected || !isAmountValid) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
      return;
    }
    const dateISO = paymentDate.toISOString();
    // Resolve the actual payment amount
    const payAmount =
      isInstallmentPayable(selected)
        ? selected.remaining
        : isOverdraftSelected && overdraftMode === "full"
        ? selected.remaining
        : numericAmount;

    if (selected.kind === "debt") {
      const dp = selected as DebtPayable;
      if (dp.installmentIndex != null) {
        toggleInstallmentPaid(dp.debtId, dp.installmentIndex);
      } else {
        addPayment(dp.debtId, payAmount, dateISO);
      }
    } else if (selected.kind === "statement") {
      recordStatementPayment(
        selected.bankLimitId,
        selected.yearMonth,
        payAmount,
        dateISO
      );
    } else {
      const bl = bankLimits.find((b) => b.id === selected.bankLimitId);
      if (bl) {
        updateBankLimit(bl.id, {
          availableLimit: (bl.availableLimit ?? 0) + payAmount,
        });
      }
    }
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    closePayModal();
  };

  const openPayment = (p: Payable) => {
    Haptics.selectionAsync();
    setSelectedId(p.id);
    setPaymentDate(new Date());
    setOverdraftMode(
      p.kind === "banklimit" && (p as BankLimitPayable).blType === "overdraft"
        ? "choose"
        : "full"
    );
    setPayModal(true);
  };

  const closePayModal = () => {
    setPayModal(false);
    setSelectedId(null);
    setAmountInput("");
    setPaymentDate(new Date());
    setOverdraftMode("choose");
  };

  const toggleSection = (id: string) => {
    Haptics.selectionAsync();
    setCollapsedSections((prev) => ({ ...prev, [id]: !prev[id] }));
  };

  // ---- Helpers --------------------------------------------------------------

  const dueLabel = (p: Payable): string => {
    if (!p.dueDate) return t("payments.noDueDate");
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const due = new Date(p.dueDate);
    due.setHours(0, 0, 0, 0);
    const diff = Math.round(
      (due.getTime() - today.getTime()) / (1000 * 60 * 60 * 24)
    );
    const dateStr = due.toLocaleDateString(i18n.language, {
      day: "numeric",
      month: "short",
    });
    if (diff === 0) return t("payments.dueLabelToday", { date: dateStr });
    if (diff > 0) return t("payments.dueLabelDays", { days: diff, date: dateStr });
    return t("payments.dueLabelOverdue", { days: Math.abs(diff), date: dateStr });
  };

  const isOverdue = (p: Payable): boolean => {
    if (!p.dueDate) return false;
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const due = new Date(p.dueDate);
    due.setHours(0, 0, 0, 0);
    return due.getTime() < today.getTime();
  };

  const iconForPayable = (p: Payable): string => {
    if (p.kind === "statement") return "credit-card";
    if (p.kind === "banklimit")
      return p.blType === "credit" ? "credit-card" : "dollar-sign";
    if (isInstallmentPayable(p)) return "layers";
    return getDebtCategoryIcon(p.category);
  };

  // ---- Styles ---------------------------------------------------------------

  const styles = StyleSheet.create({
    container: { flex: 1, backgroundColor: colors.background },

    // Header
    header: {
      paddingTop: topInset + 12,
      paddingHorizontal: 18,
      paddingBottom: 14,
      backgroundColor: colors.navy,
    },
    headerTitle: {
      fontSize: 22,
      fontWeight: "800" as const,
      color: "#FFFFFF",
      marginBottom: 12,
    },
    summaryRow: { flexDirection: "row", gap: 10, marginBottom: 12 },
    statsGrid: { gap: 8, marginBottom: 12 },
    statsRow: { flexDirection: "row", gap: 8 },
    summaryBox: {
      flex: 1,
      backgroundColor: "rgba(255,255,255,0.10)",
      borderRadius: 12,
      paddingVertical: 10,
      paddingHorizontal: 12,
    },
    summaryLabel: {
      fontSize: 10,
      fontWeight: "600" as const,
      color: "rgba(255,255,255,0.65)",
      letterSpacing: 0.5,
      textTransform: "uppercase" as const,
    },
    summaryValue: {
      fontSize: 17,
      fontWeight: "800" as const,
      color: "#FFFFFF",
      marginTop: 3,
    },

    // Filter chips
    filterRow: {
      flexDirection: "row",
      gap: 8,
    },
    filterChip: {
      flexDirection: "row",
      alignItems: "center",
      gap: 5,
      paddingHorizontal: 11,
      paddingVertical: 7,
      borderRadius: 20,
      backgroundColor: "rgba(255,255,255,0.12)",
      borderWidth: 1,
      borderColor: "rgba(255,255,255,0.18)",
    },
    filterChipActive: {
      backgroundColor: colors.primary,
      borderColor: colors.primary,
    },
    filterChipText: {
      fontSize: 12,
      fontWeight: "600" as const,
      color: "rgba(255,255,255,0.85)",
    },
    filterChipTextActive: { color: "#FFFFFF" },

    // Scroll
    scroll: { flex: 1, padding: 16 },

    // Calendar
    calendarWrap: { marginBottom: 16 },

    // Section header
    sectionHeader: {
      flexDirection: "row",
      alignItems: "center",
      paddingVertical: 10,
      paddingHorizontal: 14,
      backgroundColor: colors.card,
      borderRadius: 12,
      marginBottom: 2,
      gap: 10,
    },
    sectionHeaderExpanded: {
      borderBottomLeftRadius: 0,
      borderBottomRightRadius: 0,
    },
    sectionIconWrap: {
      width: 30,
      height: 30,
      borderRadius: 8,
      alignItems: "center",
      justifyContent: "center",
      backgroundColor: colors.primary + "18",
    },
    sectionLabel: {
      flex: 1,
      fontSize: 13,
      fontWeight: "700" as const,
      color: colors.foreground,
    },
    sectionMeta: {
      fontSize: 12,
      color: colors.mutedForeground,
      fontWeight: "500" as const,
    },

    // Section body
    sectionBody: {
      backgroundColor: colors.card,
      borderBottomLeftRadius: 12,
      borderBottomRightRadius: 12,
      marginBottom: 12,
      overflow: "hidden" as const,
    },

    // Payable row
    payRow: {
      flexDirection: "row",
      alignItems: "center",
      gap: 10,
      paddingVertical: 12,
      paddingHorizontal: 14,
      borderTopWidth: StyleSheet.hairlineWidth,
      borderTopColor: colors.border,
    },
    payIconWrap: {
      width: 34,
      height: 34,
      borderRadius: 9,
      alignItems: "center",
      justifyContent: "center",
      backgroundColor: colors.primary + "14",
    },
    payInfo: { flex: 1 },
    payLabel: {
      fontSize: 13,
      fontWeight: "700" as const,
      color: colors.foreground,
    },
    payDue: {
      fontSize: 11,
      color: colors.mutedForeground,
      marginTop: 2,
    },
    payDueOverdue: { color: colors.expense },
    payAmtWrap: { alignItems: "flex-end", gap: 3 },
    payAmt: {
      fontSize: 13,
      fontWeight: "800" as const,
      color: colors.expense,
    },
    overdueBadge: {
      backgroundColor: colors.expense + "20",
      paddingHorizontal: 5,
      paddingVertical: 2,
      borderRadius: 5,
    },
    overdueBadgeText: {
      fontSize: 9,
      fontWeight: "800" as const,
      color: colors.expense,
    },

    // Empty
    empty: {
      marginTop: 50,
      alignItems: "center",
      paddingHorizontal: 30,
    },
    emptyIconWrap: {
      width: 68,
      height: 68,
      borderRadius: 34,
      backgroundColor: colors.income + "18",
      alignItems: "center",
      justifyContent: "center",
      marginBottom: 14,
    },
    emptyTitle: {
      fontSize: 17,
      fontWeight: "800" as const,
      color: colors.foreground,
      marginBottom: 6,
      textAlign: "center" as const,
    },
    emptyText: {
      fontSize: 13,
      color: colors.mutedForeground,
      textAlign: "center" as const,
      lineHeight: 19,
    },
    noResultsText: {
      textAlign: "center" as const,
      color: colors.mutedForeground,
      fontSize: 13,
      paddingVertical: 20,
    },

    // Payment modal
    modalBackdrop: {
      flex: 1,
      backgroundColor: "rgba(0,0,0,0.5)",
      justifyContent: "flex-end",
    },
    modalContent: {
      backgroundColor: colors.card,
      borderTopLeftRadius: 24,
      borderTopRightRadius: 24,
      paddingBottom: insets.bottom + 16,
      paddingHorizontal: 20,
    },
    modalHandle: {
      width: 40,
      height: 4,
      backgroundColor: colors.border,
      borderRadius: 2,
      alignSelf: "center" as const,
      marginTop: 10,
      marginBottom: 4,
    },
    modalTitle: {
      fontSize: 17,
      fontWeight: "700" as const,
      color: colors.foreground,
      paddingVertical: 12,
      textAlign: "center" as const,
    },
    modalSubtitle: {
      fontSize: 12,
      color: colors.mutedForeground,
      textAlign: "center" as const,
      marginBottom: 16,
    },
    detailRow: {
      flexDirection: "row",
      justifyContent: "space-between",
      paddingVertical: 6,
    },
    detailKey: { fontSize: 12, color: colors.mutedForeground },
    detailVal: { fontSize: 12, fontWeight: "700" as const, color: colors.foreground },
    remainingPill: {
      backgroundColor: colors.expense + "16",
      paddingHorizontal: 8,
      paddingVertical: 3,
      borderRadius: 8,
    },
    remainingPillText: {
      color: colors.expense,
      fontSize: 12,
      fontWeight: "800" as const,
    },
    divider: {
      height: StyleSheet.hairlineWidth,
      backgroundColor: colors.border,
      marginVertical: 12,
    },
    amountWrap: {
      flexDirection: "row",
      alignItems: "center",
      backgroundColor: colors.background,
      borderRadius: 14,
      paddingHorizontal: 14,
      marginBottom: 10,
    },
    currency: {
      fontSize: 22,
      fontWeight: "700" as const,
      color: colors.primary,
      marginRight: 4,
    },
    amountInput: {
      flex: 1,
      fontSize: 24,
      fontWeight: "700" as const,
      color: colors.foreground,
      paddingVertical: 12,
    },
    quickRow: { flexDirection: "row", gap: 8, marginBottom: 12 },
    quickBtn: {
      flex: 1,
      borderRadius: 10,
      borderWidth: 1.5,
      borderColor: colors.border,
      backgroundColor: colors.background,
      paddingVertical: 9,
      alignItems: "center",
    },
    quickBtnText: {
      color: colors.foreground,
      fontSize: 12,
      fontWeight: "600" as const,
    },
    dateSelector: {
      flexDirection: "row",
      alignItems: "center",
      gap: 10,
      backgroundColor: colors.background,
      borderRadius: 12,
      paddingHorizontal: 14,
      paddingVertical: 12,
      marginBottom: 14,
    },
    dateText: { fontSize: 14, color: colors.foreground, flex: 1 },
    submitBtn: {
      borderRadius: 14,
      paddingVertical: 15,
      alignItems: "center",
      backgroundColor: isAmountValid ? colors.primary : colors.muted,
    },
    submitBtnText: {
      fontSize: 15,
      fontWeight: "800" as const,
      color: isAmountValid ? "#FFFFFF" : colors.mutedForeground,
    },
    cancelBtn: {
      borderRadius: 14,
      paddingVertical: 14,
      alignItems: "center" as const,
      backgroundColor: colors.muted,
      marginTop: 10,
    },
    cancelBtnText: {
      fontSize: 15,
      fontWeight: "700" as const,
      color: colors.foreground,
    },

    // Overdraft 2-option buttons
    overdraftOptionBtn: {
      flexDirection: "row" as const,
      alignItems: "center",
      paddingVertical: 14,
      paddingHorizontal: 16,
      borderRadius: 14,
    },
    overdraftOptionTitle: {
      fontSize: 15,
      fontWeight: "700" as const,
    },
    overdraftOptionSub: {
      fontSize: 12,
      marginTop: 2,
    },

  });

  // ---- Render ---------------------------------------------------------------

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>{t("payments.title")}</Text>
        {/* 2x2 istatistik grid */}
        <View style={styles.statsGrid}>
          <View style={styles.statsRow}>
            <View style={styles.summaryBox}>
              <Text style={styles.summaryLabel} numberOfLines={1}>
                {t("payments.monthPending", { month: stats.monthLabel })}
              </Text>
              <Text style={styles.summaryValue}>{stats.monthlyCount}</Text>
            </View>
            <View style={styles.summaryBox}>
              <Text style={styles.summaryLabel}>{t("payments.totalPending")}</Text>
              <Text style={styles.summaryValue}>{stats.totalCount}</Text>
            </View>
          </View>
          <View style={styles.statsRow}>
            <View style={styles.summaryBox}>
              <Text style={styles.summaryLabel} numberOfLines={1}>
                {t("payments.monthRemaining", { month: stats.monthLabel })}
              </Text>
              <Text style={[styles.summaryValue, { fontSize: 14 }]}>
                {formatAmount(stats.monthlyRemaining)}
              </Text>
            </View>
            <View style={styles.summaryBox}>
              <Text style={styles.summaryLabel}>{t("payments.totalRemaining")}</Text>
              <Text style={[styles.summaryValue, { fontSize: 14 }]}>
                {formatAmount(stats.totalRemaining)}
              </Text>
            </View>
          </View>
        </View>

        {calendarDate != null && (
          <View style={styles.filterRow}>
            <TouchableOpacity
              style={[styles.filterChip, styles.filterChipActive]}
              onPress={() => { Haptics.selectionAsync(); setCalendarDate(null); }}
            >
              <Feather name="calendar" size={11} color="#FFFFFF" />
              <Text style={[styles.filterChipText, styles.filterChipTextActive]}>
                {new Date(calendarDate + "T12:00:00").toLocaleDateString(i18n.language, {
                  day: "numeric", month: "short",
                })}
              </Text>
              <Feather name="x" size={11} color="#FFFFFF" />
            </TouchableOpacity>
          </View>
        )}
      </View>

      <KeyboardAwareScrollViewCompat
        style={styles.scroll}
        showsVerticalScrollIndicator={false}
        keyboardShouldPersistTaps="handled"
        bottomOffset={20}
      >
        {/* Calendar */}
        <View style={styles.calendarWrap}>
          <Calendar
            value={paymentDate}
            onChange={setPaymentDate}
            highlightedDates={highlightedDates}
            selectedDateStr={calendarDate}
            onSelectDate={setCalendarDate}
            onViewMonthChange={setCalendarViewYM}
          />
        </View>

        {/* Empty state */}
        {payables.length === 0 ? (
          <View style={styles.empty}>
            <View style={styles.emptyIconWrap}>
              <Feather name="check" size={30} color={colors.income} />
            </View>
            <Text style={styles.emptyTitle}>{t("payments.allDone")}</Text>
            <Text style={styles.emptyText}>{t("payments.emptyText")}</Text>
          </View>
        ) : filteredPayables.length === 0 ? (
          <Text style={styles.noResultsText}>
            {t("payments.noResults")}
          </Text>
        ) : (
          sections.map((sec) => {
            const collapsed = !!collapsedSections[sec.id];
            const secTotal = sec.items.reduce((s, p) => s + p.remaining, 0);
            return (
              <View key={sec.id}>
                {/* Section header */}
                <Pressable
                  style={[
                    styles.sectionHeader,
                    !collapsed && styles.sectionHeaderExpanded,
                  ]}
                  onPress={() => toggleSection(sec.id)}
                >
                  <View style={[styles.sectionIconWrap, { backgroundColor: sec.color + "22", pointerEvents: "none" } as any]}>
                    <Feather
                      name={sec.icon as any}
                      size={14}
                      color={sec.color}
                    />
                  </View>
                  <Text style={[styles.sectionLabel, { color: sec.color, pointerEvents: "none" } as any]}>
                    {sec.label}
                  </Text>
                  <Text style={[styles.sectionMeta, { pointerEvents: "none" } as any]}>
                    {sec.items.length} • {formatAmount(secTotal)}
                  </Text>
                  <View style={{ pointerEvents: "none" } as any}>
                    <Feather
                      name={collapsed ? "chevron-down" : "chevron-up"}
                      size={16}
                      color={colors.mutedForeground}
                    />
                  </View>
                </Pressable>

                {/* Section rows */}
                {!collapsed && (
                  <View style={styles.sectionBody}>
                    {sec.items.map((p) => {
                      const overdue = isOverdue(p);
                      return (
                        <Pressable
                          key={p.id}
                          style={styles.payRow}
                          onPress={() => openPayment(p)}
                        >
                          <View style={[styles.payIconWrap, { backgroundColor: getDebtCategoryColor(p.category) + "1A", pointerEvents: "none" } as any]}>
                            <Feather
                              name={iconForPayable(p) as any}
                              size={15}
                              color={getDebtCategoryColor(p.category)}
                            />
                          </View>
                          <View style={[styles.payInfo, { pointerEvents: "none" } as any]}>
                            <Text style={styles.payLabel} numberOfLines={1}>
                              {p.label}
                            </Text>
                            <Text
                              style={[
                                styles.payDue,
                                overdue && styles.payDueOverdue,
                              ]}
                            >
                              {dueLabel(p)}
                            </Text>
                          </View>
                          <View style={[styles.payAmtWrap, { pointerEvents: "none" } as any]}>
                            <Text style={styles.payAmt}>
                              {formatAmount(p.remaining)}
                            </Text>
                            {overdue && (
                              <View style={styles.overdueBadge}>
                                <Text style={styles.overdueBadgeText}>
                                  {t("payments.overdueBadge")}
                                </Text>
                              </View>
                            )}
                          </View>
                          <View style={{ pointerEvents: "none" } as any}>
                            <Feather
                              name="chevron-right"
                              size={14}
                              color={colors.mutedForeground}
                            />
                          </View>
                        </Pressable>
                      );
                    })}
                  </View>
                )}
              </View>
            );
          })
        )}

        <View style={{ height: bottomInset + 80 }} />
      </KeyboardAwareScrollViewCompat>

      {/* Payment bottom sheet */}
      <Modal
        visible={payModal}
        transparent
        animationType="slide"
        onRequestClose={closePayModal}
      >
        <Pressable style={styles.modalBackdrop} onPress={closePayModal}>
          <Pressable style={[styles.modalContent, { marginBottom: kbHeight }]} onPress={() => {}}>
            <View style={styles.modalHandle} />
            <Text style={styles.modalTitle}>{t("payments.makePayment")}</Text>
            {selected && (
              <Text style={styles.modalSubtitle} numberOfLines={1}>
                {selected.label}
              </Text>
            )}

            {/* Taksit rozeti */}
            {selected && isInstallmentPayable(selected) && (() => {
              const dp = selected as DebtPayable;
              return (
                <View style={{ alignItems: "center", marginBottom: 10 }}>
                  <View style={{
                    flexDirection: "row", alignItems: "center", gap: 6,
                    backgroundColor: colors.primary + "18",
                    paddingHorizontal: 12, paddingVertical: 6, borderRadius: 20,
                  }}>
                    <Feather name="layers" size={13} color={colors.primary} />
                    <Text style={{ fontSize: 12, fontWeight: "700" as const, color: colors.primary }}>
                      {t("payments.installmentBadge", { index: (dp.installmentIndex ?? 0) + 1, total: dp.installmentTotal })}
                    </Text>
                  </View>
                </View>
              );
            })()}

            {/* Ek hesap: toplam borç özet satırı */}
            {selected && isOverdraftSelected && (
              <>
                <View style={styles.detailRow}>
                  <Text style={styles.detailKey}>{t("payments.usedDebt")}</Text>
                  <View style={styles.remainingPill}>
                    <Text style={styles.remainingPillText}>
                      {formatAmount(selected.remaining)}
                    </Text>
                  </View>
                </View>
                <View style={styles.detailRow}>
                  <Text style={styles.detailKey}>{t("payments.totalLimit")}</Text>
                  <Text style={styles.detailVal}>{formatAmount(selected.totalAmount)}</Text>
                </View>
              </>
            )}

            {/* Normal detay satırları (ek hesap dışı) */}
            {selected && !isOverdraftSelected && (
              <>
                {!isInstallmentPayable(selected) && (
                  <>
                    <View style={styles.detailRow}>
                      <Text style={styles.detailKey}>{t("payments.total")}</Text>
                      <Text style={styles.detailVal}>
                        {formatAmount(selected.totalAmount)}
                      </Text>
                    </View>
                    <View style={styles.detailRow}>
                      <Text style={styles.detailKey}>{t("payments.paidAmount")}</Text>
                      <Text style={styles.detailVal}>
                        {formatAmount(selected.paidAmount)}
                      </Text>
                    </View>
                  </>
                )}
                <View style={styles.detailRow}>
                  <Text style={styles.detailKey}>
                    {isInstallmentPayable(selected) ? t("payments.installmentAmount") : t("payments.remaining")}
                  </Text>
                  <View style={styles.remainingPill}>
                    <Text style={styles.remainingPillText}>
                      {formatAmount(selected.remaining)}
                    </Text>
                  </View>
                </View>
                {selected.dueDate && (
                  <View style={styles.detailRow}>
                    <Text style={styles.detailKey}>
                      {isInstallmentPayable(selected) ? t("payments.installmentMonth") : t("payments.dueDate")}
                    </Text>
                    <Text
                      style={[
                        styles.detailVal,
                        isOverdue(selected) && { color: colors.expense },
                      ]}
                    >
                      {isInstallmentPayable(selected)
                        ? selected.dueDate.toLocaleDateString(i18n.language, {
                            month: "long", year: "numeric",
                          })
                        : selected.dueDate.toLocaleDateString(i18n.language, {
                            day: "numeric", month: "long", year: "numeric",
                          })}
                    </Text>
                  </View>
                )}
              </>
            )}

            <View style={styles.divider} />

            {/* ─── Ek hesap: 2 seçenek ─────────────────────────────── */}
            {selected && isOverdraftSelected && overdraftMode === "choose" ? (
              <View style={{ gap: 10, marginBottom: 6 }}>
                <TouchableOpacity
                  style={[styles.overdraftOptionBtn, { backgroundColor: colors.primary }]}
                  onPress={() => {
                    Haptics.selectionAsync();
                    setOverdraftMode("full");
                  }}
                >
                  <Feather name="check-circle" size={18} color="#FFFFFF" />
                  <View style={{ flex: 1, marginLeft: 10 }}>
                    <Text style={[styles.overdraftOptionTitle, { color: "#FFFFFF" }]}>
                      {t("payments.payFull")}
                    </Text>
                    <Text style={[styles.overdraftOptionSub, { color: "rgba(255,255,255,0.8)" }]}>
                      {t("payments.payAllSub", { amount: formatAmount(selected.remaining) })}
                    </Text>
                  </View>
                  <Feather name="chevron-right" size={16} color="rgba(255,255,255,0.8)" />
                </TouchableOpacity>
                <TouchableOpacity
                  style={[styles.overdraftOptionBtn, {
                    backgroundColor: colors.card,
                    borderWidth: 1.5,
                    borderColor: colors.primary,
                  }]}
                  onPress={() => {
                    Haptics.selectionAsync();
                    setOverdraftMode("manual");
                    setAmountInput("");
                  }}
                >
                  <Feather name="edit-2" size={18} color={colors.primary} />
                  <View style={{ flex: 1, marginLeft: 10 }}>
                    <Text style={[styles.overdraftOptionTitle, { color: colors.foreground }]}>
                      {t("payments.manualAmount")}
                    </Text>
                    <Text style={[styles.overdraftOptionSub, { color: colors.mutedForeground }]}>
                      {t("payments.manualAmountSub")}
                    </Text>
                  </View>
                  <Feather name="chevron-right" size={16} color={colors.mutedForeground} />
                </TouchableOpacity>
              </View>
            ) : selected && isOverdraftSelected && overdraftMode === "full" ? (
              /* Tamamını öde: tutar sabit gösterim */
              <>
                <View style={[styles.amountWrap, { justifyContent: "center" }]}>
                  <Text style={[styles.currency, { fontSize: 18 }]}>₺</Text>
                  <Text style={[styles.amountInput, { fontSize: 24 }]}>
                    {formatAmount(selected.remaining).replace("₺", "").trim()}
                  </Text>
                </View>
                <TouchableOpacity
                  style={{ alignSelf: "center", marginBottom: 10 }}
                  onPress={() => { Haptics.selectionAsync(); setOverdraftMode("choose"); }}
                >
                  <Text style={{ fontSize: 12, color: colors.primary }}>{t("payments.goBack")}</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={styles.dateSelector}
                  onPress={() => { Haptics.selectionAsync(); setDateModalOpen(true); }}
                >
                  <Feather name="calendar" size={15} color={colors.mutedForeground} />
                  <Text style={styles.dateText}>
                    {paymentDate.toLocaleDateString(i18n.language, { day: "numeric", month: "long", year: "numeric" })}
                  </Text>
                  <Feather name="chevron-down" size={16} color={colors.mutedForeground} />
                </TouchableOpacity>
                <TouchableOpacity
                  style={[styles.submitBtn, { backgroundColor: colors.primary }]}
                  onPress={handlePay}
                  activeOpacity={0.85}
                >
                  <Text style={[styles.submitBtnText, { color: "#FFFFFF" }]}>
                    {t("payments.payAmount", { amount: formatAmount(selected.remaining) })}
                  </Text>
                </TouchableOpacity>
              </>
            ) : selected && isOverdraftSelected && overdraftMode === "manual" ? (
              /* Manuel tutar */
              <>
                <View style={styles.amountWrap}>
                  <Text style={styles.currency}>₺</Text>
                  <TextInput
                    style={styles.amountInput}
                    value={amountInput}
                    onChangeText={setAmountInput}
                    keyboardType="decimal-pad"
                    placeholder="0,00"
                    placeholderTextColor={colors.mutedForeground}
                    autoFocus
                  />
                </View>
                <View style={[styles.quickRow, { marginBottom: 8 }]}>
                  <TouchableOpacity
                    style={styles.quickBtn}
                    onPress={() => {
                      Haptics.selectionAsync();
                      setAmountInput(selected.remaining.toFixed(2).replace(/\.00$/, "").replace(".", ","));
                    }}
                  >
                    <Text style={styles.quickBtnText}>{t("payments.allAmount")}</Text>
                  </TouchableOpacity>
                  <TouchableOpacity
                    style={styles.quickBtn}
                    onPress={() => {
                      Haptics.selectionAsync();
                      setAmountInput((selected.remaining / 2).toFixed(2).replace(/\.00$/, "").replace(".", ","));
                    }}
                  >
                    <Text style={styles.quickBtnText}>{t("payments.payHalf")}</Text>
                  </TouchableOpacity>
                </View>
                <TouchableOpacity
                  style={{ alignSelf: "center", marginBottom: 10 }}
                  onPress={() => { Haptics.selectionAsync(); setOverdraftMode("choose"); setAmountInput(""); }}
                >
                  <Text style={{ fontSize: 12, color: colors.primary }}>{t("payments.goBack")}</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={styles.dateSelector}
                  onPress={() => { Haptics.selectionAsync(); setDateModalOpen(true); }}
                >
                  <Feather name="calendar" size={15} color={colors.mutedForeground} />
                  <Text style={styles.dateText}>
                    {paymentDate.toLocaleDateString(i18n.language, { day: "numeric", month: "long", year: "numeric" })}
                  </Text>
                  <Feather name="chevron-down" size={16} color={colors.mutedForeground} />
                </TouchableOpacity>
                <TouchableOpacity
                  style={[styles.submitBtn, { backgroundColor: isAmountValid ? colors.primary : colors.muted }]}
                  onPress={handlePay}
                  activeOpacity={0.85}
                  disabled={!isAmountValid}
                >
                  <Text style={[styles.submitBtnText, { color: isAmountValid ? "#FFFFFF" : colors.mutedForeground }]}>
                    {isAmountValid ? t("payments.payAmount", { amount: formatAmount(numericAmount) }) : t("payments.enterAmount")}
                  </Text>
                </TouchableOpacity>
              </>
            ) : (
              /* Normal borç / taksit / ekstre ödeme alanı */
              <>
                {selected && isInstallmentPayable(selected) ? (
                  <View style={[styles.amountWrap, { justifyContent: "center" }]}>
                    <Text style={[styles.currency, { fontSize: 18 }]}>₺</Text>
                    <Text style={[styles.amountInput, { fontSize: 24 }]}>
                      {selected ? formatAmount(selected.remaining).replace("₺", "").trim() : ""}
                    </Text>
                  </View>
                ) : (
                  <View style={styles.amountWrap}>
                    <Text style={styles.currency}>₺</Text>
                    <TextInput
                      style={styles.amountInput}
                      value={amountInput}
                      onChangeText={setAmountInput}
                      keyboardType="decimal-pad"
                      placeholder="0,00"
                      placeholderTextColor={colors.mutedForeground}
                    />
                  </View>
                )}

                {selected && !isInstallmentPayable(selected) && (
                  <View style={styles.quickRow}>
                    <TouchableOpacity
                      style={styles.quickBtn}
                      onPress={() => {
                        Haptics.selectionAsync();
                        setAmountInput(
                          selected.remaining.toFixed(2).replace(/\.00$/, "").replace(".", ",")
                        );
                      }}
                    >
                      <Text style={styles.quickBtnText}>{t("payments.allAmount")}</Text>
                    </TouchableOpacity>
                    <TouchableOpacity
                      style={styles.quickBtn}
                      onPress={() => {
                        Haptics.selectionAsync();
                        setAmountInput(
                          (selected.remaining / 2).toFixed(2).replace(/\.00$/, "").replace(".", ",")
                        );
                      }}
                    >
                      <Text style={styles.quickBtnText}>{t("payments.payHalf")}</Text>
                    </TouchableOpacity>
                  </View>
                )}

                <TouchableOpacity
                  style={styles.dateSelector}
                  onPress={() => { Haptics.selectionAsync(); setDateModalOpen(true); }}
                >
                  <Feather name="calendar" size={15} color={colors.mutedForeground} />
                  <Text style={styles.dateText}>
                    {paymentDate.toLocaleDateString(i18n.language, {
                      day: "numeric", month: "long", year: "numeric",
                    })}
                  </Text>
                  <Feather name="chevron-down" size={16} color={colors.mutedForeground} />
                </TouchableOpacity>

                <TouchableOpacity
                  style={styles.submitBtn}
                  onPress={handlePay}
                  activeOpacity={0.85}
                  disabled={!isAmountValid}
                >
                  <Text style={styles.submitBtnText}>
                    {selected && isInstallmentPayable(selected)
                      ? t("payments.payInstallment", { amount: formatAmount(selected.remaining) })
                      : isAmountValid
                      ? t("payments.payAmount", { amount: formatAmount(numericAmount) })
                      : t("payments.pay")}
                  </Text>
                </TouchableOpacity>
              </>
            )}

            <TouchableOpacity style={styles.cancelBtn} onPress={closePayModal}>
              <Text style={styles.cancelBtnText}>{t("payments.cancel")}</Text>
            </TouchableOpacity>
          </Pressable>
        </Pressable>
      </Modal>

      {/* Date picker (inside payment modal) */}
      <Modal
        visible={dateModalOpen}
        transparent
        animationType="slide"
        onRequestClose={() => setDateModalOpen(false)}
      >
        <Pressable
          style={styles.modalBackdrop}
          onPress={() => setDateModalOpen(false)}
        >
          <Pressable style={styles.modalContent} onPress={() => {}}>
            <View style={styles.modalHandle} />
            <Text style={styles.modalTitle}>{t("payments.selectDate")}</Text>
            <Calendar
              value={paymentDate}
              onChange={(d) => {
                setPaymentDate(d);
                setDateModalOpen(false);
              }}
            />
            <TouchableOpacity
              style={[styles.cancelBtn, { marginTop: 8, marginBottom: 8 }]}
              onPress={() => setDateModalOpen(false)}
            >
              <Text style={styles.cancelBtnText}>{t("payments.cancel")}</Text>
            </TouchableOpacity>
          </Pressable>
        </Pressable>
      </Modal>

    </View>
  );
}
