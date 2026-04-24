import * as Haptics from "expo-haptics";
import { router } from "expo-router";
import React, { useState } from "react";
import { Alert, ScrollView, StyleSheet, Text, TouchableOpacity, View } from "react-native";
import FormInput from "@/components/FormInput";
import Header from "@/components/Header";
import PrimaryButton from "@/components/PrimaryButton";
import { useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";

const STATUS_OPTIONS = [
  { value: "active", label: "Aktif", color: "#16a34a" },
  { value: "paused", label: "Duraklatıldı", color: "#d97706" },
  { value: "completed", label: "Tamamlandı", color: "#6b7280" },
] as const;

export default function EditProjectScreen() {
  const colors = useColors();
  const { selectedProject, updateProject, deleteProject } = useApp();

  const [name, setName] = useState(selectedProject?.name || "");
  const [location, setLocation] = useState(selectedProject?.location || "");
  const [contractor, setContractor] = useState(selectedProject?.contractor || "");
  const [startDate, setStartDate] = useState(selectedProject?.startDate || "");
  const [endDate, setEndDate] = useState(selectedProject?.endDate || "");
  const [budget, setBudget] = useState(selectedProject?.budget?.toString() || "");
  const [description, setDescription] = useState(selectedProject?.description || "");
  const [status, setStatus] = useState<"active" | "paused" | "completed">(selectedProject?.status || "active");

  if (!selectedProject) {
    router.replace("/");
    return null;
  }

  function handleSave() {
    if (!name.trim()) return;
    updateProject(selectedProject!.id, {
      name: name.trim(),
      location,
      contractor,
      startDate,
      endDate,
      budget: parseFloat(budget) || 0,
      description,
      status,
    });
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    router.back();
  }

  function handleDelete() {
    Alert.alert("Projeyi Sil", "Bu proje ve tüm verileri silinecek. Emin misiniz?", [
      { text: "İptal", style: "cancel" },
      {
        text: "Sil",
        style: "destructive",
        onPress: () => {
          deleteProject(selectedProject!.id);
          Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning);
          router.replace("/");
        },
      },
    ]);
  }

  return (
    <View style={[styles.container, { backgroundColor: colors.background }]}>
      <Header title="Projeyi Düzenle" onBack={() => router.back()} />
      <ScrollView style={styles.scroll} contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled">
        <FormInput label="Proje Adı *" value={name} onChangeText={setName} placeholder="Proje adı" />
        <FormInput label="Konum" value={location} onChangeText={setLocation} placeholder="Şehir, ilçe..." />
        <FormInput label="Yüklenici" value={contractor} onChangeText={setContractor} placeholder="Firma / kişi" />
        <FormInput label="Başlangıç Tarihi" value={startDate} onChangeText={setStartDate} placeholder="GG.AA.YYYY" />
        <FormInput label="Bitiş Tarihi" value={endDate} onChangeText={setEndDate} placeholder="GG.AA.YYYY" />
        <FormInput label="Bütçe (TL)" value={budget} onChangeText={setBudget} placeholder="0" keyboardType="numeric" />
        <FormInput label="Açıklama" value={description} onChangeText={setDescription} placeholder="Notlar..." multiline numberOfLines={3} style={{ height: 80, textAlignVertical: "top" }} />

        <Text style={[styles.statusLabel, { color: colors.foreground }]}>Durum</Text>
        <View style={styles.statusRow}>
          {STATUS_OPTIONS.map((opt) => (
            <TouchableOpacity
              key={opt.value}
              style={[
                styles.statusBtn,
                {
                  backgroundColor: status === opt.value ? opt.color : colors.muted,
                  borderColor: status === opt.value ? opt.color : colors.border,
                },
              ]}
              onPress={() => setStatus(opt.value)}
              activeOpacity={0.7}
            >
              <Text style={[styles.statusBtnText, { color: status === opt.value ? "#fff" : colors.foreground }]}>
                {opt.label}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        <PrimaryButton label="Kaydet" onPress={handleSave} style={{ marginTop: 8 }} />
        <PrimaryButton label="Projeyi Sil" onPress={handleDelete} variant="danger" style={{ marginTop: 10 }} />
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  scroll: { flex: 1 },
  content: { padding: 20, paddingBottom: 40 },
  statusLabel: { fontSize: 14, fontFamily: "Inter_600SemiBold", marginBottom: 8 },
  statusRow: { flexDirection: "row", gap: 10, marginBottom: 16 },
  statusBtn: { flex: 1, borderRadius: 10, paddingVertical: 10, alignItems: "center", borderWidth: 1 },
  statusBtnText: { fontSize: 13, fontFamily: "Inter_600SemiBold" },
});
