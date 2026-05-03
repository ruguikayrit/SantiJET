import { Users, Package, Truck, ShoppingCart, Hammer, Scale } from "lucide-react";

const T = [
  { k: "Puantaj",    c: 47,  icon: Users,        top: "#fb923c", side: "#9a3412", deep: "#7c2d12" },
  { k: "Malzeme",    c: 184, icon: Package,      top: "#38bdf8", side: "#0369a1", deep: "#075985" },
  { k: "Sevkiyat",   c: 9,   icon: Truck,        top: "#34d399", side: "#047857", deep: "#065f46" },
  { k: "Satın Alma", c: 23,  icon: ShoppingCart, top: "#c084fc", side: "#7c3aed", deep: "#5b21b6" },
  { k: "İmalat",     c: 56,  icon: Hammer,       top: "#f87171", side: "#b91c1c", deep: "#991b1b" },
  { k: "Kantar",     c: 312, icon: Scale,        top: "#fbbf24", side: "#b45309", deep: "#92400e" },
];

export function Iso() {
  return (
    <div
      className="min-h-screen p-4 font-['Inter']"
      style={{
        background: "radial-gradient(ellipse at 50% 0%, #1e293b 0%, #020617 70%)",
      }}
    >
      <div className="flex items-center justify-between mb-3 px-1">
        <div className="flex items-center gap-2">
          <div className="w-2 h-2 rotate-45" style={{ background: "linear-gradient(135deg,#fb923c,#e85d04)" }} />
          <div className="text-[10px] font-bold tracking-[0.25em] text-white/80 uppercase">3D · Isometric</div>
        </div>
        <span className="text-[9px] font-mono text-white/40">// modules</span>
      </div>

      <div className="grid grid-cols-2 gap-x-3 gap-y-6 pt-2">
        {T.map((t) => {
          const Icon = t.icon;
          return (
            <div key={t.k} className="relative" style={{ paddingBottom: 18, paddingRight: 10 }}>
              {/* alt gölge — yer */}
              <div
                className="absolute"
                style={{
                  left: 8,
                  right: -2,
                  bottom: 4,
                  height: 10,
                  background: "radial-gradient(ellipse at center, rgba(0,0,0,0.55) 0%, transparent 70%)",
                  filter: "blur(2px)",
                }}
              />
              {/* sağ yan yüzey (kalınlık) */}
              <div
                className="absolute"
                style={{
                  top: 8,
                  right: 0,
                  bottom: 14,
                  width: 10,
                  background: `linear-gradient(180deg, ${t.side}, ${t.deep})`,
                  transform: "skewY(-30deg)",
                  transformOrigin: "top left",
                  borderRadius: "0 4px 4px 0",
                }}
              />
              {/* alt yüzey */}
              <div
                className="absolute"
                style={{
                  left: 8,
                  right: 0,
                  bottom: 8,
                  height: 10,
                  background: `linear-gradient(90deg, ${t.deep}, ${t.side})`,
                  transform: "skewX(-60deg)",
                  transformOrigin: "top left",
                  borderRadius: "0 0 4px 4px",
                }}
              />
              {/* üst kart */}
              <div
                className="relative rounded-lg p-3"
                style={{
                  background: `linear-gradient(135deg, ${t.top} 0%, ${t.side} 100%)`,
                  boxShadow: `inset 0 1px 0 rgba(255,255,255,0.4), inset 0 -1px 0 rgba(0,0,0,0.2)`,
                  marginRight: 0,
                  marginBottom: 8,
                }}
              >
                <div className="flex items-start justify-between">
                  <div
                    className="w-9 h-9 rounded-md flex items-center justify-center backdrop-blur-sm"
                    style={{ background: "rgba(255,255,255,0.22)", border: "1px solid rgba(255,255,255,0.4)" }}
                  >
                    <Icon size={17} color="#fff" strokeWidth={2.4} />
                  </div>
                  <div
                    className="px-1.5 py-0.5 rounded text-[9px] font-black tabular-nums"
                    style={{ background: "rgba(0,0,0,0.25)", color: "#fff", textShadow: "0 1px 0 rgba(0,0,0,0.3)" }}
                  >
                    {t.c}
                  </div>
                </div>
                <div className="mt-3 text-[13px] font-extrabold text-white tracking-tight" style={{ textShadow: "0 1px 0 rgba(0,0,0,0.25)" }}>
                  {t.k}
                </div>
                <div className="mt-0.5 text-[10px] font-semibold text-white/85">kayıt</div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
