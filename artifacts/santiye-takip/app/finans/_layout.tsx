import { Feather } from "@expo/vector-icons";
import { Stack, useRouter } from "expo-router";
import React from "react";
import { Platform, TouchableOpacity, View } from "react-native";
import { GestureHandlerRootView } from "react-native-gesture-handler";

import "@/i18n-finans";
import { ErrorBoundary } from "@/components/finans/ErrorBoundary";
import { AuthProvider } from "@/context/finans/AuthContext";
import { BudgetProvider } from "@/context/finans/BudgetContext";
import { CurrencyProvider } from "@/context/finans/CurrencyContext";
import { PinProvider } from "@/context/finans/PinContext";
import { ThemeProvider } from "@/context/finans/ThemeContext";
import { VoiceAssistantProvider } from "@/context/finans/VoiceAssistantContext";
function FinansHeader() {
  const router = useRouter();
  return (
    <View
      style={{
        flexDirection: "row",
        alignItems: "center",
        gap: 10,
        paddingHorizontal: 12,
        paddingVertical: 10,
        backgroundColor: "#0B1E33",
      }}
    >
      <TouchableOpacity
        onPress={() => router.replace("/" as any)}
        style={{
          padding: 8,
          borderRadius: 10,
          backgroundColor: "rgba(255,255,255,0.08)",
        }}
        accessibilityLabel="ŞantiJET ana sayfasına dön"
      >
        <Feather name="arrow-left" size={18} color="#FFFFFF" />
      </TouchableOpacity>
    </View>
  );
}

export default function FinansLayout() {
  return (
    <ErrorBoundary>
      <ThemeProvider>
        <CurrencyProvider>
          <AuthProvider>
            <BudgetProvider>
              <VoiceAssistantProvider>
                <PinProvider>
                  <GestureHandlerRootView style={{ flex: 1 }}>
                    {Platform.OS === "web" ? <FinansHeader /> : null}
                    <Stack screenOptions={{ headerShown: false }}>
                      <Stack.Screen name="(tabs)" />
                    </Stack>
                  </GestureHandlerRootView>
                </PinProvider>
              </VoiceAssistantProvider>
            </BudgetProvider>
          </AuthProvider>
        </CurrencyProvider>
      </ThemeProvider>
    </ErrorBoundary>
  );
}
