import React from "react";
import { Image, StyleSheet } from "react-native";

interface SantijetLogoProps {
  /** Logo yüksekliği (piksel). Genişlik otomatik orantılanır. */
  height?: number;
}

const logoSource = require("../assets/images/santijet-logo-full.png");

/**
 * ŞantiJET logo — orijinal görsel, şeffaf arka plan.
 * S-bolt ikonu + ŞANTİJET wordmark + OPERASYON YÖNETİMİ alt başlığı.
 */
export function SantijetLogo({ height = 72 }: SantijetLogoProps) {
  return (
    <Image
      source={logoSource}
      style={[styles.logo, { height }]}
      resizeMode="contain"
    />
  );
}

const styles = StyleSheet.create({
  logo: {
    width: "100%",
    alignSelf: "flex-start",
  },
});
