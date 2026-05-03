import { Users, Package, Truck, ShoppingCart, Hammer, Scale } from "lucide-react";

const T = [
  { k: "Puantaj",    c: 47,  icon: Users,        stamp: "C25/30" },
  { k: "Malzeme",    c: 184, icon: Package,      stamp: "TS-500" },
  { k: "Sevkiyat",   c: 9,   icon: Truck,        stamp: "LOT-09" },
  { k: "Satın Alma", c: 23,  icon: ShoppingCart, stamp: "PO-23" },
  { k: "İmalat",     c: 56,  icon: Hammer,       stamp: "İŞ-56" },
  { k: "Kantar",     c: 312, icon: Scale,        stamp: "TON-3" },
];

export function Concrete() {
  return (
    <div
      className="min-h-screen p-4 font-['Inter']"
      style={{
        background: "#cbcbc7",
        backgroundImage:
          "radial-gradient(circle at 18% 30%, rgba(120,120,115,0.35) 0 1px, transparent 2px), radial-gradient(circle at 60% 70%, rgba(80,80,75,0.28) 0 1px, transparent 2px), radial-gradient(circle at 80% 20%, rgba(140,140,135,0.3) 0 1px, transparent 2px)",
        backgroundSize: "13px 13px, 19px 19px, 23px 23px",
      }}
    >
      <div className="flex items-center justify-between mb-3 px-1">
        <div className="text-[10px] font-bold tracking-[0.25em] text-stone-800 uppercase">⌬ Beton & Kalıp</div>
        <span className="text-[9px] font-mono text-stone-700">DÖKÜM 03/05</span>
      </div>

      <div className="grid grid-cols-2 gap-3">
        {T.map((t) => {
          const Icon = t.icon;
          return (
            <div
              key={t.k}
              className="relative rounded-sm p-3 overflow-hidden"
              style={{
                background: "#e7e5e0",
                boxShadow:
                  "inset 0 0 0 1px rgba(0,0,0,0.08), inset 0 0 0 4px #e7e5e0, 0 0 0 1px #57534e, 0 4px 0 0 #44403c, 0 6px 12px rgba(0,0,0,0.25)",
              }}
            >
              <div className="absolute top-1.5 left-1.5 w-1 h-1 rounded-full bg-stone-700" />
              <div className="absolute top-1.5 right-1.5 w-1 h-1 rounded-full bg-stone-700" />
              <div className="absolute bottom-1.5 left-1.5 w-1 h-1 rounded-full bg-stone-700" />
              <div className="absolute bottom-1.5 right-1.5 w-1 h-1 rounded-full bg-stone-700" />

              <div className="flex items-start justify-between">
                <div className="w-11 h-11 rounded-sm flex items-center justify-center" style={{ background: "#e85d04", boxShadow: "inset 0 -2px 0 #9a3412" }}>
                  <Icon size={22} color="#fff" strokeWidth={2.4} />
                </div>
                <div
                  className="text-[8px] font-black text-stone-900 px-1.5 py-0.5 border border-stone-900 rounded-sm tracking-widest"
                  style={{ transform: "rotate(-6deg)", background: "rgba(232,93,4,0.12)" }}
                >
                  {t.stamp}
                </div>
              </div>

              <div className="mt-3 text-[13px] font-extrabold text-stone-900 uppercase tracking-wider">{t.k}</div>
              <div className="mt-1.5 h-px bg-stone-400/60" />
              <div className="mt-1.5 flex items-baseline justify-between">
                <span className="text-[10px] font-semibold text-stone-600 uppercase tracking-wider">Kayıt</span>
                <span className="text-[22px] leading-none font-black text-stone-900 tabular-nums">{t.c}</span>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
