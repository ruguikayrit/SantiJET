export const modules = [
  { id: "puantaj", name: "PUANTAJ", path: "/puantaj", color: "#22d3ee", code: "0x01", icon: "Users" },
  { id: "malzeme", name: "MALZEME", path: "/malzeme", color: "#a78bfa", code: "0x02", icon: "Package" },
  { id: "sevkiyat", name: "SEVKİYAT", path: "/sevkiyat", color: "#34d399", code: "0x03", icon: "Truck" },
  { id: "satin-alma", name: "SATIN ALMA", path: "/satin-alma", color: "#f472b6", code: "0x04", icon: "ShoppingCart" },
  { id: "imalat", name: "İMALAT", path: "/imalat", color: "#fb923c", code: "0x05", icon: "Hammer" },
  { id: "kantar", name: "KANTAR", path: "/kantar", color: "#facc15", code: "0x06", icon: "Scale" },
];

export const initialPuantaj = [
  { id: "1", ad: "Ahmet Yılmaz", firma: "Aktepe Taşeron", gorev: "Demirci", giris: "07:30", cikis: "18:00", mesai: "1.5" },
  { id: "2", ad: "Mehmet Demir", firma: "Aktepe Taşeron", gorev: "Kalıpçı", giris: "07:45", cikis: "17:30", mesai: "0" },
  { id: "3", ad: "Ali Kaya", firma: "Net Elektrik", gorev: "Elektrikçi", giris: "08:00", cikis: "19:00", mesai: "2" },
];

export const initialMalzeme = [
  { id: "1", kod: "M-01", ad: "Demir 14'lük", depo: "Ana Depo", stok: 15000, min: 2000, birim: "kg" },
  { id: "2", kod: "M-02", ad: "Çimento", depo: "Depo B", stok: 450, min: 500, birim: "torba" },
  { id: "3", kod: "M-03", ad: "Kablo 3x2.5", depo: "Elektrik Depo", stok: 1200, min: 300, birim: "m" },
];

export const initialSevkiyat = [
  { id: "1", plaka: "34 ABC 123", sofor: "Hasan Usta", hedef: "A Blok", tarih: "2023-10-25", icerik: "Hazır Beton", durum: "Yolda" },
  { id: "2", plaka: "06 XYZ 987", sofor: "Kemal Bey", hedef: "Ana Depo", tarih: "2023-10-25", icerik: "Demir", durum: "Teslim Edildi" },
];

export const initialSatinAlma = [
  { id: "1", poNo: "PO-2023-001", tedarikci: "Demirtaş A.Ş.", kalemSayisi: 3, tutar: 150000, durum: "Onaylandı" },
  { id: "2", poNo: "PO-2023-002", tedarikci: "Betonsan", kalemSayisi: 1, tutar: 45000, durum: "Bekliyor" },
];

export const initialImalat = [
  { id: "1", isEmri: "IE-001", blok: "A Blok", kat: "Zemin", imalatTipi: "Kolon Beton", ilerleme: 85 },
  { id: "2", isEmri: "IE-002", blok: "B Blok", kat: "1. Kat", imalatTipi: "Duvar Örümü", ilerleme: 30 },
];

export const initialKantar = [
  { id: "1", fisNo: "K-1001", plaka: "34 DD 444", malzeme: "Hafriyat", dara: 12.5, brut: 35.0, net: 22.5, tarih: "10:15" },
  { id: "2", fisNo: "K-1002", plaka: "06 AA 111", malzeme: "Mıcır", dara: 11.0, brut: 30.5, net: 19.5, tarih: "11:30" },
];

export const initialActivities = [
  { id: "1", time: "11:45:02", msg: "A Blok kolon betonu dökümü başladı.", type: "info" },
  { id: "2", time: "11:30:15", msg: "Kantar fişi K-1002 oluşturuldu.", type: "success" },
  { id: "3", time: "11:15:00", msg: "Çimento stoğu kritik seviyenin altında!", type: "warning" },
  { id: "4", time: "10:45:33", msg: "Yeni puantaj kaydı eklendi (Ahmet Yılmaz).", type: "info" },
  { id: "5", time: "10:10:12", msg: "34 ABC 123 plakalı araç şantiyeye giriş yaptı.", type: "info" },
];
