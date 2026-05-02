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
  DEFAULT_LANGUAGE,
  LANGUAGES,
  LanguageCode,
  translate,
} from "@/constants/translations";

const STORAGE_KEY = "santiye_language_v1";

interface I18nContextValue {
  language: LanguageCode;
  languages: typeof LANGUAGES;
  setLanguage: (code: LanguageCode) => void;
  t: (key: string) => string;
  isRTL: boolean;
  loaded: boolean;
}

const I18nContext = createContext<I18nContextValue | undefined>(undefined);

export function I18nProvider({ children }: { children: React.ReactNode }) {
  const [language, setLanguageState] = useState<LanguageCode>(DEFAULT_LANGUAGE);
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    AsyncStorage.getItem(STORAGE_KEY)
      .then((stored) => {
        if (stored && LANGUAGES.some((l) => l.code === stored)) {
          setLanguageState(stored as LanguageCode);
        }
      })
      .finally(() => setLoaded(true));
  }, []);

  const setLanguage = useCallback((code: LanguageCode) => {
    if (!LANGUAGES.some((l) => l.code === code)) return;
    setLanguageState(code);
    AsyncStorage.setItem(STORAGE_KEY, code).catch(() => {});
  }, []);

  const t = useCallback((key: string) => translate(language, key), [language]);

  const value = useMemo<I18nContextValue>(
    () => ({
      language,
      languages: LANGUAGES,
      setLanguage,
      t,
      isRTL: language === "ar",
      loaded,
    }),
    [language, setLanguage, t, loaded]
  );

  // Kayıtlı dil yüklenene kadar render etme — açılış sırasında dil flicker'ını önler
  if (!loaded) return null;

  return <I18nContext.Provider value={value}>{children}</I18nContext.Provider>;
}

export function useI18n(): I18nContextValue {
  const ctx = useContext(I18nContext);
  if (!ctx) {
    throw new Error("useI18n must be used inside an I18nProvider");
  }
  return ctx;
}
