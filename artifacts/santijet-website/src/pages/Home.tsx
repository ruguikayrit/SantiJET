import { motion } from "framer-motion";
import { Link } from "wouter";
import { 
  Building2, HardHat, FileText, Layers, TrendingUp, Calculator, ShieldCheck, 
  ChevronRight, Play, CheckCircle2, ArrowRight, Menu, X, Check, Zap, Server, Users, BarChart3, Database,
  Search, Settings, ArrowUpRight, ArrowDownRight, MoreHorizontal, Camera, Activity, LayoutDashboard, Bell, Box, Droplets, MapPin
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { useState, useEffect } from "react";
import { Accordion, AccordionItem, AccordionTrigger, AccordionContent } from "@/components/ui/accordion";

const BASE_URL = import.meta.env.BASE_URL.replace(/\/$/, "");

const fadeIn = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.6 } }
};

const staggerContainer = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: { staggerChildren: 0.1 }
  }
};

// --- Navbar ---
function Navbar() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const handleScroll = () => setScrolled(window.scrollY > 20);
    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  return (
    <>
      <header className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${scrolled ? "bg-background/80 backdrop-blur-md border-b border-white/5" : "bg-transparent"}`}>
        <div className="container mx-auto px-4 h-20 flex items-center justify-between">
          <Link href="/" className="flex items-center gap-1">
            <img src={`${BASE_URL}/brand/santijet-bolt-nav-nobg.png`} alt="ŞantiJET" className="h-[86px] w-auto object-contain" />
            <img src={`${BASE_URL}/brand/santijet-wordmark-nobg.png`} alt="ŞantiJET" className="h-[103px] w-auto object-contain" />
          </Link>
          
          <nav className="hidden md:flex items-center gap-8">
            <a href="#urunler" className="text-sm font-medium text-muted-foreground hover:text-white transition-colors">Ürünler</a>
            <a href="#ekosistem" className="text-sm font-medium text-muted-foreground hover:text-white transition-colors">Ekosistem</a>
            <a href="#nasil-calisir" className="text-sm font-medium text-muted-foreground hover:text-white transition-colors">Nasıl Çalışır</a>
            <a href="#fiyatlandirma" className="text-sm font-medium text-muted-foreground hover:text-white transition-colors">Fiyatlandırma</a>
          </nav>

          <div className="hidden md:flex items-center gap-4">
            <Button variant="default" className="bg-primary hover:bg-primary/90 text-white shadow-[0_0_20px_rgba(26,95,255,0.4)]">
              Demo Talep Et
            </Button>
          </div>

          <button className="md:hidden text-white" onClick={() => setMobileMenuOpen(!mobileMenuOpen)}>
            {mobileMenuOpen ? <X /> : <Menu />}
          </button>
        </div>
      </header>

      {mobileMenuOpen && (
        <div className="fixed inset-0 z-40 bg-background/95 backdrop-blur-xl pt-24 px-4 flex flex-col gap-6">
          <a href="#urunler" onClick={() => setMobileMenuOpen(false)} className="text-lg font-medium">Ürünler</a>
          <a href="#ekosistem" onClick={() => setMobileMenuOpen(false)} className="text-lg font-medium">Ekosistem</a>
          <a href="#nasil-calisir" onClick={() => setMobileMenuOpen(false)} className="text-lg font-medium">Nasıl Çalışır</a>
          <a href="#fiyatlandirma" onClick={() => setMobileMenuOpen(false)} className="text-lg font-medium">Fiyatlandırma</a>
          <Button className="w-full mt-4 bg-primary text-white">Demo Talep Et</Button>
        </div>
      )}
    </>
  );
}

// --- Hero ---
function Hero() {
  return (
    <section className="relative pt-32 pb-20 md:pt-48 md:pb-32 overflow-hidden">
      <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-primary/20 rounded-full blur-[120px] pointer-events-none" />
      
      <div className="container mx-auto px-4 relative z-10 text-center">
        <motion.h1 
          initial="hidden" animate="visible" variants={fadeIn}
          className="text-5xl md:text-7xl font-bold tracking-tight mb-6 max-w-4xl mx-auto leading-tight"
        >
          Şantiyenizi <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary to-blue-300">Tek Platformdan</span> Yönetin.
        </motion.h1>
        
        <motion.p 
          initial="hidden" animate="visible" variants={fadeIn} transition={{ delay: 0.1 }}
          className="text-lg md:text-xl text-muted-foreground mb-10 max-w-2xl mx-auto leading-relaxed"
        >
          Keşiften siparişe, malzemeden puantaja, günlük rapordan hakedişe kadar tüm süreçleri dijitalleştirin.
        </motion.p>
        
        <motion.div 
          initial="hidden" animate="visible" variants={fadeIn} transition={{ delay: 0.2 }}
          className="flex flex-col sm:flex-row items-center justify-center gap-4"
        >
          <Button size="lg" className="w-full sm:w-auto text-base h-14 px-8 bg-primary hover:bg-primary/90 text-white shadow-[0_0_30px_rgba(26,95,255,0.5)]">
            ŞantiJET Pro'yu Keşfet
          </Button>
          <Button size="lg" variant="outline" className="w-full sm:w-auto text-base h-14 px-8 border-white/10 hover:bg-white/5 text-white">
            <Play className="mr-2 h-5 w-5" /> Demo Talep Et
          </Button>
        </motion.div>

      </div>
    </section>
  );
}

// --- Ecosystem ---

// All 7 modules in circular clockwise order starting from top (12 o'clock).
const ECO_MODULES = [
  { name: "ŞANTİJET İŞ PROGRAMI",       desc: "İş planlama, programlama ve takip yönetimi", color: "#ffd060", iconKey: "program" }, // 0 top
  { name: "ŞANTİJET TEKNİK",            desc: "Teknik doküman, çizim ve detay yönetimi",    color: "#ff8c40", iconKey: "teknik"  }, // 1 upper-right
  { name: "ŞANTİJET BFA · BF · KEŞİF", desc: "Birim fiyat, analiz ve keşif yönetimi",      color: "#ff4488", iconKey: "bfa"     }, // 2 right
  { name: "ŞANTİJET DEMİR",             desc: "Demir keşfi, sipariş ve teslimat yönetimi",  color: "#00d68f", iconKey: "demir"   }, // 3 lower-right
  { name: "ŞANTİJET BETON",             desc: "Beton sipariş, döküm ve kalite yönetimi",    color: "#00d4ff", iconKey: "beton"   }, // 4 lower-left
  { name: "ŞANTİJET ÇELİK",            desc: "Çelik proje, imalat ve montaj yönetimi",     color: "#4a9eff", iconKey: "celik"   }, // 5 left
  { name: "ŞANTİJET SAHA",              desc: "Saha raporları, ilerleme ve günlük kayıtlar",color: "#b06eff", iconKey: "saha"    }, // 6 upper-left
];

// Keep aliases for backward compatibility with mobile layout
const LEFT_MODULES = ECO_MODULES.slice(3, 7);
const RIGHT_MODULES = ECO_MODULES.slice(0, 3);

function NeonIcon({ iconKey, color }: { iconKey: string; color: string }) {
  const s = { stroke: color, strokeWidth: 1.8, fill: "none", strokeLinecap: "round" as const, strokeLinejoin: "round" as const };
  switch (iconKey) {
    case "demir": return (
      <svg width="38" height="38" viewBox="0 0 38 38">
        {[7, 13, 19, 25, 31].map((y) => <line key={y} x1="4" y1={y} x2="34" y2={y} {...s} />)}
        {[7, 13, 19, 25, 31].map((y) => [7, 13, 19, 25, 31].map((x) =>
          <circle key={`${x}-${y}`} cx={x} cy={y} r="1.6" fill={color} stroke="none" />
        ))}
      </svg>
    );
    case "beton": return (
      <svg width="38" height="38" viewBox="0 0 38 38">
        {/* Drum (rotating bowl) */}
        <ellipse cx="13" cy="14" rx="10" ry="11" {...s} />
        {/* Spiral inside drum */}
        <path d="M8 10 q5-4 10 4" {...s} strokeWidth={1.4} />
        <path d="M6 16 q5-4 10 4" {...s} strokeWidth={1.4} />
        {/* Truck cab */}
        <rect x="23" y="15" width="12" height="10" rx="1.5" {...s} />
        {/* Cab window */}
        <rect x="25" y="17" width="5" height="4" rx="0.8" {...s} strokeWidth={1.2} />
        {/* Chassis / frame */}
        <line x1="23" y1="25" x2="4" y2="25" {...s} />
        {/* Chute (discharge) */}
        <line x1="20" y1="21" x2="27" y2="25" {...s} strokeWidth={1.5} />
        {/* Rear wheel */}
        <circle cx="8" cy="29" r="3.5" {...s} />
        <circle cx="8" cy="29" r="1.2" fill={color} stroke="none" />
        {/* Front wheel */}
        <circle cx="29" cy="29" r="3.5" {...s} />
        <circle cx="29" cy="29" r="1.2" fill={color} stroke="none" />
        {/* Axle line */}
        <line x1="11.5" y1="29" x2="25.5" y2="29" {...s} strokeOpacity={0.4} />
      </svg>
    );
    case "celik": return (
      <svg width="38" height="38" viewBox="0 0 38 38">
        <rect x="3" y="4" width="32" height="6" rx="1" {...s} />
        <rect x="3" y="28" width="32" height="6" rx="1" {...s} />
        <rect x="16" y="10" width="6" height="18" {...s} />
      </svg>
    );
    case "saha": return (
      <svg width="38" height="38" viewBox="0 0 38 38">
        {/* Kule gövdesi (dikey kule) */}
        <rect x="10" y="10" width="4" height="24" rx="0.8" {...s} />
        {/* Zemin tabanı */}
        <line x1="5" y1="34" x2="19" y2="34" {...s} strokeWidth={2} />
        {/* Yatay kol (boom) */}
        <line x1="12" y1="10" x2="34" y2="10" {...s} strokeWidth={2} />
        {/* Kısa karşı ağırlık kolu */}
        <line x1="12" y1="10" x2="4" y2="10" {...s} strokeWidth={2} />
        {/* Kule tepe üçgeni */}
        <line x1="12" y1="4" x2="8" y2="10" {...s} />
        <line x1="12" y1="4" x2="16" y2="10" {...s} />
        {/* Yatay kol kabloları */}
        <line x1="12" y1="4" x2="34" y2="10" {...s} strokeOpacity={0.5} />
        <line x1="12" y1="4" x2="4" y2="10" {...s} strokeOpacity={0.5} />
        {/* Kanca halatı */}
        <line x1="26" y1="10" x2="26" y2="22" {...s} />
        {/* Kanca */}
        <path d="M23 22 q0 4 3 4 q3 0 3-3" {...s} strokeWidth={1.8} />
        {/* Karşı ağırlık bloğu */}
        <rect x="2" y="8.5" width="4" height="3" rx="0.5" {...s} />
      </svg>
    );
    case "teknik": return (
      <svg width="38" height="38" viewBox="0 0 38 38">
        <rect x="4" y="4" width="22" height="30" rx="2" {...s} />
        <line x1="8" y1="12" x2="22" y2="12" {...s} />
        <line x1="8" y1="18" x2="22" y2="18" {...s} />
        <line x1="8" y1="24" x2="16" y2="24" {...s} />
        <line x1="30" y1="4" x2="30" y2="34" {...s} />
        <line x1="28" y1="4" x2="32" y2="4" {...s} />
        <line x1="28" y1="34" x2="32" y2="34" {...s} />
      </svg>
    );
    case "program": return (
      <svg width="38" height="38" viewBox="0 0 38 38">
        <rect x="3" y="7" width="28" height="24" rx="2" {...s} />
        <line x1="3" y1="15" x2="31" y2="15" {...s} />
        <line x1="11" y1="3" x2="11" y2="11" {...s} />
        <line x1="23" y1="3" x2="23" y2="11" {...s} />
        <circle cx="30" cy="30" r="7" fill="#050816" stroke={color} strokeWidth="1.8" />
        <line x1="30" y1="26" x2="30" y2="30" stroke={color} strokeWidth="1.5" strokeLinecap="round" />
        <line x1="30" y1="30" x2="34" y2="30" stroke={color} strokeWidth="1.5" strokeLinecap="round" />
      </svg>
    );
    case "bfa": return (
      <svg width="38" height="38" viewBox="0 0 38 38">
        <rect x="5" y="3" width="28" height="32" rx="3" {...s} />
        <rect x="9" y="7" width="20" height="7" rx="1" {...s} />
        {[17, 23, 29].map((y) => [9, 17, 25].map((x) =>
          <rect key={`${x}-${y}`} x={x} y={y} width="5.5" height="4" rx="0.5" {...s} strokeWidth={1.3} />
        ))}
        <text x="19" y="21.5" textAnchor="middle" fontSize="4" fill={color} fontFamily="monospace">₺</text>
      </svg>
    );
    default: return null;
  }
}

function EcoCard({
  name, desc, color, iconKey, delay = 0, initX = 0, initY = 0,
  isActive = false, onHoverStart, onHoverEnd,
}: {
  name: string; desc: string; color: string; iconKey: string;
  delay?: number; initX?: number; initY?: number;
  isActive?: boolean; onHoverStart?: () => void; onHoverEnd?: () => void;
}) {
  return (
    <motion.div
      initial={{ opacity: 0, x: initX, y: initY }}
      whileInView={{ opacity: 1, x: 0, y: 0 }}
      viewport={{ once: true }}
      transition={{ duration: 0.55, delay }}
      whileHover={{ y: -6, scale: 1.02, transition: { duration: 0.3 } }}
      onHoverStart={onHoverStart}
      onHoverEnd={onHoverEnd}
      className="flex items-stretch rounded-2xl overflow-hidden cursor-default select-none h-full"
      style={{
        background: "linear-gradient(145deg, #080d20 0%, #050918 100%)",
        border: `1.5px solid ${isActive ? color + "90" : color + "50"}`,
        boxShadow: isActive
          ? `0 0 32px ${color}40, 0 0 8px ${color}25, inset 0 0 20px ${color}08`
          : `0 0 20px ${color}20, 0 0 4px ${color}12, inset 0 0 12px ${color}06`,
        transition: "box-shadow 0.3s ease, border-color 0.3s ease",
      }}
    >
      <div className="flex-1 p-4 flex flex-col justify-center min-w-0">
        <div className="font-bold text-white text-[11px] leading-tight tracking-wide mb-2">{name}</div>
        <span
          className="inline-block self-start text-[9px] px-2.5 py-[3px] rounded-full font-bold tracking-widest mb-2.5"
          style={{ background: color + "28", color, border: `1px solid ${color}55` }}
        >
          Entegre
        </span>
        <div className="text-[10px] text-white/45 leading-snug">{desc}</div>
      </div>
      <div
        className="flex-shrink-0 w-[72px] flex items-center justify-center m-2 rounded-xl"
        style={{
          background: `linear-gradient(135deg, ${color}18 0%, ${color}08 100%)`,
          border: `1px solid ${color}45`,
        }}
      >
        <NeonIcon iconKey={iconKey} color={color} />
      </div>
    </motion.div>
  );
}

function Ecosystem() {
  const [activeCard, setActiveCard] = useState<number | null>(null);

  // ── Circular geometry: 960×720 container, hub center (480, 360), R=265 ──
  // 7 modules at step=360/7≈51.43°, starting -90° (top), clockwise.
  // Card size: 210×140 px (half: 105w, 70h)
  // Hub SVG: viewBox 0 0 300 300, center (150,150), ring r=136
  // Hub div top-left in eco-SVG: (330, 210)
  //
  //  i  angle   card-center    hub-ring-eco   card-edge-eco
  //  0  -90°   (480,  95)     (480, 224)     (480, 165)  top
  //  1  -38.6° (687, 195)     (586, 275)     (582, 195)  upper-right
  //  2   12.9° (738, 419)     (613, 390)     (633, 419)  right
  //  3   64.3° (595, 599)     (539, 483)     (595, 529)  lower-right
  //  4  115.7° (365, 599)     (421, 483)     (365, 529)  lower-left
  //  5  167.1° (222, 419)     (347, 390)     (327, 419)  left
  //  6  218.6° (273, 195)     (374, 275)     (378, 195)  upper-left
  // ─────────────────────────────────────────────────────────────────────────

  const hubDots = [
    { x: 150, y:  14 },
    { x: 256, y:  65 },
    { x: 283, y: 180 },
    { x: 209, y: 273 },
    { x:  91, y: 273 },
    { x:  17, y: 180 },
    { x:  44, y:  65 },
  ];

  // All lines: hub-ring point (ex,ey) → card-edge point (tx,ty)
  const lines = [
    { ex: 480, ey: 224, tx: 480, ty: 165 }, // 0 İş Programı
    { ex: 586, ey: 275, tx: 582, ty: 195 }, // 1 Teknik
    { ex: 613, ey: 390, tx: 633, ty: 419 }, // 2 BFA
    { ex: 539, ey: 483, tx: 595, ty: 529 }, // 3 Demir
    { ex: 421, ey: 483, tx: 365, ty: 529 }, // 4 Beton
    { ex: 347, ey: 390, tx: 327, ty: 419 }, // 5 Çelik
    { ex: 374, ey: 275, tx: 378, ty: 195 }, // 6 Saha
  ];

  const cardLayout = [
    { cx: 480, cy:  95, initX:   0, initY: -30 },
    { cx: 687, cy: 195, initX:  23, initY: -19 },
    { cx: 738, cy: 419, initX:  30, initY:   6 },
    { cx: 595, cy: 599, initX:  13, initY:  27 },
    { cx: 365, cy: 599, initX: -13, initY:  27 },
    { cx: 222, cy: 419, initX: -30, initY:   6 },
    { cx: 273, cy: 195, initX: -23, initY: -19 },
  ];

  return (
    <section
      id="ekosistem"
      className="py-20 relative overflow-hidden"
      style={{ background: "linear-gradient(180deg, #020817 0%, #041124 50%, #020817 100%)" }}
    >
      {/* Blueprint grid */}
      <div
        className="absolute inset-0 pointer-events-none"
        style={{
          backgroundImage:
            "linear-gradient(rgba(26,95,255,0.06) 1px, transparent 1px)," +
            "linear-gradient(90deg, rgba(26,95,255,0.06) 1px, transparent 1px)",
          backgroundSize: "48px 48px",
        }}
      />
      {/* Ambient radial glow centered on hub area */}
      <div
        className="absolute pointer-events-none"
        style={{
          inset: 0,
          background: "radial-gradient(ellipse 860px 680px at 50% 54%, rgba(26,95,255,0.13) 0%, transparent 68%)",
        }}
      />

      <div className="container mx-auto px-4">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: 18 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          className="text-center mb-10"
        >
          <h2 className="text-4xl md:text-5xl lg:text-6xl font-extrabold mb-3 leading-tight">
            <span className="text-white">ŞantiJET </span>
            <span style={{ background: "linear-gradient(90deg, #4a9eff 0%, #00d4ff 100%)", WebkitBackgroundClip: "text", WebkitTextFillColor: "transparent" }}>
              Ekosistemi
            </span>
          </h2>
          <p className="text-white/50 text-base md:text-lg">İnşaat projeleri için entegre dijital işletim sistemi.</p>
        </motion.div>

        {/* ── Desktop diagram ── */}
        <div className="relative max-w-[960px] mx-auto hidden md:block" style={{ height: 720 }}>

          {/* Full-scene SVG: connection lines + animated data-flow particles */}
          <svg
            className="absolute inset-0 pointer-events-none"
            style={{ width: "100%", height: "100%", zIndex: 1 }}
            viewBox="0 0 960 720"
            preserveAspectRatio="xMidYMid meet"
          >
            <defs>
              <filter id="eco-line-glow" x="-150%" y="-150%" width="400%" height="400%">
                <feGaussianBlur stdDeviation="4" result="b1" />
                <feGaussianBlur stdDeviation="11" result="b2" />
                <feMerge>
                  <feMergeNode in="b2" />
                  <feMergeNode in="b1" />
                  <feMergeNode in="SourceGraphic" />
                </feMerge>
              </filter>
              <filter id="eco-particle-glow" x="-800%" y="-800%" width="1700%" height="1700%">
                <feGaussianBlur stdDeviation="3.5" result="b" />
                <feMerge><feMergeNode in="b" /><feMergeNode in="SourceGraphic" /></feMerge>
              </filter>
              <filter id="eco-dot-glow" x="-500%" y="-500%" width="1100%" height="1100%">
                <feGaussianBlur stdDeviation="5" result="b" />
                <feMerge><feMergeNode in="b" /><feMergeNode in="SourceGraphic" /></feMerge>
              </filter>
            </defs>

            {lines.map((l, i) => {
              const isActive = activeCard === i;
              const col = ECO_MODULES[i].color;
              // Path data for animateMotion (hub→card and card→hub)
              const fwdPath = `M ${l.ex},${l.ey} L ${l.tx},${l.ty}`;
              const revPath = `M ${l.tx},${l.ty} L ${l.ex},${l.ey}`;
              const dur = 3.5 + i * 0.18;
              const durRev = 4.2 + i * 0.22;
              return (
                <g key={i}>
                  {/* Static glowing line */}
                  <line
                    x1={l.ex} y1={l.ey} x2={l.tx} y2={l.ty}
                    stroke={isActive ? col : "#1a8fff"}
                    strokeWidth={isActive ? "2.2" : "1.5"}
                    strokeOpacity={isActive ? "0.95" : "0.7"}
                    filter="url(#eco-line-glow)"
                    style={{ transition: "stroke 0.3s, stroke-width 0.3s, stroke-opacity 0.3s" }}
                  />

                  {/* Particles: hub → card (module color) */}
                  {[0, 0.34, 0.67].map((offset, j) => (
                    <circle key={`fwd-${j}`} r="3" fill={col} filter="url(#eco-particle-glow)" opacity="0.9">
                      <animateMotion path={fwdPath} dur={`${dur}s`} begin={`${-offset * dur}s`} repeatCount="indefinite" calcMode="linear" />
                    </circle>
                  ))}

                  {/* Particles: card → hub (blue) */}
                  {[0.17, 0.50].map((offset, j) => (
                    <circle key={`rev-${j}`} r="2" fill="#60b8ff" filter="url(#eco-particle-glow)" opacity="0.65">
                      <animateMotion path={revPath} dur={`${durRev}s`} begin={`${-offset * durRev}s`} repeatCount="indefinite" calcMode="linear" />
                    </circle>
                  ))}

                  {/* Card-edge endpoint dot */}
                  <circle cx={l.tx} cy={l.ty} r="4.5" fill={col} fillOpacity={isActive ? "1" : "0.85"} filter="url(#eco-dot-glow)" />
                </g>
              );
            })}
          </svg>

          {/* 7 cards — positioned by center point */}
          {ECO_MODULES.map((m, i) => {
            const { cx, cy, initX, initY } = cardLayout[i];
            return (
              <div
                key={m.name}
                className="absolute"
                style={{ width: 210, height: 140, left: cx - 105, top: cy - 70, zIndex: 10 }}
              >
                <EcoCard
                  {...m}
                  delay={i * 0.09}
                  initX={initX}
                  initY={initY}
                  isActive={activeCard === i}
                  onHoverStart={() => setActiveCard(i)}
                  onHoverEnd={() => setActiveCard(null)}
                />
              </div>
            );
          })}

          {/* Center Hub */}
          <div
            className="absolute left-1/2 -translate-x-1/2"
            style={{ top: 360, transform: "translate(-50%, -50%)", zIndex: 20 }}
          >
            <motion.div
              initial={{ opacity: 0, scale: 0.72 }}
              whileInView={{ opacity: 1, scale: 1 }}
              viewport={{ once: true }}
              transition={{ duration: 0.7 }}
              style={{ width: 300, height: 300, position: "relative" }}
            >
              {/* Breathing scale wrapper */}
              <motion.div
                animate={{ scale: [1, 1.03, 1] }}
                transition={{ duration: 4, repeat: Infinity, ease: "easeInOut" }}
                style={{ width: 300, height: 300, position: "relative" }}
              >
                {/* Pulsing outer glow */}
                <motion.div
                  className="absolute inset-0 rounded-full pointer-events-none"
                  animate={{
                    boxShadow: [
                      "0 0 60px 18px rgba(26,95,255,0.22), 0 0 140px 40px rgba(26,95,255,0.09)",
                      "0 0 90px 28px rgba(26,95,255,0.36), 0 0 200px 60px rgba(26,95,255,0.14)",
                      "0 0 60px 18px rgba(26,95,255,0.22), 0 0 140px 40px rgba(26,95,255,0.09)",
                    ],
                  }}
                  transition={{ duration: 3, repeat: Infinity, ease: "easeInOut" }}
                />

                {/* Hub SVG: rings + pulsing dots */}
                <svg viewBox="0 0 300 300" width="300" height="300" className="absolute inset-0" style={{ overflow: "visible" }}>
                  <defs>
                    <filter id="hub-ring-glow" x="-70%" y="-70%" width="240%" height="240%">
                      <feGaussianBlur stdDeviation="5" result="b1" />
                      <feGaussianBlur stdDeviation="18" result="b2" />
                      <feMerge>
                        <feMergeNode in="b2" />
                        <feMergeNode in="b1" />
                        <feMergeNode in="SourceGraphic" />
                      </feMerge>
                    </filter>
                    <filter id="hub-dot-glow" x="-700%" y="-700%" width="1500%" height="1500%">
                      <feGaussianBlur stdDeviation="7" result="b" />
                      <feMerge><feMergeNode in="b" /><feMergeNode in="SourceGraphic" /></feMerge>
                    </filter>
                    <radialGradient id="hub-inner" cx="44%" cy="38%" r="62%">
                      <stop offset="0%" stopColor="#0c1630" />
                      <stop offset="55%" stopColor="#05091a" />
                      <stop offset="100%" stopColor="#020408" />
                    </radialGradient>
                  </defs>

                  {/* Outer decorative rings */}
                  <circle cx="150" cy="150" r="147" fill="none" stroke="rgba(70,130,255,0.14)" strokeWidth="1" strokeDasharray="5 10" />
                  <circle cx="150" cy="150" r="141" fill="none" stroke="rgba(60,120,255,0.20)" strokeWidth="0.8" />

                  {/* Main neon ring — animated opacity */}
                  <motion.circle
                    cx="150" cy="150" r="136" fill="none" stroke="#1a8fff" strokeWidth="2.6"
                    animate={{ strokeOpacity: [0.75, 1.0, 0.75] }}
                    transition={{ duration: 2.5, repeat: Infinity, ease: "easeInOut" }}
                    filter="url(#hub-ring-glow)"
                  />
                  <circle cx="150" cy="150" r="136" fill="none" stroke="rgba(210,235,255,0.52)" strokeWidth="1.4" />

                  {/* Inner rings */}
                  <circle cx="150" cy="150" r="122" fill="none" stroke="rgba(26,100,255,0.30)" strokeWidth="1" />
                  <circle cx="150" cy="150" r="108" fill="none" stroke="rgba(26,80,220,0.22)" strokeWidth="0.7" strokeDasharray="3 8" />
                  <circle cx="150" cy="150" r="107" fill="url(#hub-inner)" />

                  {/* 7 connection dots at equal angles */}
                  {hubDots.map((dot, i) => (
                    <g key={i}>
                      <motion.circle
                        cx={dot.x} cy={dot.y} r={activeCard === i ? 9 : 7}
                        fill={activeCard === i ? ECO_MODULES[i].color + "55" : "rgba(70,170,255,0.28)"}
                        animate={{ opacity: [0.2, 0.9, 0.2] }}
                        transition={{ duration: 2.4, delay: i * 0.35, repeat: Infinity, ease: "easeInOut" }}
                        filter="url(#hub-dot-glow)"
                        style={{ transition: "r 0.3s, fill 0.3s" }}
                      />
                      <circle
                        cx={dot.x} cy={dot.y} r="3.8"
                        fill={activeCard === i ? ECO_MODULES[i].color : "#90d8ff"}
                        fillOpacity="0.95"
                        style={{ transition: "fill 0.3s" }}
                      />
                    </g>
                  ))}
                </svg>

                {/* Logo + PRO */}
                <div className="absolute inset-0 flex flex-col items-center justify-center" style={{ paddingBottom: 4 }}>
                  <img
                    src={`${BASE_URL}/brand/santijet-bolt-nobg.png`}
                    alt="ŞantiJET"
                    className="object-contain"
                    style={{ width: 190, height: 190, marginBottom: -20 }}
                  />
                  <span
                    className="font-bold tracking-[0.28em] text-[22px]"
                    style={{ color: "#4a90e2", textShadow: "0 0 22px rgba(74,144,226,0.95)" }}
                  >
                    PRO
                  </span>
                </div>
              </motion.div>
            </motion.div>
          </div>

        </div>{/* end desktop diagram */}

        {/* ── Mobile layout ── */}
        <div className="md:hidden flex flex-col items-center gap-4 px-2">
          <div className="relative my-4" style={{ width: 200, height: 200 }}>
            <motion.div
              className="absolute inset-0 rounded-full pointer-events-none"
              animate={{ boxShadow: ["0 0 50px 12px rgba(26,95,255,0.24)", "0 0 70px 20px rgba(26,95,255,0.38)", "0 0 50px 12px rgba(26,95,255,0.24)"] }}
              transition={{ duration: 3, repeat: Infinity, ease: "easeInOut" }}
            />
            <svg viewBox="0 0 200 200" width="200" height="200" className="absolute inset-0">
              <circle cx="100" cy="100" r="92" fill="none" stroke="#1a8fff" strokeWidth="2" strokeOpacity="0.88" />
              <circle cx="100" cy="100" r="92" fill="none" stroke="rgba(180,220,255,0.35)" strokeWidth="1.2" />
              <circle cx="100" cy="100" r="82" fill="#060a1a" />
            </svg>
            <div className="absolute inset-0 flex flex-col items-center justify-center">
              <img src={`${BASE_URL}/brand/santijet-bolt-nobg.png`} alt="ŞantiJET" className="w-20 h-20 object-contain" />
              <span className="font-bold tracking-widest text-sm" style={{ color: "#4a90e2" }}>PRO</span>
            </div>
          </div>
          {ECO_MODULES.map((m) => (
            <div key={m.name} className="w-full max-w-sm">
              <EcoCard {...m} delay={0} />
            </div>
          ))}
        </div>

      </div>
    </section>
  );
}

// --- Product Showcase ---
function ProductShowcase() {
  const products = [
    {
      id: "demir",
      title: "ŞANTİJET DEMİR",
      subject: "Demir keşfi, sipariş, teslimat, saha sayımı",
      slogan: "Demiri kontrol et. Maliyeti kontrol et.",
      color: "#1a5fff",
      icon: <Layers className="w-6 h-6" style={{ color: "#1a5fff" }} />,
      mockup: (
        <div className="w-full h-full bg-[#0a0a0a] rounded-xl border border-white/10 overflow-hidden flex flex-col font-sans">
          <div className="h-10 border-b border-white/10 flex items-center px-4 gap-4 bg-[#111]">
            <div className="flex gap-1.5">
              <div className="w-3 h-3 rounded-full bg-red-500/80" />
              <div className="w-3 h-3 rounded-full bg-yellow-500/80" />
              <div className="w-3 h-3 rounded-full bg-green-500/80" />
            </div>
            <div className="text-xs text-muted-foreground flex-1 text-center font-medium">santijet.com/demir/stok</div>
          </div>
          <div className="flex flex-1 overflow-hidden">
            <div className="w-48 border-r border-white/10 p-4 flex flex-col gap-2 bg-[#0d0d0d]">
              <div className="text-xs font-semibold text-white/50 mb-2">MENÜ</div>
              {["Keşif Özeti", "Siparişler", "Teslimatlar", "Saha Sayımı"].map((item, i) => (
                <div key={i} className={`text-sm px-3 py-2 rounded-md ${i === 2 ? "bg-[#1a5fff]/20 text-[#1a5fff] font-medium" : "text-white/70 hover:bg-white/5"}`}>
                  {item}
                </div>
              ))}
            </div>
            <div className="flex-1 p-6 bg-[#0a0a0a]">
              <div className="flex justify-between items-center mb-6">
                <h4 className="font-semibold">Son Teslimatlar</h4>
                <Button size="sm" className="bg-[#1a5fff] text-white hover:bg-[#1a5fff]/90 h-8">Yeni İrsaliye</Button>
              </div>
              <div className="grid grid-cols-3 gap-4 mb-6">
                {[
                  { label: "Toplam Gelen", val: "1,240 Ton", color: "text-white" },
                  { label: "Saha Stok", val: "320 Ton", color: "text-[#1a5fff]" },
                  { label: "Kritik Çap", val: "Ø14 (12 Ton)", color: "text-red-400" },
                ].map((stat, i) => (
                  <div key={i} className="bg-white/5 p-4 rounded-lg border border-white/5">
                    <div className="text-xs text-white/50 mb-1">{stat.label}</div>
                    <div className={`text-lg font-bold ${stat.color}`}>{stat.val}</div>
                  </div>
                ))}
              </div>
              <div className="border border-white/10 rounded-lg overflow-hidden">
                <div className="bg-white/5 px-4 py-2 text-xs font-medium text-white/50 grid grid-cols-4">
                  <div>İRSALİYE NO</div>
                  <div>TARİH</div>
                  <div>MİKTAR</div>
                  <div>DURUM</div>
                </div>
                {[
                  { no: "IRS-2024-089", date: "Bugün, 09:30", amount: "24.5 Ton", status: "Sayım Bekliyor", sColor: "text-yellow-400" },
                  { no: "IRS-2024-088", date: "Dün, 14:15", amount: "18.0 Ton", status: "Onaylandı", sColor: "text-emerald-400" },
                  { no: "IRS-2024-087", date: "12 Eki, 10:00", amount: "32.4 Ton", status: "Onaylandı", sColor: "text-emerald-400" },
                ].map((row, i) => (
                  <div key={i} className="px-4 py-3 text-sm border-t border-white/5 grid grid-cols-4 items-center">
                    <div className="font-medium text-white/90">{row.no}</div>
                    <div className="text-white/60">{row.date}</div>
                    <div className="text-white/90">{row.amount}</div>
                    <div className={row.sColor}>{row.status}</div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      )
    },
    {
      id: "bfa",
      title: "ŞANTİJET BFA",
      subject: "Birim fiyat analizleri — binlerce analiz, anında erişim",
      slogan: "Binlerce analize saniyeler içinde ulaş.",
      color: "#7c3aed",
      icon: <Calculator className="w-6 h-6" style={{ color: "#7c3aed" }} />,
      mockup: (
        <div className="w-full h-full bg-[#0a0a0a] rounded-xl border border-white/10 overflow-hidden flex flex-col font-sans">
          <div className="h-12 border-b border-white/10 flex items-center px-4 bg-[#111]">
            <div className="w-full max-w-md mx-auto relative">
              <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-white/40" />
              <input type="text" value="C30 Beton" readOnly className="w-full bg-white/5 border border-white/10 rounded-md py-1.5 pl-9 pr-4 text-sm text-white/90 outline-none" />
            </div>
          </div>
          <div className="flex-1 p-6 flex flex-col">
            <div className="flex justify-between items-end mb-6">
              <div>
                <div className="text-xs text-[#7c3aed] font-semibold mb-1">POZ: 15.150.1006</div>
                <h4 className="font-semibold text-lg">C30/37 Hazır Beton Dökülmesi</h4>
              </div>
              <div className="flex gap-2">
                <Button size="sm" variant="outline" className="h-8 border-white/10 bg-white/5">PDF İndir</Button>
                <Button size="sm" className="h-8 bg-[#7c3aed] hover:bg-[#7c3aed]/90 text-white">Analizi Kopyala</Button>
              </div>
            </div>
            
            <div className="bg-white/5 border border-white/10 rounded-lg flex-1 overflow-hidden flex flex-col">
              <div className="grid grid-cols-12 gap-4 px-4 py-2 border-b border-white/10 text-xs font-medium text-white/50 bg-black/50">
                <div className="col-span-5">TANIM</div>
                <div className="col-span-2 text-right">MİKTAR</div>
                <div className="col-span-2 text-right">B.FİYAT</div>
                <div className="col-span-3 text-right">TUTAR</div>
              </div>
              <div className="p-2 space-y-1">
                {[
                  { t: "C30/37 Hazır Beton", m: "1.05", u: "m³", f: "2,450.00", to: "2,572.50" },
                  { t: "Beton Pompası", m: "1.00", u: "m³", f: "180.00", to: "180.00" },
                  { t: "Beton İşçiliği", m: "1.20", u: "saat", f: "450.00", to: "540.00" },
                  { t: "Kür Bakımı", m: "1.00", u: "m²", f: "25.00", to: "25.00" }
                ].map((row, i) => (
                  <div key={i} className="grid grid-cols-12 gap-4 px-2 py-2 rounded hover:bg-white/5 text-sm items-center">
                    <div className="col-span-5 text-white/90">{row.t}</div>
                    <div className="col-span-2 text-right text-white/70">{row.m} {row.u}</div>
                    <div className="col-span-2 text-right text-white/70">₺{row.f}</div>
                    <div className="col-span-3 text-right font-medium">₺{row.to}</div>
                  </div>
                ))}
              </div>
              <div className="mt-auto border-t border-white/10 p-4 bg-[#7c3aed]/10 flex justify-between items-center">
                <div className="text-sm font-medium text-[#7c3aed]">Toplam Birim Maliyet (m³)</div>
                <div className="text-xl font-bold text-white">₺3,317.50</div>
              </div>
            </div>
          </div>
        </div>
      )
    },
    {
      id: "celik",
      title: "ŞANTİJET ÇELİK",
      subject: "Çelik konstrüksiyon, metraj, imalat takibi",
      slogan: "Çelik projelerini dijitalleştir.",
      color: "#94a3b8",
      icon: <Layers className="w-6 h-6" style={{ color: "#94a3b8" }} />,
      mockup: (
        <div className="w-full h-full bg-[#0a0a0a] rounded-xl border border-white/10 overflow-hidden flex font-sans">
          <div className="w-16 border-r border-white/10 bg-[#0d0d0d] flex flex-col items-center py-4 gap-6">
             <div className="w-8 h-8 rounded bg-[#94a3b8]/20 flex items-center justify-center text-[#94a3b8]"><Layers size={18} /></div>
             <div className="w-8 h-8 rounded hover:bg-white/5 flex items-center justify-center text-white/40"><Database size={18} /></div>
             <div className="w-8 h-8 rounded hover:bg-white/5 flex items-center justify-center text-white/40"><Activity size={18} /></div>
          </div>
          <div className="flex-1 p-6 flex flex-col">
            <h4 className="font-semibold mb-4">Profil Metraj Listesi</h4>
            <div className="grid grid-cols-2 gap-4 mb-4">
              <div className="bg-gradient-to-br from-[#94a3b8]/20 to-transparent p-4 rounded-xl border border-[#94a3b8]/30">
                <div className="text-xs text-[#94a3b8] mb-1">Toplam Tonaj</div>
                <div className="text-2xl font-bold">142.5 <span className="text-sm text-white/50 font-normal">Ton</span></div>
              </div>
              <div className="bg-white/5 p-4 rounded-xl border border-white/5">
                <div className="text-xs text-white/50 mb-1">İmalatı Tamamlanan</div>
                <div className="text-2xl font-bold text-white">86.2 <span className="text-sm text-white/50 font-normal">Ton (60%)</span></div>
              </div>
            </div>
            
            <div className="border border-white/10 rounded-lg bg-[#111] flex-1">
               <div className="grid grid-cols-4 px-4 py-2 border-b border-white/10 text-xs text-white/40 font-semibold">
                 <div>PROFİL</div>
                 <div>UZUNLUK (m)</div>
                 <div>ADET</div>
                 <div>AĞIRLIK (kg)</div>
               </div>
               {[
                 { p: "HEA 200", l: "6.00", a: "24", w: "6,084" },
                 { p: "IPE 300", l: "12.00", a: "18", w: "9,115" },
                 { p: "HEB 400", l: "4.50", a: "12", w: "8,370" },
                 { p: "L 80x80x8", l: "6.00", a: "40", w: "2,318" }
               ].map((r, i) => (
                 <div key={i} className="grid grid-cols-4 px-4 py-3 border-b border-white/5 text-sm hover:bg-white/5">
                   <div className="font-medium text-[#94a3b8]">{r.p}</div>
                   <div className="text-white/80">{r.l}</div>
                   <div className="text-white/80">{r.a}</div>
                   <div className="text-white/80">{r.w}</div>
                 </div>
               ))}
            </div>
          </div>
        </div>
      )
    },
    {
      id: "beton",
      title: "ŞANTİJET BETON",
      subject: "Beton döküm kayıtları, siparişler, kür takip",
      slogan: "Beton süreçlerini tek ekranda yönet.",
      color: "#64748b",
      icon: <Box className="w-6 h-6" style={{ color: "#64748b" }} />,
      mockup: (
        <div className="w-full h-full bg-[#0a0a0a] rounded-xl border border-white/10 overflow-hidden flex flex-col font-sans">
          <div className="h-14 border-b border-white/10 px-6 flex justify-between items-center bg-[#0d0d0d]">
             <div className="font-semibold text-lg flex items-center gap-2">
               <div className="w-2 h-2 rounded-full bg-[#64748b] animate-pulse" />
               Canlı Beton Dökümü
             </div>
             <div className="text-sm text-white/50">Blok A - 4. Kat Tabliyesi</div>
          </div>
          <div className="p-6 flex-1 flex gap-6">
            <div className="flex-1 flex flex-col gap-4">
              <div className="bg-white/5 border border-white/10 rounded-xl p-5 flex items-center justify-between">
                <div>
                  <div className="text-xs text-white/50 mb-1">Dökülen Hacim / Toplam</div>
                  <div className="text-3xl font-bold text-white">124 <span className="text-lg text-white/40">/ 280 m³</span></div>
                </div>
                <div className="w-16 h-16 rounded-full border-4 border-white/10 border-t-[#64748b] border-r-[#64748b] flex items-center justify-center">
                  <span className="text-sm font-bold">44%</span>
                </div>
              </div>
              
              <div className="border border-white/10 rounded-xl flex-1 p-4 bg-[#111]">
                 <div className="text-sm font-medium text-white/70 mb-4">Gelen Mikserler</div>
                 <div className="space-y-3">
                   {[
                     { t: "14:30", p: "34 ABC 123", m: "8 m³", s: "Dökülüyor", c: "text-yellow-400" },
                     { t: "14:00", p: "34 DEF 456", m: "8 m³", s: "Tamamlandı", c: "text-emerald-400" },
                     { t: "13:30", p: "34 GHI 789", m: "8 m³", s: "Tamamlandı", c: "text-emerald-400" },
                   ].map((m, i) => (
                     <div key={i} className="flex justify-between items-center p-3 rounded bg-white/5 border border-white/5">
                        <div className="flex items-center gap-3">
                          <div className="text-xs text-white/40">{m.t}</div>
                          <div className="font-medium text-sm border border-white/10 px-2 py-0.5 rounded bg-black">{m.p}</div>
                        </div>
                        <div className="flex items-center gap-4">
                          <div className="text-sm font-medium">{m.m}</div>
                          <div className={`text-xs ${m.c}`}>{m.s}</div>
                        </div>
                     </div>
                   ))}
                 </div>
              </div>
            </div>
            <div className="w-48 flex flex-col gap-4">
               <div className="bg-[#64748b]/10 border border-[#64748b]/30 rounded-xl p-4">
                 <div className="text-xs text-[#64748b] font-semibold mb-2">HAVA DURUMU</div>
                 <div className="text-2xl font-bold mb-1">18°C</div>
                 <div className="text-xs text-white/60">Nem: %45<br/>Rüzgar: 12 km/s</div>
               </div>
               <Button className="w-full bg-[#64748b] hover:bg-[#64748b]/90 text-white shadow-lg">Mikser Ekle</Button>
               <Button variant="outline" className="w-full border-white/10 text-white/70">Slump Testi Gir</Button>
            </div>
          </div>
        </div>
      )
    },
    {
      id: "malzeme",
      title: "ŞANTİJET MALZEME",
      subject: "Stok yönetimi, depo hareketleri, kritik stok",
      slogan: "Malzeme kayıplarını azalt.",
      color: "#059669",
      icon: <Database className="w-6 h-6" style={{ color: "#059669" }} />,
      mockup: (
        <div className="w-full h-full bg-[#0a0a0a] rounded-xl border border-white/10 overflow-hidden flex flex-col font-sans">
          <div className="p-5 border-b border-white/10 flex justify-between items-center">
            <h4 className="font-semibold">Depo Stok Durumu</h4>
            <div className="flex gap-2">
               <div className="px-3 py-1 rounded bg-[#059669]/20 text-[#059669] text-xs font-medium border border-[#059669]/30">Ana Depo</div>
               <div className="px-3 py-1 rounded bg-white/5 text-white/50 text-xs font-medium border border-white/10">Saha 1</div>
            </div>
          </div>
          <div className="p-5 flex-1">
             <div className="flex gap-4 mb-6">
                <div className="flex-1 bg-gradient-to-br from-red-500/10 to-transparent border border-red-500/20 p-4 rounded-lg">
                   <div className="text-red-400 text-xs font-medium mb-1">Kritik Stok Uyarısı</div>
                   <div className="text-xl font-bold text-white">4 Kalem</div>
                </div>
                <div className="flex-1 bg-white/5 border border-white/10 p-4 rounded-lg">
                   <div className="text-white/50 text-xs font-medium mb-1">Toplam Malzeme Değeri</div>
                   <div className="text-xl font-bold text-[#059669]">₺4.2M</div>
                </div>
             </div>
             
             <div className="space-y-3">
               {[
                 { n: "Çimento (Torba)", s: "120 Adet", status: "Kritik", w: "w-[15%]", c: "bg-red-500" },
                 { n: "Seramik Yapıştırıcı", s: "450 Torba", status: "Yeterli", w: "w-[60%]", c: "bg-[#059669]" },
                 { n: "İzolasyon Membranı", s: "85 Rulo", status: "Azalıyor", w: "w-[30%]", c: "bg-yellow-500" },
                 { n: "Alçıpan Plaka", s: "1,200 Adet", status: "İyi", w: "w-[85%]", c: "bg-[#059669]" },
               ].map((item, i) => (
                 <div key={i} className="p-3 bg-white/5 border border-white/5 rounded-lg">
                   <div className="flex justify-between text-sm mb-2">
                     <span className="font-medium text-white/90">{item.n}</span>
                     <span className="text-white/60">{item.s}</span>
                   </div>
                   <div className="h-1.5 w-full bg-black rounded-full overflow-hidden">
                     <div className={`h-full ${item.c} ${item.w} rounded-full`}></div>
                   </div>
                 </div>
               ))}
             </div>
          </div>
        </div>
      )
    },
    {
      id: "saha",
      title: "ŞANTİJET SAHA",
      subject: "Günlük raporlar, fotoğraf kayıtları, ilerleme",
      slogan: "Şantiyeyi cebinden yönet.",
      color: "#ea580c",
      icon: <MapPin className="w-6 h-6" style={{ color: "#ea580c" }} />,
      mockup: (
        <div className="w-full h-full bg-black rounded-xl border-4 border-[#1a1a1a] shadow-2xl overflow-hidden flex flex-col font-sans relative mx-auto max-w-[320px]">
          {/* Mobile frame header */}
          <div className="h-6 w-full flex justify-center pt-2 pb-1">
            <div className="w-16 h-1.5 bg-[#222] rounded-full"></div>
          </div>
          <div className="px-4 py-3 flex justify-between items-center border-b border-white/10">
            <div className="font-semibold">Günlük Rapor</div>
            <div className="text-xs bg-[#ea580c]/20 text-[#ea580c] px-2 py-1 rounded">24 Eki</div>
          </div>
          <div className="p-4 flex-1 overflow-y-auto space-y-4">
             <div>
               <div className="text-xs text-white/50 mb-2">HAVA DURUMU</div>
               <div className="flex gap-2">
                 <div className="flex-1 bg-white/5 rounded p-2 text-center border border-white/5 text-sm">Güneşli</div>
                 <div className="flex-1 bg-white/5 rounded p-2 text-center border border-white/5 text-sm">22°C</div>
               </div>
             </div>
             <div>
               <div className="text-xs text-white/50 mb-2">PERSONEL (124 Kişi)</div>
               <div className="bg-[#111] rounded-lg border border-white/10 p-3 space-y-2 text-sm">
                 <div className="flex justify-between"><span>Kalıpçı</span> <span className="font-medium">32</span></div>
                 <div className="flex justify-between"><span>Demirci</span> <span className="font-medium">28</span></div>
                 <div className="flex justify-between"><span>Betoncu</span> <span className="font-medium">14</span></div>
                 <div className="flex justify-between text-[#ea580c]"><span>Diğerleri</span> <span>50</span></div>
               </div>
             </div>
             <div>
               <div className="text-xs text-white/50 mb-2">FOTOĞRAFLAR</div>
               <div className="grid grid-cols-2 gap-2">
                 <div className="aspect-square bg-white/10 rounded flex items-center justify-center text-white/30 border border-white/5 relative overflow-hidden">
                   <div className="absolute inset-0 bg-gradient-to-t from-black/50 to-transparent"></div>
                   <Camera size={20} />
                 </div>
                 <div className="aspect-square bg-[#ea580c]/10 border border-[#ea580c]/30 rounded flex items-center justify-center text-[#ea580c]">
                   + Ekle
                 </div>
               </div>
             </div>
          </div>
          <div className="p-4 border-t border-white/10">
            <Button className="w-full bg-[#ea580c] text-white hover:bg-[#ea580c]/90">Raporu Gönder</Button>
          </div>
        </div>
      )
    }
  ];

  return (
    <section id="urunler" className="py-32 relative bg-black">
      {/* Container */}
      <div className="container mx-auto px-4">
        <div className="text-center mb-24">
           <motion.h2 
             initial={{ opacity: 0, y: 20 }}
             whileInView={{ opacity: 1, y: 0 }}
             viewport={{ once: true }}
             className="text-4xl md:text-6xl font-bold mb-6 tracking-tight"
           >
             İhtiyacınız Olan<br/><span className="text-transparent bg-clip-text bg-gradient-to-r from-primary to-blue-300">Her Şey Burada.</span>
           </motion.h2>
           <motion.p 
             initial={{ opacity: 0, y: 20 }}
             whileInView={{ opacity: 1, y: 0 }}
             viewport={{ once: true }}
             transition={{ delay: 0.1 }}
             className="text-xl text-muted-foreground max-w-3xl mx-auto"
           >
             Şantiyenizi uçtan uca yönetmeniz için tasarlandı. Sadece bir uygulama değil, eksiksiz bir teknoloji ekosistemi.
           </motion.p>
        </div>

        <div className="space-y-32">
          {products.map((product, idx) => {
            const isEven = idx % 2 === 0;
            return (
              <div key={product.id} className={`flex flex-col ${isEven ? 'lg:flex-row' : 'lg:flex-row-reverse'} gap-12 lg:gap-24 items-center`}>
                
                {/* Text Content */}
                <motion.div 
                  initial={{ opacity: 0, x: isEven ? -40 : 40 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  viewport={{ once: true, margin: "-100px" }}
                  transition={{ duration: 0.7, ease: "easeOut" }}
                  className="w-full lg:w-5/12 space-y-6"
                >
                  <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/5 border border-white/10" style={{ color: product.color }}>
                    {product.icon}
                    <span className="text-xs font-bold tracking-wider">{product.title}</span>
                  </div>
                  
                  <h3 className="text-3xl md:text-4xl font-bold leading-tight">
                    {product.slogan}
                  </h3>
                  
                  <p className="text-lg text-muted-foreground">
                    {product.subject}. Geleneksel Excel tablolarını ve WhatsApp gruplarını geride bırakın.
                  </p>
                  
                  <Button variant="link" className="p-0 h-auto text-white hover:text-white group" style={{ color: product.color }}>
                    <span className="mr-2 text-base font-semibold text-white">İncele</span> 
                    <ArrowRight className="w-5 h-5 transition-transform group-hover:translate-x-1" />
                  </Button>
                </motion.div>

                {/* Mockup Showcase */}
                <motion.div 
                  initial={{ opacity: 0, scale: 0.95 }}
                  whileInView={{ opacity: 1, scale: 1 }}
                  viewport={{ once: true, margin: "-100px" }}
                  transition={{ duration: 0.7, ease: "easeOut", delay: 0.2 }}
                  className="w-full lg:w-7/12 relative aspect-[4/3] md:aspect-[16/10]"
                >
                  {/* Glow effect */}
                  <div 
                    className="absolute inset-0 blur-[100px] opacity-20 pointer-events-none rounded-full"
                    style={{ backgroundColor: product.color }}
                  />
                  
                  <div className="relative w-full h-full rounded-2xl p-2 bg-white/5 border border-white/10 backdrop-blur-sm shadow-2xl">
                    {product.mockup}
                  </div>
                </motion.div>

              </div>
            );
          })}
        </div>

        {/* PRO SECTION (Centerpiece) */}
        <motion.div 
           initial={{ opacity: 0, y: 40 }}
           whileInView={{ opacity: 1, y: 0 }}
           viewport={{ once: true }}
           transition={{ duration: 0.8 }}
           className="mt-40 relative rounded-3xl overflow-hidden border border-white/10 bg-black text-center px-4 py-24 md:py-32"
        >
           <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,_var(--tw-gradient-stops))] from-primary/20 via-black to-black pointer-events-none" />
           <div className="absolute top-0 left-1/2 -translate-x-1/2 w-3/4 h-px bg-gradient-to-r from-transparent via-primary to-transparent" />
           
           <div className="relative z-10 max-w-4xl mx-auto flex flex-col items-center">
             <div className="w-24 h-24 rounded-2xl bg-gradient-to-br from-primary/40 to-primary/10 border border-primary/50 flex items-center justify-center shadow-[0_0_50px_rgba(26,95,255,0.4)] mb-8">
               <img src={`${import.meta.env.BASE_URL.replace(/\/$/, "")}/brand/santijet-bolt-nobg.png`} alt="Pro" className="w-16 h-16 object-contain" />
             </div>
             
             <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-primary/10 border border-primary/30 text-primary mb-6">
                <span className="text-sm font-bold tracking-widest uppercase">ŞANTİJET PRO</span>
             </div>
             
             <h2 className="text-4xl md:text-6xl font-bold mb-6">
               Tüm Şantiye Operasyonlarınız<br/>Tek Çatı Altında.
             </h2>
             
             <p className="text-xl text-muted-foreground mb-10 max-w-2xl">
               Farklı uygulamalar, dağınık veriler ve manuel raporlama döngüsüne son verin. Tüm modüllerin birbiriyle konuştuğu merkezi işletim sistemine geçin.
             </p>
             
             <div className="flex flex-col sm:flex-row gap-4">
               <Button size="lg" className="h-14 px-8 text-base bg-white text-black hover:bg-white/90 font-semibold">
                 Pro Ekosistemini Keşfet
               </Button>
               <Button size="lg" variant="outline" className="h-14 px-8 text-base border-white/20 text-white hover:bg-white/5">
                 Satış Ekibiyle Görüş
               </Button>
             </div>
           </div>
           
           {/* Abstract floating UI elements for PRO */}
           <div className="hidden md:block absolute top-1/4 left-10 w-48 h-32 bg-white/5 border border-white/10 rounded-xl backdrop-blur-md transform -rotate-6 p-4">
             <div className="w-1/2 h-2 bg-white/20 rounded mb-4" />
             <div className="w-3/4 h-2 bg-white/10 rounded mb-2" />
             <div className="w-full h-2 bg-white/10 rounded" />
           </div>
           <div className="hidden md:block absolute bottom-1/4 right-10 w-56 h-40 bg-white/5 border border-white/10 rounded-xl backdrop-blur-md transform rotate-3 p-4">
             <div className="flex justify-between items-center mb-4">
               <div className="w-8 h-8 rounded-full bg-primary/30" />
               <div className="w-16 h-4 bg-white/10 rounded" />
             </div>
             <div className="space-y-2">
               <div className="w-full h-2 bg-white/10 rounded" />
               <div className="w-4/5 h-2 bg-white/10 rounded" />
             </div>
           </div>
        </motion.div>

      </div>
    </section>
  );
}

// --- How It Works ---
function HowItWorks() {
  const steps = [
    { num: "01", title: "Keşif", desc: "Proje metrajları ve ihtiyaçlar belirlenir." },
    { num: "02", title: "Sipariş", desc: "Tedarikçilere dijital sipariş geçilir." },
    { num: "03", title: "Teslimat", desc: "Sahaya inen malzeme irsaliye ile kaydedilir." },
    { num: "04", title: "Saha Takibi", desc: "Günlük puantaj ve imalatlar işlenir." },
    { num: "05", title: "Raporlama", desc: "Otomatik günlük raporlar idareye sunulur." },
    { num: "06", title: "Yönetim", desc: "Hakediş ve maliyet analizi tek tıkla yapılır." },
  ];

  return (
    <section id="nasil-calisir" className="py-24 bg-black/30 border-y border-white/5 relative">
      <div className="container mx-auto px-4">
        <div className="text-center mb-16">
          <h2 className="text-3xl md:text-4xl font-bold mb-4">Kusursuz Operasyon Akışı</h2>
          <p className="text-muted-foreground max-w-2xl mx-auto">Mühendislik hassasiyetiyle tasarlanmış, sahada kanıtlanmış iş süreçleri.</p>
        </div>

        <div className="relative max-w-5xl mx-auto">
          {/* Desktop connecting line */}
          <div className="hidden md:block absolute top-1/2 left-0 right-0 h-px bg-white/10 -translate-y-1/2" />
          
          <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-6 gap-8">
            {steps.map((step, i) => (
              <div key={i} className="relative z-10 flex flex-col items-center text-center">
                <div className="w-12 h-12 rounded-full bg-background border-2 border-primary flex items-center justify-center text-lg font-bold mb-4 shadow-[0_0_15px_rgba(26,95,255,0.3)]">
                  {step.num}
                </div>
                <h3 className="font-bold mb-2">{step.title}</h3>
                <p className="text-xs text-muted-foreground">{step.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}

// --- Benefits ---
function Benefits() {
  return (
    <section className="py-24">
      <div className="container mx-auto px-4">
        <div className="grid md:grid-cols-2 gap-16 items-center">
          <div>
            <h2 className="text-3xl md:text-4xl font-bold mb-8">Neden ŞantiJET?</h2>
            <div className="space-y-6">
              {[
                { title: "Kağıt Ortadan Kalkar", desc: "Islak imzalı puantajlar ve kaybolan irsaliyeler tarihe karışır." },
                { title: "Şantiye Görünürlüğü Artar", desc: "Merkez ofisten, sahadaki tüm hareketleri anlık takip edin." },
                { title: "Maliyetler Kontrol Altına Alınır", desc: "Birim fiyat analizleri ile sürpriz maliyetleri engelleyin." },
                { title: "Verimlilik Yükselir", desc: "Tekrar eden manuel işleri yapay zeka destekli otomasyona bırakın." },
                { title: "Dijital İnşaat Operasyonu", desc: "Geleceğin inşaat yönetim standartlarını bugünden uygulayın." }
              ].map((b, i) => (
                <div key={i} className="flex gap-4">
                  <div className="mt-1 w-6 h-6 rounded-full bg-primary/20 flex items-center justify-center shrink-0">
                    <Check className="w-3 h-3 text-primary" />
                  </div>
                  <div>
                    <h4 className="font-bold mb-1">{b.title}</h4>
                    <p className="text-sm text-muted-foreground">{b.desc}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
          <div className="relative">
            <div className="aspect-square rounded-full border border-white/5 flex items-center justify-center relative">
               {/* Abstract decorative element representing efficiency/data */}
               <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,_var(--tw-gradient-stops))] from-primary/10 via-transparent to-transparent" />
               <Database className="w-32 h-32 text-primary/30 animate-pulse" />
               <div className="absolute top-1/4 left-1/4 w-4 h-4 bg-primary rounded-full shadow-[0_0_20px_rgba(26,95,255,1)]" />
               <div className="absolute bottom-1/3 right-1/4 w-3 h-3 bg-blue-400 rounded-full shadow-[0_0_15px_rgba(96,165,250,1)]" />
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}


// --- Pricing ---
function Pricing() {
  return (
    <section id="fiyatlandirma" className="py-24 relative">
      <div className="container mx-auto px-4">
        <div className="text-center mb-16">
          <h2 className="text-3xl md:text-4xl font-bold mb-4">Esnek Fiyatlandırma</h2>
          <p className="text-muted-foreground max-w-2xl mx-auto">İhtiyacınıza göre ölçeklenebilen, şeffaf paketler.</p>
        </div>

        <div className="grid md:grid-cols-3 gap-8 max-w-5xl mx-auto">
          {/* Tier 1 */}
          <div className="bg-black/40 border border-white/5 rounded-2xl p-8 flex flex-col">
            <h3 className="text-xl font-bold mb-2">Modüller</h3>
            <p className="text-sm text-muted-foreground mb-6">Sadece ihtiyacınız olanı alın.</p>
            <div className="text-3xl font-bold mb-6">Özel Fiyat<span className="text-lg text-muted-foreground font-normal">/modül</span></div>
            <ul className="space-y-3 mb-8 flex-grow">
              <li className="flex items-center gap-2 text-sm"><Check className="w-4 h-4 text-primary" /> Seçili modül kullanımı</li>
              <li className="flex items-center gap-2 text-sm"><Check className="w-4 h-4 text-primary" /> Temel destek</li>
              <li className="flex items-center gap-2 text-sm"><Check className="w-4 h-4 text-primary" /> 5 Kullanıcıya kadar</li>
            </ul>
            <Button variant="outline" className="w-full border-white/10">Bize Ulaşın</Button>
          </div>

          {/* Tier 2 - Popular */}
          <div className="bg-primary/5 border border-primary/30 rounded-2xl p-8 flex flex-col relative transform md:-translate-y-4 shadow-[0_0_40px_rgba(26,95,255,0.15)]">
            <div className="absolute top-0 left-1/2 -translate-x-1/2 -translate-y-1/2 bg-primary text-white text-xs font-bold px-3 py-1 rounded-full">
              EN POPÜLER
            </div>
            <h3 className="text-xl font-bold mb-2">ŞantiJET Pro</h3>
            <p className="text-sm text-muted-foreground mb-6">Tüm şantiye yönetimi tek ekranda.</p>
            <div className="text-3xl font-bold mb-6">Teklif Alın</div>
            <ul className="space-y-3 mb-8 flex-grow">
              <li className="flex items-center gap-2 text-sm"><Check className="w-4 h-4 text-primary" /> Tüm modüller dahil</li>
              <li className="flex items-center gap-2 text-sm"><Check className="w-4 h-4 text-primary" /> Gelişmiş ekip yönetimi</li>
              <li className="flex items-center gap-2 text-sm"><Check className="w-4 h-4 text-primary" /> AI destekli analizler</li>
              <li className="flex items-center gap-2 text-sm"><Check className="w-4 h-4 text-primary" /> Öncelikli destek</li>
            </ul>
            <Button className="w-full bg-primary text-white">Teklif İste</Button>
          </div>

          {/* Tier 3 */}
          <div className="bg-black/40 border border-white/5 rounded-2xl p-8 flex flex-col">
            <h3 className="text-xl font-bold mb-2">Enterprise</h3>
            <p className="text-sm text-muted-foreground mb-6">Büyük ölçekli firmalar için.</p>
            <div className="text-3xl font-bold mb-6">Özel SLA</div>
            <ul className="space-y-3 mb-8 flex-grow">
              <li className="flex items-center gap-2 text-sm"><Check className="w-4 h-4 text-primary" /> Sınırsız proje & kullanıcı</li>
              <li className="flex items-center gap-2 text-sm"><Check className="w-4 h-4 text-primary" /> ERP entegrasyonları</li>
              <li className="flex items-center gap-2 text-sm"><Check className="w-4 h-4 text-primary" /> Dedicated hesap yöneticisi</li>
              <li className="flex items-center gap-2 text-sm"><Check className="w-4 h-4 text-primary" /> Özel sunucu kurulumu</li>
            </ul>
            <Button variant="outline" className="w-full border-white/10">Satış Ekibiyle Görüş</Button>
          </div>
        </div>
      </div>
    </section>
  );
}

// --- FAQ & Footer ---
function FaqAndFooter() {
  const faqs = [
    { q: "Fiyatlandırma nasıl yapılıyor?", a: "Modül bazlı veya tüm sistemi kapsayan Pro paket olarak firmaya özel fiyatlandırma sunulmaktadır." },
    { q: "Verilerimiz güvende mi?", a: "Tüm verileriniz endüstri standardı şifreleme yöntemleriyle Türkiye içerisindeki güvenli sunucularda barındırılır." },
    { q: "Sahada internet olmadan çalışır mı?", a: "Mobil uygulamamız çevrimdışı (offline) çalışma desteğine sahiptir. İnternet bağlantısı sağlandığında veriler otomatik senkronize olur." },
    { q: "Sadece Demir modülünü alabilir miyim?", a: "Evet, ihtiyacınız olan modülleri tek tek satın alabilir, daha sonra diğer modülleri ekleyebilirsiniz." },
    { q: "Kurulum ve eğitim desteği veriyor musunuz?", a: "Pro ve Enterprise paketlerimizde yerinde kurulum, veri aktarımı ve personel eğitimleri uzman ekibimiz tarafından verilmektedir." }
  ];

  return (
    <>
      <section className="py-24 bg-black/20">
        <div className="container mx-auto px-4 max-w-3xl">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-bold mb-4">Sıkça Sorulan Sorular</h2>
          </div>
          <Accordion type="single" collapsible className="w-full">
            {faqs.map((faq, i) => (
              <AccordionItem key={i} value={`item-${i}`} className="border-white/10">
                <AccordionTrigger className="text-left font-medium hover:text-primary transition-colors">{faq.q}</AccordionTrigger>
                <AccordionContent className="text-muted-foreground leading-relaxed">
                  {faq.a}
                </AccordionContent>
              </AccordionItem>
            ))}
          </Accordion>
        </div>
      </section>

      <footer className="bg-black py-16 border-t border-white/5 relative overflow-hidden">
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-1/2 h-[1px] bg-gradient-to-r from-transparent via-primary/50 to-transparent" />
        <div className="container mx-auto px-4">
          <div className="grid grid-cols-2 md:grid-cols-5 gap-8 mb-12">
            <div className="col-span-2">
              <div className="flex items-center gap-1 mb-0">
                <img src={`${BASE_URL}/brand/santijet-bolt-nav-nobg.png`} alt="ŞantiJET" className="h-[86px] w-auto object-contain" />
                <img src={`${BASE_URL}/brand/santijet-wordmark-nobg.png`} alt="ŞantiJET" className="h-[103px] w-auto object-contain" />
              </div>
              <p className="text-sm text-muted-foreground max-w-xs">
                İnşaat operasyonlarınızı dijitalleştirin, sahadan merkeze tam kontrol sağlayın.
              </p>
            </div>
            <div>
              <h4 className="font-bold mb-4">Ürünler</h4>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li><a href="#" className="hover:text-white transition-colors">ŞantiJET Pro</a></li>
                <li><a href="#" className="hover:text-white transition-colors">Demir Modülü</a></li>
                <li><a href="#" className="hover:text-white transition-colors">Puantaj Modülü</a></li>
                <li><a href="#" className="hover:text-white transition-colors">Malzeme Modülü</a></li>
              </ul>
            </div>
            <div>
              <h4 className="font-bold mb-4">Şirket</h4>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li><a href="#" className="hover:text-white transition-colors">Hakkımızda</a></li>
                <li><a href="#" className="hover:text-white transition-colors">Kariyer</a></li>
                <li><a href="#" className="hover:text-white transition-colors">Blog</a></li>
                <li><a href="#" className="hover:text-white transition-colors">Basın</a></li>
              </ul>
            </div>
            <div>
              <h4 className="font-bold mb-4">Destek & İletişim</h4>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li><a href="#" className="hover:text-white transition-colors">Yardım Merkezi</a></li>
                <li><a href="#" className="hover:text-white transition-colors">API Dokümantasyonu</a></li>
                <li><a href="#" className="hover:text-white transition-colors">Bize Ulaşın</a></li>
                <li><a href="#" className="hover:text-white transition-colors">Sistem Durumu</a></li>
              </ul>
            </div>
          </div>
          <div className="border-t border-white/10 pt-8 flex flex-col md:flex-row items-center justify-between gap-4 text-xs text-muted-foreground">
            <div>© 2024 ŞantiJET. Tüm hakları saklıdır.</div>
            <div className="flex gap-4">
              <a href="#" className="hover:text-white transition-colors">Gizlilik Politikası</a>
              <a href="#" className="hover:text-white transition-colors">Kullanım Şartları</a>
              <a href="#" className="hover:text-white transition-colors">Çerez Politikası</a>
            </div>
          </div>
        </div>
      </footer>
    </>
  );
}

export default function Home() {
  return (
    <div className="min-h-screen bg-background text-foreground overflow-x-hidden selection:bg-primary/30 selection:text-primary font-sans">
      <Navbar />
      <main>
        <Hero />
        <Ecosystem />
        <ProductShowcase />
        <HowItWorks />
        <Benefits />
        <Pricing />
        <FaqAndFooter />
      </main>
    </div>
  );
}
