import React from "react";
import { View, Text, Image, StyleSheet } from "react-native";

interface SantijetLogoProps {
  /** Wordmark font büyüklüğü (px). İkon ve alt başlık buna orantılanır. */
  fontSize?: number;
}

/**
 * ŞantiJET yatay logo lockup — orijinal ikon görseli + wordmark metni.
 *
 * Kaynak görselin (1:1 kare) oranları:
 *   - S-bolt ikonu:             y  0% – 63%
 *   - "ŞANTİJET" yazısı:        y 64% – 83%
 *   - "OPERASYON YÖNETİMİ":     y 84% – 93%
 *
 * Overflow clip ile yalnızca ikon bölgesi gösterilir;
 * metin satırları React Native Text ile sağ tarafa yerleştirilir.
 */
export function SantijetLogo({ fontSize = 22 }: SantijetLogoProps) {
  // İkon yüksekliği: iki metin satırının toplam yüksekliğine eşit
  const iconH = Math.round(fontSize * 2.6);
  // Kaynak görsel 1:1 kare → S-bolt %63'ünü kaplar → tam görsel yüksekliği:
  const imgSize = Math.round(iconH / 0.63);
  // Hafif üst boşluğu gidermek için görseli biraz yukarı kaydır
  const topOffset = -Math.round(imgSize * 0.03);

  return (
    <View style={styles.row}>
      {/* ── S-Bolt ikonu (orijinal görsel, üst bölgesi kırpılarak gösterilir) ── */}
      <View
        style={{
          width: imgSize,
          height: iconH,
          overflow: "hidden",
          marginRight: Math.round(fontSize * 0.45),
        }}
      >
        <Image
          source={require("../assets/images/santijet-icon.png")}
          style={{
            width: imgSize,
            height: imgSize,
            position: "absolute",
            top: topOffset,
            left: 0,
          }}
          resizeMode="stretch"
        />
      </View>

      {/* ── Metin kolonu ── */}
      <View style={styles.textCol}>
        {/* Wordmark: ŞANTİ (beyaz) + JET (mavi) */}
        <Text
          style={[
            styles.wordmark,
            { fontSize, lineHeight: Math.round(fontSize * 1.12) },
          ]}
          numberOfLines={1}
        >
          <Text style={styles.wWhite}>ŞANTİ</Text>
          <Text style={styles.wBlue}>JET</Text>
        </Text>

        {/* Alt başlık: OPERASYON YÖNETİMİ */}
        <Text
          style={[
            styles.subtitle,
            {
              fontSize: Math.max(Math.round(fontSize * 0.38), 8),
              letterSpacing: Math.round(fontSize * 0.18),
              marginTop: Math.round(fontSize * 0.1),
            },
          ]}
          numberOfLines={1}
        >
          OPERASYON YÖNETİMİ
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: "row",
    alignItems: "center",
  },
  textCol: {
    justifyContent: "center",
  },
  wordmark: {
    fontFamily: "Inter_700Bold",
    includeFontPadding: false,
    letterSpacing: 1,
  },
  wWhite: {
    color: "#FFFFFF",
  },
  wBlue: {
    color: "#1460E8",
  },
  subtitle: {
    fontFamily: "Inter_400Regular",
    color: "#4A88EE",
    includeFontPadding: false,
  },
});
