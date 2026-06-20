import { useState, useEffect, type ReactNode } from "react";

const SESSION_KEY = "santijet_auth";
const API_BASE = import.meta.env.BASE_URL?.startsWith("/")
  ? ""
  : "";

async function verifyPassword(password: string): Promise<boolean> {
  try {
    const res = await fetch("/api/auth/verify", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ password }),
    });
    const data = await res.json() as { ok: boolean };
    return data.ok === true;
  } catch {
    return false;
  }
}

export function PasswordGate({ children }: { children: ReactNode }) {
  const [authenticated, setAuthenticated] = useState(false);
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (sessionStorage.getItem(SESSION_KEY) === "1") {
      setAuthenticated(true);
    }
  }, []);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError("");
    const ok = await verifyPassword(password);
    setLoading(false);
    if (ok) {
      sessionStorage.setItem(SESSION_KEY, "1");
      setAuthenticated(true);
    } else {
      setError("Parola hatalı. Tekrar deneyin.");
      setPassword("");
    }
  }

  if (authenticated) return <>{children}</>;

  return (
    <div className="min-h-screen bg-[#04060d] flex items-center justify-center">
      <div className="w-full max-w-sm px-6">
        <div className="flex justify-center mb-8">
          <div className="w-16 h-16 rounded-2xl bg-[#1a5fff]/10 border border-[#1a5fff]/30 flex items-center justify-center shadow-[0_0_40px_rgba(26,95,255,0.3)]">
            <svg viewBox="0 0 100 100" className="w-10 h-10" fill="none">
              <polygon points="60,5 20,55 45,55 40,95 80,45 55,45" fill="#1a5fff" />
              <polygon points="60,5 45,55 55,45" fill="white" />
            </svg>
          </div>
        </div>

        <h1 className="text-center text-white text-xl font-bold mb-1 tracking-wide">ŞantiJET</h1>
        <p className="text-center text-white/40 text-sm mb-8">Erişim için parola gereklidir.</p>

        <form onSubmit={handleSubmit} className="space-y-4">
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="Parola"
            autoFocus
            className="w-full bg-white/5 border border-white/10 rounded-lg px-4 py-3 text-white placeholder-white/30 text-sm outline-none focus:border-[#1a5fff]/60 focus:shadow-[0_0_0_2px_rgba(26,95,255,0.15)] transition-all"
          />
          {error && (
            <p className="text-red-400 text-xs text-center">{error}</p>
          )}
          <button
            type="submit"
            disabled={loading || !password}
            className="w-full bg-[#1a5fff] hover:bg-[#1a5fff]/90 disabled:opacity-50 disabled:cursor-not-allowed text-white font-semibold py-3 rounded-lg text-sm transition-colors shadow-[0_0_20px_rgba(26,95,255,0.4)]"
          >
            {loading ? "Doğrulanıyor..." : "Giriş"}
          </button>
        </form>
      </div>
    </div>
  );
}
