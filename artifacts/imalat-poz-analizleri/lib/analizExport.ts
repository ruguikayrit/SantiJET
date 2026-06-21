import * as FileSystem from "expo-file-system/legacy";
import * as Sharing from "expo-sharing";
import { zipSync } from "fflate";
import { Alert, InteractionManager, Platform, Share } from "react-native";

import { APP_LEGAL_NAME } from "@/constants/appInfo";
import { PozAnaliz, hesaplaAnalizToplam } from "@/constants/pozAnalizleri";

export type AnalizExportFormat = "pdf" | "excel";
export type PdfPaperOrientation = "landscape" | "portrait";

export interface AnalizExportOptions {
  pdfOrientation?: PdfPaperOrientation;
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
    background: linear-gradient(135deg, #16213e 0%, #0f3460 100%);
    color: #fff;
    border-radius: 10px;
    padding: 16px 18px;
    margin-bottom: 14px;
  }
  .report-brand {
    font-size: 10px;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    opacity: 0.82;
    margin-bottom: 4px;
  }
  .report-title {
    font-size: 18px;
    font-weight: 700;
    margin: 0 0 6px;
  }
  .report-date {
    font-size: 10px;
    opacity: 0.88;
  }
  .info-grid {
    display: table;
    width: 100%;
    border-collapse: separate;
    border-spacing: 0;
    margin-bottom: 16px;
    border: 1px solid #dbe3ef;
    border-radius: 10px;
    overflow: hidden;
    background: #f8fafc;
  }
  .info-row { display: table-row; }
  .info-cell {
    display: table-cell;
    width: 50%;
    padding: 10px 12px;
    vertical-align: top;
    border-bottom: 1px solid #e2e8f0;
  }
  .info-row:last-child .info-cell { border-bottom: none; }
  .info-cell:nth-child(odd) { border-right: 1px solid #e2e8f0; }
  .info-label {
    display: block;
    font-size: 9px;
    font-weight: 700;
    letter-spacing: 0.04em;
    text-transform: uppercase;
    color: #64748b;
    margin-bottom: 3px;
  }
  .info-value {
    font-size: 12px;
    font-weight: 600;
    color: #0f172a;
  }
  .kalem-section { margin-bottom: 14px; }
  .section-title {
    font-size: 12px;
    font-weight: 700;
    color: #0f172a;
    margin: 0 0 6px;
    padding-left: 10px;
    border-left: 4px solid #e85d04;
  }
  .section-title.iscilik { border-left-color: #16213e; }
  .section-title.ekipman { border-left-color: #0f766e; }
  .section-badge {
    display: inline-block;
    margin-left: 6px;
    padding: 1px 7px;
    border-radius: 999px;
    background: #e2e8f0;
    color: #475569;
    font-size: 9px;
    font-weight: 600;
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
    margin: 18px 0 14px;
    border: 1px solid #cbd5e1;
    border-radius: 10px;
    overflow: hidden;
    background: #fff;
  }
  .cost-summary-title {
    background: #f1f5f9;
    padding: 8px 12px;
    font-size: 11px;
    font-weight: 700;
    color: #0f172a;
    border-bottom: 1px solid #e2e8f0;
  }
  .cost-table {
    width: 100%;
    border-collapse: collapse;
  }
  .cost-table td {
    padding: 8px 12px;
    border-bottom: 1px solid #eef2f7;
    font-size: 11px;
  }
  .cost-table tr:last-child td { border-bottom: none; }
  .cost-label { color: #334155; }
  .cost-value { text-align: right; font-weight: 600; color: #0f172a; }
  .cost-total td {
    background: #16213e;
    color: #fff;
    font-size: 12px;
    font-weight: 700;
    padding: 10px 12px;
  }
  .cost-total .cost-value { color: #fff; }
  .notes-section { margin-top: 16px; }
  .notes-heading {
    font-size: 11px;
    font-weight: 700;
    color: #16213e;
    margin: 0 0 4px;
    padding-bottom: 4px;
    border-bottom: 2px solid #e85d04;
    display: inline-block;
  }
  .notes-block { margin-bottom: 12px; }
  .notes-body {
    margin: 6px 0 0;
    padding: 10px 12px;
    background: #f8fafc;
    border-left: 3px solid #cbd5e1;
    border-radius: 0 8px 8px 0;
    white-space: pre-wrap;
    font-size: 10px;
    color: #334155;
    line-height: 1.55;
  }
  .report-footer {
    margin-top: 18px;
    padding-top: 10px;
    border-top: 1px solid #e2e8f0;
    font-size: 9px;
    color: #94a3b8;
    text-align: center;
    line-height: 1.5;
  }
`;

const PDF_PAGE_MARGIN_MM = 10;

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

function buildPdfExportStyles(orientation: PdfPaperOrientation = "landscape"): string {
  const pageSize = orientation === "landscape" ? "A4 landscape" : "A4 portrait";
  const margin = `${PDF_PAGE_MARGIN_MM}mm`;
  return `
  @page {
    size: ${pageSize};
    margin-top: 8mm;
    margin-bottom: 8mm;
    margin-left: ${margin};
    margin-right: ${margin};
  }
  ${SANTIJET_REPORT_STYLES}
  ${reportOrientationStyles(orientation)}
  .pdf-content { margin: 0 auto; width: 100%; box-sizing: border-box; }`;
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

function excelCurrencyValue(value: number): string {
  const numericValue = Number.isFinite(value) ? value : 0;
  return `<span class="tl" x:num="${numericValue}">${numericValue}</span>`;
}

function pdfNumberCell(value: number, className: "qty" | "price"): string {
  return `<td class="${className} num">${className === "qty" ? trQty(value) : trCurrency(value)}</td>`;
}

function pdfTlCell(value: number): string {
  return `<td class="tl num">${trCurrency(value)}</td>`;
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
    tableRows += `<tr>
      <td class="center idx">${index + 1}</td>
      ${excelPozNoCell(k.pozNo)}
      <td class="desc text">${escHtml(k.tanim)}</td>
      <td class="center text">${escHtml(k.olcuBirimi)}</td>
      ${target === "excel" ? excelNumberCell(k.miktar, "qty") : pdfNumberCell(k.miktar, "qty")}
      ${target === "excel" ? excelNumberCell(k.birimFiyati, "price") : pdfNumberCell(k.birimFiyati, "price")}
      ${target === "excel" ? excelTlCell(k.tutar) : pdfTlCell(k.tutar)}
    </tr>`;
  });

  const badge = `${rows.length} kalem`;
  const tipClass = tip === "malzeme" ? "" : tip;

  return `
  <section class="kalem-section">
    <div class="section-title ${tipClass}" style="border-left-color:${TIP_ACCENT[tip]}">
      ${TIP_LABEL[tip]}<span class="section-badge">${badge}</span>
    </div>
    <table class="data-table">
      <colgroup>
        <col style="width:4%" />
        <col style="width:12%" />
        <col style="width:34%" />
        <col style="width:8%" />
        <col style="width:12%" />
        <col style="width:15%" />
        <col style="width:15%" />
      </colgroup>
      <thead>
        <tr>
          <th class="center">#</th>
          <th>Poz No</th>
          <th>Açıklama</th>
          <th class="center">Birim</th>
          <th class="num">Miktar</th>
          <th class="num">Birim Fiyat</th>
          <th class="num">Tutar</th>
        </tr>
      </thead>
      <tbody>${tableRows}</tbody>
    </table>
  </section>`;
}

function buildCostSummary(
  analiz: PozAnaliz,
  totals: ReturnType<typeof hesaplaAnalizToplam>,
  target: "excel" | "pdf",
): string {
  const valueCell = (value: number) =>
    target === "excel" ? excelCurrencyValue(value) : trCurrency(value);

  return `
  <div class="cost-summary">
    <div class="cost-summary-title">Maliyet Özeti</div>
    <table class="cost-table">
      <tr>
        <td class="cost-label">Ara Toplam (Malzeme + İşçilik)</td>
        <td class="cost-value">${valueCell(totals.malzemeIscilikToplami)}</td>
      </tr>
      <tr>
        <td class="cost-label">Yüklenici Karı (%${analiz.yukleniciKarOrani})</td>
        <td class="cost-value">${valueCell(totals.yukleniciKarTutari)}</td>
      </tr>
      <tr class="cost-total">
        <td class="cost-label">Birim Fiyat (1 ${escHtml(analiz.olcuBirimi)})</td>
        <td class="cost-value">${valueCell(totals.birimFiyati)}</td>
      </tr>
    </table>
  </div>`;
}

function buildNotesSection(analiz: PozAnaliz): string {
  const blocks = [
    analiz.pozTarifi ? { title: "Poz Tarifi", body: analiz.pozTarifi } : null,
    analiz.yapimSartlari ? { title: "Yapım Şartları", body: analiz.yapimSartlari } : null,
    analiz.olcusu ? { title: "Ölçü Bilgisi", body: analiz.olcusu } : null,
    analiz.notlar ? { title: "Notlar", body: analiz.notlar } : null,
  ].filter(Boolean) as { title: string; body: string }[];

  if (!blocks.length) return "";

  const items = blocks
    .map(
      (b) => `
    <div class="notes-block">
      <div class="notes-heading">${escHtml(b.title)}</div>
      <div class="notes-body">${escHtml(b.body)}</div>
    </div>`,
    )
    .join("");

  return `<section class="notes-section">${items}</section>`;
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
  const notes = buildNotesSection(analiz);

  return `
  <div class="report">
    <header class="report-header">
      <div class="report-brand">${escHtml(APP_LEGAL_NAME)}</div>
      <h1 class="report-title">Analiz Raporu</h1>
      <div class="report-date">Oluşturulma: ${exportDate}</div>
    </header>

    <div class="info-grid">
      <div class="info-row">
        <div class="info-cell">
          <span class="info-label">Poz Numarası</span>
          <span class="info-value">${escHtml(formatResmiPozNo(analiz.pozNo))}</span>
        </div>
        <div class="info-cell">
          <span class="info-label">Ölçü Birimi</span>
          <span class="info-value">${escHtml(analiz.olcuBirimi)}</span>
        </div>
      </div>
      <div class="info-row">
        <div class="info-cell" style="width:100%;display:table-cell;border-right:none">
          <span class="info-label">Analiz Adı</span>
          <span class="info-value">${escHtml(analiz.analizAdi)}</span>
        </div>
      </div>
      <div class="info-row">
        <div class="info-cell">
          <span class="info-label">Kalem Sayısı</span>
          <span class="info-value">${analiz.kalemler.length}</span>
        </div>
        <div class="info-cell">
          <span class="info-label">Yüklenici Kar Oranı</span>
          <span class="info-value">%${analiz.yukleniciKarOrani}</span>
        </div>
      </div>
    </div>

    ${sections}
    ${costSummary}
    ${notes}

    <footer class="report-footer">
      ${escHtml(APP_LEGAL_NAME)} — Bu rapor resmi kurum yayını değildir; yalnızca bilgilendirme amaçlıdır.
    </footer>
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
  orientation: PdfPaperOrientation = "landscape",
): string {
  return `<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <title>${escHtml(formatResmiPozNo(analiz.pozNo))} — ŞantiJET Analiz Raporu</title>
  <style>${buildPdfExportStyles(orientation)}</style>
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
  const mmToPt = (mm: number) => (mm * 72) / 25.4;
  return {
    top: mmToPt(8),
    bottom: mmToPt(8),
    left: mmToPt(PDF_PAGE_MARGIN_MM),
    right: mmToPt(PDF_PAGE_MARGIN_MM),
  };
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
  const html = buildAnalizHtml(analiz, pdfOrientation);
  const { width, height } = pdfPageSize(pdfOrientation);
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
  const pdfOrientation = options.pdfOrientation ?? "landscape";

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
        printWindow.document.write(html);
        printWindow.document.close();
        printWindow.focus();
        printWindow.print();
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

  const pdfOrientation = options.pdfOrientation ?? "landscape";
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
