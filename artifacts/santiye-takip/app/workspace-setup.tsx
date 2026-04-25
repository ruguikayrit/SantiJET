import { Feather } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import React, { useState } from "react";
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

import { useColors } from "@/hooks/useColors";
import { WorkspaceInfo, saveWorkspace } from "@/utils/workspace";

type Tab = "create" | "join";

export default function WorkspaceSetupScreen() {
  const colors = useColors();
  const router = useRouter();
  const insets = useSafeAreaInsets();

  const defaultApiUrl = process.env.EXPO_PUBLIC_DOMAIN
    ? `https://${process.env.EXPO_PUBLIC_DOMAIN}/api-server`
    : "";

  const [tab, setTab] = useState<Tab>("create");
  const [companyName, setCompanyName] = useState("");
  const [joinCode, setJoinCode] = useState("");
  const [apiUrl, setApiUrl] = useState(defaultApiUrl);
  const [loading, setLoading] = useState(false);
  const [showAdvanced, setShowAdvanced] = useState(false);

  async function testConnection(url: string): Promise<boolean> {
    try {
      const res = await fetch(`${url}/api/healthz`, {
        signal: AbortSignal.timeout(5000),
      });
      return res.ok;
    } catch {
      return false;
    }
  }

  async function handleCreate() {
    if (!companyName.trim()) {
      Alert.alert("Hata", "Firma adını girin.");
      return;
    }
    setLoading(true);
    try {
      const baseUrl = apiUrl.trim().replace(/\/$/, "");
      const ok = await testConnection(baseUrl);
      if (!ok) {
        Alert.alert(
          "Bağlantı Hatası",
          "Sunucuya ulaşılamadı. Sunucu URL'sini kontrol edin.\n\n" + baseUrl
        );
        setLoading(false);
        return;
      }
      const res = await fetch(`${baseUrl}/api/workspaces`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ company_name: companyName.trim() }),
      });
      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        Alert.alert("Hata", (err as any).error ?? "Çalışma alanı oluşturulamadı.");
        setLoading(false);
        return;
      }
      const data = (await res.json()) as {
        id: string;
        invite_code: string;
        company_name: string;
      };
      const ws: WorkspaceInfo = { ...data, api_url: baseUrl };
      await saveWorkspace(ws);
      Alert.alert(
        "Çalışma Alanı Oluşturuldu!",
        `Davet Kodunuz:\n\n${data.invite_code}\n\nBu kodu ekibinizle paylaşın. Herkes bu kodla aynı verilere erişebilir.`,
        [{ text: "Tamam", onPress: () => router.replace("/") }]
      );
    } catch (e: any) {
      Alert.alert("Hata", e?.message ?? "Beklenmeyen hata.");
    } finally {
      setLoading(false);
    }
  }

  async function handleJoin() {
    const code = joinCode.trim().toUpperCase();
    if (!code || code.length < 4) {
      Alert.alert("Hata", "Geçerli bir davet kodu girin.");
      return;
    }
    setLoading(true);
    try {
      const baseUrl = apiUrl.trim().replace(/\/$/, "");
      const ok = await testConnection(baseUrl);
      if (!ok) {
        Alert.alert(
          "Bağlantı Hatası",
          "Sunucuya ulaşılamadı. Sunucu URL'sini kontrol edin.\n\n" + baseUrl
        );
        setLoading(false);
        return;
      }
      const res = await fetch(`${baseUrl}/api/workspaces/${code}`);
      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        Alert.alert("Hata", (err as any).error ?? "Davet kodu bulunamadı.");
        setLoading(false);
        return;
      }
      const data = (await res.json()) as {
        id: string;
        invite_code: string;
        company_name: string;
      };
      const ws: WorkspaceInfo = { ...data, api_url: baseUrl };
      await saveWorkspace(ws);
      Alert.alert(
        "Başarılı",
        `"${data.company_name}" çalışma alanına katıldınız.`,
        [{ text: "Tamam", onPress: () => router.replace("/") }]
      );
    } catch (e: any) {
      Alert.alert("Hata", e?.message ?? "Beklenmeyen hata.");
    } finally {
      setLoading(false);
    }
  }

  async function handleSkip() {
    const ws: WorkspaceInfo = {
      id: "local",
      invite_code: "LOCAL",
      company_name: "Yerel Kullanım",
      api_url: apiUrl.trim().replace(/\/$/, ""),
    };
    await saveWorkspace(ws);
    router.replace("/");
  }

  return (
    <KeyboardAvoidingView
      style={{ flex: 1 }}
      behavior={Platform.OS === "ios" ? "padding" : undefined}
    >
      <ScrollView
        style={[styles.root, { backgroundColor: colors.background }]}
        contentContainerStyle={{
          paddingTop: insets.top + 24,
          paddingBottom: insets.bottom + 40,
        }}
        keyboardShouldPersistTaps="handled"
      >
        {/* Hero */}
        <View style={styles.hero}>
          <View style={[styles.logo, { backgroundColor: "#e85d04" }]}>
            <Feather name="layers" size={32} color="#fff" />
          </View>
          <Text style={[styles.title, { color: colors.foreground }]}>
            Şantiye Takip
          </Text>
          <Text style={[styles.subtitle, { color: colors.mutedForeground }]}>
            Ekibinizle veri paylaşmak için bir çalışma alanı oluşturun veya
            mevcut birine katılın.
          </Text>
        </View>

        {/* Tabs */}
        <View style={[styles.tabs, { backgroundColor: colors.card }]}>
          {(["create", "join"] as Tab[]).map((t) => (
            <TouchableOpacity
              key={t}
              style={[
                styles.tab,
                tab === t && { backgroundColor: "#e85d04" },
              ]}
              onPress={() => setTab(t)}
            >
              <Text
                style={[
                  styles.tabText,
                  { color: tab === t ? "#fff" : colors.mutedForeground },
                ]}
              >
                {t === "create" ? "Yeni Oluştur" : "Kodla Katıl"}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        {/* Card */}
        <View style={[styles.card, { backgroundColor: colors.card }]}>
          {tab === "create" ? (
            <>
              <Text style={[styles.label, { color: colors.foreground }]}>
                Firma / Şantiye Adı
              </Text>
              <TextInput
                style={[
                  styles.input,
                  {
                    color: colors.foreground,
                    backgroundColor: colors.muted,
                    borderColor: colors.border,
                  },
                ]}
                value={companyName}
                onChangeText={setCompanyName}
                placeholder="Örn: ABC İnşaat A.Ş."
                placeholderTextColor={colors.mutedForeground}
                autoCapitalize="words"
              />
            </>
          ) : (
            <>
              <Text style={[styles.label, { color: colors.foreground }]}>
                Davet Kodu
              </Text>
              <TextInput
                style={[
                  styles.input,
                  styles.codeInput,
                  {
                    color: colors.foreground,
                    backgroundColor: colors.muted,
                    borderColor: colors.border,
                  },
                ]}
                value={joinCode}
                onChangeText={(v) => setJoinCode(v.toUpperCase())}
                placeholder="AB3X9Z"
                placeholderTextColor={colors.mutedForeground}
                autoCapitalize="characters"
                maxLength={8}
              />
            </>
          )}

          <TouchableOpacity
            style={[
              styles.primaryBtn,
              { backgroundColor: "#e85d04", opacity: loading ? 0.7 : 1 },
            ]}
            onPress={tab === "create" ? handleCreate : handleJoin}
            disabled={loading}
            activeOpacity={0.85}
          >
            {loading ? (
              <ActivityIndicator color="#fff" size="small" />
            ) : (
              <>
                <Feather
                  name={tab === "create" ? "plus-circle" : "log-in"}
                  size={16}
                  color="#fff"
                />
                <Text style={styles.primaryBtnText}>
                  {tab === "create" ? "Çalışma Alanı Oluştur" : "Katıl"}
                </Text>
              </>
            )}
          </TouchableOpacity>

          {/* Advanced */}
          <TouchableOpacity
            style={styles.advancedToggle}
            onPress={() => setShowAdvanced((v) => !v)}
          >
            <Feather
              name={showAdvanced ? "chevron-up" : "chevron-down"}
              size={13}
              color={colors.mutedForeground}
            />
            <Text style={[styles.advancedText, { color: colors.mutedForeground }]}>
              Sunucu Ayarları
            </Text>
          </TouchableOpacity>
          {showAdvanced && (
            <View>
              <Text
                style={[
                  styles.label,
                  { color: colors.foreground, marginTop: 8 },
                ]}
              >
                Sunucu URL
              </Text>
              <TextInput
                style={[
                  styles.input,
                  {
                    color: colors.foreground,
                    backgroundColor: colors.muted,
                    borderColor: colors.border,
                  },
                ]}
                value={apiUrl}
                onChangeText={setApiUrl}
                placeholder="https://..."
                placeholderTextColor={colors.mutedForeground}
                autoCapitalize="none"
                keyboardType="url"
              />
            </View>
          )}
        </View>

        {/* Skip */}
        <TouchableOpacity style={styles.skipBtn} onPress={handleSkip}>
          <Text style={[styles.skipText, { color: colors.mutedForeground }]}>
            Şimdilik Atla — Yalnızca Yerel Kullanım
          </Text>
        </TouchableOpacity>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  hero: {
    alignItems: "center",
    paddingHorizontal: 24,
    marginBottom: 28,
  },
  logo: {
    width: 72,
    height: 72,
    borderRadius: 20,
    alignItems: "center",
    justifyContent: "center",
    marginBottom: 14,
  },
  title: { fontSize: 26, fontFamily: "Inter_700Bold", marginBottom: 8 },
  subtitle: {
    fontSize: 14,
    fontFamily: "Inter_400Regular",
    textAlign: "center",
    lineHeight: 22,
  },
  tabs: {
    flexDirection: "row",
    marginHorizontal: 20,
    borderRadius: 12,
    padding: 4,
    gap: 4,
    marginBottom: 16,
  },
  tab: { flex: 1, paddingVertical: 10, borderRadius: 9, alignItems: "center" },
  tabText: { fontSize: 14, fontFamily: "Inter_600SemiBold" },
  card: { marginHorizontal: 20, borderRadius: 16, padding: 20, gap: 4 },
  label: {
    fontSize: 13,
    fontFamily: "Inter_600SemiBold",
    marginBottom: 6,
    marginTop: 4,
  },
  input: {
    borderRadius: 10,
    paddingHorizontal: 14,
    paddingVertical: 12,
    fontSize: 15,
    fontFamily: "Inter_400Regular",
    borderWidth: 1,
  },
  codeInput: {
    fontSize: 26,
    fontFamily: "Inter_700Bold",
    textAlign: "center",
    letterSpacing: 6,
  },
  primaryBtn: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 8,
    paddingVertical: 14,
    borderRadius: 12,
    marginTop: 14,
  },
  primaryBtnText: { color: "#fff", fontSize: 16, fontFamily: "Inter_700Bold" },
  advancedToggle: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    marginTop: 18,
    justifyContent: "center",
  },
  advancedText: { fontSize: 12, fontFamily: "Inter_500Medium" },
  skipBtn: { marginTop: 20, alignItems: "center", paddingVertical: 12 },
  skipText: { fontSize: 13, fontFamily: "Inter_400Regular" },
});
