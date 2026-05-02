/**
 * DebtWizard — 3 adımlı borç ekleme / düzenleme sihirbazı
 *
 * Adım 1 — Borç Türü & Alacaklı
 * Adım 2 — Tutar & Taksit Bilgileri
 * Adım 3 — Tarih & Not
 */

import { Feather } from "@expo/vector-icons";
import * as Haptics from "expo-haptics";
import React, { useEffect, useMemo, useRef, useState } from "react";
import {
  Animated,
  Keyboard,
  KeyboardEvent,
  Modal,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TextStyle,
  TouchableOpacity,
  View,
  ViewStyle,
} from "react-native";

import DatePickerSheet from "@/components/finans/DatePickerSheet";
import { Debt, useBudget } from "@/context/finans/BudgetContext";
import { useColors } from "@/hooks/finans/useColors";
import { BANKS } from "@/utils/finans/categories";
import { useFormatAmount } from "@/hooks/finans/useFormatAmount";
import { useTranslation } from "react-i18next";

// ── Helpers ──────────────────────────────────────────────────────────────────

function calcEndDate(startDate: Date, installments: number): Date {
  const d = new Date(startDate);
  d.setMonth(d.getMonth() + installments - 1);
  return d;
}

function monthsElapsed(startDate: Date): number {
  const today = new Date();
  let months =
    (today.getFullYear() - startDate.getFullYear()) * 12 +
    (today.getMonth() - startDate.getMonth());
  if (today.getDate() < startDate.getDate()) months -= 1;
  return Math.max(0, months);
}

// ── Debt type options ─────────────────────────────────────────────────────────

type DebtKind = "installment" | "single";

// ── Form State ────────────────────────────────────────────────────────────────

interface WizardForm {
  name: string;
  kind: DebtKind;
  category: string;
  creditor: string;
  amount: string;
  installmentAmount: string;
  totalInstallments: string;
  date: Date;
  statementDate: Date;
  note: string;
}

const emptyForm = (): WizardForm => ({
  name: "",
  kind: "installment",
  category: "Banka Kredisi",
  creditor: "",
  amount: "",
  installmentAmount: "",
  totalInstallments: "",
  date: new Date(),
  statementDate: new Date(),
  note: "",
});

function kindToCategory(kind: DebtKind): string {
  if (kind === "installment") return "Banka Kredisi";
  return "Diğer";
}

// ── Props ─────────────────────────────────────────────────────────────────────

interface Props {
  visible: boolean;
  editDebt?: Debt | null;
  onClose: () => void;
  onSaved?: () => void;
}

// ── Step indicator ────────────────────────────────────────────────────────────

function StepDots({ step, total }: { step: number; total: number }) {
  const colors = useColors();
  return (
    <View style={{ flexDirection: "row", gap: 6, alignItems: "center" }}>
      {Array.from({ length: total }).map((_, i) => (
        <View
          key={i}
          style={{
            width: i === step ? 20 : 6,
            height: 6,
            borderRadius: 3,
            backgroundColor: i <= step ? colors.primary : colors.border,
          } as ViewStyle}
        />
      ))}
    </View>
  );
}

// ── Main Component ────────────────────────────────────────────────────────────

export function DebtWizard({ visible, editDebt, onClose, onSaved }: Props) {
  const { t } = useTranslation();
  const colors = useColors();
  const formatAmount = useFormatAmount();
  const { addDebt, updateDebt, allDebtCategories, addDebtCategory } = useBudget();

  const DEBT_KINDS: { key: DebtKind; icon: string; label: string; desc: string }[] = [
    { key: "installment", icon: "repeat",       label: t("debtWizard.kindInstallmentLabel"), desc: t("debtWizard.kindInstallmentDesc") },
    { key: "single",      icon: "dollar-sign",  label: t("debtWizard.kindSingleLabel"),      desc: t("debtWizard.kindSingleDesc") },
  ];

  const [step, setStep] = useState(0);
  const [form, setForm] = useState<WizardForm>(emptyForm());
  const [bankListOpen, setBankListOpen] = useState(false);
  const [manualBank, setManualBank] = useState("");
  const [manualBankMode, setManualBankMode] = useState(false);
  const [newCatOpen, setNewCatOpen] = useState(false);
  const [newCatText, setNewCatText] = useState("");
  const [datePickerFor, setDatePickerFor] = useState<"date" | "statement" | null>(null);
  const [kbHeight, setKbHeight] = useState(0);
  const slideAnim = useRef(new Animated.Value(0)).current;

  // Klavye yüksekliğini dinle — KeyboardAvoidingView Modal içinde iOS'ta
  // güvenilir çalışmadığından doğrudan Keyboard API kullanıyoruz.
  useEffect(() => {
    const showEvent = Platform.OS === "ios" ? "keyboardWillShow" : "keyboardDidShow";
    const hideEvent = Platform.OS === "ios" ? "keyboardWillHide" : "keyboardDidHide";
    const onShow = (e: KeyboardEvent) => setKbHeight(e.endCoordinates.height);
    const onHide = () => setKbHeight(0);
    const s1 = Keyboard.addListener(showEvent, onShow);
    const s2 = Keyboard.addListener(hideEvent, onHide);
    return () => { s1.remove(); s2.remove(); };
  }, []);

  const isEdit = !!editDebt;
  const TOTAL_STEPS = 3;

  // ── Load edit data ──────────────────────────────────────────────────────

  useEffect(() => {
    if (!visible) return;
    if (editDebt) {
      const kind: DebtKind = editDebt.isInstallment ? "installment" : "single";
      setForm({
        name: editDebt.name,
        kind,
        category: editDebt.category,
        creditor: editDebt.creditor ?? "",
        amount: String(editDebt.amount),
        installmentAmount:
          editDebt.isInstallment && (editDebt.totalInstallments ?? 0) > 0
            ? String(editDebt.amount / editDebt.totalInstallments!)
            : "",
        totalInstallments: editDebt.totalInstallments
          ? String(editDebt.totalInstallments)
          : "",
        date: new Date(editDebt.date),
        statementDate: (() => {
          const d = new Date(editDebt.date);
          d.setDate(d.getDate() - 10);
          return d;
        })(),
        note: editDebt.note ?? "",
      });
    } else {
      setForm(emptyForm());
    }
    setStep(0);
    setBankListOpen(false);
    setManualBankMode(false);
    setNewCatOpen(false);
    setDatePickerFor(null);
  }, [visible, editDebt]);

  // ── Slide animation ─────────────────────────────────────────────────────

  const goTo = (next: number) => {
    const dir = next > step ? 1 : -1;
    Animated.sequence([
      Animated.timing(slideAnim, { toValue: -dir * 30, duration: 120, useNativeDriver: true }),
      Animated.timing(slideAnim, { toValue: dir * 30, duration: 0, useNativeDriver: true }),
      Animated.timing(slideAnim, { toValue: 0, duration: 180, useNativeDriver: true }),
    ]).start();
    setStep(next);
    Haptics.selectionAsync();
  };

  // ── Amount computations ──────────────────────────────────────────────────

  const amountInfo = useMemo(() => {
    const installCount = parseInt(form.totalInstallments, 10) || 0;
    const isInst = form.kind === "installment" && installCount > 1;
    const totalNum = parseFloat(form.amount.replace(",", ".")) || 0;
    const perNum = parseFloat(form.installmentAmount.replace(",", ".")) || 0;
    let error: string | null = null;
    let effectiveTotal = totalNum;
    let effectivePer = isInst && installCount > 0 ? totalNum / installCount : 0;

    if (isInst) {
      if (totalNum > 0 && perNum > 0) {
        const expected = perNum * installCount;
        if (Math.abs(expected - totalNum) > 0.01) {
          error = `${formatAmount(perNum)} × ${installCount} = ${formatAmount(expected)}, toplam ${formatAmount(totalNum)} girildi.`;
        } else {
          effectiveTotal = totalNum;
          effectivePer = perNum;
        }
      } else if (perNum > 0 && totalNum === 0) {
        effectiveTotal = perNum * installCount;
        effectivePer = perNum;
      } else if (totalNum > 0) {
        effectivePer = totalNum / installCount;
      }
    }
    return { effectiveTotal, effectivePer, error, isInst, installCount };
  }, [form.amount, form.installmentAmount, form.totalInstallments, form.kind]);

  // ── Step validation ──────────────────────────────────────────────────────

  const step1Valid = form.name.trim().length > 0;
  const step2Valid = amountInfo.effectiveTotal > 0 && !amountInfo.error;
  const allValid = step1Valid && step2Valid;

  // ── Save ──────────────────────────────────────────────────────────────────

  const handleSave = () => {
    if (!allValid) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
      return;
    }
    const amount = amountInfo.effectiveTotal;
    const parsedInst = parseInt(form.totalInstallments, 10);
    const totalInstallments =
      form.kind === "installment" && !isNaN(parsedInst) && parsedInst > 1
        ? parsedInst
        : undefined;
    const isInstallment = totalInstallments !== undefined;
    const computedEndDate = isInstallment
      ? calcEndDate(form.date, totalInstallments!)
      : undefined;
    const autoPaidInst = isInstallment
      ? Math.min(monthsElapsed(form.date), totalInstallments!)
      : 0;
    const perInst = isInstallment ? amount / totalInstallments! : amount;
    const autoPaidAmount = autoPaidInst * perInst;

    const payload = {
      name: form.name.trim(),
      category: kindToCategory(form.kind),
      creditor: form.creditor.trim() || undefined,
      amount,
      date: form.date.toISOString(),
      dueDate: computedEndDate?.toISOString(),
      isInstallment,
      totalInstallments,
      note: form.note.trim() || undefined,
    };

    if (editDebt) {
      const editingDebt = editDebt;
      let nextPaidAmount = editingDebt.paidAmount ?? 0;
      let nextPaidInstallments = editingDebt.paidInstallments ?? 0;
      if (isInstallment && totalInstallments) {
        nextPaidInstallments = Math.min(monthsElapsed(form.date), totalInstallments);
        nextPaidAmount = nextPaidInstallments * perInst;
      } else {
        nextPaidAmount = Math.min(nextPaidAmount, amount);
      }
      updateDebt(editDebt.id, { ...payload, paidAmount: nextPaidAmount, paidInstallments: nextPaidInstallments });
    } else {
      addDebt({ ...payload, paidAmount: autoPaidAmount, paidInstallments: autoPaidInst });
    }

    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    onClose();
    onSaved?.();
  };

  // ── Styles ────────────────────────────────────────────────────────────────

  const s = useMemo(
    () =>
      StyleSheet.create({
        backdrop: { flex: 1, backgroundColor: "rgba(0,0,0,0.55)" },
        sheet: {
          position: "absolute",
          bottom: 0,
          left: 0,
          right: 0,
          backgroundColor: colors.background,
          borderTopLeftRadius: 24,
          borderTopRightRadius: 24,
          maxHeight: "90%",
          paddingBottom: Platform.OS === "ios" ? 34 : 16,
          shadowColor: "#000",
          shadowOffset: { width: 0, height: -4 },
          shadowOpacity: 0.18,
          shadowRadius: 16,
          elevation: 12,
        },
        handle: {
          width: 40,
          height: 4,
          borderRadius: 2,
          backgroundColor: colors.border,
          alignSelf: "center",
          marginTop: 10,
          marginBottom: 4,
        },
        header: {
          flexDirection: "row",
          alignItems: "center",
          justifyContent: "space-between",
          paddingHorizontal: 20,
          paddingVertical: 14,
          borderBottomWidth: StyleSheet.hairlineWidth,
          borderBottomColor: colors.border,
        },
        headerTitle: {
          fontSize: 17,
          fontWeight: "800",
          color: colors.foreground,
        } as TextStyle,
        stepLabel: {
          fontSize: 11,
          fontWeight: "600",
          color: colors.mutedForeground,
          marginTop: 2,
        } as TextStyle,
        content: { paddingHorizontal: 20, paddingTop: 20 },
        sectionTitle: {
          fontSize: 13,
          fontWeight: "700",
          color: colors.mutedForeground,
          letterSpacing: 0.5,
          textTransform: "uppercase",
          marginBottom: 12,
        } as TextStyle,
        label: {
          fontSize: 13,
          fontWeight: "700",
          color: colors.foreground,
          marginBottom: 6,
          marginTop: 14,
        } as TextStyle,
        input: {
          backgroundColor: colors.muted,
          borderRadius: 14,
          paddingHorizontal: 14,
          paddingVertical: 12,
          fontSize: 15,
          color: colors.foreground,
          borderWidth: 1.5,
          borderColor: colors.border,
        },
        inputFocused: { borderColor: colors.primary },
        kindRow: { flexDirection: "row", gap: 8, marginBottom: 4 },
        kindCard: {
          flex: 1,
          borderRadius: 16,
          borderWidth: 2,
          borderColor: colors.border,
          backgroundColor: colors.card,
          alignItems: "center",
          paddingVertical: 14,
          paddingHorizontal: 6,
          gap: 6,
        } as ViewStyle,
        kindCardActive: {
          borderColor: colors.primary,
          backgroundColor: colors.primary + "15",
        } as ViewStyle,
        kindLabel: {
          fontSize: 11,
          fontWeight: "700",
          color: colors.foreground,
          textAlign: "center",
        } as TextStyle,
        kindLabelActive: { color: colors.primary } as TextStyle,
        kindDesc: {
          fontSize: 9,
          color: colors.mutedForeground,
          textAlign: "center",
        } as TextStyle,
        bankPickerBtn: {
          flexDirection: "row",
          alignItems: "center",
          justifyContent: "space-between",
          backgroundColor: colors.muted,
          borderRadius: 14,
          paddingHorizontal: 14,
          paddingVertical: 12,
          borderWidth: 1.5,
          borderColor: colors.border,
          marginTop: 8,
        },
        bankPickerText: {
          fontSize: 14,
          color: colors.mutedForeground,
        } as TextStyle,
        bankList: {
          backgroundColor: colors.card,
          borderRadius: 14,
          borderWidth: 1,
          borderColor: colors.border,
          marginTop: 6,
          overflow: "hidden",
          maxHeight: 200,
        },
        bankRow: {
          flexDirection: "row",
          alignItems: "center",
          justifyContent: "space-between",
          paddingHorizontal: 14,
          paddingVertical: 11,
          borderTopWidth: StyleSheet.hairlineWidth,
          borderTopColor: colors.border,
        },
        bankRowText: { fontSize: 13, color: colors.foreground } as TextStyle,
        calcBox: {
          backgroundColor: colors.card,
          borderRadius: 14,
          borderWidth: 1,
          borderColor: colors.border,
          padding: 14,
          marginTop: 12,
          gap: 8,
        },
        calcRow: {
          flexDirection: "row",
          justifyContent: "space-between",
          alignItems: "center",
        },
        calcLabel: { fontSize: 12, color: colors.mutedForeground } as TextStyle,
        calcValue: { fontSize: 13, fontWeight: "700", color: colors.foreground } as TextStyle,
        dateSel: {
          flexDirection: "row",
          alignItems: "center",
          justifyContent: "space-between",
          backgroundColor: colors.muted,
          borderRadius: 14,
          paddingHorizontal: 14,
          paddingVertical: 13,
          borderWidth: 1.5,
          borderColor: colors.border,
          marginTop: 6,
        },
        dateSelText: { fontSize: 14, color: colors.foreground } as TextStyle,
        navRow: {
          flexDirection: "row",
          gap: 10,
          paddingHorizontal: 20,
          paddingTop: 16,
          paddingBottom: 4,
        },
        btn: {
          flex: 1,
          borderRadius: 16,
          paddingVertical: 15,
          alignItems: "center",
          justifyContent: "center",
        },
        btnPrimary: { backgroundColor: colors.primary },
        btnSecondary: { backgroundColor: colors.muted, borderWidth: 1, borderColor: colors.border },
        btnText: { fontSize: 15, fontWeight: "800", color: "#FFFFFF" } as TextStyle,
        btnTextSecondary: { fontSize: 15, fontWeight: "700", color: colors.foreground } as TextStyle,
        btnDisabled: { opacity: 0.4 },
        catGrid: { flexDirection: "row", flexWrap: "wrap", gap: 8, marginTop: 4 },
        catChip: {
          flexDirection: "row",
          alignItems: "center",
          gap: 6,
          paddingHorizontal: 12,
          paddingVertical: 7,
          borderRadius: 20,
          backgroundColor: colors.muted,
          borderWidth: 1.5,
          borderColor: colors.border,
        },
        catChipActive: { backgroundColor: colors.primary, borderColor: colors.primary },
        catChipText: { fontSize: 12, fontWeight: "600", color: colors.foreground } as TextStyle,
        catChipTextActive: { color: "#FFFFFF" } as TextStyle,
        errorBox: {
          flexDirection: "row",
          alignItems: "flex-start",
          gap: 6,
          backgroundColor: "#FF4D6D1A",
          borderRadius: 12,
          padding: 10,
          marginTop: 8,
        },
        errorText: { flex: 1, fontSize: 12, color: "#FF4D6D", fontWeight: "600" } as TextStyle,
      }),
    [colors]
  );

  // ── Step renderers ────────────────────────────────────────────────────────

  const renderStep1 = () => (
    <>
      <Text style={s.sectionTitle}>{t("debtWizard.step1Title")}</Text>
      <View style={s.kindRow}>
        {DEBT_KINDS.map((k) => {
          const active = form.kind === k.key;
          return (
            <TouchableOpacity
              key={k.key}
              style={[s.kindCard, active && s.kindCardActive]}
              onPress={() => {
                Haptics.selectionAsync();
                setForm((f) => ({ ...f, kind: k.key, category: kindToCategory(k.key) }));
              }}
              activeOpacity={0.75}
            >
              <Feather
                name={k.icon as any}
                size={22}
                color={active ? colors.primary : colors.mutedForeground}
              />
              <Text style={[s.kindLabel, active && s.kindLabelActive]}>{k.label}</Text>
              <Text style={s.kindDesc}>{k.desc}</Text>
            </TouchableOpacity>
          );
        })}
      </View>

      <Text style={s.label}>{t("debtWizard.debtName")} *</Text>
      <TextInput
        style={s.input}
        value={form.name}
        onChangeText={(v) => setForm((f) => ({ ...f, name: v }))}
        placeholder={t("debtWizard.debtNamePlaceholder")}
        placeholderTextColor={colors.mutedForeground}
        returnKeyType="done"
      />

      <Text style={s.label}>{t("debtWizard.creditor")}</Text>
      <TextInput
        style={s.input}
        value={form.creditor}
        onChangeText={(v) => setForm((f) => ({ ...f, creditor: v }))}
        placeholder={t("debtWizard.creditorPlaceholder")}
        placeholderTextColor={colors.mutedForeground}
        returnKeyType="done"
      />

      {/* Bank quick-picker */}
      <TouchableOpacity
        style={s.bankPickerBtn}
        onPress={() => { Haptics.selectionAsync(); setBankListOpen((v) => !v); }}
      >
        <View style={{ flexDirection: "row", alignItems: "center", gap: 10 }}>
          <Feather name="credit-card" size={16} color={colors.mutedForeground} />
          <Text style={s.bankPickerText}>{bankListOpen ? t("debtWizard.closeList") : t("debtWizard.selectFromBank")}</Text>
        </View>
        <Feather name={bankListOpen ? "chevron-up" : "chevron-down"} size={16} color={colors.mutedForeground} />
      </TouchableOpacity>

      {bankListOpen && (
        <View style={s.bankList}>
          <ScrollView style={{ maxHeight: 200 }} showsVerticalScrollIndicator={false}>
            {BANKS.map((b) => {
              const active = form.creditor === b;
              return (
                <TouchableOpacity
                  key={b}
                  style={[s.bankRow, active && { backgroundColor: colors.primary + "18" }]}
                  onPress={() => {
                    Haptics.selectionAsync();
                    setForm((f) => ({ ...f, creditor: b }));
                    setBankListOpen(false);
                  }}
                >
                  <Text style={[s.bankRowText, active && { color: colors.primary, fontWeight: "700" }]}>{b}</Text>
                  {active && <Feather name="check" size={14} color={colors.primary} />}
                </TouchableOpacity>
              );
            })}
            {manualBankMode ? (
              <View style={[s.bankRow, { gap: 8 }]}>
                <TextInput
                  value={manualBank}
                  onChangeText={setManualBank}
                  placeholder={t("debtWizard.bankNamePlaceholder")}
                  placeholderTextColor={colors.mutedForeground}
                  style={[s.input, { flex: 1, paddingVertical: 8, marginTop: 0 }]}
                  autoFocus
                  onSubmitEditing={() => {
                    if (manualBank.trim()) {
                      setForm((f) => ({ ...f, creditor: manualBank.trim() }));
                      setManualBank(""); setManualBankMode(false); setBankListOpen(false);
                    }
                  }}
                />
                <TouchableOpacity
                  style={{ backgroundColor: colors.primary, padding: 10, borderRadius: 10 }}
                  onPress={() => {
                    if (manualBank.trim()) {
                      setForm((f) => ({ ...f, creditor: manualBank.trim() }));
                      setManualBank(""); setManualBankMode(false); setBankListOpen(false);
                    }
                  }}
                >
                  <Feather name="check" size={16} color="#FFF" />
                </TouchableOpacity>
              </View>
            ) : (
              <TouchableOpacity
                style={[s.bankRow, { borderTopWidth: 1, borderTopColor: colors.border }]}
                onPress={() => setManualBankMode(true)}
              >
                <Feather name="plus" size={14} color={colors.primary} />
                <Text style={[s.bankRowText, { color: colors.primary, fontWeight: "600" }]}>{t("debtWizard.manualAdd")}</Text>
              </TouchableOpacity>
            )}
          </ScrollView>
        </View>
      )}
    </>
  );

  const renderStep2 = () => {
    const isInst = form.kind === "installment";
    const inst = parseInt(form.totalInstallments, 10) || 0;
    return (
      <>
        <Text style={s.sectionTitle}>{t("debtWizard.step2Title")}</Text>

        {isInst && (
          <>
            <Text style={s.label}>{t("debtWizard.installmentCount")} *</Text>
            <TextInput
              style={s.input}
              value={form.totalInstallments}
              onChangeText={(v) => setForm((f) => ({ ...f, totalInstallments: v.replace(/[^0-9]/g, "") }))}
              placeholder={t("debtWizard.installmentCountPlaceholder")}
              placeholderTextColor={colors.mutedForeground}
              keyboardType="number-pad"
              returnKeyType="done"
            />
          </>
        )}

        {isInst ? (
          <>
            <Text style={s.label}>{t("debtWizard.monthlyInstallment")} *</Text>
            <TextInput
              style={s.input}
              value={form.installmentAmount}
              onChangeText={(v) => setForm((f) => ({ ...f, installmentAmount: v }))}
              placeholder={t("debtWizard.amountPlaceholder")}
              placeholderTextColor={colors.mutedForeground}
              keyboardType="decimal-pad"
              returnKeyType="done"
            />
            <Text style={s.label}>{t("debtWizard.totalAmountOptional")}</Text>
            <TextInput
              style={s.input}
              value={form.amount}
              onChangeText={(v) => setForm((f) => ({ ...f, amount: v }))}
              placeholder={t("debtWizard.totalAmountPlaceholder")}
              placeholderTextColor={colors.mutedForeground}
              keyboardType="decimal-pad"
              returnKeyType="done"
            />
          </>
        ) : (
          <>
            <Text style={s.label}>{t("debtWizard.debtAmount")} *</Text>
            <TextInput
              style={s.input}
              value={form.amount}
              onChangeText={(v) => setForm((f) => ({ ...f, amount: v }))}
              placeholder={t("debtWizard.debtAmountPlaceholder")}
              placeholderTextColor={colors.mutedForeground}
              keyboardType="decimal-pad"
              returnKeyType="done"
            />
          </>
        )}

        {amountInfo.error && (
          <View style={s.errorBox}>
            <Feather name="alert-triangle" size={14} color="#FF4D6D" style={{ marginTop: 2 }} />
            <Text style={s.errorText}>{amountInfo.error}</Text>
          </View>
        )}

        {/* Hesap kutusu */}
        {amountInfo.effectiveTotal > 0 && (
          <View style={s.calcBox}>
            {isInst && (
              <>
                <View style={s.calcRow}>
                  <Text style={s.calcLabel}>{t("debtWizard.monthlyInstallmentCalc")}</Text>
                  <Text style={s.calcValue}>{formatAmount(amountInfo.effectivePer || amountInfo.effectiveTotal / Math.max(1, inst))}</Text>
                </View>
                <View style={{ height: StyleSheet.hairlineWidth, backgroundColor: colors.border }} />
                <View style={s.calcRow}>
                  <Text style={s.calcLabel}>{t("debtWizard.totalInstallments")}</Text>
                  <Text style={s.calcValue}>{inst > 0 ? inst : "?"} {t("debtWizard.installmentSuffix")}</Text>
                </View>
                <View style={{ height: StyleSheet.hairlineWidth, backgroundColor: colors.border }} />
              </>
            )}
            <View style={s.calcRow}>
              <Text style={s.calcLabel}>{t("debtWizard.totalDebt")}</Text>
              <Text style={[s.calcValue, { color: colors.expense }]}>{formatAmount(amountInfo.effectiveTotal)}</Text>
            </View>
          </View>
        )}

        {/* Category (collapsed) */}
        <View style={{ flexDirection: "row", alignItems: "center", justifyContent: "space-between", marginTop: 18 }}>
          <Text style={s.label}>{t("debtWizard.category")}</Text>
          <TouchableOpacity
            onPress={() => { Haptics.selectionAsync(); setNewCatOpen((v) => !v); }}
            style={{ flexDirection: "row", alignItems: "center", gap: 4, paddingHorizontal: 10, paddingVertical: 5, borderRadius: 10, backgroundColor: colors.muted }}
          >
            <Feather name={newCatOpen ? "x" : "plus"} size={12} color={colors.primary} />
            <Text style={{ fontSize: 11, fontWeight: "600", color: colors.primary }}>{newCatOpen ? t("common.cancel") : t("common.add")}</Text>
          </TouchableOpacity>
        </View>
        {newCatOpen && (
          <View style={{ flexDirection: "row", gap: 8, marginBottom: 8 }}>
            <TextInput
              style={[s.input, { flex: 1 }]}
              value={newCatText}
              onChangeText={setNewCatText}
              placeholder={t("debtWizard.newCategoryPlaceholder")}
              placeholderTextColor={colors.mutedForeground}
              autoFocus
            />
            <TouchableOpacity
              onPress={() => {
                const name = newCatText.trim();
                if (!name) return;
                addDebtCategory(name);
                setForm((f) => ({ ...f, category: name }));
                setNewCatText(""); setNewCatOpen(false);
                Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
              }}
              style={{ backgroundColor: colors.primary, paddingHorizontal: 14, borderRadius: 14, justifyContent: "center" }}
            >
              <Feather name="check" size={16} color="#FFF" />
            </TouchableOpacity>
          </View>
        )}
        <View style={s.catGrid}>
          {allDebtCategories.map((c) => {
            const active = form.category === c.label;
            return (
              <TouchableOpacity
                key={c.label}
                style={[s.catChip, active && s.catChipActive]}
                onPress={() => { Haptics.selectionAsync(); setForm((f) => ({ ...f, category: c.label })); }}
              >
                <Feather name={c.icon as any} size={12} color={active ? "#FFF" : colors.foreground} />
                <Text style={[s.catChipText, active && s.catChipTextActive]}>{c.label}</Text>
              </TouchableOpacity>
            );
          })}
        </View>
      </>
    );
  };

  const renderStep3 = () => {
    const instCount = parseInt(form.totalInstallments, 10);
    const endDate = form.kind === "installment" && instCount > 1 ? calcEndDate(form.date, instCount) : null;
    const autoPaid = form.kind === "installment" && instCount > 1 ? Math.min(monthsElapsed(form.date), instCount) : 0;

    return (
      <>
        <Text style={s.sectionTitle}>{t("debtWizard.step3Title")}</Text>

        <Text style={s.label}>
          {form.kind === "installment" ? t("debtWizard.startDate") : t("debtWizard.debtDate")}
        </Text>
        <TouchableOpacity style={s.dateSel} onPress={() => setDatePickerFor("date")}>
          <View style={{ flexDirection: "row", alignItems: "center", gap: 10 }}>
            <Feather name="calendar" size={16} color={colors.mutedForeground} />
            <Text style={s.dateSelText}>{form.date.toLocaleDateString("tr-TR", { day: "2-digit", month: "long", year: "numeric" })}</Text>
          </View>
          <Feather name="chevron-down" size={16} color={colors.mutedForeground} />
        </TouchableOpacity>

        {endDate && (
          <View style={[s.dateSel, { marginTop: 10, opacity: 0.7 }]}>
            <View style={{ flexDirection: "row", alignItems: "center", gap: 10 }}>
              <Feather name="flag" size={16} color={colors.mutedForeground} />
              <Text style={s.dateSelText}>{endDate.toLocaleDateString("tr-TR", { day: "2-digit", month: "long", year: "numeric" })} — {t("debtWizard.endDate")}</Text>
            </View>
            <Text style={{ fontSize: 11, color: colors.mutedForeground }}>{t("debtWizard.automatic")}</Text>
          </View>
        )}

        {autoPaid > 0 && (
          <View style={{ flexDirection: "row", alignItems: "center", gap: 8, backgroundColor: colors.primary + "15", borderRadius: 12, padding: 10, marginTop: 10 }}>
            <Feather name="info" size={14} color={colors.primary} />
            <Text style={{ fontSize: 12, color: colors.primary, fontWeight: "600", flex: 1 }}>
              {t("debtWizard.autoPaidInfo", { count: autoPaid })}
            </Text>
          </View>
        )}

        <Text style={s.label}>{t("debtWizard.noteLabel")}</Text>
        <TextInput
          style={[s.input, { minHeight: 72, textAlignVertical: "top", paddingTop: 12 }]}
          value={form.note}
          onChangeText={(v) => setForm((f) => ({ ...f, note: v }))}
          placeholder={t("debtWizard.notePlaceholder")}
          placeholderTextColor={colors.mutedForeground}
          multiline
          returnKeyType="done"
        />
      </>
    );
  };

  const stepTitles = [t("debtWizard.stepTitle1"), t("debtWizard.stepTitle2"), t("debtWizard.stepTitle3")];
  const stepDescs  = [t("debtWizard.stepDesc1"), t("debtWizard.stepDesc2"), t("debtWizard.stepDesc3")];

  return (
    <Modal visible={visible} transparent animationType="slide" onRequestClose={onClose}>
      <View style={{ flex: 1, justifyContent: "flex-end" }}>
        <Pressable style={StyleSheet.absoluteFillObject} onPress={onClose} />

        <Pressable style={[s.sheet, { marginBottom: kbHeight }]} onPress={() => {}}>
          <View style={s.handle} />

          {/* Header */}
          <View style={s.header}>
            <View>
              <Text style={s.headerTitle}>{isEdit ? t("debtWizard.editTitle") : stepTitles[step]}</Text>
              <Text style={s.stepLabel}>{stepDescs[step]}</Text>
            </View>
            <View style={{ flexDirection: "row", alignItems: "center", gap: 14 }}>
              <StepDots step={step} total={TOTAL_STEPS} />
              <TouchableOpacity onPress={onClose} hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}>
                <Feather name="x" size={22} color={colors.mutedForeground} />
              </TouchableOpacity>
            </View>
          </View>

          {/* Content */}
          <ScrollView
            keyboardShouldPersistTaps="handled"
            showsVerticalScrollIndicator={false}
            style={{ flexShrink: 1 }}
            contentContainerStyle={s.content}
          >
            <Animated.View style={{ transform: [{ translateX: slideAnim }] }}>
              {step === 0 && renderStep1()}
              {step === 1 && renderStep2()}
              {step === 2 && renderStep3()}
            </Animated.View>
            <View style={{ height: 20 }} />
          </ScrollView>

          {/* Navigation buttons */}
          <View style={s.navRow}>
            {step > 0 && (
              <TouchableOpacity style={[s.btn, s.btnSecondary, { flex: 0.4 }]} onPress={() => goTo(step - 1)}>
                <Text style={s.btnTextSecondary}>{t("common.back")}</Text>
              </TouchableOpacity>
            )}
            {step < TOTAL_STEPS - 1 ? (
              <TouchableOpacity
                style={[s.btn, s.btnPrimary, step === 0 && !step1Valid && s.btnDisabled]}
                onPress={() => {
                  if (step === 0 && !step1Valid) {
                    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
                    return;
                  }
                  goTo(step + 1);
                }}
                disabled={step === 0 && !step1Valid}
              >
                <Text style={s.btnText}>{t("common.next")} →</Text>
              </TouchableOpacity>
            ) : (
              <TouchableOpacity
                style={[s.btn, s.btnPrimary, !allValid && s.btnDisabled]}
                onPress={handleSave}
                disabled={!allValid}
              >
                <Text style={s.btnText}>{isEdit ? t("common.update") : t("common.save")}</Text>
              </TouchableOpacity>
            )}
          </View>
        </Pressable>

        {/* Date pickers */}
        <DatePickerSheet
          visible={datePickerFor === "date"}
          value={form.date}
          title={t("debtWizard.debtDatePickerTitle")}
          onSelect={(d) => setForm((f) => ({ ...f, date: d }))}
          onClose={() => setDatePickerFor(null)}
        />
        <DatePickerSheet
          visible={datePickerFor === "statement"}
          value={form.statementDate}
          title={t("debtWizard.statementDatePickerTitle")}
          onSelect={(d) => {
            const due = new Date(d);
            due.setDate(due.getDate() + 10);
            setForm((f) => ({ ...f, statementDate: d, date: due }));
          }}
          onClose={() => setDatePickerFor(null)}
        />
      </View>
    </Modal>
  );
}
