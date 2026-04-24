import { Feather } from "@expo/vector-icons";
import React, { useState } from "react";
import {
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

import BottomSheet from "@/components/BottomSheet";
import PrimaryButton from "@/components/PrimaryButton";
import { AppUser, useApp } from "@/context/AppContext";

const ROLE_COLORS: Record<string, string> = {
  "santiye-sefi": "#e85d04",
  "saha-muhendisi": "#16a34a",
  muhendis: "#0ea5e9",
  yuklenici: "#8b5cf6",
};

export default function LoginScreen() {
  const insets = useSafeAreaInsets();
  const { appUsers, roles, addAppUser, login } = useApp();

  const [pinUserId, setPinUserId] = useState<string | null>(null);
  const [pinInput, setPinInput] = useState("");
  const [pinError, setPinError] = useState(false);

  const [newUserSheet, setNewUserSheet] = useState(false);
  const [newName, setNewName] = useState("");
  const [newRoleId, setNewRoleId] = useState(roles[0]?.id || "santiye-sefi");
  const [newPin, setNewPin] = useState("");
  const [newPinConfirm, setNewPinConfirm] = useState("");

  function getRoleName(roleId: string) {
    return roles.find((r) => r.id === roleId)?.name || roleId;
  }

  function getRoleColor(roleId: string) {
    return ROLE_COLORS[roleId] || "#6b7280";
  }

  function handleUserTap(user: AppUser) {
    if (user.pin) {
      setPinUserId(user.id);
      setPinInput("");
      setPinError(false);
    } else {
      login(user.id);
    }
  }

  function handlePinConfirm() {
    const user = appUsers.find((u) => u.id === pinUserId);
    if (!user) return;
    if (pinInput === user.pin) {
      login(user.id);
      setPinUserId(null);
    } else {
      setPinError(true);
      setPinInput("");
    }
  }

  function handleCreateUser() {
    if (!newName.trim()) return;
    if (newPin && newPin !== newPinConfirm) return;
    addAppUser({
      name: newName.trim(),
      roleId: newRoleId,
      pin: newPin.length === 4 ? newPin : "",
    });
    setNewName("");
    setNewPin("");
    setNewPinConfirm("");
    setNewUserSheet(false);
  }

  const pinUser = appUsers.find((u) => u.id === pinUserId);

  return (
    <View style={[styles.root, { paddingTop: insets.top }]}>
      <View style={styles.hero}>
        <View style={styles.logoBox}>
          <Feather name="hard-drive" size={36} color="#e85d04" />
        </View>
        <Text style={styles.appName}>Şantiye Takip</Text>
        <Text style={styles.subtitle}>Hesabınızı seçin</Text>
      </View>

      <ScrollView
        contentContainerStyle={[styles.scroll, { paddingBottom: insets.bottom + 100 }]}
        showsVerticalScrollIndicator={false}
      >
        {appUsers.length === 0 ? (
          <View style={styles.emptyBox}>
            <Feather name="users" size={40} color="#475569" />
            <Text style={styles.emptyTitle}>Henüz kullanıcı yok</Text>
            <Text style={styles.emptyDesc}>
              Başlamak için ilk kullanıcıyı oluşturun
            </Text>
          </View>
        ) : (
          appUsers.map((user) => {
            const roleColor = getRoleColor(user.roleId);
            return (
              <TouchableOpacity
                key={user.id}
                style={styles.userCard}
                activeOpacity={0.85}
                onPress={() => handleUserTap(user)}
              >
                <View style={[styles.avatar, { backgroundColor: roleColor + "22" }]}>
                  <Text style={[styles.avatarText, { color: roleColor }]}>
                    {user.name.charAt(0).toUpperCase()}
                  </Text>
                </View>
                <View style={styles.userInfo}>
                  <Text style={styles.userName}>{user.name}</Text>
                  <Text style={styles.userRole}>{getRoleName(user.roleId)}</Text>
                </View>
                <View style={styles.userRight}>
                  {user.pin ? (
                    <Feather name="lock" size={16} color="#64748b" style={{ marginRight: 8 }} />
                  ) : null}
                  <Feather name="chevron-right" size={20} color="#64748b" />
                </View>
              </TouchableOpacity>
            );
          })
        )}
      </ScrollView>

      <View style={[styles.footer, { paddingBottom: insets.bottom + 16 }]}>
        <TouchableOpacity
          style={styles.addBtn}
          onPress={() => {
            setNewName("");
            setNewPin("");
            setNewPinConfirm("");
            setNewRoleId(roles[0]?.id || "santiye-sefi");
            setNewUserSheet(true);
          }}
          activeOpacity={0.85}
        >
          <Feather name="user-plus" size={18} color="#fff" />
          <Text style={styles.addBtnText}>Yeni Kullanıcı Ekle</Text>
        </TouchableOpacity>
      </View>

      {pinUserId ? (
        <View style={styles.pinOverlay}>
          <View style={styles.pinCard}>
            <Text style={styles.pinTitle}>PIN Girin</Text>
            <Text style={styles.pinName}>{pinUser?.name}</Text>
            {pinError ? (
              <Text style={styles.pinError}>Yanlış PIN, tekrar deneyin</Text>
            ) : null}
            <TextInput
              style={styles.pinInput}
              value={pinInput}
              onChangeText={(v) => {
                if (v.length <= 4 && /^\d*$/.test(v)) {
                  setPinInput(v);
                  setPinError(false);
                }
              }}
              keyboardType="number-pad"
              secureTextEntry
              maxLength={4}
              autoFocus
              placeholder="••••"
              placeholderTextColor="#94a3b8"
            />
            <View style={styles.pinBtnRow}>
              <TouchableOpacity
                style={styles.pinCancel}
                onPress={() => setPinUserId(null)}
              >
                <Text style={styles.pinCancelText}>İptal</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[
                  styles.pinConfirm,
                  { opacity: pinInput.length === 4 ? 1 : 0.5 },
                ]}
                onPress={handlePinConfirm}
                disabled={pinInput.length !== 4}
              >
                <Text style={styles.pinConfirmText}>Giriş</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      ) : null}

      <BottomSheet
        visible={newUserSheet}
        onClose={() => setNewUserSheet(false)}
        title="Yeni Kullanıcı"
      >
        <KeyboardAvoidingView
          behavior={Platform.OS === "ios" ? "padding" : "height"}
        >
          <Text style={styles.formLabel}>Ad Soyad</Text>
          <TextInput
            style={styles.formInput}
            value={newName}
            onChangeText={setNewName}
            placeholder="Örn: Ahmet Yılmaz"
            placeholderTextColor="#94a3b8"
          />

          <Text style={[styles.formLabel, { marginTop: 12 }]}>Rol</Text>
          <View style={styles.roleChips}>
            {roles.map((r) => (
              <TouchableOpacity
                key={r.id}
                onPress={() => setNewRoleId(r.id)}
                style={[
                  styles.roleChip,
                  {
                    backgroundColor:
                      newRoleId === r.id
                        ? getRoleColor(r.id)
                        : "#1e293b",
                    borderColor:
                      newRoleId === r.id
                        ? getRoleColor(r.id)
                        : "#334155",
                  },
                ]}
              >
                <Text
                  style={[
                    styles.roleChipText,
                    { color: newRoleId === r.id ? "#fff" : "#94a3b8" },
                  ]}
                >
                  {r.name}
                </Text>
              </TouchableOpacity>
            ))}
          </View>

          <Text style={[styles.formLabel, { marginTop: 12 }]}>
            PIN (Opsiyonel, 4 haneli)
          </Text>
          <TextInput
            style={styles.formInput}
            value={newPin}
            onChangeText={(v) => {
              if (v.length <= 4 && /^\d*$/.test(v)) setNewPin(v);
            }}
            placeholder="PIN girilmezse şifresiz giriş"
            placeholderTextColor="#94a3b8"
            keyboardType="number-pad"
            secureTextEntry
            maxLength={4}
          />
          {newPin.length > 0 ? (
            <>
              <Text style={[styles.formLabel, { marginTop: 12 }]}>
                PIN Tekrar
              </Text>
              <TextInput
                style={[
                  styles.formInput,
                  {
                    borderColor:
                      newPinConfirm && newPin !== newPinConfirm
                        ? "#dc2626"
                        : "#334155",
                  },
                ]}
                value={newPinConfirm}
                onChangeText={(v) => {
                  if (v.length <= 4 && /^\d*$/.test(v)) setNewPinConfirm(v);
                }}
                placeholder="••••"
                placeholderTextColor="#94a3b8"
                keyboardType="number-pad"
                secureTextEntry
                maxLength={4}
              />
            </>
          ) : null}

          <PrimaryButton
            label="Kullanıcı Oluştur"
            onPress={handleCreateUser}
            style={{ marginTop: 16 }}
          />
          <View style={{ height: 8 }} />
        </KeyboardAvoidingView>
      </BottomSheet>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#16213e" },
  hero: {
    alignItems: "center",
    paddingTop: 32,
    paddingBottom: 28,
  },
  logoBox: {
    width: 72,
    height: 72,
    borderRadius: 36,
    backgroundColor: "#e85d0422",
    justifyContent: "center",
    alignItems: "center",
    marginBottom: 16,
  },
  appName: {
    color: "#fff",
    fontSize: 26,
    fontFamily: "Inter_700Bold",
    marginBottom: 6,
  },
  subtitle: {
    color: "#94a3b8",
    fontSize: 14,
    fontFamily: "Inter_400Regular",
  },
  scroll: {
    paddingHorizontal: 16,
    gap: 10,
  },
  emptyBox: {
    alignItems: "center",
    paddingTop: 40,
    gap: 12,
  },
  emptyTitle: {
    color: "#e2e8f0",
    fontSize: 18,
    fontFamily: "Inter_700Bold",
  },
  emptyDesc: {
    color: "#94a3b8",
    fontSize: 14,
    fontFamily: "Inter_400Regular",
    textAlign: "center",
  },
  userCard: {
    backgroundColor: "#1e293b",
    borderRadius: 14,
    padding: 16,
    flexDirection: "row",
    alignItems: "center",
    gap: 14,
  },
  avatar: {
    width: 48,
    height: 48,
    borderRadius: 24,
    justifyContent: "center",
    alignItems: "center",
  },
  avatarText: {
    fontSize: 20,
    fontFamily: "Inter_700Bold",
  },
  userInfo: { flex: 1 },
  userName: {
    color: "#f1f5f9",
    fontSize: 16,
    fontFamily: "Inter_600SemiBold",
  },
  userRole: {
    color: "#94a3b8",
    fontSize: 13,
    fontFamily: "Inter_400Regular",
    marginTop: 2,
  },
  userRight: { flexDirection: "row", alignItems: "center" },
  footer: {
    position: "absolute",
    bottom: 0,
    left: 0,
    right: 0,
    paddingHorizontal: 16,
    paddingTop: 12,
    backgroundColor: "#16213e",
  },
  addBtn: {
    backgroundColor: "#e85d04",
    borderRadius: 12,
    paddingVertical: 14,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 8,
  },
  addBtnText: {
    color: "#fff",
    fontSize: 15,
    fontFamily: "Inter_600SemiBold",
  },
  pinOverlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "rgba(0,0,0,0.7)",
    justifyContent: "center",
    alignItems: "center",
    paddingHorizontal: 32,
  },
  pinCard: {
    backgroundColor: "#1e293b",
    borderRadius: 20,
    padding: 28,
    width: "100%",
    alignItems: "center",
  },
  pinTitle: {
    color: "#f1f5f9",
    fontSize: 18,
    fontFamily: "Inter_700Bold",
    marginBottom: 4,
  },
  pinName: {
    color: "#94a3b8",
    fontSize: 14,
    fontFamily: "Inter_400Regular",
    marginBottom: 16,
  },
  pinError: {
    color: "#dc2626",
    fontSize: 13,
    fontFamily: "Inter_500Medium",
    marginBottom: 8,
  },
  pinInput: {
    backgroundColor: "#0f172a",
    color: "#f1f5f9",
    fontSize: 28,
    fontFamily: "Inter_700Bold",
    textAlign: "center",
    letterSpacing: 8,
    borderRadius: 12,
    paddingVertical: 14,
    paddingHorizontal: 24,
    width: "100%",
    marginBottom: 20,
  },
  pinBtnRow: { flexDirection: "row", gap: 12, width: "100%" },
  pinCancel: {
    flex: 1,
    backgroundColor: "#334155",
    borderRadius: 10,
    paddingVertical: 12,
    alignItems: "center",
  },
  pinCancelText: {
    color: "#94a3b8",
    fontSize: 15,
    fontFamily: "Inter_600SemiBold",
  },
  pinConfirm: {
    flex: 1,
    backgroundColor: "#e85d04",
    borderRadius: 10,
    paddingVertical: 12,
    alignItems: "center",
  },
  pinConfirmText: {
    color: "#fff",
    fontSize: 15,
    fontFamily: "Inter_600SemiBold",
  },
  formLabel: {
    color: "#e2e8f0",
    fontSize: 13,
    fontFamily: "Inter_600SemiBold",
    marginBottom: 8,
  },
  formInput: {
    backgroundColor: "#1e293b",
    color: "#f1f5f9",
    fontSize: 15,
    fontFamily: "Inter_400Regular",
    borderRadius: 10,
    paddingVertical: 12,
    paddingHorizontal: 14,
    borderWidth: 1,
    borderColor: "#334155",
  },
  roleChips: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 8,
  },
  roleChip: {
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 999,
    borderWidth: 1,
  },
  roleChipText: {
    fontSize: 13,
    fontFamily: "Inter_500Medium",
  },
});
