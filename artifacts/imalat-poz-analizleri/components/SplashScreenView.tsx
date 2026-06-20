import React, { useEffect, useRef } from "react";
import { Animated, Dimensions, StyleSheet, View } from "react-native";

import { SantijetLogo } from "@/components/SantijetLogo";

const { height } = Dimensions.get("window");

/** Önceki splash tam ikon 420px; %20 küçültülmüş bolt yüksekliği */
const SPLASH_ICON_HEIGHT = Math.round(420 * 0.8);

interface Props {
  onFinish: () => void;
}

export default function SplashScreenView({ onFinish }: Props) {
  const bgOpacity = useRef(new Animated.Value(1)).current;
  const logoOpacity = useRef(new Animated.Value(0)).current;
  const logoScale = useRef(new Animated.Value(0.82)).current;
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
      Animated.delay(1200),
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
        <View style={styles.logoWrap}>
          <Animated.View style={[styles.glow, { opacity: glowOpacity }]} />
          <Animated.View
            style={{
              opacity: logoOpacity,
              transform: [{ scale: logoScale }],
            }}
          >
            <SantijetLogo
              iconHeight={SPLASH_ICON_HEIGHT}
              centered
              stacked
              wordmarkGapMultiplier={2}
            />
          </Animated.View>
        </View>
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
  logoWrap: {
    alignItems: "center",
    justifyContent: "center",
    minWidth: SPLASH_ICON_HEIGHT + 40,
    minHeight: SPLASH_ICON_HEIGHT + 80,
  },
  glow: {
    position: "absolute",
    width: Math.round(SPLASH_ICON_HEIGHT * 1.15),
    height: Math.round(SPLASH_ICON_HEIGHT * 1.15),
    borderRadius: Math.round(SPLASH_ICON_HEIGHT * 0.575),
    backgroundColor: "transparent",
    shadowColor: "#1a5fff",
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 1,
    shadowRadius: 56,
    elevation: 0,
  },
});
