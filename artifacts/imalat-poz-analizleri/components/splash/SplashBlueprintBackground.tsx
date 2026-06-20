import React, { useMemo } from "react";
import { Dimensions, StyleSheet, View } from "react-native";

const { width, height } = Dimensions.get("window");

const GRID_STEP = 44;
const MINOR = "rgba(26, 95, 255, 0.042)";
const MAJOR = "rgba(26, 95, 255, 0.068)";
const DIAGONAL = "rgba(148, 163, 184, 0.045)";
const REFERENCE = "rgba(26, 95, 255, 0.055)";

/** Enterprise construction-tech backdrop: blueprint grid, drafting guides, minimal. */
export function SplashBlueprintBackground() {
  const { vLines, hLines, diagonals } = useMemo(() => {
    const vCount = Math.ceil(width / GRID_STEP) + 1;
    const hCount = Math.ceil(height / GRID_STEP) + 1;

    const vLines = Array.from({ length: vCount }, (_, i) => ({
      key: `v-${i}`,
      left: i * GRID_STEP,
      major: i % 5 === 0,
    }));

    const hLines = Array.from({ length: hCount }, (_, i) => ({
      key: `h-${i}`,
      top: i * GRID_STEP,
      major: i % 5 === 0,
    }));

    const span = Math.max(width, height) * 1.05;
    const diagonals = [
      { key: "d1", rotate: "24deg", top: height * 0.18 },
      { key: "d2", rotate: "-18deg", top: height * 0.52 },
      { key: "d3", rotate: "12deg", top: height * 0.78 },
    ].map((d) => ({ ...d, span }));

    return { vLines, hLines, diagonals };
  }, []);

  return (
    <View style={StyleSheet.absoluteFill} pointerEvents="none">
      {vLines.map(({ key, left, major }) => (
        <View
          key={key}
          style={[
            styles.gridLineV,
            {
              left,
              backgroundColor: major ? MAJOR : MINOR,
              width: major ? StyleSheet.hairlineWidth * 2 : StyleSheet.hairlineWidth,
            },
          ]}
        />
      ))}
      {hLines.map(({ key, top, major }) => (
        <View
          key={key}
          style={[
            styles.gridLineH,
            {
              top,
              backgroundColor: major ? MAJOR : MINOR,
              height: major ? StyleSheet.hairlineWidth * 2 : StyleSheet.hairlineWidth,
            },
          ]}
        />
      ))}

      {diagonals.map(({ key, rotate, top, span }) => (
        <View
          key={key}
          style={[
            styles.diagonalWrap,
            {
              top,
              width: span,
              marginLeft: -span / 2,
              transform: [{ rotate }],
            },
          ]}
        >
          <View style={[styles.diagonalLine, { width: span }]} />
        </View>
      ))}

      {/* Engineering reference ticks — center crosshair, very faint */}
      <View style={[styles.referenceH, { top: height * 0.46, backgroundColor: REFERENCE }]} />
      <View style={[styles.referenceV, { left: width * 0.5, backgroundColor: REFERENCE }]} />
    </View>
  );
}

const styles = StyleSheet.create({
  gridLineV: {
    position: "absolute",
    top: 0,
    bottom: 0,
    width: StyleSheet.hairlineWidth,
  },
  gridLineH: {
    position: "absolute",
    left: 0,
    right: 0,
    height: StyleSheet.hairlineWidth,
  },
  diagonalWrap: {
    position: "absolute",
    left: "50%",
    height: 1,
    alignItems: "center",
    justifyContent: "center",
  },
  diagonalLine: {
    height: StyleSheet.hairlineWidth,
    backgroundColor: DIAGONAL,
  },
  referenceH: {
    position: "absolute",
    left: width * 0.12,
    right: width * 0.12,
    height: StyleSheet.hairlineWidth,
    opacity: 0.85,
  },
  referenceV: {
    position: "absolute",
    top: height * 0.28,
    bottom: height * 0.28,
    width: StyleSheet.hairlineWidth,
    opacity: 0.85,
  },
});
