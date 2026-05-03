import { Users, Package, Truck, ShoppingCart, Hammer, Scale, ChevronRight } from "lucide-react";

const T = [
  { k: "Puantaj",      c: 47,  icon: Users,        color: "#f59e0b", sub: "12 firma" },
  { k: "Malzeme",      c: 184, icon: Package,      color: "#0ea5e9", sub: "Stok hareketi" },
  { k: "Sevkiyat",     c: 9,   icon: Truck,        color: "#10b981", sub: "Bugün" },
  { k: "Satın Alma",   c: 23,  icon: ShoppingCart, color: "#a855f7", sub: "Bekleyen" },
  { k: "İmalat",       c: 56,  icon: Hammer,       color: "#ef4444", sub: "Aktif kayıt" },
  { k: "Kantar",       c: 312, icon: Scale,        color: "#e85d04", sub: "Tartım" },
];

export function Steel() {
  return (
    <div className="min-h-screen bg-[#0f172a] p-4 font-['Inter']">
      <div className="text-[10px] font-bold tracking-[0.2em] text-slate-400 uppercase mb-3 px-1">Steel & Concrete</div>
      <div className="grid grid-cols-2 gap-3">
        {T.map((t) => {
          const Icon = t.icon;
          return (
            <div key={t.k} className="relative bg-[#1e293b] border border-slate-700/60 rounded-lg overflow-hidden p-3 pl-4 shadow-lg">
              <div className="absolute left-0 top-0 bottom-0 w-1" style={{ background: t.color }} />
              <div className="flex items-start justify-between mb-3">
                <div className="w-10 h-10 rounded-md flex items-center justify-center" style={{ background: t.color + "22", border: `1px solid ${t.color}55` }}>
                  <Icon size={18} color={t.color} strokeWidth={2.2} />
                </div>
                <div className="text-[9px] font-bold tracking-wider text-slate-500 uppercase mt-1">#{String(T.indexOf(t)+1).padStart(2,"0")}</div>
              </div>
              <div className="text-[13px] font-bold text-white tracking-wide uppercase leading-tight">{t.k}</div>
              <div className="mt-2 flex items-baseline gap-1.5">
                <div className="text-2xl font-black text-white tabular-nums">{t.c}</div>
                <div className="text-[10px] text-slate-400 font-medium">{t.sub}</div>
              </div>
              <div className="mt-2 h-px bg-slate-700/60" />
              <div className="mt-2 flex items-center justify-between">
                <span className="text-[9px] font-bold tracking-widest text-slate-500 uppercase">Aç</span>
                <ChevronRight size={12} className="text-slate-500" />
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
