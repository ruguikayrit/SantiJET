import { Users, Package, Truck, ShoppingCart, Hammer, Scale } from "lucide-react";

const T = [
  { k: "PUANTAJ",    c: 47,  icon: Users,        tag: "[HR]" },
  { k: "MALZEME",    c: 184, icon: Package,      tag: "[INV]" },
  { k: "SEVKIYAT",   c: 9,   icon: Truck,        tag: "[LOG]" },
  { k: "SATIN_ALMA", c: 23,  icon: ShoppingCart, tag: "[PO]" },
  { k: "IMALAT",     c: 56,  icon: Hammer,       tag: "[MFG]" },
  { k: "KANTAR",     c: 312, icon: Scale,        tag: "[WT]" },
];

export function Brutalist() {
  return (
    <div className="min-h-screen p-4 font-mono" style={{ background: "#eeece4" }}>
      {/* üst başlık */}
      <div className="border-2 border-black bg-white p-2.5 mb-3" style={{ boxShadow: "5px 5px 0 0 #000" }}>
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-3 h-3 bg-black" />
            <span className="text-[11px] font-black tracking-[0.2em] uppercase">SANTI · JET // v2.6</span>
          </div>
          <span className="text-[10px] font-bold">[ ON ]</span>
        </div>
        <div className="mt-1.5 border-t-2 border-dashed border-black pt-1 text-[9px] tracking-widest uppercase flex justify-between">
          <span>NODE: SHA-01</span><span>UPTIME: 14:32:09</span><span>OK</span>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-3">
        {T.map((t, i) => {
          const Icon = t.icon;
          const inverted = i === 0;
          return (
            <div
              key={t.k}
              className="border-2 border-black p-3 relative"
              style={{
                background: inverted ? "#000" : "#fff",
                color: inverted ? "#fff" : "#000",
                boxShadow: "5px 5px 0 0 #000",
              }}
            >
              {/* corner brackets */}
              <span className="absolute top-0.5 left-0.5 text-[8px]" style={{ color: inverted ? "#fff" : "#000" }}>┌</span>
              <span className="absolute top-0.5 right-0.5 text-[8px]" style={{ color: inverted ? "#fff" : "#000" }}>┐</span>
              <span className="absolute bottom-0.5 left-0.5 text-[8px]" style={{ color: inverted ? "#fff" : "#000" }}>└</span>
              <span className="absolute bottom-0.5 right-0.5 text-[8px]" style={{ color: inverted ? "#fff" : "#000" }}>┘</span>

              <div className="flex items-center justify-between text-[9px] font-bold">
                <span>{t.tag}</span>
                <span>{String(i + 1).padStart(2, "0")}/06</span>
              </div>

              <div className="mt-2 flex items-end justify-between">
                <Icon size={28} color={inverted ? "#fff" : "#000"} strokeWidth={2.2} />
                <span
                  className="font-black tabular-nums leading-none tracking-tighter"
                  style={{ fontSize: inverted ? 48 : 40 }}
                >
                  {t.c}
                </span>
              </div>

              <div
                className="mt-2 pt-1.5 border-t-2 border-dashed text-[12px] font-black tracking-widest"
                style={{ borderColor: inverted ? "#fff" : "#000" }}
              >
                {t.k}
              </div>

              {inverted && (
                <div className="mt-1 text-[8px] tracking-widest opacity-70">▶ ÖNCELIKLI MODÜL</div>
              )}
            </div>
          );
        })}
      </div>

      {/* alt status bar */}
      <div className="mt-3 border-2 border-black bg-yellow-300 p-1.5 text-[9px] font-black tracking-widest uppercase flex justify-between"
        style={{ boxShadow: "5px 5px 0 0 #000" }}>
        <span>★ TOPLAM 631</span>
        <span>SYNC: 00:00:12</span>
        <span>▒▒▒▒▒░░ 71%</span>
      </div>
    </div>
  );
}
