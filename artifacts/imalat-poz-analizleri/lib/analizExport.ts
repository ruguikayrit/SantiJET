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

/** Excel — PDF ile aynı düzen, Office HTML (.xls) sarmalayıcı */
export function buildAnalizExcelHtml(analiz: PozAnaliz): string {
  return `<!DOCTYPE html>
<html xmlns:o="urn:schemas-microsoft-com:office:office"
      xmlns:x="urn:schemas-microsoft-com:office:excel"
      xmlns="http://www.w3.org/TR/REC-html40">
<head>
  <meta charset="utf-8" />
  <title>${escHtml(analiz.pozNo)} — BFA</title>
  <!--[if gte mso 9]><xml>
    <x:ExcelWorkbook>
      <x:ExcelWorksheets><x:ExcelWorksheet>
        <x:Name>BFA</x:Name>
        <x:WorksheetOptions><x:DisplayGridlines/></x:WorksheetOptions>
      </x:ExcelWorksheet></x:ExcelWorksheets>
    </x:ExcelWorkbook>
  </xml><![endif]-->
  <style>${REPORT_STYLES}</style>
</head>
<body>${buildAnalizReportBody(analiz)}
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
