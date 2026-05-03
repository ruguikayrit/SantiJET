import AsyncStorage from "@react-native-async-storage/async-storage";
import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useState,
} from "react";
import { WorkspaceInfo, loadWorkspace, saveWorkspace, clearWorkspace } from "@/utils/workspace";
import {
  CONSTRUCTION_MATERIALS,
  ConstructionMaterial,
  MATERIAL_CATEGORIES,
} from "@/constants/materials";
import { MATERIAL_UNITS, UnitOption } from "@/constants/units";
import { DEFAULT_IMALAT_POZLARI, ImalatPoz } from "@/constants/imalatPozlari";

function mergeImalatPozlari(stored: unknown): ImalatPoz[] {
  if (!Array.isArray(stored) || stored.length === 0) {
    return [...DEFAULT_IMALAT_POZLARI];
  }
  const existingCodes = new Set(
    (stored as ImalatPoz[]).map((p) => (p?.code || "").toLowerCase())
  );
  const additions = DEFAULT_IMALAT_POZLARI.filter(
    (p) => !existingCodes.has(p.code.toLowerCase())
  );
  return additions.length > 0 ? [...(stored as ImalatPoz[]), ...additions] : (stored as ImalatPoz[]);
}

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
  pozCode?: string;
  pozCategory?: string;
  plannedQty?: number;
  completedQty?: number;
  date?: string;
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
  pozCode?: string;
  pozCategory?: string;
  description?: string;
  images?: string[];
  mixerCount?: string;
  pumpCount?: string;
  pumpInfo?: string;
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
  category?: string;
  unit: string;
  quantity: number;
  usedQty: number;
  supplier: string;
  deliveryDate: string;
  unitPrice: number;
  recordDetail?: string;
  description?: string;
  code?: string;
  pozCode?: string;
  pozCategory?: string;
  shippingMethod?: string;
  waybillNo?: string;
  invoiceNo?: string;
  kantarEnabled?: boolean;
  writeToKantar?: boolean;
  kantarSlipId?: string;
  supplierKantarSlip?: boolean;
  weighApproved?: boolean;
  materialRequestId?: string;
  irsaliyePhoto?: string;
}

export interface Weighbridge {
  id: string;
  projectId: string;
  date: string;
  materialId?: string;
  materialName: string;
  category?: string;
  supplier: string;
  plate: string;
  driver: string;
  irsaliyeNo: string;
  grossWeight: number;
  tareWeight: number;
  netWeight: number;
  unit: string;
  notes: string;
  entryTime?: string;
  exitTime?: string;
  supplierIrsaliyeNo?: string;
  supplierTonnage?: number;
  supplierGrossWeight?: number;
  supplierTareWeight?: number;
}

export interface MaterialRequest {
  id: string;
  projectId: string;
  name: string;
  category?: string;
  unit: string;
  quantity: number;
  requestDate: string;
  requestedBy: string;
  status: "pending" | "approved" | "delivered" | "rejected";
  note: string;
  usageLocation?: string;
  pozCode?: string;
  pozCategory?: string;
  approvals?: {
    sef?: boolean;
    mudur?: boolean;
    satinAlma?: boolean;
  };
}

export interface MaterialMovement {
  id: string;
  projectId: string;
  type: "kullanim" | "giden";
  name: string;
  category?: string;
  unit: string;
  quantity: number;
  date: string;
  person: string;
  location: string;
  reason: string;
  note: string;
  pozCode?: string;
  pozCategory?: string;
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

export type PurchaseStatus = "pending" | "approved" | "paid" | "cancelled";
export type PurchasePaymentMethod = "nakit" | "havale" | "kredi-karti" | "cek" | "vadeli";

export interface Purchase {
  id: string;
  projectId: string;
  date: string;            // sipariş / fatura tarihi
  supplier: string;        // tedarikçi adı
  itemName: string;        // ürün / hizmet adı
  category: string;        // örn: "İnşaat Malzemesi", "Akaryakıt"
  unit: string;            // birim (adet, m3, kg, ton...)
  quantity: number;
  unitPrice: number;       // KDV hariç birim fiyat
  vatRate: number;         // % (0, 1, 8, 18, 20...)
  status: PurchaseStatus;
  paymentMethod: PurchasePaymentMethod;
  paidDate: string;        // ödendi olarak işaretlenince doldurulur
  invoiceNo: string;       // fatura no
  notes: string;
  invoiceReceived: boolean; // Faturası geldi olarak işaretlendi mi
  // İlişkili malzeme talebi (otomatik oluşturulan kayıtlar için)
  materialRequestId?: string;
  // İlişkili Gelen Malzeme (talepsiz girilip Satın Alma'ya gönderilen kayıtlar için)
  materialId?: string;
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

export interface ArchiveFile {
  id: string;
  projectId: string;
  name: string;
  ext: string;
  mime: string;
  size: number;
  storageKey: string;
  addedAt: string;
  note: string;
}

export type Permission = "none" | "view" | "edit";

export const ALL_PAGE_KEYS = [
  "proje",
  "dosyalar",
  "kesif",
  "is-programi",
  "puantaj",
  "gunluk-rapor",
  "imalat",
  "gorev",
  "malzeme",
  "taseron",
  "satin-alma",
  "kantar",
  "butce",
  "hakedis",
  "ilerleme",
  "finans",
  "kullanicilar",
] as const;

export type PageKey = (typeof ALL_PAGE_KEYS)[number];

export const PAGE_LABELS: Record<PageKey, string> = {
  proje: "Proje",
  "dosyalar": "Dosyalar",
  kesif: "Keşif",
  "is-programi": "İş Programı",
  puantaj: "Puantaj",
  "gunluk-rapor": "Günlük Rapor",
  imalat: "İmalat",
  gorev: "Görev",
  malzeme: "Malzeme",
  taseron: "Taşeron",
  "satin-alma": "Satın Alma",
  kantar: "Kantar",
  butce: "Bütçe",
  hakedis: "Hakediş",
  ilerleme: "İlerleme",
  finans: "Finans",
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
  team?: string;
}

export const DEFAULT_PROFESSIONS: string[] = [
  "Proje Koordinatörü",
  "Proje Müdürü",
  "Şantiye Şefi",
  "Saha Mühendisi",
  "Teknik Ofis Mühendisi",
  "Harita Mühendisi",
  "Jeoloji Mühendisi",
  "İSG Uzmanı",
  "Şenör",
  "Puantör",
  "Saha Formeni",
  "Makine Formeni",
  "Usta",
  "Ekskavatör Operatörü",
  "JCB Operatörü",
  "Kamyon Şoförü",
  "Kule Vinç Operatörü",
  "Mobil Vinç Operatörü",
  "Kantar Personeli",
  "Depo & Ambar Personeli",
  "Kalfa",
  "Kalfa Yardımcısı",
  "Saha Düz İşçi",
  "Gündüz Bekçisi",
  "Gece Bekçisi",
];

export const DEFAULT_TRADE_GROUPS: string[] = [
  "Hafriyat",
  "Kaba İnşaat",
  "Kalıp",
  "Demir",
  "Beton",
  "Duvar",
  "Çelik",
  "Sıva",
  "Şap",
  "İzolasyon",
  "Çatı",
  "Seramik / Fayans",
  "Boya",
  "Alçı / Asma Tavan",
  "Alüminyum / Doğrama",
  "Su Tesisatı",
  "Elektrik",
  "Mekanik / Havalandırma",
  "Yangın Tesisatı",
  "Asansör",
  "Peyzaj",
  "Altyapı",
  "İnce İşler",
];

const ALL_EDIT: Record<PageKey, Permission> = Object.fromEntries(
  ALL_PAGE_KEYS.map((k) => [k, "edit" as Permission])
) as Record<PageKey, Permission>;

const DEFAULT_ROLES: Role[] = [
  {
    id: "isveren",
    name: "İşveren",
    isAdmin: false,
    permissions: {
      proje: "view", "dosyalar": "view", kesif: "view", "is-programi": "view", puantaj: "view",
      "gunluk-rapor": "view", imalat: "view", gorev: "view", malzeme: "view",
      taseron: "view", "satin-alma": "view", kantar: "view", butce: "view", hakedis: "view", ilerleme: "view", finans: "view", kullanicilar: "view",
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
      proje: "view", "dosyalar": "edit", kesif: "none", "is-programi": "edit", puantaj: "edit",
      "gunluk-rapor": "edit", imalat: "edit", gorev: "edit", malzeme: "view",
      taseron: "view", "satin-alma": "view", kantar: "edit", butce: "none", hakedis: "none", ilerleme: "view", finans: "none", kullanicilar: "none",
    },
  },
  {
    id: "teknik-ofis-muhendisi",
    name: "Teknik Ofis Mühendisi",
    isAdmin: false,
    permissions: {
      proje: "view", "dosyalar": "edit", kesif: "edit", "is-programi": "view", puantaj: "none",
      "gunluk-rapor": "view", imalat: "edit", gorev: "view", malzeme: "view",
      taseron: "view", "satin-alma": "view", kantar: "view", butce: "view", hakedis: "edit", ilerleme: "edit", finans: "view", kullanicilar: "none",
    },
  },
  {
    id: "isg-birimi",
    name: "İSG Birimi",
    isAdmin: false,
    permissions: {
      proje: "view", "dosyalar": "view", kesif: "none", "is-programi": "view", puantaj: "none",
      "gunluk-rapor": "edit", imalat: "view", gorev: "edit", malzeme: "none",
      taseron: "none", "satin-alma": "none", kantar: "none", butce: "none", hakedis: "none", ilerleme: "view", finans: "none", kullanicilar: "none",
    },
  },
  {
    id: "taseron",
    name: "Taşeron",
    isAdmin: false,
    permissions: {
      proje: "view", "dosyalar": "view", kesif: "none", "is-programi": "view", puantaj: "none",
      "gunluk-rapor": "edit", imalat: "view", gorev: "view", malzeme: "none",
      taseron: "none", "satin-alma": "none", kantar: "none", butce: "none", hakedis: "view", ilerleme: "view", finans: "none", kullanicilar: "none",
    },
  },
  {
    id: "satin-alma-birimi",
    name: "Satın Alma Birimi",
    isAdmin: false,
    permissions: {
      proje: "view", "dosyalar": "view", kesif: "none", "is-programi": "none", puantaj: "none",
      "gunluk-rapor": "none", imalat: "none", gorev: "none", malzeme: "edit",
      taseron: "view", "satin-alma": "edit", kantar: "edit", butce: "view", hakedis: "none", ilerleme: "none", finans: "view", kullanicilar: "none",
    },
  },
  {
    id: "muhasebe-birimi",
    name: "Muhasebe Birimi",
    isAdmin: false,
    permissions: {
      proje: "view", "dosyalar": "view", kesif: "none", "is-programi": "none", puantaj: "none",
      "gunluk-rapor": "none", imalat: "none", gorev: "none", malzeme: "none",
      taseron: "none", "satin-alma": "view", kantar: "view", butce: "view", hakedis: "view", ilerleme: "none", finans: "edit", kullanicilar: "none",
    },
  },
  {
    id: "ik-birimi",
    name: "İK Birimi",
    isAdmin: false,
    permissions: {
      proje: "view", "dosyalar": "view", kesif: "none", "is-programi": "none", puantaj: "edit",
      "gunluk-rapor": "none", imalat: "none", gorev: "none", malzeme: "none",
      taseron: "none", "satin-alma": "none", kantar: "none", butce: "none", hakedis: "none", ilerleme: "none", finans: "none", kullanicilar: "edit",
    },
  },
  {
    id: "diger-kullanicilar",
    name: "Diğer Kullanıcılar",
    isAdmin: false,
    permissions: {
      proje: "view", "dosyalar": "view", kesif: "none", "is-programi": "none", puantaj: "none",
      "gunluk-rapor": "view", imalat: "none", gorev: "view", malzeme: "none",
      taseron: "none", "satin-alma": "none", kantar: "none", butce: "none", hakedis: "none", ilerleme: "none", finans: "none", kullanicilar: "none",
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
  materialMovements: MaterialMovement[];
  subcontractors: Subcontractor[];
  archiveFiles: ArchiveFile[];
  purchases: Purchase[];
  weighbridges: Weighbridge[];
  budget: BudgetEntry[];
  hakedisler: Hakedis[];
  roles: Role[];
  appUsers: AppUser[];
  currentUserId: string | null;
  materialCategories: string[];
  materialList: ConstructionMaterial[];
  materialUnits: UnitOption[];
  imalatPozlari: ImalatPoz[];
  professions: string[];
  tradeGroups: string[];
}

export type SyncStatus = "idle" | "syncing" | "success" | "error" | "conflict" | "auth_error";

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

  addMaterialMovement: (m: Omit<MaterialMovement, "id">) => void;
  updateMaterialMovement: (id: string, m: Partial<MaterialMovement>) => void;
  deleteMaterialMovement: (id: string) => void;

  addSubcontractor: (s: Omit<Subcontractor, "id">) => void;
  updateSubcontractor: (id: string, s: Partial<Subcontractor>) => void;
  deleteSubcontractor: (id: string) => void;

  addArchiveFile: (f: Omit<ArchiveFile, "id">) => string;
  updateArchiveFile: (id: string, f: Partial<ArchiveFile>) => void;
  deleteArchiveFile: (id: string) => void;

  addPurchase: (p: Omit<Purchase, "id">) => string;
  updatePurchase: (id: string, p: Partial<Purchase>) => void;
  deletePurchase: (id: string) => void;
  markPurchasePaid: (id: string, paidDate: string) => void;
  markPurchaseInvoiceReceived: (id: string, received: boolean, invoiceNo?: string) => void;

  addWeighbridge: (w: Omit<Weighbridge, "id">) => string;
  updateWeighbridge: (id: string, w: Partial<Weighbridge>) => void;
  deleteWeighbridge: (id: string) => void;

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

  addMaterialCategory: (name: string) => void;
  deleteMaterialCategory: (name: string) => void;

  addMaterialItem: (item: ConstructionMaterial) => void;
  deleteMaterialItem: (name: string) => void;

  addImalatPoz: (poz: ImalatPoz) => void;
  updateImalatPoz: (code: string, patch: Partial<ImalatPoz>) => void;
  deleteImalatPoz: (code: string) => void;

  addMaterialUnit: (unit: UnitOption) => void;
  deleteMaterialUnit: (code: string) => void;

  addProfession: (name: string) => void;
  updateProfession: (oldName: string, newName: string) => void;
  deleteProfession: (name: string) => void;
  moveProfession: (name: string, dir: -1 | 1) => void;

  addTradeGroup: (name: string) => void;
  updateTradeGroup: (oldName: string, newName: string) => void;
  deleteTradeGroup: (name: string) => void;
  moveTradeGroup: (name: string, dir: -1 | 1) => void;
  resetTradeGroups: () => void;
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
  materialMovements: [],
  subcontractors: [],
  archiveFiles: [],
  purchases: [],
  weighbridges: [],
  budget: [],
  hakedisler: [],
  roles: [],
  appUsers: [],
  currentUserId: null,
  materialCategories: [...MATERIAL_CATEGORIES],
  materialList: [...CONSTRUCTION_MATERIALS],
  materialUnits: [...MATERIAL_UNITS],
  imalatPozlari: [...DEFAULT_IMALAT_POZLARI],
  professions: [...DEFAULT_PROFESSIONS],
  tradeGroups: [...DEFAULT_TRADE_GROUPS],
};

function needsRoleMigration(roles: Role[]): boolean {
  // Sadece yeni sette olan bir ID eksikse migrate et ("isveren" v1'de yoktu)
  const storedIds = new Set(roles.map(r => r.id));
  return !storedIds.has("isveren") || !storedIds.has("proje-muduru");
}

function backfillRolePermissions(roles: Role[]): Role[] {
  // Yeni eklenen PageKey'leri (örn: "finans") mevcut rollere ekle.
  // Kullanıcının özelleştirdiği izinler korunur; yalnızca eksik anahtarlar
  // DEFAULT_ROLES'taki aynı id'li roldeki değer (yoksa "none") ile doldurulur.
  return roles.map((r) => {
    const def = DEFAULT_ROLES.find((d) => d.id === r.id);
    const merged: Record<string, Permission> = { ...(r.permissions as any) };
    // Eski "proje-arsivi" anahtarını yeni "dosyalar" anahtarına taşı
    if (merged["proje-arsivi"] !== undefined && merged["dosyalar"] === undefined) {
      merged["dosyalar"] = merged["proje-arsivi"];
    }
    delete merged["proje-arsivi"];
    for (const key of ALL_PAGE_KEYS) {
      if (merged[key] === undefined) {
        merged[key] = (def?.permissions as any)?.[key] ?? "none";
      }
    }
    return { ...r, permissions: merged as Role["permissions"] };
  });
}

function normalizePurchases(arr: any): Purchase[] {
  if (!Array.isArray(arr)) return [];
  return arr.map((p: any) => ({
    ...p,
    invoiceReceived: !!p?.invoiceReceived,
    materialRequestId:
      typeof p?.materialRequestId === "string" ? p.materialRequestId : undefined,
    materialId:
      typeof p?.materialId === "string" ? p.materialId : undefined,
  })) as Purchase[];
}

function normalizeWeighbridges(arr: any): Weighbridge[] {
  if (!Array.isArray(arr)) return [];
  return arr.map((w: any) => {
    const gross = Number(w?.grossWeight) || 0;
    const tare = Number(w?.tareWeight) || 0;
    const net = Number.isFinite(Number(w?.netWeight))
      ? Number(w.netWeight)
      : Math.max(0, gross - tare);
    return {
      id: String(w?.id || ""),
      projectId: String(w?.projectId || ""),
      date: String(w?.date || ""),
      materialId: typeof w?.materialId === "string" ? w.materialId : undefined,
      materialName: String(w?.materialName || ""),
      category: typeof w?.category === "string" ? w.category : undefined,
      supplier: String(w?.supplier || ""),
      plate: String(w?.plate || ""),
      driver: String(w?.driver || ""),
      irsaliyeNo: String(w?.irsaliyeNo || ""),
      grossWeight: gross,
      tareWeight: tare,
      netWeight: net,
      unit: String(w?.unit || "kg"),
      notes: String(w?.notes || ""),
      entryTime: typeof w?.entryTime === "string" ? w.entryTime : undefined,
      exitTime: typeof w?.exitTime === "string" ? w.exitTime : undefined,
      supplierIrsaliyeNo: typeof w?.supplierIrsaliyeNo === "string" ? w.supplierIrsaliyeNo : undefined,
      supplierTonnage: Number.isFinite(Number(w?.supplierTonnage)) ? Number(w.supplierTonnage) : undefined,
      supplierGrossWeight: Number.isFinite(Number(w?.supplierGrossWeight)) ? Number(w.supplierGrossWeight) : undefined,
      supplierTareWeight: Number.isFinite(Number(w?.supplierTareWeight)) ? Number(w.supplierTareWeight) : undefined,
    };
  });
}

async function loadInitialState(): Promise<AppState> {
  const raw = await AsyncStorage.getItem(STORAGE_KEY);
  if (raw) {
    try {
      const parsed = JSON.parse(raw);
      const state: AppState = { ...INITIAL, ...parsed };
      if (!state.roles || state.roles.length === 0 || needsRoleMigration(state.roles)) {
        state.roles = DEFAULT_ROLES;
      } else {
        state.roles = backfillRolePermissions(state.roles);
      }
      if (!Array.isArray(state.materialCategories)) {
        state.materialCategories = [...MATERIAL_CATEGORIES];
      }
      if (!Array.isArray(state.materialList)) {
        state.materialList = [...CONSTRUCTION_MATERIALS];
      }
      if (!Array.isArray(state.materialUnits)) {
        state.materialUnits = [...MATERIAL_UNITS];
      } else {
        state.materialUnits = state.materialUnits.map((u: UnitOption) => {
          if (u.code === "M2") return { code: "M²", label: "M² — Metrekare" };
          if (u.code === "M3") return { code: "M³", label: "M³ — Metreküp" };
          return u;
        });
      }
      state.imalatPozlari = mergeImalatPozlari(state.imalatPozlari);
      if (!Array.isArray(state.professions) || state.professions.length === 0) {
        state.professions = [...DEFAULT_PROFESSIONS];
      }
      if (!Array.isArray(state.tradeGroups) || state.tradeGroups.length === 0) {
        state.tradeGroups = [...DEFAULT_TRADE_GROUPS];
      }
      state.purchases = normalizePurchases(state.purchases);
      state.weighbridges = normalizeWeighbridges(state.weighbridges);
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

  function authHeaders(): Record<string, string> {
    const h: Record<string, string> = { "Content-Type": "application/json" };
    if (workspaceInfo?.auth_token) h["Authorization"] = `Bearer ${workspaceInfo.auth_token}`;
    return h;
  }

  async function pushToCloud() {
    if (!workspaceInfo || workspaceInfo.id === "local") return;
    setSyncStatus("syncing");
    try {
      const baseRev = workspaceInfo.revision ?? 0;
      const payload = {
        data: { version: 3, exportedAt: new Date().toISOString(), data: { ...state, currentUserId: null } },
        base_revision: baseRev,
      };
      const res = await fetch(
        `${workspaceInfo.api_url}/api/workspaces/${workspaceInfo.invite_code}/push`,
        { method: "POST", headers: authHeaders(), body: JSON.stringify(payload) }
      );
      if (res.status === 409) {
        setSyncStatus("conflict");
        setTimeout(() => setSyncStatus("idle"), 6000);
        return;
      }
      if (res.status === 401) {
        setSyncStatus("auth_error");
        setTimeout(() => setSyncStatus("idle"), 5000);
        return;
      }
      if (!res.ok) throw new Error("Push failed");
      const json = await res.json();
      if (typeof json.revision === "number") {
        setWorkspaceInfo({ ...workspaceInfo, revision: json.revision });
        await saveWorkspace({ ...workspaceInfo, revision: json.revision });
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

  async function pullFromCloud() {
    if (!workspaceInfo || workspaceInfo.id === "local") return;
    setSyncStatus("syncing");
    try {
      const res = await fetch(
        `${workspaceInfo.api_url}/api/workspaces/${workspaceInfo.invite_code}/pull`,
        { headers: authHeaders() }
      );
      if (res.status === 401) {
        setSyncStatus("auth_error");
        setTimeout(() => setSyncStatus("idle"), 5000);
        return;
      }
      if (!res.ok) throw new Error("Pull failed");
      const json = await res.json();
      const serverRev: number | undefined = typeof json.revision === "number" ? json.revision : undefined;
      if (json.data) {
        const incoming = json.data?.data ?? json.data;
        if (incoming && typeof incoming === "object") {
          const prevUserId = state.currentUserId;
          const incomingUsers: AppUser[] = Array.isArray(incoming.appUsers) ? incoming.appUsers : [];
          const userStillExists = prevUserId && incomingUsers.some((u) => u.id === prevUserId);
          const next: AppState = {
            ...INITIAL,
            ...incoming,
            roles: Array.isArray(incoming.roles) && incoming.roles.length > 0
              ? backfillRolePermissions(incoming.roles)
              : DEFAULT_ROLES,
            materialCategories: Array.isArray(incoming.materialCategories)
              ? incoming.materialCategories : [...MATERIAL_CATEGORIES],
            materialList: Array.isArray(incoming.materialList)
              ? incoming.materialList : [...CONSTRUCTION_MATERIALS],
            materialUnits: Array.isArray(incoming.materialUnits)
              ? incoming.materialUnits : [...MATERIAL_UNITS],
            imalatPozlari: mergeImalatPozlari(incoming.imalatPozlari),
            professions: Array.isArray(incoming.professions) && incoming.professions.length > 0
              ? incoming.professions : [...DEFAULT_PROFESSIONS],
            tradeGroups: Array.isArray(incoming.tradeGroups) && incoming.tradeGroups.length > 0
              ? incoming.tradeGroups : [...DEFAULT_TRADE_GROUPS],
            purchases: normalizePurchases(incoming.purchases),
            currentUserId: userStillExists ? prevUserId : null,
          };
          setState(next);
          AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(next));
        }
      }
      if (serverRev !== undefined) {
        const updated = { ...workspaceInfo, revision: serverRev };
        setWorkspaceInfo(updated);
        await saveWorkspace(updated);
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
        ...prev,
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
        materialMovements: prev.materialMovements.filter((x) => x.projectId !== id),
        subcontractors: prev.subcontractors.filter((x) => x.projectId !== id),
        archiveFiles: prev.archiveFiles.filter((x) => x.projectId !== id),
        purchases: prev.purchases.filter((x) => x.projectId !== id),
        weighbridges: prev.weighbridges.filter((x) => x.projectId !== id),
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

    addMaterial: ((item: Omit<Material, "id">) => {
      const id = genId();
      const willBridge = !!(item as any).writeToKantar && !(item as any).kantarSlipId;
      const slipId = willBridge ? genId() : undefined;
      const created: Material = {
        ...(item as any),
        id,
        kantarSlipId: slipId ?? (item as any).kantarSlipId,
      };
      update((prev) => {
        const next: AppState = { ...prev, materials: [...prev.materials, created] };
        if (willBridge && slipId) {
          const slip: Weighbridge = {
            id: slipId,
            projectId: created.projectId,
            date: created.deliveryDate || new Date().toISOString().slice(0, 10),
            materialId: id,
            materialName: created.name,
            category: created.category,
            supplier: created.supplier,
            plate: "",
            driver: "",
            irsaliyeNo: created.waybillNo || "",
            grossWeight: 0,
            tareWeight: 0,
            netWeight: 0,
            unit: "ton",
            notes: "Gelen Malzeme'den otomatik oluşturuldu",
          };
          next.weighbridges = [...prev.weighbridges, slip];
        }
        return next;
      });
      return id;
    }) as any,
    updateMaterial: ((id: string, patch: Partial<Material>) => {
      update((prev) => {
        const before = prev.materials.find((m) => m.id === id);
        if (!before) return prev;
        const after: Material = { ...before, ...patch };
        let nextMaterials = prev.materials.map((m) => (m.id === id ? after : m));
        let nextWeighbridges = prev.weighbridges;

        const turningOn = !!after.writeToKantar && !before.writeToKantar;
        const turningOff = !after.writeToKantar && !!before.writeToKantar;

        if (turningOn && !after.kantarSlipId) {
          const slipId = genId();
          const slip: Weighbridge = {
            id: slipId,
            projectId: after.projectId,
            date: after.deliveryDate || new Date().toISOString().slice(0, 10),
            materialId: id,
            materialName: after.name,
            category: after.category,
            supplier: after.supplier,
            plate: "",
            driver: "",
            irsaliyeNo: after.waybillNo || "",
            grossWeight: 0,
            tareWeight: 0,
            netWeight: 0,
            unit: "ton",
            notes: "Gelen Malzeme'den otomatik oluşturuldu",
          };
          const linked: Material = { ...after, kantarSlipId: slipId };
          nextMaterials = nextMaterials.map((m) => (m.id === id ? linked : m));
          nextWeighbridges = [...nextWeighbridges, slip];
        } else if (turningOff && before.kantarSlipId) {
          // Kantara Girsin kapatıldı: kantar fişini sil ve bağlantıyı kopart.
          const slipId = before.kantarSlipId;
          nextWeighbridges = nextWeighbridges.filter((w) => w.id !== slipId);
          const cleared: Material = { ...after, kantarSlipId: undefined };
          nextMaterials = nextMaterials.map((m) => (m.id === id ? cleared : m));
        } else if (after.writeToKantar && after.kantarSlipId) {
          // Kantar açık + bağlı fiş: malzeme adı/kategorisi değişmişse fişe yansıt
          const nameChanged = after.name !== before.name;
          const catChanged = after.category !== before.category;
          const supChanged = after.supplier !== before.supplier;
          if (nameChanged || catChanged || supChanged) {
            nextWeighbridges = nextWeighbridges.map((w) =>
              w.id === after.kantarSlipId
                ? {
                    ...w,
                    materialName: nameChanged ? after.name : w.materialName,
                    category: catChanged ? after.category : w.category,
                    supplier: supChanged ? after.supplier : w.supplier,
                  }
                : w
            );
          }
        }

        return { ...prev, materials: nextMaterials, weighbridges: nextWeighbridges };
      });
    }) as any,
    deleteMaterial: ((id: string) => {
      update((prev) => {
        const target = prev.materials.find((m) => m.id === id);
        const slipId = target?.kantarSlipId;
        return {
          ...prev,
          materials: prev.materials.filter((m) => m.id !== id),
          weighbridges: slipId
            ? prev.weighbridges.filter((w) => w.id !== slipId)
            : prev.weighbridges,
        };
      });
    }) as any,

    addMaterialRequest: ((item: Omit<MaterialRequest, "id">) => {
      const id = genId();
      update((prev) => {
        const newReq: MaterialRequest = { ...(item as any), id };
        const next: AppState = {
          ...prev,
          materialRequests: [...prev.materialRequests, newReq],
        };
        // Talep ilk eklenirken zaten "approved" ise otomatik satın alma oluştur
        if (
          newReq.status === "approved" &&
          !prev.purchases.some((p) => p.materialRequestId === id)
        ) {
          const today = new Date().toISOString().slice(0, 10);
          const auto: Purchase = {
            id: genId(),
            projectId: newReq.projectId,
            date: today,
            supplier: "",
            itemName: newReq.name,
            category: newReq.category || "",
            unit: newReq.unit || "",
            quantity: newReq.quantity || 0,
            unitPrice: 0,
            vatRate: 20,
            status: "pending",
            paymentMethod: "havale",
            paidDate: "",
            invoiceNo: "",
            notes: newReq.note ? `Talepten: ${newReq.note}` : "Malzeme talebinden otomatik oluşturuldu",
            invoiceReceived: false,
            materialRequestId: id,
          };
          next.purchases = [...next.purchases, auto];
        }
        // 3 onaylı (veya doğrudan approved) talepten Gelen Malzeme oluştur
        const allChecked = !!(
          newReq.approvals?.sef &&
          newReq.approvals?.mudur &&
          newReq.approvals?.satinAlma
        );
        if (
          (newReq.status === "approved" || allChecked) &&
          !prev.materials.some((m) => m.materialRequestId === id)
        ) {
          const today = new Date().toISOString().slice(0, 10);
          const autoMat: Material = {
            id: genId(),
            projectId: newReq.projectId,
            name: newReq.name,
            category: newReq.category || "",
            unit: newReq.unit || "",
            quantity: newReq.quantity || 0,
            usedQty: 0,
            supplier: "",
            deliveryDate: today,
            unitPrice: 0,
            description: newReq.note || "Malzeme talebinden otomatik oluşturuldu",
            materialRequestId: id,
          };
          next.materials = [...next.materials, autoMat];
        }
        return next;
      });
      return id;
    }) as any,
    updateMaterialRequest: ((id: string, patch: Partial<MaterialRequest>) => {
      update((prev) => {
        const before = prev.materialRequests.find((r) => r.id === id);
        if (!before) return prev;
        // approvals alanı varsa daima MEVCUT state ile alan-bazlı birleştir;
        // böylece eş zamanlı onay tıklamaları birbirinin üzerine yazmaz.
        const mergedApprovals =
          patch.approvals !== undefined
            ? { ...(before.approvals || {}), ...patch.approvals }
            : before.approvals;
        const after: MaterialRequest = { ...before, ...patch, approvals: mergedApprovals };
        let nextMaterialRequests = prev.materialRequests.map((r) => (r.id === id ? after : r));
        let nextPurchases = prev.purchases;

        // Onay geçişi tespiti
        const wasApprovedStatus = before.status === "approved";
        const isApprovedStatus = after.status === "approved";
        const beforeAllChecked =
          !!(before.approvals?.sef && before.approvals?.mudur && before.approvals?.satinAlma);
        const afterAllChecked =
          !!(after.approvals?.sef && after.approvals?.mudur && after.approvals?.satinAlma);

        // 3 onay yeni tamamlandıysa talep durumunu daima "approved" yap (purchase olsa da olmasa da)
        if (!beforeAllChecked && afterAllChecked && !isApprovedStatus) {
          const synced: MaterialRequest = { ...after, status: "approved" };
          nextMaterialRequests = nextMaterialRequests.map((r) => (r.id === id ? synced : r));
        }

        const justApproved =
          (!wasApprovedStatus && isApprovedStatus) ||
          (!beforeAllChecked && afterAllChecked);
        const alreadyHasPurchase = prev.purchases.some((p) => p.materialRequestId === id);
        if (justApproved && !alreadyHasPurchase) {
          const today = new Date().toISOString().slice(0, 10);
          const auto: Purchase = {
            id: genId(),
            projectId: after.projectId,
            date: today,
            supplier: "",
            itemName: after.name,
            category: after.category || "",
            unit: after.unit || "",
            quantity: after.quantity || 0,
            unitPrice: 0,
            vatRate: 20,
            status: "pending",
            paymentMethod: "havale",
            paidDate: "",
            invoiceNo: "",
            notes: after.note ? `Talepten: ${after.note}` : "Malzeme talebinden otomatik oluşturuldu",
            invoiceReceived: false,
            materialRequestId: id,
          };
          nextPurchases = [...nextPurchases, auto];
        }

        // 3 onay geri çekildiğinde otomatik oluşturulan Gelen Malzeme + Satın Alma kayıtlarını sil
        // (status "delivered" geçişlerinde tetiklenmez — onaylar hâlâ tam)
        const justUnapproved =
          beforeAllChecked && !afterAllChecked;
        let nextMaterials = prev.materials;
        if (justUnapproved) {
          nextMaterials = nextMaterials.filter((m) => m.materialRequestId !== id);
          nextPurchases = nextPurchases.filter((p) => p.materialRequestId !== id);
          nextMaterialRequests = nextMaterialRequests.map((r) =>
            r.id === id ? { ...r, status: r.status === "approved" ? "pending" : r.status } : r
          );
        }
        const alreadyHasMaterial = nextMaterials.some((m) => m.materialRequestId === id);
        if (justApproved && !alreadyHasMaterial) {
          const today = new Date().toISOString().slice(0, 10);
          const autoMat: Material = {
            id: genId(),
            projectId: after.projectId,
            name: after.name,
            category: after.category || "",
            unit: after.unit || "",
            quantity: after.quantity || 0,
            usedQty: 0,
            supplier: "",
            deliveryDate: today,
            unitPrice: 0,
            description: after.note || "Malzeme talebinden otomatik oluşturuldu",
            materialRequestId: id,
          };
          nextMaterials = [...nextMaterials, autoMat];
        }

        return {
          ...prev,
          materialRequests: nextMaterialRequests,
          purchases: nextPurchases,
          materials: nextMaterials,
        };
      });
    }) as any,
    deleteMaterialRequest: makeDelete("materialRequests") as any,

    addMaterialMovement: makeAdd("materialMovements") as any,
    updateMaterialMovement: makeUpdate("materialMovements") as any,
    deleteMaterialMovement: makeDelete("materialMovements") as any,

    addSubcontractor: makeAdd("subcontractors") as any,
    updateSubcontractor: makeUpdate("subcontractors") as any,
    deleteSubcontractor: makeDelete("subcontractors") as any,

    addArchiveFile: makeAdd("archiveFiles") as any,
    updateArchiveFile: makeUpdate("archiveFiles") as any,
    deleteArchiveFile: makeDelete("archiveFiles") as any,

    addPurchase: ((p: Omit<Purchase, "id">) => {
      const id = genId();
      const created: Purchase = { ...(p as any), id };
      update((prev) => ({ ...prev, purchases: [...prev.purchases, created] }));
      return id;
    }) as any,
    updatePurchase: ((id: string, patch: Partial<Purchase>) => {
      update((prev) => ({
        ...prev,
        purchases: prev.purchases.map((x) => (x.id === id ? { ...x, ...patch } : x)),
      }));
    }) as any,
    deletePurchase: makeDelete("purchases") as any,
    markPurchasePaid: ((id: string, paidDate: string) => {
      update((prev) => ({
        ...prev,
        purchases: prev.purchases.map((x) =>
          x.id === id ? { ...x, status: "paid" as PurchaseStatus, paidDate } : x
        ),
      }));
    }) as any,
    addWeighbridge: makeAdd("weighbridges") as any,
    updateWeighbridge: makeUpdate("weighbridges") as any,
    deleteWeighbridge: ((id: string) => {
      update((prev) => ({
        ...prev,
        weighbridges: prev.weighbridges.filter((w) => w.id !== id),
        // Bu fişe bağlı malzemenin bağlantısını da temizle
        materials: prev.materials.map((m) =>
          m.kantarSlipId === id ? { ...m, kantarSlipId: undefined, writeToKantar: false } : m
        ),
      }));
    }) as any,

    markPurchaseInvoiceReceived: (id, received, invoiceNo) =>
      update((prev) => ({
        ...prev,
        purchases: prev.purchases.map((p) =>
          p.id === id
            ? {
                ...p,
                invoiceReceived: received,
                invoiceNo: invoiceNo !== undefined ? invoiceNo : p.invoiceNo,
              }
            : p
        ),
      })),

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

    addMaterialCategory: (name) =>
      update((prev) =>
        prev.materialCategories.some((c) => c.toLowerCase() === name.toLowerCase())
          ? prev
          : { ...prev, materialCategories: [...prev.materialCategories, name] }
      ),
    deleteMaterialCategory: (name) =>
      update((prev) => ({
        ...prev,
        materialCategories: prev.materialCategories.filter((c) => c !== name),
      })),

    addProfession: (name) =>
      update((prev) =>
        prev.professions.some((p) => p.toLowerCase() === name.toLowerCase())
          ? prev
          : { ...prev, professions: [...prev.professions, name] }
      ),
    updateProfession: (oldName, newName) =>
      update((prev) => ({
        ...prev,
        professions: prev.professions.map((p) => (p === oldName ? newName : p)),
        appUsers: prev.appUsers.map((u) =>
          u.profession === oldName ? { ...u, profession: newName } : u
        ),
      })),
    deleteProfession: (name) =>
      update((prev) => ({
        ...prev,
        professions: prev.professions.filter((p) => p !== name),
      })),
    moveProfession: (name, dir) =>
      update((prev) => {
        const arr = [...prev.professions];
        const i = arr.indexOf(name);
        const j = i + dir;
        if (i < 0 || j < 0 || j >= arr.length) return prev;
        [arr[i], arr[j]] = [arr[j], arr[i]];
        return { ...prev, professions: arr };
      }),

    addTradeGroup: (name) =>
      update((prev) =>
        prev.tradeGroups.some((p) => p.toLowerCase() === name.toLowerCase())
          ? prev
          : { ...prev, tradeGroups: [...prev.tradeGroups, name] }
      ),
    updateTradeGroup: (oldName, newName) =>
      update((prev) => ({
        ...prev,
        tradeGroups: prev.tradeGroups.map((p) => (p === oldName ? newName : p)),
      })),
    deleteTradeGroup: (name) =>
      update((prev) => ({
        ...prev,
        tradeGroups: prev.tradeGroups.filter((p) => p !== name),
      })),
    moveTradeGroup: (name, dir) =>
      update((prev) => {
        const arr = [...prev.tradeGroups];
        const i = arr.indexOf(name);
        const j = i + dir;
        if (i < 0 || j < 0 || j >= arr.length) return prev;
        [arr[i], arr[j]] = [arr[j], arr[i]];
        return { ...prev, tradeGroups: arr };
      }),
    resetTradeGroups: () =>
      update((prev) => ({ ...prev, tradeGroups: [...DEFAULT_TRADE_GROUPS] })),

    addMaterialItem: (item) =>
      update((prev) =>
        prev.materialList.some((m) => m.name.toLowerCase() === item.name.toLowerCase())
          ? prev
          : { ...prev, materialList: [...prev.materialList, item] }
      ),
    addImalatPoz: (poz) =>
      update((prev) =>
        prev.imalatPozlari.some((p) => p.code.toLowerCase() === poz.code.toLowerCase())
          ? prev
          : { ...prev, imalatPozlari: [...prev.imalatPozlari, poz] }
      ),
    updateImalatPoz: (code, patch) =>
      update((prev) => ({
        ...prev,
        imalatPozlari: prev.imalatPozlari.map((p) =>
          p.code === code ? { ...p, ...patch } : p
        ),
      })),
    deleteImalatPoz: (code) =>
      update((prev) => ({
        ...prev,
        imalatPozlari: prev.imalatPozlari.filter((p) => p.code !== code),
      })),

    deleteMaterialItem: (name) =>
      update((prev) => ({
        ...prev,
        materialList: prev.materialList.filter((m) => m.name !== name),
      })),

    addMaterialUnit: (unit) =>
      update((prev) =>
        prev.materialUnits.some((u) => u.code.toUpperCase() === unit.code.toUpperCase())
          ? prev
          : { ...prev, materialUnits: [...prev.materialUnits, unit] }
      ),
    deleteMaterialUnit: (code) =>
      update((prev) => ({
        ...prev,
        materialUnits: prev.materialUnits.filter((u) => u.code !== code),
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
            ? backfillRolePermissions(incoming.roles)
            : DEFAULT_ROLES,
          purchases: normalizePurchases(incoming.purchases),
          weighbridges: normalizeWeighbridges(incoming.weighbridges),
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
