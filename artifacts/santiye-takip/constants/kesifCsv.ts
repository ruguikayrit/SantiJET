import type { Survey, SurveyItem } from "@/context/AppContext";

export interface ParsedKesifRow {
  projectName: string;
  title: string;
  surveyDate: string;
  surveyNotes: string;
  pozCode: string;
  pozCategory: string;
  description: string;
  unit: string;
  quantity: number;
  itemDate: string;
}

export interface KesifCsvParseResult {
  rows: ParsedKesifRow[];
  errors: string[];
}

function detectSeparator(line: string): string {
  if (line.includes(";")) return ";";
  if (line.includes("\t")) return "\t";
  return ",";
}

function splitCsvLine(line: string, sep: string): string[] {
  const out: string[] = [];
  let cur = "";
  let inQuotes = false;
  for (let i = 0; i < line.length; i++) {
    const ch = line[i];
    if (ch === '"') {
      if (inQuotes && line[i + 1] === '"') {
        cur += '"';
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (ch === sep && !inQuotes) {
      out.push(cur);
      cur = "";
    } else {
      cur += ch;
    }
  }
  out.push(cur);
  return out;
}

const HEADER_ALIASES: Record<string, string> = {
  proje: "projectName",
  "proje adi": "projectName",
  "proje adı": "projectName",
  project: "projectName",
  baslik: "title",
  başlık: "title",
  title: "title",
  "kesif baslik": "title",
  "keşif başlığı": "title",
  tarih: "surveyDate",
  "kesif tarih": "surveyDate",
  "keşif tarihi": "surveyDate",
  aciklama: "surveyNotes",
  açıklama: "surveyNotes",
  notlar: "surveyNotes",
  "kesif aciklama": "surveyNotes",
  poz: "pozCode",
  "poz kodu": "pozCode",
  "poz no": "pozCode",
  poz_kodu: "pozCode",
  kategori: "pozCategory",
  "poz kategori": "pozCategory",
  poz_kategori: "pozCategory",
  imalat: "description",
  "imalat adi": "description",
  "imalat adı": "description",
  "kalem aciklama": "description",
  "kalem açıklama": "description",
  kalem_aciklama: "description",
  birim: "unit",
  unit: "unit",
  metraj: "quantity",
  miktar: "quantity",
  quantity: "quantity",
  "kalem tarih": "itemDate",
  "kalem tarihi": "itemDate",
  kalem_tarih: "itemDate",
  "imalat tarih": "itemDate",
};

function normalizeHeader(h: string): string | null {
  const k = h.trim().toLowerCase().replace(/\s+/g, " ");
  return HEADER_ALIASES[k] || null;
}

const DEFAULT_ORDER = [
  "projectName",
  "title",
  "surveyDate",
  "surveyNotes",
  "pozCode",
  "pozCategory",
  "description",
  "unit",
  "quantity",
  "itemDate",
];

export function parseKesifCsv(text: string): KesifCsvParseResult {
  const rows: ParsedKesifRow[] = [];
  const errors: string[] = [];
  const cleaned = text.replace(/^\uFEFF/, "").replace(/\r/g, "");
  const lines = cleaned.split("\n").filter((l) => l.trim().length > 0);
  if (lines.length === 0) return { rows, errors };

  const sep = detectSeparator(lines[0]);
  let order = DEFAULT_ORDER;
  let startIdx = 0;
  const headerCells = splitCsvLine(lines[0], sep).map((c) => normalizeHeader(c));
  if (headerCells.some((c) => c !== null)) {
    order = headerCells.map((c, i) => c || DEFAULT_ORDER[i] || "");
    startIdx = 1;
  }

  for (let i = startIdx; i < lines.length; i++) {
    const lineNo = i + 1;
    const cells = splitCsvLine(lines[i], sep);
    const get = (key: string) => {
      const idx = order.indexOf(key);
      return idx >= 0 ? (cells[idx] || "").trim() : "";
    };
    const projectName = get("projectName");
    const title = get("title");
    const description = get("description");
    const unit = get("unit");
    const quantityStr = get("quantity").replace(",", ".");
    const quantity = parseFloat(quantityStr) || 0;

    if (!projectName || !title) {
      errors.push(`Satır ${lineNo}: Proje ve başlık zorunlu.`);
      continue;
    }
    if (!description) {
      errors.push(`Satır ${lineNo}: İmalat / açıklama boş.`);
      continue;
    }

    rows.push({
      projectName,
      title,
      surveyDate: get("surveyDate"),
      surveyNotes: get("surveyNotes"),
      pozCode: get("pozCode"),
      pozCategory: get("pozCategory"),
      description,
      unit,
      quantity,
      itemDate: get("itemDate"),
    });
  }
  return { rows, errors };
}

export function buildKesifCsv(
  surveys: Survey[],
  projects: { id: string; name: string }[],
): string {
  const projMap = new Map(projects.map((p) => [p.id, p.name]));
  const esc = (s: string) => {
    if (s.includes(";") || s.includes('"') || s.includes("\n")) {
      return `"${s.replace(/"/g, '""')}"`;
    }
    return s;
  };
  const header =
    "proje;baslik;tarih;aciklama;poz_kodu;poz_kategori;kalem_aciklama;birim;metraj;kalem_tarih";
  const lines: string[] = [];
  for (const s of surveys) {
    const projName = projMap.get(s.projectId) || "";
    if (s.items.length === 0) {
      lines.push(
        [projName, s.title, s.date || "", (s.notes || "").replace(/\n/g, " "), "", "", "", "", "", ""]
          .map(esc)
          .join(";"),
      );
      continue;
    }
    for (const it of s.items) {
      lines.push(
        [
          projName,
          s.title,
          s.date || "",
          (s.notes || "").replace(/\n/g, " "),
          it.pozCode || "",
          it.pozCategory || "",
          it.description,
          it.unit,
          String(it.quantity || 0),
          it.date || "",
        ]
          .map(esc)
          .join(";"),
      );
    }
  }
  return "\uFEFF" + [header, ...lines].join("\n");
}

export interface ApplyKesifResult {
  createdSurveys: number;
  updatedSurveys: number;
  addedItems: number;
  missingProjects: string[];
}

export function groupRowsByProjectAndTitle(
  rows: ParsedKesifRow[],
  projects: { id: string; name: string }[],
): {
  groups: Map<string, { projectId: string; title: string; rows: ParsedKesifRow[] }>;
  missingProjects: string[];
} {
  const norm = (s: string) => s.trim().toLowerCase();
  const projByName = new Map(projects.map((p) => [norm(p.name), p]));
  const groups = new Map<
    string,
    { projectId: string; title: string; rows: ParsedKesifRow[] }
  >();
  const missing = new Set<string>();
  for (const r of rows) {
    const proj = projByName.get(norm(r.projectName));
    if (!proj) {
      missing.add(r.projectName);
      continue;
    }
    const key = `${proj.id}::${norm(r.title)}`;
    const g = groups.get(key);
    if (g) g.rows.push(r);
    else groups.set(key, { projectId: proj.id, title: r.title, rows: [r] });
  }
  return { groups, missingProjects: Array.from(missing) };
}

export function rowToSurveyItem(r: ParsedKesifRow, idSuffix: number): SurveyItem {
  return {
    id: `${Date.now()}_${idSuffix}_${Math.random().toString(36).slice(2, 7)}`,
    description: r.description,
    unit: r.unit,
    quantity: r.quantity,
    unitPrice: 0,
    pozCode: r.pozCode || undefined,
    pozCategory: r.pozCategory || undefined,
    date: r.itemDate || undefined,
  };
}
