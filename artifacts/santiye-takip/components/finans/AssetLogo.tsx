import { Feather } from "@expo/vector-icons";
import React, { useState } from "react";
import { Image, StyleSheet, Text, View } from "react-native";

import { AssetType } from "@/context/finans/BudgetContext";

const FLAG: Record<string, string> = {
  USD: "🇺🇸", EUR: "🇪🇺", GBP: "🇬🇧", CHF: "🇨🇭", JPY: "🇯🇵",
  AED: "🇦🇪", SAR: "🇸🇦", KWD: "🇰🇼", AUD: "🇦🇺", CAD: "🇨🇦",
  NOK: "🇳🇴", SEK: "🇸🇪", DKK: "🇩🇰", CNY: "🇨🇳", RUB: "🇷🇺",
  BHD: "🇧🇭", QAR: "🇶🇦", SGD: "🇸🇬", HKD: "🇭🇰", NZD: "🇳🇿",
  INR: "🇮🇳", PKR: "🇵🇰", BRL: "🇧🇷", ZAR: "🇿🇦",
};

const CRYPTO_CDN = "https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/128/color";

const PALETTE = [
  "#E74C3C", "#E67E22", "#F39C12", "#27AE60", "#1ABC9C",
  "#2980B9", "#8E44AD", "#E91E63", "#00BCD4", "#FF5722",
  "#4CAF50", "#9C27B0", "#3F51B5", "#009688", "#FF9800",
];
function hashColor(s: string): string {
  let h = 0;
  for (let i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) & 0xffff;
  return PALETTE[h % PALETTE.length];
}

function parseName(assetType: AssetType, name: string) {
  if (assetType === "kripto") {
    const m = name.match(/\(([A-Z0-9]{2,10})\)$/);
    return { symbol: m ? m[1] : name.slice(0, 6).toUpperCase(), ticker: "" };
  }
  if (assetType === "borsa") {
    const ticker = name.split(/\s*[–\-]\s*/)[0].trim().slice(0, 5).toUpperCase();
    return { symbol: "", ticker };
  }
  if (assetType === "doviz") {
    const code = name.split(/\s*[–\-]\s*/)[0].trim().slice(0, 3).toUpperCase();
    return { symbol: "", ticker: code };
  }
  return { symbol: "", ticker: "" };
}

interface Props {
  assetType: AssetType;
  name: string;
  size?: number;
  borderRadius?: number;
}

export default function AssetLogo({ assetType, name, size = 36, borderRadius = 10 }: Props) {
  const [imgErr, setImgErr] = useState(false);
  const { symbol, ticker } = parseName(assetType, name);
  const boxStyle = { width: size, height: size, borderRadius };

  if (assetType === "kripto") {
    const url = `${CRYPTO_CDN}/${symbol.toLowerCase()}.png`;
    if (!imgErr) {
      return (
        <Image
          source={{ uri: url }}
          style={[boxStyle, styles.img]}
          onError={() => setImgErr(true)}
          resizeMode="contain"
        />
      );
    }
    const color = hashColor(symbol);
    const fs = Math.round(size * 0.32);
    return (
      <View style={[boxStyle, styles.box, { backgroundColor: color + "22" }]}>
        <Text style={[styles.sym, { color, fontSize: fs }]}>
          {symbol.slice(0, 4)}
        </Text>
      </View>
    );
  }

  if (assetType === "borsa") {
    const color = hashColor(ticker);
    const fs = ticker.length <= 3 ? Math.round(size * 0.32) : Math.round(size * 0.26);
    return (
      <View style={[boxStyle, styles.box, { backgroundColor: color + "1E" }]}>
        <View style={[styles.tickerBar, { backgroundColor: color, height: 3, borderRadius: 1.5, width: size * 0.65, marginBottom: 3 }]} />
        <Text style={[styles.sym, { color, fontSize: fs, letterSpacing: -0.5 }]}>
          {ticker.slice(0, 4)}
        </Text>
      </View>
    );
  }

  if (assetType === "doviz") {
    const code = ticker.slice(0, 3);
    const flag = FLAG[code];
    const fs = Math.round(size * 0.52);
    if (flag) {
      return (
        <View style={[boxStyle, styles.box, { backgroundColor: "#00000010" }]}>
          <Text style={{ fontSize: fs, lineHeight: size * 0.95 }}>{flag}</Text>
        </View>
      );
    }
    const color = hashColor(code);
    return (
      <View style={[boxStyle, styles.box, { backgroundColor: color + "22" }]}>
        <Text style={[styles.sym, { color, fontSize: Math.round(size * 0.28) }]}>{code}</Text>
      </View>
    );
  }

  if (assetType === "altin") {
    const goldBg = "#EAB30820";
    const goldFg = "#CA8A04";
    return (
      <View style={[boxStyle, styles.box, { backgroundColor: goldBg }]}>
        <Feather name="award" size={Math.round(size * 0.48)} color={goldFg} />
        <Text style={[styles.auLabel, { color: goldFg, fontSize: Math.round(size * 0.22) }]}>XAU</Text>
      </View>
    );
  }

  return null;
}

const styles = StyleSheet.create({
  img: {
    backgroundColor: "#FFFFFF08",
  },
  box: {
    alignItems: "center",
    justifyContent: "center",
    overflow: "hidden",
  },
  sym: {
    fontWeight: "800",
    letterSpacing: -0.5,
    includeFontPadding: false,
  },
  tickerBar: {},
  auLabel: {
    fontWeight: "700",
    letterSpacing: 0.3,
    marginTop: 1,
    includeFontPadding: false,
  },
});
