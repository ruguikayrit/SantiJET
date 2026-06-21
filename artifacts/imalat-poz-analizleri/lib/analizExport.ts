import * as FileSystem from "expo-file-system/legacy";
import * as Sharing from "expo-sharing";
import { Alert, InteractionManager, Platform, Share } from "react-native";

import { PozAnaliz, hesaplaAnalizToplam } from "@/constants/pozAnalizleri";

export type AnalizExportFormat = "pdf" | "excel";

const REPORT_STYLES = `
  body { font-family: Arial, sans-serif; font-size: 11px; color: #111; padding: 24px; }
  h1 { font-size: 16px; margin: 0 0 4px; }
  h2 { font-size: 13px; margin: 16px 0 8px; color: #444; }
  h3 { font-size: 12px; margin: 14px 0 6px; }
  .meta { margin-bottom: 16px; line-height: 1.6; }
  table { width: 100%; border-collapse: collapse; margin-top: 8px; }
  th, td { border: 1px solid #ccc; padding: 5px 6px; vertical-align: top; }
  th { background: #16213e; color: #fff; font-size: 10px; }
  .group { background: #f0f4f8; font-weight: bold; }
  .num { text-align: right; white-space: nowrap; }
  .summary { margin-top: 12px; line-height: 1.8; }
  .summary strong { display: inline-block; min-width: 220px; }
  p { white-space: pre-wrap; line-height: 1.5; }
`;

const EXCEL_STYLES = `
  body { font-family: Arial, sans-serif; font-size: 11px; color: #111; margin: 0; }
  table { border-collapse: collapse; table-layout: fixed; }
  col.spacer-col { width: 22px; }
  col.poz-col { width: 230px; }
  col.desc-col { width: 430px; }
  col.unit-col { width: 140px; }
  col.qty-col { width: 155px; }
  col.price-col { width: 165px; }
  col.total-col { width: 195px; }
  th, td { border: 1px solid #000; padding: 3px 5px; vertical-align: middle; text-align: center; }
  th { background: #fff; color: #111; font-size: 11px; font-weight: bold; }
  .spacer { border: none; background: #fff; }
  .blank-row td { height: 12px; border: none; }
  .title { height: 30px; font-size: 16px; font-weight: bold; background: #fff; color: #111; }
  .meta-row td { height: 34px; }
  .head-row th, .group { height: 16px; }
  .data-row td { height: 15px; }
  .group { background: #f0f4f8; font-weight: bold; }
  .poz { mso-number-format:"\\@"; }
  .qty { mso-number-format:"0.0000"; }
  .price { mso-number-format:"\\"₺\\"#,##0.00"; }
  .tl { mso-number-format:"\\"₺\\"#,##0.00"; }
  .text { mso-number-format:"\\@"; }
  .summary-label { font-weight: bold; }
  .note { text-align: center; white-space: normal; line-height: 1.4; }
  .tarif { height: 57px; }
  .olcu { height: 16px; font-weight: bold; }
`;

function trFmt(n: number): string {
  return n.toLocaleString("tr-TR", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
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

function excelFormulaTlCell(rowNumber: number, fallback: number): string {
  const numericValue = Number.isFinite(fallback) ? fallback : 0;
  return `<td class="tl" x:fmla="=E${rowNumber}*F${rowNumber}" x:num="${numericValue}">${numericValue}</td>`;
}

function buildAnalizReportBody(analiz: PozAnaliz): string {
  const totals = hesaplaAnalizToplam(analiz);
  const tipAd: Record<string, string> = {
    malzeme: "Malzeme",
    iscilik: "İşçilik",
    ekipman: "Ekipman",
  };

  let tableRows = "";
  for (const tip of ["malzeme", "iscilik", "ekipman"] as const) {
    const rows = analiz.kalemler.filter((k) => k.tip === tip);
    if (!rows.length) continue;
    tableRows += `<tr><td colspan="6" class="group">${tipAd[tip]}</td></tr>`;
    for (const k of rows) {
      tableRows += `<tr>
        <td>${escHtml(k.pozNo)}</td>
        <td>${escHtml(k.tanim)}</td>
        <td>${escHtml(k.olcuBirimi)}</td>
        <td class="num">${trFmt(k.miktar)}</td>
        <td class="num">${trFmt(k.birimFiyati)}</td>
        <td class="num">${trFmt(k.tutar)}</td>
      </tr>`;
    }
  }

  const extraBlocks = [
    analiz.pozTarifi ? `<h3>Poz Tarifi</h3><p>${escHtml(analiz.pozTarifi)}</p>` : "",
    analiz.yapimSartlari
      ? `<h3>Yapım Şartları</h3><p>${escHtml(analiz.yapimSartlari)}</p>`
      : "",
    analiz.olcusu ? `<h3>Ölçüsü</h3><p>${escHtml(analiz.olcusu)}</p>` : "",
  ].join("");

  return `
  <h1>BİRİM FİYAT ANALİZİ</h1>
  <div class="meta">
    <div><strong>Poz No:</strong> ${escHtml(analiz.pozNo)}</div>
    <div><strong>Analiz Adı:</strong> ${escHtml(analiz.analizAdi)}</div>
    <div><strong>Ölçü Birimi:</strong> ${escHtml(analiz.olcuBirimi)}</div>
  </div>
  <h2>Analiz Tablosu</h2>
  <table>
    <thead>
      <tr>
        <th>Poz No</th><th>Tanım</th><th>Birim</th><th>Miktar</th><th>B.Fiyat</th><th>Tutar</th>
      </tr>
    </thead>
    <tbody>${tableRows}</tbody>
  </table>
  <div class="summary">
    <div><strong>Malzeme + İşçilik Tutarı:</strong> ${trFmt(totals.malzemeIscilikToplami)} TL</div>
    <div><strong>%${analiz.yukleniciKarOrani} Yüklenici Karı:</strong> ${trFmt(totals.yukleniciKarTutari)} TL</div>
    <div><strong>1 ${escHtml(analiz.olcuBirimi)} Fiyatı:</strong> ${trFmt(totals.birimFiyati)} TL</div>
  </div>
  ${extraBlocks}`;
}

function buildAnalizExcelBody(analiz: PozAnaliz): string {
  const totals = hesaplaAnalizToplam(analiz);
  const tipAd: Record<string, string> = {
    malzeme: "Malzeme",
    iscilik: "İşçilik",
    ekipman: "Ekipman",
  };

  let rowNumber = 5;
  let tableRows = "";
  for (const tip of ["malzeme", "iscilik", "ekipman"] as const) {
    const rows = analiz.kalemler.filter((k) => k.tip === tip);
    if (!rows.length) continue;

    rowNumber += 1;
    tableRows += `<tr class="head-row"><td class="spacer"></td><td colspan="6" class="group">${tipAd[tip]}</td></tr>`;

    for (const k of rows) {
      rowNumber += 1;
      tableRows += `<tr class="data-row">
        <td class="spacer"></td>
        ${excelPozNoCell(k.pozNo)}
        <td class="text">${escHtml(k.tanim)}</td>
        <td class="text">${escHtml(k.olcuBirimi)}</td>
        ${excelNumberCell(k.miktar, "qty")}
        ${excelNumberCell(k.birimFiyati, "price")}
        ${excelFormulaTlCell(rowNumber, k.tutar)}
      </tr>`;
    }
  }

  const extraRows = [
    analiz.pozTarifi
      ? `<tr><td class="spacer"></td><td colspan="6" class="note tarif">${escHtml(analiz.pozTarifi)}</td></tr>`
      : "",
    analiz.yapimSartlari
      ? `<tr><td class="spacer"></td><td colspan="6" class="note tarif">${escHtml(analiz.yapimSartlari)}</td></tr>`
      : "",
    analiz.olcusu
      ? `<tr><td class="spacer"></td><td colspan="6" class="note olcu">Ölçü: ${escHtml(analiz.olcusu)}</td></tr>`
      : "",
  ].join("");

  return `
  <table>
    <colgroup>
      <col class="spacer-col" />
      <col class="poz-col" />
      <col class="desc-col" />
      <col class="unit-col" />
      <col class="qty-col" />
      <col class="price-col" />
      <col class="total-col" />
    </colgroup>
    <tr class="blank-row">
      <td class="spacer"></td>
      <td colspan="6"></td>
    </tr>
    <tr>
      <td class="spacer"></td>
      <td colspan="6" class="title">BİRİM FİYAT ANALİZİ</td>
    </tr>
    <tr class="head-row">
      <td class="spacer"></td>
      <th>Poz No</th>
      <th colspan="4">Analiz Adı</th>
      <th>Ölçü Birimi</th>
    </tr>
    <tr class="meta-row">
      <td class="spacer"></td>
      ${excelPozNoCell(analiz.pozNo)}
      <td colspan="4" class="text">${escHtml(analiz.analizAdi)}</td>
      <td class="text">${escHtml(analiz.olcuBirimi)}</td>
    </tr>
    <tr class="head-row">
      <td class="spacer"></td>
      <th>Poz No</th>
      <th>Tanım</th>
      <th>Birim</th>
      <th>Miktar</th>
      <th>B.Fiyat</th>
      <th>Tutar</th>
    </tr>
    ${tableRows}
    <tr>
      <td class="spacer"></td>
      <td colspan="5" class="text summary-label">Malzeme + İşçilik Tutarı</td>
      ${excelTlCell(totals.malzemeIscilikToplami)}
    </tr>
    <tr>
      <td class="spacer"></td>
      <td colspan="5" class="text summary-label">%${analiz.yukleniciKarOrani} Yüklenici Karı</td>
      ${excelTlCell(totals.yukleniciKarTutari)}
    </tr>
    <tr>
      <td class="spacer"></td>
      <td colspan="5" class="text summary-label">1 ${escHtml(analiz.olcuBirimi)} Fiyatı</td>
      ${excelTlCell(totals.birimFiyati)}
    </tr>
    ${extraRows}
  </table>`;
}

/** Excel — hücreleri ayrı, ortalı ve Office formüllü (.xls) şablon */
export function buildAnalizExcelHtml(analiz: PozAnaliz): string {
  return `<!DOCTYPE html>
<html xmlns:o="urn:schemas-microsoft-com:office:office"
      xmlns:x="urn:schemas-microsoft-com:office:excel"
      xmlns="http://www.w3.org/TR/REC-html40">
<head>
  <meta charset="utf-8" />
  <title>${escHtml(formatResmiPozNo(analiz.pozNo))} — BFA</title>
  <!--[if gte mso 9]><xml>
    <x:ExcelWorkbook>
      <x:ExcelWorksheets><x:ExcelWorksheet>
        <x:Name>BFA</x:Name>
        <x:WorksheetOptions><x:DisplayGridlines/></x:WorksheetOptions>
      </x:ExcelWorksheet></x:ExcelWorksheets>
    </x:ExcelWorkbook>
  </xml><![endif]-->
  <style>${EXCEL_STYLES}</style>
</head>
<body>${buildAnalizExcelBody(analiz)}
</body>
</html>`;
}

export function buildAnalizHtml(analiz: PozAnaliz): string {
  return `<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <title>${escHtml(analiz.pozNo)} — BFA</title>
  <style>${REPORT_STYLES}</style>
</head>
<body>${buildAnalizReportBody(analiz)}
</body>
</html>`;
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

/** Modal kapandıktan sonra paylaşım sheet'inin görünmesi için kısa gecikme */
export function waitForShareSheet(): Promise<void> {
  return new Promise((resolve) => {
    InteractionManager.runAfterInteractions(() => {
      setTimeout(resolve, Platform.OS === "ios" ? 500 : 300);
    });
  });
}

export async function exportAnaliz(analiz: PozAnaliz, format: AnalizExportFormat): Promise<void> {
  const base = safeFilename(analiz.pozNo);

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

    const html = buildAnalizHtml(analiz);
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
      const { uri } = await Print.printToFileAsync({ html });
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
