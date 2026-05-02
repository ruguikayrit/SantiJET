import React from "react";
import { StyleSheet, Text, View } from "react-native";
import Svg, { G, Path } from "react-native-svg";

import { useColors } from "@/hooks/finans/useColors";
import { useFormatAmount } from "@/hooks/finans/useFormatAmount";

export interface PieSlice {
  label: string;
  value: number;
  color: string;
}

interface Props {
  data: PieSlice[];
  size?: number;
  centerLabel?: string;
  centerValue?: string;
}

function polarToCartesian(cx: number, cy: number, r: number, angleDeg: number) {
  const a = ((angleDeg - 90) * Math.PI) / 180;
  return { x: cx + r * Math.cos(a), y: cy + r * Math.sin(a) };
}

function arcPath(
  cx: number,
  cy: number,
  rOuter: number,
  rInner: number,
  startAngle: number,
  endAngle: number
) {
  const largeArc = endAngle - startAngle > 180 ? 1 : 0;
  const o1 = polarToCartesian(cx, cy, rOuter, startAngle);
  const o2 = polarToCartesian(cx, cy, rOuter, endAngle);
  const i1 = polarToCartesian(cx, cy, rInner, endAngle);
  const i2 = polarToCartesian(cx, cy, rInner, startAngle);
  return [
    `M ${o1.x} ${o1.y}`,
    `A ${rOuter} ${rOuter} 0 ${largeArc} 1 ${o2.x} ${o2.y}`,
    `L ${i1.x} ${i1.y}`,
    `A ${rInner} ${rInner} 0 ${largeArc} 0 ${i2.x} ${i2.y}`,
    "Z",
  ].join(" ");
}

export default function PieChart({
  data,
  size = 180,
  centerLabel,
  centerValue,
}: Props) {
  const formatAmount = useFormatAmount();
  const colors = useColors();
  const total = data.reduce((s, d) => s + d.value, 0);
  const cx = size / 2;
  const cy = size / 2;
  const rOuter = size / 2;
  const rInner = size / 2 - 28;

  let startAngle = 0;
  const slices = data.map((d) => {
    const angle = total > 0 ? (d.value / total) * 360 : 0;
    const path =
      total > 0 && angle > 0
        ? arcPath(cx, cy, rOuter, rInner, startAngle, startAngle + angle)
        : "";
    startAngle += angle;
    return { ...d, path };
  });

  const styles = StyleSheet.create({
    wrap: { alignItems: "center" },
    chartWrap: { position: "relative", alignItems: "center", justifyContent: "center" },
    center: {
      position: "absolute",
      alignItems: "center",
      justifyContent: "center",
    },
    centerLabel: {
      fontSize: 11,
      color: colors.mutedForeground,
      fontWeight: "500" as const,
      marginBottom: 2,
    },
    centerValue: {
      fontSize: 15,
      fontWeight: "700" as const,
      color: colors.foreground,
    },
    legend: {
      marginTop: 16,
      width: "100%",
    },
    legendRow: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      paddingVertical: 6,
    },
    legendLeft: {
      flexDirection: "row",
      alignItems: "center",
      gap: 8,
      flex: 1,
    },
    dot: { width: 10, height: 10, borderRadius: 5 },
    legendLabel: {
      fontSize: 13,
      color: colors.foreground,
      fontWeight: "500" as const,
    },
    legendAmount: {
      fontSize: 13,
      color: colors.foreground,
      fontWeight: "600" as const,
    },
    legendPct: {
      fontSize: 11,
      color: colors.mutedForeground,
      marginLeft: 6,
    },
    emptyRing: {
      width: size,
      height: size,
      borderRadius: size / 2,
      borderWidth: 28,
      borderColor: colors.muted,
    },
  });

  if (total === 0) {
    return (
      <View style={styles.wrap}>
        <View style={styles.chartWrap}>
          <View style={styles.emptyRing} />
          <View style={[styles.center, { width: size, height: size }]}>
            {centerLabel ? <Text style={styles.centerLabel}>{centerLabel}</Text> : null}
            <Text style={styles.centerValue}>—</Text>
          </View>
        </View>
      </View>
    );
  }

  return (
    <View style={styles.wrap}>
      <View style={styles.chartWrap}>
        <Svg width={size} height={size}>
          <G>
            {slices.map((s, i) =>
              s.path ? <Path key={i} d={s.path} fill={s.color} /> : null
            )}
          </G>
        </Svg>
        <View style={[styles.center, { width: size, height: size }]}>
          {centerLabel ? <Text style={styles.centerLabel}>{centerLabel}</Text> : null}
          {centerValue ? <Text style={styles.centerValue}>{centerValue}</Text> : null}
        </View>
      </View>
      <View style={styles.legend}>
        {data.map((d, i) => {
          const pct = total > 0 ? Math.round((d.value / total) * 100) : 0;
          return (
            <View key={i} style={styles.legendRow}>
              <View style={styles.legendLeft}>
                <View style={[styles.dot, { backgroundColor: d.color }]} />
                <Text style={styles.legendLabel} numberOfLines={1}>
                  {d.label}
                </Text>
                <Text style={styles.legendPct}>%{pct}</Text>
              </View>
              <Text style={styles.legendAmount}>{formatAmount(d.value)}</Text>
            </View>
          );
        })}
      </View>
    </View>
  );
}
