import colors from "@/constants/colors";
import { useTheme } from "@/context/ThemeContext";

/**
 * Returns the design tokens for the active user-selected theme.
 *
 * The theme is read from ThemeContext (which loads the saved id from
 * AsyncStorage). The returned object contains all color tokens for the
 * active palette plus scheme-independent values like `radius`.
 *
 * Falls back to the default ("klasik") palette before the stored
 * preference has loaded.
 */
export function useColors() {
  const { theme } = useTheme();
  return { ...theme.colors, radius: colors.radius };
}
