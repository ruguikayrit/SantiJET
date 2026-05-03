export interface ImalatPoz {
  code: string;
  category: string;
  name: string;
  unit: string;
  description?: string;
}

export const IMALAT_POZ_KATEGORILERI = [
  "Hafriyat ve Toprak",
  "Beton ve Demir",
  "Kalıp",
  "Duvar",
  "Sıva ve Şap",
  "Yalıtım",
  "Çatı",
  "Kaplama",
  "Boya",
  "Doğrama",
  "Sıhhi Tesisat",
  "Elektrik",
  "Cephe",
  "Çevre Düzenleme",
  "Diğer",
] as const;

export const DEFAULT_IMALAT_POZLARI: ImalatPoz[] = [
  // Hafriyat
  { code: "14.001", category: "Hafriyat ve Toprak", name: "El ile yumuşak toprak kazılması", unit: "m³", description: "El ile her derinlik ve genişlikte yumuşak toprakta kazı" },
  { code: "14.002", category: "Hafriyat ve Toprak", name: "Makine ile yumuşak toprak kazısı", unit: "m³", description: "Ekskavatör/lastik tekerlekli yükleyici ile her derinlikte kazı" },
  { code: "14.005", category: "Hafriyat ve Toprak", name: "Makine ile sert toprak kazısı", unit: "m³" },
  { code: "14.010", category: "Hafriyat ve Toprak", name: "Dolgu yapılması (kompaktör ile sıkıştırma)", unit: "m³" },

  // Beton ve Demir
  { code: "15.001/1A", category: "Beton ve Demir", name: "C16/20 hazır beton dökümü", unit: "m³", description: "Beton pompası dahil, donatısız" },
  { code: "15.001/2A", category: "Beton ve Demir", name: "C20/25 hazır beton dökümü", unit: "m³" },
  { code: "15.001/3A", category: "Beton ve Demir", name: "C25/30 hazır beton dökümü", unit: "m³" },
  { code: "15.001/4A", category: "Beton ve Demir", name: "C30/37 hazır beton dökümü", unit: "m³" },
  { code: "15.001/5A", category: "Beton ve Demir", name: "C35/45 hazır beton dökümü", unit: "m³" },
  { code: "23.014", category: "Beton ve Demir", name: "Nervürlü çelik hasırın yerine konulması", unit: "ton" },
  { code: "23.015", category: "Beton ve Demir", name: "Ø8-Ø12mm nervürlü inşaat çeliği", unit: "ton", description: "Kesilmesi, bükülmesi ve yerine konulması" },
  { code: "23.016", category: "Beton ve Demir", name: "Ø14-Ø32mm nervürlü inşaat çeliği", unit: "ton" },

  // Kalıp
  { code: "21.001", category: "Kalıp", name: "Plywood ile düz yüzeyli beton ve betonarme kalıbı", unit: "m²" },
  { code: "21.011", category: "Kalıp", name: "Tünel kalıp ile betonarme kalıbı", unit: "m²" },
  { code: "21.057", category: "Kalıp", name: "Çelik kalıp ile düz yüzey betonarme kalıbı", unit: "m²" },

  // Duvar
  { code: "16.054", category: "Duvar", name: "Yatay delikli tuğla (19x19x13.5) ile duvar", unit: "m³" },
  { code: "16.057/1A", category: "Duvar", name: "Gaz beton bloklarla duvar (G2/0.50, 25cm)", unit: "m²" },
  { code: "16.058", category: "Duvar", name: "Bims briket ile duvar", unit: "m²" },

  // Sıva ve Şap
  { code: "27.501", category: "Sıva ve Şap", name: "İç cephe çimento harçlı kaba sıva (2cm)", unit: "m²" },
  { code: "27.525", category: "Sıva ve Şap", name: "Saten alçı sıva (2-3mm)", unit: "m²" },
  { code: "27.581", category: "Sıva ve Şap", name: "Makine ile alçı sıva (1.5cm)", unit: "m²" },
  { code: "27.583", category: "Sıva ve Şap", name: "Çimento esaslı tesviye şapı (3-5cm)", unit: "m²" },

  // Yalıtım
  { code: "10.300.1051", category: "Yalıtım", name: "Polimer bitümlü membran su yalıtımı (3mm)", unit: "m²" },
  { code: "10.300.4421", category: "Yalıtım", name: "5cm XPS ısı yalıtım plakası", unit: "m²" },
  { code: "10.300.4521", category: "Yalıtım", name: "5cm taşyünü ısı yalıtım plakası", unit: "m²" },

  // Çatı
  { code: "27.701", category: "Çatı", name: "Kiremit ile çatı kaplaması", unit: "m²" },
  { code: "27.715", category: "Çatı", name: "OSB üzerine shingle kaplaması", unit: "m²" },

  // Kaplama
  { code: "26.005", category: "Kaplama", name: "Seramik yer döşemesi (30x30 - 60x60)", unit: "m²" },
  { code: "26.301", category: "Kaplama", name: "Granit/mermer döşeme kaplaması", unit: "m²" },
  { code: "26.401", category: "Kaplama", name: "Laminat parke döşemesi", unit: "m²" },

  // Boya
  { code: "25.116/1A", category: "Boya", name: "İç cephe plastik boya (2 kat)", unit: "m²" },
  { code: "25.116/2A", category: "Boya", name: "İç cephe saten boya (2 kat)", unit: "m²" },
  { code: "25.150", category: "Boya", name: "Dış cephe akrilik boya (2 kat)", unit: "m²" },

  // Doğrama
  { code: "24.151", category: "Doğrama", name: "PVC pencere doğraması (ısıcam dahil)", unit: "m²" },
  { code: "24.158", category: "Doğrama", name: "Alüminyum cephe doğraması", unit: "m²" },
  { code: "24.231", category: "Doğrama", name: "Ahşap iç kapı (kasa dahil)", unit: "ad" },
  { code: "24.245", category: "Doğrama", name: "Çelik kapı", unit: "ad" },

  // Sıhhi Tesisat
  { code: "071-101", category: "Sıhhi Tesisat", name: "PPR-C boru ve ek parça (Ø20)", unit: "m" },
  { code: "071-105", category: "Sıhhi Tesisat", name: "PPR-C boru ve ek parça (Ø25)", unit: "m" },
  { code: "072-201", category: "Sıhhi Tesisat", name: "PVC pis su borusu (Ø100)", unit: "m" },
  { code: "081-501", category: "Sıhhi Tesisat", name: "Klozet (rezervuar dahil) montajı", unit: "ad" },

  // Elektrik
  { code: "33.100", category: "Elektrik", name: "NYA kablo (3x2.5mm²) çekilmesi", unit: "m" },
  { code: "33.110", category: "Elektrik", name: "NYM kablo (3x1.5mm²) çekilmesi", unit: "m" },
  { code: "33.300", category: "Elektrik", name: "Sıva altı priz montajı", unit: "ad" },
  { code: "33.310", category: "Elektrik", name: "Sıva altı anahtar montajı", unit: "ad" },

  // Cephe
  { code: "10.300.4451", category: "Cephe", name: "Mantolama (5cm EPS + sıva + boya)", unit: "m²" },

  // Çevre Düzenleme
  { code: "18.461", category: "Çevre Düzenleme", name: "Bordür taşı yerleştirilmesi", unit: "m" },
  { code: "18.465", category: "Çevre Düzenleme", name: "Beton kilitli parke taşı döşenmesi", unit: "m²" },
];
