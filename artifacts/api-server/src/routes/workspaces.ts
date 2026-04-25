import { Router, type IRouter, type Request, type Response, type NextFunction } from "express";
import { db, workspacesTable } from "@workspace/db";
import { and, eq } from "drizzle-orm";
import { hashPassword, verifyPassword, issueToken, verifyToken, getBearerToken } from "../lib/auth";
import { rateLimit } from "../lib/rateLimit";

const router: IRouter = Router();

const CODE_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
const CODE_LEN = 10;

function genCode(): string {
  let out = "";
  for (let i = 0; i < CODE_LEN; i++) {
    out += CODE_CHARS[Math.floor(Math.random() * CODE_CHARS.length)];
  }
  return out;
}

function genId(): string {
  return Date.now().toString() + Math.random().toString(36).substring(2, 11);
}

const writeLimiter = rateLimit({ windowMs: 60_000, max: 30 });
const authLimiter = rateLimit({ windowMs: 60_000, max: 10 });

interface AuthedRequest extends Request {
  workspaceId?: string;
}

async function requireAuth(req: AuthedRequest, res: Response, next: NextFunction) {
  const token = getBearerToken(req.headers.authorization);
  const verified = token ? verifyToken(token) : null;
  if (!verified) {
    res.status(401).json({ error: "Geçersiz veya süresi dolmuş oturum." });
    return;
  }
  const code = req.params.code?.toUpperCase().trim();
  if (!code) {
    res.status(400).json({ error: "Davet kodu gerekli." });
    return;
  }
  const rows = await db
    .select({ id: workspacesTable.id })
    .from(workspacesTable)
    .where(eq(workspacesTable.invite_code, code));
  if (rows.length === 0 || rows[0].id !== verified.workspaceId) {
    res.status(401).json({ error: "Geçersiz veya süresi dolmuş oturum." });
    return;
  }
  req.workspaceId = verified.workspaceId;
  next();
}

router.post("/workspaces", authLimiter, async (req, res) => {
  try {
    const { company_name, password } = req.body as { company_name?: string; password?: string };
    if (!company_name?.trim()) {
      res.status(400).json({ error: "Firma adı zorunludur." });
      return;
    }
    if (!password || password.length < 4) {
      res.status(400).json({ error: "Şifre en az 4 karakter olmalı." });
      return;
    }

    let invite_code = genCode();
    let attempts = 0;
    while (attempts < 10) {
      const existing = await db
        .select({ id: workspacesTable.id })
        .from(workspacesTable)
        .where(eq(workspacesTable.invite_code, invite_code));
      if (existing.length === 0) break;
      invite_code = genCode();
      attempts++;
    }

    const id = genId();
    await db.insert(workspacesTable).values({
      id,
      invite_code,
      company_name: company_name.trim(),
      password_hash: hashPassword(password),
      revision: 0,
      data: null,
    });

    const token = issueToken(id);
    res.status(201).json({
      id,
      invite_code,
      company_name: company_name.trim(),
      revision: 0,
      auth_token: token,
    });
  } catch {
    res.status(500).json({ error: "Çalışma alanı oluşturulamadı." });
  }
});

router.post("/workspaces/:code/join", authLimiter, async (req, res) => {
  try {
    const code = req.params.code?.toUpperCase().trim();
    const { password } = req.body as { password?: string };
    if (!password) {
      res.status(400).json({ error: "Şifre gerekli." });
      return;
    }
    const rows = await db.select().from(workspacesTable).where(eq(workspacesTable.invite_code, code));
    if (rows.length === 0) {
      res.status(404).json({ error: "Geçersiz davet kodu." });
      return;
    }
    const ws = rows[0];
    if (!ws.password_hash || !verifyPassword(password, ws.password_hash)) {
      res.status(401).json({ error: "Davet kodu veya şifre hatalı." });
      return;
    }
    const token = issueToken(ws.id);
    res.json({
      id: ws.id,
      invite_code: ws.invite_code,
      company_name: ws.company_name,
      revision: ws.revision,
      auth_token: token,
    });
  } catch {
    res.status(500).json({ error: "Sunucu hatası." });
  }
});

router.post("/workspaces/:code/push", writeLimiter, requireAuth, async (req: AuthedRequest, res) => {
  try {
    const code = req.params.code?.toUpperCase().trim();
    const { data, base_revision } = req.body as { data?: unknown; base_revision?: number };
    if (!data || typeof data !== "object") {
      res.status(400).json({ error: "Geçersiz veri." });
      return;
    }
    if (typeof base_revision !== "number") {
      res.status(400).json({ error: "base_revision gerekli." });
      return;
    }
    const rows = await db
      .select({ revision: workspacesTable.revision })
      .from(workspacesTable)
      .where(eq(workspacesTable.invite_code, code));
    if (rows.length === 0) {
      res.status(404).json({ error: "Geçersiz davet kodu." });
      return;
    }
    const current = rows[0].revision;
    if (current !== base_revision) {
      res.status(409).json({
        error: "Veriler güncel değil. Önce sunucudan indirin.",
        current_revision: current,
      });
      return;
    }
    const newRev = current + 1;
    const result = await db
      .update(workspacesTable)
      .set({ data: data as object, revision: newRev, updated_at: new Date() })
      .where(and(eq(workspacesTable.invite_code, code), eq(workspacesTable.revision, current)))
      .returning({ revision: workspacesTable.revision, updated_at: workspacesTable.updated_at });
    if (result.length === 0) {
      const fresh = await db
        .select({ revision: workspacesTable.revision })
        .from(workspacesTable)
        .where(eq(workspacesTable.invite_code, code));
      res.status(409).json({
        error: "Veriler güncel değil. Önce sunucudan indirin.",
        current_revision: fresh[0]?.revision ?? current,
      });
      return;
    }
    res.json({ ok: true, revision: result[0].revision, updated_at: result[0].updated_at });
  } catch {
    res.status(500).json({ error: "Veri gönderilemedi." });
  }
});

router.get("/workspaces/:code/pull", writeLimiter, requireAuth, async (req: AuthedRequest, res) => {
  try {
    const code = req.params.code?.toUpperCase().trim();
    const rows = await db.select().from(workspacesTable).where(eq(workspacesTable.invite_code, code));
    if (rows.length === 0) {
      res.status(404).json({ error: "Geçersiz davet kodu." });
      return;
    }
    const ws = rows[0];
    res.json({
      ok: true,
      data: ws.data ?? null,
      revision: ws.revision,
      updated_at: ws.updated_at,
    });
  } catch {
    res.status(500).json({ error: "Veri alınamadı." });
  }
});

export default router;
