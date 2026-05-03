import { Users, Package, Truck, ShoppingCart, Hammer, Scale, ChevronRight } from "lucide-react";

const T = [
  { k: "Puantaj",    c: 47,  icon: Users,        color: "#fb923c" },
  { k: "Malzeme",    c: 184, icon: Package,      color: "#38bdf8" },
  { k: "Sevkiyat",   c: 9,   icon: Truck,        color: "#34d399" },
  { k: "Satın Alma", c: 23,  icon: ShoppingCart, color: "#c084fc" },
  { k: "İmalat",     c: 56,  icon: Hammer,       color: "#f87171" },
  { k: "Kantar",     c: 312, icon: Scale,        color: "#fbbf24" },
];

export function Glass() {
  return (
    <div
      className="min-h-screen p-4 font-['Inter'] relative overflow-hidden"
      style={{ background: "linear-gradient(135deg, #1e1b4b 0%, #312e81 40%, #4c1d95 100%)" }}
    >
      <div className="absolute -top-20 -left-10 w-72 h-72 rounded-full" style={{ background: "radial-gradient(circle, #e85d0455 0%, transparent 70%)" }} />
      <div className="absolute top-40 -right-20 w-80 h-80 rounded-full" style={{ background: "radial-gradient(circle, #38bdf855 0%, transparent 70%)" }} />
      <div className="relative">
        <div className="text-[10px] font-bold tracking-[0.2em] text-white/60 uppercase mb-3 px-1">Glass / Aurora</div>
        <div className="grid grid-cols-2 gap-3">
          {T.map((t) => {
            const Icon = t.icon;
            return (
              <div
                key={t.k}
                className="rounded-2xl p-3.5 border border-white/15"
                style={{
                  background: "rgba(255,255,255,0.08)",
                  backdropFilter: "blur(20px)",
                  WebkitBackdropFilter: "blur(20px)",
                  boxShadow: "inset 0 1px 0 rgba(255,255,255,0.18), 0 8px 24px rgba(0,0,0,0.25)",
                }}
              >
                <div className="flex items-center justify-between">
                  <div
                    className="w-10 h-10 rounded-xl flex items-center justify-center"
                    style={{ background: `linear-gradient(135deg, ${t.color}55, ${t.color}22)`, border: `1px solid ${t.color}66` }}
                  >
                    <Icon size={18} color={t.color} strokeWidth={2.2} />
                  </div>
                  <ChevronRight size={14} className="text-white/40" />
                </div>
                <div className="mt-3 text-[13px] font-semibold text-white tracking-tight">{t.k}</div>
                <div className="mt-1 flex items-baseline gap-1.5">
                  <span className="text-[20px] font-black tabular-nums" style={{ color: t.color }}>{t.c}</span>
                  <span className="text-[10px] text-white/50 font-medium">kayıt</span>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
