import { Feather } from "@expo/vector-icons";
import * as Haptics from "expo-haptics";
import React, { useEffect, useRef, useState } from "react";
import {
  Animated,
  Platform,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import { usePin } from "@/context/finans/PinContext";
import { useColors } from "@/hooks/finans/useColors";

const PIN_LENGTH = 4;

const KEYS = [
  ["1", "2", "3"],
  ["4", "5", "6"],
  ["7", "8", "9"],
  ["", "0", "del"],
];

export default function PinLockScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const { unlock } = usePin();
  const [entered, setEntered] = useState("");
  const [error, setError] = useState(false);
  const shakeAnim = useRef(new Animated.Value(0)).current;

  const shake = () => {
    Animated.sequence([
      Animated.timing(shakeAnim, { toValue: 10, duration: 60, useNativeDriver: true }),
      Animated.timing(shakeAnim, { toValue: -10, duration: 60, useNativeDriver: true }),
      Animated.timing(shakeAnim, { toValue: 8, duration: 60, useNativeDriver: true }),
      Animated.timing(shakeAnim, { toValue: -8, duration: 60, useNativeDriver: true }),
      Animated.timing(shakeAnim, { toValue: 0, duration: 60, useNativeDriver: true }),
    ]).start();
  };

  useEffect(() => {
    if (entered.length === PIN_LENGTH) {
      const ok = unlock(entered);
      if (!ok) {
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
        setError(true);
        shake();
        setTimeout(() => {
          setEntered("");
          setError(false);
        }, 600);
      } else {
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      }
    }
  }, [entered]);

  const onKey = (key: string) => {
    if (key === "del") {
      Haptics.selectionAsync();
      setEntered((p) => p.slice(0, -1));
    } else if (key === "") {
      return;
    } else if (entered.length < PIN_LENGTH) {
      Haptics.selectionAsync();
      setEntered((p) => p + key);
    }
  };

  const s = StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: colors.navy,
      alignItems: "center",
      justifyContent: "center",
      paddingTop: insets.top,
      paddingBottom: insets.bottom,
    },
    logo: {
      width: 72,
      height: 72,
      borderRadius: 22,
      backgroundColor: "rgba(255,255,255,0.1)",
      alignItems: "center",
      justifyContent: "center",
      marginBottom: 24,
    },
    title: {
      fontSize: 22,
      fontWeight: "800" as const,
      color: "#FFFFFF",
      marginBottom: 6,
    },
    subtitle: {
      fontSize: 14,
      color: "rgba(255,255,255,0.55)",
      marginBottom: 40,
    },
    dotsRow: {
      flexDirection: "row",
      gap: 18,
      marginBottom: 48,
    },
    dot: {
      width: 16,
      height: 16,
      borderRadius: 8,
      borderWidth: 2,
      borderColor: "rgba(255,255,255,0.4)",
    },
    dotFilled: {
      backgroundColor: "#FFFFFF",
      borderColor: "#FFFFFF",
    },
    dotError: {
      backgroundColor: "#FF4D6D",
      borderColor: "#FF4D6D",
    },
    keypad: { gap: 14 },
    keyRow: { flexDirection: "row", gap: 20 },
    keyBtn: {
      width: 76,
      height: 76,
      borderRadius: 38,
      backgroundColor: "rgba(255,255,255,0.1)",
      alignItems: "center",
      justifyContent: "center",
    },
    keyBtnEmpty: { backgroundColor: "transparent" },
    keyBtnDel: { backgroundColor: "rgba(255,255,255,0.06)" },
    keyText: {
      fontSize: 26,
      fontWeight: "600" as const,
      color: "#FFFFFF",
    },
    errorText: {
      position: "absolute",
      bottom: Platform.OS === "web" ? 60 : insets.bottom + 40,
      fontSize: 13,
      color: "#FF4D6D",
      fontWeight: "600" as const,
    },
  });

  return (
    <View style={s.container}>
      <View style={s.logo}>
        <Feather name="lock" size={32} color="#FFFFFF" />
      </View>
      <Text style={s.title}>KasaFON</Text>
      <Text style={s.subtitle}>PIN kodunu gir</Text>

      <Animated.View
        style={[s.dotsRow, { transform: [{ translateX: shakeAnim }] }]}
      >
        {Array.from({ length: PIN_LENGTH }).map((_, i) => [
          <View
            key={i}
            style={[
              s.dot,
              i < entered.length && (error ? s.dotError : s.dotFilled),
            ]}
          />,
        ])}
      </Animated.View>

      <View style={s.keypad}>
        {KEYS.map((row, ri) => (
          <View key={ri} style={s.keyRow}>
            {row.map((key, ki) => (
              <TouchableOpacity
                key={ki}
                style={[
                  s.keyBtn,
                  key === "" && s.keyBtnEmpty,
                  key === "del" && s.keyBtnDel,
                ]}
                onPress={() => onKey(key)}
                disabled={key === ""}
                activeOpacity={key === "" ? 1 : 0.6}
              >
                {key === "del" ? (
                  <Feather name="delete" size={22} color="rgba(255,255,255,0.8)" />
                ) : key === "" ? null : (
                  <Text style={s.keyText}>{key}</Text>
                )}
              </TouchableOpacity>
            ))}
          </View>
        ))}
      </View>

      {error && <Text style={s.errorText}>Yanlış PIN</Text>}
    </View>
  );
}
