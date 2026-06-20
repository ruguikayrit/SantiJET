import React, { useEffect, useRef } from "react";
import { Animated, Dimensions, Image, StyleSheet, View } from "react-native";

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
/** Orijinal boşluk 32px; x2 */
const LOGO_WORDMARK_GAP = 64;

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
  const wordmarkOpacity = useRef(new Animated.Value(0)).current;
  const wordmarkTranslate = useRef(new Animated.Value(12)).current;
  const glowOpacity = useRef(new Animated.Value(0)).current;

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
        Animated.timing(glowOpacity, {
          toValue: 1,
          duration: 680,
          useNativeDriver: true,
        }),
      ]),
      Animated.delay(40),
      Animated.parallel([
        Animated.timing(wordmarkOpacity, {
          toValue: 1,
          duration: 50,
          useNativeDriver: true,
        }),
        Animated.timing(wordmarkTranslate, {
          toValue: 0,
          duration: 50,
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

  return (
    <Animated.View style={[styles.container, { opacity: bgOpacity }]}>
      <View style={[styles.center, { marginTop: -Math.round(height * 0.07) }]}>
        <View style={[styles.boltWrap, { marginBottom: LOGO_WORDMARK_GAP }]}>
          <Animated.View style={[styles.glow, { opacity: glowOpacity }]} />
          <Animated.View
            style={{
              opacity: logoOpacity,
              transform: [{ scale: logoScale }],
            }}
          >
            <SplashBolt boltHeight={BOLT_HEIGHT} />
          </Animated.View>
        </View>

        <Animated.Image
          source={WORDMARK}
          style={[
            styles.wordmark,
            {
              opacity: wordmarkOpacity,
              transform: [{ translateY: wordmarkTranslate }],
            },
          ]}
          resizeMode="contain"
        />
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
  glow: {
    position: "absolute",
    width: Math.round(BOLT_HEIGHT * 1.2),
    height: Math.round(BOLT_HEIGHT * 1.2),
    borderRadius: Math.round(BOLT_HEIGHT * 0.6),
    backgroundColor: "transparent",
    shadowColor: "#1a5fff",
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 1,
    shadowRadius: 40,
    elevation: 0,
  },
  wordmark: {
    width: WORDMARK_WIDTH,
    height: WORDMARK_HEIGHT,
  },
});
