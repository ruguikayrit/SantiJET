import { Feather } from "@expo/vector-icons";
import * as Clipboard from "expo-clipboard";
import * as Haptics from "expo-haptics";
import React, { useState } from "react";
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

import { useTranslation } from "react-i18next";

import { computeDueDay, SavedCard, SavedCardType, useBudget } from "@/context/finans/BudgetContext";
import { useColors } from "@/hooks/finans/useColors";
import { BANKS } from "@/utils/finans/categories";

interface Props {
  visible: boolean;
  onClose: () => void;
}

type TabKey = "credit" | "demand" | "time";

export default function BankInfoModal({ visible, onClose }: Props) {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const { t } = useTranslation();
  const { savedCards, addSavedCard, updateSavedCard, deleteSavedCard } = useBudget();

  const TABS: { key: TabKey; label: string; icon: string }[] = [
    { key: "credit", label: t("bankInfo.creditCard"), icon: "credit-card" },
    { key: "demand", label: t("bankInfo.demandAccount"), icon: "briefcase" },
    { key: "time",   label: t("bankInfo.timeType"),   icon: "clock" },
  ];

  const [activeTab, setActiveTab] = useState<TabKey>("credit");

  const [formVisible, setFormVisible] = useState(false);
  const [editId, setEditId] = useState<string | null>(null);
  const [formName, setFormName] = useState("");
  const [formBank, setFormBank] = useState("");
  const [formBankPickerOpen, setFormBankPickerOpen] = useState(false);
  const [formManualBank, setFormManualBank] = useState(false);
  const [formLast4, setFormLast4] = useState("");
  const [formIban, setFormIban] = useState("");
  const [formStatementDay, setFormStatementDay] = useState("");

  const filteredCards = savedCards.filter((c) => c.type === activeTab);
  const [copiedId, setCopiedId] = useState<string | null>(null);

  const copyIban = async (id: string, iban: string) => {
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    await Clipboard.setStringAsync(iban);
    setCopiedId(id);
    setTimeout(() => setCopiedId(null), 2000);
  };

  const resetForm = () => {
    setEditId(null);
    setFormName("");
    setFormBank("");
    setFormBankPickerOpen(false);
    setFormManualBank(false);
    setFormLast4("");
    setFormIban("");
    setFormStatementDay("");
  };

  const openAdd = () => {
    Haptics.selectionAsync();
    resetForm();
    setFormVisible(true);
  };

  const openEdit = (c: SavedCard) => {
    Haptics.selectionAsync();
    setEditId(c.id);
    setFormName(c.name);
    setFormBank(c.bank);
    setFormBankPickerOpen(false);
    setFormManualBank(!BANKS.includes(c.bank));
    setFormLast4(c.cardLast4 ?? "");
    setFormIban(c.iban ?? "");
    setFormStatementDay(
      c.statementDay && c.statementDay >= 1 && c.statementDay <= 31
        ? String(c.statementDay)
        : ""
    );
    setFormVisible(true);
  };

  const closeForm = () => {
    setFormVisible(false);
    resetForm();
  };

  const submitForm = () => {
    const name = formName.trim();
    const bank = formBank.trim();
    if (!name) {
      const m = activeTab === "credit" ? t("bankInfo.cardNameRequired") : t("bankInfo.accountNameRequired");
      Platform.OS === "web" ? window.alert(m) : Alert.alert(t("bankInfo.missingField"), m);
      return;
    }
    if (!bank) {
      const m = t("bankInfo.bankNameRequired");
      Platform.OS === "web" ? window.alert(m) : Alert.alert(t("bankInfo.missingField"), m);
      return;
    }
    let statementDay: number | undefined;
    if (activeTab === "credit") {
      const raw = formStatementDay.trim();
      if (raw) {
        const n = parseInt(raw, 10);
        if (!Number.isFinite(n) || n < 1 || n > 31) {
          const m = t("bankInfo.statementDayInvalid");
          Platform.OS === "web" ? window.alert(m) : Alert.alert(t("bankInfo.invalidValue"), m);
          return;
        }
        statementDay = n;
      }
    }
    const payload: Omit<SavedCard, "id"> = {
      name,
      bank,
      type: activeTab as SavedCardType,
      cardLast4: activeTab === "credit" && formLast4.trim() ? formLast4.trim() : undefined,
      iban: activeTab === "demand" && formIban.trim() ? formIban.trim().toUpperCase() : undefined,
      statementDay: activeTab === "credit" ? statementDay : undefined,
      dueDay: activeTab === "credit" ? computeDueDay(statementDay) : undefined,
    };
    if (editId) {
      updateSavedCard(editId, payload);
    } else {
      addSavedCard(payload);
    }
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    closeForm();
  };

  const handleDelete = (c: SavedCard) => {
    const msg = activeTab === "credit"
      ? t("bankInfo.deleteCardConfirm", { name: c.name })
      : t("bankInfo.deleteAccountConfirm", { name: c.name });
    if (Platform.OS === "web") {
      if (window.confirm(msg)) deleteSavedCard(c.id);
      return;
    }
    Alert.alert(t("bankInfo.deleteLabel"), msg, [
      { text: t("bankInfo.cancelLabel"), style: "cancel" },
      { text: t("bankInfo.deleteLabel"), style: "destructive", onPress: () => deleteSavedCard(c.id) },
    ]);
  };

  const styles = StyleSheet.create({
    overlay: { flex: 1, backgroundColor: colors.background, paddingTop: insets.top + 12, paddingBottom: insets.bottom },
    sheet: { flex: 1, backgroundColor: colors.background },
    sheetHeader: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingHorizontal: 20, paddingVertical: 14, borderBottomWidth: 1, borderBottomColor: colors.border },
    sheetTitle: { fontSize: 18, fontWeight: "800", color: colors.foreground },
    closeBtn: { width: 32, height: 32, borderRadius: 16, backgroundColor: colors.muted, alignItems: "center", justifyContent: "center" },
    tabRow: { flexDirection: "row", marginHorizontal: 16, marginTop: 14, backgroundColor: colors.muted, borderRadius: 14, padding: 4 },
    tabBtn: { flex: 1, flexDirection: "row", alignItems: "center", justifyContent: "center", gap: 6, paddingVertical: 10, borderRadius: 11 },
    tabBtnActive: { backgroundColor: colors.card },
    tabBtnText: { fontSize: 13, fontWeight: "600", color: colors.mutedForeground },
    tabBtnTextActive: { color: colors.foreground, fontWeight: "700" },
    addBtn: { flexDirection: "row", alignItems: "center", justifyContent: "center", gap: 8, backgroundColor: colors.primary, borderRadius: 14, paddingVertical: 12, marginHorizontal: 16, marginTop: 12 },
    addBtnText: { color: "#FFFFFF", fontWeight: "700", fontSize: 14 },
    list: { paddingHorizontal: 16, paddingTop: 12, paddingBottom: 32 },
    card: { backgroundColor: colors.card, borderRadius: 14, padding: 14, marginBottom: 10, flexDirection: "row", alignItems: "center", gap: 12 },
    cardIconBg: { width: 40, height: 40, borderRadius: 12, backgroundColor: colors.muted, alignItems: "center", justifyContent: "center" },
    cardBody: { flex: 1 },
    cardName: { fontSize: 14, fontWeight: "700", color: colors.foreground },
    cardSub: { fontSize: 12, color: colors.mutedForeground, marginTop: 2 },
    cardBtns: { flexDirection: "row", gap: 6 },
    iconBtn: { width: 32, height: 32, borderRadius: 10, alignItems: "center", justifyContent: "center", backgroundColor: colors.muted },
    ibanRow: { flexDirection: "row", alignItems: "center", gap: 6, marginTop: 4 },
    ibanText: { flex: 1, fontSize: 11, fontWeight: "600" as const, color: colors.foreground, letterSpacing: 0.5, fontVariant: ["tabular-nums"] as any },
    ibanCopyBtn: { width: 24, height: 24, borderRadius: 7, borderWidth: 1, borderColor: colors.primary, alignItems: "center", justifyContent: "center" },
    ibanCopyBtnDone: { backgroundColor: colors.primary, borderColor: colors.primary },
    emptyWrap: { alignItems: "center", paddingVertical: 40, gap: 8 },
    emptyText: { fontSize: 13, color: colors.mutedForeground, fontStyle: "italic", textAlign: "center" },
    // Form modal
    formOverlay: { flex: 1, backgroundColor: "rgba(0,0,0,0.5)", justifyContent: "center", padding: 20 },
    formCard: { backgroundColor: colors.background, borderRadius: 20, padding: 20, maxHeight: "80%" },
    formTitle: { fontSize: 18, fontWeight: "800", color: colors.foreground, marginBottom: 16 },
    label: { fontSize: 13, fontWeight: "600", color: colors.foreground, marginBottom: 6, marginTop: 12 },
    selector: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", backgroundColor: colors.muted, borderRadius: 12, paddingVertical: 12, paddingHorizontal: 14 },
    selectorText: { fontSize: 14, color: colors.foreground, fontWeight: "600" },
    bankList: { backgroundColor: colors.muted, borderRadius: 12, marginTop: 6, maxHeight: 200 },
    bankRow: { paddingVertical: 12, paddingHorizontal: 14, borderBottomWidth: 1, borderBottomColor: colors.border },
    bankRowText: { fontSize: 14, color: colors.foreground },
    input: { backgroundColor: colors.muted, borderRadius: 12, paddingVertical: 12, paddingHorizontal: 14, color: colors.foreground, fontSize: 15 },
    readonlyInput: { justifyContent: "center" },
    readonlyText: { fontSize: 14, color: colors.mutedForeground, fontWeight: "600" },
    manualLink: { marginTop: 6, alignSelf: "flex-end" },
    manualLinkText: { fontSize: 12, color: colors.primary, textDecorationLine: "underline" },
    formActions: { flexDirection: "row", gap: 10, marginTop: 22 },
    cancelBtn: { flex: 1, backgroundColor: colors.muted, borderRadius: 14, paddingVertical: 14, alignItems: "center" },
    cancelBtnText: { color: colors.foreground, fontWeight: "700", fontSize: 14 },
    saveBtn: { flex: 1, backgroundColor: colors.primary, borderRadius: 14, paddingVertical: 14, alignItems: "center" },
    saveBtnText: { color: "#FFFFFF", fontWeight: "700", fontSize: 14 },
  });

  return (
    <Modal visible={visible} animationType="slide" onRequestClose={onClose} statusBarTranslucent>
      <View style={styles.overlay}>
        <View style={styles.sheet}>
          <View style={styles.sheetHeader}>
            <Text style={styles.sheetTitle}>🏦 {t("bankInfo.title")}</Text>
            <TouchableOpacity style={styles.closeBtn} onPress={onClose} activeOpacity={0.7}>
              <Feather name="x" size={16} color={colors.foreground} />
            </TouchableOpacity>
          </View>

          <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ paddingBottom: 20 }}>
            <View style={styles.tabRow}>
              {TABS.map(({ key, label, icon }) => {
                const isActive = activeTab === key;
                return (
                  <TouchableOpacity
                    key={key}
                    style={[styles.tabBtn, isActive && styles.tabBtnActive]}
                    onPress={() => { Haptics.selectionAsync(); setActiveTab(key); }}
                  >
                    <Feather name={icon as any} size={14} color={isActive ? colors.primary : colors.mutedForeground} />
                    <Text style={[styles.tabBtnText, isActive && styles.tabBtnTextActive]}>{label}</Text>
                  </TouchableOpacity>
                );
              })}
            </View>

            <TouchableOpacity style={styles.addBtn} onPress={openAdd}>
              <Feather name="plus" size={16} color="#FFFFFF" />
              <Text style={styles.addBtnText}>
                {activeTab === "credit" ? t("bankInfo.creditCardAdd") : t("bankInfo.demandAccountAdd")}
              </Text>
            </TouchableOpacity>

            <View style={styles.list}>
              {filteredCards.length === 0 ? (
                <View style={styles.emptyWrap}>
                  <Feather name={activeTab === "credit" ? "credit-card" : "briefcase"} size={36} color={colors.mutedForeground} />
                  <Text style={styles.emptyText}>
                    {activeTab === "credit"
                      ? t("bankInfo.noCreditCardsMsg")
                      : t("bankInfo.noDemandAccountsMsg")}
                  </Text>
                </View>
              ) : (
                filteredCards.map((c) => (
                  <View key={c.id} style={styles.card}>
                    <View style={styles.cardIconBg}>
                      <Feather name={activeTab === "credit" ? "credit-card" : "briefcase"} size={18} color={colors.primary} />
                    </View>
                    <View style={styles.cardBody}>
                      <Text style={styles.cardName}>{c.name}</Text>
                      <Text style={styles.cardSub}>
                        {c.bank}
                        {c.cardLast4 ? ` • **** ${c.cardLast4}` : ""}
                      </Text>
                      {c.iban ? (
                        <View style={styles.ibanRow}>
                          <Text style={styles.ibanText} numberOfLines={1} adjustsFontSizeToFit>
                            {c.iban}
                          </Text>
                          <TouchableOpacity
                            style={[styles.ibanCopyBtn, copiedId === c.id && styles.ibanCopyBtnDone]}
                            onPress={() => copyIban(c.id, c.iban!)}
                            hitSlop={{ top: 6, bottom: 6, left: 6, right: 6 }}
                          >
                            <Feather
                              name={copiedId === c.id ? "check" : "copy"}
                              size={12}
                              color={copiedId === c.id ? "#FFFFFF" : colors.primary}
                            />
                          </TouchableOpacity>
                        </View>
                      ) : null}
                      {activeTab === "credit" && c.statementDay ? (
                        <Text style={styles.cardSub}>
                          {t("bankInfo.statementInfo", { day: c.statementDay })}
                          {c.dueDay ? t("bankInfo.dueDateInfo", { day: c.dueDay }) : ""}
                        </Text>
                      ) : null}
                    </View>
                    <View style={styles.cardBtns}>
                      <TouchableOpacity style={styles.iconBtn} onPress={() => openEdit(c)}>
                        <Feather name="edit-2" size={14} color={colors.foreground} />
                      </TouchableOpacity>
                      <TouchableOpacity style={styles.iconBtn} onPress={() => handleDelete(c)}>
                        <Feather name="trash-2" size={14} color={colors.expense} />
                      </TouchableOpacity>
                    </View>
                  </View>
                ))
              )}
            </View>
          </ScrollView>
        </View>
      </View>

      {/* Add / Edit Form Modal */}
      <Modal visible={formVisible} transparent animationType="fade" onRequestClose={closeForm}>
        <KeyboardAvoidingView
          behavior={Platform.OS === "ios" ? "padding" : "height"}
          style={{ flex: 1 }}
        >
        <Pressable style={styles.formOverlay} onPress={closeForm}>
          <Pressable style={styles.formCard} onPress={(e) => e.stopPropagation()}>
            <ScrollView showsVerticalScrollIndicator={false} keyboardShouldPersistTaps="handled">
              <Text style={styles.formTitle}>
                {editId
                  ? (activeTab === "credit" ? t("bankInfo.editCredit") : t("bankInfo.editDemand"))
                  : (activeTab === "credit" ? t("bankInfo.newCredit") : t("bankInfo.newDemand"))}
              </Text>

              <Text style={styles.label}>
                {activeTab === "credit" ? t("bankInfo.cardName") : t("bankInfo.accountName")}
              </Text>
              <TextInput
                style={styles.input}
                value={formName}
                onChangeText={setFormName}
                placeholder={activeTab === "credit" ? t("bankInfo.creditPlaceholder") : t("bankInfo.demandPlaceholder")}
                placeholderTextColor={colors.mutedForeground}
              />

              <Text style={styles.label}>{t("bankInfo.bankLabel")}</Text>
              {formManualBank ? (
                <>
                  <TextInput
                    style={styles.input}
                    value={formBank}
                    onChangeText={setFormBank}
                    placeholder={t("bankInfo.bankEnterPlaceholder")}
                    placeholderTextColor={colors.mutedForeground}
                  />
                  <TouchableOpacity style={styles.manualLink} onPress={() => { setFormManualBank(false); setFormBank(""); }}>
                    <Text style={styles.manualLinkText}>{t("bankInfo.selectFromList")}</Text>
                  </TouchableOpacity>
                </>
              ) : (
                <>
                  <TouchableOpacity style={styles.selector} onPress={() => setFormBankPickerOpen((v) => !v)}>
                    <Text style={styles.selectorText}>{formBank || t("bankInfo.selectBank")}</Text>
                    <Feather name={formBankPickerOpen ? "chevron-up" : "chevron-down"} size={16} color={colors.mutedForeground} />
                  </TouchableOpacity>
                  {formBankPickerOpen && (
                    <ScrollView style={styles.bankList} nestedScrollEnabled keyboardShouldPersistTaps="handled">
                      {BANKS.map((b) => (
                        <TouchableOpacity
                          key={b}
                          style={styles.bankRow}
                          onPress={() => { setFormBank(b); setFormBankPickerOpen(false); Haptics.selectionAsync(); }}
                        >
                          <Text style={styles.bankRowText}>{b}</Text>
                        </TouchableOpacity>
                      ))}
                    </ScrollView>
                  )}
                  <TouchableOpacity style={styles.manualLink} onPress={() => { setFormManualBank(true); setFormBank(""); }}>
                    <Text style={styles.manualLinkText}>{t("bankInfo.enterManually")}</Text>
                  </TouchableOpacity>
                </>
              )}

              {activeTab === "credit" && (
                <>
                  <Text style={styles.label}>{t("bankInfo.cardLast4Label")}</Text>
                  <TextInput
                    style={styles.input}
                    value={formLast4}
                    onChangeText={(raw) => setFormLast4(raw.replace(/\D/g, "").slice(0, 4))}
                    placeholder="1234"
                    placeholderTextColor={colors.mutedForeground}
                    keyboardType="numeric"
                    maxLength={4}
                  />

                  <Text style={styles.label}>{t("bankInfo.statementDayLabel")}</Text>
                  <TextInput
                    style={styles.input}
                    value={formStatementDay}
                    onChangeText={(raw) => {
                      const cleaned = raw.replace(/\D/g, "").slice(0, 2);
                      if (cleaned === "") {
                        setFormStatementDay("");
                        return;
                      }
                      const n = parseInt(cleaned, 10);
                      if (n > 31) setFormStatementDay("31");
                      else setFormStatementDay(cleaned);
                    }}
                    placeholder="örn. 20"
                    placeholderTextColor={colors.mutedForeground}
                    keyboardType="numeric"
                    maxLength={2}
                  />

                  <Text style={styles.label}>{t("bankInfo.dueDateLabel")}</Text>
                  <View style={[styles.input, styles.readonlyInput]}>
                    <Text style={styles.readonlyText}>
                      {(() => {
                        const raw = formStatementDay.trim();
                        if (!raw) return t("bankInfo.enterStatementFirst");
                        const n = parseInt(raw, 10);
                        const due = computeDueDay(n);
                        return due ? t("bankInfo.dueDayOfMonth", { day: due }) : "—";
                      })()}
                    </Text>
                  </View>
                </>
              )}

              {activeTab === "demand" && (
                <>
                  <Text style={styles.label}>{t("bankInfo.ibanLabel")}</Text>
                  <TextInput
                    style={styles.input}
                    value={formIban}
                    onChangeText={(raw) => setFormIban(raw.toUpperCase().replace(/[^A-Z0-9]/g, "").slice(0, 26))}
                    placeholder="TR33 0006 1005 1978 6457 8413 26"
                    placeholderTextColor={colors.mutedForeground}
                    keyboardType="default"
                    autoCapitalize="characters"
                  />
                </>
              )}

              <View style={styles.formActions}>
                <TouchableOpacity style={styles.cancelBtn} onPress={closeForm}>
                  <Text style={styles.cancelBtnText}>{t("bankInfo.cancelLabel")}</Text>
                </TouchableOpacity>
                <TouchableOpacity style={styles.saveBtn} onPress={submitForm}>
                  <Text style={styles.saveBtnText}>{t("common.save")}</Text>
                </TouchableOpacity>
              </View>
            </ScrollView>
          </Pressable>
        </Pressable>
        </KeyboardAvoidingView>
      </Modal>
    </Modal>
  );
}
