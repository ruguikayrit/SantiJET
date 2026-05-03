import { Users, Package, Truck, ShoppingCart, Hammer, Scale, ChevronRight, Eye } from "lucide-react";

const T = [
  { k: "Puantaj",    c: 47,  icon: Users,        color: "#e85d04", bg: "#fff7ed", sub: "12 firma · bugün", perm: "edit" },
  { k: "Malzeme",    c: 184, icon: Package,      color: "#0ea5e9", bg: "#f0f9ff", sub: "Stok hareketi",     perm: "edit" },
  { k: "Sevkiyat",   c: 9,   icon: Truck,        color: "#16a34a", bg: "#f0fdf4", sub: "Bekleyen 3",        perm: "view" },
  { k: "Satın Alma", c: 23,  icon: ShoppingCart, color: "#a855f7", bg: "#faf5ff", sub: "Onay bekleyen 5",   perm: "edit" },
  { k: "İmalat",     c: 56,  icon: Hammer,       color: "#dc2626", bg: "#fef2f2", sub: "Aktif kayıt",       perm: "edit" },
  { k: "Kantar",     c: 312, icon: Scale,        color: "#d97706", bg: "#fffbeb", sub: "Bu hafta tartım",   perm: "edit" },
];

export function Liste() {
  return (
    <div className="min-h-screen bg-slate-50 p-4 font-['Inter']">
      <div className="text-[10px] font-bold tracking-[0.2em] text-slate-500 uppercase mb-3 px-1">Liste / Compact</div>
      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden divide-y divide-slate-100 shadow-sm">
        {T.map((t) => {
          const Icon = t.icon;
          return (
            <div key={t.k} className="flex items-center gap-3 px-3 py-3 active:bg-slate-50">
              <div className="w-11 h-11 rounded-lg flex items-center justify-center shrink-0" style={{ background: t.bg }}>
                <Icon size={20} color={t.color} strokeWidth={2.2} />
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-1.5">
                  <span className="text-[14px] font-semibold text-slate-900 truncate">{t.k}</span>
                  {t.perm === "view" && (
                    <span className="inline-flex items-center gap-0.5 px-1 py-px rounded bg-sky-50 text-sky-600">
                      <Eye size={9} strokeWidth={2.5} />
                      <span className="text-[8px] font-bold uppercase tracking-wider">Salt okur</span>
                    </span>
                  )}
                </div>
                <div className="text-[11px] text-slate-500 truncate">{t.sub}</div>
              </div>
              <div className="flex items-center gap-2 shrink-0">
                <div className="px-2 py-0.5 rounded-md tabular-nums text-[12px] font-bold" style={{ background: t.bg, color: t.color }}>
                  {t.c}
                </div>
                <ChevronRight size={16} className="text-slate-300" />
              </div>
            </div>
          );
        })}
      </div>
      <div className="mt-3 text-[10px] text-slate-400 text-center font-medium">Uzun bas → sıralama / gizle</div>
    </div>
  );
}
