import { Tabs } from "expo-router";
import React from "react";
import { useTranslation } from "react-i18next";
import { View } from "react-native";

import { CustomTabBar } from "@/components/finans/CustomTabBar";
import VoiceAssistantButton from "@/components/finans/VoiceAssistantButton";

export default function TabLayout() {
  const { t } = useTranslation();

  return (
    <View style={{ flex: 1 }}>
      <Tabs
        tabBar={(props: any) => <CustomTabBar {...props} />}
        screenOptions={{
          headerShown: false,
          tabBarStyle: { display: "none" },
        }}
      >
        <Tabs.Screen name="index"        options={{ title: t("nav.home") }} />
        <Tabs.Screen name="transactions" options={{ title: t("nav.transactions") }} />
        <Tabs.Screen name="add"          options={{ title: t("nav.add") }} />
        <Tabs.Screen name="(sections)"   options={{ title: t("nav.financial") }} />
        <Tabs.Screen name="cash-flow"    options={{ href: null }} />
        <Tabs.Screen name="settings"     options={{ title: t("nav.settings") }} />
      </Tabs>
      <VoiceAssistantButton />
    </View>
  );
}
