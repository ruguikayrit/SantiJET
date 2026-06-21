import React, { useState } from "react";
import { StyleSheet, View } from "react-native";

const COLS = 3;
const GAP = 10;
export const MODULE_TILE_H = 132;

interface ModuleGridProps {
  children: React.ReactNode;
}

export function ModuleGrid({ children }: ModuleGridProps) {
  const [containerW, setContainerW] = useState(0);
  const items = React.Children.toArray(children);
  const tileW = containerW > 0 ? (containerW - GAP * (COLS - 1)) / COLS : 0;
  const rows = Math.ceil(items.length / COLS);
  const containerH = rows > 0 ? rows * MODULE_TILE_H + (rows - 1) * GAP : 0;

  return (
    <View
      onLayout={(e) => setContainerW(e.nativeEvent.layout.width)}
      style={[styles.grid, { height: containerH }]}
    >
      {tileW > 0
        ? items.map((child, idx) => {
            const col = idx % COLS;
            const row = Math.floor(idx / COLS);
            return (
              <View
                key={idx}
                style={{
                  position: "absolute",
                  left: col * (tileW + GAP),
                  top: row * (MODULE_TILE_H + GAP),
                  width: tileW,
                  height: MODULE_TILE_H,
                }}
              >
                {child}
              </View>
            );
          })
        : null}
    </View>
  );
}

const styles = StyleSheet.create({
  grid: {
    width: "100%",
    marginBottom: 20,
  },
});
