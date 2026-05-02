import colors from "@/constants/finans/colors";
import { useTheme } from "@/context/finans/ThemeContext";

/**
 * Returns the design tokens for the current color scheme.
 *
 * Supports all palettes: light, dark, safir, altin, grafit, orman, mor, gunbatimi.
 * Named themes bypass the system light/dark resolution and use their own fixed palette.
 */
export function useColors() {
  const { scheme } = useTheme();

  const palette =
    scheme === "safir"    ? colors.safir    :
    scheme === "altin"    ? colors.altin    :
    scheme === "grafit"   ? colors.grafit   :
    scheme === "orman"    ? colors.orman    :
    scheme === "mor"      ? colors.mor      :
    scheme === "gunbatimi"? colors.gunbatimi:
    scheme === "banka"    ? colors.banka    :
    scheme === "okyanus"  ? colors.okyanus  :
    scheme === "platin"   ? colors.platin   :
    scheme === "borsa"    ? colors.borsa    :
    scheme === "gumus"    ? colors.gumus    :
    scheme === "dark"     ? colors.dark     :
                            colors.light;

  return { ...palette, radius: colors.radius };
}
