import { Feather } from "@expo/vector-icons";
import * as Haptics from "expo-haptics";
import * as Notifications from "expo-notifications";
import React, { useCallback, useEffect, useState } from "react";
import {
  Alert,
  Platform,
  ScrollView,
  StyleSheet,
  Switch,
  Text,
  TouchableOpacity,
  View,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { useTranslation } from "react-i18next";

import { Debt, useBudget } from "@/context/finans/BudgetContext";
import { useColors } from "@/hooks/finans/useColors";
import { useFormatAmount } from "@/hooks/finans/useFormatAmount";

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldShowAlert: true,
    shouldPlaySound: true,
    shouldSetBadge: false,
    shouldShowBanner: true,
    shouldShowList: true,
  }),
});

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

type TFunction = (key: string, options?: Record<string, unknown>) => string;

function buildAlerts(
  debts: Debt[],
  colors: ReturnType<typeof import("@/hooks/finans/useColors").useColors>,
  t: TFunction
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
        if (!paidSet.has(i)) {
          nextIdx = i;
          break;
        }
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
        debt: d,
        days,
        label,
        color,
        displayAmount: perAmount,
        isInstallment: true,
        installmentIndex: nextIdx,
        totalInstallments: d.totalInstallments,
        installmentDueDate: due,
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

      result.push({
        debt: d,
        days,
        label,
        color,
        displayAmount: remaining,
        isInstallment: false,
      });
    }
  }

  return result.sort((a, b) => {
    const aVal = a.days ?? 9999;
    const bVal = b.days ?? 9999;
    return aVal - bVal;
  });
}

export default function NotificationsScreen() {
  const formatAmount = useFormatAmount();
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const { debts } = useBudget();
  const { t, i18n } = useTranslation();
  const [notifEnabled, setNotifEnabled] = useState(false);
  const [permStatus, setPermStatus] = useState<string>("undetermined");

  const topInset = 0;
  const bottomInset = Platform.OS === "web" ? 34 : insets.bottom;

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
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
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
                body: t("notifications.reminderBody", { name: d.name, amount: `${instLabel} ${formatAmount(perAmount)}` }),
                data: { debtId: d.id, installmentIndex: i },
              },
              trigger: {
                type: Notifications.SchedulableTriggerInputTypes.DATE,
                date: dayBefore,
              },
            });
            count++;
          }

          if (due.getTime() > Date.now()) {
            await Notifications.scheduleNotificationAsync({
              content: {
                title: t("notifications.installmentDueTodayTitle"),
                body: t("notifications.dueTodayBody", { name: d.name, amount: `${instLabel} ${formatAmount(perAmount)}` }),
                data: { debtId: d.id, installmentIndex: i },
              },
              trigger: {
                type: Notifications.SchedulableTriggerInputTypes.DATE,
                date: due,
              },
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
              title: t("notifications.reminderTitle"),
              body: t("notifications.reminderBody", { name: d.name, amount: formatAmount(remaining) }),
              data: { debtId: d.id },
            },
            trigger: {
              type: Notifications.SchedulableTriggerInputTypes.DATE,
              date: notify,
            },
          });
          count++;
        }

        const notifyDay = new Date(dueDate);
        notifyDay.setHours(9, 0, 0, 0);
        if (notifyDay.getTime() > Date.now()) {
          await Notifications.scheduleNotificationAsync({
            content: {
              title: t("notifications.dueTodayTitle"),
              body: t("notifications.dueTodayBody", { name: d.name, amount: formatAmount(remaining) }),
              data: { debtId: d.id },
            },
            trigger: {
              type: Notifications.SchedulableTriggerInputTypes.DATE,
              date: notifyDay,
            },
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

  const toggleSwitch = useCallback(
    async (val: boolean) => {
      if (val) {
        const ok = await requestPermission();
        if (!ok) return;
        setNotifEnabled(true);
        await scheduleNotifications();
      } else {
        setNotifEnabled(false);
        await Notifications.cancelAllScheduledNotificationsAsync();
        Haptics.selectionAsync();
      }
    },
    [requestPermission, scheduleNotifications]
  );

  const alerts = React.useMemo<DebtAlert[]>(
    () => buildAlerts(debts, colors, t as TFunction),
    [debts, colors, t]
  );

  const overdue = alerts.filter((a) => a.days !== null && a.days < 0);
  const today = alerts.filter((a) => a.days === 0);
  const soon = alerts.filter((a) => a.days !== null && a.days > 0 && a.days <= 7);
  const upcoming = alerts.filter((a) => a.days !== null && a.days > 7);
  const noDue = alerts.filter((a) => a.days === null);

  const installmentCount = debts.filter(
    (d) => d.isInstallment && d.totalInstallments && d.totalInstallments > 0 && d.amount - d.paidAmount > 0
  ).length;

  const styles = StyleSheet.create({
    container: { flex: 1, backgroundColor: colors.background },
    header: {
      backgroundColor: colors.navy,
      paddingTop: topInset + 16,
      paddingBottom: 28,
      paddingHorizontal: 24,
    },
    headerTitle: { fontSize: 26, fontWeight: "800", color: "#FFFFFF", marginBottom: 4 },
    headerSub: { fontSize: 13, color: "rgba(255,255,255,0.6)" },
    notifCard: {
      margin: 20,
      marginBottom: 0,
      backgroundColor: colors.card,
      borderRadius: 16,
      padding: 16,
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
    },
    notifCardLeft: { flex: 1, gap: 2 },
    notifCardTitle: { fontSize: 15, fontWeight: "700", color: colors.foreground },
    notifCardSub: { fontSize: 12, color: colors.mutedForeground },
    scheduleBtn: {
      marginHorizontal: 20,
      marginTop: 10,
      backgroundColor: colors.primary,
      borderRadius: 12,
      paddingVertical: 12,
      alignItems: "center",
    },
    scheduleBtnText: { fontSize: 14, fontWeight: "700", color: "#FFFFFF" },
    section: { marginTop: 22, paddingHorizontal: 20 },
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
      padding: 14,
      marginBottom: 8,
      flexDirection: "row",
      alignItems: "center",
      gap: 12,
    },
    dot: { width: 10, height: 10, borderRadius: 5 },
    cardBody: { flex: 1 },
    cardName: { fontSize: 14, fontWeight: "600", color: colors.foreground },
    cardSub: { fontSize: 12, color: colors.mutedForeground, marginTop: 1 },
    cardInstallmentBadge: {
      alignSelf: "flex-start",
      backgroundColor: colors.primary + "22",
      borderRadius: 6,
      paddingHorizontal: 6,
      paddingVertical: 2,
      marginTop: 4,
    },
    cardInstallmentBadgeText: { fontSize: 10, fontWeight: "700", color: colors.primary },
    cardRight: { alignItems: "flex-end", gap: 2 },
    cardAmount: { fontSize: 13, fontWeight: "700", color: colors.foreground },
    cardLabel: { fontSize: 11, fontWeight: "600" },
    cardDate: { fontSize: 10, color: colors.mutedForeground, marginTop: 1 },
    emptyText: {
      textAlign: "center",
      color: colors.mutedForeground,
      fontSize: 13,
      paddingVertical: 16,
      fontStyle: "italic",
    },
    infoCard: {
      marginHorizontal: 20,
      marginTop: 10,
      backgroundColor: colors.primary + "18",
      borderRadius: 12,
      padding: 12,
      flexDirection: "row",
      alignItems: "center",
      gap: 8,
    },
    infoText: { flex: 1, fontSize: 12, color: colors.primary, lineHeight: 17 },
  });

  const renderDebtCard = (a: DebtAlert) => {
    if (a.isInstallment) {
      const dateStr = a.installmentDueDate.toLocaleDateString(i18n.language, {
        day: "numeric",
        month: "long",
        year: "numeric",
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
                {t("notifications.installmentBadge", { current: a.installmentIndex + 1, total: a.totalInstallments })}
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
      ? new Date(dueIso).toLocaleDateString(i18n.language, {
          day: "numeric",
          month: "long",
          year: "numeric",
        })
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
    <View style={styles.container}>
      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={{ paddingBottom: bottomInset + 100 }}
      >
        <View style={styles.header}>
          <Text style={styles.headerTitle}>{t("notifications.title")}</Text>
          <Text style={styles.headerSub}>{t("notifications.paymentSubtitle")}</Text>
        </View>

        <View style={styles.notifCard}>
          <View style={styles.notifCardLeft}>
            <Text style={styles.notifCardTitle}>
              <Feather name="bell" size={14} /> {t("notifications.paymentReminders")}
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
            <Feather name="layers" size={14} color={colors.primary} />
            <Text style={styles.infoText}>
              {t("notifications.installmentInfoMsg", { count: installmentCount })}
            </Text>
          </View>
        )}

        {notifEnabled && (
          <TouchableOpacity style={styles.scheduleBtn} onPress={scheduleNotifications}>
            <Text style={styles.scheduleBtnText}>{t("notifications.refreshBtn")}</Text>
          </TouchableOpacity>
        )}

        {overdue.length > 0 && (
          <View style={styles.section}>
            <Text style={[styles.sectionTitle, { color: colors.expense }]}>
              {t("notifications.overdueSection", { count: overdue.length })}
            </Text>
            {overdue.map(renderDebtCard)}
          </View>
        )}

        {today.length > 0 && (
          <View style={styles.section}>
            <Text style={[styles.sectionTitle, { color: colors.expense }]}>
              {t("notifications.todaySection", { count: today.length })}
            </Text>
            {today.map(renderDebtCard)}
          </View>
        )}

        {soon.length > 0 && (
          <View style={styles.section}>
            <Text style={[styles.sectionTitle, { color: "#F59E0B" }]}>
              {t("notifications.thisWeekSection", { count: soon.length })}
            </Text>
            {soon.map(renderDebtCard)}
          </View>
        )}

        {upcoming.length > 0 && (
          <View style={styles.section}>
            <Text style={[styles.sectionTitle, { color: colors.income }]}>
              {t("notifications.upcomingSection", { count: upcoming.length })}
            </Text>
            {upcoming.map(renderDebtCard)}
          </View>
        )}

        {noDue.length > 0 && (
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>
              {t("notifications.noDueCategory", { count: noDue.length })}
            </Text>
            {noDue.map(renderDebtCard)}
          </View>
        )}

        {alerts.length === 0 && (
          <Text style={[styles.emptyText, { marginTop: 40 }]}>
            {t("notifications.noActive")}
          </Text>
        )}
      </ScrollView>
    </View>
  );
}
