import { Router, type IRouter, type Request, type Response, type NextFunction } from "express";
import OpenAI from "openai";
import { db, workspacesTable } from "@workspace/db";
import { eq } from "drizzle-orm";
import { verifyToken, getBearerToken } from "../lib/auth";
import { rateLimit } from "../lib/rateLimit";
import { logger } from "../lib/logger";

const router: IRouter = Router();

const aiLimiter = rateLimit({ windowMs: 60_000, max: 15 });

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

const openaiBaseUrl = process.env["AI_INTEGRATIONS_OPENAI_BASE_URL"];
const openaiApiKey = process.env["AI_INTEGRATIONS_OPENAI_API_KEY"];

const openai = openaiBaseUrl && openaiApiKey
  ? new OpenAI({ baseURL: openaiBaseUrl, apiKey: openaiApiKey })
  : null;

const MAX_QUESTION_LEN = 500;
const MAX_SNAPSHOT_BYTES = 200_000;

const SYSTEM_PROMPT = `Sen bir Türk inşaat şantiye yönetim uygulamasının yardımcı asistanısın.
Görevin: kullanıcının doğal dildeki sorusunu, ona verilen JSON formatındaki şantiye verileri üzerinden cevaplamak.
Kurallar:
- Cevabını sadece Türkçe ver.
- Kısa, net ve listele halinde cevap ver. Mümkün olduğunda madde işareti kullan.
- Sayısal toplamlar isteniyorsa hesapla ve net rakam ver.
- Para birimi TL'dir, gerektiğinde "₺" kullan.
- Veride bulunmayan bir bilgi sorulursa "Bu bilgi mevcut verilerde bulunmuyor." de, bilgi uydurma.
- Tarihleri "DD.MM.YYYY" formatında göster.
- Cevabı en fazla 200 kelime ile sınırla.`;

router.post("/workspaces/:code/ask", aiLimiter, requireAuth, async (req: AuthedRequest, res) => {
  try {
    if (!openai) {
      res.status(503).json({ error: "Yapay zeka servisi şu anda kullanılamıyor." });
      return;
    }
    const body = req.body as { question?: unknown; snapshot?: unknown };
    const question = typeof body.question === "string" ? body.question.trim() : "";
    const snapshot = body.snapshot;
    if (question.length < 2 || question.length > MAX_QUESTION_LEN) {
      res.status(400).json({ error: `Soru 2 ile ${MAX_QUESTION_LEN} karakter arasında olmalı.` });
      return;
    }
    if (!snapshot || typeof snapshot !== "object") {
      res.status(400).json({ error: "Veri eksik." });
      return;
    }
    const snapshotJson = JSON.stringify(snapshot);
    const byteLen = Buffer.byteLength(snapshotJson, "utf8");
    if (byteLen > MAX_SNAPSHOT_BYTES) {
      res.status(413).json({ error: "Veri çok büyük. Lütfen tek bir proje seçerek tekrar deneyin." });
      return;
    }

    const completion = await openai.chat.completions.create({
      model: "gpt-5-mini",
      max_completion_tokens: 1024,
      messages: [
        { role: "system", content: SYSTEM_PROMPT },
        { role: "user", content: `Veriler:\n${snapshotJson}\n\nSoru: ${question}` },
      ],
    });

    const answer = completion.choices[0]?.message?.content?.trim() ?? "";
    if (!answer) {
      res.status(502).json({ error: "Yapay zekadan boş cevap geldi." });
      return;
    }
    res.json({ answer });
  } catch (err) {
    logger.error({ err }, "AI ask failed");
    res.status(500).json({ error: "Yapay zeka cevap veremedi. Tekrar deneyin." });
  }
});

export default router;
