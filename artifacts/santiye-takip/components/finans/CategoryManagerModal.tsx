import React, { useEffect, useMemo, useRef, useState } from "react";
import {
  Alert,
  FlatList,
  Keyboard,
  Modal,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  TouchableWithoutFeedback,
  View,
} from "react-native";
import { Feather } from "@expo/vector-icons";

import { useBudget } from "@/context/finans/BudgetContext";
import { BANKS, DEBT_CATEGORIES, EXPENSE_CATEGORIES, INCOME_CATEGORIES } from "@/utils/finans/categories";
import { useTranslation } from "react-i18next";

type Tab = "expense" | "income" | "debt" | "bank";

interface Props {
  visible: boolean;
  onClose: () => void;
}

type DialogMode = "add" | "rename";

export default function CategoryManagerModal({ visible, onClose }: Props) {
  const { t } = useTranslation();

  const TABS: { key: Tab; label: string }[] = [
    { key: "expense", label: t("categoryMgr.tabExpense") },
    { key: "income",  label: t("categoryMgr.tabIncome") },
    { key: "debt",    label: t("categoryMgr.tabDebt") },
    { key: "bank",    label: t("categoryMgr.tabBank") },
  ];
  const TAB_TITLES: Record<Tab, string> = {
    expense: t("categoryMgr.addExpenseTitle"),
    income:  t("categoryMgr.addIncomeTitle"),
    debt:    t("categoryMgr.addDebtTitle"),
    bank:    t("categoryMgr.addBankTitle"),
  };
  const TAB_NOUN: Record<Tab, string> = {
    expense: t("categoryMgr.nounCategory"),
    income:  t("categoryMgr.nounCategory"),
    debt:    t("categoryMgr.nounCategory"),
    bank:    t("categoryMgr.nounBank"),
  };

  const {
    expenseCategoryList,
    addExpenseCategory,
    removeExpenseCategory,
    renameOrMergeExpenseCategory,
    incomeCategoryList,
    addIncomeCategory,
    removeIncomeCategory,
    renameOrMergeIncomeCategory,
    allDebtCategories,
    addDebtCategory,
    removeDebtCategory,
    renameOrMergeDebtCategory,
    allBanks,
    addBank,
    removeBank,
    renameOrMergeBank,
    transactions,
    debts,
    bankLimits,
    savedCards,
  } = useBudget();

  const [activeTab, setActiveTab] = useState<Tab>("expense");

  // Add / Rename dialog (paylaşılan)
  const [dialogMode, setDialogMode] = useState<DialogMode>("add");
  const [dialogVisible, setDialogVisible] = useState(false);
  const [draftLabel, setDraftLabel] = useState("");
  const [renameSource, setRenameSource] = useState<string | null>(null);
  const [kbHeight, setKbHeight] = useState(0);
  const inputRef = useRef<TextInput>(null);

  // Action sheet (her satır için)
  const [actionItem, setActionItem] = useState<string | null>(null);

  // Birleştirme seçici
  const [mergeFrom, setMergeFrom] = useState<string | null>(null);

  useEffect(() => {
    const showEvent = Platform.OS === "ios" ? "keyboardWillShow" : "keyboardDidShow";
    const hideEvent = Platform.OS === "ios" ? "keyboardWillHide" : "keyboardDidHide";
    const show = Keyboard.addListener(showEvent, (e) => setKbHeight(e.endCoordinates.height));
    const hide = Keyboard.addListener(hideEvent, () => setKbHeight(0));
    return () => { show.remove(); hide.remove(); };
  }, []);

  // Sekme değişince tüm overlay'leri kapat
  useEffect(() => {
    setActionItem(null);
    setMergeFrom(null);
  }, [activeTab]);

  // Modal kapanırken tüm geçici UI durumlarını temizle (stale reopen önlemi)
  useEffect(() => {
    if (!visible) {
      setActionItem(null);
      setMergeFrom(null);
      setDialogVisible(false);
      setDraftLabel("");
      setRenameSource(null);
      setActiveTab("expense");
    }
  }, [visible]);

  const defaultExpenseLabels = EXPENSE_CATEGORIES.map((c) => c.label);
  const defaultIncomeLabels = INCOME_CATEGORIES.map((c) => c.label);
  const defaultDebtLabels = DEBT_CATEGORIES.map((c) => c.label);

  // ── Kullanım sayıları (gerçek veriden hesaplanır) ─────────────────────
  const expenseUsage = useMemo(() => {
    const m: Record<string, number> = {};
    for (const tx of transactions) {
      if (tx.type === "expense") m[tx.category] = (m[tx.category] || 0) + 1;
    }
    return m;
  }, [transactions]);

  const incomeUsage = useMemo(() => {
    const m: Record<string, number> = {};
    for (const tx of transactions) {
      if (tx.type === "income") m[tx.category] = (m[tx.category] || 0) + 1;
    }
    return m;
  }, [transactions]);

  const debtUsage = useMemo(() => {
    const m: Record<string, number> = {};
    for (const d of debts) m[d.category] = (m[d.category] || 0) + 1;
    return m;
  }, [debts]);

  const bankUsage = useMemo(() => {
    const m: Record<string, number> = {};
    for (const tx of transactions) {
      if (tx.bank) m[tx.bank] = (m[tx.bank] || 0) + 1;
    }
    for (const bl of bankLimits) {
      m[bl.bank] = (m[bl.bank] || 0) + 1;
      if (bl.institution) m[bl.institution] = (m[bl.institution] || 0) + 1;
    }
    for (const sc of savedCards) m[sc.bank] = (m[sc.bank] || 0) + 1;
    return m;
  }, [transactions, bankLimits, savedCards]);

  function currentList(): string[] {
    if (activeTab === "expense") return expenseCategoryList;
    if (activeTab === "income") return incomeCategoryList;
    if (activeTab === "bank") return allBanks;
    return allDebtCategories.map((c) => c.label);
  }

  function currentUsage(): Record<string, number> {
    if (activeTab === "expense") return expenseUsage;
    if (activeTab === "income") return incomeUsage;
    if (activeTab === "bank") return bankUsage;
    return debtUsage;
  }

  function isDefault(label: string): boolean {
    if (activeTab === "expense") return defaultExpenseLabels.includes(label);
    if (activeTab === "income") return defaultIncomeLabels.includes(label);
    if (activeTab === "bank") return BANKS.includes(label);
    return defaultDebtLabels.includes(label);
  }

  // Banka tabında varsayılanlar değiştirilemez (silinemez de)
  function canModify(label: string): boolean {
    if (activeTab === "bank") return !BANKS.includes(label);
    return true;
  }

  // ── Dialog yardımcıları ──────────────────────────────────────────────
  function openAddDialog() {
    setDialogMode("add");
    setRenameSource(null);
    setDraftLabel("");
    setDialogVisible(true);
    setTimeout(() => inputRef.current?.focus(), 80);
  }

  function openRenameDialog(label: string) {
    setActionItem(null);
    setDialogMode("rename");
    setRenameSource(label);
    setDraftLabel(label);
    setDialogVisible(true);
    setTimeout(() => inputRef.current?.focus(), 80);
  }

  function closeDialog() {
    inputRef.current?.blur();
    setDialogVisible(false);
    setDraftLabel("");
    setRenameSource(null);
  }

  function performAdd(label: string) {
    if (activeTab === "expense") addExpenseCategory(label);
    else if (activeTab === "income") addIncomeCategory(label);
    else if (activeTab === "bank") addBank(label);
    else addDebtCategory(label);
  }

  function performRenameOrMerge(from: string, to: string) {
    if (activeTab === "expense") renameOrMergeExpenseCategory(from, to);
    else if (activeTab === "income") renameOrMergeIncomeCategory(from, to);
    else if (activeTab === "bank") renameOrMergeBank(from, to);
    else renameOrMergeDebtCategory(from, to);
  }

  function performRemove(label: string) {
    if (activeTab === "expense") removeExpenseCategory(label);
    else if (activeTab === "income") removeIncomeCategory(label);
    else if (activeTab === "bank") removeBank(label);
    else removeDebtCategory(label);
  }

  function confirmDialog() {
    const trimmed = draftLabel.trim();
    if (!trimmed) return;

    if (dialogMode === "add") {
      if (currentList().includes(trimmed)) {
        Alert.alert(t("categoryMgr.alertWarning"), t("categoryMgr.alertAlreadyExists"));
        return;
      }
      performAdd(trimmed);
      closeDialog();
      return;
    }

    // rename
    const from = renameSource;
    if (!from) return;
    if (trimmed === from) {
      closeDialog();
      return;
    }
    const exists = currentList().includes(trimmed);
    if (exists) {
      // Birleştirme onayı
      const usingCount = currentUsage()[from] ?? 0;
      Alert.alert(
        t("categoryMgr.alertNameExists"),
        t("categoryMgr.alertMergeConfirm", { name: trimmed, from, noun: TAB_NOUN[activeTab] }) +
          (usingCount > 0 ? ` (${t("categoryMgr.alertRecordsMoved", { count: usingCount })})` : ""),
        [
          { text: t("common.cancel"), style: "cancel" },
          {
            text: t("categoryMgr.merge"),
            style: "destructive",
            onPress: () => {
              performRenameOrMerge(from, trimmed);
              closeDialog();
            },
          },
        ]
      );
      return;
    }
    performRenameOrMerge(from, trimmed);
    closeDialog();
  }

  function handleRemove(label: string) {
    setActionItem(null);
    if (activeTab === "bank" && BANKS.includes(label)) {
      Alert.alert(t("categoryMgr.defaultBankTitle"), t("categoryMgr.defaultBankMsg"));
      return;
    }
    const usingCount = currentUsage()[label] ?? 0;
    Alert.alert(
      activeTab === "bank" ? t("categoryMgr.deleteBankTitle") : t("categoryMgr.deleteCategoryTitle"),
      usingCount > 0
        ? t("categoryMgr.deleteConfirmWithUsage", { label, noun: TAB_NOUN[activeTab], count: usingCount })
        : t("categoryMgr.deleteConfirm", { label, noun: TAB_NOUN[activeTab] }),
      [
        { text: t("common.cancel"), style: "cancel" },
        {
          text: t("common.delete"),
          style: "destructive",
          onPress: () => performRemove(label),
        },
      ]
    );
  }

  function openMergePicker(label: string) {
    setActionItem(null);
    setMergeFrom(label);
  }

  function performMergeTo(target: string) {
    if (!mergeFrom) return;
    const from = mergeFrom;
    const usingCount = currentUsage()[from] ?? 0;
    Alert.alert(
      t("categoryMgr.merge"),
      `"${from}" → "${target}"${usingCount > 0 ? `\n${t("categoryMgr.alertRecordsMoved", { count: usingCount })}` : ""}`,
      [
        { text: t("common.cancel"), style: "cancel" },
        {
          text: t("categoryMgr.merge"),
          style: "destructive",
          onPress: () => {
            performRenameOrMerge(from, target);
            setMergeFrom(null);
          },
        },
      ]
    );
  }

  // ── Kullanılmayanları temizle ────────────────────────────────────────
  const unusedItems = useMemo(() => {
    const usage = currentUsage();
    const list = currentList();
    return list.filter((l) => (usage[l] ?? 0) === 0 && canModify(l));
    // canModify'a göre default banka korunur
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [activeTab, expenseCategoryList, incomeCategoryList, allBanks, allDebtCategories, expenseUsage, incomeUsage, bankUsage, debtUsage]);

  function handleCleanupUnused() {
    if (unusedItems.length === 0) return;
    Alert.alert(
      t("categoryMgr.cleanupTitle"),
      t("categoryMgr.cleanupMsg", { count: unusedItems.length, noun: TAB_NOUN[activeTab] }),
      [
        { text: t("common.cancel"), style: "cancel" },
        {
          text: t("categoryMgr.cleanupDeleteBtn", { count: unusedItems.length }),
          style: "destructive",
          onPress: () => {
            unusedItems.forEach((label) => performRemove(label));
          },
        },
      ]
    );
  }

  // Kullanım sayısına göre azalan, eşitse alfabetik sırala (yönetim ekranı için)
  const sortedList = useMemo(() => {
    const usage = currentUsage();
    return [...currentList()].sort((a, b) => {
      const ua = usage[a] ?? 0;
      const ub = usage[b] ?? 0;
      if (ub !== ua) return ub - ua;
      return a.localeCompare(b, "tr");
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [activeTab, expenseCategoryList, incomeCategoryList, allBanks, allDebtCategories, expenseUsage, incomeUsage, bankUsage, debtUsage]);

  const mergeCandidates = useMemo(() => {
    if (!mergeFrom) return [];
    return sortedList.filter((l) => l !== mergeFrom);
  }, [mergeFrom, sortedList]);

  return (
    <Modal
      visible={visible}
      animationType="slide"
      presentationStyle="pageSheet"
      onRequestClose={onClose}
    >
      <View style={styles.root}>
        {/* ── Header ── */}
        <View style={styles.header}>
          <Text style={styles.title}>{t("categoryMgr.title")}</Text>
          <TouchableOpacity
            onPress={onClose}
            hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
          >
            <Feather name="x" size={22} color="#CBD5E0" />
          </TouchableOpacity>
        </View>

        {/* ── Tabs ── */}
        <View style={styles.tabRow}>
          {TABS.map((t) => (
            <TouchableOpacity
              key={t.key}
              style={[styles.tab, activeTab === t.key && styles.tabActive]}
              onPress={() => setActiveTab(t.key)}
            >
              <Text
                style={[
                  styles.tabLabel,
                  activeTab === t.key && styles.tabLabelActive,
                ]}
              >
                {t.label}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        {/* ── Bank tab info hint ── */}
        {activeTab === "bank" && (
          <View style={styles.hintRow}>
            <Feather name="info" size={13} color="#4A90E2" style={{ marginRight: 6 }} />
            <Text style={styles.hintText}>
              {t("categoryMgr.bankHint")}
            </Text>
          </View>
        )}

        {/* ── Kullanılmayanları temizle butonu ── */}
        {unusedItems.length > 0 && (
          <TouchableOpacity
            style={styles.cleanupBtn}
            onPress={handleCleanupUnused}
            activeOpacity={0.85}
          >
            <Feather name="trash" size={14} color="#FC8181" style={{ marginRight: 8 }} />
            <Text style={styles.cleanupBtnText}>
              {t("categoryMgr.cleanupBtn", { count: unusedItems.length })}
            </Text>
          </TouchableOpacity>
        )}

        {/* ── List ── */}
        <FlatList
          data={sortedList}
          keyExtractor={(item) => item}
          style={styles.list}
          contentContainerStyle={{ paddingBottom: 100 }}
          keyboardShouldPersistTaps="handled"
          renderItem={({ item }) => {
            const def = isDefault(item);
            const count = currentUsage()[item] ?? 0;
            const locked = activeTab === "bank" && def;
            return (
              <View style={styles.row}>
                <Feather
                  name={def ? "bookmark" : "tag"}
                  size={16}
                  color={def ? "#00C896" : "#63B3ED"}
                  style={{ marginRight: 10 }}
                />
                <Text style={styles.rowLabel} numberOfLines={1}>{item}</Text>

                {/* Kullanım badge */}
                {count > 0 && (
                  <View style={styles.countBadge}>
                    <Text style={styles.countBadgeText}>{count}</Text>
                  </View>
                )}
                {count === 0 && !locked && (
                  <View style={styles.zeroBadge}>
                    <Text style={styles.zeroBadgeText}>0</Text>
                  </View>
                )}

                {locked ? (
                  <View style={styles.lockBadge}>
                    <Feather name="lock" size={12} color="#4A5568" />
                  </View>
                ) : (
                  <TouchableOpacity
                    onPress={() => setActionItem(item)}
                    hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
                    style={{ marginLeft: 4 }}
                  >
                    <Feather name="more-vertical" size={18} color="#90B4E0" />
                  </TouchableOpacity>
                )}
              </View>
            );
          }}
          ListEmptyComponent={
            <Text style={styles.empty}>
              {activeTab === "bank" ? t("categoryMgr.emptyBank") : t("categoryMgr.emptyCategory")}
            </Text>
          }
        />

        {/* ── FAB ── */}
        <TouchableOpacity style={styles.fab} onPress={openAddDialog} activeOpacity={0.85}>
          <Feather name="plus" size={24} color="#0B1E33" />
        </TouchableOpacity>

        {/* ── Action sheet (long-press veya 3-dot) ── */}
        {actionItem && (
          <View style={StyleSheet.absoluteFillObject} pointerEvents="box-none">
            <TouchableWithoutFeedback onPress={() => setActionItem(null)}>
              <View style={styles.backdrop} />
            </TouchableWithoutFeedback>
            <View style={styles.sheetWrapper}>
              <View style={styles.sheetCard}>
                <Text style={styles.sheetTitle} numberOfLines={1}>{actionItem}</Text>
                <TouchableOpacity
                  style={styles.sheetItem}
                  onPress={() => openRenameDialog(actionItem)}
                >
                  <Feather name="edit-3" size={18} color="#90B4E0" />
                  <Text style={styles.sheetItemText}>{t("categoryMgr.rename")}</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={styles.sheetItem}
                  onPress={() => openMergePicker(actionItem)}
                >
                  <Feather name="git-merge" size={18} color="#90B4E0" />
                  <Text style={styles.sheetItemText}>{t("categoryMgr.mergeInto", { noun: TAB_NOUN[activeTab] })}</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={styles.sheetItem}
                  onPress={() => handleRemove(actionItem)}
                >
                  <Feather name="trash-2" size={18} color="#FC8181" />
                  <Text style={[styles.sheetItemText, { color: "#FC8181" }]}>{t("common.delete")}</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={[styles.sheetItem, { borderTopWidth: 1, borderTopColor: "#1A3A5C" }]}
                  onPress={() => setActionItem(null)}
                >
                  <Feather name="x" size={18} color="#4A5568" />
                  <Text style={[styles.sheetItemText, { color: "#4A5568" }]}>{t("common.cancel")}</Text>
                </TouchableOpacity>
              </View>
            </View>
          </View>
        )}

        {/* ── Birleştirme seçici ── */}
        {mergeFrom && (
          <View style={StyleSheet.absoluteFillObject} pointerEvents="box-none">
            <TouchableWithoutFeedback onPress={() => setMergeFrom(null)}>
              <View style={styles.backdrop} />
            </TouchableWithoutFeedback>
            <View style={styles.sheetWrapper}>
              <View style={[styles.sheetCard, { maxHeight: "70%" }]}>
                <Text style={styles.sheetTitle} numberOfLines={1}>
                  {t("categoryMgr.mergePickerTitle", { from: mergeFrom })}
                </Text>
                <ScrollView style={{ maxHeight: 360 }}>
                  {mergeCandidates.map((target) => {
                    const tCount = currentUsage()[target] ?? 0;
                    return (
                      <TouchableOpacity
                        key={target}
                        style={styles.mergeRow}
                        onPress={() => performMergeTo(target)}
                      >
                        <Feather name="tag" size={15} color="#63B3ED" style={{ marginRight: 10 }} />
                        <Text style={styles.mergeRowLabel} numberOfLines={1}>{target}</Text>
                        {tCount > 0 && (
                          <View style={styles.countBadge}>
                            <Text style={styles.countBadgeText}>{tCount}</Text>
                          </View>
                        )}
                      </TouchableOpacity>
                    );
                  })}
                  {mergeCandidates.length === 0 && (
                    <Text style={styles.empty}>{t("categoryMgr.noMergeCandidates", { noun: TAB_NOUN[activeTab] })}</Text>
                  )}
                </ScrollView>
                <TouchableOpacity
                  style={[styles.sheetItem, { borderTopWidth: 1, borderTopColor: "#1A3A5C", marginTop: 4 }]}
                  onPress={() => setMergeFrom(null)}
                >
                  <Feather name="x" size={18} color="#4A5568" />
                  <Text style={[styles.sheetItemText, { color: "#4A5568" }]}>{t("common.cancel")}</Text>
                </TouchableOpacity>
              </View>
            </View>
          </View>
        )}

        {/* ── Inline dialog overlay (Add / Rename) ── */}
        {dialogVisible && (
          <View style={StyleSheet.absoluteFillObject} pointerEvents="box-none">
            <TouchableWithoutFeedback onPress={closeDialog}>
              <View style={styles.backdrop} />
            </TouchableWithoutFeedback>

            <View
              style={[styles.kavWrapper, { bottom: kbHeight + 24 }]}
              pointerEvents="box-none"
            >
              <TouchableOpacity activeOpacity={1} style={styles.dialogCard}>
                <Text style={styles.dialogTitle}>
                  {dialogMode === "add"
                    ? TAB_TITLES[activeTab]
                    : t("categoryMgr.renameTitle", { name: renameSource })}
                </Text>

                <TextInput
                  ref={inputRef}
                  style={styles.dialogInput}
                  value={draftLabel}
                  onChangeText={setDraftLabel}
                  placeholder={
                    activeTab === "bank"
                      ? t("categoryMgr.bankNamePlaceholder")
                      : t("categoryMgr.categoryNamePlaceholder")
                  }
                  placeholderTextColor="#4A5568"
                  returnKeyType="done"
                  onSubmitEditing={confirmDialog}
                  autoCorrect={false}
                  selectTextOnFocus={dialogMode === "rename"}
                />

                {!!draftLabel.trim() && (
                  <View style={styles.previewRow}>
                    <Text style={styles.previewLabel}>{t("categoryMgr.preview")}</Text>
                    <View style={styles.previewChip}>
                      <Feather
                        name={activeTab === "bank" ? "home" : "tag"}
                        size={13}
                        color="#00C896"
                      />
                      <Text style={styles.previewChipText}>{draftLabel.trim()}</Text>
                    </View>
                  </View>
                )}

                {dialogMode === "rename" &&
                  !!draftLabel.trim() &&
                  draftLabel.trim() !== renameSource &&
                  currentList().includes(draftLabel.trim()) && (
                    <View style={styles.warnRow}>
                      <Feather name="alert-triangle" size={13} color="#F6AD55" />
                      <Text style={styles.warnText}>
                        {t("categoryMgr.mergeWarn")}
                      </Text>
                    </View>
                  )}

                <View style={styles.dialogBtnRow}>
                  <TouchableOpacity style={styles.cancelBtn} onPress={closeDialog}>
                    <Text style={styles.cancelBtnText}>{t("common.cancel")}</Text>
                  </TouchableOpacity>
                  <TouchableOpacity
                    style={[
                      styles.confirmBtn,
                      !draftLabel.trim() && styles.confirmBtnDisabled,
                    ]}
                    onPress={confirmDialog}
                    disabled={!draftLabel.trim()}
                  >
                    <Text style={styles.confirmBtnText}>
                      {dialogMode === "add" ? t("common.add") : t("common.save")}
                    </Text>
                  </TouchableOpacity>
                </View>
              </TouchableOpacity>
            </View>
          </View>
        )}
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: "#0B1E33",
  },
  header: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    paddingHorizontal: 20,
    paddingTop: 20,
    paddingBottom: 12,
    borderBottomWidth: 1,
    borderBottomColor: "#1A3A5C",
  },
  title: {
    fontSize: 20,
    fontWeight: "700",
    color: "#E2E8F0",
  },
  tabRow: {
    flexDirection: "row",
    marginHorizontal: 20,
    marginTop: 16,
    marginBottom: 8,
    backgroundColor: "#112238",
    borderRadius: 12,
    padding: 4,
  },
  tab: {
    flex: 1,
    paddingVertical: 8,
    borderRadius: 10,
    alignItems: "center",
  },
  tabActive: {
    backgroundColor: "#00C896",
  },
  tabLabel: {
    fontSize: 13,
    fontWeight: "600",
    color: "#718096",
  },
  tabLabelActive: {
    color: "#0B1E33",
  },
  hintRow: {
    flexDirection: "row",
    alignItems: "center",
    marginHorizontal: 20,
    marginBottom: 8,
    backgroundColor: "rgba(74,144,226,0.08)",
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderWidth: 1,
    borderColor: "rgba(74,144,226,0.2)",
  },
  hintText: {
    flex: 1,
    fontSize: 12,
    color: "#90B4E0",
    lineHeight: 17,
  },
  cleanupBtn: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    marginHorizontal: 20,
    marginBottom: 8,
    paddingHorizontal: 12,
    paddingVertical: 8,
    backgroundColor: "rgba(252,129,129,0.08)",
    borderRadius: 8,
    borderWidth: 1,
    borderColor: "rgba(252,129,129,0.25)",
  },
  cleanupBtnText: {
    fontSize: 12,
    fontWeight: "600",
    color: "#FC8181",
  },
  list: {
    flex: 1,
    paddingHorizontal: 20,
    paddingTop: 8,
  },
  row: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: "#112238",
    borderRadius: 10,
    paddingHorizontal: 14,
    paddingVertical: 12,
    marginBottom: 8,
  },
  rowLabel: {
    flex: 1,
    fontSize: 15,
    color: "#E2E8F0",
  },
  countBadge: {
    minWidth: 24,
    height: 22,
    borderRadius: 11,
    paddingHorizontal: 8,
    backgroundColor: "rgba(0,200,150,0.15)",
    borderWidth: 1,
    borderColor: "rgba(0,200,150,0.35)",
    alignItems: "center",
    justifyContent: "center",
    marginRight: 8,
  },
  countBadgeText: {
    fontSize: 11,
    fontWeight: "700",
    color: "#00C896",
  },
  zeroBadge: {
    minWidth: 24,
    height: 22,
    borderRadius: 11,
    paddingHorizontal: 8,
    backgroundColor: "rgba(74,85,104,0.25)",
    alignItems: "center",
    justifyContent: "center",
    marginRight: 8,
  },
  zeroBadgeText: {
    fontSize: 11,
    fontWeight: "700",
    color: "#4A5568",
  },
  lockBadge: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: "#1A3A5C",
    alignItems: "center",
    justifyContent: "center",
  },
  empty: {
    textAlign: "center",
    color: "#4A5568",
    marginTop: 32,
    fontSize: 14,
  },
  fab: {
    position: "absolute",
    bottom: 36,
    right: 24,
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: "#00C896",
    alignItems: "center",
    justifyContent: "center",
    shadowColor: "#00C896",
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.4,
    shadowRadius: 8,
    elevation: 8,
  },
  backdrop: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "rgba(0,0,0,0.65)",
  },
  kavWrapper: {
    position: "absolute",
    left: 0,
    right: 0,
    paddingHorizontal: 20,
  },
  dialogCard: {
    backgroundColor: "#112238",
    borderRadius: 20,
    padding: 24,
    borderWidth: 1,
    borderColor: "#1A3A5C",
  },
  dialogTitle: {
    fontSize: 17,
    fontWeight: "700",
    color: "#E2E8F0",
    marginBottom: 16,
  },
  dialogInput: {
    backgroundColor: "#0B1E33",
    borderRadius: 12,
    paddingHorizontal: 14,
    paddingVertical: 13,
    fontSize: 16,
    color: "#E2E8F0",
    borderWidth: 1.5,
    borderColor: "#1A3A5C",
  },
  previewRow: {
    flexDirection: "row",
    alignItems: "center",
    marginTop: 12,
    gap: 10,
  },
  previewLabel: {
    fontSize: 12,
    fontWeight: "600",
    color: "#4A5568",
    letterSpacing: 0.4,
    textTransform: "uppercase",
  },
  previewChip: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    backgroundColor: "rgba(0,200,150,0.12)",
    borderWidth: 1.5,
    borderColor: "#00C896",
    paddingHorizontal: 12,
    paddingVertical: 5,
    borderRadius: 20,
  },
  previewChipText: {
    fontSize: 13,
    fontWeight: "600",
    color: "#00C896",
  },
  warnRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    marginTop: 10,
    paddingHorizontal: 10,
    paddingVertical: 6,
    backgroundColor: "rgba(246,173,85,0.10)",
    borderRadius: 8,
  },
  warnText: {
    fontSize: 12,
    color: "#F6AD55",
    fontWeight: "500",
  },
  dialogBtnRow: {
    flexDirection: "row",
    marginTop: 20,
    gap: 10,
  },
  cancelBtn: {
    flex: 1,
    paddingVertical: 13,
    borderRadius: 12,
    alignItems: "center",
    backgroundColor: "#1A3A5C",
  },
  cancelBtnText: {
    fontSize: 15,
    fontWeight: "600",
    color: "#CBD5E0",
  },
  confirmBtn: {
    flex: 1,
    paddingVertical: 13,
    borderRadius: 12,
    alignItems: "center",
    backgroundColor: "#00C896",
  },
  confirmBtnDisabled: {
    opacity: 0.4,
  },
  confirmBtnText: {
    fontSize: 15,
    fontWeight: "700",
    color: "#0B1E33",
  },
  // Action sheet styles
  sheetWrapper: {
    position: "absolute",
    left: 0,
    right: 0,
    bottom: 0,
    paddingHorizontal: 16,
    paddingBottom: 32,
  },
  sheetCard: {
    backgroundColor: "#112238",
    borderRadius: 16,
    padding: 8,
    borderWidth: 1,
    borderColor: "#1A3A5C",
  },
  sheetTitle: {
    fontSize: 13,
    fontWeight: "700",
    color: "#90B4E0",
    paddingHorizontal: 14,
    paddingTop: 12,
    paddingBottom: 8,
    textTransform: "uppercase",
    letterSpacing: 0.4,
  },
  sheetItem: {
    flexDirection: "row",
    alignItems: "center",
    gap: 14,
    paddingHorizontal: 14,
    paddingVertical: 14,
  },
  sheetItemText: {
    fontSize: 15,
    color: "#E2E8F0",
    fontWeight: "500",
  },
  mergeRow: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 14,
    paddingVertical: 12,
    borderRadius: 10,
    marginBottom: 4,
    backgroundColor: "#0B1E33",
  },
  mergeRowLabel: {
    flex: 1,
    fontSize: 14,
    color: "#E2E8F0",
  },
});
