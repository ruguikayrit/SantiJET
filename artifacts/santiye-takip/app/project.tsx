import { Feather } from "@expo/vector-icons";
import * as Haptics from "expo-haptics";
import { router } from "expo-router";
import React, { useState } from "react";
import {
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import BottomSheet from "@/components/BottomSheet";
import EmptyState from "@/components/EmptyState";
import FormInput from "@/components/FormInput";
import PrimaryButton from "@/components/PrimaryButton";
import {
  createDefaultSafetyItems,
  Equipment,
  Material,
  SafetyCheck,
  SafetyItem,
  useApp,
  Worker,
  WorkItem,
  DailyReport,
  Project,
} from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";

const TABS = [
  { key: "overview", label: "Özet", icon: "grid" },
  { key: "workers", label: "Personel", icon: "users" },
  { key: "materials", label: "Malzeme", icon: "package" },
  { key: "workitems", label: "İmalatlar", icon: "tool" },
  { key: "equipment", label: "Ekipman", icon: "truck" },
  { key: "safety", label: "Güvenlik", icon: "shield" },
  { key: "reports", label: "Raporlar", icon: "file-text" },
] as const;

type TabKey = (typeof TABS)[number]["key"];

export default function ProjectScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const {
    selectedProject,
    workers,
    materials,
    workItems,
    equipment,
    safetyChecks,
    dailyReports,
    updateProject,
  } = useApp();
  const [activeTab, setActiveTab] = useState<TabKey>("overview");
  const topPad = Platform.OS === "web" ? 67 : insets.top;

  if (!selectedProject) {
    router.replace("/");
    return null;
  }

  const projectWorkers = workers.filter(
    (w) => w.projectId === selectedProject.id && w.status === "active"
  );
  const projectMaterials = materials.filter(
    (m) => m.projectId === selectedProject.id
  );
  const projectWorkItems = workItems.filter(
    (w) => w.projectId === selectedProject.id
  );
  const projectEquipment = equipment.filter(
    (e) => e.projectId === selectedProject.id
  );
  const projectSafety = safetyChecks.filter(
    (s) => s.projectId === selectedProject.id
  );
  const projectReports = dailyReports.filter(
    (r) => r.projectId === selectedProject.id
  );

  const STATUS_LABELS: Record<string, string> = {
    active: "Aktif",
    paused: "Duraklatıldı",
    completed: "Tamamlandı",
  };
  const STATUS_COLORS: Record<string, string> = {
    active: "#16a34a",
    paused: "#d97706",
    completed: "#6b7280",
  };

  function renderTabContent() {
    switch (activeTab) {
      case "overview":
        return (
          <OverviewTab
            project={selectedProject!}
            workers={projectWorkers}
            reports={projectReports}
            workItems={projectWorkItems}
            updateProject={updateProject}
          />
        );
      case "workers":
        return <WorkersTab projectId={selectedProject!.id} workers={projectWorkers} />;
      case "materials":
        return <MaterialsTab projectId={selectedProject!.id} materials={projectMaterials} />;
      case "workitems":
        return <WorkItemsTab projectId={selectedProject!.id} items={projectWorkItems} />;
      case "equipment":
        return <EquipmentTab projectId={selectedProject!.id} equipment={projectEquipment} />;
      case "safety":
        return <SafetyTab projectId={selectedProject!.id} checks={projectSafety} />;
      case "reports":
        return <ReportsTab projectId={selectedProject!.id} reports={projectReports} />;
    }
  }

  return (
    <View style={[styles.container, { backgroundColor: colors.background }]}>
      <View
        style={[
          styles.header,
          { backgroundColor: colors.navy, paddingTop: topPad + 12 },
        ]}
      >
        <View style={styles.headerTop}>
          <TouchableOpacity
            onPress={() => router.back()}
            style={styles.backBtn}
            activeOpacity={0.7}
          >
            <Feather name="arrow-left" size={22} color="#fff" />
          </TouchableOpacity>
          <View style={styles.headerMid}>
            <Text style={styles.projectName} numberOfLines={1}>
              {selectedProject.name}
            </Text>
            <View style={styles.statusRow}>
              <View
                style={[
                  styles.statusDot,
                  { backgroundColor: STATUS_COLORS[selectedProject.status] },
                ]}
              />
              <Text
                style={[
                  styles.statusLabel,
                  { color: STATUS_COLORS[selectedProject.status] },
                ]}
              >
                {STATUS_LABELS[selectedProject.status]}
              </Text>
            </View>
          </View>
          <TouchableOpacity
            onPress={() => router.push("/edit-project")}
            style={styles.editBtn}
            activeOpacity={0.7}
          >
            <Feather name="edit-2" size={18} color="#fff" />
          </TouchableOpacity>
        </View>

        <View style={styles.progressSection}>
          <View style={styles.progressLabelRow}>
            <Text style={styles.progressLabelText}>İlerleme</Text>
            <Text style={styles.progressPct}>%{selectedProject.progress}</Text>
          </View>
          <View style={styles.progressBar}>
            <View
              style={[
                styles.progressFill,
                {
                  width: `${selectedProject.progress}%` as any,
                  backgroundColor: colors.primary,
                },
              ]}
            />
          </View>
        </View>
      </View>

      <ScrollView
        horizontal
        showsHorizontalScrollIndicator={false}
        style={[
          styles.tabBar,
          { backgroundColor: colors.card, borderBottomColor: colors.border },
        ]}
        contentContainerStyle={styles.tabBarContent}
      >
        {TABS.map((tab) => (
          <TouchableOpacity
            key={tab.key}
            style={[
              styles.tab,
              activeTab === tab.key && {
                borderBottomColor: colors.primary,
                borderBottomWidth: 2,
              },
            ]}
            onPress={() => setActiveTab(tab.key)}
            activeOpacity={0.7}
          >
            <Feather
              name={tab.icon as any}
              size={16}
              color={
                activeTab === tab.key ? colors.primary : colors.mutedForeground
              }
            />
            <Text
              style={[
                styles.tabLabel,
                {
                  color:
                    activeTab === tab.key
                      ? colors.primary
                      : colors.mutedForeground,
                  fontFamily:
                    activeTab === tab.key
                      ? "Inter_600SemiBold"
                      : "Inter_400Regular",
                },
              ]}
            >
              {tab.label}
            </Text>
          </TouchableOpacity>
        ))}
      </ScrollView>

      <ScrollView
        style={styles.content}
        contentContainerStyle={{ paddingBottom: 40 }}
      >
        {renderTabContent()}
      </ScrollView>
    </View>
  );
}

// ─── Overview ────────────────────────────────────────────────────────────────

function OverviewTab({
  project,
  workers,
  reports,
  workItems,
  updateProject,
}: {
  project: Project;
  workers: Worker[];
  reports: DailyReport[];
  workItems: WorkItem[];
  updateProject: (id: string, p: Partial<Project>) => void;
}) {
  const colors = useColors();

  const avgProgress =
    workItems.length > 0
      ? Math.round(
          workItems.reduce((sum, w) => {
            const pct =
              w.plannedQty > 0 ? (w.completedQty / w.plannedQty) * 100 : 0;
            return sum + pct;
          }, 0) / workItems.length
        )
      : project.progress;

  return (
    <View style={{ padding: 16, gap: 16 }}>
      <View
        style={[
          overviewStyles.card,
          { backgroundColor: colors.card, borderColor: colors.border },
        ]}
      >
        <Text style={[overviewStyles.cardTitle, { color: colors.foreground }]}>
          Proje Bilgileri
        </Text>
        <InfoRow label="Konum" value={project.location || "-"} />
        <InfoRow label="Yüklenici" value={project.contractor || "-"} />
        <InfoRow label="Başlangıç" value={project.startDate || "-"} />
        <InfoRow label="Bitiş" value={project.endDate || "-"} />
        <InfoRow
          label="Bütçe"
          value={
            project.budget
              ? `₺${project.budget.toLocaleString("tr-TR")}`
              : "-"
          }
        />
        {project.description ? (
          <InfoRow label="Açıklama" value={project.description} />
        ) : null}
      </View>

      <View style={overviewStyles.statsGrid}>
        <MiniStat label="Personel" value={workers.length.toString()} color={colors.primary} />
        <MiniStat label="İmalat" value={workItems.length.toString()} color="#2563eb" />
        <MiniStat label="Rapor" value={reports.length.toString()} color="#16a34a" />
        <MiniStat label="% İlerleme" value={`${avgProgress}`} color="#7c3aed" />
      </View>

      <View
        style={[
          overviewStyles.card,
          { backgroundColor: colors.card, borderColor: colors.border },
        ]}
      >
        <Text style={[overviewStyles.cardTitle, { color: colors.foreground }]}>
          İlerleme Güncelle
        </Text>
        <View style={overviewStyles.progressBtns}>
          {[0, 25, 50, 75, 100].map((pct) => (
            <TouchableOpacity
              key={pct}
              style={[
                overviewStyles.pctBtn,
                {
                  backgroundColor:
                    project.progress === pct ? colors.primary : colors.muted,
                },
              ]}
              onPress={() => updateProject(project.id, { progress: pct })}
              activeOpacity={0.7}
            >
              <Text
                style={[
                  overviewStyles.pctLabel,
                  {
                    color:
                      project.progress === pct ? "#fff" : colors.foreground,
                  },
                ]}
              >
                %{pct}
              </Text>
            </TouchableOpacity>
          ))}
        </View>
      </View>
    </View>
  );
}

function InfoRow({ label, value }: { label: string; value: string }) {
  const colors = useColors();
  return (
    <View style={overviewStyles.infoRow}>
      <Text style={[overviewStyles.infoLabel, { color: colors.mutedForeground }]}>
        {label}
      </Text>
      <Text style={[overviewStyles.infoValue, { color: colors.foreground }]}>
        {value}
      </Text>
    </View>
  );
}

function MiniStat({
  label,
  value,
  color,
}: {
  label: string;
  value: string;
  color: string;
}) {
  const colors = useColors();
  return (
    <View
      style={[
        overviewStyles.miniStat,
        { backgroundColor: colors.card, borderColor: colors.border },
      ]}
    >
      <Text style={[overviewStyles.miniStatValue, { color }]}>{value}</Text>
      <Text
        style={[overviewStyles.miniStatLabel, { color: colors.mutedForeground }]}
      >
        {label}
      </Text>
    </View>
  );
}

const overviewStyles = StyleSheet.create({
  card: {
    borderRadius: 14,
    padding: 16,
    borderWidth: 1,
    gap: 10,
  },
  cardTitle: {
    fontSize: 16,
    fontFamily: "Inter_700Bold",
    marginBottom: 4,
  },
  infoRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    gap: 12,
  },
  infoLabel: {
    fontSize: 14,
    fontFamily: "Inter_400Regular",
    flex: 1,
  },
  infoValue: {
    fontSize: 14,
    fontFamily: "Inter_600SemiBold",
    flex: 2,
    textAlign: "right",
  },
  statsGrid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 10,
  },
  miniStat: {
    flex: 1,
    minWidth: "45%",
    borderRadius: 12,
    padding: 14,
    alignItems: "center",
    borderWidth: 1,
    gap: 4,
  },
  miniStatValue: {
    fontSize: 28,
    fontFamily: "Inter_700Bold",
  },
  miniStatLabel: {
    fontSize: 12,
    fontFamily: "Inter_400Regular",
  },
  progressBtns: {
    flexDirection: "row",
    gap: 8,
    flexWrap: "wrap",
  },
  pctBtn: {
    borderRadius: 8,
    paddingHorizontal: 14,
    paddingVertical: 8,
  },
  pctLabel: {
    fontSize: 14,
    fontFamily: "Inter_600SemiBold",
  },
});

// ─── Workers ─────────────────────────────────────────────────────────────────

function WorkersTab({
  projectId,
  workers,
}: {
  projectId: string;
  workers: Worker[];
}) {
  const colors = useColors();
  const { addWorker, deleteWorker, addAttendance, attendance } = useApp();
  const [showAdd, setShowAdd] = useState(false);
  const [name, setName] = useState("");
  const [role, setRole] = useState("");
  const [phone, setPhone] = useState("");
  const [rate, setRate] = useState("");

  const today = new Date().toISOString().split("T")[0];

  function handleAdd() {
    if (!name.trim()) return;
    addWorker({
      projectId,
      name: name.trim(),
      role,
      phone,
      dailyRate: parseFloat(rate) || 0,
      status: "active",
    });
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    setName("");
    setRole("");
    setPhone("");
    setRate("");
    setShowAdd(false);
  }

  function markAttendance(
    workerId: string,
    workerName: string,
    status: "present" | "absent" | "half"
  ) {
    const existing = attendance.find(
      (a) =>
        a.workerId === workerId &&
        a.date === today &&
        a.projectId === projectId
    );
    if (existing) return;
    addAttendance({
      projectId,
      workerId,
      workerName,
      date: today,
      status,
      note: "",
    });
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
  }

  function getAttendanceStatus(workerId: string): string | null {
    const a = attendance.find(
      (a) =>
        a.workerId === workerId &&
        a.date === today &&
        a.projectId === projectId
    );
    return a ? a.status : null;
  }

  const ATTENDANCE_COLORS: Record<string, string> = {
    present: "#16a34a",
    absent: "#dc2626",
    half: "#d97706",
  };
  const ATTENDANCE_LABELS: Record<string, string> = {
    present: "Mevcut",
    absent: "Devamsız",
    half: "Yarım",
  };

  return (
    <View style={{ padding: 16 }}>
      <View style={rowStyles.topRow}>
        <Text style={[rowStyles.sectionTitle, { color: colors.foreground }]}>
          Personel ({workers.length})
        </Text>
        <TouchableOpacity
          style={[rowStyles.addBtn, { backgroundColor: colors.primary }]}
          onPress={() => setShowAdd(true)}
          activeOpacity={0.8}
        >
          <Feather name="user-plus" size={16} color="#fff" />
        </TouchableOpacity>
      </View>

      {workers.length === 0 ? (
        <EmptyState
          icon="users"
          title="Personel yok"
          description="Personel ekleyin ve devamsızlık takibi yapın"
          actionLabel="Personel Ekle"
          onAction={() => setShowAdd(true)}
        />
      ) : (
        <View style={{ gap: 10 }}>
          {workers.map((w) => {
            const aStatus = getAttendanceStatus(w.id);
            return (
              <View
                key={w.id}
                style={[
                  rowStyles.workerCard,
                  { backgroundColor: colors.card, borderColor: colors.border },
                ]}
              >
                <View style={rowStyles.workerTop}>
                  <View
                    style={[
                      rowStyles.avatar,
                      { backgroundColor: colors.primary + "20" },
                    ]}
                  >
                    <Text
                      style={[
                        rowStyles.avatarText,
                        { color: colors.primary },
                      ]}
                    >
                      {w.name.charAt(0).toUpperCase()}
                    </Text>
                  </View>
                  <View style={{ flex: 1 }}>
                    <Text
                      style={[
                        rowStyles.workerName,
                        { color: colors.foreground },
                      ]}
                    >
                      {w.name}
                    </Text>
                    <Text
                      style={[
                        rowStyles.workerRole,
                        { color: colors.mutedForeground },
                      ]}
                    >
                      {w.role}
                    </Text>
                  </View>
                  <TouchableOpacity
                    onPress={() => deleteWorker(w.id)}
                    activeOpacity={0.7}
                  >
                    <Feather
                      name="trash-2"
                      size={16}
                      color={colors.destructive}
                    />
                  </TouchableOpacity>
                </View>

                <View style={rowStyles.attendanceRow}>
                  <Text
                    style={[
                      rowStyles.attendanceLabel,
                      { color: colors.mutedForeground },
                    ]}
                  >
                    Bugün:
                  </Text>
                  {aStatus ? (
                    <View
                      style={[
                        rowStyles.attendanceBadge,
                        {
                          backgroundColor:
                            ATTENDANCE_COLORS[aStatus] + "20",
                        },
                      ]}
                    >
                      <Text
                        style={[
                          rowStyles.attendanceBadgeText,
                          { color: ATTENDANCE_COLORS[aStatus] },
                        ]}
                      >
                        {ATTENDANCE_LABELS[aStatus]}
                      </Text>
                    </View>
                  ) : (
                    <View style={rowStyles.attendanceBtns}>
                      {(["present", "absent", "half"] as const).map((s) => (
                        <TouchableOpacity
                          key={s}
                          style={[
                            rowStyles.atkBtn,
                            {
                              backgroundColor:
                                ATTENDANCE_COLORS[s] + "15",
                              borderColor: ATTENDANCE_COLORS[s] + "40",
                            },
                          ]}
                          onPress={() => markAttendance(w.id, w.name, s)}
                          activeOpacity={0.7}
                        >
                          <Text
                            style={[
                              rowStyles.atkBtnText,
                              { color: ATTENDANCE_COLORS[s] },
                            ]}
                          >
                            {ATTENDANCE_LABELS[s]}
                          </Text>
                        </TouchableOpacity>
                      ))}
                    </View>
                  )}
                </View>
              </View>
            );
          })}
        </View>
      )}

      <BottomSheet
        visible={showAdd}
        onClose={() => setShowAdd(false)}
        title="Personel Ekle"
      >
        <FormInput
          label="Ad Soyad *"
          value={name}
          onChangeText={setName}
          placeholder="Ahmet Yılmaz"
        />
        <FormInput
          label="Görevi"
          value={role}
          onChangeText={setRole}
          placeholder="Usta, Kalıpçı..."
        />
        <FormInput
          label="Telefon"
          value={phone}
          onChangeText={setPhone}
          placeholder="05xx xxx xx xx"
          keyboardType="phone-pad"
        />
        <FormInput
          label="Günlük Ücret (TL)"
          value={rate}
          onChangeText={setRate}
          placeholder="0"
          keyboardType="numeric"
        />
        <PrimaryButton label="Kaydet" onPress={handleAdd} />
      </BottomSheet>
    </View>
  );
}

// ─── Materials ────────────────────────────────────────────────────────────────

function MaterialsTab({
  projectId,
  materials,
}: {
  projectId: string;
  materials: Material[];
}) {
  const colors = useColors();
  const { addMaterial, deleteMaterial, updateMaterial } = useApp();
  const [showAdd, setShowAdd] = useState(false);
  const [name, setName] = useState("");
  const [unit, setUnit] = useState("");
  const [qty, setQty] = useState("");
  const [supplier, setSupplier] = useState("");

  function handleAdd() {
    if (!name.trim()) return;
    addMaterial({
      projectId,
      name: name.trim(),
      unit,
      quantity: parseFloat(qty) || 0,
      usedQty: 0,
      supplier,
      deliveryDate: "",
    });
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    setName("");
    setUnit("");
    setQty("");
    setSupplier("");
    setShowAdd(false);
  }

  return (
    <View style={{ padding: 16 }}>
      <View style={rowStyles.topRow}>
        <Text style={[rowStyles.sectionTitle, { color: colors.foreground }]}>
          Malzemeler ({materials.length})
        </Text>
        <TouchableOpacity
          style={[rowStyles.addBtn, { backgroundColor: colors.primary }]}
          onPress={() => setShowAdd(true)}
          activeOpacity={0.8}
        >
          <Feather name="plus" size={18} color="#fff" />
        </TouchableOpacity>
      </View>

      {materials.length === 0 ? (
        <EmptyState
          icon="package"
          title="Malzeme yok"
          description="Malzeme ve stok takibi yapın"
          actionLabel="Malzeme Ekle"
          onAction={() => setShowAdd(true)}
        />
      ) : (
        <View style={{ gap: 10 }}>
          {materials.map((m) => {
            const pct =
              m.quantity > 0
                ? Math.min((m.usedQty / m.quantity) * 100, 100)
                : 0;
            return (
              <View
                key={m.id}
                style={[
                  rowStyles.workerCard,
                  { backgroundColor: colors.card, borderColor: colors.border },
                ]}
              >
                <View
                  style={{
                    flexDirection: "row",
                    justifyContent: "space-between",
                    alignItems: "flex-start",
                  }}
                >
                  <View style={{ flex: 1 }}>
                    <Text
                      style={[
                        rowStyles.workerName,
                        { color: colors.foreground },
                      ]}
                    >
                      {m.name}
                    </Text>
                    <Text
                      style={[
                        rowStyles.workerRole,
                        { color: colors.mutedForeground },
                      ]}
                    >
                      {m.supplier}
                    </Text>
                  </View>
                  <View style={{ alignItems: "flex-end", gap: 4 }}>
                    <Text
                      style={{
                        fontSize: 14,
                        fontFamily: "Inter_600SemiBold",
                        color: colors.foreground,
                      }}
                    >
                      {m.usedQty}/{m.quantity} {m.unit}
                    </Text>
                    <TouchableOpacity
                      onPress={() => deleteMaterial(m.id)}
                      activeOpacity={0.7}
                    >
                      <Feather
                        name="trash-2"
                        size={15}
                        color={colors.destructive}
                      />
                    </TouchableOpacity>
                  </View>
                </View>
                <View style={{ gap: 4 }}>
                  <View
                    style={{
                      flexDirection: "row",
                      justifyContent: "space-between",
                    }}
                  >
                    <Text
                      style={{
                        fontSize: 12,
                        color: colors.mutedForeground,
                        fontFamily: "Inter_400Regular",
                      }}
                    >
                      Kullanım
                    </Text>
                    <Text
                      style={{
                        fontSize: 12,
                        color: colors.primary,
                        fontFamily: "Inter_600SemiBold",
                      }}
                    >
                      %{Math.round(pct)}
                    </Text>
                  </View>
                  <View
                    style={[
                      rowStyles.progressBar,
                      { backgroundColor: colors.muted },
                    ]}
                  >
                    <View
                      style={[
                        rowStyles.progressFill,
                        {
                          width: `${pct}%` as any,
                          backgroundColor:
                            pct > 85 ? colors.destructive : colors.primary,
                        },
                      ]}
                    />
                  </View>
                </View>
                <TouchableOpacity
                  style={[
                    rowStyles.useBtn,
                    {
                      backgroundColor: colors.primary + "15",
                      borderColor: colors.primary + "40",
                    },
                  ]}
                  onPress={() =>
                    updateMaterial(m.id, {
                      usedQty: Math.min(m.usedQty + 1, m.quantity),
                    })
                  }
                  activeOpacity={0.7}
                >
                  <Text
                    style={{
                      fontSize: 13,
                      color: colors.primary,
                      fontFamily: "Inter_600SemiBold",
                    }}
                  >
                    +1 Kullan
                  </Text>
                </TouchableOpacity>
              </View>
            );
          })}
        </View>
      )}

      <BottomSheet
        visible={showAdd}
        onClose={() => setShowAdd(false)}
        title="Malzeme Ekle"
      >
        <FormInput
          label="Malzeme Adı *"
          value={name}
          onChangeText={setName}
          placeholder="Çimento, Demir..."
        />
        <FormInput
          label="Birim"
          value={unit}
          onChangeText={setUnit}
          placeholder="kg, ton, m², adet..."
        />
        <FormInput
          label="Miktar"
          value={qty}
          onChangeText={setQty}
          placeholder="0"
          keyboardType="numeric"
        />
        <FormInput
          label="Tedarikçi"
          value={supplier}
          onChangeText={setSupplier}
          placeholder="Firma adı"
        />
        <PrimaryButton label="Kaydet" onPress={handleAdd} />
      </BottomSheet>
    </View>
  );
}

// ─── Work Items ───────────────────────────────────────────────────────────────

function WorkItemsTab({
  projectId,
  items,
}: {
  projectId: string;
  items: WorkItem[];
}) {
  const colors = useColors();
  const { addWorkItem, deleteWorkItem, updateWorkItem } = useApp();
  const [showAdd, setShowAdd] = useState(false);
  const [name, setName] = useState("");
  const [unit, setUnit] = useState("");
  const [planned, setPlanned] = useState("");
  const [price, setPrice] = useState("");

  function handleAdd() {
    if (!name.trim()) return;
    addWorkItem({
      projectId,
      name: name.trim(),
      unit,
      plannedQty: parseFloat(planned) || 0,
      completedQty: 0,
      unitPrice: parseFloat(price) || 0,
    });
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    setName("");
    setUnit("");
    setPlanned("");
    setPrice("");
    setShowAdd(false);
  }

  return (
    <View style={{ padding: 16 }}>
      <View style={rowStyles.topRow}>
        <Text style={[rowStyles.sectionTitle, { color: colors.foreground }]}>
          İmalatlar ({items.length})
        </Text>
        <TouchableOpacity
          style={[rowStyles.addBtn, { backgroundColor: colors.primary }]}
          onPress={() => setShowAdd(true)}
          activeOpacity={0.8}
        >
          <Feather name="plus" size={18} color="#fff" />
        </TouchableOpacity>
      </View>

      {items.length === 0 ? (
        <EmptyState
          icon="tool"
          title="İmalat kalemi yok"
          description="Metraj ve ilerleme takibi için iş kalemleri ekleyin"
          actionLabel="Kalem Ekle"
          onAction={() => setShowAdd(true)}
        />
      ) : (
        <View style={{ gap: 10 }}>
          {items.map((item) => {
            const pct =
              item.plannedQty > 0
                ? Math.min((item.completedQty / item.plannedQty) * 100, 100)
                : 0;
            return (
              <View
                key={item.id}
                style={[
                  rowStyles.workerCard,
                  { backgroundColor: colors.card, borderColor: colors.border },
                ]}
              >
                <View
                  style={{
                    flexDirection: "row",
                    justifyContent: "space-between",
                  }}
                >
                  <View style={{ flex: 1 }}>
                    <Text
                      style={[
                        rowStyles.workerName,
                        { color: colors.foreground },
                      ]}
                    >
                      {item.name}
                    </Text>
                    <Text
                      style={{
                        fontSize: 12,
                        color: colors.mutedForeground,
                        fontFamily: "Inter_400Regular",
                      }}
                    >
                      {item.completedQty}/{item.plannedQty} {item.unit}
                    </Text>
                  </View>
                  <View style={{ alignItems: "flex-end", gap: 4 }}>
                    <Text
                      style={{
                        fontSize: 15,
                        fontFamily: "Inter_700Bold",
                        color: colors.primary,
                      }}
                    >
                      %{Math.round(pct)}
                    </Text>
                    <TouchableOpacity
                      onPress={() => deleteWorkItem(item.id)}
                      activeOpacity={0.7}
                    >
                      <Feather
                        name="trash-2"
                        size={15}
                        color={colors.destructive}
                      />
                    </TouchableOpacity>
                  </View>
                </View>
                <View
                  style={[
                    rowStyles.progressBar,
                    { backgroundColor: colors.muted },
                  ]}
                >
                  <View
                    style={[
                      rowStyles.progressFill,
                      {
                        width: `${pct}%` as any,
                        backgroundColor:
                          pct >= 100 ? "#16a34a" : colors.primary,
                      },
                    ]}
                  />
                </View>
                <View style={{ flexDirection: "row", gap: 8 }}>
                  <TouchableOpacity
                    style={[
                      rowStyles.useBtn,
                      {
                        backgroundColor: colors.primary + "15",
                        borderColor: colors.primary + "40",
                      },
                    ]}
                    onPress={() =>
                      updateWorkItem(item.id, {
                        completedQty: Math.min(
                          item.completedQty + 1,
                          item.plannedQty
                        ),
                      })
                    }
                    activeOpacity={0.7}
                  >
                    <Text
                      style={{
                        fontSize: 13,
                        color: colors.primary,
                        fontFamily: "Inter_600SemiBold",
                      }}
                    >
                      +1 Tamamla
                    </Text>
                  </TouchableOpacity>
                  <TouchableOpacity
                    style={[
                      rowStyles.useBtn,
                      {
                        backgroundColor: colors.muted,
                        borderColor: colors.border,
                      },
                    ]}
                    onPress={() =>
                      updateWorkItem(item.id, {
                        completedQty: Math.max(item.completedQty - 1, 0),
                      })
                    }
                    activeOpacity={0.7}
                  >
                    <Text
                      style={{
                        fontSize: 13,
                        color: colors.mutedForeground,
                        fontFamily: "Inter_600SemiBold",
                      }}
                    >
                      -1
                    </Text>
                  </TouchableOpacity>
                </View>
              </View>
            );
          })}
        </View>
      )}

      <BottomSheet
        visible={showAdd}
        onClose={() => setShowAdd(false)}
        title="İmalat Kalemi Ekle"
      >
        <FormInput
          label="İmalat Adı *"
          value={name}
          onChangeText={setName}
          placeholder="Beton dökme, Demir bağlama..."
        />
        <FormInput
          label="Birim"
          value={unit}
          onChangeText={setUnit}
          placeholder="m³, m², adet, kg..."
        />
        <FormInput
          label="Planlanan Miktar"
          value={planned}
          onChangeText={setPlanned}
          placeholder="0"
          keyboardType="numeric"
        />
        <FormInput
          label="Birim Fiyat (TL)"
          value={price}
          onChangeText={setPrice}
          placeholder="0"
          keyboardType="numeric"
        />
        <PrimaryButton label="Kaydet" onPress={handleAdd} />
      </BottomSheet>
    </View>
  );
}

// ─── Equipment ────────────────────────────────────────────────────────────────

function EquipmentTab({
  projectId,
  equipment,
}: {
  projectId: string;
  equipment: Equipment[];
}) {
  const colors = useColors();
  const { addEquipment, deleteEquipment, updateEquipment } = useApp();
  const [showAdd, setShowAdd] = useState(false);
  const [name, setName] = useState("");
  const [type, setType] = useState("");
  const [operator, setOperator] = useState("");
  const [cost, setCost] = useState("");

  const STATUS_LABELS: Record<Equipment["status"], string> = {
    active: "Aktif",
    maintenance: "Bakımda",
    idle: "Beklemede",
  };
  const STATUS_COLORS: Record<Equipment["status"], string> = {
    active: "#16a34a",
    maintenance: "#d97706",
    idle: "#6b7280",
  };

  function handleAdd() {
    if (!name.trim()) return;
    addEquipment({
      projectId,
      name: name.trim(),
      type,
      status: "active",
      operator,
      dailyCost: parseFloat(cost) || 0,
    });
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    setName("");
    setType("");
    setOperator("");
    setCost("");
    setShowAdd(false);
  }

  function cycleStatus(eq: Equipment) {
    const statuses: Equipment["status"][] = ["active", "maintenance", "idle"];
    const idx = statuses.indexOf(eq.status);
    const next = statuses[(idx + 1) % statuses.length];
    updateEquipment(eq.id, { status: next });
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
  }

  return (
    <View style={{ padding: 16 }}>
      <View style={rowStyles.topRow}>
        <Text style={[rowStyles.sectionTitle, { color: colors.foreground }]}>
          Ekipman ({equipment.length})
        </Text>
        <TouchableOpacity
          style={[rowStyles.addBtn, { backgroundColor: colors.primary }]}
          onPress={() => setShowAdd(true)}
          activeOpacity={0.8}
        >
          <Feather name="plus" size={18} color="#fff" />
        </TouchableOpacity>
      </View>

      {equipment.length === 0 ? (
        <EmptyState
          icon="truck"
          title="Ekipman yok"
          description="İş makineleri ve ekipmanları takip edin"
          actionLabel="Ekipman Ekle"
          onAction={() => setShowAdd(true)}
        />
      ) : (
        <View style={{ gap: 10 }}>
          {equipment.map((eq) => (
            <View
              key={eq.id}
              style={[
                rowStyles.workerCard,
                { backgroundColor: colors.card, borderColor: colors.border },
              ]}
            >
              <View
                style={{
                  flexDirection: "row",
                  justifyContent: "space-between",
                  alignItems: "flex-start",
                }}
              >
                <View style={{ flex: 1, gap: 2 }}>
                  <Text
                    style={[rowStyles.workerName, { color: colors.foreground }]}
                  >
                    {eq.name}
                  </Text>
                  <Text
                    style={[
                      rowStyles.workerRole,
                      { color: colors.mutedForeground },
                    ]}
                  >
                    {eq.type}
                  </Text>
                  {eq.operator ? (
                    <Text
                      style={{
                        fontSize: 12,
                        color: colors.mutedForeground,
                        fontFamily: "Inter_400Regular",
                      }}
                    >
                      Operatör: {eq.operator}
                    </Text>
                  ) : null}
                </View>
                <View style={{ alignItems: "flex-end", gap: 6 }}>
                  <TouchableOpacity
                    style={[
                      rowStyles.useBtn,
                      {
                        backgroundColor: STATUS_COLORS[eq.status] + "20",
                        borderColor: STATUS_COLORS[eq.status] + "50",
                      },
                    ]}
                    onPress={() => cycleStatus(eq)}
                    activeOpacity={0.7}
                  >
                    <Text
                      style={{
                        fontSize: 12,
                        color: STATUS_COLORS[eq.status],
                        fontFamily: "Inter_600SemiBold",
                      }}
                    >
                      {STATUS_LABELS[eq.status]}
                    </Text>
                  </TouchableOpacity>
                  <TouchableOpacity
                    onPress={() => deleteEquipment(eq.id)}
                    activeOpacity={0.7}
                  >
                    <Feather
                      name="trash-2"
                      size={15}
                      color={colors.destructive}
                    />
                  </TouchableOpacity>
                </View>
              </View>
              {eq.dailyCost > 0 && (
                <Text
                  style={{
                    fontSize: 13,
                    color: colors.mutedForeground,
                    fontFamily: "Inter_400Regular",
                  }}
                >
                  Günlük: ₺{eq.dailyCost.toLocaleString("tr-TR")}
                </Text>
              )}
            </View>
          ))}
        </View>
      )}

      <BottomSheet
        visible={showAdd}
        onClose={() => setShowAdd(false)}
        title="Ekipman Ekle"
      >
        <FormInput
          label="Ekipman Adı *"
          value={name}
          onChangeText={setName}
          placeholder="Ekskavatör, Vinç..."
        />
        <FormInput
          label="Türü"
          value={type}
          onChangeText={setType}
          placeholder="İş Makinesi, Araç..."
        />
        <FormInput
          label="Operatör"
          value={operator}
          onChangeText={setOperator}
          placeholder="Operatör adı"
        />
        <FormInput
          label="Günlük Maliyet (TL)"
          value={cost}
          onChangeText={setCost}
          placeholder="0"
          keyboardType="numeric"
        />
        <PrimaryButton label="Kaydet" onPress={handleAdd} />
      </BottomSheet>
    </View>
  );
}

// ─── Safety ───────────────────────────────────────────────────────────────────

function SafetyTab({
  projectId,
  checks,
}: {
  projectId: string;
  checks: SafetyCheck[];
}) {
  const colors = useColors();
  const { addSafetyCheck } = useApp();
  const [showNew, setShowNew] = useState(false);
  const [inspector, setInspector] = useState("");
  const [notes, setNotes] = useState("");
  const [items, setItems] = useState<SafetyItem[]>(createDefaultSafetyItems);

  function toggleItem(id: string) {
    setItems((prev) =>
      prev.map((item) => {
        if (item.id !== id) return item;
        const next: SafetyItem["status"][] = ["ok", "issue", "na"];
        const idx = next.indexOf(item.status);
        return { ...item, status: next[(idx + 1) % next.length] };
      })
    );
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
  }

  function handleSave() {
    const issueCount = items.filter((i) => i.status === "issue").length;
    const overallStatus: SafetyCheck["overallStatus"] =
      issueCount === 0 ? "pass" : issueCount > 3 ? "fail" : "partial";
    addSafetyCheck({
      projectId,
      date: new Date().toISOString().split("T")[0],
      inspector,
      items,
      overallStatus,
      notes,
    });
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    setInspector("");
    setNotes("");
    setItems(createDefaultSafetyItems());
    setShowNew(false);
  }

  const ITEM_STATUS_COLORS: Record<SafetyItem["status"], string> = {
    ok: "#16a34a",
    issue: "#dc2626",
    na: "#6b7280",
  };
  const ITEM_STATUS_LABELS: Record<SafetyItem["status"], string> = {
    ok: "Tamam",
    issue: "Sorun",
    na: "N/A",
  };
  const CHECK_STATUS_COLORS: Record<SafetyCheck["overallStatus"], string> = {
    pass: "#16a34a",
    fail: "#dc2626",
    partial: "#d97706",
  };
  const CHECK_STATUS_LABELS: Record<SafetyCheck["overallStatus"], string> = {
    pass: "Geçti",
    fail: "Başarısız",
    partial: "Kısmi",
  };

  return (
    <View style={{ padding: 16 }}>
      <View style={rowStyles.topRow}>
        <Text style={[rowStyles.sectionTitle, { color: colors.foreground }]}>
          Güvenlik Kontrolleri
        </Text>
        <TouchableOpacity
          style={[rowStyles.addBtn, { backgroundColor: colors.primary }]}
          onPress={() => setShowNew(true)}
          activeOpacity={0.8}
        >
          <Feather name="plus" size={18} color="#fff" />
        </TouchableOpacity>
      </View>

      {checks.length === 0 ? (
        <EmptyState
          icon="shield"
          title="Kontrol yok"
          description="İş güvenliği kontrol listesi oluşturun"
          actionLabel="Kontrol Başlat"
          onAction={() => setShowNew(true)}
        />
      ) : (
        <View style={{ gap: 10 }}>
          {checks.map((c) => (
            <View
              key={c.id}
              style={[
                rowStyles.workerCard,
                { backgroundColor: colors.card, borderColor: colors.border },
              ]}
            >
              <View
                style={{
                  flexDirection: "row",
                  justifyContent: "space-between",
                }}
              >
                <View>
                  <Text
                    style={[rowStyles.workerName, { color: colors.foreground }]}
                  >
                    {c.date}
                  </Text>
                  <Text
                    style={[
                      rowStyles.workerRole,
                      { color: colors.mutedForeground },
                    ]}
                  >
                    {c.inspector || "Denetçi belirtilmedi"}
                  </Text>
                </View>
                <View
                  style={[
                    rowStyles.useBtn,
                    {
                      backgroundColor:
                        CHECK_STATUS_COLORS[c.overallStatus] + "20",
                      borderColor: CHECK_STATUS_COLORS[c.overallStatus] + "50",
                    },
                  ]}
                >
                  <Text
                    style={{
                      fontSize: 13,
                      color: CHECK_STATUS_COLORS[c.overallStatus],
                      fontFamily: "Inter_600SemiBold",
                    }}
                  >
                    {CHECK_STATUS_LABELS[c.overallStatus]}
                  </Text>
                </View>
              </View>
              <Text
                style={{
                  fontSize: 13,
                  color: colors.mutedForeground,
                  fontFamily: "Inter_400Regular",
                }}
              >
                {c.items.filter((i) => i.status === "ok").length}/
                {c.items.length} madde geçti
              </Text>
            </View>
          ))}
        </View>
      )}

      <BottomSheet
        visible={showNew}
        onClose={() => setShowNew(false)}
        title="Yeni Güvenlik Kontrolü"
      >
        <FormInput
          label="Denetçi"
          value={inspector}
          onChangeText={setInspector}
          placeholder="Adınız"
        />
        <Text
          style={{
            fontSize: 15,
            fontFamily: "Inter_600SemiBold",
            color: colors.foreground,
            marginBottom: 12,
          }}
        >
          Kontrol Maddeleri
        </Text>
        {items.map((item) => (
          <TouchableOpacity
            key={item.id}
            style={{
              flexDirection: "row",
              justifyContent: "space-between",
              alignItems: "center",
              paddingVertical: 10,
              borderBottomWidth: StyleSheet.hairlineWidth,
              borderBottomColor: colors.border,
            }}
            onPress={() => toggleItem(item.id)}
            activeOpacity={0.7}
          >
            <View style={{ flex: 1 }}>
              <Text
                style={{
                  fontSize: 12,
                  color: colors.mutedForeground,
                  fontFamily: "Inter_400Regular",
                }}
              >
                {item.category}
              </Text>
              <Text
                style={{
                  fontSize: 14,
                  color: colors.foreground,
                  fontFamily: "Inter_400Regular",
                }}
              >
                {item.description}
              </Text>
            </View>
            <View
              style={[
                rowStyles.useBtn,
                {
                  backgroundColor: ITEM_STATUS_COLORS[item.status] + "20",
                  borderColor: ITEM_STATUS_COLORS[item.status] + "40",
                },
              ]}
            >
              <Text
                style={{
                  fontSize: 12,
                  color: ITEM_STATUS_COLORS[item.status],
                  fontFamily: "Inter_600SemiBold",
                }}
              >
                {ITEM_STATUS_LABELS[item.status]}
              </Text>
            </View>
          </TouchableOpacity>
        ))}
        <View style={{ height: 16 }} />
        <FormInput
          label="Notlar"
          value={notes}
          onChangeText={setNotes}
          placeholder="Ek notlar..."
          multiline
          numberOfLines={3}
          style={{ height: 80, textAlignVertical: "top" }}
        />
        <PrimaryButton label="Kontrolü Kaydet" onPress={handleSave} />
      </BottomSheet>
    </View>
  );
}

// ─── Reports ──────────────────────────────────────────────────────────────────

function ReportsTab({
  projectId,
  reports,
}: {
  projectId: string;
  reports: DailyReport[];
}) {
  const colors = useColors();
  const { addDailyReport } = useApp();
  const [showAdd, setShowAdd] = useState(false);
  const [weather, setWeather] = useState("");
  const [temp, setTemp] = useState("");
  const [workerCount, setWorkerCount] = useState("");
  const [activities, setActivities] = useState("");
  const [issues, setIssues] = useState("");
  const [createdBy, setCreatedBy] = useState("");

  function handleSave() {
    addDailyReport({
      projectId,
      date: new Date().toISOString().split("T")[0],
      weather,
      temperature: temp,
      workerCount: parseInt(workerCount) || 0,
      activities,
      issues,
      photos: [],
      createdBy,
    });
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    setWeather("");
    setTemp("");
    setWorkerCount("");
    setActivities("");
    setIssues("");
    setCreatedBy("");
    setShowAdd(false);
  }

  const WEATHER_OPTIONS = [
    "Güneşli",
    "Bulutlu",
    "Yağmurlu",
    "Karlı",
    "Rüzgarlı",
  ];

  return (
    <View style={{ padding: 16 }}>
      <View style={rowStyles.topRow}>
        <Text style={[rowStyles.sectionTitle, { color: colors.foreground }]}>
          Günlük Raporlar ({reports.length})
        </Text>
        <TouchableOpacity
          style={[rowStyles.addBtn, { backgroundColor: colors.primary }]}
          onPress={() => setShowAdd(true)}
          activeOpacity={0.8}
        >
          <Feather name="plus" size={18} color="#fff" />
        </TouchableOpacity>
      </View>

      {reports.length === 0 ? (
        <EmptyState
          icon="file-text"
          title="Rapor yok"
          description="Günlük şantiye raporu oluşturun"
          actionLabel="Rapor Oluştur"
          onAction={() => setShowAdd(true)}
        />
      ) : (
        <View style={{ gap: 10 }}>
          {[...reports].reverse().map((r) => (
            <View
              key={r.id}
              style={[
                rowStyles.workerCard,
                { backgroundColor: colors.card, borderColor: colors.border },
              ]}
            >
              <View
                style={{
                  flexDirection: "row",
                  justifyContent: "space-between",
                }}
              >
                <Text
                  style={[rowStyles.workerName, { color: colors.foreground }]}
                >
                  {r.date}
                </Text>
                <Text
                  style={{
                    fontSize: 13,
                    color: colors.mutedForeground,
                    fontFamily: "Inter_400Regular",
                  }}
                >
                  {r.weather} {r.temperature ? `• ${r.temperature}°C` : ""}
                </Text>
              </View>
              {r.createdBy ? (
                <Text
                  style={{
                    fontSize: 12,
                    color: colors.mutedForeground,
                    fontFamily: "Inter_400Regular",
                  }}
                >
                  Hazırlayan: {r.createdBy}
                </Text>
              ) : null}
              {r.workerCount > 0 ? (
                <Text
                  style={{
                    fontSize: 13,
                    color: colors.foreground,
                    fontFamily: "Inter_400Regular",
                  }}
                >
                  <Text style={{ fontFamily: "Inter_600SemiBold" }}>
                    {r.workerCount}
                  </Text>{" "}
                  işçi sahada
                </Text>
              ) : null}
              {r.activities ? (
                <View>
                  <Text
                    style={{
                      fontSize: 12,
                      fontFamily: "Inter_600SemiBold",
                      color: colors.mutedForeground,
                      marginBottom: 2,
                    }}
                  >
                    Faaliyetler
                  </Text>
                  <Text
                    style={{
                      fontSize: 13,
                      color: colors.foreground,
                      fontFamily: "Inter_400Regular",
                    }}
                  >
                    {r.activities}
                  </Text>
                </View>
              ) : null}
              {r.issues ? (
                <View>
                  <Text
                    style={{
                      fontSize: 12,
                      fontFamily: "Inter_600SemiBold",
                      color: colors.destructive,
                      marginBottom: 2,
                    }}
                  >
                    Sorunlar
                  </Text>
                  <Text
                    style={{
                      fontSize: 13,
                      color: colors.foreground,
                      fontFamily: "Inter_400Regular",
                    }}
                  >
                    {r.issues}
                  </Text>
                </View>
              ) : null}
            </View>
          ))}
        </View>
      )}

      <BottomSheet
        visible={showAdd}
        onClose={() => setShowAdd(false)}
        title="Günlük Rapor"
      >
        <Text
          style={{
            fontSize: 14,
            fontFamily: "Inter_600SemiBold",
            color: colors.foreground,
            marginBottom: 8,
          }}
        >
          Hava Durumu
        </Text>
        <View
          style={{
            flexDirection: "row",
            flexWrap: "wrap",
            gap: 8,
            marginBottom: 14,
          }}
        >
          {WEATHER_OPTIONS.map((w) => (
            <TouchableOpacity
              key={w}
              style={[
                rowStyles.useBtn,
                {
                  backgroundColor:
                    weather === w ? colors.primary : colors.muted,
                  borderColor:
                    weather === w ? colors.primary : colors.border,
                },
              ]}
              onPress={() => setWeather(w)}
              activeOpacity={0.7}
            >
              <Text
                style={{
                  fontSize: 13,
                  color: weather === w ? "#fff" : colors.foreground,
                  fontFamily: "Inter_500Medium",
                }}
              >
                {w}
              </Text>
            </TouchableOpacity>
          ))}
        </View>
        <FormInput
          label="Sıcaklık (°C)"
          value={temp}
          onChangeText={setTemp}
          placeholder="25"
          keyboardType="numeric"
        />
        <FormInput
          label="Sahada İşçi Sayısı"
          value={workerCount}
          onChangeText={setWorkerCount}
          placeholder="0"
          keyboardType="numeric"
        />
        <FormInput
          label="Bugünkü Faaliyetler *"
          value={activities}
          onChangeText={setActivities}
          placeholder="Beton dökme, kalıp..."
          multiline
          numberOfLines={3}
          style={{ height: 80, textAlignVertical: "top" }}
        />
        <FormInput
          label="Sorunlar / Eksikler"
          value={issues}
          onChangeText={setIssues}
          placeholder="Varsa yazın..."
          multiline
          numberOfLines={2}
          style={{ height: 60, textAlignVertical: "top" }}
        />
        <FormInput
          label="Hazırlayan"
          value={createdBy}
          onChangeText={setCreatedBy}
          placeholder="Adınız"
        />
        <PrimaryButton label="Raporu Kaydet" onPress={handleSave} />
      </BottomSheet>
    </View>
  );
}

// ─── Shared Styles ────────────────────────────────────────────────────────────

const rowStyles = StyleSheet.create({
  topRow: {
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBottom: 14,
  },
  sectionTitle: { fontSize: 17, fontFamily: "Inter_700Bold" },
  addBtn: {
    width: 36,
    height: 36,
    borderRadius: 18,
    justifyContent: "center",
    alignItems: "center",
  },
  workerCard: {
    borderRadius: 12,
    padding: 14,
    borderWidth: 1,
    gap: 10,
  },
  workerTop: { flexDirection: "row", alignItems: "center", gap: 12 },
  avatar: {
    width: 42,
    height: 42,
    borderRadius: 21,
    justifyContent: "center",
    alignItems: "center",
  },
  avatarText: { fontSize: 18, fontFamily: "Inter_700Bold" },
  workerName: { fontSize: 15, fontFamily: "Inter_600SemiBold" },
  workerRole: { fontSize: 13, fontFamily: "Inter_400Regular" },
  attendanceRow: { flexDirection: "row", alignItems: "center", gap: 10 },
  attendanceLabel: { fontSize: 13, fontFamily: "Inter_400Regular" },
  attendanceBadge: { borderRadius: 6, paddingHorizontal: 10, paddingVertical: 4 },
  attendanceBadgeText: { fontSize: 13, fontFamily: "Inter_600SemiBold" },
  attendanceBtns: { flexDirection: "row", gap: 6 },
  atkBtn: { borderRadius: 6, paddingHorizontal: 10, paddingVertical: 4, borderWidth: 1 },
  atkBtnText: { fontSize: 12, fontFamily: "Inter_600SemiBold" },
  progressBar: { height: 6, borderRadius: 3, overflow: "hidden" },
  progressFill: { height: "100%", borderRadius: 3 },
  useBtn: { borderRadius: 8, paddingHorizontal: 12, paddingVertical: 6, borderWidth: 1 },
});

const styles = StyleSheet.create({
  container: { flex: 1 },
  header: { paddingHorizontal: 20, paddingBottom: 20 },
  headerTop: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    marginBottom: 16,
  },
  backBtn: { width: 36, height: 36, justifyContent: "center", alignItems: "center" },
  headerMid: { flex: 1 },
  editBtn: { width: 36, height: 36, justifyContent: "center", alignItems: "center" },
  projectName: { fontSize: 20, fontFamily: "Inter_700Bold", color: "#fff" },
  statusRow: { flexDirection: "row", alignItems: "center", gap: 6, marginTop: 2 },
  statusDot: { width: 7, height: 7, borderRadius: 3.5 },
  statusLabel: { fontSize: 13, fontFamily: "Inter_600SemiBold" },
  progressSection: { gap: 8 },
  progressLabelRow: { flexDirection: "row", justifyContent: "space-between" },
  progressLabelText: {
    fontSize: 13,
    fontFamily: "Inter_400Regular",
    color: "rgba(255,255,255,0.7)",
  },
  progressPct: { fontSize: 13, fontFamily: "Inter_700Bold", color: "#e85d04" },
  progressBar: {
    height: 8,
    backgroundColor: "rgba(255,255,255,0.15)",
    borderRadius: 4,
    overflow: "hidden",
  },
  progressFill: { height: "100%", borderRadius: 4 },
  tabBar: { borderBottomWidth: StyleSheet.hairlineWidth },
  tabBarContent: { paddingHorizontal: 8 },
  tab: {
    paddingHorizontal: 14,
    paddingVertical: 12,
    flexDirection: "row",
    alignItems: "center",
    gap: 6,
  },
  tabLabel: { fontSize: 13 },
  content: { flex: 1 },
});
