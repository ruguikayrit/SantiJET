#!/usr/bin/env node
/**
 * ŞantiJET B.F.A. — geliştirme sunucusu
 *
 * Sabit yer imi: http://localhost:24917
 * - LAN modu: aynı Wi‑Fi (telefon + bilgisayar)
 * - Tunnel modu: farklı ağ / bulut ortam (Cursor Agent otomatik tunnel)
 *
 * QR bu sayfada otomatik güncellenir; yer imi adresi değişmez.
 */
import { spawn } from "child_process";
import fs from "fs";
import http from "http";
import net from "net";
import os from "os";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(__dirname, "..");
const hostFile = path.join(projectRoot, ".expo", "ipa-dev-host");
const qrImageFile = path.join(projectRoot, "assets", "images", "expo-go-qr.png");
const qrUrlFile = path.join(projectRoot, "assets", "expo-dev-url.txt");
const metroPort = Number(process.env.PORT || 24916);
const landingPort = Number(process.env.IPA_LANDING_PORT || 24917);

/** @type {{ mode: string; expUrl: string; webUrl: string; ready: boolean; message: string; updatedAt: string }} */
let links = {
  mode: "lan",
  expUrl: "",
  webUrl: "",
  ready: false,
  message: "Sunucu başlatılıyor…",
  updatedAt: new Date().toISOString(),
};

function detectLanIp() {
  for (const ifaces of Object.values(os.networkInterfaces())) {
    for (const net of ifaces || []) {
      if (net.family === "IPv4" && !net.internal) return net.address;
    }
  }
  return "localhost";
}

function resolveNetworkMode() {
  const forced = process.env.IPA_NETWORK_MODE?.trim().toLowerCase();
  if (forced === "lan" || forced === "tunnel") return forced;
  if (process.env.IPA_USE_TUNNEL === "1") return "tunnel";
  if (process.env.CURSOR_AGENT === "1") return "tunnel";
  return "lan";
}

function resolveLanHost() {
  const fromEnv = process.env.IPA_EXPO_HOST?.trim();
  if (fromEnv) return fromEnv;
  try {
    const saved = fs.readFileSync(hostFile, "utf8").trim();
    if (saved && !saved.includes("exp.direct")) return saved;
  } catch {
    /* ignore */
  }
  const detected = detectLanIp();
  fs.mkdirSync(path.dirname(hostFile), { recursive: true });
  fs.writeFileSync(hostFile, detected);
  return detected;
}

function setLinks(partial) {
  links = { ...links, ...partial, updatedAt: new Date().toISOString() };
  if (links.ready && links.expUrl) {
    persistQrArtifacts(links.expUrl).catch((err) => {
      console.warn("[ipa-dev] QR kaydedilemedi:", err?.message || err);
    });
  }
}

async function persistQrArtifacts(expUrl) {
  fs.mkdirSync(path.dirname(qrImageFile), { recursive: true });
  fs.writeFileSync(qrUrlFile, `${expUrl}\n`);
  const qrApi =
    "https://api.qrserver.com/v1/create-qr-code/?size=512x512&margin=10&data=" +
    encodeURIComponent(expUrl);
  const res = await fetch(qrApi);
  if (!res.ok) throw new Error(`QR API ${res.status}`);
  const buf = Buffer.from(await res.arrayBuffer());
  fs.writeFileSync(qrImageFile, buf);
  console.log(`[ipa-dev] QR güncellendi: ${qrImageFile}`);
}

async function fetchNgrokTunnel() {
  try {
    const res = await fetch("http://127.0.0.1:4040/api/tunnels");
    if (!res.ok) return null;
    const data = await res.json();
    const tunnel = (data.tunnels || []).find((t) => t.proto === "https" && t.public_url);
    if (!tunnel) return null;
    const host = new URL(tunnel.public_url).host;
    return {
      expUrl: `exp://${host}`,
      webUrl: tunnel.public_url,
    };
  } catch {
    return null;
  }
}

function pollTunnel() {
  const tick = async () => {
    const t = await fetchNgrokTunnel();
    if (t) {
      const prevUrl = links.expUrl;
      const changed = Boolean(prevUrl && prevUrl !== t.expUrl);
      setLinks({
        mode: "tunnel",
        expUrl: t.expUrl,
        webUrl: t.webUrl,
        ready: true,
        message: "Tunnel hazır — telefon ve bilgisayar farklı ağda olabilir.",
      });
      if (changed || !prevUrl) {
        console.log(`[ipa-dev] Tunnel: ${t.expUrl}`);
        console.log(`[ipa-dev] Web:    ${t.webUrl}`);
      }
    }
    setTimeout(tick, 5000);
  };
  tick();
}

function landingHtml() {
  return `<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>ŞantiJET B.F.A. — Bağlantı</title>
  <style>
    * { box-sizing: border-box; }
    body {
      margin: 0; min-height: 100vh; font-family: system-ui, sans-serif;
      background: #0b1220; color: #e2e8f0; display: flex; align-items: center; justify-content: center; padding: 24px;
    }
    .card {
      max-width: 420px; width: 100%; background: #16213e; border-radius: 16px;
      padding: 28px; border: 1px solid rgba(255,255,255,0.08);
    }
    h1 { margin: 0 0 4px; font-size: 22px; color: #fff; }
    .sub { color: #94a3b8; font-size: 13px; margin-bottom: 16px; line-height: 1.4; }
    .badge {
      display: inline-block; font-size: 11px; font-weight: 700; letter-spacing: 0.5px;
      padding: 4px 10px; border-radius: 999px; margin-bottom: 16px;
      background: rgba(56,189,248,0.15); color: #38bdf8; border: 1px solid rgba(56,189,248,0.3);
    }
    .qr-wrap { text-align: center; min-height: 376px; display: flex; align-items: center; justify-content: center; }
    .qr { border-radius: 12px; background: #fff; padding: 8px; max-width: 100%; }
    .loading { color: #94a3b8; font-size: 14px; }
    label { display: block; font-size: 11px; text-transform: uppercase; letter-spacing: 1px; color: #64748b; margin-top: 14px; }
    a, code {
      display: block; word-break: break-all; color: #f97316; font-size: 13px; margin-top: 4px; text-decoration: none;
    }
    a:hover { text-decoration: underline; }
    .note {
      margin-top: 20px; padding: 12px; border-radius: 10px; background: rgba(249,115,22,0.12);
      border: 1px solid rgba(249,115,22,0.25); font-size: 12px; line-height: 1.55; color: #cbd5e1;
    }
  </style>
</head>
<body>
  <div class="card">
    <h1>ŞantiJET B.F.A.</h1>
    <p class="sub">Bu sayfayı yer imlerine ekleyin — adres değişmez, QR otomatik güncellenir.</p>
    <span class="badge" id="mode">…</span>
    <div class="qr-wrap">
      <p class="loading" id="wait">Bağlantı hazırlanıyor…</p>
      <img class="qr" id="qr" width="360" height="360" alt="Expo QR" hidden />
    </div>
    <label>Expo Go (telefon)</label>
    <code id="exp">—</code>
    <label>Web</label>
    <a id="web" href="#" target="_blank" rel="noreferrer">—</a>
    <label>Sabit yer imi</label>
    <code>http://localhost:${landingPort}</code>
    <div class="note" id="note"></div>
  </div>
  <script>
    async function refresh() {
      try {
        const r = await fetch('/api/links');
        const d = await r.json();
        document.getElementById('mode').textContent = d.mode === 'tunnel' ? 'TUNNEL · Farklı ağ OK' : 'LAN · Aynı Wi‑Fi';
        document.getElementById('note').textContent = d.message || '';
        if (d.ready && d.expUrl) {
          document.getElementById('wait').hidden = true;
          const qr = document.getElementById('qr');
          qr.hidden = false;
          qr.src = 'https://api.qrserver.com/v1/create-qr-code/?size=360x360&data=' + encodeURIComponent(d.expUrl);
          document.getElementById('exp').textContent = d.expUrl;
          const web = document.getElementById('web');
          web.textContent = d.webUrl;
          web.href = d.webUrl;
        } else {
          document.getElementById('exp').textContent = d.message || 'Hazırlanıyor…';
        }
      } catch (e) {
        document.getElementById('note').textContent = 'Sunucu bekleniyor… pnpm dev:ipa çalışıyor olmalı.';
      }
    }
    refresh();
    setInterval(refresh, 2500);
  </script>
</body>
</html>`;
}

function fetchExistingLinks() {
  return new Promise((resolve) => {
    const req = http.get(
      `http://127.0.0.1:${landingPort}/api/links`,
      { timeout: 1500 },
      (res) => {
        let body = "";
        res.on("data", (chunk) => {
          body += chunk;
        });
        res.on("end", () => {
          try {
            resolve(JSON.parse(body));
          } catch {
            resolve(null);
          }
        });
      },
    );
    req.on("error", () => resolve(null));
    req.on("timeout", () => {
      req.destroy();
      resolve(null);
    });
  });
}

function isPortOpen(port) {
  return new Promise((resolve) => {
    const socket = net.connect({ port, host: "127.0.0.1" });
    socket.once("connect", () => {
      socket.end();
      resolve(true);
    });
    socket.once("error", () => resolve(false));
    socket.setTimeout(1000, () => {
      socket.destroy();
      resolve(false);
    });
  });
}

function printBanner() {
  console.log("");
  console.log("══════════════════════════════════════════════════");
  console.log("  ŞantiJET B.F.A.");
  console.log("══════════════════════════════════════════════════");
  console.log(`  Yer imi (SABİT): http://localhost:${landingPort}`);
  console.log(`  Mod: ${links.mode.toUpperCase()}`);
  if (links.expUrl) console.log(`  Expo Go: ${links.expUrl}`);
  console.log("══════════════════════════════════════════════════");
  console.log("");
}

function startLandingServer() {
  const server = http.createServer((req, res) => {
    if (req.url === "/api/links") {
      res.writeHead(200, { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" });
      res.end(JSON.stringify(links));
      return;
    }
    res.writeHead(200, { "content-type": "text/html; charset=utf-8", "cache-control": "no-store" });
    res.end(landingHtml());
  });

  server.on("error", (err) => {
    if (err.code === "EADDRINUSE") {
      console.warn(`[ipa-dev] Yer imi portu (${landingPort}) kullanımda — mevcut sunucu korunuyor.`);
      return;
    }
    console.error("[ipa-dev] Yer imi sunucusu hatası:", err.message);
    process.exit(1);
  });

  server.listen(landingPort, "0.0.0.0", () => {
    printBanner();
  });
  return server;
}

async function startMetro(mode, host) {
  const stub = path.join(projectRoot, "scripts", "fix-expo-router-stub.js");

  if (await isPortOpen(metroPort)) {
    const existing = await fetchExistingLinks();
    console.warn(`[ipa-dev] Metro zaten çalışıyor (port ${metroPort}).`);
    if (existing?.expUrl) {
      setLinks({
        mode: existing.mode || links.mode,
        expUrl: existing.expUrl,
        webUrl: existing.webUrl || links.webUrl,
        ready: true,
        message: "Mevcut geliştirme sunucusu kullanılıyor.",
      });
      console.log(`[ipa-dev] Expo Go: ${existing.expUrl}`);
    }
    printBanner();
    if (mode === "tunnel") pollTunnel();
    return;
  }

  function launchMetro(attempt = 1) {
    const args = ["exec", "expo", "start", "--port", String(metroPort)];
    if (attempt === 1) args.push("--clear");
    if (mode === "tunnel") args.push("--tunnel");
    else args.push("--lan");

    const env = {
      ...process.env,
      EXPO_NO_DEPENDENCY_VALIDATION: "1",
      ...(mode === "lan" ? { REACT_NATIVE_PACKAGER_HOSTNAME: host } : {}),
    };

    const child = spawn("pnpm", args, { cwd: projectRoot, stdio: "inherit", env, shell: false });
    child.on("exit", (code) => {
      if (code === 0 || code === null) {
        process.exit(0);
        return;
      }
      const waitMs = Math.min(attempt * 3000, 20000);
      console.warn(`[ipa-dev] Metro kapandı (kod ${code}). ${waitMs / 1000}s sonra yeniden denenecek…`);
      setTimeout(() => launchMetro(attempt + 1), waitMs);
    });
  }

  spawn("node", [stub], { cwd: projectRoot, stdio: "inherit", shell: false }).on("close", () => {
    launchMetro();
  });
}

const mode = resolveNetworkMode();

async function main() {
  const forceRestart = process.env.IPA_DEV_FORCE === "1";
  const existingLinks = await fetchExistingLinks();
  const metroRunning = await isPortOpen(metroPort);

  if (!forceRestart && existingLinks?.ready && metroRunning) {
    setLinks({
      mode: existingLinks.mode || mode,
      expUrl: existingLinks.expUrl,
      webUrl: existingLinks.webUrl,
      ready: true,
      message: "Geliştirme sunucusu zaten çalışıyor.",
    });
    console.log("[ipa-dev] Sunucu zaten aktif — yeniden başlatmak için IPA_DEV_FORCE=1 kullanın.");
    console.log(`[ipa-dev] Yer imi: http://localhost:${landingPort}`);
    if (existingLinks.expUrl) console.log(`[ipa-dev] Expo Go: ${existingLinks.expUrl}`);
    if (mode === "tunnel") pollTunnel();
    return;
  }

  if (mode === "tunnel") {
    setLinks({
      mode: "tunnel",
      ready: false,
      message: "Tunnel açılıyor… Telefon farklı ağda olsa da bağlanabilir.",
    });
    pollTunnel();
  } else {
    const host = resolveLanHost();
    const webUrl = `http://${host === "0.0.0.0" ? "localhost" : host}:${metroPort}`;
    setLinks({
      mode: "lan",
      expUrl: `exp://${host}:${metroPort}`,
      webUrl,
      ready: true,
      message: "LAN modu — telefon bilgisayarla aynı Wi‑Fi ağında olmalı.",
    });
    console.log(`[ipa-dev] LAN host: ${host}`);
  }

  startLandingServer();
  await startMetro(mode, mode === "lan" ? resolveLanHost() : "");
}

main().catch((err) => {
  console.error("[ipa-dev] Başlatma hatası:", err);
  process.exit(1);
});

process.on("SIGINT", () => process.exit(0));
process.on("SIGTERM", () => process.exit(0));
