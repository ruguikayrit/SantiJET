import { Feather } from "@expo/vector-icons";
import * as Haptics from "expo-haptics";
import React, { useEffect, useRef, useState } from "react";
import {
  Animated,
  Modal,
  Pressable,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";

import { useTranslation } from "react-i18next";

import { useColors } from "@/hooks/finans/useColors";

const PIN_LENGTH = 4;

const KEYS = [
  ["1", "2", "3"],
  ["4", "5", "6"],
  ["7", "8", "9"],
  ["", "0", "del"],
];

type Step = "verify" | "enter" | "confirm";

interface Props {
  visible: boolean;
  mode: "set" | "change" | "remove";
  currentPin: string | null;
  onSuccess: (newPin?: string) => void;
  onCancel: () => void;
}

export default function PinSetupModal({
  visible,
  mode,
  currentPin,
  onSuccess,
  onCancel,
}: Props) {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const { t } = useTranslation();
  const [step, setStep] = useState<Step>(
    mode === "set" ? "enter" : "verify"
  );
  const [entered, setEntered] = useState("");
  const [firstPin, setFirstPin] = useState("");
  const [error, setError] = useState(false);
  const shakeAnim = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    if (visible) {
      setStep(mode === "set" ? "enter" : "verify");
      setEntered("");
      setFirstPin("");
      setError(false);
    }
  }, [visible, mode]);

  const shake = () => {
    Animated.sequence([
      Animated.timing(shakeAnim, { toValue: 10, duration: 60, useNativeDriver: true }),
      Animated.timing(shakeAnim, { toValue: -10, duration: 60, useNativeDriver: true }),
      Animated.timing(shakeAnim, { toValue: 8, duration: 60, useNativeDriver: true }),
      Animated.timing(shakeAnim, { toValue: -8, duration: 60, useNativeDriver: true }),
      Animated.timing(shakeAnim, { toValue: 0, duration: 60, useNativeDriver: true }),
    ]).start();
  };

  const fail = () => {
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
    setError(true);
    shake();
    setTimeout(() => { setEntered(""); setError(false); }, 650);
  };

  useEffect(() => {
    if (entered.length < PIN_LENGTH) return;

    if (step === "verify") {
      if (entered === currentPin) {
        Haptics.selectionAsync();
        setEntered("");
        setError(false);
        if (mode === "remove") {
          onSuccess(undefined);
        } else {
          setStep("enter");
        }
      } else {
        fail();
      }
    } else if (step === "enter") {
      Haptics.selectionAsync();
      setFirstPin(entered);
      setEntered("");
      setStep("confirm");
    } else if (step === "confirm") {
      if (entered === firstPin) {
        Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
        onSuccess(entered);
      } else {
        fail();
      }
    }
  }, [entered]);

  const onKey = (key: string) => {
    if (key === "del") {
      Haptics.selectionAsync();
      setEntered((p) => p.slice(0, -1));
    } else if (key !== "" && entered.length < PIN_LENGTH) {
      Haptics.selectionAsync();
      setEntered((p) => p + key);
    }
  };

  const stepTitle = () => {
    if (step === "verify") return t("pin.verifyTitle");
    if (step === "confirm") return t("pin.confirmTitle");
    if (mode === "remove") return t("pin.enterToRemoveTitle");
    return t("pin.newPinTitle");
  };

  const stepSub = () => {
    if (step === "verify") return t("pin.verifySubtitle");
    if (step === "confirm") return t("pin.confirmSubtitle");
    return t("pin.enterSubtitle");
  };

  const s = StyleSheet.create({
    backdrop: {
      flex: 1,
      backgroundColor: "rgba(0,0,0,0.6)",
      justifyContent: "flex-end",
    },
    sheet: {
      backgroundColor: colors.navy,
      borderTopLeftRadius: 28,
      borderTopRightRadius: 28,
      paddingTop: 12,
      paddingBottom: Math.max(insets.bottom, 20) + 12,
      alignItems: "center",
    },
    handle: {
      width: 40,
      height: 4,
      borderRadius: 2,
      backgroundColor: "rgba(255,255,255,0.2)",
      marginBottom: 28,
    },
    closeBtn: {
      position: "absolute",
      top: 20,
      right: 20,
      width: 36,
      height: 36,
      borderRadius: 18,
      backgroundColor: "rgba(255,255,255,0.1)",
      alignItems: "center",
      justifyContent: "center",
    },
    title: {
      fontSize: 20,
      fontWeight: "800" as const,
      color: "#FFFFFF",
      marginBottom: 6,
    },
    subtitle: {
      fontSize: 13,
      color: "rgba(255,255,255,0.5)",
      marginBottom: 32,
    },
    dotsRow: {
      flexDirection: "row",
      gap: 18,
      marginBottom: 40,
    },
    dot: {
      width: 16,
      height: 16,
      borderRadius: 8,
      borderWidth: 2,
      borderColor: "rgba(255,255,255,0.35)",
    },
    dotFilled: { backgroundColor: "#FFFFFF", borderColor: "#FFFFFF" },
    dotError: { backgroundColor: "#FF4D6D", borderColor: "#FF4D6D" },
    dotOk: { backgroundColor: "#00C896", borderColor: "#00C896" },
    keypad: { gap: 12 },
    keyRow: { flexDirection: "row", gap: 16 },
    keyBtn: {
      width: 72,
      height: 72,
      borderRadius: 36,
      backgroundColor: "rgba(255,255,255,0.1)",
      alignItems: "center",
      justifyContent: "center",
    },
    keyBtnEmpty: { backgroundColor: "transparent" },
    keyBtnDel: { backgroundColor: "rgba(255,255,255,0.06)" },
    keyText: { fontSize: 24, fontWeight: "600" as const, color: "#FFFFFF" },
    errorText: {
      marginTop: 16,
      fontSize: 13,
      color: "#FF4D6D",
      fontWeight: "600" as const,
    },
    stepIndicator: {
      flexDirection: "row",
      gap: 6,
      marginBottom: 20,
    },
    stepDot: {
      width: 8,
      height: 8,
      borderRadius: 4,
      backgroundColor: "rgba(255,255,255,0.2)",
    },
    stepDotActive: { backgroundColor: "#00C896" },
    stepDotDone: { backgroundColor: "rgba(0,200,150,0.4)" },
  });

  const totalSteps = mode === "set" ? 2 : mode === "remove" ? 1 : 3;
  const currentStep =
    step === "verify" ? 1 : step === "enter" ? (mode === "set" ? 1 : 2) : (mode === "set" ? 2 : 3);

  return (
    <Modal visible={visible} transparent animationType="slide" onRequestClose={onCancel}>
      <Pressable style={s.backdrop} onPress={onCancel}>
        <Pressable style={s.sheet} onPress={() => {}}>
          <View style={s.handle} />

          <TouchableOpacity style={s.closeBtn} onPress={onCancel}>
            <Feather name="x" size={18} color="rgba(255,255,255,0.7)" />
          </TouchableOpacity>

          {totalSteps > 1 && (
            <View style={s.stepIndicator}>
              {Array.from({ length: totalSteps }).map((_, i) => (
                <View
                  key={i}
                  style={[
                    s.stepDot,
                    i + 1 === currentStep && s.stepDotActive,
                    i + 1 < currentStep && s.stepDotDone,
                  ]}
                />
              ))}
            </View>
          )}

          <Text style={s.title}>{stepTitle()}</Text>
          <Text style={s.subtitle}>{stepSub()}</Text>

          <Animated.View
            style={[s.dotsRow, { transform: [{ translateX: shakeAnim }] }]}
          >
            {Array.from({ length: PIN_LENGTH }).map((_, i) => (
              <View
                key={i}
                style={[
                  s.dot,
                  i < entered.length && (error ? s.dotError : s.dotFilled),
                ]}
              />
            ))}
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
                      <Feather name="delete" size={20} color="rgba(255,255,255,0.8)" />
                    ) : key === "" ? null : (
                      <Text style={s.keyText}>{key}</Text>
                    )}
                  </TouchableOpacity>
                ))}
              </View>
            ))}
          </View>

          {error && (
            <Text style={s.errorText}>
              {step === "verify" ? t("pin.wrongPin") : t("pin.pinMismatch")}
            </Text>
          )}
        </Pressable>
      </Pressable>
    </Modal>
  );
}
