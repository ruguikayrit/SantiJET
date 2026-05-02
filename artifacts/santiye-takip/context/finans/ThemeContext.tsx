import AsyncStorage from "@react-native-async-storage/async-storage";
import React, {
  createContext,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";
import { useColorScheme } from "react-native";

export type ThemeMode =
  | "system"
  | "light"
  | "dark"
  | "safir"
  | "altin"
  | "grafit"
  | "orman"
  | "mor"
  | "gunbatimi"
  | "banka"
  | "okyanus"
  | "platin"
  | "borsa"
  | "gumus";

export type ResolvedScheme =
  | "light"
  | "dark"
  | "safir"
  | "altin"
  | "grafit"
  | "orman"
  | "mor"
  | "gunbatimi"
  | "banka"
  | "okyanus"
  | "platin"
  | "borsa"
  | "gumus";

const NAMED_THEMES: ThemeMode[] = [
  "safir",
  "altin",
  "grafit",
  "orman",
  "mor",
  "gunbatimi",
  "banka",
  "okyanus",
  "platin",
  "borsa",
  "gumus",
];

interface ThemeContextValue {
  mode: ThemeMode;
  scheme: ResolvedScheme;
  setMode: (mode: ThemeMode) => void;
}

const STORAGE_KEY = "@theme_mode_v2";

const VALID_MODES: ThemeMode[] = [
  "system",
  "light",
  "dark",
  "safir",
  "altin",
  "grafit",
  "orman",
  "mor",
  "gunbatimi",
  "banka",
  "okyanus",
  "platin",
  "borsa",
  "gumus",
];

const ThemeContext = createContext<ThemeContextValue | undefined>(undefined);

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const systemScheme = useColorScheme();
  const [mode, setModeState] = useState<ThemeMode>("system");
  const [hydrated, setHydrated] = useState(false);

  useEffect(() => {
    (async () => {
      try {
        const v = await AsyncStorage.getItem(STORAGE_KEY);
        if (v && VALID_MODES.includes(v as ThemeMode)) {
          setModeState(v as ThemeMode);
        }
      } catch {}
      setHydrated(true);
    })();
  }, []);

  const setMode = (m: ThemeMode) => {
    setModeState(m);
    AsyncStorage.setItem(STORAGE_KEY, m).catch(() => {});
  };

  const scheme: ResolvedScheme = NAMED_THEMES.includes(mode)
    ? (mode as ResolvedScheme)
    : mode === "system"
    ? systemScheme === "dark"
      ? "dark"
      : "light"
    : (mode as ResolvedScheme);

  const value = useMemo(
    () => ({ mode, scheme, setMode }),
    [mode, scheme]
  );

  if (!hydrated) return null;

  return (
    <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>
  );
}

export function useTheme() {
  const ctx = useContext(ThemeContext);
  if (!ctx) {
    return {
      mode: "system" as ThemeMode,
      scheme: "light" as ResolvedScheme,
      setMode: () => {},
    };
  }
  return ctx;
}
