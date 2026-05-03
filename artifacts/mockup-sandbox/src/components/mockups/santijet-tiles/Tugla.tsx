import { Users, Package, Truck, ShoppingCart, Hammer, Scale } from "lucide-react";

const T = [
  { k: "Puantaj",    c: 47,  icon: Users },
  { k: "Malzeme",    c: 184, icon: Package },
  { k: "Sevkiyat",   c: 9,   icon: Truck },
  { k: "Satın Alma", c: 23,  icon: ShoppingCart },
  { k: "İmalat",     c: 56,  icon: Hammer },
  { k: "Kantar",     c: 312, icon: Scale },
];

export function Tugla() {
  // tuğla duvar dokusu — running bond pattern
  const brick = `
    linear-gradient(335deg, #9a3412 0 8%, transparent 8%),
    linear-gradient(155deg, #c2410c 0 8%, transparent 8%),
    repeating-linear-gradient(0deg, #78350f 0 1px, transparent 1px 28px),
    repeating-linear-gradient(90deg, #78350f 0 1px, transparent 1px 56px)
  `;
  return (
    <div
      className="min-h-screen p-4 font-['Inter']"
      style={{
        background: "#9a3412",
        backgroundImage: brick,
      }}
    >
      <div
        className="flex items-center justify-between mb-3 px-3 py-1.5 rounded-sm"
        style={{ background: "#fef3c7", border: "1px solid #92400e", boxShadow: "0 2px 0 #78350f" }}
      >
        <div className="text-[10px] font-bold tracking-[0.25em] text-stone-900 uppercase">⌬ Tuğla & Harç</div>
        <span className="text-[9px] font-mono text-stone-700">m² · 1240</span>
      </div>

      <div className="grid grid-cols-2 gap-2.5">
        {T.map((t, i) => {
          const Icon = t.icon;
          return (
            <div
              key={t.k}
              className="relative p-3"
              style={{
                background: "#fef3c7",
                border: "1px solid #92400e",
                boxShadow: "inset 0 0 0 2px #fef3c7, inset 0 0 0 3px #92400e44, 0 3px 0 0 #78350f, 0 5px 10px rgba(0,0,0,0.3)",
                marginLeft: i % 2 === 0 ? 0 : 8,
                marginRight: i % 2 === 0 ? 8 : 0,
              }}
            >
              <div className="flex items-start justify-between">
                <div
                  className="w-10 h-10 rounded-sm flex items-center justify-center"
                  style={{ background: "#9a3412", boxShadow: "inset 0 -2px 0 #7c2d12" }}
                >
                  <Icon size={20} color="#fef3c7" strokeWidth={2.4} />
                </div>
                <span className="text-[9px] font-black text-stone-700 tracking-widest uppercase">No · {String(i+1).padStart(2,"0")}</span>
              </div>
              <div className="mt-2.5 text-[13px] font-extrabold text-stone-900 uppercase tracking-wider">{t.k}</div>
              <div className="mt-1 flex items-baseline justify-between border-t border-dashed border-stone-700/40 pt-1.5">
                <span className="text-[10px] font-semibold text-stone-700 uppercase">Adet</span>
                <span className="text-xl font-black text-orange-800 tabular-nums">{t.c}</span>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
