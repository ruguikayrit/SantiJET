import React, { useState } from "react";
import { StyleSheet, View } from "react-native";

const GAP = 10;
export const MODULE_TILE_H = 132;

interface ModuleGridProps {
  children: React.ReactNode;
  /** Grid column count — B.F.A. home uses 2×2 for four modules. */
  cols?: number;
  tileHeight?: number;
}

export function ModuleGrid({ children, cols = 2, tileHeight = MODULE_TILE_H }: ModuleGridProps) {
  const [containerW, setContainerW] = useState(0);
  const items = React.Children.toArray(children);
  const tileW = containerW > 0 ? (containerW - GAP * (cols - 1)) / cols : 0;
  const rows = Math.ceil(items.length / cols);
  const containerH = rows > 0 ? rows * tileHeight + (rows - 1) * GAP : 0;

  return (
    <View
      onLayout={(e) => setContainerW(e.nativeEvent.layout.width)}
      style={[styles.grid, { height: containerH }]}
    >
      {tileW > 0
        ? items.map((child, idx) => {
            const col = idx % cols;
            const row = Math.floor(idx / cols);
            return (
              <View
                key={idx}
                style={{
                  position: "absolute",
                  left: col * (tileW + GAP),
                  top: row * (tileHeight + GAP),
                  width: tileW,
                  height: tileHeight,
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
