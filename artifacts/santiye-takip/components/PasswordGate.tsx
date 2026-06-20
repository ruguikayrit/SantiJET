import React, { useState, useEffect } from "react";
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ActivityIndicator,
  Platform,
} from "react-native";
import AsyncStorage from "@react-native-async-storage/async-storage";

const STORAGE_KEY = "santijet_app_auth";

async function verifyPassword(password: string): Promise<boolean> {
  try {
    const res = await fetch("/api/auth/verify", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ password }),
    });
    const data = (await res.json()) as { ok: boolean };
    return data.ok === true;
  } catch {
    return false;
  }
}

export function PasswordGate({ children }: { children: React.ReactNode }) {
  const [authenticated, setAuthenticated] = useState<boolean | null>(null);
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    AsyncStorage.getItem(STORAGE_KEY).then((val) => {
      setAuthenticated(val === "1");
    });
  }, []);

  async function handleSubmit() {
    if (!password) return;
    setLoading(true);
    setError("");
    const ok = await verifyPassword(password);
    setLoading(false);
    if (ok) {
      await AsyncStorage.setItem(STORAGE_KEY, "1");
      setAuthenticated(true);
    } else {
      setError("Parola hatalı. Tekrar deneyin.");
      setPassword("");
    }
  }

  if (authenticated === null) return null;
  if (authenticated) return <>{children}</>;

  return (
    <View style={styles.container}>
      <View style={styles.iconWrap}>
        <Text style={styles.iconText}>⚡</Text>
      </View>
      <Text style={styles.title}>ŞantiJET</Text>
      <Text style={styles.subtitle}>Erişim için parola gereklidir.</Text>

      <TextInput
        style={styles.input}
        value={password}
        onChangeText={setPassword}
        placeholder="Parola"
        placeholderTextColor="rgba(255,255,255,0.3)"
        secureTextEntry
        autoFocus
        onSubmitEditing={handleSubmit}
        returnKeyType="go"
      />

      {!!error && <Text style={styles.error}>{error}</Text>}

      <TouchableOpacity
        style={[styles.button, (!password || loading) && styles.buttonDisabled]}
        onPress={handleSubmit}
        disabled={!password || loading}
        activeOpacity={0.8}
      >
        {loading ? (
          <ActivityIndicator color="#fff" />
        ) : (
          <Text style={styles.buttonText}>Giriş</Text>
        )}
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#04060d",
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: 32,
  },
  iconWrap: {
    width: 64,
    height: 64,
    borderRadius: 16,
    backgroundColor: "rgba(26,95,255,0.1)",
    borderWidth: 1,
    borderColor: "rgba(26,95,255,0.3)",
    alignItems: "center",
    justifyContent: "center",
    marginBottom: 20,
  },
  iconText: {
    fontSize: 28,
    color: "#1a5fff",
  },
  title: {
    color: "#fff",
    fontSize: 20,
    fontWeight: "700",
    marginBottom: 6,
    letterSpacing: 1,
  },
  subtitle: {
    color: "rgba(255,255,255,0.4)",
    fontSize: 13,
    marginBottom: 32,
    textAlign: "center",
  },
  input: {
    width: "100%",
    backgroundColor: "rgba(255,255,255,0.05)",
    borderWidth: 1,
    borderColor: "rgba(255,255,255,0.1)",
    borderRadius: 10,
    paddingHorizontal: 16,
    paddingVertical: 14,
    color: "#fff",
    fontSize: 15,
    marginBottom: 8,
  },
  error: {
    color: "#f87171",
    fontSize: 12,
    marginBottom: 8,
    textAlign: "center",
  },
  button: {
    width: "100%",
    backgroundColor: "#1a5fff",
    borderRadius: 10,
    paddingVertical: 15,
    alignItems: "center",
    marginTop: 8,
  },
  buttonDisabled: {
    opacity: 0.5,
  },
  buttonText: {
    color: "#fff",
    fontWeight: "700",
    fontSize: 15,
  },
});
