import React from "react";
import { View, Text, StyleSheet, Platform } from "react-native";
import Svg, { Path, Defs, LinearGradient, Stop } from "react-native-svg";

interface SantijetLogoProps {
  /** Wordmark font büyüklüğü (px). Tüm ölçekler buna orantılanır. */
  fontSize?: number;
}

/**
 * ŞantiJET yatay logo lockup:
 *   [S-bolt ikonu] [ŞANTİ beyaz][JET mavi]
 *                  [OPERASYON YÖNETİMİ mavi]
 *
 * Renkler ve font stili orijinal logo görseline birebir uygun.
 */
export function SantijetLogo({ fontSize = 22 }: SantijetLogoProps) {
  // İkon yüksekliği: wordmark'ın iki satırıyla eşleşsin
  const iconH = fontSize * 2.6;
  // S-bolt viewBox: 0 0 220 300 → aspect 0.733
  const iconW = iconH * (220 / 300);

  return (
    <View style={styles.row}>
      {/* ── S-Bolt SVG ikonu ── */}
      <Svg
        width={iconW}
        height={iconH}
        viewBox="0 0 220 300"
        style={{ marginRight: fontSize * 0.42 }}
      >
        <Defs>
          {/* Beyaz-gümüş gradient (üst kanat) */}
          <LinearGradient id="sj_ug" x1="0.6" y1="0" x2="0.2" y2="1">
            <Stop offset="0" stopColor="#FFFFFF" stopOpacity="1" />
            <Stop offset="0.55" stopColor="#DCE8FF" stopOpacity="1" />
            <Stop offset="1" stopColor="#B8CCEE" stopOpacity="1" />
          </LinearGradient>
          {/* Mavi gradient (alt kanat) */}
          <LinearGradient id="sj_lg" x1="0.7" y1="0" x2="0.2" y2="1">
            <Stop offset="0" stopColor="#3B8AFF" stopOpacity="1" />
            <Stop offset="0.5" stopColor="#1460E8" stopOpacity="1" />
            <Stop offset="1" stopColor="#003CC0" stopOpacity="1" />
          </LinearGradient>
        </Defs>

        {/* Alt mavi kanat (önce çizilir — arkada kalır) */}
        <Path
          d="M 108,175 L 215,175 L 215,196 L 148,292 L 52,298 L 18,276 L 110,190 Z"
          fill="url(#sj_lg)"
        />
        {/* Üst beyaz kanat (üstte çizilir) */}
        <Path
          d="M 148,4 L 215,4 L 215,22 L 110,188 L 5,188 L 5,170 L 88,18 Z"
          fill="url(#sj_ug)"
        />
      </Svg>

      {/* ── Metin kolonu ── */}
      <View style={styles.textCol}>
        {/* Wordmark */}
        <Text
          style={[styles.wordmark, { fontSize, lineHeight: fontSize * 1.1 }]}
          numberOfLines={1}
        >
          <Text style={styles.wWhite}>ŞANTİ</Text>
          <Text style={styles.wBlue}>JET</Text>
        </Text>
        {/* Alt başlık */}
        <Text
          style={[
            styles.subtitle,
            {
              fontSize: Math.max(fontSize * 0.38, 8),
              letterSpacing: fontSize * 0.16,
              marginTop: fontSize * 0.12,
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
    letterSpacing: 0.8,
  },
  wWhite: {
    color: "#FFFFFF",
  },
  wBlue: {
    color: "#1460E8",
  },
  subtitle: {
    fontFamily: Platform.OS === "ios" ? "Inter_300Light" : "Inter_400Regular",
    color: "#4A88EE",
    includeFontPadding: false,
  },
});
