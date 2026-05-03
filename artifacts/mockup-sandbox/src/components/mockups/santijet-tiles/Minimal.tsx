import { Users, Package, Truck, ShoppingCart, Hammer, Scale, ArrowUpRight } from "lucide-react";

const T = [
  { k: "Puantaj",    c: 47,  icon: Users,        color: "#e85d04" },
  { k: "Malzeme",    c: 184, icon: Package,      color: "#0369a1" },
  { k: "Sevkiyat",   c: 9,   icon: Truck,        color: "#047857" },
  { k: "Satın Alma", c: 23,  icon: ShoppingCart, color: "#7c3aed" },
  { k: "İmalat",     c: 56,  icon: Hammer,       color: "#b91c1c" },
  { k: "Kantar",     c: 312, icon: Scale,        color: "#c2410c" },
];

export function Minimal() {
  return (
    <div className="min-h-screen bg-[#fafaf9] p-4 font-['Inter']">
      <div className="text-[10px] font-bold tracking-[0.2em] text-stone-500 uppercase mb-3 px-1">Minimal Pro</div>
      <div className="grid grid-cols-2 gap-2.5">
        {T.map((t) => {
          const Icon = t.icon;
          return (
            <div key={t.k} className="bg-white border border-stone-200 rounded-md p-3.5 hover:border-stone-300 transition">
              <div className="flex items-center justify-between">
                <Icon size={18} color={t.color} strokeWidth={2} />
                <ArrowUpRight size={14} className="text-stone-300" strokeWidth={2.2} />
              </div>
              <div className="mt-5 text-[13px] font-semibold text-stone-900 tracking-tight">{t.k}</div>
              <div className="mt-0.5 flex items-baseline gap-1.5">
                <div className="text-[11px] text-stone-400 font-medium tabular-nums">{t.c} kayıt</div>
              </div>
              <div className="mt-3 h-0.5 w-8 rounded-full" style={{ background: t.color }} />
            </div>
          );
        })}
      </div>
    </div>
  );
}
