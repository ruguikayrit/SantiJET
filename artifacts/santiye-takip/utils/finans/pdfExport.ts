import * as Print from "expo-print";
import * as Sharing from "expo-sharing";
import { Platform } from "react-native";

import { AssetEntry, BankLimit, Debt, Transaction } from "@/context/finans/BudgetContext";
import { formatCurrency } from "@/utils/finans/format";

function fmt(n: number) {
  return formatCurrency(n);
}

function fmtDate(iso: string) {
  try {
    const d = new Date(iso);
    return d.toLocaleDateString("tr-TR", {
      day: "2-digit",
      month: "2-digit",
      year: "numeric",
    });
  } catch {
    return iso;
  }
}

const TR_MONTHS = [
  "Ocak","Şubat","Mart","Nisan","Mayıs","Haziran",
  "Temmuz","Ağustos","Eylül","Ekim","Kasım","Aralık",
];

const ASSET_TYPE_LABELS: Record<string, string> = {
  vadesiz: "Vadesiz Hesap",
  vadeli:  "Vadeli / Mevduat",
  kripto:  "Kripto Para",
  borsa:   "Hisse Senedi (BIST)",
  doviz:   "Döviz",
  altin:   "Altın",
};

function buildHtml(
  transactions: Transaction[],
  debts: Debt[],
  bankLimits: BankLimit[],
  assetEntries: AssetEntry[]
): string {
  const nowDate = new Date();
  const now = nowDate.toLocaleDateString("tr-TR", {
    day: "2-digit",
    month: "long",
    year: "numeric",
  });
  const monthYear = nowDate.toLocaleDateString("tr-TR", {
    month: "long",
    year: "numeric",
  });

  // ── Gelir / Gider ────────────────────────────────────────────────────────
  const totalIncome = transactions
    .filter((t) => t.type === "income")
    .reduce((s, t) => s + t.amount, 0);

  const totalExpense = transactions
    .filter((t) => t.type === "expense")
    .reduce((s, t) => s + t.amount, 0);

  const balance = totalIncome - totalExpense;

  // ── Borçlar ──────────────────────────────────────────────────────────────
  const totalDebt    = debts.reduce((s, d) => s + d.amount, 0);
  const totalDebtPaid = debts.reduce((s, d) => s + d.paidAmount, 0);

  // BankLimit kaynaklı borç satırları
  type BLDebtRow = {
    name: string; creditor: string; category: string;
    amount: number; paidAmount: number;
  };

  const blDebtRows: BLDebtRow[] = bankLimits
    .filter((bl) => bl.type === "credit" || bl.type === "overdraft")
    .map((bl) => {
      const hasAvail = bl.availableLimit !== undefined;
      const used = hasAvail ? Math.max(0, bl.limit - (bl.availableLimit ?? 0)) : 0;
      return {
        name:      bl.institution || bl.bank,
        creditor:  bl.bank,
        category:  bl.type === "credit" ? "Kredi Kartı" : "Ek Hesap",
        amount:    used,
        paidAmount: 0,
      };
    })
    .filter((r) => r.amount > 0);

  type DebtRowItem = {
    name: string; creditor: string; category: string;
    amount: number; paidAmount: number;
  };

  const allDebtItems: DebtRowItem[] = [
    ...debts.map((d) => ({
      name:       d.name,
      creditor:   d.creditor || "—",
      category:   d.category,
      amount:     d.amount,
      paidAmount: d.paidAmount,
    })),
    ...blDebtRows,
  ].sort((a, b) => {
    const catCmp = a.category.localeCompare(b.category, "tr", { sensitivity: "base" });
    if (catCmp !== 0) return catCmp;
    return a.name.localeCompare(b.name, "tr", { sensitivity: "base" });
  });

  const totalAllDebt      = allDebtItems.reduce((s, d) => s + d.amount, 0);
  const totalAllPaid      = allDebtItems.reduce((s, d) => s + d.paidAmount, 0);
  const totalAllRemaining = Math.max(0, totalAllDebt - totalAllPaid);

  // ── Varlıklar ────────────────────────────────────────────────────────────
  const totalAssets = assetEntries.reduce((s, a) => s + a.amount, 0);

  // ── Öz Sermaye = Nakit Bakiye + Varlıklar − Kalan Borç ───────────────────
  const ozSermaye = balance + totalAssets - totalAllRemaining;

  // ────────────────────────────────────────────────────────────────────────
  // SATIR ÜRETEÇLERİ
  // ────────────────────────────────────────────────────────────────────────

  // İşlem satırları
  const txRows = transactions
    .slice()
    .sort((a, b) => {
      const catCmp = a.category.localeCompare(b.category, "tr", { sensitivity: "base" });
      if (catCmp !== 0) return catCmp;
      return new Date(b.date).getTime() - new Date(a.date).getTime();
    })
    .map(
      (t, i) => `
      <tr>
        <td class="row-num">${i + 1}</td>
        <td>${fmtDate(t.date)}</td>
        <td>${t.category}</td>
        <td>${t.note || "—"}</td>
        <td>${t.paymentMethod === "cash" ? "Nakit" : "Kredi Kartı"}</td>
        <td style="color:${t.type === "income" ? "#007A5E" : "#FF4D6D"};font-weight:600;text-align:right">
          ${t.type === "income" ? "+" : "-"}${fmt(t.amount)}
        </td>
      </tr>`
    )
    .join("");

  // Gelir kategorisi bazlı özet
  const incomeCatMap = new Map<string, number>();
  for (const t of transactions.filter(x => x.type === "income")) {
    incomeCatMap.set(t.category, (incomeCatMap.get(t.category) ?? 0) + t.amount);
  }
  const incomeCatRows = Array.from(incomeCatMap.entries())
    .sort(([, a], [, b]) => b - a)
    .map(([cat, amt], i) => `
      <tr>
        <td class="row-num">${i + 1}</td>
        <td><strong>${cat}</strong></td>
        <td style="text-align:right;color:#007A5E;font-weight:600">${fmt(amt)}</td>
        <td style="text-align:right">${totalIncome > 0 ? Math.round((amt / totalIncome) * 100) : 0}%</td>
      </tr>`)
    .join("");

  // Gider kategorisi bazlı özet
  const expenseCatMap = new Map<string, number>();
  for (const t of transactions.filter(x => x.type === "expense")) {
    expenseCatMap.set(t.category, (expenseCatMap.get(t.category) ?? 0) + t.amount);
  }
  const expenseCatRows = Array.from(expenseCatMap.entries())
    .sort(([, a], [, b]) => b - a)
    .map(([cat, amt], i) => `
      <tr>
        <td class="row-num">${i + 1}</td>
        <td><strong>${cat}</strong></td>
        <td style="text-align:right;color:#FF4D6D;font-weight:600">${fmt(amt)}</td>
        <td style="text-align:right">${totalExpense > 0 ? Math.round((amt / totalExpense) * 100) : 0}%</td>
      </tr>`)
    .join("");

  // Borç detay satırları
  const debtRows = allDebtItems
    .map((d, i) => {
      const remaining = Math.max(0, d.amount - d.paidAmount);
      const pct = d.amount > 0 ? Math.round((d.paidAmount / d.amount) * 100) : 0;
      return `
      <tr>
        <td class="row-num">${i + 1}</td>
        <td>${d.name}</td>
        <td>${d.creditor}</td>
        <td>${d.category}</td>
        <td style="text-align:right">${fmt(d.amount)}</td>
        <td style="text-align:right;color:#007A5E">${fmt(d.paidAmount)}</td>
        <td style="text-align:right;color:${remaining > 0 ? "#FF4D6D" : "#007A5E"};font-weight:600">
          ${fmt(remaining)}
        </td>
        <td style="text-align:right">${pct}%</td>
      </tr>`;
    })
    .join("");

  // ── Borç Özeti 1: Kategoriye göre ────────────────────────────────────────
  const categoryMap = new Map<string, { total: number; paid: number }>();
  for (const d of allDebtItems) {
    const cat = d.category || "Diğer";
    const cur = categoryMap.get(cat) ?? { total: 0, paid: 0 };
    cur.total += d.amount;
    cur.paid  += d.paidAmount;
    categoryMap.set(cat, cur);
  }
  const debtByCategoryRows = Array.from(categoryMap.entries())
    .sort(([a], [b]) => a.localeCompare(b, "tr"))
    .map(([cat, { total, paid }], i) => {
      const remaining = Math.max(0, total - paid);
      const pct = total > 0 ? Math.round((paid / total) * 100) : 0;
      return `
      <tr>
        <td class="row-num">${i + 1}</td>
        <td><strong>${cat}</strong></td>
        <td style="text-align:right">${fmt(total)}</td>
        <td style="text-align:right;color:#007A5E">${fmt(paid)}</td>
        <td style="text-align:right;color:${remaining > 0 ? "#FF4D6D" : "#007A5E"};font-weight:600">${fmt(remaining)}</td>
        <td style="text-align:right">${pct}%</td>
      </tr>`;
    })
    .join("");

  // ── Borç Özeti 2: Alacaklıya göre ────────────────────────────────────────
  const creditorMap = new Map<string, { total: number; paid: number }>();
  for (const d of allDebtItems) {
    const cred = d.creditor || "Bilinmiyor";
    const cur  = creditorMap.get(cred) ?? { total: 0, paid: 0 };
    cur.total += d.amount;
    cur.paid  += d.paidAmount;
    creditorMap.set(cred, cur);
  }
  const debtByCreditorRows = Array.from(creditorMap.entries())
    .sort(([a], [b]) => a.localeCompare(b, "tr"))
    .map(([cred, { total, paid }], i) => {
      const remaining = Math.max(0, total - paid);
      const pct = total > 0 ? Math.round((paid / total) * 100) : 0;
      return `
      <tr>
        <td class="row-num">${i + 1}</td>
        <td><strong>${cred}</strong></td>
        <td style="text-align:right">${fmt(total)}</td>
        <td style="text-align:right;color:#007A5E">${fmt(paid)}</td>
        <td style="text-align:right;color:${remaining > 0 ? "#FF4D6D" : "#007A5E"};font-weight:600">${fmt(remaining)}</td>
        <td style="text-align:right">${pct}%</td>
      </tr>`;
    })
    .join("");

  // Ortak özet tablo header/footer şablonu
  const debtSummaryTableHtml = (titleLabel: string, rows: string) => `
    <table>
      <thead>
        <tr>
          <th style="text-align:right;width:28px">#</th>
          <th>${titleLabel}</th>
          <th style="text-align:right">Toplam Borç</th>
          <th style="text-align:right">Ödenen</th>
          <th style="text-align:right">Kalan</th>
          <th style="text-align:right">%</th>
        </tr>
      </thead>
      <tbody>${rows}</tbody>
      <tfoot>
        <tr>
          <td colspan="2">GENEL TOPLAM</td>
          <td style="text-align:right">${fmt(totalAllDebt)}</td>
          <td style="text-align:right;color:#007A5E">${fmt(totalAllPaid)}</td>
          <td style="text-align:right;color:${totalAllRemaining > 0 ? "#FF4D6D" : "#007A5E"}">${fmt(totalAllRemaining)}</td>
          <td></td>
        </tr>
      </tfoot>
    </table>`;

  // ── Nakit Akışı — aylık ──────────────────────────────────────────────────
  const monthMap = new Map<string, { income: number; expense: number }>();
  for (const t of transactions) {
    const d  = new Date(t.date);
    const ym = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
    const cur = monthMap.get(ym) ?? { income: 0, expense: 0 };
    if (t.type === "income") cur.income += t.amount;
    else if (t.type === "expense") cur.expense += t.amount;
    monthMap.set(ym, cur);
  }
  const cashFlowRows = Array.from(monthMap.entries())
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([ym, { income, expense }], i) => {
      const [y, m] = ym.split("-").map(Number);
      const label  = `${TR_MONTHS[m - 1]} ${y}`;
      const net    = income - expense;
      return `
      <tr>
        <td class="row-num">${i + 1}</td>
        <td><strong>${label}</strong></td>
        <td style="text-align:right;color:#007A5E;font-weight:600">${fmt(income)}</td>
        <td style="text-align:right;color:#FF4D6D;font-weight:600">${fmt(expense)}</td>
        <td style="text-align:right;color:${net >= 0 ? "#007A5E" : "#FF4D6D"};font-weight:700">
          ${net >= 0 ? "+" : ""}${fmt(net)}
        </td>
      </tr>`;
    })
    .join("");

  // ── Banka Limitleri ──────────────────────────────────────────────────────
  const limitRows = bankLimits
    .slice()
    .sort((a, b) => {
      if (a.type !== b.type) return a.type === "credit" ? -1 : 1;
      return a.bank.localeCompare(b.bank, "tr", { sensitivity: "base" });
    })
    .map((b, i) => {
      const hasAvail = b.availableLimit !== undefined;
      const avail  = hasAvail ? (b.availableLimit ?? 0) : 0;
      const used   = hasAvail ? Math.max(0, b.limit - avail) : 0;
      const pct    = b.limit > 0 && hasAvail ? Math.round((used / b.limit) * 100) : 0;
      return `
      <tr>
        <td class="row-num">${i + 1}</td>
        <td>${b.institution ? `${b.institution}<br/><span style="color:#94A3B8;font-size:10px">${b.bank}</span>` : b.bank}</td>
        <td>${b.type === "credit" ? "Kredi Kartı" : "Ek Hesap"}</td>
        <td style="text-align:right">${fmt(b.limit)}</td>
        <td style="text-align:right;color:#FF4D6D">${hasAvail ? fmt(used) : "—"}</td>
        <td style="text-align:right;color:#007A5E;font-weight:600">${hasAvail ? fmt(avail) : "—"}</td>
        <td style="text-align:right">${hasAvail ? pct + "%" : "—"}</td>
      </tr>`;
    })
    .join("");

  // ── Varlık satırları ─────────────────────────────────────────────────────
  const assetRows = assetEntries
    .slice()
    .sort((a, b) => {
      const typeCmp = a.assetType.localeCompare(b.assetType, "tr");
      if (typeCmp !== 0) return typeCmp;
      return a.name.localeCompare(b.name, "tr");
    })
    .map((a, i) => {
      const typeLabel = ASSET_TYPE_LABELS[a.assetType] ?? a.assetType;
      const qtyStr = a.quantity != null
        ? a.quantity.toLocaleString("tr-TR", { maximumFractionDigits: 6 })
        : "—";
      const unitStr = a.unitPrice != null ? fmt(a.unitPrice) : "—";
      return `
      <tr>
        <td class="row-num">${i + 1}</td>
        <td>${a.name}</td>
        <td>${typeLabel}</td>
        <td>${a.platform || "—"}</td>
        <td style="text-align:right">${qtyStr}</td>
        <td style="text-align:right">${unitStr}</td>
        <td style="text-align:right;color:#007A5E;font-weight:600">${fmt(a.amount)}</td>
        ${a.note ? `<td>${a.note}</td>` : `<td style="color:#94A3B8">—</td>`}
      </tr>`;
    })
    .join("");

  // Varlık türü bazlı özet
  const assetTypeMap = new Map<string, number>();
  for (const a of assetEntries) {
    assetTypeMap.set(a.assetType, (assetTypeMap.get(a.assetType) ?? 0) + a.amount);
  }
  const assetTypeSummaryRows = Array.from(assetTypeMap.entries())
    .sort(([, a], [, b]) => b - a)
    .map(([type, amt], i) => `
      <tr>
        <td class="row-num">${i + 1}</td>
        <td><strong>${ASSET_TYPE_LABELS[type] ?? type}</strong></td>
        <td style="text-align:right;color:#007A5E;font-weight:600">${fmt(amt)}</td>
        <td style="text-align:right">${totalAssets > 0 ? Math.round((amt / totalAssets) * 100) : 0}%</td>
      </tr>`)
    .join("");

  // ── Yardımcı ─────────────────────────────────────────────────────────────
  const pageHeader = (title: string, subtitle: string) => `
    <div class="page-header">
      <div class="page-header-left">
        <div class="page-header-title">${title}</div>
        <div class="page-header-sub">${subtitle}</div>
      </div>
      <div class="page-header-date">${now}</div>
    </div>`;

  return `<!DOCTYPE html>
<html lang="tr">
<head>
<meta charset="UTF-8"/>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: -apple-system, Helvetica, Arial, sans-serif; font-size: 12px; color: #1E293B; background: #fff; }

  .page          { padding: 32px; page-break-after: always; break-after: page; }
  .page:last-child { page-break-after: avoid; break-after: avoid; }

  .cover-header { background: #0B1E33; color: #fff; padding: 28px 32px; border-radius: 12px; margin-bottom: 28px; }
  .cover-header h1 { font-size: 26px; font-weight: 800; margin-bottom: 4px; }
  .cover-header p  { font-size: 12px; opacity: 0.6; }

  .summary      { display: flex; gap: 12px; margin-bottom: 16px; flex-wrap: wrap; }
  .summary-card { flex: 1; min-width: 120px; border-radius: 10px; padding: 14px 16px; }
  .summary-card.income   { background: #E6FBF4; border: 1px solid #A7F3D8; }
  .summary-card.expense  { background: #FFF0F3; border: 1px solid #FECDD3; }
  .summary-card.balance  { background: #EFF6FF; border: 1px solid #BFDBFE; }
  .summary-card.debt     { background: #FFF7ED; border: 1px solid #FDE68A; }
  .summary-card.asset    { background: #F5F3FF; border: 1px solid #DDD6FE; }
  .summary-card.equity   { background: #F0FDF4; border: 1px solid #A7F3D0; }
  .card-label  { font-size: 10px; font-weight: 800; color: #64748B; margin-bottom: 2px; letter-spacing: 0.5px; text-transform: uppercase; }
  .card-period { font-size: 10px; font-weight: 600; color: #94A3B8; margin-bottom: 8px; }
  .card-value  { font-size: 17px; font-weight: 800; }
  .card-value.green  { color: #007A5E; }
  .card-value.red    { color: #FF4D6D; }
  .card-value.blue   { color: #3B82F6; }
  .card-value.orange { color: #F59E0B; }
  .card-value.purple { color: #7C3AED; }
  .card-value.teal   { color: #0D9488; }

  .page-header {
    display: flex; justify-content: space-between; align-items: flex-end;
    border-bottom: 3px solid #0B1E33; padding-bottom: 12px; margin-bottom: 20px;
  }
  .page-header-title { font-size: 20px; font-weight: 800; color: #0B1E33; }
  .page-header-sub   { font-size: 11px; color: #64748B; margin-top: 2px; }
  .page-header-date  { font-size: 10px; color: #94A3B8; }

  h2 { font-size: 14px; font-weight: 700; color: #0B1E33; margin: 20px 0 10px;
       border-bottom: 2px solid #E2E8F0; padding-bottom: 6px; }
  h2:first-of-type { margin-top: 0; }

  .section-badge {
    display: inline-block; background: #0B1E33; color: #fff;
    font-size: 9px; font-weight: 800; border-radius: 4px;
    padding: 2px 7px; margin-left: 8px; vertical-align: middle; letter-spacing: 0.5px;
  }

  table { width: 100%; border-collapse: collapse; margin-bottom: 24px; }
  th { font-size: 10px; font-weight: 700; color: #64748B; text-align: left;
       padding: 6px 8px; border-bottom: 2px solid #E2E8F0; background: #F8FAFC; }
  td { font-size: 11px; color: #334155; padding: 7px 8px;
       border-bottom: 1px solid #F1F5F9; vertical-align: middle; }
  tr:last-child td { border-bottom: none; }
  tr:nth-child(even) td { background: #FAFBFC; }
  .empty  { text-align: center; color: #94A3B8; padding: 20px; font-style: italic; }
  .footer { text-align: center; font-size: 10px; color: #94A3B8; margin-top: 24px; padding-top: 12px; border-top: 1px solid #E2E8F0; }
  .section { margin-bottom: 28px; }
  tfoot tr td { border-top: 2px solid #0B1E33; font-weight: 800; font-size: 12px; padding: 9px 8px; background: #F8FAFC; }
  .row-num { text-align: right; color: #94A3B8; font-size: 10px; font-weight: 600; width: 28px; min-width: 28px; }

  .divider { border: none; border-top: 1px dashed #E2E8F0; margin: 20px 0; }

  @media print {
    .page { page-break-after: always; break-after: page; }
    .page:last-child { page-break-after: avoid; break-after: avoid; }
  }
</style>
</head>
<body>

<!-- SAYFA 1 — Özet / Kapak -->
<div class="page">
  <div class="cover-header">
    <h1>Bütçe Raporu</h1>
    <p>Oluşturma tarihi: ${now} &nbsp;·&nbsp; Dönem: ${monthYear}</p>
  </div>

  <!-- Satır 1: Gelir / Gider / Bakiye -->
  <div class="summary">
    <div class="summary-card income">
      <div class="card-label">Toplam Gelir</div>
      <div class="card-period">${monthYear}</div>
      <div class="card-value green">${fmt(totalIncome)}</div>
    </div>
    <div class="summary-card expense">
      <div class="card-label">Toplam Gider</div>
      <div class="card-period">${monthYear}</div>
      <div class="card-value red">${fmt(totalExpense)}</div>
    </div>
    <div class="summary-card balance">
      <div class="card-label">Nakit Bakiye</div>
      <div class="card-period">Gelir − Gider</div>
      <div class="card-value blue">${balance >= 0 ? "" : "−"}${fmt(Math.abs(balance))}</div>
    </div>
  </div>

  <!-- Satır 2: Borç / Varlık / Öz Sermaye -->
  <div class="summary">
    <div class="summary-card debt">
      <div class="card-label">Kalan Borç</div>
      <div class="card-period">Tüm borçlar</div>
      <div class="card-value orange">${fmt(totalAllRemaining)}</div>
    </div>
    <div class="summary-card asset">
      <div class="card-label">Toplam Varlık</div>
      <div class="card-period">${assetEntries.length} kalem</div>
      <div class="card-value purple">${fmt(totalAssets)}</div>
    </div>
    <div class="summary-card equity">
      <div class="card-label">Öz Sermaye</div>
      <div class="card-period">Bakiye + Varlık − Borç</div>
      <div class="card-value ${ozSermaye >= 0 ? "teal" : "red"}">${ozSermaye >= 0 ? "" : "−"}${fmt(Math.abs(ozSermaye))}</div>
    </div>
  </div>

  <!-- İçerik Özet Tablosu -->
  <table style="margin-bottom:0">
    <thead>
      <tr>
        <th>Bölüm</th>
        <th style="text-align:right">Kayıt Sayısı</th>
        <th style="text-align:right">Toplam Tutar</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>Gelirler</td>
        <td style="text-align:right">${transactions.filter(t => t.type === "income").length}</td>
        <td style="text-align:right;color:#007A5E;font-weight:600">${fmt(totalIncome)}</td>
      </tr>
      <tr>
        <td>Giderler</td>
        <td style="text-align:right">${transactions.filter(t => t.type === "expense").length}</td>
        <td style="text-align:right;color:#FF4D6D;font-weight:600">${fmt(totalExpense)}</td>
      </tr>
      <tr>
        <td>Borçlar (kalan)</td>
        <td style="text-align:right">${allDebtItems.length}</td>
        <td style="text-align:right;color:#F59E0B;font-weight:600">${fmt(totalAllRemaining)}</td>
      </tr>
      <tr>
        <td>Varlıklar</td>
        <td style="text-align:right">${assetEntries.length}</td>
        <td style="text-align:right;color:#7C3AED;font-weight:600">${fmt(totalAssets)}</td>
      </tr>
      <tr>
        <td>Banka Limitleri</td>
        <td style="text-align:right">${bankLimits.length}</td>
        <td style="text-align:right;color:#64748B">—</td>
      </tr>
    </tbody>
    <tfoot>
      <tr>
        <td>ÖZ SERMAYE (Net Değer)</td>
        <td></td>
        <td style="text-align:right;color:${ozSermaye >= 0 ? "#0D9488" : "#FF4D6D"}">${ozSermaye >= 0 ? "" : "−"}${fmt(Math.abs(ozSermaye))}</td>
      </tr>
    </tfoot>
  </table>

  <div class="footer">KasaFON — otomatik oluşturuldu · ${now}</div>
</div>

<!-- SAYFA 2 — İşlemler -->
<div class="page">
  ${pageHeader("İşlemler", `${transactions.length} kayıt · ${monthYear}`)}

  <h2>Gelir Kategorileri <span class="section-badge">ÖZET</span></h2>
  ${incomeCatMap.size === 0 ? `<p class="empty">Gelir kaydı yok</p>` : `
    <table>
      <thead>
        <tr>
          <th style="text-align:right;width:28px">#</th>
          <th>Kategori</th>
          <th style="text-align:right">Tutar</th>
          <th style="text-align:right">%</th>
        </tr>
      </thead>
      <tbody>${incomeCatRows}</tbody>
      <tfoot>
        <tr>
          <td colspan="2">TOPLAM GELİR</td>
          <td style="text-align:right;color:#007A5E">${fmt(totalIncome)}</td>
          <td></td>
        </tr>
      </tfoot>
    </table>`}

  <h2>Gider Kategorileri <span class="section-badge">ÖZET</span></h2>
  ${expenseCatMap.size === 0 ? `<p class="empty">Gider kaydı yok</p>` : `
    <table>
      <thead>
        <tr>
          <th style="text-align:right;width:28px">#</th>
          <th>Kategori</th>
          <th style="text-align:right">Tutar</th>
          <th style="text-align:right">%</th>
        </tr>
      </thead>
      <tbody>${expenseCatRows}</tbody>
      <tfoot>
        <tr>
          <td colspan="2">TOPLAM GİDER</td>
          <td style="text-align:right;color:#FF4D6D">${fmt(totalExpense)}</td>
          <td></td>
        </tr>
      </tfoot>
    </table>`}

  <h2>Tüm İşlemler <span class="section-badge">DETAY</span></h2>
  ${transactions.length === 0
    ? `<p class="empty">Kayıt yok</p>`
    : `<table>
        <thead>
          <tr>
            <th style="text-align:right;width:28px">#</th>
            <th>Tarih</th>
            <th>Kategori</th>
            <th>Not</th>
            <th>Ödeme</th>
            <th style="text-align:right">Tutar</th>
          </tr>
        </thead>
        <tbody>${txRows}</tbody>
        <tfoot>
          <tr>
            <td colspan="5">TOPLAM GELİR / GİDER</td>
            <td style="text-align:right;color:#007A5E">${fmt(totalIncome)}&nbsp;/&nbsp;<span style="color:#FF4D6D">${fmt(totalExpense)}</span></td>
          </tr>
        </tfoot>
      </table>`}

  <div class="footer">KasaFON — İşlemler sayfası</div>
</div>

<!-- SAYFA 3 — Nakit Akışı -->
<div class="page">
  ${pageHeader("Nakit Akışı", `Aylık gelir ve gider özeti`)}

  ${transactions.length === 0
    ? `<p class="empty">Kayıt yok</p>`
    : `<table>
        <thead>
          <tr>
            <th style="text-align:right;width:28px">#</th>
            <th>Dönem</th>
            <th style="text-align:right">Gelir</th>
            <th style="text-align:right">Gider</th>
            <th style="text-align:right">Net</th>
          </tr>
        </thead>
        <tbody>${cashFlowRows}</tbody>
        <tfoot>
          <tr>
            <td colspan="2">TOPLAM</td>
            <td style="text-align:right;color:#007A5E">${fmt(totalIncome)}</td>
            <td style="text-align:right;color:#FF4D6D">${fmt(totalExpense)}</td>
            <td style="text-align:right;color:${balance >= 0 ? "#007A5E" : "#FF4D6D"};font-weight:700">
              ${balance >= 0 ? "+" : ""}${fmt(balance)}
            </td>
          </tr>
        </tfoot>
      </table>`}

  <div class="footer">KasaFON — Nakit Akışı sayfası</div>
</div>

<!-- SAYFA 4 — Borçlar (Özetler üstte, Detay altta) -->
<div class="page">
  ${pageHeader("Borçlar", `${allDebtItems.length} kayıt · ${monthYear}`)}

  ${allDebtItems.length === 0 ? `<p class="empty">Borç kaydı yok</p>` : `

  <h2>Kategoriye Göre Borç Özeti <span class="section-badge">ÖZET</span></h2>
  ${debtSummaryTableHtml("Kategori", debtByCategoryRows)}

  <h2>Alacaklıya Göre Borç Özeti <span class="section-badge">ÖZET</span></h2>
  ${debtSummaryTableHtml("Alacaklı", debtByCreditorRows)}

  <h2>Tüm Borçlar <span class="section-badge">DETAY</span></h2>
  <table>
    <thead>
      <tr>
        <th style="text-align:right;width:28px">#</th>
        <th>Borç Adı</th>
        <th>Alacaklı</th>
        <th>Kategori</th>
        <th style="text-align:right">Toplam</th>
        <th style="text-align:right">Ödenen</th>
        <th style="text-align:right">Kalan</th>
        <th style="text-align:right">%</th>
      </tr>
    </thead>
    <tbody>${debtRows}</tbody>
    <tfoot>
      <tr>
        <td colspan="4">TOPLAM</td>
        <td style="text-align:right">${fmt(totalAllDebt)}</td>
        <td style="text-align:right;color:#007A5E">${fmt(totalAllPaid)}</td>
        <td style="text-align:right;color:${totalAllRemaining > 0 ? "#FF4D6D" : "#007A5E"}">${fmt(totalAllRemaining)}</td>
        <td></td>
      </tr>
    </tfoot>
  </table>
  `}

  <div class="footer">KasaFON — Borçlar sayfası</div>
</div>

<!-- SAYFA 5 — Varlıklar -->
<div class="page">
  ${pageHeader("Varlıklar", `${assetEntries.length} kalem · Toplam ${fmt(totalAssets)}`)}

  ${assetEntries.length === 0 ? `<p class="empty">Varlık kaydı yok</p>` : `

  <h2>Varlık Türü Özeti <span class="section-badge">ÖZET</span></h2>
  <table>
    <thead>
      <tr>
        <th style="text-align:right;width:28px">#</th>
        <th>Tür</th>
        <th style="text-align:right">Tutar</th>
        <th style="text-align:right">%</th>
      </tr>
    </thead>
    <tbody>${assetTypeSummaryRows}</tbody>
    <tfoot>
      <tr>
        <td colspan="2">TOPLAM VARLIK</td>
        <td style="text-align:right;color:#7C3AED;font-weight:700">${fmt(totalAssets)}</td>
        <td></td>
      </tr>
    </tfoot>
  </table>

  <h2>Tüm Varlıklar <span class="section-badge">DETAY</span></h2>
  <table>
    <thead>
      <tr>
        <th style="text-align:right;width:28px">#</th>
        <th>Ad / Sembol</th>
        <th>Tür</th>
        <th>Platform</th>
        <th style="text-align:right">Miktar</th>
        <th style="text-align:right">Birim Fiyat</th>
        <th style="text-align:right">Toplam Değer</th>
        <th>Not</th>
      </tr>
    </thead>
    <tbody>${assetRows}</tbody>
    <tfoot>
      <tr>
        <td colspan="6">TOPLAM VARLIK DEĞERİ</td>
        <td style="text-align:right;color:#7C3AED;font-weight:700">${fmt(totalAssets)}</td>
        <td></td>
      </tr>
    </tfoot>
  </table>
  `}

  <div class="footer">KasaFON — Varlıklar sayfası</div>
</div>

<!-- SAYFA 6 — Banka Limitleri -->
<div class="page">
  ${pageHeader("Banka Limitleri", `${bankLimits.length} kayıt — Kredi Kartı ve Ek Hesap`)}

  ${bankLimits.length === 0
    ? `<p class="empty">Kayıt yok</p>`
    : `<table>
        <thead>
          <tr>
            <th style="text-align:right;width:28px">#</th>
            <th>Banka / Kurum</th>
            <th>Tür</th>
            <th style="text-align:right">Limit</th>
            <th style="text-align:right">Kullanılan</th>
            <th style="text-align:right">Kalan</th>
            <th style="text-align:right">%</th>
          </tr>
        </thead>
        <tbody>${limitRows}</tbody>
      </table>`}

  <!-- Öz Sermaye Özeti (son sayfa altı) -->
  <div style="background:#F0FDF4;border:1px solid #A7F3D0;border-radius:10px;padding:18px 20px;margin-top:8px">
    <div style="font-size:10px;font-weight:800;color:#0D9488;letter-spacing:0.5px;margin-bottom:10px;text-transform:uppercase">Net Değer Özeti (Öz Sermaye)</div>
    <table style="margin-bottom:0">
      <tbody>
        <tr>
          <td style="color:#64748B;font-size:11px">Nakit Bakiye (Gelir − Gider)</td>
          <td style="text-align:right;font-weight:700;color:${balance >= 0 ? "#007A5E" : "#FF4D6D"}">${balance >= 0 ? "+" : "−"}${fmt(Math.abs(balance))}</td>
        </tr>
        <tr>
          <td style="color:#64748B;font-size:11px">Toplam Varlık</td>
          <td style="text-align:right;font-weight:700;color:#7C3AED">+${fmt(totalAssets)}</td>
        </tr>
        <tr>
          <td style="color:#64748B;font-size:11px">Kalan Borç</td>
          <td style="text-align:right;font-weight:700;color:#FF4D6D">−${fmt(totalAllRemaining)}</td>
        </tr>
        <tr style="border-top:2px solid #0D9488">
          <td style="font-weight:800;font-size:13px;color:#0B1E33;padding-top:10px">ÖZ SERMAYE</td>
          <td style="text-align:right;font-weight:800;font-size:16px;color:${ozSermaye >= 0 ? "#0D9488" : "#FF4D6D"};padding-top:10px">
            ${ozSermaye >= 0 ? "" : "−"}${fmt(Math.abs(ozSermaye))}
          </td>
        </tr>
      </tbody>
    </table>
  </div>

  <div class="footer">KasaFON — Banka Limitleri sayfası</div>
</div>

</body>
</html>`;
}

export async function exportAsPdf(
  transactions: Transaction[],
  debts: Debt[],
  bankLimits: BankLimit[],
  assetEntries: AssetEntry[]
): Promise<void> {
  const html = buildHtml(transactions, debts, bankLimits, assetEntries);

  if (Platform.OS === "web") {
    const blob = new Blob([html], { type: "text/html" });
    const url  = URL.createObjectURL(blob);
    const a    = document.createElement("a");
    a.href     = url;
    a.download = "kasafon-raporu.html"; 
    a.click();
    URL.revokeObjectURL(url);
    return;
  }

  const { uri } = await Print.printToFileAsync({ html, base64: false });
  const canShare = await Sharing.isAvailableAsync();
  if (canShare) {
    await Sharing.shareAsync(uri, {
      mimeType:    "application/pdf",
      dialogTitle: "Bütçe Raporunu Paylaş",
      UTI:         "com.adobe.pdf",
    });
  }
}
