import React from "react";
import { Platform, StyleSheet, View } from "react-native";

interface Props {
  children: React.ReactNode;
}

export default function WebFrame({ children }: Props) {
  if (Platform.OS !== "web") {
    return <>{children}</>;
  }
  return (
    <View style={styles.outer}>
      <View style={styles.frame}>{children}</View>
    </View>
  );
}

const styles = StyleSheet.create({
  outer: {
    flex: 1,
    backgroundColor: "#0b1220",
    alignItems: "center",
    justifyContent: "center",
    minHeight: "100%" as unknown as number,
  },
  frame: {
    width: "100%",
    maxWidth: 480,
    height: "100%",
    minHeight: "100%" as unknown as number,
    backgroundColor: "#ffffff",
    overflow: "hidden",
    ...(Platform.OS === "web"
      ? ({
          boxShadow: "0 20px 60px rgba(0,0,0,0.35)",
        } as object)
      : {}),
  },
});
