import React from "react";
import { StyleSheet, Text, TextStyle, StyleProp } from "react-native";

import { SANTIJET_BRAND } from "@/constants/santijetBrand";

interface SantijetTaglineProps {
  children: string;
  style?: StyleProp<TextStyle>;
  size?: "sm" | "md";
}

/** OPERASYON YÖNETİMİ alt satırı ile aynı geniş aralıklı mavi tipografi */
export function SantijetTagline({ children, style, size = "md" }: SantijetTaglineProps) {
  return <Text style={[styles.base, size === "sm" && styles.sm, style]}>{children}</Text>;
}

const styles = StyleSheet.create({
  base: {
    color: SANTIJET_BRAND.accentBlue,
    fontSize: 11,
    fontFamily: "Inter_500Medium",
    letterSpacing: 7,
    textTransform: "uppercase",
    textAlign: "center",
  },
  sm: {
    fontSize: 9,
    letterSpacing: 5,
  },
});
