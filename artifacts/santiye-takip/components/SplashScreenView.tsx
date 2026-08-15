import React, { useEffect, useRef } from "react";
import { LinearGradient } from "expo-linear-gradient";
import { Animated, Dimensions, StyleSheet, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

const BOLT = require("@/assets/images/splash_bolt.png");
const WORDMARK = require("@/assets/images/splash_wordmark.png");

const DARK_CANVAS = "#05070A";
const DARK_BORDER = "#1E293B";
const ELECTRIC_BLUE = "#0055FF";
const ELECTRIC_BLUE_LIGHT = "#3B82F6";
const ELECTRIC_BLUE_GLOW = "rgba(72,118,220,0.2)";

const WORDMARK_ASPECT = 895 / 150;
const BOLT_WORDMARK_GAP = 28;
const BOLT_WORDMARK_GAP_REDUCED = BOLT_WORDMARK_GAP * 0.3;
const WORDMARK_ANCHOR_COMPENSATION = BOLT_WORDMARK_GAP * 0.35;
const WORDMARK_TO_LABEL = 30;
const PRODUCT_LABEL = "PRO";

function clamp(n: number, min: number, max: number) {
  return Math.min(max, Math.max(min, n));
}

interface Props {
  onFinish: () => void;
}

export default function SplashScreenView({ onFinish }: Props) {
  const insets = useSafeAreaInsets();
  const { width: screenWidth } = Dimensions.get("window");

  const boltSize = clamp(screenWidth * 0.76, 280, 440);
  const wordmarkWidth = clamp(screenWidth * 0.78, 260, 360);
  const wordmarkHeight = wordmarkWidth / WORDMARK_ASPECT;

  const bgOpacity = useRef(new Animated.Value(1)).current;
  const boltOpacity = useRef(new Animated.Value(0)).current;
  const wordmarkOpacity = useRef(new Animated.Value(0)).current;
  const labelOpacity = useRef(new Animated.Value(0)).current;
  const loadingProgress = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    const loadingLoop = Animated.loop(
      Animated.timing(loadingProgress, {
        toValue: 1,
        duration: 1800,
        useNativeDriver: true,
      }),
    );
    loadingLoop.start();

    Animated.parallel([
      Animated.sequence([
        Animated.delay(150),
        Animated.timing(boltOpacity, {
          toValue: 1,
          duration: 800,
          useNativeDriver: true,
        }),
      ]),
      Animated.sequence([
        Animated.delay(350),
        Animated.timing(wordmarkOpacity, {
          toValue: 1,
          duration: 800,
          useNativeDriver: true,
        }),
      ]),
      Animated.sequence([
        Animated.delay(550),
        Animated.timing(labelOpacity, {
          toValue: 1,
          duration: 800,
          useNativeDriver: true,
        }),
      ]),
      Animated.sequence([
        Animated.delay(1600),
        Animated.timing(bgOpacity, {
          toValue: 0,
          duration: 340,
          useNativeDriver: true,
        }),
      ]),
    ]).start(() => {
      loadingLoop.stop();
      onFinish();
    });
  }, []);

  const barTranslate = loadingProgress.interpolate({
    inputRange: [0, 1],
    outputRange: [-45, 45],
  });

  return (
    <Animated.View style={[styles.container, { opacity: bgOpacity }]}>
      <View style={[styles.safe, { paddingTop: insets.top }]}>
        <View style={styles.center}>
          <View style={{ height: WORDMARK_ANCHOR_COMPENSATION }} />
          <Animated.Image
            source={BOLT}
            style={{ width: boltSize, height: boltSize, opacity: boltOpacity }}
            resizeMode="contain"
          />
          <View style={{ height: BOLT_WORDMARK_GAP_REDUCED }} />
          <Animated.Image
            source={WORDMARK}
            style={{
              width: wordmarkWidth,
              height: wordmarkHeight,
              opacity: wordmarkOpacity,
            }}
            resizeMode="contain"
          />
          <View style={{ height: WORDMARK_TO_LABEL }} />
          <Animated.Text style={[styles.productLabel, { opacity: labelOpacity }]}>
            {PRODUCT_LABEL}
          </Animated.Text>
        </View>

        <View style={[styles.loadingTrack, { marginBottom: insets.bottom + 24 }]}>
          <Animated.View
            style={[styles.loadingBarWrap, { transform: [{ translateX: barTranslate }] }]}
          >
            <LinearGradient
              colors={[ELECTRIC_BLUE, ELECTRIC_BLUE_LIGHT]}
              start={{ x: 0, y: 0 }}
              end={{ x: 1, y: 0 }}
              style={styles.loadingBar}
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
    backgroundColor: DARK_CANVAS,
    zIndex: 9999,
  },
  safe: { flex: 1 },
  center: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: 24,
  },
  productLabel: {
    fontFamily: "Rajdhani-Bold",
    fontSize: 37,
    fontWeight: "700",
    color: ELECTRIC_BLUE,
    letterSpacing: 6,
    textShadowColor: ELECTRIC_BLUE_GLOW,
    textShadowOffset: { width: 0, height: 0 },
    textShadowRadius: 24,
  },
  loadingTrack: {
    alignSelf: "center",
    width: 130,
    height: 4,
    borderRadius: 2,
    backgroundColor: DARK_BORDER,
    overflow: "hidden",
    shadowColor: "#0055FF",
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.4,
    shadowRadius: 8,
  },
  loadingBarWrap: { width: 40, height: 4 },
  loadingBar: { width: 40, height: 4, borderRadius: 2 },
});
