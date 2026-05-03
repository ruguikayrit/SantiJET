import { Users, Package, Truck, ShoppingCart, Hammer, Scale } from "lucide-react";

const T = [
  { k: "Puantaj",    c: 47,  icon: Users,        idx: "01" },
  { k: "Malzeme",    c: 184, icon: Package,      idx: "02" },
  { k: "Sevkiyat",   c: 9,   icon: Truck,        idx: "03" },
  { k: "Satın Alma", c: 23,  icon: ShoppingCart, idx: "04" },
  { k: "İmalat",     c: 56,  icon: Hammer,       idx: "05" },
  { k: "Kantar",     c: 312, icon: Scale,        idx: "06" },
];

export function Editorial() {
  return (
    <div className="min-h-screen bg-[#f4f1ec] font-['Inter'] relative">
      {/* swiss grid lines */}
      <div className="absolute inset-0 pointer-events-none" style={{
        backgroundImage: "linear-gradient(90deg, rgba(0,0,0,0.04) 1px, transparent 1px)",
        backgroundSize: "33.33% 100%",
      }} />

      <div className="relative px-5 pt-5 pb-3 border-b border-stone-900">
        <div className="flex items-baseline justify-between">
          <div className="text-[9px] font-bold tracking-[0.4em] uppercase text-stone-900">№ 047 · Saha Bülteni</div>
          <div className="text-[9px] font-mono text-stone-500">03 · V · 2026</div>
        </div>
        <div
          className="mt-1 leading-none font-black tracking-tighter text-stone-900"
          style={{ fontFamily: "'Playfair Display', Georgia, serif", fontSize: 44, fontStyle: "italic" }}
        >
          Şantiye<br/><span className="not-italic" style={{ fontFamily: "Inter", fontWeight: 900, letterSpacing: "-0.04em" }}>BUGÜN.</span>
        </div>
      </div>

      <div className="relative px-3 pt-3 pb-6 grid grid-cols-2 gap-px bg-stone-900/15">
        {T.map((t, i) => {
          const Icon = t.icon;
          const featured = i === 0; // hero
          return (
            <div
              key={t.k}
              className={`bg-[#f4f1ec] p-4 ${featured ? "col-span-2" : ""}`}
            >
              <div className="flex items-baseline justify-between mb-2">
                <span className="text-[9px] font-mono text-stone-500 tracking-widest">{t.idx} —</span>
                <Icon size={featured ? 18 : 14} className="text-stone-900" strokeWidth={1.6} />
              </div>

              {featured ? (
                <div className="grid grid-cols-5 gap-3 items-end">
                  <div className="col-span-3">
                    <div className="text-[11px] font-bold tracking-[0.3em] uppercase text-stone-600">{t.k}</div>
                    <div
                      className="mt-1 leading-[0.85] font-black tracking-tighter text-stone-900"
                      style={{ fontSize: 96, letterSpacing: "-0.07em" }}
                    >
                      {t.c}
                    </div>
                  </div>
                  <div className="col-span-2 text-[11px] leading-snug text-stone-700 border-l border-stone-900 pl-3 pb-1">
                    Bugün sahada toplam <span className="font-bold">{t.c}</span> kayıt. Üç firma, on iki grup. Akşam 18:00'de kapanış.
                  </div>
                </div>
              ) : (
                <>
                  <div
                    className="leading-[0.85] font-black tracking-tighter text-stone-900"
                    style={{ fontSize: 56, letterSpacing: "-0.06em" }}
                  >
                    {t.c}
                  </div>
                  <div className="mt-2 text-[10px] font-bold tracking-[0.25em] uppercase text-stone-700 border-t border-stone-900 pt-1.5">
                    {t.k}
                  </div>
                </>
              )}
            </div>
          );
        })}
      </div>

      <div className="px-5 py-2 border-t border-stone-900 flex items-center justify-between text-[9px] font-mono text-stone-600">
        <span>SANTI·JET · ED.047</span>
        <span>· · ·</span>
        <span>p. 01/01</span>
      </div>
    </div>
  );
}
