import { Users, Package, Truck, ShoppingCart, Hammer, Scale, ArrowUpRight } from "lucide-react";

export function Bento() {
  return (
    <div className="min-h-screen bg-[#fafafa] p-3 font-['Inter']">
      <div className="flex items-center justify-between mb-3 px-1">
        <div className="text-[10px] font-bold tracking-[0.2em] text-stone-500 uppercase">Bento · Premium</div>
        <span className="text-[10px] font-medium text-stone-400">Bugün</span>
      </div>

      {/* Hero — Puantaj */}
      <div
        className="relative rounded-3xl p-5 mb-2.5 overflow-hidden"
        style={{ background: "linear-gradient(135deg, #1c1917 0%, #292524 100%)" }}
      >
        <div className="absolute -right-10 -top-10 w-40 h-40 rounded-full" style={{ background: "radial-gradient(circle, #e85d0466 0%, transparent 70%)" }} />
        <div className="relative flex items-start justify-between">
          <div>
            <div className="text-[10px] font-bold tracking-[0.25em] text-orange-400 uppercase">Puantaj</div>
            <div className="mt-2 text-[56px] leading-none font-black text-white tabular-nums tracking-tighter">47</div>
            <div className="mt-2 text-[12px] text-stone-400 font-medium">12 firma · 3 grup</div>
          </div>
          <div className="flex flex-col items-end gap-2">
            <div className="w-12 h-12 rounded-2xl bg-orange-500 flex items-center justify-center shadow-lg shadow-orange-500/40">
              <Users size={22} color="#fff" strokeWidth={2.4} />
            </div>
            <div className="flex items-center gap-1 px-2 py-0.5 rounded-full bg-white/10 backdrop-blur">
              <ArrowUpRight size={10} className="text-emerald-400" strokeWidth={3} />
              <span className="text-[10px] font-bold text-emerald-400 tabular-nums">+8</span>
            </div>
          </div>
        </div>
      </div>

      {/* Row 2: Malzeme (geniş) + Sevkiyat */}
      <div className="grid grid-cols-3 gap-2.5 mb-2.5">
        <div className="col-span-2 rounded-2xl bg-white border border-stone-200 p-4">
          <div className="flex items-center justify-between">
            <div className="w-9 h-9 rounded-xl bg-sky-50 flex items-center justify-center">
              <Package size={17} color="#0ea5e9" strokeWidth={2.2} />
            </div>
            <ArrowUpRight size={14} className="text-stone-300" />
          </div>
          <div className="mt-3 text-[28px] leading-none font-black text-stone-900 tabular-nums">184</div>
          <div className="mt-0.5 text-[12px] font-semibold text-stone-700">Malzeme</div>
          <div className="mt-2 h-1 rounded-full bg-stone-100 overflow-hidden">
            <div className="h-full bg-sky-500 rounded-full" style={{ width: "72%" }} />
          </div>
          <div className="mt-1 text-[10px] text-stone-400 font-medium">stok · %72 dolu</div>
        </div>
        <div
          className="rounded-2xl p-3 flex flex-col justify-between"
          style={{ background: "linear-gradient(160deg, #d1fae5 0%, #6ee7b7 100%)" }}
        >
          <div className="flex items-center justify-between">
            <Truck size={18} color="#065f46" strokeWidth={2.4} />
            <span className="text-[8px] font-black text-emerald-900/70 tracking-widest">SEV</span>
          </div>
          <div>
            <div className="text-[32px] leading-none font-black text-emerald-900 tabular-nums">9</div>
            <div className="text-[10px] font-semibold text-emerald-900/70">bugün</div>
          </div>
        </div>
      </div>

      {/* Row 3: 3 küçük */}
      <div className="grid grid-cols-3 gap-2.5 mb-2.5">
        {[
          { k: "Satın Alma", c: 23, icon: ShoppingCart, fg: "#7c2d92", bg: "linear-gradient(160deg,#f5d0fe,#e9d5ff)" },
          { k: "İmalat", c: 56, icon: Hammer, fg: "#991b1b", bg: "linear-gradient(160deg,#fecaca,#fca5a5)" },
          { k: "Kantar", c: 312, icon: Scale, fg: "#92400e", bg: "linear-gradient(160deg,#fed7aa,#fdba74)" },
        ].map((t) => {
          const Icon = t.icon;
          return (
            <div key={t.k} className="rounded-2xl p-3" style={{ background: t.bg }}>
              <Icon size={16} color={t.fg} strokeWidth={2.4} />
              <div className="mt-3 text-[20px] leading-none font-black tabular-nums" style={{ color: t.fg }}>{t.c}</div>
              <div className="text-[10px] font-bold mt-0.5 truncate" style={{ color: t.fg }}>{t.k}</div>
            </div>
          );
        })}
      </div>

      {/* alt CTA */}
      <div className="rounded-2xl bg-stone-900 p-3 flex items-center justify-between">
        <div>
          <div className="text-[10px] font-bold tracking-widest text-stone-400 uppercase">Asistan</div>
          <div className="text-[13px] font-bold text-white">Günlük rapor hazır</div>
        </div>
        <div className="w-9 h-9 rounded-full bg-orange-500 flex items-center justify-center">
          <ArrowUpRight size={16} color="#fff" strokeWidth={2.6} />
        </div>
      </div>
    </div>
  );
}
