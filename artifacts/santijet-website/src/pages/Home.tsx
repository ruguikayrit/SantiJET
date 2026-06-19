import { motion } from "framer-motion";
import { Link } from "wouter";
import { 
  Building2, HardHat, FileText, Layers, TrendingUp, Calculator, ShieldCheck, 
  ChevronRight, Play, CheckCircle2, ArrowRight, Menu, X, Check, Zap, Server, Users, BarChart3, Database
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
          <Link href="/" className="flex items-center gap-2">
            <img src={`${BASE_URL}/brand/santijet-logo-full.png`} alt="ŞantiJET Logo" className="h-8 object-contain" />
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

        {/* Premium Dashboard Mockup */}
        <motion.div 
          initial={{ opacity: 0, y: 40 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.4, duration: 0.8 }}
          className="mt-20 relative mx-auto max-w-5xl"
        >
          <div className="absolute inset-0 bg-gradient-to-t from-background via-transparent to-transparent z-10" />
          <div className="rounded-xl border border-white/10 bg-black/50 backdrop-blur-sm overflow-hidden shadow-2xl">
            <div className="h-12 border-b border-white/5 flex items-center px-4 gap-2">
              <div className="flex gap-1.5">
                <div className="w-3 h-3 rounded-full bg-red-500/80" />
                <div className="w-3 h-3 rounded-full bg-yellow-500/80" />
                <div className="w-3 h-3 rounded-full bg-green-500/80" />
              </div>
              <div className="mx-auto bg-white/5 rounded-md px-4 py-1 text-xs text-muted-foreground flex items-center gap-2">
                <ShieldCheck className="w-3 h-3" /> santijet.com/pro
              </div>
            </div>
            <div className="p-6 grid grid-cols-1 md:grid-cols-12 gap-6 opacity-90">
              <div className="hidden md:block col-span-3 space-y-4">
                <div className="flex items-center gap-2 mb-6">
                  <div className="w-8 h-8 rounded bg-primary/20 flex items-center justify-center">
                    <Building2 className="w-4 h-4 text-primary" />
                  </div>
                  <div className="text-sm font-medium">Merkez Şantiye</div>
                </div>
                <div className="space-y-1">
                  {['Dashboard', 'Demir', 'Malzeme', 'Puantaj', 'Günlük Rapor'].map((item, i) => (
                    <div key={i} className={`px-3 py-2 rounded-md text-sm ${i === 0 ? 'bg-primary/10 text-primary' : 'text-muted-foreground hover:bg-white/5'}`}>
                      {item}
                    </div>
                  ))}
                </div>
              </div>
              <div className="col-span-1 md:col-span-9 space-y-6">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-lg font-semibold">Proje Özeti</h3>
                  <div className="text-sm text-muted-foreground">Bugün, 24 Eki</div>
                </div>
                <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
                  {[
                    { label: "Bekleyen Siparişler", val: "14", color: "text-blue-400" },
                    { label: "Saha Mevcudu", val: "128", color: "text-emerald-400" },
                    { label: "Günlük İlerleme", val: "%4.2", color: "text-purple-400" }
                  ].map((stat, i) => (
                    <div key={i} className="p-4 bg-white/5 border border-white/5 rounded-lg">
                      <div className="text-xs text-muted-foreground mb-2">{stat.label}</div>
                      <div className={`text-2xl font-bold ${stat.color}`}>{stat.val}</div>
                    </div>
                  ))}
                </div>
                <div className="h-48 bg-white/5 border border-white/5 rounded-lg flex items-end p-4 gap-2">
                  {/* Fake Chart */}
                  {[40, 70, 45, 90, 65, 80, 100].map((h, i) => (
                    <div key={i} className="flex-1 bg-primary/20 hover:bg-primary/40 transition-colors rounded-t-sm" style={{ height: `${h}%` }}></div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  );
}

// --- Ecosystem ---
function Ecosystem() {
  const nodes = [
    { name: "Demir", icon: <Layers />, color: "border-blue-500", pos: "top-[10%] left-[20%]" },
    { name: "Malzeme", icon: <Building2 />, color: "border-emerald-500", pos: "top-[10%] right-[20%]" },
    { name: "Puantaj", icon: <Users />, color: "border-orange-500", pos: "top-[40%] right-[10%]" },
    { name: "Günlük Rapor", icon: <FileText />, color: "border-purple-500", pos: "bottom-[10%] right-[25%]" },
    { name: "Birim Fiyat", icon: <Calculator />, color: "border-pink-500", pos: "bottom-[10%] left-[25%]" },
    { name: "Metraj", icon: <BarChart3 />, color: "border-yellow-500", pos: "top-[40%] left-[10%]" },
    { name: "Hakediş", icon: <FileText />, color: "border-cyan-500", pos: "top-[75%] left-[15%]" },
  ];

  return (
    <section id="ekosistem" className="py-24 bg-black/30 border-y border-white/5 relative overflow-hidden">
      <div className="container mx-auto px-4 text-center">
        <h2 className="text-3xl md:text-4xl font-bold mb-4">ŞantiJET Ekosistemi</h2>
        <p className="text-muted-foreground mb-16 max-w-2xl mx-auto">Tüm modüller birbiriyle entegre çalışır. Veri silolarını yıkın, tek gerçeğe odaklanın.</p>
        
        <div className="relative w-full max-w-4xl mx-auto h-[500px] flex items-center justify-center">
          {/* Connecting Lines SVG */}
          <svg className="absolute inset-0 w-full h-full opacity-20 pointer-events-none">
            <circle cx="50%" cy="50%" r="35%" fill="none" stroke="currentColor" strokeWidth="1" strokeDasharray="4 4" className="text-primary animate-[spin_60s_linear_infinite]" />
            <circle cx="50%" cy="50%" r="20%" fill="none" stroke="currentColor" strokeWidth="1" strokeDasharray="4 4" className="text-primary animate-[spin_40s_linear_infinite_reverse]" />
            {/* Draw lines from center to nodes */}
            <line x1="50%" y1="50%" x2="20%" y2="10%" stroke="currentColor" strokeWidth="1" className="text-primary" />
            <line x1="50%" y1="50%" x2="80%" y2="10%" stroke="currentColor" strokeWidth="1" className="text-primary" />
            <line x1="50%" y1="50%" x2="90%" y2="40%" stroke="currentColor" strokeWidth="1" className="text-primary" />
            <line x1="50%" y1="50%" x2="75%" y2="90%" stroke="currentColor" strokeWidth="1" className="text-primary" />
            <line x1="50%" y1="50%" x2="25%" y2="90%" stroke="currentColor" strokeWidth="1" className="text-primary" />
            <line x1="50%" y1="50%" x2="10%" y2="40%" stroke="currentColor" strokeWidth="1" className="text-primary" />
            <line x1="50%" y1="50%" x2="15%" y2="75%" stroke="currentColor" strokeWidth="1" className="text-primary" />
          </svg>

          {/* Center Node */}
          <motion.div 
            initial={{ scale: 0.8, opacity: 0 }}
            whileInView={{ scale: 1, opacity: 1 }}
            viewport={{ once: true }}
            className="absolute z-20 w-[180px] h-[180px] bg-background border border-primary/50 rounded-full flex flex-col items-center justify-center shadow-[0_0_80px_rgba(26,95,255,0.5)]"
          >
            <img
              src={`${BASE_URL}/brand/santijet-bolt-nobg.png`}
              alt="ŞantiJET"
              className="w-36 h-36 object-contain"
            />
            <span
              style={{ fontFamily: "'Inter', sans-serif", letterSpacing: "0.18em" }}
              className="-mt-3 text-xl font-semibold text-primary/90 uppercase tracking-widest leading-none"
            >
              PRO
            </span>
          </motion.div>

          {/* Orbiting Nodes */}
          {nodes.map((node, i) => (
            <motion.div
              key={i}
              initial={{ opacity: 0, scale: 0.5 }}
              whileInView={{ opacity: 1, scale: 1 }}
              viewport={{ once: true }}
              transition={{ delay: i * 0.1 }}
              className={`absolute ${node.pos} z-10 w-24 h-24 bg-background border-2 ${node.color} rounded-full flex flex-col items-center justify-center shadow-lg`}
            >
              <div className="text-white mb-1 opacity-80">{node.icon}</div>
              <span className="text-[10px] font-medium text-center leading-tight px-2">{node.name}</span>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}

// --- Pro Platform & Modules ---
function Modules() {
  const modules = [
    {
      id: "demir",
      title: "ŞantiJET Demir",
      desc: "Demir keşfi, sipariş, teslimat, saha sayımı ve stok yönetimi.",
      features: ["Keşif & Metraj", "Sipariş Takibi", "Saha Sayımı"],
      icon: <Layers className="w-6 h-6 text-blue-400" />
    },
    {
      id: "malzeme",
      title: "ŞantiJET Malzeme",
      desc: "Şantiye malzeme giriş çıkış ve stok takibi.",
      features: ["Malzeme Girişi", "Stok Kontrolü", "İrsaliye Yönetimi"],
      icon: <Building2 className="w-6 h-6 text-emerald-400" />
    },
    {
      id: "puantaj",
      title: "ŞantiJET Puantaj",
      desc: "Personel ve ekip puantaj yönetimi.",
      features: ["Günlük Puantaj", "Ekip Yönetimi", "Mesai Takibi"],
      icon: <Users className="w-6 h-6 text-orange-400" />
    },
    {
      id: "gunluk-rapor",
      title: "ŞantiJET Günlük Rapor",
      desc: "Günlük saha faaliyetleri ve ilerleme raporları.",
      features: ["Fotoğraflı Rapor", "Ekip Özeti", "İlerleme Takibi"],
      icon: <FileText className="w-6 h-6 text-purple-400" />
    },
    {
      id: "birim-fiyat",
      title: "ŞantiJET Birim Fiyat",
      desc: "Birim fiyat analizleri ve maliyet kontrolü.",
      features: ["Analiz Kitaplığı", "Maliyet Simülasyonu", "Karşılaştırmalı Analiz"],
      icon: <Calculator className="w-6 h-6 text-pink-400" />
    },
    {
      id: "metraj",
      title: "ŞantiJET Metraj",
      desc: "Metraj hesaplama ve miktar yönetimi.",
      features: ["Otomatik Hesaplama", "Poz Yönetimi", "Hakediş Entegrasyonu"],
      icon: <BarChart3 className="w-6 h-6 text-yellow-400" />
    },
    {
      id: "hakedis",
      title: "ŞantiJET Hakediş",
      desc: "Hakediş hazırlama ve kontrol süreçleri.",
      features: ["Otomatik Hazırlama", "İdare Kontrolü", "Revizyon Takibi"],
      icon: <FileText className="w-6 h-6 text-cyan-400" />
    }
  ];

  return (
    <section id="urunler" className="py-24 relative">
      <div className="container mx-auto px-4">
        
        {/* Pro Platform Banner */}
        <div className="mb-24 p-8 md:p-12 rounded-2xl bg-gradient-to-br from-primary/20 to-background border border-primary/20 relative overflow-hidden">
          <div className="absolute top-0 right-0 w-64 h-64 bg-primary/20 blur-[80px] pointer-events-none" />
          <div className="relative z-10 grid md:grid-cols-2 gap-8 items-center">
            <div>
              <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-primary/20 text-primary text-sm font-medium mb-4">
                <Zap className="w-4 h-4" /> Master Platform
              </div>
              <h2 className="text-3xl md:text-4xl font-bold mb-4">ŞantiJET Pro</h2>
              <p className="text-lg text-muted-foreground mb-6">Tüm ŞantiJET modüllerini tek platformda birleştiren profesyonel inşaat operasyon sistemi.</p>
              <ul className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                {["Merkezi Dashboard", "Proje Yönetimi", "Kullanıcı Yönetimi", "Raporlama", "Veri Senkronizasyonu", "AI Destekli Analizler"].map((f, i) => (
                  <li key={i} className="flex items-center gap-2 text-sm">
                    <CheckCircle2 className="w-4 h-4 text-primary" /> {f}
                  </li>
                ))}
              </ul>
            </div>
            <div className="relative">
               <div className="aspect-video rounded-lg bg-black/50 border border-white/10 p-4 shadow-xl">
                 <div className="flex gap-2 mb-4 border-b border-white/10 pb-4">
                   <div className="w-10 h-10 rounded bg-white/5 flex items-center justify-center"><Server className="w-5 h-5 text-primary" /></div>
                   <div>
                     <div className="text-sm font-medium">Veri Senkronizasyonu</div>
                     <div className="text-xs text-green-400">Aktif</div>
                   </div>
                 </div>
                 <div className="space-y-2">
                   <div className="h-2 bg-white/10 rounded w-full"></div>
                   <div className="h-2 bg-white/10 rounded w-5/6"></div>
                   <div className="h-2 bg-white/10 rounded w-4/6"></div>
                 </div>
               </div>
            </div>
          </div>
        </div>

        {/* Modules Grid */}
        <div className="text-center mb-12">
          <h2 className="text-3xl md:text-4xl font-bold mb-4">İhtiyacınız Olan Modülü Seçin</h2>
          <p className="text-muted-foreground max-w-2xl mx-auto">İster tek modül ile başlayın, ister tüm süreçleri dijitalleştirin.</p>
        </div>

        <div className="grid md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {modules.map((mod, i) => (
            <motion.div 
              key={mod.id}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ delay: i * 0.05 }}
              className="group bg-black/40 border border-white/5 hover:border-primary/50 rounded-xl p-6 transition-all hover:shadow-[0_0_30px_rgba(26,95,255,0.15)] flex flex-col"
            >
              <div className="w-12 h-12 rounded-lg bg-white/5 flex items-center justify-center mb-4 group-hover:scale-110 transition-transform">
                {mod.icon}
              </div>
              <h3 className="text-xl font-bold mb-2">{mod.title}</h3>
              <p className="text-sm text-muted-foreground mb-6 flex-grow">{mod.desc}</p>
              
              <ul className="space-y-2 mb-6">
                {mod.features.map((f, idx) => (
                  <li key={idx} className="flex items-center gap-2 text-sm text-white/80">
                    <Check className="w-4 h-4 text-primary/70" /> {f}
                  </li>
                ))}
              </ul>

              <Button variant="ghost" className="w-full justify-between hover:bg-primary hover:text-white border border-white/10">
                İncele <ArrowRight className="w-4 h-4" />
              </Button>
            </motion.div>
          ))}
        </div>
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
              <img src={`${BASE_URL}/brand/santijet-logo-full.png`} alt="ŞantiJET" className="h-8 mb-6" />
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
        <Modules />
        <HowItWorks />
        <Benefits />
        <Pricing />
        <FaqAndFooter />
      </main>
    </div>
  );
}
