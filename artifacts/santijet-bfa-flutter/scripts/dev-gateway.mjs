#!/usr/bin/env node
/**
 * ŞantiJET BFA Flutter — telefon Safari erişimi
 *
 * - Statik web: build/web (port BFA_WEB_PORT, varsayılan 24918)
 * - Yer imi / QR: BFA_LANDING_PORT (varsayılan 24919)
 * - Tunnel: CURSOR_AGENT=1 iken @expo/ngrok ile public HTTPS URL
 */
import { spawn } from "child_process";
import fs from "fs";
import http from "http";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(__dirname, "..");
const webRoot = path.join(projectRoot, "build", "web");
const urlFile = path.join(projectRoot, "assets", "bfa-web-url.txt");

const webPort = Number(process.env.BFA_WEB_PORT || 24918);
const landingPort = Number(process.env.BFA_LANDING_PORT || 24919);
const useTunnel =
  process.env.BFA_USE_TUNNEL === "1" ||
  process.env.CURSOR_AGENT === "1" ||
  process.env.BFA_NETWORK_MODE === "tunnel";

/** @type {{ mode: string; webUrl: string; ready: boolean; message: string; updatedAt: string }} */
let links = {
  mode: useTunnel ? "tunnel" : "lan",
  webUrl: "",
  ready: false,
  message: "Sunucu başlatılıyor…",
  updatedAt: new Date().toISOString(),
};

function setLinks(partial) {
  links = { ...links, ...partial, updatedAt: new Date().toISOString() };
  if (links.ready && links.webUrl) {
    fs.mkdirSync(path.dirname(urlFile), { recursive: true });
    fs.writeFileSync(urlFile, links.webUrl + "\n");
  }
}

function contentType(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  const map = {
    ".html": "text/html; charset=utf-8",
    ".js": "application/javascript; charset=utf-8",
    ".json": "application/json; charset=utf-8",
    ".css": "text/css; charset=utf-8",
    ".png": "image/png",
    ".ico": "image/x-icon",
    ".wasm": "application/wasm",
    ".ttf": "font/ttf",
    ".otf": "font/otf",
    ".svg": "image/svg+xml",
  };
  return map[ext] || "application/octet-stream";
}

function startStaticServer() {
  const server = http.createServer((req, res) => {
    const urlPath = decodeURIComponent((req.url || "/").split("?")[0]);
    let filePath = path.join(webRoot, urlPath === "/" ? "index.html" : urlPath);
    if (!filePath.startsWith(webRoot)) {
      res.writeHead(403);
      res.end("Forbidden");
      return;
    }
    if (!fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
      filePath = path.join(webRoot, "index.html");
    }
    res.writeHead(200, {
      "content-type": contentType(filePath),
      "cache-control": "no-cache",
    });
    fs.createReadStream(filePath).pipe(res);
  });
  server.listen(webPort, "0.0.0.0", () => {
    console.log(`[bfa-web] Statik sunucu: http://0.0.0.0:${webPort}`);
    if (!useTunnel) {
      setLinks({
        webUrl: `http://127.0.0.1:${webPort}`,
        ready: true,
        message: "LAN modu — telefon bilgisayarla aynı Wi‑Fi ağında olmalı.",
      });
    }
  });
  return server;
}

function landingHtml() {
  return `<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>ŞantiJET BFA — Telefon Bağlantısı</title>
  <style>
    * { box-sizing: border-box; }
    body {
      margin: 0; min-height: 100vh; font-family: system-ui, sans-serif;
      background: #05070A; color: #e2e8f0; display: flex; align-items: center; justify-content: center; padding: 24px;
    }
    .card {
      max-width: 420px; width: 100%; background: #111827; border-radius: 16px;
      padding: 28px; border: 1px solid rgba(0,85,255,0.25);
    }
    h1 { margin: 0 0 4px; font-size: 22px; color: #fff; }
    .sub { color: #94a3b8; font-size: 13px; margin-bottom: 16px; line-height: 1.4; }
    .badge {
      display: inline-block; font-size: 11px; font-weight: 700; letter-spacing: 0.5px;
      padding: 4px 10px; border-radius: 999px; margin-bottom: 16px;
      background: rgba(0,85,255,0.15); color: #38bdf8; border: 1px solid rgba(0,85,255,0.35);
    }
    .qr-wrap { text-align: center; min-height: 280px; display: flex; align-items: center; justify-content: center; }
    .qr { border-radius: 12px; background: #fff; padding: 8px; max-width: 100%; }
    .loading { color: #94a3b8; font-size: 14px; }
    label { display: block; font-size: 11px; text-transform: uppercase; letter-spacing: 1px; color: #64748b; margin-top: 14px; }
    a, code {
      display: block; word-break: break-all; color: #60a5fa; font-size: 13px; margin-top: 4px; text-decoration: none;
    }
    a:hover { text-decoration: underline; }
    .note {
      margin-top: 20px; padding: 12px; border-radius: 10px; background: rgba(0,85,255,0.12);
      border: 1px solid rgba(0,85,255,0.25); font-size: 12px; line-height: 1.55; color: #cbd5e1;
    }
  </style>
</head>
<body>
  <div class="card">
    <h1>ŞantiJET BFA</h1>
    <p class="sub">iPhone Safari — QR kodu okutun veya bağlantıya dokunun.</p>
    <span class="badge" id="mode">…</span>
    <div class="qr-wrap">
      <p class="loading" id="wait">Bağlantı hazırlanıyor…</p>
      <img class="qr" id="qr" width="260" height="260" alt="Safari QR" hidden />
    </div>
    <label>Safari bağlantısı</label>
    <a id="web" href="#" target="_blank" rel="noreferrer">—</a>
    <div class="note" id="note"></div>
  </div>
  <script>
    async function refresh() {
      try {
        const r = await fetch('/api/links');
        const d = await r.json();
        document.getElementById('mode').textContent = d.mode === 'tunnel' ? 'TUNNEL · Her ağdan erişim' : 'LAN · Aynı Wi‑Fi';
        document.getElementById('note').textContent = d.message || '';
        if (d.ready && d.webUrl) {
          document.getElementById('wait').hidden = true;
          const qr = document.getElementById('qr');
          qr.hidden = false;
          qr.src = 'https://api.qrserver.com/v1/create-qr-code/?size=260x260&data=' + encodeURIComponent(d.webUrl);
          const web = document.getElementById('web');
          web.textContent = d.webUrl;
          web.href = d.webUrl;
        }
      } catch (e) {
        document.getElementById('note').textContent = 'Sunucu bekleniyor…';
      }
    }
    refresh();
    setInterval(refresh, 2500);
  </script>
</body>
</html>`;
}

function startLandingServer() {
  const server = http.createServer((req, res) => {
    if (req.url === "/api/links") {
      res.writeHead(200, {
        "content-type": "application/json; charset=utf-8",
        "cache-control": "no-store",
      });
      res.end(JSON.stringify(links));
      return;
    }
    res.writeHead(200, {
      "content-type": "text/html; charset=utf-8",
      "cache-control": "no-store",
    });
    res.end(landingHtml());
  });
  server.listen(landingPort, "0.0.0.0", () => {
    console.log(`[bfa-web] Yer imi / QR: http://localhost:${landingPort}`);
  });
  return server;
}

async function startTunnel() {
  setLinks({
    mode: "tunnel",
    ready: false,
    message: "Tunnel açılıyor… Telefon farklı ağda olsa da bağlanabilir.",
  });
  try {
    const ngrokPath = path.resolve(
      projectRoot,
      "../../node_modules/.pnpm/@expo+ngrok@4.1.3/node_modules/@expo/ngrok"
    );
    const ngrok = await import(ngrokPath);
    const authtoken =
      process.env.NGROK_AUTHTOKEN || "5W1bR67GNbWcXqmxZzBG1_56GezNeaX6sSRvn8npeQ8";
    const hostname =
      process.env.BFA_TUNNEL_HOSTNAME || "nehhr88-anonymous-24916.exp.direct";
    const url = await ngrok.default.connect({
      authtoken,
      addr: webPort,
      proto: "http",
      hostname,
    });
    const httpsUrl = url.startsWith("http://")
      ? url.replace("http://", "https://")
      : url;
    setLinks({
      mode: "tunnel",
      webUrl: httpsUrl,
      ready: true,
      message:
        "Tunnel hazır — iPhone Safari’de açın. Ana ekrana eklemek için Paylaş → Ana Ekrana Ekle.",
    });
    console.log(`[bfa-web] Safari: ${httpsUrl}`);
  } catch (err) {
    // Mevcut expo ngrok tüneli varsa 24916 üzerinden yayınla
    try {
      const res = await fetch("http://127.0.0.1:4040/api/tunnels");
      if (res.ok) {
        const data = await res.json();
        const tunnel = (data.tunnels || []).find(
          (t) => t.proto === "https" && t.public_url
        );
        if (tunnel) {
          setLinks({
            mode: "tunnel",
            webUrl: tunnel.public_url,
            ready: true,
            message:
              "Mevcut tunnel kullanılıyor. Uygulama bu adreste yayında.",
          });
          console.log(`[bfa-web] Mevcut tunnel: ${tunnel.public_url}`);
          return;
        }
      }
    } catch {
      /* ignore */
    }
    setLinks({
      ready: false,
      message: `Tunnel açılamadı: ${err.message || err}`,
    });
    console.error("[bfa-web] Tunnel hatası:", err.message || err);
  }
}

if (!fs.existsSync(webRoot)) {
  console.error("[bfa-web] build/web bulunamadı. Önce: flutter build web --release");
  process.exit(1);
}

startStaticServer();
startLandingServer();
if (useTunnel) startTunnel();

process.on("SIGINT", () => process.exit(0));
process.on("SIGTERM", () => process.exit(0));
