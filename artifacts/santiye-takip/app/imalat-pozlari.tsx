import { Feather } from "@expo/vector-icons";
import * as DocumentPicker from "expo-document-picker";
import * as FileSystem from "expo-file-system";
import { useRouter } from "expo-router";
import * as Sharing from "expo-sharing";
import React, { useMemo, useState } from "react";
import {
  Alert,
  FlatList,
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
import FormInput from "@/components/FormInput";
import PrimaryButton from "@/components/PrimaryButton";
import { useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";
import {
  ImalatPoz,
  IMALAT_POZ_KATEGORILERI,
  buildImalatPozCsv,
  parseImalatPozCsv,
} from "@/constants/imalatPozlari";

interface PF {
  code: string;
  category: string;
  name: string;
  unit: string;
  description: string;
}

const EMPTY: PF = { code: "", category: IMALAT_POZ_KATEGORILERI[0], name: "", unit: "", description: "" };

export default function ImalatPozlariScreen() {
  const colors = useColors();
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const topPad = Platform.OS === "web" ? 16 : insets.top;
  const { imalatPozlari, addImalatPoz, updateImalatPoz, deleteImalatPoz, currentRole } = useApp();
  const isAdmin = currentRole?.isAdmin === true;

  const [search, setSearch] = useState("");
  const [catFilter, setCatFilter] = useState<string | null>(null);
  const [visible, setVisible] = useState(false);
  const [editCode, setEditCode] = useState<string | null>(null);
  const [form, setForm] = useState<PF>(EMPTY);
  const [importVisible, setImportVisible] = useState(false);
  const [importText, setImportText] = useState("");
  const [busy, setBusy] = useState(false);

  const categories = useMemo(() => {
    const set = new Set<string>(IMALAT_POZ_KATEGORILERI as readonly string[]);
    imalatPozlari.forEach((p) => p.category && set.add(p.category));
    return Array.from(set);
  }, [imalatPozlari]);

  const list = useMemo(() => {
    const q = search.trim().toLowerCase();
    return imalatPozlari
      .filter((p) => (catFilter ? p.category === catFilter : true))
      .filter((p) =>
        q
          ? p.code.toLowerCase().includes(q) ||
            p.name.toLowerCase().includes(q) ||
            (p.description || "").toLowerCase().includes(q)
          : true
      )
      .sort((a, b) => a.code.localeCompare(b.code, "tr"));
  }, [imalatPozlari, catFilter, search]);

  function open(p?: ImalatPoz) {
    if (p) {
      setEditCode(p.code);
      setForm({
        code: p.code,
        category: p.category || IMALAT_POZ_KATEGORILERI[0],
        name: p.name,
        unit: p.unit,
        description: p.description || "",
      });
    } else {
      setEditCode(null);
      setForm(EMPTY);
    }
    setVisible(true);
  }

  function save() {
    const code = form.code.trim();
    const name = form.name.trim();
    const unit = form.unit.trim();
    if (!code || !name || !unit) {
      Alert.alert("Eksik bilgi", "Poz kodu, adı ve birimi zorunlu.");
      return;
    }
    const data: ImalatPoz = {
      code,
      category: form.category.trim() || "Diğer",
      name,
      unit,
      description: form.description.trim() || undefined,
    };
    if (editCode) {
      updateImalatPoz(editCode, data);
    } else {
      if (imalatPozlari.some((p) => p.code.toLowerCase() === code.toLowerCase())) {
        Alert.alert("Mevcut poz", "Bu poz kodu zaten kayıtlı.");
        return;
      }
      addImalatPoz(data);
    }
    setVisible(false);
  }

  function applyImport(text: string) {
    const result = parseImalatPozCsv(text);
    if (result.rows.length === 0) {
      Alert.alert(
        "İçe aktarma başarısız",
        result.errors.length > 0
          ? result.errors.slice(0, 5).join("\n")
          : "Hiç geçerli satır bulunamadı."
      );
      return;
    }
    let added = 0;
    let updated = 0;
    const existing = new Set(imalatPozlari.map((p) => p.code.toLowerCase()));
    for (const r of result.rows) {
      if (existing.has(r.code.toLowerCase())) {
        updateImalatPoz(r.code, r);
        updated++;
      } else {
        addImalatPoz(r);
        added++;
      }
    }
    setImportVisible(false);
    setImportText("");
    const lines = [
      `${added} yeni poz eklendi.`,
      `${updated} mevcut poz güncellendi.`,
    ];
    if (result.duplicates.length > 0)
      lines.push(`${result.duplicates.length} satır içeride tekrar olduğu için atlandı.`);
    if (result.errors.length > 0)
      lines.push(`${result.errors.length} satır hatalı (kod/ad/birim eksik).`);
    Alert.alert("İçe aktarıldı", lines.join("\n"));
  }

  async function pickCsvFile() {
    try {
      setBusy(true);
      const res = await DocumentPicker.getDocumentAsync({
        type: ["text/csv", "text/comma-separated-values", "application/vnd.ms-excel", "text/plain", "*/*"],
        copyToCacheDirectory: true,
      });
      if (res.canceled || !res.assets?.[0]) return;
      const asset = res.assets[0];
      let text = "";
      if (Platform.OS === "web" && (asset as any).file) {
        text = await ((asset as any).file as File).text();
      } else {
        text = await (FileSystem as any).readAsStringAsync(asset.uri, { encoding: "utf8" });
      }
      applyImport(text);
    } catch (e: any) {
      Alert.alert("Hata", String(e?.message || e));
    } finally {
      setBusy(false);
    }
  }

  async function exportCsv() {
    try {
      setBusy(true);
      const csv = buildImalatPozCsv(imalatPozlari);
      if (Platform.OS === "web") {
        const blob = new Blob([csv], { type: "text/csv;charset=utf-8" });
        const url = URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.href = url;
        a.download = "imalat-pozlari.csv";
        document.body.appendChild(a);
        a.click();
        a.remove();
        URL.revokeObjectURL(url);
      } else {
        const dir = (FileSystem as any).cacheDirectory ?? (FileSystem as any).documentDirectory;
        const fileUri = `${dir}imalat-pozlari.csv`;
        await (FileSystem as any).writeAsStringAsync(fileUri, csv, { encoding: "utf8" });
        if (await Sharing.isAvailableAsync()) {
          await Sharing.shareAsync(fileUri, { mimeType: "text/csv", dialogTitle: "İmalat Pozlarını Paylaş" });
        } else {
          Alert.alert("Kaydedildi", fileUri);
        }
      }
    } catch (e: any) {
      Alert.alert("Hata", String(e?.message || e));
    } finally {
      setBusy(false);
    }
  }

  function openImportSheet() {
    setImportText("");
    setImportVisible(true);
  }

  function remove() {
    if (!editCode) return;
    Alert.alert("Sil", `${editCode} pozu silinsin mi?`, [
      { text: "Vazgeç", style: "cancel" },
      {
        text: "Sil",
        style: "destructive",
        onPress: () => {
          deleteImalatPoz(editCode);
          setVisible(false);
        },
      },
    ]);
  }

  if (!isAdmin) {
    return (
      <View style={[styles.root, { backgroundColor: colors.background, alignItems: "center", justifyContent: "center", padding: 24 }]}>
        <Text style={{ color: colors.mutedForeground, textAlign: "center" }}>
          Bu sayfa sadece yöneticiler içindir.
        </Text>
        <TouchableOpacity onPress={() => router.back()} style={{ marginTop: 16 }}>
          <Text style={{ color: colors.primary, fontFamily: "Inter_600SemiBold" }}>Geri</Text>
        </TouchableOpacity>
      </View>
    );
  }

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <View style={[styles.header, { backgroundColor: colors.secondary, paddingTop: topPad + 12 }]}>
        <TouchableOpacity
          onPress={() => (router.canGoBack() ? router.back() : router.replace("/" as any))}
          style={styles.backBtn}
        >
          <Feather name="arrow-left" size={22} color={colors.secondaryForeground} />
        </TouchableOpacity>
        <Text style={[styles.headerTitle, { color: colors.secondaryForeground }]}>
          İmalat Poz Tarifleri
        </Text>
        <TouchableOpacity onPress={openImportSheet} style={styles.backBtn} disabled={busy}>
          <Feather name="upload" size={20} color={colors.secondaryForeground} />
        </TouchableOpacity>
        <TouchableOpacity onPress={exportCsv} style={styles.backBtn} disabled={busy}>
          <Feather name="download" size={20} color={colors.secondaryForeground} />
        </TouchableOpacity>
        <TouchableOpacity onPress={() => open()} style={styles.backBtn}>
          <Feather name="plus" size={22} color={colors.secondaryForeground} />
        </TouchableOpacity>
      </View>

      <View style={[styles.searchBar, { backgroundColor: colors.card, borderColor: colors.border }]}>
        <Feather name="search" size={16} color={colors.mutedForeground} />
        <TextInput
          value={search}
          onChangeText={setSearch}
          placeholder="Poz kodu, adı veya açıklama ara"
          placeholderTextColor={colors.mutedForeground}
          style={[styles.searchInput, { color: colors.foreground }]}
        />
      </View>

      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        contentContainerStyle={styles.catFilters}
        style={styles.catFiltersWrap}
      >
        <TouchableOpacity
          onPress={() => setCatFilter(null)}
          style={[styles.catChip, { backgroundColor: catFilter === null ? colors.primary : colors.muted }]}
        >
          <Text style={[styles.catChipText, { color: catFilter === null ? "#fff" : colors.foreground }]}>
            Tümü ({imalatPozlari.length})
          </Text>
        </TouchableOpacity>
        {categories.map((c) => {
          const count = imalatPozlari.filter((p) => p.category === c).length;
          if (count === 0) return null;
          const active = catFilter === c;
          return (
            <TouchableOpacity
              key={c}
              onPress={() => setCatFilter(active ? null : c)}
              style={[styles.catChip, { backgroundColor: active ? colors.primary : colors.muted }]}
            >
              <Text
                style={[styles.catChipText, { color: active ? "#fff" : colors.foreground }]}
                numberOfLines={1}
              >
                {c} ({count})
              </Text>
            </TouchableOpacity>
          );
        })}
      </ScrollView>

      <FlatList
        data={list}
        keyExtractor={(p) => p.code}
        contentContainerStyle={{ padding: 16, paddingBottom: insets.bottom + 24, gap: 8 }}
        ListEmptyComponent={
          <Text style={{ color: colors.mutedForeground, textAlign: "center", marginTop: 24 }}>
            Poz bulunamadı.
          </Text>
        }
        renderItem={({ item }) => (
          <TouchableOpacity
            onPress={() => open(item)}
            activeOpacity={0.85}
            style={[styles.row, { backgroundColor: colors.card, borderColor: colors.border }]}
          >
            <View style={[styles.codeBox, { backgroundColor: colors.primary + "15" }]}>
              <Text style={[styles.codeText, { color: colors.primary }]}>{item.code}</Text>
            </View>
            <View style={{ flex: 1 }}>
              <Text style={[styles.rowTitle, { color: colors.foreground }]} numberOfLines={2}>
                {item.name}
              </Text>
              <View style={styles.metaRow}>
                <Text style={[styles.meta, { color: colors.mutedForeground }]}>{item.category}</Text>
                <View style={[styles.unitBadge, { backgroundColor: colors.muted }]}>
                  <Text style={[styles.unitText, { color: colors.foreground }]}>{item.unit}</Text>
                </View>
              </View>
              {item.description ? (
                <Text style={[styles.desc, { color: colors.mutedForeground }]}>
                  {item.description}
                </Text>
              ) : null}
            </View>
            <Feather name="chevron-right" size={18} color={colors.mutedForeground} />
          </TouchableOpacity>
        )}
      />

      <BottomSheet
        visible={visible}
        onClose={() => setVisible(false)}
        title={editCode ? "Pozu Düzenle" : "Yeni Poz"}
      >
        <FormInput
          label="Poz Kodu"
          value={form.code}
          onChangeText={(v) => setForm({ ...form, code: v })}
          placeholder="Örn: 15.001/3A"
        />
        <Text style={[styles.label, { color: colors.foreground }]}>Kategori</Text>
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={{ gap: 6, paddingVertical: 4, paddingBottom: 10 }}
          style={{ flexGrow: 0, flexShrink: 0 }}
        >
          {categories.map((c) => {
            const active = form.category === c;
            return (
              <TouchableOpacity
                key={c}
                onPress={() => setForm({ ...form, category: c })}
                style={[styles.catChip, { backgroundColor: active ? colors.primary : colors.muted }]}
              >
                <Text
                  style={[styles.catChipText, { color: active ? "#fff" : colors.foreground }]}
                  numberOfLines={1}
                >
                  {c}
                </Text>
              </TouchableOpacity>
            );
          })}
        </ScrollView>
        <FormInput
          label="Poz Adı"
          value={form.name}
          onChangeText={(v) => setForm({ ...form, name: v })}
          placeholder="Örn: C25/30 hazır beton dökümü"
        />
        <FormInput
          label="Birim"
          value={form.unit}
          onChangeText={(v) => setForm({ ...form, unit: v })}
          placeholder="m², m³, ton, ad, m..."
        />
        <FormInput
          label="Tarif / Açıklama"
          value={form.description}
          onChangeText={(v) => setForm({ ...form, description: v })}
          placeholder="İsteğe bağlı uzun tarif (Enter ile satır eklenebilir)"
          multiline
          numberOfLines={6}
          textAlignVertical="top"
          style={{ minHeight: 120, paddingTop: 12 }}
        />
        <PrimaryButton label="Kaydet" onPress={save} style={{ marginTop: 8 }} />
        {editCode ? (
          <PrimaryButton label="Sil" variant="danger" onPress={remove} style={{ marginTop: 10 }} />
        ) : null}
      </BottomSheet>

      <BottomSheet
        visible={importVisible}
        onClose={() => setImportVisible(false)}
        title="CSV / Excel İçe Aktar"
      >
        <Text style={[styles.helpText, { color: colors.mutedForeground }]}>
          Format: kod;kategori;ad;birim;tarif{"\n"}
          İlk satır başlık olabilir. Ayraç olarak ; , veya TAB desteklenir.{"\n"}
          Tarif içinde \n yazarak satır kırılması ekleyebilirsiniz.{"\n"}
          Mevcut kodlar güncellenir, yeni kodlar eklenir.
        </Text>
        <PrimaryButton
          label={busy ? "Yükleniyor..." : "Dosya Seç (CSV)"}
          onPress={pickCsvFile}
          style={{ marginTop: 4 }}
        />
        <Text style={[styles.label, { color: colors.foreground, marginTop: 16 }]}>
          veya CSV içeriğini yapıştırın
        </Text>
        <FormInput
          label=""
          value={importText}
          onChangeText={setImportText}
          placeholder={"kod;kategori;ad;birim;tarif\nY.99.001;Diğer;Örnek poz;m²;Açıklama"}
          multiline
          numberOfLines={8}
          textAlignVertical="top"
          style={{ minHeight: 160, paddingTop: 12, fontFamily: "Inter_400Regular" }}
        />
        <PrimaryButton
          label="Yapıştırılanı İçe Aktar"
          onPress={() => applyImport(importText)}
          style={{ marginTop: 8 }}
        />
      </BottomSheet>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  header: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 12,
    paddingBottom: 14,
    gap: 8,
  },
  backBtn: { width: 40, height: 40, borderRadius: 20, alignItems: "center", justifyContent: "center" },
  headerTitle: {
    flex: 1,
    fontSize: 18,
    fontWeight: "700",
    textAlign: "center",
    fontFamily: "Inter_700Bold",
  },
  searchBar: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    paddingHorizontal: 14,
    height: 44,
    margin: 12,
    borderRadius: 10,
    borderWidth: 1,
  },
  searchInput: { flex: 1, fontSize: 14, fontFamily: "Inter_400Regular" },
  catFiltersWrap: { flexGrow: 0, flexShrink: 0, maxHeight: 52 },
  catFilters: {
    paddingHorizontal: 12,
    paddingBottom: 10,
    gap: 6,
    flexDirection: "row",
    alignItems: "center",
  },
  catChip: {
    paddingHorizontal: 12,
    height: 32,
    justifyContent: "center",
    borderRadius: 999,
    maxWidth: 220,
  },
  catChipText: { fontSize: 12, fontFamily: "Inter_500Medium" },
  row: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    padding: 12,
    borderRadius: 12,
    borderWidth: 1,
  },
  codeBox: {
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 8,
    minWidth: 70,
    alignItems: "center",
  },
  codeText: { fontSize: 11, fontFamily: "Inter_700Bold", letterSpacing: 0.3 },
  rowTitle: { fontSize: 14, fontFamily: "Inter_600SemiBold" },
  metaRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    marginTop: 4,
  },
  meta: { fontSize: 11, fontFamily: "Inter_400Regular", flex: 1 },
  unitBadge: { paddingHorizontal: 8, paddingVertical: 2, borderRadius: 999 },
  unitText: { fontSize: 11, fontFamily: "Inter_600SemiBold" },
  desc: { fontSize: 11, fontFamily: "Inter_400Regular", marginTop: 4, lineHeight: 16 },
  label: {
    fontSize: 13,
    fontFamily: "Inter_600SemiBold",
    marginTop: 4,
    marginBottom: 6,
  },
  helpText: {
    fontSize: 12,
    fontFamily: "Inter_400Regular",
    lineHeight: 18,
    marginBottom: 12,
  },
});
