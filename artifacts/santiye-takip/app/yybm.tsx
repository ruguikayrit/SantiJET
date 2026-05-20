import { Feather } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import * as WebBrowser from "expo-web-browser";
import React, { useState } from "react";
import {
  Alert,
  Modal,
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
  MEVCUT_YILLAR,
  YYBM_PDF_URLS,
  YYBM_VERILER,
  artisOrani,
  formatFiyat,
} from "@/constants/yybm";

const ONDALIK_ARALIK = 10;
const BASLANGIC_DEKAD = Math.floor(new Date().getFullYear() / ONDALIK_ARALIK) * ONDALIK_ARALIK;

export default function YYBMScreen() {
  const colors = useColors();
  const router = useRouter();
  const insets = useSafeAreaInsets();
  const topPad = Platform.OS === "web" ? 16 : insets.top;

  const [dekadBaslangic, setDekadBaslangic] = useState(BASLANGIC_DEKAD);
  const [seciliYillar, setSeciliYillar] = useState<number[]>([]);
  const [karsilastirmaGoster, setKarsilastirmaGoster] = useState(false);
  const [detayYil, setDetayYil] = useState<number | null>(null);

  const dekadYillari = Array.from({ length: 10 }, (_, i) => dekadBaslangic + i);

  function yilSecToggle(yil: number) {
    if (!MEVCUT_YILLAR.includes(yil)) {
      Alert.alert("Veri Mevcut Değil", `${yil} yılı için tebliğ verisi henüz eklenmemiştir.`);
      return;
    }
    setSeciliYillar((prev) =>
      prev.includes(yil) ? prev.filter((y) => y !== yil) : [...prev, yil]
    );
    setKarsilastirmaGoster(false);
  }

  async function pdfAc(yil: number) {
    const url = YYBM_PDF_URLS[yil];
    if (!url) return;
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

  function tekYilIslem() {
    if (seciliYillar.length === 1) {
      pdfAc(seciliYillar[0]!);
    }
  }

  function karsilastir() {
    if (seciliYillar.length >= 2) {
      setKarsilastirmaGoster(true);
    }
  }

  const siraliSecili = [...seciliYillar].sort((a, b) => a - b);

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
          T.C. Çevre, Şehircilik ve İklim Değişikliği Bakanlığı tarafından yayımlanan yıllık
          tebliğler. Mimarlık ve mühendislik hizmet bedellerinin hesabında kullanılır.
        </Text>

        <View style={[styles.pickerCard, { backgroundColor: colors.card, borderColor: colors.secondary + "40" }]}>
          <View style={styles.dekadSatir}>
            <TouchableOpacity
              onPress={() => setDekadBaslangic((d) => d - 10)}
              style={[styles.navBtn, { backgroundColor: colors.secondary }]}
            >
              <Feather name="chevron-left" size={20} color={colors.secondaryForeground} />
            </TouchableOpacity>
            <Text style={[styles.dekadText, { color: colors.foreground }]}>
              {dekadBaslangic}–{dekadBaslangic + 9}
            </Text>
            <TouchableOpacity
              onPress={() => setDekadBaslangic((d) => d + 10)}
              style={[styles.navBtn, { backgroundColor: colors.secondary }]}
            >
              <Feather name="chevron-right" size={20} color={colors.secondaryForeground} />
            </TouchableOpacity>
          </View>

          <View style={styles.yilGrid}>
            {dekadYillari.map((yil) => {
              const mevcut = MEVCUT_YILLAR.includes(yil);
              const secili = seciliYillar.includes(yil);
              return (
                <TouchableOpacity
                  key={yil}
                  onPress={() => yilSecToggle(yil)}
                  style={[
                    styles.yilBtn,
                    {
                      backgroundColor: secili
                        ? "#1a6e4a"
                        : mevcut
                        ? colors.card
                        : "transparent",
                      borderWidth: secili ? 0 : mevcut ? 1 : 0,
                      borderColor: colors.secondary + "60",
                    },
                  ]}
                >
                  <Text
                    style={[
                      styles.yilBtnText,
                      {
                        color: secili
                          ? "#4fffb0"
                          : mevcut
                          ? colors.foreground
                          : colors.mutedForeground + "60",
                        fontFamily: secili ? "JetBrainsMono_700Bold" : "JetBrainsMono_400Regular",
                      },
                    ]}
                  >
                    {yil}
                  </Text>
                  {mevcut && !secili && (
                    <View style={[styles.pdfDot, { backgroundColor: "#4fffb0" }]} />
                  )}
                </TouchableOpacity>
              );
            })}
          </View>

          {seciliYillar.length > 0 && (
            <View style={styles.seciliInfo}>
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
                setSeciliYillar([]);
                setKarsilastirmaGoster(false);
              }}
              style={[styles.iptalBtn, { backgroundColor: colors.secondary }]}
            >
              <Text style={[styles.iptalBtnText, { color: colors.secondaryForeground }]}>
                Temizle
              </Text>
            </TouchableOpacity>

            {seciliYillar.length === 1 && (
              <TouchableOpacity
                onPress={tekYilIslem}
                style={styles.aksiyonBtn}
              >
                <Feather name="file-text" size={16} color="#fff" />
                <Text style={styles.aksiyonBtnText}>PDF Görüntüle</Text>
              </TouchableOpacity>
            )}

            {seciliYillar.length >= 2 && (
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

        {seciliYillar.length === 1 && YYBM_VERILER[seciliYillar[0]!] && (
          <YilDetay
            yil={seciliYillar[0]!}
            colors={colors}
            onPdfAc={pdfAc}
          />
        )}

        {karsilastirmaGoster && siraliSecili.length >= 2 && (
          <KarsilastirmaTablosu
            yillar={siraliSecili}
            colors={colors}
          />
        )}
      </ScrollView>
    </View>
  );
}

function YilDetay({
  yil,
  colors,
  onPdfAc,
}: {
  yil: number;
  colors: ReturnType<typeof import("@/hooks/useColors").useColors>;
  onPdfAc: (yil: number) => void;
}) {
  const veri = YYBM_VERILER[yil];
  if (!veri) return null;

  return (
    <View style={{ marginTop: 16 }}>
      <View style={styles.bolumBaslik}>
        <Text style={[styles.bolumBaslikText, { color: colors.foreground }]}>
          {veri.yil} Yılı Yapı Sınıfları
        </Text>
        <Text style={[styles.bolumAlt, { color: colors.mutedForeground }]}>
          Resmî Gazete: {veri.gazeteKarariTarihi} — Sayı: {veri.gazeteNo}
        </Text>
      </View>

      <TouchableOpacity
        onPress={() => onPdfAc(yil)}
        style={[styles.pdfBtn, { borderColor: "#4fffb0" + "40", backgroundColor: "#1a6e4a" + "20" }]}
      >
        <Feather name="file-text" size={18} color="#4fffb0" />
        <Text style={[styles.pdfBtnText, { color: "#4fffb0" }]}>
          Resmî Gazete Tebliğini Aç (PDF)
        </Text>
        <Feather name="external-link" size={14} color="#4fffb0" />
      </TouchableOpacity>

      {veri.siniflar.map((s) => (
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
  yillar,
  colors,
}: {
  yillar: number[];
  colors: ReturnType<typeof import("@/hooks/useColors").useColors>;
}) {
  const veriSet = yillar.map((y) => YYBM_VERILER[y]).filter(Boolean);
  if (veriSet.length < 2) return null;

  const ilkVeri = veriSet[0]!;
  const sonVeri = veriSet[veriSet.length - 1]!;

  const toplamArtis = sonVeri.siniflar.reduce((s, sin) => s + sin.fiyat, 0);
  const toplamEski = ilkVeri.siniflar.reduce((s, sin) => s + sin.fiyat, 0);
  const genelArtis = artisOrani(toplamEski, toplamArtis);

  return (
    <View style={{ marginTop: 16 }}>
      <View style={styles.bolumBaslik}>
        <Text style={[styles.bolumBaslikText, { color: colors.foreground }]}>
          Mukayese Tablosu — {yillar.join(" / ")}
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
          {yillar.map((y) => (
            <Text key={y} style={[styles.tabloBaslikHucre, styles.hucreFiyat, { color: colors.secondaryForeground }]}>
              {y}
            </Text>
          ))}
          {yillar.length === 2 && (
            <Text style={[styles.tabloBaslikHucre, styles.hucreDegisim, { color: colors.secondaryForeground }]}>
              Artış
            </Text>
          )}
        </View>

        {ilkVeri.siniflar.map((sinif, idx) => {
          const fiyatlar = veriSet.map((v) => v!.siniflar[idx]?.fiyat ?? 0);
          const degisim =
            yillar.length === 2 && fiyatlar[0]! > 0
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
  dekadSatir: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: 20,
  },
  navBtn: {
    width: 40,
    height: 40,
    borderRadius: 12,
    alignItems: "center",
    justifyContent: "center",
  },
  dekadText: {
    fontSize: 26,
    fontFamily: "JetBrainsMono_700Bold",
    letterSpacing: 1,
  },
  yilGrid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 10,
    justifyContent: "flex-start",
  },
  yilBtn: {
    width: "30%",
    minWidth: 80,
    paddingVertical: 16,
    borderRadius: 14,
    alignItems: "center",
    justifyContent: "center",
    position: "relative",
  },
  yilBtnText: {
    fontSize: 17,
    letterSpacing: 0.5,
  },
  pdfDot: {
    position: "absolute",
    bottom: 5,
    width: 5,
    height: 5,
    borderRadius: 3,
  },
  seciliInfo: {
    marginTop: 16,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: "rgba(255,255,255,0.08)",
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
