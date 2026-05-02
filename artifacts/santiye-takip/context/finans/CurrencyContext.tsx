import AsyncStorage from "@react-native-async-storage/async-storage";
import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useRef,
  useState,
} from "react";

const STORAGE_KEY_CURRENCY = "display_currency";
const STORAGE_KEY_RATES    = "exchange_rates_cache";
const STORAGE_KEY_TS       = "exchange_rates_timestamp";
const CACHE_DURATION_MS    = 30 * 60 * 1000;

export const CURRENCY_SYMBOLS: Record<string, string> = {
  TRY: "₺", USD: "$",  EUR: "€",  GBP: "£",  CHF: "Fr",
  JPY: "¥",  CAD: "C$", AUD: "A$", CNY: "¥",  SAR: "﷼",
  AED: "د.إ", NOK: "kr", SEK: "kr", DKK: "kr", RUB: "₽",
  PLN: "zł", HUF: "Ft", CZK: "Kč", HKD: "HK$", NZD: "NZ$",
  SGD: "S$", MXN: "$",  BRL: "R$", ZAR: "R",  INR: "₹",
  KRW: "₩",  TWD: "NT$", THB: "฿", MYR: "RM", IDR: "Rp",
  PHP: "₱",  VND: "₫",  EGP: "E£", PKR: "₨", NGN: "₦",
  KES: "KSh", MAD: "MAD", QAR: "﷼", KWD: "KD", BHD: "BD",
};

const NO_FRACTION_CURRENCIES = new Set(["JPY", "KRW", "VND", "IDR", "HUF"]);

export function formatCurrencyCode(amount: number, code: string): string {
  if (code === "TRY") {
    return (
      new Intl.NumberFormat("tr-TR", {
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
      }).format(amount) + " ₺"
    );
  }
  const fd = NO_FRACTION_CURRENCIES.has(code) ? 0 : 2;
  try {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: code,
      minimumFractionDigits: fd,
      maximumFractionDigits: fd,
    }).format(amount);
  } catch {
    const symbol = CURRENCY_SYMBOLS[code] ?? code;
    return `${symbol}${amount.toFixed(fd)}`;
  }
}

export interface CurrencyContextValue {
  displayCurrency: string;
  rates: Record<string, number>;
  isLoading: boolean;
  lastUpdated: Date | null;
  convert: (tryAmount: number) => number;
  formatAmount: (tryAmount: number) => string;
  setCurrency: (code: string) => Promise<void>;
  refreshRates: () => Promise<void>;
}

const CurrencyContext = createContext<CurrencyContextValue>({
  displayCurrency: "TRY",
  rates: {},
  isLoading: false,
  lastUpdated: null,
  convert: (n) => n,
  formatAmount: (n) =>
    new Intl.NumberFormat("tr-TR", {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }).format(n) + " ₺",
  setCurrency: async () => {},
  refreshRates: async () => {},
});

async function fetchWithTimeout(url: string, ms = 8000): Promise<Response> {
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), ms);
  try {
    return await fetch(url, { signal: ctrl.signal });
  } finally {
    clearTimeout(timer);
  }
}

async function fetchRates(): Promise<Record<string, number>> {
  const apis = [
    "https://api.exchangerate-api.com/v4/latest/TRY",
    "https://open.er-api.com/v6/latest/TRY",
    "https://api.frankfurter.dev/v1/latest?from=TRY",
  ];
  for (const url of apis) {
    try {
      const res = await fetchWithTimeout(url, 8000);
      if (!res.ok) {
        console.warn("[CurrencyContext] fetch not ok:", url, res.status);
        continue;
      }
      const data = await res.json();
      const rates: Record<string, number> = data.rates ?? data.conversion_rates ?? {};
      if (Object.keys(rates).length > 10) {
        console.log("[CurrencyContext] loaded rates from", url, "count:", Object.keys(rates).length);
        return rates;
      }
    } catch (e) {
      console.warn("[CurrencyContext] fetch error:", url, e);
      continue;
    }
  }
  console.warn("[CurrencyContext] all rate APIs failed");
  return {};
}

export function CurrencyProvider({ children }: { children: React.ReactNode }) {
  const [displayCurrency, setDisplayCurrencyState] = useState("TRY");
  const [rates, setRates]                           = useState<Record<string, number>>({});
  const [isLoading, setIsLoading]                   = useState(false);
  const [lastUpdated, setLastUpdated]               = useState<Date | null>(null);
  const fetchingRef                                 = useRef(false);

  const loadAndFetch = useCallback(async (force = false) => {
    if (fetchingRef.current) return;
    try {
      fetchingRef.current = true;

      const [savedCurrency, cachedRatesRaw, cachedTsRaw] = await Promise.all([
        AsyncStorage.getItem(STORAGE_KEY_CURRENCY),
        AsyncStorage.getItem(STORAGE_KEY_RATES),
        AsyncStorage.getItem(STORAGE_KEY_TS),
      ]);

      if (savedCurrency) setDisplayCurrencyState(savedCurrency);

      const cachedTs    = cachedTsRaw ? Number(cachedTsRaw) : 0;
      const cachedRates = cachedRatesRaw ? (JSON.parse(cachedRatesRaw) as Record<string, number>) : null;
      const cacheHasData = cachedRates && Object.keys(cachedRates).length > 10;
      const cacheValid   = !force && cacheHasData && Date.now() - cachedTs < CACHE_DURATION_MS;

      if (cachedRates && cacheValid) {
        setRates(cachedRates);
        setLastUpdated(new Date(cachedTs));
        return;
      }

      setIsLoading(true);
      const fresh = await fetchRates();
      if (Object.keys(fresh).length > 0) {
        const now = Date.now();
        setRates(fresh);
        setLastUpdated(new Date(now));
        await AsyncStorage.multiSet([
          [STORAGE_KEY_RATES, JSON.stringify(fresh)],
          [STORAGE_KEY_TS, String(now)],
        ]);
      } else if (cachedRates && Object.keys(cachedRates).length > 0) {
        setRates(cachedRates);
        if (cachedTs) setLastUpdated(new Date(cachedTs));
      }
    } catch (e) {
      console.warn("[CurrencyContext] load error:", e);
    } finally {
      fetchingRef.current = false;
      setIsLoading(false);
    }
  }, []);

  useEffect(() => { loadAndFetch(); }, [loadAndFetch]);

  const setCurrency = useCallback(async (code: string) => {
    setDisplayCurrencyState(code);
    await AsyncStorage.setItem(STORAGE_KEY_CURRENCY, code);
  }, []);

  const refreshRates = useCallback(() => loadAndFetch(true), [loadAndFetch]);

  const convert = useCallback(
    (tryAmount: number): number => {
      if (displayCurrency === "TRY") return tryAmount;
      const rate = rates[displayCurrency];
      if (!rate) return tryAmount;
      return tryAmount * rate;
    },
    [displayCurrency, rates]
  );

  const formatAmount = useCallback(
    (tryAmount: number): string => {
      return formatCurrencyCode(convert(tryAmount), displayCurrency);
    },
    [convert, displayCurrency]
  );

  return (
    <CurrencyContext.Provider
      value={{ displayCurrency, rates, isLoading, lastUpdated, convert, formatAmount, setCurrency, refreshRates }}
    >
      {children}
    </CurrencyContext.Provider>
  );
}

export function useCurrency(): CurrencyContextValue {
  return useContext(CurrencyContext);
}
