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

const SYSTEM_PROMPT = `Sen bir Türk inşaat şantiye yönetim uygulamasının (ŞantiJET) yardımcı asistanısın.
Görevin: kullanıcının doğal dildeki sorusunu, ona verilen JSON formatındaki şantiye verileri üzerinden cevaplamak.
Şantiye terimleri (m3, m2, ton, beton, demir, kalıp, hakediş, puantaj, keşif, imalat) ile rahat çalışırsın.
Kurallar:
- Cevabını her zaman ve sadece Türkçe ver.
- Kısa, net ve gerektiğinde madde işareti / kalın başlık ile cevap ver.
- Sayısal toplamlar isteniyorsa hesapla ve net rakam ver. Birimi de yaz (m3, m2, kg, ton, gün, saat...).
- Para birimi TL'dir, "₺" kullan. Büyük rakamları okunaklı yaz (örn. 1.250.000 ₺).
- Tarih aralığı sorulduğunda ("bu ay", "geçen hafta", "x tarihinde") doğru filtreleme yap.
- Veride olmayan bir bilgi sorulursa "Bu bilgi mevcut verilerde bulunmuyor." de — asla uydurma.
- Tarihleri "DD.MM.YYYY" formatında göster.
- Cevabı en fazla 250 kelime ile sınırla. Yeterince bilgi varsa başında 1 cümle özet ver.
- Geçmiş mesajlar varsa onlara referans verebilir, takip sorularını kullanıcının önceki sorusuyla bağlantılı cevaplayabilirsin.`;

interface ChatMessage {
  role: "user" | "assistant";
  content: string;
}

const MAX_HISTORY_MESSAGES = 10;
const MAX_HISTORY_CHAR_PER_MSG = 4000;

router.post("/workspaces/:code/ask", aiLimiter, requireAuth, async (req: AuthedRequest, res) => {
  try {
    if (!openai) {
      res.status(503).json({ error: "Yapay zeka servisi şu anda kullanılamıyor." });
      return;
    }
    const body = req.body as { question?: unknown; snapshot?: unknown; history?: unknown };
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

    const safeHistory: ChatMessage[] = Array.isArray(body.history)
      ? body.history
          .filter((m): m is { role: string; content: string } =>
            !!m && typeof m === "object" &&
            (m as any).role && typeof (m as any).content === "string"
          )
          .filter((m) => m.role === "user" || m.role === "assistant")
          .map((m) => ({
            role: m.role as "user" | "assistant",
            content: m.content.slice(0, MAX_HISTORY_CHAR_PER_MSG),
          }))
          .slice(-MAX_HISTORY_MESSAGES)
      : [];

    const today = new Date().toISOString().slice(0, 10);

    const completion = await openai.chat.completions.create({
      model: "gpt-5-mini",
      max_completion_tokens: 1024,
      messages: [
        { role: "system", content: SYSTEM_PROMPT },
        { role: "system", content: `Bugünün tarihi: ${today}` },
        { role: "system", content: `Şantiye verileri (JSON):\n${snapshotJson}` },
        ...safeHistory.map((m) => ({ role: m.role, content: m.content })),
        { role: "user", content: question },
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
