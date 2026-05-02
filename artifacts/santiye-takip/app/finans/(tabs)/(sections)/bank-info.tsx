import { LinearGradient } from "expo-linear-gradient";
import { Feather } from "@expo/vector-icons";
import * as Clipboard from "expo-clipboard";
import * as Haptics from "expo-haptics";
import React, { useEffect, useMemo, useState } from "react";
import {
  Alert,
  Dimensions,
  FlatList,
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

import { SavedCard, SavedCardType, useBudget } from "@/context/finans/BudgetContext";
import { useColors } from "@/hooks/finans/useColors";
import { BANKS } from "@/utils/finans/categories";

const { width: SCREEN_W } = Dimensions.get("window");
const CARD_W = SCREEN_W - 72;
const CARD_H = Math.round(CARD_W * 0.58);
const CARD_GAP = 12;

const CARD_PALETTE: [string, string][] = [
  ["#4C1D95", "#7C3AED"],
  ["#065F46", "#059669"],
  ["#991B1B", "#DC2626"],
  ["#92400E", "#D97706"],
  ["#1D4ED8", "#3B82F6"],
  ["#9D174D", "#DB2777"],
  ["#0E7490", "#0891B2"],
  ["#14532D", "#16A34A"],
];

type CategoryDef = {
  type: SavedCardType;
  labelKey: string;
  icon: React.ComponentProps<typeof Feather>["name"];
  accent: string;
};

const CATEGORY_DEFS: CategoryDef[] = [
  { type: "time",   labelKey: "bankInfo.timeAccounts",    icon: "clock",        accent: "#F59E0B" },
  { type: "demand", labelKey: "bankInfo.demandAccounts",  icon: "layers",       accent: "#00C896" },
  { type: "credit", labelKey: "bankInfo.creditCardsSection", icon: "credit-card", accent: "#3B82F6" },
];

const FORM_TYPE_DEFS: { key: SavedCardType; labelKey: string; icon: React.ComponentProps<typeof Feather>["name"] }[] = [
  { key: "time",   labelKey: "bankInfo.timeType",   icon: "clock" },
  { key: "demand", labelKey: "bankInfo.demandType", icon: "layers" },
  { key: "credit", labelKey: "bankInfo.creditType", icon: "credit-card" },
];

const TYPE_THEME: Record<SavedCardType, { color: string; bg: string }> = {
  time:   { color: "#F59E0B", bg: "#FEF3C7" },
  demand: { color: "#00C896", bg: "#E6FBF4" },
  credit: { color: "#3B82F6", bg: "#EFF6FF" },
};

function formatDateStr(iso?: string): string {
  if (!iso) return "";
  try {
    const d = new Date(iso);
    if (isNaN(d.getTime())) return iso;
    return `${String(d.getDate()).padStart(2, "0")}.${String(d.getMonth() + 1).padStart(2, "0")}.${d.getFullYear()}`;
  } catch { return iso; }
}

function isoFromDDMMYYYY(s: string): string {
  const clean = s.trim();
  const parts = clean.split(".").filter(Boolean);
  if (parts.length === 3) {
    const [d, m, y] = parts;
    return `${y}-${m.padStart(2, "0")}-${d.padStart(2, "0")}`;
  }
  return clean;
}

function formatIban(raw: string): string {
  const c = raw.replace(/\s/g, "").toUpperCase();
  return c.replace(/(.{4})/g, "$1 ").trim();
}

function maskAccount(card: SavedCard): string {
  if (card.type === "credit" && card.cardLast4) return `•••• •••• •••• ${card.cardLast4}`;
  if (card.iban) return formatIban(card.iban);
  if (card.accountNumber) return card.accountNumber;
  if (card.type === "time" && card.interestRate !== undefined) return `% ${card.interestRate} faiz`;
  return "";
}

function cardBottomRight(card: SavedCard): string {
  if (card.type === "time" && card.maturityDate) return `Vade: ${formatDateStr(card.maturityDate)}`;
  if (card.type === "credit" && card.statementDay) return `Ekstre: ${card.statementDay}. gün`;
  if (card.type === "time" && card.openDate) return `Açılış: ${formatDateStr(card.openDate)}`;
  return "";
}

// ─────────────────────────────────────────────
// BankCard — visual credit-card component
// ─────────────────────────────────────────────
function BankCard({
  card,
  colorIndex,
  onPress,
  copiedId,
  onCopyIban,
}: {
  card: SavedCard;
  colorIndex: number;
  onPress: () => void;
  copiedId: string | null;
  onCopyIban: (id: string, iban: string) => void;
}) {
  const [from, to] = CARD_PALETTE[colorIndex % CARD_PALETTE.length];
  const typeIcon: React.ComponentProps<typeof Feather>["name"] =
    card.type === "credit" ? "credit-card" : card.type === "time" ? "clock" : "layers";

  const accNum = maskAccount(card);
  const btmRight = cardBottomRight(card);

  return (
    <TouchableOpacity
      activeOpacity={0.92}
      onPress={onPress}
      style={{ width: CARD_W, marginHorizontal: CARD_GAP / 2 }}
    >
      <LinearGradient
        colors={[from, to]}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={cardStyles.gradient}
      >
        {/* Top row */}
        <View style={cardStyles.topRow}>
          <View style={{ flex: 1 }}>
            <Text style={cardStyles.bankName} numberOfLines={1}>{card.bank}</Text>
            <Text style={cardStyles.cardName} numberOfLines={1}>{card.name}</Text>
          </View>
          <View style={cardStyles.iconWrap}>
            <Feather name={typeIcon} size={16} color="rgba(255,255,255,0.9)" />
          </View>
        </View>

        {/* Bottom row */}
        <View style={cardStyles.bottomRow}>
          <View style={{ flex: 1, flexDirection: "row", alignItems: "center", gap: 6 }}>
            <Text style={cardStyles.accNumber} numberOfLines={1}>{accNum}</Text>
            {card.iban && (
              <TouchableOpacity
                hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
                onPress={() => onCopyIban(card.id, card.iban!)}
              >
                <Feather
                  name={copiedId === card.id ? "check" : "copy"}
                  size={11}
                  color={copiedId === card.id ? "#FFFFFF" : "rgba(255,255,255,0.5)"}
                />
              </TouchableOpacity>
            )}
          </View>
          <Text style={cardStyles.dateLabel}>{btmRight}</Text>
        </View>

        {/* Edit hint */}
        <View style={cardStyles.editHint}>
          <Feather name="edit-2" size={9} color="rgba(255,255,255,0.35)" />
          <Text style={cardStyles.editHintText}>düzenle</Text>
        </View>
      </LinearGradient>
    </TouchableOpacity>
  );
}

const cardStyles = StyleSheet.create({
  gradient: {
    width: CARD_W,
    height: CARD_H,
    borderRadius: 20,
    padding: 18,
    justifyContent: "space-between",
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.25,
    shadowRadius: 16,
    elevation: 8,
  },
  topRow: { flexDirection: "row", alignItems: "flex-start" },
  bankName: { fontSize: 16, fontWeight: "800", color: "#FFFFFF", letterSpacing: 0.3 },
  cardName: { fontSize: 12, color: "rgba(255,255,255,0.7)", marginTop: 2 },
  iconWrap: {
    width: 34, height: 34, borderRadius: 17,
    backgroundColor: "rgba(255,255,255,0.18)",
    alignItems: "center", justifyContent: "center", marginLeft: 10,
  },
  balance: { fontSize: 26, fontWeight: "800", color: "#FFFFFF", letterSpacing: 0.5 },
  bottomRow: { flexDirection: "row", alignItems: "flex-end" },
  accNumber: { fontSize: 13, color: "rgba(255,255,255,0.75)", letterSpacing: 1.5, fontVariant: ["tabular-nums"] },
  dateLabel: { fontSize: 11, color: "rgba(255,255,255,0.65)", marginLeft: 8 },
  editHint: {
    position: "absolute", bottom: 8, right: 14,
    flexDirection: "row", alignItems: "center", gap: 3,
  },
  editHintText: { fontSize: 10, color: "rgba(255,255,255,0.35)" },
});

// ─────────────────────────────────────────────
// CategorySection — header + horizontal carousel
// ─────────────────────────────────────────────
function CategorySection({
  def,
  cards,
  onCardPress,
  colors,
  copiedId,
  onCopyIban,
}: {
  def: CategoryDef;
  cards: SavedCard[];
  onCardPress: (card: SavedCard) => void;
  colors: ReturnType<typeof useColors>;
  copiedId: string | null;
  onCopyIban: (id: string, iban: string) => void;
}) {
  const { t } = useTranslation();
  const [expanded, setExpanded] = useState(true);

  if (cards.length === 0) return null;

  return (
    <View style={{ marginBottom: 20 }}>
      {/* Category header pill */}
      <TouchableOpacity
        activeOpacity={0.82}
        onPress={() => { Haptics.selectionAsync(); setExpanded((v) => !v); }}
        style={[
          catStyles.header,
          { backgroundColor: colors.card, borderLeftColor: def.accent, borderLeftWidth: 4 },
        ]}
      >
        <View style={[catStyles.iconBox, { backgroundColor: def.accent + "20" }]}>
          <Feather name={def.icon} size={16} color={def.accent} />
        </View>
        <Text style={[catStyles.headerLabel, { color: colors.foreground }]}>
          {t(def.labelKey)}
        </Text>
        <View style={[catStyles.countBadge, { backgroundColor: def.accent + "22" }]}>
          <Text style={[catStyles.countText, { color: def.accent }]}>{cards.length}</Text>
        </View>
        <Feather
          name={expanded ? "chevron-up" : "chevron-down"}
          size={18}
          color={colors.mutedForeground}
        />
      </TouchableOpacity>

      {/* Horizontal card carousel */}
      {expanded && (
        <FlatList
          horizontal
          data={cards}
          keyExtractor={(c) => c.id}
          snapToInterval={CARD_W + CARD_GAP}
          decelerationRate="fast"
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={{ paddingHorizontal: 24, paddingTop: 12, paddingBottom: 4 }}
          ItemSeparatorComponent={() => <View style={{ width: CARD_GAP }} />}
          renderItem={({ item, index }) => (
            <BankCard
              card={item}
              colorIndex={index}
              onPress={() => onCardPress(item)}
              copiedId={copiedId}
              onCopyIban={onCopyIban}
            />
          )}
        />
      )}
    </View>
  );
}

const catStyles = StyleSheet.create({
  header: {
    flexDirection: "row",
    alignItems: "center",
    marginHorizontal: 16,
    borderRadius: 14,
    paddingHorizontal: 14,
    paddingVertical: 13,
    gap: 10,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.06,
    shadowRadius: 6,
    elevation: 2,
  },
  iconBox: {
    width: 34, height: 34, borderRadius: 9,
    alignItems: "center", justifyContent: "center",
  },
  headerLabel: { flex: 1, fontSize: 15, fontWeight: "700" },
  countBadge: {
    minWidth: 26, height: 22, borderRadius: 11,
    alignItems: "center", justifyContent: "center",
    paddingHorizontal: 7,
  },
  countText: { fontSize: 13, fontWeight: "700" },
});

// ─────────────────────────────────────────────
// Main screen
// ─────────────────────────────────────────────
export default function BankInfoScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const { t } = useTranslation();
  const { savedCards, addSavedCard, updateSavedCard, deleteSavedCard } = useBudget();

  const bottomInset = Platform.OS === "web" ? 34 : insets.bottom;

  const [modalOpen, setModalOpen]         = useState(false);
  const [editId, setEditId]               = useState<string | null>(null);
  const [kbHeight, setKbHeight]           = useState(0);
  const [bankListOpen, setBankListOpen]   = useState(false);
  const [copiedId, setCopiedId]           = useState<string | null>(null);

  useEffect(() => {
    const showEv = Platform.OS === "ios" ? "keyboardWillShow" : "keyboardDidShow";
    const hideEv = Platform.OS === "ios" ? "keyboardWillHide" : "keyboardDidHide";
    const s1 = Keyboard.addListener(showEv, (e: KeyboardEvent) => setKbHeight(e.endCoordinates.height));
    const s2 = Keyboard.addListener(hideEv, () => setKbHeight(0));
    return () => { s1.remove(); s2.remove(); };
  }, []);

  // ── Form state ─────────────────────────────
  const [formType, setFormType]               = useState<SavedCardType>("demand");
  const [formBank, setFormBank]               = useState(BANKS[0]);
  const [formName, setFormName]               = useState("");
  const [formIban, setFormIban]               = useState("");
  const [formAccount, setFormAccount]         = useState("");
  const [formLast4, setFormLast4]             = useState("");
  const [formInterestRate, setFormInterestRate] = useState("");
  const [formMaturityDate, setFormMaturityDate] = useState("");
  const [formOpenDate, setFormOpenDate]       = useState("");
  const [formStatementDay, setFormStatementDay] = useState("");

  const resetForm = () => {
    setFormType("demand");
    setFormBank(BANKS[0]);
    setFormName("");
    setFormIban("");
    setFormAccount("");
    setFormLast4("");
    setFormInterestRate("");
    setFormMaturityDate("");
    setFormOpenDate("");
    setFormStatementDay("");
    setBankListOpen(false);
  };

  const openAdd = () => {
    Haptics.selectionAsync();
    setEditId(null);
    resetForm();
    setModalOpen(true);
  };

  const openEdit = (card: SavedCard) => {
    Haptics.selectionAsync();
    setEditId(card.id);
    setFormType(card.type);
    setFormBank(card.bank);
    setFormName(card.name);
    setFormIban(card.iban ?? "");
    setFormAccount(card.accountNumber ?? "");
    setFormLast4(card.cardLast4 ?? "");
    setFormInterestRate(card.interestRate !== undefined ? String(card.interestRate) : "");
    setFormMaturityDate(card.maturityDate ? formatDateStr(card.maturityDate) : "");
    setFormOpenDate(card.openDate ? formatDateStr(card.openDate) : "");
    setFormStatementDay(card.statementDay !== undefined ? String(card.statementDay) : "");
    setBankListOpen(false);
    setModalOpen(true);
  };

  const handleSave = () => {
    const name = formName.trim() || formBank;
    const iban = formIban.trim().replace(/\s/g, "").toUpperCase();
    const interestRate = formInterestRate.trim() ? (parseFloat(formInterestRate.replace(",", ".")) || undefined) : undefined;
    const statDay = formStatementDay.trim() ? (parseInt(formStatementDay) || undefined) : undefined;
    const matDate = formMaturityDate.trim() ? isoFromDDMMYYYY(formMaturityDate) : undefined;
    const opDate = formOpenDate.trim() ? isoFromDDMMYYYY(formOpenDate) : undefined;

    const payload: Omit<SavedCard, "id"> = {
      bank: formBank,
      name,
      type: formType,
      iban: iban || undefined,
      accountNumber: formType === "demand" ? (formAccount.trim() || undefined) : undefined,
      cardLast4: formType === "credit" ? (formLast4.trim() || undefined) : undefined,
      interestRate: formType === "time" ? interestRate : undefined,
      maturityDate: formType === "time" ? matDate : undefined,
      openDate: formType === "time" ? opDate : undefined,
      statementDay: formType === "credit" ? statDay : undefined,
    };

    if (editId) {
      updateSavedCard(editId, payload);
    } else {
      addSavedCard(payload);
    }
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    setModalOpen(false);
  };

  const handleDelete = () => {
    if (!editId) return;
    const card = savedCards.find((c) => c.id === editId);
    if (!card) return;
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning);
    Alert.alert(
      t("bankInfo.delete"),
      t("bankInfo.deleteAccountConfirmMsg", { name: card.name }),
      [
        { text: t("common.cancel"), style: "cancel" },
        {
          text: t("bankInfo.delete"),
          style: "destructive",
          onPress: () => {
            deleteSavedCard(card.id);
            setModalOpen(false);
            Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
          },
        },
      ]
    );
  };

  const copyIban = async (id: string, iban: string) => {
    await Clipboard.setStringAsync(iban);
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    setCopiedId(id);
    setTimeout(() => setCopiedId((prev) => (prev === id ? null : prev)), 2000);
  };

  const timeCards   = useMemo(() => savedCards.filter((c) => c.type === "time"),   [savedCards]);
  const demandCards = useMemo(() => savedCards.filter((c) => c.type === "demand"), [savedCards]);
  const creditCards = useMemo(() => savedCards.filter((c) => c.type === "credit"), [savedCards]);

  const categoryData = useMemo(() => [
    { def: CATEGORY_DEFS[0], cards: timeCards },
    { def: CATEGORY_DEFS[1], cards: demandCards },
    { def: CATEGORY_DEFS[2], cards: creditCards },
  ], [timeCards, demandCards, creditCards]);

  const hasAnyCard = savedCards.length > 0;
  const theme = TYPE_THEME[formType];

  return (
    <View style={{ flex: 1, backgroundColor: colors.background }}>
      {/* ── Header ──────────────────────────────── */}
      <View style={[scrStyles.header, { backgroundColor: colors.navy }]}>
        <Text style={scrStyles.headerTitle}>{t("bankInfo.title")}</Text>
        <TouchableOpacity style={[scrStyles.addBtn, { backgroundColor: colors.primary }]} onPress={openAdd}>
          <Feather name="plus" size={18} color="#0B1E33" />
        </TouchableOpacity>
      </View>

      {/* ── Content ─────────────────────────────── */}
      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={{ paddingTop: 20, paddingBottom: bottomInset + 100 }}
      >
        {!hasAnyCard && (
          <View style={scrStyles.emptyState}>
            <Feather name="credit-card" size={52} color={colors.mutedForeground} />
            <Text style={[scrStyles.emptyTitle, { color: colors.foreground }]}>
              {t("bankInfo.noAccounts")}
            </Text>
            <Text style={[scrStyles.emptyHint, { color: colors.mutedForeground }]}>
              {t("bankInfo.noAccountsHint")}
            </Text>
            <TouchableOpacity
              style={[scrStyles.emptyAddBtn, { backgroundColor: colors.primary }]}
              onPress={openAdd}
            >
              <Feather name="plus" size={15} color="#0B1E33" />
              <Text style={{ fontSize: 14, fontWeight: "700", color: "#0B1E33" }}>
                {t("bankInfo.addAccount")}
              </Text>
            </TouchableOpacity>
          </View>
        )}

        {categoryData.map(({ def, cards }) => (
          <CategorySection
            key={def.type}
            def={def}
            cards={cards}
            onCardPress={openEdit}
            colors={colors}
            copiedId={copiedId}
            onCopyIban={copyIban}
          />
        ))}
      </ScrollView>

      {/* ── Add / Edit Modal ──────────────────── */}
      <Modal
        visible={modalOpen}
        transparent
        animationType="slide"
        onRequestClose={() => setModalOpen(false)}
      >
        <Pressable
          style={scrStyles.modalBackdrop}
          onPress={() => setModalOpen(false)}
        >
          <Pressable
            style={[
              scrStyles.modalSheet,
              { backgroundColor: colors.card, paddingBottom: insets.bottom + 16, marginBottom: kbHeight },
            ]}
            onPress={() => {}}
          >
            <View style={scrStyles.modalHandle} />
            <Text style={[scrStyles.modalTitle, { color: colors.foreground }]}>
              {editId ? t("bankInfo.editTitle") : t("bankInfo.addAccount")}
            </Text>

            <ScrollView
              showsVerticalScrollIndicator={false}
              keyboardShouldPersistTaps="handled"
            >
              {/* Type selector */}
              <Text style={[scrStyles.formLabel, { color: colors.mutedForeground }]}>
                {t("bankInfo.accountType").toUpperCase()}
              </Text>
              <View style={{ flexDirection: "row", gap: 6 }}>
                {FORM_TYPE_DEFS.map((ft) => {
                  const fTheme = TYPE_THEME[ft.key];
                  const active = formType === ft.key;
                  return (
                    <TouchableOpacity
                      key={ft.key}
                      style={[
                        scrStyles.typeBtn,
                        { backgroundColor: active ? fTheme.bg : colors.background, borderColor: active ? fTheme.color : colors.border },
                      ]}
                      onPress={() => { Haptics.selectionAsync(); setFormType(ft.key); }}
                    >
                      <Feather name={ft.icon} size={12} color={active ? fTheme.color : colors.mutedForeground} />
                      <Text style={{ fontSize: 10, fontWeight: active ? "700" : "500", color: active ? fTheme.color : colors.mutedForeground }}>
                        {t(ft.labelKey)}
                      </Text>
                    </TouchableOpacity>
                  );
                })}
              </View>

              {/* Bank — inline expandable list */}
              <Text style={[scrStyles.formLabel, { color: colors.mutedForeground }]}>
                {t("bankInfo.bankLabel").toUpperCase()}
              </Text>
              <TouchableOpacity
                style={[scrStyles.input, { flexDirection: "row", alignItems: "center", backgroundColor: colors.background }]}
                onPress={() => { Haptics.selectionAsync(); setBankListOpen((v) => !v); }}
              >
                <Text style={{ flex: 1, fontSize: 14, color: colors.foreground }}>{formBank}</Text>
                <Feather name={bankListOpen ? "chevron-up" : "chevron-down"} size={16} color={colors.mutedForeground} />
              </TouchableOpacity>
              {bankListOpen && (
                <View style={[scrStyles.bankDropdown, { backgroundColor: colors.background, borderColor: colors.border }]}>
                  {BANKS.map((b) => (
                    <TouchableOpacity
                      key={b}
                      style={[
                        scrStyles.bankDropdownRow,
                        { borderBottomColor: colors.border },
                        formBank === b && { backgroundColor: theme.color + "15" },
                      ]}
                      onPress={() => {
                        Haptics.selectionAsync();
                        setFormBank(b);
                        setBankListOpen(false);
                      }}
                    >
                      <Text style={{ fontSize: 14, flex: 1, color: formBank === b ? theme.color : colors.foreground, fontWeight: formBank === b ? "700" : "400" }}>
                        {b}
                      </Text>
                      {formBank === b && <Feather name="check" size={14} color={theme.color} />}
                    </TouchableOpacity>
                  ))}
                </View>
              )}

              {/* Name */}
              <Text style={[scrStyles.formLabel, { color: colors.mutedForeground }]}>
                {t("bankInfo.accountName").toUpperCase()}
              </Text>
              <TextInput
                style={[scrStyles.input, { backgroundColor: colors.background, color: colors.foreground }]}
                value={formName}
                onChangeText={setFormName}
                placeholder={
                  formType === "credit" ? "örn. Garanti Bonus"
                  : formType === "time" ? "örn. 3 Aylık Vadeli"
                  : "örn. Maaş Hesabı"
                }
                placeholderTextColor={colors.mutedForeground}
              />

              {/* ── Vadeli fields ── */}
              {formType === "time" && (
                <>
                  <Text style={[scrStyles.formLabel, { color: colors.mutedForeground }]}>
                    {t("bankInfo.interestRateLabel", "FAİZ ORANI (%)").toUpperCase()}
                  </Text>
                  <TextInput
                    style={[scrStyles.input, { backgroundColor: colors.background, color: colors.foreground }]}
                    value={formInterestRate}
                    onChangeText={setFormInterestRate}
                    placeholder="örn. 52,5"
                    placeholderTextColor={colors.mutedForeground}
                    keyboardType="decimal-pad"
                  />
                  <Text style={[scrStyles.formLabel, { color: colors.mutedForeground }]}>
                    {t("bankInfo.openDateLabel", "AÇILIŞ TARİHİ (GG.AA.YYYY)").toUpperCase()}
                  </Text>
                  <TextInput
                    style={[scrStyles.input, { backgroundColor: colors.background, color: colors.foreground }]}
                    value={formOpenDate}
                    onChangeText={setFormOpenDate}
                    placeholder={t("bankInfo.datePlaceholder", "GG.AA.YYYY")}
                    placeholderTextColor={colors.mutedForeground}
                    keyboardType="numbers-and-punctuation"
                  />
                  <Text style={[scrStyles.formLabel, { color: colors.mutedForeground }]}>
                    {t("bankInfo.maturityDateLabel", "VADE TARİHİ (GG.AA.YYYY)").toUpperCase()}
                  </Text>
                  <TextInput
                    style={[scrStyles.input, { backgroundColor: colors.background, color: colors.foreground }]}
                    value={formMaturityDate}
                    onChangeText={setFormMaturityDate}
                    placeholder={t("bankInfo.datePlaceholder", "GG.AA.YYYY")}
                    placeholderTextColor={colors.mutedForeground}
                    keyboardType="numbers-and-punctuation"
                  />
                </>
              )}

              {/* ── Vadesiz fields ── */}
              {formType === "demand" && (
                <>
                  <Text style={[scrStyles.formLabel, { color: colors.mutedForeground }]}>
                    {t("bankInfo.iban").toUpperCase()}
                  </Text>
                  <TextInput
                    style={[scrStyles.input, { backgroundColor: colors.background, color: colors.foreground }]}
                    value={formIban}
                    onChangeText={(v) => setFormIban(v.toUpperCase())}
                    placeholder={t("bankInfo.ibanPlaceholder")}
                    placeholderTextColor={colors.mutedForeground}
                    autoCapitalize="characters"
                  />
                  <Text style={[scrStyles.formLabel, { color: colors.mutedForeground }]}>
                    {t("bankInfo.accountNumberFull").toUpperCase()}
                  </Text>
                  <TextInput
                    style={[scrStyles.input, { backgroundColor: colors.background, color: colors.foreground }]}
                    value={formAccount}
                    onChangeText={setFormAccount}
                    placeholder={t("bankInfo.accountNumberFull")}
                    placeholderTextColor={colors.mutedForeground}
                    keyboardType="number-pad"
                  />
                </>
              )}

              {/* ── Kredi Kartı fields ── */}
              {formType === "credit" && (
                <>
                  <Text style={[scrStyles.formLabel, { color: colors.mutedForeground }]}>
                    {t("bankInfo.cardLastDigits").toUpperCase()}
                  </Text>
                  <TextInput
                    style={[scrStyles.input, { backgroundColor: colors.background, color: colors.foreground }]}
                    value={formLast4}
                    onChangeText={(v) => setFormLast4(v.replace(/\D/g, "").slice(0, 4))}
                    placeholder="1234"
                    placeholderTextColor={colors.mutedForeground}
                    keyboardType="number-pad"
                    maxLength={4}
                  />
                  <Text style={[scrStyles.formLabel, { color: colors.mutedForeground }]}>
                    {t("bankInfo.statementDayLabel").toUpperCase()}
                  </Text>
                  <TextInput
                    style={[scrStyles.input, { backgroundColor: colors.background, color: colors.foreground }]}
                    value={formStatementDay}
                    onChangeText={(v) => setFormStatementDay(v.replace(/\D/g, "").slice(0, 2))}
                    placeholder="15"
                    placeholderTextColor={colors.mutedForeground}
                    keyboardType="number-pad"
                    maxLength={2}
                  />
                </>
              )}

              {/* ── Buttons ── */}
              <View style={scrStyles.btnRow}>
                {editId && (
                  <TouchableOpacity
                    style={scrStyles.deleteBtn}
                    onPress={handleDelete}
                    activeOpacity={0.85}
                  >
                    <Feather name="trash-2" size={17} color="#DC2626" />
                  </TouchableOpacity>
                )}
                <TouchableOpacity
                  style={[scrStyles.cancelBtn, { flex: 1, backgroundColor: colors.muted }]}
                  onPress={() => setModalOpen(false)}
                  activeOpacity={0.85}
                >
                  <Text style={[scrStyles.cancelBtnText, { color: colors.foreground }]}>
                    {t("common.cancel")}
                  </Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={[scrStyles.saveBtn, { flex: 1, backgroundColor: theme.color }]}
                  onPress={handleSave}
                  activeOpacity={0.85}
                >
                  <Text style={scrStyles.saveBtnText}>
                    {editId ? t("bankInfo.update") : t("common.save")}
                  </Text>
                </TouchableOpacity>
              </View>
              <View style={{ height: 12 }} />
            </ScrollView>
          </Pressable>
        </Pressable>
      </Modal>

    </View>
  );
}

const scrStyles = StyleSheet.create({
  header: {
    paddingTop: 16, paddingHorizontal: 18, paddingBottom: 16,
    flexDirection: "row", alignItems: "center",
  },
  headerTitle: { flex: 1, fontSize: 22, fontWeight: "800", color: "#FFFFFF" },
  addBtn: { width: 36, height: 36, borderRadius: 18, alignItems: "center", justifyContent: "center" },

  emptyState: { alignItems: "center", paddingVertical: 60, paddingHorizontal: 40 },
  emptyTitle: { marginTop: 16, fontSize: 17, fontWeight: "700", textAlign: "center" },
  emptyHint: { marginTop: 8, fontSize: 13, textAlign: "center", lineHeight: 20 },
  emptyAddBtn: {
    flexDirection: "row", alignItems: "center", gap: 8,
    marginTop: 24, paddingHorizontal: 20, paddingVertical: 12,
    borderRadius: 14,
  },

  modalBackdrop: { flex: 1, backgroundColor: "rgba(0,0,0,0.5)", justifyContent: "flex-end" },
  modalSheet: {
    borderTopLeftRadius: 24, borderTopRightRadius: 24,
    paddingHorizontal: 20, maxHeight: "92%",
  },
  modalHandle: {
    width: 40, height: 4, borderRadius: 2,
    backgroundColor: "#D1D5DB", alignSelf: "center",
    marginTop: 10, marginBottom: 4,
  },
  modalTitle: { fontSize: 17, fontWeight: "700", textAlign: "center", paddingVertical: 12 },

  formLabel: {
    fontSize: 11, fontWeight: "700", letterSpacing: 0.6,
    textTransform: "uppercase", marginTop: 14, marginBottom: 5,
  },
  input: {
    borderRadius: 10, paddingHorizontal: 12, paddingVertical: 12,
    fontSize: 14,
  },
  typeBtn: {
    flex: 1, flexDirection: "row", alignItems: "center", justifyContent: "center",
    gap: 5, paddingVertical: 10,
    borderRadius: 11, borderWidth: 1.5,
  },

  btnRow: { flexDirection: "row", gap: 8, marginTop: 22 },
  deleteBtn: {
    width: 52, height: 52, borderRadius: 14,
    alignItems: "center", justifyContent: "center",
    backgroundColor: "#FEF2F2", borderWidth: 1, borderColor: "#FECACA",
  },
  cancelBtn: { borderRadius: 14, paddingVertical: 15, alignItems: "center" },
  cancelBtnText: { fontSize: 15, fontWeight: "700" },
  saveBtn: { borderRadius: 14, paddingVertical: 15, alignItems: "center" },
  saveBtnText: { fontSize: 15, fontWeight: "800", color: "#FFFFFF" },

  bankDropdown: {
    borderRadius: 10, borderWidth: StyleSheet.hairlineWidth,
    marginTop: 2, maxHeight: 220, overflow: "hidden",
  },
  bankDropdownRow: {
    flexDirection: "row", alignItems: "center",
    paddingVertical: 11, paddingHorizontal: 12,
    borderBottomWidth: StyleSheet.hairlineWidth,
  },
});
