import { Feather } from "@expo/vector-icons";
import * as Haptics from "expo-haptics";
import { router, useLocalSearchParams } from "expo-router";
import React, { useEffect, useMemo, useState } from "react";
import { useTranslation } from "react-i18next";
import {
  Alert,
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
import { KeyboardAvoidingView } from "react-native-keyboard-controller";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { KeyboardAwareScrollViewCompat } from "@/components/finans/KeyboardAwareScrollViewCompat";

import Calendar from "@/components/finans/Calendar";
import { PaymentMethod, SavedCard, useBudget } from "@/context/finans/BudgetContext";
import { useColors } from "@/hooks/finans/useColors";
import { BANKS, getCategoryIcon } from "@/utils/finans/categories";

type TxType = "expense" | "income";
type ScreenMode = "expense" | "income" | "transfer";

export default function AddTransactionScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const { t } = useTranslation();
  const {
    addTransaction,
    addTransfer,
    expenseCategoryList,
    incomeCategoryList,
    bankLimits,
    addExpenseCategory,
    addIncomeCategory,
    savedCards,
    addSavedCard,
    categoryUsage,
  } = useBudget();
  const params = useLocalSearchParams<{ type?: string }>();

  const [screenMode, setScreenMode] = useState<ScreenMode>("expense");
  const [txType, setTxType] = useState<TxType>("expense");

  const [transferAmount, setTransferAmount] = useState("");
  const [transferFromBank, setTransferFromBank] = useState("");
  const [transferToBank, setTransferToBank] = useState("");
  const [transferNote, setTransferNote] = useState("");
  const [transferDate, setTransferDate] = useState<Date>(new Date());
  const [transferDateModalVisible, setTransferDateModalVisible] = useState(false);
  const [transferFromModalVisible, setTransferFromModalVisible] = useState(false);
  const [transferToModalVisible, setTransferToModalVisible] = useState(false);
  const [transferConfirmVisible, setTransferConfirmVisible] = useState(false);
  const [transferSuccessVisible, setTransferSuccessVisible] = useState(false);

  useEffect(() => {
    if (params.type === "income" || params.type === "expense") {
      setTxType(params.type);
      setScreenMode(params.type);
      setSelectedCategory("");
    }
  }, [params.type]);

  const switchMode = (mode: ScreenMode) => {
    setScreenMode(mode);
    if (mode !== "transfer") {
      setTxType(mode as TxType);
      setSelectedCategory("");
      setPaymentMethod("cash");
      setBank("");
      setBankLimitId(undefined);
      setSavedCardId(undefined);
    }
    Haptics.selectionAsync();
  };

  const isTransferValid =
    parseFloat(transferAmount.replace(",", ".")) > 0 &&
    !!transferFromBank &&
    !!transferToBank &&
    transferFromBank !== transferToBank;

  const handleTransferSubmit = () => {
    if (!isTransferValid) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
      return;
    }
    setTransferConfirmVisible(true);
  };

  const doTransfer = () => {
    const numAmount = parseFloat(transferAmount.replace(",", "."));
    addTransfer({
      amount: numAmount,
      fromBank: transferFromBank,
      toBank: transferToBank,
      note: transferNote.trim(),
      date: transferDate.toISOString(),
    });
    setTransferConfirmVisible(false);
    setTransferAmount("");
    setTransferFromBank("");
    setTransferToBank("");
    setTransferNote("");
    setTransferDate(new Date());
    setTransferSuccessVisible(true);
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
  };

  const [amount, setAmount] = useState("");
  const [selectedCategory, setSelectedCategory] = useState("");
  const [note, setNote] = useState("");
  const [paymentMethod, setPaymentMethod] = useState<PaymentMethod>("cash");
  const [bank, setBank] = useState("");
  const [bankLimitId, setBankLimitId] = useState<string | undefined>(undefined);
  const [bankModalVisible, setBankModalVisible] = useState(false);
  const [savedCardId, setSavedCardId] = useState<string | undefined>(undefined);
  const [transferModalVisible, setTransferModalVisible] = useState(false);
  const [addDemandVisible, setAddDemandVisible] = useState(false);
  const [newDemandName, setNewDemandName] = useState("");
  const [newDemandBank, setNewDemandBank] = useState("");
  const [newDemandIban, setNewDemandIban] = useState("");
  const [installmentMode, setInstallmentMode] = useState<"single" | "installment">("single");
  const [installmentCount, setInstallmentCount] = useState("");
  const [date, setDate] = useState<Date>(new Date());
  const [dateModalVisible, setDateModalVisible] = useState(false);
  const [newCatVisible, setNewCatVisible] = useState(false);
  const [newCatLabel, setNewCatLabel] = useState("");
  const [categorySearch, setCategorySearch] = useState("");

  const topInset = Platform.OS === "web" ? 67 : insets.top;
  const bottomInset = Platform.OS === "web" ? 34 : insets.bottom;

  // Tip değişince arama temizlensin (akıllı sıralama yeni listeyle çalışsın)
  useEffect(() => {
    setCategorySearch("");
  }, [txType]);

  const sourceList = txType === "expense" ? expenseCategoryList : incomeCategoryList;
  const usageMap =
    txType === "expense" ? categoryUsage.expense : categoryUsage.income;

  // 1) Kullanım sayısı (azalan), 2) alfabetik (Türkçe) → akıllı sıralama
  const sortedLabels = useMemo(() => {
    return [...sourceList].sort((a, b) => {
      const ua = usageMap[a] ?? 0;
      const ub = usageMap[b] ?? 0;
      if (ua !== ub) return ub - ua;
      return a.localeCompare(b, "tr");
    });
  }, [sourceList, usageMap]);

  // Türkçe-dostu (büyük/küçük harf) arama
  const normalize = (s: string) => s.toLocaleLowerCase("tr").trim();
  const searchQuery = normalize(categorySearch);

  const filteredLabels = useMemo(() => {
    if (!searchQuery) return sortedLabels;
    return sortedLabels.filter((l) => normalize(l).includes(searchQuery));
  }, [sortedLabels, searchQuery]);

  const categories = filteredLabels.map((label) => ({
    label,
    icon: getCategoryIcon(label),
  }));

  // Aramayla eşleşen yoksa "Yeni Ekle" arama metniyle ön doldurulsun
  const showCreateFromSearch =
    !!searchQuery &&
    filteredLabels.length === 0 &&
    !sortedLabels.some((l) => normalize(l) === searchQuery);

  const handleSubmit = () => {
    const numAmount = parseFloat(amount.replace(",", "."));
    if (!numAmount || numAmount <= 0 || !selectedCategory) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
      return;
    }
    if ((paymentMethod === "card" || paymentMethod === "transfer") && !bank) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
      return;
    }
    const isInstallmentTx =
      txType === "expense" &&
      paymentMethod === "card" &&
      installmentMode === "installment";
    const instCount = parseInt(installmentCount, 10);
    if (isInstallmentTx && (!instCount || instCount < 2)) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
      return;
    }

    const doSave = () => {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      addTransaction({
        type: txType,
        amount: numAmount,
        category: selectedCategory,
        note: note.trim(),
        paymentMethod,
        bank: (paymentMethod === "card" || paymentMethod === "transfer") ? bank : undefined,
        bankLimitId: paymentMethod === "card" ? bankLimitId : undefined,
        savedCardId: paymentMethod === "transfer" ? savedCardId : undefined,
        date: date.toISOString(),
        installmentCount: isInstallmentTx ? instCount : undefined,
      });
      setAmount("");
      setSelectedCategory("");
      setNote("");
      setPaymentMethod("cash");
      setBank("");
      setBankLimitId(undefined);
      setSavedCardId(undefined);
      setInstallmentMode("single");
      setInstallmentCount("");
      setDate(new Date());
      router.navigate("/finans");
    };

    if (txType === "expense" && paymentMethod === "card") {
      let warningTitle = "";
      let warningMsg = "";

      if (!bankLimitId) {
        warningTitle = t("add.limitUndefined");
        warningMsg = t("add.limitUndefinedMsg");
      } else {
        const linkedCard = bankLimits.find((b) => b.id === bankLimitId);
        const avail = linkedCard?.availableLimit;
        if (avail === undefined || avail <= 0 || numAmount > avail) {
          warningTitle = t("add.limitInsufficient");
          if (avail === undefined) {
            warningMsg = t("add.limitNoInfo");
          } else if (avail <= 0) {
            warningMsg = t("add.limitExhausted");
          } else {
            warningMsg = t("add.limitExceeded", { amount: avail.toLocaleString(undefined, { minimumFractionDigits: 2 }) });
          }
        }
      }

      if (warningTitle) {
        if (Platform.OS === "web") {
          window.alert(`⚠️ ${warningTitle}\n\n${warningMsg}`);
        } else {
          Alert.alert(warningTitle, warningMsg, [
            { text: t("common.back"), style: "cancel" },
          ]);
        }
        return;
      }
    }

    doSave();
  };

  const isValid =
    parseFloat(amount.replace(",", ".")) > 0 &&
    !!selectedCategory &&
    (paymentMethod === "cash" || !!bank) &&
    (
      !(txType === "expense" && paymentMethod === "card" && installmentMode === "installment") ||
      parseInt(installmentCount, 10) >= 2
    );

  const accentColor = txType === "income" ? colors.income : colors.expense;
  const accentBg = txType === "income" ? colors.incomeBg : colors.expenseBg;

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: colors.background,
    },
    header: {
      paddingTop: topInset + 12,
      paddingHorizontal: 20,
      paddingBottom: 20,
      backgroundColor: colors.navy,
      borderBottomLeftRadius: 24,
      borderBottomRightRadius: 24,
    },
    headerTitle: {
      fontSize: 22,
      fontWeight: "800" as const,
      color: "#FFFFFF",
      marginBottom: 16,
    },
    typeRow: {
      flexDirection: "row",
      gap: 10,
    },
    typeBtn: {
      flex: 1,
      paddingVertical: 10,
      borderRadius: 12,
      alignItems: "center",
      flexDirection: "row",
      justifyContent: "center",
      gap: 6,
    },
    typeBtnText: {
      fontSize: 15,
      fontWeight: "700" as const,
    },
    scroll: {
      flex: 1,
      padding: 20,
    },
    label: {
      fontSize: 13,
      fontWeight: "600" as const,
      color: colors.mutedForeground,
      marginBottom: 10,
      marginTop: 20,
      letterSpacing: 0.3,
    },
    amountContainer: {
      flexDirection: "row",
      alignItems: "center",
      backgroundColor: colors.card,
      borderRadius: colors.radius,
      paddingHorizontal: 16,
      shadowColor: "#000",
      shadowOffset: { width: 0, height: 2 },
      shadowOpacity: 0.06,
      shadowRadius: 8,
      elevation: 2,
    },
    currency: {
      fontSize: 22,
      fontWeight: "700" as const,
      color: accentColor,
      marginRight: 4,
    },
    amountInput: {
      flex: 1,
      fontSize: 28,
      fontWeight: "700" as const,
      color: colors.foreground,
      paddingVertical: 14,
    },
    categorySearchWrap: {
      flexDirection: "row",
      alignItems: "center",
      backgroundColor: colors.muted,
      borderRadius: 12,
      paddingHorizontal: 12,
      paddingVertical: Platform.OS === "ios" ? 10 : 6,
      marginBottom: 10,
    },
    categorySearchInput: {
      flex: 1,
      fontSize: 14,
      color: colors.foreground,
      paddingVertical: 0,
    },
    categoryGrid: {
      flexDirection: "row",
      flexWrap: "wrap" as const,
      gap: 8,
    },
    categoryChip: {
      flexDirection: "row",
      alignItems: "center",
      paddingHorizontal: 14,
      paddingVertical: 10,
      borderRadius: 24,
      gap: 6,
      borderWidth: 1.5,
    },
    categoryChipText: {
      fontSize: 13,
      fontWeight: "600" as const,
    },
    paymentRow: {
      flexDirection: "row",
      flexWrap: "wrap" as const,
      gap: 8,
    },
    paymentBtn: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "center",
      gap: 7,
      paddingVertical: 13,
      paddingHorizontal: 12,
      borderRadius: colors.radius,
      borderWidth: 1.5,
      minWidth: 100,
      flex: 1,
    },
    paymentBtnText: {
      fontSize: 13,
      fontWeight: "600" as const,
    },
    bankSelector: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      backgroundColor: colors.card,
      borderRadius: colors.radius,
      paddingHorizontal: 16,
      paddingVertical: 14,
      shadowColor: "#000",
      shadowOffset: { width: 0, height: 2 },
      shadowOpacity: 0.06,
      shadowRadius: 8,
      elevation: 2,
    },
    bankSelectorText: {
      fontSize: 15,
      fontWeight: "500" as const,
    },
    noteInput: {
      backgroundColor: colors.card,
      borderRadius: colors.radius,
      paddingHorizontal: 16,
      paddingVertical: 14,
      fontSize: 15,
      color: colors.foreground,
      shadowColor: "#000",
      shadowOffset: { width: 0, height: 2 },
      shadowOpacity: 0.06,
      shadowRadius: 8,
      elevation: 2,
    },
    actionRow: {
      flexDirection: "row",
      gap: 10,
      marginTop: 28,
      marginBottom: bottomInset + 80,
    },
    submitBtn: {
      flex: 1,
      backgroundColor: isValid ? colors.primary : colors.muted,
      borderRadius: colors.radius,
      paddingVertical: 16,
      alignItems: "center",
    },
    submitBtnText: {
      fontSize: 17,
      fontWeight: "700" as const,
      color: isValid ? "#FFFFFF" : colors.mutedForeground,
    },
    cancelBtn: {
      flex: 1,
      backgroundColor: colors.muted,
      borderRadius: colors.radius,
      paddingVertical: 16,
      alignItems: "center",
      borderWidth: 1,
      borderColor: colors.border,
    },
    cancelBtnText: {
      fontSize: 17,
      fontWeight: "700" as const,
      color: colors.foreground,
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
      paddingBottom: insets.bottom + 16,
      maxHeight: "75%",
    },
    modalHandle: {
      width: 40,
      height: 4,
      backgroundColor: colors.border,
      borderRadius: 2,
      alignSelf: "center" as const,
      marginTop: 10,
      marginBottom: 6,
    },
    modalTitle: {
      fontSize: 17,
      fontWeight: "700" as const,
      color: colors.foreground,
      textAlign: "center" as const,
      paddingVertical: 14,
      borderBottomWidth: 1,
      borderBottomColor: colors.border,
    },
    bankItem: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      paddingVertical: 16,
      paddingHorizontal: 20,
      borderBottomWidth: StyleSheet.hairlineWidth,
      borderBottomColor: colors.border,
    },
    bankItemText: {
      fontSize: 15,
      color: colors.foreground,
    },
    instRow: {
      flexDirection: "row",
      gap: 10,
    },
    instBtn: {
      flex: 1,
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "center",
      gap: 6,
      paddingVertical: 12,
      borderRadius: 12,
      borderWidth: 1.5,
      borderColor: colors.border,
      backgroundColor: colors.card,
    },
    instBtnText: {
      fontSize: 14,
      fontWeight: "600" as const,
    },
    instCountInput: {
      backgroundColor: colors.card,
      borderRadius: 12,
      paddingVertical: 13,
      paddingHorizontal: 16,
      color: colors.foreground,
      fontSize: 16,
      borderWidth: 1,
      borderColor: colors.border,
    },
    instPreview: {
      flexDirection: "row",
      alignItems: "flex-start",
      gap: 8,
      backgroundColor: colors.primary + "14",
      borderRadius: 10,
      padding: 10,
      marginTop: 8,
    },
    instPreviewText: {
      flex: 1,
      fontSize: 12,
      color: colors.primary,
      fontWeight: "600" as const,
      lineHeight: 17,
    },
  });

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.headerTitle}>{t("add.title")}</Text>
        <View style={styles.typeRow}>
          <TouchableOpacity
            style={[
              styles.typeBtn,
              {
                backgroundColor:
                  screenMode === "expense"
                    ? colors.expense
                    : "rgba(255,255,255,0.12)",
              },
            ]}
            onPress={() => switchMode("expense")}
          >
            <Feather
              name="arrow-up-right"
              size={16}
              color={screenMode === "expense" ? "#fff" : "rgba(255,255,255,0.6)"}
            />
            <Text
              style={[
                styles.typeBtnText,
                {
                  color:
                    screenMode === "expense" ? "#fff" : "rgba(255,255,255,0.6)",
                },
              ]}
            >
              {t("add.expenseTab")}
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[
              styles.typeBtn,
              {
                backgroundColor:
                  screenMode === "income"
                    ? colors.income
                    : "rgba(255,255,255,0.12)",
              },
            ]}
            onPress={() => switchMode("income")}
          >
            <Feather
              name="arrow-down-left"
              size={16}
              color={screenMode === "income" ? "#fff" : "rgba(255,255,255,0.6)"}
            />
            <Text
              style={[
                styles.typeBtnText,
                {
                  color:
                    screenMode === "income" ? "#fff" : "rgba(255,255,255,0.6)",
                },
              ]}
            >
              {t("add.incomeTab")}
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[
              styles.typeBtn,
              {
                backgroundColor:
                  screenMode === "transfer"
                    ? "#7C5CBF"
                    : "rgba(255,255,255,0.12)",
              },
            ]}
            onPress={() => switchMode("transfer")}
          >
            <Feather
              name="shuffle"
              size={16}
              color={screenMode === "transfer" ? "#fff" : "rgba(255,255,255,0.6)"}
            />
            <Text
              style={[
                styles.typeBtnText,
                {
                  color:
                    screenMode === "transfer" ? "#fff" : "rgba(255,255,255,0.6)",
                },
              ]}
            >
              Transfer
            </Text>
          </TouchableOpacity>
        </View>
      </View>

      {screenMode === "transfer" ? (
        <KeyboardAwareScrollViewCompat
          style={styles.scroll}
          showsVerticalScrollIndicator={false}
          bottomOffset={20}
          keyboardShouldPersistTaps="handled"
        >
          <Text style={styles.label}>TUTAR</Text>
          <View style={[styles.amountContainer, { borderWidth: 2, borderColor: "#7C5CBF22" }]}>
            <Text style={[styles.currency, { color: "#7C5CBF" }]}>₺</Text>
            <TextInput
              style={styles.amountInput}
              value={transferAmount}
              onChangeText={setTransferAmount}
              keyboardType="decimal-pad"
              placeholder="0,00"
              placeholderTextColor={colors.mutedForeground}
            />
          </View>

          <Text style={styles.label}>GÖNDEREN BANKA</Text>
          <TouchableOpacity
            style={styles.bankSelector}
            onPress={() => setTransferFromModalVisible(true)}
          >
            <View style={{ flexDirection: "row", alignItems: "center", gap: 10 }}>
              <Feather name="log-out" size={15} color={transferFromBank ? "#7C5CBF" : colors.mutedForeground} />
              <Text style={[styles.bankSelectorText, { color: transferFromBank ? colors.foreground : colors.mutedForeground }]}>
                {transferFromBank || "Gönderen hesabı seçin"}
              </Text>
            </View>
            <Feather name="chevron-down" size={18} color={colors.mutedForeground} />
          </TouchableOpacity>

          <Text style={styles.label}>ALICI BANKA</Text>
          <TouchableOpacity
            style={styles.bankSelector}
            onPress={() => setTransferToModalVisible(true)}
          >
            <View style={{ flexDirection: "row", alignItems: "center", gap: 10 }}>
              <Feather name="log-in" size={15} color={transferToBank ? "#7C5CBF" : colors.mutedForeground} />
              <Text style={[styles.bankSelectorText, { color: transferToBank ? colors.foreground : colors.mutedForeground }]}>
                {transferToBank || "Alıcı hesabı seçin"}
              </Text>
            </View>
            <Feather name="chevron-down" size={18} color={colors.mutedForeground} />
          </TouchableOpacity>

          {transferFromBank && transferToBank && transferFromBank === transferToBank && (
            <View style={{
              flexDirection: "row",
              alignItems: "center",
              gap: 8,
              backgroundColor: colors.expense + "18",
              borderRadius: 10,
              padding: 10,
              marginTop: 8,
            }}>
              <Feather name="alert-circle" size={14} color={colors.expense} />
              <Text style={{ fontSize: 12, color: colors.expense, fontWeight: "600", flex: 1 }}>
                Gönderen ve alıcı banka aynı olamaz.
              </Text>
            </View>
          )}

          <Text style={styles.label}>GÖNDERİM NOTU (isteğe bağlı)</Text>
          <TextInput
            style={[styles.noteInput, { minHeight: 56 }]}
            value={transferNote}
            onChangeText={setTransferNote}
            placeholder="Açıklama ekleyin..."
            placeholderTextColor={colors.mutedForeground}
            multiline
            numberOfLines={2}
          />

          <Text style={styles.label}>İŞLEM TARİHİ</Text>
          <TouchableOpacity
            style={styles.bankSelector}
            onPress={() => setTransferDateModalVisible(true)}
          >
            <View style={{ flexDirection: "row", alignItems: "center", gap: 10 }}>
              <Feather name="calendar" size={16} color={colors.mutedForeground} />
              <Text style={[styles.bankSelectorText, { color: colors.foreground }]}>
                {transferDate.toLocaleDateString("tr-TR", { day: "2-digit", month: "long", year: "numeric" })}
              </Text>
            </View>
            <Feather name="chevron-down" size={18} color={colors.mutedForeground} />
          </TouchableOpacity>

          <View style={{ backgroundColor: "#7C5CBF14", borderRadius: 12, padding: 12, marginTop: 20, flexDirection: "row", gap: 8, alignItems: "flex-start" }}>
            <Feather name="info" size={14} color="#7C5CBF" style={{ marginTop: 1 }} />
            <Text style={{ fontSize: 12, color: "#7C5CBF", fontWeight: "600", flex: 1, lineHeight: 18 }}>
              Hesaplar arası transferler gelir ve gider toplamlarınızı etkilemez.
            </Text>
          </View>

          <View style={styles.actionRow}>
            <TouchableOpacity
              style={styles.cancelBtn}
              onPress={() => {
                Haptics.selectionAsync();
                setTransferAmount("");
                setTransferFromBank("");
                setTransferToBank("");
                setTransferNote("");
                setTransferDate(new Date());
                router.navigate("/finans");
              }}
            >
              <Text style={styles.cancelBtnText}>{t("common.cancel")}</Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.submitBtn, { backgroundColor: isTransferValid ? "#7C5CBF" : colors.muted }]}
              onPress={handleTransferSubmit}
              disabled={!isTransferValid}
            >
              <Text style={[styles.submitBtnText, { color: isTransferValid ? "#FFFFFF" : colors.mutedForeground }]}>
                Transfer Et
              </Text>
            </TouchableOpacity>
          </View>
        </KeyboardAwareScrollViewCompat>
      ) : (
      <KeyboardAwareScrollViewCompat
        style={styles.scroll}
        showsVerticalScrollIndicator={false}
        bottomOffset={20}
        keyboardShouldPersistTaps="handled"
      >
        <Text style={styles.label}>{t("add.amount")}</Text>
        <View style={styles.amountContainer}>
          <Text style={styles.currency}>₺</Text>
          <TextInput
            style={styles.amountInput}
            value={amount}
            onChangeText={setAmount}
            keyboardType="decimal-pad"
            placeholder="0,00"
            placeholderTextColor={colors.mutedForeground}
          />
        </View>

        <Text style={styles.label}>{t("add.category")}</Text>
        {sortedLabels.length >= 6 && (
          <View style={styles.categorySearchWrap}>
            <Feather
              name="search"
              size={14}
              color={colors.mutedForeground}
              style={{ marginRight: 6 }}
            />
            <TextInput
              value={categorySearch}
              onChangeText={setCategorySearch}
              placeholder={t("add.categorySearch")}
              placeholderTextColor={colors.mutedForeground}
              style={styles.categorySearchInput}
              autoCorrect={false}
              autoCapitalize="none"
              returnKeyType="search"
            />
            {!!categorySearch && (
              <TouchableOpacity
                hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
                onPress={() => setCategorySearch("")}
              >
                <Feather name="x" size={14} color={colors.mutedForeground} />
              </TouchableOpacity>
            )}
          </View>
        )}
        <View style={styles.categoryGrid}>
          {categories.map((cat) => {
            const isSelected = selectedCategory === cat.label;
            return (
              <TouchableOpacity
                key={cat.label}
                style={[
                  styles.categoryChip,
                  {
                    backgroundColor: isSelected ? accentBg : colors.card,
                    borderColor: isSelected ? accentColor : colors.border,
                  },
                ]}
                onPress={() => {
                  setSelectedCategory(cat.label);
                  Haptics.selectionAsync();
                }}
              >
                <Feather
                  name={cat.icon as any}
                  size={14}
                  color={isSelected ? accentColor : colors.mutedForeground}
                />
                <Text
                  style={[
                    styles.categoryChipText,
                    {
                      color: isSelected ? accentColor : colors.foreground,
                    },
                  ]}
                >
                  {cat.label}
                </Text>
              </TouchableOpacity>
            );
          })}
          <TouchableOpacity
            style={[
              styles.categoryChip,
              {
                backgroundColor: colors.card,
                borderColor: colors.primary,
                borderStyle: "dashed",
              },
            ]}
            onPress={() => {
              // Aramayla eşleşen yoksa arama metnini ön doldurarak modalı aç
              setNewCatLabel(showCreateFromSearch ? categorySearch.trim() : "");
              setNewCatVisible(true);
              Haptics.selectionAsync();
            }}
          >
            <Feather name="plus" size={14} color={colors.primary} />
            <Text style={[styles.categoryChipText, { color: colors.primary }]}>
              {showCreateFromSearch
                ? `"${categorySearch.trim()}" Ekle`
                : t("add.addNew")}
            </Text>
          </TouchableOpacity>
        </View>

        <Text style={styles.label}>{t("add.paymentMethod")}</Text>
        <View style={styles.paymentRow}>
          <TouchableOpacity
            style={[
              styles.paymentBtn,
              {
                backgroundColor:
                  paymentMethod === "cash" ? accentBg : colors.card,
                borderColor:
                  paymentMethod === "cash" ? accentColor : colors.border,
              },
            ]}
            onPress={() => {
              setPaymentMethod("cash");
              setBank("");
              setBankLimitId(undefined);
              Haptics.selectionAsync();
            }}
          >
            <Feather
              name="dollar-sign"
              size={16}
              color={
                paymentMethod === "cash" ? accentColor : colors.mutedForeground
              }
            />
            <Text
              style={[
                styles.paymentBtnText,
                {
                  color:
                    paymentMethod === "cash"
                      ? accentColor
                      : colors.foreground,
                },
              ]}
            >
              Nakit
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[
              styles.paymentBtn,
              {
                backgroundColor:
                  paymentMethod === "card" ? accentBg : colors.card,
                borderColor:
                  paymentMethod === "card" ? accentColor : colors.border,
              },
            ]}
            onPress={() => {
              setPaymentMethod("card");
              setBank("");
              setSavedCardId(undefined);
              Haptics.selectionAsync();
            }}
          >
            <Feather
              name="credit-card"
              size={16}
              color={
                paymentMethod === "card" ? accentColor : colors.mutedForeground
              }
            />
            <Text
              style={[
                styles.paymentBtnText,
                {
                  color:
                    paymentMethod === "card"
                      ? accentColor
                      : colors.foreground,
                },
              ]}
            >
              Kredi Kartı
            </Text>
          </TouchableOpacity>

          <TouchableOpacity
            style={[
              styles.paymentBtn,
              {
                backgroundColor:
                  paymentMethod === "transfer" ? accentBg : colors.card,
                borderColor:
                  paymentMethod === "transfer" ? accentColor : colors.border,
              },
            ]}
            onPress={() => {
              setPaymentMethod("transfer");
              setBank("");
              setBankLimitId(undefined);
              Haptics.selectionAsync();
            }}
          >
            <Feather
              name="send"
              size={16}
              color={
                paymentMethod === "transfer" ? accentColor : colors.mutedForeground
              }
            />
            <Text
              style={[
                styles.paymentBtnText,
                {
                  color:
                    paymentMethod === "transfer"
                      ? accentColor
                      : colors.foreground,
                },
              ]}
            >
              Havale/EFT
            </Text>
          </TouchableOpacity>
        </View>

        {paymentMethod === "transfer" && (
          <>
            <Text style={styles.label}>{t("add.account")}</Text>
            <TouchableOpacity
              style={styles.bankSelector}
              onPress={() => setTransferModalVisible(true)}
            >
              <Text
                style={[
                  styles.bankSelectorText,
                  {
                    color: bank ? colors.foreground : colors.mutedForeground,
                  },
                ]}
              >
                {bank || t("add.selectSavingsAccount")}
              </Text>
              <Feather
                name="chevron-down"
                size={18}
                color={colors.mutedForeground}
              />
            </TouchableOpacity>
          </>
        )}

        {paymentMethod === "card" && (
          <>
            <Text style={styles.label}>{t("add.bank")}</Text>
            <TouchableOpacity
              style={styles.bankSelector}
              onPress={() => setBankModalVisible(true)}
            >
              <Text
                style={[
                  styles.bankSelectorText,
                  {
                    color: bank ? colors.foreground : colors.mutedForeground,
                  },
                ]}
              >
                {bank || t("add.selectBank")}
              </Text>
              <Feather
                name="chevron-down"
                size={18}
                color={colors.mutedForeground}
              />
            </TouchableOpacity>

            {txType === "expense" && (
              <>
                <Text style={styles.label}>{t("add.paymentType")}</Text>
                <View style={styles.instRow}>
                  <TouchableOpacity
                    style={[
                      styles.instBtn,
                      installmentMode === "single" && { backgroundColor: accentBg, borderColor: accentColor },
                    ]}
                    onPress={() => { setInstallmentMode("single"); setInstallmentCount(""); Haptics.selectionAsync(); }}
                  >
                    <Feather name="zap" size={15} color={installmentMode === "single" ? accentColor : colors.mutedForeground} />
                    <Text style={[styles.instBtnText, { color: installmentMode === "single" ? accentColor : colors.foreground }]}>
                      {t("add.singlePayment")}
                    </Text>
                  </TouchableOpacity>
                  <TouchableOpacity
                    style={[
                      styles.instBtn,
                      installmentMode === "installment" && { backgroundColor: accentBg, borderColor: accentColor },
                    ]}
                    onPress={() => { setInstallmentMode("installment"); Haptics.selectionAsync(); }}
                  >
                    <Feather name="layers" size={15} color={installmentMode === "installment" ? accentColor : colors.mutedForeground} />
                    <Text style={[styles.instBtnText, { color: installmentMode === "installment" ? accentColor : colors.foreground }]}>
                      {t("add.installment")}
                    </Text>
                  </TouchableOpacity>
                </View>

                {installmentMode === "installment" && (
                  <>
                    <Text style={styles.label}>{t("add.installmentCount")}</Text>
                    <TextInput
                      style={styles.instCountInput}
                      value={installmentCount}
                      onChangeText={setInstallmentCount}
                      placeholder={t("add.installmentCountPlaceholderFull")}
                      placeholderTextColor={colors.mutedForeground}
                      keyboardType="number-pad"
                    />
                    {!!installmentCount && parseInt(installmentCount, 10) >= 2 && !!amount && (
                      <View style={styles.instPreview}>
                        <Feather name="info" size={13} color={colors.primary} />
                        <Text style={styles.instPreviewText}>
                          {parseInt(installmentCount, 10)} × {
                            isFinite(parseFloat(amount.replace(",", ".")))
                              ? (parseFloat(amount.replace(",", ".")) / parseInt(installmentCount, 10)).toLocaleString("tr-TR", { minimumFractionDigits: 2, maximumFractionDigits: 2 })
                              : "0,00"
                          } ₺  •  {date.toLocaleDateString("tr-TR", { month: "long" })}'dan itibaren {parseInt(installmentCount, 10)} aya kırılımlara eklenir
                        </Text>
                      </View>
                    )}
                  </>
                )}
              </>
            )}
          </>
        )}

        <Text style={styles.label}>{t("add.date")}</Text>
        <TouchableOpacity
          style={styles.bankSelector}
          onPress={() => setDateModalVisible(true)}
        >
          <View style={{ flexDirection: "row", alignItems: "center", gap: 10 }}>
            <Feather name="calendar" size={16} color={colors.mutedForeground} />
            <Text style={[styles.bankSelectorText, { color: colors.foreground }]}>
              {date.toLocaleDateString("tr-TR", {
                day: "2-digit",
                month: "long",
                year: "numeric",
              })}
            </Text>
          </View>
          <Feather name="chevron-down" size={18} color={colors.mutedForeground} />
        </TouchableOpacity>

        <Text style={styles.label}>{t("add.noteOptional")}</Text>
        <TextInput
          style={styles.noteInput}
          value={note}
          onChangeText={setNote}
          placeholder={t("add.shortNote")}
          placeholderTextColor={colors.mutedForeground}
          multiline
          numberOfLines={2}
        />

        <View style={styles.actionRow}>
          <TouchableOpacity
            style={styles.cancelBtn}
            onPress={() => {
              Haptics.selectionAsync();
              setAmount("");
              setSelectedCategory("");
              setNote("");
              setPaymentMethod("cash");
              setBank("");
              setBankLimitId(undefined);
              setSavedCardId(undefined);
              setDate(new Date());
              router.navigate("/finans");
            }}
          >
            <Text style={styles.cancelBtnText}>{t("common.cancel")}</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.submitBtn}
            onPress={handleSubmit}
            disabled={!isValid}
          >
            <Text style={styles.submitBtnText}>{t("common.save")}</Text>
          </TouchableOpacity>
        </View>
      </KeyboardAwareScrollViewCompat>
      )}

      {/* Transfer — Gönderen Banka Seçimi */}
      <Modal
        visible={transferFromModalVisible}
        transparent
        animationType="slide"
        onRequestClose={() => setTransferFromModalVisible(false)}
      >
        <Pressable style={styles.modalBackdrop} onPress={() => setTransferFromModalVisible(false)}>
          <Pressable style={styles.modalContent} onPress={() => {}}>
            <View style={styles.modalHandle} />
            <Text style={styles.modalTitle}>Gönderen Banka</Text>
            <ScrollView keyboardShouldPersistTaps="handled">
              {savedCards.filter((c) => c.type === "demand").length > 0 && (
                <>
                  <Text style={{ fontSize: 12, fontWeight: "700", color: colors.mutedForeground, marginTop: 8, marginBottom: 6, paddingHorizontal: 20, textTransform: "uppercase", letterSpacing: 0.5 }}>
                    Kayıtlı Hesaplar
                  </Text>
                  {savedCards.filter((c) => c.type === "demand").map((c) => (
                    <TouchableOpacity
                      key={c.id}
                      style={[styles.bankItem, transferFromBank === (c.name || c.bank) && { backgroundColor: "#7C5CBF12" }]}
                      onPress={() => { setTransferFromBank(c.name || c.bank); setTransferFromModalVisible(false); Haptics.selectionAsync(); }}
                    >
                      <View style={{ flexDirection: "row", alignItems: "center", flex: 1, gap: 10 }}>
                        <View style={{ width: 32, height: 32, borderRadius: 8, backgroundColor: "#7C5CBF1A", alignItems: "center", justifyContent: "center" }}>
                          <Feather name="server" size={14} color="#7C5CBF" />
                        </View>
                        <View style={{ flex: 1 }}>
                          <Text style={styles.bankItemText}>{c.name || c.bank}</Text>
                          {c.name ? <Text style={{ fontSize: 11, color: colors.mutedForeground }}>{c.bank}</Text> : null}
                        </View>
                      </View>
                      {transferFromBank === (c.name || c.bank) && <Feather name="check" size={18} color="#7C5CBF" />}
                    </TouchableOpacity>
                  ))}
                  <Text style={{ fontSize: 12, fontWeight: "700", color: colors.mutedForeground, marginTop: 16, marginBottom: 6, paddingHorizontal: 20, textTransform: "uppercase", letterSpacing: 0.5 }}>
                    Diğer Bankalar
                  </Text>
                </>
              )}
              {BANKS.map((b) => (
                <TouchableOpacity
                  key={b}
                  style={[styles.bankItem, transferFromBank === b && { backgroundColor: "#7C5CBF12" }]}
                  onPress={() => { setTransferFromBank(b); setTransferFromModalVisible(false); Haptics.selectionAsync(); }}
                >
                  <Text style={styles.bankItemText}>{b}</Text>
                  {transferFromBank === b && <Feather name="check" size={18} color="#7C5CBF" />}
                </TouchableOpacity>
              ))}
            </ScrollView>
          </Pressable>
        </Pressable>
      </Modal>

      {/* Transfer — Alıcı Banka Seçimi */}
      <Modal
        visible={transferToModalVisible}
        transparent
        animationType="slide"
        onRequestClose={() => setTransferToModalVisible(false)}
      >
        <Pressable style={styles.modalBackdrop} onPress={() => setTransferToModalVisible(false)}>
          <Pressable style={styles.modalContent} onPress={() => {}}>
            <View style={styles.modalHandle} />
            <Text style={styles.modalTitle}>Alıcı Banka</Text>
            <ScrollView keyboardShouldPersistTaps="handled">
              {savedCards.filter((c) => c.type === "demand").length > 0 && (
                <>
                  <Text style={{ fontSize: 12, fontWeight: "700", color: colors.mutedForeground, marginTop: 8, marginBottom: 6, paddingHorizontal: 20, textTransform: "uppercase", letterSpacing: 0.5 }}>
                    Kayıtlı Hesaplar
                  </Text>
                  {savedCards.filter((c) => c.type === "demand").map((c) => (
                    <TouchableOpacity
                      key={c.id}
                      style={[styles.bankItem, transferToBank === (c.name || c.bank) && { backgroundColor: "#7C5CBF12" }]}
                      onPress={() => { setTransferToBank(c.name || c.bank); setTransferToModalVisible(false); Haptics.selectionAsync(); }}
                    >
                      <View style={{ flexDirection: "row", alignItems: "center", flex: 1, gap: 10 }}>
                        <View style={{ width: 32, height: 32, borderRadius: 8, backgroundColor: "#7C5CBF1A", alignItems: "center", justifyContent: "center" }}>
                          <Feather name="server" size={14} color="#7C5CBF" />
                        </View>
                        <View style={{ flex: 1 }}>
                          <Text style={styles.bankItemText}>{c.name || c.bank}</Text>
                          {c.name ? <Text style={{ fontSize: 11, color: colors.mutedForeground }}>{c.bank}</Text> : null}
                        </View>
                      </View>
                      {transferToBank === (c.name || c.bank) && <Feather name="check" size={18} color="#7C5CBF" />}
                    </TouchableOpacity>
                  ))}
                  <Text style={{ fontSize: 12, fontWeight: "700", color: colors.mutedForeground, marginTop: 16, marginBottom: 6, paddingHorizontal: 20, textTransform: "uppercase", letterSpacing: 0.5 }}>
                    Diğer Bankalar
                  </Text>
                </>
              )}
              {BANKS.map((b) => (
                <TouchableOpacity
                  key={b}
                  style={[styles.bankItem, transferToBank === b && { backgroundColor: "#7C5CBF12" }]}
                  onPress={() => { setTransferToBank(b); setTransferToModalVisible(false); Haptics.selectionAsync(); }}
                >
                  <Text style={styles.bankItemText}>{b}</Text>
                  {transferToBank === b && <Feather name="check" size={18} color="#7C5CBF" />}
                </TouchableOpacity>
              ))}
            </ScrollView>
          </Pressable>
        </Pressable>
      </Modal>

      {/* Transfer — Tarih Seçimi */}
      <Modal
        visible={transferDateModalVisible}
        transparent
        animationType="fade"
        onRequestClose={() => setTransferDateModalVisible(false)}
      >
        <Pressable style={styles.modalBackdrop} onPress={() => setTransferDateModalVisible(false)}>
          <Pressable style={[styles.modalContent, { padding: 16, borderRadius: 24, marginHorizontal: 20, marginBottom: 0, alignSelf: "center", width: "90%" }]} onPress={() => {}}>
            <Calendar value={transferDate} onChange={(d) => { setTransferDate(d); setTransferDateModalVisible(false); }} />
          </Pressable>
        </Pressable>
      </Modal>

      {/* Transfer — Onay Modali */}
      <Modal
        visible={transferConfirmVisible}
        transparent
        animationType="fade"
        onRequestClose={() => setTransferConfirmVisible(false)}
      >
        <Pressable
          style={{ flex: 1, backgroundColor: "rgba(0,0,0,0.55)", justifyContent: "center", paddingHorizontal: 24 }}
          onPress={() => setTransferConfirmVisible(false)}
        >
          <Pressable
            style={{ backgroundColor: colors.card, borderRadius: 24, padding: 24, shadowColor: "#000", shadowOpacity: 0.3, shadowRadius: 20, elevation: 10 }}
            onPress={() => {}}
          >
            <View style={{ alignItems: "center", marginBottom: 20 }}>
              <View style={{ width: 60, height: 60, borderRadius: 30, backgroundColor: "#7C5CBF20", alignItems: "center", justifyContent: "center", marginBottom: 12 }}>
                <Feather name="shuffle" size={26} color="#7C5CBF" />
              </View>
              <Text style={{ fontSize: 18, fontWeight: "800", color: colors.foreground, textAlign: "center" }}>
                Transfer Onayı
              </Text>
            </View>

            <View style={{ backgroundColor: colors.background, borderRadius: 14, padding: 16, marginBottom: 16 }}>
              <View style={{ flexDirection: "row", alignItems: "center", justifyContent: "space-between", marginBottom: 12 }}>
                <Text style={{ fontSize: 13, color: colors.mutedForeground, fontWeight: "600" }}>TUTAR</Text>
                <Text style={{ fontSize: 18, fontWeight: "800", color: "#7C5CBF" }}>
                  ₺{parseFloat(transferAmount.replace(",", ".") || "0").toLocaleString("tr-TR", { minimumFractionDigits: 2 })}
                </Text>
              </View>
              <View style={{ borderTopWidth: 1, borderTopColor: colors.border, paddingTop: 12 }}>
                <View style={{ flexDirection: "row", alignItems: "center", gap: 8, marginBottom: 8 }}>
                  <Feather name="log-out" size={14} color={colors.mutedForeground} />
                  <Text style={{ fontSize: 13, color: colors.mutedForeground }}>Gönderen:</Text>
                  <Text style={{ fontSize: 13, fontWeight: "700", color: colors.foreground, flex: 1 }} numberOfLines={1}>{transferFromBank}</Text>
                </View>
                <View style={{ flexDirection: "row", alignItems: "center", gap: 8 }}>
                  <Feather name="log-in" size={14} color={colors.mutedForeground} />
                  <Text style={{ fontSize: 13, color: colors.mutedForeground }}>Alıcı:</Text>
                  <Text style={{ fontSize: 13, fontWeight: "700", color: colors.foreground, flex: 1 }} numberOfLines={1}>{transferToBank}</Text>
                </View>
                {!!transferNote && (
                  <View style={{ flexDirection: "row", alignItems: "center", gap: 8, marginTop: 8 }}>
                    <Feather name="file-text" size={14} color={colors.mutedForeground} />
                    <Text style={{ fontSize: 12, color: colors.mutedForeground, flex: 1 }} numberOfLines={2}>{transferNote}</Text>
                  </View>
                )}
              </View>
            </View>

            <View style={{ backgroundColor: "#7C5CBF12", borderRadius: 10, padding: 10, flexDirection: "row", gap: 8, alignItems: "flex-start", marginBottom: 20 }}>
              <Feather name="info" size={13} color="#7C5CBF" style={{ marginTop: 1 }} />
              <Text style={{ fontSize: 12, color: "#7C5CBF", fontWeight: "600", flex: 1, lineHeight: 17 }}>
                Bu transfer gelir ve gider toplamlarınızı etkilemez.
              </Text>
            </View>

            <View style={{ flexDirection: "row", gap: 10 }}>
              <TouchableOpacity
                style={{ flex: 1, backgroundColor: colors.muted, borderRadius: colors.radius, paddingVertical: 14, alignItems: "center", borderWidth: 1, borderColor: colors.border }}
                onPress={() => setTransferConfirmVisible(false)}
              >
                <Text style={{ fontSize: 15, fontWeight: "700", color: colors.foreground }}>İptal</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={{ flex: 1, backgroundColor: "#7C5CBF", borderRadius: colors.radius, paddingVertical: 14, alignItems: "center" }}
                onPress={doTransfer}
              >
                <Text style={{ fontSize: 15, fontWeight: "700", color: "#FFFFFF" }}>Onayla</Text>
              </TouchableOpacity>
            </View>
          </Pressable>
        </Pressable>
      </Modal>

      {/* Transfer — Başarı Bildirimi */}
      <Modal
        visible={transferSuccessVisible}
        transparent
        animationType="fade"
        onRequestClose={() => { setTransferSuccessVisible(false); router.navigate("/finans"); }}
      >
        <Pressable
          style={{ flex: 1, backgroundColor: "rgba(0,0,0,0.55)", justifyContent: "center", paddingHorizontal: 24 }}
          onPress={() => { setTransferSuccessVisible(false); router.navigate("/finans"); }}
        >
          <Pressable
            style={{ backgroundColor: colors.card, borderRadius: 24, padding: 28, alignItems: "center", shadowColor: "#000", shadowOpacity: 0.3, shadowRadius: 20, elevation: 10 }}
            onPress={() => {}}
          >
            <View style={{ width: 72, height: 72, borderRadius: 36, backgroundColor: "#7C5CBF20", alignItems: "center", justifyContent: "center", marginBottom: 16 }}>
              <Feather name="check-circle" size={34} color="#7C5CBF" />
            </View>
            <Text style={{ fontSize: 20, fontWeight: "800", color: colors.foreground, textAlign: "center", marginBottom: 8 }}>
              Transfer Tamamlandı!
            </Text>
            <Text style={{ fontSize: 14, color: colors.mutedForeground, textAlign: "center", lineHeight: 20, marginBottom: 24 }}>
              {transferFromBank && transferToBank
                ? `${transferFromBank} → ${transferToBank} transferi işlem geçmişine eklendi.`
                : "Transfer işlemi başarıyla kaydedildi."}
            </Text>
            <View style={{ backgroundColor: "#7C5CBF12", borderRadius: 10, padding: 12, width: "100%", flexDirection: "row", gap: 8, alignItems: "flex-start", marginBottom: 20 }}>
              <Feather name="info" size={13} color="#7C5CBF" style={{ marginTop: 1 }} />
              <Text style={{ fontSize: 12, color: "#7C5CBF", fontWeight: "600", flex: 1, lineHeight: 17 }}>
                Bu işlem gelir ve gider toplamlarınızı etkilemez.
              </Text>
            </View>
            <TouchableOpacity
              style={{ backgroundColor: "#7C5CBF", borderRadius: colors.radius, paddingVertical: 14, paddingHorizontal: 32, width: "100%", alignItems: "center" }}
              onPress={() => { setTransferSuccessVisible(false); router.navigate("/finans"); }}
            >
              <Text style={{ fontSize: 16, fontWeight: "700", color: "#FFFFFF" }}>Tamam</Text>
            </TouchableOpacity>
          </Pressable>
        </Pressable>
      </Modal>

      {/* Yeni Kategori Modal */}
      <Modal
        visible={newCatVisible}
        transparent
        animationType="fade"
        onRequestClose={() => setNewCatVisible(false)}
      >
        <KeyboardAvoidingView
          style={{ flex: 1 }}
          behavior={Platform.OS === "ios" ? "padding" : "height"}
        >
          <Pressable
            style={{
              flex: 1,
              backgroundColor: "rgba(0,0,0,0.55)",
              justifyContent: "center",
              paddingHorizontal: 28,
            }}
            onPress={() => setNewCatVisible(false)}
          >
            <Pressable
              style={{
                backgroundColor: colors.card,
                borderRadius: 20,
                padding: 22,
                shadowColor: "#000",
                shadowOpacity: 0.25,
                shadowRadius: 16,
                elevation: 8,
              }}
              onPress={() => {}}
            >
              <Text style={{
                fontSize: 15,
                fontWeight: "700",
                color: colors.foreground,
                textAlign: "center",
                marginBottom: 14,
              }}>
                {txType === "expense" ? "Yeni Gider Kategorisi" : "Yeni Gelir Kategorisi"}
              </Text>

              <TextInput
                style={{
                  fontSize: 15,
                  color: colors.foreground,
                  backgroundColor: colors.background,
                  borderColor: colors.border,
                  borderWidth: 1,
                  borderRadius: colors.radius,
                  paddingHorizontal: 13,
                  paddingVertical: 10,
                  marginBottom: 16,
                }}
                placeholder={t("add.categoryNamePlaceholder")}
                placeholderTextColor={colors.mutedForeground}
                value={newCatLabel}
                onChangeText={setNewCatLabel}
                autoFocus
                maxLength={30}
                returnKeyType="done"
                onSubmitEditing={() => {
                  const label = newCatLabel.trim();
                  if (!label) return;
                  if (txType === "expense") addExpenseCategory(label);
                  else addIncomeCategory(label);
                  setSelectedCategory(label);
                  setNewCatLabel("");
                  setNewCatVisible(false);
                  Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
                }}
              />

              <View style={{ flexDirection: "row", gap: 10 }}>
                <TouchableOpacity
                  style={{
                    flex: 1,
                    backgroundColor: colors.muted,
                    borderRadius: colors.radius,
                    paddingVertical: 12,
                    alignItems: "center",
                    borderWidth: 1,
                    borderColor: colors.border,
                  }}
                  onPress={() => setNewCatVisible(false)}
                >
                  <Text style={{ fontSize: 14, fontWeight: "700", color: colors.foreground }}>
                    İptal
                  </Text>
                </TouchableOpacity>

                <TouchableOpacity
                  style={{
                    flex: 1,
                    backgroundColor: colors.primary,
                    borderRadius: colors.radius,
                    paddingVertical: 12,
                    alignItems: "center",
                    opacity: newCatLabel.trim().length > 0 ? 1 : 0.45,
                  }}
                  onPress={() => {
                    const label = newCatLabel.trim();
                    if (!label) return;
                    if (txType === "expense") addExpenseCategory(label);
                    else addIncomeCategory(label);
                    setSelectedCategory(label);
                    setNewCatLabel("");
                    setNewCatVisible(false);
                    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
                  }}
                >
                  <Text style={{ fontSize: 14, fontWeight: "700", color: "#FFFFFF" }}>
                    Ekle
                  </Text>
                </TouchableOpacity>
              </View>
            </Pressable>
          </Pressable>
        </KeyboardAvoidingView>
      </Modal>

      <Modal
        visible={dateModalVisible}
        transparent
        animationType="fade"
        onRequestClose={() => setDateModalVisible(false)}
      >
        <Pressable
          style={styles.modalBackdrop}
          onPress={() => setDateModalVisible(false)}
        >
          <Pressable
            style={[
              styles.modalContent,
              { padding: 16, borderRadius: 24, marginHorizontal: 20, marginBottom: 0, alignSelf: "center", width: "90%" },
            ]}
            onPress={() => {}}
          >
            <Calendar
              value={date}
              onChange={(d) => {
                setDate(d);
                setDateModalVisible(false);
              }}
            />
          </Pressable>
        </Pressable>
      </Modal>

      {/* Havale/EFT/FAST — Vadesiz Hesap Seçimi Modali */}
      <Modal
        visible={transferModalVisible}
        transparent
        animationType="slide"
        onRequestClose={() => setTransferModalVisible(false)}
      >
        <Pressable
          style={styles.modalBackdrop}
          onPress={() => setTransferModalVisible(false)}
        >
          <Pressable style={styles.modalContent} onPress={() => {}}>
            <View style={styles.modalHandle} />
            <Text style={styles.modalTitle}>{t("add.selectSavingsAccount")}</Text>
            <ScrollView keyboardShouldPersistTaps="handled">
              {/* Kayıtlı vadesiz hesaplar */}
              {savedCards.filter((c) => c.type === "demand").length > 0 ? (
                <>
                  <Text
                    style={{
                      fontSize: 12,
                      fontWeight: "700",
                      color: colors.mutedForeground,
                      marginTop: 8,
                      marginBottom: 6,
                      paddingHorizontal: 20,
                      textTransform: "uppercase",
                      letterSpacing: 0.5,
                    }}
                  >
                    {t("add.savedAccounts")}
                  </Text>
                  {savedCards
                    .filter((c) => c.type === "demand")
                    .map((c) => {
                      const isSelected = savedCardId === c.id;
                      const label = c.name || c.bank;
                      const sub = c.name ? c.bank : c.iban;
                      return (
                        <TouchableOpacity
                          key={c.id}
                          style={[
                            styles.bankItem,
                            isSelected && { backgroundColor: colors.primary + "12" },
                          ]}
                          onPress={() => {
                            setBank(label);
                            setSavedCardId(c.id);
                            setTransferModalVisible(false);
                            Haptics.selectionAsync();
                          }}
                        >
                          <View style={{ flexDirection: "row", alignItems: "center", flex: 1 }}>
                            <View
                              style={{
                                width: 32,
                                height: 32,
                                borderRadius: 8,
                                backgroundColor: colors.primary + "1A",
                                alignItems: "center",
                                justifyContent: "center",
                                marginRight: 10,
                              }}
                            >
                              <Feather name="server" size={14} color={colors.primary} />
                            </View>
                            <View style={{ flex: 1 }}>
                              <Text style={styles.bankItemText}>{label}</Text>
                              {sub ? (
                                <Text
                                  style={{
                                    fontSize: 11,
                                    color: colors.mutedForeground,
                                    marginTop: 1,
                                  }}
                                  numberOfLines={1}
                                >
                                  {sub}
                                </Text>
                              ) : null}
                            </View>
                          </View>
                          {isSelected && (
                            <Feather name="check" size={18} color={colors.primary} />
                          )}
                        </TouchableOpacity>
                      );
                    })}
                </>
              ) : (
                <Text
                  style={{
                    textAlign: "center",
                    color: colors.mutedForeground,
                    fontSize: 13,
                    paddingVertical: 20,
                    paddingHorizontal: 20,
                  }}
                >
                  Henüz kayıtlı vadesiz hesabınız yok.{"\n"}Aşağıdan ekleyebilirsiniz.
                </Text>
              )}

              {/* Manuel Ekle butonu */}
              <TouchableOpacity
                style={[
                  styles.bankItem,
                  {
                    borderBottomWidth: 0,
                    marginTop: 4,
                    marginHorizontal: 12,
                    marginBottom: 8,
                    borderRadius: colors.radius,
                    backgroundColor: colors.primary + "0F",
                    borderWidth: 1.5,
                    borderColor: colors.primary + "40",
                    borderStyle: "dashed",
                  },
                ]}
                onPress={() => {
                  setNewDemandName("");
                  setNewDemandBank("");
                  setNewDemandIban("");
                  setAddDemandVisible(true);
                }}
              >
                <Feather name="plus" size={16} color={colors.primary} style={{ marginRight: 10 }} />
                <Text
                  style={{
                    fontSize: 14,
                    fontWeight: "600",
                    color: colors.primary,
                  }}
                >
                  Manuel Hesap Ekle
                </Text>
              </TouchableOpacity>
            </ScrollView>
          </Pressable>
        </Pressable>
      </Modal>

      {/* Manuel Vadesiz Hesap Ekleme Modali */}
      <Modal
        visible={addDemandVisible}
        transparent
        animationType="fade"
        onRequestClose={() => setAddDemandVisible(false)}
      >
        <KeyboardAvoidingView
          style={{ flex: 1 }}
          behavior={Platform.OS === "ios" ? "padding" : "height"}
        >
          <Pressable
            style={{
              flex: 1,
              backgroundColor: "rgba(0,0,0,0.55)",
              justifyContent: "center",
              paddingHorizontal: 24,
            }}
            onPress={() => setAddDemandVisible(false)}
          >
            <Pressable
              style={{
                backgroundColor: colors.card,
                borderRadius: 20,
                padding: 22,
                shadowColor: "#000",
                shadowOpacity: 0.25,
                shadowRadius: 16,
                elevation: 8,
              }}
              onPress={() => {}}
            >
              <Text
                style={{
                  fontSize: 16,
                  fontWeight: "700",
                  color: colors.foreground,
                  textAlign: "center",
                  marginBottom: 16,
                }}
              >
                Yeni Vadesiz Hesap
              </Text>

              {/* Hesap Adı */}
              <Text
                style={{
                  fontSize: 12,
                  fontWeight: "600",
                  color: colors.mutedForeground,
                  marginBottom: 6,
                  letterSpacing: 0.3,
                }}
              >
                HESAP ADI *
              </Text>
              <TextInput
                style={{
                  fontSize: 15,
                  color: colors.foreground,
                  backgroundColor: colors.background,
                  borderColor: colors.border,
                  borderWidth: 1,
                  borderRadius: colors.radius,
                  paddingHorizontal: 13,
                  paddingVertical: 10,
                  marginBottom: 12,
                }}
                placeholder={t("add.accountNamePlaceholder")}
                placeholderTextColor={colors.mutedForeground}
                value={newDemandName}
                onChangeText={setNewDemandName}
                maxLength={40}
                autoFocus
              />

              {/* Banka Adı */}
              <Text
                style={{
                  fontSize: 12,
                  fontWeight: "600",
                  color: colors.mutedForeground,
                  marginBottom: 6,
                  letterSpacing: 0.3,
                }}
              >
                BANKA *
              </Text>
              <TextInput
                style={{
                  fontSize: 15,
                  color: colors.foreground,
                  backgroundColor: colors.background,
                  borderColor: colors.border,
                  borderWidth: 1,
                  borderRadius: colors.radius,
                  paddingHorizontal: 13,
                  paddingVertical: 10,
                  marginBottom: 12,
                }}
                placeholder={t("add.bankNamePlaceholder")}
                placeholderTextColor={colors.mutedForeground}
                value={newDemandBank}
                onChangeText={setNewDemandBank}
                maxLength={40}
              />

              {/* IBAN (isteğe bağlı) */}
              <Text
                style={{
                  fontSize: 12,
                  fontWeight: "600",
                  color: colors.mutedForeground,
                  marginBottom: 6,
                  letterSpacing: 0.3,
                }}
              >
                IBAN (isteğe bağlı)
              </Text>
              <TextInput
                style={{
                  fontSize: 15,
                  color: colors.foreground,
                  backgroundColor: colors.background,
                  borderColor: colors.border,
                  borderWidth: 1,
                  borderRadius: colors.radius,
                  paddingHorizontal: 13,
                  paddingVertical: 10,
                  marginBottom: 18,
                }}
                placeholder={t("add.ibanPlaceholder")}
                placeholderTextColor={colors.mutedForeground}
                value={newDemandIban}
                onChangeText={setNewDemandIban}
                autoCapitalize="characters"
                maxLength={32}
              />

              <View style={{ flexDirection: "row", gap: 10 }}>
                <TouchableOpacity
                  style={{
                    flex: 1,
                    backgroundColor: colors.muted,
                    borderRadius: colors.radius,
                    paddingVertical: 12,
                    alignItems: "center",
                    borderWidth: 1,
                    borderColor: colors.border,
                  }}
                  onPress={() => setAddDemandVisible(false)}
                >
                  <Text style={{ fontSize: 14, fontWeight: "700", color: colors.foreground }}>
                    İptal
                  </Text>
                </TouchableOpacity>

                <TouchableOpacity
                  style={{
                    flex: 1,
                    backgroundColor: colors.primary,
                    borderRadius: colors.radius,
                    paddingVertical: 12,
                    alignItems: "center",
                    opacity:
                      newDemandName.trim().length > 0 && newDemandBank.trim().length > 0
                        ? 1
                        : 0.45,
                  }}
                  onPress={() => {
                    const name = newDemandName.trim();
                    const bankName = newDemandBank.trim();
                    if (!name || !bankName) return;
                    const newId = addSavedCard({
                      type: "demand",
                      name,
                      bank: bankName,
                      iban: newDemandIban.trim() || undefined,
                    });
                    setBank(name);
                    setSavedCardId(newId);
                    setAddDemandVisible(false);
                    setTransferModalVisible(false);
                    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
                  }}
                >
                  <Text style={{ fontSize: 14, fontWeight: "700", color: "#FFFFFF" }}>
                    Kaydet
                  </Text>
                </TouchableOpacity>
              </View>
            </Pressable>
          </Pressable>
        </KeyboardAvoidingView>
      </Modal>

      {/* Kredi Kartı Banka Seçimi Modali */}
      <Modal
        visible={bankModalVisible}
        transparent
        animationType="slide"
        onRequestClose={() => setBankModalVisible(false)}
      >
        <Pressable
          style={styles.modalBackdrop}
          onPress={() => setBankModalVisible(false)}
        >
          <Pressable style={styles.modalContent} onPress={() => {}}>
            <View style={styles.modalHandle} />
            <Text style={styles.modalTitle}>{t("add.selectBankCard")}</Text>
            <ScrollView>
              {(() => {
                const trackedCards = bankLimits.filter((b) => b.type === "credit");
                return (
                  <>
                    {trackedCards.length > 0 && (
                      <>
                        <Text
                          style={{
                            fontSize: 12,
                            fontWeight: "700",
                            color: colors.mutedForeground,
                            marginTop: 4,
                            marginBottom: 8,
                            paddingHorizontal: 4,
                            textTransform: "uppercase",
                            letterSpacing: 0.5,
                          }}
                        >
                          {t("add.trackedCards")}
                        </Text>
                        {trackedCards.map((b) => {
                          const displayName = b.institution || b.bank;
                          const subtitle = b.institution ? b.bank : undefined;
                          const selected = bankLimitId === b.id;
                          return (
                            <TouchableOpacity
                              key={`tracked-${b.id}`}
                              style={[
                                styles.bankItem,
                                selected && { backgroundColor: colors.primary + "12" },
                              ]}
                              onPress={() => {
                                setBank(displayName);
                                setBankLimitId(b.id);
                                setBankModalVisible(false);
                                Haptics.selectionAsync();
                              }}
                            >
                              <View
                                style={{
                                  flexDirection: "row",
                                  alignItems: "center",
                                  flex: 1,
                                }}
                              >
                                <View
                                  style={{
                                    width: 32,
                                    height: 32,
                                    borderRadius: 8,
                                    backgroundColor: colors.primary + "1A",
                                    alignItems: "center",
                                    justifyContent: "center",
                                    marginRight: 10,
                                  }}
                                >
                                  <Feather
                                    name="credit-card"
                                    size={14}
                                    color={colors.primary}
                                  />
                                </View>
                                <View style={{ flex: 1 }}>
                                  <Text style={styles.bankItemText}>{displayName}</Text>
                                  {subtitle && (
                                    <Text
                                      style={{
                                        fontSize: 11,
                                        color: colors.mutedForeground,
                                        marginTop: 2,
                                      }}
                                    >
                                      {subtitle}
                                    </Text>
                                  )}
                                </View>
                              </View>
                              {selected && (
                                <Feather name="check" size={18} color={colors.primary} />
                              )}
                            </TouchableOpacity>
                          );
                        })}
                        <Text
                          style={{
                            fontSize: 12,
                            fontWeight: "700",
                            color: colors.mutedForeground,
                            marginTop: 16,
                            marginBottom: 8,
                            paddingHorizontal: 4,
                            textTransform: "uppercase",
                            letterSpacing: 0.5,
                          }}
                        >
                          {t("add.otherBanks")}
                        </Text>
                      </>
                    )}
                    {BANKS.map((b) => {
                      const selected = bank === b && !bankLimitId;
                      return (
                        <TouchableOpacity
                          key={b}
                          style={styles.bankItem}
                          onPress={() => {
                            setBank(b);
                            setBankLimitId(undefined);
                            setBankModalVisible(false);
                            Haptics.selectionAsync();
                          }}
                        >
                          <Text style={styles.bankItemText}>{b}</Text>
                          {selected && (
                            <Feather name="check" size={18} color={colors.primary} />
                          )}
                        </TouchableOpacity>
                      );
                    })}
                  </>
                );
              })()}
            </ScrollView>
          </Pressable>
        </Pressable>
      </Modal>
    </View>
  );
}
