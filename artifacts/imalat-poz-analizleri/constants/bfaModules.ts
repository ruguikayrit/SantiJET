import type { ComponentProps } from "react";
import type { Feather } from "@expo/vector-icons";

import { PozAnaliz } from "@/constants/pozAnalizleri";

export type BfaDiscipline = "insaat" | "mekanik" | "elektrik";

export type BfaModuleKey = BfaDiscipline | "favoriler";

export type BfaModuleIcon = ComponentProps<typeof Feather>["name"];

export const BFA_DISCIPLINES: BfaDiscipline[] = ["insaat", "mekanik", "elektrik"];

export const MODULE_LABEL_SUFFIX = " BİRİM FİYAT ANALİZLERİ";
export const MODULE_SUBTITLE_LABEL = "BİRİM FİYAT ANALİZLERİ";

export function stripModuleLabelSuffix(label: string): string {
  if (label.endsWith(MODULE_LABEL_SUFFIX)) {
    return label.slice(0, -MODULE_LABEL_SUFFIX.length);
  }
  return label;
}

export function parseModuleTileLabel(label: string): {
  title: string;
  subtitle: string | null;
} {
  if (label.endsWith(MODULE_LABEL_SUFFIX)) {
    return {
      title: label.slice(0, -MODULE_LABEL_SUFFIX.length),
      subtitle: MODULE_SUBTITLE_LABEL,
    };
  }
  return { title: label, subtitle: null };
}

export interface BfaCatalogStats {
  insaat: PozAnaliz[];
  mekanik: PozAnaliz[];
  elektrik: PozAnaliz[];
  all: PozAnaliz[];
  favoriler: PozAnaliz[];
}

export interface BfaModuleDef {
  num: string;
  label: string;
  screenTitle: string;
  icon: BfaModuleIcon;
  color: string;
  infoSuffix: string;
  modul: BfaModuleKey;
  route: { pathname: string; params?: Record<string, string> };
  count: (stats: BfaCatalogStats) => number;
  emptyHint?: string;
}

export const BFA_MODULES: BfaModuleDef[] = [
  {
    num: "01",
    label: "İNŞAAT BİRİM FİYAT ANALİZLERİ",
    screenTitle: "İnşaat Birim Fiyat Analizleri",
    icon: "layers",
    color: "#d97706",
    infoSuffix: "Analiz",
    modul: "insaat",
    route: { pathname: "/imalat-pozlari", params: { modul: "insaat" } },
    count: (stats) => stats.insaat.length,
  },
  {
    num: "02",
    label: "MEKANİK TESİSAT BİRİM FİYAT ANALİZLERİ",
    screenTitle: "Mekanik Tesisat Birim Fiyat Analizleri",
    icon: "settings",
    color: "#0891b2",
    infoSuffix: "Analiz",
    modul: "mekanik",
    route: { pathname: "/imalat-pozlari", params: { modul: "mekanik" } },
    count: (stats) => stats.mekanik.length,
  },
  {
    num: "03",
    label: "ELEKTRİK TESİSAT BİRİM FİYAT ANALİZLERİ",
    screenTitle: "Elektrik Tesisat Birim Fiyat Analizleri",
    icon: "zap",
    color: "#16a34a",
    infoSuffix: "Analiz",
    modul: "elektrik",
    route: { pathname: "/imalat-pozlari", params: { modul: "elektrik" } },
    count: (stats) => stats.elektrik.length,
  },
  {
    num: "04",
    label: "FAVORİLER",
    screenTitle: "Favoriler",
    icon: "star",
    color: "#eab308",
    infoSuffix: "Analiz",
    modul: "favoriler",
    route: { pathname: "/imalat-pozlari", params: { modul: "favoriler" } },
    count: (stats) => stats.favoriler.length,
    emptyHint: "Detay ekranından yıldız ile analizleri favorilere ekleyebilirsiniz.",
  },
];

export function isBfaModuleKey(value: string): value is BfaModuleKey {
  return (
    value === "insaat" ||
    value === "mekanik" ||
    value === "elektrik" ||
    value === "favoriler"
  );
}

export function isBfaDiscipline(value: string): value is BfaDiscipline {
  return value === "insaat" || value === "mekanik" || value === "elektrik";
}

export function getBfaModuleDef(modul: BfaModuleKey): BfaModuleDef {
  return BFA_MODULES.find((m) => m.modul === modul) ?? BFA_MODULES[0];
}

export function getBfaScreenTitle(modul: BfaModuleKey, catFilter?: string | null): string {
  if (catFilter) return catFilter;
  return getBfaModuleDef(modul).screenTitle;
}

export function resolveAnalizDiscipline(analiz: Pick<PozAnaliz, "discipline">): BfaDiscipline {
  return analiz.discipline ?? "insaat";
}
