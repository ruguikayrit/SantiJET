import React, { useEffect, useRef } from "react";
import { Animated, Dimensions, StyleSheet, View } from "react-native";

import { SantijetTagline } from "@/components/SantijetTagline";
import { SANTIJET_BRAND } from "@/constants/santijetBrand";

const { width } = Dimensions.get("window");

const BOLT_NAV = require("@/assets/images/santijet-bolt-nav-nobg.png");
const WORDMARK = require("@/assets/images/santijet-wordmark.png");

interface Props {
  onFinish: () => void;
}

export default function SplashScreenView({ onFinish }: Props) {
  const bgOpacity = useRef(new Animated.Value(1)).current;
  const logoOpacity = useRef(new Animated.Value(0)).current;
  const logoScale = useRef(new Animated.Value(0.88)).current;
  const taglineOpacity = useRef(new Animated.Value(0)).current;
  const taglineTranslate = useRef(new Animated.Value(10)).current;
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
      Animated.delay(120),
      Animated.parallel([
        Animated.timing(taglineOpacity, {
          toValue: 1,
          duration: 400,
          useNativeDriver: true,
        }),
        Animated.timing(taglineTranslate, {
          toValue: 0,
          duration: 400,
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

  const boltH = 72;
  const boltW = boltH;
  const wmH = Math.round(boltH * SANTIJET_BRAND.boltWordmarkHeightRatio);
  const wmW = Math.round(wmH * SANTIJET_BRAND.wordmarkAspect);

  return (
    <Animated.View style={[styles.container, { opacity: bgOpacity }]}>
      <View style={styles.center}>
        <Animated.View
          style={[
            styles.logoRow,
            { opacity: logoOpacity, transform: [{ scale: logoScale }] },
          ]}
        >
          <Animated.View style={[styles.glow, { opacity: glowOpacity }]} />
          <Animated.Image
            source={BOLT_NAV}
            style={{ width: boltW, height: boltH }}
            resizeMode="contain"
          />
          <Animated.Image
            source={WORDMARK}
            style={{ width: wmW, height: wmH, marginLeft: 8 }}
            resizeMode="contain"
          />
        </Animated.View>

        <Animated.View
          style={{
            opacity: taglineOpacity,
            transform: [{ translateY: taglineTranslate }],
            marginTop: 18,
          }}
        >
          <SantijetTagline>BİRİM FİYAT ANALİZLERİ</SantijetTagline>
        </Animated.View>
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
    width: width * 0.92,
  },
  logoRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
  },
  glow: {
    position: "absolute",
    width: 180,
    height: 180,
    borderRadius: 90,
    backgroundColor: "transparent",
    shadowColor: SANTIJET_BRAND.accentBlue,
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 1,
    shadowRadius: 48,
    elevation: 0,
  },
});
