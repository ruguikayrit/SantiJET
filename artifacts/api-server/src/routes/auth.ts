import { Router } from "express";

const router = Router();

router.post("/auth/verify", (req, res) => {
  const { password } = req.body as { password?: string };
  const appPassword = process.env["APP_PASSWORD"];

  if (!appPassword) {
    res.status(500).json({ ok: false, message: "Sunucu yapılandırma hatası." });
    return;
  }

  if (password === appPassword) {
    res.json({ ok: true });
  } else {
    res.status(401).json({ ok: false, message: "Parola hatalı." });
  }
});

export default router;
