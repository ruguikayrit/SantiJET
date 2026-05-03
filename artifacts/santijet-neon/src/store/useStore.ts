import { create } from 'zustand';
import {
  initialPuantaj,
  initialMalzeme,
  initialSevkiyat,
  initialSatinAlma,
  initialImalat,
  initialKantar,
  initialActivities,
} from '@/data/mock-data';

export type Puantaj = {
  id: string;
  ad: string;
  firma: string;
  gorev: string;
  giris: string;
  cikis: string;
  mesai: string;
};

export type Malzeme = {
  id: string;
  kod: string;
  ad: string;
  depo: string;
  stok: number;
  min: number;
  birim: string;
};

export type SevkiyatDurum = 'Hazırlanıyor' | 'Yolda' | 'Teslim Edildi' | 'İptal';

export type Sevkiyat = {
  id: string;
  plaka: string;
  sofor: string;
  hedef: string;
  tarih: string;
  icerik: string;
  durum: SevkiyatDurum | string;
};

export type SatinAlmaDurum = 'Taslak' | 'Onay Bekliyor' | 'Onaylandı' | 'Tamamlandı';

export type SatinAlma = {
  id: string;
  poNo: string;
  tedarikci: string;
  kalemSayisi: number;
  tutar: number;
  durum: SatinAlmaDurum | string;
};

export type Imalat = {
  id: string;
  isEmri: string;
  blok: string;
  kat: string;
  imalatTipi: string;
  ilerleme: number;
};

export type Kantar = {
  id: string;
  fisNo: string;
  plaka: string;
  malzeme: string;
  dara: number;
  brut: number;
  net: number;
  tarih: string;
};

export type ActivityType = 'info' | 'warning' | 'success' | 'error';

export type Activity = {
  id: string;
  time: string;
  msg: string;
  type: ActivityType;
};

interface AppState {
  puantaj: Puantaj[];
  malzeme: Malzeme[];
  sevkiyat: Sevkiyat[];
  satinAlma: SatinAlma[];
  imalat: Imalat[];
  kantar: Kantar[];
  activities: Activity[];

  addPuantaj: (data: Omit<Puantaj, 'id'>) => void;
  addMalzeme: (data: Omit<Malzeme, 'id'>) => void;
  updateMalzeme: (id: string, data: Partial<Malzeme>) => void;
  addSevkiyat: (data: Omit<Sevkiyat, 'id'>) => void;
  updateSevkiyatStatus: (id: string, status: string) => void;
  addSatinAlma: (data: Omit<SatinAlma, 'id'>) => void;
  addImalat: (data: Omit<Imalat, 'id'>) => void;
  updateImalatProgress: (id: string, progress: number) => void;
  addKantar: (data: Omit<Kantar, 'id'>) => void;
  addActivity: (msg: string, type: ActivityType) => void;
}

export const useStore = create<AppState>((set) => ({
  puantaj: initialPuantaj as Puantaj[],
  malzeme: initialMalzeme as Malzeme[],
  sevkiyat: initialSevkiyat as Sevkiyat[],
  satinAlma: initialSatinAlma as SatinAlma[],
  imalat: initialImalat as Imalat[],
  kantar: initialKantar as Kantar[],
  activities: initialActivities as Activity[],

  addPuantaj: (data) => set((state) => ({
    puantaj: [{ ...data, id: `p-${Date.now()}` }, ...state.puantaj],
  })),
  addMalzeme: (data) => set((state) => ({
    malzeme: [{ ...data, id: `m-${Date.now()}` }, ...state.malzeme],
  })),
  updateMalzeme: (id, data) => set((state) => ({
    malzeme: state.malzeme.map((item) => (item.id === id ? { ...item, ...data } : item)),
  })),
  addSevkiyat: (data) => set((state) => ({
    sevkiyat: [{ ...data, id: `s-${Date.now()}` }, ...state.sevkiyat],
  })),
  updateSevkiyatStatus: (id, status) => set((state) => ({
    sevkiyat: state.sevkiyat.map((item) => (item.id === id ? { ...item, durum: status } : item)),
  })),
  addSatinAlma: (data) => set((state) => ({
    satinAlma: [{ ...data, id: `po-${Date.now()}` }, ...state.satinAlma],
  })),
  addImalat: (data) => set((state) => ({
    imalat: [{ ...data, id: `ie-${Date.now()}` }, ...state.imalat],
  })),
  updateImalatProgress: (id, progress) => set((state) => ({
    imalat: state.imalat.map((item) => (item.id === id ? { ...item, ilerleme: progress } : item)),
  })),
  addKantar: (data) => set((state) => ({
    kantar: [{ ...data, id: `k-${Date.now()}` }, ...state.kantar],
  })),
  addActivity: (msg, type) => set((state) => {
    const newActivity: Activity = {
      id: `a-${Date.now()}`,
      time: new Date().toLocaleTimeString('tr-TR', { hour12: false }),
      msg,
      type,
    };
    return { activities: [newActivity, ...state.activities].slice(0, 50) };
  }),
}));
