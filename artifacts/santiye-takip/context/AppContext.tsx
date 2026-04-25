import AsyncStorage from "@react-native-async-storage/async-storage";
import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useState,
} from "react";
import { WorkspaceInfo, loadWorkspace, saveWorkspace, clearWorkspace } from "@/utils/workspace";

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
  company: string;
}

export interface Attendance {
  id: string;
  projectId: string;
  workerId: string;
  workerName: string;
  date: string;
  status: "present" | "absent" | "half" | "izinli" | "raporlu" | "mazeret" | "tatil";
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

export interface MaterialRequest {
  id: string;
  projectId: string;
  name: string;
  unit: string;
  quantity: number;
  requestDate: string;
  requestedBy: string;
  status: "pending" | "approved" | "delivered" | "rejected";
  note: string;
}

export interface Subcontractor {
  id: string;
  projectId: string;
  name: string;
  contactPerson: string;
  phone: string;
  email: string;
  specialty: string;
  contractAmount: number;
  startDate: string;
  endDate: string;
  status: "active" | "completed" | "cancelled";
  notes: string;
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

export type Permission = "none" | "view" | "edit";

export const ALL_PAGE_KEYS = [
  "proje",
  "kesif",
  "is-programi",
  "puantaj",
  "gunluk-rapor",
  "imalat",
  "gorev",
  "malzeme",
  "taseron",
  "butce",
  "hakedis",
  "kullanicilar",
] as const;

export type PageKey = (typeof ALL_PAGE_KEYS)[number];

export const PAGE_LABELS: Record<PageKey, string> = {
  proje: "Proje",
  kesif: "Keşif",
  "is-programi": "İş Programı",
  puantaj: "Puantaj",
  "gunluk-rapor": "Günlük Rapor",
  imalat: "İmalat",
  gorev: "Görev",
  malzeme: "Malzeme",
  taseron: "Taşeron",
  butce: "Bütçe",
  hakedis: "Hakediş",
  kullanicilar: "Kullanıcılar",
};

export interface Role {
  id: string;
  name: string;
  isAdmin: boolean;
  permissions: Record<PageKey, Permission>;
}

export interface AppUser {
  id: string;
  name: string;
  roleId: string;
  pin: string;
  profession: string;
  phone: string;
  address: string;
  company: string;
}

const ALL_EDIT: Record<PageKey, Permission> = Object.fromEntries(
  ALL_PAGE_KEYS.map((k) => [k, "edit" as Permission])
) as Record<PageKey, Permission>;

const DEFAULT_ROLES: Role[] = [
  {
    id: "isveren",
    name: "İşveren",
    isAdmin: false,
    permissions: {
      proje: "view", kesif: "view", "is-programi": "view", puantaj: "view",
      "gunluk-rapor": "view", imalat: "view", gorev: "view", malzeme: "view",
      taseron: "view", butce: "view", hakedis: "view", kullanicilar: "view",
    },
  },
  {
    id: "proje-muduru",
    name: "Proje Müdürü",
    isAdmin: true,
    permissions: { ...ALL_EDIT },
  },
  {
    id: "santiye-sefi",
    name: "Şantiye Şefi",
    isAdmin: true,
    permissions: { ...ALL_EDIT },
  },
  {
    id: "saha-muhendisi",
    name: "Saha Mühendisi",
    isAdmin: false,
    permissions: {
      proje: "view", kesif: "none", "is-programi": "edit", puantaj: "edit",
      "gunluk-rapor": "edit", imalat: "edit", gorev: "edit", malzeme: "view",
      taseron: "view", butce: "none", hakedis: "none", kullanicilar: "none",
    },
  },
  {
    id: "teknik-ofis-muhendisi",
    name: "Teknik Ofis Mühendisi",
    isAdmin: false,
    permissions: {
      proje: "view", kesif: "edit", "is-programi": "view", puantaj: "none",
      "gunluk-rapor": "view", imalat: "edit", gorev: "view", malzeme: "view",
      taseron: "view", butce: "view", hakedis: "edit", kullanicilar: "none",
    },
  },
  {
    id: "isg-birimi",
    name: "İSG Birimi",
    isAdmin: false,
    permissions: {
      proje: "view", kesif: "none", "is-programi": "view", puantaj: "none",
      "gunluk-rapor": "edit", imalat: "view", gorev: "edit", malzeme: "none",
      taseron: "none", butce: "none", hakedis: "none", kullanicilar: "none",
    },
  },
  {
    id: "taseron",
    name: "Taşeron",
    isAdmin: false,
    permissions: {
      proje: "view", kesif: "none", "is-programi": "view", puantaj: "none",
      "gunluk-rapor": "edit", imalat: "view", gorev: "view", malzeme: "none",
      taseron: "none", butce: "none", hakedis: "view", kullanicilar: "none",
    },
  },
  {
    id: "satin-alma-birimi",
    name: "Satın Alma Birimi",
    isAdmin: false,
    permissions: {
      proje: "view", kesif: "none", "is-programi": "none", puantaj: "none",
      "gunluk-rapor": "none", imalat: "none", gorev: "none", malzeme: "edit",
      taseron: "view", butce: "view", hakedis: "none", kullanicilar: "none",
    },
  },
  {
    id: "muhasebe-birimi",
    name: "Muhasebe Birimi",
    isAdmin: false,
    permissions: {
      proje: "view", kesif: "none", "is-programi": "none", puantaj: "none",
      "gunluk-rapor": "none", imalat: "none", gorev: "none", malzeme: "none",
      taseron: "none", butce: "view", hakedis: "view", kullanicilar: "none",
    },
  },
  {
    id: "ik-birimi",
    name: "İK Birimi",
    isAdmin: false,
    permissions: {
      proje: "view", kesif: "none", "is-programi": "none", puantaj: "edit",
      "gunluk-rapor": "none", imalat: "none", gorev: "none", malzeme: "none",
      taseron: "none", butce: "none", hakedis: "none", kullanicilar: "edit",
    },
  },
  {
    id: "diger-kullanicilar",
    name: "Diğer Kullanıcılar",
    isAdmin: false,
    permissions: {
      proje: "view", kesif: "none", "is-programi": "none", puantaj: "none",
      "gunluk-rapor": "view", imalat: "none", gorev: "view", malzeme: "none",
      taseron: "none", butce: "none", hakedis: "none", kullanicilar: "none",
    },
  },
];

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
  materialRequests: MaterialRequest[];
  subcontractors: Subcontractor[];
  budget: BudgetEntry[];
  hakedisler: Hakedis[];
  roles: Role[];
  appUsers: AppUser[];
  currentUserId: string | null;
}

export type SyncStatus = "idle" | "syncing" | "success" | "error";

interface AppContextType extends AppState {
  loaded: boolean;
  currentAppUser: AppUser | null;
  currentRole: Role | null;
  workspaceInfo: WorkspaceInfo | null;
  syncStatus: SyncStatus;
  lastSyncAt: string | null;

  login: (userId: string) => void;
  logout: () => void;
  setWorkspace: (info: WorkspaceInfo | null) => Promise<void>;
  pushToCloud: () => Promise<void>;
  pullFromCloud: () => Promise<void>;

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

  addMaterialRequest: (r: Omit<MaterialRequest, "id">) => void;
  updateMaterialRequest: (id: string, r: Partial<MaterialRequest>) => void;
  deleteMaterialRequest: (id: string) => void;

  addSubcontractor: (s: Omit<Subcontractor, "id">) => void;
  updateSubcontractor: (id: string, s: Partial<Subcontractor>) => void;
  deleteSubcontractor: (id: string) => void;

  addBudget: (b: Omit<BudgetEntry, "id">) => void;
  updateBudget: (id: string, b: Partial<BudgetEntry>) => void;
  deleteBudget: (id: string) => void;

  addHakedis: (h: Omit<Hakedis, "id">) => void;
  updateHakedis: (id: string, h: Partial<Hakedis>) => void;
  deleteHakedis: (id: string) => void;

  addRole: (r: Omit<Role, "id">) => void;
  updateRole: (id: string, r: Partial<Role>) => void;
  deleteRole: (id: string) => void;

  addAppUser: (u: Omit<AppUser, "id">) => void;
  updateAppUser: (id: string, u: Partial<AppUser>) => void;
  deleteAppUser: (id: string) => void;

  exportData: () => string;
  importData: (json: string) => { ok: true; counts: Record<string, number> } | { ok: false; error: string };
}

const AppContext = createContext<AppContextType | undefined>(undefined);

function genId() {
  return Date.now().toString() + Math.random().toString(36).substr(2, 9);
}

const STORAGE_KEY = "santiye_app_data_v3";
const LEGACY_V2_KEY = "santiye_app_data_v2";
const LEGACY_V1_KEY = "santiye_app_data";


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
  materialRequests: [],
  subcontractors: [],
  budget: [],
  hakedisler: [],
  roles: [],
  appUsers: [],
  currentUserId: null,
};

function needsRoleMigration(roles: Role[]): boolean {
  // Sadece yeni sette olan bir ID eksikse migrate et ("isveren" v1'de yoktu)
  const storedIds = new Set(roles.map(r => r.id));
  return !storedIds.has("isveren") || !storedIds.has("proje-muduru");
}

async function loadInitialState(): Promise<AppState> {
  const raw = await AsyncStorage.getItem(STORAGE_KEY);
  if (raw) {
    try {
      const parsed = JSON.parse(raw);
      const state: AppState = { ...INITIAL, ...parsed };
      if (!state.roles || state.roles.length === 0 || needsRoleMigration(state.roles)) {
        state.roles = DEFAULT_ROLES;
      }
      return state;
    } catch {
      return { ...INITIAL, roles: DEFAULT_ROLES };
    }
  }

  const v2 = await AsyncStorage.getItem(LEGACY_V2_KEY);
  if (v2) {
    try {
      const old = JSON.parse(v2);
      const migrated: AppState = {
        ...INITIAL,
        ...old,
        roles: DEFAULT_ROLES,
        appUsers: [],
        currentUserId: null,
      };
      await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(migrated));
      return migrated;
    } catch {}
  }

  const v1 = await AsyncStorage.getItem(LEGACY_V1_KEY);
  if (v1) {
    try {
      const old = JSON.parse(v1);
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
        roles: DEFAULT_ROLES,
        appUsers: [],
        currentUserId: null,
      };
      await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(migrated));
      return migrated;
    } catch {}
  }

  return { ...INITIAL, roles: DEFAULT_ROLES };
}

export function AppProvider({ children }: { children: React.ReactNode }) {
  const [state, setState] = useState<AppState>(INITIAL);
  const [stateLoaded, setStateLoaded] = useState(false);
  const [workspaceLoaded, setWorkspaceLoaded] = useState(false);
  const [workspaceInfo, setWorkspaceInfo] = useState<WorkspaceInfo | null>(null);
  const [syncStatus, setSyncStatus] = useState<SyncStatus>("idle");
  const [lastSyncAt, setLastSyncAt] = useState<string | null>(null);

  const loaded = stateLoaded && workspaceLoaded;

  useEffect(() => {
    loadInitialState().then((s) => {
      setState(s);
      setStateLoaded(true);
    });
    loadWorkspace().then((ws) => {
      setWorkspaceInfo(ws);
      setWorkspaceLoaded(true);
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

  const currentAppUser =
    state.appUsers.find((u) => u.id === state.currentUserId) ?? null;
  const currentRole = currentAppUser
    ? state.roles.find((r) => r.id === currentAppUser.roleId) ?? null
    : null;

  async function pushToCloud() {
    if (!workspaceInfo || workspaceInfo.id === "local") return;
    setSyncStatus("syncing");
    try {
      const payload = { version: 3, exportedAt: new Date().toISOString(), data: { ...state, currentUserId: null } };
      const res = await fetch(
        `${workspaceInfo.api_url}/api/workspaces/${workspaceInfo.invite_code}/push`,
        { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(payload) }
      );
      if (!res.ok) throw new Error("Push failed");
      const now = new Date().toISOString();
      setLastSyncAt(now);
      setSyncStatus("success");
      setTimeout(() => setSyncStatus("idle"), 3000);
    } catch {
      setSyncStatus("error");
      setTimeout(() => setSyncStatus("idle"), 4000);
    }
  }

  async function pullFromCloud() {
    if (!workspaceInfo || workspaceInfo.id === "local") return;
    setSyncStatus("syncing");
    try {
      const res = await fetch(
        `${workspaceInfo.api_url}/api/workspaces/${workspaceInfo.invite_code}/pull`
      );
      if (!res.ok) throw new Error("Pull failed");
      const json = await res.json();
      if (!json.data) {
        setSyncStatus("idle");
        return;
      }
      const incoming = json.data?.data ?? json.data;
      if (incoming && typeof incoming === "object") {
        const prevUserId = state.currentUserId;
        const incomingUsers: AppUser[] = Array.isArray(incoming.appUsers) ? incoming.appUsers : [];
        const userStillExists = prevUserId && incomingUsers.some((u) => u.id === prevUserId);
        const next: AppState = {
          ...INITIAL,
          ...incoming,
          roles: Array.isArray(incoming.roles) && incoming.roles.length > 0 ? incoming.roles : DEFAULT_ROLES,
          currentUserId: userStillExists ? prevUserId : null,
        };
        setState(next);
        AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(next));
      }
      const now = new Date().toISOString();
      setLastSyncAt(now);
      setSyncStatus("success");
      setTimeout(() => setSyncStatus("idle"), 3000);
    } catch {
      setSyncStatus("error");
      setTimeout(() => setSyncStatus("idle"), 4000);
    }
  }

  const ctx: AppContextType = {
    ...state,
    loaded,
    currentAppUser,
    currentRole,
    workspaceInfo,
    syncStatus,
    lastSyncAt,

    login: (userId) =>
      setState((prev) => ({ ...prev, currentUserId: userId })),
    logout: () => setState((prev) => ({ ...prev, currentUserId: null })),
    setWorkspace: async (info) => {
      if (info) await saveWorkspace(info);
      else await clearWorkspace();
      setWorkspaceInfo(info);
    },
    pushToCloud,
    pullFromCloud,

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
        materialRequests: prev.materialRequests.filter((x) => x.projectId !== id),
        subcontractors: prev.subcontractors.filter((x) => x.projectId !== id),
        budget: prev.budget.filter((x) => x.projectId !== id),
        hakedisler: prev.hakedisler.filter((x) => x.projectId !== id),
        roles: prev.roles,
        appUsers: prev.appUsers,
        currentUserId: prev.currentUserId,
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

    addMaterialRequest: makeAdd("materialRequests") as any,
    updateMaterialRequest: makeUpdate("materialRequests") as any,
    deleteMaterialRequest: makeDelete("materialRequests") as any,

    addSubcontractor: makeAdd("subcontractors") as any,
    updateSubcontractor: makeUpdate("subcontractors") as any,
    deleteSubcontractor: makeDelete("subcontractors") as any,

    addBudget: makeAdd("budget") as any,
    updateBudget: makeUpdate("budget") as any,
    deleteBudget: makeDelete("budget") as any,

    addHakedis: makeAdd("hakedisler") as any,
    updateHakedis: makeUpdate("hakedisler") as any,
    deleteHakedis: makeDelete("hakedisler") as any,

    addRole: makeAdd("roles") as any,
    updateRole: makeUpdate("roles") as any,
    deleteRole: makeDelete("roles") as any,

    addAppUser: makeAdd("appUsers") as any,
    updateAppUser: makeUpdate("appUsers") as any,
    deleteAppUser: (id) =>
      update((prev) => ({
        ...prev,
        appUsers: prev.appUsers.filter((u) => u.id !== id),
        currentUserId: prev.currentUserId === id ? null : prev.currentUserId,
      })),

    exportData: () => {
      const payload = {
        version: 3,
        exportedAt: new Date().toISOString(),
        data: { ...state, currentUserId: null },
      };
      return JSON.stringify(payload, null, 2);
    },

    importData: (json: string) => {
      try {
        const parsed = JSON.parse(json);
        const incoming = parsed?.data ?? parsed;
        if (!incoming || typeof incoming !== "object") {
          return { ok: false as const, error: "Geçersiz dosya formatı" };
        }
        const next: AppState = {
          ...INITIAL,
          ...incoming,
          roles: Array.isArray(incoming.roles) && incoming.roles.length > 0
            ? incoming.roles
            : DEFAULT_ROLES,
          currentUserId: null,
        };
        setState(next);
        const counts: Record<string, number> = {};
        (Object.keys(INITIAL) as (keyof AppState)[]).forEach((k) => {
          const val = (next as any)[k];
          if (Array.isArray(val)) counts[k] = val.length;
        });
        return { ok: true as const, counts };
      } catch (e: any) {
        return { ok: false as const, error: e?.message || "JSON ayrıştırılamadı" };
      }
    },
  };

  return <AppContext.Provider value={ctx}>{children}</AppContext.Provider>;
}

export function useApp() {
  const ctx = useContext(AppContext);
  if (!ctx) throw new Error("useApp must be used within AppProvider");
  return ctx;
}
