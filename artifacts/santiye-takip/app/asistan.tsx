import AsyncStorage from "@react-native-async-storage/async-storage";
import { Feather } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import React, { useEffect, useRef, useState } from "react";
import {
  ActivityIndicator,
  Alert,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import { useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";
import { buildAiSnapshot, getSuggestedQuestions } from "@/utils/aiSnapshot";

interface ChatMessage {
  id: string;
  role: "user" | "assistant";
  content: string;
  ts: number;
}

const STORAGE_KEY = "santijet_ai_chat_v1";
const MAX_STORED = 40;

function newId() {
  return Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
}

function safeBack(router: ReturnType<typeof useRouter>) {
  if (router.canGoBack()) router.back();
  else router.replace("/" as any);
}

export default function AsistanScreen() {
  const colors = useColors();
  const router = useRouter();
  const app = useApp();
  const insets = useSafeAreaInsets();
  const topPad = Platform.OS === "web" ? 16 : insets.top;

  const { workspaceInfo, currentRole } = app;

  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [historyLoaded, setHistoryLoaded] = useState(false);

  const scrollRef = useRef<ScrollView>(null);

  const cloudReady =
    workspaceInfo && workspaceInfo.id !== "local" && !!workspaceInfo.auth_token;

  useEffect(() => {
    AsyncStorage.getItem(STORAGE_KEY)
      .then((raw) => {
        if (raw) {
          try {
            const parsed = JSON.parse(raw);
            if (Array.isArray(parsed)) setMessages(parsed.slice(-MAX_STORED));
          } catch {}
        }
      })
      .finally(() => setHistoryLoaded(true));
  }, []);

  useEffect(() => {
    if (!historyLoaded) return;
    AsyncStorage.setItem(
      STORAGE_KEY,
      JSON.stringify(messages.slice(-MAX_STORED))
    ).catch(() => {});
  }, [messages, historyLoaded]);

  useEffect(() => {
    setTimeout(() => scrollRef.current?.scrollToEnd({ animated: true }), 60);
  }, [messages, loading]);

  const suggested = getSuggestedQuestions(app);

  async function send(text: string) {
    const trimmed = text.trim();
    if (!trimmed || loading) return;

    if (!cloudReady) {
      setError(
        "Yapay zeka için önce Çalışma Alanı bağlantısı gerek. Ana sayfadan bağlanın."
      );
      return;
    }

    setError(null);
    setInput("");

    const userMsg: ChatMessage = {
      id: newId(),
      role: "user",
      content: trimmed,
      ts: Date.now(),
    };
    const next = [...messages, userMsg];
    setMessages(next);
    setLoading(true);

    try {
      const snapshot = buildAiSnapshot(app, currentRole);
      const history = next
        .slice(-10)
        .filter((m) => m.id !== userMsg.id)
        .map((m) => ({ role: m.role, content: m.content }));

      const res = await fetch(
        `${workspaceInfo!.api_url}/api/workspaces/${workspaceInfo!.invite_code}/ask`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${workspaceInfo!.auth_token}`,
          },
          body: JSON.stringify({ question: trimmed, snapshot, history }),
        }
      );
      const json = await res.json().catch(() => ({} as any));
      if (!res.ok) {
        setError(json?.error || "Cevap alınamadı.");
        setMessages((prev) => prev.filter((m) => m.id !== userMsg.id));
      } else {
        const answer =
          typeof json.answer === "string" && json.answer.trim()
            ? json.answer.trim()
            : "Boş cevap geldi.";
        setMessages((prev) => [
          ...prev,
          { id: newId(), role: "assistant", content: answer, ts: Date.now() },
        ]);
      }
    } catch (e: any) {
      setError(e?.message || "Bağlantı hatası.");
      setMessages((prev) => prev.filter((m) => m.id !== userMsg.id));
    } finally {
      setLoading(false);
    }
  }

  function clearChat() {
    if (messages.length === 0) return;
    const doClear = () => {
      setMessages([]);
      setError(null);
    };
    if (Platform.OS === "web") {
      doClear();
    } else {
      Alert.alert(
        "Sohbeti Temizle",
        "Tüm mesajlar silinecek. Devam edilsin mi?",
        [
          { text: "Vazgeç", style: "cancel" },
          { text: "Sil", style: "destructive", onPress: doClear },
        ]
      );
    }
  }

  return (
    <KeyboardAvoidingView
      style={[styles.root, { backgroundColor: colors.background }]}
      behavior={Platform.OS === "ios" ? "padding" : undefined}
      keyboardVerticalOffset={Platform.OS === "ios" ? 0 : 0}
    >
      <View
        style={[
          styles.header,
          { backgroundColor: colors.secondary, paddingTop: topPad + 12 },
        ]}
      >
        <TouchableOpacity
          onPress={() => safeBack(router)}
          style={styles.iconBtn}
          accessibilityLabel="Geri"
        >
          <Feather name="arrow-left" size={22} color={colors.secondaryForeground} />
        </TouchableOpacity>
        <View style={styles.headerCenter}>
          <View style={styles.headerTitleRow}>
            <View style={[styles.aiDot, { backgroundColor: colors.primary }]}>
              <Feather name="cpu" size={12} color={colors.primaryForeground} />
            </View>
            <Text style={[styles.headerTitle, { color: colors.secondaryForeground }]}>
              ŞantiJET Asistan
            </Text>
          </View>
          <Text style={[styles.headerSub, { color: colors.secondaryForeground, opacity: 0.75 }]}>
            Geçmiş kayıtlardan sorularına cevap verir
          </Text>
        </View>
        <TouchableOpacity
          onPress={clearChat}
          style={styles.iconBtn}
          accessibilityLabel="Sohbeti temizle"
          disabled={messages.length === 0}
        >
          <Feather
            name="trash-2"
            size={20}
            color={colors.secondaryForeground}
            style={{ opacity: messages.length === 0 ? 0.35 : 1 }}
          />
        </TouchableOpacity>
      </View>

      <ScrollView
        ref={scrollRef}
        style={{ flex: 1 }}
        contentContainerStyle={[
          styles.scroll,
          { paddingBottom: insets.bottom + 12 },
        ]}
        keyboardShouldPersistTaps="handled"
      >
        {!cloudReady && (
          <View style={[styles.warnCard, { backgroundColor: colors.muted, borderColor: colors.warning + "60" }]}>
            <Feather name="cloud-off" size={16} color={colors.warning} />
            <Text style={[styles.warnText, { color: colors.foreground }]}>
              Yapay zeka, ekibin verisini bulutta işler. Önce Ana Sayfadan
              bir Çalışma Alanına bağlanmanız gerekiyor.
            </Text>
          </View>
        )}

        {messages.length === 0 ? (
          <View style={styles.empty}>
            <View style={[styles.emptyIcon, { backgroundColor: colors.primary + "20" }]}>
              <Feather name="message-circle" size={28} color={colors.primary} />
            </View>
            <Text style={[styles.emptyTitle, { color: colors.foreground }]}>
              Şantiyene bir şey sor
            </Text>
            <Text style={[styles.emptySub, { color: colors.mutedForeground }]}>
              Tüm projeler, puantajlar, imalatlar, hakedişler ve raporlar
              üzerinden yanıt verir. Aşağıdaki örneklerden başlayabilirsin:
            </Text>

            <View style={styles.suggestList}>
              {suggested.map((q, i) => (
                <TouchableOpacity
                  key={i}
                  style={[
                    styles.suggestBtn,
                    { backgroundColor: colors.card, borderColor: colors.border },
                  ]}
                  onPress={() => send(q)}
                  activeOpacity={0.85}
                >
                  <Feather name="zap" size={13} color={colors.primary} />
                  <Text
                    style={[styles.suggestText, { color: colors.foreground }]}
                    numberOfLines={2}
                  >
                    {q}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
          </View>
        ) : (
          messages.map((m) => (
            <View
              key={m.id}
              style={[
                styles.bubbleRow,
                { justifyContent: m.role === "user" ? "flex-end" : "flex-start" },
              ]}
            >
              {m.role === "assistant" && (
                <View style={[styles.avatar, { backgroundColor: colors.primary }]}>
                  <Feather name="cpu" size={12} color={colors.primaryForeground} />
                </View>
              )}
              <View
                style={[
                  styles.bubble,
                  m.role === "user"
                    ? { backgroundColor: colors.primary, borderTopRightRadius: 4 }
                    : {
                        backgroundColor: colors.card,
                        borderTopLeftRadius: 4,
                        borderWidth: 1,
                        borderColor: colors.border,
                      },
                ]}
              >
                <Text
                  selectable
                  style={[
                    styles.bubbleText,
                    {
                      color:
                        m.role === "user"
                          ? colors.primaryForeground
                          : colors.foreground,
                    },
                  ]}
                >
                  {m.content}
                </Text>
              </View>
            </View>
          ))
        )}

        {loading && (
          <View style={[styles.bubbleRow, { justifyContent: "flex-start" }]}>
            <View style={[styles.avatar, { backgroundColor: colors.primary }]}>
              <Feather name="cpu" size={12} color={colors.primaryForeground} />
            </View>
            <View
              style={[
                styles.bubble,
                {
                  backgroundColor: colors.card,
                  borderTopLeftRadius: 4,
                  borderWidth: 1,
                  borderColor: colors.border,
                  flexDirection: "row",
                  alignItems: "center",
                  gap: 8,
                },
              ]}
            >
              <ActivityIndicator size="small" color={colors.primary} />
              <Text style={[styles.bubbleText, { color: colors.mutedForeground }]}>
                Düşünüyor...
              </Text>
            </View>
          </View>
        )}

        {error && (
          <View style={[styles.errorBox, { backgroundColor: colors.destructive + "15", borderColor: colors.destructive }]}>
            <Feather name="alert-circle" size={14} color={colors.destructive} />
            <Text style={[styles.errorText, { color: colors.destructive }]}>
              {error}
            </Text>
          </View>
        )}
      </ScrollView>

      <View
        style={[
          styles.inputBar,
          {
            backgroundColor: colors.card,
            borderTopColor: colors.border,
            paddingBottom: insets.bottom > 0 ? insets.bottom : 10,
          },
        ]}
      >
        <TextInput
          style={[
            styles.input,
            { color: colors.foreground, backgroundColor: colors.muted },
          ]}
          placeholder="Bir soru sor... (örn: bu ay kaç m3 beton döküldü?)"
          placeholderTextColor={colors.mutedForeground}
          value={input}
          onChangeText={setInput}
          multiline
          maxLength={500}
          editable={!loading}
          onSubmitEditing={() => send(input)}
          blurOnSubmit
        />
        <TouchableOpacity
          style={[
            styles.sendBtn,
            {
              backgroundColor: input.trim() && !loading ? colors.primary : colors.muted,
            },
          ]}
          onPress={() => send(input)}
          disabled={!input.trim() || loading}
          activeOpacity={0.85}
        >
          {loading ? (
            <ActivityIndicator size="small" color={colors.primaryForeground} />
          ) : (
            <Feather
              name="send"
              size={18}
              color={
                input.trim()
                  ? colors.primaryForeground
                  : colors.mutedForeground
              }
            />
          )}
        </TouchableOpacity>
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  header: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 8,
    paddingBottom: 14,
    gap: 4,
  },
  iconBtn: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: "center",
    justifyContent: "center",
  },
  headerCenter: { flex: 1, alignItems: "center" },
  headerTitleRow: { flexDirection: "row", alignItems: "center", gap: 6 },
  aiDot: {
    width: 22,
    height: 22,
    borderRadius: 11,
    alignItems: "center",
    justifyContent: "center",
  },
  headerTitle: {
    fontSize: 17,
    fontWeight: "700",
    fontFamily: "Inter_700Bold",
  },
  headerSub: { fontSize: 11, marginTop: 2, fontFamily: "Inter_400Regular" },
  scroll: { padding: 14, gap: 10 },
  warnCard: {
    flexDirection: "row",
    gap: 10,
    padding: 12,
    borderRadius: 12,
    borderWidth: 1,
    alignItems: "flex-start",
    marginBottom: 8,
  },
  warnText: { flex: 1, fontSize: 13, lineHeight: 18, fontFamily: "Inter_400Regular" },
  empty: { paddingVertical: 24, alignItems: "center" },
  emptyIcon: {
    width: 64,
    height: 64,
    borderRadius: 32,
    alignItems: "center",
    justifyContent: "center",
    marginBottom: 14,
  },
  emptyTitle: {
    fontSize: 18,
    fontWeight: "700",
    fontFamily: "Inter_700Bold",
    marginBottom: 6,
  },
  emptySub: {
    fontSize: 13,
    lineHeight: 19,
    textAlign: "center",
    fontFamily: "Inter_400Regular",
    paddingHorizontal: 16,
    marginBottom: 18,
  },
  suggestList: { width: "100%", gap: 8 },
  suggestBtn: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
    padding: 12,
    borderRadius: 10,
    borderWidth: 1,
  },
  suggestText: {
    flex: 1,
    fontSize: 13,
    lineHeight: 18,
    fontFamily: "Inter_500Medium",
  },
  bubbleRow: {
    flexDirection: "row",
    alignItems: "flex-end",
    gap: 6,
    marginBottom: 4,
  },
  avatar: {
    width: 24,
    height: 24,
    borderRadius: 12,
    alignItems: "center",
    justifyContent: "center",
  },
  bubble: {
    maxWidth: "82%",
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderRadius: 16,
  },
  bubbleText: { fontSize: 14, lineHeight: 20, fontFamily: "Inter_400Regular" },
  errorBox: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    padding: 10,
    borderRadius: 10,
    borderWidth: 1,
    marginTop: 4,
  },
  errorText: { flex: 1, fontSize: 12, fontFamily: "Inter_500Medium" },
  inputBar: {
    flexDirection: "row",
    alignItems: "flex-end",
    gap: 8,
    paddingHorizontal: 12,
    paddingTop: 10,
    borderTopWidth: 1,
  },
  input: {
    flex: 1,
    minHeight: 42,
    maxHeight: 110,
    paddingHorizontal: 14,
    paddingVertical: 10,
    borderRadius: 22,
    fontSize: 14,
    fontFamily: "Inter_400Regular",
  },
  sendBtn: {
    width: 42,
    height: 42,
    borderRadius: 21,
    alignItems: "center",
    justifyContent: "center",
  },
});
