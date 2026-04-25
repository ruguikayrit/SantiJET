import type { Request, Response, NextFunction } from "express";

interface Bucket {
  count: number;
  resetAt: number;
}

const MAX_BUCKETS = 10_000;

export function rateLimit(opts: { windowMs: number; max: number; key?: (req: Request) => string }) {
  const { windowMs, max } = opts;
  const buckets = new Map<string, Bucket>();
  const keyFn = opts.key ?? ((req: Request) => req.ip ?? req.socket?.remoteAddress ?? "unknown");

  function sweep(now: number) {
    for (const [k, v] of buckets) {
      if (v.resetAt <= now) buckets.delete(k);
    }
    if (buckets.size > MAX_BUCKETS) {
      const overflow = buckets.size - MAX_BUCKETS;
      let removed = 0;
      for (const k of buckets.keys()) {
        buckets.delete(k);
        if (++removed >= overflow) break;
      }
    }
  }

  const interval = setInterval(() => sweep(Date.now()), Math.max(windowMs, 60_000));
  if (typeof interval.unref === "function") interval.unref();

  return function rateLimitMiddleware(req: Request, res: Response, next: NextFunction) {
    const now = Date.now();
    const key = keyFn(req);
    const b = buckets.get(key);
    if (!b || now > b.resetAt) {
      if (buckets.size >= MAX_BUCKETS) sweep(now);
      buckets.set(key, { count: 1, resetAt: now + windowMs });
      next();
      return;
    }
    b.count++;
    if (b.count > max) {
      const retry = Math.max(0, Math.ceil((b.resetAt - now) / 1000));
      res.setHeader("Retry-After", String(retry));
      res.status(429).json({ error: "Çok fazla istek. Lütfen biraz bekleyin." });
      return;
    }
    next();
  };
}
