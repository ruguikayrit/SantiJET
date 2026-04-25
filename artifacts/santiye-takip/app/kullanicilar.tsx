import { Feather } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import React, { useEffect, useState } from "react";
import {
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";

import { useSafeAreaInsets } from "react-native-safe-area-context";

import BottomSheet from "@/components/BottomSheet";
import Header from "@/components/Header";
import PrimaryButton from "@/components/PrimaryButton";
import {
  ALL_PAGE_KEYS,
  AppUser,
  PAGE_LABELS,
  PageKey,
  Permission,
  Role,
  useApp,
} from "@/context/AppContext";
import { usePermission } from "@/hooks/usePermission";
import { useColors } from "@/hooks/useColors";

const MESLEKLER = [
  "Proje Koordinatörü",
  "Proje Müdürü",
  "Şantiye Şefi",
  "Saha Mühendisi",
  "Teknik Ofis Mühendisi",
  "Harita Mühendisi",
  "Jeoloji Mühendisi",
  "İSG Uzmanı",
  "Şenör",
  "Puantör",
  "Saha Formeni",
  "Makine Formeni",
  "Ekskavatör Operatörü",
  "JCB Operatörü",
  "Kamyon Şoförü",
  "Kule Vinç Operatörü",
  "Mobil Vinç Operatörü",
  "Kantar Personeli",
  "Depo & Ambar Personeli",
  "Kalfa",
  "Kalfa Yardımcısı",
  "Saha Düz İşçi",
  "Gündüz Bekçisi",
  "Gece Bekçisi",
];

type Tab = "users" | "roles";

const PERM_OPTIONS: { value: Permission; label: string; color: string }[] = [
  { value: "none", label: "Yok", color: "#94a3b8" },
  { value: "view", label: "Görüntüle", color: "#0ea5e9" },
  { value: "edit", label: "Düzenle", color: "#16a34a" },
];

const ROLE_COLORS: Record<string, string> = {
  "santiye-sefi": "#e85d04",
  "saha-muhendisi": "#16a34a",
  muhendis: "#0ea5e9",
  yuklenici: "#8b5cf6",
};

function getRoleColor(roleId: string) {
  return ROLE_COLORS[roleId] || "#6b7280";
}

export default function KullanicilarScreen() {
  const colors = useColors();
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const {
    appUsers,
    roles,
    currentRole,
    addAppUser,
    updateAppUser,
    deleteAppUser,
    updateRole,
  } = useApp();
  const perm = usePermission("kullanicilar");

  useEffect(() => {
    if (perm === "none") router.back();
  }, [perm]);

  const [tab, setTab] = useState<Tab>("users");

  const [userSheet, setUserSheet] = useState(false);
  const [editUserId, setEditUserId] = useState<string | null>(null);
  const [uName, setUName] = useState("");
  const [uRoleId, setURoleId] = useState(roles[0]?.id || "");
  const [uPin, setUPin] = useState("");
  const [uProfession, setUProfession] = useState("");
  const [uPhone, setUPhone] = useState("");
  const [uAddress, setUAddress] = useState("");
  const [uCompany, setUCompany] = useState("");
  const [profDropOpen, setProfDropOpen] = useState(false);

  const [roleSheet, setRoleSheet] = useState(false);
  const [editRoleId, setEditRoleId] = useState<string | null>(null);
  const [editPerms, setEditPerms] = useState<Record<PageKey, Permission>>(
    {} as any
  );

  if (perm === "none") return null;

  function openUser(u?: AppUser) {
    if (u) {
      setEditUserId(u.id);
      setUName(u.name);
      setURoleId(u.roleId);
      setUPin(u.pin);
      setUProfession(u.profession || "");
      setUPhone(u.phone || "");
      setUAddress(u.address || "");
      setUCompany(u.company || "");
    } else {
      setEditUserId(null);
      setUName("");
      setURoleId(roles[0]?.id || "");
      setUPin("");
      setUProfession("");
      setUPhone("");
      setUAddress("");
      setUCompany("");
    }
    setUserSheet(true);
  }

  function saveUser() {
    if (!uName.trim()) return;
    const data = {
      name: uName.trim(),
      roleId: uRoleId,
      pin: uPin,
      profession: uProfession.trim(),
      phone: uPhone.trim(),
      address: uAddress.trim(),
      company: uCompany.trim(),
    };
    if (editUserId) updateAppUser(editUserId, data);
    else addAppUser(data);
    setUserSheet(false);
  }

  function removeUser() {
    if (editUserId) deleteAppUser(editUserId);
    setUserSheet(false);
  }

  function openRole(r: Role) {
    setEditRoleId(r.id);
    setEditPerms({ ...r.permissions });
    setRoleSheet(true);
  }

  function saveRole() {
    if (editRoleId) updateRole(editRoleId, { permissions: editPerms });
    setRoleSheet(false);
  }

  function setPermForPage(pageKey: PageKey, value: Permission) {
    setEditPerms((prev) => ({ ...prev, [pageKey]: value }));
  }

  function getRoleName(roleId: string) {
    return roles.find((r) => r.id === roleId)?.name || roleId;
  }

  const canEdit = perm === "edit";

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <Header
        title="Kullanıcı Yönetimi"
        onBack={() => router.back()}
        rightAction={
          tab === "users" && canEdit
            ? { icon: "user-plus", onPress: () => openUser() }
            : undefined
        }
      />

      <View style={[styles.tabs, { backgroundColor: colors.card }]}>
        <TouchableOpacity
          style={[styles.tab, tab === "users" && styles.tabActive]}
          onPress={() => setTab("users")}
        >
          <Text
            style={[
              styles.tabText,
              {
                color:
                  tab === "users" ? colors.primary : colors.mutedForeground,
              },
            ]}
          >
            Kullanıcılar ({appUsers.length})
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.tab, tab === "roles" && styles.tabActive]}
          onPress={() => setTab("roles")}
        >
          <Text
            style={[
              styles.tabText,
              {
                color:
                  tab === "roles" ? colors.primary : colors.mutedForeground,
              },
            ]}
          >
            Roller ({roles.length})
          </Text>
        </TouchableOpacity>
      </View>

      <ScrollView
        contentContainerStyle={[
          styles.list,
          { paddingBottom: insets.bottom + 24 },
        ]}
        showsVerticalScrollIndicator={false}
      >
        {tab === "users" ? (
          appUsers.length === 0 ? (
            <View style={styles.empty}>
              <Feather name="users" size={40} color={colors.mutedForeground} />
              <Text style={[styles.emptyTitle, { color: colors.foreground }]}>
                Kullanıcı yok
              </Text>
              <Text
                style={[styles.emptyDesc, { color: colors.mutedForeground }]}
              >
                Sağ üstteki + ile yeni kullanıcı ekleyin
              </Text>
            </View>
          ) : (
            appUsers.map((u) => {
              const roleColor = getRoleColor(u.roleId);
              return (
                <TouchableOpacity
                  key={u.id}
                  style={[styles.card, { backgroundColor: colors.card }]}
                  activeOpacity={0.85}
                  onPress={() => canEdit && openUser(u)}
                >
                  <View
                    style={[
                      styles.avatar,
                      { backgroundColor: roleColor + "22" },
                    ]}
                  >
                    <Text style={[styles.avatarText, { color: roleColor }]}>
                      {u.name.charAt(0).toUpperCase()}
                    </Text>
                  </View>
                  <View style={{ flex: 1 }}>
                    <Text
                      style={[styles.cardTitle, { color: colors.foreground }]}
                    >
                      {u.name}
                    </Text>
                    <View style={styles.cardMeta}>
                      <View
                        style={[
                          styles.rolePill,
                          { backgroundColor: roleColor + "22" },
                        ]}
                      >
                        <Text
                          style={[styles.rolePillText, { color: roleColor }]}
                        >
                          {getRoleName(u.roleId)}
                        </Text>
                      </View>
                      {u.pin ? (
                        <Feather
                          name="lock"
                          size={13}
                          color={colors.mutedForeground}
                        />
                      ) : null}
                    </View>
                    {(u.profession || u.company || u.phone) ? (
                      <Text style={[styles.cardSub, { color: colors.mutedForeground }]} numberOfLines={1}>
                        {[u.profession, u.company, u.phone].filter(Boolean).join(" · ")}
                      </Text>
                    ) : null}
                  </View>
                  {canEdit ? (
                    <Feather
                      name="edit-2"
                      size={16}
                      color={colors.mutedForeground}
                    />
                  ) : null}
                </TouchableOpacity>
              );
            })
          )
        ) : (
          roles.map((r) => {
            const rColor = getRoleColor(r.id);
            const editCount = Object.values(r.permissions).filter(
              (p) => p === "edit"
            ).length;
            const viewCount = Object.values(r.permissions).filter(
              (p) => p === "view"
            ).length;
            return (
              <TouchableOpacity
                key={r.id}
                style={[styles.card, { backgroundColor: colors.card }]}
                activeOpacity={0.85}
                onPress={() => canEdit && openRole(r)}
              >
                <View
                  style={[styles.roleIcon, { backgroundColor: rColor + "22" }]}
                >
                  <Feather
                    name={r.isAdmin ? "shield" : "user"}
                    size={20}
                    color={rColor}
                  />
                </View>
                <View style={{ flex: 1 }}>
                  <View style={styles.roleHead}>
                    <Text
                      style={[styles.cardTitle, { color: colors.foreground }]}
                    >
                      {r.name}
                    </Text>
                    {r.isAdmin ? (
                      <View
                        style={[
                          styles.adminBadge,
                          { backgroundColor: "#e85d0422" },
                        ]}
                      >
                        <Text style={styles.adminBadgeText}>Admin</Text>
                      </View>
                    ) : null}
                  </View>
                  <Text
                    style={[styles.cardSub, { color: colors.mutedForeground }]}
                  >
                    {editCount} düzenle · {viewCount} görüntüle ·{" "}
                    {11 - editCount - viewCount} erişim yok
                  </Text>
                </View>
                {canEdit ? (
                  <Feather
                    name="settings"
                    size={16}
                    color={colors.mutedForeground}
                  />
                ) : null}
              </TouchableOpacity>
            );
          })
        )}
      </ScrollView>

      <BottomSheet
        visible={userSheet}
        onClose={() => setUserSheet(false)}
        title={editUserId ? "Kullanıcıyı Düzenle" : "Yeni Kullanıcı"}
      >
        <Text style={[styles.formLabel, { color: colors.foreground }]}>Ad Soyad</Text>
        <TextInput
          style={[styles.formInput, { backgroundColor: colors.muted, color: colors.foreground, borderColor: colors.border }]}
          value={uName}
          onChangeText={setUName}
          placeholder="Örn: Ahmet Yılmaz"
          placeholderTextColor={colors.mutedForeground}
        />

        {/* Meslek — tam genişlik + satır içi açılır liste */}
        <Text style={[styles.formLabel, { color: colors.foreground, marginTop: 12 }]}>Meslek</Text>
        <TouchableOpacity
          style={[styles.formInput, styles.profTrigger, { backgroundColor: colors.muted, borderColor: profDropOpen ? colors.primary : colors.border }]}
          onPress={() => setProfDropOpen(v => !v)}
          activeOpacity={0.8}
        >
          <Text style={{ flex: 1, color: uProfession ? colors.foreground : colors.mutedForeground, fontSize: 14, fontFamily: "Inter_400Regular" }} numberOfLines={1}>
            {uProfession || "Meslek seçin..."}
          </Text>
          <Feather name={profDropOpen ? "chevron-up" : "chevron-down"} size={16} color={colors.mutedForeground} />
        </TouchableOpacity>

        {profDropOpen && (
          <View style={[styles.profInlineList, { backgroundColor: colors.muted, borderColor: colors.primary }]}>
            {MESLEKLER.map((m, i) => {
              const isSelected = uProfession === m;
              return (
                <TouchableOpacity
                  key={m}
                  style={[
                    styles.profInlineItem,
                    { borderBottomColor: colors.border },
                    i === MESLEKLER.length - 1 && { borderBottomWidth: 0 },
                    isSelected && { backgroundColor: colors.primary + "20" },
                  ]}
                  onPress={() => { setUProfession(m); setProfDropOpen(false); }}
                  activeOpacity={0.75}
                >
                  <Text style={[styles.profInlineText, { color: isSelected ? colors.primary : colors.foreground, fontFamily: isSelected ? "Inter_600SemiBold" : "Inter_400Regular" }]}>
                    {m}
                  </Text>
                  {isSelected && <Feather name="check" size={14} color={colors.primary} />}
                </TouchableOpacity>
              );
            })}
          </View>
        )}

        {/* Telefon — tam genişlik */}
        <Text style={[styles.formLabel, { color: colors.foreground, marginTop: 12 }]}>Telefon</Text>
        <TextInput
          style={[styles.formInput, { backgroundColor: colors.muted, color: colors.foreground, borderColor: colors.border }]}
          value={uPhone}
          onChangeText={setUPhone}
          placeholder="05XX XXX XX XX"
          placeholderTextColor={colors.mutedForeground}
          keyboardType="phone-pad"
        />

        <Text style={[styles.formLabel, { color: colors.foreground, marginTop: 12 }]}>Şirket / Firma</Text>
        <TextInput
          style={[styles.formInput, { backgroundColor: colors.muted, color: colors.foreground, borderColor: colors.border }]}
          value={uCompany}
          onChangeText={setUCompany}
          placeholder="Örn: ABC Taşeronluk"
          placeholderTextColor={colors.mutedForeground}
        />

        <Text style={[styles.formLabel, { color: colors.foreground, marginTop: 12 }]}>Adres</Text>
        <TextInput
          style={[styles.formInput, { backgroundColor: colors.muted, color: colors.foreground, borderColor: colors.border, minHeight: 64, textAlignVertical: "top" }]}
          value={uAddress}
          onChangeText={setUAddress}
          placeholder="İl, İlçe..."
          placeholderTextColor={colors.mutedForeground}
          multiline
        />

        <Text style={[styles.formLabel, { color: colors.foreground, marginTop: 12 }]}>Rol</Text>
        <View style={styles.chips}>
          {roles.map((r) => {
            const rColor = getRoleColor(r.id);
            return (
              <TouchableOpacity
                key={r.id}
                onPress={() => setURoleId(r.id)}
                style={[styles.chip, { backgroundColor: uRoleId === r.id ? rColor : colors.muted }]}
              >
                <Text style={[styles.chipText, { color: uRoleId === r.id ? "#fff" : colors.foreground }]}>
                  {r.name}
                </Text>
              </TouchableOpacity>
            );
          })}
        </View>

        <Text style={[styles.formLabel, { color: colors.foreground, marginTop: 4 }]}>PIN (Opsiyonel, 4 haneli)</Text>
        <TextInput
          style={[styles.formInput, { backgroundColor: colors.muted, color: colors.foreground, borderColor: colors.border }]}
          value={uPin}
          onChangeText={(v) => { if (v.length <= 4 && /^\d*$/.test(v)) setUPin(v); }}
          placeholder="Boş bırakılırsa şifresiz"
          placeholderTextColor={colors.mutedForeground}
          keyboardType="number-pad"
          secureTextEntry
          maxLength={4}
        />

        <PrimaryButton label="Kaydet" onPress={saveUser} style={{ marginTop: 12 }} />
        {editUserId ? (
          <PrimaryButton label="Sil" variant="danger" onPress={removeUser} style={{ marginTop: 10 }} />
        ) : null}
      </BottomSheet>

      <BottomSheet
        visible={roleSheet}
        onClose={() => setRoleSheet(false)}
        title="Rol İzinleri"
      >
        <ScrollView showsVerticalScrollIndicator={false}>
          <Text style={[styles.roleEditName, { color: colors.primary }]}>
            {roles.find((r) => r.id === editRoleId)?.name}
          </Text>
          <Text style={[styles.roleEditHint, { color: colors.mutedForeground }]}>
            Her sayfa için erişim seviyesini seçin
          </Text>

          {ALL_PAGE_KEYS.map((pageKey) => (
            <View
              key={pageKey}
              style={[styles.permRow, { borderBottomColor: colors.muted }]}
            >
              <Text
                style={[styles.permPageName, { color: colors.foreground }]}
              >
                {PAGE_LABELS[pageKey]}
              </Text>
              <View style={styles.permBtns}>
                {PERM_OPTIONS.map((opt) => (
                  <TouchableOpacity
                    key={opt.value}
                    onPress={() => setPermForPage(pageKey, opt.value)}
                    style={[
                      styles.permBtn,
                      {
                        backgroundColor:
                          editPerms[pageKey] === opt.value
                            ? opt.color
                            : colors.muted,
                      },
                    ]}
                  >
                    <Text
                      style={[
                        styles.permBtnText,
                        {
                          color:
                            editPerms[pageKey] === opt.value
                              ? "#fff"
                              : colors.mutedForeground,
                        },
                      ]}
                    >
                      {opt.label}
                    </Text>
                  </TouchableOpacity>
                ))}
              </View>
            </View>
          ))}

          <PrimaryButton
            label="Kaydet"
            onPress={saveRole}
            style={{ marginTop: 16, marginBottom: 8 }}
          />
        </ScrollView>
      </BottomSheet>

    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  tabs: {
    flexDirection: "row",
    marginHorizontal: 16,
    marginTop: 12,
    borderRadius: 10,
    padding: 4,
  },
  tab: {
    flex: 1,
    paddingVertical: 8,
    alignItems: "center",
    borderRadius: 8,
  },
  tabActive: { backgroundColor: "#fff" },
  tabText: { fontSize: 13, fontFamily: "Inter_600SemiBold" },
  list: { padding: 16, gap: 10 },
  empty: { alignItems: "center", paddingTop: 40, gap: 12 },
  emptyTitle: { fontSize: 18, fontFamily: "Inter_700Bold" },
  emptyDesc: {
    fontSize: 14,
    fontFamily: "Inter_400Regular",
    textAlign: "center",
  },
  card: {
    borderRadius: 12,
    padding: 14,
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  avatar: {
    width: 44,
    height: 44,
    borderRadius: 22,
    justifyContent: "center",
    alignItems: "center",
  },
  avatarText: { fontSize: 18, fontFamily: "Inter_700Bold" },
  cardTitle: { fontSize: 15, fontFamily: "Inter_600SemiBold" },
  cardMeta: { flexDirection: "row", alignItems: "center", gap: 8, marginTop: 4 },
  cardSub: { fontSize: 12, fontFamily: "Inter_400Regular", marginTop: 4 },
  rolePill: { paddingHorizontal: 8, paddingVertical: 3, borderRadius: 999 },
  rolePillText: { fontSize: 11, fontFamily: "Inter_600SemiBold" },
  roleIcon: {
    width: 44,
    height: 44,
    borderRadius: 22,
    justifyContent: "center",
    alignItems: "center",
  },
  roleHead: { flexDirection: "row", alignItems: "center", gap: 8 },
  adminBadge: { paddingHorizontal: 8, paddingVertical: 3, borderRadius: 999 },
  adminBadgeText: {
    fontSize: 10,
    fontFamily: "Inter_600SemiBold",
    color: "#e85d04",
  },
  formLabel: { fontSize: 14, fontFamily: "Inter_600SemiBold", marginBottom: 8 },
  formInput: {
    fontSize: 15,
    fontFamily: "Inter_400Regular",
    borderRadius: 10,
    paddingVertical: 12,
    paddingHorizontal: 14,
    borderWidth: 1,
  },
  row: { flexDirection: "row", gap: 8 },
  chips: { flexDirection: "row", flexWrap: "wrap", gap: 8, marginBottom: 14 },
  chip: { paddingHorizontal: 14, paddingVertical: 8, borderRadius: 999 },
  chipText: { fontSize: 13, fontFamily: "Inter_500Medium" },
  roleEditName: {
    fontSize: 17,
    fontFamily: "Inter_700Bold",
    marginBottom: 4,
  },
  roleEditHint: {
    fontSize: 13,
    fontFamily: "Inter_400Regular",
    marginBottom: 16,
  },
  permRow: {
    paddingVertical: 12,
    borderBottomWidth: StyleSheet.hairlineWidth,
    gap: 8,
  },
  permPageName: { fontSize: 14, fontFamily: "Inter_600SemiBold" },
  permBtns: { flexDirection: "row", gap: 6 },
  permBtn: {
    flex: 1,
    paddingVertical: 7,
    borderRadius: 8,
    alignItems: "center",
  },
  permBtnText: { fontSize: 11, fontFamily: "Inter_600SemiBold" },

  profTrigger: { flexDirection: "row", alignItems: "center" },
  profInlineList: { borderWidth: 1.5, borderRadius: 10, marginTop: 4, overflow: "hidden" },
  profInlineItem: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingHorizontal: 14, paddingVertical: 12, borderBottomWidth: StyleSheet.hairlineWidth },
  profInlineText: { fontSize: 14 },
});
