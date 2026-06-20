import React from "react";
import { View, Image, StyleSheet } from "react-native";

interface SantijetLogoProps {
  iconHeight?: number;
  /** Header gibi ortalanmış bloklarda true */
  centered?: boolean;
  /** S logosu wordmark tipografinin üstünde, ortalanmış */
  stacked?: boolean;
}

const ICON_SRC = require("../assets/images/santijet-icon.png");
const WM_SRC = require("../assets/images/santijet-wordmark.png");
const WM_FULL_SRC = require("../assets/images/santijet-wordmark-full.png");

const BOLT_X_START = 0.24;
const BOLT_X_END = 0.76;
const BOLT_Y_START = 0.06;
const BOLT_Y_END = 0.635;
const WM_ASPECT = 1016 / 187;
/** Referans: ŞANTİJET + OPERASYON YÖNETİMİ (1774×887) */
const WM_FULL_ASPECT = 1774 / 887;

function BoltIcon({ iconHeight }: { iconHeight: number }) {
  const boltImgH = Math.round(iconHeight / (BOLT_Y_END - BOLT_Y_START));
  const boltImgW = boltImgH;
  const boltLeft = Math.round(BOLT_X_START * boltImgW);
  const boltTop = Math.round(BOLT_Y_START * boltImgH);
  const boltDispW = Math.round((BOLT_X_END - BOLT_X_START) * boltImgW);

  return (
    <View style={{ width: boltDispW, height: iconHeight, overflow: "hidden" }}>
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
  );
}

export function SantijetLogo({
  iconHeight = 48,
  centered = false,
  stacked = false,
}: SantijetLogoProps) {
  if (stacked) {
    const boltH = iconHeight;
    const wmH = Math.round(iconHeight * 0.95);
    const wmW = Math.round(wmH * WM_FULL_ASPECT);
    const wordmarkOffset = Math.round(iconHeight * 0.08);
    const overlap = Math.round(boltH * 0.12);

    return (
      <View style={[styles.stackedWrap, centered && styles.centered]}>
        <View style={[styles.stackedInner, { width: wmW }]}>
          <View style={[styles.boltLayer, { marginBottom: -overlap }]}>
            <BoltIcon iconHeight={boltH} />
          </View>
          <Image
            source={WM_FULL_SRC}
            style={{ width: wmW, height: wmH, marginTop: wordmarkOffset }}
            resizeMode="contain"
          />
        </View>
      </View>
    );
  }

  const wmH = Math.round(iconHeight * 0.62);
  const wmW = Math.round(wmH * WM_ASPECT);

  return (
    <View style={[styles.row, centered && styles.centered]}>
      <BoltIcon iconHeight={iconHeight} />
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
  centered: {
    alignSelf: "center",
  },
  stackedWrap: {
    alignSelf: "flex-start",
  },
  stackedInner: {
    alignItems: "center",
    justifyContent: "center",
  },
  boltLayer: {
    alignItems: "center",
    justifyContent: "center",
    zIndex: 2,
  },
});
