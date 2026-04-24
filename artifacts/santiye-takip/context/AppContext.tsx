import AsyncStorage from "@react-native-async-storage/async-storage";
import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useState,
} from "react";

export interface Project {
  id: string;
  name: string;
  location: string;
  contractor: string;
  startDate: string;
  endDate: string;
  budget: number;
  status: "active" | "paused" | "completed";
  progress: number;
  description: string;
}

export interface Worker {
  id: string;
  projectId: string;
  name: string;
  role: string;
  phone: string;
  dailyRate: number;
  status: "active" | "inactive";
}

export interface Attendance {
  id: string;
  projectId: string;
  workerId: string;
  workerName: string;
  date: string;
  status: "present" | "absent" | "half";
  note: string;
}

export interface WorkItem {
  id: string;
  projectId: string;
  name: string;
  unit: string;
  plannedQty: number;
  completedQty: number;
  unitPrice: number;
}

export interface Material {
  id: string;
  projectId: string;
  name: string;
  unit: string;
  quantity: number;
  usedQty: number;
  supplier: string;
  deliveryDate: string;
}

export interface Equipment {
  id: string;
  projectId: string;
  name: string;
  type: string;
  status: "active" | "maintenance" | "idle";
  operator: string;
  dailyCost: number;
}

export interface SafetyCheck {
  id: string;
  projectId: string;
  date: string;
  inspector: string;
  items: SafetyItem[];
  overallStatus: "pass" | "fail" | "partial";
  notes: string;
}

export interface SafetyItem {
  id: string;
  category: string;
  description: string;
  status: "ok" | "issue" | "na";
  note: string;
}

export interface DailyReport {
  id: string;
  projectId: string;
  date: string;
  weather: string;
  temperature: string;
  workerCount: number;
  activities: string;
  issues: string;
  photos: string[];
  createdBy: string;
}

interface AppState {
  projects: Project[];
  workers: Worker[];
  attendance: Attendance[];
  workItems: WorkItem[];
  materials: Material[];
  equipment: Equipment[];
  safetyChecks: SafetyCheck[];
  dailyReports: DailyReport[];
  selectedProjectId: string | null;
}

interface AppContextType extends AppState {
  selectedProject: Project | undefined;
  setSelectedProjectId: (id: string | null) => void;

  addProject: (p: Omit<Project, "id">) => void;
  updateProject: (id: string, p: Partial<Project>) => void;
  deleteProject: (id: string) => void;

  addWorker: (w: Omit<Worker, "id">) => void;
  updateWorker: (id: string, w: Partial<Worker>) => void;
  deleteWorker: (id: string) => void;

  addAttendance: (a: Omit<Attendance, "id">) => void;
  updateAttendance: (id: string, a: Partial<Attendance>) => void;

  addWorkItem: (w: Omit<WorkItem, "id">) => void;
  updateWorkItem: (id: string, w: Partial<WorkItem>) => void;
  deleteWorkItem: (id: string) => void;

  addMaterial: (m: Omit<Material, "id">) => void;
  updateMaterial: (id: string, m: Partial<Material>) => void;
  deleteMaterial: (id: string) => void;

  addEquipment: (e: Omit<Equipment, "id">) => void;
  updateEquipment: (id: string, e: Partial<Equipment>) => void;
  deleteEquipment: (id: string) => void;

  addSafetyCheck: (s: Omit<SafetyCheck, "id">) => void;

  addDailyReport: (r: Omit<DailyReport, "id">) => void;
  updateDailyReport: (id: string, r: Partial<DailyReport>) => void;
}

const AppContext = createContext<AppContextType | undefined>(undefined);

function genId() {
  return Date.now().toString() + Math.random().toString(36).substr(2, 9);
}

const STORAGE_KEY = "santiye_app_data";

const DEFAULT_SAFETY_ITEMS: Omit<SafetyItem, "id">[] = [
  { category: "KKD", description: "Baret takılı mı?", status: "ok", note: "" },
  { category: "KKD", description: "Güvenlik yeleği var mı?", status: "ok", note: "" },
  { category: "KKD", description: "İş ayakkabısı kullanılıyor mu?", status: "ok", note: "" },
  { category: "Saha", description: "Çalışma alanı temiz ve düzenli mi?", status: "ok", note: "" },
  { category: "Saha", description: "İkaz levhaları yerinde mi?", status: "ok", note: "" },
  { category: "Saha", description: "Yangın tüpü erişilebilir mi?", status: "ok", note: "" },
  { category: "Ekipman", description: "İş makineleri kontrol edildi mi?", status: "ok", note: "" },
  { category: "Ekipman", description: "Elektrik bağlantıları güvenli mi?", status: "ok", note: "" },
  { category: "Sağlık", description: "İlk yardım çantası hazır mı?", status: "ok", note: "" },
  { category: "Sağlık", description: "Acil çıkış yolları açık mı?", status: "ok", note: "" },
];

export function createDefaultSafetyItems(): SafetyItem[] {
  return DEFAULT_SAFETY_ITEMS.map((item) => ({ ...item, id: genId() }));
}

export function AppProvider({ children }: { children: React.ReactNode }) {
  const [state, setState] = useState<AppState>({
    projects: [],
    workers: [],
    attendance: [],
    workItems: [],
    materials: [],
    equipment: [],
    safetyChecks: [],
    dailyReports: [],
    selectedProjectId: null,
  });

  useEffect(() => {
    AsyncStorage.getItem(STORAGE_KEY).then((raw) => {
      if (raw) {
        try {
          const parsed = JSON.parse(raw);
          setState((prev) => ({ ...prev, ...parsed }));
        } catch {}
      }
    });
  }, []);

  const persist = useCallback((newState: AppState) => {
    const { selectedProjectId, ...toSave } = newState;
    AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(toSave));
  }, []);

  function update(updater: (prev: AppState) => AppState) {
    setState((prev) => {
      const next = updater(prev);
      persist(next);
      return next;
    });
  }

  const ctx: AppContextType = {
    ...state,
    selectedProject: state.projects.find((p) => p.id === state.selectedProjectId),

    setSelectedProjectId: (id) =>
      setState((prev) => ({ ...prev, selectedProjectId: id })),

    addProject: (p) =>
      update((prev) => ({
        ...prev,
        projects: [...prev.projects, { ...p, id: genId() }],
      })),
    updateProject: (id, p) =>
      update((prev) => ({
        ...prev,
        projects: prev.projects.map((x) => (x.id === id ? { ...x, ...p } : x)),
      })),
    deleteProject: (id) =>
      update((prev) => ({
        ...prev,
        projects: prev.projects.filter((x) => x.id !== id),
        workers: prev.workers.filter((x) => x.projectId !== id),
        attendance: prev.attendance.filter((x) => x.projectId !== id),
        workItems: prev.workItems.filter((x) => x.projectId !== id),
        materials: prev.materials.filter((x) => x.projectId !== id),
        equipment: prev.equipment.filter((x) => x.projectId !== id),
        safetyChecks: prev.safetyChecks.filter((x) => x.projectId !== id),
        dailyReports: prev.dailyReports.filter((x) => x.projectId !== id),
      })),

    addWorker: (w) =>
      update((prev) => ({
        ...prev,
        workers: [...prev.workers, { ...w, id: genId() }],
      })),
    updateWorker: (id, w) =>
      update((prev) => ({
        ...prev,
        workers: prev.workers.map((x) => (x.id === id ? { ...x, ...w } : x)),
      })),
    deleteWorker: (id) =>
      update((prev) => ({
        ...prev,
        workers: prev.workers.filter((x) => x.id !== id),
      })),

    addAttendance: (a) =>
      update((prev) => ({
        ...prev,
        attendance: [...prev.attendance, { ...a, id: genId() }],
      })),
    updateAttendance: (id, a) =>
      update((prev) => ({
        ...prev,
        attendance: prev.attendance.map((x) => (x.id === id ? { ...x, ...a } : x)),
      })),

    addWorkItem: (w) =>
      update((prev) => ({
        ...prev,
        workItems: [...prev.workItems, { ...w, id: genId() }],
      })),
    updateWorkItem: (id, w) =>
      update((prev) => ({
        ...prev,
        workItems: prev.workItems.map((x) => (x.id === id ? { ...x, ...w } : x)),
      })),
    deleteWorkItem: (id) =>
      update((prev) => ({
        ...prev,
        workItems: prev.workItems.filter((x) => x.id !== id),
      })),

    addMaterial: (m) =>
      update((prev) => ({
        ...prev,
        materials: [...prev.materials, { ...m, id: genId() }],
      })),
    updateMaterial: (id, m) =>
      update((prev) => ({
        ...prev,
        materials: prev.materials.map((x) => (x.id === id ? { ...x, ...m } : x)),
      })),
    deleteMaterial: (id) =>
      update((prev) => ({
        ...prev,
        materials: prev.materials.filter((x) => x.id !== id),
      })),

    addEquipment: (e) =>
      update((prev) => ({
        ...prev,
        equipment: [...prev.equipment, { ...e, id: genId() }],
      })),
    updateEquipment: (id, e) =>
      update((prev) => ({
        ...prev,
        equipment: prev.equipment.map((x) => (x.id === id ? { ...x, ...e } : x)),
      })),
    deleteEquipment: (id) =>
      update((prev) => ({
        ...prev,
        equipment: prev.equipment.filter((x) => x.id !== id),
      })),

    addSafetyCheck: (s) =>
      update((prev) => ({
        ...prev,
        safetyChecks: [...prev.safetyChecks, { ...s, id: genId() }],
      })),

    addDailyReport: (r) =>
      update((prev) => ({
        ...prev,
        dailyReports: [...prev.dailyReports, { ...r, id: genId() }],
      })),
    updateDailyReport: (id, r) =>
      update((prev) => ({
        ...prev,
        dailyReports: prev.dailyReports.map((x) => (x.id === id ? { ...x, ...r } : x)),
      })),
  };

  return <AppContext.Provider value={ctx}>{children}</AppContext.Provider>;
}

export function useApp() {
  const ctx = useContext(AppContext);
  if (!ctx) throw new Error("useApp must be used within AppProvider");
  return ctx;
}
