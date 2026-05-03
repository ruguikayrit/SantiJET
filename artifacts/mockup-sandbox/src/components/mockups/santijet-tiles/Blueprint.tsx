import { Users, Package, Truck, ShoppingCart, Hammer, Scale, Plus } from "lucide-react";

const T = [
  { k: "PUANTAJ",    c: 47,  icon: Users,        ref: "P-01" },
  { k: "MALZEME",    c: 184, icon: Package,      ref: "M-02" },
  { k: "SEVKİYAT",   c: 9,   icon: Truck,        ref: "S-03" },
  { k: "SATIN ALMA", c: 23,  icon: ShoppingCart, ref: "A-04" },
  { k: "İMALAT",     c: 56,  icon: Hammer,       ref: "İ-05" },
  { k: "KANTAR",     c: 312, icon: Scale,        ref: "K-06" },
];

export function Blueprint() {
  const grid = `linear-gradient(#e7d9b8 1px, transparent 1px), linear-gradient(90deg, #e7d9b8 1px, transparent 1px)`;
  return (
    <div
      className="min-h-screen p-4 font-['JetBrains_Mono']"
      style={{ background: "#f5ecd6", backgroundImage: grid, backgroundSize: "20px 20px" }}
    >
      <div className="text-[10px] font-bold tracking-[0.3em] text-stone-700 mb-3 px-1">— BLUEPRINT / ŞANTİJET</div>
      <div className="grid grid-cols-2 gap-3">
        {T.map((t) => {
          const Icon = t.icon;
          return (
            <div key={t.k} className="relative bg-[#fbf6e8] border-2 border-stone-800 rounded-none p-3" style={{ boxShadow: "3px 3px 0 0 #1c1917" }}>
              <div className="absolute -top-2 left-3 bg-[#e85d04] text-white text-[9px] font-bold px-1.5 py-0.5 tracking-widest">{t.ref}</div>
              <div className="flex items-start justify-between mt-1">
                <div className="w-9 h-9 border-2 border-stone-800 bg-white flex items-center justify-center">
                  <Icon size={18} color="#1c1917" strokeWidth={2} />
                </div>
                <Plus size={14} className="text-stone-400" strokeWidth={2.5} />
              </div>
              <div className="mt-3 text-[12px] font-bold text-stone-900 tracking-widest">{t.k}</div>
              <div className="mt-2 flex items-baseline gap-2 border-t border-dashed border-stone-400 pt-2">
                <span className="text-[10px] text-stone-500 uppercase tracking-wider">Adet</span>
                <span className="text-xl font-black text-stone-900 tabular-nums ml-auto">{String(t.c).padStart(3,"0")}</span>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
