export const modules = [
  { id: "puantaj", name: "PUANTAJ", path: "/puantaj", color: "#22d3ee", code: "0x01", icon: "Users" },
  { id: "malzeme", name: "MALZEME", path: "/malzeme", color: "#a78bfa", code: "0x02", icon: "Package" },
  { id: "sevkiyat", name: "SEVKİYAT", path: "/sevkiyat", color: "#34d399", code: "0x03", icon: "Truck" },
  { id: "satin-alma", name: "SATIN ALMA", path: "/satin-alma", color: "#f472b6", code: "0x04", icon: "ShoppingCart" },
  { id: "imalat", name: "İMALAT", path: "/imalat", color: "#fb923c", code: "0x05", icon: "Hammer" },
  { id: "kantar", name: "KANTAR", path: "/kantar", color: "#facc15", code: "0x06", icon: "Scale" },
];

let _seed = 1337;
const rand = () => {
  _seed = (_seed * 9301 + 49297) % 233280;
  return _seed / 233280;
};
const pick = <T>(arr: T[]) => arr[Math.floor(rand() * arr.length)];
const intBetween = (a: number, b: number) => a + Math.floor(rand() * (b - a + 1));
const pad = (n: number, w = 2) => String(n).padStart(w, "0");

const adlar = ["Ahmet", "Mehmet", "Ali", "Mustafa", "Hasan", "Hüseyin", "İbrahim", "Murat", "Emre", "Cem", "Kadir", "Yusuf", "Osman", "Ramazan", "Serkan", "Tolga", "Bekir", "Cihan", "Deniz", "Erkan", "Furkan", "Gökhan", "Hakan", "İlker", "Kerem", "Levent", "Onur", "Selim", "Tayfun", "Volkan"];
const soyadlar = ["Yılmaz", "Demir", "Kaya", "Şahin", "Çelik", "Yıldız", "Yıldırım", "Öztürk", "Aydın", "Özdemir", "Arslan", "Doğan", "Kılıç", "Aslan", "Çetin", "Kara", "Koç", "Kurt", "Özkan", "Şimşek"];
const firmalar = ["Aktepe Taşeron", "Net Elektrik", "Mekanik Tesisat A.Ş.", "Yılmaz İnşaat", "Demirtaş Yapı", "Kaya Hafriyat", "Öz Demir", "Kalıp Pro", "Sıva Ustası", "Boya Sanat"];
const gorevler = ["Demirci", "Kalıpçı", "Betoncu", "Elektrikçi", "Sıhhi Tesisatçı", "Boyacı", "Kaynakçı", "Operatör", "Düz İşçi", "Formen", "Şantiye Şefi", "Sıvacı", "Fayansçı"];

export const initialPuantaj = Array.from({ length: 47 }, (_, i) => {
  const girisH = intBetween(7, 8);
  const girisM = pick([0, 15, 30, 45]);
  const cikisH = intBetween(17, 19);
  const cikisM = pick([0, 15, 30, 45]);
  const mesaiSaat = Math.max(0, (cikisH + cikisM / 60) - (girisH + girisM / 60) - 9);
  return {
    id: `p-${i + 1}`,
    ad: `${pick(adlar)} ${pick(soyadlar)}`,
    firma: pick(firmalar),
    gorev: pick(gorevler),
    giris: `${pad(girisH)}:${pad(girisM)}`,
    cikis: `${pad(cikisH)}:${pad(cikisM)}`,
    mesai: mesaiSaat.toFixed(1),
  };
});

const malzemeAdlari = [
  ["Demir", "kg", "Ana Depo"], ["Çimento", "torba", "Depo B"], ["Kum", "ton", "Hafriyat"],
  ["Çakıl", "ton", "Hafriyat"], ["Tuğla", "adet", "Ana Depo"], ["Bims", "adet", "Ana Depo"],
  ["Alçı", "torba", "Depo B"], ["Boya", "kg", "İnce İş Depo"], ["Kablo", "m", "Elektrik Depo"],
  ["PVC Boru", "m", "Tesisat Depo"], ["Galvaniz Boru", "m", "Tesisat Depo"],
  ["Vida", "adet", "Sarf Depo"], ["Çivi", "kg", "Sarf Depo"], ["Sıva", "torba", "Depo B"],
  ["Fayans", "m²", "İnce İş Depo"], ["Seramik", "m²", "İnce İş Depo"],
  ["Mermer", "m²", "İnce İş Depo"], ["Kapı", "adet", "İnce İş Depo"],
  ["Pencere", "adet", "İnce İş Depo"], ["İzolasyon Levha", "adet", "Yalıtım Depo"],
];
const olcuVarianti = ["6'lık", "8'lik", "10'luk", "12'lik", "14'lük", "16'lık", "20'lik", "Q8", "Q10", "Q12"];

export const initialMalzeme = Array.from({ length: 184 }, (_, i) => {
  const [adBase, birim, depo] = pick(malzemeAdlari);
  const ad = rand() > 0.4 ? `${adBase} ${pick(olcuVarianti)}` : (adBase as string);
  const min = intBetween(50, 1500);
  const stok = intBetween(0, 4000);
  return {
    id: `m-${i + 1}`,
    kod: `M-${pad(i + 1, 4)}`,
    ad,
    depo: depo as string,
    stok,
    min,
    birim: birim as string,
  };
});

const plakalar = ["34 ABC 123", "06 XYZ 987", "34 DD 444", "06 AA 111", "35 KK 256", "16 BR 770", "41 PT 091", "07 GR 333", "01 AS 482", "33 TR 615"];
const soforler = ["Hasan Usta", "Kemal Bey", "Recep Çıkın", "Murat Dağ", "İsmail Tek", "Bahri Demirel", "Şükrü Ayaz", "Ergün Kılıç"];
const sevkHedef = ["A Blok", "B Blok", "C Blok", "D Blok", "Ana Depo", "Şantiye Sahası", "Depo B"];
const sevkIcerik = ["Hazır Beton", "Demir", "Çimento", "Tuğla", "Kum", "Çakıl", "İskele", "Kalıp Malzemesi"];
const sevkDurum = ["Hazırlanıyor", "Yolda", "Teslim Edildi", "İptal"];

export const initialSevkiyat = Array.from({ length: 9 }, (_, i) => ({
  id: `s-${i + 1}`,
  plaka: pick(plakalar),
  sofor: pick(soforler),
  hedef: pick(sevkHedef),
  tarih: `2026-05-${pad(intBetween(1, 3))}`,
  icerik: pick(sevkIcerik),
  durum: pick(sevkDurum),
}));

const tedarikciler = ["Demirtaş A.Ş.", "Betonsan", "Akçansa", "Borusan Mannesmann", "Eczacıbaşı Yapı", "Çimsa", "Kalekim", "Şişecam", "Yalıtım A.Ş.", "Sika Türkiye", "Türk Demir Döküm"];
const poDurum = ["Taslak", "Onay Bekliyor", "Onaylandı", "Tamamlandı"];

export const initialSatinAlma = Array.from({ length: 23 }, (_, i) => ({
  id: `po-${i + 1}`,
  poNo: `PO-2026-${pad(i + 1, 3)}`,
  tedarikci: pick(tedarikciler),
  kalemSayisi: intBetween(1, 12),
  tutar: intBetween(15, 850) * 1000,
  durum: pick(poDurum),
}));

const bloklar = ["A Blok", "B Blok", "C Blok", "D Blok", "E Blok"];
const katlar = ["Bodrum", "Zemin", "1. Kat", "2. Kat", "3. Kat", "4. Kat", "5. Kat", "6. Kat", "Çatı"];
const imalatTipleri = ["Kolon Beton", "Perde Beton", "Döşeme Beton", "Duvar Örümü", "Sıva", "Şap", "Kaba Sıhhi Tesisat", "İnce Sıhhi Tesisat", "Elektrik Tesisat", "Boya", "Fayans", "Seramik", "Mermer", "Kapı Montaj"];

export const initialImalat = Array.from({ length: 56 }, (_, i) => ({
  id: `ie-${i + 1}`,
  isEmri: `IE-${pad(i + 1, 4)}`,
  blok: pick(bloklar),
  kat: pick(katlar),
  imalatTipi: pick(imalatTipleri),
  ilerleme: intBetween(0, 100),
}));

const kantarMalzemeleri = ["Hafriyat", "Mıcır", "Kum", "Çakıl", "Demir Hurdası", "Atık", "Hazır Beton", "Toprak"];

export const initialKantar = Array.from({ length: 312 }, (_, i) => {
  const dara = intBetween(80, 160) / 10;
  const brut = dara + intBetween(80, 280) / 10;
  return {
    id: `k-${i + 1}`,
    fisNo: `K-${pad(1000 + i, 4)}`,
    plaka: pick(plakalar),
    malzeme: pick(kantarMalzemeleri),
    dara: parseFloat(dara.toFixed(1)),
    brut: parseFloat(brut.toFixed(1)),
    net: parseFloat((brut - dara).toFixed(1)),
    tarih: `${pad(intBetween(7, 18))}:${pad(intBetween(0, 59))}`,
  };
});

export const initialActivities = [
  { id: "a-1", time: "11:45:02", msg: "A Blok kolon betonu dökümü başladı.", type: "info" as const },
  { id: "a-2", time: "11:30:15", msg: "Kantar fişi K-1002 oluşturuldu.", type: "success" as const },
  { id: "a-3", time: "11:15:00", msg: "Çimento stoğu kritik seviyenin altında.", type: "warning" as const },
  { id: "a-4", time: "10:45:33", msg: "Yeni puantaj kaydı eklendi (Ahmet Yılmaz).", type: "info" as const },
  { id: "a-5", time: "10:10:12", msg: "34 ABC 123 plakalı araç şantiyeye giriş yaptı.", type: "info" as const },
  { id: "a-6", time: "09:55:01", msg: "PO-2026-018 onay bekliyor.", type: "warning" as const },
  { id: "a-7", time: "09:42:24", msg: "B Blok 2. Kat sıva ilerlemesi %75.", type: "info" as const },
  { id: "a-8", time: "09:21:09", msg: "IE-0023 iş emri tamamlandı.", type: "success" as const },
  { id: "a-9", time: "08:58:47", msg: "Yeni sevkiyat oluşturuldu (Hazır Beton).", type: "info" as const },
  { id: "a-10", time: "08:30:00", msg: "Sabah vardiyası başladı.", type: "info" as const },
  { id: "a-11", time: "08:12:18", msg: "Demir 14'lük stok girişi yapıldı.", type: "success" as const },
  { id: "a-12", time: "07:45:00", msg: "Sistem senkronizasyonu tamamlandı.", type: "success" as const },
];
