#!/usr/bin/env node
/**
 * MGM (mgm.gov.tr) il istasyon haritası + hava önbelleği üretici.
 * Kullanım:
 *   node fetch-mgm-weather.mjs stations   → lib/.../mgm_stations.dart
 *   node fetch-mgm-weather.mjs cache      → web/weather/mgm.json
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, '../..');
const PUANTAJ = path.join(ROOT, 'artifacts/santijet-puantaj');
const CACHE_OUT = path.join(ROOT, 'data/mgm-weather/mgm.json');
const MGM_ORIGIN = 'https://www.mgm.gov.tr';
const MGM_HEADERS = {
  Origin: MGM_ORIGIN,
  Referer: `${MGM_ORIGIN}/`,
  Accept: 'application/json',
};

const HADISE = {
  A: 'Açık',
  AB: 'Az bulutlu',
  PB: 'Parçalı bulutlu',
  CBS: 'Çok bulutlu',
  KAP: 'Kapalı',
  HY: 'Hafif yağmurlu',
  Y: 'Yağmurlu',
  YAG: 'Yağmurlu',
  KY: 'Kuvvetli yağmurlu',
  SY: 'Sağanak yağışlı',
  HSY: 'Hafif sağanak',
  MSY: 'Orta sağanak',
  KSY: 'Kuvvetli sağanak',
  YSY: 'Yer yer sağanak',
  GSY: 'Gökgürültülü sağanak',
  GOK: 'Gökgürültülü',
  KGY: 'Kuvvetli gök gürültülü',
  KYŞ: 'Kuvvetli yağış',
  KSYG: 'Kuvvetli sağanak',
  SCK: 'Sıcak',
  SGK: 'Soğuk',
  PUS: 'Puslu',
  SIS: 'Sisli',
  DMN: 'Dumanlı',
  KF: 'Kum fırtınası',
  TOZ: 'Tozlu',
  RZL: 'Rüzgarlı',
  Kar: 'Karlı',
  KRLH: 'Karla karışık yağmur',
  DKH: 'Dolu',
  GUS: 'Güneyli rüzgar',
};

function hadiseLabel(code) {
  if (!code || code === '-9999') return 'Değişken';
  const key = String(code).trim().toUpperCase();
  return HADISE[key] ?? HADISE[code] ?? String(code);
}

function num(v) {
  if (v == null) return null;
  const n = Number(v);
  if (!Number.isFinite(n) || n <= -9000) return null;
  return n;
}

async function mgmGet(url, { retries = 3 } = {}) {
  let lastErr;
  for (let i = 0; i < retries; i++) {
    try {
      const res = await fetch(url, { headers: MGM_HEADERS });
      if (res.status === 503 || res.status === 429) {
        await new Promise((r) => setTimeout(r, 400 * (i + 1)));
        lastErr = new Error(`HTTP ${res.status} ${url}`);
        continue;
      }
      if (!res.ok) throw new Error(`HTTP ${res.status} ${url}`);
      return res.json();
    } catch (e) {
      lastErr = e;
      await new Promise((r) => setTimeout(r, 300 * (i + 1)));
    }
  }
  throw lastErr ?? new Error(`failed ${url}`);
}

async function loadStations() {
  const iller = await mgmGet('https://servis.mgm.gov.tr/web/merkezler/iller');
  const by = {};
  for (const x of iller) {
    const p = String(x.ilPlaka).padStart(2, '0');
    if (!by[p] || x.oncelik === 1) {
      by[p] = {
        merkezId: x.merkezId,
        gunlukIstNo: x.gunlukTahminIstNo,
        name: x.il,
      };
    }
  }
  return by;
}

function writeStationsDart(by) {
  const out = path.join(PUANTAJ, 'lib/domain/catalogs/mgm_stations.dart');
  const keys = Object.keys(by).sort();
  let body =
    '/// MGM il merkezleri — plaka → merkezId / günlük tahmin istasyonu.\n' +
    '/// Kaynak: servis.mgm.gov.tr/web/merkezler/iller\n' +
    'class MgmStation {\n' +
    '  const MgmStation({required this.merkezId, required this.gunlukIstNo});\n' +
    '  final int merkezId;\n' +
    '  final int gunlukIstNo;\n' +
    '}\n\n' +
    'const mgmStationsByPlate = <String, MgmStation>{\n';
  for (const k of keys) {
    body +=
      `  '${k}': MgmStation(merkezId: ${by[k].merkezId}, gunlukIstNo: ${by[k].gunlukIstNo}),\n`;
  }
  body += '};\n';
  fs.mkdirSync(path.dirname(out), { recursive: true });
  fs.writeFileSync(out, body);
  console.log('Wrote', out, `(${keys.length} cities)`);
}

async function fetchCityWeather(station) {
  const [sondurumRaw, gunlukRaw] = await Promise.all([
    mgmGet(
      `https://servis.mgm.gov.tr/web/sondurumlar?merkezid=${station.merkezId}`,
    ),
    mgmGet(
      `https://servis.mgm.gov.tr/web/tahminler/gunluk?istno=${station.gunlukIstNo}`,
    ),
  ]);
  const s = Array.isArray(sondurumRaw) ? sondurumRaw[0] : sondurumRaw;
  const g = Array.isArray(gunlukRaw) ? gunlukRaw[0] : gunlukRaw;
  if (!s) throw new Error(`sondurum empty ${station.merkezId}`);

  const night =
    num(g?.enDusukGun0) ?? num(g?.enDusukGun1) ?? null;
  const code = s.hadiseKodu ?? g?.hadiseGun0 ?? '';

  return {
    name: station.name,
    temperatureC: num(s.sicaklik),
    nightTemperatureC: night,
    humidityPercent: num(s.nem),
    description: hadiseLabel(code),
    windKmh: num(s.ruzgarHiz),
    observedAt: s.veriZamani ?? null,
    hadiseKodu: code || null,
  };
}

async function writeCache(by) {
  const cities = {};
  const plates = Object.keys(by).sort();
  let ok = 0;
  let fail = 0;
  // Sıralı + hafif gecikme — MGM rate limit riskini azaltır.
  for (const plate of plates) {
    try {
      cities[plate] = await fetchCityWeather(by[plate]);
      ok++;
      process.stdout.write('.');
    } catch (e) {
      fail++;
      console.error(`\n${plate} failed:`, e.message || e);
    }
    await new Promise((r) => setTimeout(r, 150));
  }
  console.log('');

  const payload = {
    updatedAt: new Date().toISOString(),
    source: 'mgm.gov.tr',
    cities,
  };
  const out = CACHE_OUT;
  fs.mkdirSync(path.dirname(out), { recursive: true });
  fs.writeFileSync(out, JSON.stringify(payload, null, 2));
  // Flutter web build'e gömülü kopya (deploy anındaki anlık görüntü).
  const webCopy = path.join(PUANTAJ, 'web/weather/mgm.json');
  fs.mkdirSync(path.dirname(webCopy), { recursive: true });
  fs.writeFileSync(webCopy, JSON.stringify(payload, null, 2));
  console.log(`Wrote ${out} (ok=${ok}, fail=${fail})`);
  console.log(`Copied ${webCopy}`);
}

const mode = process.argv[2] || 'cache';
const stations = await loadStations();
if (mode === 'stations') {
  writeStationsDart(stations);
} else if (mode === 'cache') {
  writeStationsDart(stations);
  await writeCache(stations);
} else if (mode === 'both') {
  writeStationsDart(stations);
  await writeCache(stations);
} else {
  console.error('Usage: node fetch-mgm-weather.mjs [stations|cache|both]');
  process.exit(1);
}
