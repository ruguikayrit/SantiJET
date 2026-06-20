import * as FileSystem from "expo-file-system/legacy";
import * as Sharing from "expo-sharing";
import { Alert, Platform } from "react-native";

import { PozAnaliz, hesaplaAnalizToplam } from "@/constants/pozAnalizleri";

export type AnalizExportFormat = "txt" | "csv" | "pdf";

function trFmt(n: number): string {
  return n.toLocaleString("tr-TR", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
}

function escCsv(value: string): string {
  const v = value.replace(/"/g, '""');
  return `"${v}"`;
}

function safeFilename(pozNo: string): string {
  return pozNo.replace(/[^a-zA-Z0-9_-]+/g, "_").slice(0, 40) || "analiz";
}

export function buildAnalizText(analiz: PozAnaliz): string {
  const totals = hesaplaAnalizToplam(analiz);
  let txt = `BİRİM FİYAT ANALİZİ\n${"=".repeat(60)}\n`;
  txt += `Poz No      : ${analiz.pozNo}\n`;
  txt += `Analiz Adı  : ${analiz.analizAdi}\n`;
  txt += `Ölçü Birimi : ${analiz.olcuBirimi}\n\n`;

  const tipSira: ("malzeme" | "iscilik" | "ekipman")[] = ["malzeme", "iscilik", "ekipman"];
  const tipAd: Record<string, string> = {
    malzeme: "Malzeme",
    iscilik: "İşçilik",
    ekipman: "Ekipman",
  };

  for (const tip of tipSira) {
    const rows = analiz.kalemler.filter((k) => k.tip === tip);
    if (!rows.length) continue;
    txt += `${tipAd[tip]}\n${"-".repeat(60)}\n`;
    rows.forEach((k) => {
      txt += `  ${k.pozNo.padEnd(14)} ${k.tanim.substring(0, 30).padEnd(32)} ${k.olcuBirimi.padEnd(6)} ${trFmt(k.miktar).padStart(8)} ${trFmt(k.birimFiyati).padStart(10)} ${trFmt(k.tutar).padStart(12)}\n`;
    });
  }
  txt += `${"=".repeat(60)}\n`;
  txt += `Malzeme + İşçilik Tutarı         : ${trFmt(totals.malzemeIscilikToplami)} TL\n`;
  txt += `%${analiz.yukleniciKarOrani} Yüklenici Karı              : ${trFmt(totals.yukleniciKarTutari)} TL\n`;
  txt += `1 ${analiz.olcuBirimi} Fiyatı                  : ${trFmt(totals.birimFiyati)} TL\n`;
  if (analiz.pozTarifi) txt += `\nPoz Tarifi:\n${analiz.pozTarifi}\n`;
  if (analiz.yapimSartlari) txt += `\nYapım Şartları:\n${analiz.yapimSartlari}\n`;
  if (analiz.olcusu) txt += `\nÖlçüsü:\n${analiz.olcusu}\n`;
  return txt;
}

export function buildAnalizCsv(analiz: PozAnaliz): string {
  const totals = hesaplaAnalizToplam(analiz);
  const lines: string[] = [
    "Bölüm,Poz No,Tanım,Ölçü Birimi,Miktar,Birim Fiyatı (TL),Tutar (TL)",
  ];

  for (const k of analiz.kalemler) {
    const bolum =
      k.tip === "malzeme" ? "Malzeme" : k.tip === "iscilik" ? "İşçilik" : "Ekipman";
    lines.push(
      [
        escCsv(bolum),
        escCsv(k.pozNo),
        escCsv(k.tanim),
        escCsv(k.olcuBirimi),
        trFmt(k.miktar),
        trFmt(k.birimFiyati),
        trFmt(k.tutar),
      ].join(","),
    );
  }

  lines.push("");
  lines.push(`Poz No,${escCsv(analiz.pozNo)}`);
  lines.push(`Analiz Adı,${escCsv(analiz.analizAdi)}`);
  lines.push(`Ölçü Birimi,${escCsv(analiz.olcuBirimi)}`);
  lines.push(`Malzeme + İşçilik,${trFmt(totals.malzemeIscilikToplami)}`);
  lines.push(`Yüklenici Karı (%${analiz.yukleniciKarOrani}),${trFmt(totals.yukleniciKarTutari)}`);
  lines.push(`1 ${analiz.olcuBirimi} Fiyatı,${trFmt(totals.birimFiyati)}`);
  return "\uFEFF" + lines.join("\n");
}

function escHtml(text: string): string {
  return text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
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

async function shareFile(uri: string, mimeType: string, dialogTitle: string): Promise<void> {
  if (await Sharing.isAvailableAsync()) {
    await Sharing.shareAsync(uri, { mimeType, dialogTitle });
    return;
  }
  Alert.alert("Dışa Aktarma", "Bu cihazda paylaşım desteklenmiyor.");
}

export async function exportAnaliz(analiz: PozAnaliz, format: AnalizExportFormat): Promise<void> {
  const base = safeFilename(analiz.pozNo);

  try {
    if (format === "txt") {
      const content = buildAnalizText(analiz);
      const filename = `analiz_${base}.txt`;
      if (Platform.OS === "web") {
        await downloadOnWeb(content, filename, "text/plain;charset=utf-8");
        return;
      }
      const uri = `${FileSystem.cacheDirectory}${filename}`;
      await FileSystem.writeAsStringAsync(uri, content, {
        encoding: FileSystem.EncodingType.UTF8,
      });
      await shareFile(uri, "text/plain", "Analizi Dışa Aktar");
      return;
    }

    if (format === "csv") {
      const content = buildAnalizCsv(analiz);
      const filename = `analiz_${base}.csv`;
      if (Platform.OS === "web") {
        await downloadOnWeb(content, filename, "text/csv;charset=utf-8");
        return;
      }
      const uri = `${FileSystem.cacheDirectory}${filename}`;
      await FileSystem.writeAsStringAsync(uri, content, {
        encoding: FileSystem.EncodingType.UTF8,
      });
      await shareFile(uri, "text/csv", "Excel (CSV) Dışa Aktar");
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
      await shareFile(uri, "application/pdf", "PDF Dışa Aktar");
    } catch {
      const filename = `analiz_${base}.html`;
      const uri = `${FileSystem.cacheDirectory}${filename}`;
      await FileSystem.writeAsStringAsync(uri, html, {
        encoding: FileSystem.EncodingType.UTF8,
      });
      await shareFile(uri, "text/html", "HTML Dışa Aktar (PDF yerine)");
    }
  } catch {
    Alert.alert("Hata", "Dışa aktarma başarısız. Lütfen tekrar deneyin.");
  }
}
