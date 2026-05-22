import React from "react";
import { View, Image, StyleSheet } from "react-native";

interface SantijetLogoProps {
  /** İkon yüksekliği (px). Wordmark buna orantılanır. */
  iconHeight?: number;
}

const iconSource = require("../assets/images/santijet-icon.png");
const wordmarkSource = require("../assets/images/santijet-wordmark.png");

/**
 * ŞantiJET yatay logo lockup:
 *   [S-bolt ikonu (orijinal görsel, kırpılmış)] [ŞANTİJET wordmark (orijinal görsel, şeffaf)]
 *
 * İkon kaynağı: santijet-icon.png  (tam logo görseli, üst %63 kırpılır)
 * Wordmark kaynağı: santijet-wordmark.png (sadece yazı, arka plan kaldırılmış)
 */
export function SantijetLogo({ iconHeight = 52 }: SantijetLogoProps) {
  // S-bolt kaynak görsel 1:1 kare; S-bolt ikonun görüntü içindeki yükseklik payı ~%63
  const imgSize = Math.round(iconHeight / 0.63);
  const topOffset = -Math.round(imgSize * 0.04);

  // Wordmark görsel oranı: kaynak yaklaşık 4.5:1 (genişlik:yükseklik)
  const wordmarkH = Math.round(iconHeight * 0.6);
  const wordmarkW = Math.round(wordmarkH * 4.5);

  return (
    <View style={styles.row}>
      {/* S-Bolt ikonu — sadece üst bölge görünür */}
      <View
        style={{
          width: imgSize,
          height: iconHeight,
          overflow: "hidden",
          marginRight: Math.round(iconHeight * 0.18),
        }}
      >
        <Image
          source={iconSource}
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

      {/* ŞANTİJET wordmark — orijinal görsel, şeffaf arka plan */}
      <Image
        source={wordmarkSource}
        style={{ width: wordmarkW, height: wordmarkH }}
        resizeMode="contain"
      />
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: "row",
    alignItems: "center",
    alignSelf: "flex-start",
  },
});
