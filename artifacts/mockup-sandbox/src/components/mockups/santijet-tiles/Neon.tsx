import { Users, Package, Truck, ShoppingCart, Hammer, Scale, Activity } from "lucide-react";

const T = [
  { k: "PUANTAJ",    c: 47,  icon: Users,        color: "#22d3ee", code: "0x01" },
  { k: "MALZEME",    c: 184, icon: Package,      color: "#a78bfa", code: "0x02" },
  { k: "SEVKİYAT",   c: 9,   icon: Truck,        color: "#34d399", code: "0x03" },
  { k: "SATIN ALMA", c: 23,  icon: ShoppingCart, color: "#f472b6", code: "0x04" },
  { k: "İMALAT",     c: 56,  icon: Hammer,       color: "#fb923c", code: "0x05" },
  { k: "KANTAR",     c: 312, icon: Scale,        color: "#facc15", code: "0x06" },
];

export function Neon() {
  const grid = `linear-gradient(#22d3ee0a 1px, transparent 1px), linear-gradient(90deg, #22d3ee0a 1px, transparent 1px)`;
  return (
    <div
      className="min-h-screen p-4 font-['JetBrains_Mono'] relative"
      style={{ background: "#04060d", backgroundImage: grid, backgroundSize: "32px 32px" }}
    >
      <div className="absolute inset-x-0 top-0 h-px" style={{ background: "linear-gradient(90deg, transparent, #22d3ee, transparent)" }} />
      <div className="flex items-center justify-between mb-3 px-1">
        <div className="flex items-center gap-2">
          <div className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" style={{ boxShadow: "0 0 8px #34d399" }} />
          <span className="text-[10px] font-bold tracking-[0.3em] text-emerald-400 uppercase" style={{ textShadow: "0 0 8px #34d39988" }}>SİSTEM · ONLINE</span>
        </div>
        <span className="text-[9px] font-mono text-cyan-300/70">v2.6.4</span>
      </div>

      <div className="grid grid-cols-2 gap-3">
        {T.map((t) => {
          const Icon = t.icon;
          return (
            <div
              key={t.k}
              className="relative rounded-md p-3 overflow-hidden"
              style={{
                background: "linear-gradient(180deg, #0b1224 0%, #050810 100%)",
                border: `1px solid ${t.color}55`,
                boxShadow: `0 0 0 1px ${t.color}22, 0 0 24px ${t.color}33, inset 0 1px 0 ${t.color}22`,
              }}
            >
              <div className="absolute top-0 left-0 right-0 h-px" style={{ background: t.color, opacity: 0.7, boxShadow: `0 0 6px ${t.color}` }} />
              <div className="absolute top-1.5 right-2 flex items-center gap-1">
                <Activity size={8} color={t.color} strokeWidth={2.5} />
                <span className="text-[8px] font-mono" style={{ color: t.color }}>{t.code}</span>
              </div>

              <div
                className="w-10 h-10 rounded flex items-center justify-center"
                style={{ background: `${t.color}11`, border: `1px solid ${t.color}66`, boxShadow: `inset 0 0 12px ${t.color}33` }}
              >
                <Icon size={18} color={t.color} strokeWidth={2} style={{ filter: `drop-shadow(0 0 4px ${t.color})` }} />
              </div>

              <div className="mt-3 text-[11px] font-bold tracking-[0.2em] text-white/80">{t.k}</div>
              <div className="mt-1 flex items-baseline gap-1.5">
                <span
                  className="text-[26px] leading-none font-black tabular-nums"
                  style={{ color: t.color, textShadow: `0 0 12px ${t.color}aa, 0 0 2px ${t.color}` }}
                >
                  {String(t.c).padStart(3, "0")}
                </span>
              </div>

              {/* mini sparkline */}
              <svg width="100%" height="14" className="mt-2" viewBox="0 0 100 14">
                <path
                  d="M0 10 L15 7 L30 9 L45 4 L60 6 L75 2 L100 5"
                  stroke={t.color}
                  strokeWidth="1"
                  fill="none"
                  style={{ filter: `drop-shadow(0 0 3px ${t.color})` }}
                />
              </svg>
            </div>
          );
        })}
      </div>
    </div>
  );
}
