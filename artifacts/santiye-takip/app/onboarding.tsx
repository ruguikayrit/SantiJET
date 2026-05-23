import { Feather } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import React, { useEffect, useState } from "react";
import {
  Image,
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

import { SantijetLogo } from "@/components/SantijetLogo";
import { useApp } from "@/context/AppContext";

const ROLE_COLORS: Record<string, string> = {
  "isveren": "#7c3aed", "proje-muduru": "#e85d04",
  "santiye-sefi": "#dc2626", "saha-muhendisi": "#16a34a",
  "teknik-ofis-muhendisi": "#0ea5e9", "isg-birimi": "#f59e0b",
  "taseron": "#64748b", "satin-alma-birimi": "#0891b2",
  "muhasebe-birimi": "#059669", "ik-birimi": "#8b5cf6",
  "diger-kullanicilar": "#94a3b8",
};

type Step = "welcome" | "email-form" | "workspace-choice" | "pin-prompt";
type AuthMethod = "google" | "apple" | "email";

export default function OnboardingScreen() {
  const insets = useSafeAreaInsets();
  const router = useRouter();
  const { appUsers, roles, addAppUser, login, setWorkspace, workspaceInfo } = useApp();

  const [step, setStep] = useState<Step>("welcome");
  const [authMethod, setAuthMethod] = useState<AuthMethod>("email");

  // Email form state
  const [uName, setUName] = useState("");
  const [uEmail, setUEmail] = useState("");
  const [uRoleId, setURoleId] = useState(roles[0]?.id ?? "santiye-sefi");
  const [uPin, setUPin] = useState("");
  const [formError, setFormError] = useState("");

  // PIN prompt state (for existing users)
  const [pinUserId, setPinUserId] = useState<string | null>(null);
  const [pinInput, setPinInput] = useState("");
  const [pinError, setPinError] = useState(false);

  // Pending login after addAppUser
  const [pendingLoginName, setPendingLoginName] = useState<string | null>(null);
  const [pendingWorkspace, setPendingWorkspace] = useState<"local" | "team" | null>(null);

  // After addAppUser, find the new user and login
  useEffect(() => {
    if (!pendingLoginName) return;
    const user = appUsers.find((u) => u.name === pendingLoginName);
    if (!user) return;
    login(user.id);
    setPendingLoginName(null);
    if (pendingWorkspace === "local") {
      setPendingWorkspace(null);
    } else if (pendingWorkspace === "team") {
      setPendingWorkspace(null);
      router.replace("/workspace-setup" as any);
    }
  }, [appUsers, pendingLoginName]);

  function getRoleColor(roleId: string) {
    return ROLE_COLORS[roleId] ?? "#6b7280";
  }
  function getRoleName(roleId: string) {
    return roles.find((r) => r.id === roleId)?.name ?? roleId;
  }

  function handleAuthMethod(method: AuthMethod) {
    setAuthMethod(method);
    setStep("email-form");
  }

  function handleExistingUser(userId: string) {
    const user = appUsers.find((u) => u.id === userId);
    if (!user) return;
    if (user.pin) {
      setPinUserId(userId);
      setPinInput("");
      setPinError(false);
      setStep("pin-prompt");
    } else {
      login(userId);
    }
  }

  function handlePinConfirm() {
    const user = appUsers.find((u) => u.id === pinUserId);
    if (!user) return;
    if (pinInput === user.pin) {
      login(user.id);
    } else {
      setPinError(true);
      setPinInput("");
    }
  }

  function handleEmailSubmit() {
    if (!uName.trim()) {
      setFormError("Adınızı girin");
      return;
    }
    setFormError("");
    addAppUser({
      name: uName.trim(),
      roleId: uRoleId,
      pin: uPin.length === 4 ? uPin : "",
      profession: "",
      phone: uEmail.trim(),
      address: "",
      company: "",
    });
    setPendingLoginName(uName.trim());

    // If no workspace yet, go to workspace choice; else login will trigger auto-redirect
    if (!workspaceInfo) {
      setStep("workspace-choice");
    }
  }

  function handleBireysel() {
    setWorkspace({ id: "local", company_name: "Yerel", invite_code: "", api_url: "" });
    setPendingWorkspace("local");
  }

  function handleEkip() {
    setPendingWorkspace("team");
    // pendingLoginName still set, useEffect will pick it up
    router.replace("/workspace-setup" as any);
  }

  const hasExistingUsers = appUsers.length > 0;

  // ── PIN Prompt Step ─────────────────────────────────────────────
  if (step === "pin-prompt") {
    const pinUser = appUsers.find((u) => u.id === pinUserId);
    const rColor = getRoleColor(pinUser?.roleId ?? "");
    return (
      <KeyboardAvoidingView
        style={styles.root}
        behavior={Platform.OS === "ios" ? "padding" : "height"}
      >
        <View style={[styles.root, { paddingTop: insets.top + 16, paddingBottom: insets.bottom + 24 }]}>
          <TouchableOpacity style={styles.backBtn} onPress={() => setStep("welcome")}>
            <Feather name="arrow-left" size={20} color="#94a3b8" />
            <Text style={styles.backText}>Geri</Text>
          </TouchableOpacity>

          <View style={styles.pinHero}>
            <View style={[styles.pinAvatar, { backgroundColor: rColor }]}>
              <Text style={styles.pinAvatarText}>
                {pinUser?.name.charAt(0).toUpperCase() ?? "?"}
              </Text>
            </View>
            <Text style={styles.pinName}>{pinUser?.name}</Text>
            <Text style={styles.pinRole}>{getRoleName(pinUser?.roleId ?? "")}</Text>
          </View>

          <View style={styles.pinBody}>
            <Text style={styles.pinLabel}>PIN Kodunuzu Girin</Text>
            <TextInput
              style={[styles.pinInput, pinError && { borderColor: "#dc2626" }]}
              value={pinInput}
              onChangeText={(v) => { if (v.length <= 4 && /^\d*$/.test(v)) { setPinInput(v); setPinError(false); } }}
              keyboardType="number-pad"
              secureTextEntry
              maxLength={4}
              placeholder="● ● ● ●"
              placeholderTextColor="#334155"
              autoFocus
            />
            {pinError && (
              <Text style={styles.pinErrorText}>Yanlış PIN. Tekrar deneyin.</Text>
            )}
            <TouchableOpacity
              style={[styles.primaryBtn, { opacity: pinInput.length === 4 ? 1 : 0.5 }]}
              onPress={handlePinConfirm}
              disabled={pinInput.length !== 4}
              activeOpacity={0.85}
            >
              <Text style={styles.primaryBtnText}>Giriş Yap</Text>
            </TouchableOpacity>
          </View>
        </View>
      </KeyboardAvoidingView>
    );
  }

  // ── Workspace Choice Step ────────────────────────────────────────
  if (step === "workspace-choice") {
    return (
      <View style={[styles.root, { paddingTop: insets.top + 20, paddingBottom: insets.bottom + 24 }]}>
        <View style={styles.choiceHeader}>
          <SantijetLogo iconHeight={32} />
          <Text style={styles.choiceTitle}>Nasıl Kullanmak İstersiniz?</Text>
          <Text style={styles.choiceSub}>
            İstediğiniz zaman diğer seçeneğe geçebilirsiniz
          </Text>
        </View>

        <View style={styles.choiceCards}>
          <TouchableOpacity style={styles.choiceCard} activeOpacity={0.85} onPress={handleBireysel}>
            <View style={[styles.choiceIcon, { backgroundColor: "#3b82f620" }]}>
              <Feather name="user" size={32} color="#3b82f6" />
            </View>
            <Text style={styles.choiceCardTitle}>Bireysel Kullan</Text>
            <Text style={styles.choiceCardDesc}>
              Kendi şantiyeni tek başına yönet. İnternet bağlantısı gerekmez, veriler cihazında saklanır.
            </Text>
            <View style={styles.choiceCardBadge}>
              <Feather name="zap" size={12} color="#3b82f6" />
              <Text style={[styles.choiceCardBadgeText, { color: "#3b82f6" }]}>Hemen Başla</Text>
            </View>
          </TouchableOpacity>

          <TouchableOpacity style={styles.choiceCard} activeOpacity={0.85} onPress={handleEkip}>
            <View style={[styles.choiceIcon, { backgroundColor: "#e85d0420" }]}>
              <Feather name="users" size={32} color="#e85d04" />
            </View>
            <Text style={styles.choiceCardTitle}>Ekip ile Kullan</Text>
            <Text style={styles.choiceCardDesc}>
              Şirket kodu ile ekibine katıl ya da kendi ekibini oluştur. Veriler bulutta senkronize edilir.
            </Text>
            <View style={styles.choiceCardBadge}>
              <Feather name="cloud" size={12} color="#e85d04" />
              <Text style={[styles.choiceCardBadgeText, { color: "#e85d04" }]}>Şirket Kodu Gir</Text>
            </View>
          </TouchableOpacity>
        </View>
      </View>
    );
  }

  // ── Email / Profile Form Step ────────────────────────────────────
  if (step === "email-form") {
    const methodLabel = authMethod === "google" ? "Google" : authMethod === "apple" ? "Apple" : "E-posta";
    const methodColor = authMethod === "google" ? "#db4437" : authMethod === "apple" ? "#555" : "#e85d04";

    return (
      <KeyboardAvoidingView
        style={styles.root}
        behavior={Platform.OS === "ios" ? "padding" : "height"}
      >
        <ScrollView
          contentContainerStyle={[styles.formScroll, { paddingTop: insets.top + 16, paddingBottom: insets.bottom + 40 }]}
          keyboardShouldPersistTaps="handled"
          showsVerticalScrollIndicator={false}
        >
          <TouchableOpacity style={styles.backBtn} onPress={() => setStep("welcome")}>
            <Feather name="arrow-left" size={20} color="#94a3b8" />
            <Text style={styles.backText}>Geri</Text>
          </TouchableOpacity>

          <View style={styles.formHeader}>
            <View style={[styles.formMethodBadge, { backgroundColor: methodColor + "20", borderColor: methodColor + "40" }]}>
              <Feather
                name={authMethod === "google" ? "globe" : authMethod === "apple" ? "smartphone" : "mail"}
                size={14}
                color={methodColor}
              />
              <Text style={[styles.formMethodText, { color: methodColor }]}>{methodLabel} ile Devam</Text>
            </View>
            <Text style={styles.formTitle}>Profilinizi Oluşturun</Text>
            <Text style={styles.formSubtitle}>Bu bilgiler ekibinizdeki kişilere görünecektir</Text>
          </View>

          <View style={styles.formBody}>
            <Text style={styles.fieldLabel}>Ad Soyad</Text>
            <TextInput
              style={[styles.fieldInput, formError ? { borderColor: "#dc2626" } : {}]}
              value={uName}
              onChangeText={(v) => { setUName(v); setFormError(""); }}
              placeholder="Örn: Ahmet Yılmaz"
              placeholderTextColor="#334155"
              autoCapitalize="words"
              autoFocus
            />
            {formError ? <Text style={styles.fieldError}>{formError}</Text> : null}

            <Text style={[styles.fieldLabel, { marginTop: 16 }]}>E-posta Adresi</Text>
            <TextInput
              style={styles.fieldInput}
              value={uEmail}
              onChangeText={setUEmail}
              placeholder="ornek@email.com"
              placeholderTextColor="#334155"
              keyboardType="email-address"
              autoCapitalize="none"
            />

            <Text style={[styles.fieldLabel, { marginTop: 16 }]}>Unvan / Rol</Text>
            <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginBottom: 4 }}>
              <View style={styles.rolePills}>
                {roles.map((r) => {
                  const rColor = getRoleColor(r.id);
                  const sel = uRoleId === r.id;
                  return (
                    <TouchableOpacity
                      key={r.id}
                      style={[styles.rolePill, { backgroundColor: sel ? rColor : rColor + "20", borderColor: rColor + "50" }]}
                      onPress={() => setURoleId(r.id)}
                      activeOpacity={0.8}
                    >
                      <Text style={[styles.rolePillText, { color: sel ? "#fff" : rColor }]}>
                        {r.name}
                      </Text>
                    </TouchableOpacity>
                  );
                })}
              </View>
            </ScrollView>

            <Text style={[styles.fieldLabel, { marginTop: 16 }]}>
              PIN Kodu <Text style={styles.fieldOptional}>(isteğe bağlı, 4 haneli)</Text>
            </Text>
            <TextInput
              style={styles.fieldInput}
              value={uPin}
              onChangeText={(v) => { if (v.length <= 4 && /^\d*$/.test(v)) setUPin(v); }}
              placeholder="Boş bırakılırsa şifresiz"
              placeholderTextColor="#334155"
              keyboardType="number-pad"
              secureTextEntry
              maxLength={4}
            />

            <TouchableOpacity
              style={[styles.primaryBtn, { marginTop: 24 }]}
              onPress={handleEmailSubmit}
              activeOpacity={0.85}
            >
              <Text style={styles.primaryBtnText}>Devam Et</Text>
              <Feather name="arrow-right" size={18} color="#fff" />
            </TouchableOpacity>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    );
  }

  // ── Welcome Step (default) ───────────────────────────────────────
  return (
    <ScrollView
      style={styles.root}
      contentContainerStyle={[styles.welcomeScroll, { paddingTop: insets.top + 20, paddingBottom: insets.bottom + 32 }]}
      showsVerticalScrollIndicator={false}
      keyboardShouldPersistTaps="handled"
    >
      {/* Logo + Tagline */}
      <View style={styles.hero}>
        <SantijetLogo iconHeight={56} />
        <Text style={styles.tagline}>İnşaat & Şantiye Yönetimi</Text>
        <Text style={styles.taglineSub}>Bireysel veya ekip olarak kullanın</Text>
      </View>

      {/* Auth Buttons */}
      <View style={styles.authSection}>
        {/* Google */}
        <TouchableOpacity
          style={styles.authBtn}
          activeOpacity={0.85}
          onPress={() => handleAuthMethod("google")}
        >
          <View style={[styles.authBtnIcon, { backgroundColor: "#fef2f2" }]}>
            <Text style={styles.authBtnIconText}>G</Text>
          </View>
          <Text style={styles.authBtnText}>Google ile Devam Et</Text>
          <Feather name="chevron-right" size={16} color="#64748b" />
        </TouchableOpacity>

        {/* Apple */}
        <TouchableOpacity
          style={styles.authBtn}
          activeOpacity={0.85}
          onPress={() => handleAuthMethod("apple")}
        >
          <View style={[styles.authBtnIcon, { backgroundColor: "#f8fafc" }]}>
            <Feather name="smartphone" size={18} color="#1c1917" />
          </View>
          <Text style={styles.authBtnText}>Apple ile Devam Et</Text>
          <Feather name="chevron-right" size={16} color="#64748b" />
        </TouchableOpacity>

        {/* Email */}
        <TouchableOpacity
          style={[styles.authBtn, styles.authBtnPrimary]}
          activeOpacity={0.85}
          onPress={() => handleAuthMethod("email")}
        >
          <View style={[styles.authBtnIcon, { backgroundColor: "#e85d0420" }]}>
            <Feather name="mail" size={18} color="#e85d04" />
          </View>
          <Text style={[styles.authBtnText, styles.authBtnPrimaryText]}>E-posta ile Devam Et</Text>
          <Feather name="chevron-right" size={16} color="#e85d04" />
        </TouchableOpacity>
      </View>

      {/* Divider */}
      <View style={styles.divider}>
        <View style={styles.dividerLine} />
        <Text style={styles.dividerText}>veya</Text>
        <View style={styles.dividerLine} />
      </View>

      {/* Team Code */}
      <TouchableOpacity
        style={styles.teamCodeBtn}
        activeOpacity={0.85}
        onPress={() => router.push("/workspace-setup" as any)}
      >
        <Feather name="link" size={16} color="#0ea5e9" />
        <Text style={styles.teamCodeText}>Şirket Kodunuz Var mı? Buradan Girin</Text>
        <Feather name="chevron-right" size={14} color="#0ea5e9" />
      </TouchableOpacity>

      {/* Existing Users (returning user) */}
      {hasExistingUsers && (
        <View style={styles.existingSection}>
          <Text style={styles.existingSectionTitle}>Kayıtlı Hesaplar</Text>
          {appUsers.map((u) => {
            const rColor = getRoleColor(u.roleId);
            return (
              <TouchableOpacity
                key={u.id}
                style={styles.existingCard}
                activeOpacity={0.85}
                onPress={() => handleExistingUser(u.id)}
              >
                <View style={[styles.existingAvatar, { backgroundColor: rColor }]}>
                  <Text style={styles.existingAvatarText}>{u.name.charAt(0).toUpperCase()}</Text>
                </View>
                <View style={{ flex: 1 }}>
                  <Text style={styles.existingName}>{u.name}</Text>
                  <Text style={styles.existingRole}>{getRoleName(u.roleId)}</Text>
                </View>
                <View style={styles.existingAction}>
                  {u.pin ? (
                    <Feather name="lock" size={14} color="#64748b" />
                  ) : (
                    <Feather name="log-in" size={14} color="#22c55e" />
                  )}
                </View>
              </TouchableOpacity>
            );
          })}
        </View>
      )}

      {/* Footer */}
      <Text style={styles.footer}>
        Devam ederek Kullanım Koşullarını ve{"\n"}Gizlilik Politikasını kabul etmiş olursunuz
      </Text>
    </ScrollView>
  );
}

const BG = "#090d18";
const CARD = "#111827";
const BORDER = "rgba(255,255,255,0.07)";

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: BG },
  welcomeScroll: { paddingHorizontal: 24 },
  formScroll: { paddingHorizontal: 24 },

  // ── Back Button ───────────────────────────────────────────────────
  backBtn: { flexDirection: "row", alignItems: "center", gap: 8, marginBottom: 24, alignSelf: "flex-start" },
  backText: { color: "#94a3b8", fontSize: 15, fontFamily: "Inter_500Medium" },

  // ── Hero ──────────────────────────────────────────────────────────
  hero: { alignItems: "center", paddingTop: 20, paddingBottom: 40, gap: 10 },
  tagline: { color: "#e2e8f0", fontSize: 18, fontFamily: "Inter_700Bold", textAlign: "center" },
  taglineSub: { color: "#475569", fontSize: 14, fontFamily: "Inter_400Regular", textAlign: "center" },

  // ── Auth Buttons ──────────────────────────────────────────────────
  authSection: { gap: 12, marginBottom: 24 },
  authBtn: {
    flexDirection: "row", alignItems: "center", gap: 12,
    backgroundColor: CARD, borderRadius: 14, padding: 14,
    borderWidth: 1, borderColor: BORDER,
  },
  authBtnPrimary: { borderColor: "#e85d0440" },
  authBtnIcon: { width: 38, height: 38, borderRadius: 10, justifyContent: "center", alignItems: "center" },
  authBtnIconText: { fontSize: 20, fontFamily: "Inter_700Bold", color: "#db4437" },
  authBtnText: { flex: 1, color: "#cbd5e1", fontSize: 15, fontFamily: "Inter_600SemiBold" },
  authBtnPrimaryText: { color: "#f1f5f9" },

  // ── Divider ───────────────────────────────────────────────────────
  divider: { flexDirection: "row", alignItems: "center", gap: 12, marginBottom: 16 },
  dividerLine: { flex: 1, height: 1, backgroundColor: BORDER },
  dividerText: { color: "#475569", fontSize: 13, fontFamily: "Inter_400Regular" },

  // ── Team Code ─────────────────────────────────────────────────────
  teamCodeBtn: {
    flexDirection: "row", alignItems: "center", justifyContent: "center", gap: 8,
    padding: 14, borderRadius: 14, backgroundColor: "#0ea5e910",
    borderWidth: 1, borderColor: "#0ea5e930", marginBottom: 32,
  },
  teamCodeText: { color: "#0ea5e9", fontSize: 14, fontFamily: "Inter_600SemiBold" },

  // ── Existing Users ────────────────────────────────────────────────
  existingSection: { gap: 10, marginBottom: 32 },
  existingSectionTitle: {
    color: "#64748b", fontSize: 11, fontFamily: "Inter_700Bold",
    letterSpacing: 1.5, textTransform: "uppercase",
  },
  existingCard: {
    flexDirection: "row", alignItems: "center", gap: 12,
    backgroundColor: CARD, borderRadius: 12, padding: 12,
    borderWidth: 1, borderColor: BORDER,
  },
  existingAvatar: { width: 40, height: 40, borderRadius: 20, justifyContent: "center", alignItems: "center" },
  existingAvatarText: { color: "#fff", fontSize: 18, fontFamily: "Inter_700Bold" },
  existingName: { color: "#f1f5f9", fontSize: 14, fontFamily: "Inter_600SemiBold" },
  existingRole: { color: "#64748b", fontSize: 12, fontFamily: "Inter_400Regular", marginTop: 2 },
  existingAction: {
    width: 32, height: 32, borderRadius: 16,
    backgroundColor: "rgba(255,255,255,0.05)", justifyContent: "center", alignItems: "center",
  },

  // ── Footer ────────────────────────────────────────────────────────
  footer: {
    color: "#334155", fontSize: 11, fontFamily: "Inter_400Regular",
    textAlign: "center", lineHeight: 16,
  },

  // ── Form Step ─────────────────────────────────────────────────────
  formHeader: { gap: 8, marginBottom: 28 },
  formMethodBadge: {
    flexDirection: "row", alignItems: "center", gap: 6, alignSelf: "flex-start",
    paddingHorizontal: 10, paddingVertical: 5, borderRadius: 999, borderWidth: 1,
  },
  formMethodText: { fontSize: 12, fontFamily: "Inter_600SemiBold" },
  formTitle: { color: "#f1f5f9", fontSize: 24, fontFamily: "Inter_700Bold" },
  formSubtitle: { color: "#64748b", fontSize: 14, fontFamily: "Inter_400Regular" },
  formBody: { gap: 4 },
  fieldLabel: { color: "#94a3b8", fontSize: 13, fontFamily: "Inter_600SemiBold", marginBottom: 6 },
  fieldOptional: { color: "#475569", fontFamily: "Inter_400Regular" },
  fieldInput: {
    backgroundColor: CARD, borderRadius: 12, padding: 14,
    color: "#f1f5f9", fontSize: 15, fontFamily: "Inter_400Regular",
    borderWidth: 1, borderColor: BORDER,
  },
  fieldError: { color: "#dc2626", fontSize: 12, fontFamily: "Inter_500Medium", marginTop: 4 },
  rolePills: { flexDirection: "row", gap: 8, paddingVertical: 4 },
  rolePill: { paddingHorizontal: 12, paddingVertical: 7, borderRadius: 999, borderWidth: 1 },
  rolePillText: { fontSize: 13, fontFamily: "Inter_600SemiBold" },

  // ── Primary Button ────────────────────────────────────────────────
  primaryBtn: {
    flexDirection: "row", alignItems: "center", justifyContent: "center", gap: 8,
    backgroundColor: "#e85d04", borderRadius: 14, paddingVertical: 16,
  },
  primaryBtnText: { color: "#fff", fontSize: 16, fontFamily: "Inter_700Bold" },

  // ── PIN Prompt ─────────────────────────────────────────────────────
  pinHero: { flex: 1, alignItems: "center", justifyContent: "center", gap: 12 },
  pinAvatar: { width: 72, height: 72, borderRadius: 36, justifyContent: "center", alignItems: "center" },
  pinAvatarText: { color: "#fff", fontSize: 30, fontFamily: "Inter_700Bold" },
  pinName: { color: "#f1f5f9", fontSize: 22, fontFamily: "Inter_700Bold" },
  pinRole: { color: "#64748b", fontSize: 14, fontFamily: "Inter_400Regular" },
  pinBody: { paddingHorizontal: 24, paddingBottom: 24, gap: 12 },
  pinLabel: { color: "#94a3b8", fontSize: 14, fontFamily: "Inter_600SemiBold", textAlign: "center" },
  pinInput: {
    backgroundColor: CARD, borderRadius: 14, padding: 16, textAlign: "center",
    color: "#f1f5f9", fontSize: 28, letterSpacing: 12,
    borderWidth: 1, borderColor: BORDER, fontFamily: "Inter_700Bold",
  },
  pinErrorText: { color: "#dc2626", fontSize: 13, fontFamily: "Inter_500Medium", textAlign: "center" },

  // ── Workspace Choice Step ──────────────────────────────────────────
  choiceHeader: { alignItems: "center", paddingHorizontal: 24, marginBottom: 32, gap: 12 },
  choiceTitle: { color: "#f1f5f9", fontSize: 22, fontFamily: "Inter_700Bold", textAlign: "center" },
  choiceSub: { color: "#64748b", fontSize: 14, fontFamily: "Inter_400Regular", textAlign: "center" },
  choiceCards: { paddingHorizontal: 20, gap: 16 },
  choiceCard: {
    backgroundColor: CARD, borderRadius: 20, padding: 24,
    borderWidth: 1, borderColor: BORDER, gap: 12,
  },
  choiceIcon: { width: 60, height: 60, borderRadius: 30, justifyContent: "center", alignItems: "center" },
  choiceCardTitle: { color: "#f1f5f9", fontSize: 20, fontFamily: "Inter_700Bold" },
  choiceCardDesc: { color: "#94a3b8", fontSize: 14, fontFamily: "Inter_400Regular", lineHeight: 20 },
  choiceCardBadge: {
    flexDirection: "row", alignItems: "center", gap: 6, alignSelf: "flex-start",
    paddingHorizontal: 10, paddingVertical: 5, borderRadius: 999,
    backgroundColor: "rgba(255,255,255,0.05)",
  },
  choiceCardBadgeText: { fontSize: 13, fontFamily: "Inter_600SemiBold" },
});
