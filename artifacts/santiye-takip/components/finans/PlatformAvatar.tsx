import React from "react";
import { View, Text, StyleSheet } from "react-native";

const PALETTE = [
  "#E74C3C", "#E67E22", "#F39C12", "#27AE60", "#1ABC9C",
  "#2980B9", "#8E44AD", "#E91E63", "#00BCD4", "#FF5722",
  "#4CAF50", "#9C27B0", "#3F51B5", "#009688", "#FF9800",
  "#607D8B", "#795548", "#F06292", "#4DB6AC", "#7986CB",
];

function hashStr(s: string): number {
  let h = 0;
  for (let i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) & 0xffff;
  return h;
}

function pickColor(name: string): string {
  return PALETTE[hashStr(name) % PALETTE.length];
}

function getInitials(name: string): string {
  const clean = name.split(/[\s–\-\(\/,]/)[0].trim();
  if (!clean) return "?";
  const words = name.trim().split(/\s+/);
  if (words.length >= 2) {
    return (words[0][0] + words[1][0]).toUpperCase();
  }
  return clean.slice(0, 2).toUpperCase();
}

interface Props {
  name: string;
  size?: number;
  borderRadius?: number;
}

export default function PlatformAvatar({ name, size = 36, borderRadius = 10 }: Props) {
  const color = pickColor(name);
  const initials = getInitials(name);
  const fontSize = Math.round(size * 0.36);

  return (
    <View
      style={[
        styles.base,
        {
          width: size,
          height: size,
          borderRadius,
          backgroundColor: color + "28",
        },
      ]}
    >
      <Text style={[styles.text, { fontSize, color }]}>{initials}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  base: {
    alignItems: "center",
    justifyContent: "center",
  },
  text: {
    fontWeight: "800",
    letterSpacing: -0.4,
    includeFontPadding: false,
  },
});
