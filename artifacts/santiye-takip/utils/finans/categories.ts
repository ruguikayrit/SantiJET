export const EXPENSE_CATEGORIES = [
  { label: "Market", icon: "shopping-cart" },
  { label: "Yemek", icon: "coffee" },
  { label: "Ulaşım", icon: "map-pin" },
  { label: "Faturalar", icon: "zap" },
  { label: "Sağlık", icon: "heart" },
  { label: "Giyim", icon: "tag" },
  { label: "Eğlence", icon: "film" },
  { label: "Eğitim", icon: "book" },
  { label: "Spor", icon: "activity" },
  { label: "Diğer", icon: "more-horizontal" },
];

export const INCOME_CATEGORIES = [
  { label: "Maaş", icon: "briefcase" },
  { label: "Freelance", icon: "monitor" },
  { label: "Yatırım", icon: "trending-up" },
  { label: "Kira Geliri", icon: "home" },
  { label: "Hediye", icon: "gift" },
  { label: "Diğer", icon: "more-horizontal" },
];

const CATEGORY_ICON_MAP: Record<string, string> = {};
[...EXPENSE_CATEGORIES, ...INCOME_CATEGORIES].forEach((c) => {
  CATEGORY_ICON_MAP[c.label] = c.icon;
});

export const CATEGORY_ICONS = CATEGORY_ICON_MAP;

export function getCategoryIcon(category: string): string {
  return CATEGORY_ICON_MAP[category] ?? "circle";
}

export type PaymentMethod = "cash" | "card";

export const DEBT_CATEGORIES = [
  { label: "Banka Kredisi", icon: "dollar-sign" },
  { label: "Kira",          icon: "home" },
  { label: "Kişisel Borç",  icon: "user" },
  { label: "Fatura",        icon: "zap" },
  { label: "Taksit",        icon: "layers" },
  { label: "Diğer",         icon: "more-horizontal" },
];

export const DEBT_CATEGORY_COLORS: Record<string, string> = {
  "Banka Kredisi": "#3B82F6",
  "Kira":          "#F97316",
  "Kişisel Borç":  "#EC4899",
  "Fatura":        "#F59E0B",
  "Taksit":        "#8B5CF6",
  "Diğer":         "#64748B",
  "Kredi Kartı":   "#F97316",
  "Ek Hesap":      "#10B981",
};

export function getDebtCategoryColor(category: string, fallback = "#6366F1"): string {
  return DEBT_CATEGORY_COLORS[category] ?? fallback;
}

export function getDebtCategoryIcon(category: string): string {
  const found = DEBT_CATEGORIES.find((c) => c.label === category);
  return found?.icon ?? "credit-card";
}

export const BANKS = [
  "Ziraat Bankası",
  "İş Bankası",
  "Garanti BBVA",
  "Yapı Kredi",
  "Akbank",
  "QNB Finansbank",
  "DenizBank",
  "Halkbank",
  "VakıfBank",
  "TEB",
  "ING",
  "Enpara",
  "Diğer",
];
