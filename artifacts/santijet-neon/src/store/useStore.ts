import { create } from 'zustand';
import { 
  initialPuantaj, 
  initialMalzeme, 
  initialSevkiyat, 
  initialSatinAlma, 
  initialImalat, 
  initialKantar,
  initialActivities
} from '@/data/mock-data';

interface AppState {
  puantaj: any[];
  malzeme: any[];
  sevkiyat: any[];
  satinAlma: any[];
  imalat: any[];
  kantar: any[];
  activities: any[];
  
  addPuantaj: (data: any) => void;
  addMalzeme: (data: any) => void;
  updateMalzeme: (id: string, data: any) => void;
  addSevkiyat: (data: any) => void;
  updateSevkiyatStatus: (id: string, status: string) => void;
  addSatinAlma: (data: any) => void;
  addImalat: (data: any) => void;
  updateImalatProgress: (id: string, progress: number) => void;
  addKantar: (data: any) => void;
  addActivity: (msg: string, type: 'info' | 'warning' | 'success' | 'error') => void;
}

export const useStore = create<AppState>((set) => ({
  puantaj: initialPuantaj,
  malzeme: initialMalzeme,
  sevkiyat: initialSevkiyat,
  satinAlma: initialSatinAlma,
  imalat: initialImalat,
  kantar: initialKantar,
  activities: initialActivities,

  addPuantaj: (data) => set((state) => {
    const newData = { ...data, id: Date.now().toString() };
    return { puantaj: [newData, ...state.puantaj] };
  }),
  addMalzeme: (data) => set((state) => {
    const newData = { ...data, id: Date.now().toString() };
    return { malzeme: [newData, ...state.malzeme] };
  }),
  updateMalzeme: (id, data) => set((state) => ({
    malzeme: state.malzeme.map(item => item.id === id ? { ...item, ...data } : item)
  })),
  addSevkiyat: (data) => set((state) => {
    const newData = { ...data, id: Date.now().toString() };
    return { sevkiyat: [newData, ...state.sevkiyat] };
  }),
  updateSevkiyatStatus: (id, status) => set((state) => ({
    sevkiyat: state.sevkiyat.map(item => item.id === id ? { ...item, durum: status } : item)
  })),
  addSatinAlma: (data) => set((state) => {
    const newData = { ...data, id: Date.now().toString() };
    return { satinAlma: [newData, ...state.satinAlma] };
  }),
  addImalat: (data) => set((state) => {
    const newData = { ...data, id: Date.now().toString() };
    return { imalat: [newData, ...state.imalat] };
  }),
  updateImalatProgress: (id, progress) => set((state) => ({
    imalat: state.imalat.map(item => item.id === id ? { ...item, ilerleme: progress } : item)
  })),
  addKantar: (data) => set((state) => {
    const newData = { ...data, id: Date.now().toString() };
    return { kantar: [newData, ...state.kantar] };
  }),
  addActivity: (msg, type) => set((state) => {
    const newActivity = {
      id: Date.now().toString(),
      time: new Date().toLocaleTimeString('tr-TR', { hour12: false }),
      msg,
      type
    };
    return { activities: [newActivity, ...state.activities].slice(0, 50) };
  }),
}));
