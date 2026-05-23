import React from "react";
import { ActivityIndicator, StyleSheet, Text, TouchableOpacity, TouchableOpacityProps } from "react-native";
import { useColors } from "@/hooks/useColors";

const SAVE_GREEN = "#16a34a";
const CANCEL_RED = "#dc2626";

interface Props extends TouchableOpacityProps {
  label: string;
  loading?: boolean;
  variant?: "primary" | "secondary" | "danger" | "cancel";
}

export default function PrimaryButton({ label, loading, variant = "primary", style, ...props }: Props) {
  const colors = useColors();

  const bg =
    variant === "danger"
      ? colors.destructive
      : variant === "secondary"
      ? colors.muted
      : variant === "cancel"
      ? CANCEL_RED
      : SAVE_GREEN;

  const fg =
    variant === "secondary" ? colors.foreground : "#ffffff";

  return (
    <TouchableOpacity
      style={[styles.btn, { backgroundColor: bg }, style]}
      activeOpacity={0.8}
      disabled={loading || props.disabled}
      {...props}
    >
      {loading ? (
        <ActivityIndicator color={fg} />
      ) : (
        <Text style={[styles.label, { color: fg }]}>{label}</Text>
      )}
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  btn: {
    borderRadius: 12,
    paddingVertical: 14,
    alignItems: "center",
    justifyContent: "center",
  },
  label: {
    fontSize: 16,
    fontFamily: "Inter_600SemiBold",
  },
});
