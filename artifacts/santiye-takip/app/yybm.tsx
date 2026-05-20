import { Feather } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import * as WebBrowser from "expo-web-browser";
import React, { useState } from "react";
import {
  Alert,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import { useColors } from "@/hooks/useColors";
import {
  YYBM_DONEMLER,
  YYBM_DONEM_MAP,
  type YybmDonem,
  artisOrani,
  formatFiyat,
} from "@/constants/yybm";

const COLS = 4;

export default function YYBMScreen() {
  const colors = useColors();
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const topPad = Platform.OS === "web" ? 16 : insets.top;

  const [seciliIds, setSeciliIds] = useState<string[]>([]);
  const [karsilastirmaGoster, setKarsilastirmaGoster] = useState(false);

  function donemSecToggle(id: string) {
    setSeciliIds((prev) =>
      prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id]
    );
    setKarsilastirmaGoster(false);
  }

  async function pdfAc(donem: YybmDonem) {
    if (!donem.pdfMevcut) return;
    const url = donem.pdfUrl;
    try {
      if (Platform.OS === "web") {
        const fullUrl =
          typeof window !== "undefined"
            ? window.location.origin + url
            : url;
        window.open(fullUrl, "_blank");
      } else {
        const base =
          typeof process !== "undefined" && process.env["EXPO_PUBLIC_API_BASE"]
            ? process.env["EXPO_PUBLIC_API_BASE"]
            : "https://689a4caa-af33-4c75-a1a6-b3449c5db588-00-xsp1uioahgyj.janeway.replit.dev";
        await WebBrowser.openBrowserAsync(base + url);
      }
    } catch {
      Alert.alert("Hata", "PDF açılırken bir sorun oluştu.");
    }
  }

  function karsilastir() {
    if (seciliIds.length >= 2) {
      setKarsilastirmaGoster(true);
    }
  }

  const siraliSecili = [...seciliIds].sort((a, b) => {
    const da = YYBM_DONEM_MAP[a];
    const db = YYBM_DONEM_MAP[b];
    if (!da || !db) return 0;
    if (da.yil !== db.yil) return da.yil - db.yil;
    return (da.altDonem ?? 0) - (db.altDonem ?? 0);
  });

  // Pad grid to a multiple of COLS
  const padded = [...YYBM_DONEMLER];
  while (padded.length % COLS !== 0) padded.push(null as unknown as YybmDonem);

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <View
        style={[
          styles.header,
          { backgroundColor: colors.secondary, paddingTop: topPad + 12 },
        ]}
      >
        <TouchableOpacity
          onPress={() => {
            if (router.canGoBack()) router.back();
            else router.replace("/ayarlar" as any);
          }}
          style={styles.backBtn}
        >
          <Feather name="arrow-left" size={22} color={colors.secondaryForeground} />
        </TouchableOpacity>
        <Text style={[styles.headerTitle, { color: colors.secondaryForeground }]}>
          Yapı Yaklaşık Birim Maliyetleri
        </Text>
        <View style={{ width: 40 }} />
      </View>

      <ScrollView
        contentContainerStyle={[styles.scroll, { paddingBottom: insets.bottom + 32 }]}
        showsVerticalScrollIndicator={false}
      >
        <Text style={[styles.aciklama, { color: colors.mutedForeground }]}>
          T.C. Çevre, Şehircilik ve İklim Değişikliği Bakanlığı tarafından yayımlanan tebliğler.
          Mimarlık ve mühendislik hizmet bedellerinin hesabında kullanılır.
        </Text>

        <View style={[styles.pickerCard, { backgroundColor: colors.card, borderColor: colors.secondary + "40" }]}>
          <View style={styles.gridBaslik}>
            <Feather name="calendar" size={15} color={colors.mutedForeground} />
            <Text style={[styles.gridBaslikText, { color: colors.mutedForeground }]}>
              Dönem seçin
            </Text>
          </View>

          <View style={styles.grid}>
            {padded.map((donem, idx) => {
              if (!donem) {
                return <View key={`empty-${idx}`} style={styles.donemBosHucre} />;
              }
              const secili = seciliIds.includes(donem.id);
              const eskiYapi = donem.yapiSinifiTipi === "eski";
              return (
                <TouchableOpacity
                  key={donem.id}
                  onPress={() => donemSecToggle(donem.id)}
                  style={[
                    styles.donemBtn,
                    {
                      backgroundColor: secili
                        ? "#1a6e4a"
                        : colors.card,
                      borderWidth: secili ? 0 : 1,
                      borderColor: colors.secondary + "60",
                    },
                  ]}
                >
                  <Text
                    style={[
                      styles.donemBtnText,
                      {
                        color: secili ? "#4fffb0" : colors.foreground,
                        fontFamily: secili ? "JetBrainsMono_700Bold" : "JetBrainsMono_400Regular",
                      },
                    ]}
                  >
                    {donem.etiket}
                  </Text>
                  {donem.pdfMevcut && !secili && (
                    <View style={[styles.pdfDot, { backgroundColor: eskiYapi ? "#aaa" : "#4fffb0" }]} />
                  )}
                </TouchableOpacity>
              );
            })}
          </View>

          <View style={[styles.lejand, { borderTopColor: colors.secondary + "30" }]}>
            <View style={styles.lejandItem}>
              <View style={[styles.lejandDot, { backgroundColor: "#4fffb0" }]} />
              <Text style={[styles.lejandText, { color: colors.mutedForeground }]}>Yeni sınıf yapısı (2025+)</Text>
            </View>
            <View style={styles.lejandItem}>
              <View style={[styles.lejandDot, { backgroundColor: "#aaa" }]} />
              <Text style={[styles.lejandText, { color: colors.mutedForeground }]}>Eski sınıf yapısı (2020–2024)</Text>
            </View>
          </View>

          {seciliIds.length > 0 && (
            <View style={[styles.seciliInfo, { borderTopColor: colors.secondary + "30" }]}>
              <Text style={[styles.seciliLabel, { color: colors.mutedForeground }]}>
                Seçili:{" "}
                <Text style={{ color: colors.foreground }}>
                  {siraliSecili.join(", ")}
                </Text>
              </Text>
            </View>
          )}

          <View style={styles.btnSatir}>
            <TouchableOpacity
              onPress={() => {
                setSeciliIds([]);
                setKarsilastirmaGoster(false);
              }}
              style={[styles.iptalBtn, { backgroundColor: colors.secondary }]}
            >
              <Text style={[styles.iptalBtnText, { color: colors.secondaryForeground }]}>
                Temizle
              </Text>
            </TouchableOpacity>

            {seciliIds.length === 1 && YYBM_DONEM_MAP[seciliIds[0]!] && (
              <TouchableOpacity
                onPress={() => pdfAc(YYBM_DONEM_MAP[seciliIds[0]!]!)}
                style={styles.aksiyonBtn}
              >
                <Feather name="file-text" size={16} color="#fff" />
                <Text style={styles.aksiyonBtnText}>PDF Görüntüle</Text>
              </TouchableOpacity>
            )}

            {seciliIds.length >= 2 && (
              <TouchableOpacity
                onPress={karsilastir}
                style={[styles.aksiyonBtn, { backgroundColor: "#1a6e4a" }]}
              >
                <Feather name="bar-chart-2" size={16} color="#4fffb0" />
                <Text style={[styles.aksiyonBtnText, { color: "#4fffb0" }]}>
                  Fiyatları Mukayese Et
                </Text>
              </TouchableOpacity>
            )}
          </View>
        </View>

        {seciliIds.length === 1 && YYBM_DONEM_MAP[seciliIds[0]!] && (
          <DonemDetay
            donem={YYBM_DONEM_MAP[seciliIds[0]!]!}
            colors={colors}
            onPdfAc={pdfAc}
          />
        )}

        {karsilastirmaGoster && siraliSecili.length >= 2 && (
          <KarsilastirmaTablosu
            donemIds={siraliSecili}
            colors={colors}
          />
        )}
      </ScrollView>
    </View>
  );
}

function DonemDetay({
  donem,
  colors,
  onPdfAc,
}: {
  donem: YybmDonem;
  colors: ReturnType<typeof import("@/hooks/useColors").useColors>;
  onPdfAc: (d: YybmDonem) => void;
}) {
  return (
    <View style={{ marginTop: 16 }}>
      <View style={styles.bolumBaslik}>
        <Text style={[styles.bolumBaslikText, { color: colors.foreground }]}>
          {donem.etiket} Dönemi Yapı Sınıfları
        </Text>
        <Text style={[styles.bolumAlt, { color: colors.mutedForeground }]}>
          Resmî Gazete: {donem.gazeteKarariTarihi} — Sayı: {donem.gazeteNo}
        </Text>
      </View>

      <TouchableOpacity
        onPress={() => onPdfAc(donem)}
        style={[styles.pdfBtn, { borderColor: "#4fffb0" + "40", backgroundColor: "#1a6e4a" + "20" }]}
      >
        <Feather name="file-text" size={18} color="#4fffb0" />
        <Text style={[styles.pdfBtnText, { color: "#4fffb0" }]}>
          Resmî Gazete Tebliğini Aç (PDF)
        </Text>
        <Feather name="external-link" size={14} color="#4fffb0" />
      </TouchableOpacity>

      {donem.yapiSinifiTipi === "eski" && (
        <View style={[styles.uyariSatir, { backgroundColor: colors.secondary + "30", borderColor: colors.secondary + "60" }]}>
          <Feather name="info" size={13} color={colors.mutedForeground} />
          <Text style={[styles.uyariText, { color: colors.mutedForeground }]}>
            Bu dönem eski sınıf yapısını kullanır (I–V, A–D). 2025 sonrası tebliğlerle karşılaştırma yapılamaz.
          </Text>
        </View>
      )}

      {donem.siniflar.map((s) => (
        <View
          key={s.kod}
          style={[styles.sinifKart, { backgroundColor: colors.card, borderColor: colors.secondary + "30" }]}
        >
          <View style={styles.sinifUst}>
            <View style={[styles.sinifKodBadge, { backgroundColor: "#1a6e4a" }]}>
              <Text style={[styles.sinifKod, { color: "#4fffb0" }]}>{s.kod}</Text>
            </View>
            <Text style={[styles.sinifFiyat, { color: colors.foreground }]}>
              {formatFiyat(s.fiyat)}
            </Text>
          </View>
          <Text style={[styles.sinifGrup, { color: colors.foreground }]}>{s.grup}</Text>
          <Text style={[styles.sinifAciklama, { color: colors.mutedForeground }]}>{s.aciklama}</Text>
        </View>
      ))}
    </View>
  );
}

function KarsilastirmaTablosu({
  donemIds,
  colors,
}: {
  donemIds: string[];
  colors: ReturnType<typeof import("@/hooks/useColors").useColors>;
}) {
  const donemler = donemIds.map((id) => YYBM_DONEM_MAP[id]).filter(Boolean) as YybmDonem[];
  if (donemler.length < 2) return null;

  // Only allow same-type comparison
  const tipler = new Set(donemler.map((d) => d.yapiSinifiTipi));
  const karisik = tipler.size > 1;

  if (karisik) {
    return (
      <View style={{ marginTop: 16 }}>
        <View style={[styles.uyariKart, { backgroundColor: colors.card, borderColor: "#ff6b6b40" }]}>
          <Feather name="alert-triangle" size={18} color="#ff6b6b" />
          <Text style={[styles.uyariKartText, { color: colors.mutedForeground }]}>
            Eski sınıf yapısı (2020–2024) ile yeni sınıf yapısı (2025+) dönemleri farklı sınıflar içerdiğinden
            doğrudan karşılaştırma yapılamaz. Lütfen aynı yapı sistemine ait dönemleri seçin.
          </Text>
        </View>
      </View>
    );
  }

  const ilk = donemler[0]!;
  const son = donemler[donemler.length - 1]!;
  const toplamSon = son.siniflar.reduce((s, x) => s + x.fiyat, 0);
  const toplamIlk = ilk.siniflar.reduce((s, x) => s + x.fiyat, 0);
  const genelArtis = artisOrani(toplamIlk, toplamSon);

  return (
    <View style={{ marginTop: 16 }}>
      <View style={styles.bolumBaslik}>
        <Text style={[styles.bolumBaslikText, { color: colors.foreground }]}>
          Mukayese Tablosu — {donemIds.join(" / ")}
        </Text>
        <Text style={[styles.bolumAlt, { color: colors.mutedForeground }]}>
          Genel ortalama artış: %{genelArtis.toFixed(1)}
        </Text>
      </View>

      <View style={[styles.tablo, { backgroundColor: colors.card, borderColor: colors.secondary + "30" }]}>
        <View style={[styles.tabloBaslik, { backgroundColor: colors.secondary }]}>
          <Text style={[styles.tabloBaslikHucre, styles.hucreSinif, { color: colors.secondaryForeground }]}>
            Sınıf
          </Text>
          {donemler.map((d) => (
            <Text key={d.id} style={[styles.tabloBaslikHucre, styles.hucreFiyat, { color: colors.secondaryForeground }]}>
              {d.etiket}
            </Text>
          ))}
          {donemler.length === 2 && (
            <Text style={[styles.tabloBaslikHucre, styles.hucreDegisim, { color: colors.secondaryForeground }]}>
              Artış
            </Text>
          )}
        </View>

        {ilk.siniflar.map((sinif, idx) => {
          const fiyatlar = donemler.map((d) => d.siniflar[idx]?.fiyat ?? 0);
          const degisim =
            donemler.length === 2 && fiyatlar[0]! > 0
              ? artisOrani(fiyatlar[0]!, fiyatlar[fiyatlar.length - 1]!)
              : null;
          const pozitif = degisim !== null && degisim >= 0;

          return (
            <View
              key={sinif.kod}
              style={[
                styles.tabloSatir,
                { borderColor: colors.secondary + "20" },
                idx % 2 === 0 ? {} : { backgroundColor: colors.secondary + "08" },
              ]}
            >
              <Text style={[styles.tabloHucre, styles.hucreSinif, { color: colors.foreground }]}>
                {sinif.kod}
              </Text>
              {fiyatlar.map((f, fi) => (
                <Text key={fi} style={[styles.tabloHucre, styles.hucreFiyat, { color: colors.foreground, fontFamily: "JetBrainsMono_400Regular" }]}>
                  {f.toLocaleString("tr-TR")}
                </Text>
              ))}
              {degisim !== null && (
                <Text
                  style={[
                    styles.tabloHucre,
                    styles.hucreDegisim,
                    { color: pozitif ? "#ff6b6b" : "#4fffb0", fontFamily: "JetBrainsMono_700Bold" },
                  ]}
                >
                  {pozitif ? "+" : ""}{degisim.toFixed(1)}%
                </Text>
              )}
            </View>
          );
        })}
      </View>

      <View style={[styles.ozet, { backgroundColor: "#1a6e4a" + "20", borderColor: "#4fffb0" + "30" }]}>
        <Feather name="info" size={14} color="#4fffb0" />
        <Text style={[styles.ozetText, { color: colors.mutedForeground }]}>
          Fiyatlar KDV hariç, genel giderler (%15) ve yüklenici kârı (%10) dahil olarak
          belirlenmiştir. Kaynak: T.C. Çevre, Şehircilik ve İklim Değişikliği Bakanlığı.
        </Text>
      </View>
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
  backBtn: {
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: "center",
    justifyContent: "center",
  },
  headerTitle: {
    flex: 1,
    fontSize: 16,
    fontWeight: "700",
    textAlign: "center",
    fontFamily: "Inter_700Bold",
  },
  scroll: { padding: 16 },
  aciklama: {
    fontSize: 13,
    fontFamily: "Inter_400Regular",
    lineHeight: 19,
    marginBottom: 16,
  },
  pickerCard: {
    borderRadius: 16,
    borderWidth: 1,
    padding: 16,
  },
  gridBaslik: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
    marginBottom: 14,
  },
  gridBaslikText: {
    fontSize: 12,
    fontFamily: "Inter_600SemiBold",
    letterSpacing: 0.5,
    textTransform: "uppercase",
  },
  grid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 8,
  },
  donemBtn: {
    width: `${(100 / COLS) - 2.5}%` as any,
    paddingVertical: 14,
    borderRadius: 12,
    alignItems: "center",
    justifyContent: "center",
    position: "relative",
    minHeight: 52,
  },
  donemBosHucre: {
    width: `${(100 / COLS) - 2.5}%` as any,
    minHeight: 52,
  },
  donemBtnText: {
    fontSize: 15,
    letterSpacing: 0.5,
  },
  pdfDot: {
    position: "absolute",
    bottom: 5,
    width: 5,
    height: 5,
    borderRadius: 3,
  },
  lejand: {
    flexDirection: "row",
    gap: 16,
    marginTop: 14,
    paddingTop: 12,
    borderTopWidth: 1,
    flexWrap: "wrap",
  },
  lejandItem: {
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
  },
  lejandDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  lejandText: {
    fontSize: 11,
    fontFamily: "Inter_400Regular",
  },
  seciliInfo: {
    marginTop: 14,
    paddingTop: 12,
    borderTopWidth: 1,
  },
  seciliLabel: {
    fontSize: 13,
    fontFamily: "Inter_400Regular",
    textAlign: "center",
  },
  btnSatir: {
    flexDirection: "row",
    gap: 10,
    marginTop: 16,
    alignItems: "center",
  },
  iptalBtn: {
    flex: 1,
    paddingVertical: 14,
    borderRadius: 14,
    alignItems: "center",
  },
  iptalBtnText: {
    fontSize: 15,
    fontFamily: "Inter_600SemiBold",
  },
  aksiyonBtn: {
    flex: 2,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 8,
    paddingVertical: 14,
    borderRadius: 14,
    backgroundColor: "#1c4ed8",
  },
  aksiyonBtnText: {
    fontSize: 14,
    fontFamily: "Inter_700Bold",
    color: "#fff",
  },
  uyariSatir: {
    flexDirection: "row",
    alignItems: "flex-start",
    gap: 8,
    padding: 10,
    borderRadius: 10,
    borderWidth: 1,
    marginBottom: 12,
  },
  uyariText: {
    flex: 1,
    fontSize: 11,
    fontFamily: "Inter_400Regular",
    lineHeight: 16,
  },
  uyariKart: {
    flexDirection: "row",
    alignItems: "flex-start",
    gap: 12,
    padding: 14,
    borderRadius: 12,
    borderWidth: 1,
  },
  uyariKartText: {
    flex: 1,
    fontSize: 13,
    fontFamily: "Inter_400Regular",
    lineHeight: 19,
  },
  bolumBaslik: { marginBottom: 12 },
  bolumBaslikText: {
    fontSize: 16,
    fontFamily: "Inter_700Bold",
    marginBottom: 3,
  },
  bolumAlt: {
    fontSize: 12,
    fontFamily: "Inter_400Regular",
  },
  pdfBtn: {
    flexDirection: "row",
    alignItems: "center",
    gap: 10,
    padding: 14,
    borderRadius: 12,
    borderWidth: 1,
    marginBottom: 14,
  },
  pdfBtnText: {
    flex: 1,
    fontSize: 14,
    fontFamily: "Inter_600SemiBold",
  },
  sinifKart: {
    borderRadius: 12,
    borderWidth: 1,
    padding: 12,
    marginBottom: 8,
  },
  sinifUst: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: 6,
  },
  sinifKodBadge: {
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 8,
  },
  sinifKod: {
    fontSize: 13,
    fontFamily: "JetBrainsMono_700Bold",
    letterSpacing: 0.5,
  },
  sinifFiyat: {
    fontSize: 15,
    fontFamily: "JetBrainsMono_700Bold",
  },
  sinifGrup: {
    fontSize: 13,
    fontFamily: "Inter_600SemiBold",
    marginBottom: 2,
  },
  sinifAciklama: {
    fontSize: 12,
    fontFamily: "Inter_400Regular",
    lineHeight: 17,
  },
  tablo: {
    borderRadius: 12,
    borderWidth: 1,
    overflow: "hidden",
  },
  tabloBaslik: {
    flexDirection: "row",
    paddingVertical: 10,
    paddingHorizontal: 10,
  },
  tabloBaslikHucre: {
    fontSize: 12,
    fontFamily: "Inter_700Bold",
    textAlign: "center",
  },
  tabloSatir: {
    flexDirection: "row",
    paddingVertical: 9,
    paddingHorizontal: 10,
    borderTopWidth: 1,
  },
  tabloHucre: {
    fontSize: 12,
    textAlign: "center",
    fontFamily: "Inter_400Regular",
  },
  hucreSinif: { flex: 1.2, textAlign: "left" },
  hucreFiyat: { flex: 2, textAlign: "right" },
  hucreDegisim: { flex: 1.5, textAlign: "right" },
  ozet: {
    flexDirection: "row",
    alignItems: "flex-start",
    gap: 8,
    marginTop: 12,
    padding: 12,
    borderRadius: 10,
    borderWidth: 1,
  },
  ozetText: {
    flex: 1,
    fontSize: 11,
    fontFamily: "Inter_400Regular",
    lineHeight: 16,
  },
});
