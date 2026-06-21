import { Feather } from "@expo/vector-icons";
import React from "react";
import {
  ActivityIndicator,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";

import { parseModuleTileLabel, type BfaModuleIcon } from "@/constants/bfaModules";

const ICON_LABEL_GAP = 3;

interface ModuleTileProps {
  num: string;
  label: string;
  icon: BfaModuleIcon;
  color: string;
  info: string;
  loading?: boolean;
  cardForeground: string;
  cardBackground: string;
  onPress: () => void;
}

export function ModuleTile({
  num,
  label,
  icon,
  color,
  info,
  loading,
  cardForeground,
  cardBackground,
  onPress,
}: ModuleTileProps) {
  const { title, subtitle } = parseModuleTileLabel(label);

  return (
    <TouchableOpacity
      activeOpacity={0.85}
      onPress={onPress}
      style={[
        styles.tileInner,
        {
          backgroundColor: cardBackground,
          borderColor: color + "33",
        },
      ]}
    >
      <View style={styles.tileTopRow}>
        <Text style={styles.tileNum}>{num}</Text>
      </View>

      <View style={styles.tileCenter}>
        <View style={[styles.tileIconCircle, { backgroundColor: color + "1e" }]}>
          <Feather name={icon} size={26} color={color} />
        </View>

        <View style={styles.tileLabelGroup}>
          <Text style={[styles.tileLabel, { color: cardForeground }]} numberOfLines={2}>
            {title.toUpperCase()}
          </Text>
          {subtitle ? (
            <Text
              style={[styles.tileSubtitle, { color: cardForeground }]}
              numberOfLines={2}
              adjustsFontSizeToFit
              minimumFontScale={0.7}
            >
              {subtitle}
            </Text>
          ) : null}
        </View>
      </View>

      <View style={styles.tileFootRow}>
        <View style={[styles.tileDot, { backgroundColor: color }]} />
        {loading ? (
          <ActivityIndicator size="small" color={color} style={styles.tileInfoLoader} />
        ) : (
          <Text style={[styles.tileInfo, { color }]} numberOfLines={1}>
            {info}
          </Text>
        )}
        <View style={[styles.tileChevCircle, { borderColor: color + "55" }]}>
          <Feather name="chevron-right" size={9} color={color} />
        </View>
      </View>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  tileInner: {
    flex: 1,
    padding: 10,
    borderRadius: 14,
    borderWidth: 1,
    overflow: "hidden",
    justifyContent: "space-between",
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 6,
    elevation: 3,
  },
  tileTopRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
  },
  tileNum: {
    fontSize: 10,
    fontFamily: "Inter_700Bold",
    color: "#334155",
    letterSpacing: 0.5,
  },
  tileCenter: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    gap: ICON_LABEL_GAP,
  },
  tileLabelGroup: {
    alignItems: "center",
    gap: 1,
    width: "100%",
  },
  tileIconCircle: {
    width: 50,
    height: 50,
    borderRadius: 25,
    justifyContent: "center",
    alignItems: "center",
  },
  tileLabel: {
    fontSize: 10,
    fontFamily: "Inter_700Bold",
    textAlign: "center",
    letterSpacing: 0.4,
  },
  tileSubtitle: {
    fontSize: 7,
    fontFamily: "Inter_700Bold",
    textAlign: "center",
    letterSpacing: 0.2,
    lineHeight: 9,
    marginTop: -1,
  },
  tileFootRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 4,
  },
  tileDot: {
    width: 5,
    height: 5,
    borderRadius: 3,
  },
  tileInfo: {
    flex: 1,
    fontSize: 9,
    fontFamily: "Inter_500Medium",
  },
  tileInfoLoader: {
    flex: 1,
    alignSelf: "flex-start",
  },
  tileChevCircle: {
    width: 18,
    height: 18,
    borderRadius: 9,
    borderWidth: 1,
    justifyContent: "center",
    alignItems: "center",
  },
});
