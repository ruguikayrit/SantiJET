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

import { useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";
import { WorkspaceInfo } from "@/utils/workspace";

type Tab = "create" | "join";

export default function WorkspaceSetupScreen() {
  const colors = useColors();
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const { setWorkspace, pushToCloud, pullFromCloud } = useApp();

  const defaultApiUrl = process.env.EXPO_PUBLIC_DOMAIN
    ? `https://${process.env.EXPO_PUBLIC_DOMAIN}`
    : "";

  const [tab, setTab] = useState<Tab>("create");
  const [companyName, setCompanyName] = useState("");
  const [joinCode, setJoinCode] = useState("");
  const [createPassword, setCreatePassword] = useState("");
  const [joinPassword, setJoinPassword] = useState("");
  const [apiUrl, setApiUrl] = useState(defaultApiUrl);
  const [loading, setLoading] = useState(false);
  const [showAdvanced, setShowAdvanced] = useState(false);
  const [createdInfo, setCreatedInfo] = useState<WorkspaceInfo | null>(null);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  function notifyError(msg: string) {
    setErrorMsg(msg);
    if (Platform.OS !== "web") Alert.alert("Hata", msg);
  }

  function withTimeout<T>(p: Promise<T>, ms: number): Promise<T> {
    return new Promise<T>((resolve, reject) => {
      const t = setTimeout(() => reject(new Error("Sunucu yanıt vermedi (zaman aşımı).")), ms);
      p.then((v) => { clearTimeout(t); resolve(v); }, (e) => { clearTimeout(t); reject(e); });
    });
  }

  async function handleCreate() {
    setErrorMsg(null);
    if (!companyName.trim()) {
      notifyError("Firma adını girin.");
      return;
    }
    if (!createPassword || createPassword.length < 4) {
      notifyError("Şifre en az 4 karakter olmalı.");
      return;
    }
    setLoading(true);
    try {
      const baseUrl = apiUrl.trim().replace(/\/$/, "");
      let res: Response;
      try {
        res = await withTimeout(
          fetch(`${baseUrl}/api/workspaces`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ company_name: companyName.trim(), password: createPassword }),
          }),
          15000,
        );
      } catch (e: any) {
        notifyError(`Sunucuya ulaşılamadı (${e?.message ?? "bilinmeyen hata"}). URL: ${baseUrl}`);
        setLoading(false);
        return;
      }
      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        notifyError((err as any).error ?? `Çalışma alanı oluşturulamadı (HTTP ${res.status}).`);
        setLoading(false);
        return;
      }
      const data = (await res.json()) as {
        id: string;
        invite_code: string;
        company_name: string;
        revision: number;
        auth_token: string;
      };
      const ws: WorkspaceInfo = {
        id: data.id,
        invite_code: data.invite_code,
        company_name: data.company_name,
        api_url: baseUrl,
        revision: data.revision,
        auth_token: data.auth_token,
      };
      await setWorkspace(ws);
      try { await pushToCloud(); } catch {}
      setCreatedInfo(ws);
    } catch (e: any) {
      notifyError(e?.message ?? "Beklenmeyen hata.");
    } finally {
      setLoading(false);
    }
  }

  async function handleJoin() {
    setErrorMsg(null);
    const code = joinCode.trim().toUpperCase();
    if (!code || code.length < 4) {
      notifyError("Geçerli bir davet kodu girin.");
      return;
    }
    if (!joinPassword) {
      notifyError("Çalışma alanı şifresini girin.");
      return;
    }
    setLoading(true);
    try {
      const baseUrl = apiUrl.trim().replace(/\/$/, "");
      let res: Response;
      try {
        res = await withTimeout(
          fetch(`${baseUrl}/api/workspaces/${code}/join`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ password: joinPassword }),
          }),
          15000,
        );
      } catch (e: any) {
        notifyError(`Sunucuya ulaşılamadı (${e?.message ?? "bilinmeyen hata"}). URL: ${baseUrl}`);
        setLoading(false);
        return;
      }
      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        notifyError((err as any).error ?? "Davet kodu veya şifre hatalı.");
        setLoading(false);
        return;
      }
      const data = (await res.json()) as {
        id: string;
        invite_code: string;
        company_name: string;
        revision: number;
        auth_token: string;
      };
      const ws: WorkspaceInfo = {
        id: data.id,
        invite_code: data.invite_code,
        company_name: data.company_name,
        api_url: baseUrl,
        revision: data.revision,
        auth_token: data.auth_token,
      };
      await setWorkspace(ws);
      try { await pullFromCloud(); } catch {}
      router.replace("/");
    } catch (e: any) {
      notifyError(e?.message ?? "Beklenmeyen hata.");
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
    await setWorkspace(ws);
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
            ŞantiJET
          </Text>
          <Text style={[styles.subtitle, { color: colors.mutedForeground }]}>
            Ekibinizle veri paylaşmak için bir çalışma alanı oluşturun veya
            mevcut birine katılın.
          </Text>
        </View>

        {/* Success view after create */}
        {createdInfo && (
          <View style={[styles.card, { backgroundColor: colors.card, marginTop: 12 }]}>
            <View style={{ alignItems: "center", marginBottom: 12 }}>
              <View style={{ width: 56, height: 56, borderRadius: 28, backgroundColor: "#16a34a20", justifyContent: "center", alignItems: "center", marginBottom: 8 }}>
                <Feather name="check-circle" size={28} color="#16a34a" />
              </View>
              <Text style={[styles.label, { color: colors.foreground, fontSize: 17, marginBottom: 4 }]}>Çalışma Alanı Oluşturuldu!</Text>
              <Text style={[styles.subtitle, { color: colors.mutedForeground, marginBottom: 0 }]} numberOfLines={2}>
                {createdInfo.company_name}
              </Text>
            </View>
            <Text style={[styles.label, { color: colors.foreground, textAlign: "center", marginBottom: 6 }]}>
              Davet Kodunuz
            </Text>
            <View style={{ backgroundColor: "#e85d0420", borderColor: "#e85d04", borderWidth: 1, borderRadius: 12, paddingVertical: 16, marginBottom: 12 }}>
              <Text style={{ color: "#e85d04", fontFamily: "Inter_700Bold", fontSize: 32, textAlign: "center", letterSpacing: 6 }}>
                {createdInfo.invite_code}
              </Text>
            </View>
            <Text style={[styles.subtitle, { color: colors.mutedForeground, fontSize: 12, marginBottom: 12 }]}>
              Bu kodu ekibinizle paylaşın. Aynı kodu kullanan herkes verileri paylaşır.
            </Text>
            <TouchableOpacity
              style={[styles.primaryBtn, { backgroundColor: "#e85d04" }]}
              onPress={() => router.replace("/")}
              activeOpacity={0.85}
            >
              <Feather name="arrow-right" size={16} color="#fff" />
              <Text style={styles.primaryBtnText}>Devam Et</Text>
            </TouchableOpacity>
          </View>
        )}

        {/* Tabs + Form */}
        {!createdInfo && (
        <>
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
              <Text style={[styles.label, { color: colors.foreground, marginTop: 12 }]}>
                Çalışma Alanı Şifresi
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
                value={createPassword}
                onChangeText={setCreatePassword}
                placeholder="En az 4 karakter"
                placeholderTextColor={colors.mutedForeground}
                secureTextEntry
                autoCapitalize="none"
              />
              <Text style={[styles.subtitle, { color: colors.mutedForeground, fontSize: 12, marginTop: 6, marginBottom: 0 }]}>
                Bu şifreyi ekibinizle paylaşın. Davet kodu ile birlikte gerekecek.
              </Text>
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
                placeholder="AB3X9Z2K7M"
                placeholderTextColor={colors.mutedForeground}
                autoCapitalize="characters"
                maxLength={12}
              />
              <Text style={[styles.label, { color: colors.foreground, marginTop: 12 }]}>
                Çalışma Alanı Şifresi
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
                value={joinPassword}
                onChangeText={setJoinPassword}
                placeholder="Yöneticinizden alın"
                placeholderTextColor={colors.mutedForeground}
                secureTextEntry
                autoCapitalize="none"
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
          {errorMsg && (
            <View style={{ marginTop: 12, padding: 10, borderRadius: 8, backgroundColor: "#dc262620", borderWidth: 1, borderColor: "#dc2626" }}>
              <Text style={{ color: "#dc2626", fontSize: 12, fontFamily: "Inter_500Medium" }}>
                {errorMsg}
              </Text>
            </View>
          )}
        </View>
        </>
        )}

        {/* Skip */}
        {!createdInfo && (
        <TouchableOpacity style={styles.skipBtn} onPress={handleSkip}>
          <Text style={[styles.skipText, { color: colors.mutedForeground }]}>
            Şimdilik Atla — Yalnızca Yerel Kullanım
          </Text>
        </TouchableOpacity>
        )}
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
