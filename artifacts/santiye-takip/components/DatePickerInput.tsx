import { Feather } from "@expo/vector-icons";
import React, { useEffect, useState } from "react";
import {
  Modal,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";

import { useColors } from "@/hooks/useColors";

const DAYS = ["Pt", "Sa", "Ça", "Pe", "Cu", "Ct", "Pz"];
const MONTHS = [
  "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
  "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık",
];

function todayDateObj() {
  const d = new Date();
  return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}

function parseStr(str: string): Date | null {
  const p = str.split(".");
  if (p.length !== 3) return null;
  const [dd, mm, yyyy] = p.map(Number);
  if (!dd || !mm || !yyyy) return null;
  const d = new Date(yyyy, mm - 1, dd);
  return isNaN(d.getTime()) ? null : d;
}

function formatDate(d: Date): string {
  return `${String(d.getDate()).padStart(2, "0")}.${String(d.getMonth() + 1).padStart(2, "0")}.${d.getFullYear()}`;
}

function sameDay(a: Date, b: Date) {
  return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
}

function buildGrid(year: number, month: number): (number | null)[][] {
  const firstDay = new Date(year, month, 1).getDay();
  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const offset = (firstDay === 0 ? 6 : firstDay - 1);
  const cells: (number | null)[] = Array(offset).fill(null);
  for (let d = 1; d <= daysInMonth; d++) cells.push(d);
  while (cells.length % 7 !== 0) cells.push(null);
  const rows: (number | null)[][] = [];
  for (let i = 0; i < cells.length; i += 7) rows.push(cells.slice(i, i + 7));
  return rows;
}

interface Props {
  label?: string;
  value: string;
  onChange: (v: string) => void;
}

export default function DatePickerInput({ label, value, onChange }: Props) {
  const colors = useColors();
  const today = todayDateObj();

  const [open, setOpen] = useState(false);
  const [cursor, setCursor] = useState<{ year: number; month: number }>(() => {
    const parsed = parseStr(value);
    return parsed
      ? { year: parsed.getFullYear(), month: parsed.getMonth() }
      : { year: today.getFullYear(), month: today.getMonth() };
  });

  const selected = parseStr(value);

  useEffect(() => {
    if (open) {
      const parsed = parseStr(value);
      if (parsed) {
        setCursor({ year: parsed.getFullYear(), month: parsed.getMonth() });
      } else {
        setCursor({ year: today.getFullYear(), month: today.getMonth() });
      }
    }
  }, [open]);

  function prev() {
    setCursor((c) => {
      if (c.month === 0) return { year: c.year - 1, month: 11 };
      return { year: c.year, month: c.month - 1 };
    });
  }

  function next() {
    setCursor((c) => {
      if (c.month === 11) return { year: c.year + 1, month: 0 };
      return { year: c.year, month: c.month + 1 };
    });
  }

  function selectDay(day: number | null) {
    if (!day) return;
    const d = new Date(cursor.year, cursor.month, day);
    onChange(formatDate(d));
    setOpen(false);
  }

  function goToday() {
    onChange(formatDate(today));
    setOpen(false);
  }

  const grid = buildGrid(cursor.year, cursor.month);

  return (
    <>
      {label ? (
        <Text style={[styles.label, { color: colors.foreground }]}>{label}</Text>
      ) : null}
      <TouchableOpacity
        style={[styles.trigger, { backgroundColor: colors.muted, borderColor: colors.border ?? colors.muted }]}
        onPress={() => setOpen(true)}
        activeOpacity={0.8}
      >
        <Feather name="calendar" size={16} color={colors.primary} />
        <Text style={[styles.triggerText, { color: value ? colors.foreground : colors.mutedForeground }]}>
          {value || "GG.AA.YYYY"}
        </Text>
        <Feather name="chevron-down" size={14} color={colors.mutedForeground} />
      </TouchableOpacity>

      <Modal visible={open} transparent animationType="fade" onRequestClose={() => setOpen(false)}>
        <TouchableOpacity
          style={styles.overlay}
          activeOpacity={1}
          onPress={() => setOpen(false)}
        >
          <TouchableOpacity activeOpacity={1} onPress={() => {}}>
            <View style={[styles.sheet, { backgroundColor: colors.card }]}>
              <View style={styles.navRow}>
                <TouchableOpacity onPress={prev} style={styles.navBtn} activeOpacity={0.7}>
                  <Feather name="chevron-left" size={20} color={colors.foreground} />
                </TouchableOpacity>
                <Text style={[styles.monthTitle, { color: colors.foreground }]}>
                  {MONTHS[cursor.month]} {cursor.year}
                </Text>
                <TouchableOpacity onPress={next} style={styles.navBtn} activeOpacity={0.7}>
                  <Feather name="chevron-right" size={20} color={colors.foreground} />
                </TouchableOpacity>
              </View>

              <View style={styles.dayHeader}>
                {DAYS.map((d) => (
                  <Text key={d} style={[styles.dayName, { color: colors.mutedForeground }]}>
                    {d}
                  </Text>
                ))}
              </View>

              {grid.map((row, ri) => (
                <View key={ri} style={styles.row}>
                  {row.map((day, ci) => {
                    const cellDate = day ? new Date(cursor.year, cursor.month, day) : null;
                    const isSel = !!(cellDate && selected && sameDay(cellDate, selected));
                    const isToday = !!(cellDate && sameDay(cellDate, today));
                    return (
                      <TouchableOpacity
                        key={ci}
                        style={[
                          styles.cell,
                          isSel && { backgroundColor: colors.primary },
                          !isSel && isToday && { borderWidth: 1.5, borderColor: colors.primary },
                        ]}
                        onPress={() => selectDay(day)}
                        activeOpacity={day ? 0.75 : 1}
                        disabled={!day}
                      >
                        {day ? (
                          <Text
                            style={[
                              styles.cellText,
                              { color: isSel ? "#fff" : isToday ? colors.primary : colors.foreground },
                              (isSel || isToday) && { fontFamily: "Inter_700Bold" },
                            ]}
                          >
                            {day}
                          </Text>
                        ) : null}
                      </TouchableOpacity>
                    );
                  })}
                </View>
              ))}

              <TouchableOpacity
                style={[styles.todayRow, { borderTopColor: colors.muted }]}
                onPress={goToday}
                activeOpacity={0.8}
              >
                <Feather name="crosshair" size={14} color={colors.primary} />
                <Text style={[styles.todayText, { color: colors.primary }]}>Bugün</Text>
              </TouchableOpacity>
            </View>
          </TouchableOpacity>
        </TouchableOpacity>
      </Modal>
    </>
  );
}

const styles = StyleSheet.create({
  label: {
    fontSize: 14,
    fontFamily: "Inter_600SemiBold",
    marginBottom: 6,
  },
  trigger: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderRadius: 10,
    borderWidth: 1,
    marginBottom: 14,
  },
  triggerText: {
    flex: 1,
    fontSize: 14,
    fontFamily: "Inter_500Medium",
  },
  overlay: {
    flex: 1,
    backgroundColor: "rgba(0,0,0,0.45)",
    justifyContent: "center",
    alignItems: "center",
    padding: 24,
  },
  sheet: {
    borderRadius: 16,
    padding: 16,
    width: 320,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.18,
    shadowRadius: 12,
    elevation: 10,
  },
  navRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    marginBottom: 14,
  },
  navBtn: { padding: 6 },
  monthTitle: {
    fontSize: 16,
    fontFamily: "Inter_700Bold",
  },
  dayHeader: {
    flexDirection: "row",
    marginBottom: 6,
  },
  dayName: {
    flex: 1,
    textAlign: "center",
    fontSize: 11,
    fontFamily: "Inter_600SemiBold",
  },
  row: {
    flexDirection: "row",
    marginBottom: 2,
  },
  cell: {
    flex: 1,
    aspectRatio: 1,
    borderRadius: 8,
    alignItems: "center",
    justifyContent: "center",
    margin: 1,
  },
  cellText: {
    fontSize: 13,
    fontFamily: "Inter_400Regular",
  },
  todayRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    gap: 6,
    marginTop: 12,
    paddingTop: 12,
    borderTopWidth: 1,
  },
  todayText: {
    fontSize: 14,
    fontFamily: "Inter_600SemiBold",
  },
});
