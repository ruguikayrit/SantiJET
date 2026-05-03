import { Users, Package, Truck, ShoppingCart, Hammer, Scale, Sparkles } from "lucide-react";

const T = [
  { k: "Puantaj",    c: 47,  icon: Users,        grad: "linear-gradient(135deg,#fb7185,#fb923c)" },
  { k: "Malzeme",    c: 184, icon: Package,      grad: "linear-gradient(135deg,#22d3ee,#3b82f6)" },
  { k: "Sevkiyat",   c: 9,   icon: Truck,        grad: "linear-gradient(135deg,#34d399,#06b6d4)" },
  { k: "Satın Alma", c: 23,  icon: ShoppingCart, grad: "linear-gradient(135deg,#c084fc,#f472b6)" },
  { k: "İmalat",     c: 56,  icon: Hammer,       grad: "linear-gradient(135deg,#facc15,#fb923c)" },
  { k: "Kantar",     c: 312, icon: Scale,        grad: "linear-gradient(135deg,#a78bfa,#22d3ee)" },
];

export function Aurora() {
  return (
    <div className="min-h-screen relative overflow-hidden font-['Inter']" style={{ background: "#05060d" }}>
      {/* aurora mesh gradient orbs */}
      <div
        className="absolute"
        style={{
          top: -120, left: -80, width: 380, height: 380, borderRadius: "50%",
          background: "radial-gradient(circle, #ec4899 0%, transparent 65%)",
          filter: "blur(60px)", opacity: 0.55,
        }}
      />
      <div
        className="absolute"
        style={{
          top: 200, right: -120, width: 420, height: 420, borderRadius: "50%",
          background: "radial-gradient(circle, #06b6d4 0%, transparent 65%)",
          filter: "blur(70px)", opacity: 0.5,
        }}
      />
      <div
        className="absolute"
        style={{
          bottom: -100, left: 60, width: 360, height: 360, borderRadius: "50%",
          background: "radial-gradient(circle, #8b5cf6 0%, transparent 65%)",
          filter: "blur(60px)", opacity: 0.45,
        }}
      />
      {/* grain */}
      <div
        className="absolute inset-0 pointer-events-none"
        style={{
          backgroundImage: "radial-gradient(rgba(255,255,255,0.04) 1px, transparent 1px)",
          backgroundSize: "3px 3px", mixBlendMode: "overlay",
        }}
      />

      <div className="relative p-4">
        <div className="flex items-center justify-between mb-4 px-1">
          <div className="flex items-center gap-2">
            <Sparkles size={13} className="text-white" strokeWidth={2.4} />
            <span className="text-[10px] font-bold tracking-[0.3em] text-white/90 uppercase">Aurora · Mesh</span>
          </div>
          <span className="text-[9px] font-mono text-white/40">03·05</span>
        </div>

        <div className="grid grid-cols-2 gap-3">
          {T.map((t) => {
            const Icon = t.icon;
            return (
              <div
                key={t.k}
                className="relative rounded-2xl p-4 overflow-hidden"
                style={{
                  background: "rgba(255,255,255,0.04)",
                  border: "1px solid rgba(255,255,255,0.10)",
                  backdropFilter: "blur(24px)",
                  WebkitBackdropFilter: "blur(24px)",
                  boxShadow: "inset 0 1px 0 rgba(255,255,255,0.12), 0 12px 32px rgba(0,0,0,0.4)",
                }}
              >
                {/* shine */}
                <div
                  className="absolute -top-10 -right-10 w-28 h-28 rounded-full pointer-events-none"
                  style={{ background: t.grad, opacity: 0.35, filter: "blur(20px)" }}
                />

                <div
                  className="relative w-10 h-10 rounded-xl flex items-center justify-center"
                  style={{ background: t.grad, boxShadow: "inset 0 1px 0 rgba(255,255,255,0.4), 0 6px 16px rgba(0,0,0,0.4)" }}
                >
                  <Icon size={18} color="#fff" strokeWidth={2.4} />
                </div>

                <div className="mt-4 text-[10px] font-bold tracking-[0.25em] uppercase text-white/60">{t.k}</div>
                <div
                  className="mt-1 text-[34px] leading-none font-black tabular-nums tracking-tighter"
                  style={{ background: t.grad, WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent", backgroundClip: "text" }}
                >
                  {t.c}
                </div>

                {/* alt çizgi */}
                <div className="mt-3 h-px w-full" style={{ background: "linear-gradient(90deg, rgba(255,255,255,0.15), transparent)" }} />
                <div className="mt-2 flex items-center justify-between text-[10px] font-medium text-white/40">
                  <span>kayıt</span>
                  <span className="tabular-nums text-emerald-300/80">+{Math.round(t.c * 0.05)}</span>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
