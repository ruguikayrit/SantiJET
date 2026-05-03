import { Feather } from "@expo/vector-icons";
import { useRouter } from "expo-router";
import React, { useEffect, useMemo, useState } from "react";
import {
  FlatList,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from "react-native";

import BottomSheet from "@/components/BottomSheet";
import CategoryPicker from "@/components/CategoryPicker";
import DatePickerInput from "@/components/DatePickerInput";
import EmptyState from "@/components/EmptyState";
import FormInput from "@/components/FormInput";
import Header from "@/components/Header";
import PrimaryButton from "@/components/PrimaryButton";
import UnitPicker from "@/components/UnitPicker";
import {
  Purchase,
  PurchasePaymentMethod,
  PurchaseStatus,
  useApp,
} from "@/context/AppContext";
import { useColors } from "@/hooks/useColors";
import { usePermission } from "@/hooks/usePermission";

const STATUS_LABEL: Record<PurchaseStatus, string> = {
  pending: "Bekliyor",
  approved: "Onaylandı",
  paid: "Ödendi",
  cancelled: "İptal",
};
const STATUS_COLOR: Record<PurchaseStatus, string> = {
  pending: "#d97706",
  approved: "#0891b2",
  paid: "#16a34a",
  cancelled: "#6b7280",
};

const PAY_LABEL: Record<PurchasePaymentMethod, string> = {
  nakit: "Nakit",
  havale: "Havale/EFT",
  "kredi-karti": "Kredi Kartı",
  cek: "Çek",
  vadeli: "Vadeli",
};

interface F {
  projectId: string;
  date: string;
  supplier: string;
  itemName: string;
  category: string;
  unit: string;
  quantity: string;
  unitPrice: string;
  vatRate: string;
  status: PurchaseStatus;
  paymentMethod: PurchasePaymentMethod;
  paidDate: string;
  invoiceNo: string;
  notes: string;
  invoiceReceived: boolean;
}

const EMPTY: F = {
  projectId: "",
  date: "",
  supplier: "",
  itemName: "",
  category: "",
  unit: "",
  quantity: "",
  unitPrice: "",
  vatRate: "20",
  status: "pending",
  paymentMethod: "havale",
  paidDate: "",
  invoiceNo: "",
  notes: "",
  invoiceReceived: false,
};

function fmtTL(n: number) {
  return n.toLocaleString("tr-TR", { minimumFractionDigits: 0, maximumFractionDigits: 2 });
}

function calcTotal(qty: number, price: number, vat: number) {
  const sub = qty * price;
  const tax = sub * (vat / 100);
  return { sub, tax, total: sub + tax };
}

export default function SatinAlmaScreen() {
  const colors = useColors();
  const router = useRouter();
  const {
    projects,
    purchases,
    addPurchase,
    updatePurchase,
    deletePurchase,
    markPurchasePaid,
    markPurchaseInvoiceReceived,
  } = useApp();

  const perm = usePermission("satin-alma");
  const canEdit = perm === "edit";
  useEffect(() => {
    if (perm === "none") {
      if (router.canGoBack()) router.back();
      else router.replace("/");
    }
  }, [perm]);

  const [filter, setFilter] = useState<string | null>(null);
  const [statusFilter, setStatusFilter] = useState<PurchaseStatus | "all">("all");
  const [materialFilter, setMaterialFilter] = useState<string | null>(null);
  const [visible, setVisible] = useState(false);
  const [editId, setEditId] = useState<string | null>(null);
  const [form, setForm] = useState<F>(EMPTY);

  const projScoped = useMemo(
    () => (filter ? purchases.filter((p) => p.projectId === filter) : purchases),
    [purchases, filter]
  );

  const materialNames = useMemo(() => {
    const set = new Set<string>();
    for (const p of projScoped) {
      const v = (p.itemName || "").trim();
      if (v) set.add(v);
    }
    return Array.from(set).sort((a, b) => a.localeCompare(b, "tr"));
  }, [projScoped]);

  useEffect(() => {
    if (materialFilter && !materialNames.includes(materialFilter)) {
      setMaterialFilter(null);
    }
  }, [materialFilter, materialNames]);

  const [searchText, setSearchText] = useState("");
  const [searchDate, setSearchDate] = useState("");
  const hasFilter = !!(searchText.trim() || searchDate.trim());
  function clearFilters() { setSearchText(""); setSearchDate(""); }

  const list = useMemo(() => {
    let arr = projScoped;
    if (statusFilter !== "all") arr = arr.filter((p) => p.status === statusFilter);
    if (materialFilter) arr = arr.filter((p) => (p.itemName || "").trim() === materialFilter);
    const q = searchText.trim().toLocaleLowerCase("tr-TR");
    if (q) {
      arr = arr.filter((p) =>
        [p.supplier, p.itemName, p.category, p.invoiceNo, p.notes, p.unit]
          .filter(Boolean).join(" ").toLocaleLowerCase("tr-TR").includes(q)
      );
    }
    const d = searchDate.trim();
    if (d) arr = arr.filter((p) => p.date === d || p.paidDate === d);
    return [...arr].sort((a, b) => (b.date || "").localeCompare(a.date || ""));
  }, [projScoped, statusFilter, materialFilter, searchText, searchDate]);

  const summary = useMemo(() => {
    let total = 0;
    let paid = 0;
    let pending = 0;
    let waitingInvoice = 0;
    for (const p of list) {
      const { total: t } = calcTotal(p.quantity || 0, p.unitPrice || 0, p.vatRate || 0);
      total += t;
      if (p.status === "paid") paid += t;
      else if (p.status === "pending" || p.status === "approved") pending += t;
      if (!p.invoiceReceived && p.status !== "cancelled") waitingInvoice += 1;
    }
    return { total, paid, pending, waitingInvoice, count: list.length };
  }, [list]);

  function open(p?: Purchase) {
    if (p) {
      setEditId(p.id);
      setForm({
        projectId: p.projectId,
        date: p.date,
        supplier: p.supplier,
        itemName: p.itemName,
        category: p.category,
        unit: p.unit,
        quantity: String(p.quantity || ""),
        unitPrice: String(p.unitPrice || ""),
        vatRate: String(p.vatRate ?? 20),
        status: p.status,
        paymentMethod: p.paymentMethod,
        paidDate: p.paidDate,
        invoiceNo: p.invoiceNo,
        notes: p.notes,
        invoiceReceived: !!p.invoiceReceived,
      });
    } else {
      setEditId(null);
      setForm({
        ...EMPTY,
        projectId: filter || projects[0]?.id || "",
        date: new Date().toISOString().slice(0, 10),
      });
    }
    setVisible(true);
  }

  function save() {
    if (!form.projectId || !form.itemName.trim() || !form.quantity || !form.unitPrice) return;
    const data: Omit<Purchase, "id"> = {
      projectId: form.projectId,
      date: form.date.trim(),
      supplier: form.supplier.trim(),
      itemName: form.itemName.trim(),
      category: form.category.trim(),
      unit: form.unit.trim(),
      quantity: parseFloat(form.quantity) || 0,
      unitPrice: parseFloat(form.unitPrice) || 0,
      vatRate: parseFloat(form.vatRate) || 0,
      status: form.status,
      paymentMethod: form.paymentMethod,
      paidDate: form.status === "paid" ? (form.paidDate || new Date().toISOString().slice(0, 10)) : "",
      invoiceNo: form.invoiceNo.trim(),
      notes: form.notes.trim(),
      invoiceReceived: form.invoiceReceived,
    };
    if (editId) updatePurchase(editId, data);
    else addPurchase(data);
    setVisible(false);
  }

  function toggleInvoice(p: Purchase) {
    markPurchaseInvoiceReceived(p.id, !p.invoiceReceived);
  }

  function remove() {
    if (editId) deletePurchase(editId);
    setVisible(false);
  }

  function quickPay(p: Purchase) {
    markPurchasePaid(p.id, new Date().toISOString().slice(0, 10));
  }

  function projectName(id: string) {
    return projects.find((p) => p.id === id)?.name || "—";
  }

  const formTotal = useMemo(
    () =>
      calcTotal(
        parseFloat(form.quantity) || 0,
        parseFloat(form.unitPrice) || 0,
        parseFloat(form.vatRate) || 0
      ),
    [form.quantity, form.unitPrice, form.vatRate]
  );

  return (
    <View style={[styles.root, { backgroundColor: colors.background }]}>
      <Header
        title="Satın Alma"
        onBack={() => (router.canGoBack() ? router.back() : router.replace("/"))}
        rightAction={canEdit && projects.length > 0 ? { icon: "plus", onPress: () => open() } : undefined}
      />


      {projects.length === 0 ? (
        <EmptyState
          icon="briefcase"
          title="Önce proje ekleyin"
          description="Satın alma kayıtları için en az bir projeniz olmalı"
          actionLabel="Projelere Git"
          onAction={() => router.push("/proje" as any)}
        />
      ) : (
        <>
          <View style={styles.summaryRow}>
            <View style={[styles.sumBox, { backgroundColor: "#16213e22" }]}>
              <Text style={[styles.sumLabel, { color: colors.foreground }]}>Toplam</Text>
              <Text style={[styles.sumNum, { color: "#16213e" }]}>{fmtTL(summary.total)} ₺</Text>
            </View>
            <View style={[styles.sumBox, { backgroundColor: STATUS_COLOR.paid + "22" }]}>
              <Text style={[styles.sumLabel, { color: colors.foreground }]}>Ödenen</Text>
              <Text style={[styles.sumNum, { color: STATUS_COLOR.paid }]}>{fmtTL(summary.paid)} ₺</Text>
            </View>
            <View style={[styles.sumBox, { backgroundColor: STATUS_COLOR.pending + "22" }]}>
              <Text style={[styles.sumLabel, { color: colors.foreground }]}>Bekleyen</Text>
              <Text style={[styles.sumNum, { color: STATUS_COLOR.pending }]}>{fmtTL(summary.pending)} ₺</Text>
            </View>
          </View>

          <View style={[styles.filterBar, { borderBottomColor: colors.border, backgroundColor: colors.card }]}>
            <View style={styles.filterRow}>
              <View style={[styles.searchBox, { backgroundColor: colors.muted, flex: 1 }]}>
                <Feather name="search" size={13} color={colors.mutedForeground} />
                <TextInput
                  value={searchText}
                  onChangeText={setSearchText}
                  placeholder="Tedarikçi, ürün, fatura no, not..."
                  placeholderTextColor={colors.mutedForeground}
                  style={[styles.searchInput, { color: colors.foreground }]}
                />
              </View>
            </View>
            <View style={styles.filterRow}>
              <View style={{ flex: 1 }}>
                <DatePickerInput value={searchDate} onChange={setSearchDate} />
              </View>
              {hasFilter ? (
                <TouchableOpacity onPress={clearFilters} style={[styles.clearBtn, { backgroundColor: colors.muted }]} activeOpacity={0.7}>
                  <Feather name="x" size={14} color={colors.foreground} />
                  <Text style={[styles.clearBtnText, { color: colors.foreground }]}>Temizle</Text>
                </TouchableOpacity>
              ) : null}
            </View>
          </View>

          <View style={styles.statusFilters}>
            {(["all", "pending", "approved", "paid", "cancelled"] as const).map((s) => {
              const active = statusFilter === s;
              const label = s === "all" ? "Tümü" : STATUS_LABEL[s as PurchaseStatus];
              const c = s === "all" ? colors.primary : STATUS_COLOR[s as PurchaseStatus];
              return (
                <TouchableOpacity
                  key={s}
                  onPress={() => setStatusFilter(s)}
                  style={[styles.statChip, { backgroundColor: active ? c : colors.muted }]}
                >
                  <Text style={[styles.statChipText, { color: active ? "#fff" : colors.foreground }]}>
                    {label}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </View>

          {materialNames.length > 0 ? (
            <ScrollView
              horizontal
              showsHorizontalScrollIndicator={false}
              contentContainerStyle={styles.matFilters}
              style={styles.matFiltersWrap}
            >
              <TouchableOpacity
                onPress={() => setMaterialFilter(null)}
                style={[
                  styles.matChip,
                  { backgroundColor: materialFilter === null ? colors.primary : colors.muted },
                ]}
              >
                <Text
                  style={[
                    styles.matChipText,
                    { color: materialFilter === null ? "#fff" : colors.foreground },
                  ]}
                >
                  Tümü ({projScoped.length})
                </Text>
              </TouchableOpacity>
              {materialNames.map((name) => {
                const count = projScoped.filter(
                  (p) => (p.itemName || "").trim() === name
                ).length;
                const active = materialFilter === name;
                return (
                  <TouchableOpacity
                    key={name}
                    onPress={() => setMaterialFilter(active ? null : name)}
                    style={[
                      styles.matChip,
                      { backgroundColor: active ? colors.primary : colors.muted },
                    ]}
                  >
                    <Text
                      style={[
                        styles.matChipText,
                        { color: active ? "#fff" : colors.foreground },
                      ]}
                      numberOfLines={1}
                    >
                      {name} ({count})
                    </Text>
                  </TouchableOpacity>
                );
              })}
            </ScrollView>
          ) : null}

          {list.length === 0 ? (
            <EmptyState
              icon="shopping-cart"
              title="Satın alma kaydı yok"
              description="Yeni alım eklemek için + düğmesine dokunun"
              actionLabel={canEdit ? "Kayıt Ekle" : undefined}
              onAction={canEdit ? () => open() : undefined}
            />
          ) : (
            <FlatList
              data={list}
              keyExtractor={(p) => p.id}
              contentContainerStyle={styles.list}
              renderItem={({ item }) => {
                const { total } = calcTotal(item.quantity, item.unitPrice, item.vatRate);
                return (
                  <TouchableOpacity
                    style={[styles.card, { backgroundColor: colors.card }]}
                    activeOpacity={0.85}
                    onPress={() => open(item)}
                  >
                    <View style={[styles.iconBox, { backgroundColor: STATUS_COLOR[item.status] + "22" }]}>
                      <Feather name="shopping-cart" size={18} color={STATUS_COLOR[item.status]} />
                    </View>
                    <View style={{ flex: 1 }}>
                      <View style={styles.headRow}>
                        <Text style={[styles.proj, { color: colors.primary }]} numberOfLines={1}>
                          {projectName(item.projectId)}
                        </Text>
                        <View style={[styles.badge, { backgroundColor: STATUS_COLOR[item.status] }]}>
                          <Text style={styles.badgeText}>{STATUS_LABEL[item.status]}</Text>
                        </View>
                      </View>
                      <Text style={[styles.title, { color: colors.foreground }]} numberOfLines={1}>
                        {item.itemName}
                      </Text>
                      {item.supplier ? (
                        <Text style={[styles.desc, { color: colors.mutedForeground }]} numberOfLines={1}>
                          {item.supplier}
                          {item.invoiceNo ? ` · F.No: ${item.invoiceNo}` : ""}
                        </Text>
                      ) : null}
                      <View style={styles.metaRow}>
                        <Text style={[styles.meta, { color: colors.mutedForeground }]}>
                          {item.quantity} {item.unit} × {fmtTL(item.unitPrice)} ₺
                        </Text>
                        {item.date ? (
                          <Text style={[styles.meta, { color: colors.mutedForeground }]}>{item.date}</Text>
                        ) : null}
                      </View>
                    </View>
                    <View style={{ alignItems: "flex-end", gap: 6 }}>
                      <Text style={[styles.amount, { color: colors.foreground }]}>{fmtTL(total)} ₺</Text>
                      {item.materialRequestId ? (
                        <View style={[styles.linkBadge, { backgroundColor: "#7c3aed22" }]}>
                          <Feather name="link" size={10} color="#7c3aed" />
                          <Text style={[styles.linkBadgeText, { color: "#7c3aed" }]}>Talepten</Text>
                        </View>
                      ) : null}
                      {item.finansTransactionId ? (
                        <TouchableOpacity
                          onPress={(e) => {
                            e.stopPropagation();
                            router.push("/finans" as any);
                          }}
                          style={[styles.linkBadge, { backgroundColor: "#0B1E3322" }]}
                        >
                          <Feather name="dollar-sign" size={10} color="#0B1E33" />
                          <Text style={[styles.linkBadgeText, { color: "#0B1E33" }]}>KasaFON</Text>
                        </TouchableOpacity>
                      ) : null}
                      {canEdit && item.status !== "cancelled" ? (
                        <TouchableOpacity
                          onPress={(e) => {
                            e.stopPropagation();
                            toggleInvoice(item);
                          }}
                          style={[
                            styles.payBtn,
                            {
                              backgroundColor: item.invoiceReceived ? "#0891b2" : colors.muted,
                            },
                          ]}
                        >
                          <Feather
                            name={item.invoiceReceived ? "check" : "file-text"}
                            size={11}
                            color={item.invoiceReceived ? "#fff" : colors.foreground}
                          />
                          <Text
                            style={[
                              styles.payBtnText,
                              { color: item.invoiceReceived ? "#fff" : colors.foreground },
                            ]}
                          >
                            {item.invoiceReceived ? "Fatura ✓" : "Fatura"}
                          </Text>
                        </TouchableOpacity>
                      ) : null}
                      {canEdit && item.status !== "paid" && item.status !== "cancelled" ? (
                        <TouchableOpacity
                          onPress={(e) => {
                            e.stopPropagation();
                            quickPay(item);
                          }}
                          style={[styles.payBtn, { backgroundColor: STATUS_COLOR.paid }]}
                        >
                          <Feather name="check" size={11} color="#fff" />
                          <Text style={styles.payBtnText}>Ödendi</Text>
                        </TouchableOpacity>
                      ) : null}
                    </View>
                  </TouchableOpacity>
                );
              }}
            />
          )}
        </>
      )}

      <BottomSheet
        visible={visible}
        onClose={() => setVisible(false)}
        title={editId ? "Alımı Düzenle" : "Yeni Satın Alma"}
      >
        <Text style={[styles.label, { color: colors.foreground }]}>Proje</Text>
        <View style={styles.chips}>
          {projects.map((p) => (
            <TouchableOpacity
              key={p.id}
              onPress={() => setForm({ ...form, projectId: p.id })}
              style={[
                styles.chip,
                { backgroundColor: form.projectId === p.id ? colors.primary : colors.muted },
              ]}
            >
              <Text
                style={[
                  styles.chipText,
                  { color: form.projectId === p.id ? "#fff" : colors.foreground },
                ]}
              >
                {p.name}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        <FormInput
          label="Ürün / Hizmet *"
          value={form.itemName}
          onChangeText={(v) => setForm({ ...form, itemName: v })}
          placeholder="Örn: 400 doz çimento"
        />
        <FormInput
          label="Tedarikçi"
          value={form.supplier}
          onChangeText={(v) => setForm({ ...form, supplier: v })}
          placeholder="Örn: ABC İnşaat Ltd."
        />
        <CategoryPicker
          label="Kategori"
          value={form.category}
          onChange={(v) => setForm({ ...form, category: v })}
        />

        <View style={{ flexDirection: "row", gap: 10 }}>
          <View style={{ flex: 1 }}>
            <FormInput
              label="Miktar *"
              value={form.quantity}
              onChangeText={(v) => setForm({ ...form, quantity: v })}
              keyboardType="numeric"
            />
          </View>
          <View style={{ flex: 1 }}>
            <UnitPicker
              label="Birim"
              value={form.unit}
              onChange={(v) => setForm({ ...form, unit: v })}
            />
          </View>
        </View>

        <View style={{ flexDirection: "row", gap: 10 }}>
          <View style={{ flex: 1 }}>
            <FormInput
              label="Birim Fiyat (₺) *"
              value={form.unitPrice}
              onChangeText={(v) => setForm({ ...form, unitPrice: v })}
              keyboardType="numeric"
            />
          </View>
          <View style={{ flex: 1 }}>
            <FormInput
              label="KDV (%)"
              value={form.vatRate}
              onChangeText={(v) => setForm({ ...form, vatRate: v })}
              keyboardType="numeric"
            />
          </View>
        </View>

        <View style={[styles.totalBox, { backgroundColor: colors.muted }]}>
          <View style={styles.totalRow}>
            <Text style={[styles.totalLabel, { color: colors.mutedForeground }]}>Ara Toplam</Text>
            <Text style={[styles.totalValue, { color: colors.foreground }]}>
              {fmtTL(formTotal.sub)} ₺
            </Text>
          </View>
          <View style={styles.totalRow}>
            <Text style={[styles.totalLabel, { color: colors.mutedForeground }]}>KDV</Text>
            <Text style={[styles.totalValue, { color: colors.foreground }]}>
              {fmtTL(formTotal.tax)} ₺
            </Text>
          </View>
          <View style={[styles.totalRow, { borderTopWidth: 1, borderTopColor: colors.border, paddingTop: 6, marginTop: 4 }]}>
            <Text style={[styles.totalLabel, { color: colors.foreground, fontFamily: "Inter_700Bold" }]}>
              Genel Toplam
            </Text>
            <Text style={[styles.totalValue, { color: colors.primary, fontFamily: "Inter_700Bold" }]}>
              {fmtTL(formTotal.total)} ₺
            </Text>
          </View>
        </View>

        <DatePickerInput
          label="Sipariş / Fatura Tarihi"
          value={form.date}
          onChange={(v) => setForm({ ...form, date: v })}
        />
        <FormInput
          label="Fatura No"
          value={form.invoiceNo}
          onChangeText={(v) => setForm({ ...form, invoiceNo: v })}
        />

        <TouchableOpacity
          onPress={() => setForm({ ...form, invoiceReceived: !form.invoiceReceived })}
          style={[
            styles.invoiceToggle,
            {
              backgroundColor: form.invoiceReceived ? "#0891b222" : colors.muted,
              borderColor: form.invoiceReceived ? "#0891b2" : colors.border,
            },
          ]}
          activeOpacity={0.7}
        >
          <View
            style={[
              styles.invoiceCheckBox,
              {
                borderColor: form.invoiceReceived ? "#0891b2" : colors.border,
                backgroundColor: form.invoiceReceived ? "#0891b2" : "transparent",
              },
            ]}
          >
            {form.invoiceReceived ? <Feather name="check" size={12} color="#fff" /> : null}
          </View>
          <View style={{ flex: 1 }}>
            <Text style={[styles.invoiceTitle, { color: colors.foreground }]}>Faturası Geldi</Text>
            <Text style={[styles.invoiceDesc, { color: colors.mutedForeground }]}>
              {form.invoiceReceived
                ? "Tedarikçiden fatura teslim alındı"
                : "Fatura henüz teslim alınmadı"}
            </Text>
          </View>
        </TouchableOpacity>

        <Text style={[styles.label, { color: colors.foreground }]}>Durum</Text>
        <View style={styles.chips}>
          {(Object.keys(STATUS_LABEL) as PurchaseStatus[]).map((s) => (
            <TouchableOpacity
              key={s}
              onPress={() =>
                setForm({
                  ...form,
                  status: s,
                  paidDate:
                    s === "paid" && !form.paidDate
                      ? new Date().toISOString().slice(0, 10)
                      : form.paidDate,
                })
              }
              style={[
                styles.chip,
                { backgroundColor: form.status === s ? STATUS_COLOR[s] : colors.muted },
              ]}
            >
              <Text
                style={[
                  styles.chipText,
                  { color: form.status === s ? "#fff" : colors.foreground },
                ]}
              >
                {STATUS_LABEL[s]}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        <Text style={[styles.label, { color: colors.foreground }]}>Ödeme Yöntemi</Text>
        <View style={styles.chips}>
          {(Object.keys(PAY_LABEL) as PurchasePaymentMethod[]).map((m) => (
            <TouchableOpacity
              key={m}
              onPress={() => setForm({ ...form, paymentMethod: m })}
              style={[
                styles.chip,
                { backgroundColor: form.paymentMethod === m ? colors.primary : colors.muted },
              ]}
            >
              <Text
                style={[
                  styles.chipText,
                  { color: form.paymentMethod === m ? "#fff" : colors.foreground },
                ]}
              >
                {PAY_LABEL[m]}
              </Text>
            </TouchableOpacity>
          ))}
        </View>

        {form.status === "paid" ? (
          <DatePickerInput
            label="Ödeme Tarihi"
            value={form.paidDate}
            onChange={(v) => setForm({ ...form, paidDate: v })}
          />
        ) : null}

        <FormInput
          label="Notlar"
          value={form.notes}
          onChangeText={(v) => setForm({ ...form, notes: v })}
          multiline
          style={{ height: 70, textAlignVertical: "top" }}
        />

        {canEdit ? <PrimaryButton label="Kaydet" onPress={save} style={{ marginTop: 8 }} /> : null}
        {canEdit && editId ? (
          <PrimaryButton label="Sil" variant="danger" onPress={remove} style={{ marginTop: 10 }} />
        ) : null}
        {!canEdit ? (
          <PrimaryButton label="Kapat" onPress={() => setVisible(false)} style={{ marginTop: 8 }} />
        ) : null}
      </BottomSheet>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  summaryRow: { flexDirection: "row", gap: 8, paddingHorizontal: 16, marginTop: 12 },
  sumBox: { flex: 1, padding: 10, borderRadius: 10, alignItems: "center" },
  sumLabel: { fontSize: 11, fontFamily: "Inter_500Medium" },
  sumNum: { fontSize: 13, fontFamily: "Inter_700Bold", marginTop: 4 },
  statusFilters: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 6,
    paddingHorizontal: 16,
    marginTop: 12,
    marginBottom: 4,
  },
  statChip: { paddingHorizontal: 12, paddingVertical: 6, borderRadius: 999 },
  statChipText: { fontSize: 12, fontFamily: "Inter_500Medium" },
  matFiltersWrap: { flexGrow: 0, flexShrink: 0 },
  matFilters: {
    paddingHorizontal: 16,
    paddingVertical: 10,
    gap: 8,
    flexDirection: "row",
    alignItems: "center",
  },
  matChip: {
    paddingHorizontal: 12,
    height: 32,
    justifyContent: "center",
    borderRadius: 999,
    maxWidth: 220,
  },
  matChipText: { fontSize: 12, fontFamily: "Inter_500Medium" },
  list: { padding: 16, gap: 10 },
  card: {
    borderRadius: 12,
    padding: 12,
    flexDirection: "row",
    alignItems: "flex-start",
    gap: 12,
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 4,
    elevation: 2,
  },
  iconBox: {
    width: 40,
    height: 40,
    borderRadius: 20,
    justifyContent: "center",
    alignItems: "center",
  },
  headRow: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", gap: 6 },
  proj: { fontSize: 11, fontFamily: "Inter_600SemiBold", flex: 1 },
  badge: { paddingHorizontal: 8, paddingVertical: 2, borderRadius: 999 },
  badgeText: { color: "#fff", fontSize: 10, fontFamily: "Inter_600SemiBold" },
  title: { fontSize: 14, fontFamily: "Inter_600SemiBold", marginTop: 3 },
  desc: { fontSize: 12, fontFamily: "Inter_400Regular", marginTop: 2 },
  metaRow: { flexDirection: "row", justifyContent: "space-between", marginTop: 4, gap: 6 },
  meta: { fontSize: 11, fontFamily: "Inter_400Regular" },
  amount: { fontSize: 14, fontFamily: "Inter_700Bold" },
  payBtn: {
    flexDirection: "row",
    alignItems: "center",
    gap: 4,
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 999,
  },
  payBtnText: { color: "#fff", fontSize: 11, fontFamily: "Inter_600SemiBold" },
  linkBadge: {
    flexDirection: "row",
    alignItems: "center",
    gap: 3,
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 999,
  },
  linkBadgeText: { fontSize: 10, fontFamily: "Inter_600SemiBold" },
  invoiceToggle: {
    flexDirection: "row",
    alignItems: "center",
    gap: 12,
    padding: 12,
    borderRadius: 10,
    borderWidth: 1,
    marginBottom: 14,
  },
  invoiceCheckBox: {
    width: 22,
    height: 22,
    borderRadius: 6,
    borderWidth: 2,
    justifyContent: "center",
    alignItems: "center",
  },
  invoiceTitle: { fontSize: 14, fontFamily: "Inter_600SemiBold" },
  invoiceDesc: { fontSize: 11, fontFamily: "Inter_400Regular", marginTop: 2 },
  label: { fontSize: 14, fontFamily: "Inter_600SemiBold", marginBottom: 8, marginTop: 4 },
  chips: { flexDirection: "row", flexWrap: "wrap", gap: 8, marginBottom: 14 },
  chip: { paddingHorizontal: 14, paddingVertical: 8, borderRadius: 999 },
  chipText: { fontSize: 13, fontFamily: "Inter_500Medium" },
  totalBox: { padding: 12, borderRadius: 10, marginBottom: 12, gap: 4 },
  totalRow: { flexDirection: "row", justifyContent: "space-between" },
  totalLabel: { fontSize: 13, fontFamily: "Inter_500Medium" },
  totalValue: { fontSize: 14, fontFamily: "Inter_600SemiBold" },
  filterBar: { paddingHorizontal: 12, paddingVertical: 10, gap: 8, borderBottomWidth: StyleSheet.hairlineWidth },
  filterRow: { flexDirection: "row", gap: 8, alignItems: "center" },
  searchBox: { flexDirection: "row", alignItems: "center", gap: 6, paddingHorizontal: 10, paddingVertical: 8, borderRadius: 8, minHeight: 38 },
  searchInput: { flex: 1, fontSize: 13, fontFamily: "Inter_500Medium", padding: 0 },
  clearBtn: { flexDirection: "row", alignItems: "center", gap: 4, paddingHorizontal: 10, paddingVertical: 8, borderRadius: 8 },
  clearBtnText: { fontSize: 12, fontFamily: "Inter_600SemiBold" },
});
