import { motion } from "framer-motion";
import { Link } from "wouter";
import { 
  Building2, HardHat, FileText, Layers, TrendingUp, Calculator, ShieldCheck, 
  ChevronRight, Play, CheckCircle2, ArrowRight, Menu, X, Check, Zap, Server, Users, BarChart3, Database,
  Search, Settings, ArrowUpRight, ArrowDownRight, MoreHorizontal, Camera, Activity, LayoutDashboard, Bell, Box, Droplets, MapPin
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { useState, useEffect, useRef } from "react";
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
          <Link href="/" className="flex items-center">
            <img src={`${BASE_URL}/brand/santijet-wordmark-plain-nobg.png`} alt="ŞantiJET" className="h-10 w-auto object-contain" />
          </Link>
          
          <nav className="hidden md:flex items-center gap-8">
            <a href="#pro" className="text-sm font-medium text-muted-foreground hover:text-white transition-colors">Pro</a>
            <a href="#apps" className="text-sm font-medium text-muted-foreground hover:text-white transition-colors">Apps</a>
            <a href="#nasil-calisir" className="text-sm font-medium text-muted-foreground hover:text-white transition-colors">Nasıl Çalışır</a>
            <a href="#fiyatlandirma" className="text-sm font-medium text-muted-foreground hover:text-white transition-colors">Fiyatlandırma</a>
          </nav>

          <div className="hidden md:flex items-center gap-4">
            <a href="#fiyatlandirma">
              <Button variant="default" className="bg-primary hover:bg-primary/90 text-white shadow-[0_0_20px_rgba(26,95,255,0.4)]">
                Teklif Al
              </Button>
            </a>
          </div>

          <button className="md:hidden text-white" onClick={() => setMobileMenuOpen(!mobileMenuOpen)}>
            {mobileMenuOpen ? <X /> : <Menu />}
          </button>
        </div>
      </header>

      {mobileMenuOpen && (
        <div className="fixed inset-0 z-40 bg-background/95 backdrop-blur-xl pt-24 px-4 flex flex-col gap-6">
          <a href="#pro" onClick={() => setMobileMenuOpen(false)} className="text-lg font-medium">Pro — Firmalar</a>
          <a href="#apps" onClick={() => setMobileMenuOpen(false)} className="text-lg font-medium">Apps — Mühendisler</a>
          <a href="#nasil-calisir" onClick={() => setMobileMenuOpen(false)} className="text-lg font-medium">Nasıl Çalışır</a>
          <a href="#fiyatlandirma" onClick={() => setMobileMenuOpen(false)} className="text-lg font-medium">Fiyatlandırma</a>
          <a href="#fiyatlandirma" onClick={() => setMobileMenuOpen(false)}><Button className="w-full mt-4 bg-primary text-white">Teklif Al</Button></a>
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
          Firmalar için <span className="text-transparent bg-clip-text bg-gradient-to-r from-primary to-blue-300">ERP.</span> Mühendisler için uygulamalar.
        </motion.h1>
        
        <motion.p 
          initial="hidden" animate="visible" variants={fadeIn} transition={{ delay: 0.1 }}
          className="text-lg md:text-xl text-muted-foreground mb-10 max-w-2xl mx-auto leading-relaxed"
        >
          ŞantiJET Pro, firmanın keşiften hakedişe operasyonunu tek ERP’de toplar. ŞantiJET Apps, mühendisin metraj, hesap ve saha rutinini kısaltan uygulama ailesidir.
        </motion.p>
        
        <motion.div 
          initial="hidden" animate="visible" variants={fadeIn} transition={{ delay: 0.2 }}
          className="flex flex-col sm:flex-row items-center justify-center gap-4"
        >
          <a href="#pro" className="w-full sm:w-auto">
            <Button size="lg" className="w-full sm:w-auto text-base h-14 px-8 bg-primary hover:bg-primary/90 text-white shadow-[0_0_30px_rgba(26,95,255,0.5)]">
              Pro — Firmalar için
            </Button>
          </a>
          <a href="#apps" className="w-full sm:w-auto">
            <Button size="lg" variant="outline" className="w-full sm:w-auto text-base h-14 px-8 border-white/10 hover:bg-white/5 text-white">
              Apps — Mühendisler için
            </Button>
          </a>
        </motion.div>

      </div>
    </section>
  );
}

// --- Two families ---
function Families() {
  return (
    <section className="pb-8 pt-4 relative">
      <div className="container mx-auto px-4">
        <div className="text-center mb-12">
          <h2 className="text-3xl md:text-5xl font-bold mb-4">İki aile. İki iş.</h2>
          <p className="text-muted-foreground max-w-2xl mx-auto text-lg">
            Pro firmaya satılır. Apps mühendise satılır. Biri şirketin sistemi, diğeri kişinin elindeki araçtır.
          </p>
        </div>
        <div className="grid md:grid-cols-2 gap-6 max-w-5xl mx-auto">
          <a href="#pro" className="group rounded-3xl border border-primary/40 bg-primary/5 p-8 md:p-10 transition-colors hover:bg-primary/10">
            <div className="text-xs font-bold tracking-[0.22em] text-primary mb-4">FİRMALAR İÇİN</div>
            <h3 className="text-3xl font-bold mb-3">ŞantiJET Pro</h3>
            <p className="text-muted-foreground leading-relaxed mb-6">
              ERP sistemli şantiye uygulaması. Keşif, satın alma, malzeme, puantaj, günlük rapor, iş programı ve hakediş aynı kayıtta, ekip halinde yürür.
            </p>
            <div className="flex flex-wrap gap-2 mb-8">
              {["ERP", "Ekip ve yetki", "Şantiye geneli"].map((tag) => (
                <span key={tag} className="text-xs px-3 py-1 rounded-full border border-primary/30 text-primary/90">{tag}</span>
              ))}
            </div>
            <span className="inline-flex items-center text-sm font-semibold text-white">
              Pro ERP’yi gör <ArrowRight className="ml-2 w-4 h-4 transition-transform group-hover:translate-x-1" />
            </span>
          </a>
          <a href="#apps" className="group rounded-3xl border border-white/10 bg-white/[0.03] p-8 md:p-10 transition-colors hover:bg-white/[0.06]">
            <div className="text-xs font-bold tracking-[0.22em] text-cyan-300 mb-4">MÜHENDİSLER İÇİN</div>
            <h3 className="text-3xl font-bold mb-3">ŞantiJET Apps</h3>
            <p className="text-muted-foreground leading-relaxed mb-6">
              Rutin işi azaltan, hesabı ve kaydı hızlandıran uygulama ailesi. Demir, Beton, Maliyet, İş Programı, Tahvil, Kasa, Saha ve Malzeme ayrı ayrı alınır.
            </p>
            <div className="flex flex-wrap gap-2 mb-8">
              {["Tek iş, tek uygulama", "Hızlı rutin", "Mühendisin aracı"].map((tag) => (
                <span key={tag} className="text-xs px-3 py-1 rounded-full border border-white/15 text-white/70">{tag}</span>
              ))}
            </div>
            <span className="inline-flex items-center text-sm font-semibold text-white">
              Apps ailesini gör <ArrowRight className="ml-2 w-4 h-4 transition-transform group-hover:translate-x-1" />
            </span>
          </a>
        </div>
      </div>
    </section>
  );
}

// --- Ecosystem (ŞantiJET Pro ERP) ---

// 14 Pro modules, clockwise from the top, one shared radius.
const ECO_MODULES = [
  { name: "PLANLAMA",            color: "#ffd060", iconKey: "plan" },
  { name: "İMALAT",              color: "#00d4ff", iconKey: "imalat" },
  { name: "VERİM ANALİZİ",       color: "#3ddc97", iconKey: "verim" },
  { name: "PUANTAJ",             color: "#b06eff", iconKey: "puantaj" },
  { name: "BİRİM FİYAT ANALİZİ", color: "#ff4488", iconKey: "bfa" },
  { name: "KEŞİF",               color: "#ff8c40", iconKey: "kesif" },
  { name: "YAKLAŞIK MALİYET",    color: "#f472b6", iconKey: "maliyet" },
  { name: "BÜTÇE",               color: "#f5c542", iconKey: "butce" },
  { name: "KASA",                color: "#34d399", iconKey: "kasa" },
  { name: "HAKEDİŞ",             color: "#4a9eff", iconKey: "hakedis" },
  { name: "MALZEME",             color: "#00d68f", iconKey: "malzeme" },
  { name: "SATIN ALMA",          color: "#22d3ee", iconKey: "satin" },
  { name: "DEPO",                color: "#a3e635", iconKey: "depo" },
  { name: "MAKİNE",              color: "#fb923c", iconKey: "makine" },
];

// One fixed step around the hub. Every card is the same disc, so the
// gap along the ring is the same as the angle.
const PRO_CARD_W = 132;
const PRO_CARD_H = 132;
const PRO_HUB = 300;
const PRO_HUB_R = 148;
const PRO_RING_R = 136;
const PRO_FLOW = "#00D0FF";
const PRO_GAP = 28;
const PRO_CARD_GAP = 36;
const PRO_PAD = 36;
const PRO_ANGLE_STEP = (2 * Math.PI) / ECO_MODULES.length;
const PRO_GROUP_SCALE = 0.8;
const PRO_HUB_SCALE = 0.85;
const PRO_CARD_SCALE = 0.9;
const PRO_ORBIT_SCALE = 0.8 * 1.07;

function buildProDiagram() {
  const angles = Array.from({ length: ECO_MODULES.length }, (_, i) =>
    -Math.PI / 2 + i * PRO_ANGLE_STEP,
  );
  const radius = Math.max(
    (PRO_CARD_W + PRO_CARD_GAP) / (2 * Math.sin(PRO_ANGLE_STEP / 2)),
    PRO_HUB_R + PRO_GAP + PRO_CARD_W / 2,
  ) * PRO_ORBIT_SCALE;
  const raw = angles.map((a) => ({
    a,
    cx: Math.cos(a) * radius,
    cy: Math.sin(a) * radius,
  }));
  const minL = Math.min(...raw.map((p) => p.cx - PRO_CARD_W / 2));
  const maxR = Math.max(...raw.map((p) => p.cx + PRO_CARD_W / 2));
  const minT = Math.min(...raw.map((p) => p.cy - PRO_CARD_H / 2));
  const maxB = Math.max(...raw.map((p) => p.cy + PRO_CARD_H / 2));
  const ox = -minL + PRO_PAD;
  const oy = -minT + PRO_PAD;
  const cards = raw.map((p) => {
    const cx = p.cx + ox;
    const cy = p.cy + oy;
    return {
      cx,
      cy,
      initX: Math.cos(p.a) * 22,
      initY: Math.sin(p.a) * 22,
      ex: ox + Math.cos(p.a) * PRO_RING_R * PRO_HUB_SCALE,
      ey: oy + Math.sin(p.a) * PRO_RING_R * PRO_HUB_SCALE,
      tx: cx - Math.cos(p.a) * (PRO_CARD_W / 2) * PRO_CARD_SCALE,
      ty: cy - Math.sin(p.a) * (PRO_CARD_W / 2) * PRO_CARD_SCALE,
    };
  });
  const dots = angles.map((a) => ({
    x: 150 + Math.cos(a) * PRO_RING_R,
    y: 150 + Math.sin(a) * PRO_RING_R,
  }));
  return {
    width: Math.ceil(maxR - minL + PRO_PAD * 2),
    height: Math.ceil(maxB - minT + PRO_PAD * 2),
    hubX: ox,
    hubY: oy,
    cards,
    dots,
  };
}

const PRO_DIAGRAM = buildProDiagram();

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
      <svg width="33" height="33" viewBox="0 0 22 22">
        <rect x="3.5" y="2.5" width="15" height="17" rx="1.6" {...s} strokeWidth={1.6} />
        <line x1="6.5" y1="7" x2="15.5" y2="7" {...s} strokeWidth={1.6} />
        <line x1="6.5" y1="11" x2="15.5" y2="11" {...s} strokeWidth={1.6} />
        <line x1="6.5" y1="15" x2="12" y2="15" {...s} strokeWidth={1.6} />
      </svg>
    );
    case "plan": return (
      <svg width="33" height="33" viewBox="0 0 22 22">
        <rect x="3" y="4.5" width="16" height="14" rx="1.6" {...s} strokeWidth={1.6} />
        <line x1="3" y1="8.5" x2="19" y2="8.5" {...s} strokeWidth={1.6} />
        <line x1="7" y1="3" x2="7" y2="6" {...s} strokeWidth={1.6} />
        <line x1="15" y1="3" x2="15" y2="6" {...s} strokeWidth={1.6} />
      </svg>
    );
    case "imalat": return (
      <svg width="33" height="33" viewBox="0 0 22 22">
        <path d="M4 16 L8 8 L12 13 L16 6 L18 16 Z" {...s} strokeWidth={1.6} />
        <line x1="3" y1="18" x2="19" y2="18" {...s} strokeWidth={1.6} />
      </svg>
    );
    case "verim": return (
      <svg width="33" height="33" viewBox="0 0 22 22">
        <polyline points="3,16 8,11 12,14 19,6" {...s} strokeWidth={1.6} />
        <polyline points="14,6 19,6 19,11" {...s} strokeWidth={1.6} />
      </svg>
    );
    case "puantaj": return (
      <svg width="33" height="33" viewBox="0 0 22 22">
        <circle cx="11" cy="11" r="7.2" {...s} strokeWidth={1.6} />
        <polyline points="11,7.2 11,11 14,13" {...s} strokeWidth={1.6} />
      </svg>
    );
    case "kesif": return (
      <svg width="33" height="33" viewBox="0 0 22 22">
        <circle cx="9.5" cy="9.5" r="5.2" {...s} strokeWidth={1.6} />
        <line x1="13.2" y1="13.2" x2="18" y2="18" {...s} strokeWidth={1.6} />
      </svg>
    );
    case "maliyet": return (
      <svg width="33" height="33" viewBox="0 0 22 22">
        <rect x="4" y="3" width="14" height="16" rx="1.6" {...s} strokeWidth={1.6} />
        <line x1="7" y1="8" x2="15" y2="8" {...s} strokeWidth={1.6} />
        <line x1="7" y1="11.5" x2="15" y2="11.5" {...s} strokeWidth={1.6} />
        <line x1="7" y1="15" x2="12" y2="15" {...s} strokeWidth={1.6} />
      </svg>
    );
    case "butce": return (
      <svg width="33" height="33" viewBox="0 0 22 22">
        <rect x="3" y="6" width="16" height="11" rx="1.6" {...s} strokeWidth={1.6} />
        <path d="M7 6 V5.2 a4 4 0 0 1 8 0 V6" {...s} strokeWidth={1.6} />
      </svg>
    );
    case "kasa": return (
      <svg width="33" height="33" viewBox="0 0 22 22">
        <rect x="3" y="5" width="16" height="12" rx="1.6" {...s} strokeWidth={1.6} />
        <circle cx="11" cy="11" r="2.2" {...s} strokeWidth={1.6} />
        <line x1="3" y1="8" x2="5" y2="8" {...s} strokeWidth={1.6} />
      </svg>
    );
    case "hakedis": return (
      <svg width="33" height="33" viewBox="0 0 22 22">
        <path d="M5 4 h9 l3 3 v11 h-12 z" {...s} strokeWidth={1.6} />
        <polyline points="7.5,12 10,14.5 15,9" {...s} strokeWidth={1.6} />
      </svg>
    );
    case "malzeme": return (
      <svg width="33" height="33" viewBox="0 0 22 22">
        <path d="M4 8 L11 4.5 L18 8 L11 11.5 Z" {...s} strokeWidth={1.6} />
        <path d="M4 8 V14.5 L11 18 L11 11.5" {...s} strokeWidth={1.6} />
        <path d="M18 8 V14.5 L11 18" {...s} strokeWidth={1.6} />
      </svg>
    );
    case "satin": return (
      <svg width="33" height="33" viewBox="0 0 22 22">
        <path d="M4 5 h2.2 l1.4 8 h9.2 l1.4-5.5 H8" {...s} strokeWidth={1.6} />
        <circle cx="9" cy="17" r="1.2" fill={color} stroke="none" />
        <circle cx="15" cy="17" r="1.2" fill={color} stroke="none" />
      </svg>
    );
    case "depo": return (
      <svg width="33" height="33" viewBox="0 0 22 22">
        <path d="M3 9.5 L11 4 L19 9.5 V18 H3 Z" {...s} strokeWidth={1.6} />
        <rect x="8.5" y="12" width="5" height="6" {...s} strokeWidth={1.6} />
      </svg>
    );
    case "makine": return (
      <svg width="33" height="33" viewBox="0 0 22 22">
        <circle cx="11" cy="11" r="3" {...s} strokeWidth={1.6} />
        <path d="M11 3.5 V6 M11 16 V18.5 M3.5 11 H6 M16 11 H18.5 M5.6 5.6 L7.4 7.4 M14.6 14.6 L16.4 16.4 M16.4 5.6 L14.6 7.4 M7.4 14.6 L5.6 16.4" {...s} strokeWidth={1.6} />
      </svg>
    );
    default: return null;
  }
}

function EcoCard({
  name, color, iconKey, delay = 0, initX = 0, initY = 0,
  isActive = false, onHoverStart, onHoverEnd,
}: {
  name: string; color: string; iconKey: string;
  delay?: number; initX?: number; initY?: number;
  isActive?: boolean; onHoverStart?: () => void; onHoverEnd?: () => void;
}) {
  return (
    <motion.div
      initial={{ opacity: 0, x: initX, y: initY }}
      whileInView={{ opacity: 1, x: 0, y: 0 }}
      viewport={{ once: true }}
      transition={{ duration: 0.55, delay }}
      whileHover={{ scale: 1.045, transition: { duration: 0.25 } }}
      onHoverStart={onHoverStart}
      onHoverEnd={onHoverEnd}
      className="relative flex h-full w-full flex-col items-center justify-center overflow-hidden rounded-full cursor-default select-none text-center"
      style={{
        background: `radial-gradient(circle at 50% 36%, ${color}3a 0%, #08111f 48%, #040812 100%)`,
        boxShadow: isActive
          ? `0 0 0 1.5px ${color}, 0 0 28px ${color}66, inset 0 0 18px ${color}24`
          : `0 0 0 1.5px ${color}99, 0 0 18px ${color}30, inset 0 0 14px rgba(0,0,0,0.4)`,
        transition: "box-shadow 0.3s ease",
      }}
    >
      <span
        className="pointer-events-none absolute inset-[7px] rounded-full"
        style={{ border: `1px solid ${color}40` }}
      />
      <span
        className="relative mb-1 flex h-12 w-12 shrink-0 items-center justify-center rounded-full"
        style={{ background: "#050914e6", boxShadow: `inset 0 0 0 1px ${color}70` }}
      >
        <NeonIcon iconKey={iconKey} color={color} />
      </span>
      <span className="relative block max-w-[96px] text-center text-[10px] font-semibold leading-[1.2] text-white">
        {name}
      </span>
    </motion.div>
  );
}

function Ecosystem() {
  const [activeCard, setActiveCard] = useState<number | null>(null);
  const wrapRef = useRef<HTMLDivElement>(null);
  const [scale, setScale] = useState(PRO_GROUP_SCALE);

  useEffect(() => {
    const el = wrapRef.current;
    if (!el) return;
    const obs = new ResizeObserver(([entry]) => {
      const fit = Math.min(1, entry.contentRect.width / PRO_DIAGRAM.width);
      setScale(fit * PRO_GROUP_SCALE);
    });
    obs.observe(el);
    return () => obs.disconnect();
  }, []);

  const { width: stageW, height: stageH, hubX, hubY, cards, dots } = PRO_DIAGRAM;

  return (
    <section
      id="pro"
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
              Pro
            </span>
          </h2>
          <p className="text-white/50 text-base md:text-lg max-w-2xl mx-auto">Firmalar için ERP. Keşiften hakedişe modüller tek sistemde konuşur; ekip aynı kaydı görür.</p>
        </motion.div>

        {/* ── Desktop diagram ── */}
        <div
          ref={wrapRef}
          className="relative mx-auto hidden md:block"
          style={{ width: "100%", maxWidth: stageW }}
        >
          <div
            className="relative mx-auto"
            style={{ width: Math.round(stageW * scale), height: Math.round(stageH * scale) }}
          >
          <div style={{
            width: stageW,
            height: stageH,
            transform: `scale(${scale})`,
            transformOrigin: "top left",
          }}>

          {/* Full-scene SVG: connection lines + animated data-flow particles */}
          <svg
            className="absolute inset-0 pointer-events-none"
            style={{ width: "100%", height: "100%", zIndex: 1 }}
            viewBox={`0 0 ${stageW} ${stageH}`}
            preserveAspectRatio="xMidYMid meet"
          >
            <defs>
              <filter id="eco-line-glow" filterUnits="userSpaceOnUse" x={-48} y={-48} width={stageW + 96} height={stageH + 96}>
                <feGaussianBlur stdDeviation="4" result="b1" />
                <feGaussianBlur stdDeviation="11" result="b2" />
                <feMerge>
                  <feMergeNode in="b2" />
                  <feMergeNode in="b1" />
                  <feMergeNode in="SourceGraphic" />
                </feMerge>
              </filter>
              <filter id="eco-particle-glow" filterUnits="userSpaceOnUse" x={-48} y={-48} width={stageW + 96} height={stageH + 96}>
                <feGaussianBlur stdDeviation="3.5" result="b" />
                <feMerge><feMergeNode in="b" /><feMergeNode in="SourceGraphic" /></feMerge>
              </filter>
              <filter id="eco-dot-glow" filterUnits="userSpaceOnUse" x={-48} y={-48} width={stageW + 96} height={stageH + 96}>
                <feGaussianBlur stdDeviation="5" result="b" />
                <feMerge><feMergeNode in="b" /><feMergeNode in="SourceGraphic" /></feMerge>
              </filter>
            </defs>

            {cards.map((l, i) => {
              const fwdPath = `M ${l.ex},${l.ey} L ${l.tx},${l.ty}`;
              const revPath = `M ${l.tx},${l.ty} L ${l.ex},${l.ey}`;
              return (
                <g key={i}>
                  <line
                    x1={l.ex} y1={l.ey} x2={l.tx} y2={l.ty}
                    stroke={PRO_FLOW}
                    strokeWidth="1.6"
                    strokeLinecap="round"
                    strokeOpacity="0.9"
                    filter="url(#eco-line-glow)"
                  />
                  {[0, 0.34, 0.67].map((offset, j) => (
                    <circle key={`fwd-${j}`} r="2.6" fill={PRO_FLOW} filter="url(#eco-particle-glow)" opacity="0.95">
                      <animateMotion path={fwdPath} dur="3.6s" begin={`${-offset * 3.6}s`} repeatCount="indefinite" calcMode="linear" />
                    </circle>
                  ))}
                  {[0.17, 0.5].map((offset, j) => (
                    <circle key={`rev-${j}`} r="2.6" fill={PRO_FLOW} filter="url(#eco-particle-glow)" opacity="0.95">
                      <animateMotion path={revPath} dur="3.6s" begin={`${-offset * 3.6}s`} repeatCount="indefinite" calcMode="linear" />
                    </circle>
                  ))}
                  <circle cx={l.tx} cy={l.ty} r="4" fill={PRO_FLOW} fillOpacity="0.95" filter="url(#eco-dot-glow)" />
                </g>
              );
            })}
          </svg>

          {/* Cards — equal angles, one shared radius */}
          {ECO_MODULES.map((m, i) => {
            const { cx, cy, initX, initY } = cards[i];
            return (
              <div
                key={m.name}
                className="absolute"
                style={{ width: PRO_CARD_W, height: PRO_CARD_H, left: cx - PRO_CARD_W / 2, top: cy - PRO_CARD_H / 2, zIndex: 20, transform: `scale(${PRO_CARD_SCALE})`, transformOrigin: "center center" }}
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
            className="absolute"
            style={{ left: hubX - PRO_HUB / 2, top: hubY - PRO_HUB / 2, width: PRO_HUB, height: PRO_HUB, zIndex: 10, transform: `scale(${PRO_HUB_SCALE})`, transformOrigin: "center center" }}
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

                  {/* Connection dots at the same angles as the cards */}
                  {dots.map((dot, i) => (
                    <g key={i}>
                      <motion.circle
                        cx={dot.x} cy={dot.y} r={7}
                        fill="rgba(0,208,255,0.35)"
                        animate={{ opacity: [0.35, 0.9, 0.35] }}
                        transition={{ duration: 2.4, delay: i * 0.35, repeat: Infinity, ease: "easeInOut" }}
                        filter="url(#hub-dot-glow)"
                      />
                      <circle
                        cx={dot.x} cy={dot.y} r="3.8"
                        fill={PRO_FLOW}
                        fillOpacity="0.95"
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

          </div>{/* end scale wrapper */}
          </div>{/* end group frame */}
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
          <div className="grid w-full max-w-[292px] grid-cols-2 gap-3">
            {ECO_MODULES.map((m) => (
              <div key={m.name} className="aspect-square">
                <EcoCard {...m} delay={0} />
              </div>
            ))}
          </div>
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
      subject: "Demir metrajı, sipariş, gelen demir ve saha sayımı. Cetveli kur, siparişi geç, sayımı sahada kapat.",
      slogan: "Demir rutinini dakikalara indir.",
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
      title: "ŞANTİJET MALİYET",
      subject: "Birim fiyat, metraj, keşif ve yaklaşık maliyet. Pozu bul, analizi aç, cetveli çıkar.",
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
      id: "beton",
      title: "ŞANTİJET BETON",
      subject: "Beton keşfi, sipariş, döküm kaydı ve basınç testi. Mikser sahadayken kayıt kapanır.",
      slogan: "Dökümü ve testi sahada bitir.",
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
      subject: "Keşiften talebe, tekliften teslim almaya. Malzeme kalemini dosyalar arasında kaybetme.",
      slogan: "Talebi aç, teklifi karşılaştır, teslimi al.",
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
      subject: "Puantaj, imalat ve günlük saha raporu. Günün adam-gününü ve raporunu yerinde kapat.",
      slogan: "Puantajı ve raporu yerinde bitir.",
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
    <section id="apps" className="py-32 relative bg-black">
      <div className="container mx-auto px-4">
        <div className="text-center mb-24">
           <div className="text-xs font-bold tracking-[0.22em] text-cyan-300 mb-4">MÜHENDİSLER İÇİN</div>
           <motion.h2 
             initial={{ opacity: 0, y: 20 }}
             whileInView={{ opacity: 1, y: 0 }}
             viewport={{ once: true }}
             className="text-4xl md:text-6xl font-bold mb-6 tracking-tight"
           >
             ŞantiJET Apps.<br/><span className="text-transparent bg-clip-text bg-gradient-to-r from-cyan-300 to-blue-300">Rutini kısalt.</span>
           </motion.h2>
           <motion.p 
             initial={{ opacity: 0, y: 20 }}
             whileInView={{ opacity: 1, y: 0 }}
             viewport={{ once: true }}
             transition={{ delay: 0.1 }}
             className="text-xl text-muted-foreground max-w-3xl mx-auto"
           >
             Her uygulama tek bir mühendislik işini hızlandırır. İhtiyacın olanı alırsın; firma ERP’si ayrıca Pro’dadır.
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
                    {product.subject}
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

        <div className="mt-28 grid sm:grid-cols-3 gap-4 max-w-5xl mx-auto">
          {[
            { name: "Tahvil", desc: "Proje donatısını eldeki çap ve aralığa eşdeğer çevirir." },
            { name: "Kasa", desc: "İş avansı ve harcamayı şantiye defterinde tutar." },
            { name: "İş Programı", desc: "Planı girer, ilerlemeyi ve gecikmeyi gösterir." },
          ].map((app) => (
            <div key={app.name} className="rounded-2xl border border-white/10 bg-white/[0.03] p-6">
              <div className="text-[11px] font-bold tracking-[0.18em] text-cyan-300/80 mb-2">APPS</div>
              <h3 className="text-xl font-bold mb-2">ŞantiJET {app.name}</h3>
              <p className="text-sm text-muted-foreground leading-relaxed">{app.desc}</p>
            </div>
          ))}
        </div>

        {/* Pro, Apps’ten ayrı: firma ERP’si */}
        <motion.div 
           initial={{ opacity: 0, y: 40 }}
           whileInView={{ opacity: 1, y: 0 }}
           viewport={{ once: true }}
           transition={{ duration: 0.8 }}
           className="mt-32 relative rounded-3xl overflow-hidden border border-white/10 bg-black text-center px-4 py-24 md:py-32"
        >
           <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_center,_var(--tw-gradient-stops))] from-primary/20 via-black to-black pointer-events-none" />
           <div className="absolute top-0 left-1/2 -translate-x-1/2 w-3/4 h-px bg-gradient-to-r from-transparent via-primary to-transparent" />
           
           <div className="relative z-10 max-w-4xl mx-auto flex flex-col items-center">
             <div className="w-24 h-24 rounded-2xl bg-gradient-to-br from-primary/40 to-primary/10 border border-primary/50 flex items-center justify-center shadow-[0_0_50px_rgba(26,95,255,0.4)] mb-8">
               <img src={`${import.meta.env.BASE_URL.replace(/\/$/, "")}/brand/santijet-bolt-nobg.png`} alt="Pro" className="w-16 h-16 object-contain" />
             </div>
             
             <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-primary/10 border border-primary/30 text-primary mb-6">
                <span className="text-sm font-bold tracking-widest uppercase">Firmalar için · ERP</span>
             </div>
             
             <h2 className="text-4xl md:text-6xl font-bold mb-6">
               Mühendis uygulamayı açar.<br/>Firma sistemi Pro’da durur.
             </h2>
             
             <p className="text-xl text-muted-foreground mb-10 max-w-2xl">
               Apps tek kişinin rutinini hızlandırır. Pro, aynı şantiyenin keşif, satın alma, puantaj, rapor ve hakedişini ekip olarak tutan ERP’dir.
             </p>
             
             <div className="flex flex-col sm:flex-row gap-4">
               <a href="#pro">
                 <Button size="lg" className="h-14 px-8 text-base bg-white text-black hover:bg-white/90 font-semibold">
                   Pro ERP’yi incele
                 </Button>
               </a>
               <a href="#fiyatlandirma">
                 <Button size="lg" variant="outline" className="h-14 px-8 text-base border-white/20 text-white hover:bg-white/5">
                   Firma teklifi al
                 </Button>
               </a>
             </div>
           </div>
           
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
  const tracks = [
    {
      audience: "Firmalar · Pro",
      title: "ERP günü nasıl akar",
      tone: "text-primary",
      steps: [
        { num: "01", title: "Keşif", desc: "Metraj ve ihtiyaç proje kaydına girer." },
        { num: "02", title: "Satın alma", desc: "Talep ve sipariş aynı işe bağlanır." },
        { num: "03", title: "Saha", desc: "Puantaj, imalat ve günlük rapor ekibe düşer." },
        { num: "04", title: "Hakediş", desc: "Maliyet ve hakediş bu kayıttan çıkar." },
      ],
    },
    {
      audience: "Mühendisler · Apps",
      title: "Rutin nasıl kısalır",
      tone: "text-cyan-300",
      steps: [
        { num: "01", title: "İşi seç", desc: "Demir, beton, maliyet, program veya saha." },
        { num: "02", title: "Hesabı aç", desc: "Cetvel, döküm, analiz ya da kontrol tek ekranda." },
        { num: "03", title: "Sonucu al", desc: "Sayım, test, yaklaşık maliyet veya uygunluk kapanır." },
        { num: "04", title: "Kaydet", desc: "İş cihazda durur; firma sistemi gerekmez." },
      ],
    },
  ];

  return (
    <section id="nasil-calisir" className="py-24 bg-black/30 border-y border-white/5 relative">
      <div className="container mx-auto px-4">
        <div className="text-center mb-16">
          <h2 className="text-3xl md:text-4xl font-bold mb-4">İki ayrı akış</h2>
          <p className="text-muted-foreground max-w-2xl mx-auto">Pro şirketin operasyonunu bağlar. Apps, mühendisin o günkü hesabını hızlandırır.</p>
        </div>

        <div className="grid lg:grid-cols-2 gap-8 max-w-5xl mx-auto">
          {tracks.map((track) => (
            <div key={track.audience} className="rounded-3xl border border-white/10 bg-black/40 p-8">
              <div className={`text-xs font-bold tracking-[0.18em] mb-2 ${track.tone}`}>{track.audience}</div>
              <h3 className="text-2xl font-bold mb-8">{track.title}</h3>
              <div className="space-y-6">
                {track.steps.map((step) => (
                  <div key={step.num} className="flex gap-4">
                    <div className="w-10 h-10 rounded-full bg-background border border-white/15 flex items-center justify-center text-sm font-bold shrink-0">
                      {step.num}
                    </div>
                    <div>
                      <h4 className="font-bold">{step.title}</h4>
                      <p className="text-sm text-muted-foreground">{step.desc}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

// --- Benefits ---
function Benefits() {
  const columns = [
    {
      title: "Pro, firmaya ne kazandırır",
      items: [
        { title: "Tek kayıt", desc: "Keşif, satın alma, saha ve hakediş ayrı dosyalarda dağılmaz." },
        { title: "Ekip görünürlüğü", desc: "Ofis ve saha aynı şantiyenin hareketini görür." },
        { title: "Yetki", desc: "Kim neyi görür, kim neyi yazar, firma belirler." },
        { title: "Hakedişe giden iz", desc: "Metrajdan hak edişe kadar iz sürülebilir." },
      ],
    },
    {
      title: "Apps, mühendise ne kazandırır",
      items: [
        { title: "Kısa rutin", desc: "Metraj, tahvil, döküm ve puantaj el işi olmaktan çıkar." },
        { title: "Tek başına yeter", desc: "Bir uygulama, bir iş. Firma ERP’si kurmadan kullanılır." },
        { title: "Sahada kapanır", desc: "Sayım, test ve günlük rapor işin başında biter." },
        { title: "Seçerek alınır", desc: "Demir ayrı, Beton ayrı, Maliyet ayrı. İhtiyacın olanı alırsın." },
      ],
    },
  ];

  return (
    <section className="py-24">
      <div className="container mx-auto px-4">
        <h2 className="text-3xl md:text-4xl font-bold mb-12 text-center">Neden iki aile?</h2>
        <div className="grid md:grid-cols-2 gap-8 max-w-5xl mx-auto">
          {columns.map((col) => (
            <div key={col.title} className="rounded-3xl border border-white/10 p-8">
              <h3 className="text-2xl font-bold mb-8">{col.title}</h3>
              <div className="space-y-6">
                {col.items.map((b) => (
                  <div key={b.title} className="flex gap-4">
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
          ))}
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
          <h2 className="text-3xl md:text-4xl font-bold mb-4">Kime, ne satılır</h2>
          <p className="text-muted-foreground max-w-2xl mx-auto">Fiyat firmaya ve seçilen uygulamaya göre çıkar. Rakam teklifte netleşir.</p>
        </div>

        <div className="grid md:grid-cols-3 gap-8 max-w-5xl mx-auto">
          {/* Tier 1 */}
          <div className="bg-black/40 border border-white/5 rounded-2xl p-8 flex flex-col">
            <h3 className="text-xl font-bold mb-2">Apps</h3>
            <p className="text-sm text-muted-foreground mb-6">Mühendisler için. İhtiyacın olan uygulamayı al.</p>
            <div className="text-3xl font-bold mb-6">Teklif<span className="text-lg text-muted-foreground font-normal"> / uygulama</span></div>
            <ul className="space-y-3 mb-8 flex-grow">
              <li className="flex items-center gap-2 text-sm"><Check className="w-4 h-4 text-primary" /> Demir, Beton, Maliyet ve diğerleri</li>
              <li className="flex items-center gap-2 text-sm"><Check className="w-4 h-4 text-primary" /> Tek işi hızlandıran bağımsız araç</li>
              <li className="flex items-center gap-2 text-sm"><Check className="w-4 h-4 text-primary" /> Firma ERP’si gerekmez</li>
            </ul>
            <Button variant="outline" className="w-full border-white/10">Uygulama teklifi</Button>
          </div>

          {/* Tier 2 - Popular */}
          <div className="bg-primary/5 border border-primary/30 rounded-2xl p-8 flex flex-col relative transform md:-translate-y-4 shadow-[0_0_40px_rgba(26,95,255,0.15)]">
            <div className="absolute top-0 left-1/2 -translate-x-1/2 -translate-y-1/2 bg-primary text-white text-xs font-bold px-3 py-1 rounded-full">
              EN POPÜLER
            </div>
            <h3 className="text-xl font-bold mb-2">ŞantiJET Pro</h3>
            <p className="text-sm text-muted-foreground mb-6">Firmalar için ERP. Operasyon tek sistemde.</p>
            <div className="text-3xl font-bold mb-6">Teklif Alın</div>
            <ul className="space-y-3 mb-8 flex-grow">
              <li className="flex items-center gap-2 text-sm"><Check className="w-4 h-4 text-primary" /> Keşif, satın alma, saha, hakediş</li>
              <li className="flex items-center gap-2 text-sm"><Check className="w-4 h-4 text-primary" /> Ekip, yetki ve şantiye geneli</li>
              <li className="flex items-center gap-2 text-sm"><Check className="w-4 h-4 text-primary" /> Günlük rapor ve iş programı</li>
              <li className="flex items-center gap-2 text-sm"><Check className="w-4 h-4 text-primary" /> Kurulum görüşmesi</li>
            </ul>
            <Button className="w-full bg-primary text-white">Firma teklifi</Button>
          </div>

          {/* Tier 3 */}
          <div className="bg-black/40 border border-white/5 rounded-2xl p-8 flex flex-col">
            <h3 className="text-xl font-bold mb-2">Kurumsal</h3>
            <p className="text-sm text-muted-foreground mb-6">Çok şantiyeli firmalar için Pro.</p>
            <div className="text-3xl font-bold mb-6">Özel kapsam</div>
            <ul className="space-y-3 mb-8 flex-grow">
              <li className="flex items-center gap-2 text-sm"><Check className="w-4 h-4 text-primary" /> Birden fazla şantiye ve ekip</li>
              <li className="flex items-center gap-2 text-sm"><Check className="w-4 h-4 text-primary" /> Kurulum ve kullanıcı eğitimi</li>
              <li className="flex items-center gap-2 text-sm"><Check className="w-4 h-4 text-primary" /> Apps ailesiyle birlikte paket</li>
              <li className="flex items-center gap-2 text-sm"><Check className="w-4 h-4 text-primary" /> Ayrılmış iletişim hattı</li>
            </ul>
            <Button variant="outline" className="w-full border-white/10">Kurumsal görüşme</Button>
          </div>
        </div>
      </div>
    </section>
  );
}

// --- FAQ & Footer ---
function FaqAndFooter() {
  const faqs = [
    { q: "Pro ile Apps arasındaki fark nedir?", a: "Pro, firmalar için ERP’dir: keşif, satın alma, saha, rapor ve hakediş tek sistemde yürür. Apps, mühendisler için uygulama ailesidir: her uygulama tek bir rutini kısaltır ve tek başına kullanılır." },
    { q: "ŞantiJET Pro bir ERP mi?", a: "Evet. Pro, şantiyenin operasyon kaydını ekip halinde tutan ERP uygulamasıdır. Ayrı mühendislik araçlarının yerine geçmez; firmanın sistemidir." },
    { q: "Sadece Demir uygulamasını alabilir miyim?", a: "Evet. Apps ailesindeki uygulamalar ayrı alınır. Demir, Beton, Maliyet, İş Programı, Tahvil, Kasa, Saha ve Malzeme birbirine bağlı paket değildir." },
    { q: "Apps’i Pro olmadan kullanabilir miyim?", a: "Evet. Mühendis, firma ERP’si kurmadan ihtiyacı olan uygulamayı kullanır. Pro, şirketin ortak operasyon kaydı istendiğinde devreye girer." },
    { q: "Kurulum nasıl olur?", a: "Pro için firma teklifi ve kurulum görüşmesi yapılır. Apps için seçilen uygulamanın teklifi çıkar. Fiyat, şantiye sayısı ve uygulama listesine göre netleşir." }
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
                <img src={`${BASE_URL}/brand/santijet-wordmark-plain-nobg.png`} alt="ŞantiJET" className="h-10 w-auto object-contain" />
              </div>
              <p className="text-sm text-muted-foreground max-w-xs">
                Pro firmalar için ERP. Apps, mühendislerin rutinini kısaltan uygulama ailesi.
              </p>
            </div>
            <div>
              <h4 className="font-bold mb-4">Pro</h4>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li><a href="#pro" className="hover:text-white transition-colors">Firmalar için ERP</a></li>
                <li><a href="#pro" className="hover:text-white transition-colors">Keşif ve hakediş</a></li>
                <li><a href="#pro" className="hover:text-white transition-colors">Puantaj ve rapor</a></li>
                <li><a href="#fiyatlandirma" className="hover:text-white transition-colors">Firma teklifi</a></li>
              </ul>
            </div>
            <div>
              <h4 className="font-bold mb-4">Apps</h4>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li><a href="#apps" className="hover:text-white transition-colors">Demir</a></li>
                <li><a href="#apps" className="hover:text-white transition-colors">Beton</a></li>
                <li><a href="#apps" className="hover:text-white transition-colors">Maliyet</a></li>
                <li><a href="#apps" className="hover:text-white transition-colors">Saha</a></li>
              </ul>
            </div>
            <div>
              <h4 className="font-bold mb-4">İletişim</h4>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li><a href="#fiyatlandirma" className="hover:text-white transition-colors">Teklif al</a></li>
                <li><a href="#nasil-calisir" className="hover:text-white transition-colors">Nasıl çalışır</a></li>
                <li><a href="#apps" className="hover:text-white transition-colors">Tahvil, Kasa, Saha</a></li>
                <li><a href="#apps" className="hover:text-white transition-colors">İş Programı, Malzeme</a></li>
              </ul>
            </div>
          </div>
          <div className="border-t border-white/10 pt-8 flex flex-col md:flex-row items-center justify-between gap-4 text-xs text-muted-foreground">
            <div>© 2026 ŞantiJET. Tüm hakları saklıdır.</div>
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
        <Families />
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
