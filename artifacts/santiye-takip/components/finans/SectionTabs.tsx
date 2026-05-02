import { Feather } from "@expo/vector-icons";
import * as Haptics from "expo-haptics";
import { usePathname, useRouter } from "expo-router";
import React from "react";
import {
  Animated,
  Platform,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { useTranslation } from "react-i18next";

import { useColors } from "@/hooks/finans/useColors";

type Section = {
  key: string;
  path: string;
  labelKey: string;
  sublabelKey: string;
  icon: keyof typeof Feather.glyphMap;
  color: string;
};

const SECTION_DEFS: Section[] = [
  {
    key:         "debts",
    path:        "/finans/debts",
    labelKey:    "sections.debts",
    sublabelKey: "sections.debts_sub",
    icon:        "credit-card",
    color:       "#FF4D6D",
  },
  {
    key:         "payments",
    path:        "/finans/payments",
    labelKey:    "sections.payments",
    sublabelKey: "sections.payments_sub",
    icon:        "check-circle",
    color:       "#00C896",
  },
  {
    key:         "assets",
    path:        "/finans/assets",
    labelKey:    "sections.assets",
    sublabelKey: "sections.assets_sub",
    icon:        "briefcase",
    color:       "#F5A623",
  },
  {
    key:         "bank-limits",
    path:        "/finans/bank-limits",
    labelKey:    "sections.bankLimits",
    sublabelKey: "sections.bankLimits_sub",
    icon:        "bar-chart-2",
    color:       "#4E9EF5",
  },
  {
    key:         "bank-info",
    path:        "/finans/bank-info",
    labelKey:    "sections.bankInfo",
    sublabelKey: "sections.bankInfo_sub",
    icon:        "database",
    color:       "#F5A623",
  },
];

function TabPill({ section, active, onPress }: {
  section: Section & { label: string; sublabel: string };
  active: boolean;
  onPress: () => void;
}) {
  const scale = React.useRef(new Animated.Value(1)).current;

  const handlePress = () => {
    Animated.sequence([
      Animated.timing(scale, { toValue: 0.92, duration: 70, useNativeDriver: false }),
      Animated.timing(scale, { toValue: 1,    duration: 110, useNativeDriver: false }),
    ]).start();
    Haptics.selectionAsync();
    onPress();
  };

  return (
    <TouchableOpacity
      activeOpacity={0.85}
      onPress={handlePress}
      style={styles.pillTouch}
    >
      <Animated.View
        style={[
          styles.pill,
          { transform: [{ scale }] },
          active
            ? {
                backgroundColor: section.color,
                shadowColor:     section.color,
                shadowOpacity:   0.5,
                shadowRadius:    10,
                shadowOffset:    { width: 0, height: 3 },
                elevation:       8,
              }
            : {
                backgroundColor: "rgba(255,255,255,0.06)",
                borderWidth:     1,
                borderColor:     "rgba(255,255,255,0.09)",
              },
        ]}
      >
        <Feather
          name={section.icon}
          size={17}
          color={active ? "#fff" : section.color}
        />
        <Text
          style={[
            styles.pillLabel,
            { color: active ? "#fff" : "rgba(255,255,255,0.85)" },
          ]}
          numberOfLines={1}
        >
          {section.label}
        </Text>
        {active && (
          <Text style={styles.pillSub} numberOfLines={1}>
            {section.sublabel}
          </Text>
        )}
      </Animated.View>
    </TouchableOpacity>
  );
}

export function SectionTabs() {
  const pathname = usePathname();
  const router   = useRouter();
  const { t }    = useTranslation();
  const colors   = useColors();

  const sections = SECTION_DEFS.map((s) => ({
    ...s,
    label:    t(s.labelKey),
    sublabel: t(s.sublabelKey),
  }));

  return (
    <View
      style={[
        styles.wrapper,
        { backgroundColor: colors.navy, borderTopColor: "rgba(255,255,255,0.08)" },
      ]}
    >
      <View style={styles.row}>
        {sections.map((s) => {
          const active = pathname === s.path || pathname.startsWith(s.path + "/");
          return (
            <TabPill
              key={s.key}
              section={s}
              active={active}
              onPress={() => {
                if (!active) router.replace(s.path as any);
              }}
            />
          );
        })}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  wrapper: {
    borderTopWidth:   1,
    paddingTop:       10,
    paddingBottom:    10,
    paddingHorizontal: 10,
  },
  row: {
    flexDirection:  "row",
    gap:            6,
  },
  pillTouch: {
    flex: 1,
    height: 70,
  },
  pill: {
    width:          "100%",
    height:         "100%",
    borderRadius:   14,
    alignItems:     "center",
    justifyContent: "center",
    gap:            4,
    paddingVertical: 8,
    paddingHorizontal: 4,
    ...Platform.select({
      web: {
        cursor:     "pointer",
        transition: "all 0.14s ease",
      },
    }),
  },
  pillLabel: {
    fontSize:      11,
    fontWeight:    "700",
    letterSpacing: -0.2,
    textAlign:     "center",
  },
  pillSub: {
    fontSize:   8,
    fontWeight: "600",
    color:      "rgba(255,255,255,0.82)",
    textTransform: "uppercase",
    letterSpacing: 0.3,
  },
});
