import React from "react";
import { ScrollView, StyleSheet, Text, TouchableOpacity } from "react-native";
import { Project } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";

interface Props {
  projects: Project[];
  value: string | null;
  onChange: (id: string | null) => void;
  includeAll?: boolean;
}

export default function ProjectPicker({ projects, value, onChange, includeAll = true }: Props) {
  const colors = useColors();

  if (projects.length === 0) return null;

  return (
    <ScrollView
      horizontal
      showsHorizontalScrollIndicator={false}
      contentContainerStyle={styles.row}
      style={[styles.wrap, { borderBottomColor: colors.border }]}
    >
      {includeAll ? (
        <TouchableOpacity
          onPress={() => onChange(null)}
          style={[
            styles.chip,
            {
              backgroundColor: value === null ? colors.primary : colors.muted,
            },
          ]}
          activeOpacity={0.8}
        >
          <Text
            style={[
              styles.chipText,
              { color: value === null ? "#fff" : colors.foreground },
            ]}
          >
            Tümü
          </Text>
        </TouchableOpacity>
      ) : null}

      {projects.map((p) => (
        <TouchableOpacity
          key={p.id}
          onPress={() => onChange(p.id)}
          style={[
            styles.chip,
            {
              backgroundColor: value === p.id ? colors.primary : colors.muted,
            },
          ]}
          activeOpacity={0.8}
        >
          <Text
            style={[
              styles.chipText,
              { color: value === p.id ? "#fff" : colors.foreground },
            ]}
            numberOfLines={1}
          >
            {p.name}
          </Text>
        </TouchableOpacity>
      ))}
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  wrap: {
    flexGrow: 0,
    borderBottomWidth: StyleSheet.hairlineWidth,
  },
  row: {
    paddingHorizontal: 12,
    paddingVertical: 12,
    gap: 8,
  },
  chip: {
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 999,
    maxWidth: 180,
  },
  chipText: {
    fontSize: 13,
    fontFamily: "Inter_500Medium",
  },
});
