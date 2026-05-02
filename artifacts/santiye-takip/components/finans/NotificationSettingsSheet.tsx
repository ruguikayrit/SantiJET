import { Feather } from "@expo/vector-icons";
import * as Haptics from "expo-haptics";
import React, { useEffect, useState } from "react";
import {
  Modal,
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

import { useBudget } from "@/context/finans/BudgetContext";
import { useColors } from "@/hooks/finans/useColors";
import {
  DEFAULT_REMINDER_SETTINGS,
  type ReminderSettings,
  sendTestNotification,
} from "@/utils/finans/notifications";

interface Props {
  visible: boolean;
  onClose: () => void;
}

const DAYS_CYCLE = [0, 1, 3, 7];
const HOUR_CYCLE = [8, 9, 10, 12, 18, 20];

function cycleDays(n: number): number {
  const i = DAYS_CYCLE.indexOf(n);
  return DAYS_CYCLE[(i === -1 ? 0 : i + 1) % DAYS_CYCLE.length];
}
function cycleHour(n: number): number {
  const i = HOUR_CYCLE.indexOf(n);
  return HOUR_CYCLE[(i === -1 ? 0 : i + 1) % HOUR_CYCLE.length];
}
function fmtHour(h: number): string {
  return `${String(h).padStart(2, "0")}:00`;
}

export default function NotificationSettingsSheet({ visible, onClose }: Props) {
  const { t } = useTranslation();
  const colors = useColors();
  const { reminderSettings, updateReminderSettings } = useBudget();
  const { bottom } = useSafeAreaInsets();

  const fmtDays = (n: number): string =>
    n === 0 ? t("notifSheet.sameDay") : t("notifSheet.daysBefore", { count: n });

  const [draft, setDraft] = useState<ReminderSettings>({
    ...DEFAULT_REMINDER_SETTINGS,
    enabled: true,
  });

  useEffect(() => {
    if (visible) {
      setDraft({ ...reminderSettings, enabled: true });
    }
  }, [visible]);

  function patch(p: Partial<ReminderSettings>) {
    setDraft((prev) => ({ ...prev, ...p }));
  }

  function handleSave() {
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    updateReminderSettings(draft);
    onClose();
  }

  function handleCancel() {
    Haptics.selectionAsync();
    if (!reminderSettings.enabled) {
      updateReminderSettings({ enabled: false });
    }
    onClose();
  }

  async function handleTest() {
    Haptics.selectionAsync();
    await sendTestNotification();
  }

  const s = StyleSheet.create({
    overlay: {
      flex: 1,
      backgroundColor: "rgba(0,0,0,0.45)",
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
      borderRadius: 2,
      backgroundColor: colors.border,
      alignSelf: "center",
      marginTop: 10,
      marginBottom: 4,
    },
    header: {
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
      paddingHorizontal: 20,
      paddingVertical: 14,
      borderBottomWidth: 1,
      borderBottomColor: colors.border,
    },
    headerTitle: {
      fontSize: 17,
      fontWeight: "700" as const,
      color: colors.foreground,
    },
    closeBtn: {
      width: 32,
      height: 32,
      borderRadius: 16,
      backgroundColor: colors.muted,
      alignItems: "center",
      justifyContent: "center",
    },
    body: {
      paddingHorizontal: 16,
      paddingTop: 16,
    },
    card: {
      backgroundColor: colors.card,
      borderRadius: 16,
      overflow: "hidden" as const,
      marginBottom: 12,
    },
    row: {
      flexDirection: "row" as const,
      alignItems: "center" as const,
      paddingHorizontal: 16,
      paddingVertical: 13,
      gap: 12,
    },
    subRow: {
      flexDirection: "row" as const,
      alignItems: "center" as const,
      paddingHorizontal: 16,
      paddingLeft: 52,
      paddingVertical: 11,
      gap: 12,
      backgroundColor: colors.accent,
    },
    divider: {
      height: 1,
      backgroundColor: colors.border,
    },
    iconBg: {
      width: 34,
      height: 34,
      borderRadius: 10,
      backgroundColor: colors.muted,
      alignItems: "center" as const,
      justifyContent: "center" as const,
    },
    rowBody: { flex: 1 },
    rowTitle: {
      fontSize: 14,
      fontWeight: "600" as const,
      color: colors.foreground,
    },
    rowDesc: {
      fontSize: 12,
      color: colors.mutedForeground,
      marginTop: 1,
    },
    chipBtn: {
      flexDirection: "row" as const,
      alignItems: "center" as const,
      gap: 4,
      backgroundColor: colors.muted,
      paddingHorizontal: 10,
      paddingVertical: 5,
      borderRadius: 20,
    },
    chipTxt: {
      fontSize: 13,
      fontWeight: "600" as const,
      color: colors.primary,
    },
    footer: {
      flexDirection: "row" as const,
      gap: 10,
      paddingHorizontal: 16,
      paddingTop: 12,
      paddingBottom: bottom + 16,
      borderTopWidth: 1,
      borderTopColor: colors.border,
    },
    cancelBtn: {
      flex: 1,
      alignItems: "center" as const,
      justifyContent: "center" as const,
      paddingVertical: 13,
      borderRadius: 14,
      backgroundColor: colors.muted,
    },
    cancelTxt: {
      fontSize: 15,
      fontWeight: "600" as const,
      color: colors.mutedForeground,
    },
    saveBtn: {
      flex: 2,
      alignItems: "center" as const,
      justifyContent: "center" as const,
      paddingVertical: 13,
      borderRadius: 14,
      backgroundColor: colors.primary,
    },
    saveTxt: {
      fontSize: 15,
      fontWeight: "700" as const,
      color: "#FFFFFF",
    },
  });

  return (
    <Modal
      visible={visible}
      transparent
      animationType="slide"
      onRequestClose={handleCancel}
    >
      <View style={s.overlay}>
        <View style={s.sheet}>
          <View style={s.handle} />

          {/* Header */}
          <View style={s.header}>
            <Text style={s.headerTitle}>{t("notifSheet.title")}</Text>
            <TouchableOpacity style={s.closeBtn} onPress={handleCancel}>
              <Feather name="x" size={16} color={colors.mutedForeground} />
            </TouchableOpacity>
          </View>

          <ScrollView
            style={s.body}
            showsVerticalScrollIndicator={false}
            keyboardShouldPersistTaps="handled"
          >
            {/* Kart Son Ödeme */}
            <View style={s.card}>
              <View style={s.row}>
                <View style={s.iconBg}>
                  <Feather name="credit-card" size={17} color={colors.primary} />
                </View>
                <View style={s.rowBody}>
                  <Text style={s.rowTitle}>{t("notifSheet.ccDueTitle")}</Text>
                  <Text style={s.rowDesc}>{t("notifSheet.ccDueDesc")}</Text>
                </View>
                <Switch
                  value={draft.ccDueReminder}
                  onValueChange={(v) => { Haptics.selectionAsync(); patch({ ccDueReminder: v }); }}
                  trackColor={{ false: colors.border, true: colors.primary }}
                  thumbColor="#FFF"
                />
              </View>
              {draft.ccDueReminder && (
                <>
                  <View style={s.divider} />
                  <View style={s.subRow}>
                    <View style={s.rowBody}>
                      <Text style={[s.rowDesc, { color: colors.foreground }]}>{t("notifSheet.whenQuestion")}</Text>
                    </View>
                    <TouchableOpacity
                      style={s.chipBtn}
                      onPress={() => { Haptics.selectionAsync(); patch({ ccDueDaysBefore: cycleDays(draft.ccDueDaysBefore) }); }}
                    >
                      <Text style={s.chipTxt}>{fmtDays(draft.ccDueDaysBefore)}</Text>
                      <Feather name="repeat" size={12} color={colors.primary} />
                    </TouchableOpacity>
                  </View>
                </>
              )}
            </View>

            {/* Ekstre Kesim */}
            <View style={s.card}>
              <View style={s.row}>
                <View style={s.iconBg}>
                  <Feather name="file-text" size={17} color={colors.primary} />
                </View>
                <View style={s.rowBody}>
                  <Text style={s.rowTitle}>{t("notifSheet.statementTitle")}</Text>
                  <Text style={s.rowDesc}>{t("notifSheet.statementDesc")}</Text>
                </View>
                <Switch
                  value={draft.ccStatementReminder}
                  onValueChange={(v) => { Haptics.selectionAsync(); patch({ ccStatementReminder: v }); }}
                  trackColor={{ false: colors.border, true: colors.primary }}
                  thumbColor="#FFF"
                />
              </View>
            </View>

            {/* Borç Vadesi */}
            <View style={s.card}>
              <View style={s.row}>
                <View style={s.iconBg}>
                  <Feather name="clock" size={17} color={colors.primary} />
                </View>
                <View style={s.rowBody}>
                  <Text style={s.rowTitle}>{t("notifSheet.debtDueTitle")}</Text>
                  <Text style={s.rowDesc}>{t("notifSheet.debtDueDesc")}</Text>
                </View>
                <Switch
                  value={draft.debtDueReminder}
                  onValueChange={(v) => { Haptics.selectionAsync(); patch({ debtDueReminder: v }); }}
                  trackColor={{ false: colors.border, true: colors.primary }}
                  thumbColor="#FFF"
                />
              </View>
              {draft.debtDueReminder && (
                <>
                  <View style={s.divider} />
                  <View style={s.subRow}>
                    <View style={s.rowBody}>
                      <Text style={[s.rowDesc, { color: colors.foreground }]}>{t("notifSheet.whenQuestion")}</Text>
                    </View>
                    <TouchableOpacity
                      style={s.chipBtn}
                      onPress={() => { Haptics.selectionAsync(); patch({ debtDueDaysBefore: cycleDays(draft.debtDueDaysBefore) }); }}
                    >
                      <Text style={s.chipTxt}>{fmtDays(draft.debtDueDaysBefore)}</Text>
                      <Feather name="repeat" size={12} color={colors.primary} />
                    </TouchableOpacity>
                  </View>
                </>
              )}
            </View>

            {/* Bildirim Saati */}
            <View style={s.card}>
              <View style={s.row}>
                <View style={s.iconBg}>
                  <Feather name="sun" size={17} color={colors.primary} />
                </View>
                <View style={s.rowBody}>
                  <Text style={s.rowTitle}>{t("notifSheet.reminderHourTitle")}</Text>
                  <Text style={s.rowDesc}>{t("notifSheet.reminderHourDesc")}</Text>
                </View>
                <TouchableOpacity
                  style={s.chipBtn}
                  onPress={() => { Haptics.selectionAsync(); patch({ reminderHour: cycleHour(draft.reminderHour) }); }}
                >
                  <Text style={s.chipTxt}>{fmtHour(draft.reminderHour)}</Text>
                  <Feather name="repeat" size={12} color={colors.primary} />
                </TouchableOpacity>
              </View>
            </View>

            {/* Test Bildirimi */}
            <TouchableOpacity onPress={handleTest}>
              <View style={[s.card, { marginBottom: 20 }]}>
                <View style={s.row}>
                  <View style={[s.iconBg, { backgroundColor: "#EFF6FF" }]}>
                    <Feather name="send" size={17} color="#3B82F6" />
                  </View>
                  <View style={s.rowBody}>
                    <Text style={s.rowTitle}>{t("notifSheet.testTitle")}</Text>
                    <Text style={s.rowDesc}>{t("notifSheet.testDesc")}</Text>
                  </View>
                  <Feather name="chevron-right" size={18} color={colors.mutedForeground} />
                </View>
              </View>
            </TouchableOpacity>
          </ScrollView>

          {/* Footer — İptal + Kaydet */}
          <View style={s.footer}>
            <TouchableOpacity style={s.cancelBtn} onPress={handleCancel}>
              <Text style={s.cancelTxt}>{t("common.cancel")}</Text>
            </TouchableOpacity>
            <TouchableOpacity style={s.saveBtn} onPress={handleSave}>
              <Text style={s.saveTxt}>{t("common.save")}</Text>
            </TouchableOpacity>
          </View>
        </View>
      </View>
    </Modal>
  );
}
