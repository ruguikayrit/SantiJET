/**
 * Fiyat çekme yardımcıları.
 * - Kripto   : CoinGecko (CORS-friendly, ücretsiz)
 * - Borsa    : Yahoo Finance v8 chart (THYAO.IS formatı)
 * - Döviz    : Frankfurter API (CORS-friendly, ücretsiz)
 * - Altın    : metals.live (USD/oz) + Frankfurter (USD→TRY)
 */

const COINGECKO_IDS: Record<string, string> = {
  BTC:    "bitcoin",
  ETH:    "ethereum",
  BNB:    "binancecoin",
  SOL:    "solana",
  XRP:    "ripple",
  USDT:   "tether",
  USDC:   "usd-coin",
  ADA:    "cardano",
  AVAX:   "avalanche-2",
  DOGE:   "dogecoin",
  SHIB:   "shiba-inu",
  TRX:    "tron",
  DOT:    "polkadot",
  LINK:   "chainlink",
  MATIC:  "matic-network",
  LTC:    "litecoin",
  BCH:    "bitcoin-cash",
  UNI:    "uniswap",
  ATOM:   "cosmos",
  XLM:    "stellar",
  ETC:    "ethereum-classic",
  XMR:    "monero",
  ALGO:   "algorand",
  VET:    "vechain",
  FTM:    "fantom",
  NEAR:   "near",
  HBAR:   "hedera-hashgraph",
  GRT:    "the-graph",
  AAVE:   "aave",
  ICP:    "internet-computer",
  FIL:    "filecoin",
  SAND:   "the-sandbox",
  MANA:   "decentraland",
  AXS:    "axie-infinity",
  EGLD:   "elrond-erd-2",
  THETA:  "theta-token",
  EOS:    "eos",
  XTZ:    "tezos",
  FLOW:   "flow",
  ARB:    "arbitrum",
  OP:     "optimism",
  APT:    "aptos",
  SUI:    "sui",
  INJ:    "injective-protocol",
  STX:    "blockstack",
  IMX:    "immutable-x",
  MKR:    "maker",
  COMP:   "compound-governance-token",
  CRV:    "curve-dao-token",
  SUSHI:  "sushi",
  YFI:    "yearn-finance",
  "1INCH":"1inch",
  BAL:    "balancer",
  CAKE:   "pancakeswap-token",
  SNX:    "havven",
  DASH:   "dash",
  ZEC:    "zcash",
  BAT:    "basic-attention-token",
  ZIL:    "zilliqa",
  QTUM:   "qtum",
  NEO:    "neo",
  ENJ:    "enjincoin",
  CHZ:    "chiliz",
  IOTA:   "iota",
  ROSE:   "oasis-network",
  KSM:    "kusama",
  KAVA:   "kava",
  ZEN:    "zencash",
  WAVES:  "waves",
  ONT:    "ontology",
  ICX:    "icon",
  ZRX:    "0x",
  STORJ:  "storj",
  RVN:    "ravencoin",
  ANKR:   "ankr",
  CELO:   "celo",
  RSR:    "reserve-rights-token",
  LRC:    "loopring",
  OCEAN:  "ocean-protocol",
  FET:    "fetch-ai",
  AGIX:   "singularitynet",
  RNDR:   "render-token",
  WLD:    "worldcoin-wld",
  TON:    "the-open-network",
  PEPE:   "pepe",
  FLOKI:  "floki",
  BONK:   "bonk",
  WIF:    "dogwifcoin",
  JUP:    "jupiter-ag",
  JTO:    "jito-governance-token",
  PYTH:   "pyth-network",
  TIA:    "celestia",
  SEI:    "sei-network",
  BLUR:   "blur",
  GMT:    "stepn",
  APE:    "apecoin",
  LDO:    "lido-dao",
  RPL:    "rocket-pool",
  PENDLE: "pendle",
  GMX:    "gmx",
  DYDX:   "dydx",
  RUNE:   "thorchain",
  OSMO:   "osmosis",
  MINA:   "mina-protocol",
  CFX:    "conflux-token",
  ONDO:   "ondo-finance",
  ENA:    "ethena",
  POL:    "matic-network",
  TRUMP:  "official-trump",
  PNUT:   "peanut-the-squirrel",
  POPCAT: "popcat",
};

function extractSymbol(cryptoName: string): string | null {
  const m = cryptoName.match(/\(([A-Z0-9]+)\)$/);
  return m ? m[1] : null;
}

function extractBistTicker(stockName: string): string | null {
  const m = stockName.match(/^([A-Z0-9&.\-]+)\s*–/);
  return m ? m[1].trim() : null;
}

async function fetchWithTimeout(url: string, ms = 7000): Promise<Response> {
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), ms);
  try {
    return await fetch(url, { signal: ctrl.signal });
  } finally {
    clearTimeout(timer);
  }
}

/** Kripto: isim "Bitcoin (BTC)" formatında beklenr → TRY cinsinden birim fiyat */
export async function fetchCryptoPriceTRY(name: string): Promise<number | null> {
  const symbol = extractSymbol(name);
  if (!symbol) return null;
  const cgId = COINGECKO_IDS[symbol.toUpperCase()];
  if (!cgId) return null;
  try {
    const res = await fetchWithTimeout(
      `https://api.coingecko.com/api/v3/simple/price?ids=${cgId}&vs_currencies=try`
    );
    if (!res.ok) return null;
    const data = await res.json();
    return data?.[cgId]?.try ?? null;
  } catch {
    return null;
  }
}

/** BIST hisse: isim "THYAO – Türk Hava Yolları" formatında → TRY hisse fiyatı */
export async function fetchBistPriceTRY(name: string): Promise<number | null> {
  const ticker = extractBistTicker(name);
  if (!ticker) return null;
  try {
    const res = await fetchWithTimeout(
      `https://query1.finance.yahoo.com/v8/finance/chart/${ticker}.IS?interval=1d&range=1d`
    );
    if (!res.ok) return null;
    const data = await res.json();
    const price = data?.chart?.result?.[0]?.meta?.regularMarketPrice;
    return typeof price === "number" ? price : null;
  } catch {
    return null;
  }
}

/** Döviz: kod "USD", "EUR" vs → 1 birim = X TRY */
export async function fetchForexRateTRY(currencyCode: string): Promise<number | null> {
  const code = currencyCode.trim().toUpperCase();
  if (code === "TRY") return 1;
  try {
    const res = await fetchWithTimeout(
      `https://api.frankfurter.dev/v1/latest?from=${code}&to=TRY`
    );
    if (!res.ok) return null;
    const data = await res.json();
    return data?.rates?.TRY ?? null;
  } catch {
    return null;
  }
}

/** Altın: CoinGecko PAXG (1 troy ons = 31.1035 gram) → TRY/gram veya TRY/ons
 *  PAXG (Pax Gold) gerçek altın fiyatını takip eder; 1 PAXG = 1 troy ons altın.
 *  CoinGecko, CORS-friendly ve API key gerektirmez.
 */
export async function fetchGoldPriceTRY(unit: "gram" | "oz"): Promise<number | null> {
  try {
    const res = await fetchWithTimeout(
      "https://api.coingecko.com/api/v3/simple/price?ids=pax-gold&vs_currencies=try"
    );
    if (!res.ok) return null;
    const data = await res.json();
    const tryPerOz: number = data?.["pax-gold"]?.try;
    if (!tryPerOz) return null;
    return unit === "gram" ? tryPerOz / 31.1035 : tryPerOz;
  } catch {
    return null;
  }
}

/** Genel hisse senedi: Yahoo Finance + gerekirse TRY dönüşümü.
 *  name: "AAPL – Apple" gibi format → ticker çıkarılır.
 *  exchangeSuffix: ".IS" | ".DE" | ".L" | ".PA" | ".T" | "" (US)
 *  currency: "TRY" | "USD" | "EUR" | "GBP" | "JPY" …
 *  priceDivisor: FTSE gibi pence cinsinden gelen fiyatlar için 100
 */
export async function fetchStockPriceTRY(
  name: string,
  exchangeSuffix: string,
  currency: string,
  priceDivisor = 1
): Promise<number | null> {
  const ticker = extractBistTicker(name);
  if (!ticker) return null;
  const symbol = exchangeSuffix ? `${ticker}${exchangeSuffix}` : ticker;
  try {
    const res = await fetchWithTimeout(
      `https://query1.finance.yahoo.com/v8/finance/chart/${symbol}?interval=1d&range=1d`
    );
    if (!res.ok) return null;
    const data = await res.json();
    const rawPrice: number = data?.chart?.result?.[0]?.meta?.regularMarketPrice;
    if (typeof rawPrice !== "number") return null;
    const localPrice = rawPrice / priceDivisor;
    if (currency === "TRY") return localPrice;
    const tryRate = await fetchForexRateTRY(currency);
    if (!tryRate) return null;
    return localPrice * tryRate;
  } catch {
    return null;
  }
}

/** Tek dispatch fonksiyonu — assetType + assetName'e göre doğru API'yi çağırır */
export async function fetchUnitPrice(
  assetType: string,
  assetName: string
): Promise<number | null> {
  switch (assetType) {
    case "kripto": return fetchCryptoPriceTRY(assetName);
    case "borsa":  return fetchBistPriceTRY(assetName);
    case "doviz": {
      const code = assetName.split(/\s|–|-/)[0].trim().toUpperCase();
      return fetchForexRateTRY(code);
    }
    case "altin": {
      const isOz = assetName.toLowerCase().includes("ons");
      return fetchGoldPriceTRY(isOz ? "oz" : "gram");
    }
    default: return null;
  }
}
