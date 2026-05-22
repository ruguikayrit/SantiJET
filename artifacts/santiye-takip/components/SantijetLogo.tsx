import React from "react";
import { View, Image, StyleSheet } from "react-native";

interface SantijetLogoProps {
  /** İkon yüksekliği (px). Tüm ölçekler buna orantılanır. */
  iconHeight?: number;
}

// santijet-icon.png   : 1254×1254 kare (tam logo, şeffaf arkaplan)
//   S-bolt bölgesi    : x %24–%76, y %6–%63
// santijet-wordmark.png: 1016×187 (yalnızca yazı, arka plan kaldırılmış)
//   Oran              : 5.433:1 (genişlik:yükseklik)

const ICON_SRC = require("../assets/images/santijet-icon.png");
const WM_SRC   = require("../assets/images/santijet-wordmark.png");

// santijet-icon.png içindeki S-bolt bölgesinin oransal sınırları
const BOLT_X_START = 0.24;  // %24 soldan
const BOLT_X_END   = 0.76;  // %76 soldan  → genişlik %52
const BOLT_Y_START = 0.06;  // %6  üstten
const BOLT_Y_END   = 0.635; // %63,5 üstten → yükseklik %57,5

// santijet-wordmark.png gerçek oran
const WM_ASPECT = 1016 / 187; // ≈ 5.43

export function SantijetLogo({ iconHeight = 48 }: SantijetLogoProps) {
  // ── S-Bolt ───────────────────────────────────────────────────────
  // Görseli bolt'un tam yüksekliğini kapsayacak şekilde ölçekle
  const boltImgH = Math.round(iconHeight / (BOLT_Y_END - BOLT_Y_START)); // ≈ 83px
  const boltImgW = boltImgH; // kare görsel

  // Bolt bölgesinin piksel konumları (ölçeklenmiş görsel içinde)
  const boltLeft   = Math.round(BOLT_X_START * boltImgW); // ≈20px — kırp
  const boltTop    = Math.round(BOLT_Y_START * boltImgH);  // ≈5px  — kırp
  const boltDispW  = Math.round((BOLT_X_END - BOLT_X_START) * boltImgW); // ≈43px görünür genişlik

  // ── Wordmark ─────────────────────────────────────────────────────
  // S-bolt ile dikey hizalamak için wordmark yüksekliği bolt yüksekliğinin %65'i
  const wmH = Math.round(iconHeight * 0.65);
  const wmW = Math.round(wmH * WM_ASPECT);

  return (
    <View style={styles.row}>
      {/* S-Bolt ikonu: şeffaf sol/sağ boşluk kırpılır */}
      <View
        style={{
          width: boltDispW,
          height: iconHeight,
          overflow: "hidden",
        }}
      >
        <Image
          source={ICON_SRC}
          style={{
            width: boltImgW,
            height: boltImgH,
            position: "absolute",
            top: -boltTop,
            left: -boltLeft,
          }}
          resizeMode="stretch"
        />
      </View>

      {/* ŞANTİJET wordmark — orijinal görsel, hemen yanında */}
      <Image
        source={WM_SRC}
        style={{ width: wmW, height: wmH, marginLeft: 8 }}
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
