import { LinearGradient } from "expo-linear-gradient";
import { Feather } from "@expo/vector-icons";
import { SymbolView } from "expo-symbols";
import * as Haptics from "expo-haptics";
import React from "react";
import {
  Platform,
  Pressable,
  StyleSheet,
  Text,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useTranslation } from "react-i18next";

import { useColors } from "@/hooks/finans/useColors";

type BottomTabBarProps = { state: any; descriptors: any; navigation: any };

const isIOS = Platform.OS === "ios";

type TabItemConfig = {
  routeName: string;
  label: string;
  icon: string;
  iosSymbol?: string;
  iosFilled?: string;
  isAdd?: boolean;
};

const ITEMS: TabItemConfig[] = [
  { routeName: "index",       label: "nav.home",         icon: "home",       iosSymbol: "house",         iosFilled: "house.fill" },
  { routeName: "transactions",label: "nav.transactions", icon: "list",       iosSymbol: "list.bullet",   iosFilled: "list.bullet" },
  { routeName: "add",         label: "nav.add",          icon: "plus",       iosSymbol: "plus",          iosFilled: "plus",       isAdd: true },
  { routeName: "(sections)",  label: "nav.financial",    icon: "credit-card",iosSymbol: "creditcard",    iosFilled: "creditcard.fill" },
  { routeName: "settings",    label: "nav.settings",     icon: "settings",   iosSymbol: "gearshape",     iosFilled: "gearshape.fill" },
];

export function CustomTabBar({ state, descriptors, navigation }: BottomTabBarProps) {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const { t } = useTranslation();

  const BAR_HEIGHT = 62;
  const BOTTOM_PAD = Math.max(insets.bottom, 8);

  return (
    <View style={[s.wrapper, { height: BAR_HEIGHT + BOTTOM_PAD }]}>
      {/* Background gradient fills the full wrapper (including safe area) */}
      <LinearGradient
        colors={[colors.navyLight, colors.navy]}
        start={{ x: 0, y: 0 }}
        end={{ x: 0, y: 1 }}
        style={[StyleSheet.absoluteFill, s.bgGradient]}
      />

      {/* Glow line at top */}
      <LinearGradient
        colors={[colors.primary + "55", "transparent"]}
        style={s.glowLine}
        start={{ x: 0.1, y: 0 }}
        end={{ x: 0.9, y: 1 }}
      />

      {/* Tabs row — only BAR_HEIGHT tall, sits at top of wrapper */}
      <View style={[s.bar, { height: BAR_HEIGHT }]}>
        {(state.routes as { key: string; name: string; params?: object }[]).map((route, index) => {
          const cfg = ITEMS.find((i) => i.routeName === route.name);
          if (!cfg) return null;

          const { options } = descriptors[route.key];
          if (options.href === null) return null;

          const isFocused = state.index === index;

          const onPress = () => {
            const event = navigation.emit({
              type: "tabPress",
              target: route.key,
              canPreventDefault: true,
            });
            if (!isFocused && !event.defaultPrevented) {
              Haptics.selectionAsync();
              navigation.navigate(route.name, route.params);
            }
          };

          if (cfg.isAdd) {
            return (
              <Pressable
                key={route.key}
                onPress={onPress}
                style={s.addWrap}
                android_ripple={{ color: colors.primary + "33", borderless: true }}
              >
                <LinearGradient
                  colors={[colors.primary, colors.primary + "CC"]}
                  style={s.addBtn}
                  start={{ x: 0, y: 0 }}
                  end={{ x: 1, y: 1 }}
                >
                  <Feather name="plus" size={26} color="#FFFFFF" />
                </LinearGradient>
              </Pressable>
            );
          }

          const activeColor = "#FFFFFF";
          const inactiveColor = "rgba(255,255,255,0.38)";
          const labelColor = isFocused ? activeColor : inactiveColor;

          return (
            <Pressable
              key={route.key}
              onPress={onPress}
              style={s.tabItem}
              android_ripple={{ color: colors.primary + "33", borderless: true }}
            >
              {isFocused && (
                <LinearGradient
                  colors={[colors.primary + "33", colors.primary + "11"]}
                  style={s.activePill}
                  start={{ x: 0, y: 0 }}
                  end={{ x: 0, y: 1 }}
                />
              )}

              <View style={s.iconWrap}>
                {isIOS && cfg.iosSymbol ? (
                  <SymbolView
                    name={(isFocused ? (cfg.iosFilled ?? cfg.iosSymbol) : cfg.iosSymbol) as any}
                    tintColor={isFocused ? colors.primary : inactiveColor}
                    size={22}
                  />
                ) : (
                  <Feather
                    name={cfg.icon as any}
                    size={22}
                    color={isFocused ? colors.primary : inactiveColor}
                  />
                )}
                {isFocused && (
                  <View style={[s.activeDot, { backgroundColor: colors.primary }]} />
                )}
              </View>

              <Text
                style={[
                  s.label,
                  { color: labelColor, fontWeight: isFocused ? "700" : "400" },
                ]}
                numberOfLines={1}
              >
                {t(cfg.label)}
              </Text>
            </Pressable>
          );
        })}
      </View>
    </View>
  );
}

const s = StyleSheet.create({
  wrapper: {
    position: "absolute",
    bottom: 0,
    left: 0,
    right: 0,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: -4 },
    shadowOpacity: 0.35,
    shadowRadius: 16,
    elevation: 20,
    backgroundColor: "transparent",
  },
  bgGradient: {
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
  },
  glowLine: {
    position: "absolute",
    top: 0,
    left: 0,
    right: 0,
    height: 1.5,
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    zIndex: 2,
  },
  bar: {
    flexDirection: "row",
    alignItems: "center",
    paddingHorizontal: 4,
  },
  tabItem: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    height: "100%",
    paddingTop: 8,
    paddingBottom: 4,
    position: "relative",
  },
  activePill: {
    position: "absolute",
    top: 6,
    bottom: 4,
    left: 6,
    right: 6,
    borderRadius: 14,
  },
  iconWrap: {
    alignItems: "center",
    justifyContent: "center",
  },
  activeDot: {
    width: 4,
    height: 4,
    borderRadius: 2,
    marginTop: 3,
  },
  label: {
    fontSize: 10,
    marginTop: 0,
    letterSpacing: 0.1,
  },
  addWrap: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    height: "100%",
    paddingBottom: 2,
  },
  addBtn: {
    width: 46,
    height: 46,
    borderRadius: 23,
    alignItems: "center",
    justifyContent: "center",
    marginTop: -8,
    shadowColor: "#00C896",
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.4,
    shadowRadius: 10,
    elevation: 8,
  },
});
