import * as FileSystem from "expo-file-system/legacy";
import * as Sharing from "expo-sharing";
import { zipSync } from "fflate";
import { Alert, InteractionManager, Platform, Share } from "react-native";

import { APP_LEGAL_NAME } from "@/constants/appInfo";
import { PozAnaliz, hesaplaAnalizToplam } from "@/constants/pozAnalizleri";

export type AnalizExportFormat = "pdf" | "excel";
export type PdfPaperOrientation = "landscape" | "portrait";

/** Tüm PDF dışa aktarmalar dikey A4 kullanır */
export const PDF_PAPER_ORIENTATION: PdfPaperOrientation = "portrait";

export interface AnalizExportOptions {
  pdfOrientation?: PdfPaperOrientation;
}

function resolvePdfOrientation(_orientation?: PdfPaperOrientation): PdfPaperOrientation {
  return PDF_PAPER_ORIENTATION;
}

const TIP_LABEL: Record<"malzeme" | "iscilik" | "ekipman", string> = {
  malzeme: "Malzeme Kalemleri",
  iscilik: "İşçilik Kalemleri",
  ekipman: "Ekipman Kalemleri",
};

const TIP_ACCENT: Record<"malzeme" | "iscilik" | "ekipman", string> = {
  malzeme: "#e85d04",
  iscilik: "#16213e",
  ekipman: "#0f766e",
};

/** PDF/print motorlarında renk ve dolgu kaybını önlemek için satır içi stiller */
const PDF_CELL = {
  headerBrand:
    "background-color:#16213e;color:#ffffff;padding:8px 12px;border:none;font-size:10px;letter-spacing:0.08em;text-transform:uppercase;",
  headerTitle:
    "background-color:#16213e;color:#ffffff;padding:2px 12px 6px;border:none;font-size:18px;font-weight:700;",
  headerDateLabel:
    "background-color:#16213e;color:#ffffff;padding:8px 12px;border:none;font-size:9px;font-weight:700;width:120px;text-transform:uppercase;",
  headerDateValue:
    "background-color:#16213e;color:#ffffff;padding:8px 12px;border:none;font-size:10px;",
  infoLabel:
    "padding:10px 12px;background-color:#f1f5f9;color:#64748b;font-size:9px;font-weight:700;border:1px solid #e2e8f0;text-transform:uppercase;width:22%;",
  infoValue:
    "padding:10px 12px;font-size:12px;font-weight:600;color:#0f172a;border:1px solid #e2e8f0;background-color:#ffffff;",
  th: "background-color:#16213e;color:#ffffff;padding:7px 6px;font-size:9px;font-weight:700;border:none;text-transform:uppercase;",
  td: "padding:6px;border-bottom:1px solid #e2e8f0;font-size:10px;vertical-align:top;background-color:#ffffff;",
  tdAlt: "padding:6px;border-bottom:1px solid #e2e8f0;font-size:10px;vertical-align:top;background-color:#f8fafc;",
  poz: "padding:6px;border-bottom:1px solid #e2e8f0;font-size:10px;vertical-align:top;font-weight:600;color:#1d4ed8;",
  sectionTitle: (accent: string) =>
    `padding:4px 0 4px 10px;border:none;border-left:4px solid ${accent};font-size:12px;font-weight:700;color:#0f172a;background-color:#ffffff;`,
  sectionBadge:
    "padding:4px 0;border:none;text-align:right;font-size:9px;font-weight:600;color:#475569;background-color:#ffffff;",
  costTitle:
    "padding:8px 12px;background-color:#f1f5f9;font-weight:700;border:1px solid #cbd5e1;border-bottom:1px solid #e2e8f0;",
  costLabel:
    "padding:8px 12px;color:#334155;border:1px solid #cbd5e1;border-top:none;background-color:#ffffff;",
  costValue:
    "padding:8px 12px;text-align:right;font-weight:600;color:#0f172a;border:1px solid #cbd5e1;border-top:none;background-color:#ffffff;",
  costTotal:
    "padding:10px 12px;background-color:#16213e;color:#ffffff;font-weight:700;border:1px solid #16213e;",
  notesHeading:
    "padding:0 0 4px;border:none;border-bottom:2px solid #e85d04;font-size:11px;font-weight:700;color:#16213e;background-color:#ffffff;",
  notesBody:
    "padding:10px 12px 0;border:none;font-size:10px;color:#334155;line-height:1.55;white-space:pre-wrap;background-color:#f8fafc;",
} as const;

const PDF_PRINT_COLOR_FIX = `
  html, body, table, tr, td, th {
    -webkit-print-color-adjust: exact !important;
    print-color-adjust: exact !important;
  }
`;

const SANTIJET_REPORT_STYLES = `
  body {
    font-family: "Segoe UI", Arial, sans-serif;
    font-size: 11px;
    color: #1e293b;
    margin: 0;
    line-height: 1.45;
  }
  .report { max-width: 100%; }
  .report-header {
    width: 100%;
    border-collapse: collapse;
    margin-bottom: 14px;
    background: #16213e;
    color: #fff;
  }
  .report-header td {
    padding: 8px 12px;
    border: none;
    vertical-align: middle;
  }
  .report-brand {
    font-size: 10px;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    opacity: 0.82;
    padding-bottom: 2px;
  }
  .report-title {
    font-size: 18px;
    font-weight: 700;
    padding-top: 0;
    padding-bottom: 4px;
  }
  .report-date-label {
    font-size: 9px;
    font-weight: 700;
    letter-spacing: 0.04em;
    text-transform: uppercase;
    opacity: 0.82;
    width: 120px;
  }
  .report-date {
    font-size: 10px;
    opacity: 0.95;
  }
  .info-grid {
    width: 100%;
    border-collapse: collapse;
    margin-bottom: 16px;
    border: 1px solid #dbe3ef;
    background: #f8fafc;
  }
  .info-grid td {
    padding: 10px 12px;
    vertical-align: top;
    border: 1px solid #e2e8f0;
  }
  .info-label {
    width: 22%;
    font-size: 9px;
    font-weight: 700;
    letter-spacing: 0.04em;
    text-transform: uppercase;
    color: #64748b;
    background: #f1f5f9;
  }
  .info-value {
    font-size: 12px;
    font-weight: 600;
    color: #0f172a;
  }
  .kalem-section { margin-bottom: 14px; }
  .section-head {
    width: 100%;
    border-collapse: collapse;
    margin-bottom: 6px;
  }
  .section-head td {
    padding: 4px 0;
    border: none;
    vertical-align: middle;
  }
  .section-title {
    font-size: 12px;
    font-weight: 700;
    color: #0f172a;
    padding-left: 10px;
    border-left: 4px solid #e85d04;
  }
  .section-title.iscilik { border-left-color: #16213e; }
  .section-title.ekipman { border-left-color: #0f766e; }
  .section-badge {
    width: 90px;
    text-align: right;
    font-size: 9px;
    font-weight: 600;
    color: #475569;
    white-space: nowrap;
  }
  .data-table {
    width: 100%;
    border-collapse: collapse;
    table-layout: fixed;
    margin-bottom: 2px;
  }
  .data-table th {
    background: #16213e;
    color: #fff;
    font-size: 9px;
    font-weight: 700;
    letter-spacing: 0.03em;
    text-transform: uppercase;
    padding: 7px 6px;
    border: none;
    text-align: left;
  }
  .data-table th.num { text-align: right; }
  .data-table th.center { text-align: center; }
  .data-table td {
    padding: 6px;
    border-bottom: 1px solid #e2e8f0;
    vertical-align: top;
    font-size: 10px;
  }
  .data-table tr:nth-child(even) td { background: #f8fafc; }
  .data-table tr:last-child td { border-bottom: none; }
  .desc { text-align: left; white-space: normal; word-wrap: break-word; }
  .center { text-align: center; }
  .num { text-align: right; white-space: nowrap; }
  .idx { color: #64748b; font-weight: 600; }
  .poz { mso-number-format:"\\@"; font-weight: 600; color: #1d4ed8; }
  .qty { mso-number-format:"0.0000"; }
  .price { mso-number-format:"\\"₺\\"#,##0.00"; }
  .tl { mso-number-format:"\\"₺\\"#,##0.00"; }
  .text { mso-number-format:"\\@"; }
  .cost-summary {
    width: 100%;
    border-collapse: collapse;
    margin: 18px 0 14px;
    border: 1px solid #cbd5e1;
    background: #fff;
  }
  .cost-summary td {
    padding: 8px 12px;
    border-bottom: 1px solid #eef2f7;
    font-size: 11px;
  }
  .cost-summary-title {
    background: #f1f5f9;
    font-size: 11px;
    font-weight: 700;
    color: #0f172a;
    border-bottom: 1px solid #e2e8f0;
  }
  .cost-label { color: #334155; width: 70%; }
  .cost-value { text-align: right; font-weight: 600; color: #0f172a; }
  .cost-total td {
    background: #16213e;
    color: #fff;
    font-size: 12px;
    font-weight: 700;
    padding: 10px 12px;
    border-bottom: none;
  }
  .cost-total .cost-value { color: #fff; }
  .notes-section { margin-top: 16px; width: 100%; }
  .notes-block {
    width: 100%;
    border-collapse: collapse;
    margin-bottom: 12px;
  }
  .notes-block td {
    padding: 0;
    border: none;
    vertical-align: top;
  }
  .notes-heading {
    font-size: 11px;
    font-weight: 700;
    color: #16213e;
    padding-bottom: 4px;
    border-bottom: 2px solid #e85d04;
  }
  .notes-body {
    padding: 10px 12px 0;
    white-space: pre-wrap;
    font-size: 10px;
    color: #334155;
    line-height: 1.55;
  }
  .report-footer {
    width: 100%;
    border-collapse: collapse;
    margin-top: 18px;
    border-top: 1px solid #e2e8f0;
  }
  .report-footer td {
    padding-top: 10px;
    font-size: 9px;
    color: #94a3b8;
    text-align: center;
    line-height: 1.5;
    border: none;
  }
`;

function reportOrientationStyles(orientation: PdfPaperOrientation): string {
  if (orientation === "portrait") {
    return `
  body { font-size: 9px; }
  .report-title { font-size: 15px; }
  .data-table th, .data-table td { font-size: 8px; padding: 5px 4px; }
  .info-value { font-size: 10px; }`;
  }
  return "";
}

function buildPdfExportStyles(orientation: PdfPaperOrientation = PDF_PAPER_ORIENTATION): string {
  const pageSize = orientation === "landscape" ? "A4 landscape" : "A4 portrait";
  const contentWidth = orientation === "landscape" ? "297mm" : "210mm";
  return `
  @page {
    size: ${pageSize};
    margin: 0;
  }
  ${PDF_PRINT_COLOR_FIX}
  ${SANTIJET_REPORT_STYLES}
  ${reportOrientationStyles(orientation)}
  .pdf-content {
    margin: 0 auto;
    width: 100%;
    max-width: ${contentWidth};
    box-sizing: border-box;
    padding: 8mm 10mm;
    background-color: #ffffff;
  }
  @media print {
    ${PDF_PRINT_COLOR_FIX}
    .pdf-content {
      max-width: none;
      padding: 8mm 10mm;
    }
  }`;
}

const EXCEL_STYLES = SANTIJET_REPORT_STYLES;

function trFmt(n: number): string {
  return n.toLocaleString("tr-TR", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function trQty(n: number): string {
  return n.toLocaleString("tr-TR", { minimumFractionDigits: 4, maximumFractionDigits: 4 });
}

function trCurrency(n: number): string {
  return `₺${trFmt(n)}`;
}

function safeFilename(pozNo: string): string {
  return pozNo.replace(/[^a-zA-Z0-9_-]+/g, "_").slice(0, 40) || "analiz";
}

function escHtml(text: string): string {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

/** Resmi poz numarası: XX.XXX.XXXX */
function formatResmiPozNo(pozNo: string): string {
  const trimmed = pozNo.trim();
  if (/^\d{2}\.\d{3}\.\d{4}$/.test(trimmed)) return trimmed;

  const digits = trimmed.replace(/\D/g, "");
  if (digits.length === 9) {
    return `${digits.slice(0, 2)}.${digits.slice(2, 5)}.${digits.slice(5, 9)}`;
  }

  return trimmed;
}

function excelTextCell(value: string, className = "info-value text"): string {
  return `<td class="${className}" style="mso-number-format:'\\@';">${escHtml(value)}</td>`;
}

function excelInfoPozCell(pozNo: string): string {
  const formatted = formatResmiPozNo(pozNo);
  if (/^\d{2}\.\d{3}\.\d{4}$/.test(formatted)) {
    return `<td class="info-value poz" style="mso-number-format:'\\@';">="${formatted}"</td>`;
  }
  return excelTextCell(formatted, "info-value poz");
}

function excelPozNoCell(pozNo: string): string {
  const formatted = formatResmiPozNo(pozNo);
  if (/^\d{2}\.\d{3}\.\d{4}$/.test(formatted)) {
    return `<td class="poz" style="mso-number-format:'\\@';">="${formatted}"</td>`;
  }
  return `<td class="poz" style="mso-number-format:'\\@';">${escHtml(formatted)}</td>`;
}

function excelNumberCell(value: number, className: "qty" | "price"): string {
  const numericValue = Number.isFinite(value) ? value : 0;
  return `<td class="${className}" x:num="${numericValue}">${numericValue}</td>`;
}

function excelTlCell(value: number): string {
  const numericValue = Number.isFinite(value) ? value : 0;
  return `<td class="tl" x:num="${numericValue}">${numericValue}</td>`;
}

function pdfPozNoCell(pozNo: string, zebra: "td" | "tdAlt" = "td"): string {
  const base = PDF_CELL[zebra];
  return `<td style="${base}font-weight:600;color:#1d4ed8;">${escHtml(formatResmiPozNo(pozNo))}</td>`;
}

function pdfDataCell(
  content: string,
  zebra: "td" | "tdAlt",
  extra = "",
  className = "",
): string {
  return `<td class="${className}" style="${PDF_CELL[zebra]}${extra}">${content}</td>`;
}

function pdfNumberCell(value: number, className: "qty" | "price", zebra: "td" | "tdAlt"): string {
  const align = "text-align:right;white-space:nowrap;";
  return pdfDataCell(
    className === "qty" ? trQty(value) : trCurrency(value),
    zebra,
    align,
    className,
  );
}

function pdfTlCell(value: number, zebra: "td" | "tdAlt"): string {
  return pdfDataCell(trCurrency(value), zebra, "text-align:right;white-space:nowrap;", "tl");
}

function buildKalemSection(
  analiz: PozAnaliz,
  tip: "malzeme" | "iscilik" | "ekipman",
  target: "excel" | "pdf",
): string {
  const rows = analiz.kalemler.filter((k) => k.tip === tip);
  if (!rows.length) return "";

  let tableRows = "";
  rows.forEach((k, index) => {
    const zebra: "td" | "tdAlt" = index % 2 === 1 ? "tdAlt" : "td";
    if (target === "excel") {
      tableRows += `<tr>
        <td class="center idx">${index + 1}</td>
        ${excelPozNoCell(k.pozNo)}
        <td class="desc text">${escHtml(k.tanim)}</td>
        <td class="center text">${escHtml(k.olcuBirimi)}</td>
        ${excelNumberCell(k.miktar, "qty")}
        ${excelNumberCell(k.birimFiyati, "price")}
        ${excelTlCell(k.tutar)}
      </tr>`;
      return;
    }

    tableRows += `<tr>
      ${pdfDataCell(String(index + 1), zebra, "text-align:center;color:#64748b;font-weight:600;", "idx")}
      ${pdfPozNoCell(k.pozNo, zebra)}
      ${pdfDataCell(escHtml(k.tanim), zebra, "text-align:left;white-space:normal;word-wrap:break-word;", "desc")}
      ${pdfDataCell(escHtml(k.olcuBirimi), zebra, "text-align:center;", "text")}
      ${pdfNumberCell(k.miktar, "qty", zebra)}
      ${pdfNumberCell(k.birimFiyati, "price", zebra)}
      ${pdfTlCell(k.tutar, zebra)}
    </tr>`;
  });

  const badge = `${rows.length} kalem`;
  const tipClass = tip === "malzeme" ? "" : tip;
  const sectionHead =
    target === "excel"
      ? `<table class="section-head">
      <tr>
        <td class="section-title ${tipClass}" style="border-left-color:${TIP_ACCENT[tip]}">${TIP_LABEL[tip]}</td>
        <td class="section-badge">${badge}</td>
      </tr>
    </table>`
      : `<table class="section-head" cellpadding="0" cellspacing="0" style="width:100%;border-collapse:collapse;margin-bottom:6px;">
      <tr>
        <td class="section-title ${tipClass}" style="${PDF_CELL.sectionTitle(TIP_ACCENT[tip])}">${TIP_LABEL[tip]}</td>
        <td class="section-badge" style="${PDF_CELL.sectionBadge}">${badge}</td>
      </tr>
    </table>`;

  const tableHead =
    target === "excel"
      ? `<thead>
        <tr>
          <th class="center">#</th>
          <th>Poz No</th>
          <th>Açıklama</th>
          <th class="center">Birim</th>
          <th class="num">Miktar</th>
          <th class="num">Birim Fiyat</th>
          <th class="num">Tutar</th>
        </tr>
      </thead>`
      : `<thead>
        <tr>
          <th style="${PDF_CELL.th}text-align:center;">#</th>
          <th style="${PDF_CELL.th}">Poz No</th>
          <th style="${PDF_CELL.th}">Açıklama</th>
          <th style="${PDF_CELL.th}text-align:center;">Birim</th>
          <th style="${PDF_CELL.th}text-align:right;">Miktar</th>
          <th style="${PDF_CELL.th}text-align:right;">Birim Fiyat</th>
          <th style="${PDF_CELL.th}text-align:right;">Tutar</th>
        </tr>
      </thead>`;

  return `
  <section class="kalem-section">
    ${sectionHead}
    <table class="data-table" cellpadding="0" cellspacing="0"${target === "pdf" ? ' style="width:100%;border-collapse:collapse;table-layout:fixed;margin-bottom:2px;"' : ""}>
      <colgroup>
        <col style="width:4%" />
        <col style="width:12%" />
        <col style="width:34%" />
        <col style="width:8%" />
        <col style="width:12%" />
        <col style="width:15%" />
        <col style="width:15%" />
      </colgroup>
      ${tableHead}
      <tbody>${tableRows}</tbody>
    </table>
  </section>`;
}

function excelCostValueCell(value: number): string {
  const numericValue = Number.isFinite(value) ? value : 0;
  return `<td class="cost-value tl" x:num="${numericValue}">${numericValue}</td>`;
}

function buildCostSummary(
  analiz: PozAnaliz,
  totals: ReturnType<typeof hesaplaAnalizToplam>,
  target: "excel" | "pdf",
): string {
  if (target === "excel") {
    const valueCell = (value: number) => excelCostValueCell(value);
    return `
  <table class="cost-summary">
    <tr>
      <td colspan="2" class="cost-summary-title">Maliyet Özeti</td>
    </tr>
    <tr>
      <td class="cost-label">Ara Toplam (Malzeme + İşçilik)</td>
      ${valueCell(totals.malzemeIscilikToplami)}
    </tr>
    <tr>
      <td class="cost-label">Yüklenici Karı (%${analiz.yukleniciKarOrani})</td>
      ${valueCell(totals.yukleniciKarTutari)}
    </tr>
    <tr class="cost-total">
      <td class="cost-label">Birim Fiyat (1 ${escHtml(analiz.olcuBirimi)})</td>
      ${valueCell(totals.birimFiyati)}
    </tr>
  </table>`;
  }

  return `
  <table class="cost-summary" cellpadding="0" cellspacing="0" style="width:100%;border-collapse:collapse;margin:18px 0 14px;">
    <tr>
      <td colspan="2" style="${PDF_CELL.costTitle}">Maliyet Özeti</td>
    </tr>
    <tr>
      <td style="${PDF_CELL.costLabel}">Ara Toplam (Malzeme + İşçilik)</td>
      <td style="${PDF_CELL.costValue}">${trCurrency(totals.malzemeIscilikToplami)}</td>
    </tr>
    <tr>
      <td style="${PDF_CELL.costLabel}">Yüklenici Karı (%${analiz.yukleniciKarOrani})</td>
      <td style="${PDF_CELL.costValue}">${trCurrency(totals.yukleniciKarTutari)}</td>
    </tr>
    <tr>
      <td style="${PDF_CELL.costTotal}">Birim Fiyat (1 ${escHtml(analiz.olcuBirimi)})</td>
      <td style="${PDF_CELL.costTotal}text-align:right;">${trCurrency(totals.birimFiyati)}</td>
    </tr>
  </table>`;
}

function buildNotesSection(analiz: PozAnaliz, target: "excel" | "pdf"): string {
  const blocks = [
    analiz.pozTarifi ? { title: "Poz Tarifi", body: analiz.pozTarifi } : null,
    analiz.yapimSartlari ? { title: "Yapım Şartları", body: analiz.yapimSartlari } : null,
    analiz.olcusu ? { title: "Ölçü Bilgisi", body: analiz.olcusu } : null,
    analiz.notlar ? { title: "Notlar", body: analiz.notlar } : null,
  ].filter(Boolean) as { title: string; body: string }[];

  if (!blocks.length) return "";

  const items = blocks
    .map((b) => {
      if (target === "excel") {
        return `
    <table class="notes-block">
      <tr><td class="notes-heading">${escHtml(b.title)}</td></tr>
      <tr><td class="notes-body">${escHtml(b.body)}</td></tr>
    </table>`;
      }
      return `
    <table class="notes-block" cellpadding="0" cellspacing="0" style="width:100%;border-collapse:collapse;margin-bottom:12px;">
      <tr><td style="${PDF_CELL.notesHeading}">${escHtml(b.title)}</td></tr>
      <tr><td style="${PDF_CELL.notesBody}">${escHtml(b.body)}</td></tr>
    </table>`;
    })
    .join("");

  return `<section class="notes-section">${items}</section>`;
}

function buildReportHeader(exportDate: string, target: "excel" | "pdf"): string {
  if (target === "excel") {
    return `
  <table class="report-header">
    <tr>
      <td colspan="2" class="report-brand">${escHtml(APP_LEGAL_NAME)}</td>
    </tr>
    <tr>
      <td colspan="2" class="report-title">Analiz Raporu</td>
    </tr>
    <tr>
      <td class="report-date-label">Oluşturulma</td>
      <td class="report-date">${exportDate}</td>
    </tr>
  </table>`;
  }

  return `
  <table class="report-header" cellpadding="0" cellspacing="0" style="width:100%;border-collapse:collapse;margin-bottom:14px;">
    <tr>
      <td colspan="2" style="${PDF_CELL.headerBrand}">${escHtml(APP_LEGAL_NAME)}</td>
    </tr>
    <tr>
      <td colspan="2" style="${PDF_CELL.headerTitle}">Analiz Raporu</td>
    </tr>
    <tr>
      <td style="${PDF_CELL.headerDateLabel}">Oluşturulma</td>
      <td style="${PDF_CELL.headerDateValue}">${exportDate}</td>
    </tr>
  </table>`;
}

function buildInfoGrid(analiz: PozAnaliz, target: "excel" | "pdf"): string {
  if (target === "excel") {
    const pozValue = excelInfoPozCell(analiz.pozNo);
    const unitValue = excelTextCell(analiz.olcuBirimi);
    const nameValue = `<td class="info-value text" colspan="3" style="mso-number-format:'\\@';">${escHtml(analiz.analizAdi)}</td>`;
    const countValue = `<td class="info-value">${analiz.kalemler.length}</td>`;
    const karValue = excelTextCell(`%${analiz.yukleniciKarOrani}`);

    return `
  <table class="info-grid">
    <tr>
      <td class="info-label">Poz Numarası</td>
      ${pozValue}
      <td class="info-label">Ölçü Birimi</td>
      ${unitValue}
    </tr>
    <tr>
      <td class="info-label">Analiz Adı</td>
      ${nameValue}
    </tr>
    <tr>
      <td class="info-label">Kalem Sayısı</td>
      ${countValue}
      <td class="info-label">Yüklenici Kar Oranı</td>
      ${karValue}
    </tr>
  </table>`;
  }

  return `
  <table class="info-grid" cellpadding="0" cellspacing="0" style="width:100%;border-collapse:collapse;margin-bottom:16px;border:1px solid #dbe3ef;">
    <tr>
      <td style="${PDF_CELL.infoLabel}">Poz Numarası</td>
      <td style="${PDF_CELL.infoValue}">${escHtml(formatResmiPozNo(analiz.pozNo))}</td>
      <td style="${PDF_CELL.infoLabel}">Ölçü Birimi</td>
      <td style="${PDF_CELL.infoValue}">${escHtml(analiz.olcuBirimi)}</td>
    </tr>
    <tr>
      <td style="${PDF_CELL.infoLabel}">Analiz Adı</td>
      <td style="${PDF_CELL.infoValue}" colspan="3">${escHtml(analiz.analizAdi)}</td>
    </tr>
    <tr>
      <td style="${PDF_CELL.infoLabel}">Kalem Sayısı</td>
      <td style="${PDF_CELL.infoValue}">${analiz.kalemler.length}</td>
      <td style="${PDF_CELL.infoLabel}">Yüklenici Kar Oranı</td>
      <td style="${PDF_CELL.infoValue}">%${analiz.yukleniciKarOrani}</td>
    </tr>
  </table>`;
}

function buildSantijetReportBody(analiz: PozAnaliz, target: "excel" | "pdf"): string {
  const totals = hesaplaAnalizToplam(analiz);
  const exportDate = new Date().toLocaleDateString("tr-TR", {
    day: "numeric",
    month: "long",
    year: "numeric",
  });

  const sections = (["malzeme", "iscilik", "ekipman"] as const)
    .map((tip) => buildKalemSection(analiz, tip, target))
    .join("");

  const costSummary = buildCostSummary(analiz, totals, target);
  const notes = buildNotesSection(analiz, target);

  return `
  <div class="report">
    ${buildReportHeader(exportDate, target)}
    ${buildInfoGrid(analiz, target)}

    ${sections}
    ${costSummary}
    ${notes}

    <table class="report-footer">
      <tr>
        <td>${escHtml(APP_LEGAL_NAME)} — Bu rapor resmi kurum yayını değildir; yalnızca bilgilendirme amaçlıdır.</td>
      </tr>
    </table>
  </div>`;
}

/** Excel — ŞantiJET rapor formatı (.xls) */
export function buildAnalizExcelHtml(analiz: PozAnaliz): string {
  return `<!DOCTYPE html>
<html xmlns:o="urn:schemas-microsoft-com:office:office"
      xmlns:x="urn:schemas-microsoft-com:office:excel"
      xmlns="http://www.w3.org/TR/REC-html40">
<head>
  <meta charset="utf-8" />
  <title>${escHtml(formatResmiPozNo(analiz.pozNo))} — ŞantiJET Analiz Raporu</title>
  <!--[if gte mso 9]><xml>
    <x:ExcelWorkbook>
      <x:ExcelWorksheets><x:ExcelWorksheet>
        <x:Name>Analiz Raporu</x:Name>
        <x:WorksheetOptions><x:DisplayGridlines/></x:WorksheetOptions>
      </x:ExcelWorksheet></x:ExcelWorksheets>
    </x:ExcelWorkbook>
  </xml><![endif]-->
  <style>${EXCEL_STYLES}</style>
</head>
<body>${buildSantijetReportBody(analiz, "excel")}
</body>
</html>`;
}

export function buildAnalizHtml(
  analiz: PozAnaliz,
  orientation: PdfPaperOrientation = PDF_PAPER_ORIENTATION,
): string {
  const resolvedOrientation = resolvePdfOrientation(orientation);
  return `<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <title>${escHtml(formatResmiPozNo(analiz.pozNo))} — ŞantiJET Analiz Raporu</title>
  <style>${buildPdfExportStyles(resolvedOrientation)}</style>
</head>
<body><div class="pdf-content">${buildSantijetReportBody(analiz, "pdf")}</div>
</body>
</html>`;
}

function pdfPageSize(orientation: PdfPaperOrientation): { width: number; height: number } {
  // A4 @ 72 dpi (pt)
  return orientation === "landscape"
    ? { width: 842, height: 595 }
    : { width: 595, height: 842 };
}

function pdfPageMarginsPt(): { top: number; right: number; bottom: number; left: number } {
  return { top: 0, bottom: 0, left: 0, right: 0 };
}

async function downloadOnWeb(content: string, filename: string, mime: string): Promise<void> {
  const blob = new Blob([content], { type: mime });
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = filename;
  anchor.click();
  URL.revokeObjectURL(url);
}

function isShareCancelled(err: unknown): boolean {
  const msg = err instanceof Error ? err.message : String(err);
  return /cancel|dismiss|abort|closed/i.test(msg);
}

async function shareExportFile(uri: string, dialogTitle: string, mimeType: string): Promise<void> {
  if (Platform.OS === "web") return;

  if (await Sharing.isAvailableAsync()) {
    try {
      await Sharing.shareAsync(uri, {
        mimeType,
        dialogTitle,
        ...(Platform.OS === "ios" ? { UTI: "public.data" } : {}),
      });
      return;
    } catch (err) {
      if (isShareCancelled(err)) return;
    }
  }

  try {
    const result = await Share.share(
      Platform.OS === "ios"
        ? { url: uri, title: dialogTitle }
        : { title: dialogTitle, message: dialogTitle, url: uri },
    );
    if (result.action === Share.dismissedAction) return;
  } catch (err) {
    if (isShareCancelled(err)) return;
    throw err;
  }
}

async function writeExportFile(filename: string, content: string): Promise<string> {
  const dir = FileSystem.documentDirectory ?? FileSystem.cacheDirectory;
  if (!dir) throw new Error("Dosya dizini bulunamadı");
  const uri = `${dir}${filename}`;
  await FileSystem.writeAsStringAsync(uri, content, {
    encoding: FileSystem.EncodingType.UTF8,
  });
  const info = await FileSystem.getInfoAsync(uri);
  if (!info.exists) throw new Error("Dosya oluşturulamadı");
  return uri;
}

function uint8ToBase64(bytes: Uint8Array): string {
  let binary = "";
  const chunk = 0x8000;
  for (let i = 0; i < bytes.length; i += chunk) {
    binary += String.fromCharCode(...bytes.subarray(i, i + chunk));
  }
  return btoa(binary);
}

async function writeExportBinaryFile(filename: string, bytes: Uint8Array): Promise<string> {
  const dir = FileSystem.documentDirectory ?? FileSystem.cacheDirectory;
  if (!dir) throw new Error("Dosya dizini bulunamadı");
  const uri = `${dir}${filename}`;
  await FileSystem.writeAsStringAsync(uri, uint8ToBase64(bytes), {
    encoding: FileSystem.EncodingType.Base64,
  });
  const info = await FileSystem.getInfoAsync(uri);
  if (!info.exists) throw new Error("Dosya oluşturulamadı");
  return uri;
}

async function downloadBinaryOnWeb(bytes: Uint8Array, filename: string, mime: string): Promise<void> {
  const copy = new Uint8Array(bytes);
  const blob = new Blob([copy], { type: mime });
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = filename;
  anchor.click();
  URL.revokeObjectURL(url);
}

async function buildPdfBytes(
  analiz: PozAnaliz,
  pdfOrientation: PdfPaperOrientation,
): Promise<Uint8Array | null> {
  const orientation = resolvePdfOrientation(pdfOrientation);
  const html = buildAnalizHtml(analiz, orientation);
  const { width, height } = pdfPageSize(orientation);
  try {
    const Print = await import("expo-print");
    const { uri } = await Print.printToFileAsync({
      html,
      width,
      height,
      margins: pdfPageMarginsPt(),
    });
    const base64 = await FileSystem.readAsStringAsync(uri, {
      encoding: FileSystem.EncodingType.Base64,
    });
    const raw = atob(base64);
    const bytes = new Uint8Array(raw.length);
    for (let i = 0; i < raw.length; i += 1) bytes[i] = raw.charCodeAt(i);
    return bytes;
  } catch {
    return null;
  }
}

/** Modal kapandıktan sonra paylaşım sheet'inin görünmesi için kısa gecikme */
export function waitForShareSheet(): Promise<void> {
  return new Promise((resolve) => {
    InteractionManager.runAfterInteractions(() => {
      setTimeout(resolve, Platform.OS === "ios" ? 500 : 300);
    });
  });
}

export async function exportAnaliz(
  analiz: PozAnaliz,
  format: AnalizExportFormat,
  options: AnalizExportOptions = {},
): Promise<void> {
  const base = safeFilename(analiz.pozNo);
  const pdfOrientation = resolvePdfOrientation(options.pdfOrientation);

  try {
    if (format === "excel") {
      const content = buildAnalizExcelHtml(analiz);
      const filename = `analiz_${base}.xls`;
      if (Platform.OS === "web") {
        await downloadOnWeb(content, filename, "application/vnd.ms-excel;charset=utf-8");
        return;
      }
      const uri = await writeExportFile(filename, content);
      await shareExportFile(uri, "Excel Dışa Aktar", "application/vnd.ms-excel");
      return;
    }

    const html = buildAnalizHtml(analiz, pdfOrientation);
    const { width, height } = pdfPageSize(pdfOrientation);
    if (Platform.OS === "web") {
      const printWindow = window.open("", "_blank");
      if (printWindow) {
        printWindow.document.open();
        printWindow.document.write(html);
        printWindow.document.close();
        const triggerPrint = () => {
          printWindow.focus();
          printWindow.print();
        };
        if (printWindow.document.readyState === "complete") {
          setTimeout(triggerPrint, 250);
        } else {
          printWindow.onload = () => setTimeout(triggerPrint, 250);
        }
      } else {
        await downloadOnWeb(html, `analiz_${base}.html`, "text/html;charset=utf-8");
      }
      return;
    }

    try {
      const Print = await import("expo-print");
      const { uri } = await Print.printToFileAsync({
        html,
        width,
        height,
        margins: pdfPageMarginsPt(),
      });
      await shareExportFile(uri, "PDF Dışa Aktar", "application/pdf");
    } catch {
      const filename = `analiz_${base}.html`;
      const uri = await writeExportFile(filename, html);
      await shareExportFile(uri, "HTML Dışa Aktar (PDF yerine)", "text/html");
    }
  } catch (err) {
    if (isShareCancelled(err)) return;
    Alert.alert("Hata", "Dışa aktarma başarısız. Lütfen tekrar deneyin.");
  }
}

export async function exportBulkAnalizler(
  analizler: PozAnaliz[],
  format: AnalizExportFormat,
  options: AnalizExportOptions = {},
): Promise<void> {
  if (!analizler.length) return;

  const pdfOrientation = resolvePdfOrientation(options.pdfOrientation);
  const zipEntries: Record<string, Uint8Array> = {};
  let htmlFallbackCount = 0;

  try {
    for (const analiz of analizler) {
      const base = safeFilename(analiz.pozNo);
      if (format === "excel") {
        const content = buildAnalizExcelHtml(analiz);
        zipEntries[`analiz_${base}.xls`] = new TextEncoder().encode(content);
        continue;
      }

      if (Platform.OS === "web") {
        const html = buildAnalizHtml(analiz, pdfOrientation);
        zipEntries[`analiz_${base}.html`] = new TextEncoder().encode(html);
        continue;
      }

      const pdfBytes = await buildPdfBytes(analiz, pdfOrientation);
      if (pdfBytes) {
        zipEntries[`analiz_${base}.pdf`] = pdfBytes;
      } else {
        const html = buildAnalizHtml(analiz, pdfOrientation);
        zipEntries[`analiz_${base}.html`] = new TextEncoder().encode(html);
        htmlFallbackCount += 1;
      }
    }

    const zipBytes = zipSync(zipEntries);
    const stamp = new Date().toISOString().slice(0, 10);
    const zipName = `analizler_${stamp}_${analizler.length}.zip`;

    if (Platform.OS === "web") {
      await downloadBinaryOnWeb(zipBytes, zipName, "application/zip");
      return;
    }

    const uri = await writeExportBinaryFile(zipName, zipBytes);
    const title =
      htmlFallbackCount > 0
        ? `Toplu Dışa Aktar (${htmlFallbackCount} HTML yedek)`
        : "Toplu Dışa Aktar";
    await shareExportFile(uri, title, "application/zip");
  } catch (err) {
    if (isShareCancelled(err)) return;
    Alert.alert("Hata", "Toplu dışa aktarma başarısız. Lütfen tekrar deneyin.");
  }
}
