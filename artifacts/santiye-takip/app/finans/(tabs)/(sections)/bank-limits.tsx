import { Feather } from "@expo/vector-icons";
import * as Haptics from "expo-haptics";

import React, { useMemo, useState } from "react";
import {
  Alert,
  KeyboardAvoidingView,
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

import AsyncStorage from "@react-native-async-storage/async-storage";
import { useTranslation } from "react-i18next";
import { BankLimit, BankLimitType, useBudget } from "@/context/finans/BudgetContext";
import { useColors } from "@/hooks/finans/useColors";
import { useListOrder } from "@/hooks/finans/useListOrder";
import { useFormatAmount } from "@/hooks/finans/useFormatAmount";

export default function BankLimitsScreen() {
  const formatAmount = useFormatAmount();
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const { t } = useTranslation();

  const {
    bankLimits,
    addBankLimit,
    updateBankLimit,
    deleteBankLimit,
    reconcileBankLimit,
    savedCards,
  } = useBudget();

  type LimitsTab = BankLimitType;
  const [activeTab, setActiveTab] = useState<LimitsTab>("credit");

  const tabColor = activeTab === "credit" ? "#00C896" : "#4E9EF5";
  const tabBg    = activeTab === "credit" ? "#E6FBF4" : "#EEF5FF";

  // "Bankayla Eşitle" modal state
  const [reconcileTarget, setReconcileTarget] = useState<BankLimit | null>(null);
  const [reconcileInput, setReconcileInput] = useState("");

  const openReconcile = (b: BankLimit) => {
    Haptics.selectionAsync();
    setReconcileTarget(b);
    setReconcileInput(
      typeof b.availableLimit === "number" && Number.isFinite(b.availableLimit)
        ? String(b.availableLimit)
        : ""
    );
  };

  const closeReconcile = () => {
    setReconcileTarget(null);
    setReconcileInput("");
  };

  const submitReconcile = () => {
    if (!reconcileTarget) return;
    const parsed = parseFloat(reconcileInput.replace(",", "."));
    if (!Number.isFinite(parsed) || parsed < 0) {
      const m = t("bankLimits.validation.invalidAmount");
      Platform.OS === "web" ? window.alert(m) : Alert.alert(t("bankLimits.validation.missing"), m);
      return;
    }
    if (parsed > reconcileTarget.limit + 0.005) {
      const m = t("bankLimits.validation.limitExceedsTotal", { total: formatAmount(reconcileTarget.limit) });
      Platform.OS === "web" ? window.alert(m) : Alert.alert(t("bankLimits.validation.invalid"), m);
      return;
    }
    reconcileBankLimit(reconcileTarget.id, parsed);
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    closeReconcile();
  };

  const [modalVisible, setModalVisible] = useState(false);
  const [editId, setEditId] = useState<string | null>(null);
  const [institution, setInstitution] = useState("");
  const [bank, setBank] = useState("");
  const [savedCardId, setSavedCardId] = useState<string | undefined>(undefined);
  const [bankPickerOpen, setBankPickerOpen] = useState(false);
  const [cardPickerOpen, setCardPickerOpen] = useState(false);
  const [manualEntry, setManualEntry] = useState(false);
  const [limit, setLimit] = useState("");
  const [availableLimit, setAvailableLimit] = useState("");
  const [type, setType] = useState<BankLimitType>("credit");
  const [expandedId, setExpandedId] = useState<string | null>(null);

  const topInset = 0;
  const bottomInset = Platform.OS === "web" ? 34 : insets.bottom;

  const filteredLimits = useMemo(
    () => bankLimits.filter((b) => b.type === activeTab),
    [bankLimits, activeTab]
  );
  const creditIds = useMemo(
    () => bankLimits.filter((b) => b.type === "credit").map((b) => b.id),
    [bankLimits]
  );
  const extraIds = useMemo(
    () => bankLimits.filter((b) => b.type !== "credit").map((b) => b.id),
    [bankLimits]
  );
  const [reorderMode, setReorderMode] = useState(false);
  const creditOrder = useListOrder("bank-limits-credit", creditIds);
  const extraOrder  = useListOrder("bank-limits-extra",  extraIds);
  const activeOrder = activeTab === "credit" ? creditOrder : extraOrder;

  const moveWithinFiltered = (id: string, dir: "up" | "down") => {
    Haptics.selectionAsync();
    activeOrder.setOrderedIds((prev) => {
      const filtered = filteredLimits.map((b) => b.id).filter((fid) => prev.includes(fid)).sort((a, b) => prev.indexOf(a) - prev.indexOf(b));
      const pos = filtered.indexOf(id);
      const next = dir === "up" ? pos - 1 : pos + 1;
      if (next < 0 || next >= filtered.length) return prev;
      const idxA = prev.indexOf(id);
      const idxB = prev.indexOf(filtered[next]);
      const arr = [...prev];
      [arr[idxA], arr[idxB]] = [arr[idxB], arr[idxA]];
      AsyncStorage.setItem(activeTab === "credit" ? "bank-limits-credit" : "bank-limits-extra", JSON.stringify(arr));
      return arr;
    });
  };

  // Tab kartları için tür bazlı toplamlar (Harcanan / Kalan)
  const typeTotals = useMemo(() => {
    const calc = (t: BankLimitType) => {
      const lims = bankLimits.filter((b) => b.type === t);
      const limit = lims.reduce((s, b) => s + (b.limit ?? 0), 0);
      const available = lims.reduce(
        (s, b) => s + (b.availableLimit ?? 0),
        0
      );
      const used = Math.max(0, limit - available);
      return { limit, available, used };
    };
    return { credit: calc("credit"), overdraft: calc("overdraft") };
  }, [bankLimits]);

  const resetForm = () => {
    setEditId(null);
    setInstitution("");
    setBank("");
    setSavedCardId(undefined);
    setLimit("");
    setAvailableLimit("");
    setType("credit");
    setBankPickerOpen(false);
    setCardPickerOpen(false);
    setManualEntry(false);
  };

  const openAdd = () => {
    Haptics.selectionAsync();
    resetForm();
    setType(activeTab);
    setModalVisible(true);
  };

  const openEdit = (b: BankLimit) => {
    Haptics.selectionAsync();
    setEditId(b.id);
    setInstitution(b.institution || "");
    setBank(b.bank);
    setSavedCardId(b.savedCardId);
    setLimit(String(b.limit));
    setAvailableLimit(b.availableLimit !== undefined ? String(b.availableLimit) : "");
    setType(b.type);
    setBankPickerOpen(false);
    setCardPickerOpen(false);
    setManualEntry(!b.savedCardId);
    setModalVisible(true);
  };

  const close = () => {
    setModalVisible(false);
    resetForm();
  };

  const submit = () => {
    const trimmedInstitution = institution.trim();
    const trimmedBank = bank.trim();
    const lim = parseFloat(limit.replace(",", "."));
    const avail = parseFloat(availableLimit.replace(",", "."));
    if (!trimmedInstitution) {
      const m = t("bankLimits.validation.bankRequired");
      Platform.OS === "web" ? window.alert(m) : Alert.alert(t("bankLimits.validation.missing"), m);
      return;
    }
    if (!trimmedBank) {
      const m = type === "credit" ? t("bankLimits.validation.cardRequired") : t("bankLimits.validation.accountRequired");
      Platform.OS === "web" ? window.alert(m) : Alert.alert(t("bankLimits.validation.missing"), m);
      return;
    }
    if (!isFinite(lim) || lim <= 0) {
      const m = t("bankLimits.validation.limitRequired");
      Platform.OS === "web" ? window.alert(m) : Alert.alert(t("bankLimits.validation.missing"), m);
      return;
    }
    const availVal = isFinite(avail) && avail >= 0 ? avail : undefined;
    const payload = {
      bank: trimmedBank,
      institution: trimmedInstitution,
      savedCardId,
      limit: lim,
      availableLimit: availVal,
      type,
    };
    if (editId) {
      updateBankLimit(editId, payload);
    } else {
      addBankLimit(payload);
    }
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    close();
  };

  const handleDelete = (b: BankLimit) => {
    const msg = t("bankLimits.deleteConfirm", { bank: b.bank });
    if (Platform.OS === "web") {
      if (window.confirm(msg)) deleteBankLimit(b.id);
      return;
    }
    Alert.alert(t("bankLimits.deleteTitle"), msg, [
      { text: t("bankLimits.cancel"), style: "cancel" },
      {
        text: t("bankLimits.deleteTitle"),
        style: "destructive",
        onPress: () => deleteBankLimit(b.id),
      },
    ]);
  };

  const styles = StyleSheet.create({
    container: { flex: 1, backgroundColor: colors.background },
    header: {
      backgroundColor: colors.navy,
      paddingTop: topInset + 16,
      paddingBottom: 16,
      paddingHorizontal: 20,
    },
    headerTopRow: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      marginBottom: 6,
    },

    headerTitle: {
      flex: 1,
      fontSize: 20,
      fontWeight: "800",
      color: "#FFFFFF",
      textAlign: "center",
    },
    tabRow: {
      flexDirection: "row",
      marginHorizontal: 16,
      marginTop: 16,
      gap: 10,
    },
    tabCard: {
      flex: 1,
      backgroundColor: colors.card,
      borderRadius: 16,
      padding: 12,
      borderWidth: 1,
      borderColor: colors.border,
      overflow: "hidden",
      position: "relative",
    },
    tabCardTop: {
      flexDirection: "row",
      justifyContent: "space-between",
      alignItems: "center",
      marginBottom: 10,
    },
    tabCardIcon: {
      width: 32,
      height: 32,
      borderRadius: 10,
      alignItems: "center",
      justifyContent: "center",
    },
    tabCardBadge: {
      minWidth: 22,
      height: 22,
      borderRadius: 11,
      alignItems: "center",
      justifyContent: "center",
      paddingHorizontal: 6,
    },
    tabCardBadgeText: {
      fontSize: 11,
      fontWeight: "800",
    },
    tabCardLabel: {
      fontSize: 12,
      fontWeight: "700",
      color: colors.foreground,
      marginBottom: 6,
    },
    tabCardValue: {
      fontSize: 11,
      fontWeight: "600",
      color: colors.mutedForeground,
    },
    tabStatRow: {
      marginTop: 3,
      alignItems: "flex-start",
    },
    tabStatLabel: {
      fontSize: 10,
      fontWeight: "500",
      color: colors.mutedForeground,
    },
    tabStatValue: {
      fontSize: 12,
      fontWeight: "800",
      color: colors.foreground,
      letterSpacing: -0.2,
    },
    tabCardBar: {
      position: "absolute",
      bottom: 0,
      left: 0,
      right: 0,
      height: 3,
      borderRadius: 2,
    },
    addRow: { paddingHorizontal: 20, marginTop: 12 },
    addBtn: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "center",
      gap: 8,
      backgroundColor: colors.primary,
      borderRadius: colors.radius,
      paddingVertical: 13,
    },
    addBtnText: { color: "#FFFFFF", fontWeight: "700", fontSize: 15 },
    list: { paddingHorizontal: 20, marginTop: 16, paddingBottom: 24 },
    card: {
      backgroundColor: colors.card,
      borderRadius: colors.radius,
      padding: 16,
      marginBottom: 12,
    },
    cardTopRow: {
      flexDirection: "row",
      alignItems: "center",
      gap: 12,
      marginBottom: 10,
    },
    bankIconBg: {
      width: 40,
      height: 40,
      borderRadius: 12,
      alignItems: "center",
      justifyContent: "center",
      backgroundColor: colors.muted,
    },
    bankName: {
      fontSize: 16,
      fontWeight: "700",
      color: colors.foreground,
    },
    typeBadge: {
      fontSize: 11,
      color: colors.mutedForeground,
      marginTop: 2,
    },
    typeRow: {
      flexDirection: "row",
      gap: 8,
      marginBottom: 4,
    },
    iconBtn: {
      width: 32,
      height: 32,
      borderRadius: 10,
      alignItems: "center",
      justifyContent: "center",
      backgroundColor: colors.muted,
    },
    statBlock: { marginBottom: 8 },
    statLabel: {
      fontSize: 11,
      color: colors.mutedForeground,
      marginBottom: 4,
      letterSpacing: 0.3,
    },
    statRow: {
      flexDirection: "row",
      justifyContent: "space-between",
      marginBottom: 4,
    },
    statText: { fontSize: 13, color: colors.foreground, fontWeight: "600" },
    barTrack: {
      height: 8,
      borderRadius: 4,
      backgroundColor: colors.muted,
      overflow: "hidden",
    },
    barFill: { height: "100%", borderRadius: 4 },
    availableRow: {
      flexDirection: "row",
      justifyContent: "space-between",
      marginTop: 10,
      paddingTop: 10,
      borderTopWidth: 1,
      borderTopColor: colors.border,
    },
    availableLabel: {
      fontSize: 12,
      color: colors.mutedForeground,
    },
    availableValue: {
      fontSize: 14,
      fontWeight: "800",
      color: colors.income,
    },
    reconcileBtn: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "center",
      gap: 6,
      marginTop: 12,
      paddingVertical: 10,
      paddingHorizontal: 14,
      borderRadius: 10,
      borderWidth: 1,
      borderColor: colors.primary + "33",
      backgroundColor: colors.primary + "0F",
    },
    reconcileBtnText: {
      fontSize: 13,
      fontWeight: "700",
      color: colors.primary,
    },
    expandedActions: {
      flexDirection: "row",
      gap: 8,
      marginTop: 10,
    },
    expandedBtn: {
      flex: 1,
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "center",
      gap: 6,
      paddingVertical: 10,
      borderRadius: 10,
      backgroundColor: colors.muted,
    },
    expandedBtnDanger: {
      backgroundColor: colors.expense + "15",
    },
    expandedBtnText: {
      fontSize: 13,
      fontWeight: "700",
      color: colors.foreground,
    },
    reconcileSummaryRow: {
      flexDirection: "row",
      justifyContent: "space-between",
      alignItems: "center",
      paddingVertical: 6,
    },
    reconcileSummaryLabel: {
      fontSize: 12,
      color: colors.mutedForeground,
    },
    reconcileSummaryValue: {
      fontSize: 13,
      fontWeight: "700",
      color: colors.foreground,
    },
    reconcileDiffPill: {
      marginTop: 12,
      borderRadius: 10,
      paddingVertical: 10,
      paddingHorizontal: 12,
      backgroundColor: colors.muted,
    },
    reconcileDiffText: {
      fontSize: 12,
      color: colors.foreground,
      lineHeight: 17,
    },
    noteText: {
      fontSize: 12,
      color: colors.mutedForeground,
      marginTop: 6,
      fontStyle: "italic",
    },
    empty: {
      alignItems: "center",
      paddingVertical: 60,
    },
    emptyText: {
      fontSize: 14,
      color: colors.mutedForeground,
      marginTop: 12,
      textAlign: "center",
    },

    backdrop: {
      flex: 1,
      backgroundColor: "rgba(0,0,0,0.45)",
      justifyContent: "center",
      padding: 20,
    },
    modalCard: {
      backgroundColor: colors.background,
      borderRadius: colors.radius,
      padding: 20,
      maxHeight: "90%",
    },
    modalTitle: {
      fontSize: 18,
      fontWeight: "800",
      color: colors.foreground,
      marginBottom: 16,
    },
    label: {
      fontSize: 13,
      fontWeight: "600",
      color: colors.foreground,
      marginBottom: 6,
      marginTop: 12,
    },
    selector: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      backgroundColor: colors.muted,
      borderRadius: 12,
      paddingVertical: 12,
      paddingHorizontal: 14,
    },
    selectorText: { fontSize: 14, color: colors.foreground, fontWeight: "600" },
    bankList: {
      backgroundColor: colors.muted,
      borderRadius: 12,
      marginTop: 6,
      maxHeight: 220,
    },
    bankRow: {
      paddingVertical: 12,
      paddingHorizontal: 14,
      borderBottomWidth: 1,
      borderBottomColor: colors.border,
    },
    input: {
      backgroundColor: colors.muted,
      borderRadius: 12,
      paddingVertical: 12,
      paddingHorizontal: 14,
      color: colors.foreground,
      fontSize: 15,
    },
    lockedField: {
      flexDirection: "row",
      alignItems: "center",
      gap: 8,
      backgroundColor: colors.border,
      borderRadius: 12,
      paddingVertical: 12,
      paddingHorizontal: 14,
      opacity: 0.8,
    },
    lockedFieldText: {
      fontSize: 15,
      fontWeight: "600",
      color: colors.mutedForeground,
      flex: 1,
    },
    actions: {
      flexDirection: "row",
      gap: 10,
      marginTop: 22,
    },
    cancelBtn: {
      flex: 1,
      backgroundColor: colors.muted,
      borderRadius: colors.radius,
      paddingVertical: 14,
      alignItems: "center",
      borderWidth: 1,
      borderColor: colors.border,
    },
    cancelBtnText: { color: colors.foreground, fontWeight: "700", fontSize: 15 },
    saveBtn: {
      flex: 1,
      backgroundColor: colors.primary,
      borderRadius: colors.radius,
      paddingVertical: 14,
      alignItems: "center",
    },
    saveBtnText: { color: "#FFFFFF", fontWeight: "700", fontSize: 15 },
    reorderBanner: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "center",
      backgroundColor: colors.primary,
      paddingVertical: 10,
      gap: 8,
    },
    reorderBannerText: { fontSize: 13, fontWeight: "700", color: "#FFFFFF" },
    reorderArrows: { flexDirection: "row", gap: 2 },
    arrowBtn: {
      padding: 5,
      borderRadius: 6,
      backgroundColor: colors.primary + "18",
    },
    arrowDisabled: { opacity: 0.3 },
  });

  return (
    <View style={styles.container}>
      <ScrollView
        style={{ flex: 1 }}
        contentContainerStyle={{ paddingBottom: bottomInset + 24 }}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.header}>
          <View style={styles.headerTopRow}>
            <Text style={styles.headerTitle}>{t("bankLimits.title")}</Text>
          </View>
        </View>

        {/* Tab Seçici — büyük kart */}
        <View style={styles.tabRow}>
          {(
            [
              {
                key:      "credit" as LimitsTab,
                label:    t("bankLimits.tabs.credit"),
                icon:     "credit-card" as const,
                color:    "#00C896",
                bg:       "#E6FBF4",
                stats: [
                  { key: "limit", label: t("bankLimits.totalLimit"),     value: formatAmount(typeTotals.credit.limit),     color: colors.foreground },
                  { key: "used",  label: t("bankLimits.usedLimit"),      value: formatAmount(typeTotals.credit.used),      color: "#F59E0B" },
                  { key: "left",  label: t("bankLimits.remainingLimit"), value: formatAmount(typeTotals.credit.available), color: "#00C896" },
                ],
              },
              {
                key:      "overdraft" as LimitsTab,
                label:    t("bankLimits.tabs.overdraft"),
                icon:     "dollar-sign" as const,
                color:    "#4E9EF5",
                bg:       "#EEF5FF",
                stats: [
                  { key: "limit", label: t("bankLimits.totalLimit"),     value: formatAmount(typeTotals.overdraft.limit),     color: colors.foreground },
                  { key: "used",  label: t("bankLimits.usedLimit"),      value: formatAmount(typeTotals.overdraft.used),      color: "#F59E0B" },
                  { key: "left",  label: t("bankLimits.remainingLimit"), value: formatAmount(typeTotals.overdraft.available), color: "#4E9EF5" },
                ],
              },
            ] as const
          ).map(({ key, label, icon, color, bg, stats }) => {
            const isActive = activeTab === key;
            const count = bankLimits.filter((b) => b.type === key).length;
            return (
              <TouchableOpacity
                key={key}
                activeOpacity={0.78}
                style={[
                  styles.tabCard,
                  isActive && {
                    backgroundColor: bg,
                    borderColor: color,
                    borderWidth: 1.5,
                  },
                ]}
                onPress={() => {
                  Haptics.selectionAsync();
                  setActiveTab(key);
                }}
              >
                {/* Üst: ikon + rozet */}
                <View style={styles.tabCardTop}>
                  <View style={[styles.tabCardIcon, { backgroundColor: isActive ? color : colors.muted }]}>
                    <Feather name={icon} size={16} color={isActive ? "#fff" : colors.mutedForeground} />
                  </View>
                  <View style={[
                    styles.tabCardBadge,
                    { backgroundColor: isActive ? color : colors.muted },
                  ]}>
                    <Text style={[styles.tabCardBadgeText, { color: isActive ? "#fff" : colors.mutedForeground }]}>
                      {count}
                    </Text>
                  </View>
                </View>
                {/* Alt: başlık + 3 tutar (limit / harcanan / kalan) */}
                <Text style={[styles.tabCardLabel, isActive && { color: color }]} numberOfLines={1}>
                  {label}
                </Text>
                {stats.map((s) => (
                  <View key={s.key} style={styles.tabStatRow}>
                    <Text
                      style={[styles.tabStatValue, { color: s.color }]}
                      numberOfLines={1}
                      ellipsizeMode="tail"
                    >
                      <Text style={styles.tabStatLabel}>{s.label} - </Text>
                      {s.value}
                    </Text>
                  </View>
                ))}
                {/* Aktif çizgi */}
                {isActive && <View style={[styles.tabCardBar, { backgroundColor: color }]} />}
              </TouchableOpacity>
            );
          })}
        </View>

        <View style={styles.addRow}>
          <TouchableOpacity style={[styles.addBtn, { backgroundColor: tabColor }]} onPress={openAdd}>
            <Feather name="plus" size={18} color="#FFFFFF" />
            <Text style={styles.addBtnText}>
              {activeTab === "credit" ? t("bankLimits.addCredit") : t("bankLimits.addOverdraft")}
            </Text>
          </TouchableOpacity>
        </View>

        {reorderMode && (
          <TouchableOpacity
            style={styles.reorderBanner}
            onPress={() => { setReorderMode(false); setExpandedId(null); }}
          >
            <Feather name="check" size={14} color="#FFFFFF" />
            <Text style={styles.reorderBannerText}>{t("bankLimits.reorderDone")}</Text>
          </TouchableOpacity>
        )}

        <View style={styles.list}>
          {filteredLimits.length === 0 ? (
            <View style={styles.empty}>
              <Feather
                name={activeTab === "credit" ? "credit-card" : "dollar-sign"}
                size={42}
                color={colors.mutedForeground}
              />
              <Text style={styles.emptyText}>
                {activeTab === "credit"
                  ? t("bankLimits.emptyCredit")
                  : t("bankLimits.emptyOverdraft")}
              </Text>
            </View>
          ) : (() => {
              const sortedFiltered = activeOrder.sortedByOrder(filteredLimits);
              return sortedFiltered.map((b) => {
              const avail = b.availableLimit ?? 0;
              const hasAvail = b.availableLimit !== undefined;
              const used = hasAvail ? Math.max(0, b.limit - avail) : 0;
              const ratio = b.limit > 0 && hasAvail ? used / b.limit : 0;
              const overLimit = hasAvail && avail < 0;
              const fillColor = overLimit ? colors.expense : ratio > 0.8 ? "#F59E0B" : tabColor;
              const isCC = b.type === "credit";
              const posInFiltered = sortedFiltered.findIndex((x) => x.id === b.id);
              const canUp = posInFiltered > 0;
              const canDown = posInFiltered < sortedFiltered.length - 1;
              return (
                <View key={b.id} style={styles.card}>
                  <TouchableOpacity
                    style={styles.cardTopRow}
                    onPress={() => {
                      if (reorderMode) return;
                      Haptics.selectionAsync();
                      setExpandedId(expandedId === b.id ? null : b.id);
                    }}
                    onLongPress={() => {
                      Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
                      setExpandedId(null);
                      setReorderMode(true);
                    }}
                    delayLongPress={600}
                    activeOpacity={0.85}
                  >
                    <View style={[styles.bankIconBg, { backgroundColor: tabBg }]}>
                      <Feather name={isCC ? "credit-card" : "dollar-sign"} size={20} color={tabColor} />
                    </View>
                    <View style={{ flex: 1 }}>
                      <Text style={styles.bankName}>{b.institution || b.bank}</Text>
                      <Text style={styles.typeBadge}>
                        {b.institution ? `${b.bank} • ${isCC ? t("bankLimits.tabs.credit") : t("bankLimits.tabs.overdraft")}` : (isCC ? t("bankLimits.tabs.credit") : t("bankLimits.tabs.overdraft"))}
                      </Text>
                    </View>
                    {reorderMode ? (
                      <View style={styles.reorderArrows}>
                        <TouchableOpacity
                          disabled={!canUp}
                          onPress={() => moveWithinFiltered(b.id, "up")}
                          style={[styles.arrowBtn, !canUp && styles.arrowDisabled]}
                        >
                          <Feather name="chevron-up" size={18} color={canUp ? colors.primary : colors.mutedForeground} />
                        </TouchableOpacity>
                        <TouchableOpacity
                          disabled={!canDown}
                          onPress={() => moveWithinFiltered(b.id, "down")}
                          style={[styles.arrowBtn, !canDown && styles.arrowDisabled]}
                        >
                          <Feather name="chevron-down" size={18} color={canDown ? colors.primary : colors.mutedForeground} />
                        </TouchableOpacity>
                      </View>
                    ) : (
                      <Feather
                        name={expandedId === b.id ? "chevron-up" : "chevron-down"}
                        size={16}
                        color={colors.mutedForeground}
                      />
                    )}
                  </TouchableOpacity>

                  <View style={styles.statBlock}>
                    <View style={styles.statRow}>
                      <Text style={styles.statLabel}>{t("bankLimits.totalLimit")}</Text>
                      <Text style={styles.statText}>{formatAmount(b.limit)}</Text>
                    </View>
                    {hasAvail && (
                      <>
                        <View style={styles.statRow}>
                          <Text style={styles.statLabel}>{t("bankLimits.used")}</Text>
                          <Text style={styles.statText}>{formatAmount(used)}</Text>
                        </View>
                        <View style={styles.barTrack}>
                          <View style={[styles.barFill, { width: `${Math.min(100, ratio * 100)}%`, backgroundColor: fillColor }]} />
                        </View>
                      </>
                    )}
                  </View>

                  {overLimit && (
                    <View style={{
                      flexDirection: "row",
                      alignItems: "center",
                      backgroundColor: colors.expenseBg,
                      borderRadius: 8,
                      paddingHorizontal: 10,
                      paddingVertical: 6,
                      marginBottom: 6,
                      gap: 6,
                    }}>
                      <Feather name="alert-triangle" size={13} color={colors.expense} />
                      <Text style={{ fontSize: 12, color: colors.expense, fontWeight: "700", flex: 1 }}>
                        {t("bankLimits.overLimit", { amount: formatAmount(Math.abs(avail)) })}
                      </Text>
                    </View>
                  )}
                  <View style={styles.availableRow}>
                    <Text style={styles.availableLabel}>{t("bankLimits.availableNow")}</Text>
                    <Text style={[styles.availableValue, { color: overLimit ? colors.expense : tabColor }]}>
                      {hasAvail ? (overLimit ? formatAmount(0) : formatAmount(avail)) : "—"}
                    </Text>
                  </View>

                  <TouchableOpacity
                    style={[styles.reconcileBtn, { borderColor: tabColor + "33", backgroundColor: tabColor + "0F" }]}
                    onPress={() => openReconcile(b)}
                  >
                    <Feather name="refresh-cw" size={13} color={tabColor} />
                    <Text style={[styles.reconcileBtnText, { color: tabColor }]}>{t("bankLimits.reconcileBtn")}</Text>
                  </TouchableOpacity>
                  {!reorderMode && expandedId === b.id && (
                    <View style={styles.expandedActions}>
                      <TouchableOpacity
                        style={styles.expandedBtn}
                        onPress={() => { setExpandedId(null); openEdit(b); }}
                      >
                        <Feather name="edit-2" size={13} color={colors.foreground} />
                        <Text style={styles.expandedBtnText}>{t("bankLimits.edit")}</Text>
                      </TouchableOpacity>
                      <TouchableOpacity
                        style={[styles.expandedBtn, styles.expandedBtnDanger]}
                        onPress={() => { setExpandedId(null); handleDelete(b); }}
                      >
                        <Feather name="trash-2" size={13} color={colors.expense} />
                        <Text style={[styles.expandedBtnText, { color: colors.expense }]}>{t("bankLimits.deleteTitle")}</Text>
                      </TouchableOpacity>
                    </View>
                  )}
                </View>
              );
            });
          })()}
        </View>
      </ScrollView>

      <Modal
        visible={modalVisible}
        transparent
        animationType="fade"
        onRequestClose={close}
      >
        <KeyboardAvoidingView
          behavior={Platform.OS === "ios" ? "padding" : undefined}
          style={{ flex: 1 }}
        >
          <Pressable style={styles.backdrop} onPress={close}>
            <Pressable style={styles.modalCard} onPress={() => {}}>
              <ScrollView
                showsVerticalScrollIndicator={false}
                keyboardShouldPersistTaps="handled"
              >
                <Text style={styles.modalTitle}>
                  {editId ? t("bankLimits.editLimit") : (type === "credit" ? t("bankLimits.newCreditLimit") : t("bankLimits.newOverdraftLimit"))}
                </Text>

                {(() => {
                  const savedOfType = savedCards.filter((c) =>
                    type === "credit" ? c.type === "credit" : c.type === "demand"
                  );
                  const institutions = Array.from(
                    new Set(savedOfType.map((c) => c.bank).filter(Boolean))
                  ).sort((a, b) => a.localeCompare(b, "tr"));
                  const cardsForInstitution = savedOfType.filter((c) => c.bank === institution);
                  const noSavedAtAll = savedOfType.length === 0;

                  if (noSavedAtAll && !manualEntry) {
                    return (
                      <View style={{ backgroundColor: colors.background, borderRadius: 10, padding: 12, borderWidth: 1, borderColor: colors.border }}>
                        <Text style={{ color: colors.foreground, fontSize: 13, marginBottom: 8 }}>
                          {type === "credit"
                            ? t("bankLimits.noSavedCards.credit")
                            : t("bankLimits.noSavedCards.overdraft")}
                        </Text>
                        <TouchableOpacity onPress={() => setManualEntry(true)}>
                          <Text style={{ color: colors.primary, fontSize: 13, fontWeight: "600" }}>{t("bankLimits.manualEntry")}</Text>
                        </TouchableOpacity>
                      </View>
                    );
                  }

                  if (manualEntry) {
                    return (
                      <>
                        <Text style={styles.label}>{t("bankLimits.bank")}</Text>
                        <TextInput
                          style={styles.input}
                          value={institution}
                          onChangeText={setInstitution}
                          placeholder={t("bankLimits.bankNamePlaceholder")}
                          placeholderTextColor={colors.mutedForeground}
                        />
                        <Text style={styles.label}>{type === "credit" ? t("bankLimits.cardName") : t("bankLimits.accountName")}</Text>
                        <TextInput
                          style={styles.input}
                          value={bank}
                          onChangeText={setBank}
                          placeholder={type === "credit" ? t("bankLimits.cardNamePlaceholder") : t("bankLimits.accountNamePlaceholder")}
                          placeholderTextColor={colors.mutedForeground}
                        />
                        {!noSavedAtAll && (
                          <TouchableOpacity onPress={() => { setManualEntry(false); setInstitution(""); setBank(""); setSavedCardId(undefined); }} style={{ marginTop: 6 }}>
                            <Text style={{ color: colors.primary, fontSize: 12 }}>
                              {t("bankLimits.selectFromSaved")}
                            </Text>
                          </TouchableOpacity>
                        )}
                      </>
                    );
                  }

                  return (
                    <>
                      <Text style={styles.label}>{t("bankLimits.stepBank")}</Text>
                      <TouchableOpacity
                        style={styles.selector}
                        onPress={() => { Haptics.selectionAsync(); setBankPickerOpen(!bankPickerOpen); setCardPickerOpen(false); }}
                      >
                        <Text style={[styles.selectorText, !institution && { color: colors.mutedForeground }]}>
                          {institution || t("bankLimits.selectBank")}
                        </Text>
                        <Feather name={bankPickerOpen ? "chevron-up" : "chevron-down"} size={18} color={colors.mutedForeground} />
                      </TouchableOpacity>
                      {bankPickerOpen && (
                        <View style={styles.bankList}>
                          <ScrollView nestedScrollEnabled keyboardShouldPersistTaps="handled">
                            {institutions.map((inst) => (
                              <TouchableOpacity
                                key={inst}
                                style={styles.bankRow}
                                onPress={() => {
                                  Haptics.selectionAsync();
                                  setInstitution(inst);
                                  setBank("");
                                  setSavedCardId(undefined);
                                  setBankPickerOpen(false);
                                  setCardPickerOpen(true);
                                }}
                              >
                                <Text style={styles.selectorText}>{inst}</Text>
                              </TouchableOpacity>
                            ))}
                          </ScrollView>
                        </View>
                      )}

                      <Text style={styles.label}>
                        {t("bankLimits.stepCard", { type: type === "credit" ? t("bankLimits.tabs.credit") : t("bankLimits.tabs.overdraft") })}
                      </Text>
                      <TouchableOpacity
                        style={[styles.selector, !institution && { opacity: 0.5 }]}
                        disabled={!institution}
                        onPress={() => { Haptics.selectionAsync(); setCardPickerOpen(!cardPickerOpen); setBankPickerOpen(false); }}
                      >
                        <Text style={[styles.selectorText, !bank && { color: colors.mutedForeground }]}>
                          {bank || (institution ? (type === "credit" ? t("bankLimits.selectCard") : t("bankLimits.selectAccount")) : t("bankLimits.selectBankFirst"))}
                        </Text>
                        <Feather name={cardPickerOpen ? "chevron-up" : "chevron-down"} size={18} color={colors.mutedForeground} />
                      </TouchableOpacity>
                      {cardPickerOpen && institution && (
                        <View style={styles.bankList}>
                          <ScrollView nestedScrollEnabled keyboardShouldPersistTaps="handled">
                            {cardsForInstitution.length === 0 ? (
                              <View style={styles.bankRow}>
                                <Text style={{ color: colors.mutedForeground, fontSize: 13 }}>
                                  {type === "credit" ? t("bankLimits.noCardForBank.credit") : t("bankLimits.noCardForBank.overdraft")}
                                </Text>
                              </View>
                            ) : (
                              cardsForInstitution.map((c) => (
                                <TouchableOpacity
                                  key={c.id}
                                  style={styles.bankRow}
                                  onPress={() => {
                                    Haptics.selectionAsync();
                                    setBank(c.name);
                                    setSavedCardId(c.id);
                                    setCardPickerOpen(false);
                                  }}
                                >
                                  <Text style={styles.selectorText}>{c.name}</Text>
                                  {(c.cardLast4 || c.accountNumber) && (
                                    <Text style={{ fontSize: 11, color: colors.mutedForeground }}>
                                      {c.cardLast4 ? `**** ${c.cardLast4}` : ""}
                                      {c.accountNumber ? `**** ${c.accountNumber}` : ""}
                                    </Text>
                                  )}
                                </TouchableOpacity>
                              ))
                            )}
                          </ScrollView>
                        </View>
                      )}

                      <TouchableOpacity onPress={() => { setManualEntry(true); setBankPickerOpen(false); setCardPickerOpen(false); }} style={{ marginTop: 6 }}>
                        <Text style={{ color: colors.primary, fontSize: 12 }}>
                          {t("bankLimits.manualEntry")}
                        </Text>
                      </TouchableOpacity>
                    </>
                  );
                })()}

                {/* Kilitli Kategori */}
                <Text style={styles.label}>{t("bankLimits.categoryLabel")}</Text>
                <View style={styles.lockedField}>
                  <Feather name={type === "credit" ? "credit-card" : "dollar-sign"} size={14} color={colors.mutedForeground} />
                  <Text style={styles.lockedFieldText}>
                    {type === "credit" ? t("bankLimits.categoryCredit") : t("bankLimits.categoryOverdraft")}
                  </Text>
                  <Feather name="lock" size={12} color={colors.mutedForeground} style={{ marginLeft: "auto" }} />
                </View>

                <Text style={styles.label}>{t("bankLimits.totalLimitInput")}</Text>
                <TextInput
                  style={styles.input}
                  value={limit}
                  onChangeText={setLimit}
                  keyboardType="decimal-pad"
                  placeholder={t("bankLimits.limitPlaceholder")}
                  placeholderTextColor={colors.mutedForeground}
                />

                <Text style={styles.label}>{t("bankLimits.availableInput")}</Text>
                <TextInput
                  style={styles.input}
                  value={availableLimit}
                  onChangeText={setAvailableLimit}
                  keyboardType="decimal-pad"
                  placeholder={t("bankLimits.availablePlaceholder")}
                  placeholderTextColor={colors.mutedForeground}
                />

                <View style={styles.actions}>
                  <TouchableOpacity style={styles.cancelBtn} onPress={close}>
                    <Text style={styles.cancelBtnText}>{t("bankLimits.cancel")}</Text>
                  </TouchableOpacity>
                  <TouchableOpacity style={styles.saveBtn} onPress={submit}>
                    <Text style={styles.saveBtnText}>{editId ? t("bankLimits.update") : t("bankLimits.save")}</Text>
                  </TouchableOpacity>
                </View>
              </ScrollView>
            </Pressable>
          </Pressable>
        </KeyboardAvoidingView>
      </Modal>

      <Modal
        visible={!!reconcileTarget}
        transparent
        animationType="fade"
        onRequestClose={closeReconcile}
      >
        <KeyboardAvoidingView
          behavior={Platform.OS === "ios" ? "padding" : undefined}
          style={{ flex: 1 }}
        >
          <Pressable style={styles.backdrop} onPress={closeReconcile}>
            <Pressable style={styles.modalCard} onPress={() => {}}>
              <ScrollView
                showsVerticalScrollIndicator={false}
                keyboardShouldPersistTaps="handled"
              >
                <Text style={styles.modalTitle}>{t("bankLimits.reconcileTitle")}</Text>

                {reconcileTarget && (() => {
                  const isCCTarget = reconcileTarget.type === "credit";
                  const limitLabel = isCCTarget ? t("bankLimits.reconcile.cardLimit") : t("bankLimits.reconcile.accountLimit");
                  const cur =
                    typeof reconcileTarget.availableLimit === "number" &&
                    Number.isFinite(reconcileTarget.availableLimit)
                      ? reconcileTarget.availableLimit
                      : reconcileTarget.limit;
                  const parsed = parseFloat(reconcileInput.replace(",", "."));
                  const validInput =
                    Number.isFinite(parsed) &&
                    parsed >= 0 &&
                    parsed <= reconcileTarget.limit + 0.005;
                  const diff = validInput ? cur - parsed : 0;
                  const diffAbs = Math.abs(diff);
                  let diffMsg = "";
                  if (validInput && diffAbs >= 0.005) {
                    if (diff > 0) {
                      diffMsg = t("bankLimits.reconcile.diffExpense", { amount: formatAmount(diffAbs) });
                    } else {
                      diffMsg = t("bankLimits.reconcile.diffIncome", { amount: formatAmount(diffAbs) });
                    }
                  } else if (validInput) {
                    diffMsg = t("bankLimits.reconcile.noChange");
                  }
                  return (
                    <>
                      <Text
                        style={{
                          fontSize: 13,
                          color: colors.mutedForeground,
                          marginBottom: 14,
                          lineHeight: 18,
                        }}
                      >
                        {t("bankLimits.reconcile.instructions", { name: reconcileTarget.institution || reconcileTarget.bank })}
                      </Text>

                      <View style={styles.reconcileSummaryRow}>
                        <Text style={styles.reconcileSummaryLabel}>{limitLabel}</Text>
                        <Text style={styles.reconcileSummaryValue}>
                          {formatAmount(reconcileTarget.limit)}
                        </Text>
                      </View>
                      <View style={styles.reconcileSummaryRow}>
                        <Text style={styles.reconcileSummaryLabel}>
                          {t("bankLimits.reconcile.appAvailable")}
                        </Text>
                        <Text style={styles.reconcileSummaryValue}>
                          {formatAmount(cur)}
                        </Text>
                      </View>

                      <Text style={styles.label}>{t("bankLimits.reconcile.bankAvailable")}</Text>
                      <TextInput
                        value={reconcileInput}
                        onChangeText={setReconcileInput}
                        placeholder={t("bankLimits.reconcile.placeholder")}
                        placeholderTextColor={colors.mutedForeground}
                        keyboardType="decimal-pad"
                        style={{
                          backgroundColor: colors.muted,
                          borderRadius: 12,
                          paddingVertical: 12,
                          paddingHorizontal: 14,
                          fontSize: 16,
                          fontWeight: "600",
                          color: colors.foreground,
                        }}
                      />

                      {!!diffMsg && (
                        <View style={styles.reconcileDiffPill}>
                          <Text style={styles.reconcileDiffText}>{diffMsg}</Text>
                        </View>
                      )}

                      <View
                        style={{
                          flexDirection: "row",
                          gap: 10,
                          marginTop: 18,
                        }}
                      >
                        <TouchableOpacity
                          style={styles.cancelBtn}
                          onPress={closeReconcile}
                        >
                          <Text style={styles.cancelBtnText}>{t("bankLimits.cancel")}</Text>
                        </TouchableOpacity>
                        <TouchableOpacity
                          style={styles.saveBtn}
                          onPress={submitReconcile}
                        >
                          <Text style={styles.saveBtnText}>{t("bankLimits.reconcile.syncBtn")}</Text>
                        </TouchableOpacity>
                      </View>
                    </>
                  );
                })()}
              </ScrollView>
            </Pressable>
          </Pressable>
        </KeyboardAvoidingView>
      </Modal>

    </View>
  );
}
