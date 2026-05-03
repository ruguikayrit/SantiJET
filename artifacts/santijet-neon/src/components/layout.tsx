import React, { useState, useEffect } from 'react';
import { Link, useLocation } from 'wouter';
import { modules } from '@/data/mock-data';
import { 
  Users, Package, Truck, ShoppingCart, Hammer, Scale, 
  Activity, Menu, X, Clock, ChevronLeft, ChevronRight
} from 'lucide-react';

const iconMap: Record<string, React.ElementType> = {
  Users, Package, Truck, ShoppingCart, Hammer, Scale, Activity
};

export function Layout({ children }: { children: React.ReactNode }) {
  const [location] = useLocation();
  const [time, setTime] = useState(new Date());
  const [sidebarOpen, setSidebarOpen] = useState(true);

  useEffect(() => {
    const timer = setInterval(() => setTime(new Date()), 1000);
    return () => clearInterval(timer);
  }, []);

  const currentModule = modules.find(m => m.path === location);
  const accentColor = currentModule ? currentModule.color : '#22d3ee';

  return (
    <div className="min-h-screen flex flex-col bg-[#04060d] text-slate-300 font-sans overflow-hidden">
      {/* Topbar */}
      <header 
        className="h-12 border-b flex items-center justify-between px-4 z-20 sticky top-0 bg-[#04060d]/90 backdrop-blur-md"
        style={{ borderColor: `${accentColor}33` }}
      >
        <div className="flex items-center gap-4">
          <button 
            data-testid="button-toggle-sidebar"
            onClick={() => setSidebarOpen(!sidebarOpen)}
            className="text-slate-400 hover:text-white transition-colors"
          >
            <Menu size={18} />
          </button>
          <Link href="/" className="flex items-center gap-2 cursor-pointer" data-testid="link-home-logo">
            <span className="font-mono font-bold tracking-widest text-sm" style={{ color: accentColor, textShadow: `0 0 10px ${accentColor}88` }}>
              SANTI·JET
            </span>
            <span className="text-[10px] font-mono text-slate-500">// v2.6</span>
          </Link>
        </div>

        <div className="flex items-center gap-6">
          <div className="hidden md:flex items-center gap-2 px-3 py-1 rounded bg-[#0b1224] border border-slate-800">
            <span className="text-[10px] font-mono text-slate-400">ŞANTİYE:</span>
            <span className="text-xs font-bold tracking-wider text-slate-200">KARTAL-03</span>
          </div>

          <div className="flex items-center gap-2 font-mono text-xs tabular-nums text-slate-300">
            <Clock size={12} className="text-slate-500" />
            {time.toLocaleTimeString('tr-TR', { hour12: false })}
          </div>

          <div className="flex items-center gap-2">
            <div className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" style={{ boxShadow: "0 0 8px #34d399" }} />
            <span className="text-[10px] font-bold tracking-[0.3em] text-emerald-400 uppercase hidden sm:inline" style={{ textShadow: "0 0 8px #34d39988" }}>
              ONLINE
            </span>
          </div>
        </div>
      </header>

      <div className="flex flex-1 overflow-hidden relative">
        {/* Sidebar */}
        <aside 
          className={`${sidebarOpen ? 'w-48' : 'w-14'} transition-all duration-300 border-r flex flex-col bg-[#050810] z-10 shrink-0`}
          style={{ borderColor: `${accentColor}22` }}
        >
          <nav className="flex-1 py-4 flex flex-col gap-1 px-2">
            <Link href="/" data-testid="link-sidebar-home">
              <div 
                className={`flex items-center gap-3 px-3 py-2.5 rounded cursor-pointer transition-all ${location === '/' ? 'bg-slate-800/50' : 'hover:bg-slate-800/30'}`}
                style={location === '/' ? { boxShadow: `inset 2px 0 0 ${accentColor}` } : {}}
              >
                <Activity size={16} className={location === '/' ? 'text-white' : 'text-slate-500'} style={location === '/' ? { filter: `drop-shadow(0 0 5px ${accentColor})`, color: accentColor } : {}} />
                {sidebarOpen && <span className={`text-[11px] font-bold tracking-wider ${location === '/' ? 'text-white' : 'text-slate-400'}`}>ANA EKRAN</span>}
              </div>
            </Link>
            
            <div className="my-2 border-t border-slate-800/50 mx-2" />

            {modules.map(m => {
              const Icon = iconMap[m.icon];
              const isActive = location.startsWith(m.path);
              return (
                <Link key={m.id} href={m.path} data-testid={`link-sidebar-${m.id}`}>
                  <div 
                    className={`flex items-center gap-3 px-3 py-2.5 rounded cursor-pointer transition-all relative group overflow-hidden ${isActive ? 'bg-[#0b1224]' : 'hover:bg-slate-800/30'}`}
                    style={isActive ? { 
                      border: `1px solid ${m.color}33`,
                      boxShadow: `inset 2px 0 0 ${m.color}, inset 0 0 20px ${m.color}11`
                    } : {}}
                  >
                    {isActive && <div className="absolute inset-0 opacity-20" style={{ background: `linear-gradient(90deg, ${m.color}, transparent)` }} />}
                    <Icon 
                      size={16} 
                      className="relative z-10 transition-colors" 
                      style={{ 
                        color: isActive ? m.color : '#64748b',
                        filter: isActive ? `drop-shadow(0 0 5px ${m.color})` : 'none'
                      }} 
                    />
                    {sidebarOpen && (
                      <span className={`relative z-10 text-[11px] font-bold tracking-wider transition-colors ${isActive ? 'text-white' : 'text-slate-400 group-hover:text-slate-200'}`}>
                        {m.name}
                      </span>
                    )}
                  </div>
                </Link>
              );
            })}
          </nav>
          
          {sidebarOpen && (
            <div className="p-4 border-t border-slate-800/50 text-[9px] font-mono text-slate-600 tracking-widest text-center">
              SYS_ID: SJ-29A
            </div>
          )}
        </aside>

        {/* Main Content */}
        <main className="flex-1 overflow-auto relative">
          <div className="absolute inset-0 pointer-events-none opacity-[0.03]" style={{ 
            backgroundImage: `linear-gradient(${accentColor} 1px, transparent 1px), linear-gradient(90deg, ${accentColor} 1px, transparent 1px)`,
            backgroundSize: '32px 32px'
          }} />
          <div className="relative min-h-full p-4 md:p-6 animate-in fade-in duration-500">
            {children}
          </div>
        </main>
      </div>
    </div>
  );
}
