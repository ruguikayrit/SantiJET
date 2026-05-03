import { Users, Package, Truck, ShoppingCart, Hammer, Scale, HardHat, AlertTriangle } from "lucide-react";

const T = [
  { k: "PUANTAJ",    c: 47,  icon: Users,        code: "TS-01" },
  { k: "MALZEME",    c: 184, icon: Package,      code: "MT-02" },
  { k: "SEVKİYAT",   c: 9,   icon: Truck,        code: "SV-03" },
  { k: "SATIN ALMA", c: 23,  icon: ShoppingCart, code: "SA-04" },
  { k: "İMALAT",     c: 56,  icon: Hammer,       code: "IM-05" },
  { k: "KANTAR",     c: 312, icon: Scale,        code: "KN-06" },
];

const stripes = `repeating-linear-gradient(135deg, #1c1917 0 14px, #facc15 14px 28px)`;

export function HiVis() {
  return (
    <div className="min-h-screen bg-[#fef3c7] p-4 font-['Inter']">
      <div className="flex items-center gap-2 mb-3 px-1">
        <HardHat size={14} className="text-yellow-600" strokeWidth={2.5} />
        <div className="text-[10px] font-bold tracking-[0.25em] text-stone-900 uppercase">Hi-Vis · İSG Modu</div>
      </div>
      <div className="h-2 mb-3 rounded-sm" style={{ background: stripes }} />
      <div className="grid grid-cols-2 gap-3">
        {T.map((t) => {
          const Icon = t.icon;
          return (
            <div key={t.k} className="bg-yellow-300 border-2 border-stone-900 rounded-md overflow-hidden" style={{ boxShadow: "4px 4px 0 0 #1c1917" }}>
              <div className="flex items-center justify-between px-2 py-1 bg-stone-900">
                <div className="flex items-center gap-1">
                  <AlertTriangle size={9} className="text-yellow-300" strokeWidth={3} fill="#facc15" />
                  <span className="text-[8px] font-black text-yellow-300 tracking-[0.2em]">DİKKAT</span>
                </div>
                <span className="text-[8px] font-bold text-yellow-300 tabular-nums">{t.code}</span>
              </div>
              <div className="p-3">
                <div className="flex items-start justify-between">
                  <div className="w-10 h-10 rounded-md bg-stone-900 flex items-center justify-center">
                    <Icon size={20} color="#facc15" strokeWidth={2.4} />
                  </div>
                  <span className="text-[28px] leading-none font-black text-stone-900 tabular-nums">{t.c}</span>
                </div>
                <div className="mt-2 text-[12px] font-black text-stone-900 tracking-wider">{t.k}</div>
              </div>
              <div className="h-1.5" style={{ background: stripes }} />
            </div>
          );
        })}
      </div>
    </div>
  );
}
