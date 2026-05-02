import AsyncStorage from "@react-native-async-storage/async-storage";
import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";

import {
  BANKS,
  DEBT_CATEGORIES,
  EXPENSE_CATEGORIES,
  INCOME_CATEGORIES,
} from "@/utils/finans/categories";
import {
  DEFAULT_REMINDER_SETTINGS,
  rescheduleAllReminders,
  type ReminderSettings,
} from "@/utils/finans/notifications";

export type TransactionType = "income" | "expense" | "transfer";
export type PaymentMethod = "cash" | "card" | "transfer";

export interface Transaction {
  id: string;
  type: TransactionType;
  amount: number;
  category: string;
  note: string;
  date: string;
  paymentMethod?: PaymentMethod;
  bank?: string;
  // Number of installments for credit-card expenses. 1 (or undefined) = peşin.
  // The full `amount` is the total purchase price; per-installment math is
  // computed downstream (utils/statements).
  installmentCount?: number;
  // When set on a card expense, this txn is auto-deducted from the linked
  // BankLimit's availableLimit. Lets us know exactly which card to update
  // (the free-text `bank` field can be ambiguous if multiple cards share a name).
  bankLimitId?: string;
  // When set on a transfer expense/income, links to a savedCard (vadesiz hesap).
  savedCardId?: string;
  // Reconciliation/correction transactions skip auto-sync to avoid double-counting.
  // Created by "Bankayla Eşitle" flow on the Banka Limitleri screen.
  correction?: boolean;
  // Transfer fields: only set when type === "transfer"
  fromBank?: string;
  toBank?: string;
}

/**
 * How much should this transaction DECREASE the linked BankLimit's
 * availableLimit. Positive = decrease, negative = increase, 0 = no effect.
 *
 * Only card expenses tied to a tracked BankLimit (and not flagged as a
 * correction) participate in auto-sync.
 */
export function txAvailableLimitDelta(
  tx: Pick<
    Transaction,
    "bankLimitId" | "correction" | "paymentMethod" | "type" | "amount"
  >
): number {
  if (!tx.bankLimitId) return 0;
  if (tx.correction) return 0;
  if (tx.paymentMethod !== "card") return 0;
  if (tx.type !== "expense") return 0;
  if (!Number.isFinite(tx.amount) || tx.amount <= 0) return 0;
  return tx.amount;
}

export interface Payment {
  id: string;
  date: string;
  amount: number;
  txId?: string; // linked auto-created expense transaction
}

export interface MonthlyBreakdown {
  yearMonth: string;
  amount: number;
}

export interface Debt {
  id: string;
  name: string;
  category: string;
  creditor?: string;
  amount: number;
  paidAmount: number;
  date: string;
  dueDate?: string;
  isInstallment: boolean;
  totalInstallments?: number;
  paidInstallments?: number;
  paidInstallmentIndices?: number[];
  note?: string;
  payments: Payment[];
  monthlyBreakdowns?: MonthlyBreakdown[];
  paidBreakdownMonths?: string[]; // yearMonth strings marked as paid e.g. "2026-04"
  breakdownPaymentMap?: Record<string, string>; // yearMonth -> paymentId
  bankLimitId?: string; // links debt to a BankLimit (auto-managed for CC statements)
}

function migrateDebt(raw: any): Debt {
  const payments: Payment[] = Array.isArray(raw?.payments) ? raw.payments : [];
  const paidFromPayments = payments.reduce(
    (s, p) => s + (typeof p.amount === "number" ? p.amount : 0),
    0
  );
  return {
    id: String(raw?.id ?? Date.now() + Math.random()),
    name: String(raw?.name ?? "Borç"),
    category: typeof raw?.category === "string" ? raw.category : "Diğer",
    creditor: typeof raw?.creditor === "string" ? raw.creditor : undefined,
    amount: typeof raw?.amount === "number" ? raw.amount : 0,
    paidAmount:
      typeof raw?.paidAmount === "number"
        ? raw.paidAmount
        : paidFromPayments,
    date: typeof raw?.date === "string" ? raw.date : new Date().toISOString(),
    dueDate: typeof raw?.dueDate === "string" ? raw.dueDate : undefined,
    isInstallment: !!raw?.isInstallment,
    totalInstallments:
      typeof raw?.totalInstallments === "number"
        ? raw.totalInstallments
        : undefined,
    paidInstallments:
      typeof raw?.paidInstallments === "number"
        ? raw.paidInstallments
        : undefined,
    paidInstallmentIndices: Array.isArray(raw?.paidInstallmentIndices)
      ? raw.paidInstallmentIndices.filter(
          (n: unknown) => typeof n === "number"
        )
      : undefined,
    note: typeof raw?.note === "string" ? raw.note : undefined,
    payments,
    monthlyBreakdowns: Array.isArray(raw?.monthlyBreakdowns)
      ? raw.monthlyBreakdowns.filter(
          (b: any) => typeof b?.yearMonth === "string" && typeof b?.amount === "number"
        )
      : undefined,
    paidBreakdownMonths: Array.isArray(raw?.paidBreakdownMonths)
      ? raw.paidBreakdownMonths.filter((s: any) => typeof s === "string")
      : undefined,
    breakdownPaymentMap:
      raw?.breakdownPaymentMap && typeof raw.breakdownPaymentMap === "object" && !Array.isArray(raw.breakdownPaymentMap)
        ? (raw.breakdownPaymentMap as Record<string, string>)
        : undefined,
    bankLimitId: typeof raw?.bankLimitId === "string" ? raw.bankLimitId : undefined,
  };
}

export type BankLimitType = "credit" | "overdraft";

// One entry per statement period (yearMonth = month statement is CUT in).
// `manualAmount` overrides the auto-computed amount from transactions.
// `paidAmount` accumulates payments recorded against this statement.
export interface CardStatementEntry {
  yearMonth: string;
  manualAmount?: number;
  paidAmount: number;
  lastPaymentDate?: string;
}

export interface BankLimit {
  id: string;
  bank: string;
  institution?: string;
  savedCardId?: string;
  limit: number;
  availableLimit?: number;
  type: BankLimitType;
  note?: string;
  // Per-period overrides + payment tracking. Only meaningful for type="credit".
  cardStatements?: CardStatementEntry[];
}

export type AssetType = "vadesiz" | "vadeli" | "kripto" | "borsa" | "doviz" | "altin";

export interface AssetEntry {
  id: string;
  name: string;
  platform: string;
  assetType: AssetType;
  amount: number;       // toplam TRY değeri = unitPrice * quantity
  quantity?: number;    // birim miktarı (adet, gram, USD...)
  unitPrice?: number;   // birim başına TRY fiyatı (en son çekilen)
  note?: string;
  interestRate?: number;  // vadeli mevduat: yıllık faiz oranı (%)
  maturityDate?: string;  // vadeli mevduat: vade tarihi (ISO string)
}

export type SavedCardType = "credit" | "demand" | "time";

export interface SavedCard {
  id: string;
  name: string;
  bank: string;
  type: SavedCardType;
  cardLast4?: string;
  accountNumber?: string; // legacy: kept for backward compatibility
  iban?: string;          // IBAN (opsiyonel), sadece vadesiz hesaplar için
  statementDay?: number;  // 1-31, only for credit cards
  dueDay?: number;        // 1-31, derived = statementDay + 11
  balance?: number;       // Current balance
  interestRate?: number;  // vadeli hesap: faiz oranı (%)
  maturityDate?: string;  // vadeli hesap: vade tarihi (ISO string)
  openDate?: string;      // vadeli hesap: açılış tarihi (ISO string)
}

// Compute due day from statement day. Adds 11 days using a 31-day
// reference month so wrap-around mirrors a calendar day.
export function computeDueDay(statementDay: number | undefined | null): number | undefined {
  if (
    statementDay === undefined ||
    statementDay === null ||
    !Number.isFinite(statementDay) ||
    statementDay < 1 ||
    statementDay > 31
  ) {
    return undefined;
  }
  const ref = new Date(2024, 0, Math.floor(statementDay)); // Jan 2024 (31 days)
  ref.setDate(ref.getDate() + 11);
  return ref.getDate();
}

export interface CashFlowEntry {
  id: string;
  bank: string;       // Kart / banka adı
  yearMonth: string;  // "2026-04"
  amount: number;
  note?: string;
}

export interface BudgetContextType {
  transactions: Transaction[];
  addTransaction: (tx: Omit<Transaction, "id">) => void;
  updateTransaction: (id: string, patch: Partial<Omit<Transaction, "id">>) => void;
  deleteTransaction: (id: string) => void;
  addTransfer: (opts: { amount: number; fromBank: string; toBank: string; note?: string; date: string }) => void;
  totalIncome: number;
  totalExpense: number;
  balance: number;
  debts: Debt[];
  addDebt: (d: Omit<Debt, "id" | "payments"> & { payments?: Payment[] }) => void;
  updateDebt: (id: string, patch: Partial<Omit<Debt, "id">>) => void;
  deleteDebt: (id: string) => void;
  addPayment: (debtId: string, amount: number, date: string) => void;
  updatePayment: (debtId: string, paymentId: string, amount: number, date: string) => void;
  deletePayment: (debtId: string, paymentId: string) => void;
  toggleInstallmentPaid: (debtId: string, index: number) => void;
  toggleBreakdownPaid: (debtId: string, yearMonth: string) => void;
  totalDebt: number;
  totalDebtRemaining: number;
  customDebtCategories: string[];
  addDebtCategory: (label: string) => void;
  expenseCategoryList: string[];
  addExpenseCategory: (label: string) => void;
  removeExpenseCategory: (label: string) => void;
  incomeCategoryList: string[];
  addIncomeCategory: (label: string) => void;
  removeIncomeCategory: (label: string) => void;
  // Kategori kullanım sayacı: en sık kullanılanları üste taşımak için
  categoryUsage: {
    expense: Record<string, number>;
    income: Record<string, number>;
  };
  // Yeniden adlandırma / birleştirme: target zaten varsa merge etkisi
  // Tüm referanslar (transactions / debts / bankLimits / savedCards) güncellenir
  renameOrMergeExpenseCategory: (from: string, to: string) => void;
  renameOrMergeIncomeCategory: (from: string, to: string) => void;
  renameOrMergeDebtCategory: (from: string, to: string) => void;
  renameOrMergeBank: (from: string, to: string) => void;
  allDebtCategories: { label: string; icon: string }[];
  removeDebtCategory: (label: string) => void;
  allBanks: string[];
  addBank: (name: string) => void;
  removeBank: (name: string) => void;
  bankLimits: BankLimit[];
  addBankLimit: (b: Omit<BankLimit, "id">) => void;
  updateBankLimit: (id: string, patch: Partial<Omit<BankLimit, "id">>) => void;
  deleteBankLimit: (id: string) => void;
  // "Bankayla Eşitle": set the card's availableLimit to the value the user sees
  // in their bank app, and record the difference as a correction transaction
  // so that overall balance stays accurate.
  reconcileBankLimit: (
    bankLimitId: string,
    newAvailableLimit: number,
    dateISO?: string
  ) => void;
  getDebtForBankLimit: (bankLimitId: string) => Debt | undefined;
  addBankLimitBreakdown: (bankLimit: BankLimit, yearMonth: string, amount: number) => void;
  updateBankLimitBreakdown: (bankLimitId: string, yearMonth: string, amount: number) => void;
  removeBankLimitBreakdown: (bankLimitId: string, yearMonth: string) => void;
  // New CC statement APIs (Apr 2026 refactor)
  setManualStatementAmount: (
    bankLimitId: string,
    yearMonth: string,
    amount: number | null
  ) => void;
  recordStatementPayment: (
    bankLimitId: string,
    yearMonth: string,
    amount: number,
    date: string
  ) => void;
  resetStatementPayment: (bankLimitId: string, yearMonth: string) => void;
  savedCards: SavedCard[];
  addSavedCard: (c: Omit<SavedCard, "id">) => string;
  updateSavedCard: (id: string, patch: Partial<Omit<SavedCard, "id">>) => void;
  deleteSavedCard: (id: string) => void;
  assetEntries: AssetEntry[];
  addAssetEntry: (e: Omit<AssetEntry, "id">) => void;
  updateAssetEntry: (id: string, patch: Partial<Omit<AssetEntry, "id">>) => void;
  deleteAssetEntry: (id: string) => void;
  cashFlowEntries: CashFlowEntry[];
  addCashFlowEntry: (e: Omit<CashFlowEntry, "id">) => void;
  updateCashFlowEntry: (id: string, patch: Partial<Omit<CashFlowEntry, "id">>) => void;
  deleteCashFlowEntry: (id: string) => void;
  exportData: () => string;
  importData: (json: string, mode: "replace" | "merge") => {
    txCount: number;
    debtCount: number;
  };
  clearAllData: () => void;
  reminderSettings: ReminderSettings;
  updateReminderSettings: (patch: Partial<ReminderSettings>) => void;
}

const STORAGE_KEY = "@budget_transactions";
const DEBTS_STORAGE_KEY = "@budget_debts";
const DEBT_CATS_STORAGE_KEY = "@budget_debt_categories";
const BANK_LIMITS_STORAGE_KEY = "@budget_bank_limits";
const SAVED_CARDS_STORAGE_KEY = "@budget_saved_cards";
const CASH_FLOW_STORAGE_KEY = "@budget_cashflow_entries";
const EXPENSE_CATS_KEY = "@budget_expense_cats";
const INCOME_CATS_KEY = "@budget_income_cats";
const REMOVED_DEBT_DEFAULTS_KEY = "@budget_removed_debt_defaults";
const CUSTOM_BANKS_KEY = "@budget_custom_banks";
const PAYMENT_MIGRATION_KEY = "@budget_payment_migration_v1";
const CC_REFACTOR_MIGRATION_KEY = "@budget_cc_refactor_v1";
const REMINDER_SETTINGS_KEY = "@budget_reminder_settings";
const ASSETS_STORAGE_KEY = "@budget_asset_entries";
const CATEGORY_USAGE_KEY = "@budget_category_usage";

const BudgetContext = createContext<BudgetContextType | null>(null);

export function BudgetProvider({ children }: { children: React.ReactNode }) {
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [debts, setDebts] = useState<Debt[]>([]);
  const [customDebtCategories, setCustomDebtCategories] = useState<string[]>([]);
  const [bankLimits, setBankLimits] = useState<BankLimit[]>([]);
  const [savedCards, setSavedCards] = useState<SavedCard[]>([]);
  const [assetEntries, setAssetEntries] = useState<AssetEntry[]>([]);
  const [cashFlowEntries, setCashFlowEntries] = useState<CashFlowEntry[]>([]);
  const [expenseCategoryList, setExpenseCategoryList] = useState<string[]>([]);
  const [incomeCategoryList, setIncomeCategoryList] = useState<string[]>([]);
  const [removedDebtDefaults, setRemovedDebtDefaults] = useState<string[]>([]);
  const [customBankList, setCustomBankList] = useState<string[]>([]);
  const [reminderSettings, setReminderSettings] = useState<ReminderSettings>(
    DEFAULT_REMINDER_SETTINGS,
  );
  const [reminderSettingsHydrated, setReminderSettingsHydrated] = useState(false);
  const [categoryUsage, setCategoryUsage] = useState<{
    expense: Record<string, number>;
    income: Record<string, number>;
  }>({ expense: {}, income: {} });

  useEffect(() => {
    AsyncStorage.getItem(STORAGE_KEY).then((raw) => {
      if (raw) {
        try {
          setTransactions(JSON.parse(raw));
        } catch {}
      }
    });
    AsyncStorage.getItem(DEBTS_STORAGE_KEY).then((raw) => {
      if (raw) {
        try {
          const parsed = JSON.parse(raw);
          if (Array.isArray(parsed)) {
            setDebts(parsed.map(migrateDebt));
          }
        } catch {}
      }
    });
    AsyncStorage.getItem(BANK_LIMITS_STORAGE_KEY).then((raw) => {
      if (raw) {
        try {
          const parsed = JSON.parse(raw);
          if (Array.isArray(parsed)) {
            setBankLimits(
              parsed
                .filter(
                  (b: any) =>
                    b && typeof b.bank === "string" && typeof b.limit === "number"
                )
                .map((b: any) => ({
                  id: String(b.id ?? Date.now() + Math.random()),
                  bank: b.bank,
                  institution:
                    typeof b.institution === "string" ? b.institution : undefined,
                  savedCardId:
                    typeof b.savedCardId === "string" ? b.savedCardId : undefined,
                  limit: b.limit,
                  availableLimit:
                    typeof b.availableLimit === "number"
                      ? b.availableLimit
                      : undefined,
                  type: b.type === "overdraft" ? "overdraft" : "credit",
                  note: typeof b.note === "string" ? b.note : undefined,
                  cardStatements: Array.isArray(b.cardStatements)
                    ? b.cardStatements
                        .filter(
                          (e: any) =>
                            e &&
                            typeof e.yearMonth === "string" &&
                            typeof e.paidAmount === "number"
                        )
                        .map((e: any) => ({
                          yearMonth: String(e.yearMonth),
                          manualAmount:
                            typeof e.manualAmount === "number"
                              ? e.manualAmount
                              : undefined,
                          paidAmount: Number(e.paidAmount) || 0,
                          lastPaymentDate:
                            typeof e.lastPaymentDate === "string"
                              ? e.lastPaymentDate
                              : undefined,
                        }))
                    : undefined,
                }))
            );
          }
        } catch {}
      }
    });
    AsyncStorage.getItem(SAVED_CARDS_STORAGE_KEY).then((raw) => {
      if (raw) {
        try {
          const parsed = JSON.parse(raw);
          if (Array.isArray(parsed)) {
            setSavedCards(
              parsed
                .filter((c: any) => c && typeof c.id === "string" && typeof c.name === "string" && typeof c.bank === "string")
                .map((c: any) => {
                  const stDay =
                    typeof c.statementDay === "number" &&
                    c.statementDay >= 1 &&
                    c.statementDay <= 31
                      ? Math.floor(c.statementDay)
                      : undefined;
                  return {
                    id: String(c.id),
                    name: String(c.name),
                    bank: String(c.bank),
                    type: c.type === "demand" ? "demand" : c.type === "time" ? "time" : "credit",
                    cardLast4: typeof c.cardLast4 === "string" ? c.cardLast4 : undefined,
                    accountNumber: typeof c.accountNumber === "string" ? c.accountNumber : undefined,
                    iban: typeof c.iban === "string" ? c.iban : undefined,
                    statementDay: stDay,
                    dueDay: computeDueDay(stDay),
                    balance:
                      typeof c.balance === "number" && Number.isFinite(c.balance)
                        ? c.balance
                        : undefined,
                    interestRate:
                      typeof c.interestRate === "number" && Number.isFinite(c.interestRate)
                        ? c.interestRate
                        : undefined,
                    maturityDate: typeof c.maturityDate === "string" ? c.maturityDate : undefined,
                    openDate: typeof c.openDate === "string" ? c.openDate : undefined,
                  } as SavedCard;
                })
            );
          }
        } catch {}
      }
    });
    AsyncStorage.getItem(CASH_FLOW_STORAGE_KEY).then((raw) => {
      if (raw) {
        try {
          const parsed = JSON.parse(raw);
          if (Array.isArray(parsed)) {
            setCashFlowEntries(
              parsed
                .filter(
                  (e: any) =>
                    e &&
                    typeof e.bank === "string" &&
                    typeof e.yearMonth === "string" &&
                    typeof e.amount === "number"
                )
                .map((e: any) => ({
                  id: String(e.id ?? Date.now() + Math.random()),
                  bank: e.bank,
                  yearMonth: e.yearMonth,
                  amount: e.amount,
                  note: typeof e.note === "string" ? e.note : undefined,
                }))
            );
          }
        } catch {}
      }
    });
    AsyncStorage.getItem(DEBT_CATS_STORAGE_KEY).then((raw) => {
      if (raw) {
        try {
          const parsed = JSON.parse(raw);
          if (Array.isArray(parsed)) {
            setCustomDebtCategories(
              parsed.filter((s: unknown) => typeof s === "string")
            );
          }
        } catch {}
      }
    });
    AsyncStorage.getItem(EXPENSE_CATS_KEY).then((raw) => {
      if (raw) {
        try {
          const parsed = JSON.parse(raw);
          if (Array.isArray(parsed)) {
            setExpenseCategoryList(parsed.filter((s: unknown) => typeof s === "string"));
            return;
          }
        } catch {}
      }
      setExpenseCategoryList(EXPENSE_CATEGORIES.map((c) => c.label));
    });
    AsyncStorage.getItem(INCOME_CATS_KEY).then((raw) => {
      if (raw) {
        try {
          const parsed = JSON.parse(raw);
          if (Array.isArray(parsed)) {
            setIncomeCategoryList(parsed.filter((s: unknown) => typeof s === "string"));
            return;
          }
        } catch {}
      }
      setIncomeCategoryList(INCOME_CATEGORIES.map((c) => c.label));
    });
    AsyncStorage.getItem(REMOVED_DEBT_DEFAULTS_KEY).then((raw) => {
      if (raw) {
        try {
          const parsed = JSON.parse(raw);
          if (Array.isArray(parsed)) {
            setRemovedDebtDefaults(parsed.filter((s: unknown) => typeof s === "string"));
          }
        } catch {}
      }
    });
    AsyncStorage.getItem(CUSTOM_BANKS_KEY).then((raw) => {
      if (raw) {
        try {
          const parsed = JSON.parse(raw);
          if (Array.isArray(parsed)) {
            setCustomBankList(parsed.filter((s: unknown) => typeof s === "string"));
          }
        } catch {}
      }
    });
    AsyncStorage.getItem(CATEGORY_USAGE_KEY).then((raw) => {
      if (!raw) return;
      try {
        const parsed = JSON.parse(raw);
        if (parsed && typeof parsed === "object") {
          const sanitize = (
            v: unknown
          ): Record<string, number> => {
            if (!v || typeof v !== "object") return {};
            const out: Record<string, number> = {};
            for (const [k, val] of Object.entries(v as Record<string, unknown>)) {
              if (typeof val === "number" && Number.isFinite(val) && val > 0) {
                out[k] = Math.floor(val);
              }
            }
            return out;
          };
          setCategoryUsage({
            expense: sanitize((parsed as { expense?: unknown }).expense),
            income: sanitize((parsed as { income?: unknown }).income),
          });
        }
      } catch {}
    });
    AsyncStorage.getItem(REMINDER_SETTINGS_KEY)
      .then((raw) => {
        if (!raw) return;
        try {
          const parsed = JSON.parse(raw);
          if (!parsed || typeof parsed !== "object") return;
          const safe: ReminderSettings = {
            enabled:
              typeof parsed.enabled === "boolean"
                ? parsed.enabled
                : DEFAULT_REMINDER_SETTINGS.enabled,
            ccDueReminder:
              typeof parsed.ccDueReminder === "boolean"
                ? parsed.ccDueReminder
                : DEFAULT_REMINDER_SETTINGS.ccDueReminder,
            ccDueDaysBefore:
              typeof parsed.ccDueDaysBefore === "number" &&
              parsed.ccDueDaysBefore >= 0 &&
              parsed.ccDueDaysBefore <= 30
                ? Math.floor(parsed.ccDueDaysBefore)
                : DEFAULT_REMINDER_SETTINGS.ccDueDaysBefore,
            ccStatementReminder:
              typeof parsed.ccStatementReminder === "boolean"
                ? parsed.ccStatementReminder
                : DEFAULT_REMINDER_SETTINGS.ccStatementReminder,
            debtDueReminder:
              typeof parsed.debtDueReminder === "boolean"
                ? parsed.debtDueReminder
                : DEFAULT_REMINDER_SETTINGS.debtDueReminder,
            debtDueDaysBefore:
              typeof parsed.debtDueDaysBefore === "number" &&
              parsed.debtDueDaysBefore >= 0 &&
              parsed.debtDueDaysBefore <= 30
                ? Math.floor(parsed.debtDueDaysBefore)
                : DEFAULT_REMINDER_SETTINGS.debtDueDaysBefore,
            reminderHour:
              typeof parsed.reminderHour === "number" &&
              parsed.reminderHour >= 0 &&
              parsed.reminderHour <= 23
                ? Math.floor(parsed.reminderHour)
                : DEFAULT_REMINDER_SETTINGS.reminderHour,
          };
          setReminderSettings(safe);
        } catch {}
      })
      .finally(() => setReminderSettingsHydrated(true));

    AsyncStorage.getItem(ASSETS_STORAGE_KEY).then((raw) => {
      if (raw) {
        try {
          const parsed = JSON.parse(raw);
          if (Array.isArray(parsed)) setAssetEntries(parsed);
        } catch {}
      }
    });

    // One-time migration: create expense transactions for existing payment records
    AsyncStorage.getItem(PAYMENT_MIGRATION_KEY).then(async (done) => {
      if (done === "1") return;

      const [rawDebts, rawTx] = await Promise.all([
        AsyncStorage.getItem(DEBTS_STORAGE_KEY),
        AsyncStorage.getItem(STORAGE_KEY),
      ]);

      const debtsData: Debt[] = rawDebts
        ? (() => { try { const p = JSON.parse(rawDebts); return Array.isArray(p) ? p.map(migrateDebt) : []; } catch { return []; } })()
        : [];

      const existingTx: Transaction[] = rawTx
        ? (() => { try { const p = JSON.parse(rawTx); return Array.isArray(p) ? p : []; } catch { return []; } })()
        : [];

      const migrationTx: Transaction[] = [];

      for (const d of debtsData) {
        if (d.payments.length > 0) {
          // Migrate explicit payment records (regular & installment debts paid via addPayment)
          for (const p of d.payments) {
            migrationTx.push({
              id: `mig_pay_${p.id}`,
              type: "expense",
              amount: p.amount,
              category: d.category,
              note: d.name,
              date: p.date,
              paymentMethod: d.category.toLowerCase() === "kredi kartı" ? "card" : "cash",
              ...(d.creditor ? { bank: d.creditor } : {}),
            });
          }
        } else if (
          d.isInstallment &&
          d.totalInstallments &&
          d.paidInstallmentIndices &&
          d.paidInstallmentIndices.length > 0
        ) {
          // Migrate toggled installments (no payment records exist)
          const perInstallment = d.amount / d.totalInstallments;
          for (const idx of d.paidInstallmentIndices) {
            const instDate = new Date(d.date);
            instDate.setMonth(instDate.getMonth() + idx);
            migrationTx.push({
              id: `mig_inst_${d.id}_${idx}`,
              type: "expense",
              amount: perInstallment,
              category: d.category,
              note: `${d.name} - Taksit ${idx + 1}/${d.totalInstallments}`,
              date: instDate.toISOString(),
              paymentMethod: d.category.toLowerCase() === "kredi kartı" ? "card" : "cash",
              ...(d.creditor ? { bank: d.creditor } : {}),
            });
          }
        }
      }

      if (migrationTx.length > 0) {
        const merged = [...migrationTx, ...existingTx];
        await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(merged));
        setTransactions(merged);
      }

      await AsyncStorage.setItem(PAYMENT_MIGRATION_KEY, "1");
    });

    // One-time CC refactor migration: wipe old auto-managed CC debts +
    // monthlyBreakdowns. CC borç artık BankLimit'ten türetilen tek doğruluk
    // kaynağıyla yönetiliyor (Apr 2026 refactor — D=1 wipe).
    AsyncStorage.getItem(CC_REFACTOR_MIGRATION_KEY).then(async (done) => {
      if (done === "1") return;

      const rawDebts = await AsyncStorage.getItem(DEBTS_STORAGE_KEY);
      if (rawDebts) {
        try {
          const parsed = JSON.parse(rawDebts);
          if (Array.isArray(parsed)) {
            const cleaned = parsed
              // Drop auto-managed CC debts (those linked to a BankLimit)
              .filter(
                (d: any) =>
                  !(
                    d &&
                    typeof d.bankLimitId === "string" &&
                    d.bankLimitId.length > 0
                  )
              )
              // Strip breakdown fields from any remaining debts
              .map((d: any) => {
                if (!d || typeof d !== "object") return d;
                const {
                  monthlyBreakdowns: _mb,
                  paidBreakdownMonths: _pbm,
                  breakdownPaymentMap: _bpm,
                  ...rest
                } = d;
                return rest;
              });
            await AsyncStorage.setItem(
              DEBTS_STORAGE_KEY,
              JSON.stringify(cleaned)
            );
            setDebts(cleaned.map(migrateDebt));
          }
        } catch {}
      }

      await AsyncStorage.setItem(CC_REFACTOR_MIGRATION_KEY, "1");
    });
  }, []);

  const addDebtCategory = useCallback((label: string) => {
    const trimmed = label.trim();
    if (!trimmed) return;
    setCustomDebtCategories((prev) => {
      if (prev.includes(trimmed)) return prev;
      const updated = [...prev, trimmed];
      AsyncStorage.setItem(DEBT_CATS_STORAGE_KEY, JSON.stringify(updated));
      return updated;
    });
  }, []);

  const addExpenseCategory = useCallback((label: string) => {
    const trimmed = label.trim();
    if (!trimmed) return;
    setExpenseCategoryList((prev) => {
      if (prev.includes(trimmed)) return prev;
      const next = [...prev, trimmed];
      AsyncStorage.setItem(EXPENSE_CATS_KEY, JSON.stringify(next));
      return next;
    });
  }, []);

  const removeExpenseCategory = useCallback((label: string) => {
    setExpenseCategoryList((prev) => {
      const next = prev.filter((l) => l !== label);
      AsyncStorage.setItem(EXPENSE_CATS_KEY, JSON.stringify(next));
      return next;
    });
  }, []);

  const addIncomeCategory = useCallback((label: string) => {
    const trimmed = label.trim();
    if (!trimmed) return;
    setIncomeCategoryList((prev) => {
      if (prev.includes(trimmed)) return prev;
      const next = [...prev, trimmed];
      AsyncStorage.setItem(INCOME_CATS_KEY, JSON.stringify(next));
      return next;
    });
  }, []);

  const removeIncomeCategory = useCallback((label: string) => {
    setIncomeCategoryList((prev) => {
      const next = prev.filter((l) => l !== label);
      AsyncStorage.setItem(INCOME_CATS_KEY, JSON.stringify(next));
      return next;
    });
  }, []);

  const allBanks = useMemo(
    () => Array.from(new Set([...BANKS, ...customBankList])),
    [customBankList]
  );

  const addBank = useCallback((name: string) => {
    const trimmed = name.trim();
    if (!trimmed) return;
    setCustomBankList((prev) => {
      if (prev.includes(trimmed) || BANKS.includes(trimmed)) return prev;
      const next = [...prev, trimmed];
      AsyncStorage.setItem(CUSTOM_BANKS_KEY, JSON.stringify(next));
      return next;
    });
  }, []);

  const removeBank = useCallback((name: string) => {
    setCustomBankList((prev) => {
      const next = prev.filter((b) => b !== name);
      AsyncStorage.setItem(CUSTOM_BANKS_KEY, JSON.stringify(next));
      return next;
    });
  }, []);

  const removeDebtCategory = useCallback(
    (label: string) => {
      const defaultLabels = DEBT_CATEGORIES.map((c) => c.label);
      if (defaultLabels.includes(label)) {
        setRemovedDebtDefaults((prev) => {
          if (prev.includes(label)) return prev;
          const next = [...prev, label];
          AsyncStorage.setItem(REMOVED_DEBT_DEFAULTS_KEY, JSON.stringify(next));
          return next;
        });
      } else {
        setCustomDebtCategories((prev) => {
          const next = prev.filter((l) => l !== label);
          AsyncStorage.setItem(DEBT_CATS_STORAGE_KEY, JSON.stringify(next));
          return next;
        });
      }
    },
    []
  );

  const allDebtCategories = useMemo(
    () => [
      ...DEBT_CATEGORIES.filter((d) => !removedDebtDefaults.includes(d.label)),
      ...customDebtCategories.map((c) => ({ label: c, icon: "tag" as const })),
    ],
    [customDebtCategories, removedDebtDefaults]
  );

  // ── Yeniden adlandır / birleştir helpers ─────────────────────────────────
  // Target zaten varsa "merge" davranışı (eski kategoriye ait tüm referanslar
  // hedefe taşınır, eski kategori listeden silinir).
  const renameOrMergeExpenseCategory = useCallback(
    (from: string, to: string) => {
      const f = from.trim();
      const t = to.trim();
      if (!f || !t || f === t) return;
      // Liste güncellemesi
      setExpenseCategoryList((prev) => {
        const without = prev.filter((l) => l !== f);
        const next = without.includes(t) ? without : [...without, t];
        AsyncStorage.setItem(EXPENSE_CATS_KEY, JSON.stringify(next));
        return next;
      });
      // İşlemleri yeniden etiketle
      setTransactions((prev) => {
        let changed = false;
        const updated = prev.map((tx) => {
          if (tx.type === "expense" && tx.category === f) {
            changed = true;
            return { ...tx, category: t };
          }
          return tx;
        });
        if (!changed) return prev;
        AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
        return updated;
      });
      // Kullanım sayacını taşı
      setCategoryUsage((prev) => {
        const fromCount = prev.expense[f] ?? 0;
        if (fromCount === 0 && !(t in prev.expense)) return prev;
        const nextBucket = { ...prev.expense };
        delete nextBucket[f];
        if (fromCount > 0) {
          nextBucket[t] = (nextBucket[t] ?? 0) + fromCount;
        }
        const next = { ...prev, expense: nextBucket };
        AsyncStorage.setItem(CATEGORY_USAGE_KEY, JSON.stringify(next));
        return next;
      });
    },
    []
  );

  const renameOrMergeIncomeCategory = useCallback(
    (from: string, to: string) => {
      const f = from.trim();
      const t = to.trim();
      if (!f || !t || f === t) return;
      setIncomeCategoryList((prev) => {
        const without = prev.filter((l) => l !== f);
        const next = without.includes(t) ? without : [...without, t];
        AsyncStorage.setItem(INCOME_CATS_KEY, JSON.stringify(next));
        return next;
      });
      setTransactions((prev) => {
        let changed = false;
        const updated = prev.map((tx) => {
          if (tx.type === "income" && tx.category === f) {
            changed = true;
            return { ...tx, category: t };
          }
          return tx;
        });
        if (!changed) return prev;
        AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
        return updated;
      });
      setCategoryUsage((prev) => {
        const fromCount = prev.income[f] ?? 0;
        if (fromCount === 0 && !(t in prev.income)) return prev;
        const nextBucket = { ...prev.income };
        delete nextBucket[f];
        if (fromCount > 0) {
          nextBucket[t] = (nextBucket[t] ?? 0) + fromCount;
        }
        const next = { ...prev, income: nextBucket };
        AsyncStorage.setItem(CATEGORY_USAGE_KEY, JSON.stringify(next));
        return next;
      });
    },
    []
  );

  const renameOrMergeDebtCategory = useCallback(
    (from: string, to: string) => {
      const f = from.trim();
      const t = to.trim();
      if (!f || !t || f === t) return;
      const defaultLabels = DEBT_CATEGORIES.map((c) => c.label);

      // 1) Eski default ise gizlenenler listesine ekle
      if (defaultLabels.includes(f)) {
        setRemovedDebtDefaults((prev) => {
          if (prev.includes(f)) return prev;
          const next = [...prev, f];
          AsyncStorage.setItem(REMOVED_DEBT_DEFAULTS_KEY, JSON.stringify(next));
          return next;
        });
      }
      // 2) Eski custom ise listeden çıkar
      setCustomDebtCategories((prev) => {
        const next = prev.filter((l) => l !== f);
        if (next.length === prev.length) return prev;
        AsyncStorage.setItem(DEBT_CATS_STORAGE_KEY, JSON.stringify(next));
        return next;
      });
      // 3) Yeni default ise gizlenenlerden geri al; değilse custom'a ekle
      if (defaultLabels.includes(t)) {
        setRemovedDebtDefaults((prev) => {
          const next = prev.filter((l) => l !== t);
          if (next.length === prev.length) return prev;
          AsyncStorage.setItem(REMOVED_DEBT_DEFAULTS_KEY, JSON.stringify(next));
          return next;
        });
      } else {
        setCustomDebtCategories((prev) => {
          if (prev.includes(t)) return prev;
          const next = [...prev, t];
          AsyncStorage.setItem(DEBT_CATS_STORAGE_KEY, JSON.stringify(next));
          return next;
        });
      }
      // 4) Borçları yeniden etiketle
      setDebts((prev) => {
        let changed = false;
        const updated = prev.map((d) => {
          if (d.category === f) {
            changed = true;
            return { ...d, category: t };
          }
          return d;
        });
        if (!changed) return prev;
        AsyncStorage.setItem(DEBTS_STORAGE_KEY, JSON.stringify(updated));
        return updated;
      });
    },
    []
  );

  const renameOrMergeBank = useCallback(
    (from: string, to: string) => {
      const f = from.trim();
      const t = to.trim();
      if (!f || !t || f === t) return;
      // Varsayılan banka kaynak olarak değiştirilemez (silinemediği gibi)
      if (BANKS.includes(f)) return;
      // Yeniyi custom listeye ekle (eğer default değilse)
      if (!BANKS.includes(t)) {
        setCustomBankList((prev) => {
          if (prev.includes(t)) return prev;
          const next = [...prev, t];
          AsyncStorage.setItem(CUSTOM_BANKS_KEY, JSON.stringify(next));
          return next;
        });
      }
      // Eskiyi custom listeden sil
      setCustomBankList((prev) => {
        const next = prev.filter((b) => b !== f);
        if (next.length === prev.length) return prev;
        AsyncStorage.setItem(CUSTOM_BANKS_KEY, JSON.stringify(next));
        return next;
      });
      // Cascade: işlemler
      setTransactions((prev) => {
        let changed = false;
        const updated = prev.map((tx) => {
          if (tx.bank === f) {
            changed = true;
            return { ...tx, bank: t };
          }
          return tx;
        });
        if (!changed) return prev;
        AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
        return updated;
      });
      // Cascade: banka limitleri (hem `bank` hem opsiyonel `institution` alanı)
      setBankLimits((prev) => {
        let changed = false;
        const updated = prev.map((bl) => {
          let next = bl;
          if (bl.bank === f) {
            next = { ...next, bank: t };
            changed = true;
          }
          if (bl.institution === f) {
            next = { ...next, institution: t };
            changed = true;
          }
          return next;
        });
        if (!changed) return prev;
        AsyncStorage.setItem(BANK_LIMITS_STORAGE_KEY, JSON.stringify(updated));
        return updated;
      });
      // Cascade: kayıtlı kartlar
      setSavedCards((prev) => {
        let changed = false;
        const updated = prev.map((sc) => {
          if (sc.bank === f) {
            changed = true;
            return { ...sc, bank: t };
          }
          return sc;
        });
        if (!changed) return prev;
        AsyncStorage.setItem(SAVED_CARDS_STORAGE_KEY, JSON.stringify(updated));
        return updated;
      });
    },
    []
  );

  // Apply a signed delta to a BankLimit's availableLimit.
  // `decrease` positive = card was charged (less credit available).
  // `decrease` negative = card was paid back (more credit available).
  // No clamping — delete/edit must be perfectly reversible. Negative
  // availableLimit is rendered as "over limit" (red) in the UI; values
  // above `limit` mean the user is in credit (rare but valid).
  const applyAvailableLimitDelta = useCallback(
    (bankLimitId: string, decrease: number) => {
      if (!bankLimitId || !Number.isFinite(decrease) || decrease === 0) return;
      setBankLimits((prev) => {
        const updated = prev.map((b) => {
          if (b.id !== bankLimitId) return b;
          const cur =
            typeof b.availableLimit === "number" && Number.isFinite(b.availableLimit)
              ? b.availableLimit
              : b.limit;
          return { ...b, availableLimit: cur - decrease };
        });
        AsyncStorage.setItem(BANK_LIMITS_STORAGE_KEY, JSON.stringify(updated));
        return updated;
      });
    },
    []
  );

  const addTransfer = useCallback(
    (opts: { amount: number; fromBank: string; toBank: string; note?: string; date: string }) => {
      const tx: Transaction = {
        id: Date.now().toString() + Math.random().toString(36).substr(2, 6),
        type: "transfer",
        amount: opts.amount,
        category: "Transfer",
        note: opts.note ?? "",
        date: opts.date,
        fromBank: opts.fromBank,
        toBank: opts.toBank,
      };
      setTransactions((prev) => {
        const updated = [tx, ...prev];
        AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
        return updated;
      });
    },
    []
  );

  const addTransaction = useCallback(
    (tx: Omit<Transaction, "id">) => {
      const newTx: Transaction = {
        ...tx,
        id: Date.now().toString() + Math.random().toString(36).substr(2, 6),
      };
      setTransactions((prev) => {
        const updated = [newTx, ...prev];
        AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
        return updated;
      });
      // Auto-sync to BankLimit.availableLimit for tracked card expenses.
      const delta = txAvailableLimitDelta(newTx);
      if (delta > 0 && newTx.bankLimitId) {
        applyAvailableLimitDelta(newTx.bankLimitId, delta);
      }
      // Kategori kullanım sayacı: en sık kullanılanlar üste çıksın diye
      if (newTx.category && (newTx.type === "expense" || newTx.type === "income")) {
        setCategoryUsage((prev) => {
          const bucket = newTx.type === "expense" ? prev.expense : prev.income;
          const nextBucket = {
            ...bucket,
            [newTx.category]: (bucket[newTx.category] ?? 0) + 1,
          };
          const next =
            newTx.type === "expense"
              ? { ...prev, expense: nextBucket }
              : { ...prev, income: nextBucket };
          AsyncStorage.setItem(CATEGORY_USAGE_KEY, JSON.stringify(next));
          return next;
        });
      }
    },
    [applyAvailableLimitDelta]
  );

  const updateTransaction = useCallback(
    (id: string, patch: Partial<Omit<Transaction, "id">>) => {
      setTransactions((prev) => {
        const old = prev.find((t) => t.id === id);
        if (!old) return prev;
        const newTx = { ...old, ...patch } as Transaction;
        const oldDelta = txAvailableLimitDelta(old);
        const newDelta = txAvailableLimitDelta(newTx);
        // Reverse old effect, apply new effect (per-card).
        if (old.bankLimitId === newTx.bankLimitId) {
          if (oldDelta !== newDelta && newTx.bankLimitId) {
            applyAvailableLimitDelta(newTx.bankLimitId, newDelta - oldDelta);
          }
        } else {
          if (oldDelta > 0 && old.bankLimitId) {
            applyAvailableLimitDelta(old.bankLimitId, -oldDelta);
          }
          if (newDelta > 0 && newTx.bankLimitId) {
            applyAvailableLimitDelta(newTx.bankLimitId, newDelta);
          }
        }
        const updated = prev.map((t) => (t.id === id ? newTx : t));
        AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
        return updated;
      });
    },
    [applyAvailableLimitDelta]
  );

  const deleteTransaction = useCallback(
    (id: string) => {
      setTransactions((prev) => {
        const old = prev.find((t) => t.id === id);
        const updated = prev.filter((t) => t.id !== id);
        AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
        if (old) {
          const delta = txAvailableLimitDelta(old);
          if (delta > 0 && old.bankLimitId) {
            // Restore the credit that was previously deducted.
            applyAvailableLimitDelta(old.bankLimitId, -delta);
          }
        }
        return updated;
      });
    },
    [applyAvailableLimitDelta]
  );

  const totalIncome = transactions
    .filter((t) => t.type === "income")
    .reduce((s, t) => s + t.amount, 0);

  const totalExpense = transactions
    .filter((t) => t.type === "expense")
    .reduce((s, t) => s + t.amount, 0);

  const balance = totalIncome - totalExpense;

  const persistDebts = (next: Debt[]) => {
    AsyncStorage.setItem(DEBTS_STORAGE_KEY, JSON.stringify(next));
  };

  const addDebt = useCallback(
    (d: Omit<Debt, "id" | "payments"> & { payments?: Payment[] }) => {
      const newDebt: Debt = {
        ...d,
        payments: d.payments ?? [],
        id: Date.now().toString() + Math.random().toString(36).substr(2, 6),
      };
      setDebts((prev) => {
        const updated = [newDebt, ...prev];
        persistDebts(updated);
        return updated;
      });
    },
    []
  );

  const updateDebt = useCallback(
    (id: string, patch: Partial<Omit<Debt, "id">>) => {
      setDebts((prev) => {
        const updated = prev.map((d) =>
          d.id === id ? { ...d, ...patch } : d
        );
        persistDebts(updated);
        return updated;
      });
    },
    []
  );

  const deleteDebt = useCallback((id: string) => {
    setDebts((prev) => {
      const updated = prev.filter((d) => d.id !== id);
      persistDebts(updated);
      return updated;
    });
  }, []);

  const addPayment = useCallback(
    (debtId: string, amount: number, date: string) => {
      let autoTx: Transaction | null = null;
      const txId = (Date.now() + 1).toString() + Math.random().toString(36).substr(2, 9);

      setDebts((prev) => {
        const updated = prev.map((d) => {
          if (d.id !== debtId) return d;
          const payment: Payment = {
            id: Date.now().toString() + Math.random().toString(36).substr(2, 6),
            date,
            amount,
            txId,
          };
          const nextPaid = Math.min(d.amount, d.paidAmount + amount);
          let nextPaidInstallments = d.paidInstallments;
          if (
            d.isInstallment &&
            d.totalInstallments &&
            d.totalInstallments > 0
          ) {
            const perInstallment = d.amount / d.totalInstallments;
            const calc = Math.round(nextPaid / perInstallment);
            nextPaidInstallments = Math.min(d.totalInstallments, calc);
          }
          autoTx = {
            id: txId,
            type: "expense",
            amount,
            category: d.category,
            note: d.name,
            date,
            paymentMethod: d.category.toLowerCase() === "kredi kartı" ? "card" : "cash",
            ...(d.creditor ? { bank: d.creditor } : {}),
          };
          return {
            ...d,
            paidAmount: nextPaid,
            paidInstallments: nextPaidInstallments,
            payments: [payment, ...d.payments],
          };
        });
        persistDebts(updated);
        return updated;
      });

      if (autoTx) {
        const tx = autoTx as Transaction;
        setTransactions((prev) => {
          const updated = [tx, ...prev];
          AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
          return updated;
        });
      }
    },
    []
  );

  const updatePayment = useCallback(
    (debtId: string, paymentId: string, amount: number, date: string) => {
      let oldTxId: string | undefined;
      let oldAmount = 0;

      setDebts((prev) => {
        const updated = prev.map((d) => {
          if (d.id !== debtId) return d;
          const oldPayment = d.payments.find((p) => p.id === paymentId);
          if (!oldPayment) return d;
          oldTxId = oldPayment.txId;
          oldAmount = oldPayment.amount;
          const newPayments = d.payments.map((p) =>
            p.id === paymentId ? { ...p, amount, date } : p
          );
          const newPaid = newPayments.reduce((s, p) => s + p.amount, 0);
          return {
            ...d,
            paidAmount: Math.min(d.amount, newPaid),
            payments: newPayments,
          };
        });
        persistDebts(updated);
        return updated;
      });

      // Update linked transaction if it exists
      if (oldTxId) {
        const txId = oldTxId;
        setTransactions((prev) => {
          const updated = prev.map((t) =>
            t.id === txId ? { ...t, amount, date } : t
          );
          AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
          return updated;
        });
      }
    },
    []
  );

  const deletePayment = useCallback(
    (debtId: string, paymentId: string) => {
      let txId: string | undefined;

      setDebts((prev) => {
        const updated = prev.map((d) => {
          if (d.id !== debtId) return d;
          const p = d.payments.find((p) => p.id === paymentId);
          if (!p) return d;
          txId = p.txId;
          const newPayments = d.payments.filter((p) => p.id !== paymentId);
          const newPaid = newPayments.reduce((s, p) => s + p.amount, 0);
          return { ...d, paidAmount: Math.min(d.amount, newPaid), payments: newPayments };
        });
        persistDebts(updated);
        return updated;
      });

      if (txId) {
        const id = txId;
        setTransactions((prev) => {
          const updated = prev.filter((t) => t.id !== id);
          AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
          return updated;
        });
      }
    },
    []
  );

  const toggleInstallmentPaid = useCallback(
    (debtId: string, index: number) => {
      let autoTx: Transaction | null = null;

      setDebts((prev) => {
        const updated = prev.map((d) => {
          if (d.id !== debtId) return d;
          if (!d.isInstallment || !d.totalInstallments) return d;
          const total = d.totalInstallments;
          if (index < 0 || index >= total) return d;
          const baseSet = new Set<number>(
            d.paidInstallmentIndices ??
              Array.from({ length: d.paidInstallments ?? 0 }, (_, i) => i)
          );
          const wasPaid = baseSet.has(index);
          if (wasPaid) {
            baseSet.delete(index);
          } else {
            baseSet.add(index);
            // Taksit ödeme tarihi: başlangıç + index ay
            const instDate = new Date(d.date);
            instDate.setMonth(instDate.getMonth() + index);
            const perInstallment = d.amount / total;
            autoTx = {
              id: (Date.now() + 1).toString() + Math.random().toString(36).substr(2, 9),
              type: "expense",
              amount: perInstallment,
              category: d.category,
              note: `${d.name} - Taksit ${index + 1}/${total}`,
              date: instDate.toISOString(),
              paymentMethod: d.category.toLowerCase() === "kredi kartı" ? "card" : "cash",
              ...(d.creditor ? { bank: d.creditor } : {}),
            };
          }
          const indices = Array.from(baseSet).sort((a, b) => a - b);
          const perInstallment = d.amount / total;
          return {
            ...d,
            paidInstallmentIndices: indices,
            paidInstallments: indices.length,
            paidAmount: Math.min(d.amount, indices.length * perInstallment),
          };
        });
        persistDebts(updated);
        return updated;
      });

      if (autoTx) {
        const tx = autoTx as Transaction;
        setTransactions((prev) => {
          const updated = [tx, ...prev];
          AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
          return updated;
        });
      }
    },
    []
  );

  const toggleBreakdownPaid = useCallback(
    (debtId: string, yearMonth: string) => {
      let autoTx: Transaction | null = null;
      let removeTxId: string | undefined;

      setDebts((prev) => {
        const updated = prev.map((d) => {
          if (d.id !== debtId) return d;
          const paidMonths = d.paidBreakdownMonths ?? [];
          const paymentMap = d.breakdownPaymentMap ?? {};
          const isPaid = paidMonths.includes(yearMonth);
          const breakdown = (d.monthlyBreakdowns ?? []).find(
            (b) => b.yearMonth === yearMonth
          );
          if (!breakdown) return d;

          if (!isPaid) {
            // Mark as paid: create a real payment record
            const paymentId =
              Date.now().toString() + Math.random().toString(36).substr(2, 6);
            const txId =
              (Date.now() + 1).toString() +
              Math.random().toString(36).substr(2, 9);
            const [yr, mo] = yearMonth.split("-").map(Number);
            const date = new Date(yr, mo - 1, 1).toISOString();
            const payment: Payment = {
              id: paymentId,
              date,
              amount: breakdown.amount,
              txId,
            };
            const newPayments = [payment, ...d.payments];
            const newPaid = Math.min(d.amount, d.paidAmount + breakdown.amount);
            autoTx = {
              id: txId,
              type: "expense",
              amount: breakdown.amount,
              category: d.category,
              note: `${d.name} - ${yearMonth}`,
              date,
              paymentMethod: "card",
              ...(d.creditor ? { bank: d.creditor } : {}),
            };
            return {
              ...d,
              paidAmount: newPaid,
              payments: newPayments,
              paidBreakdownMonths: [...paidMonths, yearMonth],
              breakdownPaymentMap: { ...paymentMap, [yearMonth]: paymentId },
            };
          } else {
            // Unmark as paid: remove the linked payment record
            const paymentId = paymentMap[yearMonth];
            let newPayments = d.payments;
            if (paymentId) {
              const p = d.payments.find((p) => p.id === paymentId);
              removeTxId = p?.txId;
              newPayments = d.payments.filter((p) => p.id !== paymentId);
            }
            const newPaid = newPayments.reduce((s, p) => s + p.amount, 0);
            const newMap = { ...paymentMap };
            delete newMap[yearMonth];
            return {
              ...d,
              paidAmount: Math.min(d.amount, newPaid),
              payments: newPayments,
              paidBreakdownMonths: paidMonths.filter((m) => m !== yearMonth),
              breakdownPaymentMap: newMap,
            };
          }
        });
        persistDebts(updated);
        return updated;
      });

      if (autoTx) {
        const tx = autoTx as Transaction;
        setTransactions((prev) => {
          const updated = [tx, ...prev];
          AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
          return updated;
        });
      }
      if (removeTxId) {
        const id = removeTxId;
        setTransactions((prev) => {
          const updated = prev.filter((t) => t.id !== id);
          AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
          return updated;
        });
      }
    },
    []
  );

  const persistBankLimits = (next: BankLimit[]) => {
    AsyncStorage.setItem(BANK_LIMITS_STORAGE_KEY, JSON.stringify(next));
  };

  const addBankLimit = useCallback((b: Omit<BankLimit, "id">) => {
    setBankLimits((prev) => {
      const newItem: BankLimit = {
        ...b,
        id: Date.now().toString() + Math.random().toString(36).substr(2, 6),
      };
      const updated = [newItem, ...prev];
      persistBankLimits(updated);
      return updated;
    });
  }, []);

  const updateBankLimit = useCallback(
    (id: string, patch: Partial<Omit<BankLimit, "id">>) => {
      setBankLimits((prev) => {
        const updated = prev.map((b) => {
          if (b.id !== id) return b;
          const merged = { ...b, ...patch };
          // Clamp availableLimit: must be in [0, limit]; clear if negative
          if (
            typeof merged.availableLimit === "number" &&
            typeof merged.limit === "number"
          ) {
            if (merged.availableLimit < 0) {
              merged.availableLimit = 0;
            } else if (merged.availableLimit > merged.limit) {
              merged.availableLimit = merged.limit;
            }
          }
          return merged;
        });
        persistBankLimits(updated);
        // If the limit changed, recompute the linked debt's amount so that
        // it always reflects max(sumBreakdowns, bankLimit.limit).
        const newLimit = updated.find((b) => b.id === id)?.limit;
        if (typeof newLimit === "number") {
          setDebts((dprev) => {
            const linked = dprev.find((d) => d.bankLimitId === id);
            if (!linked) return dprev;
            const sum = (linked.monthlyBreakdowns ?? []).reduce(
              (s, x) => s + x.amount,
              0
            );
            const newAmount = Math.max(sum, newLimit);
            if (newAmount === linked.amount) return dprev;
            const paidSet = new Set(linked.paidBreakdownMonths ?? []);
            const newPaid = (linked.monthlyBreakdowns ?? [])
              .filter((b) => paidSet.has(b.yearMonth))
              .reduce((s, b) => s + b.amount, 0);
            const next = dprev.map((d) =>
              d.id === linked.id
                ? { ...d, amount: newAmount, paidAmount: Math.min(newAmount, newPaid) }
                : d
            );
            persistDebts(next);
            return next;
          });
        }
        return updated;
      });
    },
    []
  );

  const deleteBankLimit = useCallback((id: string) => {
    setBankLimits((prev) => {
      const updated = prev.filter((b) => b.id !== id);
      persistBankLimits(updated);
      return updated;
    });
    setDebts((prev) => {
      const linked = prev.find((d) => d.bankLimitId === id);
      if (linked) {
        const txIds = (linked.payments ?? [])
          .map((p) => p.txId)
          .filter((tid): tid is string => !!tid);
        if (txIds.length > 0) {
          setTransactions((txPrev) => {
            const txUpdated = txPrev.filter((t) => !txIds.includes(t.id));
            AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(txUpdated));
            return txUpdated;
          });
        }
      }
      const updated = prev.filter((d) => d.bankLimitId !== id);
      persistDebts(updated);
      return updated;
    });
  }, []);

  const getDebtForBankLimit = useCallback(
    (bankLimitId: string): Debt | undefined => {
      return debts.find((d) => d.bankLimitId === bankLimitId);
    },
    [debts]
  );

  const recomputeDebtFromBreakdowns = (d: Debt, floor: number = 0): Debt => {
    const bds = d.monthlyBreakdowns ?? [];
    const sum = bds.reduce((s, b) => s + b.amount, 0);
    const newAmount = Math.max(sum, floor);
    const paidSet = new Set(d.paidBreakdownMonths ?? []);
    const newPaid = bds
      .filter((b) => paidSet.has(b.yearMonth))
      .reduce((s, b) => s + b.amount, 0);
    return {
      ...d,
      amount: newAmount,
      paidAmount: Math.min(newAmount, newPaid),
    };
  };

  const addBankLimitBreakdown = useCallback(
    (bankLimit: BankLimit, yearMonth: string, amount: number) => {
      setDebts((prev) => {
        const existing = prev.find((d) => d.bankLimitId === bankLimit.id);
        const displayName = bankLimit.institution
          ? `${bankLimit.institution} - ${bankLimit.bank}`
          : bankLimit.bank;
        if (existing) {
          const breakdowns = (existing.monthlyBreakdowns ?? []).filter(
            (b) => b.yearMonth !== yearMonth
          );
          breakdowns.push({ yearMonth, amount });
          breakdowns.sort((a, b) => a.yearMonth.localeCompare(b.yearMonth));
          const updatedDebt = recomputeDebtFromBreakdowns(
            {
              ...existing,
              name: displayName,
              creditor: bankLimit.institution || bankLimit.bank,
              monthlyBreakdowns: breakdowns,
            },
            bankLimit.limit
          );
          const updated = prev.map((d) => (d.id === existing.id ? updatedDebt : d));
          persistDebts(updated);
          return updated;
        }
        const newDebt: Debt = {
          id: Date.now().toString() + Math.random().toString(36).substr(2, 6),
          name: displayName,
          category: "Kredi Kartı",
          creditor: bankLimit.institution || bankLimit.bank,
          amount: Math.max(amount, bankLimit.limit),
          paidAmount: 0,
          date: new Date().toISOString(),
          isInstallment: false,
          payments: [],
          monthlyBreakdowns: [{ yearMonth, amount }],
          paidBreakdownMonths: [],
          bankLimitId: bankLimit.id,
        };
        const updated = [newDebt, ...prev];
        persistDebts(updated);
        return updated;
      });
    },
    []
  );

  const updateBankLimitBreakdown = useCallback(
    (bankLimitId: string, yearMonth: string, amount: number) => {
      setDebts((prev) => {
        const existing = prev.find((d) => d.bankLimitId === bankLimitId);
        if (!existing) return prev;
        const breakdowns = (existing.monthlyBreakdowns ?? []).map((b) =>
          b.yearMonth === yearMonth ? { ...b, amount } : b
        );
        const limit =
          bankLimits.find((b) => b.id === bankLimitId)?.limit ?? 0;
        const updatedDebt = recomputeDebtFromBreakdowns(
          {
            ...existing,
            monthlyBreakdowns: breakdowns,
          },
          limit
        );
        const updated = prev.map((d) => (d.id === existing.id ? updatedDebt : d));
        persistDebts(updated);
        return updated;
      });
    },
    [bankLimits]
  );

  const removeBankLimitBreakdown = useCallback(
    (bankLimitId: string, yearMonth: string) => {
      let removeTxId: string | undefined;
      setDebts((prev) => {
        const existing = prev.find((d) => d.bankLimitId === bankLimitId);
        if (!existing) return prev;
        const breakdowns = (existing.monthlyBreakdowns ?? []).filter(
          (b) => b.yearMonth !== yearMonth
        );
        const paidMonths = (existing.paidBreakdownMonths ?? []).filter(
          (m) => m !== yearMonth
        );
        // Clean up linked payment + transaction if this month was paid
        const paymentMap = { ...(existing.breakdownPaymentMap ?? {}) };
        const linkedPaymentId = paymentMap[yearMonth];
        let payments = existing.payments;
        if (linkedPaymentId) {
          const p = existing.payments.find((p) => p.id === linkedPaymentId);
          removeTxId = p?.txId;
          payments = existing.payments.filter((p) => p.id !== linkedPaymentId);
          delete paymentMap[yearMonth];
        }
        if (breakdowns.length === 0) {
          // Also remove all remaining linked transactions for this debt
          const remainingTxIds = (existing.payments ?? [])
            .map((p) => p.txId)
            .filter((id): id is string => !!id);
          if (remainingTxIds.length > 0) {
            setTransactions((txPrev) => {
              const txUpdated = txPrev.filter((t) => !remainingTxIds.includes(t.id));
              AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(txUpdated));
              return txUpdated;
            });
            removeTxId = undefined; // already cleaned above
          }
          const updated = prev.filter((d) => d.id !== existing.id);
          persistDebts(updated);
          return updated;
        }
        const limit =
          bankLimits.find((b) => b.id === bankLimitId)?.limit ?? 0;
        const updatedDebt = recomputeDebtFromBreakdowns(
          {
            ...existing,
            monthlyBreakdowns: breakdowns,
            paidBreakdownMonths: paidMonths,
            breakdownPaymentMap: paymentMap,
            payments,
          },
          limit
        );
        const updated = prev.map((d) => (d.id === existing.id ? updatedDebt : d));
        persistDebts(updated);
        return updated;
      });

      if (removeTxId) {
        const id = removeTxId;
        setTransactions((prev) => {
          const updated = prev.filter((t) => t.id !== id);
          AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
          return updated;
        });
      }
    },
    [bankLimits]
  );

  // ---- New CC statement APIs (Apr 2026 refactor) --------------------------

  const setManualStatementAmount = useCallback(
    (bankLimitId: string, yearMonth: string, amount: number | null) => {
      setBankLimits((prev) => {
        const updated = prev.map((b) => {
          if (b.id !== bankLimitId) return b;
          const list = b.cardStatements ? [...b.cardStatements] : [];
          const idx = list.findIndex((e) => e.yearMonth === yearMonth);
          if (amount === null) {
            // Clear manual override; keep entry if there is paidAmount
            if (idx < 0) return b;
            const cur = list[idx];
            if (!cur.paidAmount) {
              list.splice(idx, 1);
            } else {
              list[idx] = { ...cur, manualAmount: undefined };
            }
          } else {
            const base: CardStatementEntry =
              idx >= 0 ? list[idx] : { yearMonth, paidAmount: 0 };
            const next: CardStatementEntry = {
              ...base,
              manualAmount: amount,
              yearMonth,
            };
            if (idx >= 0) list[idx] = next;
            else list.push(next);
          }
          list.sort((a, b2) => a.yearMonth.localeCompare(b2.yearMonth));
          return { ...b, cardStatements: list };
        });
        persistBankLimits(updated);
        return updated;
      });
    },
    []
  );

  const recordStatementPayment = useCallback(
    (
      bankLimitId: string,
      yearMonth: string,
      amount: number,
      date: string
    ) => {
      if (!Number.isFinite(amount) || amount <= 0) return;
      // Update the cardStatements paidAmount
      let cardName: string | undefined;
      setBankLimits((prev) => {
        const updated = prev.map((b) => {
          if (b.id !== bankLimitId) return b;
          cardName = b.bank;
          const list = b.cardStatements ? [...b.cardStatements] : [];
          const idx = list.findIndex((e) => e.yearMonth === yearMonth);
          const base: CardStatementEntry =
            idx >= 0 ? list[idx] : { yearMonth, paidAmount: 0 };
          const next: CardStatementEntry = {
            ...base,
            paidAmount: (base.paidAmount || 0) + amount,
            lastPaymentDate: date,
            yearMonth,
          };
          if (idx >= 0) list[idx] = next;
          else list.push(next);
          list.sort((a, b2) => a.yearMonth.localeCompare(b2.yearMonth));
          return { ...b, cardStatements: list };
        });
        persistBankLimits(updated);
        return updated;
      });

      // Paying off a statement frees up that much credit on the card.
      applyAvailableLimitDelta(bankLimitId, -amount);

      // Mirror the payment as an expense Transaction so totals + history stay
      // accurate (paymentMethod="cash" because the user is paying the bank
      // FROM cash, not making another card purchase).
      const newTx: Transaction = {
        id: Date.now().toString() + Math.random().toString(36).substr(2, 9),
        type: "expense",
        amount,
        category: "Kredi Kartı",
        note: cardName
          ? `${cardName} - ${yearMonth} ekstre ödemesi`
          : `${yearMonth} ekstre ödemesi`,
        date,
        paymentMethod: "cash",
        bank: cardName,
      };
      setTransactions((prev) => {
        const updated = [newTx, ...prev];
        AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
        return updated;
      });
    },
    [applyAvailableLimitDelta]
  );

  const resetStatementPayment = useCallback(
    (bankLimitId: string, yearMonth: string) => {
      // Capture the paid amount being undone so we can restore the
      // availableLimit (recordStatementPayment had decreased the card's
      // outstanding debt by exactly this much).
      let paidBefore = 0;
      setBankLimits((prev) => {
        const updated = prev.map((b) => {
          if (b.id !== bankLimitId) return b;
          const list = b.cardStatements ? [...b.cardStatements] : [];
          const idx = list.findIndex((e) => e.yearMonth === yearMonth);
          if (idx < 0) return b;
          const cur = list[idx];
          paidBefore = cur.paidAmount || 0;
          if (cur.manualAmount === undefined) {
            list.splice(idx, 1);
          } else {
            list[idx] = {
              ...cur,
              paidAmount: 0,
              lastPaymentDate: undefined,
            };
          }
          return { ...b, cardStatements: list };
        });
        persistBankLimits(updated);
        return updated;
      });

      // Re-apply the debt that was previously freed.
      if (paidBefore > 0) {
        applyAvailableLimitDelta(bankLimitId, paidBefore);
      }
    },
    [applyAvailableLimitDelta]
  );

  // "Bankayla Eşitle" — set availableLimit to whatever the bank app reports
  // and record the difference as a correction transaction so the overall
  // balance on the home screen stays accurate.
  const reconcileBankLimit = useCallback(
    (bankLimitId: string, newAvailableLimit: number, dateISO?: string) => {
      if (!Number.isFinite(newAvailableLimit) || newAvailableLimit < 0) return;
      let cardName = "";
      let oldAvailable: number | undefined;
      let cardLimit = 0;
      setBankLimits((prev) => {
        const updated = prev.map((b) => {
          if (b.id !== bankLimitId) return b;
          cardName = b.institution || b.bank;
          oldAvailable =
            typeof b.availableLimit === "number" && Number.isFinite(b.availableLimit)
              ? b.availableLimit
              : b.limit;
          cardLimit = b.limit;
          const clamped = Math.max(0, Math.min(b.limit, newAvailableLimit));
          return { ...b, availableLimit: clamped };
        });
        persistBankLimits(updated);
        return updated;
      });

      if (oldAvailable === undefined) return;
      const clampedNew = Math.max(0, Math.min(cardLimit, newAvailableLimit));
      const diff = oldAvailable - clampedNew; // >0 = used more, <0 = freed up
      if (Math.abs(diff) < 0.005) return;

      const date = dateISO ?? new Date().toISOString();
      const correctionTx: Transaction = {
        id: Date.now().toString() + Math.random().toString(36).substr(2, 9),
        type: diff > 0 ? "expense" : "income",
        amount: Math.abs(diff),
        category: "Banka Düzeltme",
        note:
          diff > 0
            ? `${cardName} - bankayla eşitleme (eksik harcama)`
            : `${cardName} - bankayla eşitleme (iade/fazla)`,
        date,
        paymentMethod: "cash",
        bank: cardName,
        bankLimitId,
        correction: true,
      };
      setTransactions((prev) => {
        const updated = [correctionTx, ...prev];
        AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(updated));
        return updated;
      });
    },
    []
  );

  const persistSavedCards = (next: SavedCard[]) =>
    AsyncStorage.setItem(SAVED_CARDS_STORAGE_KEY, JSON.stringify(next));

  const addSavedCard = useCallback((c: Omit<SavedCard, "id">): string => {
    const newId = Date.now().toString() + Math.random().toString(36).substr(2, 6);
    setSavedCards((prev) => {
      const newCard: SavedCard = { ...c, id: newId };
      const updated = [...prev, newCard];
      persistSavedCards(updated);
      return updated;
    });
    return newId;
  }, []);

  const updateSavedCard = useCallback(
    (id: string, patch: Partial<Omit<SavedCard, "id">>) => {
      setSavedCards((prev) => {
        const updated = prev.map((c) => (c.id === id ? { ...c, ...patch } : c));
        persistSavedCards(updated);
        return updated;
      });
    },
    []
  );

  const deleteSavedCard = useCallback((id: string) => {
    setSavedCards((prev) => {
      const updated = prev.filter((c) => c.id !== id);
      persistSavedCards(updated);
      return updated;
    });
  }, []);

  const persistAssets = (entries: AssetEntry[]) =>
    AsyncStorage.setItem(ASSETS_STORAGE_KEY, JSON.stringify(entries));

  const addAssetEntry = useCallback((e: Omit<AssetEntry, "id">) => {
    setAssetEntries((prev) => {
      const updated = [
        ...prev,
        { ...e, id: Date.now().toString() + Math.random().toString(36).substr(2, 6) },
      ];
      persistAssets(updated);
      return updated;
    });
  }, []);

  const updateAssetEntry = useCallback(
    (id: string, patch: Partial<Omit<AssetEntry, "id">>) => {
      setAssetEntries((prev) => {
        const updated = prev.map((e) => (e.id === id ? { ...e, ...patch } : e));
        persistAssets(updated);
        return updated;
      });
    },
    []
  );

  const deleteAssetEntry = useCallback((id: string) => {
    setAssetEntries((prev) => {
      const updated = prev.filter((e) => e.id !== id);
      persistAssets(updated);
      return updated;
    });
  }, []);

  const persistCashFlow = (entries: CashFlowEntry[]) =>
    AsyncStorage.setItem(CASH_FLOW_STORAGE_KEY, JSON.stringify(entries));

  const addCashFlowEntry = useCallback((e: Omit<CashFlowEntry, "id">) => {
    setCashFlowEntries((prev) => {
      const updated = [...prev, { ...e, id: String(Date.now() + Math.random()) }];
      persistCashFlow(updated);
      return updated;
    });
  }, []);

  const updateCashFlowEntry = useCallback(
    (id: string, patch: Partial<Omit<CashFlowEntry, "id">>) => {
      setCashFlowEntries((prev) => {
        const updated = prev.map((e) => (e.id === id ? { ...e, ...patch } : e));
        persistCashFlow(updated);
        return updated;
      });
    },
    []
  );

  const deleteCashFlowEntry = useCallback((id: string) => {
    setCashFlowEntries((prev) => {
      const updated = prev.filter((e) => e.id !== id);
      persistCashFlow(updated);
      return updated;
    });
  }, []);

  const totalDebt = debts.reduce((s, d) => s + d.amount, 0);
  const totalDebtRemaining = debts.reduce(
    (s, d) => s + Math.max(0, d.amount - d.paidAmount),
    0
  );

  const exportData = useCallback(() => {
    return JSON.stringify(
      {
        version: 4,
        exportedAt: new Date().toISOString(),
        transactions,
        debts,
        bankLimits,
        savedCards,
        assetEntries,
        cashFlowEntries,
        customDebtCategories,
        expenseCategoryList,
        incomeCategoryList,
        customBankList,
        reminderSettings,
      },
      null,
      2
    );
  }, [
    transactions,
    debts,
    bankLimits,
    savedCards,
    assetEntries,
    cashFlowEntries,
    customDebtCategories,
    expenseCategoryList,
    incomeCategoryList,
    customBankList,
    reminderSettings,
  ]);

  const importData = useCallback(
    (json: string, mode: "replace" | "merge") => {
      const parsed = JSON.parse(json);
      const incomingTx: Transaction[] = Array.isArray(parsed?.transactions)
        ? parsed.transactions.filter(
            (t: any) =>
              t &&
              typeof t.id === "string" &&
              (t.type === "income" || t.type === "expense") &&
              typeof t.amount === "number" &&
              typeof t.category === "string" &&
              typeof t.date === "string"
          )
        : [];
      const incomingDebts: Debt[] = Array.isArray(parsed?.debts)
        ? parsed.debts
            .filter(
              (d: any) =>
                d &&
                typeof d.name === "string" &&
                typeof d.amount === "number" &&
                typeof d.date === "string"
            )
            .map(migrateDebt)
        : [];
      const incomingBankLimits: BankLimit[] = Array.isArray(parsed?.bankLimits)
        ? parsed.bankLimits
            .filter(
              (b: any) =>
                b &&
                typeof b.id === "string" &&
                typeof b.bank === "string" &&
                typeof b.limit === "number" &&
                (b.type === "credit" || b.type === "overdraft")
            )
            .map((b: any) => ({
              id: String(b.id),
              bank: String(b.bank),
              institution: typeof b.institution === "string" ? b.institution : undefined,
              savedCardId: typeof b.savedCardId === "string" ? b.savedCardId : undefined,
              limit: Number(b.limit),
              availableLimit:
                typeof b.availableLimit === "number" ? b.availableLimit : undefined,
              type: b.type as BankLimitType,
              note: typeof b.note === "string" ? b.note : undefined,
              cardStatements: Array.isArray(b.cardStatements)
                ? b.cardStatements
                    .filter(
                      (e: any) =>
                        e &&
                        typeof e.yearMonth === "string" &&
                        typeof e.paidAmount === "number"
                    )
                    .map((e: any) => ({
                      yearMonth: String(e.yearMonth),
                      manualAmount:
                        typeof e.manualAmount === "number"
                          ? e.manualAmount
                          : undefined,
                      paidAmount: Number(e.paidAmount) || 0,
                      lastPaymentDate:
                        typeof e.lastPaymentDate === "string"
                          ? e.lastPaymentDate
                          : undefined,
                    }))
                : undefined,
            }))
        : [];
      const incomingSavedCards: SavedCard[] = Array.isArray(parsed?.savedCards)
        ? parsed.savedCards
            .filter(
              (c: any) =>
                c &&
                typeof c.id === "string" &&
                typeof c.name === "string" &&
                typeof c.bank === "string" &&
                (c.type === "credit" || c.type === "demand")
            )
            .map((c: any) => {
              const stDay =
                typeof c.statementDay === "number" &&
                c.statementDay >= 1 &&
                c.statementDay <= 31
                  ? Math.floor(c.statementDay)
                  : undefined;
              return {
                id: String(c.id),
                name: String(c.name),
                bank: String(c.bank),
                type: c.type as SavedCardType,
                cardLast4: typeof c.cardLast4 === "string" ? c.cardLast4 : undefined,
                accountNumber:
                  typeof c.accountNumber === "string" ? c.accountNumber : undefined,
                iban: typeof c.iban === "string" ? c.iban : undefined,
                statementDay: stDay,
                dueDay: computeDueDay(stDay),
                balance:
                  typeof c.balance === "number" && Number.isFinite(c.balance)
                    ? c.balance
                    : undefined,
              };
            })
        : [];
      const incomingCashFlow: CashFlowEntry[] = Array.isArray(parsed?.cashFlowEntries)
        ? parsed.cashFlowEntries
            .filter(
              (e: any) =>
                e &&
                typeof e.id === "string" &&
                typeof e.bank === "string" &&
                typeof e.yearMonth === "string" &&
                typeof e.amount === "number"
            )
            .map((e: any) => ({
              id: String(e.id),
              bank: String(e.bank),
              yearMonth: String(e.yearMonth),
              amount: Number(e.amount),
              note: typeof e.note === "string" ? e.note : undefined,
            }))
        : [];
      const VALID_ASSET_TYPES: AssetType[] = ["vadesiz","vadeli","kripto","borsa","doviz","altin"];
      const incomingAssets: AssetEntry[] = Array.isArray(parsed?.assetEntries)
        ? parsed.assetEntries
            .filter(
              (e: any) =>
                e &&
                typeof e.id === "string" &&
                typeof e.name === "string" &&
                typeof e.platform === "string" &&
                VALID_ASSET_TYPES.includes(e.assetType) &&
                typeof e.amount === "number"
            )
            .map((e: any) => ({
              id: String(e.id),
              name: String(e.name),
              platform: String(e.platform),
              assetType: e.assetType as AssetType,
              amount: Number(e.amount),
              note: typeof e.note === "string" ? e.note : undefined,
            }))
        : [];
      const incomingCustomDebtCats: string[] = Array.isArray(parsed?.customDebtCategories)
        ? parsed.customDebtCategories.filter((s: any) => typeof s === "string")
        : [];
      const incomingExpenseCats: string[] = Array.isArray(parsed?.expenseCategoryList)
        ? parsed.expenseCategoryList.filter((s: any) => typeof s === "string")
        : [];
      const incomingIncomeCats: string[] = Array.isArray(parsed?.incomeCategoryList)
        ? parsed.incomeCategoryList.filter((s: any) => typeof s === "string")
        : [];
      const incomingCustomBankList: string[] = Array.isArray(parsed?.customBankList)
        ? parsed.customBankList.filter((s: any) => typeof s === "string")
        : [];
      const incomingReminderSettings: Partial<ReminderSettings> =
        parsed?.reminderSettings && typeof parsed.reminderSettings === "object"
          ? parsed.reminderSettings
          : {};

      let nextTx: Transaction[];
      let nextDebts: Debt[];
      let nextBankLimits: BankLimit[];
      let nextSavedCards: SavedCard[];
      let nextAssets: AssetEntry[];
      let nextCashFlow: CashFlowEntry[];
      let nextCustomDebtCats: string[];
      let nextExpenseCats: string[];
      let nextIncomeCats: string[];
      let nextCustomBankList: string[];
      let nextReminderSettings: ReminderSettings;

      if (mode === "replace") {
        nextTx = incomingTx;
        nextDebts = incomingDebts;
        nextBankLimits = incomingBankLimits;
        nextSavedCards = incomingSavedCards;
        nextAssets = incomingAssets;
        nextCashFlow = incomingCashFlow;
        nextCustomDebtCats = incomingCustomDebtCats;
        nextExpenseCats =
          incomingExpenseCats.length > 0 ? incomingExpenseCats : expenseCategoryList;
        nextIncomeCats =
          incomingIncomeCats.length > 0 ? incomingIncomeCats : incomeCategoryList;
        nextCustomBankList =
          incomingCustomBankList.length > 0 ? incomingCustomBankList : customBankList;
        nextReminderSettings =
          Object.keys(incomingReminderSettings).length > 0
            ? { ...reminderSettings, ...incomingReminderSettings }
            : reminderSettings;
      } else {
        const txIds = new Set(transactions.map((t) => t.id));
        const debtIds = new Set(debts.map((d) => d.id));
        const blIds = new Set(bankLimits.map((b) => b.id));
        const scIds = new Set(savedCards.map((c) => c.id));
        const assetIds = new Set(assetEntries.map((e) => e.id));
        const cfIds = new Set(cashFlowEntries.map((e) => e.id));
        nextTx = [
          ...transactions,
          ...incomingTx.filter((t) => !txIds.has(t.id)),
        ];
        nextDebts = [
          ...debts,
          ...incomingDebts.filter((d) => !debtIds.has(d.id)),
        ];
        nextBankLimits = [
          ...bankLimits,
          ...incomingBankLimits.filter((b) => !blIds.has(b.id)),
        ];
        nextSavedCards = [
          ...savedCards,
          ...incomingSavedCards.filter((c) => !scIds.has(c.id)),
        ];
        nextAssets = [
          ...assetEntries,
          ...incomingAssets.filter((e) => !assetIds.has(e.id)),
        ];
        nextCashFlow = [
          ...cashFlowEntries,
          ...incomingCashFlow.filter((e) => !cfIds.has(e.id)),
        ];
        nextCustomDebtCats = Array.from(
          new Set([...customDebtCategories, ...incomingCustomDebtCats])
        );
        nextExpenseCats = Array.from(
          new Set([...expenseCategoryList, ...incomingExpenseCats])
        );
        nextIncomeCats = Array.from(
          new Set([...incomeCategoryList, ...incomingIncomeCats])
        );
        nextCustomBankList = Array.from(
          new Set([...customBankList, ...incomingCustomBankList])
        );
        nextReminderSettings = { ...reminderSettings, ...incomingReminderSettings };
      }
      nextTx.sort((a, b) => (a.date < b.date ? 1 : -1));
      nextDebts.sort((a, b) => (a.date < b.date ? 1 : -1));

      setTransactions(nextTx);
      setDebts(nextDebts);
      setBankLimits(nextBankLimits);
      setSavedCards(nextSavedCards);
      setAssetEntries(nextAssets);
      setCashFlowEntries(nextCashFlow);
      setCustomDebtCategories(nextCustomDebtCats);
      setExpenseCategoryList(nextExpenseCats);
      setIncomeCategoryList(nextIncomeCats);
      setCustomBankList(nextCustomBankList);
      setReminderSettings(nextReminderSettings);
      AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(nextTx));
      AsyncStorage.setItem(DEBTS_STORAGE_KEY, JSON.stringify(nextDebts));
      AsyncStorage.setItem(BANK_LIMITS_STORAGE_KEY, JSON.stringify(nextBankLimits));
      AsyncStorage.setItem(SAVED_CARDS_STORAGE_KEY, JSON.stringify(nextSavedCards));
      AsyncStorage.setItem(ASSETS_STORAGE_KEY, JSON.stringify(nextAssets));
      AsyncStorage.setItem(CASH_FLOW_STORAGE_KEY, JSON.stringify(nextCashFlow));
      AsyncStorage.setItem(DEBT_CATS_STORAGE_KEY, JSON.stringify(nextCustomDebtCats));
      AsyncStorage.setItem(EXPENSE_CATS_KEY, JSON.stringify(nextExpenseCats));
      AsyncStorage.setItem(INCOME_CATS_KEY, JSON.stringify(nextIncomeCats));
      AsyncStorage.setItem(CUSTOM_BANKS_KEY, JSON.stringify(nextCustomBankList));
      AsyncStorage.setItem(REMINDER_SETTINGS_KEY, JSON.stringify(nextReminderSettings));

      return { txCount: incomingTx.length, debtCount: incomingDebts.length };
    },
    [
      transactions,
      debts,
      bankLimits,
      savedCards,
      assetEntries,
      cashFlowEntries,
      customDebtCategories,
      expenseCategoryList,
      incomeCategoryList,
      customBankList,
      reminderSettings,
    ]
  );

  const updateReminderSettings = useCallback(
    (patch: Partial<ReminderSettings>) => {
      setReminderSettings((prev) => ({ ...prev, ...patch }));
    },
    [],
  );

  // Persist reminder settings whenever they change (only after initial hydration).
  useEffect(() => {
    if (!reminderSettingsHydrated) return;
    AsyncStorage.setItem(
      REMINDER_SETTINGS_KEY,
      JSON.stringify(reminderSettings),
    ).catch(() => {});
  }, [reminderSettings, reminderSettingsHydrated]);

  // Auto-reschedule local notifications whenever the source data or settings change.
  useEffect(() => {
    rescheduleAllReminders({
      bankLimits,
      savedCards,
      transactions,
      debts,
      settings: reminderSettings,
    }).catch(() => {});
  }, [bankLimits, savedCards, transactions, debts, reminderSettings]);

  const clearAllData = useCallback(() => {
    const defaultExpense = EXPENSE_CATEGORIES.map((c) => c.label);
    const defaultIncome = INCOME_CATEGORIES.map((c) => c.label);
    setTransactions([]);
    setDebts([]);
    setCustomDebtCategories([]);
    setBankLimits([]);
    setSavedCards([]);
    setAssetEntries([]);
    setCashFlowEntries([]);
    setExpenseCategoryList(defaultExpense);
    setIncomeCategoryList(defaultIncome);
    setRemovedDebtDefaults([]);
    setCategoryUsage({ expense: {}, income: {} });
    AsyncStorage.removeItem(CATEGORY_USAGE_KEY);
    AsyncStorage.setItem(STORAGE_KEY, JSON.stringify([]));
    AsyncStorage.setItem(DEBTS_STORAGE_KEY, JSON.stringify([]));
    AsyncStorage.setItem(DEBT_CATS_STORAGE_KEY, JSON.stringify([]));
    AsyncStorage.setItem(BANK_LIMITS_STORAGE_KEY, JSON.stringify([]));
    AsyncStorage.setItem(SAVED_CARDS_STORAGE_KEY, JSON.stringify([]));
    AsyncStorage.setItem(ASSETS_STORAGE_KEY, JSON.stringify([]));
    AsyncStorage.setItem(CASH_FLOW_STORAGE_KEY, JSON.stringify([]));
    AsyncStorage.setItem(EXPENSE_CATS_KEY, JSON.stringify(defaultExpense));
    AsyncStorage.setItem(INCOME_CATS_KEY, JSON.stringify(defaultIncome));
    AsyncStorage.setItem(REMOVED_DEBT_DEFAULTS_KEY, JSON.stringify([]));
    setCustomBankList([]);
    AsyncStorage.setItem(CUSTOM_BANKS_KEY, JSON.stringify([]));
    AsyncStorage.removeItem(PAYMENT_MIGRATION_KEY);
    AsyncStorage.removeItem(REMINDER_SETTINGS_KEY);
    setReminderSettings(DEFAULT_REMINDER_SETTINGS);
  }, []);

  return (
    <BudgetContext.Provider
      value={{
        transactions,
        addTransaction,
        updateTransaction,
        deleteTransaction,
        addTransfer,
        totalIncome,
        totalExpense,
        balance,
        debts,
        addDebt,
        updateDebt,
        deleteDebt,
        addPayment,
        updatePayment,
        deletePayment,
        toggleInstallmentPaid,
        toggleBreakdownPaid,
        totalDebt,
        totalDebtRemaining,
        customDebtCategories,
        addDebtCategory,
        expenseCategoryList,
        addExpenseCategory,
        removeExpenseCategory,
        incomeCategoryList,
        addIncomeCategory,
        removeIncomeCategory,
        categoryUsage,
        renameOrMergeExpenseCategory,
        renameOrMergeIncomeCategory,
        renameOrMergeDebtCategory,
        renameOrMergeBank,
        allDebtCategories,
        removeDebtCategory,
        allBanks,
        addBank,
        removeBank,
        bankLimits,
        addBankLimit,
        updateBankLimit,
        deleteBankLimit,
        reconcileBankLimit,
        getDebtForBankLimit,
        addBankLimitBreakdown,
        updateBankLimitBreakdown,
        removeBankLimitBreakdown,
        setManualStatementAmount,
        recordStatementPayment,
        resetStatementPayment,
        savedCards,
        addSavedCard,
        updateSavedCard,
        deleteSavedCard,
        assetEntries,
        addAssetEntry,
        updateAssetEntry,
        deleteAssetEntry,
        cashFlowEntries,
        addCashFlowEntry,
        updateCashFlowEntry,
        deleteCashFlowEntry,
        exportData,
        importData,
        clearAllData,
        reminderSettings,
        updateReminderSettings,
      }}
    >
      {children}
    </BudgetContext.Provider>
  );
}

export function useBudget(): BudgetContextType {
  const ctx = useContext(BudgetContext);
  if (!ctx) throw new Error("useBudget must be used within BudgetProvider");
  return ctx;
}
