import { Users, Package, Truck, ShoppingCart, Hammer, Scale, Wrench } from "lucide-react";

const T = [
  { k: "Puantaj",    c: 47,  icon: Users,        tag: "İK" },
  { k: "Malzeme",    c: 184, icon: Package,      tag: "DEPO" },
  { k: "Sevkiyat",   c: 9,   icon: Truck,        tag: "LOJ" },
  { k: "Satın Alma", c: 23,  icon: ShoppingCart, tag: "TED" },
  { k: "İmalat",     c: 56,  icon: Hammer,       tag: "ÜRT" },
  { k: "Kantar",     c: 312, icon: Scale,        tag: "TRT" },
];

function Bolt() {
  return (
    <div className="w-2 h-2 rounded-full bg-stone-700 border border-stone-900 shadow-inner" style={{ boxShadow: "inset 0 0 1px #000, inset 1px 1px 0 #57534e" }} />
  );
}

export function Scaffold() {
  return (
    <div
      className="min-h-screen p-4 font-['Inter']"
      style={{
        background: "linear-gradient(180deg, #44403c 0%, #292524 100%)",
        backgroundImage:
          "linear-gradient(180deg, #44403c 0%, #292524 100%), repeating-linear-gradient(0deg, transparent 0 39px, rgba(0,0,0,0.15) 39px 40px)",
      }}
    >
      <div className="flex items-center justify-between mb-3 px-1">
        <div className="flex items-center gap-2">
          <Wrench size={14} className="text-amber-400" strokeWidth={2.5} />
          <div className="text-[10px] font-bold tracking-[0.25em] text-amber-400 uppercase">İSKELE · Çelik Yapı</div>
        </div>
        <span className="text-[9px] font-mono text-stone-400">EN-12810</span>
      </div>

      <div className="grid grid-cols-2 gap-3">
        {T.map((t) => {
          const Icon = t.icon;
          return (
            <div
              key={t.k}
              className="relative rounded-sm p-3 pt-4"
              style={{
                background: "linear-gradient(180deg, #78716c 0%, #57534e 100%)",
                border: "1px solid #1c1917",
                boxShadow: "inset 0 1px 0 #a8a29e, inset 0 -2px 4px rgba(0,0,0,0.4), 0 2px 6px rgba(0,0,0,0.5)",
              }}
            >
              <div className="absolute top-1 left-1"><Bolt /></div>
              <div className="absolute top-1 right-1"><Bolt /></div>
              <div className="absolute bottom-1 left-1"><Bolt /></div>
              <div className="absolute bottom-1 right-1"><Bolt /></div>

              <div className="flex items-start justify-between">
                <div className="w-10 h-10 rounded-sm flex items-center justify-center" style={{ background: "#1c1917", border: "1px solid #000", boxShadow: "inset 0 1px 0 #44403c" }}>
                  <Icon size={20} color="#fbbf24" strokeWidth={2.2} />
                </div>
                <div className="bg-amber-400 text-stone-900 px-1.5 py-0.5 text-[8px] font-black tracking-widest rounded-sm">{t.tag}</div>
              </div>

              <div className="mt-3 text-[13px] font-bold text-white uppercase tracking-wider drop-shadow">{t.k}</div>
              <div className="mt-1 flex items-baseline justify-between">
                <span className="text-[10px] text-stone-300 uppercase">Toplam</span>
                <span className="text-xl font-black text-amber-400 tabular-nums" style={{ textShadow: "0 1px 0 #000" }}>{t.c}</span>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
