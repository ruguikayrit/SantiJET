import { Users, Package, Truck, ShoppingCart, Hammer, Scale, Sun } from "lucide-react";

const T = [
  { k: "Puantaj",    c: 47,  icon: Users,        grad: "linear-gradient(135deg,#fb7185,#f97316)" },
  { k: "Malzeme",    c: 184, icon: Package,      grad: "linear-gradient(135deg,#60a5fa,#a78bfa)" },
  { k: "Sevkiyat",   c: 9,   icon: Truck,        grad: "linear-gradient(135deg,#34d399,#06b6d4)" },
  { k: "Satın Alma", c: 23,  icon: ShoppingCart, grad: "linear-gradient(135deg,#c084fc,#ec4899)" },
  { k: "İmalat",     c: 56,  icon: Hammer,       grad: "linear-gradient(135deg,#fbbf24,#f97316)" },
  { k: "Kantar",     c: 312, icon: Scale,        grad: "linear-gradient(135deg,#5eead4,#818cf8)" },
];

export function MeshPastel() {
  return (
    <div className="min-h-screen relative overflow-hidden font-['Inter']" style={{ background: "#fafaff" }}>
      <div className="absolute" style={{ top: -140, left: -100, width: 420, height: 420, borderRadius: "50%",
        background: "radial-gradient(circle, #fda4af 0%, transparent 65%)", filter: "blur(70px)", opacity: 0.85 }} />
      <div className="absolute" style={{ top: 200, right: -120, width: 460, height: 460, borderRadius: "50%",
        background: "radial-gradient(circle, #a5b4fc 0%, transparent 65%)", filter: "blur(80px)", opacity: 0.75 }} />
      <div className="absolute" style={{ bottom: -120, left: 80, width: 400, height: 400, borderRadius: "50%",
        background: "radial-gradient(circle, #6ee7b7 0%, transparent 65%)", filter: "blur(80px)", opacity: 0.55 }} />
      <div className="absolute" style={{ bottom: 200, right: 40, width: 260, height: 260, borderRadius: "50%",
        background: "radial-gradient(circle, #fcd34d 0%, transparent 60%)", filter: "blur(60px)", opacity: 0.55 }} />

      <div className="relative p-4">
        <div className="flex items-center justify-between mb-4 px-1">
          <div className="flex items-center gap-2">
            <Sun size={13} className="text-stone-700" strokeWidth={2.4} />
            <span className="text-[10px] font-bold tracking-[0.3em] text-stone-800 uppercase">Mesh · Pastel</span>
          </div>
          <span className="text-[9px] font-mono text-stone-500">03·05</span>
        </div>

        <div className="grid grid-cols-2 gap-3">
          {T.map((t) => {
            const Icon = t.icon;
            return (
              <div key={t.k} className="relative rounded-2xl p-4 overflow-hidden"
                style={{ background: "rgba(255,255,255,0.55)", border: "1px solid rgba(255,255,255,0.9)",
                  backdropFilter: "blur(24px)", WebkitBackdropFilter: "blur(24px)",
                  boxShadow: "inset 0 1px 0 rgba(255,255,255,0.9), 0 12px 28px rgba(120,80,160,0.18)" }}>
                <div className="absolute -top-10 -right-10 w-28 h-28 rounded-full pointer-events-none"
                  style={{ background: t.grad, opacity: 0.32, filter: "blur(22px)" }} />
                <div className="relative w-10 h-10 rounded-xl flex items-center justify-center"
                  style={{ background: t.grad, boxShadow: "inset 0 1px 0 rgba(255,255,255,0.55), 0 6px 14px rgba(0,0,0,0.18)" }}>
                  <Icon size={18} color="#fff" strokeWidth={2.4} />
                </div>
                <div className="mt-4 text-[10px] font-bold tracking-[0.25em] uppercase text-stone-600">{t.k}</div>
                <div className="mt-1 text-[34px] leading-none font-black tabular-nums tracking-tighter"
                  style={{ background: t.grad, WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent", backgroundClip: "text" }}>
                  {t.c}
                </div>
                <div className="mt-3 h-px w-full" style={{ background: "linear-gradient(90deg, rgba(0,0,0,0.10), transparent)" }} />
                <div className="mt-2 flex items-center justify-between text-[10px] font-medium text-stone-500">
                  <span>kayıt</span>
                  <span className="tabular-nums text-emerald-600">+{Math.round(t.c * 0.05)}</span>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
