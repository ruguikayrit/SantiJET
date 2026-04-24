import { Feather } from "@expo/vector-icons";
import React from "react";
import { StyleSheet, Text, TouchableOpacity, View } from "react-native";
import { useColors } from "@/hooks/useColors";
import { Project } from "@/context/AppContext";

interface Props {
  project: Project;
  onPress: () => void;
}

const STATUS_LABELS: Record<Project["status"], string> = {
  active: "Aktif",
  paused: "Duraklatıldı",
  completed: "Tamamlandı",
};

const STATUS_COLORS: Record<Project["status"], string> = {
  active: "#16a34a",
  paused: "#d97706",
  completed: "#6b7280",
};

export default function ProjectCard({ project, onPress }: Props) {
  const colors = useColors();

  return (
    <TouchableOpacity
      style={[styles.card, { backgroundColor: colors.card, borderColor: colors.border }]}
      onPress={onPress}
      activeOpacity={0.8}
    >
      <View style={styles.header}>
        <View style={[styles.statusDot, { backgroundColor: STATUS_COLORS[project.status] }]} />
        <Text style={[styles.status, { color: STATUS_COLORS[project.status] }]}>
          {STATUS_LABELS[project.status]}
        </Text>
      </View>

      <Text style={[styles.name, { color: colors.foreground }]} numberOfLines={2}>
        {project.name}
      </Text>

      <View style={styles.meta}>
        <Feather name="map-pin" size={13} color={colors.mutedForeground} />
        <Text style={[styles.metaText, { color: colors.mutedForeground }]} numberOfLines={1}>
          {project.location}
        </Text>
      </View>

      <View style={styles.progressRow}>
        <View style={[styles.progressBar, { backgroundColor: colors.muted }]}>
          <View
            style={[
              styles.progressFill,
              {
                backgroundColor: colors.primary,
                width: `${project.progress}%` as any,
              },
            ]}
          />
        </View>
        <Text style={[styles.progressText, { color: colors.primary }]}>
          %{project.progress}
        </Text>
      </View>

      <View style={styles.footer}>
        <View style={styles.footerItem}>
          <Feather name="calendar" size={12} color={colors.mutedForeground} />
          <Text style={[styles.footerText, { color: colors.mutedForeground }]}>
            {project.endDate}
          </Text>
        </View>
        <View style={styles.footerItem}>
          <Feather name="user" size={12} color={colors.mutedForeground} />
          <Text style={[styles.footerText, { color: colors.mutedForeground }]}>
            {project.contractor}
          </Text>
        </View>
      </View>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  card: {
    borderRadius: 14,
    padding: 16,
    marginBottom: 12,
    borderWidth: 1,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.06,
    shadowRadius: 8,
    elevation: 2,
  },
  header: {
    flexDirection: "row",
    alignItems: "center",
    marginBottom: 8,
    gap: 6,
  },
  statusDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  status: {
    fontSize: 12,
    fontFamily: "Inter_600SemiBold",
  },
  name: {
    fontSize: 17,
    fontFamily: "Inter_700Bold",
    marginBottom: 6,
    lineHeight: 22,
  },
  meta: {
    flexDirection: "row",
    alignItems: "center",
    gap: 4,
    marginBottom: 12,
  },
  metaText: {
    fontSize: 13,
    fontFamily: "Inter_400Regular",
    flex: 1,
  },
  progressRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    marginBottom: 12,
  },
  progressBar: {
    flex: 1,
    height: 6,
    borderRadius: 3,
    overflow: "hidden",
  },
  progressFill: {
    height: "100%",
    borderRadius: 3,
  },
  progressText: {
    fontSize: 13,
    fontFamily: "Inter_700Bold",
    minWidth: 36,
    textAlign: "right",
  },
  footer: {
    flexDirection: "row",
    justifyContent: "space-between",
  },
  footerItem: {
    flexDirection: "row",
    alignItems: "center",
    gap: 4,
  },
  footerText: {
    fontSize: 12,
    fontFamily: "Inter_400Regular",
  },
});
