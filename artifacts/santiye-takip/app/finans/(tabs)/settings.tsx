import { Feather } from "@expo/vector-icons";
import AsyncStorage from "@react-native-async-storage/async-storage";
import * as Haptics from "expo-haptics";
import { useRouter } from "expo-router";
import React, { useEffect, useState } from "react";
import { useTranslation } from "react-i18next";
import {
  Alert,
  KeyboardAvoidingView,
  Modal,
  Platform,
  ScrollView,
  StyleSheet,
  Switch,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import MembershipCard from "@/components/finans/MembershipCard";
import CategoryManagerModal from "@/components/finans/CategoryManagerModal";
import NotificationSettingsSheet from "@/components/finans/NotificationSettingsSheet";
import PinSetupModal from "@/components/finans/PinSetupModal";
import i18n, { SUPPORTED_LANGUAGES } from "@/i18n-finans";
import { useBudget } from "@/context/finans/BudgetContext";
import { useCurrency, CURRENCY_SYMBOLS } from "@/context/finans/CurrencyContext";
import { usePin } from "@/context/finans/PinContext";
import { ThemeMode, useTheme, ResolvedScheme } from "@/context/finans/ThemeContext";
import { useVoiceAssistant } from "@/context/finans/VoiceAssistantContext";
import { useColors } from "@/hooks/finans/useColors";
import { FOREX_LIST } from "@/utils/finans/assets-data";
import {
  getOrCreateBackupKey,
  getLastSavedAt,
  saveToCloud,
  restoreFromCloud,
  setBackupKey,
} from "@/utils/finans/cloudBackup";
import { exportJSON, pickJSON } from "@/utils/finans/dataIO";
import { exportAsExcel } from "@/utils/finans/excelExport";
import {
  hasNotificationPermission,
  requestNotificationPermission,
} from "@/utils/finans/notifications";
import { exportAsPdf } from "@/utils/finans/pdfExport";

export default function SettingsScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const { t, i18n: i18nHook } = useTranslation();
  const { mode, setMode } = useTheme();
  const {
    transactions,
    debts,
    bankLimits,
    assetEntries,
    exportData,
    importData,
    clearAllData,
    reminderSettings,
    updateReminderSettings,
  } = useBudget();
  const { pin, setPin, removePin } = usePin();
  const { enabled: voiceEnabled, setEnabled: setVoiceEnabled } = useVoiceAssistant();
  const [notifPermGranted, setNotifPermGranted] = useState<boolean>(false);
  const [busy, setBusy] = useState(false);
  const [hasExported, setHasExported] = useState(false);
  const [justSaved, setJustSaved] = useState(false);
  const [categoryModalVisible, setCategoryModalVisible] = useState(false);
  const [pinModal, setPinModal] = useState<{ visible: boolean; mode: "set" | "change" | "remove" }>({
    visible: false,
    mode: "set",
  });

  // Cloud backup
  const [cloudKey, setCloudKey] = useState<string>("");
  const [cloudLastSaved, setCloudLastSaved] = useState<string | null>(null);
  const [cloudBusy, setCloudBusy] = useState(false);
  const [restoreModal, setRestoreModal] = useState(false);
  const [restoreInput, setRestoreInput] = useState("");
  const [notifSheetOpen, setNotifSheetOpen] = useState(false);
  const [langModalVisible, setLangModalVisible] = useState(false);
  const [currentLang, setCurrentLang] = useState(i18n.language || "tr");

  const { displayCurrency, rates, isLoading: ratesLoading, lastUpdated: ratesUpdated, setCurrency, refreshRates } = useCurrency();
  type CurrencyPickerTarget = "display" | "convFrom" | "convTo";
  const [currencyPickerTarget, setCurrencyPickerTarget] = useState<CurrencyPickerTarget | null>(null);
  const [currencySearch, setCurrencySearch] = useState("");
  const [ratesExpanded, setRatesExpanded] = useState(false);
  const [convFrom, setConvFrom] = useState("USD");
  const [convTo, setConvTo] = useState("TRY");
  const [convAmount, setConvAmount] = useState("100");

  type SectionKey = "yedekleme" | "kategoriler" | "guvenlik" | "hatirlaticilar" | "bulut" | "tema" | "doviz";
  const DEFAULT_SECTION_ORDER: SectionKey[] = [
    "doviz", "yedekleme", "kategoriler", "guvenlik", "hatirlaticilar", "bulut", "tema",
  ];
  const [sectionOrder, setSectionOrder] = useState<SectionKey[]>(DEFAULT_SECTION_ORDER);
  const [reorderMode, setReorderMode] = useState(false);

  useEffect(() => {
    getOrCreateBackupKey().then(setCloudKey);
    getLastSavedAt().then(setCloudLastSaved);
    hasNotificationPermission().then(setNotifPermGranted);
    AsyncStorage.getItem("settings_section_order").then((val) => {
      if (!val) return;
      try {
        const parsed = JSON.parse(val) as SectionKey[];
        if (parsed.length === DEFAULT_SECTION_ORDER.length && parsed.every((k) => DEFAULT_SECTION_ORDER.includes(k))) {
          setSectionOrder(parsed);
        }
      } catch {}
    });
    AsyncStorage.getItem("app_language").then((saved) => {
      if (saved && saved !== i18n.language) {
        i18n.changeLanguage(saved);
        setCurrentLang(saved);
      }
    });
  }, []);

  const handleLanguageChange = async (code: string) => {
    Haptics.selectionAsync();
    await i18n.changeLanguage(code);
    await AsyncStorage.setItem("app_language", code);
    setCurrentLang(code);
    setLangModalVisible(false);
  };

  const moveSection = (key: SectionKey, dir: "up" | "down") => {
    Haptics.selectionAsync();
    setSectionOrder((prev) => {
      const idx = prev.indexOf(key);
      const next = dir === "up" ? idx - 1 : idx + 1;
      if (next < 0 || next >= prev.length) return prev;
      const arr = [...prev];
      [arr[idx], arr[next]] = [arr[next], arr[idx]];
      AsyncStorage.setItem("settings_section_order", JSON.stringify(arr));
      return arr;
    });
  };

  const enterReorderMode = () => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    setReorderMode(true);
  };

  const handleReminderToggle = async (next: boolean) => {
    Haptics.selectionAsync();
    if (next) {
      const granted = await requestNotificationPermission();
      setNotifPermGranted(granted);
      if (!granted) {
        Alert.alert(
          t("settings.security.permissionRequired"),
          t("settings.security.notifPermMsg"),
        );
        return;
      }
      setNotifSheetOpen(true);
    } else {
      updateReminderSettings({ enabled: false });
    }
  };

  const handleSaveToApp = () => {
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    setJustSaved(true);
    setTimeout(() => setJustSaved(false), 2000);
  };

  const topInset = Platform.OS === "web" ? 67 : insets.top;
  const bottomInset = Platform.OS === "web" ? 34 : insets.bottom;

  const handleExport = async () => {
    if (busy) return;
    try {
      setBusy(true);
      Haptics.selectionAsync();
      const json = exportData();
      await exportJSON(json);
      setHasExported(true);
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      const okMsg = t("settings.backup.savedMsg");
      if (Platform.OS === "web") {
        window.alert(okMsg);
      } else {
        Alert.alert(t("settings.backup.saved"), okMsg);
      }
    } catch (e: any) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
      const msg = e?.message ?? t("common.unknownError");
      if (Platform.OS === "web") {
        window.alert(t("settings.backup.exportFailed", { msg }));
      } else {
        Alert.alert(t("common.error"), t("settings.backup.exportFailed", { msg }));
      }
    } finally {
      setBusy(false);
    }
  };

  const runReport = async (format: "pdf" | "excel") => {
    if (busy) return;
    try {
      setBusy(true);
      Haptics.selectionAsync();
      if (format === "pdf") {
        await exportAsPdf(transactions, debts, bankLimits, assetEntries);
      } else {
        await exportAsExcel(transactions, debts, bankLimits);
      }
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    } catch (e: any) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
      const msg = e?.message ?? t("common.unknownError");
      const label = format === "pdf" ? "PDF" : "Excel";
      if (Platform.OS === "web") {
        window.alert(t("settings.backup.reportFailed", { label, msg }));
      } else {
        Alert.alert(t("common.error"), t("settings.backup.reportFailed", { label, msg }));
      }
    } finally {
      setBusy(false);
    }
  };

  const handleGenerateReport = () => {
    if (busy) return;
    Haptics.selectionAsync();
    if (Platform.OS === "web") {
      const choice = window.prompt(
        t("settings.backup.reportFormat") + "\n\n1 = PDF\n2 = Excel",
        "1"
      );
      if (choice === "1") runReport("pdf");
      else if (choice === "2") runReport("excel");
      return;
    }
    Alert.alert(
      t("settings.backup.budgetReport"),
      t("settings.backup.reportFormat"),
      [
        { text: "PDF", onPress: () => runReport("pdf") },
        { text: "Excel", onPress: () => runReport("excel") },
        { text: t("common.cancel"), style: "cancel" },
      ],
      { cancelable: true }
    );
  };

  const runImport = async (importMode: "replace" | "merge") => {
    try {
      const json = await pickJSON();
      if (!json) return;
      const { txCount, debtCount } = importData(json, importMode);
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      const mode = importMode === "replace" ? t("settings.backup.importModeLoaded") : t("settings.backup.importModeMerged");
      const msg = t("settings.backup.importMsg", { txCount, debtCount, mode });
      if (Platform.OS === "web") {
        window.alert(msg);
      } else {
        Alert.alert(t("settings.backup.importComplete"), msg);
      }
    } catch (e: any) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
      const msg = e?.message ?? t("common.invalidFile");
      if (Platform.OS === "web") {
        window.alert(t("settings.backup.importFailed", { msg }));
      } else {
        Alert.alert(t("common.error"), t("settings.backup.importFailed", { msg }));
      }
    }
  };

  const handleImport = () => {
    if (busy) return;
    Haptics.selectionAsync();
    const hasExisting = transactions.length > 0 || debts.length > 0;
    if (!hasExisting) {
      runImport("replace");
      return;
    }
    if (Platform.OS === "web") {
      const replace = window.confirm(t("settings.backup.webImportHint"));
      runImport(replace ? "replace" : "merge");
      return;
    }
    Alert.alert(
      t("settings.backup.importTitle"),
      t("settings.backup.importPrompt"),
      [
        { text: t("common.cancel"), style: "cancel" },
        { text: t("settings.backup.merge"), onPress: () => runImport("merge") },
        {
          text: t("settings.backup.overwrite"),
          style: "destructive",
          onPress: () => runImport("replace"),
        },
      ]
    );
  };

  const performClear = () => {
    clearAllData();
    setHasExported(false);
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    const msg = t("settings.backup.deletedMsg");
    if (Platform.OS === "web") {
      window.alert(msg);
    } else {
      Alert.alert(t("common.deleted"), msg);
    }
  };

  const handleDeleteAll = () => {
    if (busy) return;
    Haptics.selectionAsync();
    const hasData = transactions.length > 0 || debts.length > 0;
    if (!hasData) {
      const msg = t("settings.backup.noData");
      if (Platform.OS === "web") {
        window.alert(msg);
      } else {
        Alert.alert(t("common.info"), msg);
      }
      return;
    }
    if (!hasExported) {
      const warn = t("settings.backup.backupFirstMsg");
      if (Platform.OS === "web") {
        const proceed = window.confirm(warn);
        if (!proceed) return;
        const sure = window.confirm(
          t("settings.backup.deleteMsg") + " " + t("settings.backup.continueQuestion")
        );
        if (sure) performClear();
        return;
      }
      Alert.alert(t("settings.backup.backupFirst"), warn, [
        { text: t("common.cancel"), style: "cancel" },
        {
          text: t("settings.backup.deleteAnyway"),
          style: "destructive",
          onPress: () => {
            Alert.alert(
              t("settings.backup.deleteTitle"),
              t("settings.backup.deleteMsg"),
              [
                { text: t("common.cancel"), style: "cancel" },
                {
                  text: t("settings.backup.confirmDelete"),
                  style: "destructive",
                  onPress: performClear,
                },
              ]
            );
          },
        },
      ]);
      return;
    }
    const confirmMsg = t("settings.backup.deleteMsg") + " " + t("settings.backup.continueQuestion");
    if (Platform.OS === "web") {
      const sure = window.confirm(confirmMsg);
      if (sure) performClear();
      return;
    }
    Alert.alert(t("settings.backup.deleteTitle"), confirmMsg, [
      { text: t("common.cancel"), style: "cancel" },
      { text: t("settings.backup.confirmDelete"), style: "destructive", onPress: performClear },
    ]);
  };

  const handlePinToggle = () => {
    Haptics.selectionAsync();
    if (pin) {
      setPinModal({ visible: true, mode: "remove" });
    } else {
      setPinModal({ visible: true, mode: "set" });
    }
  };

  const handleChangePin = () => {
    Haptics.selectionAsync();
    setPinModal({ visible: true, mode: "change" });
  };

  const handlePinSuccess = async (newPin?: string) => {
    setPinModal((p) => ({ ...p, visible: false }));
    if (pinModal.mode === "remove") {
      await removePin();
    } else if (newPin) {
      await setPin(newPin);
    }
  };

  const handleCloudBackup = async () => {
    if (cloudBusy) return;
    setCloudBusy(true);
    Haptics.selectionAsync();
    try {
      const key = cloudKey || (await getOrCreateBackupKey());
      const raw = exportData();
      const parsed = JSON.parse(raw);
      const result = await saveToCloud(key, parsed);
      setCloudKey(result.key);
      setCloudLastSaved(result.savedAt);
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      const msg = t("settings.cloud.backupSuccessMsg", { key: result.key });
      if (Platform.OS === "web") {
        window.alert(msg);
      } else {
        Alert.alert(t("settings.cloud.backupSuccess"), msg);
      }
    } catch (e: any) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
      const msg = e?.message ?? t("common.unknownError");
      if (Platform.OS === "web") {
        window.alert(t("settings.cloud.backupFailed", { msg }));
      } else {
        Alert.alert(t("common.error"), t("settings.cloud.backupFailed", { msg }));
      }
    } finally {
      setCloudBusy(false);
    }
  };

  const handleCloudRestore = async () => {
    const key = restoreInput.trim().toUpperCase();
    if (!key || key.length < 4) {
      Alert.alert(t("common.error"), t("settings.cloud.invalidCode"));
      return;
    }
    setRestoreModal(false);
    setCloudBusy(true);
    Haptics.selectionAsync();
    try {
      const { data } = await restoreFromCloud(key);
      const json = JSON.stringify(data);
      const hasExisting = transactions.length > 0 || debts.length > 0;

      const doRestore = async (mode: "replace" | "merge") => {
        const { txCount, debtCount } = importData(json, mode);
        await setBackupKey(key);
        setCloudKey(key);
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
        const restoreMode = mode === "replace" ? t("settings.backup.importModeLoaded") : t("settings.backup.importModeMerged");
        Alert.alert(
          t("settings.cloud.restoreSuccess"),
          t("settings.cloud.restoreMsg", { txCount, debtCount, mode: restoreMode })
        );
      };

      if (!hasExisting) {
        await doRestore("replace");
        return;
      }

      Alert.alert(t("settings.cloud.restoreTitle"), t("settings.cloud.restorePrompt"), [
        { text: t("common.cancel"), style: "cancel" },
        { text: t("settings.backup.merge"), onPress: () => doRestore("merge") },
        { text: t("settings.backup.overwrite"), style: "destructive", onPress: () => doRestore("replace") },
      ]);
    } catch (e: any) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
      Alert.alert(t("common.error"), e?.message ?? t("settings.cloud.restoreFailed"));
    } finally {
      setCloudBusy(false);
      setRestoreInput("");
    }
  };

  const handleCloudComingSoon = (provider: string) => {
    Haptics.selectionAsync();
    Alert.alert(
      t("settings.cloud.integration", { provider }),
      t("settings.cloud.comingSoon", { provider }),
      [{ text: t("common.ok") }]
    );
  };

  const handleRegenerateKey = () => {
    Alert.alert(
      t("settings.cloud.regenerateKey"),
      t("settings.cloud.regenerateMsg"),
      [
        { text: t("common.cancel"), style: "cancel" },
        {
          text: t("settings.cloud.newCode"),
          style: "destructive",
          onPress: async () => {
            const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
            const newKey = Array.from({ length: 6 }, () =>
              chars[Math.floor(Math.random() * chars.length)]
            ).join("");
            await setBackupKey(newKey);
            setCloudKey(newKey);
            setCloudLastSaved(null);
          },
        },
      ]
    );
  };

  const themeOptions: { key: ThemeMode; label: string; icon: string }[] = [
    { key: "light", label: t("settings.theme.light"), icon: "sun" },
    { key: "dark", label: t("settings.theme.dark"), icon: "moon" },
    { key: "system", label: t("settings.theme.system"), icon: "smartphone" },
  ];

  type NamedTheme = {
    key: ThemeMode;
    name: string;
    swatches: string[];
    description: string;
  };

  const namedThemes: NamedTheme[] = [
    {
      key: "light",
      name: t("settings.theme.emerald"),
      swatches: ["#0B1E33", "#00C896", "#F5F7FA"],
      description: t("settings.theme.emeraldDesc"),
    },
    {
      key: "safir",
      name: t("settings.theme.sapphire"),
      swatches: ["#0B1E33", "#0099B8", "#FFFFFF"],
      description: t("settings.theme.sapphireDesc"),
    },
    {
      key: "altin",
      name: t("settings.theme.gold"),
      swatches: ["#0C1926", "#D4A017", "#F0E8D0"],
      description: t("settings.theme.goldDesc"),
    },
    {
      key: "grafit",
      name: t("settings.theme.graphite"),
      swatches: ["#0A0D0A", "#00E87A", "#E2E8E4"],
      description: t("settings.theme.graphiteDesc"),
    },
    {
      key: "orman",
      name: t("settings.theme.forest"),
      swatches: ["#0C1E14", "#6EE4A0", "#E4F0E8"],
      description: t("settings.theme.forestDesc"),
    },
    {
      key: "mor",
      name: t("settings.theme.purple"),
      swatches: ["#0C0B1E", "#8B5CF6", "#EAE8FF"],
      description: t("settings.theme.purpleDesc"),
    },
    {
      key: "gunbatimi",
      name: t("settings.theme.sunset"),
      swatches: ["#1A1A2E", "#E07B39", "#FFF8F2"],
      description: t("settings.theme.sunsetDesc"),
    },
    {
      key: "banka",
      name: t("settings.theme.bank"),
      swatches: ["#0A1D3A", "#1855C8", "#EDF4FC"],
      description: t("settings.theme.bankDesc"),
    },
    {
      key: "okyanus",
      name: t("settings.theme.ocean"),
      swatches: ["#030D1C", "#00C4E0", "#B0CCD8"],
      description: t("settings.theme.oceanDesc"),
    },
    {
      key: "platin",
      name: t("settings.theme.platinum"),
      swatches: ["#152032", "#284882", "#F2F5F9"],
      description: t("settings.theme.platinumDesc"),
    },
    {
      key: "borsa",
      name: t("settings.theme.stock"),
      swatches: ["#05090F", "#0088FF", "#A5BFCE"],
      description: t("settings.theme.stockDesc"),
    },
    {
      key: "gumus",
      name: t("settings.theme.silver"),
      swatches: ["#141A22", "#88B0C8", "#C8D2DC"],
      description: t("settings.theme.silverDesc"),
    },
  ];

  const styles = StyleSheet.create({
    container: { flex: 1, backgroundColor: colors.background },
    header: {
      backgroundColor: colors.navy,
      paddingTop: topInset + 16,
      paddingBottom: 28,
      paddingHorizontal: 24,
      borderBottomLeftRadius: 28,
      borderBottomRightRadius: 28,
    },
    headerTitle: {
      fontSize: 22,
      fontWeight: "800" as const,
      color: "#FFFFFF",
    },
    headerSub: {
      fontSize: 13,
      color: "rgba(255,255,255,0.6)",
      marginTop: 4,
    },
    section: { paddingHorizontal: 20, marginTop: 22 },
    sectionTitle: {
      fontSize: 13,
      fontWeight: "700" as const,
      color: colors.mutedForeground,
      letterSpacing: 0.3,
      marginBottom: 10,
      marginLeft: 4,
    },
    card: {
      backgroundColor: colors.card,
      borderRadius: colors.radius,
      padding: 6,
    },
    themeModeRow: {
      flexDirection: "row" as const,
      gap: 4,
    },
    themeModeBtn: {
      flex: 1,
      flexDirection: "row" as const,
      alignItems: "center" as const,
      justifyContent: "center" as const,
      paddingVertical: 8,
      borderRadius: 10,
      gap: 5,
      backgroundColor: colors.muted,
    },
    themeModeBtnActive: { backgroundColor: colors.primary },
    themeModeLabel: {
      fontSize: 12,
      fontWeight: "600" as const,
      color: colors.mutedForeground,
    },
    themeModeLabelActive: { color: "#FFFFFF" },
    themeModeDivider: {
      height: 1,
      backgroundColor: colors.border,
      marginVertical: 12,
      marginHorizontal: -16,
    },
    themeCircleRow: {
      flexDirection: "row" as const,
      gap: 14,
      paddingVertical: 2,
    },
    themeCircleWrap: {
      alignItems: "center" as const,
      gap: 5,
    },
    themeCircle: {
      width: 40,
      height: 40,
      borderRadius: 20,
      overflow: "hidden" as const,
      flexDirection: "row" as const,
      borderWidth: 1.5,
      borderColor: colors.border,
    },
    themeCircleHalf: { flex: 1 },
    themeCircleLabel: {
      fontSize: 10,
      color: colors.mutedForeground,
      fontWeight: "500" as const,
    },
    themeCircleLabelActive: {
      color: colors.primary,
      fontWeight: "700" as const,
    },
    ioBtn: {
      flexDirection: "row",
      alignItems: "center",
      paddingVertical: 16,
      paddingHorizontal: 14,
      gap: 14,
    },
    ioIconBg: {
      width: 38,
      height: 38,
      borderRadius: 10,
      alignItems: "center",
      justifyContent: "center",
      backgroundColor: colors.muted,
    },
    ioBody: { flex: 1 },
    ioTitle: {
      fontSize: 15,
      fontWeight: "600" as const,
      color: colors.foreground,
    },
    ioDesc: {
      fontSize: 12,
      color: colors.mutedForeground,
      marginTop: 2,
    },
    divider: {
      height: 1,
      backgroundColor: colors.border,
      marginLeft: 14,
    },
    statRow: {
      flexDirection: "row",
      justifyContent: "space-between",
      alignItems: "center",
      paddingVertical: 14,
      paddingHorizontal: 14,
    },
    statLabel: { fontSize: 14, color: colors.foreground },
    statValue: {
      fontSize: 14,
      fontWeight: "700" as const,
      color: colors.primary,
    },
    footer: {
      alignItems: "center",
      paddingVertical: 28,
    },
    footerText: {
      fontSize: 12,
      color: colors.mutedForeground,
    },
    // Backup grid boxes
    backupBox: {
      width: "48%" as any,
      backgroundColor: colors.card,
      borderRadius: 16,
      padding: 16,
      gap: 6,
      position: "relative" as const,
      borderWidth: 1,
      borderColor: colors.border,
    },
    backupIconRing: {
      width: 46,
      height: 46,
      borderRadius: 14,
      alignItems: "center" as const,
      justifyContent: "center" as const,
      marginBottom: 4,
    },
    backupLabel: {
      fontSize: 14,
      fontWeight: "700" as const,
      color: colors.foreground,
    },
    backupSub: {
      fontSize: 11,
      color: colors.mutedForeground,
      lineHeight: 15,
    },
    backupBadge: {
      position: "absolute" as const,
      top: 12,
      right: 12,
      width: 20,
      height: 20,
      borderRadius: 10,
      backgroundColor: "#E6FBF4",
      alignItems: "center" as const,
      justifyContent: "center" as const,
    },
    // Cloud 3-column grid
    cloudBox: {
      width: "31%" as any,
      backgroundColor: colors.card,
      borderRadius: 14,
      padding: 11,
      gap: 4,
      position: "relative" as const,
      borderWidth: 1,
      borderColor: colors.border,
    },
    cloudIconRing: {
      width: 38,
      height: 38,
      borderRadius: 11,
      alignItems: "center" as const,
      justifyContent: "center" as const,
      marginBottom: 3,
    },
    cloudLabel: {
      fontSize: 11,
      fontWeight: "700" as const,
      color: colors.foreground,
      lineHeight: 14,
    },
    cloudSub: {
      fontSize: 10,
      color: colors.mutedForeground,
      lineHeight: 13,
    },
    // Cloud backup key
    cloudKeyBox: {
      backgroundColor: colors.navy + "12",
      borderRadius: 14,
      borderWidth: 1,
      borderColor: colors.navy + "30",
      padding: 16,
      marginBottom: 10,
      alignItems: "center",
    },
    cloudKeyLabel: {
      fontSize: 11,
      fontWeight: "700" as const,
      color: colors.mutedForeground,
      letterSpacing: 0.5,
      marginBottom: 8,
    },
    cloudKeyText: {
      fontSize: 28,
      fontWeight: "800" as const,
      color: colors.navy,
      letterSpacing: 6,
      fontVariant: ["tabular-nums"],
    },
    cloudKeyHint: {
      fontSize: 11,
      color: colors.mutedForeground,
      marginTop: 6,
      textAlign: "center",
    },
    cloudKeyRegenBtn: {
      marginTop: 10,
      flexDirection: "row" as const,
      alignItems: "center" as const,
      gap: 4,
    },
    cloudKeyRegenText: {
      fontSize: 12,
      color: colors.mutedForeground,
      textDecorationLine: "underline" as const,
    },
    cloudSoonBadge: {
      position: "absolute" as const,
      top: 10,
      right: 10,
      backgroundColor: colors.muted,
      paddingHorizontal: 6,
      paddingVertical: 2,
      borderRadius: 6,
    },
    cloudSoonBadgeText: {
      fontSize: 8,
      fontWeight: "800" as const,
      color: colors.mutedForeground,
      letterSpacing: 0.5,
    },
    // Restore modal
    modalOverlay: {
      flex: 1,
      backgroundColor: "rgba(0,0,0,0.5)",
      justifyContent: "center" as const,
      alignItems: "center" as const,
      padding: 24,
    },
    modalBox: {
      backgroundColor: colors.card,
      borderRadius: 20,
      padding: 24,
      width: "100%",
    },
    modalTitle: {
      fontSize: 18,
      fontWeight: "800" as const,
      color: colors.foreground,
      marginBottom: 6,
    },
    modalDesc: {
      fontSize: 13,
      color: colors.mutedForeground,
      marginBottom: 16,
    },
    modalInput: {
      backgroundColor: colors.muted,
      borderRadius: 12,
      borderWidth: 1,
      borderColor: colors.border,
      paddingHorizontal: 16,
      paddingVertical: 14,
      fontSize: 22,
      fontWeight: "800" as const,
      letterSpacing: 6,
      color: colors.foreground,
      textAlign: "center" as const,
      marginBottom: 16,
    },
    modalBtnRow: {
      flexDirection: "row" as const,
      gap: 10,
    },
    modalCancelBtn: {
      flex: 1,
      paddingVertical: 14,
      borderRadius: 12,
      backgroundColor: colors.muted,
      alignItems: "center" as const,
    },
    modalCancelText: {
      fontSize: 15,
      fontWeight: "600" as const,
      color: colors.foreground,
    },
    modalConfirmBtn: {
      flex: 1,
      paddingVertical: 14,
      borderRadius: 12,
      backgroundColor: colors.primary,
      alignItems: "center" as const,
    },
    modalConfirmText: {
      fontSize: 15,
      fontWeight: "700" as const,
      color: "#FFFFFF",
    },
    reorderBanner: {
      flexDirection: "row" as const,
      alignItems: "center" as const,
      justifyContent: "center" as const,
      gap: 8,
      marginHorizontal: 20,
      marginTop: 12,
      paddingVertical: 11,
      borderRadius: 12,
      backgroundColor: colors.primary,
    },
    reorderBannerText: {
      fontSize: 14,
      fontWeight: "700" as const,
      color: "#FFFFFF",
    },
    premiumBanner: {
      flexDirection: "row" as const,
      alignItems: "center" as const,
      justifyContent: "space-between" as const,
      marginHorizontal: 20,
      marginTop: 12,
      paddingVertical: 14,
      paddingHorizontal: 16,
      borderRadius: 16,
      backgroundColor: "#F59E0B18",
      borderWidth: 1,
      borderColor: "#F59E0B44",
    },
    premiumBannerLeft: {
      flexDirection: "row" as const,
      alignItems: "center" as const,
      gap: 12,
    },
    premiumBannerIcon: {
      width: 36,
      height: 36,
      borderRadius: 10,
      backgroundColor: "#F59E0B22",
      alignItems: "center" as const,
      justifyContent: "center" as const,
    },
    premiumBannerTitle: {
      fontSize: 14,
      fontWeight: "700" as const,
      color: "#F59E0B",
    },
    premiumBannerSub: {
      fontSize: 11,
      color: colors.mutedForeground,
      marginTop: 1,
    },
    reorderArrow: {
      width: 28,
      height: 28,
      borderRadius: 8,
      backgroundColor: colors.muted,
      alignItems: "center" as const,
      justifyContent: "center" as const,
    },
  });

  const SectionHdr = ({ title, sKey }: { title: string; sKey: SectionKey }) => {
    const idx = sectionOrder.indexOf(sKey);
    const canUp = idx > 0;
    const canDown = idx < sectionOrder.length - 1;
    return (
      <TouchableOpacity
        style={{ flexDirection: "row", alignItems: "center", marginBottom: 10, marginLeft: 4 }}
        onLongPress={enterReorderMode}
        delayLongPress={600}
        activeOpacity={1}
      >
        <Text style={[styles.sectionTitle, { marginBottom: 0, marginLeft: 0, flex: 1 }]}>{title}</Text>
        {reorderMode && (
          <View style={{ flexDirection: "row", gap: 4, alignItems: "center" }}>
            <TouchableOpacity
              style={[styles.reorderArrow, !canUp && { opacity: 0.3 }]}
              onPress={() => canUp && moveSection(sKey, "up")}
            >
              <Feather name="chevron-up" size={15} color={colors.primary} />
            </TouchableOpacity>
            <TouchableOpacity
              style={[styles.reorderArrow, !canDown && { opacity: 0.3 }]}
              onPress={() => canDown && moveSection(sKey, "down")}
            >
              <Feather name="chevron-down" size={15} color={colors.primary} />
            </TouchableOpacity>
            <Feather name="menu" size={14} color={colors.mutedForeground} style={{ marginLeft: 2 }} />
          </View>
        )}
      </TouchableOpacity>
    );
  };

  return (
    <View style={styles.container}>
      <ScrollView
        showsVerticalScrollIndicator={false}
        style={{ flex: 1 }}
        keyboardShouldPersistTaps="handled"
        contentContainerStyle={{ paddingBottom: bottomInset + 100 }}
      >
        <View style={styles.header}>
          <Text style={styles.headerTitle}>{t("settings.title")}</Text>
          <Text style={styles.headerSub}>{t("settings.subtitle")}</Text>
        </View>

        {/* ── Sıra değiştirme bandı ── */}
        {reorderMode && (
          <TouchableOpacity
            style={styles.reorderBanner}
            onPress={() => { Haptics.selectionAsync(); setReorderMode(false); }}
            activeOpacity={0.85}
          >
            <Feather name="check" size={14} color="#FFFFFF" />
            <Text style={styles.reorderBannerText}>{t("settings.sections.reorderSave")}</Text>
          </TouchableOpacity>
        )}

        {/* ── Üyelik Paneli ── */}
        <MembershipCard />

        {/* ── Dil Seçici ── */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>{t("settings.sections.language").toUpperCase()}</Text>
          <View style={styles.card}>
            <TouchableOpacity
              style={styles.ioBtn}
              onPress={() => { Haptics.selectionAsync(); setLangModalVisible(true); }}
              activeOpacity={0.75}
            >
              <View style={[styles.ioIconBg, { backgroundColor: colors.primary + "22" }]}>
                <Text style={{ fontSize: 20 }}>🌐</Text>
              </View>
              <View style={styles.ioBody}>
                <Text style={styles.ioTitle}>
                  {SUPPORTED_LANGUAGES.find((l) => l.code === currentLang)?.nativeLabel ?? "Türkçe"}
                </Text>
                <Text style={styles.ioDesc}>
                  {SUPPORTED_LANGUAGES.find((l) => l.code === currentLang)?.label ?? "Türkçe"} · {t("settings.language.title")}
                </Text>
              </View>
              <Feather name="chevron-right" size={18} color={colors.mutedForeground} />
            </TouchableOpacity>
          </View>
        </View>

        {/* ── Sıralanabilir bölümler ── */}
        {sectionOrder.map((key, mapIdx) => {
          const sectionStyle = mapIdx === 0 ? [styles.section, { marginTop: 20 }] : styles.section;
          switch (key) {
            case "yedekleme": return (
              <View key={key} style={sectionStyle}>
                <SectionHdr title={t("settings.sections.backupSection")} sKey="yedekleme" />
                <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 10 }}>
                  <TouchableOpacity style={[styles.backupBox, busy && { opacity: 0.5 }]} onPress={handleImport} disabled={busy} activeOpacity={0.82}>
                    <View style={[styles.backupIconRing, { backgroundColor: "#EFF6FF" }]}>
                      <Feather name="download" size={22} color="#3B82F6" />
                    </View>
                    <Text style={styles.backupLabel}>{t("settings.backup.importBtn")}</Text>
                    <Text style={styles.backupSub}>{t("settings.backup.fromFile")}</Text>
                  </TouchableOpacity>
                  <TouchableOpacity style={[styles.backupBox, busy && { opacity: 0.5 }]} onPress={handleExport} disabled={busy} activeOpacity={0.82}>
                    <View style={[styles.backupIconRing, { backgroundColor: colors.muted }]}>
                      <Feather name="upload" size={22} color={colors.primary} />
                    </View>
                    <Text style={styles.backupLabel}>{t("settings.backup.exportBtn")}</Text>
                    <Text style={styles.backupSub}>{t("settings.backup.jsonFile")}</Text>
                  </TouchableOpacity>
                  <TouchableOpacity style={styles.backupBox} onPress={handleSaveToApp} activeOpacity={0.82}>
                    <View style={[styles.backupIconRing, { backgroundColor: "#E6FBF4" }]}>
                      <Feather name="save" size={22} color="#00C896" />
                    </View>
                    <Text style={styles.backupLabel}>{t("settings.backup.save")}</Text>
                    <Text style={styles.backupSub}>{justSaved ? t("settings.backup.savedStatus") : t("settings.backup.autoManual")}</Text>
                    {justSaved && (
                      <View style={styles.backupBadge}>
                        <Feather name="check" size={10} color="#00C896" />
                      </View>
                    )}
                  </TouchableOpacity>
                  <TouchableOpacity style={[styles.backupBox, busy && { opacity: 0.5 }]} onPress={handleGenerateReport} disabled={busy} activeOpacity={0.82}>
                    <View style={[styles.backupIconRing, { backgroundColor: "#FFF0F3" }]}>
                      <Feather name="file-text" size={22} color="#FF4D6D" />
                    </View>
                    <Text style={styles.backupLabel}>{t("settings.backup.report")}</Text>
                    <Text style={styles.backupSub}>{t("settings.backup.pdfExcel")}</Text>
                  </TouchableOpacity>
                </View>
              </View>
            );
            case "kategoriler": return (
              <View key={key} style={sectionStyle}>
                <SectionHdr title={t("settings.sections.categoriesSection")} sKey="kategoriler" />
                <View style={styles.card}>
                  <TouchableOpacity style={styles.ioBtn} onPress={() => { Haptics.selectionAsync(); setCategoryModalVisible(true); }}>
                    <View style={styles.ioIconBg}>
                      <Feather name="tag" size={18} color={colors.primary} />
                    </View>
                    <View style={styles.ioBody}>
                      <Text style={styles.ioTitle}>{t("settings.categories.management")}</Text>
                      <Text style={styles.ioDesc}>{t("settings.categories.managementDesc")}</Text>
                    </View>
                    <Feather name="chevron-right" size={18} color={colors.mutedForeground} />
                  </TouchableOpacity>
                </View>
              </View>
            );
            case "guvenlik": return (
              <View key={key} style={sectionStyle}>
                <SectionHdr title={t("settings.sections.securitySection")} sKey="guvenlik" />
                <View style={styles.card}>
                  <View style={styles.ioBtn}>
                    <View style={styles.ioIconBg}>
                      <Feather name="lock" size={18} color={colors.primary} />
                    </View>
                    <View style={styles.ioBody}>
                      <Text style={styles.ioTitle}>{t("settings.security.pinLock")}</Text>
                      <Text style={styles.ioDesc}>{pin ? t("settings.security.pinEnabled") : t("settings.security.pinDisabled")}</Text>
                    </View>
                    <Switch value={!!pin} onValueChange={handlePinToggle} trackColor={{ false: colors.border, true: colors.primary }} thumbColor="#FFFFFF" />
                  </View>
                  {!!pin && (
                    <>
                      <View style={styles.divider} />
                      <TouchableOpacity style={styles.ioBtn} onPress={handleChangePin}>
                        <View style={styles.ioIconBg}>
                          <Feather name="edit-2" size={18} color={colors.primary} />
                        </View>
                        <View style={styles.ioBody}>
                          <Text style={styles.ioTitle}>{t("settings.security.changePinTitle")}</Text>
                          <Text style={styles.ioDesc}>{t("settings.security.changePinDesc")}</Text>
                        </View>
                        <Feather name="chevron-right" size={18} color={colors.mutedForeground} />
                      </TouchableOpacity>
                    </>
                  )}
                </View>
              </View>
            );
            case "hatirlaticilar": return (
              <View key={key} style={sectionStyle}>
                <SectionHdr title={t("settings.sections.remindersSection")} sKey="hatirlaticilar" />
                <View style={styles.card}>
                  <View style={styles.ioBtn}>
                    <View style={[styles.ioIconBg, { backgroundColor: "#EEF2FF" }]}>
                      <Feather name="mic" size={18} color="#6366F1" />
                    </View>
                    <View style={styles.ioBody}>
                      <Text style={styles.ioTitle}>Sesli Asistan</Text>
                      <Text style={styles.ioDesc}>
                        {voiceEnabled ? "Mikrofon butonu aktif — ekranda serbestçe taşınabilir" : "Mikrofon butonu gizli"}
                      </Text>
                    </View>
                    <Switch
                      value={voiceEnabled}
                      onValueChange={(v) => { Haptics.selectionAsync(); setVoiceEnabled(v); }}
                      trackColor={{ false: colors.border, true: "#6366F1" }}
                      thumbColor="#FFFFFF"
                    />
                  </View>
                  <View style={styles.divider} />
                  <View style={styles.ioBtn}>
                    <View style={[styles.ioIconBg, { backgroundColor: "#E6FBF4" }]}>
                      <Feather name="bell" size={18} color="#007A5E" />
                    </View>
                    <View style={styles.ioBody}>
                      <Text style={styles.ioTitle}>{t("settings.reminders.notifications")}</Text>
                      <Text style={styles.ioDesc}>
                        {reminderSettings.enabled ? t("settings.reminders.enabledDesc") : t("settings.reminders.disabledDesc")}
                      </Text>
                    </View>
                    <Switch value={reminderSettings.enabled} onValueChange={handleReminderToggle} trackColor={{ false: colors.border, true: colors.primary }} thumbColor="#FFFFFF" />
                  </View>
                  {reminderSettings.enabled && (
                    <>
                      <View style={styles.divider} />
                      <TouchableOpacity style={styles.ioBtn} onPress={() => { Haptics.selectionAsync(); setNotifSheetOpen(true); }} activeOpacity={0.7}>
                        <View style={styles.ioBody}>
                          <Text style={[styles.ioTitle, { color: colors.primary }]}>{t("settings.reminders.editSettings")}</Text>
                          <Text style={styles.ioDesc}>{t("settings.reminders.editDesc")}</Text>
                        </View>
                        <Feather name="chevron-right" size={18} color={colors.primary} />
                      </TouchableOpacity>
                    </>
                  )}
                </View>
              </View>
            );
            case "bulut": return (
              <View key={key} style={sectionStyle}>
                <SectionHdr title={t("settings.sections.cloudSection")} sKey="bulut" />
                <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 8 }}>
                  <TouchableOpacity style={[styles.cloudBox, cloudBusy && { opacity: 0.5 }]} onPress={handleCloudBackup} disabled={cloudBusy} activeOpacity={0.82}>
                    <View style={[styles.cloudIconRing, { backgroundColor: "#E6FBF4" }]}>
                      <Feather name="cloud" size={18} color="#00C896" />
                    </View>
                    <Text style={styles.cloudLabel}>{cloudBusy ? t("settings.cloud.backing") : t("settings.cloud.kasafonCloud")}</Text>
                    <Text style={styles.cloudSub}>{t("settings.cloud.backupToCloud")}</Text>
                  </TouchableOpacity>
                  <TouchableOpacity style={[styles.cloudBox, cloudBusy && { opacity: 0.5 }]} onPress={() => { Haptics.selectionAsync(); setRestoreModal(true); }} disabled={cloudBusy} activeOpacity={0.82}>
                    <View style={[styles.cloudIconRing, { backgroundColor: "#EFF6FF" }]}>
                      <Feather name="download-cloud" size={18} color="#3B82F6" />
                    </View>
                    <Text style={styles.cloudLabel}>{t("settings.cloud.restoreLabel")}</Text>
                    <Text style={styles.cloudSub}>{t("settings.cloud.restoreWithCode")}</Text>
                  </TouchableOpacity>
                  <TouchableOpacity style={styles.cloudBox} onPress={() => handleCloudComingSoon("Google Drive")} activeOpacity={0.82}>
                    <View style={[styles.cloudIconRing, { backgroundColor: "#FEF3F2" }]}>
                      <Feather name="hard-drive" size={18} color="#EA4335" />
                    </View>
                    <Text style={styles.cloudLabel}>Google Drive</Text>
                    <Text style={styles.cloudSub}>{t("settings.cloud.soon")}</Text>
                    <View style={styles.cloudSoonBadge}><Text style={styles.cloudSoonBadgeText}>{t("settings.cloud.soonBadge")}</Text></View>
                  </TouchableOpacity>
                  <TouchableOpacity style={styles.cloudBox} onPress={() => handleCloudComingSoon("iCloud")} activeOpacity={0.82}>
                    <View style={[styles.cloudIconRing, { backgroundColor: "#F0F9FF" }]}>
                      <Feather name="cloud" size={18} color="#0EA5E9" />
                    </View>
                    <Text style={styles.cloudLabel}>iCloud</Text>
                    <Text style={styles.cloudSub}>{t("settings.cloud.soon")}</Text>
                    <View style={styles.cloudSoonBadge}><Text style={styles.cloudSoonBadgeText}>{t("settings.cloud.soonBadge")}</Text></View>
                  </TouchableOpacity>
                  <TouchableOpacity style={styles.cloudBox} onPress={() => handleCloudComingSoon("OneDrive")} activeOpacity={0.82}>
                    <View style={[styles.cloudIconRing, { backgroundColor: "#EFF6FF" }]}>
                      <Feather name="cloud-drizzle" size={18} color="#0078D4" />
                    </View>
                    <Text style={styles.cloudLabel}>OneDrive</Text>
                    <Text style={styles.cloudSub}>{t("settings.cloud.soon")}</Text>
                    <View style={styles.cloudSoonBadge}><Text style={styles.cloudSoonBadgeText}>{t("settings.cloud.soonBadge")}</Text></View>
                  </TouchableOpacity>
                  <TouchableOpacity style={styles.cloudBox} onPress={() => handleCloudComingSoon("Dropbox")} activeOpacity={0.82}>
                    <View style={[styles.cloudIconRing, { backgroundColor: "#EEF4FF" }]}>
                      <Feather name="box" size={18} color="#0061FF" />
                    </View>
                    <Text style={styles.cloudLabel}>Dropbox</Text>
                    <Text style={styles.cloudSub}>{t("settings.cloud.soon")}</Text>
                    <View style={styles.cloudSoonBadge}><Text style={styles.cloudSoonBadgeText}>{t("settings.cloud.soonBadge")}</Text></View>
                  </TouchableOpacity>
                </View>
                <View style={[styles.cloudKeyBox, { marginTop: 12, marginBottom: 0 }]}>
                  <Text style={styles.cloudKeyLabel}>{t("settings.cloud.keyLabel")}</Text>
                  <Text style={styles.cloudKeyText}>{cloudKey || "------"}</Text>
                  <Text style={styles.cloudKeyHint}>{t("settings.cloud.keyHint")}</Text>
                  {cloudLastSaved && (
                    <Text style={[styles.cloudKeyHint, { marginTop: 4 }]}>
                      {t("settings.cloud.lastSaved", { time: new Date(cloudLastSaved).toLocaleString(i18nHook.language, { day: "2-digit", month: "2-digit", year: "numeric", hour: "2-digit", minute: "2-digit" }) })}
                    </Text>
                  )}
                  <TouchableOpacity style={styles.cloudKeyRegenBtn} onPress={handleRegenerateKey}>
                    <Feather name="refresh-cw" size={11} color={colors.mutedForeground} />
                    <Text style={styles.cloudKeyRegenText}>{t("settings.cloud.regenerateKey")}</Text>
                  </TouchableOpacity>
                </View>
              </View>
            );
            case "tema": return (
              <View key={key} style={sectionStyle}>
                <SectionHdr title={t("settings.sections.themeSection")} sKey="tema" />
                <View style={styles.card}>
                  <View style={styles.themeModeRow}>
                    {themeOptions.map((opt) => {
                      const active = mode === opt.key;
                      return (
                        <TouchableOpacity key={opt.key} style={[styles.themeModeBtn, active && styles.themeModeBtnActive]} onPress={() => { Haptics.selectionAsync(); setMode(opt.key); }} activeOpacity={0.75}>
                          <Feather name={opt.icon as any} size={13} color={active ? "#FFFFFF" : colors.mutedForeground} />
                          <Text style={[styles.themeModeLabel, active && styles.themeModeLabelActive]}>{opt.label}</Text>
                        </TouchableOpacity>
                      );
                    })}
                  </View>
                  <View style={styles.themeModeDivider} />
                  <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.themeCircleRow}>
                    {namedThemes.map((nt) => {
                      const isActive = mode === nt.key;
                      return (
                        <TouchableOpacity key={nt.key} style={styles.themeCircleWrap} onPress={() => { Haptics.selectionAsync(); setMode(nt.key); }} activeOpacity={0.7}>
                          <View style={[styles.themeCircle, isActive && { borderColor: colors.primary, borderWidth: 2.5 }]}>
                            <View style={[styles.themeCircleHalf, { backgroundColor: nt.swatches[0] }]} />
                            <View style={[styles.themeCircleHalf, { backgroundColor: nt.swatches[1] }]} />
                          </View>
                          <Text style={[styles.themeCircleLabel, isActive && styles.themeCircleLabelActive]}>{nt.name}</Text>
                        </TouchableOpacity>
                      );
                    })}
                  </ScrollView>
                </View>
              </View>
            );
            case "doviz": {
              const MAJOR = ["USD","EUR","GBP","CHF","JPY","SAR","AED","CAD","AUD","CNY","RUB","GBP"];
              const uniqueMajor = [...new Set(MAJOR)];
              const selectedSymbol = CURRENCY_SYMBOLS[displayCurrency] ?? displayCurrency;
              return (
                <View key={key} style={sectionStyle}>
                  <SectionHdr title={t("settings.sections.currencySection")} sKey="doviz" />

                  {/* Aktif para birimi seçici */}
                  <TouchableOpacity
                    style={[styles.card, { flexDirection: "row", alignItems: "center", gap: 12 }]}
                    onPress={() => { Haptics.selectionAsync(); setCurrencyPickerTarget("display"); }}
                    activeOpacity={0.8}
                  >
                    <View style={{ width: 42, height: 42, borderRadius: 12, backgroundColor: colors.primary + "18", alignItems: "center", justifyContent: "center" }}>
                      <Text style={{ fontSize: 20 }}>{selectedSymbol}</Text>
                    </View>
                    <View style={{ flex: 1 }}>
                      <Text style={{ fontSize: 13, color: colors.mutedForeground, marginBottom: 1 }}>{t("settings.currency.displayCurrency")}</Text>
                      <Text style={{ fontSize: 16, fontWeight: "700", color: colors.foreground }}>
                        {displayCurrency} {displayCurrency !== "TRY" ? `— ${FOREX_LIST.find(f => f.code === displayCurrency)?.name ?? displayCurrency}` : "— Türk Lirası"}
                      </Text>
                    </View>
                    <Feather name="chevron-right" size={18} color={colors.mutedForeground} />
                  </TouchableOpacity>

                  {displayCurrency !== "TRY" && (
                    <View style={[styles.card, { flexDirection: "row", alignItems: "center", gap: 8, backgroundColor: colors.primary + "12" }]}>
                      <Feather name="info" size={14} color={colors.primary} />
                      <Text style={{ flex: 1, fontSize: 12, color: colors.primary, lineHeight: 16 }}>
                        {t("settings.currency.conversionNote")}
                      </Text>
                    </View>
                  )}

                  {/* Hızlı Çevirici */}
                  {(() => {
                    const amtNum = parseFloat(convAmount.replace(",", ".")) || 0;
                    const fromRate = convFrom === "TRY" ? 1 : rates[convFrom];
                    const toRate   = convTo   === "TRY" ? 1 : rates[convTo];
                    const canConvert = !!fromRate && !!toRate;
                    const tryAmt = canConvert ? amtNum / (fromRate as number) : 0;
                    const result = canConvert ? tryAmt * (toRate as number) : 0;
                    const fromSym = CURRENCY_SYMBOLS[convFrom] ?? convFrom;
                    const toSym   = CURRENCY_SYMBOLS[convTo]   ?? convTo;
                    const fmt = (n: number) =>
                      new Intl.NumberFormat("tr-TR", { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(n);
                    return (
                      <View style={[styles.card, { paddingHorizontal: 14, paddingVertical: 14, gap: 10 }]}>
                        <View style={{ flexDirection: "row", alignItems: "center", gap: 8 }}>
                          <Feather name="repeat" size={14} color={colors.primary} />
                          <Text style={{ fontSize: 13, fontWeight: "700", color: colors.foreground }}>
                            {t("settings.currency.quickConverter")}
                          </Text>
                        </View>

                        <View style={{ flexDirection: "row", alignItems: "center", gap: 8 }}>
                          <View style={{ flex: 1, flexDirection: "row", alignItems: "center", backgroundColor: colors.muted, borderRadius: 10, paddingHorizontal: 10, height: 44 }}>
                            <Text style={{ fontSize: 15, fontWeight: "700", color: colors.foreground, marginRight: 6 }}>{fromSym}</Text>
                            <TextInput
                              value={convAmount}
                              onChangeText={(v) => setConvAmount(v.replace(/[^0-9.,]/g, ""))}
                              keyboardType="decimal-pad"
                              placeholder="0"
                              placeholderTextColor={colors.mutedForeground}
                              style={{ flex: 1, fontSize: 15, color: colors.foreground, paddingVertical: 0 }}
                            />
                          </View>
                          <TouchableOpacity
                            onPress={() => { Haptics.selectionAsync(); setCurrencyPickerTarget("convFrom"); }}
                            activeOpacity={0.75}
                            style={{ flexDirection: "row", alignItems: "center", gap: 4, paddingHorizontal: 10, height: 44, backgroundColor: colors.primary + "12", borderRadius: 10 }}
                          >
                            <Text style={{ fontSize: 13, fontWeight: "700", color: colors.primary }}>{convFrom}</Text>
                            <Feather name="chevron-down" size={14} color={colors.primary} />
                          </TouchableOpacity>
                        </View>

                        <View style={{ alignItems: "center" }}>
                          <TouchableOpacity
                            onPress={() => { Haptics.selectionAsync(); setConvFrom(convTo); setConvTo(convFrom); }}
                            activeOpacity={0.7}
                            style={{ width: 32, height: 32, borderRadius: 16, backgroundColor: colors.muted, alignItems: "center", justifyContent: "center" }}
                          >
                            <Feather name="repeat" size={14} color={colors.mutedForeground} />
                          </TouchableOpacity>
                        </View>

                        <View style={{ flexDirection: "row", alignItems: "center", gap: 8 }}>
                          <View style={{ flex: 1, flexDirection: "row", alignItems: "center", backgroundColor: colors.muted, borderRadius: 10, paddingHorizontal: 10, height: 44 }}>
                            <Text style={{ fontSize: 15, fontWeight: "700", color: colors.foreground, marginRight: 6 }}>{toSym}</Text>
                            <Text style={{ flex: 1, fontSize: 15, fontWeight: "700", color: canConvert ? colors.primary : colors.mutedForeground }} numberOfLines={1}>
                              {canConvert ? fmt(result) : "—"}
                            </Text>
                          </View>
                          <TouchableOpacity
                            onPress={() => { Haptics.selectionAsync(); setCurrencyPickerTarget("convTo"); }}
                            activeOpacity={0.75}
                            style={{ flexDirection: "row", alignItems: "center", gap: 4, paddingHorizontal: 10, height: 44, backgroundColor: colors.primary + "12", borderRadius: 10 }}
                          >
                            <Text style={{ fontSize: 13, fontWeight: "700", color: colors.primary }}>{convTo}</Text>
                            <Feather name="chevron-down" size={14} color={colors.primary} />
                          </TouchableOpacity>
                        </View>

                        {canConvert && amtNum > 0 && (
                          <Text style={{ fontSize: 11, color: colors.mutedForeground, textAlign: "center", marginTop: 2 }}>
                            {fmt(amtNum)} {convFrom} = {fmt(result)} {convTo}
                          </Text>
                        )}
                      </View>
                    );
                  })()}

                  {/* Döviz kurları (açılır liste) */}
                  <View style={[styles.card, { paddingHorizontal: 0, paddingVertical: 0, overflow: "hidden" }]}>
                    <TouchableOpacity
                      onPress={() => { Haptics.selectionAsync(); setRatesExpanded((v) => !v); }}
                      activeOpacity={0.75}
                      style={{ flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingHorizontal: 16, paddingVertical: 12, borderBottomWidth: ratesExpanded ? StyleSheet.hairlineWidth : 0, borderBottomColor: colors.border }}
                    >
                      <View style={{ flexDirection: "row", alignItems: "center", gap: 8 }}>
                        <Feather name={ratesExpanded ? "chevron-down" : "chevron-right"} size={14} color={colors.mutedForeground} />
                        <Text style={{ fontSize: 13, fontWeight: "700", color: colors.foreground }}>
                          {t("settings.currency.liveRates")}
                        </Text>
                      </View>
                      <View style={{ flexDirection: "row", alignItems: "center", gap: 8 }}>
                        {ratesUpdated && (
                          <Text style={{ fontSize: 10, color: colors.mutedForeground }}>
                            {ratesUpdated.toLocaleTimeString("tr-TR", { hour: "2-digit", minute: "2-digit" })}
                          </Text>
                        )}
                        <TouchableOpacity
                          onPress={(e) => { e.stopPropagation?.(); Haptics.selectionAsync(); refreshRates(); }}
                          disabled={ratesLoading}
                          style={{ opacity: ratesLoading ? 0.4 : 1, padding: 4 }}
                          hitSlop={8}
                        >
                          <Feather name="refresh-cw" size={14} color={colors.primary} />
                        </TouchableOpacity>
                      </View>
                    </TouchableOpacity>
                    {ratesExpanded && (
                      <>
                        {uniqueMajor.map((code, idx) => {
                          const rate = rates[code];
                          if (!rate) return null;
                          const tryPerUnit = 1 / rate;
                          const sym = CURRENCY_SYMBOLS[code] ?? code;
                          const isLast = idx === uniqueMajor.filter(c => !!rates[c]).length - 1;
                          return (
                            <TouchableOpacity
                              key={code}
                              style={{ flexDirection: "row", alignItems: "center", paddingHorizontal: 16, paddingVertical: 11, borderBottomWidth: isLast ? 0 : StyleSheet.hairlineWidth, borderBottomColor: colors.border, backgroundColor: displayCurrency === code ? colors.primary + "0C" : "transparent" }}
                              onPress={() => { Haptics.selectionAsync(); setCurrency(code); }}
                              activeOpacity={0.7}
                            >
                              <View style={{ width: 32, height: 32, borderRadius: 8, backgroundColor: colors.muted, alignItems: "center", justifyContent: "center", marginRight: 12 }}>
                                <Text style={{ fontSize: 14, fontWeight: "700", color: colors.foreground }}>{sym}</Text>
                              </View>
                              <Text style={{ flex: 1, fontSize: 14, fontWeight: "600", color: colors.foreground }}>{code}</Text>
                              <Text style={{ fontSize: 13, fontWeight: "700", color: displayCurrency === code ? colors.primary : colors.foreground }}>
                                {new Intl.NumberFormat("tr-TR", { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(tryPerUnit)} ₺
                              </Text>
                              {displayCurrency === code && <Feather name="check" size={14} color={colors.primary} style={{ marginLeft: 8 }} />}
                            </TouchableOpacity>
                          );
                        })}
                        {Object.keys(rates).length === 0 && !ratesLoading && (
                          <View style={{ padding: 20, alignItems: "center" }}>
                            <Text style={{ fontSize: 13, color: colors.mutedForeground }}>{t("settings.currency.noRates")}</Text>
                          </View>
                        )}
                        {ratesLoading && (
                          <View style={{ padding: 20, alignItems: "center" }}>
                            <Text style={{ fontSize: 13, color: colors.mutedForeground }}>{t("settings.currency.loading")}</Text>
                          </View>
                        )}
                      </>
                    )}
                  </View>
                </View>
              );
            }
            default: return null;
          }
        })}

        <NotificationSettingsSheet
          visible={notifSheetOpen}
          onClose={() => setNotifSheetOpen(false)}
        />

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>{t("settings.sections.dangerSection")}</Text>
          <View style={styles.card}>
            <TouchableOpacity
              style={[styles.ioBtn, busy && { opacity: 0.5 }]}
              onPress={handleDeleteAll}
              disabled={busy}
            >
              <View
                style={[
                  styles.ioIconBg,
                  { backgroundColor: colors.expense + "1A" },
                ]}
              >
                <Feather name="trash-2" size={18} color={colors.expense} />
              </View>
              <View style={styles.ioBody}>
                <Text style={[styles.ioTitle, { color: colors.expense }]}>
                  {t("settings.danger.deleteAll")}
                </Text>
                <Text style={styles.ioDesc}>
                  {hasExported
                    ? t("settings.danger.safeToDelete")
                    : t("settings.danger.backupFirst")}
                </Text>
              </View>
              <Feather
                name="chevron-right"
                size={18}
                color={colors.mutedForeground}
              />
            </TouchableOpacity>
          </View>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>{t("settings.sections.statsSection")}</Text>
          <View style={styles.card}>
            <View style={styles.statRow}>
              <Text style={styles.statLabel}>{t("settings.stats.totalTransactions")}</Text>
              <Text style={styles.statValue}>{transactions.length}</Text>
            </View>
            <View style={styles.divider} />
            <View style={styles.statRow}>
              <Text style={styles.statLabel}>{t("settings.stats.totalDebts")}</Text>
              <Text style={styles.statValue}>{debts.length}</Text>
            </View>
          </View>
        </View>

        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Hakkında</Text>
          <View style={styles.card}>
            <TouchableOpacity
              style={styles.ioBtn}
              onPress={() => { Haptics.selectionAsync(); router.push("/finans" as any); }}
              activeOpacity={0.7}
            >
              <View style={styles.ioIconBg}>
                <Feather name="shield" size={18} color={colors.primary} />
              </View>
              <View style={styles.ioBody}>
                <Text style={styles.ioTitle}>Gizlilik Politikası</Text>
                <Text style={styles.ioDesc}>Verileriniz nasıl korunuyor?</Text>
              </View>
              <Feather name="chevron-right" size={18} color={colors.mutedForeground} />
            </TouchableOpacity>
            <View style={styles.divider} />
            <View style={styles.ioBtn}>
              <View style={styles.ioIconBg}>
                <Feather name="info" size={18} color={colors.primary} />
              </View>
              <View style={styles.ioBody}>
                <Text style={styles.ioTitle}>Versiyon</Text>
                <Text style={styles.ioDesc}>1.0.0 (Build 1)</Text>
              </View>
            </View>
          </View>
        </View>

        <View style={styles.footer}>
          <Text style={styles.footerText}>KasaFON • v1.0</Text>
        </View>
      </ScrollView>

      <PinSetupModal
        visible={pinModal.visible}
        mode={pinModal.mode}
        currentPin={pin}
        onSuccess={handlePinSuccess}
        onCancel={() => setPinModal((p) => ({ ...p, visible: false }))}
      />
      <CategoryManagerModal
        visible={categoryModalVisible}
        onClose={() => setCategoryModalVisible(false)}
      />
      {/* Language Picker Modal */}
      <Modal
        visible={langModalVisible}
        transparent
        animationType="slide"
        onRequestClose={() => setLangModalVisible(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={[styles.modalBox, { maxHeight: "80%", padding: 0, overflow: "hidden" }]}>
            <View style={{ paddingHorizontal: 20, paddingTop: 20, paddingBottom: 12, borderBottomWidth: 1, borderBottomColor: colors.border }}>
              <Text style={styles.modalTitle}>🌐 {t("settings.language.select")}</Text>
              <Text style={styles.modalDesc}>{t("settings.language.title")} · Choose your language</Text>
            </View>
            <ScrollView showsVerticalScrollIndicator={false} style={{ maxHeight: 420 }}>
              {SUPPORTED_LANGUAGES.map((lang) => {
                const isSelected = currentLang === lang.code;
                return (
                  <TouchableOpacity
                    key={lang.code}
                    onPress={() => handleLanguageChange(lang.code)}
                    activeOpacity={0.75}
                    style={{
                      flexDirection: "row",
                      alignItems: "center",
                      paddingHorizontal: 20,
                      paddingVertical: 14,
                      backgroundColor: isSelected ? colors.primary + "15" : "transparent",
                      borderBottomWidth: 1,
                      borderBottomColor: colors.border + "55",
                    }}
                  >
                    <View style={{ flex: 1 }}>
                      <Text style={{ fontSize: 16, fontWeight: "600", color: isSelected ? colors.primary : colors.foreground }}>
                        {lang.nativeLabel}
                      </Text>
                      <Text style={{ fontSize: 12, color: colors.mutedForeground, marginTop: 2 }}>
                        {lang.label}
                      </Text>
                    </View>
                    {isSelected && (
                      <Feather name="check-circle" size={20} color={colors.primary} />
                    )}
                  </TouchableOpacity>
                );
              })}
            </ScrollView>
            <TouchableOpacity
              onPress={() => { Haptics.selectionAsync(); setLangModalVisible(false); }}
              style={{ paddingVertical: 16, alignItems: "center", borderTopWidth: 1, borderTopColor: colors.border }}
            >
              <Text style={{ fontSize: 15, fontWeight: "600", color: colors.mutedForeground }}>Vazgeç · Cancel</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>

      {/* Currency Picker Modal (display / convFrom / convTo) */}
      <Modal
        visible={currencyPickerTarget !== null}
        transparent
        animationType="slide"
        onRequestClose={() => { setCurrencyPickerTarget(null); setCurrencySearch(""); }}
      >
        <View style={styles.modalOverlay}>
          <View style={[styles.modalBox, { maxHeight: "85%", padding: 0, overflow: "hidden" }]}>
            <View style={{ paddingHorizontal: 16, paddingTop: 16, paddingBottom: 10, borderBottomWidth: 1, borderBottomColor: colors.border }}>
              <Text style={[styles.modalTitle, { marginBottom: 8 }]}>
                {currencyPickerTarget === "convFrom"
                  ? t("settings.currency.pickFrom")
                  : currencyPickerTarget === "convTo"
                  ? t("settings.currency.pickTo")
                  : t("settings.currency.selectCurrency")}
              </Text>
              <View style={{ flexDirection: "row", alignItems: "center", backgroundColor: colors.muted, borderRadius: 10, paddingHorizontal: 10, gap: 6 }}>
                <Feather name="search" size={14} color={colors.mutedForeground} />
                <TextInput
                  value={currencySearch}
                  onChangeText={setCurrencySearch}
                  placeholder={t("settings.currency.searchCurrency")}
                  placeholderTextColor={colors.mutedForeground}
                  style={{ flex: 1, paddingVertical: 9, fontSize: 14, color: colors.foreground }}
                  autoFocus
                />
              </View>
            </View>
            <ScrollView showsVerticalScrollIndicator={false} keyboardShouldPersistTaps="handled">
              {[{ code: "TRY", name: "Türk Lirası" }, ...FOREX_LIST]
                .filter((c) => currencySearch === "" || c.code.toLowerCase().includes(currencySearch.toLowerCase()) || c.name.toLowerCase().includes(currencySearch.toLowerCase()))
                .map((c) => {
                  const activeCode =
                    currencyPickerTarget === "convFrom" ? convFrom :
                    currencyPickerTarget === "convTo"   ? convTo   :
                    displayCurrency;
                  const isSelected = activeCode === c.code;
                  const sym = CURRENCY_SYMBOLS[c.code] ?? c.code;
                  const rate = c.code === "TRY" ? null : rates[c.code];
                  const tryPerUnit = rate ? 1 / rate : null;
                  return (
                    <TouchableOpacity
                      key={c.code}
                      onPress={() => {
                        Haptics.selectionAsync();
                        if (currencyPickerTarget === "convFrom") setConvFrom(c.code);
                        else if (currencyPickerTarget === "convTo") setConvTo(c.code);
                        else setCurrency(c.code);
                        setCurrencyPickerTarget(null);
                        setCurrencySearch("");
                      }}
                      activeOpacity={0.75}
                      style={{ flexDirection: "row", alignItems: "center", paddingHorizontal: 16, paddingVertical: 13, backgroundColor: isSelected ? colors.primary + "15" : "transparent", borderBottomWidth: StyleSheet.hairlineWidth, borderBottomColor: colors.border }}
                    >
                      <View style={{ width: 36, height: 36, borderRadius: 8, backgroundColor: colors.muted, alignItems: "center", justifyContent: "center", marginRight: 12 }}>
                        <Text style={{ fontSize: 16, fontWeight: "700", color: colors.foreground }}>{sym}</Text>
                      </View>
                      <View style={{ flex: 1 }}>
                        <Text style={{ fontSize: 15, fontWeight: "600", color: isSelected ? colors.primary : colors.foreground }}>{c.code}</Text>
                        <Text style={{ fontSize: 11, color: colors.mutedForeground, marginTop: 1 }}>{c.name}</Text>
                      </View>
                      {tryPerUnit !== null && (
                        <Text style={{ fontSize: 12, color: colors.mutedForeground, marginRight: 8 }}>
                          {new Intl.NumberFormat("tr-TR", { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(tryPerUnit)} ₺
                        </Text>
                      )}
                      {isSelected && <Feather name="check-circle" size={18} color={colors.primary} />}
                    </TouchableOpacity>
                  );
                })}
            </ScrollView>
            <TouchableOpacity
              onPress={() => { Haptics.selectionAsync(); setCurrencyPickerTarget(null); setCurrencySearch(""); }}
              style={{ paddingVertical: 14, alignItems: "center", borderTopWidth: 1, borderTopColor: colors.border }}
            >
              <Text style={{ fontSize: 15, fontWeight: "600", color: colors.mutedForeground }}>{t("common.cancel")}</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>

      {/* Restore Key Modal */}
      <Modal
        visible={restoreModal}
        transparent
        animationType="fade"
        onRequestClose={() => setRestoreModal(false)}
      >
        <KeyboardAvoidingView
          behavior={Platform.OS === "ios" ? "padding" : "height"}
          style={{ flex: 1 }}
        >
        <View style={styles.modalOverlay}>
          <View style={styles.modalBox}>
            <Text style={styles.modalTitle}>{t("settings.cloud.restore")}</Text>
            <Text style={styles.modalDesc}>
              {t("settings.cloud.enterCode")}
            </Text>
            <TextInput
              style={styles.modalInput}
              value={restoreInput}
              onChangeText={(v) => setRestoreInput(v.toUpperCase())}
              placeholder={t("settings.cloud.codePlaceholder")}
              placeholderTextColor={colors.mutedForeground}
              autoCapitalize="characters"
              maxLength={6}
              autoFocus
            />
            <View style={styles.modalBtnRow}>
              <TouchableOpacity
                style={styles.modalCancelBtn}
                onPress={() => { setRestoreModal(false); setRestoreInput(""); }}
              >
                <Text style={styles.modalCancelText}>{t("common.cancel")}</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.modalConfirmBtn, restoreInput.length < 4 && { opacity: 0.5 }]}
                onPress={handleCloudRestore}
                disabled={restoreInput.length < 4}
              >
                <Text style={styles.modalConfirmText}>{t("settings.cloud.restoreLabel")}</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
        </KeyboardAvoidingView>
      </Modal>
    </View>
  );
}
