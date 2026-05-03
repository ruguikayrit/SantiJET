import React, { useEffect, useState } from 'react';
import { Link } from 'wouter';
import { useStore } from '@/store/useStore';
import { modules } from '@/data/mock-data';
import { Activity, Bell, AlertTriangle, CheckCircle2, Info, Users, Package, Truck, ShoppingCart, Hammer, Scale } from 'lucide-react';

const iconMap: Record<string, React.ElementType> = {
  Users, Package, Truck, ShoppingCart, Hammer, Scale, Activity
};

export default function Home() {
  const activities = useStore(state => state.activities);
  const puantaj = useStore(state => state.puantaj);
  const malzeme = useStore(state => state.malzeme);
  const sevkiyat = useStore(state => state.sevkiyat);
  const satinAlma = useStore(state => state.satinAlma);
  const imalat = useStore(state => state.imalat);
  const kantar = useStore(state => state.kantar);

  const getModuleCount = (id: string) => {
    switch (id) {
      case 'puantaj': return puantaj.length;
      case 'malzeme': return malzeme.length;
      case 'sevkiyat': return sevkiyat.length;
      case 'satin-alma': return satinAlma.length;
      case 'imalat': return imalat.length;
      case 'kantar': return kantar.length;
      default: return 0;
    }
  };

  return (
    <div className="h-full flex flex-col gap-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-xl font-bold tracking-widest text-slate-100">ANA EKRAN</h1>
          <p className="text-xs font-mono text-slate-500 mt-1">SİSTEM ÖZETİ // {new Date().toLocaleDateString('tr-TR')}</p>
        </div>
        <div className="flex gap-2">
          <div className="flex flex-col items-end">
            <span className="text-[10px] font-mono text-slate-500">AKTİF MODÜL</span>
            <span className="text-sm font-bold tracking-widest text-emerald-400" style={{ textShadow: '0 0 10px #34d39988' }}>{modules.length} / {modules.length}</span>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Module Tiles Grid */}
        <div className="lg:col-span-2 grid grid-cols-1 sm:grid-cols-2 gap-4">
          {modules.map((m) => {
            const Icon = iconMap[m.icon];
            const count = getModuleCount(m.id);
            return (
              <Link key={m.id} href={m.path} data-testid={`link-tile-${m.id}`}>
                <div 
                  className="relative rounded-md p-4 overflow-hidden cursor-pointer group transition-all duration-300 hover:-translate-y-1"
                  style={{
                    background: "linear-gradient(180deg, #0b1224 0%, #050810 100%)",
                    border: `1px solid ${m.color}55`,
                    boxShadow: `0 0 0 1px ${m.color}22, 0 0 24px ${m.color}11, inset 0 1px 0 ${m.color}22`,
                  }}
                >
                  <div 
                    className="absolute top-0 left-0 right-0 h-px transition-opacity duration-300 opacity-50 group-hover:opacity-100" 
                    style={{ background: m.color, boxShadow: `0 0 10px ${m.color}` }} 
                  />
                  
                  <div className="absolute top-2 right-3 flex items-center gap-1.5 opacity-60 group-hover:opacity-100 transition-opacity">
                    <Activity size={10} color={m.color} strokeWidth={2.5} />
                    <span className="text-[9px] font-mono" style={{ color: m.color }}>{m.code}</span>
                  </div>

                  <div 
                    className="w-12 h-12 rounded flex items-center justify-center transition-transform duration-300 group-hover:scale-110"
                    style={{ background: `${m.color}11`, border: `1px solid ${m.color}66`, boxShadow: `inset 0 0 15px ${m.color}33` }}
                  >
                    <Icon size={22} color={m.color} strokeWidth={2} style={{ filter: `drop-shadow(0 0 5px ${m.color})` }} />
                  </div>

                  <div className="mt-4 text-xs font-bold tracking-[0.2em] text-white/80">{m.name}</div>
                  <div className="mt-1 flex items-baseline gap-2">
                    <span 
                      className="text-3xl leading-none font-black tabular-nums transition-all duration-300"
                      style={{ color: m.color, textShadow: `0 0 15px ${m.color}aa, 0 0 2px ${m.color}` }}
                    >
                      {String(count).padStart(3, "0")}
                    </span>
                    <span className="text-[10px] font-mono text-slate-500 uppercase tracking-widest">Kayıt</span>
                  </div>

                  <svg width="100%" height="20" className="mt-3 opacity-50 group-hover:opacity-100 transition-opacity" viewBox="0 0 100 20" preserveAspectRatio="none">
                    <path
                      d="M0 15 L10 12 L20 18 L30 8 L40 14 L50 5 L60 16 L70 10 L80 15 L90 7 L100 12"
                      stroke={m.color}
                      strokeWidth="1.5"
                      fill="none"
                      style={{ filter: `drop-shadow(0 0 4px ${m.color})` }}
                    />
                  </svg>
                </div>
              </Link>
            );
          })}
        </div>

        {/* Istasyon Durumu Panel */}
        <div className="flex flex-col gap-4">
          <div className="border border-slate-800 rounded-md bg-[#0b1224]/80 overflow-hidden flex flex-col h-full relative" style={{ boxShadow: 'inset 0 0 30px rgba(0,0,0,0.5)' }}>
            <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-slate-500 to-transparent opacity-30" />
            
            <div className="p-3 border-b border-slate-800/50 flex items-center justify-between bg-slate-900/50">
              <div className="flex items-center gap-2">
                <Bell size={14} className="text-slate-400" />
                <span className="text-xs font-bold tracking-widest text-slate-300">İSTASYON DURUMU</span>
              </div>
              <span className="text-[10px] font-mono text-emerald-500 animate-pulse">LIVE</span>
            </div>

            <div className="p-4 flex flex-col gap-4">
              {/* KPIs */}
              <div className="grid grid-cols-2 gap-2">
                <div className="p-2 rounded bg-black/40 border border-slate-800 flex flex-col">
                  <span className="text-[9px] font-mono text-slate-500">SİSTEM YÜKÜ</span>
                  <span className="text-sm font-mono text-emerald-400 font-bold mt-1">24.5%</span>
                  <div className="w-full h-1 bg-slate-900 mt-1 rounded-full overflow-hidden">
                    <div className="h-full bg-emerald-500 w-[24.5%]" style={{ boxShadow: '0 0 5px #10b981' }} />
                  </div>
                </div>
                <div className="p-2 rounded bg-black/40 border border-slate-800 flex flex-col">
                  <span className="text-[9px] font-mono text-slate-500">AĞ GECİKMESİ</span>
                  <span className="text-sm font-mono text-cyan-400 font-bold mt-1">12ms</span>
                  <div className="w-full h-1 bg-slate-900 mt-1 rounded-full overflow-hidden">
                    <div className="h-full bg-cyan-500 w-[12%]" style={{ boxShadow: '0 0 5px #06b6d4' }} />
                  </div>
                </div>
              </div>

              {/* Activities Log */}
              <div className="flex-1 flex flex-col">
                <span className="text-[10px] font-mono text-slate-500 mb-2">SON AKTİVİTELER</span>
                <div className="flex-1 overflow-y-auto space-y-2 pr-1" style={{ maxHeight: '300px' }}>
                  {activities.map((act) => {
                    let dotColor = '#64748b'; // info
                    let Icon = Info;
                    if (act.type === 'warning') { dotColor = '#f59e0b'; Icon = AlertTriangle; }
                    if (act.type === 'error') { dotColor = '#ef4444'; Icon = AlertTriangle; }
                    if (act.type === 'success') { dotColor = '#10b981'; Icon = CheckCircle2; }

                    return (
                      <div key={act.id} className="flex gap-3 text-sm p-2 rounded bg-black/20 border border-slate-800/50 items-start">
                        <div className="mt-0.5">
                          <Icon size={12} color={dotColor} style={{ filter: `drop-shadow(0 0 3px ${dotColor})` }} />
                        </div>
                        <div className="flex-1 min-w-0">
                          <div className="text-[11px] text-slate-300 leading-tight">{act.msg}</div>
                          <div className="text-[9px] font-mono text-slate-600 mt-1">{act.time}</div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
