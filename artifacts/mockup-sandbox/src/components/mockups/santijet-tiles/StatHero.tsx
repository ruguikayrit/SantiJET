import { Users, Package, Truck, ShoppingCart, Hammer, Scale, TrendingUp } from "lucide-react";

const T = [
  { k: "Puantaj",    c: 47,  icon: Users,        color: "#e85d04", bg: "#fff7ed", trend: "+4" },
  { k: "Malzeme",    c: 184, icon: Package,      color: "#0ea5e9", bg: "#f0f9ff", trend: "+12" },
  { k: "Sevkiyat",   c: 9,   icon: Truck,        color: "#16a34a", bg: "#f0fdf4", trend: "+1" },
  { k: "Satın Alma", c: 23,  icon: ShoppingCart, color: "#a855f7", bg: "#faf5ff", trend: "+3" },
  { k: "İmalat",     c: 56,  icon: Hammer,       color: "#dc2626", bg: "#fef2f2", trend: "+7" },
  { k: "Kantar",     c: 312, icon: Scale,        color: "#d97706", bg: "#fffbeb", trend: "+22" },
];

function Spark({ color }: { color: string }) {
  return (
    <svg width="56" height="18" viewBox="0 0 56 18" fill="none">
      <path d="M2 14 L10 10 L18 12 L26 6 L34 9 L42 4 L54 2"
        stroke={color} strokeWidth="1.6" fill="none" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

export function StatHero() {
  return (
    <div className="min-h-screen bg-[#f8fafc] p-4 font-['Inter']">
      <div className="text-[10px] font-bold tracking-[0.2em] text-slate-500 uppercase mb-3 px-1">Stat-Hero</div>
      <div className="grid grid-cols-2 gap-3">
        {T.map((t) => {
          const Icon = t.icon;
          return (
            <div key={t.k} className="bg-white rounded-xl border border-slate-200 p-3.5 shadow-sm">
              <div className="flex items-start justify-between">
                <div className="w-9 h-9 rounded-lg flex items-center justify-center" style={{ background: t.bg }}>
                  <Icon size={17} color={t.color} strokeWidth={2.2} />
                </div>
                <div className="flex items-center gap-0.5 px-1.5 py-0.5 rounded" style={{ background: t.bg }}>
                  <TrendingUp size={9} color={t.color} strokeWidth={2.5} />
                  <span className="text-[9px] font-bold tabular-nums" style={{ color: t.color }}>{t.trend}</span>
                </div>
              </div>
              <div className="mt-3 text-[28px] leading-none font-black text-slate-900 tabular-nums tracking-tight">{t.c}</div>
              <div className="mt-1 text-[12px] font-semibold text-slate-700">{t.k}</div>
              <div className="mt-2 flex items-end justify-between">
                <span className="text-[9px] font-medium text-slate-400 uppercase tracking-wider">Bu hafta</span>
                <Spark color={t.color} />
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
