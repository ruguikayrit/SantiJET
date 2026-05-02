import { Feather } from "@expo/vector-icons";
import * as Haptics from "expo-haptics";
import React, { useMemo, useState } from "react";
import { StyleSheet, Text, TouchableOpacity, View } from "react-native";
import { useTranslation } from "react-i18next";

import { useColors } from "@/hooks/finans/useColors";

interface Props {
  value: Date;
  onChange: (date: Date) => void;
  /** Maps "YYYY-MM-DD" → array of category colors (one per event on that day). */
  highlightedDates?: Map<string, string[]>;
  selectedDateStr?: string | null; // for filter-mode selection (distinct from value)
  onSelectDate?: (dateStr: string | null) => void;
  onViewMonthChange?: (yearMonth: string) => void; // "YYYY-MM" fires on month navigation
}

function toYMD(d: Date): string {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
}

export default function Calendar({
  value,
  onChange,
  highlightedDates,
  selectedDateStr,
  onSelectDate,
  onViewMonthChange,
}: Props) {
  const colors = useColors();
  const { t, i18n } = useTranslation();
  const [viewDate, setViewDate] = useState(
    new Date(value.getFullYear(), value.getMonth(), 1)
  );

  const toYM = (d: Date) =>
    `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;

  const changeView = (newDate: Date) => {
    setViewDate(newDate);
    onViewMonthChange?.(toYM(newDate));
  };

  const days = useMemo(() => {
    const year = viewDate.getFullYear();
    const month = viewDate.getMonth();
    const firstDay = new Date(year, month, 1);
    const lastDay = new Date(year, month + 1, 0);
    const totalDays = lastDay.getDate();
    let firstWeekday = firstDay.getDay() - 1;
    if (firstWeekday < 0) firstWeekday = 6;

    const cells: (Date | null)[] = [];
    for (let i = 0; i < firstWeekday; i++) cells.push(null);
    for (let d = 1; d <= totalDays; d++) cells.push(new Date(year, month, d));
    return cells;
  }, [viewDate]);

  const today = new Date();
  const isSameDay = (a: Date, b: Date) =>
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate();

  const goPrev = () => {
    Haptics.selectionAsync();
    changeView(new Date(viewDate.getFullYear(), viewDate.getMonth() - 1, 1));
  };
  const goNext = () => {
    Haptics.selectionAsync();
    changeView(new Date(viewDate.getFullYear(), viewDate.getMonth() + 1, 1));
  };
  const goToday = () => {
    Haptics.selectionAsync();
    changeView(new Date(today.getFullYear(), today.getMonth(), 1));
  };

  const isCurrentMonth =
    viewDate.getFullYear() === today.getFullYear() &&
    viewDate.getMonth() === today.getMonth();

  const monthLabel = new Date(viewDate.getFullYear(), viewDate.getMonth(), 1)
    .toLocaleDateString(i18n.language, { month: "long" });

  const dayLabels = useMemo(() => {
    return Array.from({ length: 7 }, (_, i) => {
      const d = new Date(2024, 0, 1 + i); // Jan 1, 2024 is a Monday
      return new Intl.DateTimeFormat(i18n.language, { weekday: "narrow" }).format(d);
    });
  }, [i18n.language]);

  const styles = StyleSheet.create({
    container: {
      backgroundColor: colors.card,
      borderRadius: colors.radius,
      padding: 14,
    },
    header: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      marginBottom: 12,
    },
    monthLabel: {
      fontSize: 15,
      fontWeight: "700" as const,
      color: colors.foreground,
    },
    navBtn: {
      width: 30,
      height: 30,
      borderRadius: 15,
      backgroundColor: colors.muted,
      alignItems: "center",
      justifyContent: "center",
    },
    weekRow: {
      flexDirection: "row",
      marginBottom: 6,
    },
    weekLabel: {
      flex: 1,
      textAlign: "center" as const,
      fontSize: 10,
      fontWeight: "600" as const,
      color: colors.mutedForeground,
    },
    grid: {
      flexDirection: "row",
      flexWrap: "wrap" as const,
    },
    cell: {
      width: `${100 / 7}%`,
      alignItems: "center",
      paddingVertical: 2,
    },
    dayBtn: {
      width: 32,
      height: 32,
      borderRadius: 16,
      alignItems: "center",
      justifyContent: "center",
    },
    dayText: {
      fontSize: 13,
      color: colors.foreground,
      fontWeight: "500" as const,
    },
    dotRow: {
      flexDirection: "row",
      gap: 3,
      marginTop: 2,
      height: 5,
      alignItems: "center",
      justifyContent: "center",
    },
    dot: {
      width: 5,
      height: 5,
      borderRadius: 3,
    },
    todayBtn: {
      paddingHorizontal: 10,
      paddingVertical: 5,
      borderRadius: 20,
      backgroundColor: colors.primary + "22",
      borderWidth: 1,
      borderColor: colors.primary + "55",
    },
    todayBtnText: {
      fontSize: 11,
      fontWeight: "700" as const,
      color: colors.primary,
    },
  });

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <TouchableOpacity style={styles.navBtn} onPress={goPrev}>
          <Feather name="chevron-left" size={16} color={colors.foreground} />
        </TouchableOpacity>
        <View style={{ flex: 1, alignItems: "center", gap: 4 }}>
          <Text style={styles.monthLabel}>
            {monthLabel} {viewDate.getFullYear()}
          </Text>
          {!isCurrentMonth && (
            <TouchableOpacity style={styles.todayBtn} onPress={goToday}>
              <Text style={styles.todayBtnText}>↩ {t("calendar.today")}</Text>
            </TouchableOpacity>
          )}
        </View>
        <TouchableOpacity style={styles.navBtn} onPress={goNext}>
          <Feather name="chevron-right" size={16} color={colors.foreground} />
        </TouchableOpacity>
      </View>

      <View style={styles.weekRow}>
        {dayLabels.map((d, idx) => (
          <Text key={idx} style={styles.weekLabel}>
            {d}
          </Text>
        ))}
      </View>

      <View style={styles.grid}>
        {days.map((d, i) => {
          if (!d) return <View key={`e-${i}`} style={styles.cell} />;
          const ymd = toYMD(d);
          const isFilterSelected = !!onSelectDate && selectedDateStr === ymd;
          const isValueSelected = !onSelectDate && isSameDay(d, value);
          const isSelected = isFilterSelected || isValueSelected;
          const isToday = isSameDay(d, today);

          // ── Event colors for this day ─────────────────────────────────────
          const rawColors = highlightedDates?.get(ymd) ?? [];
          // Deduplicate while preserving order
          const uniqueColors = rawColors.filter((c, idx) => rawColors.indexOf(c) === idx);
          const hasEvent = uniqueColors.length > 0;
          const primaryColor = uniqueColors[0];
          // Dots: show all unique colors (up to 3)
          const dotColors = uniqueColors.slice(0, 3);

          // ── Circle background priority: selected > event > today ──────────
          const circleBg = isSelected
            ? colors.primary
            : hasEvent
            ? primaryColor
            : isToday
            ? colors.muted
            : undefined;

          const textColor = isSelected || hasEvent
            ? "#FFFFFF"
            : colors.foreground;

          return (
            <View key={ymd} style={styles.cell}>
              <TouchableOpacity
                style={[styles.dayBtn, circleBg ? { backgroundColor: circleBg } : undefined]}
                onPress={() => {
                  Haptics.selectionAsync();
                  if (onSelectDate) {
                    onSelectDate(isFilterSelected ? null : ymd);
                  } else {
                    onChange(d);
                  }
                }}
              >
                <Text
                  style={[
                    styles.dayText,
                    { color: textColor },
                    (isSelected || hasEvent) && { fontWeight: "700" as const },
                  ]}
                >
                  {d.getDate()}
                </Text>
              </TouchableOpacity>

              {/* Colored category dots below the day */}
              {hasEvent && dotColors.length > 1 && (
                <View style={styles.dotRow}>
                  {dotColors.map((c, idx) => (
                    <View
                      key={idx}
                      style={[
                        styles.dot,
                        {
                          backgroundColor: isSelected ? "rgba(255,255,255,0.7)" : c,
                          width: dotColors.length > 2 ? 4 : 5,
                          height: dotColors.length > 2 ? 4 : 5,
                          borderRadius: 3,
                        },
                      ]}
                    />
                  ))}
                </View>
              )}
              {/* Single dot for single-category days (kept slim) */}
              {hasEvent && dotColors.length === 1 && (
                <View style={styles.dotRow}>
                  <View style={[styles.dot, { backgroundColor: isSelected ? "rgba(255,255,255,0.7)" : primaryColor, width: 5, height: 5 }]} />
                </View>
              )}
            </View>
          );
        })}
      </View>
    </View>
  );
}
