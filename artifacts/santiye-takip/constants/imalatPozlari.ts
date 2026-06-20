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
  "Mekanik Tesisat",
  "Asansör",
  "Cephe",
  "Çevre Düzenleme",
  "Yıkım ve Söküm",
  "Çelik Yapı",
  "Altyapı",
  "Peyzaj",
  "Diğer",
] as const;

const HAFRIYAT: ImalatPoz[] = [
  { code: "Y.14.001/01", category: "Hafriyat ve Toprak", name: "El ile yumuşak ve sert toprak kazısı", unit: "m³", description: "Her derinlik ve genişlikte el ile kazı yapılması.\nKazılan malzemenin kazı kenarına atılması veya 4 m mesafeye kadar taşınması dahildir.\nKazı yan duvarlarının iksası hariçtir." },
  { code: "Y.14.001/02", category: "Hafriyat ve Toprak", name: "El ile yumuşak küskülük kazı", unit: "m³" },
  { code: "Y.14.001/03", category: "Hafriyat ve Toprak", name: "El ile sert küskülük kazı", unit: "m³" },
  { code: "Y.14.001/04", category: "Hafriyat ve Toprak", name: "El ile yumuşak kaya kazısı", unit: "m³" },
  { code: "Y.14.001/05", category: "Hafriyat ve Toprak", name: "El ile sert kaya kazısı", unit: "m³" },
  { code: "Y.14.002/01", category: "Hafriyat ve Toprak", name: "Makine ile yumuşak toprak kazısı", unit: "m³", description: "Ekskavatör veya yükleyici ile her derinlik ve genişlikte kazı.\nKazılan malzemenin yükleme yapılarak en fazla 25 m mesafeye taşınması dahildir." },
  { code: "Y.14.002/02", category: "Hafriyat ve Toprak", name: "Makine ile sert toprak kazısı", unit: "m³" },
  { code: "Y.14.002/03", category: "Hafriyat ve Toprak", name: "Makine ile yumuşak küskülük kazı", unit: "m³" },
  { code: "Y.14.002/04", category: "Hafriyat ve Toprak", name: "Makine ile sert küskülük kazı", unit: "m³" },
  { code: "Y.14.002/05", category: "Hafriyat ve Toprak", name: "Makine ile yumuşak kaya kazısı", unit: "m³" },
  { code: "Y.14.002/06", category: "Hafriyat ve Toprak", name: "Makine ile sert kaya kazısı", unit: "m³", description: "Patlayıcı veya hidrolik kırıcı ile sert kaya formasyonunda kazı.\nKırılan malzemenin yüklenip taşınması dahildir." },
  { code: "Y.14.002/07", category: "Hafriyat ve Toprak", name: "Makine ile patlayıcı kullanılarak kaya kazısı", unit: "m³" },
  { code: "Y.14.003/01", category: "Hafriyat ve Toprak", name: "Temel için makine ile dar derin kazı (yumuşak)", unit: "m³" },
  { code: "Y.14.003/02", category: "Hafriyat ve Toprak", name: "Temel için makine ile dar derin kazı (sert)", unit: "m³" },
  { code: "Y.14.004/01", category: "Hafriyat ve Toprak", name: "Hendek kazısı (kanal/altyapı)", unit: "m³" },
  { code: "Y.14.005/01", category: "Hafriyat ve Toprak", name: "Sulu zeminde kazı (su atımı dahil)", unit: "m³" },
  { code: "Y.14.010/01", category: "Hafriyat ve Toprak", name: "Dolgu yapılması ve sıkıştırılması", unit: "m³", description: "Uygun malzeme ile 30 cm tabakalar halinde dolgu serilmesi.\nHer tabakanın silindir veya kompaktör ile sıkıştırılması.\nProktor değerinin %95'ine ulaşılması esastır." },
  { code: "Y.14.010/02", category: "Hafriyat ve Toprak", name: "Stabilize malzeme ile dolgu", unit: "m³" },
  { code: "Y.14.010/03", category: "Hafriyat ve Toprak", name: "Mıcır (0/63) ile dolgu", unit: "m³" },
  { code: "Y.14.010/04", category: "Hafriyat ve Toprak", name: "Çakıl ile drenaj dolgusu", unit: "m³" },
  { code: "Y.14.010/05", category: "Hafriyat ve Toprak", name: "Sıkıştırılmış kum yatak", unit: "m³" },
  { code: "Y.14.020/01", category: "Hafriyat ve Toprak", name: "Hafriyat naklı (0-1 km)", unit: "m³·km" },
  { code: "Y.14.020/02", category: "Hafriyat ve Toprak", name: "Hafriyat naklı (1-5 km)", unit: "m³·km" },
  { code: "Y.14.020/03", category: "Hafriyat ve Toprak", name: "Hafriyat naklı (5-10 km)", unit: "m³·km" },
  { code: "Y.14.020/04", category: "Hafriyat ve Toprak", name: "Hafriyat naklı (10 km üstü)", unit: "m³·km" },
  { code: "Y.14.030/01", category: "Hafriyat ve Toprak", name: "Bohça (palplanş) iksa", unit: "m²" },
  { code: "Y.14.030/02", category: "Hafriyat ve Toprak", name: "Ahşap iksa", unit: "m²" },
  { code: "Y.14.030/03", category: "Hafriyat ve Toprak", name: "Çelik iksa (H profil + sürgülü)", unit: "m²" },
  { code: "Y.14.030/04", category: "Hafriyat ve Toprak", name: "Berliner duvar (dikme + ahşap)", unit: "m²" },
  { code: "Y.14.040/01", category: "Hafriyat ve Toprak", name: "Forekazık iksa (Ø60 cm)", unit: "m" },
  { code: "Y.14.040/02", category: "Hafriyat ve Toprak", name: "Forekazık iksa (Ø80 cm)", unit: "m" },
  { code: "Y.14.040/03", category: "Hafriyat ve Toprak", name: "Forekazık iksa (Ø100 cm)", unit: "m" },
  { code: "Y.14.040/04", category: "Hafriyat ve Toprak", name: "Mini kazık (Ø30-40 cm)", unit: "m" },
  { code: "Y.14.050/01", category: "Hafriyat ve Toprak", name: "Geosentetik donatılı duvar", unit: "m²" },
  { code: "Y.14.050/02", category: "Hafriyat ve Toprak", name: "Gabion duvar", unit: "m³" },
  { code: "Y.14.060/01", category: "Hafriyat ve Toprak", name: "Ankrajlı kayma duvarı (zemin çivisi)", unit: "ad" },
  { code: "Y.14.060/02", category: "Hafriyat ve Toprak", name: "Püskürtme beton (shotcrete) iksa", unit: "m²" },
  { code: "Y.14.070/01", category: "Hafriyat ve Toprak", name: "Yüzey suyu drenaj kanalı", unit: "m" },
  { code: "Y.14.070/02", category: "Hafriyat ve Toprak", name: "Drenaj borusu (HDPE Ø100, koruge)", unit: "m" },
  { code: "Y.14.070/03", category: "Hafriyat ve Toprak", name: "Drenaj borusu (HDPE Ø160, koruge)", unit: "m" },
];

const C_SINIFLARI = [
  ["Y.16.050/01", "C8/10 grobeton", "1A"],
  ["Y.16.050/02", "C12/15 hazır beton", "2A"],
  ["Y.16.050/03", "C16/20 hazır beton", "3A"],
  ["Y.16.050/04", "C20/25 hazır beton", "4A"],
  ["Y.16.050/05", "C25/30 hazır beton", "5A"],
  ["Y.16.050/06", "C30/37 hazır beton", "6A"],
  ["Y.16.050/07", "C35/45 hazır beton", "7A"],
  ["Y.16.050/08", "C40/50 hazır beton", "8A"],
  ["Y.16.050/09", "C45/55 hazır beton", "9A"],
  ["Y.16.050/10", "C50/60 hazır beton", "10A"],
];

const BETON: ImalatPoz[] = [
  ...C_SINIFLARI.map(([code, name]) => ({
    code,
    category: "Beton ve Demir",
    name: `${name} dökümü (pompa dahil)`,
    unit: "m³",
    description: "Transmikser ile sahaya getirilen hazır betonun beton pompası ile yerine dökülmesi.\nVibratör ile sıkıştırılması ve kür işlemi dahildir.",
  })),
  { code: "Y.16.051/01", category: "Beton ve Demir", name: "Su geçirimsiz (hidrofuge) beton ek bedeli", unit: "m³" },
  { code: "Y.16.051/02", category: "Beton ve Demir", name: "Çelik liflik beton ek bedeli", unit: "m³" },
  { code: "Y.16.051/03", category: "Beton ve Demir", name: "Polipropilen liflik beton ek bedeli", unit: "m³" },
  { code: "Y.16.051/04", category: "Beton ve Demir", name: "Renkli beton ek bedeli", unit: "m³" },
  { code: "Y.16.051/05", category: "Beton ve Demir", name: "Self-compacting (SCC) beton ek bedeli", unit: "m³" },
  { code: "Y.16.051/06", category: "Beton ve Demir", name: "Beyaz çimentolu beton ek bedeli", unit: "m³" },
  { code: "Y.16.052/01", category: "Beton ve Demir", name: "Püskürtme beton (shotcrete) C25/30", unit: "m³" },
  { code: "Y.16.053/01", category: "Beton ve Demir", name: "Beton kür uygulaması (kür ilacı)", unit: "m²" },
  { code: "Y.16.054/01", category: "Beton ve Demir", name: "Tesviye betonu (5-10 cm)", unit: "m²" },
  { code: "Y.16.055/01", category: "Beton ve Demir", name: "Lazer mastar ile zemin tesviyesi", unit: "m²" },
  { code: "Y.16.056/01", category: "Beton ve Demir", name: "Helikopter perdah", unit: "m²" },
  { code: "Y.16.060/01", category: "Beton ve Demir", name: "Hazır prekast kiriş yerleştirme", unit: "ad" },
  { code: "Y.16.060/02", category: "Beton ve Demir", name: "Hazır prekast kolon yerleştirme", unit: "ad" },
  { code: "Y.16.060/03", category: "Beton ve Demir", name: "Hazır prekast döşeme paneli (HC)", unit: "m²" },
  { code: "Y.16.060/04", category: "Beton ve Demir", name: "Prekast cephe paneli", unit: "m²" },
];

const DEMIR_CAPLAR = [
  ["Y.23.014/01", "Çelik hasır Q188", "ton"],
  ["Y.23.014/02", "Çelik hasır Q221", "ton"],
  ["Y.23.014/03", "Çelik hasır Q257", "ton"],
  ["Y.23.014/04", "Çelik hasır Q295", "ton"],
  ["Y.23.014/05", "Çelik hasır Q317", "ton"],
  ["Y.23.015/01", "Nervürlü inşaat çeliği Ø8", "ton"],
  ["Y.23.015/02", "Nervürlü inşaat çeliği Ø10", "ton"],
  ["Y.23.015/03", "Nervürlü inşaat çeliği Ø12", "ton"],
  ["Y.23.015/04", "Nervürlü inşaat çeliği Ø14", "ton"],
  ["Y.23.015/05", "Nervürlü inşaat çeliği Ø16", "ton"],
  ["Y.23.015/06", "Nervürlü inşaat çeliği Ø18", "ton"],
  ["Y.23.015/07", "Nervürlü inşaat çeliği Ø20", "ton"],
  ["Y.23.015/08", "Nervürlü inşaat çeliği Ø22", "ton"],
  ["Y.23.015/09", "Nervürlü inşaat çeliği Ø25", "ton"],
  ["Y.23.015/10", "Nervürlü inşaat çeliği Ø28", "ton"],
  ["Y.23.015/11", "Nervürlü inşaat çeliği Ø32", "ton"],
];

const DEMIR: ImalatPoz[] = [
  ...DEMIR_CAPLAR.map(([code, name, unit]) => ({
    code,
    category: "Beton ve Demir",
    name: `${name} (kesim+bükme+montaj)`,
    unit: unit as string,
    description: "Donatının kesilmesi, bükülmesi, projedeki yerine konulup bağ teli ile bağlanması.\nFire ve bağ teli dahildir.",
  })),
  { code: "Y.23.016/01", category: "Beton ve Demir", name: "Düz inşaat demiri", unit: "ton" },
  { code: "Y.23.020/01", category: "Beton ve Demir", name: "Hazır kolon donatı kafesi", unit: "ton" },
  { code: "Y.23.020/02", category: "Beton ve Demir", name: "Hazır kiriş donatı kafesi", unit: "ton" },
  { code: "Y.23.020/03", category: "Beton ve Demir", name: "Perde donatı paneli", unit: "ton" },
  { code: "Y.23.030/01", category: "Beton ve Demir", name: "Ankraj çubuğu Ø12 (paslanmaz)", unit: "ad" },
  { code: "Y.23.030/02", category: "Beton ve Demir", name: "Ankraj çubuğu Ø16 (paslanmaz)", unit: "ad" },
  { code: "Y.23.030/03", category: "Beton ve Demir", name: "Ankraj çubuğu Ø20 (paslanmaz)", unit: "ad" },
  { code: "Y.23.040/01", category: "Beton ve Demir", name: "Epoksi ankraj uygulaması Ø12", unit: "ad" },
  { code: "Y.23.040/02", category: "Beton ve Demir", name: "Epoksi ankraj uygulaması Ø16", unit: "ad" },
  { code: "Y.23.040/03", category: "Beton ve Demir", name: "Epoksi ankraj uygulaması Ø20", unit: "ad" },
  { code: "Y.23.050/01", category: "Beton ve Demir", name: "Mevcut betona kimyasal ankraj", unit: "ad" },
  { code: "Y.23.060/01", category: "Beton ve Demir", name: "Karot alımı (beton numunesi)", unit: "ad" },
];

const KALIP: ImalatPoz[] = [
  { code: "Y.21.001/01", category: "Kalıp", name: "Plywood ile düz yüzeyli temel kalıbı", unit: "m²", description: "18 mm su kontrası plywood ile düz yüzeyli kalıp imalatı.\nIskelet ahşap kereste ile, destek ve payandalar dahildir.\nSökülüp tekrar kurulması dahil." },
  { code: "Y.21.001/02", category: "Kalıp", name: "Plywood ile düz yüzeyli döşeme kalıbı", unit: "m²" },
  { code: "Y.21.001/03", category: "Kalıp", name: "Plywood ile düz yüzeyli kolon kalıbı", unit: "m²" },
  { code: "Y.21.001/04", category: "Kalıp", name: "Plywood ile düz yüzeyli kiriş kalıbı", unit: "m²" },
  { code: "Y.21.001/05", category: "Kalıp", name: "Plywood ile düz yüzeyli perde kalıbı", unit: "m²" },
  { code: "Y.21.002/01", category: "Kalıp", name: "Plywood ile eğri yüzeyli betonarme kalıbı", unit: "m²" },
  { code: "Y.21.002/02", category: "Kalıp", name: "Dairesel kolon kalıbı", unit: "m²" },
  { code: "Y.21.002/03", category: "Kalıp", name: "Dairesel duvar/perde kalıbı", unit: "m²" },
  { code: "Y.21.011/01", category: "Kalıp", name: "Tünel kalıp ile betonarme kalıbı", unit: "m²", description: "Çelik tünel kalıp sistemi ile duvar ve döşemenin tek seferde dökümü.\nKalıp kurulumu, döküm, sökum ve yer değişimi dahildir." },
  { code: "Y.21.020/01", category: "Kalıp", name: "Çelik kolon kalıbı (modüler)", unit: "m²" },
  { code: "Y.21.020/02", category: "Kalıp", name: "Çelik perde kalıbı (modüler)", unit: "m²" },
  { code: "Y.21.020/03", category: "Kalıp", name: "Çelik döşeme kalıbı (panel)", unit: "m²" },
  { code: "Y.21.030/01", category: "Kalıp", name: "Mantar (drop-head) kalıp sistemi", unit: "m²" },
  { code: "Y.21.040/01", category: "Kalıp", name: "Tırmanır kalıp (climbing) sistemi", unit: "m²" },
  { code: "Y.21.040/02", category: "Kalıp", name: "Kayar kalıp (slip-form) sistemi", unit: "m²" },
  { code: "Y.21.050/01", category: "Kalıp", name: "Tek yüzlü perde kalıbı", unit: "m²" },
  { code: "Y.21.057/01", category: "Kalıp", name: "Çelik kalıp ile düz yüzey betonarme kalıbı", unit: "m²" },
  { code: "Y.21.060/01", category: "Kalıp", name: "Asmolen kalıp sistemi", unit: "m²" },
  { code: "Y.21.061/01", category: "Kalıp", name: "Polistren asmolen blok yerleştirme", unit: "ad" },
  { code: "Y.21.070/01", category: "Kalıp", name: "Cephe iskelesi kurulumu", unit: "m²" },
  { code: "Y.21.070/02", category: "Kalıp", name: "İç iskele/destek iskelesi", unit: "m²" },
  { code: "Y.21.070/03", category: "Kalıp", name: "Asansörlü cephe iskelesi", unit: "m²" },
  { code: "Y.21.080/01", category: "Kalıp", name: "Brüt beton görünümlü özel kalıp", unit: "m²" },
  { code: "Y.21.080/02", category: "Kalıp", name: "Desenli kalıp (ahşap dokulu)", unit: "m²" },
];

const DUVAR: ImalatPoz[] = [
  { code: "Y.18.001/01", category: "Duvar", name: "Yatay delikli tuğla (19x19x13.5) duvar", unit: "m³", description: "TS 4377 standardına uygun yatay delikli tuğla.\nÇimento+kireç harcı ile örülmesi.\nDerz dolgusu dahildir." },
  { code: "Y.18.001/02", category: "Duvar", name: "Yatay delikli tuğla (19x19x8.5) duvar", unit: "m²" },
  { code: "Y.18.001/03", category: "Duvar", name: "Düşey delikli tuğla duvar", unit: "m³" },
  { code: "Y.18.001/04", category: "Duvar", name: "Dolu tuğla duvar (klasik)", unit: "m³" },
  { code: "Y.18.001/05", category: "Duvar", name: "Refrakter tuğla duvar (baca)", unit: "m³" },
  { code: "Y.18.002/01", category: "Duvar", name: "Gaz beton blok duvar (G2/0.50, 7.5 cm)", unit: "m²" },
  { code: "Y.18.002/02", category: "Duvar", name: "Gaz beton blok duvar (G2/0.50, 10 cm)", unit: "m²" },
  { code: "Y.18.002/03", category: "Duvar", name: "Gaz beton blok duvar (G2/0.50, 15 cm)", unit: "m²" },
  { code: "Y.18.002/04", category: "Duvar", name: "Gaz beton blok duvar (G2/0.50, 20 cm)", unit: "m²" },
  { code: "Y.18.002/05", category: "Duvar", name: "Gaz beton blok duvar (G2/0.50, 25 cm)", unit: "m²", description: "Otoklavlanmış gaz beton blok ile duvar örülmesi.\nÖzel yapıştırma harcı kullanılır.\nYatay ve düşey hatıl bağlantıları dahildir." },
  { code: "Y.18.002/06", category: "Duvar", name: "Gaz beton blok duvar (G4/0.60, 25 cm)", unit: "m²" },
  { code: "Y.18.003/01", category: "Duvar", name: "Bims briket duvar (10 cm)", unit: "m²" },
  { code: "Y.18.003/02", category: "Duvar", name: "Bims briket duvar (15 cm)", unit: "m²" },
  { code: "Y.18.003/03", category: "Duvar", name: "Bims briket duvar (20 cm)", unit: "m²" },
  { code: "Y.18.004/01", category: "Duvar", name: "Beton briket duvar", unit: "m²" },
  { code: "Y.18.005/01", category: "Duvar", name: "Çift kat alçı levha bölme duvar (12.5+12.5)", unit: "m²", description: "Çelik konstrüksiyon üzerine 12.5 mm alçı levha çift kat.\nİçi taşyünü/cam yünü dolgulu.\nDerz bandı, macun ve yüzey hazırlığı dahildir." },
  { code: "Y.18.005/02", category: "Duvar", name: "Tek kat alçı levha bölme duvar (12.5)", unit: "m²" },
  { code: "Y.18.005/03", category: "Duvar", name: "Yangına dayanıklı alçı levha bölme", unit: "m²" },
  { code: "Y.18.005/04", category: "Duvar", name: "Su geçirmez alçı levha (yeşil) bölme", unit: "m²" },
  { code: "Y.18.005/05", category: "Duvar", name: "Çimento esaslı levha (CP) bölme", unit: "m²" },
  { code: "Y.18.006/01", category: "Duvar", name: "Tuğla bacalık ve baca duvarı", unit: "m" },
  { code: "Y.18.006/02", category: "Duvar", name: "Çelik tek cidarlı baca", unit: "m" },
  { code: "Y.18.006/03", category: "Duvar", name: "Çelik çift cidarlı yalıtımlı baca", unit: "m" },
  { code: "Y.18.007/01", category: "Duvar", name: "Hatıl betonu yapılması", unit: "m³" },
  { code: "Y.18.007/02", category: "Duvar", name: "Lento betonu", unit: "m³" },
  { code: "Y.18.007/03", category: "Duvar", name: "Düşey hatıl (köşe)", unit: "m³" },
  { code: "Y.18.008/01", category: "Duvar", name: "Cam tuğla duvar", unit: "m²" },
  { code: "Y.18.009/01", category: "Duvar", name: "Akustik bölme duvar", unit: "m²" },
];

const SIVA: ImalatPoz[] = [
  { code: "Y.27.501/01", category: "Sıva ve Şap", name: "İç cephe çimento harçlı kaba sıva (1.5 cm)", unit: "m²" },
  { code: "Y.27.501/02", category: "Sıva ve Şap", name: "İç cephe çimento harçlı kaba sıva (2 cm)", unit: "m²" },
  { code: "Y.27.501/03", category: "Sıva ve Şap", name: "İç cephe çimento harçlı kaba sıva (3 cm)", unit: "m²" },
  { code: "Y.27.502/01", category: "Sıva ve Şap", name: "Dış cephe çimento harçlı kaba sıva", unit: "m²" },
  { code: "Y.27.502/02", category: "Sıva ve Şap", name: "Çift kat dış cephe sıva (kaba+ince)", unit: "m²" },
  { code: "Y.27.510/01", category: "Sıva ve Şap", name: "İnce sıva (perdah) yapılması", unit: "m²" },
  { code: "Y.27.510/02", category: "Sıva ve Şap", name: "Mineral dekoratif sıva", unit: "m²" },
  { code: "Y.27.520/01", category: "Sıva ve Şap", name: "Saten alçı sıva (2-3 mm)", unit: "m²", description: "Düzgün hazırlanmış yüzeye saten alçı uygulanması.\nBoyaya hazır pürüzsüz yüzey elde edilir." },
  { code: "Y.27.521/01", category: "Sıva ve Şap", name: "Makine ile alçı sıva (1.5 cm)", unit: "m²" },
  { code: "Y.27.521/02", category: "Sıva ve Şap", name: "Makine ile alçı sıva (2 cm)", unit: "m²" },
  { code: "Y.27.521/03", category: "Sıva ve Şap", name: "El ile alçı sıva", unit: "m²" },
  { code: "Y.27.530/01", category: "Sıva ve Şap", name: "Çimento esaslı tesviye şapı (3 cm)", unit: "m²" },
  { code: "Y.27.530/02", category: "Sıva ve Şap", name: "Çimento esaslı tesviye şapı (5 cm)", unit: "m²" },
  { code: "Y.27.530/03", category: "Sıva ve Şap", name: "Çimento esaslı tesviye şapı (8 cm)", unit: "m²" },
  { code: "Y.27.530/04", category: "Sıva ve Şap", name: "Eğimli şap (banyo/teras)", unit: "m²" },
  { code: "Y.27.531/01", category: "Sıva ve Şap", name: "Hafif şap (perlit/EPS dolgulu)", unit: "m²" },
  { code: "Y.27.531/02", category: "Sıva ve Şap", name: "Self-leveling (kendiliğinden yayılan) şap", unit: "m²" },
  { code: "Y.27.531/03", category: "Sıva ve Şap", name: "Anhidrit (alçı) şap", unit: "m²" },
  { code: "Y.27.532/01", category: "Sıva ve Şap", name: "Yerden ısıtmalı sistem üzeri şap", unit: "m²" },
  { code: "Y.27.540/01", category: "Sıva ve Şap", name: "Brüt beton silinmesi/perdahı", unit: "m²" },
  { code: "Y.27.540/02", category: "Sıva ve Şap", name: "Beton yüzey tamiratı (epoksi)", unit: "m²" },
];

const YALITIM: ImalatPoz[] = [
  { code: "Y.10.300.1051", category: "Yalıtım", name: "Polimer bitümlü membran su yalıtımı (3 mm)", unit: "m²", description: "Plastomer (APP) veya elastomer (SBS) esaslı membran.\nAlttan astar uygulanması, üst üste 10 cm bindirme.\nŞaloma ile kaynak yapılarak uygulanır." },
  { code: "Y.10.300.1052", category: "Yalıtım", name: "Polimer bitümlü membran (4 mm)", unit: "m²" },
  { code: "Y.10.300.1053", category: "Yalıtım", name: "Polimer bitümlü membran (3 mm + 4 mm çift kat)", unit: "m²" },
  { code: "Y.10.300.1054", category: "Yalıtım", name: "Mineral kaplamalı membran (üst kat)", unit: "m²" },
  { code: "Y.10.300.1100", category: "Yalıtım", name: "Sürme su yalıtım (kristalize çimento esaslı)", unit: "m²" },
  { code: "Y.10.300.1110", category: "Yalıtım", name: "Çift komponentli akrilik su yalıtım", unit: "m²" },
  { code: "Y.10.300.1120", category: "Yalıtım", name: "Bitüm-kauçuk esaslı sıvı membran", unit: "m²" },
  { code: "Y.10.300.1130", category: "Yalıtım", name: "Poliüretan esaslı su yalıtım", unit: "m²" },
  { code: "Y.10.300.1140", category: "Yalıtım", name: "EPDM membran", unit: "m²" },
  { code: "Y.10.300.1150", category: "Yalıtım", name: "PVC membran", unit: "m²" },
  { code: "Y.10.300.1160", category: "Yalıtım", name: "TPO membran", unit: "m²" },
  { code: "Y.10.300.1170", category: "Yalıtım", name: "Bentonit su yalıtım örtüsü", unit: "m²" },
  { code: "Y.10.300.4421", category: "Yalıtım", name: "XPS plaka 3 cm", unit: "m²" },
  { code: "Y.10.300.4422", category: "Yalıtım", name: "XPS plaka 4 cm", unit: "m²" },
  { code: "Y.10.300.4423", category: "Yalıtım", name: "XPS plaka 5 cm", unit: "m²", description: "Ekstrude polistren köpük (XPS) levha ile ısı yalıtımı." },
  { code: "Y.10.300.4424", category: "Yalıtım", name: "XPS plaka 6 cm", unit: "m²" },
  { code: "Y.10.300.4425", category: "Yalıtım", name: "XPS plaka 8 cm", unit: "m²" },
  { code: "Y.10.300.4426", category: "Yalıtım", name: "XPS plaka 10 cm", unit: "m²" },
  { code: "Y.10.300.4521", category: "Yalıtım", name: "Taşyünü plaka 5 cm", unit: "m²" },
  { code: "Y.10.300.4522", category: "Yalıtım", name: "Taşyünü plaka 6 cm", unit: "m²" },
  { code: "Y.10.300.4523", category: "Yalıtım", name: "Taşyünü plaka 8 cm", unit: "m²" },
  { code: "Y.10.300.4524", category: "Yalıtım", name: "Taşyünü plaka 10 cm", unit: "m²" },
  { code: "Y.10.300.4530", category: "Yalıtım", name: "Camyünü şilte 5 cm", unit: "m²" },
  { code: "Y.10.300.4531", category: "Yalıtım", name: "Camyünü şilte 10 cm", unit: "m²" },
  { code: "Y.10.300.4540", category: "Yalıtım", name: "EPS strafor 3 cm", unit: "m²" },
  { code: "Y.10.300.4541", category: "Yalıtım", name: "EPS strafor 5 cm", unit: "m²" },
  { code: "Y.10.300.4542", category: "Yalıtım", name: "EPS strafor 8 cm", unit: "m²" },
  { code: "Y.10.300.4550", category: "Yalıtım", name: "Çatı arası dökme cam yünü", unit: "m³" },
  { code: "Y.10.300.4560", category: "Yalıtım", name: "Poliüretan püskürtme yalıtım", unit: "m²" },
  { code: "Y.10.300.4570", category: "Yalıtım", name: "Vakum izolasyon paneli (VIP)", unit: "m²" },
  { code: "Y.10.300.5010", category: "Yalıtım", name: "Asma tavan ses yalıtımı", unit: "m²" },
  { code: "Y.10.300.5020", category: "Yalıtım", name: "Yüzer döşeme ses yalıtım şiltesi", unit: "m²" },
  { code: "Y.10.300.5030", category: "Yalıtım", name: "Akustik panel kaplaması", unit: "m²" },
];

const CATI: ImalatPoz[] = [
  { code: "Y.27.701/01", category: "Çatı", name: "Marsilya tipi kiremit kaplama", unit: "m²", description: "Marsilya kiremit ile çatı kaplaması.\nLata, kontra lata ve mahya kiremidi dahildir." },
  { code: "Y.27.701/02", category: "Çatı", name: "Alaturka kiremit kaplama", unit: "m²" },
  { code: "Y.27.701/03", category: "Çatı", name: "Akdeniz kiremit kaplama", unit: "m²" },
  { code: "Y.27.701/04", category: "Çatı", name: "Beton kiremit kaplama", unit: "m²" },
  { code: "Y.27.702/01", category: "Çatı", name: "Çatı ahşap konstrüksiyonu (kerestesi)", unit: "m³" },
  { code: "Y.27.702/02", category: "Çatı", name: "Çelik çatı makası", unit: "ton" },
  { code: "Y.27.702/03", category: "Çatı", name: "Lamelli ahşap (glulam) makas", unit: "m³" },
  { code: "Y.27.703/01", category: "Çatı", name: "OSB çatı tahtası (15-18 mm)", unit: "m²" },
  { code: "Y.27.703/02", category: "Çatı", name: "Su yalıtım altı membran (T1)", unit: "m²" },
  { code: "Y.27.704/01", category: "Çatı", name: "Bitümlü asfalt shingle kaplama", unit: "m²" },
  { code: "Y.27.704/02", category: "Çatı", name: "Trapez sac kaplama", unit: "m²" },
  { code: "Y.27.704/03", category: "Çatı", name: "Sandviç panel çatı kaplaması (5 cm)", unit: "m²" },
  { code: "Y.27.704/04", category: "Çatı", name: "Sandviç panel çatı kaplaması (8 cm)", unit: "m²" },
  { code: "Y.27.704/05", category: "Çatı", name: "Sandviç panel çatı kaplaması (10 cm)", unit: "m²" },
  { code: "Y.27.704/06", category: "Çatı", name: "Bakır levha çatı kaplama", unit: "m²" },
  { code: "Y.27.704/07", category: "Çatı", name: "Çinko-titanyum çatı kaplama", unit: "m²" },
  { code: "Y.27.704/08", category: "Çatı", name: "Polikarbon ışıklık kaplama", unit: "m²" },
  { code: "Y.27.705/01", category: "Çatı", name: "Galvaniz oluk", unit: "m" },
  { code: "Y.27.705/02", category: "Çatı", name: "PVC oluk", unit: "m" },
  { code: "Y.27.705/03", category: "Çatı", name: "Bakır oluk", unit: "m" },
  { code: "Y.27.705/04", category: "Çatı", name: "Galvaniz indirme borusu", unit: "m" },
  { code: "Y.27.705/05", category: "Çatı", name: "PVC indirme borusu", unit: "m" },
  { code: "Y.27.706/01", category: "Çatı", name: "Çatı havalandırma bacası", unit: "ad" },
  { code: "Y.27.706/02", category: "Çatı", name: "Çatı penceresi (Velux tipi)", unit: "ad" },
  { code: "Y.27.706/03", category: "Çatı", name: "Mahya kiremidi", unit: "m" },
  { code: "Y.27.706/04", category: "Çatı", name: "Çatı feneri (light dome)", unit: "ad" },
  { code: "Y.27.706/05", category: "Çatı", name: "Yağmur taşma borusu (overflow)", unit: "ad" },
  { code: "Y.27.707/01", category: "Çatı", name: "Yeşil çatı uygulama (extensive)", unit: "m²" },
  { code: "Y.27.707/02", category: "Çatı", name: "Teras gezilebilir çatı kaplama", unit: "m²" },
];

const KAPLAMA: ImalatPoz[] = [
  { code: "Y.26.001/01", category: "Kaplama", name: "Seramik yer döşemesi 30x30", unit: "m²" },
  { code: "Y.26.001/02", category: "Kaplama", name: "Seramik yer döşemesi 33x33", unit: "m²" },
  { code: "Y.26.001/03", category: "Kaplama", name: "Seramik yer döşemesi 45x45", unit: "m²" },
  { code: "Y.26.001/04", category: "Kaplama", name: "Seramik yer döşemesi 60x60", unit: "m²", description: "1. sınıf granit seramik karo ile yer döşemesi.\nÇimento esaslı yapıştırıcı ve derz dolgusu dahildir." },
  { code: "Y.26.001/05", category: "Kaplama", name: "Seramik yer döşemesi 80x80", unit: "m²" },
  { code: "Y.26.002/01", category: "Kaplama", name: "Porselen karo 60x60 (rektifiyeli)", unit: "m²" },
  { code: "Y.26.002/02", category: "Kaplama", name: "Porselen karo 60x120", unit: "m²" },
  { code: "Y.26.002/03", category: "Kaplama", name: "Porselen karo 75x150", unit: "m²" },
  { code: "Y.26.003/01", category: "Kaplama", name: "Seramik duvar kaplaması (banyo) 25x40", unit: "m²" },
  { code: "Y.26.003/02", category: "Kaplama", name: "Seramik duvar kaplaması (banyo) 30x60", unit: "m²" },
  { code: "Y.26.003/03", category: "Kaplama", name: "Mozaik karo (cam/seramik)", unit: "m²" },
  { code: "Y.26.004/01", category: "Kaplama", name: "Süpürgelik fayans (10 cm)", unit: "m" },
  { code: "Y.26.004/02", category: "Kaplama", name: "Süpürgelik mermer/granit", unit: "m" },
  { code: "Y.26.004/03", category: "Kaplama", name: "Süpürgelik MDF/laminat", unit: "m" },
  { code: "Y.26.301/01", category: "Kaplama", name: "Granit yer kaplama (30x30)", unit: "m²" },
  { code: "Y.26.301/02", category: "Kaplama", name: "Granit yer kaplama (60x60)", unit: "m²" },
  { code: "Y.26.301/03", category: "Kaplama", name: "Mermer yer kaplama (cilalı)", unit: "m²" },
  { code: "Y.26.301/04", category: "Kaplama", name: "Traverten yer kaplama", unit: "m²" },
  { code: "Y.26.310/01", category: "Kaplama", name: "Mermer denizlik (pencere altı)", unit: "m" },
  { code: "Y.26.310/02", category: "Kaplama", name: "Mermer eşik", unit: "m" },
  { code: "Y.26.320/01", category: "Kaplama", name: "Mermer basamak + rıht", unit: "m" },
  { code: "Y.26.320/02", category: "Kaplama", name: "Granit basamak + rıht", unit: "m" },
  { code: "Y.26.401/01", category: "Kaplama", name: "Laminat parke 8 mm AC4", unit: "m²" },
  { code: "Y.26.401/02", category: "Kaplama", name: "Laminat parke 10 mm AC5", unit: "m²" },
  { code: "Y.26.401/03", category: "Kaplama", name: "Laminat parke 12 mm AC5", unit: "m²" },
  { code: "Y.26.402/01", category: "Kaplama", name: "Masif parke", unit: "m²" },
  { code: "Y.26.402/02", category: "Kaplama", name: "Lamine (engineered) parke", unit: "m²" },
  { code: "Y.26.403/01", category: "Kaplama", name: "PVC/LVT kaplama 4 mm", unit: "m²" },
  { code: "Y.26.403/02", category: "Kaplama", name: "PVC/LVT kaplama 5 mm (klik)", unit: "m²" },
  { code: "Y.26.404/01", category: "Kaplama", name: "Halıfleks döşemesi", unit: "m²" },
  { code: "Y.26.404/02", category: "Kaplama", name: "Halı karo", unit: "m²" },
  { code: "Y.26.404/03", category: "Kaplama", name: "Linoleum kaplama", unit: "m²" },
  { code: "Y.26.405/01", category: "Kaplama", name: "Epoksi yer kaplaması (endüstriyel)", unit: "m²" },
  { code: "Y.26.405/02", category: "Kaplama", name: "Polyuretan döşeme kaplaması", unit: "m²" },
  { code: "Y.26.405/03", category: "Kaplama", name: "Anti-statik PVC kaplama", unit: "m²" },
  { code: "Y.26.406/01", category: "Kaplama", name: "Asma tavan (alçı plaka)", unit: "m²" },
  { code: "Y.26.406/02", category: "Kaplama", name: "Asma tavan (taşyünü panel)", unit: "m²" },
  { code: "Y.26.406/03", category: "Kaplama", name: "Asma tavan (alüminyum lamel)", unit: "m²" },
  { code: "Y.26.406/04", category: "Kaplama", name: "Akustik asma tavan", unit: "m²" },
  { code: "Y.26.407/01", category: "Kaplama", name: "Ahşap duvar kaplama (lambri)", unit: "m²" },
  { code: "Y.26.407/02", category: "Kaplama", name: "Doğal taş duvar kaplama (kültür taşı)", unit: "m²" },
];

const BOYA: ImalatPoz[] = [
  { code: "Y.25.001/01", category: "Boya", name: "Astar boya uygulanması", unit: "m²" },
  { code: "Y.25.001/02", category: "Boya", name: "Macunlama (silisyumlu)", unit: "m²" },
  { code: "Y.25.001/03", category: "Boya", name: "Akrilik macun çekilmesi", unit: "m²" },
  { code: "Y.25.001/04", category: "Boya", name: "Zımpara (yüzey hazırlığı)", unit: "m²" },
  { code: "Y.25.116/01", category: "Boya", name: "İç cephe plastik boya (2 kat)", unit: "m²", description: "Yüzey hazırlığı, macunlama ve zımpara.\nTek kat astar, iki kat plastik boya uygulanması." },
  { code: "Y.25.116/02", category: "Boya", name: "İç cephe saten boya (2 kat)", unit: "m²" },
  { code: "Y.25.116/03", category: "Boya", name: "İç cephe ipek mat boya", unit: "m²" },
  { code: "Y.25.116/04", category: "Boya", name: "Tavanlara plastik boya", unit: "m²" },
  { code: "Y.25.116/05", category: "Boya", name: "Antibakteriyel iç cephe boyası", unit: "m²" },
  { code: "Y.25.150/01", category: "Boya", name: "Dış cephe akrilik boya (2 kat)", unit: "m²" },
  { code: "Y.25.150/02", category: "Boya", name: "Dış cephe silikon esaslı boya", unit: "m²" },
  { code: "Y.25.150/03", category: "Boya", name: "Dış cephe silikat boya", unit: "m²" },
  { code: "Y.25.150/04", category: "Boya", name: "Dış cephe elastomerik boya", unit: "m²" },
  { code: "Y.25.151/01", category: "Boya", name: "Dış cephe dekoratif kaplama (mineral)", unit: "m²" },
  { code: "Y.25.151/02", category: "Boya", name: "Dış cephe dekoratif kaplama (akrilik)", unit: "m²" },
  { code: "Y.25.200/01", category: "Boya", name: "Yağlı boya (iki kat)", unit: "m²" },
  { code: "Y.25.200/02", category: "Boya", name: "Sentetik boya", unit: "m²" },
  { code: "Y.25.200/03", category: "Boya", name: "Antipas boya (demir aksam)", unit: "m²" },
  { code: "Y.25.200/04", category: "Boya", name: "Galvaniz boya (çinko esaslı)", unit: "m²" },
  { code: "Y.25.220/01", category: "Boya", name: "Su bazlı vernik (parke/ahşap)", unit: "m²" },
  { code: "Y.25.220/02", category: "Boya", name: "Solvent bazlı vernik", unit: "m²" },
  { code: "Y.25.230/01", category: "Boya", name: "Demir konstrüksiyon antipas + boya", unit: "m²" },
  { code: "Y.25.240/01", category: "Boya", name: "Yangın geciktirici boya (çelik)", unit: "m²" },
  { code: "Y.25.250/01", category: "Boya", name: "Yol çizgi boyası (termoplastik)", unit: "m" },
  { code: "Y.25.260/01", category: "Boya", name: "Tekstüre kabartma boyalı kaplama", unit: "m²" },
];

const DOGRAMA: ImalatPoz[] = [
  { code: "Y.24.151/01", category: "Doğrama", name: "PVC pencere (5 odacık, 4+16+4 ısıcam)", unit: "m²", description: "5 odacıklı PVC profil ile pencere imalatı.\n4+16+4 mm low-e ısı camı dahildir." },
  { code: "Y.24.151/02", category: "Doğrama", name: "PVC pencere (6 odacık, 4+16+4+16+4 üçlü cam)", unit: "m²" },
  { code: "Y.24.151/03", category: "Doğrama", name: "PVC sürme pencere", unit: "m²" },
  { code: "Y.24.152/01", category: "Doğrama", name: "PVC kapı doğraması", unit: "m²" },
  { code: "Y.24.152/02", category: "Doğrama", name: "PVC balkon kapısı", unit: "m²" },
  { code: "Y.24.158/01", category: "Doğrama", name: "Alüminyum cephe doğraması (termal kırmalı)", unit: "m²" },
  { code: "Y.24.158/02", category: "Doğrama", name: "Alüminyum sürme pencere", unit: "m²" },
  { code: "Y.24.158/03", category: "Doğrama", name: "Alüminyum açılır pencere", unit: "m²" },
  { code: "Y.24.158/04", category: "Doğrama", name: "Alüminyum vitrin/giriş kapısı", unit: "m²" },
  { code: "Y.24.158/05", category: "Doğrama", name: "Alüminyum katlanır cam balkon", unit: "m²" },
  { code: "Y.24.158/06", category: "Doğrama", name: "Alüminyum giyotin pencere", unit: "m²" },
  { code: "Y.24.165/01", category: "Doğrama", name: "Otomatik fotoselli giriş kapısı", unit: "ad" },
  { code: "Y.24.165/02", category: "Doğrama", name: "Otomatik döner kapı", unit: "ad" },
  { code: "Y.24.231/01", category: "Doğrama", name: "Ahşap iç kapı (lake, kasa dahil)", unit: "ad", description: "Lake veya kaplama ahşap iç kapı.\nKasa, pervaz, menteşe, kol ve kilit dahil komple montaj." },
  { code: "Y.24.231/02", category: "Doğrama", name: "Ahşap iç kapı (kaplama, kasa dahil)", unit: "ad" },
  { code: "Y.24.231/03", category: "Doğrama", name: "Amerikan panel kapı", unit: "ad" },
  { code: "Y.24.231/04", category: "Doğrama", name: "MDF iç kapı", unit: "ad" },
  { code: "Y.24.231/05", category: "Doğrama", name: "Sürgülü iç kapı (rayli)", unit: "ad" },
  { code: "Y.24.231/06", category: "Doğrama", name: "Cam iç kapı", unit: "ad" },
  { code: "Y.24.240/01", category: "Doğrama", name: "Ahşap dış kapı", unit: "ad" },
  { code: "Y.24.245/01", category: "Doğrama", name: "Çelik daire kapısı (standart)", unit: "ad" },
  { code: "Y.24.245/02", category: "Doğrama", name: "Çelik daire kapısı (lüks)", unit: "ad" },
  { code: "Y.24.245/03", category: "Doğrama", name: "Çelik villa kapısı", unit: "ad" },
  { code: "Y.24.250/01", category: "Doğrama", name: "Yangın kapısı (60 dk)", unit: "ad" },
  { code: "Y.24.250/02", category: "Doğrama", name: "Yangın kapısı (90 dk)", unit: "ad" },
  { code: "Y.24.250/03", category: "Doğrama", name: "Yangın kapısı (120 dk)", unit: "ad" },
  { code: "Y.24.260/01", category: "Doğrama", name: "Sektoral garaj kapısı (motorlu)", unit: "m²" },
  { code: "Y.24.260/02", category: "Doğrama", name: "Yana açılır endüstriyel kapı", unit: "m²" },
  { code: "Y.24.260/03", category: "Doğrama", name: "Hızlı sarmal kapı (PVC)", unit: "m²" },
  { code: "Y.24.270/01", category: "Doğrama", name: "Kepenk (motorlu)", unit: "m²" },
  { code: "Y.24.270/02", category: "Doğrama", name: "Tente / pergola", unit: "m²" },
  { code: "Y.24.280/01", category: "Doğrama", name: "Korkuluk (alüminyum + cam)", unit: "m" },
  { code: "Y.24.280/02", category: "Doğrama", name: "Korkuluk (paslanmaz çelik)", unit: "m" },
  { code: "Y.24.280/03", category: "Doğrama", name: "Korkuluk (ferforje)", unit: "m" },
];

const PPR_CAPLAR = ["20","25","32","40","50","63","75","90","110"];
const PVC_GIDER = ["50","75","100","125","160","200"];

const SIHHI: ImalatPoz[] = [
  ...PPR_CAPLAR.map((c, i) => ({
    code: `Y.071-1${(i+10).toString().padStart(2,"0")}`,
    category: "Sıhhi Tesisat",
    name: `PPR-C boru ve ek parça (Ø${c})`,
    unit: "m",
    description: i === 0 ? "Polipropilen randon copolimer (PPR-C) sıcak/soğuk su borusu.\nFüzyon kaynak ile birleştirme.\nGerekli ek parçalar (T, dirsek, manşon) dahil." : undefined,
  })),
  ...PVC_GIDER.map((c, i) => ({
    code: `Y.072-2${(i+10).toString().padStart(2,"0")}`,
    category: "Sıhhi Tesisat",
    name: `PVC pis su borusu (Ø${c})`,
    unit: "m",
    description: i === 0 ? "Sızdırmaz PVC pis su gider borusu.\nMuf veya yapıştırıcı bağlantılı.\nUygun eğimle döşenmesi dahildir." : undefined,
  })),
  { code: "Y.073-301", category: "Sıhhi Tesisat", name: "HDPE pis su borusu (Ø50, kaynaklı)", unit: "m" },
  { code: "Y.073-302", category: "Sıhhi Tesisat", name: "HDPE pis su borusu (Ø100, kaynaklı)", unit: "m" },
  { code: "Y.073-303", category: "Sıhhi Tesisat", name: "Sessiz atık su borusu (Polo-Kal)", unit: "m" },
  { code: "Y.074-401", category: "Sıhhi Tesisat", name: "Galvaniz boru (1/2'')", unit: "m" },
  { code: "Y.074-402", category: "Sıhhi Tesisat", name: "Galvaniz boru (3/4'')", unit: "m" },
  { code: "Y.074-403", category: "Sıhhi Tesisat", name: "Galvaniz boru (1'')", unit: "m" },
  { code: "Y.074-404", category: "Sıhhi Tesisat", name: "Bakır boru (sıhhi tesisat)", unit: "m" },
  { code: "Y.074-405", category: "Sıhhi Tesisat", name: "PEX-AL-PEX kompozit boru", unit: "m" },
  { code: "Y.081-501", category: "Sıhhi Tesisat", name: "Klozet (rezervuarlı, oturak)", unit: "ad" },
  { code: "Y.081-502", category: "Sıhhi Tesisat", name: "Asma klozet + gömme rezervuar", unit: "ad" },
  { code: "Y.081-503", category: "Sıhhi Tesisat", name: "Akıllı klozet (taharet musluklu)", unit: "ad" },
  { code: "Y.081-504", category: "Sıhhi Tesisat", name: "Lavabo (ayaklı)", unit: "ad" },
  { code: "Y.081-505", category: "Sıhhi Tesisat", name: "Lavabo (yarım ayaklı)", unit: "ad" },
  { code: "Y.081-506", category: "Sıhhi Tesisat", name: "Lavabo (tezgah üstü)", unit: "ad" },
  { code: "Y.081-507", category: "Sıhhi Tesisat", name: "Lavabo (tezgah altı)", unit: "ad" },
  { code: "Y.081-508", category: "Sıhhi Tesisat", name: "Pisuvar (manuel)", unit: "ad" },
  { code: "Y.081-509", category: "Sıhhi Tesisat", name: "Pisuvar (sensörlü)", unit: "ad" },
  { code: "Y.081-510", category: "Sıhhi Tesisat", name: "Banyo eviyesi (akrilik kabin)", unit: "ad" },
  { code: "Y.081-511", category: "Sıhhi Tesisat", name: "Duşa kabin (komple)", unit: "ad" },
  { code: "Y.081-512", category: "Sıhhi Tesisat", name: "Mutfak eviyesi (paslanmaz tek gözlü)", unit: "ad" },
  { code: "Y.081-513", category: "Sıhhi Tesisat", name: "Mutfak eviyesi (paslanmaz çift gözlü)", unit: "ad" },
  { code: "Y.081-514", category: "Sıhhi Tesisat", name: "Granit eviye (tezgah altı)", unit: "ad" },
  { code: "Y.081-515", category: "Sıhhi Tesisat", name: "Lavabo bataryası", unit: "ad" },
  { code: "Y.081-516", category: "Sıhhi Tesisat", name: "Eviye bataryası", unit: "ad" },
  { code: "Y.081-517", category: "Sıhhi Tesisat", name: "Duş bataryası + el duşu", unit: "ad" },
  { code: "Y.081-518", category: "Sıhhi Tesisat", name: "Banyo bataryası (banyo+duş)", unit: "ad" },
  { code: "Y.081-519", category: "Sıhhi Tesisat", name: "Termostatik duş bataryası", unit: "ad" },
  { code: "Y.081-520", category: "Sıhhi Tesisat", name: "Yer süzgeci (paslanmaz)", unit: "ad" },
  { code: "Y.081-521", category: "Sıhhi Tesisat", name: "Sifon (lavabo)", unit: "ad" },
  { code: "Y.081-522", category: "Sıhhi Tesisat", name: "Termosifon (boyler) montajı", unit: "ad" },
  { code: "Y.081-523", category: "Sıhhi Tesisat", name: "Şofben/kombi su giriş çıkış bağlantısı", unit: "ad" },
  { code: "Y.081-524", category: "Sıhhi Tesisat", name: "Su deposu (polietilen, 1000 L)", unit: "ad" },
  { code: "Y.081-525", category: "Sıhhi Tesisat", name: "Hidrofor montajı", unit: "ad" },
  { code: "Y.081-526", category: "Sıhhi Tesisat", name: "Su sayacı (Ø15-20 mm)", unit: "ad" },
  { code: "Y.081-527", category: "Sıhhi Tesisat", name: "Vana (küresel, 1/2'')", unit: "ad" },
  { code: "Y.081-528", category: "Sıhhi Tesisat", name: "Filtre (su giriş)", unit: "ad" },
];

const KABLO_TIPLERI = [
  ["Y.33.100/01", "NYA tek damarlı 1.5 mm²"],
  ["Y.33.100/02", "NYA tek damarlı 2.5 mm²"],
  ["Y.33.100/03", "NYA tek damarlı 4 mm²"],
  ["Y.33.100/04", "NYA tek damarlı 6 mm²"],
  ["Y.33.100/05", "NYA tek damarlı 10 mm²"],
  ["Y.33.110/01", "NYM 3x1.5 mm²"],
  ["Y.33.110/02", "NYM 3x2.5 mm²"],
  ["Y.33.110/03", "NYM 3x4 mm²"],
  ["Y.33.110/04", "NYM 5x2.5 mm²"],
  ["Y.33.110/05", "NYM 5x4 mm²"],
  ["Y.33.120/01", "NYY 4x4 mm²"],
  ["Y.33.120/02", "NYY 4x6 mm²"],
  ["Y.33.120/03", "NYY 4x10 mm²"],
  ["Y.33.120/04", "NYY 4x16 mm²"],
  ["Y.33.120/05", "NYY 4x25 mm²"],
  ["Y.33.130/01", "Cat6 UTP veri kablosu"],
  ["Y.33.130/02", "Cat6 STP veri kablosu"],
  ["Y.33.130/03", "Cat6a STP veri kablosu"],
  ["Y.33.130/04", "Fiber optik kablo (multimode)"],
  ["Y.33.130/05", "Fiber optik kablo (singlemode)"],
  ["Y.33.140/01", "TV/SAT kablosu RG6"],
  ["Y.33.140/02", "Hoparlör kablosu (2x2.5)"],
  ["Y.33.140/03", "Yangın algılama kablosu JE-H"],
  ["Y.33.140/04", "Halojensiz NHXMH 3x1.5"],
  ["Y.33.140/05", "Halojensiz NHXMH 3x2.5"],
];

const ELEKTRIK: ImalatPoz[] = [
  ...KABLO_TIPLERI.map(([code, name]) => ({
    code,
    category: "Elektrik",
    name: `${name} çekilmesi`,
    unit: "m",
  })),
  { code: "Y.33.300/01", category: "Elektrik", name: "Sıva altı topraklı priz", unit: "ad" },
  { code: "Y.33.300/02", category: "Elektrik", name: "Sıva altı USB'li priz", unit: "ad" },
  { code: "Y.33.300/03", category: "Elektrik", name: "Sıva altı çocuk korumalı priz", unit: "ad" },
  { code: "Y.33.300/04", category: "Elektrik", name: "Yer içi priz kutusu", unit: "ad" },
  { code: "Y.33.300/05", category: "Elektrik", name: "Endüstriyel CEE priz", unit: "ad" },
  { code: "Y.33.310/01", category: "Elektrik", name: "Anahtar (tek)", unit: "ad" },
  { code: "Y.33.310/02", category: "Elektrik", name: "Anahtar (komütatör)", unit: "ad" },
  { code: "Y.33.310/03", category: "Elektrik", name: "Anahtar (vavyen)", unit: "ad" },
  { code: "Y.33.310/04", category: "Elektrik", name: "Dimer anahtar", unit: "ad" },
  { code: "Y.33.310/05", category: "Elektrik", name: "Sensörlü anahtar (PIR)", unit: "ad" },
  { code: "Y.33.310/06", category: "Elektrik", name: "Akıllı anahtar (KNX/Wi-Fi)", unit: "ad" },
  { code: "Y.33.320/01", category: "Elektrik", name: "Veri/data prizi (Cat6 RJ45)", unit: "ad" },
  { code: "Y.33.320/02", category: "Elektrik", name: "Telefon prizi (RJ11)", unit: "ad" },
  { code: "Y.33.330/01", category: "Elektrik", name: "TV/uydu prizi", unit: "ad" },
  { code: "Y.33.340/01", category: "Elektrik", name: "Spot armatür (LED 7W)", unit: "ad" },
  { code: "Y.33.340/02", category: "Elektrik", name: "Spot armatür (LED 12W)", unit: "ad" },
  { code: "Y.33.340/03", category: "Elektrik", name: "Sıva üstü tavan armatürü", unit: "ad" },
  { code: "Y.33.340/04", category: "Elektrik", name: "Sıva altı downlight", unit: "ad" },
  { code: "Y.33.340/05", category: "Elektrik", name: "Sarkıt (pendant) armatür", unit: "ad" },
  { code: "Y.33.340/06", category: "Elektrik", name: "Avize (kristal)", unit: "ad" },
  { code: "Y.33.340/07", category: "Elektrik", name: "Aplik armatür", unit: "ad" },
  { code: "Y.33.340/08", category: "Elektrik", name: "Floresan armatür (60 cm)", unit: "ad" },
  { code: "Y.33.340/09", category: "Elektrik", name: "Floresan armatür (120 cm)", unit: "ad" },
  { code: "Y.33.340/10", category: "Elektrik", name: "LED panel armatür (60x60)", unit: "ad" },
  { code: "Y.33.340/11", category: "Elektrik", name: "Etanş armatür (IP65, 120 cm)", unit: "ad" },
  { code: "Y.33.360/01", category: "Elektrik", name: "Acil aydınlatma (kendinden bataryalı)", unit: "ad" },
  { code: "Y.33.365/01", category: "Elektrik", name: "Yönlendirme (exit) armatürü", unit: "ad" },
  { code: "Y.33.400/01", category: "Elektrik", name: "Otomat sigorta 1P (6-32 A)", unit: "ad" },
  { code: "Y.33.400/02", category: "Elektrik", name: "Otomat sigorta 3P (6-63 A)", unit: "ad" },
  { code: "Y.33.410/01", category: "Elektrik", name: "Kaçak akım rölesi 30 mA", unit: "ad" },
  { code: "Y.33.410/02", category: "Elektrik", name: "Kaçak akım rölesi 300 mA", unit: "ad" },
  { code: "Y.33.420/01", category: "Elektrik", name: "Daire sigorta tablosu (komple)", unit: "ad" },
  { code: "Y.33.420/02", category: "Elektrik", name: "Bina ana dağıtım tablosu", unit: "ad" },
  { code: "Y.33.420/03", category: "Elektrik", name: "Kompanzasyon panosu", unit: "ad" },
  { code: "Y.33.430/01", category: "Elektrik", name: "Topraklama bakır levha + bağlantı", unit: "ad" },
  { code: "Y.33.430/02", category: "Elektrik", name: "Topraklama çubuğu (Ø16, 1.5 m)", unit: "ad" },
  { code: "Y.33.440/01", category: "Elektrik", name: "Paratoner (aktif başlık)", unit: "ad" },
  { code: "Y.33.440/02", category: "Elektrik", name: "Paratoner (Franklin pasif)", unit: "ad" },
  { code: "Y.33.450/01", category: "Elektrik", name: "Kapı zili (sesli)", unit: "ad" },
  { code: "Y.33.450/02", category: "Elektrik", name: "Diafon (sesli) sistemi", unit: "ad" },
  { code: "Y.33.450/03", category: "Elektrik", name: "Görüntülü diafon sistemi", unit: "ad" },
  { code: "Y.33.460/01", category: "Elektrik", name: "Kamera (analog dome)", unit: "ad" },
  { code: "Y.33.460/02", category: "Elektrik", name: "Kamera (IP, 4 MP)", unit: "ad" },
  { code: "Y.33.460/03", category: "Elektrik", name: "NVR/DVR kayıt cihazı (16 kanal)", unit: "ad" },
  { code: "Y.33.470/01", category: "Elektrik", name: "Yangın duman dedektörü", unit: "ad" },
  { code: "Y.33.470/02", category: "Elektrik", name: "Yangın ısı dedektörü", unit: "ad" },
  { code: "Y.33.470/03", category: "Elektrik", name: "Yangın alarm butonu", unit: "ad" },
  { code: "Y.33.470/04", category: "Elektrik", name: "Yangın santral panosu", unit: "ad" },
  { code: "Y.33.470/05", category: "Elektrik", name: "Sireli flaşörlü ihbar cihazı", unit: "ad" },
  { code: "Y.33.480/01", category: "Elektrik", name: "Hareket sensörü (PIR)", unit: "ad" },
  { code: "Y.33.480/02", category: "Elektrik", name: "Cam kırılma dedektörü", unit: "ad" },
  { code: "Y.33.490/01", category: "Elektrik", name: "Jeneratör montajı (50 kVA)", unit: "ad" },
  { code: "Y.33.490/02", category: "Elektrik", name: "UPS sistemi (10 kVA)", unit: "ad" },
  { code: "Y.33.490/03", category: "Elektrik", name: "Solar panel (450 W)", unit: "ad" },
  { code: "Y.33.490/04", category: "Elektrik", name: "Inverter (5 kW)", unit: "ad" },
  { code: "Y.33.490/05", category: "Elektrik", name: "EV şarj istasyonu (7.4 kW)", unit: "ad" },
];

const MEKANIK: ImalatPoz[] = [
  { code: "Y.40.100/01", category: "Mekanik Tesisat", name: "Kombi (yoğuşmalı 24 kW)", unit: "ad" },
  { code: "Y.40.100/02", category: "Mekanik Tesisat", name: "Kombi (yoğuşmalı 28 kW)", unit: "ad" },
  { code: "Y.40.100/03", category: "Mekanik Tesisat", name: "Kombi (yoğuşmalı 35 kW)", unit: "ad" },
  { code: "Y.40.100/04", category: "Mekanik Tesisat", name: "Merkezi sistem kazan (sıvı yakıt)", unit: "ad" },
  { code: "Y.40.100/05", category: "Mekanik Tesisat", name: "Merkezi sistem kazan (doğalgaz)", unit: "ad" },
  { code: "Y.40.100/06", category: "Mekanik Tesisat", name: "Pellet kazan", unit: "ad" },
  { code: "Y.40.110/01", category: "Mekanik Tesisat", name: "Yerden ısıtma serpantini (PEX, 16 mm)", unit: "m²" },
  { code: "Y.40.110/02", category: "Mekanik Tesisat", name: "Yerden ısıtma kollektörü", unit: "ad" },
  { code: "Y.40.120/01", category: "Mekanik Tesisat", name: "Panel radyatör (600 mm)", unit: "ad" },
  { code: "Y.40.120/02", category: "Mekanik Tesisat", name: "Panel radyatör (900 mm)", unit: "ad" },
  { code: "Y.40.120/03", category: "Mekanik Tesisat", name: "Dökme dilim radyatör", unit: "ad" },
  { code: "Y.40.130/01", category: "Mekanik Tesisat", name: "Havlupan (50x80)", unit: "ad" },
  { code: "Y.40.130/02", category: "Mekanik Tesisat", name: "Havlupan (50x120)", unit: "ad" },
  { code: "Y.40.140/01", category: "Mekanik Tesisat", name: "Split klima (9000 BTU)", unit: "ad" },
  { code: "Y.40.140/02", category: "Mekanik Tesisat", name: "Split klima (12000 BTU)", unit: "ad" },
  { code: "Y.40.140/03", category: "Mekanik Tesisat", name: "Split klima (18000 BTU)", unit: "ad" },
  { code: "Y.40.140/04", category: "Mekanik Tesisat", name: "Split klima (24000 BTU)", unit: "ad" },
  { code: "Y.40.150/01", category: "Mekanik Tesisat", name: "VRV/VRF iç ünite (kaset)", unit: "ad" },
  { code: "Y.40.150/02", category: "Mekanik Tesisat", name: "VRV/VRF iç ünite (kanallı)", unit: "ad" },
  { code: "Y.40.150/03", category: "Mekanik Tesisat", name: "VRV/VRF dış ünite", unit: "ad" },
  { code: "Y.40.160/01", category: "Mekanik Tesisat", name: "Banyo havalandırma fanı", unit: "ad" },
  { code: "Y.40.160/02", category: "Mekanik Tesisat", name: "Mutfak davlumbaz havalandırma", unit: "ad" },
  { code: "Y.40.170/01", category: "Mekanik Tesisat", name: "Galvaniz hava kanalı", unit: "m²" },
  { code: "Y.40.170/02", category: "Mekanik Tesisat", name: "Yuvarlak spiro kanal (galvaniz)", unit: "m" },
  { code: "Y.40.170/03", category: "Mekanik Tesisat", name: "Hava menfez (lineer)", unit: "ad" },
  { code: "Y.40.170/04", category: "Mekanik Tesisat", name: "Hava menfez (kare difüzör)", unit: "ad" },
  { code: "Y.40.180/01", category: "Mekanik Tesisat", name: "Yangın söndürme sprinkler ucu", unit: "ad" },
  { code: "Y.40.180/02", category: "Mekanik Tesisat", name: "Yangın sprinkler borusu (galvaniz)", unit: "m" },
  { code: "Y.40.190/01", category: "Mekanik Tesisat", name: "Yangın hidrant kabini (dolaplı)", unit: "ad" },
  { code: "Y.40.190/02", category: "Mekanik Tesisat", name: "Yangın hidrant (yer altı)", unit: "ad" },
  { code: "Y.40.200/01", category: "Mekanik Tesisat", name: "Soğutma kulesi", unit: "ad" },
  { code: "Y.40.200/02", category: "Mekanik Tesisat", name: "Chiller (su soğutmalı)", unit: "ad" },
  { code: "Y.40.210/01", category: "Mekanik Tesisat", name: "Doğalgaz iç tesisat (Ø22)", unit: "m" },
  { code: "Y.40.210/02", category: "Mekanik Tesisat", name: "Doğalgaz iç tesisat (Ø28)", unit: "m" },
  { code: "Y.40.220/01", category: "Mekanik Tesisat", name: "Boru yalıtımı (kauçuk köpük)", unit: "m" },
  { code: "Y.40.220/02", category: "Mekanik Tesisat", name: "Kanal yalıtımı (camyünü)", unit: "m²" },
];

const ASANSOR: ImalatPoz[] = [
  { code: "Y.50.100/01", category: "Asansör", name: "Halatlı asansör (4 kişi, 320 kg, 4 durak)", unit: "ad" },
  { code: "Y.50.100/02", category: "Asansör", name: "Halatlı asansör (6 kişi, 450 kg, 5 durak)", unit: "ad" },
  { code: "Y.50.100/03", category: "Asansör", name: "Halatlı asansör (8 kişi, 630 kg, 6 durak)", unit: "ad" },
  { code: "Y.50.100/04", category: "Asansör", name: "Halatlı asansör (13 kişi, 1000 kg)", unit: "ad" },
  { code: "Y.50.110/01", category: "Asansör", name: "MRL (makine dairesiz) asansör", unit: "ad" },
  { code: "Y.50.120/01", category: "Asansör", name: "Hidrolik asansör", unit: "ad" },
  { code: "Y.50.130/01", category: "Asansör", name: "Engelli asansörü (dikey platform)", unit: "ad" },
  { code: "Y.50.130/02", category: "Asansör", name: "Engelli asansörü (eğimli platform)", unit: "ad" },
  { code: "Y.50.140/01", category: "Asansör", name: "Yük asansörü", unit: "ad" },
  { code: "Y.50.150/01", category: "Asansör", name: "Yürüyen merdiven", unit: "ad" },
  { code: "Y.50.150/02", category: "Asansör", name: "Yürüyen bant (hareketli kaldırım)", unit: "m" },
];

const CEPHE: ImalatPoz[] = [
  { code: "Y.10.300.4451", category: "Cephe", name: "Mantolama (3 cm EPS + sıva + boya)", unit: "m²" },
  { code: "Y.10.300.4452", category: "Cephe", name: "Mantolama (5 cm EPS + sıva + boya)", unit: "m²", description: "Yapıştırıcı + dübel + EPS levha + file donatılı sıva + dekoratif kaplama + dış cephe boyası." },
  { code: "Y.10.300.4453", category: "Cephe", name: "Mantolama (8 cm EPS + sıva + boya)", unit: "m²" },
  { code: "Y.10.300.4454", category: "Cephe", name: "Mantolama (5 cm XPS + sıva + boya)", unit: "m²" },
  { code: "Y.10.300.4455", category: "Cephe", name: "Mantolama (5 cm taşyünü + sıva + boya)", unit: "m²" },
  { code: "Y.10.300.4456", category: "Cephe", name: "Mantolama dekoratif kaplama (mineral sıva)", unit: "m²" },
  { code: "Y.10.300.4470/01", category: "Cephe", name: "Granit cephe kaplama (havalandırmalı)", unit: "m²" },
  { code: "Y.10.300.4470/02", category: "Cephe", name: "Traverten cephe kaplama", unit: "m²" },
  { code: "Y.10.300.4470/03", category: "Cephe", name: "Mermer cephe kaplama", unit: "m²" },
  { code: "Y.10.300.4470/04", category: "Cephe", name: "Kültür taşı cephe kaplama", unit: "m²" },
  { code: "Y.10.300.4480/01", category: "Cephe", name: "Alüminyum kompozit panel cephe (4 mm)", unit: "m²" },
  { code: "Y.10.300.4480/02", category: "Cephe", name: "HPL panel cephe", unit: "m²" },
  { code: "Y.10.300.4480/03", category: "Cephe", name: "Fibercement panel cephe", unit: "m²" },
  { code: "Y.10.300.4480/04", category: "Cephe", name: "Seramik cephe (havalandırmalı)", unit: "m²" },
  { code: "Y.10.300.4490/01", category: "Cephe", name: "Giydirme cam cephe (curtain wall, stick)", unit: "m²" },
  { code: "Y.10.300.4490/02", category: "Cephe", name: "Giydirme cam cephe (unitized)", unit: "m²" },
  { code: "Y.10.300.4490/03", category: "Cephe", name: "Spider cephe (silikonlu)", unit: "m²" },
  { code: "Y.10.300.4500/01", category: "Cephe", name: "Brüt beton cephe (pürüzsüz)", unit: "m²" },
  { code: "Y.10.300.4500/02", category: "Cephe", name: "Brüt beton cephe (desenli)", unit: "m²" },
];

const CEVRE: ImalatPoz[] = [
  { code: "Y.18.461/01", category: "Çevre Düzenleme", name: "Beton bordür (15x30)", unit: "m" },
  { code: "Y.18.461/02", category: "Çevre Düzenleme", name: "Beton bordür (18x35)", unit: "m" },
  { code: "Y.18.461/03", category: "Çevre Düzenleme", name: "Granit bordür", unit: "m" },
  { code: "Y.18.465/01", category: "Çevre Düzenleme", name: "Beton kilitli parke (6 cm)", unit: "m²" },
  { code: "Y.18.465/02", category: "Çevre Düzenleme", name: "Beton kilitli parke (8 cm)", unit: "m²" },
  { code: "Y.18.465/03", category: "Çevre Düzenleme", name: "Beton parke (yaya/araç yolu)", unit: "m²" },
  { code: "Y.18.465/04", category: "Çevre Düzenleme", name: "Doğal taş parke", unit: "m²" },
  { code: "Y.18.470/01", category: "Çevre Düzenleme", name: "Yağmursuyu ızgarası (dökme demir)", unit: "ad" },
  { code: "Y.18.470/02", category: "Çevre Düzenleme", name: "Yağmursuyu logarı", unit: "ad" },
  { code: "Y.18.480/01", category: "Çevre Düzenleme", name: "Yeşil alan tesviyesi + bitkisel toprak", unit: "m²" },
  { code: "Y.18.490/01", category: "Çevre Düzenleme", name: "Bahçe aydınlatma direği (LED 4 m)", unit: "ad" },
  { code: "Y.18.490/02", category: "Çevre Düzenleme", name: "Yol aydınlatma direği (LED 8 m)", unit: "ad" },
  { code: "Y.18.500/01", category: "Çevre Düzenleme", name: "Tel örgü çit (h=1.5 m)", unit: "m" },
  { code: "Y.18.500/02", category: "Çevre Düzenleme", name: "Tel örgü çit (h=2 m)", unit: "m" },
  { code: "Y.18.500/03", category: "Çevre Düzenleme", name: "Panel çit (galvanizli)", unit: "m" },
  { code: "Y.18.510/01", category: "Çevre Düzenleme", name: "Beton bahçe duvarı + kaplama", unit: "m²" },
  { code: "Y.18.520/01", category: "Çevre Düzenleme", name: "Pergola/güneşlik (ahşap)", unit: "m²" },
  { code: "Y.18.520/02", category: "Çevre Düzenleme", name: "Pergola/güneşlik (metal)", unit: "m²" },
  { code: "Y.18.530/01", category: "Çevre Düzenleme", name: "Asfalt kaplama (4 cm)", unit: "m²" },
  { code: "Y.18.530/02", category: "Çevre Düzenleme", name: "Asfalt kaplama (6 cm)", unit: "m²" },
];

const PEYZAJ: ImalatPoz[] = [
  { code: "Y.19.001/01", category: "Peyzaj", name: "Çim ekimi (tohum)", unit: "m²" },
  { code: "Y.19.001/02", category: "Peyzaj", name: "Hazır rulo çim serme", unit: "m²" },
  { code: "Y.19.002/01", category: "Peyzaj", name: "Bitkisel toprak getirme + serme (20 cm)", unit: "m³" },
  { code: "Y.19.003/01", category: "Peyzaj", name: "Damla sulama hattı", unit: "m" },
  { code: "Y.19.003/02", category: "Peyzaj", name: "Otomatik fıskiye sulama (gizli)", unit: "ad" },
  { code: "Y.19.003/03", category: "Peyzaj", name: "Sulama otomasyon panosu", unit: "ad" },
  { code: "Y.19.004/01", category: "Peyzaj", name: "Çiçek dikimi (mevsimlik)", unit: "ad" },
  { code: "Y.19.004/02", category: "Peyzaj", name: "Çalı dikimi", unit: "ad" },
  { code: "Y.19.004/03", category: "Peyzaj", name: "Ağaç dikimi (boy 1.5-2 m)", unit: "ad" },
  { code: "Y.19.004/04", category: "Peyzaj", name: "Ağaç dikimi (boy 2-3 m)", unit: "ad" },
  { code: "Y.19.004/05", category: "Peyzaj", name: "Ağaç dikimi (boy 3-5 m)", unit: "ad" },
  { code: "Y.19.005/01", category: "Peyzaj", name: "Süs havuzu (eko sistem)", unit: "m²" },
  { code: "Y.19.005/02", category: "Peyzaj", name: "Süs havuzu fıskiye + filtre", unit: "ad" },
  { code: "Y.19.006/01", category: "Peyzaj", name: "Bank (ahşap+metal)", unit: "ad" },
  { code: "Y.19.006/02", category: "Peyzaj", name: "Çöp kovası (paslanmaz)", unit: "ad" },
  { code: "Y.19.006/03", category: "Peyzaj", name: "Bisiklet park yeri", unit: "ad" },
];

const ALTYAPI: ImalatPoz[] = [
  { code: "Y.30.001/01", category: "Altyapı", name: "Beton menfez (B 100x100)", unit: "m" },
  { code: "Y.30.001/02", category: "Altyapı", name: "Beton menfez (B 150x150)", unit: "m" },
  { code: "Y.30.002/01", category: "Altyapı", name: "Beton büz (Ø300)", unit: "m" },
  { code: "Y.30.002/02", category: "Altyapı", name: "Beton büz (Ø500)", unit: "m" },
  { code: "Y.30.002/03", category: "Altyapı", name: "Beton büz (Ø800)", unit: "m" },
  { code: "Y.30.002/04", category: "Altyapı", name: "Koruge HDPE atıksu borusu (Ø200)", unit: "m" },
  { code: "Y.30.002/05", category: "Altyapı", name: "Koruge HDPE atıksu borusu (Ø315)", unit: "m" },
  { code: "Y.30.002/06", category: "Altyapı", name: "Koruge HDPE atıksu borusu (Ø500)", unit: "m" },
  { code: "Y.30.003/01", category: "Altyapı", name: "Atıksu logarı (B 80x80)", unit: "ad" },
  { code: "Y.30.003/02", category: "Altyapı", name: "Atıksu logarı (Ø100, prefabrik)", unit: "ad" },
  { code: "Y.30.004/01", category: "Altyapı", name: "Pis su rögarı kapağı (D400)", unit: "ad" },
  { code: "Y.30.004/02", category: "Altyapı", name: "Yağmursuyu rögar kapağı", unit: "ad" },
  { code: "Y.30.005/01", category: "Altyapı", name: "İçme suyu hattı PE100 (Ø32)", unit: "m" },
  { code: "Y.30.005/02", category: "Altyapı", name: "İçme suyu hattı PE100 (Ø63)", unit: "m" },
  { code: "Y.30.005/03", category: "Altyapı", name: "İçme suyu hattı PE100 (Ø110)", unit: "m" },
  { code: "Y.30.005/04", category: "Altyapı", name: "İçme suyu hattı PE100 (Ø200)", unit: "m" },
  { code: "Y.30.006/01", category: "Altyapı", name: "Yangın hidrant (yer üstü)", unit: "ad" },
  { code: "Y.30.007/01", category: "Altyapı", name: "Sayaç odası", unit: "ad" },
  { code: "Y.30.008/01", category: "Altyapı", name: "Septik tank (3 gözlü)", unit: "ad" },
  { code: "Y.30.008/02", category: "Altyapı", name: "Sızdırma kuyusu", unit: "ad" },
  { code: "Y.30.009/01", category: "Altyapı", name: "Doğalgaz hattı (Ø32 PE)", unit: "m" },
  { code: "Y.30.009/02", category: "Altyapı", name: "Doğalgaz vana grubu", unit: "ad" },
  { code: "Y.30.010/01", category: "Altyapı", name: "Trafo binası (prekast)", unit: "ad" },
  { code: "Y.30.010/02", category: "Altyapı", name: "OG-AG kablosu Ø95 mm² (3 fazlı)", unit: "m" },
];

const CELIK: ImalatPoz[] = [
  { code: "Y.22.001/01", category: "Çelik Yapı", name: "Çelik konstrüksiyon imalatı + montaj (HEA)", unit: "ton" },
  { code: "Y.22.001/02", category: "Çelik Yapı", name: "Çelik konstrüksiyon imalatı + montaj (IPE)", unit: "ton" },
  { code: "Y.22.001/03", category: "Çelik Yapı", name: "Çelik konstrüksiyon (kutu profil)", unit: "ton" },
  { code: "Y.22.001/04", category: "Çelik Yapı", name: "Trapez sac taban + beton kompozit döşeme", unit: "m²" },
  { code: "Y.22.002/01", category: "Çelik Yapı", name: "Çelik baz plaka + ankraj", unit: "ad" },
  { code: "Y.22.002/02", category: "Çelik Yapı", name: "Çelik gusset (eklem) plakası", unit: "ad" },
  { code: "Y.22.003/01", category: "Çelik Yapı", name: "Hot-dip galvaniz işlemi", unit: "ton" },
  { code: "Y.22.003/02", category: "Çelik Yapı", name: "Yangın geciktirici boya kaplama", unit: "m²" },
  { code: "Y.22.004/01", category: "Çelik Yapı", name: "Çelik ızgara (geçit, ızgara)", unit: "m²" },
  { code: "Y.22.005/01", category: "Çelik Yapı", name: "Çelik merdiven (servis)", unit: "m" },
  { code: "Y.22.005/02", category: "Çelik Yapı", name: "Çelik döner merdiven", unit: "m" },
  { code: "Y.22.006/01", category: "Çelik Yapı", name: "Çelik korkuluk (boyalı)", unit: "m" },
  { code: "Y.22.007/01", category: "Çelik Yapı", name: "Çelik aşık (Z profil)", unit: "m" },
];

const YIKIM: ImalatPoz[] = [
  { code: "Y.70.001/01", category: "Yıkım ve Söküm", name: "Tuğla duvar yıkımı + nakli", unit: "m³" },
  { code: "Y.70.001/02", category: "Yıkım ve Söküm", name: "Beton blok duvar yıkımı + nakli", unit: "m³" },
  { code: "Y.70.001/03", category: "Yıkım ve Söküm", name: "Alçıpan bölme sökümü", unit: "m²" },
  { code: "Y.70.002/01", category: "Yıkım ve Söküm", name: "Betonarme yapı yıkımı (kontrollü)", unit: "m³" },
  { code: "Y.70.002/02", category: "Yıkım ve Söküm", name: "Çelik yapı sökümü", unit: "ton" },
  { code: "Y.70.002/03", category: "Yıkım ve Söküm", name: "Tarihi yapı kontrollü demontaj", unit: "m³" },
  { code: "Y.70.003/01", category: "Yıkım ve Söküm", name: "Sıva sökümü", unit: "m²" },
  { code: "Y.70.003/02", category: "Yıkım ve Söküm", name: "Boya kazıma", unit: "m²" },
  { code: "Y.70.004/01", category: "Yıkım ve Söküm", name: "Seramik/karo sökümü", unit: "m²" },
  { code: "Y.70.004/02", category: "Yıkım ve Söküm", name: "Şap sökümü", unit: "m²" },
  { code: "Y.70.004/03", category: "Yıkım ve Söküm", name: "Parke sökümü", unit: "m²" },
  { code: "Y.70.004/04", category: "Yıkım ve Söküm", name: "Halı/PVC kaplama sökümü", unit: "m²" },
  { code: "Y.70.005/01", category: "Yıkım ve Söküm", name: "Kapı/pencere sökümü", unit: "ad" },
  { code: "Y.70.005/02", category: "Yıkım ve Söküm", name: "Mutfak/banyo dolap sökümü", unit: "m" },
  { code: "Y.70.006/01", category: "Yıkım ve Söküm", name: "Çatı kaplama sökümü", unit: "m²" },
  { code: "Y.70.006/02", category: "Yıkım ve Söküm", name: "Çatı ahşap konstrüksiyon sökümü", unit: "m³" },
  { code: "Y.70.007/01", category: "Yıkım ve Söküm", name: "Sıhhi tesisat sökümü", unit: "ad" },
  { code: "Y.70.007/02", category: "Yıkım ve Söküm", name: "Mekanik tesisat sökümü", unit: "m" },
  { code: "Y.70.008/01", category: "Yıkım ve Söküm", name: "Elektrik tesisat sökümü", unit: "m²" },
  { code: "Y.70.008/02", category: "Yıkım ve Söküm", name: "Asbest içeren malzeme sökümü", unit: "m²" },
  { code: "Y.70.009/01", category: "Yıkım ve Söküm", name: "Hafriyat naklı (yıkım atığı)", unit: "m³" },
];

export const DEFAULT_IMALAT_POZLARI: ImalatPoz[] = [
  ...HAFRIYAT,
  ...BETON,
  ...DEMIR,
  ...KALIP,
  ...DUVAR,
  ...SIVA,
  ...YALITIM,
  ...CATI,
  ...KAPLAMA,
  ...BOYA,
  ...DOGRAMA,
  ...SIHHI,
  ...ELEKTRIK,
  ...MEKANIK,
  ...ASANSOR,
  ...CEPHE,
  ...CEVRE,
  ...PEYZAJ,
  ...ALTYAPI,
  ...CELIK,
  ...YIKIM,
];

// ====== CSV Import / Export ======

export interface CsvParseResult {
  rows: ImalatPoz[];
  errors: string[];
  duplicates: string[];
}

function splitCsvLine(line: string, sep: string): string[] {
  const out: string[] = [];
  let cur = "";
  let inQ = false;
  for (let i = 0; i < line.length; i++) {
    const ch = line[i];
    if (inQ) {
      if (ch === '"' && line[i + 1] === '"') { cur += '"'; i++; }
      else if (ch === '"') { inQ = false; }
      else { cur += ch; }
    } else {
      if (ch === '"') inQ = true;
      else if (ch === sep) { out.push(cur); cur = ""; }
      else cur += ch;
    }
  }
  out.push(cur);
  return out.map((s) => s.trim());
}

export function parseImalatPozCsv(text: string): CsvParseResult {
  const errors: string[] = [];
  const duplicates: string[] = [];
  const rows: ImalatPoz[] = [];
  const seen = new Set<string>();

  const cleaned = text.replace(/^\uFEFF/, "");
  const allLines = cleaned.split(/\r?\n/).filter((l) => l.trim().length > 0);
  if (allLines.length === 0) return { rows, errors: ["Dosya boş."], duplicates };

  // Auto-detect separator
  const first = allLines[0];
  const sep = (first.includes(";") ? ";" : (first.includes("\t") ? "\t" : ","));

  // Detect header
  let startIdx = 0;
  const lower = first.toLowerCase();
  if (lower.includes("kod") || lower.includes("code")) startIdx = 1;

  for (let i = startIdx; i < allLines.length; i++) {
    const lineNo = i + 1;
    const parts = splitCsvLine(allLines[i], sep);
    const code = (parts[0] || "").trim();
    const category = (parts[1] || "Diğer").trim() || "Diğer";
    const name = (parts[2] || "").trim();
    const unit = (parts[3] || "").trim();
    const description = (parts[4] || "").trim().replace(/\\n/g, "\n");
    if (!code || !name || !unit) {
      errors.push(`Satır ${lineNo}: Kod, ad ve birim zorunlu.`);
      continue;
    }
    const key = code.toLowerCase();
    if (seen.has(key)) {
      duplicates.push(code);
      continue;
    }
    seen.add(key);
    rows.push({ code, category, name, unit, description: description || undefined });
  }

  return { rows, errors, duplicates };
}

export function buildImalatPozCsv(items: ImalatPoz[]): string {
  const esc = (s: string) => {
    if (s.includes(";") || s.includes('"') || s.includes("\n")) {
      return `"${s.replace(/"/g, '""')}"`;
    }
    return s;
  };
  const header = "kod;kategori;ad;birim;tarif";
  const lines = items.map((p) =>
    [p.code, p.category, p.name, p.unit, (p.description || "").replace(/\n/g, "\\n")]
      .map(esc)
      .join(";")
  );
  return "\uFEFF" + [header, ...lines].join("\n");
}

// ================================================================
// İMALAT POZ ANALİZLERİ — Tip Tanımları
// Resmi veri: assets/data/resmi-poz-analizleri.json
// ================================================================

export interface AnalizKalemi {
  id: string;
  tip: "malzeme" | "iscilik" | "ekipman";
  pozNo: string;
  tanim: string;
  olcuBirimi: string;
  miktar: number;
  birimFiyati: number;
  tutar: number;
}

export interface PozAnaliz {
  id: string;
  pozNo: string;
  analizAdi: string;
  olcuBirimi: string;
  kategori: string;
  kalemler: AnalizKalemi[];
  pozTarifi: string;
  yapimSartlari: string;
  olcusu: string;
  malzemeIscilikToplami: number;
  yukleniciKarOrani: number;
  yukleniciKarTutari: number;
  birimFiyati: number;
  olusturmaTarihi: string;
  guncellemeTarihi: string;
  kaynakTip: "sistem" | "kullanici" | "kopya";
  notlar?: string;
}

export function hesaplaAnalizToplam(
  analiz: Pick<PozAnaliz, "kalemler" | "yukleniciKarOrani">
): {
  malzemeIscilikToplami: number;
  yukleniciKarTutari: number;
  birimFiyati: number;
} {
  const toplam = analiz.kalemler.reduce((s, k) => s + (k.tutar || 0), 0);
  const kar = Math.round(toplam * (analiz.yukleniciKarOrani / 100) * 100) / 100;
  return {
    malzemeIscilikToplami: Math.round(toplam * 100) / 100,
    yukleniciKarTutari: kar,
    birimFiyati: Math.round((toplam + kar) * 100) / 100,
  };
}

