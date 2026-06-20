import type { ComponentProps } from "react";
import type { Feather } from "@expo/vector-icons";

import { buildPozKategoriFiltreleri, PozAnaliz } from "@/constants/pozAnalizleri";

export type BfaModuleIcon = ComponentProps<typeof Feather>["name"];

export interface BfaModuleDef {
  num: string;
  label: string;
  icon: BfaModuleIcon;
  color: string;
  infoSuffix: string;
  route: { pathname: string; params?: Record<string, string> };
  count: (analizler: PozAnaliz[]) => number;
}

export const BFA_MODULES: BfaModuleDef[] = [
  {
    num: "01",
    label: "İNŞAAT BİRİM FİYAT ANALİZLERİ",
    icon: "layers",
    color: "#d97706",
    infoSuffix: "Analiz",
    route: { pathname: "/imalat-pozlari", params: { modul: "insaat" } },
    count: (analizler) => analizler.length,
  },
  {
    num: "02",
    label: "ÖZEL BİRİM FİYAT ANALİZLERİ",
    icon: "edit-3",
    color: "#0891b2",
    infoSuffix: "Analiz",
    route: { pathname: "/imalat-pozlari", params: { modul: "ozel" } },
    count: (analizler) => analizler.filter((a) => a.kaynakTip !== "sistem").length,
  },
  {
    num: "03",
    label: "ANALİZ KATALOĞU",
    icon: "book-open",
    color: "#16a34a",
    infoSuffix: "Kategori",
    route: { pathname: "/analiz-katalogu" },
    count: (analizler) => buildPozKategoriFiltreleri(analizler).length,
  },
];
