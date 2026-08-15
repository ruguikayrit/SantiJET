import { Feather } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import React from "react";
import { StyleSheet, Text, TouchableOpacity, View } from "react-native";

import BottomSheet from "@/components/BottomSheet";
import { useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";

const ROLE_COLORS: Record<string, string> = {
  isveren: "#7c3aed",
  "proje-muduru": "#e85d04",
  "santiye-sefi": "#dc2626",
  "saha-muhendisi": "#16a34a",
  "teknik-ofis-muhendisi": "#0ea5e9",
  "isg-birimi": "#f59e0b",
  taseron: "#64748b",
  "satin-alma-birimi": "#0891b2",
  "muhasebe-birimi": "#059669",
  "ik-birimi": "#8b5cf6",
  "diger-kullanicilar": "#94a3b8",
};

interface Props {
  visible: boolean;
  onClose: () => void;
}

export default function AccountSheet({ visible, onClose }: Props) {
  const colors = useColors();
  const router = useRouter();
  const { currentRole, currentAppUser, logout, workspaceInfo, setWorkspace } = useApp();

  if (!currentAppUser) {
    return (
      <BottomSheet visible={visible} onClose={onClose} title="Hesabım">
        <Text style={[styles.empty, { color: colors.mutedForeground }]}>
          Hesap bilgisi bulunamadı.
        </Text>
      </BottomSheet>
    );
  }

  const roleColor = ROLE_COLORS[currentAppUser.roleId] ?? "#6b7280";

  return (
    <BottomSheet visible={visible} onClose={onClose} title="Hesabım">
      <View style={styles.body}>
        <View style={styles.hero}>
          <View style={[styles.avatar, { backgroundColor: roleColor }]}>
            <Text style={styles.avatarText}>
              {currentAppUser.name.charAt(0).toUpperCase()}
            </Text>
          </View>
          <View style={{ flex: 1, gap: 4 }}>
            <Text style={[styles.name, { color: colors.foreground }]}>
              {currentAppUser.name}
            </Text>
            <View style={[styles.rolePill, { backgroundColor: roleColor + "22" }]}>
              <Text style={[styles.rolePillText, { color: roleColor }]}>
                {currentRole?.name ?? currentAppUser.roleId}
              </Text>
              {currentRole?.isAdmin ? (
                <Feather name="shield" size={10} color={roleColor} />
              ) : null}
            </View>
          </View>
        </View>

        <View style={[styles.infoCard, { backgroundColor: colors.muted, borderColor: colors.border }]}>
          {currentAppUser.profession ? (
            <View style={styles.row}>
              <Feather name="briefcase" size={14} color={colors.mutedForeground} />
              <Text style={[styles.rowLabel, { color: colors.mutedForeground }]}>Meslek</Text>
              <Text style={[styles.rowVal, { color: colors.foreground }]} numberOfLines={1}>
                {currentAppUser.profession}
              </Text>
            </View>
          ) : null}
          {currentAppUser.team ? (
            <View style={styles.row}>
              <Feather name="users" size={14} color={colors.mutedForeground} />
              <Text style={[styles.rowLabel, { color: colors.mutedForeground }]}>Grup</Text>
              <Text style={[styles.rowVal, { color: colors.foreground }]} numberOfLines={1}>
                {currentAppUser.team}
              </Text>
            </View>
          ) : null}
          {currentAppUser.company ? (
            <View style={styles.row}>
              <Feather name="layers" size={14} color={colors.mutedForeground} />
              <Text style={[styles.rowLabel, { color: colors.mutedForeground }]}>Firma</Text>
              <Text style={[styles.rowVal, { color: colors.foreground }]} numberOfLines={1}>
                {currentAppUser.company}
              </Text>
            </View>
          ) : null}
          {currentAppUser.phone ? (
            <View style={styles.row}>
              <Feather name="phone" size={14} color={colors.mutedForeground} />
              <Text style={[styles.rowLabel, { color: colors.mutedForeground }]}>Telefon</Text>
              <Text style={[styles.rowVal, { color: colors.foreground }]} numberOfLines={1}>
                {currentAppUser.phone}
              </Text>
            </View>
          ) : null}
          {currentAppUser.address ? (
            <View style={styles.row}>
              <Feather name="map-pin" size={14} color={colors.mutedForeground} />
              <Text style={[styles.rowLabel, { color: colors.mutedForeground }]}>Adres</Text>
              <Text style={[styles.rowVal, { color: colors.foreground }]} numberOfLines={2}>
                {currentAppUser.address}
              </Text>
            </View>
          ) : null}
        </View>

        <TouchableOpacity
          style={[styles.navBtn, { backgroundColor: colors.card, borderColor: colors.border }]}
          activeOpacity={0.85}
          onPress={() => {
            onClose();
            router.push("/kullanicilar" as any);
          }}
        >
          <View style={[styles.navIcon, { backgroundColor: "#ede9fe" }]}>
            <Feather name="shield" size={18} color="#7c3aed" />
          </View>
          <View style={{ flex: 1 }}>
            <Text style={[styles.navLabel, { color: colors.foreground }]}>Kullanıcı Yönetimi</Text>
            <Text style={[styles.navSub, { color: colors.mutedForeground }]}>
              Tüm kullanıcıları ve rolleri görüntüle
            </Text>
          </View>
          <Feather name="chevron-right" size={16} color={colors.mutedForeground} />
        </TouchableOpacity>

        {(!workspaceInfo || workspaceInfo.id === "local") && (
          <TouchableOpacity
            style={[styles.connectBtn, { borderColor: "#e85d04" }]}
            activeOpacity={0.85}
            onPress={() => {
              onClose();
              router.push("/workspace-setup" as any);
            }}
          >
            <Feather name="link" size={18} color="#e85d04" />
            <Text style={styles.connectText}>Şirket Kodu ile Bağlan</Text>
          </TouchableOpacity>
        )}

        {workspaceInfo && workspaceInfo.id !== "local" && (
          <TouchableOpacity
            style={[styles.localBtn, { borderColor: "#0ea5e9" }]}
            activeOpacity={0.85}
            onPress={() => {
              onClose();
              setWorkspace({
                id: "local",
                company_name: "Yerel",
                invite_code: "",
                api_url: "",
              });
            }}
          >
            <Feather name="home" size={18} color="#0ea5e9" />
            <Text style={styles.localText}>Yerel Oturuma Geri Dön</Text>
          </TouchableOpacity>
        )}

        <TouchableOpacity
          style={[styles.logoutBtn, { borderColor: "#dc2626" }]}
          activeOpacity={0.85}
          onPress={() => {
            onClose();
            logout();
          }}
        >
          <Feather name="log-out" size={18} color="#dc2626" />
          <Text style={styles.logoutText}>Oturumu Kapat</Text>
        </TouchableOpacity>
      </View>
    </BottomSheet>
  );
}

const styles = StyleSheet.create({
  empty: { fontSize: 13, fontFamily: "Inter_400Regular", textAlign: "center", paddingVertical: 12 },
  body: { gap: 12 },
  hero: { flexDirection: "row", alignItems: "center", gap: 14, paddingBottom: 4 },
  avatar: { width: 56, height: 56, borderRadius: 28, justifyContent: "center", alignItems: "center" },
  avatarText: { color: "#fff", fontSize: 24, fontFamily: "Inter_700Bold" },
  name: { fontSize: 18, fontFamily: "Inter_700Bold" },
  rolePill: {
    flexDirection: "row",
    alignItems: "center",
    alignSelf: "flex-start",
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 8,
    gap: 4,
  },
  rolePillText: { fontSize: 12, fontFamily: "Inter_600SemiBold" },
  infoCard: { borderRadius: 12, borderWidth: 1, overflow: "hidden" },
  row: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: "rgba(0,0,0,0.06)",
  },
  rowLabel: { fontSize: 12, fontFamily: "Inter_500Medium", width: 60 },
  rowVal: { flex: 1, fontSize: 13, fontFamily: "Inter_600SemiBold" },
  navBtn: { flexDirection: "row", alignItems: "center", gap: 12, padding: 14, borderRadius: 12, borderWidth: 1 },
  navIcon: { width: 40, height: 40, borderRadius: 10, justifyContent: "center", alignItems: "center" },
  navLabel: { fontSize: 14, fontFamily: "Inter_600SemiBold" },
  navSub: { fontSize: 12, fontFamily: "Inter_400Regular", marginTop: 1 },
  connectBtn: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 10,
    paddingVertical: 14,
    borderRadius: 12,
    borderWidth: 1.5,
    backgroundColor: "#fff7ed",
    marginTop: 4,
  },
  connectText: { fontSize: 15, fontFamily: "Inter_700Bold", color: "#e85d04" },
  localBtn: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 10,
    paddingVertical: 14,
    borderRadius: 12,
    borderWidth: 1.5,
    backgroundColor: "#e0f2fe",
    marginTop: 4,
  },
  localText: { fontSize: 15, fontFamily: "Inter_700Bold", color: "#0ea5e9" },
  logoutBtn: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 10,
    paddingVertical: 14,
    borderRadius: 12,
    borderWidth: 1.5,
    backgroundColor: "#fee2e2",
    marginTop: 4,
  },
  logoutText: { fontSize: 15, fontFamily: "Inter_700Bold", color: "#dc2626" },
});
