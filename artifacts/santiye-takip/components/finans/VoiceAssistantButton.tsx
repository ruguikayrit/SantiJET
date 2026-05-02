import { Feather } from "@expo/vector-icons";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { Audio } from "expo-av";
import * as FileSystem from "expo-file-system/legacy";
import { LinearGradient } from "expo-linear-gradient";
import { useSegments } from "expo-router";
import React, { useCallback, useEffect, useRef, useState } from "react";
import {
  ActivityIndicator,
  Animated,
  Dimensions,
  Modal,
  PanResponder,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
  useColorScheme,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import { BankLimit, PaymentMethod, Transaction, useBudget } from "@/context/finans/BudgetContext";
import { useVoiceAssistant } from "@/context/finans/VoiceAssistantContext";
import { EXPENSE_CATEGORIES, INCOME_CATEGORIES } from "@/utils/finans/categories";

const API_BASE = process.env.EXPO_PUBLIC_DOMAIN
  ? `https://${process.env.EXPO_PUBLIC_DOMAIN}:8080/api`
  : "http://localhost:8080/api";

const TAB_BAR_HEIGHT = 62;
const FAB_SIZE = 56;
const POSITION_KEY = "@voice_assistant_position";

const HIDDEN_TABS = ["(sections)", "settings"];

type RecordingState = "idle" | "recording" | "processing" | "result" | "error";
type PickerType = "category" | "paymentMethod" | "card" | null;

interface ParsedTransaction {
  type: "gelir" | "gider";
  amount: number | null;
  currency: string;
  category: string;
  description: string;
  date: string;
  paymentMethod: "cash" | "card" | "transfer" | null;
  bank: string | null;
  confidence: number;
}

interface EditState {
  type: "income" | "expense";
  amount: string;
  category: string;
  note: string;
  date: string;
  paymentMethod: PaymentMethod | "";
  bank: string;
}

const PAYMENT_OPTIONS: { key: PaymentMethod | ""; label: string; icon: string }[] = [
  { key: "",         label: "Belirtilmedi", icon: "—" },
  { key: "cash",     label: "Nakit",        icon: "💵" },
  { key: "card",     label: "Kredi Kartı",  icon: "💳" },
  { key: "transfer", label: "Havale/EFT",   icon: "🏦" },
];

export default function VoiceAssistantButton() {
  const { enabled } = useVoiceAssistant();
  const colorScheme = useColorScheme();
  const isDark = colorScheme === "dark";
  const insets = useSafeAreaInsets();
  const { addTransaction, bankLimits } = useBudget();
  const segments = useSegments();

  // Hide on Finansal ((sections)) and Settings tabs
  const activeTab = segments[1] as string | undefined;
  const isHiddenTab = HIDDEN_TABS.includes(activeTab ?? "");

  const [state, setState] = useState<RecordingState>("idle");
  const [transcript, setTranscript] = useState("");
  const [editState, setEditState] = useState<EditState>({
    type: "expense",
    amount: "",
    category: "",
    note: "",
    date: new Date().toISOString().slice(0, 10),
    paymentMethod: "",
    bank: "",
  });
  const [errorMsg, setErrorMsg] = useState("");
  const [activePicker, setActivePicker] = useState<PickerType>(null);

  const recordingRef = useRef<Audio.Recording | null>(null);
  const pulseAnim = useRef(new Animated.Value(1)).current;
  const pulseLoop = useRef<Animated.CompositeAnimation | null>(null);

  const { width: screenW, height: screenH } = Dimensions.get("window");
  const defaultX = screenW - FAB_SIZE - 20;
  const defaultY = screenH - insets.bottom - TAB_BAR_HEIGHT - FAB_SIZE - 12;

  const pan = useRef(new Animated.ValueXY({ x: defaultX, y: defaultY })).current;
  const panRef = useRef({ x: defaultX, y: defaultY });

  useEffect(() => {
    AsyncStorage.getItem(POSITION_KEY).then((val) => {
      if (val) {
        try {
          const { x, y } = JSON.parse(val) as { x: number; y: number };
          pan.setValue({ x, y });
          panRef.current = { x, y };
        } catch {}
      }
    });
  }, []);

  const panResponder = useRef(
    PanResponder.create({
      onStartShouldSetPanResponder: () => false,
      onMoveShouldSetPanResponder: (_e, gs) =>
        Math.abs(gs.dx) > 5 || Math.abs(gs.dy) > 5,
      onPanResponderGrant: () => {
        pan.setOffset({ x: panRef.current.x, y: panRef.current.y });
        pan.setValue({ x: 0, y: 0 });
      },
      onPanResponderMove: Animated.event([null, { dx: pan.x, dy: pan.y }], {
        useNativeDriver: false,
      }),
      onPanResponderRelease: (_e, gs) => {
        pan.flattenOffset();
        const { width: w, height: h } = Dimensions.get("window");
        let newX = panRef.current.x + gs.dx;
        let newY = panRef.current.y + gs.dy;
        newX = Math.max(8, Math.min(w - FAB_SIZE - 8, newX));
        newY = Math.max(insets.top + 8, Math.min(h - FAB_SIZE - 8, newY));
        pan.setValue({ x: newX, y: newY });
        panRef.current = { x: newX, y: newY };
        AsyncStorage.setItem(POSITION_KEY, JSON.stringify({ x: newX, y: newY }));
      },
    })
  ).current;

  const startPulse = useCallback(() => {
    pulseLoop.current = Animated.loop(
      Animated.sequence([
        Animated.timing(pulseAnim, { toValue: 1.25, duration: 600, useNativeDriver: true }),
        Animated.timing(pulseAnim, { toValue: 1, duration: 600, useNativeDriver: true }),
      ])
    );
    pulseLoop.current.start();
  }, [pulseAnim]);

  const stopPulse = useCallback(() => {
    pulseLoop.current?.stop();
    pulseAnim.setValue(1);
  }, [pulseAnim]);

  const handleMicPress = async () => {
    if (state === "recording") {
      await stopRecording();
    } else if (state === "idle") {
      await startRecording();
    }
  };

  const M4A_RECORDING_OPTIONS: Audio.RecordingOptions = {
    ...Audio.RecordingOptionsPresets.HIGH_QUALITY,
    ios: {
      extension: ".m4a",
      outputFormat: Audio.IOSOutputFormat.MPEG4AAC,
      audioQuality: Audio.IOSAudioQuality.HIGH,
      sampleRate: 44100,
      numberOfChannels: 1,
      bitRate: 128000,
    },
  };

  const startRecording = async () => {
    const { status } = await Audio.requestPermissionsAsync();
    if (status !== "granted") {
      setErrorMsg("Mikrofon izni gerekli. Lütfen ayarlardan izin verin.");
      setState("error");
      return;
    }
    try {
      await Audio.setAudioModeAsync({
        allowsRecordingIOS: true,
        playsInSilentModeIOS: true,
        staysActiveInBackground: false,
      });
      const { recording } = await Audio.Recording.createAsync(M4A_RECORDING_OPTIONS);
      recordingRef.current = recording;
      setState("recording");
      startPulse();
    } catch (err: any) {
      setErrorMsg("Kayıt başlatılamadı: " + (err?.message ?? "Bilinmeyen hata"));
      setState("error");
    }
  };

  const stopRecording = async () => {
    stopPulse();
    setState("processing");
    try {
      const recording = recordingRef.current;
      if (!recording) return;
      await recording.stopAndUnloadAsync();
      const uri = recording.getURI();
      recordingRef.current = null;
      if (!uri) throw new Error("Kayıt URI alınamadı");

      const base64 = await FileSystem.readAsStringAsync(uri, {
        encoding: FileSystem.EncodingType.Base64,
      });

      const response = await fetch(`${API_BASE}/assistant/parse-voice`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ audioBase64: base64, mimeType: "audio/m4a", ext: "m4a", language: "tr" }),
      });

      if (!response.ok) {
        const errData = await response.json().catch(() => ({})) as { error?: string };
        throw new Error(errData?.error ?? `HTTP ${response.status}`);
      }

      const data = await response.json() as { transcript: string; transaction: ParsedTransaction };
      const tx = data.transaction;

      // Match bank name from registered cards if possible
      const matchedCard = matchBankName(tx.bank, bankLimits);

      setTranscript(data.transcript ?? "");
      setEditState({
        type: tx.type === "gelir" ? "income" : "expense",
        amount: tx.amount != null ? String(tx.amount) : "",
        category: tx.category ?? "",
        note: tx.description ?? "",
        date: tx.date ?? new Date().toISOString().slice(0, 10),
        paymentMethod: (tx.paymentMethod as PaymentMethod) ?? "",
        bank: matchedCard ?? tx.bank ?? "",
      });
      setState("result");
    } catch (err: any) {
      setErrorMsg(err?.message ?? "İşlem sırasında hata oluştu");
      setState("error");
    }
  };

  function matchBankName(aiBank: string | null, limits: BankLimit[]): string | null {
    if (!aiBank) return null;
    const lower = aiBank.toLowerCase();
    const found = limits.find(
      (b) => b.type === "credit" && b.bank.toLowerCase().includes(lower)
    );
    return found ? found.bank : null;
  }

  const handleConfirm = () => {
    const amount = parseFloat(editState.amount.replace(",", "."));
    if (!amount || isNaN(amount)) {
      setErrorMsg("Lütfen geçerli bir tutar girin.");
      setState("error");
      return;
    }
    const newTx: Omit<Transaction, "id"> = {
      type: editState.type,
      amount,
      category: editState.category,
      note: editState.note,
      date: editState.date,
      ...(editState.paymentMethod ? { paymentMethod: editState.paymentMethod } : {}),
      ...(editState.bank ? { bank: editState.bank } : {}),
    };
    addTransaction(newTx);
    setState("idle");
    setTranscript("");
  };

  const handleDismiss = () => {
    setState("idle");
    setErrorMsg("");
    setTranscript("");
  };

  const categories = editState.type === "income" ? INCOME_CATEGORIES : EXPENSE_CATEGORIES;
  const creditCards = bankLimits.filter((b) => b.type === "credit");

  // Theme colors
  const bg          = isDark ? "#1E1E2E" : "#FFFFFF";
  const textColor   = isDark ? "#E2E8F0" : "#1E293B";
  const subColor    = isDark ? "#94A3B8" : "#64748B";
  const inputBg     = isDark ? "#0F172A" : "#F8FAFC";
  const borderColor = isDark ? "#334155" : "#E2E8F0";
  const divColor    = isDark ? "#1E293B" : "#F1F5F9";

  if (!enabled || isHiddenTab) return null;

  const paymentLabel = PAYMENT_OPTIONS.find((p) => p.key === editState.paymentMethod)?.label ?? "Belirtilmedi";
  const paymentIcon  = PAYMENT_OPTIONS.find((p) => p.key === editState.paymentMethod)?.icon ?? "—";

  return (
    <>
      {/* Floating Mic Button */}
      {(state === "idle" || state === "recording") && (
        <Animated.View
          style={[styles.fabWrapper, { left: pan.x, top: pan.y }]}
          {...panResponder.panHandlers}
        >
          {state === "recording" && (
            <Animated.View
              style={[
                styles.pulseRing,
                {
                  opacity: pulseAnim.interpolate({ inputRange: [1, 1.25], outputRange: [0.5, 0] }),
                  transform: [{ scale: pulseAnim }],
                },
              ]}
            />
          )}
          <TouchableOpacity onPress={handleMicPress} activeOpacity={0.82}>
            <LinearGradient
              colors={state === "recording" ? ["#FF3B30", "#C0392B"] : ["#4CD964", "#27AE60"]}
              start={{ x: 0, y: 0 }}
              end={{ x: 0.6, y: 1 }}
              style={styles.fab}
            >
              <Feather name={state === "recording" ? "mic-off" : "mic"} size={24} color="#FFF" />
            </LinearGradient>
          </TouchableOpacity>
        </Animated.View>
      )}

      {/* Processing Modal */}
      <Modal visible={state === "processing"} transparent animationType="fade" statusBarTranslucent>
        <View style={styles.overlay}>
          <View style={[styles.floatingCard, { backgroundColor: bg, alignItems: "center", paddingVertical: 36 }]}>
            <ActivityIndicator size="large" color="#6366F1" />
            <Text style={[styles.cardTitle, { color: textColor, marginTop: 16 }]}>Analiz ediliyor...</Text>
            <Text style={[styles.cardSub, { color: subColor }]}>Sesiniz işleniyor</Text>
          </View>
        </View>
      </Modal>

      {/* Summary / Confirmation Modal */}
      <Modal
        visible={state === "result"}
        transparent
        animationType="slide"
        statusBarTranslucent
        onRequestClose={handleDismiss}
      >
        <View style={styles.overlay}>
          <View style={[styles.sheet, { backgroundColor: bg }]}>
            {/* Header */}
            <View style={styles.sheetHeader}>
              <View style={styles.sheetHandle} />
              <View style={styles.headerRow}>
                <Text style={[styles.sheetTitle, { color: textColor }]}>İşlem Özeti</Text>
                <TouchableOpacity onPress={handleDismiss} hitSlop={{ top: 12, bottom: 12, left: 12, right: 12 }}>
                  <Feather name="x" size={22} color={subColor} />
                </TouchableOpacity>
              </View>
            </View>

            {/* Transcript */}
            {!!transcript && (
              <View style={[styles.transcriptBox, { backgroundColor: isDark ? "#0F172A" : "#F0F4FF", borderColor: isDark ? "#312E81" : "#C7D2FE" }]}>
                <Feather name="mic" size={13} color="#6366F1" style={{ marginRight: 6 }} />
                <Text style={[styles.transcriptText, { color: isDark ? "#A5B4FC" : "#4338CA" }]} numberOfLines={2}>
                  {transcript}
                </Text>
              </View>
            )}

            <ScrollView style={{ flex: 1 }} showsVerticalScrollIndicator={false} keyboardShouldPersistTaps="handled">

              {/* Tür toggle */}
              <View style={[styles.row, { borderBottomColor: divColor }]}>
                <Text style={[styles.rowLabel, { color: subColor }]}>Tür</Text>
                <View style={styles.typeToggle}>
                  {(["expense", "income"] as const).map((tp) => (
                    <TouchableOpacity
                      key={tp}
                      style={[
                        styles.typeBtn,
                        editState.type === tp && {
                          backgroundColor: tp === "expense" ? "#EF4444" : "#22C55E",
                        },
                        { borderColor: tp === "expense" ? "#EF4444" : "#22C55E" },
                      ]}
                      onPress={() => setEditState((s) => ({ ...s, type: tp, category: "" }))}
                    >
                      <Text style={[styles.typeBtnText, { color: editState.type === tp ? "#FFF" : (tp === "expense" ? "#EF4444" : "#22C55E") }]}>
                        {tp === "expense" ? "Gider" : "Gelir"}
                      </Text>
                    </TouchableOpacity>
                  ))}
                </View>
              </View>

              {/* Tutar */}
              <View style={[styles.row, { borderBottomColor: divColor }]}>
                <Text style={[styles.rowLabel, { color: subColor }]}>
                  Tutar{!editState.amount && <Text style={{ color: "#EF4444" }}> *</Text>}
                </Text>
                <View style={[styles.amountInput, { backgroundColor: inputBg, borderColor: !editState.amount ? "#EF4444" : borderColor }]}>
                  <Text style={[styles.amountCurrency, { color: subColor }]}>₺</Text>
                  <TextInput
                    style={[styles.amountText, { color: textColor }]}
                    value={editState.amount}
                    onChangeText={(v) => setEditState((s) => ({ ...s, amount: v }))}
                    keyboardType="decimal-pad"
                    placeholder="0,00"
                    placeholderTextColor={isDark ? "#475569" : "#94A3B8"}
                  />
                </View>
              </View>

              {/* Açıklama */}
              <View style={[styles.row, { borderBottomColor: divColor }]}>
                <Text style={[styles.rowLabel, { color: subColor }]}>Açıklama</Text>
                <TextInput
                  style={[styles.inlineInput, { backgroundColor: inputBg, borderColor, color: textColor }]}
                  value={editState.note}
                  onChangeText={(v) => setEditState((s) => ({ ...s, note: v }))}
                  placeholder="Açıklama..."
                  placeholderTextColor={isDark ? "#475569" : "#94A3B8"}
                />
              </View>

              {/* Kategori */}
              <TouchableOpacity
                style={[styles.row, { borderBottomColor: divColor }]}
                onPress={() => setActivePicker("category")}
                activeOpacity={0.7}
              >
                <Text style={[styles.rowLabel, { color: subColor }]}>Kategori</Text>
                <View style={[styles.dropdownCell, { backgroundColor: inputBg, borderColor }]}>
                  <Text style={[styles.dropdownText, { color: editState.category ? textColor : (isDark ? "#475569" : "#94A3B8") }]}>
                    {editState.category || "Seçin..."}
                  </Text>
                  <Feather name="chevron-down" size={15} color={subColor} />
                </View>
              </TouchableOpacity>

              {/* Ödeme Yöntemi */}
              <TouchableOpacity
                style={[styles.row, { borderBottomColor: divColor }]}
                onPress={() => setActivePicker("paymentMethod")}
                activeOpacity={0.7}
              >
                <Text style={[styles.rowLabel, { color: subColor }]}>Ödeme Şekli</Text>
                <View style={[styles.dropdownCell, { backgroundColor: inputBg, borderColor }]}>
                  <Text style={[styles.dropdownText, { color: editState.paymentMethod ? textColor : (isDark ? "#475569" : "#94A3B8") }]}>
                    {editState.paymentMethod ? `${paymentIcon}  ${paymentLabel}` : "Seçin..."}
                  </Text>
                  <Feather name="chevron-down" size={15} color={subColor} />
                </View>
              </TouchableOpacity>

              {/* Kayıtlı Kart (only when card selected) */}
              {editState.paymentMethod === "card" && (
                <TouchableOpacity
                  style={[styles.row, { borderBottomColor: divColor }]}
                  onPress={() => setActivePicker("card")}
                  activeOpacity={0.7}
                >
                  <Text style={[styles.rowLabel, { color: subColor }]}>Kayıtlı Kart</Text>
                  <View style={[styles.dropdownCell, { backgroundColor: inputBg, borderColor }]}>
                    <Text style={[styles.dropdownText, { color: editState.bank ? textColor : (isDark ? "#475569" : "#94A3B8") }]}>
                      {editState.bank || (creditCards.length > 0 ? "Seçin..." : "Manuel girin...")}
                    </Text>
                    {creditCards.length > 0 && <Feather name="chevron-down" size={15} color={subColor} />}
                  </View>
                </TouchableOpacity>
              )}

              {/* Manuel kart girişi (card + no registered cards) */}
              {editState.paymentMethod === "card" && creditCards.length === 0 && (
                <View style={[styles.row, { borderBottomColor: divColor }]}>
                  <Text style={[styles.rowLabel, { color: subColor }]}>Kart Adı</Text>
                  <TextInput
                    style={[styles.inlineInput, { backgroundColor: inputBg, borderColor, color: textColor }]}
                    value={editState.bank}
                    onChangeText={(v) => setEditState((s) => ({ ...s, bank: v }))}
                    placeholder="ör. Bonus, World, Axess..."
                    placeholderTextColor={isDark ? "#475569" : "#94A3B8"}
                  />
                </View>
              )}

              {/* Tarih */}
              <View style={[styles.row, { borderBottomColor: "transparent" }]}>
                <Text style={[styles.rowLabel, { color: subColor }]}>Tarih</Text>
                <TextInput
                  style={[styles.inlineInput, { backgroundColor: inputBg, borderColor, color: textColor }]}
                  value={editState.date}
                  onChangeText={(v) => setEditState((s) => ({ ...s, date: v }))}
                  placeholder="YYYY-AA-GG"
                  placeholderTextColor={isDark ? "#475569" : "#94A3B8"}
                />
              </View>

            </ScrollView>

            {/* Action Buttons */}
            <View style={styles.actionRow}>
              <TouchableOpacity style={[styles.cancelBtn, { borderColor }]} onPress={handleDismiss} activeOpacity={0.8}>
                <Text style={[styles.cancelBtnText, { color: subColor }]}>İptal</Text>
              </TouchableOpacity>
              <TouchableOpacity style={styles.confirmBtnWrap} onPress={handleConfirm} activeOpacity={0.85}>
                <LinearGradient
                  colors={["#6366F1", "#8B5CF6"]}
                  start={{ x: 0, y: 0 }}
                  end={{ x: 1, y: 0 }}
                  style={styles.confirmBtn}
                >
                  <Feather name="check" size={16} color="#FFF" style={{ marginRight: 6 }} />
                  <Text style={styles.confirmBtnText}>Onayla</Text>
                </LinearGradient>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      </Modal>

      {/* Category Picker */}
      <Modal
        visible={activePicker === "category"}
        transparent
        animationType="slide"
        onRequestClose={() => setActivePicker(null)}
      >
        <View style={styles.overlay}>
          <View style={[styles.pickerSheet, { backgroundColor: bg }]}>
            <View style={styles.pickerHeader}>
              <Text style={[styles.pickerTitle, { color: textColor }]}>Kategori Seç</Text>
              <TouchableOpacity onPress={() => setActivePicker(null)}>
                <Feather name="x" size={20} color={subColor} />
              </TouchableOpacity>
            </View>
            <ScrollView>
              {categories.map((cat) => {
                const isSelected = editState.category === cat.label;
                return (
                  <TouchableOpacity
                    key={cat.label}
                    style={[styles.pickerItem, { borderBottomColor: divColor }]}
                    onPress={() => {
                      setEditState((s) => ({ ...s, category: cat.label }));
                      setActivePicker(null);
                    }}
                  >
                    <Text style={[styles.pickerItemIcon]}>{cat.icon}</Text>
                    <Text style={[styles.pickerItemLabel, { color: textColor, fontWeight: isSelected ? "700" : "400" }]}>
                      {cat.label}
                    </Text>
                    {isSelected && <Feather name="check" size={16} color="#6366F1" />}
                  </TouchableOpacity>
                );
              })}
            </ScrollView>
          </View>
        </View>
      </Modal>

      {/* Payment Method Picker */}
      <Modal
        visible={activePicker === "paymentMethod"}
        transparent
        animationType="slide"
        onRequestClose={() => setActivePicker(null)}
      >
        <View style={styles.overlay}>
          <View style={[styles.pickerSheet, { backgroundColor: bg }]}>
            <View style={styles.pickerHeader}>
              <Text style={[styles.pickerTitle, { color: textColor }]}>Ödeme Şekli</Text>
              <TouchableOpacity onPress={() => setActivePicker(null)}>
                <Feather name="x" size={20} color={subColor} />
              </TouchableOpacity>
            </View>
            {PAYMENT_OPTIONS.map((pm) => {
              const isSelected = editState.paymentMethod === pm.key;
              return (
                <TouchableOpacity
                  key={pm.key}
                  style={[styles.pickerItem, { borderBottomColor: divColor }]}
                  onPress={() => {
                    setEditState((s) => ({
                      ...s,
                      paymentMethod: pm.key,
                      bank: pm.key !== "card" ? "" : s.bank,
                    }));
                    setActivePicker(null);
                  }}
                >
                  <Text style={styles.pickerItemIcon}>{pm.icon}</Text>
                  <Text style={[styles.pickerItemLabel, { color: textColor, fontWeight: isSelected ? "700" : "400" }]}>
                    {pm.label}
                  </Text>
                  {isSelected && <Feather name="check" size={16} color="#6366F1" />}
                </TouchableOpacity>
              );
            })}
          </View>
        </View>
      </Modal>

      {/* Card Picker */}
      <Modal
        visible={activePicker === "card"}
        transparent
        animationType="slide"
        onRequestClose={() => setActivePicker(null)}
      >
        <View style={styles.overlay}>
          <View style={[styles.pickerSheet, { backgroundColor: bg }]}>
            <View style={styles.pickerHeader}>
              <Text style={[styles.pickerTitle, { color: textColor }]}>Kayıtlı Kart</Text>
              <TouchableOpacity onPress={() => setActivePicker(null)}>
                <Feather name="x" size={20} color={subColor} />
              </TouchableOpacity>
            </View>
            {/* None option */}
            <TouchableOpacity
              style={[styles.pickerItem, { borderBottomColor: divColor }]}
              onPress={() => { setEditState((s) => ({ ...s, bank: "" })); setActivePicker(null); }}
            >
              <Text style={styles.pickerItemIcon}>—</Text>
              <Text style={[styles.pickerItemLabel, { color: subColor }]}>Belirtilmedi</Text>
              {editState.bank === "" && <Feather name="check" size={16} color="#6366F1" />}
            </TouchableOpacity>
            {creditCards.map((card) => {
              const isSelected = editState.bank === card.bank;
              return (
                <TouchableOpacity
                  key={card.id}
                  style={[styles.pickerItem, { borderBottomColor: divColor }]}
                  onPress={() => { setEditState((s) => ({ ...s, bank: card.bank })); setActivePicker(null); }}
                >
                  <Text style={styles.pickerItemIcon}>💳</Text>
                  <View style={{ flex: 1 }}>
                    <Text style={[styles.pickerItemLabel, { color: textColor, fontWeight: isSelected ? "700" : "400" }]}>
                      {card.bank}
                    </Text>
                    {card.institution && (
                      <Text style={[styles.pickerItemSub, { color: subColor }]}>{card.institution}</Text>
                    )}
                  </View>
                  {isSelected && <Feather name="check" size={16} color="#6366F1" />}
                </TouchableOpacity>
              );
            })}
          </View>
        </View>
      </Modal>

      {/* Error Modal */}
      <Modal visible={state === "error"} transparent animationType="fade" onRequestClose={handleDismiss}>
        <View style={styles.overlay}>
          <View style={[styles.floatingCard, { backgroundColor: bg, alignItems: "center" }]}>
            <Text style={{ fontSize: 36, marginBottom: 12 }}>⚠️</Text>
            <Text style={[styles.cardTitle, { color: textColor }]}>Hata Oluştu</Text>
            <Text style={[styles.cardSub, { color: subColor, marginBottom: 20, textAlign: "center" }]}>
              {errorMsg}
            </Text>
            <TouchableOpacity style={[styles.confirmBtn, { backgroundColor: "#6366F1" }]} onPress={handleDismiss}>
              <Text style={styles.confirmBtnText}>Tamam</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>
    </>
  );
}

const styles = StyleSheet.create({
  fabWrapper: {
    position: "absolute",
    zIndex: 1000,
    alignItems: "center",
    justifyContent: "center",
    width: FAB_SIZE,
    height: FAB_SIZE,
  },
  pulseRing: {
    position: "absolute",
    width: FAB_SIZE + 20,
    height: FAB_SIZE + 20,
    borderRadius: (FAB_SIZE + 20) * 0.32,
    backgroundColor: "#FF3B30",
    alignSelf: "center",
  },
  fab: {
    width: FAB_SIZE,
    height: FAB_SIZE,
    borderRadius: FAB_SIZE * 0.32,
    alignItems: "center",
    justifyContent: "center",
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.35,
    shadowRadius: 10,
    elevation: 10,
  },
  overlay: {
    flex: 1,
    backgroundColor: "rgba(0,0,0,0.55)",
    justifyContent: "flex-end",
  },
  floatingCard: {
    margin: 32,
    alignSelf: "center",
    borderRadius: 20,
    padding: 32,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.25,
    shadowRadius: 16,
    elevation: 12,
  },
  cardTitle: { fontSize: 17, fontWeight: "700", marginBottom: 6 },
  cardSub: { fontSize: 14 },
  // Sheet (bottom-slide panel)
  sheet: {
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    maxHeight: "90%",
    shadowColor: "#000",
    shadowOffset: { width: 0, height: -4 },
    shadowOpacity: 0.2,
    shadowRadius: 12,
    elevation: 16,
  },
  sheetHeader: {
    paddingTop: 12,
    paddingHorizontal: 20,
    paddingBottom: 4,
  },
  sheetHandle: {
    width: 40,
    height: 4,
    borderRadius: 2,
    backgroundColor: "#CBD5E1",
    alignSelf: "center",
    marginBottom: 14,
  },
  headerRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: 12,
  },
  sheetTitle: { fontSize: 18, fontWeight: "700" },
  transcriptBox: {
    flexDirection: "row",
    alignItems: "flex-start",
    marginHorizontal: 16,
    marginBottom: 10,
    padding: 10,
    borderRadius: 10,
    borderWidth: 1,
  },
  transcriptText: { fontSize: 13, lineHeight: 18, flex: 1 },
  // Rows
  row: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderBottomWidth: 1,
    gap: 12,
  },
  rowLabel: { fontSize: 13, fontWeight: "600", minWidth: 90 },
  // Type toggle
  typeToggle: { flexDirection: "row", gap: 8, flex: 1, justifyContent: "flex-end" },
  typeBtn: {
    paddingHorizontal: 18,
    paddingVertical: 7,
    borderRadius: 20,
    borderWidth: 1.5,
  },
  typeBtnText: { fontSize: 13, fontWeight: "600" },
  // Amount
  amountInput: {
    flexDirection: "row",
    alignItems: "center",
    flex: 1,
    borderRadius: 10,
    borderWidth: 1,
    paddingHorizontal: 12,
    height: 40,
  },
  amountCurrency: { fontSize: 15, fontWeight: "700", marginRight: 6 },
  amountText: { fontSize: 15, flex: 1 },
  // Inline text input
  inlineInput: {
    flex: 1,
    borderRadius: 10,
    borderWidth: 1,
    paddingHorizontal: 12,
    paddingVertical: 8,
    fontSize: 14,
    height: 40,
  },
  // Dropdown cell
  dropdownCell: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    flex: 1,
    borderRadius: 10,
    borderWidth: 1,
    paddingHorizontal: 12,
    paddingVertical: 9,
    height: 40,
  },
  dropdownText: { fontSize: 14, flex: 1 },
  // Action buttons
  actionRow: {
    flexDirection: "row",
    gap: 12,
    paddingHorizontal: 20,
    paddingTop: 14,
    paddingBottom: Platform.OS === "ios" ? 34 : 20,
    borderTopWidth: 1,
    borderTopColor: "rgba(148,163,184,0.15)",
  },
  cancelBtn: {
    flex: 1,
    borderWidth: 1,
    borderRadius: 14,
    paddingVertical: 13,
    alignItems: "center",
    justifyContent: "center",
  },
  cancelBtnText: { fontSize: 15, fontWeight: "600" },
  confirmBtnWrap: { flex: 2 },
  confirmBtn: {
    flexDirection: "row",
    borderRadius: 14,
    paddingVertical: 13,
    alignItems: "center",
    justifyContent: "center",
  },
  confirmBtnText: { color: "#FFF", fontSize: 15, fontWeight: "700" },
  // Picker sheet
  pickerSheet: {
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    maxHeight: "75%",
    paddingBottom: Platform.OS === "ios" ? 34 : 20,
  },
  pickerHeader: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    paddingHorizontal: 20,
    paddingTop: 20,
    paddingBottom: 12,
    borderBottomWidth: 1,
    borderBottomColor: "rgba(148,163,184,0.2)",
  },
  pickerTitle: { fontSize: 16, fontWeight: "700" },
  pickerItem: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 20,
    paddingVertical: 14,
    borderBottomWidth: 1,
    gap: 12,
  },
  pickerItemIcon: { fontSize: 20, width: 28, textAlign: "center" },
  pickerItemLabel: { fontSize: 15, flex: 1 },
  pickerItemSub: { fontSize: 12, marginTop: 1 },
});
