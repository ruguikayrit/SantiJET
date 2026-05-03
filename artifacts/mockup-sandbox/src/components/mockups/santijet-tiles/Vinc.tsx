import { Users, Package, Truck, ShoppingCart, Hammer, Scale, ConstructionIcon } from "lucide-react";

const T = [
  { k: "Puantaj",    c: 47,  icon: Users },
  { k: "Malzeme",    c: 184, icon: Package },
  { k: "Sevkiyat",   c: 9,   icon: Truck },
  { k: "Satın Alma", c: 23,  icon: ShoppingCart },
  { k: "İmalat",     c: 56,  icon: Hammer },
  { k: "Kantar",     c: 312, icon: Scale },
];

function Crane() {
  return (
    <svg viewBox="0 0 200 80" className="w-full h-12 opacity-30">
      <line x1="40" y1="80" x2="40" y2="10" stroke="#1e293b" strokeWidth="3" />
      <line x1="40" y1="14" x2="180" y2="14" stroke="#1e293b" strokeWidth="3" />
      <line x1="40" y1="14" x2="20" y2="30" stroke="#1e293b" strokeWidth="2" />
      <line x1="160" y1="14" x2="160" y2="40" stroke="#1e293b" strokeWidth="1.5" />
      <rect x="155" y="40" width="10" height="6" fill="#e85d04" />
      <line x1="40" y1="14" x2="60" y2="22" stroke="#1e293b" strokeWidth="1" />
      <line x1="40" y1="14" x2="80" y2="20" stroke="#1e293b" strokeWidth="1" />
      <line x1="40" y1="14" x2="100" y2="18" stroke="#1e293b" strokeWidth="1" />
    </svg>
  );
}

export function Vinc() {
  return (
    <div
      className="min-h-screen p-4 font-['Inter'] relative overflow-hidden"
      style={{ background: "linear-gradient(180deg, #7dd3fc 0%, #bae6fd 40%, #fef3c7 100%)" }}
    >
      <div className="absolute top-8 right-0 left-0 pointer-events-none"><Crane /></div>
      <div className="absolute bottom-0 left-0 right-0 h-12" style={{ background: "linear-gradient(180deg, transparent, #d97706 80%)", opacity: 0.25 }} />

      <div className="relative">
        <div className="flex items-center gap-2 mb-3 px-1">
          <ConstructionIcon size={14} className="text-orange-700" strokeWidth={2.5} />
          <div className="text-[10px] font-bold tracking-[0.25em] text-stone-800 uppercase">Vinç · Saha Operasyonu</div>
        </div>

        <div className="grid grid-cols-2 gap-3 mt-14">
          {T.map((t) => {
            const Icon = t.icon;
            return (
              <div
                key={t.k}
                className="relative bg-white/80 rounded-xl border border-sky-200 p-3"
                style={{
                  backdropFilter: "blur(8px)",
                  boxShadow: "0 6px 18px rgba(2,132,199,0.18), inset 0 1px 0 rgba(255,255,255,0.9)",
                }}
              >
                {/* askı kablosu */}
                <div className="absolute -top-3 left-1/2 -translate-x-1/2 w-px h-3 bg-stone-700" />
                <div className="absolute -top-4 left-1/2 -translate-x-1/2 w-2 h-2 rotate-45 bg-orange-600 rounded-sm" />

                <div className="flex items-start justify-between">
                  <div className="w-10 h-10 rounded-lg bg-gradient-to-br from-orange-500 to-orange-700 flex items-center justify-center shadow-md">
                    <Icon size={18} color="#fff" strokeWidth={2.4} />
                  </div>
                  <div className="text-right">
                    <div className="text-[8px] font-bold tracking-widest text-sky-700 uppercase">Yük</div>
                    <div className="text-[20px] leading-none font-black text-stone-900 tabular-nums">{t.c}</div>
                  </div>
                </div>
                <div className="mt-2.5 text-[13px] font-bold text-stone-900 tracking-tight">{t.k}</div>
                <div className="mt-1.5 h-1 rounded-full bg-sky-100 overflow-hidden">
                  <div className="h-full bg-gradient-to-r from-orange-400 to-orange-600" style={{ width: `${Math.min(100, t.c / 3)}%` }} />
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
