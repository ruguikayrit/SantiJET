import { Feather } from "@expo/vector-icons";
import * as Haptics from "expo-haptics";
import React, { useEffect, useRef, useState } from "react";
import {
  Animated,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import { useTranslation } from "react-i18next";

import { useColors } from "@/hooks/finans/useColors";

function daysInMonth(year: number, month: number) {
  return new Date(year, month + 1, 0).getDate();
}

interface Props {
  visible: boolean;
  value: Date;
  title?: string;
  onSelect: (date: Date) => void;
  onClose: () => void;
}

export default function DatePickerSheet({
  visible,
  value,
  title,
  onSelect,
  onClose,
}: Props) {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const { t, i18n } = useTranslation();

  const [rendered, setRendered] = useState(visible);
  const [pickerYear, setPickerYear] = useState(value.getFullYear());
  const [pickerMonth, setPickerMonth] = useState(value.getMonth());
  const [pickerDay, setPickerDay] = useState(value.getDate());

  const slideAnim = useRef(new Animated.Value(visible ? 0 : 500)).current;
  const opacityAnim = useRef(new Animated.Value(visible ? 1 : 0)).current;

  useEffect(() => {
    if (visible) {
      setPickerYear(value.getFullYear());
      setPickerMonth(value.getMonth());
      setPickerDay(value.getDate());
      setRendered(true);
      Animated.parallel([
        Animated.timing(opacityAnim, {
          toValue: 1,
          duration: 200,
          useNativeDriver: true,
        }),
        Animated.spring(slideAnim, {
          toValue: 0,
          useNativeDriver: true,
          bounciness: 3,
          speed: 14,
        }),
      ]).start();
    } else {
      Animated.parallel([
        Animated.timing(opacityAnim, {
          toValue: 0,
          duration: 160,
          useNativeDriver: true,
        }),
        Animated.timing(slideAnim, {
          toValue: 500,
          duration: 160,
          useNativeDriver: true,
        }),
      ]).start(() => setRendered(false));
    }
  }, [visible]);

  if (!rendered) return null;

  const maxDay = daysInMonth(pickerYear, pickerMonth);
  const safeDay = Math.min(pickerDay, maxDay);

  const handleMonthSelect = (m: number) => {
    Haptics.selectionAsync();
    setPickerMonth(m);
    const newMax = daysInMonth(pickerYear, m);
    setPickerDay((d) => Math.min(d, newMax));
  };

  const handleDaySelect = (d: number) => {
    Haptics.selectionAsync();
    setPickerDay(d);
    onSelect(new Date(pickerYear, pickerMonth, d));
    onClose();
  };

  const dayRows: number[][] = [];
  for (let d = 1; d <= maxDay; d += 7) {
    dayRows.push(
      Array.from({ length: Math.min(7, maxDay - d + 1) }, (_, i) => d + i)
    );
  }

  const s = StyleSheet.create({
    root: {
      ...StyleSheet.absoluteFillObject,
      justifyContent: "flex-end",
    },
    backdrop: {
      ...StyleSheet.absoluteFillObject,
      backgroundColor: "rgba(0,0,0,0.45)",
    },
    sheet: {
      backgroundColor: colors.background,
      borderTopLeftRadius: 22,
      borderTopRightRadius: 22,
      paddingTop: 8,
      paddingHorizontal: 16,
      paddingBottom: Math.max(insets.bottom, 16) + 8,
      maxHeight: "85%",
    },
    handle: {
      width: 40,
      height: 4,
      borderRadius: 2,
      backgroundColor: colors.border,
      alignSelf: "center",
      marginBottom: 14,
    },
    titleText: {
      fontSize: 16,
      fontWeight: "700" as const,
      color: colors.foreground,
      textAlign: "center",
      marginBottom: 14,
    },
    yearNavRow: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      marginBottom: 12,
      paddingHorizontal: 4,
    },
    yearNavBtn: {
      width: 38,
      height: 38,
      borderRadius: 10,
      backgroundColor: colors.muted,
      alignItems: "center",
      justifyContent: "center",
    },
    yearNavLabel: {
      fontSize: 18,
      fontWeight: "800" as const,
      color: colors.foreground,
    },
    monthGrid: {
      flexDirection: "row",
      flexWrap: "wrap",
      gap: 7,
      marginBottom: 14,
    },
    monthBtn: {
      width: "30%",
      paddingVertical: 12,
      borderRadius: 12,
      backgroundColor: colors.muted,
      alignItems: "center",
      flexGrow: 1,
    },
    monthBtnActive: { backgroundColor: colors.primary },
    monthBtnText: {
      fontSize: 13,
      fontWeight: "600" as const,
      color: colors.foreground,
    },
    monthBtnTextActive: { color: "#FFFFFF" },
    divider: {
      height: 1,
      backgroundColor: colors.border,
      marginBottom: 10,
    },
    sectionLabel: {
      fontSize: 12,
      fontWeight: "700" as const,
      color: colors.mutedForeground,
      marginBottom: 8,
      letterSpacing: 0.3,
    },
    dayGrid: { gap: 5 },
    dayRow: { flexDirection: "row", gap: 5 },
    dayBtn: {
      flex: 1,
      paddingVertical: 10,
      borderRadius: 10,
      backgroundColor: colors.muted,
      alignItems: "center",
    },
    dayBtnActive: { backgroundColor: colors.primary },
    dayBtnText: {
      fontSize: 13,
      fontWeight: "600" as const,
      color: colors.foreground,
    },
    dayBtnTextActive: { color: "#FFFFFF" },
  });

  return (
    <Animated.View
      style={[s.root, { opacity: opacityAnim, pointerEvents: visible ? "auto" : "none" }]}
    >
      <Pressable style={s.backdrop} onPress={onClose} />
      <Animated.View
        style={[s.sheet, { transform: [{ translateY: slideAnim }] }]}
      >
        <View style={s.handle} />
        <Text style={s.titleText}>{title ?? t("datePicker.selectDate")}</Text>

        {/* Year navigation */}
        <View style={s.yearNavRow}>
          <TouchableOpacity
            style={s.yearNavBtn}
            onPress={() => {
              Haptics.selectionAsync();
              setPickerYear((y) => y - 1);
            }}
          >
            <Feather name="chevron-left" size={20} color={colors.foreground} />
          </TouchableOpacity>
          <Text style={s.yearNavLabel}>{pickerYear}</Text>
          <TouchableOpacity
            style={s.yearNavBtn}
            onPress={() => {
              Haptics.selectionAsync();
              setPickerYear((y) => y + 1);
            }}
          >
            <Feather name="chevron-right" size={20} color={colors.foreground} />
          </TouchableOpacity>
        </View>

        {/* Month grid */}
        <View style={s.monthGrid}>
          {Array.from({ length: 12 }, (_, idx) => {
            const isActive = idx === pickerMonth;
            const name = new Intl.DateTimeFormat(i18n.language, { month: "short" }).format(new Date(2000, idx, 1));
            return (
              <TouchableOpacity
                key={idx}
                style={[s.monthBtn, isActive && s.monthBtnActive]}
                onPress={() => handleMonthSelect(idx)}
              >
                <Text
                  style={[s.monthBtnText, isActive && s.monthBtnTextActive]}
                >
                  {name}
                </Text>
              </TouchableOpacity>
            );
          })}
        </View>

        <View style={s.divider} />
        <Text style={s.sectionLabel}>{t("datePicker.dayLabel")}</Text>

        {/* Day grid */}
        <ScrollView showsVerticalScrollIndicator={false}>
          <View style={s.dayGrid}>
            {dayRows.map((row, ri) => (
              <View key={ri} style={s.dayRow}>
                {row.map((d) => {
                  const isActive = d === safeDay;
                  return (
                    <TouchableOpacity
                      key={d}
                      style={[s.dayBtn, isActive && s.dayBtnActive]}
                      onPress={() => handleDaySelect(d)}
                    >
                      <Text
                        style={[s.dayBtnText, isActive && s.dayBtnTextActive]}
                      >
                        {d}
                      </Text>
                    </TouchableOpacity>
                  );
                })}
                {row.length < 7 &&
                  Array.from({ length: 7 - row.length }).map((_, i) => (
                    <View
                      key={`e-${i}`}
                      style={[s.dayBtn, { backgroundColor: "transparent" }]}
                    />
                  ))}
              </View>
            ))}
          </View>
        </ScrollView>
      </Animated.View>
    </Animated.View>
  );
}
