import { createHmac, randomBytes, scryptSync, timingSafeEqual } from "node:crypto";

const SECRET = process.env.SESSION_SECRET;
if (!SECRET || SECRET.length < 16) {
  throw new Error(
    "SESSION_SECRET environment variable is required (min 16 chars) for token signing.",
  );
}
const TOKEN_TTL_MS = 30 * 24 * 60 * 60 * 1000;

export function hashPassword(password: string): string {
  const salt = randomBytes(16).toString("hex");
  const derived = scryptSync(password, salt, 64).toString("hex");
  return `${salt}:${derived}`;
}

export function verifyPassword(password: string, stored: string): boolean {
  if (!stored || !stored.includes(":")) return false;
  const [salt, expected] = stored.split(":");
  try {
    const derived = scryptSync(password, salt, 64);
    const expectedBuf = Buffer.from(expected, "hex");
    if (derived.length !== expectedBuf.length) return false;
    return timingSafeEqual(derived, expectedBuf);
  } catch {
    return false;
  }
}

export function issueToken(workspaceId: string, ttlMs: number = TOKEN_TTL_MS): string {
  const exp = Date.now() + ttlMs;
  const payload = `${workspaceId}.${exp}`;
  const sig = createHmac("sha256", SECRET).update(payload).digest("hex");
  return `${payload}.${sig}`;
}

export function verifyToken(token: string): { workspaceId: string } | null {
  if (!token) return null;
  const parts = token.split(".");
  if (parts.length !== 3) return null;
  const [workspaceId, expStr, sig] = parts;
  const exp = Number(expStr);
  if (!workspaceId || !Number.isFinite(exp) || exp < Date.now()) return null;
  const expected = createHmac("sha256", SECRET).update(`${workspaceId}.${expStr}`).digest("hex");
  try {
    const a = Buffer.from(sig, "hex");
    const b = Buffer.from(expected, "hex");
    if (a.length !== b.length) return null;
    if (!timingSafeEqual(a, b)) return null;
  } catch {
    return null;
  }
  return { workspaceId };
}

export function getBearerToken(authHeader: string | undefined): string | null {
  if (!authHeader) return null;
  const m = authHeader.match(/^Bearer\s+(.+)$/i);
  return m ? m[1].trim() : null;
}
