import { Users, Package, Truck, ShoppingCart, Hammer, Scale, FileSignature } from "lucide-react";

const T = [
  { k: "Puantaj",    c: 47,  icon: Users,        no: "001" },
  { k: "Malzeme",    c: 184, icon: Package,      no: "002" },
  { k: "Sevkiyat",   c: 9,   icon: Truck,        no: "003" },
  { k: "Satın Alma", c: 23,  icon: ShoppingCart, no: "004" },
  { k: "İmalat",     c: 56,  icon: Hammer,       no: "005" },
  { k: "Kantar",     c: 312, icon: Scale,        no: "006" },
];

export function Tutanak() {
  const lined = `repeating-linear-gradient(180deg, transparent 0 27px, #c2410c22 27px 28px)`;
  return (
    <div
      className="min-h-screen p-4 font-['Inter']"
      style={{
        background: "#f5e9c8",
        backgroundImage:
          "radial-gradient(circle at 20% 30%, rgba(180,140,80,0.18) 0 1px, transparent 2px), radial-gradient(circle at 70% 80%, rgba(160,120,70,0.15) 0 1px, transparent 2px)",
        backgroundSize: "11px 11px, 17px 17px",
      }}
    >
      <div className="flex items-center justify-between mb-3 px-1">
        <div className="flex items-center gap-2">
          <FileSignature size={14} className="text-stone-800" strokeWidth={2.2} />
          <div className="text-[11px] font-bold tracking-[0.2em] text-stone-900 uppercase font-['Caveat']" style={{ fontFamily: "Caveat, cursive" }}>Şantiye Defteri</div>
        </div>
        <span className="text-[10px] font-mono text-stone-700">03·05·2026</span>
      </div>

      <div className="grid grid-cols-2 gap-3">
        {T.map((t) => {
          const Icon = t.icon;
          return (
            <div
              key={t.k}
              className="relative p-3 pt-4"
              style={{
                background: "#fdf6e3",
                backgroundImage: lined,
                border: "1px solid #b08968",
                boxShadow: "2px 3px 0 0 rgba(120,80,40,0.25), inset 0 0 0 1px rgba(176,137,104,0.4)",
                borderLeft: "3px solid #c2410c",
              }}
            >
              {/* perforaj delikleri */}
              <div className="absolute left-1.5 top-3 w-1.5 h-1.5 rounded-full bg-stone-300 border border-stone-400" />
              <div className="absolute left-1.5 top-1/2 w-1.5 h-1.5 rounded-full bg-stone-300 border border-stone-400" />
              <div className="absolute left-1.5 bottom-3 w-1.5 h-1.5 rounded-full bg-stone-300 border border-stone-400" />

              <div className="flex items-start justify-between pl-2.5">
                <div className="w-9 h-9 rounded-sm bg-white border border-stone-700 flex items-center justify-center" style={{ boxShadow: "1px 1px 0 #44403c" }}>
                  <Icon size={18} color="#1e3a8a" strokeWidth={2} />
                </div>
                <span
                  className="text-[10px] font-bold text-red-700 border border-red-700 rounded-full px-1.5 py-0.5 tabular-nums"
                  style={{ transform: "rotate(-8deg)", fontFamily: "Caveat, cursive", fontSize: 13 }}
                >
                  No: {t.no}
                </span>
              </div>

              <div className="mt-2.5 pl-2.5 text-[14px] font-bold text-stone-900 tracking-wide" style={{ color: "#1e3a8a" }}>{t.k}</div>
              <div className="mt-1 pl-2.5 flex items-baseline gap-2 border-t border-dashed border-stone-400 pt-1.5">
                <span className="text-[10px] text-stone-700 italic">adet</span>
                <span className="ml-auto text-xl font-black tabular-nums" style={{ fontFamily: "Caveat, cursive", color: "#1e3a8a", fontSize: 26 }}>{t.c}</span>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
