import React from "react";
import { View, Image, StyleSheet } from "react-native";

interface SantijetLogoProps {
  /** İkon bölgesi konteyner yüksekliği (px). Wordmark buna orantılanır. */
  iconHeight?: number;
}

const logoSrc = require("../assets/images/santijet-icon.png");

/**
 * ŞantiJET yatay logo lockup — tek kaynak görsel (santijet-icon.png),
 * iki farklı dikey bölge kırpılarak yan yana gösterilir:
 *
 *  [S-bolt ikonu]  [ŞANTİJET wordmark]
 *  y: 0% – 63%    y: 64% – 83%
 *
 * Kaynak görsel 1:1 kare.
 * Wordmark bölgesi tam logo görselinden alındığı için Ş cedilla korunur.
 */
export function SantijetLogo({ iconHeight = 48 }: SantijetLogoProps) {
  // ── S-bolt ikonu ──────────────────────────────────────────────────
  // S-bolt görselin üst ~%63'ünü kaplar
  const boltImgSize = Math.round(iconHeight / 0.63);
  const boltTopOffset = -Math.round(boltImgSize * 0.04); // üst boşluk kırp

  // ── ŞANTİJET wordmark ────────────────────────────────────────────
  // Wordmark y: ~%64 – %83 → yükseklik payı ~%19
  // Wordmark x: ~%8  – %92 → genişlik payı  ~%84
  const wmH = Math.round(iconHeight * 0.7);            // gösterim yüksekliği
  const wmImgSize = Math.round(wmH / 0.19);            // tam görsel boyutu
  const wmTopOffset = -Math.round(wmImgSize * 0.64);   // wordmark başlangıcı
  const wmLeftOffset = -Math.round(wmImgSize * 0.08);  // sol boşluk kırp
  const wmContainerW = Math.round(wmImgSize * 0.84);   // görünür genişlik

  return (
    <View style={styles.row}>
      {/* S-Bolt ikonu */}
      <View
        style={{
          width: boltImgSize,
          height: iconHeight,
          overflow: "hidden",
        }}
      >
        <Image
          source={logoSrc}
          style={{
            width: boltImgSize,
            height: boltImgSize,
            position: "absolute",
            top: boltTopOffset,
            left: 0,
          }}
          resizeMode="stretch"
        />
      </View>

      {/* ŞANTİJET wordmark */}
      <View
        style={{
          width: wmContainerW,
          height: wmH,
          overflow: "hidden",
          alignSelf: "center",
          marginLeft: 6,
        }}
      >
        <Image
          source={logoSrc}
          style={{
            width: wmImgSize,
            height: wmImgSize,
            position: "absolute",
            top: wmTopOffset,
            left: wmLeftOffset,
          }}
          resizeMode="stretch"
        />
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: "row",
    alignItems: "center",
    alignSelf: "flex-start",
    marginLeft: 0,
  },
});
