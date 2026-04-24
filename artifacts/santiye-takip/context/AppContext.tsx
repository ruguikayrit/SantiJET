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
  description: string;
}

export interface SurveyItem {
  id: string;
  description: string;
  unit: string;
  quantity: number;
  unitPrice: number;
}

export interface Survey {
  id: string;
  projectId: string;
  title: string;
  date: string;
  location: string;
  notes: string;
  items: SurveyItem[];
}

export interface ScheduleTask {
  id: string;
  projectId: string;
  name: string;
  startDate: string;
  endDate: string;
  progress: number;
  status: "planned" | "in_progress" | "completed" | "delayed";
  responsible: string;
}

export interface Worker {
  id: string;
  projectId: string;
  name: string;
  role: string;
  phone: string;
  dailyRate: number;
}

export interface Attendance {
  id: string;
  projectId: string;
  workerId: string;
  workerName: string;
  date: string;
  status: "present" | "absent" | "half";
  hours: number;
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
  createdBy: string;
}

export interface Production {
  id: string;
  projectId: string;
  name: string;
  unit: string;
  plannedQty: number;
  completedQty: number;
  unitPrice: number;
  date: string;
}

export interface Task {
  id: string;
  projectId: string;
  title: string;
  description: string;
  assignee: string;
  deadline: string;
  priority: "low" | "medium" | "high";
  status: "open" | "in_progress" | "done";
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
  unitPrice: number;
}

export interface BudgetEntry {
  id: string;
  projectId: string;
  type: "income" | "expense";
  category: string;
  description: string;
  amount: number;
  date: string;
}

export interface HakedisItem {
  id: string;
  description: string;
  unit: string;
  quantity: number;
  unitPrice: number;
}

export interface Hakedis {
  id: string;
  projectId: string;
  number: string;
  date: string;
  period: string;
  contractor: string;
  status: "draft" | "submitted" | "approved" | "paid";
  notes: string;
  items: HakedisItem[];
}

interface AppState {
  projects: Project[];
  surveys: Survey[];
  scheduleTasks: ScheduleTask[];
  workers: Worker[];
  attendance: Attendance[];
  dailyReports: DailyReport[];
  productions: Production[];
  tasks: Task[];
  materials: Material[];
  budget: BudgetEntry[];
  hakedisler: Hakedis[];
}

interface AppContextType extends AppState {
  addProject: (p: Omit<Project, "id">) => string;
  updateProject: (id: string, p: Partial<Project>) => void;
  deleteProject: (id: string) => void;

  addSurvey: (s: Omit<Survey, "id">) => void;
  updateSurvey: (id: string, s: Partial<Survey>) => void;
  deleteSurvey: (id: string) => void;

  addScheduleTask: (t: Omit<ScheduleTask, "id">) => void;
  updateScheduleTask: (id: string, t: Partial<ScheduleTask>) => void;
  deleteScheduleTask: (id: string) => void;

  addWorker: (w: Omit<Worker, "id">) => void;
  updateWorker: (id: string, w: Partial<Worker>) => void;
  deleteWorker: (id: string) => void;

  addAttendance: (a: Omit<Attendance, "id">) => void;
  updateAttendance: (id: string, a: Partial<Attendance>) => void;
  deleteAttendance: (id: string) => void;

  addDailyReport: (r: Omit<DailyReport, "id">) => void;
  updateDailyReport: (id: string, r: Partial<DailyReport>) => void;
  deleteDailyReport: (id: string) => void;

  addProduction: (p: Omit<Production, "id">) => void;
  updateProduction: (id: string, p: Partial<Production>) => void;
  deleteProduction: (id: string) => void;

  addTask: (t: Omit<Task, "id">) => void;
  updateTask: (id: string, t: Partial<Task>) => void;
  deleteTask: (id: string) => void;

  addMaterial: (m: Omit<Material, "id">) => void;
  updateMaterial: (id: string, m: Partial<Material>) => void;
  deleteMaterial: (id: string) => void;

  addBudget: (b: Omit<BudgetEntry, "id">) => void;
  updateBudget: (id: string, b: Partial<BudgetEntry>) => void;
  deleteBudget: (id: string) => void;

  addHakedis: (h: Omit<Hakedis, "id">) => void;
  updateHakedis: (id: string, h: Partial<Hakedis>) => void;
  deleteHakedis: (id: string) => void;
}

const AppContext = createContext<AppContextType | undefined>(undefined);

function genId() {
  return Date.now().toString() + Math.random().toString(36).substr(2, 9);
}

const STORAGE_KEY = "santiye_app_data_v2";
const LEGACY_KEY = "santiye_app_data";

const INITIAL: AppState = {
  projects: [],
  surveys: [],
  scheduleTasks: [],
  workers: [],
  attendance: [],
  dailyReports: [],
  productions: [],
  tasks: [],
  materials: [],
  budget: [],
  hakedisler: [],
};

async function loadInitialState(): Promise<AppState> {
  const raw = await AsyncStorage.getItem(STORAGE_KEY);
  if (raw) {
    try {
      return { ...INITIAL, ...JSON.parse(raw) };
    } catch {
      return INITIAL;
    }
  }

  const legacy = await AsyncStorage.getItem(LEGACY_KEY);
  if (legacy) {
    try {
      const old = JSON.parse(legacy);
      const migrated: AppState = {
        ...INITIAL,
        projects: Array.isArray(old.projects) ? old.projects : [],
        workers: Array.isArray(old.workers) ? old.workers : [],
        attendance: Array.isArray(old.attendance)
          ? old.attendance.map((a: any) => ({
              hours: a.status === "present" ? 8 : a.status === "half" ? 4 : 0,
              ...a,
            }))
          : [],
        materials: Array.isArray(old.materials)
          ? old.materials.map((m: any) => ({ unitPrice: 0, ...m }))
          : [],
        dailyReports: Array.isArray(old.dailyReports)
          ? old.dailyReports.map((r: any) => {
              const { photos, ...rest } = r || {};
              return rest;
            })
          : [],
        productions: Array.isArray(old.workItems)
          ? old.workItems.map((w: any) => ({ date: "", ...w }))
          : [],
      };
      await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(migrated));
      return migrated;
    } catch {}
  }

  return INITIAL;
}

export function AppProvider({ children }: { children: React.ReactNode }) {
  const [state, setState] = useState<AppState>(INITIAL);
  const [loaded, setLoaded] = useState(false);

  useEffect(() => {
    loadInitialState().then((s) => {
      setState(s);
      setLoaded(true);
    });
  }, []);

  const persist = useCallback((newState: AppState) => {
    AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(newState));
  }, []);

  useEffect(() => {
    if (loaded) persist(state);
  }, [state, loaded, persist]);

  function update(updater: (prev: AppState) => AppState) {
    setState((prev) => updater(prev));
  }

  function makeAdd<K extends keyof AppState>(key: K) {
    return (item: any) => {
      const id = genId();
      update((prev) => ({
        ...prev,
        [key]: [...(prev[key] as any[]), { ...item, id }],
      }));
      return id;
    };
  }

  function makeUpdate<K extends keyof AppState>(key: K) {
    return (id: string, patch: any) =>
      update((prev) => ({
        ...prev,
        [key]: (prev[key] as any[]).map((x) =>
          x.id === id ? { ...x, ...patch } : x
        ),
      }));
  }

  function makeDelete<K extends keyof AppState>(key: K) {
    return (id: string) =>
      update((prev) => ({
        ...prev,
        [key]: (prev[key] as any[]).filter((x) => x.id !== id),
      }));
  }

  const ctx: AppContextType = {
    ...state,

    addProject: makeAdd("projects") as any,
    updateProject: makeUpdate("projects") as any,
    deleteProject: (id) =>
      update((prev) => ({
        projects: prev.projects.filter((x) => x.id !== id),
        surveys: prev.surveys.filter((x) => x.projectId !== id),
        scheduleTasks: prev.scheduleTasks.filter((x) => x.projectId !== id),
        workers: prev.workers.filter((x) => x.projectId !== id),
        attendance: prev.attendance.filter((x) => x.projectId !== id),
        dailyReports: prev.dailyReports.filter((x) => x.projectId !== id),
        productions: prev.productions.filter((x) => x.projectId !== id),
        tasks: prev.tasks.filter((x) => x.projectId !== id),
        materials: prev.materials.filter((x) => x.projectId !== id),
        budget: prev.budget.filter((x) => x.projectId !== id),
        hakedisler: prev.hakedisler.filter((x) => x.projectId !== id),
      })),

    addSurvey: makeAdd("surveys") as any,
    updateSurvey: makeUpdate("surveys") as any,
    deleteSurvey: makeDelete("surveys") as any,

    addScheduleTask: makeAdd("scheduleTasks") as any,
    updateScheduleTask: makeUpdate("scheduleTasks") as any,
    deleteScheduleTask: makeDelete("scheduleTasks") as any,

    addWorker: makeAdd("workers") as any,
    updateWorker: makeUpdate("workers") as any,
    deleteWorker: makeDelete("workers") as any,

    addAttendance: makeAdd("attendance") as any,
    updateAttendance: makeUpdate("attendance") as any,
    deleteAttendance: makeDelete("attendance") as any,

    addDailyReport: makeAdd("dailyReports") as any,
    updateDailyReport: makeUpdate("dailyReports") as any,
    deleteDailyReport: makeDelete("dailyReports") as any,

    addProduction: makeAdd("productions") as any,
    updateProduction: makeUpdate("productions") as any,
    deleteProduction: makeDelete("productions") as any,

    addTask: makeAdd("tasks") as any,
    updateTask: makeUpdate("tasks") as any,
    deleteTask: makeDelete("tasks") as any,

    addMaterial: makeAdd("materials") as any,
    updateMaterial: makeUpdate("materials") as any,
    deleteMaterial: makeDelete("materials") as any,

    addBudget: makeAdd("budget") as any,
    updateBudget: makeUpdate("budget") as any,
    deleteBudget: makeDelete("budget") as any,

    addHakedis: makeAdd("hakedisler") as any,
    updateHakedis: makeUpdate("hakedisler") as any,
    deleteHakedis: makeDelete("hakedisler") as any,
  };

  return <AppContext.Provider value={ctx}>{children}</AppContext.Provider>;
}

export function useApp() {
  const ctx = useContext(AppContext);
  if (!ctx) throw new Error("useApp must be used within AppProvider");
  return ctx;
}
