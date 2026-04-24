import * as Haptics from "expo-haptics";
import { router } from "expo-router";
import React, { useState } from "react";
import { ScrollView, StyleSheet, View } from "react-native";
import FormInput from "@/components/FormInput";
import Header from "@/components/Header";
import PrimaryButton from "@/components/PrimaryButton";
import { useApp } from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";

export default function NewProjectScreen() {
  const colors = useColors();
  const { addProject } = useApp();

  const [name, setName] = useState("");
  const [location, setLocation] = useState("");
  const [contractor, setContractor] = useState("");
  const [startDate, setStartDate] = useState("");
  const [endDate, setEndDate] = useState("");
  const [budget, setBudget] = useState("");
  const [description, setDescription] = useState("");

  function handleSave() {
    if (!name.trim()) return;
    addProject({
      name: name.trim(),
      location: location.trim(),
      contractor: contractor.trim(),
      startDate,
      endDate,
      budget: parseFloat(budget) || 0,
      status: "active",
      progress: 0,
      description: description.trim(),
    });
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    router.back();
  }

  return (
    <View style={[styles.container, { backgroundColor: colors.background }]}>
      <Header
        title="Yeni Proje"
        onBack={() => router.back()}
      />
      <ScrollView
        style={styles.scroll}
        contentContainerStyle={styles.content}
        keyboardShouldPersistTaps="handled"
      >
        <FormInput
          label="Proje Adı *"
          value={name}
          onChangeText={setName}
          placeholder="Örn: Bostancı Konut Projesi"
        />
        <FormInput
          label="Konum"
          value={location}
          onChangeText={setLocation}
          placeholder="Örn: İstanbul, Bostancı"
        />
        <FormInput
          label="Yüklenici / Müteahhit"
          value={contractor}
          onChangeText={setContractor}
          placeholder="Firma / kişi adı"
        />
        <FormInput
          label="Başlangıç Tarihi"
          value={startDate}
          onChangeText={setStartDate}
          placeholder="GG.AA.YYYY"
          keyboardType="numbers-and-punctuation"
        />
        <FormInput
          label="Bitiş Tarihi"
          value={endDate}
          onChangeText={setEndDate}
          placeholder="GG.AA.YYYY"
          keyboardType="numbers-and-punctuation"
        />
        <FormInput
          label="Bütçe (TL)"
          value={budget}
          onChangeText={setBudget}
          placeholder="0"
          keyboardType="numeric"
        />
        <FormInput
          label="Açıklama"
          value={description}
          onChangeText={setDescription}
          placeholder="Proje hakkında notlar..."
          multiline
          numberOfLines={4}
          style={{ height: 100, textAlignVertical: "top" }}
        />
        <PrimaryButton label="Projeyi Kaydet" onPress={handleSave} />
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  scroll: { flex: 1 },
  content: { padding: 20, paddingBottom: 40 },
});
