import { Feather } from "@expo/vector-icons";
import * as Haptics from "expo-haptics";
import React, { useState } from "react";
import {
  Alert,
  FlatList,
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

import { useTranslation } from "react-i18next";

import DatePickerSheet from "@/components/finans/DatePickerSheet";
import { PaymentMethod, Transaction, useBudget } from "@/context/finans/BudgetContext";
import { useColors } from "@/hooks/finans/useColors";
import { BANKS, getCategoryIcon } from "@/utils/finans/categories";
import { formatDate } from "@/utils/finans/format";
import { useFormatAmount } from "@/hooks/finans/useFormatAmount";

interface Props {
  transaction: Transaction;
}

type TxType = "expense" | "income";

interface FormState {
  type: TxType;
  amount: string;
  category: string;
  note: string;
  paymentMethod: PaymentMethod;
  bank: string;
  bankLimitId?: string;
  date: Date;
}

function toFormState(t: Transaction): FormState {
  return {
    type: t.type as TxType,
    amount: String(t.amount).replace(".", ","),
    category: t.category,
    note: t.note ?? "",
    paymentMethod: t.paymentMethod ?? "cash",
    bank: t.bank ?? "",
    bankLimitId: t.bankLimitId,
    date: new Date(t.date),
  };
}

export default function TransactionCard({ transaction }: Props) {
  const formatAmount = useFormatAmount();
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const { t } = useTranslation();
  const {
    deleteTransaction,
    updateTransaction,
    expenseCategoryList,
    incomeCategoryList,
    bankLimits,
  } = useBudget();
  const isIncome = transaction.type === "income";
  const isTransfer = transaction.type === "transfer";

  const [editOpen, setEditOpen] = useState(false);
  const [form, setForm] = useState<FormState>(() => toFormState(transaction));
  const [bankListOpen, setBankListOpen] = useState(false);
  const [datePicking, setDatePicking] = useState(false);

  const openEdit = () => {
    Haptics.selectionAsync();
    setForm(toFormState(transaction));
    setBankListOpen(false);
    setDatePicking(false);
    setEditOpen(true);
  };

  const closeEdit = () => {
    setEditOpen(false);
  };

  const handleSave = () => {
    const numAmount = parseFloat(form.amount.replace(",", "."));
    if (!numAmount || numAmount <= 0 || !form.category) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
      return;
    }
    if (form.paymentMethod === "card" && !form.bank) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
      return;
    }
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    updateTransaction(transaction.id, {
      type: form.type,
      amount: numAmount,
      category: form.category,
      note: form.note.trim(),
      paymentMethod: form.paymentMethod,
      bank: form.paymentMethod === "card" ? form.bank : undefined,
      bankLimitId: form.paymentMethod === "card" ? form.bankLimitId : undefined,
      date: form.date.toISOString(),
    });
    closeEdit();
  };

  const handleDelete = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    Alert.alert(t("transactionCard.deleteTitle"), t("transactionCard.deleteMsg"), [
      { text: t("common.cancel"), style: "cancel" },
      {
        text: t("common.delete"),
        style: "destructive",
        onPress: () => deleteTransaction(transaction.id),
      },
    ]);
  };

  const isValid =
    parseFloat(form.amount.replace(",", ".")) > 0 &&
    !!form.category &&
    (form.paymentMethod === "cash" || !!form.bank);

  const sourceList = form.type === "expense" ? expenseCategoryList : incomeCategoryList;
  const categories = sourceList.map((label) => ({ label, icon: getCategoryIcon(label) }));

  const accentColor = form.type === "income" ? colors.income : colors.expense;
  const accentBg = form.type === "income" ? colors.incomeBg : colors.expenseBg;
  const iconName = getCategoryIcon(transaction.category);

  const s = StyleSheet.create({
    container: {
      flexDirection: "row",
      alignItems: "center",
      backgroundColor: colors.card,
      borderRadius: colors.radius,
      paddingHorizontal: 16,
      paddingVertical: 14,
      marginBottom: 10,
      shadowColor: "#000",
      shadowOffset: { width: 0, height: 1 },
      shadowOpacity: 0.05,
      shadowRadius: 4,
      elevation: 1,
    },
    iconContainer: {
      width: 46,
      height: 46,
      borderRadius: 23,
      backgroundColor: isTransfer ? "#7C5CBF20" : isIncome ? colors.incomeBg : colors.expenseBg,
      alignItems: "center",
      justifyContent: "center",
      marginRight: 14,
    },
    info: { flex: 1 },
    category: {
      fontSize: 15,
      fontWeight: "600" as const,
      color: colors.foreground,
      marginBottom: 3,
    },
    note: { fontSize: 12, color: colors.mutedForeground },
    metaRow: {
      flexDirection: "row",
      alignItems: "center",
      gap: 6,
      flexWrap: "wrap" as const,
    },
    metaItem: { flexDirection: "row", alignItems: "center", gap: 4 },
    right: { alignItems: "flex-end" },
    amount: {
      fontSize: 16,
      fontWeight: "700" as const,
      color: isTransfer ? "#7C5CBF" : isIncome ? colors.income : colors.expense,
      marginBottom: 3,
    },
    date: { fontSize: 11, color: colors.mutedForeground },
    actionBtns: { flexDirection: "row", gap: 4, marginLeft: 8 },
    iconBtn: { padding: 6 },
    backdrop: {
      flex: 1,
      backgroundColor: "rgba(0,0,0,0.5)",
      justifyContent: "flex-end",
    },
    sheet: {
      backgroundColor: colors.background,
      borderTopLeftRadius: 24,
      borderTopRightRadius: 24,
      maxHeight: "92%",
    },
    handle: {
      width: 40,
      height: 4,
      borderRadius: 2,
      backgroundColor: colors.border,
      alignSelf: "center" as const,
      marginTop: 10,
      marginBottom: 4,
    },
    sheetTitle: {
      fontSize: 17,
      fontWeight: "700" as const,
      color: colors.foreground,
      textAlign: "center" as const,
      paddingVertical: 14,
      borderBottomWidth: 1,
      borderBottomColor: colors.border,
      marginBottom: 4,
    },
    body: {
      paddingHorizontal: 20,
      paddingBottom: Math.max(insets.bottom, 16) + 16,
    },
    typeRow: { flexDirection: "row", gap: 10, marginTop: 16, marginBottom: 4 },
    typeBtn: {
      flex: 1,
      paddingVertical: 11,
      borderRadius: 12,
      alignItems: "center",
      flexDirection: "row",
      justifyContent: "center",
      gap: 6,
      borderWidth: 1.5,
    },
    typeBtnText: { fontSize: 14, fontWeight: "700" as const },
    label: {
      fontSize: 12,
      fontWeight: "600" as const,
      color: colors.mutedForeground,
      letterSpacing: 0.3,
      marginBottom: 8,
      marginTop: 16,
    },
    amountContainer: {
      flexDirection: "row",
      alignItems: "center",
      backgroundColor: colors.card,
      borderRadius: colors.radius,
      paddingHorizontal: 16,
    },
    currency: {
      fontSize: 20,
      fontWeight: "700" as const,
      color: accentColor,
      marginRight: 4,
    },
    amountInput: {
      flex: 1,
      fontSize: 26,
      fontWeight: "700" as const,
      color: colors.foreground,
      paddingVertical: 14,
    },
    categoryGrid: {
      flexDirection: "row",
      flexWrap: "wrap" as const,
      gap: 8,
    },
    chip: {
      flexDirection: "row",
      alignItems: "center",
      paddingHorizontal: 12,
      paddingVertical: 9,
      borderRadius: 22,
      gap: 5,
      borderWidth: 1.5,
    },
    chipText: { fontSize: 13, fontWeight: "600" as const },
    paymentRow: { flexDirection: "row", gap: 10 },
    paymentBtn: {
      flex: 1,
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "center",
      gap: 8,
      paddingVertical: 13,
      borderRadius: colors.radius,
      borderWidth: 1.5,
    },
    paymentBtnText: { fontSize: 14, fontWeight: "600" as const },
    dateSelector: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      backgroundColor: colors.card,
      borderRadius: colors.radius,
      paddingHorizontal: 16,
      paddingVertical: 14,
    },
    dateSelectorText: { fontSize: 15, color: colors.foreground },
    bankSelector: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      backgroundColor: colors.card,
      borderRadius: colors.radius,
      paddingHorizontal: 16,
      paddingVertical: 14,
    },
    bankSelectorText: { fontSize: 15 },
    bankList: {
      backgroundColor: colors.card,
      borderRadius: colors.radius,
      marginTop: 6,
      maxHeight: 200,
    },
    bankItem: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      paddingVertical: 14,
      paddingHorizontal: 16,
      borderBottomWidth: StyleSheet.hairlineWidth,
      borderBottomColor: colors.border,
    },
    bankItemText: { fontSize: 15, color: colors.foreground },
    noteInput: {
      backgroundColor: colors.card,
      borderRadius: colors.radius,
      paddingHorizontal: 16,
      paddingVertical: 13,
      fontSize: 15,
      color: colors.foreground,
    },
    actionRow: { flexDirection: "row", gap: 10, marginTop: 22 },
    saveBtn: {
      flex: 1,
      paddingVertical: 15,
      borderRadius: colors.radius,
      alignItems: "center",
    },
    saveBtnText: { fontSize: 16, fontWeight: "700" as const, color: "#FFFFFF" },
    cancelBtn: {
      flex: 1,
      backgroundColor: colors.muted,
      paddingVertical: 15,
      borderRadius: colors.radius,
      alignItems: "center",
    },
    cancelBtnText: {
      fontSize: 16,
      fontWeight: "700" as const,
      color: colors.foreground,
    },
  });

  if (isTransfer) {
    return (
      <>
        <TouchableOpacity
          style={s.container}
          onPress={() => {
            Haptics.selectionAsync();
            Alert.alert(
              "Transfer Detayı",
              `Tutar: ₺${transaction.amount.toLocaleString("tr-TR", { minimumFractionDigits: 2 })}\nGönderen: ${transaction.fromBank ?? "-"}\nAlıcı: ${transaction.toBank ?? "-"}${transaction.note ? `\nNot: ${transaction.note}` : ""}`,
              [
                { text: "Sil", style: "destructive", onPress: () => deleteTransaction(transaction.id) },
                { text: "Kapat", style: "cancel" },
              ]
            );
          }}
          activeOpacity={0.75}
        >
          <View style={s.iconContainer}>
            <Feather name="shuffle" size={20} color="#7C5CBF" />
          </View>
          <View style={s.info}>
            <Text style={s.category}>Transfer</Text>
            <View style={s.metaRow}>
              <View style={s.metaItem}>
                <Feather name="log-out" size={11} color={colors.mutedForeground} />
                <Text style={s.note} numberOfLines={1}>{transaction.fromBank ?? "-"}</Text>
              </View>
              <Feather name="arrow-right" size={11} color={colors.mutedForeground} />
              <View style={s.metaItem}>
                <Feather name="log-in" size={11} color={colors.mutedForeground} />
                <Text style={s.note} numberOfLines={1}>{transaction.toBank ?? "-"}</Text>
              </View>
              {transaction.note ? (
                <Text style={s.note} numberOfLines={1}>• {transaction.note}</Text>
              ) : null}
            </View>
          </View>
          <View style={s.right}>
            <Text style={s.amount}>₺{formatAmount(transaction.amount)}</Text>
            <Text style={s.date}>{formatDate(transaction.date)}</Text>
          </View>
        </TouchableOpacity>
      </>
    );
  }

  return (
    <>
      <TouchableOpacity style={s.container} onPress={openEdit} activeOpacity={0.75}>
        <View style={s.iconContainer}>
          <Feather
            name={iconName as any}
            size={20}
            color={isIncome ? colors.income : colors.expense}
          />
        </View>
        <View style={s.info}>
          <Text style={s.category}>{transaction.category}</Text>
          <View style={s.metaRow}>
            {transaction.paymentMethod ? (
              <View style={s.metaItem}>
                <Feather
                  name={
                    transaction.paymentMethod === "card"
                      ? "credit-card"
                      : "dollar-sign"
                  }
                  size={11}
                  color={colors.mutedForeground}
                />
                <Text style={s.note}>
                  {transaction.paymentMethod === "card"
                    ? (transaction.bank ?? t("transactionCard.card"))
                    : t("transactionCard.cash")}
                </Text>
              </View>
            ) : null}
            {transaction.note ? (
              <Text style={s.note} numberOfLines={1}>
                {transaction.paymentMethod ? "• " : ""}
                {transaction.note}
              </Text>
            ) : null}
          </View>
        </View>
        <View style={s.right}>
          <Text style={s.amount}>
            {isIncome ? "+" : "-"}
            {formatAmount(transaction.amount)}
          </Text>
          <Text style={s.date}>{formatDate(transaction.date)}</Text>
        </View>
      </TouchableOpacity>

      {/* Edit Modal */}
      <Modal
        visible={editOpen}
        transparent
        animationType="slide"
        onRequestClose={closeEdit}
      >
        <KeyboardAvoidingView
          behavior={Platform.OS === "ios" ? "padding" : "height"}
          style={{ flex: 1 }}
        >
          <Pressable style={s.backdrop} onPress={closeEdit}>
            <Pressable style={s.sheet} onPress={() => {}}>
              <View style={s.handle} />
              <Text style={s.sheetTitle}>İşlemi Düzenle</Text>

              <ScrollView
                style={s.body}
                keyboardShouldPersistTaps="handled"
                showsVerticalScrollIndicator={false}
              >
                {/* Type toggle */}
                <View style={s.typeRow}>
                  {(["expense", "income"] as TxType[]).map((txType) => {
                    const active = form.type === txType;
                    const color = txType === "income" ? colors.income : colors.expense;
                    const bg = txType === "income" ? colors.incomeBg : colors.expenseBg;
                    return (
                      <TouchableOpacity
                        key={txType}
                        style={[
                          s.typeBtn,
                          {
                            backgroundColor: active ? bg : colors.muted,
                            borderColor: active ? color : colors.border,
                          },
                        ]}
                        onPress={() => {
                          Haptics.selectionAsync();
                          setForm({ ...form, type: txType, category: "" });
                        }}
                      >
                        <Feather
                          name={
                            txType === "income" ? "arrow-down-left" : "arrow-up-right"
                          }
                          size={15}
                          color={active ? color : colors.mutedForeground}
                        />
                        <Text
                          style={[
                            s.typeBtnText,
                            { color: active ? color : colors.foreground },
                          ]}
                        >
                          {txType === "income" ? t("transactionCard.income") : t("transactionCard.expense")}
                        </Text>
                      </TouchableOpacity>
                    );
                  })}
                </View>

                {/* Amount */}
                <Text style={s.label}>{t("transactionCard.amount")}</Text>
                <View style={s.amountContainer}>
                  <Text style={s.currency}>₺</Text>
                  <TextInput
                    style={s.amountInput}
                    value={form.amount}
                    onChangeText={(v) => setForm({ ...form, amount: v })}
                    keyboardType="decimal-pad"
                    placeholder="0,00"
                    placeholderTextColor={colors.mutedForeground}
                  />
                </View>

                {/* Category */}
                <Text style={s.label}>{t("transactionCard.category")}</Text>
                <View style={s.categoryGrid}>
                  {categories.map((cat) => {
                    const sel = form.category === cat.label;
                    return (
                      <TouchableOpacity
                        key={cat.label}
                        style={[
                          s.chip,
                          {
                            backgroundColor: sel ? accentBg : colors.card,
                            borderColor: sel ? accentColor : colors.border,
                          },
                        ]}
                        onPress={() => {
                          Haptics.selectionAsync();
                          setForm({ ...form, category: cat.label });
                        }}
                      >
                        <Feather
                          name={cat.icon as any}
                          size={13}
                          color={sel ? accentColor : colors.mutedForeground}
                        />
                        <Text
                          style={[
                            s.chipText,
                            { color: sel ? accentColor : colors.foreground },
                          ]}
                        >
                          {cat.label}
                        </Text>
                      </TouchableOpacity>
                    );
                  })}
                </View>

                {/* Payment method */}
                <Text style={s.label}>ÖDEME ŞEKLİ</Text>
                <View style={s.paymentRow}>
                  {(["cash", "card"] as PaymentMethod[]).map((pm) => {
                    const active = form.paymentMethod === pm;
                    return (
                      <TouchableOpacity
                        key={pm}
                        style={[
                          s.paymentBtn,
                          {
                            backgroundColor: active ? accentBg : colors.card,
                            borderColor: active ? accentColor : colors.border,
                          },
                        ]}
                        onPress={() => {
                          Haptics.selectionAsync();
                          setForm({
                            ...form,
                            paymentMethod: pm,
                            bank: "",
                            bankLimitId: undefined,
                          });
                        }}
                      >
                        <Feather
                          name={pm === "card" ? "credit-card" : "dollar-sign"}
                          size={15}
                          color={active ? accentColor : colors.mutedForeground}
                        />
                        <Text
                          style={[
                            s.paymentBtnText,
                            { color: active ? accentColor : colors.foreground },
                          ]}
                        >
                          {pm === "card" ? t("transactionCard.creditCard") : t("transactionCard.cash")}
                        </Text>
                      </TouchableOpacity>
                    );
                  })}
                </View>

                {/* Bank selector (inline list) */}
                {form.paymentMethod === "card" && (
                  <>
                    <Text style={s.label}>{t("transactionCard.bank")}</Text>
                    <TouchableOpacity
                      style={s.bankSelector}
                      onPress={() => {
                        Haptics.selectionAsync();
                        setBankListOpen((v) => !v);
                      }}
                    >
                      <Text
                        style={[
                          s.bankSelectorText,
                          {
                            color: form.bank
                              ? colors.foreground
                              : colors.mutedForeground,
                          },
                        ]}
                      >
                        {form.bank || t("transactionCard.selectBank")}
                      </Text>
                      <Feather
                        name={bankListOpen ? "chevron-up" : "chevron-down"}
                        size={18}
                        color={colors.mutedForeground}
                      />
                    </TouchableOpacity>
                    {bankListOpen && (() => {
                      const trackedCards = bankLimits.filter(
                        (b) => b.type === "credit"
                      );
                      type RowItem =
                        | { kind: "header"; label: string; key: string }
                        | { kind: "tracked"; key: string; bankLimit: typeof bankLimits[number] }
                        | { kind: "generic"; key: string; bank: string };
                      const data: RowItem[] = [];
                      if (trackedCards.length > 0) {
                        data.push({
                          kind: "header",
                          label: t("transactionCard.savedCards"),
                          key: "h-tracked",
                        });
                        trackedCards.forEach((b) =>
                          data.push({
                            kind: "tracked",
                            key: `t-${b.id}`,
                            bankLimit: b,
                          })
                        );
                        data.push({
                          kind: "header",
                          label: t("transactionCard.otherBanks"),
                          key: "h-generic",
                        });
                      }
                      BANKS.forEach((b) =>
                        data.push({ kind: "generic", key: `g-${b}`, bank: b })
                      );
                      return (
                        <View style={s.bankList}>
                          <FlatList
                            data={data}
                            keyExtractor={(item) => item.key}
                            scrollEnabled
                            nestedScrollEnabled
                            keyboardShouldPersistTaps="handled"
                            renderItem={({ item }) => {
                              if (item.kind === "header") {
                                return (
                                  <Text
                                    style={{
                                      fontSize: 11,
                                      fontWeight: "700",
                                      color: colors.mutedForeground,
                                      paddingHorizontal: 12,
                                      paddingTop: 10,
                                      paddingBottom: 6,
                                      textTransform: "uppercase",
                                      letterSpacing: 0.5,
                                    }}
                                  >
                                    {item.label}
                                  </Text>
                                );
                              }
                              if (item.kind === "tracked") {
                                const b = item.bankLimit;
                                const displayName = b.institution || b.bank;
                                const subtitle = b.institution ? b.bank : undefined;
                                const selected = form.bankLimitId === b.id;
                                return (
                                  <TouchableOpacity
                                    style={[
                                      s.bankItem,
                                      selected && {
                                        backgroundColor: colors.primary + "12",
                                      },
                                    ]}
                                    onPress={() => {
                                      Haptics.selectionAsync();
                                      setForm({
                                        ...form,
                                        bank: displayName,
                                        bankLimitId: b.id,
                                      });
                                      setBankListOpen(false);
                                    }}
                                  >
                                    <View style={{ flex: 1 }}>
                                      <Text style={s.bankItemText}>{displayName}</Text>
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
                                    {selected && (
                                      <Feather
                                        name="check"
                                        size={16}
                                        color={colors.primary}
                                      />
                                    )}
                                  </TouchableOpacity>
                                );
                              }
                              const selected =
                                form.bank === item.bank && !form.bankLimitId;
                              return (
                                <TouchableOpacity
                                  style={s.bankItem}
                                  onPress={() => {
                                    Haptics.selectionAsync();
                                    setForm({
                                      ...form,
                                      bank: item.bank,
                                      bankLimitId: undefined,
                                    });
                                    setBankListOpen(false);
                                  }}
                                >
                                  <Text style={s.bankItemText}>{item.bank}</Text>
                                  {selected && (
                                    <Feather
                                      name="check"
                                      size={16}
                                      color={colors.primary}
                                    />
                                  )}
                                </TouchableOpacity>
                              );
                            }}
                          />
                        </View>
                      );
                    })()}
                  </>
                )}

                {/* Date */}
                <Text style={s.label}>{t("transactionCard.date")}</Text>
                <TouchableOpacity
                  style={s.dateSelector}
                  onPress={() => {
                    Haptics.selectionAsync();
                    setDatePicking(true);
                  }}
                >
                  <Text style={s.dateSelectorText}>
                    {form.date.toLocaleDateString(undefined, {
                      day: "2-digit",
                      month: "long",
                      year: "numeric",
                    })}
                  </Text>
                  <Feather
                    name="calendar"
                    size={18}
                    color={colors.mutedForeground}
                  />
                </TouchableOpacity>

                {/* Note */}
                <Text style={s.label}>{t("transactionCard.noteLabel")}</Text>
                <TextInput
                  style={s.noteInput}
                  value={form.note}
                  onChangeText={(v) => setForm({ ...form, note: v })}
                  placeholder={t("transactionCard.addNote")}
                  placeholderTextColor={colors.mutedForeground}
                />

                {/* Actions */}
                <View style={s.actionRow}>
                  <TouchableOpacity
                    style={[
                      s.saveBtn,
                      { backgroundColor: isValid ? accentColor : colors.muted },
                    ]}
                    onPress={handleSave}
                    disabled={!isValid}
                  >
                    <Text
                      style={[
                        s.saveBtnText,
                        { color: isValid ? "#FFFFFF" : colors.mutedForeground },
                      ]}
                    >
                      {t("common.save")}
                    </Text>
                  </TouchableOpacity>
                  <TouchableOpacity style={s.cancelBtn} onPress={closeEdit}>
                    <Text style={s.cancelBtnText}>{t("common.cancel")}</Text>
                  </TouchableOpacity>
                </View>
                <TouchableOpacity
                  style={{
                    marginTop: 10,
                    paddingVertical: 13,
                    borderRadius: colors.radius,
                    alignItems: "center",
                    backgroundColor: colors.expense + "15",
                  }}
                  onPress={() => { closeEdit(); setTimeout(handleDelete, 150); }}
                >
                  <Text style={{ fontSize: 15, fontWeight: "700", color: colors.expense }}>
                    {t("transactionCard.deleteTitle")}
                  </Text>
                </TouchableOpacity>
              </ScrollView>
            </Pressable>
          </Pressable>

          {/* DatePickerSheet inside this Modal for iOS compatibility */}
          <DatePickerSheet
            visible={datePicking}
            value={form.date}
            title={t("datePicker.selectDate")}
            onSelect={(d) => setForm({ ...form, date: d })}
            onClose={() => setDatePicking(false)}
          />
        </KeyboardAvoidingView>
      </Modal>
    </>
  );
}
