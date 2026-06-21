export interface ThemeColors {
  text: string;
  tint: string;

  background: string;
  foreground: string;

  card: string;
  cardForeground: string;

  primary: string;
  primaryForeground: string;

  secondary: string;
  secondaryForeground: string;

  muted: string;
  mutedForeground: string;

  accent: string;
  accentForeground: string;

  destructive: string;
  destructiveForeground: string;

  success: string;
  successForeground: string;

  warning: string;
  warningForeground: string;

  border: string;
  input: string;

  orange: string;
  navy: string;
  darkNavy: string;
}

export interface ThemeDefinition {
  id: string;
  name: string;
  description: string;
  isDark: boolean;
  preview: { bg: string; primary: string; secondary: string };
  colors: ThemeColors;
}

const klasik: ThemeColors = {
  text: "#1a1a2e",
  tint: "#e85d04",
  background: "#f5f5f5",
  foreground: "#1a1a2e",
  card: "#ffffff",
  cardForeground: "#1a1a2e",
  primary: "#e85d04",
  primaryForeground: "#ffffff",
  secondary: "#16213e",
  secondaryForeground: "#ffffff",
  muted: "#eaeaea",
  mutedForeground: "#6b7280",
  accent: "#fde68a",
  accentForeground: "#92400e",
  destructive: "#dc2626",
  destructiveForeground: "#ffffff",
  success: "#16a34a",
  successForeground: "#ffffff",
  warning: "#d97706",
  warningForeground: "#ffffff",
  border: "#e5e7eb",
  input: "#e5e7eb",
  orange: "#e85d04",
  navy: "#16213e",
  darkNavy: "#0f3460",
};

const turuncuEnerji: ThemeColors = {
  text: "#1a1a2e",
  tint: "#ff6a00",
  background: "#fff8f1",
  foreground: "#1a1a2e",
  card: "#ffffff",
  cardForeground: "#1a1a2e",
  primary: "#ff6a00",
  primaryForeground: "#ffffff",
  secondary: "#16213e",
  secondaryForeground: "#ffffff",
  muted: "#ffe8d6",
  mutedForeground: "#7a4a1f",
  accent: "#ffd6a8",
  accentForeground: "#7a3000",
  destructive: "#dc2626",
  destructiveForeground: "#ffffff",
  success: "#16a34a",
  successForeground: "#ffffff",
  warning: "#b45309",
  warningForeground: "#ffffff",
  border: "#ffd6a8",
  input: "#ffd6a8",
  orange: "#ff6a00",
  navy: "#16213e",
  darkNavy: "#0f3460",
};

const beyazMinimal: ThemeColors = {
  text: "#0b1020",
  tint: "#e85d04",
  background: "#ffffff",
  foreground: "#0b1020",
  card: "#ffffff",
  cardForeground: "#0b1020",
  primary: "#16213e",
  primaryForeground: "#ffffff",
  secondary: "#0b1020",
  secondaryForeground: "#ffffff",
  muted: "#f7f7fa",
  mutedForeground: "#64748b",
  accent: "#e85d04",
  accentForeground: "#ffffff",
  destructive: "#dc2626",
  destructiveForeground: "#ffffff",
  success: "#15803d",
  successForeground: "#ffffff",
  warning: "#d97706",
  warningForeground: "#ffffff",
  border: "#e6e8ee",
  input: "#e6e8ee",
  orange: "#e85d04",
  navy: "#16213e",
  darkNavy: "#0b1020",
};

const gece: ThemeColors = {
  text: "#e8ecf5",
  tint: "#ff8a3c",
  background: "#0b1428",
  foreground: "#e8ecf5",
  card: "#142042",
  cardForeground: "#e8ecf5",
  primary: "#ff8a3c",
  primaryForeground: "#0b1428",
  secondary: "#1e2d56",
  secondaryForeground: "#e8ecf5",
  muted: "#1a2547",
  mutedForeground: "#9aa6c2",
  accent: "#ffb27a",
  accentForeground: "#0b1428",
  destructive: "#ef4444",
  destructiveForeground: "#ffffff",
  success: "#22c55e",
  successForeground: "#ffffff",
  warning: "#f59e0b",
  warningForeground: "#0b1428",
  border: "#22305a",
  input: "#22305a",
  orange: "#ff8a3c",
  navy: "#16213e",
  darkNavy: "#0b1428",
};

const kremSicak: ThemeColors = {
  text: "#1a1a2e",
  tint: "#d2691e",
  background: "#fbf6ee",
  foreground: "#1a1a2e",
  card: "#ffffff",
  cardForeground: "#1a1a2e",
  primary: "#d2691e",
  primaryForeground: "#ffffff",
  secondary: "#16213e",
  secondaryForeground: "#ffffff",
  muted: "#f1e8d4",
  mutedForeground: "#6b5d3f",
  accent: "#f7d8a8",
  accentForeground: "#7a3000",
  destructive: "#b91c1c",
  destructiveForeground: "#ffffff",
  success: "#15803d",
  successForeground: "#ffffff",
  warning: "#b45309",
  warningForeground: "#ffffff",
  border: "#ead9b8",
  input: "#ead9b8",
  orange: "#d2691e",
  navy: "#16213e",
  darkNavy: "#0f3460",
};

const steel: ThemeColors = {
  text: "#e2e8f0",
  tint: "#f59e0b",
  background: "#0f172a",
  foreground: "#e2e8f0",
  card: "#1e293b",
  cardForeground: "#e2e8f0",
  primary: "#f59e0b",
  primaryForeground: "#0f172a",
  secondary: "#1e293b",
  secondaryForeground: "#e2e8f0",
  muted: "#1e293b",
  mutedForeground: "#94a3b8",
  accent: "#0ea5e9",
  accentForeground: "#0f172a",
  destructive: "#ef4444",
  destructiveForeground: "#ffffff",
  success: "#10b981",
  successForeground: "#ffffff",
  warning: "#f59e0b",
  warningForeground: "#0f172a",
  border: "#334155",
  input: "#334155",
  orange: "#f59e0b",
  navy: "#0f172a",
  darkNavy: "#020617",
};

export const THEMES: ThemeDefinition[] = [
  {
    id: "klasik",
    name: "Klasik",
    description: "Açık gri zemin, turuncu vurgu",
    isDark: false,
    preview: { bg: "#f5f5f5", primary: "#e85d04", secondary: "#16213e" },
    colors: klasik,
  },
  {
    id: "turuncu-enerji",
    name: "Turuncu Enerji",
    description: "Sıcak turuncu zemin, dinamik",
    isDark: false,
    preview: { bg: "#fff8f1", primary: "#ff6a00", secondary: "#16213e" },
    colors: turuncuEnerji,
  },
  {
    id: "beyaz-minimal",
    name: "Beyaz Minimal",
    description: "Temiz beyaz, ince çizgiler",
    isDark: false,
    preview: { bg: "#ffffff", primary: "#16213e", secondary: "#e85d04" },
    colors: beyazMinimal,
  },
  {
    id: "gece",
    name: "Gece",
    description: "Koyu lacivert, gözleri yormaz",
    isDark: true,
    preview: { bg: "#0b1428", primary: "#ff8a3c", secondary: "#16213e" },
    colors: gece,
  },
  {
    id: "krem-sicak",
    name: "Krem & Sıcak",
    description: "Yumuşak krem zemin",
    isDark: false,
    preview: { bg: "#fbf6ee", primary: "#d2691e", secondary: "#16213e" },
    colors: kremSicak,
  },
  {
    id: "steel",
    name: "Steel & Concrete",
    description: "Koyu lacivert, renkli kart şeritleri",
    isDark: true,
    preview: { bg: "#0f172a", primary: "#f59e0b", secondary: "#1e293b" },
    colors: steel,
  },
];

export const DEFAULT_THEME_ID = "klasik";

export function getTheme(id: string | null | undefined): ThemeDefinition {
  return THEMES.find((t) => t.id === id) ?? THEMES[0];
}

const colors = {
  light: klasik,
  radius: 10,
};

export default colors;
