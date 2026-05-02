import { Feather } from "@expo/vector-icons";
import * as Haptics from "expo-haptics";
import { LinearGradient } from "expo-linear-gradient";
import { useLocalSearchParams, useRouter } from "expo-router";
import React, { useEffect, useRef, useMemo, useState } from "react";
import {
  Animated,
  Alert,
  Keyboard,
  KeyboardEvent,
  Modal,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Switch,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useTranslation } from "react-i18next";

import DatePickerSheet from "@/components/finans/DatePickerSheet";
import PlatformAvatar from "@/components/finans/PlatformAvatar";
import { DebtFlowTable } from "@/components/finans/DebtFlowTable";
import { DebtSummaryTable } from "@/components/finans/DebtSummaryTable";
import { DebtSummaryVisual } from "@/components/finans/DebtSummaryVisual";
import { DebtWizard } from "@/components/finans/DebtWizard";
import { KeyboardAwareScrollViewCompat } from "@/components/finans/KeyboardAwareScrollViewCompat";
import { BankLimit, Debt, MonthlyBreakdown, useBudget } from "@/context/finans/BudgetContext";
import { useColors } from "@/hooks/finans/useColors";
import { BANKS, getDebtCategoryIcon, getDebtCategoryColor } from "@/utils/finans/categories";
import { todayYM, installmentRemainingAtYM, regularRemainingAtYM } from "@/utils/finans/debtCalc";
import { useFormatAmount } from "@/hooks/finans/useFormatAmount";
import {
  findSavedCardForBankLimit,
  formatStatementYearMonth,
  getActiveStatementYearMonth,
  getAllStatementsForCard,
  type ResolvedStatement,
} from "@/utils/finans/statements";

type SortKey =
  | "alpha"
  | "amount"
  | "date";
type CardSortKey = "amount" | "date";


function daysUntil(iso?: string): number | null {
  if (!iso) return null;
  const target = new Date(iso);
  target.setHours(0, 0, 0, 0);
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  return Math.round((target.getTime() - today.getTime()) / 86400000);
}

export default function DebtsScreen() {
  const { t, i18n } = useTranslation();
  const formatAmount = useFormatAmount();
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const params = useLocalSearchParams<{ cardId?: string }>();
  const {
    debts,
    addDebt,
    updateDebt,
    deleteDebt,
    addPayment,
    addDebtCategory,
    allDebtCategories,
    bankLimits,
    savedCards,
    transactions,
    setManualStatementAmount,
    updateBankLimit,
  } = useBudget();

  // Resolved statements per card (single source of truth)
  const cardData = useMemo(() => {
    return bankLimits
      .map((b) => {
        const sc = findSavedCardForBankLimit(b, savedCards);
        const statements = getAllStatementsForCard({
          bankLimit: b,
          savedCard: sc,
          transactions,
        });
        // Total CC debt = limit - availableLimit (BankLimit is source of truth).
        // For overdraft: use limit-availableLimit if reconciled, else full limit.
        // For credit: fall back to statements when availableLimit is not set.
        const totalDebt =
          b.availableLimit !== undefined
            ? Math.max(0, b.limit - (b.availableLimit ?? 0))
            : b.type === "overdraft"
              ? b.limit
              : statements
                  .filter((s) => !s.isActive && !s.isFuture)
                  .reduce((sum, s) => sum + s.remaining, 0);
        return {
          bankLimit: b,
          savedCard: sc,
          statements,
          totalDebt,
          hasStatementDay: !!sc?.statementDay,
        };
      })
      .filter(
        (c) =>
          c.bankLimit.type === "credit" ||
          (c.bankLimit.type === "overdraft" && c.bankLimit.limit > 0) ||
          c.totalDebt > 0 ||
          c.statements.length > 0
      );
  }, [bankLimits, savedCards, transactions]);

  const bankLimitContribToGrand = useMemo(
    () => cardData.reduce((s, c) => s + c.totalDebt, 0),
    [cardData]
  );

  const [viewMode, setViewMode] = useState<"analiz" | "detail">("detail");

  const [cardSortKey, setCardSortKey] = useState<CardSortKey>("amount");
  const [cardBankFilter, setCardBankFilter] = useState<string | null>(null);
  const [cardBankPickerOpen, setCardBankPickerOpen] = useState(false);

  const cardBankOptions = useMemo(() => {
    const names = Array.from(
      new Set(cardData.map((c) => c.bankLimit.institution || c.bankLimit.bank))
    ).sort();
    return names;
  }, [cardData]);

  // Consistent total: same formula as DebtSummaryVisual so header and
  // Analiz "KALAN" always match.
  const grandTotalRemaining = useMemo(() => {
    const currentYM = todayYM();
    const debtRemainingNow = debts
      .filter((d) => {
        const startYM = d.date.slice(0, 7);
        return startYM <= currentYM;
      })
      .reduce((s, d) => {
        const kalan = d.isInstallment
          ? installmentRemainingAtYM(d.amount, d.date, d.totalInstallments ?? 1, currentYM)
          : regularRemainingAtYM(d.amount, d.payments ?? [], currentYM);
        return s + Math.max(0, kalan);
      }, 0);
    return debtRemainingNow + bankLimitContribToGrand;
  }, [debts, bankLimitContribToGrand]);

  const [editId, setEditId] = useState<string | null>(null);
  const [modalVisible, setModalVisible] = useState(false);

  const [paymentDebt, setPaymentDebt] = useState<Debt | null>(null);
  const [paymentAmount, setPaymentAmount] = useState("");
  const [paymentDate, setPaymentDate] = useState<Date>(new Date());
  const [paymentDateOpen, setPaymentDateOpen] = useState(false);

  const [sortKey, setSortKey] = useState<SortKey>("alpha");
  const [sortDir, setSortDir] = useState<"asc" | "desc">("asc");
  const [creditorFilter, setCreditorFilter] = useState<string | null>(null);
  const [debtTypeFilter, setDebtTypeFilter] = useState<string | null>(null);
  const [filterPickerOpen, setFilterPickerOpen] = useState<"creditor" | "type" | null>(null);

  const CC_TYPE_LABELS = { credit: t("debts.creditCard"), demand: t("debts.overdraftAccount") };
  const CC_FILTER_VALUES: string[] = [CC_TYPE_LABELS.credit, CC_TYPE_LABELS.demand];

  const sortedCardData = useMemo(() => {
    let copy = [...cardData];
    // Borç tipi filtresi (Kredi Kartı / Ek Hesap)
    if (debtTypeFilter === CC_TYPE_LABELS.credit) {
      copy = copy.filter((c) => c.bankLimit.type === "credit");
    } else if (debtTypeFilter === CC_TYPE_LABELS.demand) {
      copy = copy.filter((c) => c.bankLimit.type !== "credit");
    }
    // Alacaklı filtresi: banka/kurum adına göre eşleştir
    if (creditorFilter) {
      copy = copy.filter(
        (c) => (c.bankLimit.institution || c.bankLimit.bank) === creditorFilter
      );
    }
    copy.sort((a, b) => {
      if (sortKey === "date") {
        const dayA = a.savedCard?.dueDay ?? Infinity;
        const dayB = b.savedCard?.dueDay ?? Infinity;
        return dayA - dayB;
      }
      let cmp = 0;
      if (sortKey === "amount") {
        cmp = b.totalDebt - a.totalDebt;
      } else {
        const nameA = a.bankLimit.institution || a.bankLimit.bank;
        const nameB = b.bankLimit.institution || b.bankLimit.bank;
        cmp = nameA.localeCompare(nameB, i18n.language, { sensitivity: "base" });
      }
      return sortDir === "desc" ? -cmp : cmp;
    });
    return copy;
  }, [cardData, sortKey, sortDir, debtTypeFilter, creditorFilter]);

  const [expandedId, setExpandedId] = useState<string | null>(null);

  // Auto-card (bank limit) expansion state
  const [expandedAutoId, setExpandedAutoId] = useState<string | null>(null);

  // Honor ?cardId= deep-link from Nakit Akışı warnings
  useEffect(() => {
    const cid = typeof params.cardId === "string" ? params.cardId : undefined;
    if (cid) setExpandedAutoId(cid);
  }, [params.cardId]);

  // Overdraft quick-edit modal state
  const [odEditBl, setOdEditBl] = useState<BankLimit | null>(null);
  const [odEditAmt, setOdEditAmt] = useState("");   // kalan limit
  const [odEditDebt, setOdEditDebt] = useState(""); // borç miktarı
  const [odKbHeight, setOdKbHeight] = useState(0); // klavye yüksekliği

  useEffect(() => {
    const showEv = Platform.OS === "ios" ? "keyboardWillShow" : "keyboardDidShow";
    const hideEv = Platform.OS === "ios" ? "keyboardWillHide" : "keyboardDidHide";
    const s1 = Keyboard.addListener(showEv, (e: KeyboardEvent) => setOdKbHeight(e.endCoordinates.height));
    const s2 = Keyboard.addListener(hideEv, () => setOdKbHeight(0));
    return () => { s1.remove(); s2.remove(); };
  }, []);

  // Monthly breakdown modal state
  const [breakdownModal, setBreakdownModal] = useState(false);
  const [breakdownDebtId, setBreakdownDebtId] = useState<string | null>(null);
  const [breakdownBankLimit, setBreakdownBankLimit] = useState<BankLimit | null>(null);
  const [breakdownOriginalYM, setBreakdownOriginalYM] = useState<string | null>(null);
  const [breakdownEditIdx, setBreakdownEditIdx] = useState<number | null>(null);
  const [breakdownYM, setBreakdownYM] = useState(() => {
    const d = new Date();
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
  });
  const [breakdownAmount, setBreakdownAmount] = useState("");

  const topInset = 0;
  const bottomInset = Platform.OS === "web" ? 34 : insets.bottom;

  const scrollRef = useRef<ScrollView>(null);
  const [showScrollTop, setShowScrollTop] = useState(false);
  const scrollTopOpacity = useRef(new Animated.Value(0)).current;

  const handleScroll = (e: { nativeEvent: { contentOffset: { y: number } } }) => {
    const y = e.nativeEvent.contentOffset.y;
    const shouldShow = y > 250;
    if (shouldShow !== showScrollTop) {
      setShowScrollTop(shouldShow);
      Animated.timing(scrollTopOpacity, {
        toValue: shouldShow ? 1 : 0,
        duration: 200,
        useNativeDriver: true,
      }).start();
    }
  };

  const scrollToTop = () => {
    Haptics.selectionAsync();
    scrollRef.current?.scrollTo({ y: 0, animated: true });
  };

  // Unique creditor and category options for filter pickers
  const creditorOptions = useMemo(() => {
    const manualCreditors = debts
      .filter((d) => !d.bankLimitId && d.creditor?.trim())
      .map((d) => d.creditor!.trim());
    const ccBanks = cardData.map((c) => c.bankLimit.institution || c.bankLimit.bank);
    const names = Array.from(new Set([...ccBanks, ...manualCreditors])).sort((a, b) =>
      a.localeCompare(b, i18n.language)
    );
    return names;
  }, [debts, cardData]);

  const debtTypeOptions = useMemo(() => {
    const cats = Array.from(
      new Set(debts.filter((d) => !d.bankLimitId).map((d) => d.category || "Diğer"))
    ).sort((a, b) => a.localeCompare(b, i18n.language));
    const ccTypes: string[] = [];
    if (cardData.some((c) => c.bankLimit.type === "credit")) ccTypes.push(CC_TYPE_LABELS.credit);
    if (cardData.some((c) => c.bankLimit.type !== "credit")) ccTypes.push(CC_TYPE_LABELS.demand);
    return [...ccTypes, ...cats];
  }, [debts, cardData]);

  const visibleDebts = useMemo(() => {
    // CC veya OD tipi seçiliyse manuel borçlar tamamen gizlenir
    if (debtTypeFilter === CC_TYPE_LABELS.credit || debtTypeFilter === CC_TYPE_LABELS.demand) return [];

    let arr = debts.filter((d) => !d.bankLimitId);

    // Alacaklı filter
    if (creditorFilter) arr = arr.filter((d) => d.creditor?.trim() === creditorFilter);
    // Borç tipi filter
    if (debtTypeFilter) arr = arr.filter((d) => (d.category || "Diğer") === debtTypeFilter);

    arr.sort((a, b) => {
      if (sortKey === "date") {
        const tA = a.dueDate ? new Date(a.dueDate).getTime() : Infinity;
        const tB = b.dueDate ? new Date(b.dueDate).getTime() : Infinity;
        return tA - tB;
      }
      let cmp = 0;
      if (sortKey === "amount") {
        cmp = (b.amount - b.paidAmount) - (a.amount - a.paidAmount);
      } else {
        cmp = (a.name ?? "").localeCompare(b.name ?? "", i18n.language, { sensitivity: "base" });
      }
      return sortDir === "desc" ? -cmp : cmp;
    });
    return arr;
  }, [debts, sortKey, sortDir, creditorFilter, debtTypeFilter]);

  const openAdd = () => {
    Haptics.selectionAsync();
    setEditId(null);
    setModalVisible(true);
  };

  const openEdit = (d: Debt) => {
    Haptics.selectionAsync();
    setEditId(d.id);
    setModalVisible(true);
  };


  const handleDelete = (id: string, name: string) => {
    Alert.alert(t("debts.deleteDebt"), t("debts.deleteDebtConfirm", { name }), [
      { text: t("debts.cancel"), style: "cancel" },
      {
        text: t("debts.delete"),
        style: "destructive",
        onPress: () => {
          Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning);
          deleteDebt(id);
        },
      },
    ]);
  };

  const openPayment = (d: Debt) => {
    Haptics.selectionAsync();
    setPaymentDebt(d);
    let suggested = "";
    if (d.isInstallment && d.totalInstallments && d.totalInstallments > 0) {
      const perInst = d.amount / d.totalInstallments;
      suggested = perInst.toFixed(2).replace(".", ",");
    } else {
      suggested = String(Math.max(0, d.amount - d.paidAmount)).replace(".", ",");
    }
    setPaymentAmount(suggested);
    setPaymentDate(new Date());
  };

  const handleSavePayment = () => {
    if (!paymentDebt) return;
    const amt = parseFloat(paymentAmount.replace(",", "."));
    if (isNaN(amt) || amt <= 0) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
      return;
    }
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    addPayment(paymentDebt.id, amt, paymentDate.toISOString());
    setPaymentDebt(null);
    setPaymentAmount("");
  };

  const styles = StyleSheet.create({
    container: { flex: 1, backgroundColor: colors.background },
    header: {
      backgroundColor: colors.navy,
      paddingTop: topInset + 16,
      paddingBottom: 18,
      paddingHorizontal: 24,
      flexDirection: "row",
      alignItems: "flex-start",
      gap: 12,
    },
    headerLabel: { fontSize: 13, color: "rgba(255,255,255,0.6)", marginBottom: 6 },
    headerAmount: { fontSize: 36, fontWeight: "800" as const, color: "#FFFFFF" },
    headerSub: {
      fontSize: 13,
      color: "rgba(255,255,255,0.6)",
      marginTop: 4,
    },
    addBtnHeader: {
      alignItems: "center",
      gap: 6,
      marginTop: 4,
    },
    addBtnHeaderInner: {
      width: 48,
      height: 48,
      borderRadius: 16,
      backgroundColor: colors.primary,
      alignItems: "center",
      justifyContent: "center",
      shadowColor: colors.primary,
      shadowOffset: { width: 0, height: 4 },
      shadowOpacity: 0.45,
      shadowRadius: 8,
      elevation: 6,
    },
    addBtnHeaderText: {
      fontSize: 10,
      fontWeight: "700" as const,
      color: "rgba(255,255,255,0.75)",
      letterSpacing: 0.4,
    },
    filterBar: {
      flexDirection: "row",
      gap: 8,
      marginHorizontal: 16,
      marginTop: 12,
      marginBottom: 4,
    },
    filterSquare: {
      flex: 1,
      alignItems: "center",
      justifyContent: "center",
      gap: 5,
      paddingVertical: 10,
      paddingHorizontal: 4,
      borderRadius: 12,
      backgroundColor: colors.card,
      borderWidth: 1,
      borderColor: colors.border,
      minHeight: 60,
    },
    filterSquareActive: {
      backgroundColor: colors.primary,
      borderColor: colors.primary,
    },
    filterSquareLabel: {
      fontSize: 10,
      fontWeight: "600" as const,
      color: colors.foreground,
      textAlign: "center" as const,
    },
    filterSquareLabelActive: {
      color: "#0B1E33",
    },
    filterDropdown: {
      marginHorizontal: 16,
      marginTop: 4,
      marginBottom: 4,
      backgroundColor: colors.card,
      borderRadius: 12,
      borderWidth: 1,
      borderColor: colors.border,
      overflow: "hidden",
    },
    filterDropdownRow: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      paddingHorizontal: 16,
      paddingVertical: 12,
      borderBottomWidth: 1,
      borderBottomColor: colors.border,
    },
    filterDropdownRowActive: {
      backgroundColor: colors.primary + "14",
    },
    filterDropdownText: {
      fontSize: 14,
      color: colors.foreground,
    },
    viewModeTabs: {
      flexDirection: "row",
      gap: 6,
      marginHorizontal: 16,
      marginTop: 16,
      marginBottom: 4,
      backgroundColor: colors.muted,
      borderRadius: 14,
      padding: 5,
      borderWidth: 1,
      borderColor: colors.border,
    },
    viewModeTab: {
      flex: 1,
      borderRadius: 10,
      overflow: "hidden",
    },
    viewModeTabGrad: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "center",
      gap: 6,
      paddingVertical: 11,
      paddingHorizontal: 8,
    },
    viewModeTabInner: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "center",
      gap: 6,
      paddingVertical: 11,
      paddingHorizontal: 8,
    },
    viewModeTabText: {
      fontSize: 12,
      fontWeight: "600" as const,
      color: colors.mutedForeground,
    },
    viewModeTabTextActive: {
      fontSize: 12,
      color: "#FFFFFF",
      fontWeight: "700" as const,
    },
    autoSection: {
      marginHorizontal: 20,
      marginTop: 16,
      backgroundColor: colors.card,
      borderRadius: colors.radius,
      padding: 14,
      borderWidth: 1,
      borderColor: colors.border,
    },
    autoSectionHeader: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      marginBottom: 4,
    },
    autoSectionTitle: {
      fontSize: 14,
      fontWeight: "700" as const,
      color: colors.foreground,
    },
    autoSectionHint: {
      fontSize: 11,
      color: colors.mutedForeground,
      marginBottom: 10,
    },
    autoCard: {
      flexDirection: "row",
      alignItems: "center",
      gap: 10,
      backgroundColor: colors.background,
      borderRadius: 10,
      paddingVertical: 10,
      paddingHorizontal: 12,
      marginTop: 8,
      borderWidth: 1,
      borderColor: colors.border,
    },
    autoIconBg: {
      width: 36,
      height: 36,
      borderRadius: 18,
      backgroundColor: colors.primary + "20",
      alignItems: "center",
      justifyContent: "center",
    },
    autoCardTitle: {
      fontSize: 14,
      fontWeight: "700" as const,
      color: colors.foreground,
    },
    autoCardSub: {
      fontSize: 11,
      color: colors.mutedForeground,
      marginTop: 2,
    },
    autoCardAmount: {
      fontSize: 15,
      fontWeight: "800" as const,
      color: colors.expense,
    },
    autoCardLimit: {
      fontSize: 11,
      color: colors.mutedForeground,
      marginTop: 2,
    },
    autoCardWrapper: {
      backgroundColor: colors.background,
      borderRadius: 10,
      marginTop: 8,
      borderWidth: 1,
      borderColor: colors.border,
      overflow: "hidden",
    },
    autoCardHead: {
      flexDirection: "row",
      alignItems: "center",
      gap: 10,
      paddingVertical: 10,
      paddingHorizontal: 12,
    },
    autoExpand: {
      paddingHorizontal: 12,
      paddingTop: 4,
      paddingBottom: 12,
      borderTopWidth: 1,
      borderTopColor: colors.border,
    },
    autoBdHeader: {
      flexDirection: "row",
      justifyContent: "space-between",
      alignItems: "center",
      marginTop: 8,
      marginBottom: 6,
    },
    autoBdTitle: {
      fontSize: 12,
      fontWeight: "700" as const,
      color: colors.foreground,
    },
    autoBdAddBtn: {
      flexDirection: "row",
      alignItems: "center",
      gap: 4,
      paddingHorizontal: 8,
      paddingVertical: 4,
      borderRadius: 6,
      backgroundColor: colors.primary + "18",
    },
    autoBdAddBtnText: {
      fontSize: 11,
      fontWeight: "700" as const,
      color: colors.primary,
    },
    autoBdEmpty: {
      fontSize: 11,
      color: colors.mutedForeground,
      fontStyle: "italic" as const,
      textAlign: "center" as const,
      paddingVertical: 6,
    },
    autoBdRow: {
      flexDirection: "row",
      alignItems: "center",
      gap: 8,
      paddingVertical: 8,
      borderBottomWidth: 1,
      borderBottomColor: colors.border,
    },
    autoBdMonth: {
      fontSize: 12,
      fontWeight: "600" as const,
      color: colors.foreground,
      flex: 1,
    },
    autoBdAmt: {
      fontSize: 12,
      fontWeight: "700" as const,
      color: colors.expense,
    },
    autoBdAmtPaid: {
      color: colors.income,
      textDecorationLine: "line-through" as const,
    },
    autoBdBadge: {
      flexDirection: "row",
      alignItems: "center",
      gap: 3,
      paddingHorizontal: 6,
      paddingVertical: 3,
      borderRadius: 6,
    },
    autoBdBadgeText: {
      fontSize: 10,
      fontWeight: "700" as const,
    },
    autoBdIconBtn: {
      width: 22,
      height: 22,
      borderRadius: 6,
      backgroundColor: colors.card,
      alignItems: "center" as const,
      justifyContent: "center" as const,
    },
    autoBdTotalRow: {
      flexDirection: "row",
      justifyContent: "space-between",
      alignItems: "center",
      marginTop: 8,
      paddingTop: 6,
      borderTopWidth: 1,
      borderTopColor: colors.border,
    },
    autoBdGoLink: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "center",
      gap: 4,
      paddingTop: 10,
    },
    autoBdGoLinkText: {
      fontSize: 11,
      fontWeight: "600" as const,
      color: colors.primary,
    },
    cardQuickEditBtn: {
      paddingHorizontal: 12,
      paddingVertical: 10,
      alignItems: "center",
      justifyContent: "center",
    },
    actionRow: {
      flexDirection: "row",
      gap: 10,
      marginHorizontal: 20,
      marginTop: 14,
    },
    addBtn: {
      alignSelf: "flex-start",
      flexDirection: "row",
      alignItems: "center",
      gap: 6,
      backgroundColor: colors.primary + "14",
      borderWidth: 1,
      borderColor: colors.primary + "55",
      paddingVertical: 8,
      paddingHorizontal: 14,
      borderRadius: 999,
    },
    addBtnText: {
      color: colors.primary,
      fontSize: 13,
      fontWeight: "600" as const,
      letterSpacing: 0.2,
    },
    filterBtn: {
      width: 48,
      alignItems: "center",
      justifyContent: "center",
      backgroundColor: colors.card,
      borderRadius: colors.radius,
      borderWidth: 1,
      borderColor: colors.border,
    },
    chipsRow: {
      flexDirection: "row",
      gap: 8,
      paddingHorizontal: 20,
      marginTop: 14,
    },
    chip: {
      paddingHorizontal: 12,
      paddingVertical: 6,
      borderRadius: 999,
      backgroundColor: colors.muted,
    },
    chipActive: { backgroundColor: colors.primary },
    chipText: {
      fontSize: 12,
      fontWeight: "600" as const,
      color: colors.mutedForeground,
    },
    chipTextActive: { color: "#FFFFFF" },
    cardFilterSegment: {
      flexDirection: "row" as const,
      backgroundColor: colors.muted,
      borderRadius: 12,
      padding: 3,
      marginTop: 12,
    },
    cardFilterSegmentItem: {
      flex: 1,
      flexDirection: "row" as const,
      alignItems: "center" as const,
      justifyContent: "center" as const,
      gap: 5,
      paddingVertical: 9,
      paddingHorizontal: 6,
      borderRadius: 9,
    },
    cardFilterSegmentItemActive: {
      backgroundColor: colors.primary,
    },
    cardFilterSegmentText: {
      fontSize: 12,
      fontWeight: "600" as const,
      color: colors.mutedForeground,
    },
    cardFilterSegmentTextActive: {
      color: "#FFFFFF",
      fontWeight: "700" as const,
    },
    section: { paddingHorizontal: 20, marginTop: 18 },
    debtCard: {
      backgroundColor: colors.card,
      borderRadius: colors.radius,
      padding: 14,
      paddingLeft: 18,
      marginBottom: 10,
      overflow: "hidden",
    },
    debtTopRow: { flexDirection: "row", alignItems: "center", gap: 12 },
    iconBg: {
      width: 40,
      height: 40,
      borderRadius: 12,
      backgroundColor: colors.expenseBg,
      alignItems: "center",
      justifyContent: "center",
    },
    debtBody: { flex: 1 },
    debtName: {
      fontSize: 15,
      fontWeight: "700" as const,
      color: colors.foreground,
    },
    debtMeta: {
      fontSize: 12,
      color: colors.mutedForeground,
      marginTop: 2,
    },
    amountCol: { alignItems: "flex-end" as const },
    amountRemaining: {
      fontSize: 15,
      fontWeight: "700" as const,
      color: colors.expense,
    },
    amountTotal: {
      fontSize: 11,
      color: colors.mutedForeground,
      marginTop: 2,
    },
    progressTrack: {
      height: 6,
      borderRadius: 3,
      backgroundColor: colors.muted,
      marginTop: 12,
      overflow: "hidden" as const,
    },
    progressFill: {
      height: 6,
      borderRadius: 3,
      backgroundColor: colors.primary,
    },
    badgeRow: {
      flexDirection: "row",
      gap: 6,
      marginTop: 10,
      flexWrap: "wrap" as const,
    },
    badge: {
      flexDirection: "row",
      alignItems: "center",
      gap: 4,
      paddingHorizontal: 8,
      paddingVertical: 4,
      borderRadius: 6,
      backgroundColor: colors.muted,
    },
    badgeText: {
      fontSize: 11,
      fontWeight: "600" as const,
      color: colors.foreground,
    },
    expandedActions: {
      flexDirection: "row",
      gap: 8,
      marginTop: 12,
      borderTopWidth: 1,
      borderTopColor: colors.border,
      paddingTop: 12,
    },
    actionBtn: {
      flex: 1,
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "center",
      gap: 6,
      paddingVertical: 10,
      borderRadius: 10,
      backgroundColor: colors.muted,
    },
    actionBtnPrimary: { backgroundColor: colors.primary },
    actionBtnDanger: { backgroundColor: colors.expenseBg },
    actionBtnText: {
      fontSize: 13,
      fontWeight: "600" as const,
      color: colors.foreground,
    },
    actionBtnTextPrimary: { color: "#FFFFFF" },
    actionBtnTextDanger: { color: colors.expense },
    paymentList: {
      marginTop: 10,
      borderTopWidth: 1,
      borderTopColor: colors.border,
      paddingTop: 8,
    },
    paymentRow: {
      flexDirection: "row",
      justifyContent: "space-between",
      paddingVertical: 4,
    },
    paymentText: { fontSize: 12, color: colors.mutedForeground },
    paymentAmt: {
      fontSize: 12,
      fontWeight: "600" as const,
      color: colors.income,
    },
    empty: { alignItems: "center", paddingVertical: 40 },
    emptyText: {
      fontSize: 15,
      color: colors.mutedForeground,
      marginTop: 12,
    },
    emptySub: {
      fontSize: 13,
      color: colors.mutedForeground,
      opacity: 0.7,
      marginTop: 4,
      textAlign: "center" as const,
      paddingHorizontal: 32,
    },
    modalBackdrop: {
      flex: 1,
      backgroundColor: "rgba(0,0,0,0.5)",
      justifyContent: "flex-end",
    },
    modalContent: {
      backgroundColor: colors.card,
      borderTopLeftRadius: 24,
      borderTopRightRadius: 24,
      padding: 20,
      paddingBottom: bottomInset + 20,
      maxHeight: "92%" as const,
    },
    modalTitle: {
      fontSize: 18,
      fontWeight: "700" as const,
      color: colors.foreground,
      marginBottom: 8,
    },
    label: {
      fontSize: 13,
      fontWeight: "600" as const,
      color: colors.foreground,
      marginBottom: 8,
      marginTop: 14,
    },
    input: {
      backgroundColor: colors.muted,
      borderRadius: 12,
      paddingHorizontal: 14,
      paddingVertical: 12,
      fontSize: 15,
      color: colors.foreground,
    },
    selector: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      backgroundColor: colors.muted,
      borderRadius: 12,
      paddingHorizontal: 14,
      paddingVertical: 12,
    },
    selectorText: { fontSize: 15, color: colors.foreground },
    catGrid: {
      flexDirection: "row",
      flexWrap: "wrap" as const,
      gap: 8,
    },
    catChip: {
      flexDirection: "row",
      alignItems: "center",
      gap: 6,
      paddingHorizontal: 12,
      paddingVertical: 8,
      borderRadius: 999,
      backgroundColor: colors.muted,
    },
    catChipActive: { backgroundColor: colors.primary },
    catChipText: {
      fontSize: 13,
      fontWeight: "600" as const,
      color: colors.foreground,
    },
    catChipTextActive: { color: "#FFFFFF" },
    switchRow: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      marginTop: 14,
      backgroundColor: colors.muted,
      paddingHorizontal: 14,
      paddingVertical: 10,
      borderRadius: 12,
    },
    switchLabel: {
      fontSize: 14,
      fontWeight: "600" as const,
      color: colors.foreground,
    },
    saveBtn: {
      backgroundColor: colors.primary,
      paddingVertical: 14,
      borderRadius: colors.radius,
      alignItems: "center",
      marginTop: 22,
    },
    saveBtnDisabled: { opacity: 0.4 },
    cancelBtn: {
      flex: 1,
      backgroundColor: colors.muted,
      borderRadius: colors.radius,
      paddingVertical: 14,
      alignItems: "center",
      borderWidth: 1,
      borderColor: colors.border,
    },
    cancelBtnText: {
      color: colors.foreground,
      fontWeight: "700" as const,
      fontSize: 15,
    },
    saveBtnText: {
      color: "#FFFFFF",
      fontSize: 15,
      fontWeight: "700" as const,
    },
    bankList: {
      marginTop: 6,
      backgroundColor: colors.muted,
      borderRadius: 12,
      overflow: "hidden" as const,
      maxHeight: 260,
    },
    bankRow: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      paddingHorizontal: 14,
      paddingVertical: 12,
      borderBottomWidth: 1,
      borderBottomColor: colors.border,
    },
    bankItemText: { fontSize: 14, color: colors.foreground },
    cardBankPickerList: {
      marginTop: 6,
      marginBottom: 6,
      backgroundColor: colors.muted,
      borderRadius: 12,
      overflow: "hidden" as const,
    },
    cardBankPickerRow: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      paddingHorizontal: 14,
      paddingVertical: 11,
      borderBottomWidth: 1,
      borderBottomColor: colors.border,
    },
    cardBankPickerRowActive: {
      backgroundColor: colors.accent,
    },
    cardBankPickerText: {
      fontSize: 13,
      color: colors.foreground,
    },
    inlineCalendar: {
      marginTop: 8,
      backgroundColor: colors.muted,
      borderRadius: 16,
      padding: 8,
    },
    subLabel: {
      fontSize: 12,
      fontWeight: "600" as const,
      color: colors.mutedForeground,
      marginBottom: 6,
      marginTop: 6,
      marginLeft: 2,
    },
    calcBox: {
      marginTop: 10,
      backgroundColor: colors.muted,
      borderRadius: 12,
      paddingHorizontal: 14,
      paddingVertical: 6,
    },
    calcRow: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      paddingVertical: 10,
    },
    calcLabel: {
      fontSize: 13,
      color: colors.mutedForeground,
      flex: 1,
    },
    calcValue: {
      fontSize: 14,
      fontWeight: "700" as const,
      color: colors.foreground,
    },
    calcDivider: {
      height: 1,
      backgroundColor: colors.border,
    },
    sortFilterCard: {
      backgroundColor: colors.card,
      padding: 20,
      borderRadius: 24,
      marginHorizontal: 20,
      width: "90%" as const,
      alignSelf: "center" as const,
    },
    scrollTopBtn: {
      position: "absolute" as const,
      right: 20,
      width: 44,
      height: 44,
      borderRadius: 22,
      backgroundColor: colors.primary,
      alignItems: "center" as const,
      justifyContent: "center" as const,
      shadowColor: "#000",
      shadowOffset: { width: 0, height: 4 },
      shadowOpacity: 0.25,
      shadowRadius: 8,
      elevation: 6,
    },
    centeredBackdrop: {
      flex: 1,
      backgroundColor: "rgba(0,0,0,0.5)",
      justifyContent: "center",
    },
    groupHeader: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      paddingHorizontal: 14,
      paddingVertical: 10,
      backgroundColor: colors.muted,
      borderRadius: 10,
      marginBottom: 8,
    },
    debtGroupHeader: {
      flexDirection: "row" as const,
      alignItems: "center" as const,
      gap: 6,
      paddingHorizontal: 4,
      paddingVertical: 6,
      marginBottom: 6,
      borderBottomWidth: 1,
      borderBottomColor: colors.border,
    },
    debtGroupHeaderTitle: {
      flex: 1,
      fontSize: 12,
      fontWeight: "700" as const,
      color: colors.foreground,
      textTransform: "uppercase" as const,
      letterSpacing: 0.6,
    },
    debtGroupHeaderCount: {
      fontSize: 11,
      fontWeight: "600" as const,
      color: colors.mutedForeground,
    },
    groupHeaderTitle: {
      fontSize: 14,
      fontWeight: "700",
      color: colors.foreground,
    },
    groupHeaderAmount: {
      fontSize: 14,
      fontWeight: "700",
      color: colors.expense,
    },
    groupHeaderSub: {
      fontSize: 10,
      color: colors.mutedForeground,
      marginTop: 1,
    },
    groupCountPill: {
      backgroundColor: colors.background,
      borderRadius: 10,
      paddingHorizontal: 7,
      paddingVertical: 2,
      minWidth: 22,
      alignItems: "center",
    },
    groupCountText: {
      fontSize: 11,
      fontWeight: "600",
      color: colors.foreground,
    },
    // ── Breakdown styles ─────────────────────────────────────────────────────
    breakdownSection: {
      backgroundColor: colors.muted,
      borderRadius: 12,
      padding: 12,
      marginTop: 10,
      marginBottom: 2,
    },
    breakdownHeader: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      marginBottom: 8,
    },
    breakdownTitle: {
      fontSize: 11,
      fontWeight: "800",
      color: colors.mutedForeground,
      letterSpacing: 0.4,
    },
    breakdownAddBtn: {
      flexDirection: "row",
      alignItems: "center",
      gap: 4,
      backgroundColor: colors.primary + "22",
      borderRadius: 8,
      paddingHorizontal: 8,
      paddingVertical: 4,
    },
    breakdownAddBtnText: {
      fontSize: 11,
      fontWeight: "700",
      color: colors.primary,
    },
    breakdownEmpty: {
      fontSize: 12,
      color: colors.mutedForeground,
      fontStyle: "italic",
      textAlign: "center",
      paddingVertical: 8,
    },
    breakdownRow: {
      flexDirection: "row",
      alignItems: "center",
      gap: 6,
      paddingVertical: 6,
      borderBottomWidth: 1,
      borderBottomColor: colors.border,
    },
    breakdownRowLeft: {
      flex: 1,
      flexDirection: "row",
      alignItems: "center",
      gap: 5,
    },
    breakdownMonth: {
      fontSize: 13,
      fontWeight: "600",
      color: colors.foreground,
    },
    breakdownAmt: {
      fontSize: 13,
      fontWeight: "700",
      color: colors.expense,
    },
    breakdownIconBtn: {
      width: 26,
      height: 26,
      borderRadius: 8,
      backgroundColor: colors.background,
      alignItems: "center",
      justifyContent: "center",
    },
    breakdownTotalRow: {
      flexDirection: "row",
      justifyContent: "space-between",
      alignItems: "center",
      marginTop: 8,
      paddingTop: 8,
    },
    breakdownTotalLabel: {
      fontSize: 12,
      fontWeight: "700",
      color: colors.foreground,
    },
    breakdownTotalAmt: {
      fontSize: 14,
      fontWeight: "800",
      color: colors.expense,
    },
    // ── Breakdown Modal styles ────────────────────────────────────────────────
    bdBackdrop: {
      flex: 1,
      backgroundColor: "rgba(0,0,0,0.45)",
      justifyContent: "center",
      padding: 24,
    },
    bdCard: {
      backgroundColor: colors.background,
      borderRadius: 20,
      padding: 22,
    },
    bdTitle: {
      fontSize: 17,
      fontWeight: "800",
      color: colors.foreground,
      marginBottom: 18,
    },
    bdLabel: {
      fontSize: 13,
      fontWeight: "600",
      color: colors.foreground,
      marginBottom: 8,
      marginTop: 14,
    },
    bdMonthNav: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      backgroundColor: colors.muted,
      borderRadius: 12,
      paddingVertical: 10,
      paddingHorizontal: 8,
    },
    bdNavBtn: { padding: 4 },
    bdMonthLabel: {
      fontSize: 15,
      fontWeight: "700",
      color: colors.foreground,
    },
    bdInput: {
      backgroundColor: colors.muted,
      borderRadius: 12,
      paddingVertical: 12,
      paddingHorizontal: 14,
      color: colors.foreground,
      fontSize: 16,
    },
    bdActions: {
      flexDirection: "row",
      gap: 10,
      marginTop: 22,
    },
    bdCancel: {
      flex: 1,
      backgroundColor: colors.muted,
      borderRadius: 14,
      paddingVertical: 13,
      alignItems: "center",
    },
    bdCancelText: { color: colors.foreground, fontWeight: "600", fontSize: 14 },
    bdSave: {
      flex: 1,
      backgroundColor: colors.primary,
      borderRadius: 14,
      paddingVertical: 13,
      alignItems: "center",
    },
    bdSaveText: { color: "#FFFFFF", fontWeight: "700", fontSize: 14 },
  });

  const renderDueBadge = (d: Debt) => {
    const days = daysUntil(d.dueDate);
    const remaining = d.amount - d.paidAmount;
    if (!d.dueDate || remaining <= 0 || days === null) return null;
    let bg = colors.muted;
    let fg = colors.foreground;
    let label = t("debts.dueBadge", { date: new Date(d.dueDate).toLocaleDateString(i18n.language, {
      day: "2-digit",
      month: "short",
    }) });
    if (days < 0) {
      bg = "#FFE0E6";
      fg = colors.expense;
      label = t("debts.overdueDays", { days: Math.abs(days) });
    } else if (days === 0) {
      bg = "#FFE9D6";
      fg = "#D97706";
      label = t("debts.dueTodayBadge");
    } else if (days <= 7) {
      bg = "#FFF4D6";
      fg = "#B45309";
      label = t("debts.dueDaysLeft", { days });
    }
    return (
      <View style={[styles.badge, { backgroundColor: bg }]}>
        <Feather name="clock" size={11} color={fg} />
        <Text style={[styles.badgeText, { color: fg }]}>{label}</Text>
      </View>
    );
  };

  // ── Breakdown helpers ────────────────────────────────────────────────────
  const fmtYM = (ym: string) => {
    const [y, m] = ym.split("-").map(Number);
    return new Date(y, m - 1, 1).toLocaleDateString(i18n.language, { month: "long", year: "numeric" });
  };

  const shiftYM = (ym: string, delta: number) => {
    const [y, m] = ym.split("-").map(Number);
    const d = new Date(y, m - 1 + delta, 1);
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
  };

  const openBreakdownAdd = (debtId: string) => {
    setBreakdownDebtId(debtId);
    setBreakdownBankLimit(null);
    setBreakdownEditIdx(null);
    setBreakdownOriginalYM(null);
    setBreakdownYM(`${new Date().getFullYear()}-${String(new Date().getMonth() + 1).padStart(2, "0")}`);
    setBreakdownAmount("");
    setBreakdownModal(true);
    Haptics.selectionAsync();
  };

  const openBreakdownEdit = (debtId: string, idx: number, b: MonthlyBreakdown) => {
    setBreakdownDebtId(debtId);
    setBreakdownBankLimit(null);
    setBreakdownEditIdx(idx);
    setBreakdownOriginalYM(b.yearMonth);
    setBreakdownYM(b.yearMonth);
    setBreakdownAmount(String(b.amount));
    setBreakdownModal(true);
    Haptics.selectionAsync();
  };

  const openManualStatementEditor = (
    b: BankLimit,
    ym: string,
    currentAmount?: number
  ) => {
    setBreakdownBankLimit(b);
    setBreakdownDebtId(null);
    setBreakdownEditIdx(currentAmount !== undefined ? 0 : null);
    setBreakdownOriginalYM(ym);
    setBreakdownYM(ym);
    setBreakdownAmount(currentAmount !== undefined ? String(currentAmount) : "");
    setBreakdownModal(true);
  };

  // "Ekstre Ekle" — open the modal in add-new mode for a bank limit.
  // Defaults to the active (uncut) statement period for that card so the
  // most common case (entering this month's bank-issued total) is one tap away.
  const openManualStatementAdd = (b: BankLimit) => {
    const sc = findSavedCardForBankLimit(b, savedCards);
    const now = new Date();
    const defaultYm = sc?.statementDay
      ? getActiveStatementYearMonth(sc.statementDay, now)
      : `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}`;
    setBreakdownBankLimit(b);
    setBreakdownDebtId(null);
    setBreakdownEditIdx(null);
    setBreakdownOriginalYM(null);
    setBreakdownYM(defaultYm);
    setBreakdownAmount("");
    setBreakdownModal(true);
    Haptics.selectionAsync();
  };

  // ── Overdraft quick-edit ─────────────────────────────────────────────────

  const openOdEdit = (b: BankLimit) => {
    const available = b.availableLimit ?? 0;
    const debt = Math.max(0, (b.limit ?? 0) - available);
    setOdEditBl(b);
    setOdEditAmt(available > 0 ? String(Math.round(available)) : "");
    setOdEditDebt(debt > 0 ? String(Math.round(debt)) : "");
    Haptics.selectionAsync();
  };

  // Kalan limit değişince borç alanını güncelle
  const onChangeKalanLimit = (val: string) => {
    setOdEditAmt(val);
    if (odEditBl) {
      const kalan = parseFloat(val.replace(",", ".").replace(/\s/g, ""));
      if (isFinite(kalan) && kalan >= 0) {
        const debt = Math.max(0, odEditBl.limit - kalan);
        setOdEditDebt(String(Math.round(debt)));
      }
    }
  };

  // Borç miktarı değişince kalan limit alanını güncelle
  const onChangeBorc = (val: string) => {
    setOdEditDebt(val);
    if (odEditBl) {
      const borc = parseFloat(val.replace(",", ".").replace(/\s/g, ""));
      if (isFinite(borc) && borc >= 0) {
        const kalan = Math.max(0, odEditBl.limit - borc);
        setOdEditAmt(String(Math.round(kalan)));
      }
    }
  };

  const saveOdEdit = () => {
    if (!odEditBl) return;
    const amt = parseFloat(odEditAmt.replace(",", ".").replace(/\s/g, ""));
    if (!isFinite(amt) || amt < 0) {
      const msg = t("debts.errorInvalidAmount");
      Platform.OS === "web" ? window.alert(msg) : Alert.alert(t("debts.errorTitle"), msg);
      return;
    }
    updateBankLimit(odEditBl.id, {
      availableLimit: Math.min(Math.max(0, amt), odEditBl.limit),
    });
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    setOdEditBl(null);
    setOdEditAmt("");
    setOdEditDebt("");
  };

  // ── End overdraft quick-edit ─────────────────────────────────────────────

  const closeBreakdownModal = () => {
    setBreakdownModal(false);
    setBreakdownDebtId(null);
    setBreakdownBankLimit(null);
    setBreakdownEditIdx(null);
    setBreakdownOriginalYM(null);
    setBreakdownAmount("");
  };

  const saveBreakdown = () => {
    const amt = parseFloat(breakdownAmount.replace(",", "."));
    if (!isFinite(amt) || amt <= 0) {
      const msg = t("debts.errorInvalidAmount");
      Platform.OS === "web" ? window.alert(msg) : Alert.alert(t("debts.errorMissingTitle"), msg);
      return;
    }

    // Bank-limit (CC) statement: write manual amount via new API
    if (breakdownBankLimit) {
      const bl = breakdownBankLimit;
      // If user moved the YM during edit, clear the old one first
      if (
        breakdownEditIdx !== null &&
        breakdownOriginalYM &&
        breakdownOriginalYM !== breakdownYM
      ) {
        setManualStatementAmount(bl.id, breakdownOriginalYM, null);
      }
      setManualStatementAmount(bl.id, breakdownYM, amt);
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      closeBreakdownModal();
      return;
    }

    if (!breakdownDebtId) return;
    const debt = debts.find((d) => d.id === breakdownDebtId);
    if (!debt) return;
    const existing = debt.monthlyBreakdowns ?? [];
    let updated: MonthlyBreakdown[];
    if (breakdownEditIdx !== null) {
      updated = existing.map((b, i) =>
        i === breakdownEditIdx ? { yearMonth: breakdownYM, amount: amt } : b
      );
    } else {
      // prevent duplicate month
      const dupIdx = existing.findIndex((b) => b.yearMonth === breakdownYM);
      if (dupIdx >= 0) {
        updated = existing.map((b, i) =>
          i === dupIdx ? { yearMonth: breakdownYM, amount: amt } : b
        );
      } else {
        updated = [...existing, { yearMonth: breakdownYM, amount: amt }];
      }
    }
    updated.sort((a, b) => a.yearMonth.localeCompare(b.yearMonth));
    updateDebt(breakdownDebtId, { monthlyBreakdowns: updated });
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    closeBreakdownModal();
  };

  const deleteBreakdown = (debtId: string, idx: number) => {
    const debt = debts.find((d) => d.id === debtId);
    if (!debt) return;
    const existing = debt.monthlyBreakdowns ?? [];
    const updated = existing.filter((_, i) => i !== idx);
    const doDelete = () => {
      updateDebt(debtId, { monthlyBreakdowns: updated });
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    };
    if (Platform.OS === "web") {
      if (window.confirm(t("debts.deleteBreakdownConfirm"))) doDelete();
    } else {
      Alert.alert(t("debts.deleteBreakdownTitle"), t("debts.deleteBreakdownConfirm"), [
        { text: t("debts.cancel"), style: "cancel" },
        { text: t("debts.delete"), style: "destructive", onPress: doDelete },
      ]);
    }
  };
  // ── End breakdown helpers ────────────────────────────────────────────────

  const renderDebtCard = (d: Debt) => {
    const remaining = Math.max(0, d.amount - d.paidAmount);
    const pct =
      d.amount > 0
        ? Math.min(100, Math.round((d.paidAmount / d.amount) * 100))
        : 0;
    const fullyPaid = remaining <= 0;
    const expanded = expandedId === d.id;
    const catColor = getDebtCategoryColor(d.category || "Diğer");
    return (
      <TouchableOpacity
        key={d.id}
        activeOpacity={0.85}
        onPress={() => {
          Haptics.selectionAsync();
          setExpandedId(expanded ? null : d.id);
        }}
        style={styles.debtCard}
      >
        {/* Category color stripe */}
        <View style={{ position: "absolute", left: 0, top: 0, bottom: 0, width: 4, backgroundColor: catColor }} />
        <View style={styles.debtTopRow}>
          <PlatformAvatar name={d.name} size={42} borderRadius={12} />
          <View style={styles.debtBody}>
            <Text style={styles.debtName}>{d.name}</Text>
            <Text style={styles.debtMeta}>
              {d.category}
              {d.creditor ? ` • ${d.creditor}` : ""}
            </Text>
          </View>
          <View style={styles.amountCol}>
            <Text
              style={[
                styles.amountRemaining,
                { color: fullyPaid ? colors.income : catColor },
              ]}
            >
              {fullyPaid ? t("debts.fullyPaid") : formatAmount(remaining)}
            </Text>
            <Text style={styles.amountTotal}>
              / {formatAmount(d.amount)}
            </Text>
          </View>
        </View>

        <View style={styles.progressTrack}>
          <View
            style={[
              styles.progressFill,
              {
                width: `${pct}%`,
                backgroundColor: fullyPaid ? colors.income : catColor,
              },
            ]}
          />
        </View>

        <View style={styles.badgeRow}>
          {d.isInstallment && d.totalInstallments ? (
            <View style={styles.badge}>
              <Feather name="layers" size={11} color={colors.foreground} />
              <Text style={styles.badgeText}>
                {d.paidInstallments ?? 0}/{d.totalInstallments} {t("debts.installments")}
              </Text>
            </View>
          ) : null}
          {renderDueBadge(d)}
          <View style={styles.badge}>
            <Text style={styles.badgeText}>%{pct} {t("debts.paidPercent")}</Text>
          </View>
        </View>

        {expanded && (
          <>
            {d.payments.length > 0 && (
              <View style={styles.paymentList}>
                {d.payments.slice(0, 5).map((p) => (
                  <View key={p.id} style={styles.paymentRow}>
                    <Text style={styles.paymentText}>
                      {new Date(p.date).toLocaleDateString(i18n.language, {
                        day: "2-digit",
                        month: "short",
                        year: "numeric",
                      })}
                    </Text>
                    <Text style={styles.paymentAmt}>
                      +{formatAmount(p.amount)}
                    </Text>
                  </View>
                ))}
              </View>
            )}

            {/* Legacy "Aylık Ekstre Kırılımı" UI removed Apr 2026:
                BankLimit ekstreleri artık tek doğruluk kaynağı. Kullanıcı
                kredi kartı borcunu manuel olarak da girdiyse o sadece düz bir
                borç olarak görünür; ekstre dönemleri Banka Limitleri'nden
                yönetilir. */}

            <View style={styles.expandedActions}>
              <TouchableOpacity
                style={styles.actionBtn}
                onPress={() => openEdit(d)}
              >
                <Feather name="edit-2" size={14} color={colors.foreground} />
                <Text style={styles.actionBtnText}>{t("debts.edit")}</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.actionBtn, styles.actionBtnDanger]}
                onPress={() => handleDelete(d.id, d.name)}
              >
                <Feather name="trash-2" size={14} color={colors.expense} />
                <Text
                  style={[
                    styles.actionBtnText,
                    styles.actionBtnTextDanger,
                  ]}
                >
                  {t("debts.delete")}
                </Text>
              </TouchableOpacity>
            </View>
          </>
        )}
      </TouchableOpacity>
    );
  };

  return (
    <View style={styles.container}>
      <ScrollView
        ref={scrollRef}
        showsVerticalScrollIndicator={false}
        style={{ flex: 1 }}
        keyboardShouldPersistTaps="handled"
        contentContainerStyle={{ paddingBottom: bottomInset + 100 }}
        onScroll={handleScroll}
        scrollEventThrottle={100}
      >
        {/* ── Header ──────────────────────────────────────────────────── */}
        <View style={styles.header}>
          <View style={{ flex: 1 }}>
            <Text style={styles.headerLabel}>{t("debts.remainingTotalDebt")}</Text>
            <Text style={styles.headerAmount}>
              {formatAmount(grandTotalRemaining)}
            </Text>
            <Text style={styles.headerSub}>
              {t("debts.debtCount", { count: debts.length })}
              {cardData.length > 0 ? t("debts.bankLimitCount", { count: cardData.length }) : ""}
            </Text>
          </View>
          {/* Yeni Borç — sağ üst */}
          <TouchableOpacity
            style={styles.addBtnHeader}
            onPress={openAdd}
            activeOpacity={0.82}
          >
            <View style={styles.addBtnHeaderInner}>
              <Feather name="plus" size={18} color="#0B1E33" />
            </View>
            <Text style={styles.addBtnHeaderText}>{t("debts.newDebt")}</Text>
          </TouchableOpacity>
        </View>

        {/* ── Analiz / Borç Dökümü tab switcher ──── */}
        <View style={styles.viewModeTabs}>
          {(
            [
              ["analiz", t("debts.analysis"),   "activity", ["#6366F1", "#3B82F6"] as const, "#6366F1"],
              ["detail", t("debts.debtDetail"), "list",     ["#F59E0B", "#EF4444"] as const, "#F59E0B"],
            ] as ["analiz" | "detail", string, string, readonly [string, string], string][]
          ).map(([key, label, icon, gradColors, accentColor]) => {
            const isActive = viewMode === key;
            return (
              <Pressable
                key={key}
                style={styles.viewModeTab}
                onPress={() => {
                  Haptics.selectionAsync();
                  setViewMode(key);
                  setFilterPickerOpen(null);
                }}
              >
                {isActive ? (
                  <LinearGradient
                    colors={gradColors}
                    start={{ x: 0, y: 0 }}
                    end={{ x: 1, y: 0 }}
                    style={styles.viewModeTabGrad}
                  >
                    <Feather name={icon as any} size={14} color="#FFFFFF" />
                    <Text style={styles.viewModeTabTextActive} numberOfLines={1}>{label}</Text>
                  </LinearGradient>
                ) : (
                  <View style={styles.viewModeTabInner}>
                    <Feather name={icon as any} size={14} color={accentColor} />
                    <Text style={[styles.viewModeTabText, { color: accentColor }]} numberOfLines={1}>{label}</Text>
                  </View>
                )}
              </Pressable>
            );
          })}
        </View>

        {/* ── Filtre & Sıralama Butonu ─── */}
        {(viewMode === "detail" || viewMode === "analiz") && (<><View style={styles.filterBar}>
          {/* Alacaklı */}
          {(() => {
            const active = creditorFilter !== null;
            return (
              <TouchableOpacity
                style={[styles.filterSquare, active && styles.filterSquareActive]}
                onPress={() => {
                  Haptics.selectionAsync();
                  setFilterPickerOpen(filterPickerOpen === "creditor" ? null : "creditor");
                }}
                activeOpacity={0.75}
              >
                <Feather name="user" size={16} color={active ? "#0B1E33" : colors.primary} />
                <Text style={[styles.filterSquareLabel, active && styles.filterSquareLabelActive]} numberOfLines={1}>
                  {creditorFilter ?? t("debts.creditor")}
                </Text>
                {active && (
                  <TouchableOpacity
                    hitSlop={{ top: 6, bottom: 6, left: 6, right: 6 }}
                    onPress={(e) => { e.stopPropagation(); Haptics.selectionAsync(); setCreditorFilter(null); setFilterPickerOpen(null); }}
                  >
                    <Feather name="x" size={11} color="#0B1E33" />
                  </TouchableOpacity>
                )}
              </TouchableOpacity>
            );
          })()}

          {/* Borç Tipi */}
          {(() => {
            const active = debtTypeFilter !== null;
            return (
              <TouchableOpacity
                style={[styles.filterSquare, active && styles.filterSquareActive]}
                onPress={() => {
                  Haptics.selectionAsync();
                  setFilterPickerOpen(filterPickerOpen === "type" ? null : "type");
                }}
                activeOpacity={0.75}
              >
                <Feather name="tag" size={16} color={active ? "#0B1E33" : colors.primary} />
                <Text style={[styles.filterSquareLabel, active && styles.filterSquareLabelActive]} numberOfLines={1}>
                  {debtTypeFilter ?? t("debts.debtTypePlaceholder")}
                </Text>
                {active && (
                  <TouchableOpacity
                    hitSlop={{ top: 6, bottom: 6, left: 6, right: 6 }}
                    onPress={(e) => { e.stopPropagation(); Haptics.selectionAsync(); setDebtTypeFilter(null); setFilterPickerOpen(null); }}
                  >
                    <Feather name="x" size={11} color="#0B1E33" />
                  </TouchableOpacity>
                )}
              </TouchableOpacity>
            );
          })()}

          {/* Sıralama butonları — sadece Borç Dökümü'nde */}
          {viewMode === "detail" && (() => {
            const alphaActive = sortKey === "alpha";
            const isDesc = sortDir === "desc";
            const amtActive = sortKey === "amount" || isDesc;
            const dateActive = sortKey === "date";
            return (
              <>
                {/* Alfabetik */}
                <TouchableOpacity
                  style={[styles.filterSquare, alphaActive && styles.filterSquareActive]}
                  onPress={() => { Haptics.selectionAsync(); setSortKey("alpha"); setFilterPickerOpen(null); }}
                  activeOpacity={0.75}
                >
                  <Feather name="align-left" size={16} color={alphaActive ? "#0B1E33" : colors.primary} />
                  <Text style={[styles.filterSquareLabel, alphaActive && styles.filterSquareLabelActive]}>{t("debts.alphabetical")}</Text>
                </TouchableOpacity>

                {/* Artan / Azalan */}
                <TouchableOpacity
                  style={[styles.filterSquare, amtActive && styles.filterSquareActive]}
                  onPress={() => {
                    Haptics.selectionAsync();
                    if (sortKey !== "amount") { setSortKey("amount"); setSortDir("desc"); }
                    else { setSortDir((d) => (d === "asc" ? "desc" : "asc")); }
                    setFilterPickerOpen(null);
                  }}
                  activeOpacity={0.75}
                >
                  <Feather
                    name={sortKey !== "amount" ? "bar-chart" : sortDir === "asc" ? "trending-up" : "trending-down"}
                    size={16}
                    color={amtActive ? "#0B1E33" : colors.primary}
                  />
                  <Text style={[styles.filterSquareLabel, amtActive && styles.filterSquareLabelActive]}>
                    {sortKey !== "amount" ? t("debts.sortAscDesc") : sortDir === "asc" ? t("debts.sortAsc") : t("debts.sortDesc")}
                  </Text>
                </TouchableOpacity>

                {/* Tarih */}
                <TouchableOpacity
                  style={[styles.filterSquare, dateActive && styles.filterSquareActive]}
                  onPress={() => { Haptics.selectionAsync(); setSortKey("date"); setFilterPickerOpen(null); }}
                  activeOpacity={0.75}
                >
                  <Feather name="calendar" size={16} color={dateActive ? "#0B1E33" : colors.primary} />
                  <Text style={[styles.filterSquareLabel, dateActive && styles.filterSquareLabelActive]}>{t("debts.sortDate")}</Text>
                </TouchableOpacity>
              </>
            );
          })()}
        </View>

        {/* ── Filtre Picker Dropdown ───────────────────────────────── */}
        {filterPickerOpen === "creditor" && (
          <View style={styles.filterDropdown}>
            <TouchableOpacity
              style={[styles.filterDropdownRow, !creditorFilter && styles.filterDropdownRowActive]}
              onPress={() => { setCreditorFilter(null); setFilterPickerOpen(null); Haptics.selectionAsync(); }}
            >
              <Text style={[styles.filterDropdownText, !creditorFilter && { color: colors.primary, fontWeight: "700" }]}>{t("debts.all")}</Text>
              {!creditorFilter && <Feather name="check" size={14} color={colors.primary} />}
            </TouchableOpacity>
            {creditorOptions.length === 0 ? (
              <Text style={[styles.filterDropdownText, { padding: 12, color: colors.mutedForeground }]}>{t("debts.creditorNotFound")}</Text>
            ) : (
              creditorOptions.map((c) => (
                <TouchableOpacity
                  key={c}
                  style={[styles.filterDropdownRow, creditorFilter === c && styles.filterDropdownRowActive]}
                  onPress={() => { setCreditorFilter(c); setFilterPickerOpen(null); Haptics.selectionAsync(); }}
                >
                  <Text style={[styles.filterDropdownText, creditorFilter === c && { color: colors.primary, fontWeight: "700" }]}>{c}</Text>
                  {creditorFilter === c && <Feather name="check" size={14} color={colors.primary} />}
                </TouchableOpacity>
              ))
            )}
          </View>
        )}
        {filterPickerOpen === "type" && (
          <View style={styles.filterDropdown}>
            <TouchableOpacity
              style={[styles.filterDropdownRow, !debtTypeFilter && styles.filterDropdownRowActive]}
              onPress={() => { setDebtTypeFilter(null); setFilterPickerOpen(null); Haptics.selectionAsync(); }}
            >
              <Text style={[styles.filterDropdownText, !debtTypeFilter && { color: colors.primary, fontWeight: "700" }]}>{t("debts.all")}</Text>
              {!debtTypeFilter && <Feather name="check" size={14} color={colors.primary} />}
            </TouchableOpacity>
            {debtTypeOptions.map((opt) => (
              <TouchableOpacity
                key={opt}
                style={[styles.filterDropdownRow, debtTypeFilter === opt && styles.filterDropdownRowActive]}
                onPress={() => { setDebtTypeFilter(opt); setFilterPickerOpen(null); Haptics.selectionAsync(); }}
              >
                <Text style={[styles.filterDropdownText, debtTypeFilter === opt && { color: colors.primary, fontWeight: "700" }]}>{opt}</Text>
                {debtTypeFilter === opt && <Feather name="check" size={14} color={colors.primary} />}
              </TouchableOpacity>
            ))}
          </View>
        )}
        </>)}

        {/* ── Analiz: Borç Özeti + Nakit Akışı ────────────────────────── */}
        {viewMode === "analiz" && (
          <View style={{ marginHorizontal: 16, marginTop: 4, marginBottom: 16, gap: 16 }}>
            {/* Görsel Borç Özeti */}
            <DebtSummaryVisual
              creditorFilter={creditorFilter}
              debtTypeFilter={debtTypeFilter}
            />

            {/* Çizgi ayırıcı */}
            <View style={{ height: 1, backgroundColor: colors.border, marginVertical: 4 }} />

            {/* Aylık Nakit Akışı */}
            <View>
              <View style={{ flexDirection: "row", alignItems: "center", gap: 6, marginBottom: 8 }}>
                <Feather name="trending-up" size={14} color={colors.income ?? "#00C896"} />
                <Text style={{ fontSize: 13, fontWeight: "700", color: colors.foreground }}>{t("debts.cashFlow")}</Text>
              </View>
              <DebtFlowTable
                creditorFilter={creditorFilter}
                debtTypeFilter={debtTypeFilter}
              />
            </View>
          </View>
        )}

        {/* ── Borç Dökümü ─────────────────────────────────────────────── */}
        {viewMode === "detail" && (
          <>

        {sortedCardData.length > 0 && (!debtTypeFilter || CC_FILTER_VALUES.includes(debtTypeFilter as any)) && (
          <View style={styles.autoSection}>
            <View style={styles.autoSectionHeader}>
              <View style={{ flexDirection: "row", alignItems: "center", gap: 6 }}>
                <Feather name="zap" size={14} color="#F59E0B" />
                <Text style={[styles.autoSectionTitle, { color: "#F59E0B" }]}>
                  {debtTypeFilter === CC_TYPE_LABELS.credit
                    ? t("debts.creditCard")
                    : debtTypeFilter === CC_TYPE_LABELS.demand
                    ? t("debts.overdraftAccount")
                    : t("debts.creditCardAndOverdraft")}
                </Text>
              </View>
            </View>
            {sortedCardData.map((c) => {
              const b = c.bankLimit;
              const isCC = b.type === "credit";
              // Per-card type guard — prevents mismatched cards from rendering
              // even if sortedCardData filtering ever misses one
              if (debtTypeFilter === CC_TYPE_LABELS.credit && !isCC) return null;
              if (debtTypeFilter === CC_TYPE_LABELS.demand && isCC) return null;
              const expanded = expandedAutoId === b.id;
              const visibleStatements = c.statements.filter(
                (s) => s.hasData || s.isActive
              );
              return (
                <View key={b.id} style={styles.autoCardWrapper}>
                  {/* ── Card header row: expand (CC) or edit-trigger (OD) ── */}
                  <View style={{ flexDirection: "row", alignItems: "center" }}>
                    <TouchableOpacity
                      activeOpacity={0.7}
                      style={[styles.autoCardHead, { flex: 1 }]}
                      onPress={() => {
                        Haptics.selectionAsync();
                        if (isCC) setExpandedAutoId(expanded ? null : b.id);
                        else openOdEdit(b);
                      }}
                    >
                      <View style={styles.autoIconBg}>
                        <Feather
                          name={isCC ? "credit-card" : "dollar-sign"}
                          size={18}
                          color={colors.primary}
                        />
                      </View>
                      <View style={{ flex: 1 }}>
                        <Text style={styles.autoCardTitle}>
                          {b.institution || b.bank}
                        </Text>
                        <Text style={styles.autoCardSub}>
                          {b.institution ? `${b.bank} • ` : ""}
                          {isCC ? t("debts.creditCard") : t("debts.overdraftAccount")}
                          {visibleStatements.length > 0
                            ? t("debts.statementPeriodCount", { count: visibleStatements.length })
                            : ""}
                        </Text>
                      </View>
                      <View style={{ alignItems: "flex-end" }}>
                        <Text style={styles.autoCardAmount}>
                          {formatAmount(c.totalDebt)}
                        </Text>
                        <Text style={styles.autoCardLimit}>
                          / {formatAmount(b.limit)}
                        </Text>
                      </View>
                    </TouchableOpacity>

                    {/* ── Quick-edit button (kalan limit) ── */}
                    <TouchableOpacity
                      style={styles.cardQuickEditBtn}
                      hitSlop={{ top: 8, bottom: 8, left: 6, right: 10 }}
                      onPress={() => openOdEdit(b)}
                    >
                      <Feather name="edit-2" size={15} color={colors.primary} />
                    </TouchableOpacity>
                  </View>

                  {isCC && expanded && (
                    <View style={styles.autoExpand}>
                      {!c.hasStatementDay && (
                        <Text
                          style={[
                            styles.autoBdEmpty,
                            { color: colors.expense, fontStyle: "normal" },
                          ]}
                        >
                          {t("debts.noStatementDay")}
                        </Text>
                      )}

                      <View style={styles.autoBdHeader}>
                        <Text style={styles.autoBdTitle}>{t("debts.statementPeriods")}</Text>
                        <TouchableOpacity
                          style={styles.autoBdAddBtn}
                          onPress={() => openManualStatementAdd(b)}
                          activeOpacity={0.7}
                        >
                          <Feather name="plus" size={11} color={colors.primary} />
                          <Text style={styles.autoBdAddBtnText}>{t("debts.addStatement")}</Text>
                        </TouchableOpacity>
                      </View>

                      {visibleStatements.length === 0 ? (
                        <Text style={styles.autoBdEmpty}>
                          {t("debts.noStatementPeriods")}
                        </Text>
                      ) : (
                        visibleStatements.map((s) => {
                          const isManual = s.manualAmount !== undefined;
                          const isFullyPaid = s.isFullyPaid;
                          const isActive = s.isActive;
                          const isMissing =
                            !s.hasData && !isActive; // past period with no data
                          return (
                            <View
                              key={s.yearMonth}
                              style={[
                                styles.autoBdRow,
                                isFullyPaid && { opacity: 0.55 },
                              ]}
                            >
                              <Feather
                                name="calendar"
                                size={11}
                                color={
                                  isMissing
                                    ? colors.expense
                                    : colors.mutedForeground
                                }
                              />
                              <View style={{ flex: 1, minWidth: 0 }}>
                                <Text
                                  style={[
                                    styles.autoBdMonth,
                                    isFullyPaid && styles.autoBdAmtPaid,
                                  ]}
                                >
                                  {formatStatementYearMonth(s.yearMonth)}
                                  {isActive ? t("debts.activeStatementLabel") : ""}
                                </Text>
                                <Text
                                  style={{
                                    fontSize: 10,
                                    color: colors.mutedForeground,
                                    marginTop: 1,
                                  }}
                                >
                                  {t("debts.statementDueLabel", { date: s.dueDate.toLocaleDateString(i18n.language, {
                                    day: "numeric",
                                    month: "short",
                                  }) })}
                                  {s.paidAmount > 0 && !isFullyPaid
                                    ? t("debts.paidAmountLabel", { amount: formatAmount(s.paidAmount) })
                                    : ""}
                                </Text>
                              </View>
                              <View
                                style={{ alignItems: "flex-end", gap: 2 }}
                              >
                                <Text
                                  style={[
                                    styles.autoBdAmt,
                                    isFullyPaid && styles.autoBdAmtPaid,
                                  ]}
                                >
                                  {formatAmount(s.amount)}
                                </Text>
                                <View
                                  style={{
                                    flexDirection: "row",
                                    alignItems: "center",
                                    gap: 4,
                                  }}
                                >
                                  <Text
                                    style={{
                                      fontSize: 9,
                                      fontWeight: "700",
                                      color: isManual ? "#7C3AED" : colors.primary,
                                      backgroundColor: isManual
                                        ? "#7C3AED18"
                                        : colors.primary + "18",
                                      paddingHorizontal: 5,
                                      paddingVertical: 1,
                                      borderRadius: 5,
                                      overflow: "hidden",
                                    }}
                                  >
                                    {isManual ? t("debts.manualBadge") : t("debts.autoBadge")}
                                  </Text>
                                </View>
                              </View>
                              <TouchableOpacity
                                style={styles.autoBdIconBtn}
                                onPress={() =>
                                  openManualStatementEditor(
                                    b,
                                    s.yearMonth,
                                    isManual ? s.manualAmount : undefined
                                  )
                                }
                              >
                                <Feather
                                  name="edit-2"
                                  size={10}
                                  color={colors.foreground}
                                />
                              </TouchableOpacity>
                              {isManual && (
                                <TouchableOpacity
                                  style={styles.autoBdIconBtn}
                                  onPress={() => {
                                    const doDelete = () =>
                                      setManualStatementAmount(
                                        b.id,
                                        s.yearMonth,
                                        null
                                      );
                                    if (Platform.OS === "web") {
                                      if (
                                        window.confirm(t("debts.deleteStatementConfirm"))
                                      )
                                        doDelete();
                                    } else {
                                      Alert.alert(
                                        t("debts.deleteStatementTitle"),
                                        t("debts.deleteStatementConfirm"),
                                        [
                                          { text: t("debts.cancel"), style: "cancel" },
                                          {
                                            text: t("debts.delete"),
                                            style: "destructive",
                                            onPress: doDelete,
                                          },
                                        ]
                                      );
                                    }
                                  }}
                                >
                                  <Feather
                                    name="rotate-ccw"
                                    size={10}
                                    color={colors.expense}
                                  />
                                </TouchableOpacity>
                              )}
                            </View>
                          );
                        })
                      )}

                      <View style={styles.autoBdTotalRow}>
                        <Text style={styles.autoBdTitle}>{t("debts.totalDebtCard")}</Text>
                        <Text style={[styles.autoBdAmt, { fontSize: 13 }]}>
                          {formatAmount(c.totalDebt)}
                        </Text>
                      </View>

                      <TouchableOpacity
                        style={styles.autoBdGoLink}
                        onPress={() => {
                          Haptics.selectionAsync();
                          router.push("/finans/bank-limits" as any);
                        }}
                      >
                        <Feather name="settings" size={11} color={colors.primary} />
                        <Text style={styles.autoBdGoLinkText}>{t("debts.openBankLimits")}</Text>
                      </TouchableOpacity>
                    </View>
                  )}
                </View>
              );
            })}
          </View>
        )}

        <View style={styles.section}>
          {visibleDebts.length === 0 ? (
            <View style={styles.empty}>
              <Feather
                name="check-circle"
                size={40}
                color={colors.mutedForeground}
              />
              <Text style={styles.emptyText}>
                {debts.length === 0 ? t("debts.emptyText") : t("debts.noDebtsFilter")}
              </Text>
              <Text style={styles.emptySub}>
                {debts.length === 0
                  ? t("debts.emptySub")
                  : t("debts.noDebtsFilterHint")}
              </Text>
            </View>
          ) : (
            (() => {
              const sabit = visibleDebts.filter((d) => !d.isInstallment);
              const taksitli = visibleDebts.filter((d) => d.isInstallment);
              return (
                <>
                  {sabit.length > 0 && (
                    <>
                      <View style={styles.debtGroupHeader}>
                        <Feather name="anchor" size={13} color={colors.primary} />
                        <Text style={styles.debtGroupHeaderTitle}>{t("debts.fixedDebt")}</Text>
                        <Text style={styles.debtGroupHeaderCount}>{sabit.length}</Text>
                      </View>
                      {sabit.map((d) => renderDebtCard(d))}
                    </>
                  )}
                  {taksitli.length > 0 && (
                    <>
                      <View style={[styles.debtGroupHeader, sabit.length > 0 && { marginTop: 8 }]}>
                        <Feather name="layers" size={13} color={colors.primary} />
                        <Text style={styles.debtGroupHeaderTitle}>{t("debts.installmentDebt")}</Text>
                        <Text style={styles.debtGroupHeaderCount}>{taksitli.length}</Text>
                      </View>
                      {taksitli.map((d) => renderDebtCard(d))}
                    </>
                  )}
                </>
              );
            })()
          )}
        </View>
          </>
        )}
      </ScrollView>


      {/* Add/Edit Wizard */}
      <DebtWizard
        visible={modalVisible}
        editDebt={editId ? debts.find((d) => d.id === editId) ?? null : null}
        onClose={() => { setModalVisible(false); setEditId(null); }}
      />


      {/* Payment Modal */}
      <Modal
        visible={paymentDebt !== null}
        transparent
        animationType="slide"
        onRequestClose={() => setPaymentDebt(null)}
      >
        <View style={{ flex: 1 }}>
        <Pressable
          style={styles.modalBackdrop}
          onPress={() => setPaymentDebt(null)}
        >
          <Pressable style={styles.modalContent} onPress={() => {}}>
            <KeyboardAwareScrollViewCompat
              keyboardShouldPersistTaps="handled"
              showsVerticalScrollIndicator={false}
            >
              <Text style={styles.modalTitle}>{t("debts.addPayment")}</Text>
              {paymentDebt && (
                <Text style={[styles.debtMeta, { marginBottom: 4 }]}>
                  {paymentDebt.name} • {t("debts.remainingAmount")}{" "}
                  {formatAmount(
                    Math.max(0, paymentDebt.amount - paymentDebt.paidAmount)
                  )}
                </Text>
              )}

              <Text style={styles.label}>{t("debts.paymentAmount")}</Text>
              <TextInput
                style={styles.input}
                value={paymentAmount}
                onChangeText={setPaymentAmount}
                placeholder="0,00"
                placeholderTextColor={colors.mutedForeground}
                keyboardType="decimal-pad"
              />

              <Text style={styles.label}>{t("debts.paymentDate")}</Text>
              <TouchableOpacity
                style={styles.selector}
                onPress={() => {
                  Haptics.selectionAsync();
                  setPaymentDateOpen(true);
                }}
              >
                <View
                  style={{ flexDirection: "row", alignItems: "center", gap: 10 }}
                >
                  <Feather
                    name="calendar"
                    size={16}
                    color={colors.mutedForeground}
                  />
                  <Text style={styles.selectorText}>
                    {paymentDate.toLocaleDateString(i18n.language, {
                      day: "2-digit",
                      month: "long",
                      year: "numeric",
                    })}
                  </Text>
                </View>
                <Feather
                  name="chevron-down"
                  size={18}
                  color={colors.mutedForeground}
                />
              </TouchableOpacity>

              <View style={{ flexDirection: "row", gap: 10, marginTop: 22 }}>
                <TouchableOpacity
                  style={styles.cancelBtn}
                  onPress={() => setPaymentDebt(null)}
                >
                  <Text style={styles.cancelBtnText}>{t("debts.cancel")}</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={[
                    styles.cancelBtn,
                    { backgroundColor: colors.primary, borderColor: colors.primary, flex: 1 },
                    !(parseFloat(paymentAmount.replace(",", ".")) > 0) && styles.saveBtnDisabled,
                  ]}
                  onPress={handleSavePayment}
                  disabled={!(parseFloat(paymentAmount.replace(",", ".")) > 0)}
                >
                  <Text style={styles.saveBtnText}>{t("debts.save")}</Text>
                </TouchableOpacity>
              </View>
            </KeyboardAwareScrollViewCompat>
          </Pressable>
        </Pressable>

        {/* Payment date picker — inside this Modal so iOS works */}
        <DatePickerSheet
          visible={paymentDateOpen}
          value={paymentDate}
          title={t("debts.paymentDate")}
          onSelect={(d) => setPaymentDate(d)}
          onClose={() => setPaymentDateOpen(false)}
        />
        </View>
      </Modal>

      {/* Scroll to top button */}
      <Animated.View
        style={[
          styles.scrollTopBtn,
          { bottom: bottomInset + 90, opacity: scrollTopOpacity },
        ]}
        pointerEvents={showScrollTop ? "auto" : "none"}
      >
        <TouchableOpacity onPress={scrollToTop} activeOpacity={0.85}>
          <Feather name="arrow-up" size={20} color="#FFFFFF" />
        </TouchableOpacity>
      </Animated.View>

      {/* ── Overdraft Quick-Edit Modal ─────────────────────────────── */}
      <Modal
        visible={!!odEditBl}
        transparent
        animationType="fade"
        onRequestClose={() => { setOdEditBl(null); setOdEditAmt(""); setOdEditDebt(""); }}
      >
        <Pressable
          style={styles.bdBackdrop}
          onPress={() => { setOdEditBl(null); setOdEditAmt(""); setOdEditDebt(""); }}
        >
          <Pressable style={[styles.bdCard, { marginBottom: odKbHeight }]} onPress={() => {}}>
            <Text style={styles.bdTitle}>{t("debts.updateLimit")}</Text>
            <Text style={[styles.bdLabel, { marginTop: 4 }]}>
              {odEditBl?.institution || odEditBl?.bank}
              {" • "}
              {odEditBl?.type === "credit" ? t("debts.creditCard") : t("debts.overdraftAccount")}
            </Text>
            {odEditBl && (
              <Text style={{ fontSize: 11, color: colors.mutedForeground, marginTop: 4 }}>
                {t("debts.totalLimitInfo", { amount: formatAmount(odEditBl.limit) })}
              </Text>
            )}

            {/* Borç Miktarı */}
            <Text style={[styles.bdLabel, { marginTop: 16 }]}>{t("debts.debtAmount")}</Text>
            <TextInput
              style={styles.bdInput}
              value={odEditDebt}
              onChangeText={onChangeBorc}
              placeholder="0"
              placeholderTextColor={colors.mutedForeground}
              keyboardType="decimal-pad"
              autoFocus
            />

            {/* Kalan Limit */}
            <Text style={[styles.bdLabel, { marginTop: 12 }]}>{t("debts.availableLimit")}</Text>
            <TextInput
              style={styles.bdInput}
              value={odEditAmt}
              onChangeText={onChangeKalanLimit}
              placeholder="0"
              placeholderTextColor={colors.mutedForeground}
              keyboardType="decimal-pad"
            />

            <View style={[styles.bdActions, { marginTop: 20 }]}>
              <TouchableOpacity
                style={styles.bdCancel}
                onPress={() => { setOdEditBl(null); setOdEditAmt(""); setOdEditDebt(""); }}
              >
                <Text style={styles.bdCancelText}>{t("debts.cancel")}</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.bdSave} onPress={saveOdEdit}>
                <Text style={styles.bdSaveText}>{t("debts.save")}</Text>
              </TouchableOpacity>
            </View>
          </Pressable>
        </Pressable>
      </Modal>

      {/* Monthly Breakdown Modal */}
      <Modal visible={breakdownModal} transparent animationType="fade" onRequestClose={closeBreakdownModal}>
        <Pressable style={styles.bdBackdrop} onPress={closeBreakdownModal}>
          <Pressable style={styles.bdCard} onPress={() => {}}>
            <Text style={styles.bdTitle}>
              {breakdownEditIdx !== null ? t("debts.editBreakdown") : t("debts.addBreakdown")}
            </Text>

            <Text style={styles.bdLabel}>{t("debts.month")}</Text>
            <View style={styles.bdMonthNav}>
              <TouchableOpacity onPress={() => { Haptics.selectionAsync(); setBreakdownYM((ym) => shiftYM(ym, -1)); }} style={styles.bdNavBtn}>
                <Feather name="chevron-left" size={20} color={colors.foreground} />
              </TouchableOpacity>
              <Text style={styles.bdMonthLabel}>{fmtYM(breakdownYM)}</Text>
              <TouchableOpacity onPress={() => { Haptics.selectionAsync(); setBreakdownYM((ym) => shiftYM(ym, 1)); }} style={styles.bdNavBtn}>
                <Feather name="chevron-right" size={20} color={colors.foreground} />
              </TouchableOpacity>
            </View>

            <Text style={styles.bdLabel}>{t("debts.statementAmountLabel")}</Text>
            <TextInput
              style={styles.bdInput}
              value={breakdownAmount}
              onChangeText={setBreakdownAmount}
              placeholder="0,00"
              placeholderTextColor={colors.mutedForeground}
              keyboardType="decimal-pad"
              autoFocus
            />

            <View style={styles.bdActions}>
              <TouchableOpacity style={styles.bdCancel} onPress={closeBreakdownModal}>
                <Text style={styles.bdCancelText}>{t("debts.cancel")}</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.bdSave} onPress={saveBreakdown}>
                <Text style={styles.bdSaveText}>{t("debts.save")}</Text>
              </TouchableOpacity>
            </View>
          </Pressable>
        </Pressable>
      </Modal>

    </View>
  );
}
