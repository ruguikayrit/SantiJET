import * as FileSystem from "expo-file-system";
import * as Sharing from "expo-sharing";
import { Platform } from "react-native";

import { BankLimit, Debt, Transaction } from "@/context/finans/BudgetContext";

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

function escapeXml(value: string | number | undefined | null): string {
  if (value === null || value === undefined) return "";
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
}

function strCell(value: string | undefined | null): string {
  return `<Cell><Data ss:Type="String">${escapeXml(value ?? "")}</Data></Cell>`;
}

function numCell(value: number): string {
  const v = Number.isFinite(value) ? value : 0;
  return `<Cell ss:StyleID="num"><Data ss:Type="Number">${v}</Data></Cell>`;
}

function headerCell(value: string): string {
  return `<Cell ss:StyleID="header"><Data ss:Type="String">${escapeXml(value)}</Data></Cell>`;
}

function totalStrCell(value: string): string {
  return `<Cell ss:StyleID="totalText"><Data ss:Type="String">${escapeXml(value)}</Data></Cell>`;
}

function totalNumCell(value: number): string {
  const v = Number.isFinite(value) ? value : 0;
  return `<Cell ss:StyleID="totalNum"><Data ss:Type="Number">${v}</Data></Cell>`;
}

function buildWorksheet(name: string, rowsXml: string, columnWidths: number[]): string {
  const cols = columnWidths
    .map((w) => `<Column ss:AutoFitWidth="0" ss:Width="${w}"/>`)
    .join("");
  return `<Worksheet ss:Name="${escapeXml(name)}">
    <Table>${cols}${rowsXml}</Table>
    <WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel">
      <FreezePanes/>
      <FrozenNoSplit/>
      <SplitHorizontal>1</SplitHorizontal>
      <TopRowBottomPane>1</TopRowBottomPane>
      <ActivePane>2</ActivePane>
    </WorksheetOptions>
  </Worksheet>`;
}

function buildXml(
  transactions: Transaction[],
  debts: Debt[],
  bankLimits: BankLimit[]
): string {
  const totalIncome = transactions
    .filter((t) => t.type === "income")
    .reduce((s, t) => s + t.amount, 0);
  const totalExpense = transactions
    .filter((t) => t.type === "expense")
    .reduce((s, t) => s + t.amount, 0);

  const txRowsArr = transactions
    .slice()
    .sort((a, b) => {
      const catCmp = a.category.localeCompare(b.category, "tr", { sensitivity: "base" });
      if (catCmp !== 0) return catCmp;
      return new Date(b.date).getTime() - new Date(a.date).getTime();
    });

  const txHeader = `<Row>
    ${headerCell("#")}
    ${headerCell("Tarih")}
    ${headerCell("Kategori")}
    ${headerCell("Not")}
    ${headerCell("Ödeme")}
    ${headerCell("Tür")}
    ${headerCell("Tutar")}
  </Row>`;

  const txBody = txRowsArr
    .map(
      (t, i) => `<Row>
        ${numCell(i + 1)}
        ${strCell(fmtDate(t.date))}
        ${strCell(t.category)}
        ${strCell(t.note || "")}
        ${strCell(t.paymentMethod === "cash" ? "Nakit" : "Kredi Kartı")}
        ${strCell(t.type === "income" ? "Gelir" : "Gider")}
        ${numCell(t.type === "income" ? t.amount : -t.amount)}
      </Row>`
    )
    .join("");

  const txFooter = `<Row>
    ${totalStrCell("")}${totalStrCell("")}${totalStrCell("")}${totalStrCell("")}${totalStrCell("")}
    ${totalStrCell("Net")}
    ${totalNumCell(totalIncome - totalExpense)}
  </Row>`;

  const txSheet = buildWorksheet(
    "İşlemler",
    txHeader + txBody + (txRowsArr.length > 0 ? txFooter : ""),
    [40, 80, 130, 200, 90, 70, 100]
  );

  // Debts sheet
  const debtsSorted = debts
    .slice()
    .sort((a, b) => a.name.localeCompare(b.name, "tr", { sensitivity: "base" }));

  const totalDebt = debts.reduce((s, d) => s + d.amount, 0);
  const totalDebtPaid = debts.reduce((s, d) => s + d.paidAmount, 0);
  const totalDebtRemaining = Math.max(0, totalDebt - totalDebtPaid);

  const debtHeader = `<Row>
    ${headerCell("#")}
    ${headerCell("Borç Adı")}
    ${headerCell("Alacaklı")}
    ${headerCell("Kategori")}
    ${headerCell("Toplam")}
    ${headerCell("Ödenen")}
    ${headerCell("Kalan")}
    ${headerCell("İlerleme %")}
  </Row>`;

  const debtBody = debtsSorted
    .map((d, i) => {
      const remaining = Math.max(0, d.amount - d.paidAmount);
      const pct = d.amount > 0 ? Math.round((d.paidAmount / d.amount) * 100) : 0;
      return `<Row>
        ${numCell(i + 1)}
        ${strCell(d.name)}
        ${strCell(d.creditor || "")}
        ${strCell(d.category)}
        ${numCell(d.amount)}
        ${numCell(d.paidAmount)}
        ${numCell(remaining)}
        ${numCell(pct)}
      </Row>`;
    })
    .join("");

  const debtFooter = `<Row>
    ${totalStrCell("")}${totalStrCell("TOPLAM")}${totalStrCell("")}${totalStrCell("")}
    ${totalNumCell(totalDebt)}
    ${totalNumCell(totalDebtPaid)}
    ${totalNumCell(totalDebtRemaining)}
    ${totalStrCell("")}
  </Row>`;

  const debtSheet = buildWorksheet(
    "Borçlar",
    debtHeader + debtBody + (debtsSorted.length > 0 ? debtFooter : ""),
    [40, 180, 130, 110, 100, 100, 100, 90]
  );

  // Bank limits sheet
  const ccUsageByBank = new Map<string, number>();
  for (const d of debts) {
    if (d.category.toLowerCase() !== "kredi kartı") continue;
    const key = (d.creditor ?? "").trim().toLowerCase();
    if (!key) continue;
    const remaining = Math.max(0, d.amount - d.paidAmount);
    ccUsageByBank.set(key, (ccUsageByBank.get(key) ?? 0) + remaining);
  }

  const limitsSorted = bankLimits
    .slice()
    .sort((a, b) => a.bank.localeCompare(b.bank, "tr", { sensitivity: "base" }));

  const limitHeader = `<Row>
    ${headerCell("#")}
    ${headerCell("Banka")}
    ${headerCell("Tür")}
    ${headerCell("Limit")}
    ${headerCell("Kullanılan")}
    ${headerCell("Kalan")}
    ${headerCell("Kullanım %")}
  </Row>`;

  const limitBody = limitsSorted
    .map((b, i) => {
      const used =
        b.type === "credit"
          ? (ccUsageByBank.get(b.bank.trim().toLowerCase()) ?? 0)
          : 0;
      const available = Math.max(0, b.limit - used);
      const pct = b.limit > 0 ? Math.round((used / b.limit) * 100) : 0;
      return `<Row>
        ${numCell(i + 1)}
        ${strCell(b.bank)}
        ${strCell(b.type === "credit" ? "Kredi Kartı" : "Ek Hesap")}
        ${numCell(b.limit)}
        ${numCell(used)}
        ${numCell(available)}
        ${numCell(pct)}
      </Row>`;
    })
    .join("");

  const limitSheet = buildWorksheet(
    "Banka Limitleri",
    limitHeader + limitBody,
    [40, 150, 110, 110, 110, 110, 100]
  );

  // Summary sheet
  const ekHesapTotal = debts
    .filter((d) => d.category.toLowerCase() === "ek hesap")
    .reduce((s, d) => s + Math.max(0, d.amount - d.paidAmount), 0);

  const summaryRows = `
    <Row>${headerCell("Bölüm")}${headerCell("Değer")}</Row>
    <Row>${strCell("Toplam Gelir")}${numCell(totalIncome)}</Row>
    <Row>${strCell("Toplam Gider")}${numCell(totalExpense)}</Row>
    <Row>${strCell("Bakiye")}${numCell(totalIncome - totalExpense)}</Row>
    <Row>${strCell("Kalan Borç")}${numCell(totalDebtRemaining)}</Row>
    <Row>${strCell("Genel Toplam Bakiye (Ek Hesap dahil)")}${numCell(-ekHesapTotal)}</Row>
    <Row>${strCell("İşlem Sayısı")}${numCell(transactions.length)}</Row>
    <Row>${strCell("Borç Sayısı")}${numCell(debts.length)}</Row>
    <Row>${strCell("Banka Limiti Sayısı")}${numCell(bankLimits.length)}</Row>
  `;
  const summarySheet = buildWorksheet("Özet", summaryRows, [240, 140]);

  return `<?xml version="1.0" encoding="UTF-8"?>
<?mso-application progid="Excel.Sheet"?>
<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
  xmlns:o="urn:schemas-microsoft-com:office:office"
  xmlns:x="urn:schemas-microsoft-com:office:excel"
  xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"
  xmlns:html="http://www.w3.org/TR/REC-html40">
  <Styles>
    <Style ss:ID="Default" ss:Name="Normal">
      <Font ss:FontName="Calibri" ss:Size="11"/>
      <Alignment ss:Vertical="Center"/>
    </Style>
    <Style ss:ID="header">
      <Font ss:FontName="Calibri" ss:Size="11" ss:Bold="1" ss:Color="#FFFFFF"/>
      <Interior ss:Color="#0B1E33" ss:Pattern="Solid"/>
      <Alignment ss:Vertical="Center" ss:Horizontal="Center"/>
      <Borders>
        <Border ss:Position="Bottom" ss:LineStyle="Continuous" ss:Weight="1" ss:Color="#0B1E33"/>
      </Borders>
    </Style>
    <Style ss:ID="num">
      <NumberFormat ss:Format="#,##0.00"/>
    </Style>
    <Style ss:ID="totalText">
      <Font ss:FontName="Calibri" ss:Size="11" ss:Bold="1"/>
      <Interior ss:Color="#F1F5F9" ss:Pattern="Solid"/>
      <Borders>
        <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="2" ss:Color="#0B1E33"/>
      </Borders>
    </Style>
    <Style ss:ID="totalNum">
      <Font ss:FontName="Calibri" ss:Size="11" ss:Bold="1"/>
      <NumberFormat ss:Format="#,##0.00"/>
      <Interior ss:Color="#F1F5F9" ss:Pattern="Solid"/>
      <Borders>
        <Border ss:Position="Top" ss:LineStyle="Continuous" ss:Weight="2" ss:Color="#0B1E33"/>
      </Borders>
    </Style>
  </Styles>
  ${summarySheet}
  ${txSheet}
  ${debtSheet}
  ${limitSheet}
</Workbook>`;
}

export async function exportAsExcel(
  transactions: Transaction[],
  debts: Debt[],
  bankLimits: BankLimit[]
): Promise<void> {
  const xml = buildXml(transactions, debts, bankLimits);

  if (Platform.OS === "web") {
    const blob = new Blob(["\ufeff" + xml], {
      type: "application/vnd.ms-excel;charset=utf-8",
    });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "butce-raporu.xls";
    a.click();
    URL.revokeObjectURL(url);
    return;
  }

  const dir =
    (FileSystem as any).cacheDirectory ?? (FileSystem as any).documentDirectory;
  if (!dir) {
    throw new Error("Dosya dizini bulunamadı");
  }
  const fileUri = `${dir}butce-raporu.xls`;
  await (FileSystem as any).writeAsStringAsync(fileUri, "\ufeff" + xml, {
    encoding: ((FileSystem as any).EncodingType?.UTF8 ?? "utf8") as any,
  });

  const canShare = await Sharing.isAvailableAsync();
  if (canShare) {
    await Sharing.shareAsync(fileUri, {
      mimeType: "application/vnd.ms-excel",
      dialogTitle: "Bütçe Raporunu Paylaş",
      UTI: "com.microsoft.excel.xls",
    });
  }
}
