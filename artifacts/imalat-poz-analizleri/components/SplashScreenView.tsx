import React, { useEffect, useRef } from "react";
import { Animated, Dimensions, StyleSheet, View } from "react-native";

const { height } = Dimensions.get("window");

const ICON = require("@/assets/images/santijet-icon.png");

/** Önceki splash ikon boyutu 140px; x3 */
const ICON_SIZE = 420;
const GLOW_SIZE = 480;

interface Props {
  onFinish: () => void;
}

export default function SplashScreenView({ onFinish }: Props) {
  const bgOpacity = useRef(new Animated.Value(1)).current;
  const iconOpacity = useRef(new Animated.Value(0)).current;
  const iconScale = useRef(new Animated.Value(0.82)).current;
  const glowOpacity = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    Animated.sequence([
      Animated.delay(80),
      Animated.parallel([
        Animated.timing(iconOpacity, {
          toValue: 1,
          duration: 520,
          useNativeDriver: true,
        }),
        Animated.spring(iconScale, {
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
        <View style={styles.iconWrapper}>
          <Animated.View style={[styles.glow, { opacity: glowOpacity }]} />
          <Animated.Image
            source={ICON}
            style={[
              styles.icon,
              { opacity: iconOpacity, transform: [{ scale: iconScale }] },
            ]}
            resizeMode="contain"
          />
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
  iconWrapper: {
    width: ICON_SIZE + 24,
    height: ICON_SIZE + 24,
    alignItems: "center",
    justifyContent: "center",
  },
  glow: {
    position: "absolute",
    width: GLOW_SIZE,
    height: GLOW_SIZE,
    borderRadius: GLOW_SIZE / 2,
    backgroundColor: "transparent",
    shadowColor: "#1a5fff",
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 1,
    shadowRadius: 72,
    elevation: 0,
  },
  icon: {
    width: ICON_SIZE,
    height: ICON_SIZE,
  },
});
