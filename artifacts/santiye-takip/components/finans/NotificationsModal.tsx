import { Feather } from "@expo/vector-icons";
import * as Notifications from "expo-notifications";
import React, { useCallback, useEffect, useState } from "react";
import {
  Alert,
  Modal,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Switch,
  Text,
  TouchableOpacity,
  View,
} from "react-native";

import { useTranslation } from "react-i18next";

import { Debt, useBudget } from "@/context/finans/BudgetContext";
import { useColors } from "@/hooks/finans/useColors";
import { useFormatAmount } from "@/hooks/finans/useFormatAmount";

function daysUntil(date: Date): number {
  const diff = date.getTime() - new Date().setHours(0, 0, 0, 0);
  return Math.ceil(diff / 86400000);
}

function installmentDate(startIso: string, index: number): Date {
  const d = new Date(startIso);
  d.setMonth(d.getMonth() + index);
  return d;
}

function getPaidSet(d: Debt): Set<number> {
  if (Array.isArray(d.paidInstallmentIndices) && d.paidInstallmentIndices.length > 0) {
    return new Set(d.paidInstallmentIndices);
  }
  return new Set(Array.from({ length: d.paidInstallments ?? 0 }, (_, i) => i));
}

type DebtAlert = {
  debt: Debt;
  days: number | null;
  label: string;
  color: string;
  displayAmount: number;
  isInstallment: false;
} | {
  debt: Debt;
  days: number;
  label: string;
  color: string;
  displayAmount: number;
  isInstallment: true;
  installmentIndex: number;
  totalInstallments: number;
  installmentDueDate: Date;
};

export function buildAlerts(
  debts: Debt[],
  colors: ReturnType<typeof import("@/hooks/finans/useColors").useColors>,
  t: (key: string, opts?: Record<string, unknown>) => string
): DebtAlert[] {
  const result: DebtAlert[] = [];

  for (const d of debts) {
    const remaining = d.amount - d.paidAmount;
    if (remaining <= 0) continue;

    if (d.isInstallment && d.totalInstallments && d.totalInstallments > 0) {
      const paidSet = getPaidSet(d);
      const perAmount = d.amount / d.totalInstallments;

      let nextIdx = -1;
      for (let i = 0; i < d.totalInstallments; i++) {
        if (!paidSet.has(i)) { nextIdx = i; break; }
      }
      if (nextIdx === -1) continue;

      const due = installmentDate(d.date, nextIdx);
      const days = daysUntil(due);
      let label = "";
      let color = colors.foreground;
      if (days < 0) { label = t("notifications.overdueDays", { days: Math.abs(days) }); color = colors.expense; }
      else if (days === 0) { label = t("notifications.dueTodayLabel"); color = colors.expense; }
      else if (days <= 3) { label = t("notifications.daysLeft", { days }); color = "#EF4444"; }
      else if (days <= 7) { label = t("notifications.daysLeft", { days }); color = "#F59E0B"; }
      else { label = t("notifications.daysLeft", { days }); color = colors.income; }

      result.push({
        debt: d, days, label, color, displayAmount: perAmount,
        isInstallment: true, installmentIndex: nextIdx,
        totalInstallments: d.totalInstallments, installmentDueDate: due,
      });
    } else {
      const dueIso = d.dueDate ?? d.date;
      if (!dueIso) continue;
      const due = new Date(dueIso);
      const days = daysUntil(due);
      let label = "";
      let color = colors.foreground;
      if (days < 0) { label = t("notifications.overdueDays", { days: Math.abs(days) }); color = colors.expense; }
      else if (days === 0) { label = t("notifications.dueTodayLabel"); color = colors.expense; }
      else if (days <= 3) { label = t("notifications.daysLeft", { days }); color = "#EF4444"; }
      else if (days <= 7) { label = t("notifications.daysLeft", { days }); color = "#F59E0B"; }
      else { label = t("notifications.daysLeft", { days }); color = colors.income; }

      result.push({ debt: d, days, label, color, displayAmount: remaining, isInstallment: false });
    }
  }

  return result.sort((a, b) => {
    const aVal = a.days ?? 9999;
    const bVal = b.days ?? 9999;
    return aVal - bVal;
  });
}

interface Props {
  visible: boolean;
  onClose: () => void;
}

export default function NotificationsModal({ visible, onClose }: Props) {
  const formatAmount = useFormatAmount();
  const colors = useColors();
  const { t } = useTranslation();
  const { debts } = useBudget();
  const [notifEnabled, setNotifEnabled] = useState(false);
  const [permStatus, setPermStatus] = useState<string>("undetermined");

  useEffect(() => {
    Notifications.getPermissionsAsync().then((s) => {
      setPermStatus(s.status);
      setNotifEnabled(s.status === "granted");
    });
  }, []);

  const requestPermission = useCallback(async () => {
    const { status } = await Notifications.requestPermissionsAsync();
    setPermStatus(status);
    setNotifEnabled(status === "granted");
    if (status !== "granted") {
      Alert.alert(
        t("notifications.permissionRequired"),
        t("notifications.permissionMsg")
      );
    }
    return status === "granted";
  }, [t]);

  const scheduleNotifications = useCallback(async () => {
    const granted = notifEnabled || (await requestPermission());
    if (!granted) return;

    await Notifications.cancelAllScheduledNotificationsAsync();
    let count = 0;

    for (const d of debts) {
      const remaining = d.amount - d.paidAmount;
      if (remaining <= 0) continue;

      if (d.isInstallment && d.totalInstallments && d.totalInstallments > 0) {
        const paidSet = getPaidSet(d);
        const perAmount = d.amount / d.totalInstallments;

        for (let i = 0; i < d.totalInstallments; i++) {
          if (paidSet.has(i)) continue;
          const due = installmentDate(d.date, i);
          due.setHours(9, 0, 0, 0);
          const dayBefore = new Date(due);
          dayBefore.setDate(dayBefore.getDate() - 1);
          const instLabel = t("notifications.installmentLabel", { current: i + 1, total: d.totalInstallments });

          if (dayBefore.getTime() > Date.now()) {
            await Notifications.scheduleNotificationAsync({
              content: {
                title: t("notifications.installmentReminderTitle"),
                body: `${d.name} — ${instLabel} ${formatAmount(perAmount)} ${t("notifications.tomorrowDue")}`,
                data: { debtId: d.id, installmentIndex: i },
              },
              trigger: { type: Notifications.SchedulableTriggerInputTypes.DATE, date: dayBefore },
            });
            count++;
          }
          if (due.getTime() > Date.now()) {
            await Notifications.scheduleNotificationAsync({
              content: {
                title: t("notifications.installmentDueTodayTitle"),
                body: `${d.name} — ${instLabel} ${formatAmount(perAmount)} ${t("notifications.todayDue")}`,
                data: { debtId: d.id, installmentIndex: i },
              },
              trigger: { type: Notifications.SchedulableTriggerInputTypes.DATE, date: due },
            });
            count++;
          }
        }
      } else {
        const dueIso = d.dueDate ?? d.date;
        if (!dueIso) continue;
        const dueDate = new Date(dueIso);

        const notify = new Date(dueDate);
        notify.setDate(notify.getDate() - 1);
        notify.setHours(9, 0, 0, 0);
        if (notify.getTime() > Date.now()) {
          await Notifications.scheduleNotificationAsync({
            content: {
              title: t("notifications.paymentReminderTitle"),
              body: `${d.name} — ${formatAmount(remaining)} ${t("notifications.tomorrowDue")}`,
              data: { debtId: d.id },
            },
            trigger: { type: Notifications.SchedulableTriggerInputTypes.DATE, date: notify },
          });
          count++;
        }
        const notifyDay = new Date(dueDate);
        notifyDay.setHours(9, 0, 0, 0);
        if (notifyDay.getTime() > Date.now()) {
          await Notifications.scheduleNotificationAsync({
            content: {
              title: t("notifications.dueTodayTitle"),
              body: `${d.name} — ${formatAmount(remaining)} ${t("notifications.todayDue")}`,
              data: { debtId: d.id },
            },
            trigger: { type: Notifications.SchedulableTriggerInputTypes.DATE, date: notifyDay },
          });
          count++;
        }
      }
    }

    Alert.alert(
      t("notifications.scheduledTitle"),
      count > 0
        ? t("notifications.scheduledMsg", { count })
        : t("notifications.noUpcomingDebts")
    );
  }, [debts, notifEnabled, requestPermission, t]);

  const toggleSwitch = useCallback(async (val: boolean) => {
    if (val) {
      const ok = await requestPermission();
      if (!ok) return;
      setNotifEnabled(true);
      await scheduleNotifications();
    } else {
      setNotifEnabled(false);
      await Notifications.cancelAllScheduledNotificationsAsync();
    }
  }, [requestPermission, scheduleNotifications]);

  const alerts = React.useMemo<DebtAlert[]>(() => buildAlerts(debts, colors, t), [debts, colors, t]);
  const overdue = alerts.filter((a) => a.days !== null && a.days < 0);
  const today = alerts.filter((a) => a.days === 0);
  const soon = alerts.filter((a) => a.days !== null && a.days > 0 && a.days <= 7);
  const upcoming = alerts.filter((a) => a.days !== null && a.days > 7);
  const noDue = alerts.filter((a) => a.days === null);

  const installmentCount = debts.filter(
    (d) => d.isInstallment && d.totalInstallments && d.totalInstallments > 0 && d.amount - d.paidAmount > 0
  ).length;

  const styles = StyleSheet.create({
    overlay: {
      flex: 1,
      backgroundColor: "rgba(0,0,0,0.55)",
      justifyContent: "flex-end",
    },
    sheet: {
      backgroundColor: colors.background,
      borderTopLeftRadius: 24,
      borderTopRightRadius: 24,
      maxHeight: "88%",
    },
    handle: {
      width: 40,
      height: 4,
      backgroundColor: colors.border,
      borderRadius: 2,
      alignSelf: "center",
      marginTop: 12,
      marginBottom: 4,
    },
    sheetHeader: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      paddingHorizontal: 20,
      paddingVertical: 14,
      borderBottomWidth: 1,
      borderBottomColor: colors.border,
    },
    sheetTitle: { fontSize: 18, fontWeight: "800", color: colors.foreground },
    closeBtn: {
      width: 32,
      height: 32,
      borderRadius: 16,
      backgroundColor: colors.muted,
      alignItems: "center",
      justifyContent: "center",
    },
    notifCard: {
      margin: 16,
      marginBottom: 0,
      backgroundColor: colors.card,
      borderRadius: 16,
      padding: 14,
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
    },
    notifCardLeft: { flex: 1, gap: 2 },
    notifCardTitle: { fontSize: 14, fontWeight: "700", color: colors.foreground },
    notifCardSub: { fontSize: 11, color: colors.mutedForeground },
    scheduleBtn: {
      marginHorizontal: 16,
      marginTop: 10,
      backgroundColor: colors.primary,
      borderRadius: 12,
      paddingVertical: 11,
      alignItems: "center",
    },
    scheduleBtnText: { fontSize: 14, fontWeight: "700", color: "#FFFFFF" },
    infoCard: {
      marginHorizontal: 16,
      marginTop: 10,
      backgroundColor: colors.primary + "18",
      borderRadius: 12,
      padding: 10,
      flexDirection: "row",
      alignItems: "center",
      gap: 8,
    },
    infoText: { flex: 1, fontSize: 11, color: colors.primary, lineHeight: 16 },
    section: { marginTop: 18, paddingHorizontal: 16 },
    sectionTitle: {
      fontSize: 11,
      fontWeight: "800",
      color: colors.mutedForeground,
      letterSpacing: 0.5,
      marginBottom: 8,
    },
    card: {
      backgroundColor: colors.card,
      borderRadius: 14,
      padding: 12,
      marginBottom: 8,
      flexDirection: "row",
      alignItems: "center",
      gap: 10,
    },
    dot: { width: 10, height: 10, borderRadius: 5 },
    cardBody: { flex: 1 },
    cardName: { fontSize: 13, fontWeight: "600", color: colors.foreground },
    cardSub: { fontSize: 11, color: colors.mutedForeground, marginTop: 1 },
    cardInstallmentBadge: {
      alignSelf: "flex-start",
      backgroundColor: colors.primary + "22",
      borderRadius: 6,
      paddingHorizontal: 6,
      paddingVertical: 2,
      marginTop: 3,
    },
    cardInstallmentBadgeText: { fontSize: 10, fontWeight: "700", color: colors.primary },
    cardRight: { alignItems: "flex-end", gap: 2 },
    cardAmount: { fontSize: 12, fontWeight: "700", color: colors.foreground },
    cardLabel: { fontSize: 11, fontWeight: "600" },
    cardDate: { fontSize: 10, color: colors.mutedForeground, marginTop: 1 },
    emptyWrap: { alignItems: "center", paddingVertical: 32, gap: 8 },
    emptyText: { fontSize: 14, color: colors.mutedForeground, fontStyle: "italic" },
  });

  const renderDebtCard = (a: DebtAlert) => {
    if (a.isInstallment) {
      const dateStr = a.installmentDueDate.toLocaleDateString(undefined, {
        day: "numeric", month: "long", year: "numeric",
      });
      return (
        <View key={`${a.debt.id}-inst-${a.installmentIndex}`} style={styles.card}>
          <View style={[styles.dot, { backgroundColor: a.color }]} />
          <View style={styles.cardBody}>
            <Text style={styles.cardName}>{a.debt.name}</Text>
            <Text style={styles.cardSub}>
              {a.debt.category}{a.debt.creditor ? ` • ${a.debt.creditor}` : ""}
            </Text>
            <View style={styles.cardInstallmentBadge}>
              <Text style={styles.cardInstallmentBadgeText}>
                {t("notifications.installmentBadgeShort", { current: a.installmentIndex + 1, total: a.totalInstallments })}
              </Text>
            </View>
          </View>
          <View style={styles.cardRight}>
            <Text style={styles.cardAmount}>{formatAmount(a.displayAmount)}</Text>
            <Text style={[styles.cardLabel, { color: a.color }]}>{a.label}</Text>
            <Text style={styles.cardDate}>{dateStr}</Text>
          </View>
        </View>
      );
    }

    const dueIso = a.debt.dueDate ?? a.debt.date;
    const dateStr = dueIso
      ? new Date(dueIso).toLocaleDateString(undefined, { day: "numeric", month: "long", year: "numeric" })
      : "";

    return (
      <View key={a.debt.id} style={styles.card}>
        <View style={[styles.dot, { backgroundColor: a.color }]} />
        <View style={styles.cardBody}>
          <Text style={styles.cardName}>{a.debt.name}</Text>
          <Text style={styles.cardSub}>
            {a.debt.category}{a.debt.creditor ? ` • ${a.debt.creditor}` : ""}
          </Text>
        </View>
        <View style={styles.cardRight}>
          <Text style={styles.cardAmount}>{formatAmount(a.displayAmount)}</Text>
          <Text style={[styles.cardLabel, { color: a.color }]}>{a.label}</Text>
          {dateStr ? <Text style={styles.cardDate}>{dateStr}</Text> : null}
        </View>
      </View>
    );
  };

  return (
    <Modal
      visible={visible}
      transparent
      animationType="slide"
      onRequestClose={onClose}
      statusBarTranslucent
    >
      <Pressable style={styles.overlay} onPress={onClose}>
        <Pressable onPress={(e) => e.stopPropagation()} style={styles.sheet}>
          <View style={styles.handle} />
          <View style={styles.sheetHeader}>
            <Text style={styles.sheetTitle}>🔔 {t("notifications.title")}</Text>
            <TouchableOpacity style={styles.closeBtn} onPress={onClose} activeOpacity={0.7}>
              <Feather name="x" size={16} color={colors.foreground} />
            </TouchableOpacity>
          </View>

          <ScrollView
            showsVerticalScrollIndicator={false}
            contentContainerStyle={{ paddingBottom: 40 }}
          >
            <View style={styles.notifCard}>
              <View style={styles.notifCardLeft}>
                <Text style={styles.notifCardTitle}>
                  <Feather name="bell" size={13} /> {t("notifications.paymentReminders")}
                </Text>
                <Text style={styles.notifCardSub}>
                  {notifEnabled
                    ? t("notifications.enabledDesc")
                    : t("notifications.disabledDesc")}
                </Text>
              </View>
              <Switch
                value={notifEnabled}
                onValueChange={toggleSwitch}
                trackColor={{ false: colors.muted, true: colors.primary }}
                thumbColor="#FFFFFF"
              />
            </View>

            {installmentCount > 0 && (
              <View style={styles.infoCard}>
                <Feather name="layers" size={13} color={colors.primary} />
                <Text style={styles.infoText}>
                  {t("notifications.installmentInfo", { count: installmentCount })}
                </Text>
              </View>
            )}

            {notifEnabled && (
              <TouchableOpacity style={styles.scheduleBtn} onPress={scheduleNotifications}>
                <Text style={styles.scheduleBtnText}>🔔 {t("notifications.refresh")}</Text>
              </TouchableOpacity>
            )}

            {overdue.length > 0 && (
              <View style={styles.section}>
                <Text style={[styles.sectionTitle, { color: colors.expense }]}>
                  ⚠️ {t("notifications.overdue")} ({overdue.length})
                </Text>
                {overdue.map(renderDebtCard)}
              </View>
            )}

            {today.length > 0 && (
              <View style={styles.section}>
                <Text style={[styles.sectionTitle, { color: colors.expense }]}>
                  🔴 {t("notifications.dueToday")} ({today.length})
                </Text>
                {today.map(renderDebtCard)}
              </View>
            )}

            {soon.length > 0 && (
              <View style={styles.section}>
                <Text style={[styles.sectionTitle, { color: "#F59E0B" }]}>
                  🟡 {t("notifications.thisWeek")} ({soon.length})
                </Text>
                {soon.map(renderDebtCard)}
              </View>
            )}

            {upcoming.length > 0 && (
              <View style={styles.section}>
                <Text style={[styles.sectionTitle, { color: colors.income }]}>
                  🟢 {t("notifications.upcoming")} ({upcoming.length})
                </Text>
                {upcoming.map(renderDebtCard)}
              </View>
            )}

            {noDue.length > 0 && (
              <View style={styles.section}>
                <Text style={styles.sectionTitle}>{t("notifications.noDue")} ({noDue.length})</Text>
                {noDue.map(renderDebtCard)}
              </View>
            )}

            {alerts.length === 0 && (
              <View style={styles.emptyWrap}>
                <Feather name="check-circle" size={36} color={colors.income} />
                <Text style={styles.emptyText}>{t("notifications.noActive")}</Text>
              </View>
            )}
          </ScrollView>
        </Pressable>
      </Pressable>
    </Modal>
  );
}
