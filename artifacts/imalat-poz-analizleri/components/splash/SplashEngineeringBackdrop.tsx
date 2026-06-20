import React, { useMemo } from "react";
import { Dimensions, StyleSheet, View } from "react-native";

const { width, height } = Dimensions.get("window");

const GRID_STEP = 52;
/** Blueprint katmanı: bilinçaltı — %2–4 opaklık */
const GRID_MINOR = "rgba(148, 163, 184, 0.024)";
const GRID_MAJOR = "rgba(26, 95, 255, 0.032)";
const AXIS_LINE = "rgba(26, 95, 255, 0.028)";
const DIMENSION = "rgba(148, 163, 184, 0.026)";
const DRAFT_GUIDE = "rgba(100, 116, 139, 0.022)";

/**
 * Neredeyse görünmez mühendislik blueprint katmanı.
 * Logo/wordmark dokunulmaz; yalnızca atmosfer.
 */
export function SplashEngineeringBackdrop() {
  const { vLines, hLines, dimMarks, guides } = useMemo(() => {
    const vCount = Math.ceil(width / GRID_STEP) + 1;
    const hCount = Math.ceil(height / GRID_STEP) + 1;

    const vLines = Array.from({ length: vCount }, (_, i) => ({
      key: `v-${i}`,
      left: i * GRID_STEP,
      major: i % 4 === 0,
    }));

    const hLines = Array.from({ length: hCount }, (_, i) => ({
      key: `h-${i}`,
      top: i * GRID_STEP,
      major: i % 4 === 0,
    }));

    const cx = width * 0.5;
    const cy = height * 0.44;
    const boxW = width * 0.62;
    const boxH = height * 0.38;

    const dimMarks = [
      { key: "d-top", style: { top: cy - boxH / 2, left: cx - boxW / 2, width: boxW, height: StyleSheet.hairlineWidth } },
      { key: "d-bot", style: { top: cy + boxH / 2, left: cx - boxW / 2, width: boxW, height: StyleSheet.hairlineWidth } },
      { key: "d-l", style: { left: cx - boxW / 2, top: cy - boxH / 2, width: StyleSheet.hairlineWidth, height: boxH } },
      { key: "d-r", style: { left: cx + boxW / 2, top: cy - boxH / 2, width: StyleSheet.hairlineWidth, height: boxH } },
    ];

    const tick = 6;
    const ticks = [
      { key: "t1", style: { left: cx - tick, top: cy - boxH / 2 - tick, width: tick * 2, height: StyleSheet.hairlineWidth } },
      { key: "t2", style: { left: cx - tick, top: cy + boxH / 2, width: tick * 2, height: StyleSheet.hairlineWidth } },
      { key: "t3", style: { left: cx - boxW / 2 - tick, top: cy - tick, width: StyleSheet.hairlineWidth, height: tick * 2 } },
      { key: "t4", style: { left: cx + boxW / 2, top: cy - tick, width: StyleSheet.hairlineWidth, height: tick * 2 } },
    ];

    const span = Math.max(width, height) * 0.92;
    const guides = [
      { key: "g1", rotate: "18deg", top: cy - span * 0.12 },
      { key: "g2", rotate: "-14deg", top: cy + span * 0.08 },
    ].map((g) => ({ ...g, span }));

    return { vLines, hLines, dimMarks: [...dimMarks, ...ticks], guides };
  }, []);

  return (
    <View style={StyleSheet.absoluteFill} pointerEvents="none">
      {vLines.map(({ key, left, major }) => (
        <View
          key={key}
          style={[
            styles.gridV,
            {
              left,
              backgroundColor: major ? GRID_MAJOR : GRID_MINOR,
            },
          ]}
        />
      ))}
      {hLines.map(({ key, top, major }) => (
        <View
          key={key}
          style={[
            styles.gridH,
            {
              top,
              backgroundColor: major ? GRID_MAJOR : GRID_MINOR,
            },
          ]}
        />
      ))}

      {/* Structural axis — center field, barely visible */}
      <View style={[styles.axisH, { top: height * 0.44, backgroundColor: AXIS_LINE }]} />
      <View style={[styles.axisV, { left: width * 0.5, backgroundColor: AXIS_LINE }]} />

      {dimMarks.map(({ key, style }) => (
        <View key={key} style={[styles.dim, style, { backgroundColor: DIMENSION }]} />
      ))}

      {guides.map(({ key, rotate, top, span }) => (
        <View
          key={key}
          style={[
            styles.guideWrap,
            { top, width: span, marginLeft: -span / 2, transform: [{ rotate }] },
          ]}
        >
          <View style={[styles.guideLine, { width: span, backgroundColor: DRAFT_GUIDE }]} />
        </View>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  gridV: {
    position: "absolute",
    top: 0,
    bottom: 0,
    width: StyleSheet.hairlineWidth,
  },
  gridH: {
    position: "absolute",
    left: 0,
    right: 0,
    height: StyleSheet.hairlineWidth,
  },
  axisH: {
    position: "absolute",
    left: width * 0.08,
    right: width * 0.08,
    height: StyleSheet.hairlineWidth,
  },
  axisV: {
    position: "absolute",
    top: height * 0.18,
    bottom: height * 0.22,
    width: StyleSheet.hairlineWidth,
  },
  dim: {
    position: "absolute",
  },
  guideWrap: {
    position: "absolute",
    left: "50%",
    height: StyleSheet.hairlineWidth,
  },
  guideLine: {
    height: StyleSheet.hairlineWidth,
  },
});
