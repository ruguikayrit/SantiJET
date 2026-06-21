import * as FileSystem from "expo-file-system/legacy";
import * as XLSX from "xlsx";
import { Alert, Platform } from "react-native";

import { BfaDiscipline } from "@/constants/bfaModules";
import { IMALAT_POZ_KATEGORILERI, PozAnaliz, normalizeTrSearch } from "@/constants/pozAnalizleri";

export interface KesifImportRow {
  pozNo: string;
  analizAdi: string;
  olcuBirimi: string;
  miktar: number;
  birimFiyati?: number;
  projeAdi?: string;
  aciklama?: string;
}

export interface KesifImportParseResult {
  rows: KesifImportRow[];
  projectName?: string;
  projectAciklama?: string;
  errors: string[];
  sourceLabel: string;
}

export interface KesifImportMatchResult {
  matched: { row: KesifImportRow; analiz: PozAnaliz }[];
  unmatched: KesifImportRow[];
}

const HEADER_ALIASES: Record<string, keyof KesifImportRow | "sira" | "projeAdi" | "aciklama"> = {
  "#": "sira",
  sira: "sira",
  "sıra": "sira",
  no: "sira",
  "poz no": "pozNo",
  poz: "pozNo",
  "poz no.": "pozNo",
  pozno: "pozNo",
  "poz_kodu": "pozNo",
  "poz kodu": "pozNo",
  "poz numarası": "pozNo",
  "poz numarasi": "pozNo",
  tanim: "analizAdi",
  tanım: "analizAdi",
  aciklama: "analizAdi",
  açıklama: "analizAdi",
  "analiz adi": "analizAdi",
  "analiz adı": "analizAdi",
  "kalem aciklama": "analizAdi",
  "kalem açıklama": "analizAdi",
  kalem_aciklama: "analizAdi",
  description: "analizAdi",
  imalat: "analizAdi",
  birim: "olcuBirimi",
  unit: "olcuBirimi",
  "ölçü birimi": "olcuBirimi",
  "olcu birimi": "olcuBirimi",
  miktar: "miktar",
  metraj: "miktar",
  quantity: "miktar",
  qty: "miktar",
  "birim fiyat": "birimFiyati",
  "birim fiyat (tl)": "birimFiyati",
  "birim fiyati": "birimFiyati",
  "birim fiyatı": "birimFiyati",
  "unit price": "birimFiyati",
  bf: "birimFiyati",
  proje: "projeAdi",
  "proje adi": "projeAdi",
  "proje adı": "projeAdi",
  project: "projeAdi",
  not: "aciklama",
  notlar: "aciklama",
  "proje aciklama": "aciklama",
  "proje açıklama": "aciklama",
};

const SKIP_ROW_MARKERS = ["genel toplam", "toplam", "metraj / keşif", "metraj / kesif", "henüz poz"];

const KATEGORI_KEYWORDS: { kategori: (typeof IMALAT_POZ_KATEGORILERI)[number]; words: string[] }[] = [
  { kategori: "Hafriyat ve Toprak", words: ["hafriyat", "kazı", "kazi", "toprak", "dolgu", "sergi"] },
  { kategori: "Beton ve Demir", words: ["beton", "demir", "donatı", "donati", "çimento", "cimento"] },
  { kategori: "Kalıp", words: ["kalıp", "kalip", "iskele"] },
  { kategori: "Duvar", words: ["duvar", "gazbeton", "briket", "tuğla", "tugla"] },
  { kategori: "Sıva ve Şap", words: ["sıva", "siva", "şap", "sap", "alçı", "alci"] },
  { kategori: "Yalıtım", words: ["yalıtım", "yalitim", "izolasyon", "xps", "eps", "bitümlü", "bitumlu"] },
  { kategori: "Çatı", words: ["çatı", "cati", "kiremit", "membran"] },
  { kategori: "Kaplama", words: ["kaplama", "seramik", "fayans", "granit", "parke", "laminat"] },
  { kategori: "Boya", words: ["boya", "badana", "astar"] },
  { kategori: "Doğrama", words: ["doğrama", "dograma", "kapı", "kapi", "pencere", "pvc", "alüminyum"] },
  { kategori: "Sıhhi Tesisat", words: ["lavabo", "klozet", "sihhi", "su tesisat", "batarya", "rezervuar"] },
  { kategori: "Elektrik", words: ["elektrik", "kablo", "pano", "aydinlatma", "aydınlatma", "priz", "sigorta"] },
  { kategori: "Mekanik Tesisat", words: ["mekanik", "klima", "fan", "havalandırma", "havalandirma", "kazan", "boru"] },
  { kategori: "Asansör", words: ["asansör", "asansor"] },
  { kategori: "Cephe", words: ["cephe", "giydirme", "kompozit"] },
  { kategori: "Çevre Düzenleme", words: ["çevre", "cevre", "peyzaj", "bahçe", "bahce"] },
  { kategori: "Yıkım ve Söküm", words: ["yıkım", "yikim", "söküm", "sokum", "kırım", "kirim"] },
  { kategori: "Çelik Yapı", words: ["çelik", "celik", "profil", "konstrüksiyon"] },
  { kategori: "Altyapı", words: ["altyapı", "altyapi", "kanalizasyon", "atık su"] },
  { kategori: "Peyzaj", words: ["peyzaj", "çim", "cim", "fidan", "ağaç"] },
];

function normalizeHeader(value: unknown): keyof KesifImportRow | "sira" | "projeAdi" | "aciklama" | null {
  const text = String(value ?? "")
    .trim()
    .toLowerCase()
    .replace(/\s+/g, " ");
  return HEADER_ALIASES[text] ?? null;
}

export function normalizeImportPozNo(pozNo: string): string {
  const trimmed = pozNo.trim();
  if (/^\d{2}\.\d{3}\.\d{4}$/.test(trimmed)) return trimmed;

  const digits = trimmed.replace(/\D/g, "");
  if (digits.length >= 9) {
    return `${digits.slice(0, 2)}.${digits.slice(2, 5)}.${digits.slice(5, 9)}`;
  }

  return trimmed;
}

export function inferDisciplineFromPoz(pozNo: string): BfaDiscipline {
  const digits = pozNo.replace(/\D/g, "");
  const prefix = digits.slice(0, 2);
  if (prefix === "35") return "elektrik";
  if (prefix === "25") return "mekanik";
  return "insaat";
}

export function inferKategoriFromImportRow(
  pozNo: string,
  analizAdi: string,
  discipline: BfaDiscipline,
): (typeof IMALAT_POZ_KATEGORILERI)[number] {
  const desc = normalizeTrSearch(`${pozNo} ${analizAdi}`);

  if (discipline === "elektrik") return "Elektrik";
  if (discipline === "mekanik") {
    if (/(lavabo|klozet|sihhi|batarya|rezervuar|su tesisat)/i.test(desc)) return "Sıhhi Tesisat";
    return "Mekanik Tesisat";
  }

  for (const entry of KATEGORI_KEYWORDS) {
    if (entry.words.some((word) => desc.includes(normalizeTrSearch(word)))) {
      return entry.kategori;
    }
  }

  return "Diğer";
}

function parseNumber(value: unknown): number {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  const text = String(value ?? "")
    .trim()
    .replace(/\s/g, "")
    .replace(/₺/g, "")
    .replace(/\./g, "")
    .replace(",", ".");
  const n = parseFloat(text);
  return Number.isFinite(n) ? n : 0;
}

function shouldSkipRow(values: string[]): boolean {
  const joined = values.join(" ").trim();
  if (!joined) return true;
  const lower = normalizeTrSearch(joined);
  return SKIP_ROW_MARKERS.some((m) => lower.includes(m));
}

function mapMatrixToRows(matrix: unknown[][], sourceLabel: string): KesifImportParseResult {
  const errors: string[] = [];
  const rows: KesifImportRow[] = [];
  if (!matrix.length) {
    return { rows, errors: ["Dosyada veri bulunamadı."], sourceLabel };
  }

  let headerMap: Array<keyof KesifImportRow | "sira" | "projeAdi" | "aciklama" | null> = [];
  let startIdx = 0;

  const firstRow = matrix[0]?.map((c) => String(c ?? "")) ?? [];
  const normalizedHeaders = firstRow.map((cell) => normalizeHeader(cell));
  if (normalizedHeaders.some((h) => h && h !== "sira")) {
    headerMap = normalizedHeaders;
    startIdx = 1;
  } else {
    headerMap = ["sira", "pozNo", "analizAdi", "olcuBirimi", "miktar", "birimFiyati", null];
  }

  let projectName: string | undefined;
  let projectAciklama: string | undefined;

  for (let i = startIdx; i < matrix.length; i += 1) {
    const line = matrix[i]?.map((c) => String(c ?? "").trim()) ?? [];
    if (shouldSkipRow(line)) continue;

    const get = (key: keyof KesifImportRow | "projeAdi" | "aciklama") => {
      const idx = headerMap.indexOf(key);
      return idx >= 0 ? (line[idx] ?? "").trim() : "";
    };

    const pozNo = get("pozNo");
    const analizAdi = get("analizAdi");
    const olcuBirimi = get("olcuBirimi") || "Ad";
    const miktar = parseNumber(get("miktar"));
    const birimFiyatiRaw = get("birimFiyati");
    const birimFiyati = birimFiyatiRaw ? parseNumber(birimFiyatiRaw) : undefined;
    const projeAdi = get("projeAdi");
    const aciklama = get("aciklama");

    if (!pozNo && !analizAdi) continue;
    if (!analizAdi && !pozNo) {
      errors.push(`Satır ${i + 1}: Tanım veya poz no gerekli.`);
      continue;
    }

    if (projeAdi && !projectName) projectName = projeAdi;
    if (aciklama && !projectAciklama) projectAciklama = aciklama;

    rows.push({
      pozNo: pozNo || "ÖZEL",
      analizAdi: analizAdi || pozNo,
      olcuBirimi,
      miktar,
      birimFiyati,
      projeAdi: projeAdi || undefined,
      aciklama: aciklama || undefined,
    });
  }

  if (!rows.length && !errors.length) {
    errors.push("İçe aktarılabilir satır bulunamadı.");
  }

  return { rows, projectName, projectAciklama, errors, sourceLabel };
}

function parseHtmlTableRows(html: string): unknown[][] {
  const rows: unknown[][] = [];
  const trRegex = /<tr[^>]*>([\s\S]*?)<\/tr>/gi;
  let trMatch: RegExpExecArray | null;
  while ((trMatch = trRegex.exec(html)) !== null) {
    const cells: string[] = [];
    const cellRegex = /<t[dh][^>]*>([\s\S]*?)<\/t[dh]>/gi;
    let cellMatch: RegExpExecArray | null;
    while ((cellMatch = cellRegex.exec(trMatch[1])) !== null) {
      const text = cellMatch[1]
        .replace(/<[^>]+>/g, " ")
        .replace(/&nbsp;/g, " ")
        .replace(/&amp;/g, "&")
        .replace(/&lt;/g, "<")
        .replace(/&gt;/g, ">")
        .replace(/\s+/g, " ")
        .trim();
      cells.push(text);
    }
    if (cells.length) rows.push(cells);
  }
  return rows;
}

function parseCsvMatrix(text: string): unknown[][] {
  const cleaned = text.replace(/^\uFEFF/, "").replace(/\r/g, "");
  const lines = cleaned.split("\n").filter((l) => l.trim().length > 0);
  if (!lines.length) return [];

  const detectSep = (line: string) => {
    if (line.includes(";")) return ";";
    if (line.includes("\t")) return "\t";
    return ",";
  };
  const sep = detectSep(lines[0]);

  return lines.map((line) => {
    const cells: string[] = [];
    let cur = "";
    let inQuotes = false;
    for (let i = 0; i < line.length; i += 1) {
      const ch = line[i];
      if (ch === '"') {
        if (inQuotes && line[i + 1] === '"') {
          cur += '"';
          i += 1;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch === sep && !inQuotes) {
        cells.push(cur);
        cur = "";
      } else {
        cur += ch;
      }
    }
    cells.push(cur);
    return cells;
  });
}

function parseWorkbookBuffer(buffer: ArrayBuffer, sourceLabel: string): KesifImportParseResult {
  try {
    const textAttempt = new TextDecoder("utf-8").decode(buffer).trim();
    if (textAttempt.startsWith("<") && /<table/i.test(textAttempt)) {
      return mapMatrixToRows(parseHtmlTableRows(textAttempt), sourceLabel);
    }

    const workbook = XLSX.read(buffer, { type: "array", raw: false });
    const sheetName = workbook.SheetNames[0];
    if (!sheetName) {
      return { rows: [], errors: ["Excel dosyasında sayfa bulunamadı."], sourceLabel };
    }
    const sheet = workbook.Sheets[sheetName];
    const matrix = XLSX.utils.sheet_to_json(sheet, { header: 1, defval: "" }) as unknown[][];
    return mapMatrixToRows(matrix, sourceLabel);
  } catch {
    return { rows: [], errors: ["Excel dosyası okunamadı."], sourceLabel };
  }
}

export function parseKesifImportContent(
  content: string | ArrayBuffer,
  fileName: string,
): KesifImportParseResult {
  const lowerName = fileName.toLowerCase();
  const sourceLabel = fileName;

  if (typeof content === "string") {
    const trimmed = content.trim();
    if (trimmed.startsWith("<") && /<table/i.test(trimmed)) {
      return mapMatrixToRows(parseHtmlTableRows(trimmed), sourceLabel);
    }
    if (lowerName.endsWith(".csv") || lowerName.endsWith(".txt") || !trimmed.startsWith("<")) {
      return mapMatrixToRows(parseCsvMatrix(trimmed), sourceLabel);
    }
  }

  const buffer =
    typeof content === "string"
      ? Uint8Array.from(content, (c) => c.charCodeAt(0)).buffer
      : content;

  return parseWorkbookBuffer(buffer, sourceLabel);
}

export function matchImportRows(rows: KesifImportRow[], catalog: PozAnaliz[]): KesifImportMatchResult {
  const byPoz = new Map<string, PozAnaliz>();
  for (const analiz of catalog) {
    byPoz.set(normalizeImportPozNo(analiz.pozNo), analiz);
  }

  const matched: { row: KesifImportRow; analiz: PozAnaliz }[] = [];
  const unmatched: KesifImportRow[] = [];

  for (const row of rows) {
    const key = normalizeImportPozNo(row.pozNo);
    const analiz = byPoz.get(key);
    if (analiz) {
      matched.push({ row, analiz });
    } else {
      unmatched.push(row);
    }
  }

  return { matched, unmatched };
}

export function buildCatalogAnalizFromImportRow(row: KesifImportRow): Omit<
  PozAnaliz,
  "id" | "olusturmaTarihi" | "guncellemeTarihi"
> {
  const pozNo = normalizeImportPozNo(row.pozNo) || row.pozNo.trim() || "ÖZEL";
  const discipline = inferDisciplineFromPoz(pozNo);
  const kategori = inferKategoriFromImportRow(pozNo, row.analizAdi, discipline);
  const birimFiyati = row.birimFiyati && row.birimFiyati > 0 ? row.birimFiyati : 0;

  return {
    pozNo,
    analizAdi: row.analizAdi.trim() || pozNo,
    olcuBirimi: row.olcuBirimi.trim() || "Ad",
    kategori,
    kalemler: [],
    pozTarifi: "",
    yapimSartlari: "",
    olcusu: "",
    malzemeIscilikToplami: birimFiyati > 0 ? birimFiyati : 0,
    yukleniciKarOrani: 25,
    yukleniciKarTutari: 0,
    birimFiyati: birimFiyati > 0 ? birimFiyati : 0,
    kaynakTip: "kullanici",
    discipline,
    notlar: "Keşif içe aktarma ile oluşturuldu.",
  };
}

function base64ToArrayBuffer(base64: string): ArrayBuffer {
  const raw = atob(base64);
  const bytes = new Uint8Array(raw.length);
  for (let i = 0; i < raw.length; i += 1) bytes[i] = raw.charCodeAt(i);
  return bytes.buffer;
}

export async function readKesifImportFile(uri: string, fileName: string): Promise<string | ArrayBuffer> {
  const lower = fileName.toLowerCase();
  const isText =
    lower.endsWith(".csv") ||
    lower.endsWith(".txt") ||
    lower.endsWith(".htm") ||
    lower.endsWith(".html");

  if (Platform.OS === "web") {
    const response = await fetch(uri);
    if (isText) return response.text();
    return response.arrayBuffer();
  }

  if (isText) {
    return FileSystem.readAsStringAsync(uri, { encoding: FileSystem.EncodingType.UTF8 });
  }

  const base64 = await FileSystem.readAsStringAsync(uri, {
    encoding: FileSystem.EncodingType.Base64,
  });
  return base64ToArrayBuffer(base64);
}

export async function pickKesifImportFile(): Promise<{ uri: string; name: string } | null> {
  try {
    const DocumentPicker = await import("expo-document-picker");
    const result = await DocumentPicker.getDocumentAsync({
      type: [
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "application/vnd.ms-excel",
        "text/csv",
        "text/comma-separated-values",
        "text/plain",
        "*/*",
      ],
      copyToCacheDirectory: true,
      multiple: false,
    });

    if (result.canceled || !result.assets?.[0]?.uri) return null;
    const asset = result.assets[0];
    return { uri: asset.uri, name: asset.name || "kesif_import.xlsx" };
  } catch {
    Alert.alert("Hata", "Dosya seçilemedi. Lütfen tekrar deneyin.");
    return null;
  }
}

export function mergeImportRowsByPoz(rows: KesifImportRow[]): KesifImportRow[] {
  const map = new Map<string, KesifImportRow>();
  for (const row of rows) {
    const key = `${normalizeImportPozNo(row.pozNo)}|${normalizeTrSearch(row.analizAdi)}`;
    const existing = map.get(key);
    if (!existing) {
      map.set(key, { ...row });
      continue;
    }
    existing.miktar += row.miktar;
    if (!existing.birimFiyati && row.birimFiyati) existing.birimFiyati = row.birimFiyati;
  }
  return Array.from(map.values());
}

export function defaultImportProjectName(fileName: string, parsed?: KesifImportParseResult): string {
  if (parsed?.projectName?.trim()) return parsed.projectName.trim();
  const base = fileName.replace(/\.[^.]+$/, "").replace(/[_-]+/g, " ").trim();
  return base || "İçe Aktarılan Keşif";
}
