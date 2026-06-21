import * as FileSystem from "expo-file-system/legacy";
import * as Sharing from "expo-sharing";
import { Alert, Platform, Share } from "react-native";

import { KesifProject, hesaplaKesifToplam, trFmtKesif } from "@/constants/kesif";
import { AnalizExportFormat, PdfPaperOrientation } from "@/lib/analizExport";

const KESIF_STYLES = `
  body { font-family: Arial, sans-serif; font-size: 11px; color: #111; margin: 0; }
  h1 { font-size: 16px; margin: 0 0 6px; text-align: center; }
  .meta { margin-bottom: 14px; line-height: 1.6; font-size: 10px; color: #444; }
  table { border-collapse: collapse; width: 100%; table-layout: fixed; margin-top: 8px; }
  th, td { border: 1px solid #000; padding: 4px 5px; vertical-align: middle; }
  th { background: #f0f4f8; font-weight: bold; text-align: center; font-size: 10px; }
  .num { text-align: right; white-space: nowrap; }
  .center { text-align: center; }
  .desc { text-align: left; }
  .total-row td { font-weight: bold; background: #f8fafc; }
  .tl { mso-number-format:"\\"₺\\"#,##0.00"; }
  .qty { mso-number-format:"0.0000"; }
  .text { mso-number-format:"\\@"; }
`;

function escHtml(text: string): string {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

function safeFilename(ad: string): string {
  return ad.replace(/[^a-zA-Z0-9_-]+/g, "_").slice(0, 40) || "kesif";
}

function buildKesifBody(project: KesifProject, target: "excel" | "pdf"): string {
  const toplam = hesaplaKesifToplam(project.satirlar);
  const tarih = new Date(project.guncellemeTarihi).toLocaleDateString("tr-TR");

  let rows = "";
  project.satirlar.forEach((s, i) => {
    const qty = Number.isFinite(s.miktar) ? s.miktar : 0;
    const bf = Number.isFinite(s.birimFiyati) ? s.birimFiyati : 0;
    const tut = Number.isFinite(s.tutar) ? s.tutar : 0;
    rows += `<tr>
      <td class="center">${i + 1}</td>
      <td class="center text">${escHtml(s.pozNo)}</td>
      <td class="desc text">${escHtml(s.analizAdi)}</td>
      <td class="center text">${escHtml(s.olcuBirimi)}</td>
      ${target === "excel" ? `<td class="qty num" x:num="${qty}">${qty}</td>` : `<td class="num">${trFmtKesif(qty)}</td>`}
      ${target === "excel" ? `<td class="tl num" x:num="${bf}">${bf}</td>` : `<td class="num">${trFmtKesif(bf)} TL</td>`}
      ${target === "excel" ? `<td class="tl num" x:num="${tut}">${tut}</td>` : `<td class="num">${trFmtKesif(tut)} TL</td>`}
    </tr>`;
  });

  if (!project.satirlar.length) {
    rows = `<tr><td colspan="7" class="center">Henüz poz eklenmedi</td></tr>`;
  }

  const totalCell =
    target === "excel"
      ? `<td class="tl num" x:num="${toplam}">${toplam}</td>`
      : `<td class="num">${trFmtKesif(toplam)} TL</td>`;

  return `
  <h1>METRAJ / KEŞİF CETVELİ</h1>
  <div class="meta">
    <div><strong>Proje:</strong> ${escHtml(project.ad)}</div>
    ${project.aciklama ? `<div><strong>Açıklama:</strong> ${escHtml(project.aciklama)}</div>` : ""}
    <div><strong>Tarih:</strong> ${tarih}</div>
    <div><strong>Poz Sayısı:</strong> ${project.satirlar.length}</div>
  </div>
  <table>
    <thead>
      <tr>
        <th style="width:5%">#</th>
        <th style="width:12%">Poz No</th>
        <th style="width:34%">Tanım</th>
        <th style="width:8%">Birim</th>
        <th style="width:12%">Miktar</th>
        <th style="width:14%">Birim Fiyat (TL)</th>
        <th style="width:15%">Tutar (TL)</th>
      </tr>
    </thead>
    <tbody>
      ${rows}
      <tr class="total-row">
        <td colspan="6" class="desc">GENEL TOPLAM</td>
        ${totalCell}
      </tr>
    </tbody>
  </table>`;
}

export function buildKesifExcelHtml(project: KesifProject): string {
  return `<!DOCTYPE html>
<html xmlns:o="urn:schemas-microsoft-com:office:office"
      xmlns:x="urn:schemas-microsoft-com:office:excel"
      xmlns="http://www.w3.org/TR/REC-html40">
<head>
  <meta charset="utf-8" />
  <title>${escHtml(project.ad)} — Keşif</title>
  <!--[if gte mso 9]><xml>
    <x:ExcelWorkbook>
      <x:ExcelWorksheets><x:ExcelWorksheet>
        <x:Name>Keşif</x:Name>
        <x:WorksheetOptions><x:DisplayGridlines/></x:WorksheetOptions>
      </x:ExcelWorksheet></x:ExcelWorksheets>
    </x:ExcelWorkbook>
  </xml><![endif]-->
  <style>${KESIF_STYLES}</style>
</head>
<body>${buildKesifBody(project, "excel")}
</body>
</html>`;
}

export function buildKesifHtml(
  project: KesifProject,
  orientation: PdfPaperOrientation = "landscape",
): string {
  const pageSize = orientation === "landscape" ? "A4 landscape" : "A4 portrait";
  return `<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <title>${escHtml(project.ad)} — Keşif</title>
  <style>
  @page { size: ${pageSize}; margin: 10mm; }
  ${KESIF_STYLES}
  .pdf-content { width: 100%; box-sizing: border-box; }
  </style>
</head>
<body><div class="pdf-content">${buildKesifBody(project, "pdf")}</div>
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
  return uri;
}

export async function exportKesif(
  project: KesifProject,
  format: AnalizExportFormat,
  options: { pdfOrientation?: PdfPaperOrientation } = {},
): Promise<void> {
  const base = safeFilename(project.ad);
  const pdfOrientation = options.pdfOrientation ?? "landscape";

  try {
    if (format === "excel") {
      const content = buildKesifExcelHtml(project);
      const filename = `kesif_${base}.xls`;
      if (Platform.OS === "web") {
        await downloadOnWeb(content, filename, "application/vnd.ms-excel;charset=utf-8");
        return;
      }
      const uri = await writeExportFile(filename, content);
      await shareExportFile(uri, "Keşif Excel", "application/vnd.ms-excel");
      return;
    }

    const html = buildKesifHtml(project, pdfOrientation);
    const { width, height } = pdfPageSize(pdfOrientation);

    if (Platform.OS === "web") {
      const printWindow = window.open("", "_blank");
      if (printWindow) {
        printWindow.document.write(html);
        printWindow.document.close();
        printWindow.focus();
        printWindow.print();
      } else {
        await downloadOnWeb(html, `kesif_${base}.html`, "text/html;charset=utf-8");
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
      await shareExportFile(uri, "Keşif PDF", "application/pdf");
    } catch {
      const filename = `kesif_${base}.html`;
      const uri = await writeExportFile(filename, html);
      await shareExportFile(uri, "Keşif HTML (PDF yerine)", "text/html");
    }
  } catch (err) {
    if (isShareCancelled(err)) return;
    Alert.alert("Hata", "Keşif dışa aktarma başarısız. Lütfen tekrar deneyin.");
  }
}
