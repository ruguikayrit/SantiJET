/**
 * Credit-card statement helpers.
 *
 * Source-of-truth design (Apr 2026 refactor):
 *   - A credit card lives as a BankLimit with type==="credit".
 *   - Each card has a SavedCard sibling (matched by bank+name) that carries
 *     statementDay (1-31) and computed dueDay (= statementDay + 11 wrap).
 *   - A "statement period" is identified by the year-month in which it is
 *     CUT. Period spans (prevStatementDay+1 .. statementDay).
 *   - Active (uncut) period = the period that contains today.
 *   - Past (issued) periods are immutable and can carry a manualAmount
 *     override (which beats the auto-computed amount from transactions).
 *
 * The helpers are pure: they do not touch storage. Callers in the
 * BudgetContext / UI compose them with persisted state.
 */

import type {
  BankLimit,
  CardStatementEntry,
  SavedCard,
  Transaction,
} from "@/context/finans/BudgetContext";

export interface StatementPeriod {
  yearMonth: string;        // e.g. "2026-04" — month the statement is CUT in
  periodStart: Date;        // inclusive
  periodEnd: Date;          // inclusive (= statement cut date)
  statementDate: Date;      // = periodEnd
  dueDate: Date;            // = statementDate + 11 days
  isActive: boolean;        // true if today falls inside (periodStart..periodEnd]
  isFuture: boolean;        // true if periodStart > today
}

export interface ResolvedStatement extends StatementPeriod {
  autoAmount: number;       // sum of CC tx amounts (with installments expanded) falling in this period
  manualAmount?: number;    // user override; beats autoAmount when set
  amount: number;           // displayed total = manualAmount ?? autoAmount
  paidAmount: number;       // total paid against this statement
  remaining: number;        // max(0, amount - paidAmount)
  isFullyPaid: boolean;     // amount > 0 && paidAmount >= amount
  hasData: boolean;         // amount > 0 OR manualAmount set
}

// ---- Day math ---------------------------------------------------------------

function daysInMonth(year: number, monthZero: number): number {
  return new Date(year, monthZero + 1, 0).getDate();
}

function clampDay(day: number, year: number, monthZero: number): number {
  return Math.min(Math.max(1, Math.floor(day)), daysInMonth(year, monthZero));
}

function startOfDay(d: Date): Date {
  const r = new Date(d);
  r.setHours(0, 0, 0, 0);
  return r;
}

function ymKey(year: number, monthZero: number): string {
  return `${year}-${String(monthZero + 1).padStart(2, "0")}`;
}

function parseYM(ym: string): { year: number; monthZero: number } {
  const [y, m] = ym.split("-").map(Number);
  return { year: y, monthZero: (m || 1) - 1 };
}

// Add N months to (year, monthZero) -> { year, monthZero }
function addMonths(year: number, monthZero: number, delta: number) {
  const total = year * 12 + monthZero + delta;
  return { year: Math.floor(total / 12), monthZero: ((total % 12) + 12) % 12 };
}

// ---- Period resolution -----------------------------------------------------

/**
 * For a given date and statementDay, return the year-month identifier of the
 * statement period that contains that date (period ENDS in this YM).
 *
 * Rule: if date.day <= statementDay → falls in current month's statement.
 *       else → falls in next month's statement.
 */
export function getStatementYearMonth(
  statementDay: number,
  date: Date
): string {
  const day = date.getDate();
  const month = date.getMonth();
  const year = date.getFullYear();
  const stClamped = clampDay(statementDay, year, month);
  if (day <= stClamped) {
    return ymKey(year, month);
  }
  const next = addMonths(year, month, 1);
  return ymKey(next.year, next.monthZero);
}

/**
 * Resolve a StatementPeriod for a given (statementDay, yearMonth).
 */
export function getStatementPeriod(
  statementDay: number,
  yearMonth: string,
  today: Date = new Date()
): StatementPeriod {
  const { year, monthZero } = parseYM(yearMonth);
  const stDay = clampDay(statementDay, year, monthZero);
  const statementDate = startOfDay(new Date(year, monthZero, stDay));

  // Period start = previous month's statementDay + 1
  const prev = addMonths(year, monthZero, -1);
  const prevStDay = clampDay(statementDay, prev.year, prev.monthZero);
  const periodStart = startOfDay(new Date(prev.year, prev.monthZero, prevStDay + 1));
  // Handle wrap if prevStDay+1 > daysInMonth → setDate handles it via Date math
  // but we want a clean date; recompute via Date arithmetic:
  const adjStart = new Date(prev.year, prev.monthZero, prevStDay);
  adjStart.setDate(adjStart.getDate() + 1);
  adjStart.setHours(0, 0, 0, 0);

  const dueDate = new Date(statementDate);
  dueDate.setDate(dueDate.getDate() + 11);

  const t = startOfDay(today);
  const isActive = t >= adjStart && t <= statementDate;
  const isFuture = t < adjStart;

  return {
    yearMonth,
    periodStart: adjStart,
    periodEnd: statementDate,
    statementDate,
    dueDate,
    isActive,
    isFuture,
  };
}

/**
 * Active (uncut) statement YM for a card today.
 */
export function getActiveStatementYearMonth(
  statementDay: number,
  today: Date = new Date()
): string {
  return getStatementYearMonth(statementDay, today);
}

// ---- Auto amount from transactions -----------------------------------------

/**
 * For a given card (matched on tx.bank == matchKey) and target statement YM,
 * sum up the per-installment amounts of every credit-card expense whose
 * date+installmentOffset falls within that period.
 *
 * Installment expansion: a tx with installmentCount=N contributes amount/N to
 * each of N consecutive periods starting from the period that contains tx.date.
 */
export function computeAutoStatementAmount(
  matchKey: string,
  statementDay: number,
  targetYearMonth: string,
  transactions: Transaction[]
): number {
  const key = matchKey.trim().toLowerCase();
  if (!key) return 0;
  let total = 0;
  for (const tx of transactions) {
    if (tx.type !== "expense") continue;
    if (tx.paymentMethod !== "card") continue;
    if (!tx.bank || tx.bank.trim().toLowerCase() !== key) continue;
    const installments = Math.max(1, Math.floor(tx.installmentCount ?? 1));
    const per = tx.amount / installments;
    const txDate = new Date(tx.date);
    for (let i = 0; i < installments; i++) {
      const instDate = new Date(txDate);
      instDate.setMonth(instDate.getMonth() + i);
      const ym = getStatementYearMonth(statementDay, instDate);
      if (ym === targetYearMonth) {
        total += per;
      }
    }
  }
  return total;
}

// ---- All statements for a card ---------------------------------------------

/**
 * Returns all statement periods that have data (transactions OR manual entry)
 * plus the currently active uncut period — sorted oldest → newest.
 *
 * Transactions are matched by bank name (tx.bank), since that is what the
 * "Add Transaction" flow stores. If multiple cards share a bank, all of their
 * card transactions will count toward each card's statement — a known
 * limitation of the bank-name matching scheme.
 */
export function getAllStatementsForCard(args: {
  bankLimit: BankLimit;
  savedCard?: SavedCard;
  transactions: Transaction[];
  today?: Date;
}): ResolvedStatement[] {
  const { bankLimit, savedCard, transactions, today = new Date() } = args;
  const stDay = savedCard?.statementDay;
  const manualEntries = bankLimit.cardStatements ?? [];

  // No statementDay → we can't compute auto amounts or define real periods.
  // BUT if the user has entered manual amounts, surface those rows so they
  // are actionable (otherwise users see "Henüz ekstre dönemi yok" right after
  // adding a manual ekstre, which feels like data loss).
  if (!stDay) {
    if (manualEntries.length === 0) return [];
    return manualEntries
      .slice()
      .sort((a, b) => a.yearMonth.localeCompare(b.yearMonth))
      .map((e) => {
        const period = approximatePeriodFromYM(e.yearMonth, today);
        const manualAmount = e.manualAmount;
        const paidAmount = e.paidAmount ?? 0;
        const amount = manualAmount ?? 0;
        const remaining = Math.max(0, amount - paidAmount);
        const isFullyPaid = amount > 0 && paidAmount >= amount - 0.005;
        const hasData = amount > 0 || manualAmount !== undefined;
        return {
          ...period,
          autoAmount: 0,
          manualAmount,
          amount,
          paidAmount,
          remaining,
          isFullyPaid,
          hasData,
        };
      });
  }

  // tx.bank is the bank name (BANKS list value), not the card nickname.
  const matchKey =
    (bankLimit.bank && bankLimit.bank.trim()) ||
    (savedCard?.bank && savedCard.bank.trim()) ||
    "";

  // Collect candidate YMs from: manual entries, transactions (expanded), active period
  const candidateYMs = new Set<string>();
  for (const e of manualEntries) candidateYMs.add(e.yearMonth);

  const lcMatch = matchKey.trim().toLowerCase();
  for (const tx of transactions) {
    if (tx.type !== "expense") continue;
    if (tx.paymentMethod !== "card") continue;
    if (!tx.bank || tx.bank.trim().toLowerCase() !== lcMatch) continue;
    const installments = Math.max(1, Math.floor(tx.installmentCount ?? 1));
    const txDate = new Date(tx.date);
    for (let i = 0; i < installments; i++) {
      const instDate = new Date(txDate);
      instDate.setMonth(instDate.getMonth() + i);
      candidateYMs.add(getStatementYearMonth(stDay, instDate));
    }
  }
  candidateYMs.add(getActiveStatementYearMonth(stDay, today));

  const ymList = Array.from(candidateYMs).sort();
  return ymList.map((ym) => {
    const period = getStatementPeriod(stDay, ym, today);
    const auto = computeAutoStatementAmount(matchKey, stDay, ym, transactions);
    const manualEntry = manualEntries.find((e) => e.yearMonth === ym);
    const manualAmount = manualEntry?.manualAmount;
    const paidAmount = manualEntry?.paidAmount ?? 0;
    const amount = manualAmount !== undefined ? manualAmount : auto;
    const remaining = Math.max(0, amount - paidAmount);
    const isFullyPaid = amount > 0 && paidAmount >= amount - 0.005;
    const hasData = amount > 0 || manualAmount !== undefined;
    return {
      ...period,
      autoAmount: auto,
      manualAmount,
      amount,
      paidAmount,
      remaining,
      isFullyPaid,
      hasData,
    };
  });
}

// Fallback period when statementDay is not configured. Uses the YM's last
// calendar day as both periodEnd and statementDate, dueDate = +11 days.
// Period start = first day of the YM. Active flag derived from today vs. range.
function approximatePeriodFromYM(yearMonth: string, today: Date): StatementPeriod {
  const { year, monthZero } = parseYM(yearMonth);
  const periodStart = startOfDay(new Date(year, monthZero, 1));
  const lastDay = daysInMonth(year, monthZero);
  const statementDate = startOfDay(new Date(year, monthZero, lastDay));
  const dueDate = new Date(statementDate);
  dueDate.setDate(dueDate.getDate() + 11);
  const t = startOfDay(today);
  const isActive = t >= periodStart && t <= statementDate;
  const isFuture = t < periodStart;
  return {
    yearMonth,
    periodStart,
    periodEnd: statementDate,
    statementDate,
    dueDate,
    isActive,
    isFuture,
  };
}

// ---- Convenience -----------------------------------------------------------

/**
 * Total displayed CC debt for a BankLimit comes from limit - availableLimit.
 * If availableLimit is missing, fall back to sum of unpaid issued statements.
 */
export function getCardTotalDebt(
  bankLimit: BankLimit,
  resolvedStatements?: ResolvedStatement[]
): number {
  if (
    typeof bankLimit.availableLimit === "number" &&
    Number.isFinite(bankLimit.availableLimit)
  ) {
    return Math.max(0, bankLimit.limit - bankLimit.availableLimit);
  }
  if (resolvedStatements && resolvedStatements.length > 0) {
    return resolvedStatements
      .filter((s) => !s.isActive && !s.isFuture)
      .reduce((sum, s) => sum + s.remaining, 0);
  }
  return 0;
}

export function findSavedCardForBankLimit(
  bankLimit: BankLimit,
  savedCards: SavedCard[]
): SavedCard | undefined {
  if (bankLimit.savedCardId) {
    const byId = savedCards.find((c) => c.id === bankLimit.savedCardId);
    if (byId) return byId;
  }
  // Fallback by bank name (case-insensitive)
  const k = bankLimit.bank.trim().toLowerCase();
  return savedCards.find(
    (c) => c.type === "credit" && c.bank.trim().toLowerCase() === k
  );
}

export function formatStatementYearMonth(ym: string): string {
  const { year, monthZero } = parseYM(ym);
  const months = [
    "Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran",
    "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık",
  ];
  return `${months[monthZero]} ${year}`;
}

export type { CardStatementEntry } from "@/context/finans/BudgetContext";
