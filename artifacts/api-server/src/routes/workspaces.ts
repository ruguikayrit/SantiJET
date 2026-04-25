import { Router, type IRouter } from "express";
import { db, workspacesTable } from "@workspace/db";
import { eq } from "drizzle-orm";

const router: IRouter = Router();

function genCode(): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  return Array.from({ length: 6 }, () => chars[Math.floor(Math.random() * chars.length)]).join("");
}

function genId(): string {
  return Date.now().toString() + Math.random().toString(36).substr(2, 9);
}

router.post("/workspaces", async (req, res) => {
  try {
    const { company_name } = req.body as { company_name?: string };
    if (!company_name?.trim()) {
      res.status(400).json({ error: "Firma adı zorunludur." });
      return;
    }

    let invite_code = genCode();
    let attempts = 0;
    while (attempts < 10) {
      const existing = await db.select({ id: workspacesTable.id }).from(workspacesTable).where(eq(workspacesTable.invite_code, invite_code));
      if (existing.length === 0) break;
      invite_code = genCode();
      attempts++;
    }

    const id = genId();
    await db.insert(workspacesTable).values({ id, invite_code, company_name: company_name.trim(), data: null });

    res.status(201).json({ id, invite_code, company_name: company_name.trim() });
  } catch (err) {
    res.status(500).json({ error: "Çalışma alanı oluşturulamadı." });
  }
});

router.get("/workspaces/:code", async (req, res) => {
  try {
    const code = req.params.code?.toUpperCase().trim();
    const rows = await db.select().from(workspacesTable).where(eq(workspacesTable.invite_code, code));
    if (rows.length === 0) {
      res.status(404).json({ error: "Geçersiz davet kodu." });
      return;
    }
    const { data: _data, ...info } = rows[0];
    res.json(info);
  } catch {
    res.status(500).json({ error: "Sunucu hatası." });
  }
});

router.post("/workspaces/:code/push", async (req, res) => {
  try {
    const code = req.params.code?.toUpperCase().trim();
    const rows = await db.select({ id: workspacesTable.id }).from(workspacesTable).where(eq(workspacesTable.invite_code, code));
    if (rows.length === 0) {
      res.status(404).json({ error: "Geçersiz davet kodu." });
      return;
    }
    const payload = req.body;
    if (!payload || typeof payload !== "object") {
      res.status(400).json({ error: "Geçersiz veri." });
      return;
    }
    await db.update(workspacesTable).set({ data: payload, updated_at: new Date() }).where(eq(workspacesTable.invite_code, code));
    res.json({ ok: true, updated_at: new Date().toISOString() });
  } catch {
    res.status(500).json({ error: "Veri gönderilemedi." });
  }
});

router.get("/workspaces/:code/pull", async (req, res) => {
  try {
    const code = req.params.code?.toUpperCase().trim();
    const rows = await db.select().from(workspacesTable).where(eq(workspacesTable.invite_code, code));
    if (rows.length === 0) {
      res.status(404).json({ error: "Geçersiz davet kodu." });
      return;
    }
    const ws = rows[0];
    if (!ws.data) {
      res.json({ ok: true, data: null, updated_at: ws.updated_at });
      return;
    }
    res.json({ ok: true, data: ws.data, updated_at: ws.updated_at });
  } catch {
    res.status(500).json({ error: "Veri alınamadı." });
  }
});

export default router;
