import { Feather } from "@expo/vector-icons";
import * as Haptics from "expo-haptics";
import { LinearGradient } from "expo-linear-gradient";
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
import AssetLogo from "@/components/finans/AssetLogo";
import SearchPicker from "@/components/finans/SearchPicker";
import { AssetEntry, AssetType, useBudget } from "@/context/finans/BudgetContext";
import { useColors } from "@/hooks/finans/useColors";
import { useListOrder } from "@/hooks/finans/useListOrder";
import { BIST_STOCKS, CRYPTO_LIST, FOREX_LIST, GOLD_LIST, PLATFORM_OPTIONS, STOCK_INDICES } from "@/utils/finans/assets-data";
import { fetchUnitPrice, fetchStockPriceTRY } from "@/utils/finans/priceApi";
import { useTranslation } from "react-i18next";
import { useFormatAmount } from "@/hooks/finans/useFormatAmount";

const PRICE_TYPES: AssetType[] = ["kripto", "borsa", "doviz", "altin"];

export default function AssetsScreen() {
  const formatAmount = useFormatAmount();
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const { t }  = useTranslation();

  const getForexDisplayName = (name: string) => {
    const code = name.split(/[\s–\-]/)[0].replace(/[^A-Z]/g, "");
    if (!code || code.length !== 3) return name;
    try {
      const dn = new Intl.DisplayNames(["en"], { type: "currency" });
      const localName = dn.of(code);
      return localName ? `${code} – ${localName}` : name;
    } catch {
      return name;
    }
  };
  const { assetEntries, addAssetEntry, updateAssetEntry, deleteAssetEntry } = useBudget();

  const ASSET_TYPES: { key: AssetType; label: string; icon: keyof typeof import("@expo/vector-icons").Feather.glyphMap; color: string }[] = [
    { key: "vadesiz", label: t("assets.types.vadesiz"), icon: "layers",       color: "#00C896" },
    { key: "vadeli",  label: t("assets.types.vadeli"),  icon: "clock",         color: "#3B82F6" },
    { key: "kripto",  label: t("assets.types.kripto"),  icon: "zap",           color: "#F59E0B" },
    { key: "borsa",   label: t("assets.types.borsa"),   icon: "trending-up",   color: "#8B5CF6" },
    { key: "doviz",   label: t("assets.types.doviz"),   icon: "dollar-sign",   color: "#06B6D4" },
    { key: "altin",   label: t("assets.types.altin"),   icon: "award",         color: "#EAB308" },
  ];

  const INVESTMENT_GRID_TYPES = [
    { key: "vadesiz" as AssetType, label: t("assets.types.vadesiz"), icon: "layers"      as const, color: "#00C896" },
    { key: "vadeli"  as AssetType, label: t("assets.types.vadeli"),  icon: "clock"       as const, color: "#3B82F6" },
    { key: "kripto"  as AssetType, label: t("assets.types.kripto"),  icon: "zap"         as const, color: "#F59E0B" },
    { key: "borsa"   as AssetType, label: t("assets.types.borsa"),   icon: "trending-up" as const, color: "#8B5CF6" },
    { key: "doviz"   as AssetType, label: t("assets.types.doviz"),   icon: "dollar-sign" as const, color: "#06B6D4" },
    { key: "altin"   as AssetType, label: t("assets.types.altin"),   icon: "award"       as const, color: "#EAB308" },
  ];

  const [assetModalOpen, setAssetModalOpen]       = useState(false);
  const [assetEditId, setAssetEditId]             = useState<string | null>(null);
  const [lockedAssetType, setLockedAssetType]     = useState<AssetType | null>(null);
  const [assetName, setAssetName]                 = useState("");
  const [assetPlatform, setAssetPlatform]         = useState("");
  const [assetType, setAssetType]                 = useState<AssetType>("vadeli");
  const [assetAmount, setAssetAmount]             = useState("");
  const [assetNote, setAssetNote]                 = useState("");
  const [assetQuantity, setAssetQuantity]         = useState("");
  const [assetUnitPrice, setAssetUnitPrice]       = useState("");
  const [assetInterestRate, setAssetInterestRate] = useState("");
  const [assetMaturityDate, setAssetMaturityDate] = useState("");
  const [priceFetching, setPriceFetching]           = useState(false);
  const [priceFetchErr, setPriceFetchErr]           = useState<string | null>(null);
  const [selectedStockIndex, setSelectedStockIndex] = useState<string>("");

  const isPriceType = PRICE_TYPES.includes(assetType);

  const calcTotal = useMemo(() => {
    const qty = parseFloat(assetQuantity.replace(",", "."));
    const up  = parseFloat(assetUnitPrice.replace(",", "."));
    if (!Number.isFinite(qty) || !Number.isFinite(up)) return null;
    return qty * up;
  }, [assetQuantity, assetUnitPrice]);

  const stockOptions = useMemo(() => {
    if (!selectedStockIndex) return BIST_STOCKS;
    const idx = STOCK_INDICES.find((i) => i.id === selectedStockIndex);
    return idx ? idx.stocks : BIST_STOCKS;
  }, [selectedStockIndex]);

  const triggerPriceFetch = async (type: AssetType, name: string) => {
    if (!PRICE_TYPES.includes(type) || !name) return;
    setPriceFetching(true);
    setPriceFetchErr(null);
    setAssetUnitPrice("");
    let price: number | null;
    if (type === "borsa" && selectedStockIndex) {
      const idx = STOCK_INDICES.find((i) => i.id === selectedStockIndex);
      price = idx
        ? await fetchStockPriceTRY(name, idx.exchangeSuffix, idx.currency, idx.priceDivisor)
        : await fetchUnitPrice(type, name);
    } else {
      price = await fetchUnitPrice(type, name);
    }
    setPriceFetching(false);
    if (price !== null && price > 0) {
      setAssetUnitPrice(price.toFixed(price < 1 ? 8 : 2));
      setPriceFetchErr(null);
    } else {
      setPriceFetchErr(t("assets.priceFetchErr"));
    }
  };

  const openAssetAdd = (defaultType?: AssetType, locked = false) => {
    Haptics.selectionAsync();
    setAssetEditId(null);
    setAssetName("");
    setAssetPlatform("");
    setAssetType(defaultType ?? "vadeli");
    setLockedAssetType(locked && defaultType ? defaultType : null);
    setAssetAmount("");
    setAssetQuantity("");
    setAssetUnitPrice("");
    setAssetInterestRate("");
    setAssetMaturityDate("");
    setPriceFetchErr(null);
    setSelectedStockIndex("");
    setAssetNote("");
    setAssetModalOpen(true);
  };

  const openAssetEdit = (e: AssetEntry) => {
    Haptics.selectionAsync();
    setAssetEditId(e.id);
    setLockedAssetType(null);
    setAssetName(e.name);
    setAssetPlatform(e.platform);
    setAssetType(e.assetType);
    setAssetNote(e.note ?? "");
    setAssetInterestRate(e.interestRate !== undefined ? String(e.interestRate) : "");
    setAssetMaturityDate(e.maturityDate
      ? (() => { const [y, m, d] = e.maturityDate!.split("-"); return `${d}.${m}.${y}`; })()
      : "");
    setPriceFetchErr(null);
    setSelectedStockIndex("");
    if (PRICE_TYPES.includes(e.assetType)) {
      setAssetQuantity(e.quantity !== undefined ? String(e.quantity) : "");
      setAssetUnitPrice(e.unitPrice !== undefined ? String(e.unitPrice) : "");
      setAssetAmount("");
    } else {
      setAssetAmount(String(e.amount));
      setAssetQuantity("");
      setAssetUnitPrice("");
    }
    setAssetModalOpen(true);
  };

  const submitAssetBase = (onSuccess: () => void) => {
    const name = assetName.trim();
    const platform = assetPlatform.trim();

    if (!name) {
      const m = t("assets.validation.nameRequired");
      Platform.OS === "web" ? window.alert(m) : Alert.alert(t("assets.validation.missing"), m);
      return;
    }

    let amount: number;
    let quantity: number | undefined;
    let unitPrice: number | undefined;

    if (isPriceType) {
      const qty = parseFloat(assetQuantity.replace(",", "."));
      const up  = parseFloat(assetUnitPrice.replace(",", "."));
      if (!Number.isFinite(qty) || qty <= 0) {
        const m = t("assets.validation.quantityRequired");
        Platform.OS === "web" ? window.alert(m) : Alert.alert(t("assets.validation.missing"), m);
        return;
      }
      if (!Number.isFinite(up) || up <= 0) {
        const m = t("assets.validation.unitPriceRequired");
        Platform.OS === "web" ? window.alert(m) : Alert.alert(t("assets.validation.missing"), m);
        return;
      }
      quantity  = qty;
      unitPrice = up;
      amount    = qty * up;
    } else {
      amount = parseFloat(assetAmount.replace(",", "."));
      if (!Number.isFinite(amount) || amount < 0) {
        const m = t("assets.validation.amountRequired");
        Platform.OS === "web" ? window.alert(m) : Alert.alert(t("assets.validation.invalid"), m);
        return;
      }
    }

    const ir = parseFloat(assetInterestRate.replace(",", "."));
    const interestRate = assetType === "vadeli" && Number.isFinite(ir) && ir > 0 ? ir : undefined;
    let maturityDateRaw = assetMaturityDate.trim();
    if (/^\d{2}\.\d{2}\.\d{4}$/.test(maturityDateRaw)) {
      const [dd, mm, yyyy] = maturityDateRaw.split(".");
      maturityDateRaw = `${yyyy}-${mm}-${dd}`;
    }
    const maturityDate = assetType === "vadeli" && maturityDateRaw ? maturityDateRaw : undefined;

    const payload = { name, platform, assetType, amount, quantity, unitPrice, note: assetNote.trim() || undefined, interestRate, maturityDate };
    if (assetEditId) {
      updateAssetEntry(assetEditId, payload);
    } else {
      addAssetEntry(payload);
    }
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    onSuccess();
  };

  const submitAsset       = () => submitAssetBase(() => setAssetModalOpen(false));
  const submitDetailAsset = () => submitAssetBase(() => setDetailFormMode("none"));

  const openDetailAdd = (type: AssetType) => {
    Haptics.selectionAsync();
    setAssetEditId(null);
    setLockedAssetType(type);
    setAssetType(type);
    setAssetName("");
    setAssetPlatform("");
    setAssetAmount("");
    setAssetQuantity("");
    setAssetUnitPrice("");
    setAssetInterestRate("");
    setAssetMaturityDate("");
    setPriceFetchErr(null);
    setSelectedStockIndex("");
    setAssetNote("");
    setDetailFormMode("add");
  };

  const openDetailEdit = (e: AssetEntry) => {
    Haptics.selectionAsync();
    setAssetEditId(e.id);
    setLockedAssetType(e.assetType);
    setAssetType(e.assetType);
    setAssetName(e.name);
    setAssetPlatform(e.platform);
    setAssetNote(e.note ?? "");
    setAssetInterestRate(e.interestRate !== undefined ? String(e.interestRate) : "");
    setAssetMaturityDate(e.maturityDate
      ? (() => { const [y, m, d] = e.maturityDate!.split("-"); return `${d}.${m}.${y}`; })()
      : "");
    setPriceFetchErr(null);
    setSelectedStockIndex("");
    if (PRICE_TYPES.includes(e.assetType)) {
      setAssetQuantity(e.quantity !== undefined ? String(e.quantity) : "");
      setAssetUnitPrice(e.unitPrice !== undefined ? String(e.unitPrice) : "");
      setAssetAmount("");
    } else {
      setAssetAmount(String(e.amount));
      setAssetQuantity("");
      setAssetUnitPrice("");
    }
    setDetailFormMode("edit");
  };

  const handleDeleteDetail = (e: AssetEntry) => {
    const msg = t("assets.deleteConfirm", { name: e.name });
    if (Platform.OS === "web") {
      if (window.confirm(msg)) { deleteAssetEntry(e.id); setDetailFormMode("none"); }
      return;
    }
    Alert.alert(t("assets.deleteTitle"), msg, [
      { text: t("assets.cancel"), style: "cancel" },
      { text: t("assets.deleteTitle"), style: "destructive", onPress: () => {
        deleteAssetEntry(e.id);
        setDetailFormMode("none");
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      }},
    ]);
  };

  const handleDeleteAsset = (e: AssetEntry) => {
    const msg = t("assets.deleteConfirm", { name: e.name });
    if (Platform.OS === "web") {
      if (window.confirm(msg)) deleteAssetEntry(e.id);
      return;
    }
    Alert.alert(t("assets.deleteTitle"), msg, [
      { text: t("assets.cancel"), style: "cancel" },
      { text: t("assets.deleteTitle"), style: "destructive", onPress: () => {
        deleteAssetEntry(e.id);
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      }},
    ]);
  };

  const totalAssets = useMemo(
    () => assetEntries.reduce((s, e) => s + e.amount, 0),
    [assetEntries]
  );

  const groupTotals = useMemo(() => {
    return INVESTMENT_GRID_TYPES.map((g) => {
      const items = assetEntries.filter((e) => e.assetType === g.key);
      const total = items.reduce((s, e) => s + e.amount, 0);
      return { label: g.label, color: g.color, icon: g.icon, total, count: items.length };
    });
  }, [assetEntries]);

  const bottomInset = Platform.OS === "web" ? 34 : insets.bottom;
  const assetIds = useMemo(() => assetEntries.map((e) => e.id), [assetEntries]);
  const [reorderMode, setReorderMode] = useState(false);
  const [detailType, setDetailType]   = useState<AssetType | null>(null);
  const [detailFormMode, setDetailFormMode] = useState<"none" | "add" | "edit">("none");
  const assetsOrder = useListOrder("assets-order", assetIds);

  const moveWithinGroup = (id: string, dir: "up" | "down", groupItems: AssetEntry[]) => {
    Haptics.selectionAsync();
    assetsOrder.setOrderedIds((prev) => {
      const groupSorted = groupItems
        .map((e) => e.id)
        .filter((gid) => prev.includes(gid))
        .sort((a, b) => prev.indexOf(a) - prev.indexOf(b));
      const pos = groupSorted.indexOf(id);
      const next = dir === "up" ? pos - 1 : pos + 1;
      if (next < 0 || next >= groupSorted.length) return prev;
      const idxA = prev.indexOf(id);
      const idxB = prev.indexOf(groupSorted[next]);
      const arr = [...prev];
      [arr[idxA], arr[idxB]] = [arr[idxB], arr[idxA]];
      AsyncStorage.setItem("assets-order", JSON.stringify(arr));
      return arr;
    });
  };

  const styles = StyleSheet.create({
    container: { flex: 1, backgroundColor: colors.background },
    header: {
      backgroundColor: colors.navy,
      paddingTop: 16,
      paddingBottom: 16,
      paddingHorizontal: 20,
    },
    headerTitle: {
      fontSize: 20,
      fontWeight: "800",
      color: "#FFFFFF",
      textAlign: "center",
    },
    heroCard: {
      marginHorizontal: 16,
      marginTop: 16,
      borderRadius: 22,
      padding: 22,
      overflow: "hidden",
    },
    heroBubble: {
      position: "absolute",
      width: 180,
      height: 180,
      borderRadius: 90,
      right: -50,
      top: -60,
      opacity: 0.18,
    },
    heroTopRow: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      marginBottom: 18,
    },
    heroIconBadge: {
      width: 40,
      height: 40,
      borderRadius: 12,
      backgroundColor: "rgba(255,255,255,0.22)",
      alignItems: "center",
      justifyContent: "center",
    },
    heroTrendChip: {
      flexDirection: "row",
      alignItems: "center",
      gap: 5,
      paddingHorizontal: 10,
      paddingVertical: 5,
      borderRadius: 20,
    },
    heroTrendText: {
      fontSize: 11,
      fontWeight: "700",
      color: "#FFF",
      letterSpacing: 0.3,
    },
    heroLabel: {
      fontSize: 11,
      fontWeight: "700",
      color: "rgba(255,255,255,0.7)",
      letterSpacing: 1.4,
      textTransform: "uppercase",
      marginBottom: 6,
    },
    heroAmount: {
      fontSize: 38,
      fontWeight: "800",
      color: "#FFFFFF",
      letterSpacing: -1,
    },
    heroPillRow: {
      flexDirection: "row",
      flexWrap: "wrap",
      gap: 8,
      marginTop: 18,
    },
    heroPill: {
      flexDirection: "row",
      alignItems: "center",
      gap: 5,
      backgroundColor: "rgba(255,255,255,0.18)",
      paddingHorizontal: 10,
      paddingVertical: 5,
      borderRadius: 20,
    },
    heroPillText: {
      fontSize: 11,
      fontWeight: "600",
      color: "rgba(255,255,255,0.9)",
    },
    heroPillPct: {
      fontSize: 10,
      fontWeight: "700",
      color: "#FFF",
    },
    groupRow: {
      flexDirection: "row",
      alignItems: "center",
      gap: 10,
      paddingVertical: 8,
    },
    groupRowBorder: {
      borderBottomWidth: 1,
      borderBottomColor: colors.border,
    },
    groupIcon: {
      width: 30,
      height: 30,
      borderRadius: 9,
      alignItems: "center",
      justifyContent: "center",
    },
    groupLabel: {
      flex: 1,
      fontSize: 13,
      color: colors.foreground,
      fontWeight: "600",
    },
    groupAmount: {
      fontSize: 14,
      fontWeight: "700",
    },
    groupPct: {
      fontSize: 10,
      color: colors.mutedForeground,
      fontWeight: "600",
      marginTop: 1,
    },
    addRow: { paddingHorizontal: 20, marginTop: 16 },
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
    list: { paddingHorizontal: 20, marginTop: 4, paddingBottom: 24 },
    assetSectionLabel: {
      fontSize: 11,
      fontWeight: "700",
      color: colors.mutedForeground,
      letterSpacing: 0.8,
      textTransform: "uppercase",
      marginTop: 16,
      marginBottom: 6,
    },
    assetList: {
      backgroundColor: colors.card,
      borderRadius: colors.radius,
      overflow: "hidden",
      marginBottom: 12,
    },
    assetRow: {
      flexDirection: "row",
      alignItems: "center",
      gap: 11,
      paddingVertical: 12,
      paddingHorizontal: 14,
    },
    assetRowBorder: {
      borderBottomWidth: 1,
      borderBottomColor: colors.border,
    },
    assetInitial: {
      width: 36,
      height: 36,
      borderRadius: 10,
      alignItems: "center",
      justifyContent: "center",
      backgroundColor: colors.primary + "20",
    },
    assetName: {
      fontSize: 14,
      fontWeight: "700",
      color: colors.foreground,
    },
    assetSub: {
      fontSize: 11,
      color: colors.mutedForeground,
      marginTop: 1,
    },
    assetBalance: {
      fontSize: 14,
      fontWeight: "800",
      textAlign: "right",
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
    input: {
      backgroundColor: colors.muted,
      borderRadius: 12,
      paddingVertical: 12,
      paddingHorizontal: 14,
      color: colors.foreground,
      fontSize: 15,
    },
    typeChip: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "center",
      gap: 6,
      paddingVertical: 10,
      paddingHorizontal: 12,
      borderRadius: 10,
      backgroundColor: colors.muted,
      borderWidth: 1,
      borderColor: colors.border,
    },
    typeChipText: {
      fontSize: 13,
      fontWeight: "600",
      color: colors.foreground,
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

    investGridWrap: { paddingHorizontal: 14, paddingTop: 6, paddingBottom: 4 },
    investGrid: { flexDirection: "row", flexWrap: "wrap", gap: 10 },
    gridCard: {
      width: "48%",
      borderRadius: 18,
      borderWidth: 1.5,
      padding: 14,
      gap: 4,
    },
    gridCardTop: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      marginBottom: 10,
    },
    gridCardIconBox: {
      width: 44,
      height: 44,
      borderRadius: 14,
      alignItems: "center",
      justifyContent: "center",
    },
    gridCardLabel: { fontSize: 10, fontWeight: "800", letterSpacing: 1.2 },
    gridCardTotal: { fontSize: 15, fontWeight: "800", color: colors.foreground },
    gridCardCount: { fontSize: 11, fontWeight: "600" },
    gridCardEmpty: { fontSize: 12, fontWeight: "700", marginTop: 4 },
    gridExpanded: {
      marginHorizontal: 14,
      marginBottom: 12,
      borderRadius: 16,
      borderWidth: 1,
      overflow: "hidden",
      backgroundColor: colors.card,
    },
    gridExpandedAddBtn: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "center",
      gap: 6,
      margin: 12,
      paddingVertical: 9,
      borderRadius: 10,
    },
    gridExpandedAddBtnText: { color: "#FFFFFF", fontWeight: "700", fontSize: 13 },
    gridEmptyText: {
      textAlign: "center",
      fontSize: 13,
      fontWeight: "500",
      paddingVertical: 20,
      paddingHorizontal: 16,
    },

    reorderBanner: {
      flexDirection: "row" as const,
      alignItems: "center" as const,
      justifyContent: "center" as const,
      backgroundColor: colors.primary,
      paddingVertical: 10,
      gap: 8,
    },
    reorderBannerText: { fontSize: 13, fontWeight: "700" as const, color: "#FFFFFF" },
    reorderArrows: { flexDirection: "row" as const, gap: 2 },
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
          <Text style={styles.headerTitle}>{t("assets.title")}</Text>
        </View>

        {/* Toplam Varlık özet kartı */}
        {(() => {
          const isPositive = totalAssets >= 0;
          const gradColors = isPositive
            ? (["#00A877", "#00C896", "#34D9AC"] as const)
            : (["#B91C1C", "#DC2626", "#EF4444"] as const);
          const accentColor = isPositive ? "#00FFC8" : "#FCA5A5";
          const trendIcon  = isPositive ? "trending-up" : "trending-down";
          return (
            <LinearGradient
              colors={gradColors}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 1 }}
              style={styles.heroCard}
            >
              {/* decorative blurred circle */}
              <View style={[styles.heroBubble, { backgroundColor: accentColor }]} />

              {/* Top row: icon badge + trend chip */}
              <View style={styles.heroTopRow}>
                <View style={styles.heroIconBadge}>
                  <Feather name="briefcase" size={18} color="#FFF" />
                </View>
                <View style={[styles.heroTrendChip, { backgroundColor: "rgba(255,255,255,0.18)" }]}>
                  <Feather name={trendIcon} size={12} color="#FFF" />
                  <Text style={styles.heroTrendText}>
                    {isPositive ? t("assets.positive") : t("assets.negative")}
                  </Text>
                </View>
              </View>

              {/* Label */}
              <Text style={styles.heroLabel}>{t("assets.totalAssetsLabel")}</Text>

              {/* Amount */}
              <Text style={styles.heroAmount} numberOfLines={1} adjustsFontSizeToFit>
                {formatAmount(totalAssets)}
              </Text>

              {/* Breakdown pills */}
              {assetEntries.length > 0 && (
                <View style={styles.heroPillRow}>
                  {groupTotals.filter((g) => g.count > 0).map((g) => {
                    const pct = totalAssets !== 0 ? Math.round(Math.abs(g.total / totalAssets) * 100) : 0;
                    return (
                      <View key={g.label} style={styles.heroPill}>
                        <Feather name={g.icon} size={10} color="rgba(255,255,255,0.85)" />
                        <Text style={styles.heroPillText} numberOfLines={1}>{g.label}</Text>
                        <Text style={styles.heroPillPct}>{pct}%</Text>
                      </View>
                    );
                  })}
                </View>
              )}
            </LinearGradient>
          );
        })()}


        {/* Reorder banner (global) */}
        {reorderMode && (
          <TouchableOpacity style={styles.reorderBanner} onPress={() => setReorderMode(false)}>
            <Feather name="check" size={14} color="#FFFFFF" />
            <Text style={styles.reorderBannerText}>Sıralamayı Kaydet ✓</Text>
          </TouchableOpacity>
        )}

        {/* 2×3 Varlık Grid */}
        <View style={styles.investGridWrap}>
          <View style={styles.investGrid}>
            {INVESTMENT_GRID_TYPES.map((gt) => {
              const typeItems = assetEntries.filter((e) => e.assetType === gt.key);
              const total = typeItems.reduce((s, e) => s + e.amount, 0);
              return (
                <TouchableOpacity
                  key={gt.key}
                  style={[
                    styles.gridCard,
                    { borderColor: gt.color + "55", backgroundColor: gt.color + "0E" },
                  ]}
                  onPress={() => {
                    setDetailType(gt.key);
                    setDetailFormMode("none");
                    setReorderMode(false);
                  }}
                  activeOpacity={0.75}
                >
                  <View style={styles.gridCardTop}>
                    <View style={[styles.gridCardIconBox, { backgroundColor: gt.color + "28" }]}>
                      <Feather name={gt.icon} size={21} color={gt.color} />
                    </View>
                    <Feather name="chevron-right" size={14} color={gt.color + "AA"} />
                  </View>
                  <Text style={[styles.gridCardLabel, { color: gt.color }]}>{gt.label.toUpperCase()}</Text>
                  {typeItems.length > 0 ? (
                    <>
                      <Text style={styles.gridCardTotal} numberOfLines={1}>{formatAmount(total)}</Text>
                      <Text style={[styles.gridCardCount, { color: gt.color + "BB" }]}>{t("assets.assetCount", { count: typeItems.length })}</Text>
                    </>
                  ) : (
                    <Text style={[styles.gridCardEmpty, { color: gt.color + "80" }]}>+ {t("assets.addAsset")}</Text>
                  )}
                </TouchableOpacity>
              );
            })}
          </View>
        </View>


      </ScrollView>

      {/* ── Varlık Tipi Detay Modal (tam ekran) ─────────────────────── */}
      {detailType && (() => {
        const gt = INVESTMENT_GRID_TYPES.find((x) => x.key === detailType)!;
        const rawItems = assetEntries.filter((e) => e.assetType === detailType);
        const items = assetsOrder.sortedByOrder(rawItems);
        const isBankType = detailType === "vadesiz" || detailType === "vadeli";
        const total = items.reduce((s, e) => s + e.amount, 0);
        const currentEditEntry = assetEditId ? assetEntries.find((e) => e.id === assetEditId) : null;
        return (
          <Modal
            visible
            animationType="slide"
            onRequestClose={() => { setDetailType(null); setDetailFormMode("none"); }}
          >
            <View style={{ flex: 1, backgroundColor: colors.background }}>
              {/* Başlık */}
              <View style={{
                backgroundColor: colors.navy,
                paddingTop: insets.top + 10,
                paddingBottom: 14,
                paddingHorizontal: 18,
                flexDirection: "row",
                alignItems: "center",
                gap: 12,
              }}>
                <View style={{ width: 38, height: 38, borderRadius: 12, backgroundColor: gt.color + "30", alignItems: "center", justifyContent: "center" }}>
                  <Feather name={gt.icon} size={20} color={gt.color} />
                </View>
                <View style={{ flex: 1 }}>
                  <Text style={{ fontSize: 18, fontWeight: "800", color: "#FFF" }}>{gt.label}</Text>
                  {items.length > 0 && (
                    <Text style={{ fontSize: 12, color: gt.color, fontWeight: "600" }}>{formatAmount(total)}</Text>
                  )}
                </View>
                <TouchableOpacity
                  onPress={() => { setDetailType(null); setDetailFormMode("none"); }}
                  style={{ width: 36, height: 36, borderRadius: 10, backgroundColor: "rgba(255,255,255,0.12)", alignItems: "center", justifyContent: "center" }}
                >
                  <Feather name="x" size={18} color="#FFF" />
                </TouchableOpacity>
              </View>

              <KeyboardAvoidingView behavior={Platform.OS === "ios" ? "padding" : undefined} style={{ flex: 1 }}>
                <ScrollView contentContainerStyle={{ padding: 16, paddingBottom: insets.bottom + 24 }} keyboardShouldPersistTaps="handled">

                  {/* LIST VIEW */}
                  {detailFormMode === "none" && (
                    <>
                      <TouchableOpacity
                        onPress={() => openDetailAdd(detailType)}
                        style={{ flexDirection: "row", alignItems: "center", justifyContent: "center", gap: 8, backgroundColor: gt.color, borderRadius: 14, paddingVertical: 13, marginBottom: 16 }}
                      >
                        <Feather name="plus" size={16} color="#FFF" />
                        <Text style={{ color: "#FFF", fontWeight: "700", fontSize: 15 }}>Yeni {gt.label} Ekle</Text>
                      </TouchableOpacity>

                      {items.length === 0 ? (
                        <View style={{ alignItems: "center", paddingVertical: 40 }}>
                          <View style={{ width: 64, height: 64, borderRadius: 20, backgroundColor: gt.color + "18", alignItems: "center", justifyContent: "center", marginBottom: 14 }}>
                            <Feather name={gt.icon} size={30} color={gt.color + "99"} />
                          </View>
                          <Text style={{ fontSize: 15, color: colors.mutedForeground, textAlign: "center", lineHeight: 22 }}>
                            Henüz {gt.label.toLowerCase()} eklenmedi.{"\n"}Yukarıdaki butona tıklayarak ekleyebilirsin.
                          </Text>
                        </View>
                      ) : (
                        <View style={styles.assetList}>
                          {items.map((e, idx) => {
                            const isLast = idx === items.length - 1;
                            const maturityMs = e.maturityDate ? new Date(e.maturityDate).getTime() : null;
                            const daysLeft = maturityMs !== null ? Math.ceil((maturityMs - Date.now()) / 86400000) : null;
                            const maturityFormatted = e.maturityDate
                              ? (() => { const [y, m, d] = e.maturityDate!.split("-"); return `${d}.${m}.${y}`; })()
                              : null;
                            return (
                              <TouchableOpacity
                                key={e.id}
                                style={[styles.assetRow, !isLast && styles.assetRowBorder]}
                                onPress={() => openDetailEdit(e)}
                                activeOpacity={0.6}
                              >
                                {isBankType ? (
                                  <View style={[styles.assetInitial, { backgroundColor: gt.color + "22" }]}>
                                    <Feather name={gt.icon} size={16} color={gt.color} />
                                  </View>
                                ) : (
                                  <AssetLogo assetType={e.assetType} name={e.name} size={40} borderRadius={11} />
                                )}
                                <View style={{ flex: 1 }}>
                                  <Text style={styles.assetName} numberOfLines={1}>
                                    {e.assetType === "doviz" ? getForexDisplayName(e.name) : e.name}
                                  </Text>
                                  {e.platform ? <Text style={styles.assetSub} numberOfLines={1}>{e.platform}</Text> : null}
                                  {e.assetType === "vadeli" && (e.interestRate !== undefined || e.maturityDate) && (
                                    <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 6, marginTop: 3 }}>
                                      {e.interestRate !== undefined && (
                                        <View style={{ flexDirection: "row", alignItems: "center", gap: 3, backgroundColor: "#3B82F620", paddingHorizontal: 7, paddingVertical: 2, borderRadius: 8 }}>
                                          <Feather name="percent" size={9} color="#3B82F6" />
                                          <Text style={{ fontSize: 10, color: "#3B82F6", fontWeight: "600" }}>{e.interestRate}% faiz</Text>
                                        </View>
                                      )}
                                      {daysLeft !== null && maturityFormatted && (
                                        <View style={{ flexDirection: "row", alignItems: "center", gap: 3, backgroundColor: (daysLeft <= 7 ? "#EF4444" : daysLeft <= 30 ? "#F59E0B" : "#10B981") + "20", paddingHorizontal: 7, paddingVertical: 2, borderRadius: 8 }}>
                                          <Feather name="calendar" size={9} color={daysLeft <= 7 ? "#EF4444" : daysLeft <= 30 ? "#F59E0B" : "#10B981"} />
                                          <Text style={{ fontSize: 10, color: daysLeft <= 7 ? "#EF4444" : daysLeft <= 30 ? "#F59E0B" : "#10B981", fontWeight: "600" }}>
                                            {daysLeft < 0 ? `Vadesi geçti (${maturityFormatted})` : daysLeft === 0 ? "Bugün vade!" : `${maturityFormatted} · ${daysLeft}g`}
                                          </Text>
                                        </View>
                                      )}
                                    </View>
                                  )}
                                </View>
                                <View style={{ alignItems: "flex-end", gap: 4 }}>
                                  <Text style={[styles.assetBalance, { color: gt.color }]}>{formatAmount(e.amount)}</Text>
                                  <View style={{ flexDirection: "row", alignItems: "center", gap: 3, backgroundColor: gt.color + "18", paddingHorizontal: 8, paddingVertical: 3, borderRadius: 8 }}>
                                    <Feather name="edit-2" size={10} color={gt.color} />
                                    <Text style={{ fontSize: 10, color: gt.color, fontWeight: "600" }}>Düzenle</Text>
                                  </View>
                                </View>
                              </TouchableOpacity>
                            );
                          })}
                        </View>
                      )}
                    </>
                  )}

                  {/* FORM VIEW (add or edit) */}
                  {detailFormMode !== "none" && (
                    <>
                      {/* Form başlık */}
                      <View style={{ flexDirection: "row", alignItems: "center", gap: 10, marginBottom: 18 }}>
                        <View style={{ width: 34, height: 34, borderRadius: 10, backgroundColor: gt.color + "22", alignItems: "center", justifyContent: "center" }}>
                          <Feather name={detailFormMode === "add" ? "plus-circle" : "edit-2"} size={16} color={gt.color} />
                        </View>
                        <Text style={{ fontSize: 16, fontWeight: "800", color: colors.foreground }}>
                          {detailFormMode === "add" ? `Yeni ${gt.label} Ekle` : `${gt.label} Düzenle`}
                        </Text>
                      </View>

                      {/* Tür — kilitli */}
                      <Text style={styles.label}>{t("assets.assetType")}</Text>
                      <View style={{ flexDirection: "row", alignItems: "center", gap: 10, backgroundColor: gt.color + "18", borderRadius: 12, paddingHorizontal: 14, paddingVertical: 11, marginBottom: 14 }}>
                        <View style={{ width: 32, height: 32, borderRadius: 10, backgroundColor: gt.color + "28", alignItems: "center", justifyContent: "center" }}>
                          <Feather name={gt.icon} size={16} color={gt.color} />
                        </View>
                        <Text style={{ fontSize: 15, fontWeight: "700", color: gt.color, flex: 1 }}>{gt.label}</Text>
                        <View style={{ flexDirection: "row", alignItems: "center", gap: 4, backgroundColor: gt.color + "25", paddingHorizontal: 8, paddingVertical: 4, borderRadius: 8 }}>
                          <Feather name="lock" size={11} color={gt.color} />
                          <Text style={{ fontSize: 11, fontWeight: "600", color: gt.color }}>Kilitli</Text>
                        </View>
                      </View>

                      {/* Endeks Adı — sadece borsa için */}
                      {assetType === "borsa" && (
                        <>
                          <Text style={styles.label}>Endeks Adı</Text>
                          <SearchPicker
                            value={selectedStockIndex ? (() => { const idx = STOCK_INDICES.find((i) => i.id === selectedStockIndex); return idx ? `${idx.flag} ${idx.label}` : ""; })() : ""}
                            onSelect={(v) => {
                              const found = STOCK_INDICES.find((i) => `${i.flag} ${i.label}` === v);
                              setSelectedStockIndex(found ? found.id : "");
                              setAssetName("");
                            }}
                            options={STOCK_INDICES.map((i) => ({ label: `${i.flag} ${i.label}`, sublabel: i.country }))}
                            placeholder="Endeks seç (Örn. BIST 100)"
                            modalTitle="Endeks Seç"
                            emptyText="Endeks bulunamadı"
                            allowCustom={false}
                          />
                        </>
                      )}

                      {/* Varlık Adı */}
                      <Text style={styles.label}>{t("assets.assetName")}</Text>
                      {assetType === "borsa" ? (
                        <SearchPicker value={assetName} onSelect={(v) => { setAssetName(v); triggerPriceFetch("borsa", v); }} options={stockOptions.map((s) => ({ label: `${s.ticker} – ${s.name}`, sublabel: s.name }))} placeholder={t("assets.picker.borsaPlaceholder")} modalTitle={t("assets.picker.borsaTitle")} emptyText={t("assets.picker.borsaEmpty")} allowCustom />
                      ) : assetType === "kripto" ? (
                        <SearchPicker value={assetName} onSelect={(v) => { setAssetName(v); triggerPriceFetch("kripto", v); }} options={CRYPTO_LIST.map((c) => ({ label: `${c.name} (${c.symbol})`, sublabel: c.symbol }))} placeholder={t("assets.picker.kriptoPlaceholder")} modalTitle={t("assets.picker.kriptoTitle")} emptyText={t("assets.picker.kriptoEmpty")} allowCustom />
                      ) : assetType === "doviz" ? (
                        <SearchPicker value={assetName} onSelect={(v) => { setAssetName(v); triggerPriceFetch("doviz", v); }} options={FOREX_LIST.map((f) => ({ label: getForexDisplayName(`${f.code} – ${f.name}`), sublabel: f.code }))} placeholder={t("assets.picker.dovizPlaceholder")} modalTitle={t("assets.picker.dovizTitle")} emptyText={t("assets.picker.dovizEmpty")} allowCustom={false} />
                      ) : assetType === "altin" ? (
                        <SearchPicker value={assetName} onSelect={(v) => { setAssetName(v); triggerPriceFetch("altin", v); }} options={GOLD_LIST.map((g) => ({ label: g.label }))} placeholder={t("assets.picker.altinPlaceholder")} modalTitle={t("assets.picker.altinTitle")} emptyText="" allowCustom={false} />
                      ) : (
                        <TextInput style={[styles.input, { marginBottom: 12 }]} value={assetName} onChangeText={setAssetName} placeholder={assetType === "vadeli" ? t("assets.picker.vadeliBankPlaceholder") : t("assets.picker.vadesizBankPlaceholder")} placeholderTextColor={colors.mutedForeground} />
                      )}

                      {/* Platform */}
                      <Text style={styles.label}>{assetType === "kripto" ? t("assets.platform.kripto") : assetType === "borsa" ? t("assets.platform.borsa") : t("assets.platform.default")}</Text>
                      <SearchPicker value={assetPlatform} onSelect={setAssetPlatform} options={(PLATFORM_OPTIONS[assetType] ?? []).map((p) => ({ label: p }))} placeholder={assetType === "kripto" ? t("assets.platform.kriptoPlaceholder") : assetType === "borsa" ? t("assets.platform.borsaPlaceholder") : t("assets.platform.defaultPlaceholder")} modalTitle={assetType === "kripto" ? t("assets.platform.kriptoTitle") : assetType === "borsa" ? t("assets.platform.borsaTitle") : t("assets.platform.defaultTitle")} allowCustom />

                      {/* Fiyat alanları (borsa/kripto/döviz/altın) */}
                      {isPriceType ? (
                        <>
                          <Text style={styles.label}>{t("assets.unitPriceLabel")}{assetType === "doviz" ? t("assets.unitPriceSuffix.doviz") : assetType === "altin" ? t("assets.unitPriceSuffix.altin") : assetType === "borsa" ? t("assets.unitPriceSuffix.borsa") : t("assets.unitPriceSuffix.default")}</Text>
                          <View style={{ flexDirection: "row", alignItems: "center", gap: 8, marginBottom: 12 }}>
                            <TextInput style={[styles.input, { flex: 1, marginBottom: 0 }]} value={assetUnitPrice} onChangeText={setAssetUnitPrice} keyboardType="decimal-pad" placeholder={priceFetching ? t("assets.priceFetching") : t("assets.pricePlaceholder")} placeholderTextColor={priceFetching ? colors.primary : colors.mutedForeground} editable={!priceFetching} />
                            <TouchableOpacity style={{ backgroundColor: colors.muted, borderRadius: 10, padding: 10, opacity: priceFetching || !assetName ? 0.4 : 1 }} onPress={() => triggerPriceFetch(assetType, assetName)} disabled={priceFetching || !assetName}>
                              <Feather name={priceFetching ? "loader" : "refresh-cw"} size={16} color={colors.foreground} />
                            </TouchableOpacity>
                          </View>
                          {!!priceFetchErr && <Text style={{ fontSize: 12, color: colors.expense, marginTop: -8, marginBottom: 10 }}>{priceFetchErr}</Text>}
                          <Text style={styles.label}>{t("assets.quantityLabel")}{assetType === "doviz" ? t("assets.quantitySuffix.doviz") : assetType === "altin" ? t("assets.quantitySuffix.altin") : assetType === "borsa" ? t("assets.quantitySuffix.borsa") : t("assets.quantitySuffix.default")}</Text>
                          <TextInput style={styles.input} value={assetQuantity} onChangeText={setAssetQuantity} keyboardType="decimal-pad" placeholder={t("assets.quantityPlaceholder")} placeholderTextColor={colors.mutedForeground} />
                          {calcTotal !== null && (
                            <View style={{ backgroundColor: colors.muted, borderRadius: 12, padding: 14, marginTop: 4, flexDirection: "row", justifyContent: "space-between", alignItems: "center" }}>
                              <Text style={{ fontSize: 13, color: colors.mutedForeground }}>{t("assets.assetValue")}</Text>
                              <Text style={{ fontSize: 17, fontWeight: "700", color: "#00C896" }}>{formatAmount(calcTotal)}</Text>
                            </View>
                          )}
                        </>
                      ) : (
                        <>
                          <Text style={styles.label}>{t("assets.assetValueTRY")}</Text>
                          <TextInput style={styles.input} value={assetAmount} onChangeText={setAssetAmount} keyboardType="decimal-pad" placeholder={t("assets.amountPlaceholder")} placeholderTextColor={colors.mutedForeground} />
                        </>
                      )}

                      {/* Vadeli özel alanlar */}
                      {assetType === "vadeli" && (
                        <View style={{ flexDirection: "row", gap: 10 }}>
                          <View style={{ flex: 1 }}>
                            <Text style={styles.label}>Faiz Oranı (%/yıl)</Text>
                            <TextInput style={styles.input} value={assetInterestRate} onChangeText={setAssetInterestRate} keyboardType="decimal-pad" placeholder="Örn: 65.5" placeholderTextColor={colors.mutedForeground} />
                          </View>
                          <View style={{ flex: 1 }}>
                            <Text style={styles.label}>Vade Tarihi</Text>
                            <TextInput style={styles.input} value={assetMaturityDate} onChangeText={setAssetMaturityDate} placeholder="GG.AA.YYYY" placeholderTextColor={colors.mutedForeground}
                              onBlur={() => {
                                const raw = assetMaturityDate.trim();
                                if (/^\d{2}\.\d{2}\.\d{4}$/.test(raw)) {
                                  const [d, m, y] = raw.split(".");
                                  setAssetMaturityDate(`${y}-${m}-${d}`);
                                }
                              }}
                            />
                          </View>
                        </View>
                      )}

                      {/* Not */}
                      <Text style={styles.label}>{t("assets.noteLabel")}</Text>
                      <TextInput style={styles.input} value={assetNote} onChangeText={setAssetNote} placeholder={t("assets.notePlaceholder")} placeholderTextColor={colors.mutedForeground} />

                      {/* Kaydet / İptal */}
                      <View style={{ flexDirection: "row", gap: 10, marginTop: 8 }}>
                        <TouchableOpacity
                          style={{ flex: 1, paddingVertical: 14, borderRadius: 14, alignItems: "center", backgroundColor: colors.muted }}
                          onPress={() => setDetailFormMode("none")}
                        >
                          <Text style={{ fontSize: 15, fontWeight: "700", color: colors.foreground }}>İptal</Text>
                        </TouchableOpacity>
                        <TouchableOpacity
                          style={{ flex: 2, paddingVertical: 14, borderRadius: 14, alignItems: "center", backgroundColor: gt.color }}
                          onPress={submitDetailAsset}
                        >
                          <Text style={{ fontSize: 15, fontWeight: "700", color: "#FFF" }}>Kaydet</Text>
                        </TouchableOpacity>
                      </View>

                      {/* Sil (sadece düzenleme modunda) */}
                      {detailFormMode === "edit" && currentEditEntry && (
                        <TouchableOpacity
                          style={{ marginTop: 10, paddingVertical: 13, borderRadius: 14, alignItems: "center", backgroundColor: colors.expense + "15" }}
                          onPress={() => handleDeleteDetail(currentEditEntry)}
                        >
                          <Text style={{ fontSize: 15, fontWeight: "700", color: colors.expense }}>{t("assets.deleteAsset")}</Text>
                        </TouchableOpacity>
                      )}
                    </>
                  )}

                </ScrollView>
              </KeyboardAvoidingView>
            </View>
          </Modal>
        );
      })()}

      {/* Asset Ekle / Düzenle Modal */}
      <Modal
        visible={assetModalOpen}
        transparent
        animationType="slide"
        onRequestClose={() => setAssetModalOpen(false)}
      >
        <KeyboardAvoidingView
          behavior={Platform.OS === "ios" ? "padding" : undefined}
          style={{ flex: 1 }}
        >
          <Pressable
            style={[styles.backdrop, { justifyContent: "flex-end", padding: 0 }]}
            onPress={() => setAssetModalOpen(false)}
          >
            <Pressable
              style={[styles.modalCard, {
                borderTopLeftRadius: 24,
                borderTopRightRadius: 24,
                borderBottomLeftRadius: 0,
                borderBottomRightRadius: 0,
                paddingBottom: bottomInset + 12,
              }]}
              onPress={() => {}}
            >
              <View style={{
                width: 40, height: 4, borderRadius: 2,
                backgroundColor: colors.border,
                alignSelf: "center", marginBottom: 12,
              }} />
              <ScrollView showsVerticalScrollIndicator={false} keyboardShouldPersistTaps="handled">
                <Text style={styles.modalTitle}>
                  {assetEditId ? t("assets.editAsset") : t("assets.newAsset")}
                </Text>

                {/* Tür seçici */}
                <Text style={styles.label}>{t("assets.assetType")}</Text>
                {lockedAssetType ? (() => {
                  const lockedCfg = ASSET_TYPES.find((at) => at.key === lockedAssetType)!;
                  return (
                    <View style={{ flexDirection: "row", alignItems: "center", gap: 10, backgroundColor: lockedCfg.color + "18", borderRadius: 12, paddingHorizontal: 14, paddingVertical: 11, marginBottom: 12 }}>
                      <View style={{ width: 32, height: 32, borderRadius: 10, backgroundColor: lockedCfg.color + "28", alignItems: "center", justifyContent: "center" }}>
                        <Feather name={lockedCfg.icon} size={16} color={lockedCfg.color} />
                      </View>
                      <Text style={{ fontSize: 15, fontWeight: "700", color: lockedCfg.color, flex: 1 }}>{lockedCfg.label}</Text>
                      <View style={{ flexDirection: "row", alignItems: "center", gap: 4, backgroundColor: lockedCfg.color + "25", paddingHorizontal: 8, paddingVertical: 4, borderRadius: 8 }}>
                        <Feather name="lock" size={11} color={lockedCfg.color} />
                        <Text style={{ fontSize: 11, fontWeight: "600", color: lockedCfg.color }}>Kilitli</Text>
                      </View>
                    </View>
                  );
                })() : (
                  <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 8 }}>
                    {ASSET_TYPES.map((at) => {
                      const active = assetType === at.key;
                      return (
                        <TouchableOpacity
                          key={at.key}
                          onPress={() => {
                            Haptics.selectionAsync();
                            if (at.key !== assetType) {
                              setAssetType(at.key);
                              setAssetName("");
                              setAssetUnitPrice("");
                              setPriceFetchErr(null);
                              setSelectedStockIndex("");
                            }
                          }}
                          style={[
                            styles.typeChip,
                            active && { backgroundColor: at.color, borderColor: at.color },
                          ]}
                        >
                          <Feather name={at.icon} size={13} color={active ? "#FFF" : colors.foreground} />
                          <Text style={[styles.typeChipText, active && { color: "#FFF", fontWeight: "700" }]}>
                            {at.label}
                          </Text>
                        </TouchableOpacity>
                      );
                    })}
                  </View>
                )}

                {/* Endeks Adı — sadece borsa için */}
                {assetType === "borsa" && (
                  <>
                    <Text style={styles.label}>Endeks Adı</Text>
                    <SearchPicker
                      value={selectedStockIndex ? (() => { const idx = STOCK_INDICES.find((i) => i.id === selectedStockIndex); return idx ? `${idx.flag} ${idx.label}` : ""; })() : ""}
                      onSelect={(v) => {
                        const found = STOCK_INDICES.find((i) => `${i.flag} ${i.label}` === v);
                        setSelectedStockIndex(found ? found.id : "");
                        setAssetName("");
                      }}
                      options={STOCK_INDICES.map((i) => ({ label: `${i.flag} ${i.label}`, sublabel: i.country }))}
                      placeholder="Endeks seç (Örn. BIST 100)"
                      modalTitle="Endeks Seç"
                      emptyText="Endeks bulunamadı"
                      allowCustom={false}
                    />
                  </>
                )}

                {/* Varlık Adı */}
                <Text style={styles.label}>{t("assets.assetName")}</Text>
                {assetType === "borsa" ? (
                  <SearchPicker
                    value={assetName}
                    onSelect={(v) => { setAssetName(v); triggerPriceFetch("borsa", v); }}
                    options={stockOptions.map((s) => ({ label: `${s.ticker} – ${s.name}`, sublabel: s.name }))}
                    placeholder={t("assets.picker.borsaPlaceholder")}
                    modalTitle={t("assets.picker.borsaTitle")}
                    emptyText={t("assets.picker.borsaEmpty")}
                    allowCustom
                  />
                ) : assetType === "kripto" ? (
                  <SearchPicker
                    value={assetName}
                    onSelect={(v) => { setAssetName(v); triggerPriceFetch("kripto", v); }}
                    options={CRYPTO_LIST.map((c) => ({ label: `${c.name} (${c.symbol})`, sublabel: c.symbol }))}
                    placeholder={t("assets.picker.kriptoPlaceholder")}
                    modalTitle={t("assets.picker.kriptoTitle")}
                    emptyText={t("assets.picker.kriptoEmpty")}
                    allowCustom
                  />
                ) : assetType === "doviz" ? (
                  <SearchPicker
                    value={assetName}
                    onSelect={(v) => { setAssetName(v); triggerPriceFetch("doviz", v); }}
                    options={FOREX_LIST.map((f) => ({ label: getForexDisplayName(`${f.code} – ${f.name}`), sublabel: f.code }))}
                    placeholder={t("assets.picker.dovizPlaceholder")}
                    modalTitle={t("assets.picker.dovizTitle")}
                    emptyText={t("assets.picker.dovizEmpty")}
                    allowCustom={false}
                  />
                ) : assetType === "altin" ? (
                  <SearchPicker
                    value={assetName}
                    onSelect={(v) => { setAssetName(v); triggerPriceFetch("altin", v); }}
                    options={GOLD_LIST.map((g) => ({ label: g.label }))}
                    placeholder={t("assets.picker.altinPlaceholder")}
                    modalTitle={t("assets.picker.altinTitle")}
                    emptyText=""
                    allowCustom={false}
                  />
                ) : (
                  <TextInput
                    style={[styles.input, { marginBottom: 12 }]}
                    value={assetName}
                    onChangeText={setAssetName}
                    placeholder={
                      assetType === "vadeli" ? t("assets.picker.vadeliBankPlaceholder") :
                      t("assets.picker.vadesizBankPlaceholder")
                    }
                    placeholderTextColor={colors.mutedForeground}
                  />
                )}

                {/* Platform / Kurum */}
                <Text style={styles.label}>
                  {assetType === "kripto" ? t("assets.platform.kripto") :
                   assetType === "borsa"  ? t("assets.platform.borsa") :
                   t("assets.platform.default")}
                </Text>
                <SearchPicker
                  value={assetPlatform}
                  onSelect={setAssetPlatform}
                  options={(PLATFORM_OPTIONS[assetType] ?? []).map((p) => ({ label: p }))}
                  placeholder={
                    assetType === "kripto" ? t("assets.platform.kriptoPlaceholder") :
                    assetType === "borsa"  ? t("assets.platform.borsaPlaceholder") :
                    t("assets.platform.defaultPlaceholder")
                  }
                  modalTitle={
                    assetType === "kripto" ? t("assets.platform.kriptoTitle") :
                    assetType === "borsa"  ? t("assets.platform.borsaTitle") :
                    t("assets.platform.defaultTitle")
                  }
                  allowCustom
                />

                {isPriceType ? (
                  <>
                    <Text style={styles.label}>
                      {t("assets.unitPriceLabel")}
                      {assetType === "doviz" ? t("assets.unitPriceSuffix.doviz") :
                       assetType === "altin" ? t("assets.unitPriceSuffix.altin") :
                       assetType === "borsa" ? t("assets.unitPriceSuffix.borsa") :
                       t("assets.unitPriceSuffix.default")}
                    </Text>
                    <View style={{ flexDirection: "row", alignItems: "center", gap: 8, marginBottom: 12 }}>
                      <TextInput
                        style={[styles.input, { flex: 1, marginBottom: 0 }]}
                        value={assetUnitPrice}
                        onChangeText={setAssetUnitPrice}
                        keyboardType="decimal-pad"
                        placeholder={priceFetching ? t("assets.priceFetching") : t("assets.pricePlaceholder")}
                        placeholderTextColor={priceFetching ? colors.primary : colors.mutedForeground}
                        editable={!priceFetching}
                      />
                      <TouchableOpacity
                        style={{
                          backgroundColor: colors.muted,
                          borderRadius: 10,
                          padding: 10,
                          opacity: priceFetching || !assetName ? 0.4 : 1,
                        }}
                        onPress={() => triggerPriceFetch(assetType, assetName)}
                        disabled={priceFetching || !assetName}
                      >
                        <Feather
                          name={priceFetching ? "loader" : "refresh-cw"}
                          size={16}
                          color={colors.foreground}
                        />
                      </TouchableOpacity>
                    </View>
                    {!!priceFetchErr && (
                      <Text style={{ fontSize: 12, color: colors.expense, marginTop: -8, marginBottom: 10 }}>
                        {priceFetchErr}
                      </Text>
                    )}

                    <Text style={styles.label}>
                      {t("assets.quantityLabel")}
                      {assetType === "doviz" ? t("assets.quantitySuffix.doviz") :
                       assetType === "altin" ? t("assets.quantitySuffix.altin") :
                       assetType === "borsa" ? t("assets.quantitySuffix.borsa") :
                       t("assets.quantitySuffix.default")}
                    </Text>
                    <TextInput
                      style={styles.input}
                      value={assetQuantity}
                      onChangeText={setAssetQuantity}
                      keyboardType="decimal-pad"
                      placeholder={t("assets.quantityPlaceholder")}
                      placeholderTextColor={colors.mutedForeground}
                    />

                    {calcTotal !== null && (
                      <View style={{
                        backgroundColor: colors.muted,
                        borderRadius: 12,
                        padding: 14,
                        marginTop: 12,
                        flexDirection: "row",
                        justifyContent: "space-between",
                        alignItems: "center",
                      }}>
                        <Text style={{ fontSize: 13, color: colors.mutedForeground }}>{t("assets.assetValue")}</Text>
                        <Text style={{ fontSize: 17, fontWeight: "700", color: "#00C896" }}>
                          {formatAmount(calcTotal)}
                        </Text>
                      </View>
                    )}
                  </>
                ) : (
                  <>
                    <Text style={styles.label}>{t("assets.assetValueTRY")}</Text>
                    <TextInput
                      style={styles.input}
                      value={assetAmount}
                      onChangeText={setAssetAmount}
                      keyboardType="decimal-pad"
                      placeholder={t("assets.amountPlaceholder")}
                      placeholderTextColor={colors.mutedForeground}
                    />
                  </>
                )}

                {/* Vadeli mevduat: faiz oranı ve vade tarihi */}
                {assetType === "vadeli" && (
                  <>
                    <View style={{ flexDirection: "row", gap: 10 }}>
                      <View style={{ flex: 1 }}>
                        <Text style={styles.label}>Faiz Oranı (%/yıl)</Text>
                        <TextInput
                          style={styles.input}
                          value={assetInterestRate}
                          onChangeText={setAssetInterestRate}
                          keyboardType="decimal-pad"
                          placeholder="Örn: 65.5"
                          placeholderTextColor={colors.mutedForeground}
                        />
                      </View>
                      <View style={{ flex: 1 }}>
                        <Text style={styles.label}>Vade Tarihi</Text>
                        <TextInput
                          style={styles.input}
                          value={assetMaturityDate}
                          onChangeText={setAssetMaturityDate}
                          placeholder="GG.AA.YYYY"
                          placeholderTextColor={colors.mutedForeground}
                          onBlur={() => {
                            const raw = assetMaturityDate.trim();
                            if (/^\d{2}\.\d{2}\.\d{4}$/.test(raw)) {
                              const [d, m, y] = raw.split(".");
                              setAssetMaturityDate(`${y}-${m}-${d}`);
                            }
                          }}
                        />
                      </View>
                    </View>
                  </>
                )}

                <Text style={styles.label}>{t("assets.noteLabel")}</Text>
                <TextInput
                  style={styles.input}
                  value={assetNote}
                  onChangeText={setAssetNote}
                  placeholder={t("assets.notePlaceholder")}
                  placeholderTextColor={colors.mutedForeground}
                />

                <View style={styles.actions}>
                  <TouchableOpacity style={styles.cancelBtn} onPress={() => setAssetModalOpen(false)}>
                    <Text style={styles.cancelBtnText}>{t("assets.cancel")}</Text>
                  </TouchableOpacity>
                  <TouchableOpacity style={styles.saveBtn} onPress={submitAsset}>
                    <Text style={styles.saveBtnText}>{assetEditId ? t("assets.update") : t("assets.save")}</Text>
                  </TouchableOpacity>
                </View>
                {assetEditId !== null && (
                  <TouchableOpacity
                    style={{
                      marginTop: 10,
                      paddingVertical: 13,
                      borderRadius: colors.radius,
                      alignItems: "center",
                      backgroundColor: colors.expense + "15",
                    }}
                    onPress={() => {
                      const entry = assetEntries.find(e => e.id === assetEditId);
                      if (entry) {
                        setAssetModalOpen(false);
                        setTimeout(() => handleDeleteAsset(entry), 150);
                      }
                    }}
                  >
                    <Text style={{ fontSize: 15, fontWeight: "700", color: colors.expense }}>
                      {t("assets.deleteAsset")}
                    </Text>
                  </TouchableOpacity>
                )}
                <View style={{ height: 8 }} />
              </ScrollView>
            </Pressable>
          </Pressable>
        </KeyboardAvoidingView>
      </Modal>
    </View>
  );
}
