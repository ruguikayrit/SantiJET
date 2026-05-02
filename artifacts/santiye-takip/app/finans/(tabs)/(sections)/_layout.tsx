import { Slot } from "expo-router";
import { Platform, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import { useColors } from "@/hooks/finans/useColors";
import { SectionTabs } from "@/components/finans/SectionTabs";

const TAB_BAR_HEIGHT_WEB = 84;
const TAB_BAR_HEIGHT_NATIVE = 62; // custom tab bar height (CustomTabBar BAR_HEIGHT)

export default function SectionsLayout() {
  const insets = useSafeAreaInsets();
  const colors = useColors();
  const topPad = Platform.OS === "web" ? 67 : insets.top;
  const bottomPad =
    Platform.OS === "web"
      ? TAB_BAR_HEIGHT_WEB
      : TAB_BAR_HEIGHT_NATIVE + insets.bottom;

  return (
    <View style={{ flex: 1, backgroundColor: colors.background, paddingBottom: bottomPad }}>
      <View style={{ flex: 1, paddingTop: topPad }}>
        <Slot />
      </View>
      <SectionTabs />
    </View>
  );
}
