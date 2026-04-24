import { Feather } from "@expo/vector-icons";
import { router } from "expo-router";
import React from "react";
import {
  FlatList,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import EmptyState from "@/components/EmptyState";
import ProjectCard from "@/components/ProjectCard";
import StatCard from "@/components/StatCard";
import { useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";

export default function HomeScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const { projects, workers, dailyReports, attendance, setSelectedProjectId } = useApp();
  const topPad = Platform.OS === "web" ? 67 : insets.top;

  const activeProjects = projects.filter((p) => p.status === "active").length;
  const totalWorkers = workers.filter((w) => w.status === "active").length;
  const today = new Date().toISOString().split("T")[0];
  const todayReports = dailyReports.filter((r) => r.date === today).length;
  const todayPresent = attendance.filter(
    (a) => a.date === today && a.status === "present"
  ).length;

  function handleProjectPress(id: string) {
    setSelectedProjectId(id);
    router.push("/project");
  }

  return (
    <View style={[styles.container, { backgroundColor: colors.background }]}>
      <View
        style={[
          styles.headerBg,
          { backgroundColor: colors.navy, paddingTop: topPad + 16 },
        ]}
      >
        <View style={styles.topRow}>
          <View>
            <Text style={styles.greeting}>Hoş Geldiniz</Text>
            <Text style={styles.appTitle}>Şantiye Takip</Text>
          </View>
          <TouchableOpacity
            style={[styles.addBtn, { backgroundColor: colors.primary }]}
            onPress={() => router.push("/new-project")}
            activeOpacity={0.8}
          >
            <Feather name="plus" size={22} color="#fff" />
          </TouchableOpacity>
        </View>

        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={styles.statsRow}
        >
          <StatCard
            icon="layers"
            label="Aktif Proje"
            value={activeProjects}
            color="#e85d04"
          />
          <StatCard
            icon="users"
            label="Personel"
            value={totalWorkers}
            color="#2563eb"
          />
          <StatCard
            icon="clipboard"
            label="Bugünkü Rapor"
            value={todayReports}
            color="#16a34a"
          />
          <StatCard
            icon="check-circle"
            label="Bugün Mevcut"
            value={todayPresent}
            color="#7c3aed"
          />
        </ScrollView>
      </View>

      <View style={styles.body}>
        <Text style={[styles.sectionTitle, { color: colors.foreground }]}>
          Projeler
        </Text>
        {projects.length === 0 ? (
          <EmptyState
            icon="briefcase"
            title="Henüz proje yok"
            description="İlk projenizi oluşturmak için + düğmesine dokunun"
            actionLabel="Proje Ekle"
            onAction={() => router.push("/new-project")}
          />
        ) : (
          <FlatList
            data={projects}
            keyExtractor={(item) => item.id}
            renderItem={({ item }) => (
              <ProjectCard
                project={item}
                onPress={() => handleProjectPress(item.id)}
              />
            )}
            showsVerticalScrollIndicator={false}
            contentContainerStyle={styles.listContent}
          />
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  headerBg: {
    paddingHorizontal: 20,
    paddingBottom: 20,
  },
  topRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 20,
  },
  greeting: {
    fontSize: 13,
    fontFamily: "Inter_400Regular",
    color: "rgba(255,255,255,0.7)",
  },
  appTitle: {
    fontSize: 24,
    fontFamily: "Inter_700Bold",
    color: "#ffffff",
  },
  addBtn: {
    width: 44,
    height: 44,
    borderRadius: 22,
    justifyContent: "center",
    alignItems: "center",
  },
  statsRow: {
    gap: 10,
    paddingRight: 4,
  },
  body: {
    flex: 1,
    paddingHorizontal: 20,
    paddingTop: 20,
  },
  sectionTitle: {
    fontSize: 18,
    fontFamily: "Inter_700Bold",
    marginBottom: 12,
  },
  listContent: {
    paddingBottom: 34,
  },
});
