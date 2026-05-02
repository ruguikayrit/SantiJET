const colors = {
  light: {
    text: "#0f1923",
    tint: "#00C896",

    background: "#F5F7FA",
    foreground: "#0f1923",

    card: "#FFFFFF",
    cardForeground: "#0f1923",

    primary: "#00C896",
    primaryForeground: "#FFFFFF",

    secondary: "#EEF7F4",
    secondaryForeground: "#00A97E",

    muted: "#F0F2F5",
    mutedForeground: "#8A94A6",

    accent: "#E8F9F4",
    accentForeground: "#00A97E",

    destructive: "#FF4D6D",
    destructiveForeground: "#FFFFFF",

    income: "#00C896",
    incomeBg: "#E8F9F4",
    expense: "#FF4D6D",
    expenseBg: "#FFECF0",

    border: "#E8ECF1",
    input: "#E8ECF1",

    navy: "#0B1E33",
    navyLight: "#1A3550",
  },

  dark: {
    text: "#F5F7FA",
    tint: "#00C896",

    background: "#0A1420",
    foreground: "#F5F7FA",

    card: "#152233",
    cardForeground: "#F5F7FA",

    primary: "#00D8A4",
    primaryForeground: "#06141C",

    secondary: "#16302A",
    secondaryForeground: "#5BE5BE",

    muted: "#1E2D40",
    mutedForeground: "#8595AB",

    accent: "#163E36",
    accentForeground: "#5BE5BE",

    destructive: "#FF5F7C",
    destructiveForeground: "#FFFFFF",

    income: "#00D8A4",
    incomeBg: "#10302A",
    expense: "#FF5F7C",
    expenseBg: "#3A1A24",

    border: "#243349",
    input: "#243349",

    navy: "#06121F",
    navyLight: "#152233",
  },

  /** Safir — Lacivert · Turkuaz · Beyaz */
  safir: {
    text: "#0B1E33",
    tint: "#0099B8",

    background: "#F2F7FB",
    foreground: "#0B1E33",

    card: "#FFFFFF",
    cardForeground: "#0B1E33",

    primary: "#0099B8",
    primaryForeground: "#FFFFFF",

    secondary: "#DDF2F7",
    secondaryForeground: "#006C84",

    muted: "#E4EEF5",
    mutedForeground: "#6A8599",

    accent: "#C8E8F2",
    accentForeground: "#005F77",

    destructive: "#FF4D6D",
    destructiveForeground: "#FFFFFF",

    income: "#0099B8",
    incomeBg: "#D5EFF6",
    expense: "#FF4D6D",
    expenseBg: "#FFECF0",

    border: "#C5DDE9",
    input: "#C5DDE9",

    navy: "#0B1E33",
    navyLight: "#163248",
  },

  /** Altın — Koyu lacivert · Mat altın */
  altin: {
    text: "#F0E8D0",
    tint: "#D4A017",

    background: "#0C1926",
    foreground: "#F0E8D0",

    card: "#14253A",
    cardForeground: "#F0E8D0",

    primary: "#D4A017",
    primaryForeground: "#0C1926",

    secondary: "#1E3048",
    secondaryForeground: "#E6C052",

    muted: "#182030",
    mutedForeground: "#8A9BAD",

    accent: "#2A3E58",
    accentForeground: "#E6C052",

    destructive: "#FF5F7C",
    destructiveForeground: "#FFFFFF",

    income: "#D4A017",
    incomeBg: "#1E2A10",
    expense: "#FF5F7C",
    expenseBg: "#2A1020",

    border: "#243548",
    input: "#243548",

    navy: "#060E18",
    navyLight: "#0C1926",
  },

  /** Grafit — Terminal siyahı · Neon yeşil */
  grafit: {
    text: "#E2E8E4",
    tint: "#00E87A",

    background: "#0A0D0A",
    foreground: "#E2E8E4",

    card: "#131613",
    cardForeground: "#E2E8E4",

    primary: "#00E87A",
    primaryForeground: "#0A0D0A",

    secondary: "#1A201A",
    secondaryForeground: "#00E87A",

    muted: "#1A1E1A",
    mutedForeground: "#6A7A6A",

    accent: "#0E1E14",
    accentForeground: "#00E87A",

    destructive: "#FF4466",
    destructiveForeground: "#FFFFFF",

    income: "#00E87A",
    incomeBg: "#0A2010",
    expense: "#FF4466",
    expenseBg: "#200A10",

    border: "#202820",
    input: "#202820",

    navy: "#050705",
    navyLight: "#131613",
  },

  /** Orman — Derin yeşil · Krem */
  orman: {
    text: "#E4F0E8",
    tint: "#6EE4A0",

    background: "#0C1E14",
    foreground: "#E4F0E8",

    card: "#142A1C",
    cardForeground: "#E4F0E8",

    primary: "#6EE4A0",
    primaryForeground: "#0C1E14",

    secondary: "#1A3024",
    secondaryForeground: "#A8F0C4",

    muted: "#182418",
    mutedForeground: "#7A9E84",

    accent: "#1E3828",
    accentForeground: "#A8F0C4",

    destructive: "#FF7070",
    destructiveForeground: "#FFFFFF",

    income: "#6EE4A0",
    incomeBg: "#0E2A18",
    expense: "#FF7070",
    expenseBg: "#2A1010",

    border: "#1E3228",
    input: "#1E3228",

    navy: "#060E08",
    navyLight: "#0C1E14",
  },

  /** Mor — Koyu indigo · Lila (Fintech) */
  mor: {
    text: "#EAE8FF",
    tint: "#8B5CF6",

    background: "#0C0B1E",
    foreground: "#EAE8FF",

    card: "#16142E",
    cardForeground: "#EAE8FF",

    primary: "#8B5CF6",
    primaryForeground: "#FFFFFF",

    secondary: "#201C40",
    secondaryForeground: "#B89EFF",

    muted: "#181630",
    mutedForeground: "#8480A8",

    accent: "#271E50",
    accentForeground: "#B89EFF",

    destructive: "#FF4D6D",
    destructiveForeground: "#FFFFFF",

    income: "#8B5CF6",
    incomeBg: "#1A1440",
    expense: "#FF4D6D",
    expenseBg: "#2A1020",

    border: "#242050",
    input: "#242050",

    navy: "#07060F",
    navyLight: "#0C0B1E",
  },

  /** Gün Batımı — Krem · Lacivert & Turuncu */
  gunbatimi: {
    text: "#1A1A2E",
    tint: "#E07B39",

    background: "#FFF8F2",
    foreground: "#1A1A2E",

    card: "#FFFFFF",
    cardForeground: "#1A1A2E",

    primary: "#E07B39",
    primaryForeground: "#FFFFFF",

    secondary: "#FFEEDE",
    secondaryForeground: "#A85520",

    muted: "#F5ECE4",
    mutedForeground: "#9A7A6A",

    accent: "#FFE4CC",
    accentForeground: "#A85520",

    destructive: "#D63C5A",
    destructiveForeground: "#FFFFFF",

    income: "#E07B39",
    incomeBg: "#FFF0E0",
    expense: "#D63C5A",
    expenseBg: "#FFECF0",

    border: "#EDE0D4",
    input: "#EDE0D4",

    navy: "#1A1A2E",
    navyLight: "#252545",
  },

  /** Banka — Klasik bankacılık · Beyaz & Kraliyet Mavisi */
  banka: {
    text: "#0A1D3A",
    tint: "#1855C8",

    background: "#EDF4FC",
    foreground: "#0A1D3A",

    card: "#FFFFFF",
    cardForeground: "#0A1D3A",

    primary: "#1855C8",
    primaryForeground: "#FFFFFF",

    secondary: "#D0E2FA",
    secondaryForeground: "#0C308A",

    muted: "#E0EAF8",
    mutedForeground: "#5E74A2",

    accent: "#BAD4F6",
    accentForeground: "#0C308A",

    destructive: "#DC2A4A",
    destructiveForeground: "#FFFFFF",

    income: "#1855C8",
    incomeBg: "#D4E5FF",
    expense: "#DC2A4A",
    expenseBg: "#FCEAED",

    border: "#C4D8F2",
    input: "#C4D8F2",

    navy: "#0A1D3A",
    navyLight: "#142E5A",
  },

  /** Okyanus — Derin koyu lacivert & parlak cyan */
  okyanus: {
    text: "#B0CCD8",
    tint: "#00C4E0",

    background: "#030D1C",
    foreground: "#B0CCD8",

    card: "#081828",
    cardForeground: "#B0CCD8",

    primary: "#00C4E0",
    primaryForeground: "#020A14",

    secondary: "#082235",
    secondaryForeground: "#40D8F0",

    muted: "#081828",
    mutedForeground: "#456880",

    accent: "#0A2840",
    accentForeground: "#40D8F0",

    destructive: "#FF4060",
    destructiveForeground: "#FFFFFF",

    income: "#00C4E0",
    incomeBg: "#062030",
    expense: "#FF4060",
    expenseBg: "#280A18",

    border: "#102840",
    input: "#102840",

    navy: "#020810",
    navyLight: "#081828",
  },

  /** Platin — Hafif gri · Derin lacivert (İsviçre bankacılığı) */
  platin: {
    text: "#152032",
    tint: "#284882",

    background: "#F2F5F9",
    foreground: "#152032",

    card: "#FFFFFF",
    cardForeground: "#152032",

    primary: "#284882",
    primaryForeground: "#FFFFFF",

    secondary: "#D5DFF4",
    secondaryForeground: "#1C336A",

    muted: "#E5EAF4",
    mutedForeground: "#586882",

    accent: "#BFD0EC",
    accentForeground: "#1C336A",

    destructive: "#CC2040",
    destructiveForeground: "#FFFFFF",

    income: "#284882",
    incomeBg: "#D0DCFF",
    expense: "#CC2040",
    expenseBg: "#FCEAED",

    border: "#C5D0E2",
    input: "#C5D0E2",

    navy: "#152032",
    navyLight: "#22324C",
  },

  /** Borsa — Trading terminali · Siyah & Elektrik Mavi */
  borsa: {
    text: "#A5BFCE",
    tint: "#0088FF",

    background: "#05090F",
    foreground: "#A5BFCE",

    card: "#0A1520",
    cardForeground: "#A5BFCE",

    primary: "#0088FF",
    primaryForeground: "#020A14",

    secondary: "#0A2035",
    secondaryForeground: "#55AAFF",

    muted: "#0A1828",
    mutedForeground: "#486070",

    accent: "#0C2445",
    accentForeground: "#55AAFF",

    destructive: "#FF3060",
    destructiveForeground: "#FFFFFF",

    income: "#0088FF",
    incomeBg: "#082040",
    expense: "#FF3060",
    expenseBg: "#280A18",

    border: "#142A40",
    input: "#142A40",

    navy: "#030810",
    navyLight: "#0A1520",
  },

  /** Gümüş — Antrasit · Çelik mavi (Kurumsal finans) */
  gumus: {
    text: "#C8D2DC",
    tint: "#88B0C8",

    background: "#141A22",
    foreground: "#C8D2DC",

    card: "#1C2430",
    cardForeground: "#C8D2DC",

    primary: "#88B0C8",
    primaryForeground: "#080E14",

    secondary: "#223040",
    secondaryForeground: "#9AB8CC",

    muted: "#1A2230",
    mutedForeground: "#586878",

    accent: "#283848",
    accentForeground: "#9AB8CC",

    destructive: "#E05070",
    destructiveForeground: "#FFFFFF",

    income: "#88B0C8",
    incomeBg: "#182838",
    expense: "#E05070",
    expenseBg: "#281020",

    border: "#263444",
    input: "#263444",

    navy: "#0A1018",
    navyLight: "#1C2430",
  },

  radius: 14,
};

export default colors;
