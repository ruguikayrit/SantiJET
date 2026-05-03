import { Users, Package, Truck, ShoppingCart, Hammer, Scale, Waves } from "lucide-react";

const T = [
  { k: "Puantaj",    c: 47,  icon: Users,        grad: "linear-gradient(135deg,#22d3ee,#3b82f6)" },
  { k: "Malzeme",    c: 184, icon: Package,      grad: "linear-gradient(135deg,#06b6d4,#1e40af)" },
  { k: "Sevkiyat",   c: 9,   icon: Truck,        grad: "linear-gradient(135deg,#67e8f9,#0e7490)" },
  { k: "Satın Alma", c: 23,  icon: ShoppingCart, grad: "linear-gradient(135deg,#818cf8,#1e3a8a)" },
  { k: "İmalat",     c: 56,  icon: Hammer,       grad: "linear-gradient(135deg,#a78bfa,#4338ca)" },
  { k: "Kantar",     c: 312, icon: Scale,        grad: "linear-gradient(135deg,#5eead4,#0f766e)" },
];

export function MeshOcean() {
  return (
    <div className="min-h-screen relative overflow-hidden font-['Inter']" style={{ background: "#020617" }}>
      <div className="absolute" style={{ top: -140, left: -100, width: 420, height: 420, borderRadius: "50%",
        background: "radial-gradient(circle, #06b6d4 0%, transparent 65%)", filter: "blur(60px)", opacity: 0.65 }} />
      <div className="absolute" style={{ top: 180, right: -120, width: 460, height: 460, borderRadius: "50%",
        background: "radial-gradient(circle, #4338ca 0%, transparent 65%)", filter: "blur(70px)", opacity: 0.6 }} />
      <div className="absolute" style={{ bottom: -120, left: 80, width: 400, height: 400, borderRadius: "50%",
        background: "radial-gradient(circle, #14b8a6 0%, transparent 65%)", filter: "blur(70px)", opacity: 0.4 }} />
      <div className="absolute" style={{ top: 380, left: 100, width: 240, height: 240, borderRadius: "50%",
        background: "radial-gradient(circle, #818cf8 0%, transparent 60%)", filter: "blur(50px)", opacity: 0.5 }} />
      <div className="absolute inset-0 pointer-events-none" style={{
        backgroundImage: "radial-gradient(rgba(255,255,255,0.05) 1px, transparent 1px)",
        backgroundSize: "3px 3px", mixBlendMode: "overlay" }} />

      <div className="relative p-4">
        <div className="flex items-center justify-between mb-4 px-1">
          <div className="flex items-center gap-2">
            <Waves size={13} className="text-cyan-300" strokeWidth={2.4} />
            <span className="text-[10px] font-bold tracking-[0.3em] text-white/90 uppercase">Mesh · Ocean</span>
          </div>
          <span className="text-[9px] font-mono text-white/40">03·05</span>
        </div>

        <div className="grid grid-cols-2 gap-3">
          {T.map((t) => {
            const Icon = t.icon;
            return (
              <div key={t.k} className="relative rounded-2xl p-4 overflow-hidden"
                style={{ background: "rgba(255,255,255,0.04)", border: "1px solid rgba(255,255,255,0.10)",
                  backdropFilter: "blur(24px)", WebkitBackdropFilter: "blur(24px)",
                  boxShadow: "inset 0 1px 0 rgba(255,255,255,0.12), 0 12px 32px rgba(0,0,0,0.45)" }}>
                <div className="absolute -top-10 -right-10 w-28 h-28 rounded-full pointer-events-none"
                  style={{ background: t.grad, opacity: 0.4, filter: "blur(20px)" }} />
                <div className="relative w-10 h-10 rounded-xl flex items-center justify-center"
                  style={{ background: t.grad, boxShadow: "inset 0 1px 0 rgba(255,255,255,0.4), 0 6px 16px rgba(0,0,0,0.4)" }}>
                  <Icon size={18} color="#fff" strokeWidth={2.4} />
                </div>
                <div className="mt-4 text-[10px] font-bold tracking-[0.25em] uppercase text-white/60">{t.k}</div>
                <div className="mt-1 text-[34px] leading-none font-black tabular-nums tracking-tighter"
                  style={{ background: t.grad, WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent", backgroundClip: "text" }}>
                  {t.c}
                </div>
                <div className="mt-3 h-px w-full" style={{ background: "linear-gradient(90deg, rgba(255,255,255,0.18), transparent)" }} />
                <div className="mt-2 flex items-center justify-between text-[10px] font-medium text-white/40">
                  <span>kayıt</span>
                  <span className="tabular-nums text-cyan-200/80">+{Math.round(t.c * 0.05)}</span>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
