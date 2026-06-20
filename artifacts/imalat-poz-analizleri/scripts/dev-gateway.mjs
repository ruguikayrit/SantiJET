#!/usr/bin/env node
/**
 * ŞantiJET İPA — sabit QR / sabit link geliştirme sunucusu
 *
 * - Metro her zaman port 24916 (veya PORT)
 * - QR adresi: exp://<host>:24916 — host bir kez kaydedilir, yeniden başlatmada değişmez
 * - Sabit açılış sayfası: http://localhost:24917 — yer imlerine eklenebilir
 *
 * Farklı ağdan erişim için bir kez ayarlayın:
 *   IPA_EXPO_HOST=sizin-sabit-adresiniz
 */
import { spawn } from "child_process";
import fs from "fs";
import http from "http";
import os from "os";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(__dirname, "..");
const hostFile = path.join(projectRoot, ".expo", "ipa-dev-host");
const metroPort = Number(process.env.PORT || 24916);
const landingPort = Number(process.env.IPA_LANDING_PORT || 24917);

function detectLanIp() {
  for (const ifaces of Object.values(os.networkInterfaces())) {
    for (const net of ifaces || []) {
      if (net.family === "IPv4" && !net.internal) return net.address;
    }
  }
  return "localhost";
}

function resolveHost() {
  const fromEnv = process.env.IPA_EXPO_HOST?.trim();
  if (fromEnv) {
    fs.mkdirSync(path.dirname(hostFile), { recursive: true });
    fs.writeFileSync(hostFile, fromEnv);
    return fromEnv;
  }
  try {
    const saved = fs.readFileSync(hostFile, "utf8").trim();
    if (saved) return saved;
  } catch {
    /* ilk çalıştırma */
  }
  const detected = detectLanIp();
  fs.mkdirSync(path.dirname(hostFile), { recursive: true });
  fs.writeFileSync(hostFile, detected);
  console.log(`[ipa-dev] Host kaydedildi: ${detected} (${hostFile})`);
  return detected;
}

function webHost(host) {
  return host === "0.0.0.0" ? "localhost" : host;
}

function landingHtml(host) {
  const expUrl = `exp://${host}:${metroPort}`;
  const webUrl = `http://${webHost(host)}:${metroPort}`;
  const landingUrl = `http://localhost:${landingPort}`;
  const qr = `https://api.qrserver.com/v1/create-qr-code/?size=360x360&data=${encodeURIComponent(expUrl)}`;

  return `<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>ŞantiJET İPA — Geliştirme</title>
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
    .sub { color: #94a3b8; font-size: 13px; margin-bottom: 20px; }
    .qr { display: block; margin: 0 auto 16px; border-radius: 12px; background: #fff; padding: 8px; }
    label { display: block; font-size: 11px; text-transform: uppercase; letter-spacing: 1px; color: #64748b; margin-top: 14px; }
    a, code {
      display: block; word-break: break-all; color: #f97316; font-size: 13px; margin-top: 4px;
      text-decoration: none;
    }
    a:hover { text-decoration: underline; }
    .note {
      margin-top: 20px; padding: 12px; border-radius: 10px; background: rgba(249,115,22,0.12);
      border: 1px solid rgba(249,115,22,0.25); font-size: 12px; line-height: 1.5; color: #cbd5e1;
    }
    .host { color: #38bdf8; font-weight: 600; }
  </style>
</head>
<body>
  <div class="card">
    <h1>ŞantiJET İPA</h1>
    <p class="sub">Sabit geliştirme bağlantıları — kod değişince QR değişmez</p>
    <img class="qr" src="${qr}" width="360" height="360" alt="Expo Go QR" />
    <label>Expo Go (telefon)</label>
    <code>${expUrl}</code>
    <label>Web tarayıcı</label>
    <a href="${webUrl}" target="_blank" rel="noreferrer">${webUrl}</a>
    <label>Bu sayfa (yer imi)</label>
    <code>${landingUrl}</code>
    <div class="note">
      Host: <span class="host">${host}</span> · Port: ${metroPort}<br />
      QR yalnızca <strong>IPA_EXPO_HOST</strong> değiştirilirse veya <code>.expo/ipa-dev-host</code> silinirse güncellenir.
      Tunnel kullanmayın — her yeniden başlatmada rastgele adres üretir.
    </div>
  </div>
</body>
</html>`;
}

function startLandingServer(host) {
  const server = http.createServer((_req, res) => {
    res.writeHead(200, { "content-type": "text/html; charset=utf-8" });
    res.end(landingHtml(host));
  });
  server.listen(landingPort, "0.0.0.0", () => {
    console.log("");
    console.log("══════════════════════════════════════════════════");
    console.log("  ŞantiJET İPA — SABİT BAĞLANTILAR");
    console.log("══════════════════════════════════════════════════");
    console.log(`  Yer imi sayfası : http://localhost:${landingPort}`);
    console.log(`  Web uygulama    : http://${webHost(host)}:${metroPort}`);
    console.log(`  Expo Go         : exp://${host}:${metroPort}`);
    console.log("══════════════════════════════════════════════════");
    console.log("");
  });
  return server;
}

function startMetro(host) {
  const stub = path.join(projectRoot, "scripts", "fix-expo-router-stub.js");
  spawn("node", [stub], { cwd: projectRoot, stdio: "inherit", shell: false }).on("close", () => {
    const env = {
      ...process.env,
      EXPO_NO_DEPENDENCY_VALIDATION: "1",
      REACT_NATIVE_PACKAGER_HOSTNAME: host,
    };
    const child = spawn(
      "pnpm",
      ["exec", "expo", "start", "--lan", "--port", String(metroPort)],
      { cwd: projectRoot, stdio: "inherit", env, shell: false },
    );
    child.on("exit", (code) => process.exit(code ?? 0));
  });
}

const host = resolveHost();
startLandingServer(host);
startMetro(host);

process.on("SIGINT", () => process.exit(0));
process.on("SIGTERM", () => process.exit(0));
