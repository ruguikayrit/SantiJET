import { Feather } from "@expo/vector-icons";
import React, { useState } from "react";
import {
  KeyboardAvoidingView,
  Modal,
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
  "isveren":                "#7c3aed",
  "proje-muduru":           "#e85d04",
  "santiye-sefi":           "#dc2626",
  "saha-muhendisi":         "#16a34a",
  "teknik-ofis-muhendisi":  "#0ea5e9",
  "isg-birimi":             "#f59e0b",
  "taseron":                "#64748b",
  "satin-alma-birimi":      "#0891b2",
  "muhasebe-birimi":        "#059669",
  "ik-birimi":              "#8b5cf6",
  "diger-kullanicilar":     "#94a3b8",
};

export default function LoginScreen() {
  const insets = useSafeAreaInsets();
  const { appUsers, roles, addAppUser, login } = useApp();

  const [dropdownOpen, setDropdownOpen] = useState(false);
  const [selectedUserId, setSelectedUserId] = useState<string | null>(null);

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

  function selectUser(user: AppUser) {
    setSelectedUserId(user.id);
    setDropdownOpen(false);
  }

  function handleLogin() {
    if (!selectedUserId) return;
    const user = appUsers.find((u) => u.id === selectedUserId);
    if (!user) return;
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
      profession: "",
      phone: "",
      address: "",
      company: "",
    });
    setNewName("");
    setNewPin("");
    setNewPinConfirm("");
    setNewUserSheet(false);
  }

  const selectedUser = appUsers.find((u) => u.id === selectedUserId) || null;
  const pinUser = appUsers.find((u) => u.id === pinUserId);

  return (
    <View style={[styles.root, { paddingTop: insets.top }]}>
      {/* Hero */}
      <View style={styles.hero}>
        <View style={styles.logoBox}>
          <Feather name="hard-drive" size={36} color="#e85d04" />
        </View>
        <Text style={styles.appName}>ŞantiJET</Text>
        <Text style={styles.subtitle}>Hesabınızı seçin</Text>
      </View>

      {/* Main content */}
      <View style={styles.body}>
        {appUsers.length === 0 ? (
          <View style={styles.emptyBox}>
            <Feather name="users" size={40} color="#475569" />
            <Text style={styles.emptyTitle}>Henüz kullanıcı yok</Text>
            <Text style={styles.emptyDesc}>Başlamak için ilk kullanıcıyı oluşturun</Text>
          </View>
        ) : (
          <>
            <Text style={styles.dropLabel}>Kullanıcı</Text>

            {/* Dropdown trigger */}
            <TouchableOpacity
              style={[
                styles.dropTrigger,
                dropdownOpen && { borderColor: "#e85d04" },
              ]}
              onPress={() => setDropdownOpen(true)}
              activeOpacity={0.85}
            >
              {selectedUser ? (
                <View style={styles.dropSelected}>
                  <View style={[styles.avatar, { backgroundColor: getRoleColor(selectedUser.roleId) + "22" }]}>
                    <Text style={[styles.avatarText, { color: getRoleColor(selectedUser.roleId) }]}>
                      {selectedUser.name.charAt(0).toUpperCase()}
                    </Text>
                  </View>
                  <View style={styles.dropUserInfo}>
                    <Text style={styles.dropUserName}>{selectedUser.name}</Text>
                    <Text style={styles.dropUserRole}>{getRoleName(selectedUser.roleId)}</Text>
                  </View>
                  {selectedUser.pin ? (
                    <Feather name="lock" size={14} color="#64748b" style={{ marginRight: 4 }} />
                  ) : null}
                </View>
              ) : (
                <Text style={styles.dropPlaceholder}>Kullanıcı seçin...</Text>
              )}
              <Feather name="chevron-down" size={20} color="#64748b" />
            </TouchableOpacity>

            {/* Login button */}
            {selectedUser ? (
              <TouchableOpacity
                style={styles.loginBtn}
                onPress={handleLogin}
                activeOpacity={0.85}
              >
                <Feather name="log-in" size={18} color="#fff" />
                <Text style={styles.loginBtnText}>
                  {selectedUser.pin ? "PIN ile Giriş Yap" : "Giriş Yap"}
                </Text>
              </TouchableOpacity>
            ) : null}
          </>
        )}
      </View>

      {/* Footer — add user */}
      <View style={[styles.footer, { paddingBottom: insets.bottom + 16 }]}>
        <TouchableOpacity
          style={styles.addBtn}
          onPress={() => {
            setNewName(""); setNewPin(""); setNewPinConfirm("");
            setNewRoleId(roles[0]?.id || "santiye-sefi");
            setNewUserSheet(true);
          }}
          activeOpacity={0.85}
        >
          <Feather name="user-plus" size={18} color="#fff" />
          <Text style={styles.addBtnText}>Yeni Kullanıcı Ekle</Text>
        </TouchableOpacity>
      </View>

      {/* ── Dropdown modal ── */}
      <Modal visible={dropdownOpen} transparent animationType="fade" onRequestClose={() => setDropdownOpen(false)}>
        <TouchableOpacity style={styles.modalOverlay} activeOpacity={1} onPress={() => setDropdownOpen(false)}>
          <View style={[styles.dropList, { marginTop: insets.top + 220 }]}>
            <View style={styles.dropListHeader}>
              <Text style={styles.dropListTitle}>Kullanıcı Seçin</Text>
              <TouchableOpacity onPress={() => setDropdownOpen(false)}>
                <Feather name="x" size={20} color="#94a3b8" />
              </TouchableOpacity>
            </View>
            <ScrollView style={{ maxHeight: 360 }} showsVerticalScrollIndicator={false}>
              {appUsers.map((user) => {
                const rColor = getRoleColor(user.roleId);
                const isSelected = user.id === selectedUserId;
                return (
                  <TouchableOpacity
                    key={user.id}
                    style={[styles.dropItem, isSelected && { backgroundColor: "#e85d0415" }]}
                    onPress={() => selectUser(user)}
                    activeOpacity={0.8}
                  >
                    <View style={[styles.avatar, { backgroundColor: rColor + "22" }]}>
                      <Text style={[styles.avatarText, { color: rColor }]}>
                        {user.name.charAt(0).toUpperCase()}
                      </Text>
                    </View>
                    <View style={styles.dropUserInfo}>
                      <Text style={[styles.dropItemName, isSelected && { color: "#e85d04" }]}>{user.name}</Text>
                      <Text style={styles.dropItemRole}>{getRoleName(user.roleId)}</Text>
                    </View>
                    {user.pin ? (
                      <Feather name="lock" size={13} color="#64748b" style={{ marginRight: 6 }} />
                    ) : null}
                    {isSelected ? (
                      <Feather name="check-circle" size={18} color="#e85d04" />
                    ) : (
                      <Feather name="chevron-right" size={18} color="#334155" />
                    )}
                  </TouchableOpacity>
                );
              })}
            </ScrollView>
          </View>
        </TouchableOpacity>
      </Modal>

      {/* ── PIN overlay ── */}
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
                if (v.length <= 4 && /^\d*$/.test(v)) { setPinInput(v); setPinError(false); }
              }}
              keyboardType="number-pad"
              secureTextEntry
              maxLength={4}
              autoFocus
              placeholder="••••"
              placeholderTextColor="#94a3b8"
            />
            <View style={styles.pinBtnRow}>
              <TouchableOpacity style={styles.pinCancel} onPress={() => setPinUserId(null)}>
                <Text style={styles.pinCancelText}>İptal</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={[styles.pinConfirm, { opacity: pinInput.length === 4 ? 1 : 0.5 }]}
                onPress={handlePinConfirm}
                disabled={pinInput.length !== 4}
              >
                <Text style={styles.pinConfirmText}>Giriş</Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>
      ) : null}

      {/* ── New user BottomSheet ── */}
      <BottomSheet visible={newUserSheet} onClose={() => setNewUserSheet(false)} title="Yeni Kullanıcı">
        <KeyboardAvoidingView behavior={Platform.OS === "ios" ? "padding" : "height"}>
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
                style={[styles.roleChip, { backgroundColor: newRoleId === r.id ? getRoleColor(r.id) : "#1e293b", borderColor: newRoleId === r.id ? getRoleColor(r.id) : "#334155" }]}
              >
                <Text style={[styles.roleChipText, { color: newRoleId === r.id ? "#fff" : "#94a3b8" }]}>
                  {r.name}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
          <Text style={[styles.formLabel, { marginTop: 12 }]}>PIN (Opsiyonel, 4 haneli)</Text>
          <TextInput
            style={styles.formInput}
            value={newPin}
            onChangeText={(v) => { if (v.length <= 4 && /^\d*$/.test(v)) setNewPin(v); }}
            placeholder="PIN girilmezse şifresiz giriş"
            placeholderTextColor="#94a3b8"
            keyboardType="number-pad"
            secureTextEntry
            maxLength={4}
          />
          {newPin.length > 0 ? (
            <>
              <Text style={[styles.formLabel, { marginTop: 12 }]}>PIN Tekrar</Text>
              <TextInput
                style={[styles.formInput, { borderColor: newPinConfirm && newPin !== newPinConfirm ? "#dc2626" : "#334155" }]}
                value={newPinConfirm}
                onChangeText={(v) => { if (v.length <= 4 && /^\d*$/.test(v)) setNewPinConfirm(v); }}
                placeholder="••••"
                placeholderTextColor="#94a3b8"
                keyboardType="number-pad"
                secureTextEntry
                maxLength={4}
              />
            </>
          ) : null}
          <PrimaryButton label="Kullanıcı Oluştur" onPress={handleCreateUser} style={{ marginTop: 16 }} />
          <View style={{ height: 8 }} />
        </KeyboardAvoidingView>
      </BottomSheet>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: "#16213e" },
  hero: { alignItems: "center", paddingTop: 32, paddingBottom: 28 },
  logoBox: { width: 72, height: 72, borderRadius: 36, backgroundColor: "#e85d0422", justifyContent: "center", alignItems: "center", marginBottom: 16 },
  appName: { color: "#fff", fontSize: 26, fontFamily: "Inter_700Bold", marginBottom: 6 },
  subtitle: { color: "#94a3b8", fontSize: 14, fontFamily: "Inter_400Regular" },

  body: { flex: 1, paddingHorizontal: 20, paddingTop: 8 },
  emptyBox: { alignItems: "center", paddingTop: 40, gap: 12 },
  emptyTitle: { color: "#e2e8f0", fontSize: 18, fontFamily: "Inter_700Bold" },
  emptyDesc: { color: "#94a3b8", fontSize: 14, fontFamily: "Inter_400Regular", textAlign: "center" },

  dropLabel: { color: "#94a3b8", fontSize: 12, fontFamily: "Inter_600SemiBold", marginBottom: 8, letterSpacing: 0.5, textTransform: "uppercase" },
  dropTrigger: {
    backgroundColor: "#1e293b",
    borderRadius: 14,
    paddingHorizontal: 16,
    paddingVertical: 14,
    flexDirection: "row",
    alignItems: "center",
    borderWidth: 1.5,
    borderColor: "#334155",
    gap: 10,
  },
  dropSelected: { flex: 1, flexDirection: "row", alignItems: "center", gap: 12 },
  dropUserInfo: { flex: 1 },
  dropUserName: { color: "#f1f5f9", fontSize: 16, fontFamily: "Inter_600SemiBold" },
  dropUserRole: { color: "#94a3b8", fontSize: 12, fontFamily: "Inter_400Regular", marginTop: 2 },
  dropPlaceholder: { flex: 1, color: "#475569", fontSize: 15, fontFamily: "Inter_400Regular" },

  loginBtn: {
    backgroundColor: "#e85d04",
    borderRadius: 12,
    paddingVertical: 15,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 8,
    marginTop: 14,
    shadowColor: "#e85d04",
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 6,
  },
  loginBtnText: { color: "#fff", fontSize: 16, fontFamily: "Inter_700Bold" },

  avatar: { width: 40, height: 40, borderRadius: 20, justifyContent: "center", alignItems: "center" },
  avatarText: { fontSize: 17, fontFamily: "Inter_700Bold" },

  footer: { position: "absolute", bottom: 0, left: 0, right: 0, paddingHorizontal: 16, paddingTop: 12, backgroundColor: "#16213e" },
  addBtn: { backgroundColor: "#1e293b", borderRadius: 12, paddingVertical: 14, flexDirection: "row", alignItems: "center", justifyContent: "center", gap: 8, borderWidth: 1, borderColor: "#334155" },
  addBtnText: { color: "#94a3b8", fontSize: 15, fontFamily: "Inter_600SemiBold" },

  // Modal dropdown list
  modalOverlay: { flex: 1, backgroundColor: "rgba(0,0,0,0.55)" },
  dropList: {
    marginHorizontal: 20,
    backgroundColor: "#1e293b",
    borderRadius: 18,
    overflow: "hidden",
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 8 },
    shadowOpacity: 0.4,
    shadowRadius: 20,
    elevation: 20,
  },
  dropListHeader: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingHorizontal: 18, paddingVertical: 14, borderBottomWidth: StyleSheet.hairlineWidth, borderBottomColor: "#334155" },
  dropListTitle: { color: "#f1f5f9", fontSize: 16, fontFamily: "Inter_700Bold" },
  dropItem: { flexDirection: "row", alignItems: "center", paddingHorizontal: 16, paddingVertical: 14, gap: 12, borderBottomWidth: StyleSheet.hairlineWidth, borderBottomColor: "#0f172a40" },
  dropItemName: { color: "#f1f5f9", fontSize: 15, fontFamily: "Inter_600SemiBold" },
  dropItemRole: { color: "#94a3b8", fontSize: 12, fontFamily: "Inter_400Regular", marginTop: 2 },

  // PIN
  pinOverlay: { ...StyleSheet.absoluteFillObject, backgroundColor: "rgba(0,0,0,0.7)", justifyContent: "center", alignItems: "center", paddingHorizontal: 32 },
  pinCard: { backgroundColor: "#1e293b", borderRadius: 20, padding: 28, width: "100%", alignItems: "center" },
  pinTitle: { color: "#f1f5f9", fontSize: 18, fontFamily: "Inter_700Bold", marginBottom: 4 },
  pinName: { color: "#94a3b8", fontSize: 14, fontFamily: "Inter_400Regular", marginBottom: 16 },
  pinError: { color: "#dc2626", fontSize: 13, fontFamily: "Inter_500Medium", marginBottom: 8 },
  pinInput: { backgroundColor: "#0f172a", color: "#f1f5f9", fontSize: 28, fontFamily: "Inter_700Bold", textAlign: "center", letterSpacing: 8, borderRadius: 12, paddingVertical: 14, paddingHorizontal: 24, width: "100%", marginBottom: 20 },
  pinBtnRow: { flexDirection: "row", gap: 12, width: "100%" },
  pinCancel: { flex: 1, backgroundColor: "#334155", borderRadius: 10, paddingVertical: 12, alignItems: "center" },
  pinCancelText: { color: "#94a3b8", fontSize: 15, fontFamily: "Inter_600SemiBold" },
  pinConfirm: { flex: 1, backgroundColor: "#e85d04", borderRadius: 10, paddingVertical: 12, alignItems: "center" },
  pinConfirmText: { color: "#fff", fontSize: 15, fontFamily: "Inter_600SemiBold" },

  // New user form
  formLabel: { color: "#e2e8f0", fontSize: 13, fontFamily: "Inter_600SemiBold", marginBottom: 8 },
  formInput: { backgroundColor: "#1e293b", color: "#f1f5f9", fontSize: 15, fontFamily: "Inter_400Regular", borderRadius: 10, paddingVertical: 12, paddingHorizontal: 14, borderWidth: 1, borderColor: "#334155" },
  roleChips: { flexDirection: "row", flexWrap: "wrap", gap: 8 },
  roleChip: { paddingHorizontal: 14, paddingVertical: 8, borderRadius: 999, borderWidth: 1 },
  roleChipText: { fontSize: 13, fontFamily: "Inter_500Medium" },
});
