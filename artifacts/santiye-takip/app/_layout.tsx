import {
  Inter_400Regular,
  Inter_500Medium,
  Inter_600SemiBold,
  Inter_700Bold,
  useFonts,
} from "@expo-google-fonts/inter";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { Stack, useRouter, useSegments } from "expo-router";
import * as SplashScreen from "expo-splash-screen";
import React, { useEffect } from "react";
import { GestureHandlerRootView } from "react-native-gesture-handler";
import { SafeAreaProvider } from "react-native-safe-area-context";

import { ErrorBoundary } from "@/components/ErrorBoundary";
import WebFrame from "@/components/WebFrame";
import { AppProvider, useApp } from "@/context/AppContext";
import { ThemeProvider } from "@/context/ThemeContext";

SplashScreen.preventAutoHideAsync();

const queryClient = new QueryClient();

function AppGate({ children }: { children: React.ReactNode }) {
  const { currentUserId, loaded, workspaceInfo } = useApp();
  const router = useRouter();
  const segments = useSegments();
  const firstSegment = segments[0] ?? "";

  useEffect(() => {
    if (!loaded) return;
    const inLogin = firstSegment === "login";
    const inWorkspace = firstSegment === "workspace-setup";

    if (!workspaceInfo && !inWorkspace) {
      router.replace("/workspace-setup" as any);
      return;
    }
    if (workspaceInfo && !currentUserId && !inLogin && !inWorkspace) {
      router.replace("/login" as any);
      return;
    }
    if (workspaceInfo && currentUserId && inLogin) {
      router.replace("/");
    }
  }, [loaded, currentUserId, workspaceInfo?.id, firstSegment]);

  return <>{children}</>;
}

function RootLayoutNav() {
  return (
    <AppGate>
      <Stack screenOptions={{ headerShown: false }}>
        <Stack.Screen name="index" />
        <Stack.Screen name="login" />
        <Stack.Screen name="workspace-setup" />
        <Stack.Screen name="kullanicilar" />
        <Stack.Screen name="proje" />
        <Stack.Screen name="kesif" />
        <Stack.Screen name="is-programi" />
        <Stack.Screen name="puantaj" />
        <Stack.Screen name="gunluk-rapor" />
        <Stack.Screen name="imalat" />
        <Stack.Screen name="gorev" />
        <Stack.Screen name="malzeme" />
        <Stack.Screen name="taseron" />
        <Stack.Screen name="butce" />
        <Stack.Screen name="hakedis" />
        <Stack.Screen name="rapor" />
        <Stack.Screen name="temalar" />
        <Stack.Screen name="asistan" />
      </Stack>
    </AppGate>
  );
}

export default function RootLayout() {
  const [fontsLoaded, fontError] = useFonts({
    Inter_400Regular,
    Inter_500Medium,
    Inter_600SemiBold,
    Inter_700Bold,
  });

  useEffect(() => {
    if (fontsLoaded || fontError) {
      SplashScreen.hideAsync();
    }
  }, [fontsLoaded, fontError]);

  if (!fontsLoaded && !fontError) return null;

  return (
    <SafeAreaProvider>
      <ThemeProvider>
        <ErrorBoundary>
          <QueryClientProvider client={queryClient}>
            <GestureHandlerRootView style={{ flex: 1 }}>
              <WebFrame>
                <AppProvider>
                  <RootLayoutNav />
                </AppProvider>
              </WebFrame>
            </GestureHandlerRootView>
          </QueryClientProvider>
        </ErrorBoundary>
      </ThemeProvider>
    </SafeAreaProvider>
  );
}
