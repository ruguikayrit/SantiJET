import React, { useEffect, useRef } from "react";
import { Animated, Dimensions, Image, StyleSheet, View } from "react-native";

import { SplashBlueprintBackground } from "@/components/splash/SplashBlueprintBackground";
import { SplashVignette } from "@/components/splash/SplashVignette";

const { width, height } = Dimensions.get("window");

const ICON_SRC = require("@/assets/images/santijet-icon.png");
const WORDMARK = require("@/assets/images/santijet-wordmark.png");

const BOLT_X_START = 0.24;
const BOLT_X_END = 0.76;
const BOLT_Y_START = 0.06;
const BOLT_Y_END = 0.635;
const WM_ASPECT = 1016 / 187;

/** Orijinal splash wordmark genişliği 0.72; %20 küçültülmüş */
const WORDMARK_WIDTH = Math.round(width * 0.72 * 0.8);
const WORDMARK_HEIGHT = Math.round(WORDMARK_WIDTH / WM_ASPECT);
/** SantijetLogo stacked oranı: bolt yüksekliği ≈ wordmark yüksekliği / 0.54; splash x2.5 */
const BOLT_HEIGHT = Math.round((WORDMARK_HEIGHT / 0.54) * 2.5);
/** Logo–wordmark aralığı ~%17 azaltıldı (64 → 53) */
const LOGO_WORDMARK_GAP = Math.round(64 * 0.825);

const BRAND_GLOW = "#1a5fff";

function SplashBolt({ boltHeight }: { boltHeight: number }) {
  const boltImgH = Math.round(boltHeight / (BOLT_Y_END - BOLT_Y_START));
  const boltImgW = boltImgH;
  const boltLeft = Math.round(BOLT_X_START * boltImgW);
  const boltTop = Math.round(BOLT_Y_START * boltImgH);
  const boltDispW = Math.round((BOLT_X_END - BOLT_X_START) * boltImgW);

  return (
    <View style={{ width: boltDispW, height: boltHeight, overflow: "hidden" }}>
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

interface Props {
  onFinish: () => void;
}

export default function SplashScreenView({ onFinish }: Props) {
  const bgOpacity = useRef(new Animated.Value(1)).current;
  const logoOpacity = useRef(new Animated.Value(0)).current;
  const logoScale = useRef(new Animated.Value(0.82)).current;
  const logoGlowOpacity = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    Animated.sequence([
      Animated.delay(80),
      Animated.parallel([
        Animated.timing(logoOpacity, {
          toValue: 1,
          duration: 520,
          useNativeDriver: true,
        }),
        Animated.spring(logoScale, {
          toValue: 1,
          friction: 7,
          tension: 60,
          useNativeDriver: true,
        }),
        Animated.timing(logoGlowOpacity, {
          toValue: 1,
          duration: 680,
          useNativeDriver: true,
        }),
      ]),
      Animated.delay(900),
      Animated.timing(bgOpacity, {
        toValue: 0,
        duration: 340,
        useNativeDriver: true,
      }),
    ]).start(() => {
      onFinish();
    });
  }, []);

  const radialSize = Math.round(BOLT_HEIGHT * 1.75);
  const ambientSize = Math.round(BOLT_HEIGHT * 1.35);

  return (
    <Animated.View style={[styles.container, { opacity: bgOpacity }]}>
      <SplashBlueprintBackground />
      <SplashVignette />

      <View style={[styles.center, { marginTop: -Math.round(height * 0.07) }]}>
        <View style={[styles.boltWrap, { marginBottom: LOGO_WORDMARK_GAP }]}>
          <Animated.View
            style={[
              styles.radialLight,
              {
                width: radialSize,
                height: radialSize,
                borderRadius: radialSize / 2,
                opacity: logoGlowOpacity,
              },
            ]}
          />
          <Animated.View
            style={[
              styles.ambientGlow,
              {
                width: ambientSize,
                height: ambientSize,
                borderRadius: ambientSize / 2,
                opacity: logoGlowOpacity,
              },
            ]}
          />
          <Animated.View
            style={[
              styles.coreGlow,
              {
                width: Math.round(BOLT_HEIGHT * 1.2),
                height: Math.round(BOLT_HEIGHT * 1.2),
                borderRadius: Math.round(BOLT_HEIGHT * 0.6),
                opacity: logoGlowOpacity,
              },
            ]}
          />
          <Animated.View
            style={{
              opacity: logoOpacity,
              transform: [{ scale: logoScale }],
            }}
          >
            <SplashBolt boltHeight={BOLT_HEIGHT} />
          </Animated.View>
        </View>

        <Image source={WORDMARK} style={styles.wordmark} resizeMode="contain" />
      </View>
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  container: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "#04060d",
    zIndex: 9999,
    justifyContent: "center",
    alignItems: "center",
  },
  center: {
    alignItems: "center",
    justifyContent: "center",
  },
  boltWrap: {
    alignItems: "center",
    justifyContent: "center",
    minHeight: BOLT_HEIGHT,
  },
  radialLight: {
    position: "absolute",
    backgroundColor: "rgba(26, 95, 255, 0.055)",
  },
  ambientGlow: {
    position: "absolute",
    backgroundColor: "rgba(26, 95, 255, 0.07)",
    shadowColor: BRAND_GLOW,
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.55,
    shadowRadius: 56,
    elevation: 0,
  },
  coreGlow: {
    position: "absolute",
    backgroundColor: "transparent",
    shadowColor: BRAND_GLOW,
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 1,
    shadowRadius: 50,
    elevation: 0,
  },
  wordmark: {
    width: WORDMARK_WIDTH,
    height: WORDMARK_HEIGHT,
  },
});
