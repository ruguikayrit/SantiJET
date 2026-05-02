import { Feather } from "@expo/vector-icons";
import * as Haptics from "expo-haptics";
import { LinearGradient } from "expo-linear-gradient";
import { useRouter } from "expo-router";
import React from "react";
import { ActivityIndicator, StyleSheet, Text, TouchableOpacity, View } from "react-native";
import { useTranslation } from "react-i18next";

import { useAuth } from "@/context/finans/AuthContext";
import { useColors } from "@/hooks/finans/useColors";
import { useSubscription } from "@/lib/finans/revenuecat";

const GOLD = "#F59E0B";
const GOLD_DIM = "#F59E0B22";
const GOLD_BORDER = "#F59E0B44";
const EMERALD = "#10B981";

function formatExpiry(dateStr: string | null | undefined): string | null {
  if (!dateStr) return null;
  try {
    const d = new Date(dateStr);
    return d.toLocaleDateString("tr-TR", { day: "numeric", month: "long", year: "numeric" });
  } catch {
    return null;
  }
}

export default function MembershipCard() {
  const colors = useColors();
  const router = useRouter();
  const { t } = useTranslation();
  const { isLoggedIn, user } = useAuth();
  const { isSubscribed, customerInfo, isLoading, isSupported } = useSubscription();

  const goToPricing = () => {
    Haptics.selectionAsync();
    router.push("/finans" as any);
  };

  const goToMembership = (mode: "login" | "register") => {
    Haptics.selectionAsync();
    router.push({ pathname: "/finans" as any, params: { mode } });
  };

  const s = StyleSheet.create({
    card: {
      marginHorizontal: 20,
      marginTop: 14,
      borderRadius: 18,
      overflow: "hidden" as const,
    },

    // ── Subscribed card ─────────────────────────────────────────────────────
    premCard: {
      backgroundColor: "#0B1E33",
      borderWidth: 1,
      borderColor: GOLD_BORDER,
      borderRadius: 18,
      padding: 18,
      gap: 14,
    },
    premTop: {
      flexDirection: "row" as const,
      alignItems: "center" as const,
      gap: 12,
    },
    premIconWrap: {
      width: 44,
      height: 44,
      borderRadius: 14,
      backgroundColor: GOLD_DIM,
      borderWidth: 1,
      borderColor: GOLD_BORDER,
      alignItems: "center" as const,
      justifyContent: "center" as const,
    },
    premInfo: { flex: 1 },
    premName: {
      fontSize: 15,
      fontWeight: "800" as const,
      color: GOLD,
      letterSpacing: 0.2,
    },
    premSub: {
      fontSize: 12,
      color: "rgba(255,255,255,0.55)",
      marginTop: 2,
    },
    premBadge: {
      backgroundColor: EMERALD + "22",
      borderRadius: 20,
      paddingHorizontal: 10,
      paddingVertical: 4,
      borderWidth: 1,
      borderColor: EMERALD + "55",
    },
    premBadgeText: {
      fontSize: 11,
      fontWeight: "700" as const,
      color: EMERALD,
    },
    premDivider: {
      height: 1,
      backgroundColor: "rgba(255,255,255,0.08)",
    },
    premBottom: {
      flexDirection: "row" as const,
      alignItems: "center" as const,
      justifyContent: "space-between" as const,
    },
    premExpiryLabel: {
      fontSize: 11,
      color: "rgba(255,255,255,0.4)",
    },
    premExpiryDate: {
      fontSize: 13,
      fontWeight: "700" as const,
      color: "rgba(255,255,255,0.85)",
      marginTop: 1,
    },
    premManageBtn: {
      flexDirection: "row" as const,
      alignItems: "center" as const,
      gap: 5,
      backgroundColor: GOLD_DIM,
      borderWidth: 1,
      borderColor: GOLD_BORDER,
      paddingHorizontal: 14,
      paddingVertical: 8,
      borderRadius: 10,
    },
    premManageBtnText: {
      fontSize: 12,
      fontWeight: "700" as const,
      color: GOLD,
    },

    // ── Upsell card (not subscribed) ─────────────────────────────────────────
    upsellInner: {
      padding: 18,
      gap: 14,
    },
    upsellTop: {
      flexDirection: "row" as const,
      alignItems: "center" as const,
      gap: 12,
    },
    upsellIconWrap: {
      width: 44,
      height: 44,
      borderRadius: 14,
      backgroundColor: GOLD_DIM,
      borderWidth: 1,
      borderColor: GOLD_BORDER,
      alignItems: "center" as const,
      justifyContent: "center" as const,
    },
    upsellTitle: {
      fontSize: 15,
      fontWeight: "800" as const,
      color: GOLD,
    },
    upsellSub: {
      fontSize: 12,
      color: "rgba(255,255,255,0.50)",
      marginTop: 2,
    },
    featureRow: {
      flexDirection: "row" as const,
      flexWrap: "wrap" as const,
      gap: 6,
    },
    featureChip: {
      flexDirection: "row" as const,
      alignItems: "center" as const,
      gap: 4,
      backgroundColor: "rgba(255,255,255,0.07)",
      borderRadius: 20,
      paddingHorizontal: 9,
      paddingVertical: 4,
    },
    featureChipText: {
      fontSize: 11,
      color: "rgba(255,255,255,0.65)",
      fontWeight: "500" as const,
    },
    upgradeBtn: {
      backgroundColor: GOLD,
      borderRadius: 12,
      paddingVertical: 11,
      alignItems: "center" as const,
      flexDirection: "row" as const,
      justifyContent: "center" as const,
      gap: 6,
    },
    upgradeBtnText: {
      fontSize: 14,
      fontWeight: "800" as const,
      color: "#0B1E33",
    },

    // ── Auth card (not logged in) ─────────────────────────────────────────────
    authCard: {
      backgroundColor: colors.card,
      borderWidth: 1,
      borderColor: colors.border,
      borderRadius: 18,
      padding: 18,
      gap: 14,
    },
    authTop: {
      flexDirection: "row" as const,
      alignItems: "center" as const,
      gap: 12,
    },
    authIconWrap: {
      width: 44,
      height: 44,
      borderRadius: 14,
      backgroundColor: colors.primary + "18",
      alignItems: "center" as const,
      justifyContent: "center" as const,
    },
    authTitle: {
      fontSize: 15,
      fontWeight: "800" as const,
      color: colors.foreground,
    },
    authSub: {
      fontSize: 12,
      color: colors.mutedForeground,
      marginTop: 2,
    },
    authBtnRow: {
      flexDirection: "row" as const,
      gap: 10,
    },
    authBtn: {
      flex: 1,
      paddingVertical: 10,
      borderRadius: 10,
      alignItems: "center" as const,
      backgroundColor: colors.primary,
    },
    authBtnOutline: {
      flex: 1,
      paddingVertical: 10,
      borderRadius: 10,
      alignItems: "center" as const,
      backgroundColor: "transparent",
      borderWidth: 1,
      borderColor: colors.border,
    },
    authBtnText: {
      fontSize: 13,
      fontWeight: "700" as const,
      color: "#FFFFFF",
    },
    authBtnOutlineText: {
      fontSize: 13,
      fontWeight: "700" as const,
      color: colors.foreground,
    },

    loadingCard: {
      backgroundColor: colors.card,
      borderRadius: 18,
      padding: 24,
      alignItems: "center" as const,
    },
  });

  // ── Loading ──────────────────────────────────────────────────────────────
  if (isLoading) {
    return (
      <View style={[s.card, s.loadingCard]}>
        <ActivityIndicator size="small" color={GOLD} />
      </View>
    );
  }

  // ── Subscribed ──────────────────────────────────────────────────────────
  if (isSupported && isSubscribed) {
    const premiumEntitlement = customerInfo?.entitlements.active["premium"];
    const expiryStr = formatExpiry(premiumEntitlement?.expirationDate);
    const displayName = user?.name ?? customerInfo?.originalAppUserId ?? "Üye";

    return (
      <View style={s.card}>
        <View style={s.premCard}>
          <View style={s.premTop}>
            <View style={s.premIconWrap}>
              <Feather name="award" size={20} color={GOLD} />
            </View>
            <View style={s.premInfo}>
              <Text style={s.premName}>KasaFON Premium</Text>
              <Text style={s.premSub}>{displayName}</Text>
            </View>
            <View style={s.premBadge}>
              <Text style={s.premBadgeText}>Aktif</Text>
            </View>
          </View>

          <View style={s.premDivider} />

          <View style={s.premBottom}>
            <View>
              <Text style={s.premExpiryLabel}>Yenileme tarihi</Text>
              <Text style={s.premExpiryDate}>{expiryStr ?? "—"}</Text>
            </View>
            <TouchableOpacity style={s.premManageBtn} onPress={goToPricing} activeOpacity={0.8}>
              <Text style={s.premManageBtnText}>Yönet</Text>
              <Feather name="chevron-right" size={14} color={GOLD} />
            </TouchableOpacity>
          </View>
        </View>
      </View>
    );
  }

  // ── Not logged in ────────────────────────────────────────────────────────
  if (!isLoggedIn) {
    return (
      <View style={[s.card, s.authCard]}>
        <View style={s.authTop}>
          <View style={s.authIconWrap}>
            <Feather name="user" size={20} color={colors.primary} />
          </View>
          <View style={{ flex: 1 }}>
            <Text style={s.authTitle}>Üyelik Paneli</Text>
            <Text style={s.authSub}>Giriş yaparak üyeliğinizi yönetin</Text>
          </View>
        </View>
        <View style={s.authBtnRow}>
          <TouchableOpacity style={s.authBtn} onPress={() => goToMembership("login")} activeOpacity={0.85}>
            <Text style={s.authBtnText}>Giriş Yap</Text>
          </TouchableOpacity>
          <TouchableOpacity style={s.authBtnOutline} onPress={() => goToMembership("register")} activeOpacity={0.85}>
            <Text style={s.authBtnOutlineText}>Kayıt Ol</Text>
          </TouchableOpacity>
        </View>
      </View>
    );
  }

  // ── Not subscribed (logged in) ───────────────────────────────────────────
  const FEATURES = [
    { icon: "layers" as const, label: "Borç & taksit takibi" },
    { icon: "pie-chart" as const, label: "Varlık yönetimi" },
    { icon: "file-text" as const, label: "PDF & Excel raporu" },
    { icon: "cloud" as const, label: "Bulut yedekleme" },
    { icon: "bell" as const, label: "Ödeme hatırlatıcı" },
  ];

  return (
    <View style={s.card}>
      <LinearGradient
        colors={["#1A0F00", "#0B1E33"]}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={{ borderRadius: 18, borderWidth: 1, borderColor: GOLD_BORDER }}
      >
        <View style={s.upsellInner}>
          <View style={s.upsellTop}>
            <View style={s.upsellIconWrap}>
              <Feather name="award" size={20} color={GOLD} />
            </View>
            <View style={{ flex: 1 }}>
              <Text style={s.upsellTitle}>KasaFON Premium'a Geç</Text>
              <Text style={s.upsellSub}>Merhaba, {user?.name ?? "kullanıcı"}</Text>
            </View>
          </View>

          <View style={s.featureRow}>
            {FEATURES.map((f) => (
              <View key={f.label} style={s.featureChip}>
                <Feather name={f.icon} size={11} color={GOLD} />
                <Text style={s.featureChipText}>{f.label}</Text>
              </View>
            ))}
          </View>

          <TouchableOpacity style={s.upgradeBtn} onPress={goToPricing} activeOpacity={0.85}>
            <Feather name="zap" size={15} color="#0B1E33" />
            <Text style={s.upgradeBtnText}>Üyelik Planlarını Gör</Text>
          </TouchableOpacity>
        </View>
      </LinearGradient>
    </View>
  );
}
