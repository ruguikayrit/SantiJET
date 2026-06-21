import * as FileSystem from "expo-file-system/legacy";
import * as Sharing from "expo-sharing";
import { Alert, Platform, Share } from "react-native";

import { PozAnaliz } from "@/constants/pozAnalizleri";
import {
  AnalizCompareResult,
  buildAnalizCompare,
  trFmtCompare,
} from "@/lib/analizCompare";
import {
  AnalizExportFormat,
  AnalizExportOptions,
  PdfPaperOrientation,
} from "@/lib/analizExport";

const TIP_LABEL: Record<string, string> = {
  malzeme: "Malzeme",
  iscilik: "İşçilik",
  ekipman: "Ekipman",
};

const COMPARE_STYLES = `
  body { font-family: Arial, sans-serif; font-size: 11px; color: #111; margin: 0; }
  h1 { font-size: 16px; margin: 0 0 8px; text-align: center; }
  h2 { font-size: 13px; margin: 18px 0 8px; color: #333; }
  .meta { margin-bottom: 12px; line-height: 1.6; font-size: 10px; color: #555; }
  table { border-collapse: collapse; width: 100%; table-layout: auto; margin-top: 6px; }
  th, td { border: 1px solid #000; padding: 4px 6px; vertical-align: middle; }
  th { background: #f0f4f8; font-weight: bold; text-align: center; font-size: 10px; }
  .label { text-align: left; font-weight: 600; background: #fafafa; }
  .num { text-align: right; white-space: nowrap; }
  .center { text-align: center; }
  .poz-head { font-weight: bold; color: #1d4ed8; }
  .sub { font-size: 9px; color: #666; display: block; margin-top: 2px; }
  .compare-min { background: #dcfce7; }
  .compare-max { background: #fee2e2; }
  .tl { mso-number-format:"\\"₺\\"#,##0.00"; }
  .text { mso-number-format:"\\@"; }
`;

function escHtml(text: string): string {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function safeCompareFilename(compare: AnalizCompareResult): string {
  const parts = compare.analizler
    .map((a) => a.pozNo.replace(/[^a-zA-Z0-9_-]+/g, "_"))
    .slice(0, 4);
  return parts.join("_vs_").slice(0, 80) || "karsilastirma";
}

function buildCompareStyles(orientation: PdfPaperOrientation, colCount: number): string {
  const pageSize = orientation === "landscape" ? "A4 landscape" : "A4 portrait";
  const fontSize = colCount > 3 ? "8px" : colCount > 2 ? "9px" : "10px";
  return `
  @page { size: ${pageSize}; margin: 10mm; }
  ${COMPARE_STYLES}
  body { font-size: ${fontSize}; }
  th, td { font-size: ${fontSize}; padding: 3px 4px; }
  .pdf-content { width: 100%; box-sizing: border-box; }`;
}

function buildCompareBody(compare: AnalizCompareResult, target: "excel" | "pdf"): string {
  const today = new Date().toLocaleDateString("tr-TR");
  const analizList = compare.analizler
    .map((a) => `${escHtml(a.pozNo)} — ${escHtml(a.analizAdi)}`)
    .join("<br/>");

  let summaryRows = "";
  const summaryFields: {
    label: string;
    key: "malzemeIscilikToplami" | "yukleniciKarTutari" | "birimFiyati";
    highlight?: boolean;
  }[] = [
    { label: "Malzeme + İşçilik Tutarı", key: "malzemeIscilikToplami" },
    { label: "Yüklenici Karı", key: "yukleniciKarTutari" },
    {
      label: "1 Birim Fiyatı",
      key: "birimFiyati",
      highlight: true,
    },
  ];

  for (const field of summaryFields) {
    summaryRows += `<tr><td class="label">${field.label}</td>`;
    for (const a of compare.analizler) {
      const val = a[field.key];
      let cls = "num";
      if (field.highlight && compare.analizler.length > 1) {
        if (val === compare.minBirimFiyati) cls += " compare-min";
        else if (val === compare.maxBirimFiyati) cls += " compare-max";
      }
      const suffix = field.key === "birimFiyati" ? ` / ${escHtml(a.olcuBirimi)}` : "";
      if (target === "excel") {
        const n = Number.isFinite(val) ? val : 0;
        summaryRows += `<td class="tl num ${cls}" x:num="${n}">${n}</td>`;
      } else {
        summaryRows += `<td class="${cls}">${trFmtCompare(val)} TL${suffix ? `<span class="sub">${suffix.trim()}</span>` : ""}</td>`;
      }
    }
    summaryRows += "</tr>";
  }

  let kalemHeader = `<tr><th class="label">Tip</th><th>Poz No</th><th class="label">Tanım</th>`;
  for (const a of compare.analizler) {
    kalemHeader += `<th class="poz-head">${escHtml(a.pozNo)}</th>`;
  }
  kalemHeader += "</tr>";

  let kalemRows = "";
  for (const row of compare.kalemRows) {
    const tutarlar = compare.analizler
      .map((a) => row.values[a.id]?.tutar ?? null)
      .filter((v): v is number => v !== null);
    const minT = tutarlar.length ? Math.min(...tutarlar) : null;
    const maxT = tutarlar.length ? Math.max(...tutarlar) : null;

    kalemRows += `<tr>
      <td class="label">${TIP_LABEL[row.tip]}</td>
      <td class="center">${escHtml(row.pozNo || "—")}</td>
      <td class="label">${escHtml(row.tanim || "—")}</td>`;

    for (const a of compare.analizler) {
      const v = row.values[a.id];
      let cls = "num";
      if (v && minT !== null && maxT !== null && minT !== maxT) {
        if (v.tutar === minT) cls += " compare-min";
        else if (v.tutar === maxT) cls += " compare-max";
      }
      if (v) {
        kalemRows +=
          target === "excel"
            ? `<td class="${cls}"><span class="text">${trFmtCompare(v.tutar)} TL</span><span class="sub">${trFmtCompare(v.miktar)} × ${trFmtCompare(v.birimFiyati)}</span></td>`
            : `<td class="${cls}">${trFmtCompare(v.tutar)} TL<span class="sub">${trFmtCompare(v.miktar)} × ${trFmtCompare(v.birimFiyati)}</span></td>`;
      } else {
        kalemRows += `<td class="center">—</td>`;
      }
    }
    kalemRows += "</tr>";
  }

  const emptyKalem =
    compare.kalemRows.length === 0
      ? `<tr><td colspan="${3 + compare.analizler.length}" class="center">Kalem bulunamadı</td></tr>`
      : "";

  let summaryHeader = `<tr><th class="label">Özet</th>`;
  for (const a of compare.analizler) {
    summaryHeader += `<th><span class="poz-head">${escHtml(a.pozNo)}</span><span class="sub">${escHtml(a.analizAdi)}</span></th>`;
  }
  summaryHeader += "</tr>";

  return `
  <h1>ANALİZ KARŞILAŞTIRMA</h1>
  <div class="meta">
    <div><strong>Tarih:</strong> ${today}</div>
    <div><strong>Karşılaştırılan Analizler (${compare.analizler.length}):</strong><br/>${analizList}</div>
  </div>
  <h2>Birim Fiyat Özeti</h2>
  <table>
    <thead>${summaryHeader}</thead>
    <tbody>${summaryRows}</tbody>
  </table>
  <h2>Kalem Karşılaştırması</h2>
  <p style="font-size:9px;color:#666;margin:0 0 6px;">Yeşil: en düşük tutar · Kırmızı: en yüksek tutar</p>
  <table>
    <thead>${kalemHeader}</thead>
    <tbody>${kalemRows}${emptyKalem}</tbody>
  </table>`;
}

export function buildCompareExcelHtml(compare: AnalizCompareResult): string {
  return `<!DOCTYPE html>
<html xmlns:o="urn:schemas-microsoft-com:office:office"
      xmlns:x="urn:schemas-microsoft-com:office:excel"
      xmlns="http://www.w3.org/TR/REC-html40">
<head>
  <meta charset="utf-8" />
  <title>Analiz Karşılaştırma</title>
  <!--[if gte mso 9]><xml>
    <x:ExcelWorkbook>
      <x:ExcelWorksheets><x:ExcelWorksheet>
        <x:Name>Karşılaştırma</x:Name>
        <x:WorksheetOptions><x:DisplayGridlines/></x:WorksheetOptions>
      </x:ExcelWorksheet></x:ExcelWorksheets>
    </x:ExcelWorkbook>
  </xml><![endif]-->
  <style>${COMPARE_STYLES}</style>
</head>
<body>${buildCompareBody(compare, "excel")}
</body>
</html>`;
}

export function buildCompareHtml(
  compare: AnalizCompareResult,
  orientation: PdfPaperOrientation = "landscape",
): string {
  return `<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <title>Analiz Karşılaştırma</title>
  <style>${buildCompareStyles(orientation, compare.analizler.length)}</style>
</head>
<body><div class="pdf-content">${buildCompareBody(compare, "pdf")}</div>
</body>
</html>`;
}

function pdfPageSize(orientation: PdfPaperOrientation): { width: number; height: number } {
  return orientation === "landscape"
    ? { width: 842, height: 595 }
    : { width: 595, height: 842 };
}

function pdfPageMarginsPt(): { top: number; right: number; bottom: number; left: number } {
  const mmToPt = (mm: number) => (mm * 72) / 25.4;
  const margin = mmToPt(10);
  return { top: margin, bottom: margin, left: margin, right: margin };
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

export async function exportCompare(
  analizler: PozAnaliz[],
  format: AnalizExportFormat,
  options: AnalizExportOptions = {},
): Promise<void> {
  if (analizler.length < 2) return;

  const compare = buildAnalizCompare(analizler);
  const base = safeCompareFilename(compare);
  const pdfOrientation = options.pdfOrientation ?? "landscape";

  try {
    if (format === "excel") {
      const content = buildCompareExcelHtml(compare);
      const filename = `karsilastirma_${base}.xls`;
      if (Platform.OS === "web") {
        await downloadOnWeb(content, filename, "application/vnd.ms-excel;charset=utf-8");
        return;
      }
      const uri = await writeExportFile(filename, content);
      await shareExportFile(uri, "Karşılaştırma Excel", "application/vnd.ms-excel");
      return;
    }

    const html = buildCompareHtml(compare, pdfOrientation);
    const { width, height } = pdfPageSize(pdfOrientation);

    if (Platform.OS === "web") {
      const printWindow = window.open("", "_blank");
      if (printWindow) {
        printWindow.document.write(html);
        printWindow.document.close();
        printWindow.focus();
        printWindow.print();
      } else {
        await downloadOnWeb(html, `karsilastirma_${base}.html`, "text/html;charset=utf-8");
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
      await shareExportFile(uri, "Karşılaştırma PDF", "application/pdf");
    } catch {
      const filename = `karsilastirma_${base}.html`;
      const uri = await writeExportFile(filename, html);
      await shareExportFile(uri, "Karşılaştırma HTML (PDF yerine)", "text/html");
    }
  } catch (err) {
    if (isShareCancelled(err)) return;
    Alert.alert("Hata", "Karşılaştırma dışa aktarma başarısız. Lütfen tekrar deneyin.");
  }
}
