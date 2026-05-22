import React from "react";
import { View, Text, StyleSheet } from "react-native";
import Svg, {
  Polygon,
  Defs,
  LinearGradient,
  Stop,
} from "react-native-svg";

interface SantijetLogoProps {
  /** İkon yüksekliği (piksel). Wordmark buna göre ölçeklenir. */
  iconHeight?: number;
  /** Yalnızca ikon göster (wordmark gizle). */
  iconOnly?: boolean;
}

/**
 * ŞantiJET vektör logosu — react-native-svg tabanlı, şeffaf arka plan.
 * S-bolt ikonu (beyaz üst, mavi alt) + "ŞANTİ" beyaz / "JET" mavi wordmark.
 */
export function SantijetLogo({ iconHeight = 36, iconOnly = false }: SantijetLogoProps) {
  // S-bolt oranı: viewBox 280x400
  const iconWidth = iconHeight * (280 / 400);

  const fontSize = iconHeight * 0.62;
  const letterSpacing = fontSize * 0.06;

  return (
    <View style={styles.row}>
      {/* ─── S-Bolt SVG ikonu ─── */}
      <Svg width={iconWidth} height={iconHeight} viewBox="0 0 280 400">
        <Defs>
          <LinearGradient id="upperGradL" x1="0" y1="0" x2="0" y2="1">
            <Stop offset="0" stopColor="#FFFFFF" stopOpacity="1" />
            <Stop offset="1" stopColor="#DCE8FF" stopOpacity="1" />
          </LinearGradient>
          <LinearGradient id="lowerGradL" x1="0" y1="0" x2="0" y2="1">
            <Stop offset="0" stopColor="#3D8AFF" stopOpacity="1" />
            <Stop offset="1" stopColor="#0044CC" stopOpacity="1" />
          </LinearGradient>
        </Defs>

        {/* Beyaz üst kanat */}
        <Polygon
          points="185,8 258,44 162,218 32,218 90,124"
          fill="url(#upperGradL)"
        />
        {/* Mavi alt kanat */}
        <Polygon
          points="118,192 258,192 258,218 205,308 102,398 38,372"
          fill="url(#lowerGradL)"
        />
      </Svg>

      {/* ─── Wordmark ─── */}
      {!iconOnly && (
        <View style={[styles.wordmark, { marginLeft: iconHeight * 0.22 }]}>
          <Text
            style={[
              styles.wordmarkBase,
              {
                fontSize,
                letterSpacing,
                lineHeight: fontSize * 1.15,
              },
            ]}
            numberOfLines={1}
          >
            <Text style={styles.wordWhite}>ŞANTİ</Text>
            <Text style={styles.wordBlue}>JET</Text>
          </Text>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: "row",
    alignItems: "center",
  },
  wordmark: {
    justifyContent: "center",
  },
  wordmarkBase: {
    fontFamily: "Inter_700Bold",
    includeFontPadding: false,
  },
  wordWhite: {
    color: "#FFFFFF",
  },
  wordBlue: {
    color: "#0066FF",
  },
});
