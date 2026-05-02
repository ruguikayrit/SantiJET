/**
 * IsoBarChart — İzometrik 3D bar chart
 *
 * Her bar 3 yüzeyden oluşur:
 *   • Ön yüz  (base renk)
 *   • Üst yüz (açık ton — ışık)
 *   • Sağ yüz (koyu ton — gölge)
 *
 * Kullanım: borç tiplerine göre kalan tutar karşılaştırması
 */

import React, { useState } from "react";
import { View, Text, LayoutChangeEvent, StyleSheet } from "react-native";
import Svg, { G, Path, Line, Text as SvgText, Defs, LinearGradient as SvgGradient, Stop } from "react-native-svg";

import { useColors } from "@/hooks/finans/useColors";

// ── Color helpers ──────────────────────────────────────────────────────────────

function adjustHex(hex: string, delta: number): string {
  const clamp = (v: number) => Math.min(255, Math.max(0, v));
  const clean = hex.replace("#", "").padEnd(6, "0");
  const r = clamp(parseInt(clean.slice(0, 2), 16) + delta);
  const g = clamp(parseInt(clean.slice(2, 4), 16) + delta);
  const b = clamp(parseInt(clean.slice(4, 6), 16) + delta);
  return `#${r.toString(16).padStart(2, "0")}${g.toString(16).padStart(2, "0")}${b.toString(16).padStart(2, "0")}`;
}

// ── Types ─────────────────────────────────────────────────────────────────────

export interface IsoBar {
  label: string;
  value: number;
  color: string;
}

interface Props {
  data: IsoBar[];
  formatAmount: (n: number) => string;
  maxBars?: number;
}

// ── ISO geometry constants ─────────────────────────────────────────────────────
// Depth projection: side face leans right & slightly up

const ISO_DX = 20;   // horizontal offset for iso depth
const ISO_DY = 10;   // vertical offset for iso depth
const MAX_H  = 120;  // tallest bar height in px
const PAD_T  = 28;   // space above tallest bar (for top-face overhang + label)
const PAD_B  = 40;   // space below ground line (for x-axis labels)
const AXIS_H = 1;    // ground axis thickness

// ── Component ─────────────────────────────────────────────────────────────────

export function IsoBarChart({ data, formatAmount, maxBars = 7 }: Props) {
  const colors = useColors();
  const [svgW, setSvgW] = useState(0);

  const bars = data.slice(0, maxBars);
  const n    = bars.length;

  if (n === 0) return null;

  const svgH  = PAD_T + MAX_H + ISO_DY + PAD_B + AXIS_H;
  const groundY = PAD_T + MAX_H + ISO_DY;  // y-coordinate of ground line

  // Dynamically compute bar width + gap from available SVG width
  const minBarW = 30;
  const maxBarW = 56;
  const available = svgW > 0 ? svgW : 320;
  // total space occupied: n bars * (barW + ISO_DX) + gap * (n+1)
  // solve: barW such that gaps are reasonable
  const rawBarW = (available - n * ISO_DX - 24 /* min total gap */) / n;
  const barW = Math.min(maxBarW, Math.max(minBarW, rawBarW - 8));
  const totalBarsW = n * (barW + ISO_DX);
  const gapTotal = available - totalBarsW;
  const gap = Math.max(4, gapTotal / (n + 1));

  const maxVal = Math.max(...bars.map((b) => b.value), 1);

  const styles = StyleSheet.create({
    root: { width: "100%" },
    labelArea: {
      flexDirection: "row",
      justifyContent: "space-around",
      paddingHorizontal: 0,
      marginTop: -2,
    },
    labelWrap: {
      alignItems: "center",
      flex: 1,
    },
    labelText: {
      fontSize: 9,
      fontWeight: "700",
      color: colors.mutedForeground,
      textAlign: "center",
    },
  });

  return (
    <View
      style={styles.root}
      onLayout={(e: LayoutChangeEvent) => setSvgW(e.nativeEvent.layout.width)}
    >
      {svgW > 0 && (
        <Svg width={svgW} height={svgH}>
          <Defs>
            {/* Per-bar gradients for front face depth */}
            {bars.map((bar, i) => (
              <SvgGradient key={`gf${i}`} id={`gf${i}`} x1="0" y1="0" x2="1" y2="0">
                <Stop offset="0" stopColor={adjustHex(bar.color, 20)} stopOpacity="1" />
                <Stop offset="1" stopColor={bar.color} stopOpacity="1" />
              </SvgGradient>
            ))}
          </Defs>

          {/* Ground axis */}
          <Line
            x1={0}
            y1={groundY}
            x2={svgW}
            y2={groundY}
            stroke={colors.border}
            strokeWidth={AXIS_H}
          />

          {bars.map((bar, i) => {
            const barH   = maxVal > 0 ? (bar.value / maxVal) * MAX_H : 0;
            const x      = gap + i * (barW + ISO_DX + gap);
            const yTop   = groundY - barH;           // top-left of front face
            const yGnd   = groundY;                  // bottom of front face

            // ── 3 face path strings ─────────────────────────────────────
            // Front face (rectangle)
            const front = [
              `M ${x} ${yGnd}`,
              `L ${x + barW} ${yGnd}`,
              `L ${x + barW} ${yTop}`,
              `L ${x} ${yTop}`,
              "Z",
            ].join(" ");

            // Top face (parallelogram: shifts right+up by ISO_DX, ISO_DY)
            const top = [
              `M ${x} ${yTop}`,
              `L ${x + barW} ${yTop}`,
              `L ${x + barW + ISO_DX} ${yTop - ISO_DY}`,
              `L ${x + ISO_DX} ${yTop - ISO_DY}`,
              "Z",
            ].join(" ");

            // Right side face (parallelogram)
            const side = [
              `M ${x + barW} ${yGnd}`,
              `L ${x + barW + ISO_DX} ${yGnd - ISO_DY}`,
              `L ${x + barW + ISO_DX} ${yTop - ISO_DY}`,
              `L ${x + barW} ${yTop}`,
              "Z",
            ].join(" ");

            const frontColor = bar.color;
            const topColor   = adjustHex(bar.color, 65);
            const sideColor  = adjustHex(bar.color, -55);

            // Center X of bar (front face center)
            const barCx = x + barW / 2;
            const labelY = yTop - ISO_DY - 6; // above top face

            // Formatted amount (short for small bars)
            const amt = formatAmount(bar.value);

            return (
              <G key={bar.label}>
                {/* Right side — drawn first (behind) */}
                <Path d={side}  fill={sideColor}  />
                {/* Front face */}
                <Path d={front} fill={`url(#gf${i})`} />
                {/* Top face — drawn last (on top) */}
                <Path d={top}   fill={topColor}   />

                {/* Value label above bar */}
                {barH > 8 && (
                  <SvgText
                    x={barCx + ISO_DX / 2}
                    y={labelY}
                    textAnchor="middle"
                    fontSize={9}
                    fontWeight="700"
                    fill={colors.foreground}
                  >
                    {amt}
                  </SvgText>
                )}
              </G>
            );
          })}
        </Svg>
      )}

      {/* X-axis labels (rendered as native Text for proper truncation) */}
      {svgW > 0 && (
        <View style={[styles.labelArea, { marginTop: -(PAD_B - 4) }]}>
          {bars.map((bar, i) => {
            const x    = gap + i * (barW + ISO_DX + gap);
            const cx   = x + barW / 2 + ISO_DX / 2;
            const itemW = barW + ISO_DX + gap;
            return (
              <View
                key={bar.label}
                style={[
                  styles.labelWrap,
                  { width: itemW, marginLeft: i === 0 ? gap : 0 },
                ]}
              >
                <View style={{ width: 8, height: 8, borderRadius: 4, backgroundColor: bar.color, marginBottom: 3 }} />
                <Text style={styles.labelText} numberOfLines={2}>
                  {bar.label}
                </Text>
              </View>
            );
          })}
        </View>
      )}
    </View>
  );
}
