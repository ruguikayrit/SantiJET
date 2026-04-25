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
import { KeyboardProvider } from "react-native-keyboard-controller";
import { SafeAreaProvider } from "react-native-safe-area-context";

import { ErrorBoundary } from "@/components/ErrorBoundary";
import { AppProvider, useApp } from "@/context/AppContext";

SplashScreen.preventAutoHideAsync();

const queryClient = new QueryClient();

function AppGate({ children }: { children: React.ReactNode }) {
  const { currentUserId, loaded, workspaceInfo } = useApp();
  const router = useRouter();
  const segments = useSegments();

  useEffect(() => {
    if (!loaded) return;
    const inLogin = segments[0] === "login";
    const inWorkspace = segments[0] === "workspace-setup";

    if (!workspaceInfo && !inWorkspace) {
      router.replace("/workspace-setup" as any);
      return;
    }
    if (!currentUserId && !inLogin && !inWorkspace) {
      router.replace("/login" as any);
    } else if (currentUserId && (inLogin || inWorkspace)) {
      router.replace("/");
    }
  }, [loaded, currentUserId, workspaceInfo, segments]);

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
      <ErrorBoundary>
        <QueryClientProvider client={queryClient}>
          <GestureHandlerRootView>
            <KeyboardProvider>
              <AppProvider>
                <RootLayoutNav />
              </AppProvider>
            </KeyboardProvider>
          </GestureHandlerRootView>
        </QueryClientProvider>
      </ErrorBoundary>
    </SafeAreaProvider>
  );
}
