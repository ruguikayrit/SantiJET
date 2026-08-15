import React, { useMemo } from "react";
import { Image, StyleSheet, Text, View } from "react-native";

import { useColors } from "@/hooks/useColors";

const WORDMARK_DARK = require("@/assets/images/splash_wordmark.png");
const WORDMARK_LIGHT = require("@/assets/images/splash_wordmark_light.png");
const WORDMARK_ASPECT = 895 / 150;

/** Demir / SAHA `SantijetHeader` + `_BrandTitleMetrics` ile birebir. */
const BRAND_SCALE = 0.7;
const HOME_PRODUCT_SCALE = 1.875;
const HOME_PRODUCT_LETTER_SPACING = 0.75;
const HOME_WORDMARK_TO_PRODUCT_GAP = 6;
const WORDMARK_LETTER_FILL_RATIO = 0.55;
const WORDMARK_HEIGHT_SCALE = 2.5;
const INTER_ASCENT_RATIO = 0.76;
const DARK_WORDMARK_PIXEL_HEIGHT = 150;
const DARK_WORDMARK_LEFT_INK_PX = 12;
const LIGHT_WORDMARK_PIXEL_HEIGHT = 157;
const LIGHT_WORDMARK_LEFT_INK_PX = 12;

const PRODUCT_LABEL = "PRO";

function luminance(hex: string): number {
  const h = hex.replace("#", "");
  if (h.length < 6) return 0;
  const r = parseInt(h.slice(0, 2), 16) / 255;
  const g = parseInt(h.slice(2, 4), 16) / 255;
  const b = parseInt(h.slice(4, 6), 16) / 255;
  const lin = (c: number) =>
    c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
  return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b);
}

export default function HomeBrandMark() {
  const colors = useColors();
  const onLightBand = luminance(colors.secondary) > 0.55;
  const wordmarkSource = onLightBand ? WORDMARK_LIGHT : WORDMARK_DARK;
  const productColor = colors.secondaryForeground;

  const metrics = useMemo(() => {
    const metricFs = BRAND_SCALE * 14;
    const productFs = metricFs * HOME_PRODUCT_SCALE;
    const ascent = metricFs * INTER_ASCENT_RATIO;
    const wordmarkHeight =
      (ascent / WORDMARK_LETTER_FILL_RATIO) * WORDMARK_HEIGHT_SCALE;
    const leftInk = onLightBand
      ? LIGHT_WORDMARK_LEFT_INK_PX
      : DARK_WORDMARK_LEFT_INK_PX;
    const pixelHeight = onLightBand
      ? LIGHT_WORDMARK_PIXEL_HEIGHT
      : DARK_WORDMARK_PIXEL_HEIGHT;
    const productIndent = wordmarkHeight * (leftInk / pixelHeight);
    return {
      wordmarkHeight,
      wordmarkWidth: wordmarkHeight * WORDMARK_ASPECT,
      productIndent,
      productFs,
    };
  }, [onLightBand]);

  return (
    <View style={styles.wrap}>
      <Image
        source={wordmarkSource}
        style={{
          height: metrics.wordmarkHeight,
          width: metrics.wordmarkWidth,
        }}
        resizeMode="contain"
      />
      <Text
        style={[
          styles.product,
          {
            marginTop: HOME_WORDMARK_TO_PRODUCT_GAP,
            marginLeft: metrics.productIndent,
            fontSize: metrics.productFs,
            lineHeight: metrics.productFs,
            letterSpacing: HOME_PRODUCT_LETTER_SPACING,
            color: productColor,
          },
        ]}
      >
        {PRODUCT_LABEL}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    flex: 1,
    alignItems: "flex-start",
    justifyContent: "center",
    minWidth: 0,
  },
  product: {
    fontFamily: "Inter_700Bold",
    fontWeight: "700",
    includeFontPadding: false,
  },
});
