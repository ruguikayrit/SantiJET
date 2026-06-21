import { Feather } from "@expo/vector-icons";
import React from "react";
import {
  ActivityIndicator,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";

import type { BfaModuleIcon } from "@/constants/bfaModules";

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
      <View style={[styles.tileIconCircle, { backgroundColor: color + "1e" }]}>
        <Feather name={icon} size={23} color={color} />
      </View>
      <View style={styles.tileBody}>
        <Text style={styles.tileNum}>{num}</Text>
        <Text style={[styles.tileLabel, { color: cardForeground }]} numberOfLines={2}>
          {label}
        </Text>
        <View style={styles.tileFootRow}>
          <View style={[styles.tileDot, { backgroundColor: color }]} />
          {loading ? (
            <ActivityIndicator size="small" color={color} />
          ) : (
            <Text style={[styles.tileInfo, { color }]} numberOfLines={1}>
              {info}
            </Text>
          )}
        </View>
      </View>
      <View style={[styles.tileChevCircle, { borderColor: color + "55" }]}>
        <Feather name="chevron-right" size={13} color={color} />
      </View>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  tileInner: {
    width: "100%",
    flexDirection: "row",
    alignItems: "center",
    gap: 13,
    padding: 14,
    borderRadius: 13,
    borderWidth: 1,
    marginBottom: 11,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 6,
    elevation: 3,
  },
  tileBody: {
    flex: 1,
    gap: 3,
  },
  tileNum: {
    fontSize: 9,
    fontFamily: "Inter_700Bold",
    color: "#334155",
    letterSpacing: 0.5,
  },
  tileIconCircle: {
    width: 47,
    height: 47,
    borderRadius: 24,
    justifyContent: "center",
    alignItems: "center",
  },
  tileLabel: {
    fontSize: 12,
    fontFamily: "Inter_700Bold",
    letterSpacing: 0.4,
  },
  tileFootRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 5,
    marginTop: 1,
  },
  tileDot: {
    width: 5,
    height: 5,
    borderRadius: 3,
  },
  tileInfo: {
    fontSize: 11,
    fontFamily: "Inter_500Medium",
  },
  tileChevCircle: {
    width: 29,
    height: 29,
    borderRadius: 15,
    borderWidth: 1,
    justifyContent: "center",
    alignItems: "center",
  },
});
