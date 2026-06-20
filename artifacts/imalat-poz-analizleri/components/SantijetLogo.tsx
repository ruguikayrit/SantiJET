import React from "react";
import { View, Image, StyleSheet } from "react-native";

interface SantijetLogoProps {
  iconHeight?: number;
}

const ICON_SRC = require("../assets/images/santijet-icon.png");
const WM_SRC = require("../assets/images/santijet-wordmark.png");

const BOLT_X_START = 0.24;
const BOLT_X_END = 0.76;
const BOLT_Y_START = 0.06;
const BOLT_Y_END = 0.635;
const WM_ASPECT = 1016 / 187;

export function SantijetLogo({ iconHeight = 48 }: SantijetLogoProps) {
  const boltImgH = Math.round(iconHeight / (BOLT_Y_END - BOLT_Y_START));
  const boltImgW = boltImgH;
  const boltLeft = Math.round(BOLT_X_START * boltImgW);
  const boltTop = Math.round(BOLT_Y_START * boltImgH);
  const boltDispW = Math.round((BOLT_X_END - BOLT_X_START) * boltImgW);
  const wmH = Math.round(iconHeight * 0.65);
  const wmW = Math.round(wmH * WM_ASPECT);

  return (
    <View style={styles.row}>
      <View style={{ width: boltDispW, height: iconHeight, overflow: "hidden" }}>
        <Image
          source={ICON_SRC}
          style={{
            width: boltImgW,
            height: boltImgH,
            position: "absolute",
            top: -boltTop,
            left: -boltLeft,
          }}
          resizeMode="stretch"
        />
      </View>
      <Image
        source={WM_SRC}
        style={{ width: wmW, height: wmH, marginLeft: 8 }}
        resizeMode="contain"
      />
    </View>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: "row",
    alignItems: "center",
    alignSelf: "flex-start",
  },
});
