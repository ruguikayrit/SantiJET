import React from "react";
import { Dimensions, StyleSheet, View } from "react-native";

const { width, height } = Dimensions.get("window");

const STRIPS = 5;

function EdgeFade({
  edge,
}: {
  edge: "top" | "bottom" | "left" | "right";
}) {
  const isVertical = edge === "left" || edge === "right";
  const stripSize = (isVertical ? width : height) * 0.18 / STRIPS;

  return (
    <>
      {Array.from({ length: STRIPS }, (_, i) => {
        const fade = (STRIPS - i) / STRIPS;
        const opacity = 0.14 * fade * fade;
        const pos = i * stripSize;

        const style =
          edge === "top"
            ? { top: pos, left: 0, right: 0, height: stripSize }
            : edge === "bottom"
              ? { bottom: pos, left: 0, right: 0, height: stripSize }
              : edge === "left"
                ? { left: pos, top: 0, bottom: 0, width: stripSize }
                : { right: pos, top: 0, bottom: 0, width: stripSize };

        return (
          <View
            key={`${edge}-${i}`}
            style={[styles.strip, style, { backgroundColor: `rgba(0, 0, 0, ${opacity})` }]}
          />
        );
      })}
    </>
  );
}

/** Soft edge vignette — keeps focus on center logo block. */
export function SplashVignette() {
  return (
    <View style={StyleSheet.absoluteFill} pointerEvents="none">
      <EdgeFade edge="top" />
      <EdgeFade edge="bottom" />
      <EdgeFade edge="left" />
      <EdgeFade edge="right" />
    </View>
  );
}

const styles = StyleSheet.create({
  strip: {
    position: "absolute",
  },
});
