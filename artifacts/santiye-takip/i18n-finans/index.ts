import * as Localization from "expo-localization";
import i18n from "i18next";
import { initReactI18next } from "react-i18next";

import ar from "./locales/ar.json";
import de from "./locales/de.json";
import en from "./locales/en.json";
import es from "./locales/es.json";
import fr from "./locales/fr.json";
import hi from "./locales/hi.json";
import id from "./locales/id.json";
import it from "./locales/it.json";
import ja from "./locales/ja.json";
import ko from "./locales/ko.json";
import nl from "./locales/nl.json";
import pl from "./locales/pl.json";
import pt from "./locales/pt.json";
import ru from "./locales/ru.json";
import sv from "./locales/sv.json";
import tr from "./locales/tr.json";
import uk from "./locales/uk.json";
import zh from "./locales/zh.json";

export const SUPPORTED_LANGUAGES = [
  { code: "tr", label: "Türkçe", nativeLabel: "Türkçe", rtl: false },
  { code: "en", label: "English", nativeLabel: "English", rtl: false },
  { code: "ar", label: "Arapça", nativeLabel: "العربية", rtl: true },
  { code: "zh", label: "Çince", nativeLabel: "中文", rtl: false },
  { code: "de", label: "Almanca", nativeLabel: "Deutsch", rtl: false },
  { code: "es", label: "İspanyolca", nativeLabel: "Español", rtl: false },
  { code: "fr", label: "Fransızca", nativeLabel: "Français", rtl: false },
  { code: "hi", label: "Hintçe", nativeLabel: "हिन्दी", rtl: false },
  { code: "id", label: "Endonezce", nativeLabel: "Bahasa Indonesia", rtl: false },
  { code: "it", label: "İtalyanca", nativeLabel: "Italiano", rtl: false },
  { code: "ja", label: "Japonca", nativeLabel: "日本語", rtl: false },
  { code: "ko", label: "Korece", nativeLabel: "한국어", rtl: false },
  { code: "nl", label: "Hollandaca", nativeLabel: "Nederlands", rtl: false },
  { code: "pl", label: "Lehçe", nativeLabel: "Polski", rtl: false },
  { code: "pt", label: "Portekizce", nativeLabel: "Português", rtl: false },
  { code: "ru", label: "Rusça", nativeLabel: "Русский", rtl: false },
  { code: "sv", label: "İsveççe", nativeLabel: "Svenska", rtl: false },
  { code: "uk", label: "Ukraynaca", nativeLabel: "Українська", rtl: false },
] as const;

export type LanguageCode = (typeof SUPPORTED_LANGUAGES)[number]["code"];

const SUPPORTED_CODES = SUPPORTED_LANGUAGES.map((l) => l.code);

function detectLanguage(): string {
  const locales = Localization.getLocales();
  for (const locale of locales) {
    const lang = locale.languageCode ?? "";
    if (SUPPORTED_CODES.includes(lang as LanguageCode)) {
      return lang;
    }
  }
  return "tr";
}

i18n.use(initReactI18next).init({
  resources: {
    tr: { translation: tr },
    en: { translation: en },
    ar: { translation: ar },
    de: { translation: de },
    es: { translation: es },
    fr: { translation: fr },
    hi: { translation: hi },
    id: { translation: id },
    it: { translation: it },
    ja: { translation: ja },
    ko: { translation: ko },
    nl: { translation: nl },
    pl: { translation: pl },
    pt: { translation: pt },
    ru: { translation: ru },
    sv: { translation: sv },
    uk: { translation: uk },
    zh: { translation: zh },
  },
  lng: detectLanguage(),
  fallbackLng: "tr",
  interpolation: {
    escapeValue: false,
  },
  compatibilityJSON: "v4",
});

export default i18n;
