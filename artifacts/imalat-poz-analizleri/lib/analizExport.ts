import * as FileSystem from "expo-file-system/legacy";
import * as Sharing from "expo-sharing";
import { Alert, Platform } from "react-native";

import { PozAnaliz, hesaplaAnalizToplam } from "@/constants/pozAnalizleri";

export type AnalizExportFormat = "pdf" | "excel";

function trFmt(n: number): string {
  return n.toLocaleString("tr-TR", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function excelNum(n: number): string {
  const v = Math.round(n * 100) / 100;
  return v.toFixed(2).replace(".", ",");
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

function escCell(text: string): string {
  return escHtml(text).replace(/\n/g, "<br/>");
}

/** Excel'in doğrudan açabildiği HTML tablo (.xls) */
export function buildAnalizExcelHtml(analiz: PozAnaliz): string {
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
    tableRows += `<tr><td colspan="6" style="background:#e8eef5;font-weight:bold">${tipAd[tip]}</td></tr>`;
    for (const k of rows) {
      tableRows += `<tr>
        <td>${escCell(k.pozNo)}</td>
        <td>${escCell(k.tanim)}</td>
        <td>${escCell(k.olcuBirimi)}</td>
        <td style="text-align:right">${excelNum(k.miktar)}</td>
        <td style="text-align:right">${excelNum(k.birimFiyati)}</td>
        <td style="text-align:right">${excelNum(k.tutar)}</td>
      </tr>`;
    }
  }

  return `<!DOCTYPE html>
<html xmlns:o="urn:schemas-microsoft-com:office:office"
      xmlns:x="urn:schemas-microsoft-com:office:excel"
      xmlns="http://www.w3.org/TR/REC-html40">
<head>
  <meta charset="utf-8" />
  <!--[if gte mso 9]><xml>
    <x:ExcelWorkbook>
      <x:ExcelWorksheets><x:ExcelWorksheet>
        <x:Name>BFA</x:Name>
        <x:WorksheetOptions><x:DisplayGridlines/></x:WorksheetOptions>
      </x:ExcelWorksheet></x:ExcelWorksheets>
    </x:ExcelWorkbook>
  </xml><![endif]-->
  <style>
    table { border-collapse: collapse; width: 100%; }
    th, td { border: 1px solid #999; padding: 4px 6px; font-size: 11pt; vertical-align: top; }
    th { background: #16213e; color: #fff; font-weight: bold; }
    .meta td { border: none; padding: 2px 0; }
    .summary td { border: none; font-weight: bold; }
  </style>
</head>
<body>
  <table>
    <tr class="meta"><td colspan="6"><b>BİRİM FİYAT ANALİZİ</b></td></tr>
    <tr class="meta"><td colspan="2">Poz No</td><td colspan="4">${escCell(analiz.pozNo)}</td></tr>
    <tr class="meta"><td colspan="2">Analiz Adı</td><td colspan="4">${escCell(analiz.analizAdi)}</td></tr>
    <tr class="meta"><td colspan="2">Ölçü Birimi</td><td colspan="4">${escCell(analiz.olcuBirimi)}</td></tr>
    <tr><td colspan="6">&nbsp;</td></tr>
    <tr>
      <th>Poz No</th><th>Tanım</th><th>Ölçü Birimi</th>
      <th>Miktar</th><th>Birim Fiyatı (TL)</th><th>Tutar (TL)</th>
    </tr>
    ${tableRows}
    <tr><td colspan="6">&nbsp;</td></tr>
    <tr class="summary">
      <td colspan="5">Malzeme + İşçilik Tutarı</td>
      <td style="text-align:right">${excelNum(totals.malzemeIscilikToplami)}</td>
    </tr>
    <tr class="summary">
      <td colspan="5">%${analiz.yukleniciKarOrani} Yüklenici Karı</td>
      <td style="text-align:right">${excelNum(totals.yukleniciKarTutari)}</td>
    </tr>
    <tr class="summary">
      <td colspan="5">1 ${escCell(analiz.olcuBirimi)} Fiyatı</td>
      <td style="text-align:right">${excelNum(totals.birimFiyati)}</td>
    </tr>
  </table>
</body>
</html>`;
}

export function buildAnalizHtml(analiz: PozAnaliz): string {
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

  return `<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <title>${escHtml(analiz.pozNo)} — BFA</title>
  <style>
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
  </style>
</head>
<body>
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
  ${extraBlocks}
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

async function shareFile(
  uri: string,
  mimeType: string,
  dialogTitle: string,
  uti?: string,
): Promise<void> {
  if (!(await Sharing.isAvailableAsync())) {
    Alert.alert("Dışa Aktarma", "Bu cihazda paylaşım desteklenmiyor.");
    return;
  }
  await Sharing.shareAsync(uri, {
    mimeType,
    dialogTitle,
    ...(uti && Platform.OS === "ios" ? { UTI: uti } : {}),
  });
}

async function writeExportFile(filename: string, content: string): Promise<string> {
  const dir = FileSystem.cacheDirectory ?? FileSystem.documentDirectory;
  if (!dir) throw new Error("Dosya dizini bulunamadı");
  const uri = `${dir}${filename}`;
  await FileSystem.writeAsStringAsync(uri, content, {
    encoding: FileSystem.EncodingType.UTF8,
  });
  const info = await FileSystem.getInfoAsync(uri);
  if (!info.exists) throw new Error("Dosya oluşturulamadı");
  return uri;
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
      await shareFile(uri, "application/vnd.ms-excel", "Excel Dışa Aktar", "com.microsoft.excel.xls");
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
      await shareFile(uri, "application/pdf", "PDF Dışa Aktar", "com.adobe.pdf");
    } catch {
      const filename = `analiz_${base}.html`;
      const uri = await writeExportFile(filename, html);
      await shareFile(uri, "text/html", "HTML Dışa Aktar (PDF yerine)");
    }
  } catch {
    Alert.alert("Hata", "Dışa aktarma başarısız. Lütfen tekrar deneyin.");
  }
}
