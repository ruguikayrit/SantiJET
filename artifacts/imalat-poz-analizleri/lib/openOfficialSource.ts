import { Alert, Linking } from "react-native";

import { SOURCE_OPEN_CONFIRM_MESSAGE } from "@/constants/officialSources";

export function openOfficialSource(url: string): void {
  Alert.alert("Resmi Kaynak", SOURCE_OPEN_CONFIRM_MESSAGE, [
    { text: "İptal", style: "cancel" },
    {
      text: "Aç",
      onPress: () => {
        void (async () => {
          try {
            const canOpen = await Linking.canOpenURL(url);
            if (!canOpen) {
              Alert.alert("Bağlantı açılamadı", "Resmi kaynak adresine erişilemiyor.");
              return;
            }
            await Linking.openURL(url);
          } catch {
            Alert.alert("Bağlantı açılamadı", "Resmi kaynak adresine erişilemiyor.");
          }
        })();
      },
    },
  ]);
}
