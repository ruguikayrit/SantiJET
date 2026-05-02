/**
 * Local-notification reminders for credit-card statement cuts, CC due dates
 * and manual debt due dates. All scheduling is local (no push server). Web
 * is a no-op. Expo Go on Android may have reduced capabilities — failures
 * are caught and ignored so the app keeps running.
 *
 * Strategy: every time the source data changes, cancel everything we own
 * and re-schedule the NEXT few occurrences for each (card, kind) pair.
 * Since the app reschedules on every relevant change AND on cold start,
 * notifications roll forward as long as the user opens the app once a
 * month or so.
 */

import * as Notifications from "expo-notifications";
import { Platform } from "react-native";

import type { BankLimit, Debt, SavedCard, Transaction } from "@/context/finans/BudgetContext";
import {
  findSavedCardForBankLimit,
  getAllStatementsForCard,
  formatStatementYearMonth,
} from "@/utils/finans/statements";

export interface ReminderSettings {
  enabled: boolean;
  ccDueReminder: boolean;
  ccDueDaysBefore: number; // 1, 3, 7
  ccStatementReminder: boolean;
  debtDueReminder: boolean;
  debtDueDaysBefore: number;
  reminderHour: number; // 0-23
}

export const DEFAULT_REMINDER_SETTINGS: ReminderSettings = {
  enabled: false,
  ccDueReminder: true,
  ccDueDaysBefore: 3,
  ccStatementReminder: true,
  debtDueReminder: true,
  debtDueDaysBefore: 3,
  reminderHour: 9,
};

const ID_PREFIX = "budget_reminder_";

function isAvailable(): boolean {
  return Platform.OS === "ios" || Platform.OS === "android";
}

let handlerInstalled = false;
function ensureHandler() {
  if (handlerInstalled) return;
  try {
    Notifications.setNotificationHandler({
      handleNotification: async () => ({
        shouldShowBanner: true,
        shouldShowList: true,
        shouldPlaySound: true,
        shouldSetBadge: false,
      }),
    });
    handlerInstalled = true;
  } catch {
    // older runtimes
  }
}

export async function ensureNotificationChannel(): Promise<void> {
  if (Platform.OS !== "android") return;
  try {
    await Notifications.setNotificationChannelAsync("reminders", {
      name: "Hatırlatıcılar",
      importance: Notifications.AndroidImportance.HIGH,
      vibrationPattern: [0, 250, 250, 250],
      lightColor: "#00C896",
    });
  } catch {
    // ignore
  }
}

export async function requestNotificationPermission(): Promise<boolean> {
  if (!isAvailable()) return false;
  ensureHandler();
  await ensureNotificationChannel();
  try {
    const current = await Notifications.getPermissionsAsync();
    if (current.granted) return true;
    if (!current.canAskAgain) return false;
    const req = await Notifications.requestPermissionsAsync();
    return !!req.granted;
  } catch {
    return false;
  }
}

export async function hasNotificationPermission(): Promise<boolean> {
  if (!isAvailable()) return false;
  try {
    const current = await Notifications.getPermissionsAsync();
    return !!current.granted;
  } catch {
    return false;
  }
}

async function cancelOurReminders(): Promise<void> {
  if (!isAvailable()) return;
  try {
    const all = await Notifications.getAllScheduledNotificationsAsync();
    await Promise.all(
      all
        .filter((n) => typeof n.identifier === "string" && n.identifier.startsWith(ID_PREFIX))
        .map((n) => Notifications.cancelScheduledNotificationAsync(n.identifier))
    );
  } catch {
    // ignore
  }
}

function atHour(date: Date, hour: number): Date {
  const r = new Date(date);
  r.setHours(hour, 0, 0, 0);
  return r;
}

function shiftDays(date: Date, days: number): Date {
  const r = new Date(date);
  r.setDate(r.getDate() + days);
  return r;
}

interface ScheduleItem {
  id: string;
  fireAt: Date;
  title: string;
  body: string;
}

function buildCardReminders(
  bankLimits: BankLimit[],
  savedCards: SavedCard[],
  transactions: Transaction[],
  settings: ReminderSettings,
  now: Date,
  horizonMonths: number,
): ScheduleItem[] {
  const out: ScheduleItem[] = [];
  if (!settings.ccDueReminder && !settings.ccStatementReminder) return out;

  const horizon = new Date(now);
  horizon.setMonth(horizon.getMonth() + horizonMonths);

  for (const bl of bankLimits) {
    if (bl.type !== "credit") continue;
    const card = findSavedCardForBankLimit(bl, savedCards);
    if (!card?.statementDay) continue;

    const statements = getAllStatementsForCard({
      bankLimit: bl,
      savedCard: card,
      transactions,
      today: now,
    });

    for (const s of statements) {
      // Statement cut reminder — fires ON the cut day at reminderHour
      if (settings.ccStatementReminder) {
        const fire = atHour(s.statementDate, settings.reminderHour);
        if (fire > now && fire <= horizon) {
          out.push({
            id: `${ID_PREFIX}cut_${bl.id}_${s.yearMonth}`,
            fireAt: fire,
            title: `${bl.bank} ekstresi kesildi`,
            body: `${formatStatementYearMonth(s.yearMonth)} dönemi için ekstreni kontrol et.`,
          });
        }
      }
      // Due date reminder — N days before due date
      if (settings.ccDueReminder && !s.isFullyPaid) {
        const fire = atHour(
          shiftDays(s.dueDate, -Math.max(0, settings.ccDueDaysBefore)),
          settings.reminderHour,
        );
        if (fire > now && fire <= horizon) {
          const daysLabel =
            settings.ccDueDaysBefore === 0
              ? "bugün"
              : `${settings.ccDueDaysBefore} gün sonra`;
          out.push({
            id: `${ID_PREFIX}duecc_${bl.id}_${s.yearMonth}`,
            fireAt: fire,
            title: `${bl.bank} son ödeme ${daysLabel}`,
            body: `${formatStatementYearMonth(s.yearMonth)} ekstresi için son ödeme tarihi yaklaşıyor.`,
          });
        }
      }
    }
  }
  return out;
}

function buildDebtReminders(
  debts: Debt[],
  settings: ReminderSettings,
  now: Date,
  horizon: Date,
): ScheduleItem[] {
  const out: ScheduleItem[] = [];
  if (!settings.debtDueReminder) return out;

  for (const d of debts) {
    if (!d.dueDate) continue;
    if (d.paidAmount >= d.amount - 0.005) continue;
    const due = new Date(d.dueDate);
    if (Number.isNaN(due.getTime())) continue;
    const fire = atHour(
      shiftDays(due, -Math.max(0, settings.debtDueDaysBefore)),
      settings.reminderHour,
    );
    if (fire > now && fire <= horizon) {
      const daysLabel =
        settings.debtDueDaysBefore === 0
          ? "bugün"
          : `${settings.debtDueDaysBefore} gün sonra`;
      out.push({
        id: `${ID_PREFIX}duedebt_${d.id}`,
        fireAt: fire,
        title: `${d.name} vadesi ${daysLabel}`,
        body: d.creditor
          ? `${d.creditor} • Kalan: ${(d.amount - d.paidAmount).toFixed(0)} TL`
          : `Kalan: ${(d.amount - d.paidAmount).toFixed(0)} TL`,
      });
    }
  }
  return out;
}

const MAX_PENDING = 50; // safe under iOS' 64 limit

export async function rescheduleAllReminders(args: {
  bankLimits: BankLimit[];
  savedCards: SavedCard[];
  transactions: Transaction[];
  debts: Debt[];
  settings: ReminderSettings;
}): Promise<{ scheduled: number; skipped: boolean }> {
  if (!isAvailable()) return { scheduled: 0, skipped: true };
  ensureHandler();
  await ensureNotificationChannel();

  await cancelOurReminders();

  if (!args.settings.enabled) {
    return { scheduled: 0, skipped: false };
  }

  const granted = await hasNotificationPermission();
  if (!granted) return { scheduled: 0, skipped: true };

  const now = new Date();
  const horizonMonths = 4;
  const horizon = new Date(now);
  horizon.setMonth(horizon.getMonth() + horizonMonths);

  const cardItems = buildCardReminders(
    args.bankLimits,
    args.savedCards,
    args.transactions,
    args.settings,
    now,
    horizonMonths,
  );
  const debtItems = buildDebtReminders(args.debts, args.settings, now, horizon);

  const all = [...cardItems, ...debtItems]
    .sort((a, b) => a.fireAt.getTime() - b.fireAt.getTime())
    .slice(0, MAX_PENDING);

  const results = await Promise.all(
    all.map((it) =>
      Notifications.scheduleNotificationAsync({
        identifier: it.id,
        content: {
          title: it.title,
          body: it.body,
          ...(Platform.OS === "android" ? { channelId: "reminders" } : {}),
        },
        trigger: {
          type: Notifications.SchedulableTriggerInputTypes.DATE,
          date: it.fireAt,
        },
      })
        .then(() => true as const)
        .catch(() => false as const),
    ),
  );
  const scheduled = results.filter(Boolean).length;
  return { scheduled, skipped: false };
}

export async function sendTestNotification(): Promise<boolean> {
  if (!isAvailable()) return false;
  ensureHandler();
  await ensureNotificationChannel();
  try {
    await Notifications.scheduleNotificationAsync({
      identifier: `${ID_PREFIX}test_${Date.now()}`,
      content: {
        title: "KasaFON — Test",
        body: "Bildirimler çalışıyor. Hatırlatıcılarını planladık.",
        ...(Platform.OS === "android" ? { channelId: "reminders" } : {}),
      },
      trigger: {
        type: Notifications.SchedulableTriggerInputTypes.TIME_INTERVAL,
        seconds: 2,
      },
    });
    return true;
  } catch {
    return false;
  }
}
