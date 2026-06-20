import AsyncStorage from "@react-native-async-storage/async-storage";
import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";

import {
  DEFAULT_THEME_ID,
  THEMES,
  ThemeDefinition,
  getTheme,
} from "@/constants/colors";

const STORAGE_KEY = "poz_analiz_theme_v1";

interface ThemeContextValue {
  themeId: string;
  theme: ThemeDefinition;
  themes: ThemeDefinition[];
  setThemeId: (id: string) => void;
  loaded: boolean;
}

const ThemeContext = createContext<ThemeContextValue | undefined>(undefined);

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [themeId, setThemeIdState] = useState<string>(DEFAULT_THEME_ID);
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    AsyncStorage.getItem(STORAGE_KEY)
      .then((stored) => {
        if (stored && THEMES.some((t) => t.id === stored)) {
          setThemeIdState(stored);
        }
      })
      .finally(() => setLoaded(true));
  }, []);

  const setThemeId = useCallback((id: string) => {
    if (!THEMES.some((t) => t.id === id)) return;
    setThemeIdState(id);
    AsyncStorage.setItem(STORAGE_KEY, id).catch(() => {});
  }, []);

  const value = useMemo<ThemeContextValue>(
    () => ({
      themeId,
      theme: getTheme(themeId),
      themes: THEMES,
      setThemeId,
      loaded,
    }),
    [themeId, setThemeId, loaded]
  );

  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
}

export function useTheme(): ThemeContextValue {
  const ctx = useContext(ThemeContext);
  if (!ctx) throw new Error("useTheme must be used inside ThemeProvider");
  return ctx;
}
