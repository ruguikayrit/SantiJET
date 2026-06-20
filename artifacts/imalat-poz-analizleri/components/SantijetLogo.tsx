import React from "react";
import { View, Image, StyleSheet } from "react-native";

import { SANTIJET_BRAND } from "@/constants/santijetBrand";

interface SantijetLogoProps {
  /** Bolt ikon yüksekliği (px). Wordmark buna orantılanır. */
  iconHeight?: number;
  /** Header gibi ortalanmış bloklarda true */
  centered?: boolean;
  /** horizontal: web sitesi navbar düzeni (varsayılan) */
  layout?: "horizontal" | "stacked" | "wordmark";
}

const BOLT_NAV_SRC = require("../assets/images/santijet-bolt-nav-nobg.png");
const ICON_SRC = require("../assets/images/santijet-icon.png");
const WM_SRC = require("../assets/images/santijet-wordmark.png");

const BOLT_X_START = 0.24;
const BOLT_X_END = 0.76;
const BOLT_Y_START = 0.06;
const BOLT_Y_END = 0.635;

function LegacyBoltIcon({ iconHeight }: { iconHeight: number }) {
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

function WordmarkImage({ height }: { height: number }) {
  const width = Math.round(height * SANTIJET_BRAND.wordmarkAspect);
  return <Image source={WM_SRC} style={{ width, height }} resizeMode="contain" />;
}

export function SantijetLogo({
  iconHeight = 48,
  centered = false,
  layout = "horizontal",
}: SantijetLogoProps) {
  if (layout === "wordmark") {
    return (
      <View style={[styles.row, centered && styles.centered]}>
        <WordmarkImage height={iconHeight} />
      </View>
    );
  }

  if (layout === "stacked") {
    const boltH = iconHeight;
    const wmH = Math.round(iconHeight * 0.54);
    const wmW = Math.round(wmH * SANTIJET_BRAND.wordmarkAspect);
    const wordmarkOffset = Math.round(iconHeight * 0.1);
    const overlap = Math.round(boltH * 0.12);

    return (
      <View style={[styles.stackedWrap, centered && styles.centered]}>
        <View style={[styles.stackedInner, { width: wmW }]}>
          <View style={[styles.boltLayer, { marginBottom: -overlap }]}>
            <LegacyBoltIcon iconHeight={boltH} />
          </View>
          <View style={{ marginTop: wordmarkOffset }}>
            <WordmarkImage height={wmH} />
          </View>
        </View>
      </View>
    );
  }

  const boltH = iconHeight;
  const boltW = boltH;
  const wmH = Math.round(boltH * SANTIJET_BRAND.boltWordmarkHeightRatio);
  const wmW = Math.round(wmH * SANTIJET_BRAND.wordmarkAspect);

  return (
    <View style={[styles.row, centered && styles.centered]}>
      <Image
        source={BOLT_NAV_SRC}
        style={{ width: boltW, height: boltH }}
        resizeMode="contain"
      />
      <Image
        source={WM_SRC}
        style={{ width: wmW, height: wmH, marginLeft: 6 }}
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
