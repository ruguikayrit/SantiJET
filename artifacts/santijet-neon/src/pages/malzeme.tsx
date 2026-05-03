import React, { useState } from 'react';
import { useStore } from '@/store/useStore';
import { Package, Plus, Search, AlertTriangle, ArrowDownRight, ArrowUpRight } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from '@/components/ui/form';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { useToast } from '@/hooks/use-toast';
import { Badge } from '@/components/ui/badge';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';

const moduleColor = '#a78bfa';

const formSchema = z.object({
  id: z.string(),
  tip: z.enum(['giris', 'cikis']),
  miktar: z.coerce.number().min(1, 'Miktar 0\'dan büyük olmalıdır.'),
});

export default function Malzeme() {
  const { malzeme, updateMalzeme, addActivity } = useStore();
  const [searchTerm, setSearchTerm] = useState('');
  const [open, setOpen] = useState(false);
  const [selectedMalzeme, setSelectedMalzeme] = useState<string | null>(null);
  const { toast } = useToast();

  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: { id: '', tip: 'giris', miktar: 0 },
  });

  const onSubmit = (values: z.infer<typeof formSchema>) => {
    const item = malzeme.find(m => m.id === values.id);
    if (!item) return;

    const yeniStok = values.tip === 'giris' 
      ? Number(item.stok) + Number(values.miktar)
      : Number(item.stok) - Number(values.miktar);

    if (yeniStok < 0) {
      toast({
        title: "HATA",
        description: "Stok miktarı 0'ın altına düşemez.",
        className: "bg-[#0b1224] border border-red-500 text-red-500 font-mono",
      });
      return;
    }

    updateMalzeme(values.id, { stok: yeniStok });
    addActivity(`Stok hareketi (${values.tip}): ${item.ad} ${values.miktar} ${item.birim}`, values.tip === 'giris' ? 'success' : 'info');
    
    if (yeniStok < item.min) {
      addActivity(`Kritik stok uyarısı: ${item.ad} minimum seviyenin altında!`, 'warning');
    }

    toast({
      title: "Hareket Kaydedildi",
      description: `${item.ad} stoğu güncellendi. Yeni stok: ${yeniStok} ${item.birim}`,
      className: "bg-[#0b1224] border border-[#a78bfa] text-[#a78bfa] font-mono",
    });
    setOpen(false);
    form.reset();
  };

  const filteredData = malzeme.filter(m => 
    m.ad.toLowerCase().includes(searchTerm.toLowerCase()) || 
    m.kod.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="h-full flex flex-col gap-4">
      {/* Module Header Band */}
      <div className="flex items-center justify-between border-b pb-4 relative" style={{ borderColor: `${moduleColor}33` }}>
        <div className="absolute bottom-[-1px] left-0 w-32 h-[1px]" style={{ background: moduleColor, boxShadow: `0 0 10px ${moduleColor}` }} />
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded bg-[#a78bfa]/10 border border-[#a78bfa]/30 flex items-center justify-center">
            <Package size={20} color={moduleColor} style={{ filter: `drop-shadow(0 0 5px ${moduleColor})` }} />
          </div>
          <div>
            <h1 className="text-xl font-bold tracking-widest text-slate-100">MALZEME ENVANTERİ</h1>
            <p className="text-[10px] font-mono text-[#a78bfa]/70 mt-1">ANA DEPO STOK DURUMU</p>
          </div>
        </div>
        
        <div className="flex gap-4">
          <div className="flex flex-col items-end">
            <span className="text-[9px] font-mono text-slate-500">KRİTİK STOK</span>
            <span className="text-lg font-bold font-mono text-red-400" style={{ textShadow: `0 0 10px rgba(248, 113, 113, 0.5)` }}>
              {malzeme.filter(m => m.stok <= m.min).length}
            </span>
          </div>
          <div className="w-px bg-slate-800" />
          <div className="flex flex-col items-end">
            <span className="text-[9px] font-mono text-slate-500">TOPLAM KALEM</span>
            <span className="text-lg font-bold font-mono" style={{ color: moduleColor, textShadow: `0 0 10px ${moduleColor}88` }}>
              {malzeme.length}
            </span>
          </div>
        </div>
      </div>

      {/* Toolbar */}
      <div className="flex items-center justify-between bg-black/20 p-2 rounded border border-slate-800">
        <div className="flex items-center gap-2 w-full max-w-sm relative">
          <Search size={14} className="absolute left-3 text-slate-500" />
          <Input 
            placeholder="Malzeme kodu veya adı ara..." 
            className="pl-9 bg-[#0b1224] border-slate-700 text-sm font-mono h-8 rounded-sm focus-visible:ring-[#a78bfa]/50"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            data-testid="input-search-malzeme"
          />
        </div>
        
        <Dialog open={open} onOpenChange={setOpen}>
          <DialogTrigger asChild>
            <Button size="sm" className="h-8 bg-[#a78bfa]/20 hover:bg-[#a78bfa]/30 text-[#a78bfa] border border-[#a78bfa]/50 rounded-sm font-mono text-[11px] tracking-wider" data-testid="button-stok-hareketi">
              <Plus size={14} className="mr-1" /> STOK HAREKETİ
            </Button>
          </DialogTrigger>
          <DialogContent className="bg-[#050810] border-[#a78bfa]/30 text-slate-200 font-mono rounded-none border-t-2 border-t-[#a78bfa]">
            <DialogHeader>
              <DialogTitle className="text-[#a78bfa] tracking-widest uppercase text-sm flex items-center gap-2">
                <Package size={16} /> STOK GİRİŞ/ÇIKIŞ FİŞİ
              </DialogTitle>
            </DialogHeader>
            
            <Form {...form}>
              <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4 mt-4">
                <FormField control={form.control} name="id" render={({ field }) => (
                  <FormItem>
                    <FormLabel className="text-[10px] text-slate-400">MALZEME</FormLabel>
                    <Select onValueChange={field.onChange} defaultValue={field.value}>
                      <FormControl>
                        <SelectTrigger className="bg-black/50 border-slate-700 h-8 text-sm" data-testid="select-malzeme">
                          <SelectValue placeholder="Malzeme seçiniz" />
                        </SelectTrigger>
                      </FormControl>
                      <SelectContent className="bg-[#0b1224] border-slate-700 text-slate-200 font-mono">
                        {malzeme.map(m => (
                          <SelectItem key={m.id} value={m.id}>[{m.kod}] {m.ad}</SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    <FormMessage className="text-[10px] text-red-400" />
                  </FormItem>
                )} />

                <div className="grid grid-cols-2 gap-3">
                  <FormField control={form.control} name="tip" render={({ field }) => (
                    <FormItem>
                      <FormLabel className="text-[10px] text-slate-400">HAREKET TİPİ</FormLabel>
                      <Select onValueChange={field.onChange} defaultValue={field.value}>
                        <FormControl>
                          <SelectTrigger className="bg-black/50 border-slate-700 h-8 text-sm" data-testid="select-tip">
                            <SelectValue placeholder="Tip" />
                          </SelectTrigger>
                        </FormControl>
                        <SelectContent className="bg-[#0b1224] border-slate-700 text-slate-200 font-mono">
                          <SelectItem value="giris" className="text-emerald-400">GİRİŞ (+)</SelectItem>
                          <SelectItem value="cikis" className="text-red-400">ÇIKIŞ (-)</SelectItem>
                        </SelectContent>
                      </Select>
                      <FormMessage className="text-[10px] text-red-400" />
                    </FormItem>
                  )} />
                  <FormField control={form.control} name="miktar" render={({ field }) => (
                    <FormItem>
                      <FormLabel className="text-[10px] text-slate-400">MİKTAR</FormLabel>
                      <FormControl><Input type="number" {...field} className="bg-black/50 border-slate-700 h-8 rounded-sm text-sm tabular-nums text-[#a78bfa]" data-testid="input-miktar" /></FormControl>
                      <FormMessage className="text-[10px] text-red-400" />
                    </FormItem>
                  )} />
                </div>
                
                <div className="pt-2">
                  <Button type="submit" className="w-full bg-[#a78bfa] hover:bg-[#a78bfa]/80 text-black font-bold tracking-widest text-xs h-9 rounded-sm" data-testid="button-submit-malzeme">
                    İŞLEMİ ONAYLA
                  </Button>
                </div>
              </form>
            </Form>
          </DialogContent>
        </Dialog>
      </div>

      {/* Grid View */}
      <div className="flex-1 overflow-y-auto">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 pb-4">
          {filteredData.map((item) => {
            const isLow = item.stok <= item.min;
            return (
              <div 
                key={item.id}
                className="relative rounded border bg-[#0b1224]/80 p-4 flex flex-col gap-3 group transition-all"
                style={{
                  borderColor: isLow ? 'rgba(248, 113, 113, 0.4)' : `${moduleColor}22`,
                  boxShadow: isLow ? 'inset 0 0 20px rgba(248, 113, 113, 0.1)' : 'none'
                }}
              >
                <div className="flex items-start justify-between">
                  <div>
                    <div className="text-[10px] font-mono text-slate-500">{item.kod}</div>
                    <div className="font-bold text-slate-200 mt-0.5">{item.ad}</div>
                  </div>
                  {isLow && (
                    <div className="flex items-center gap-1 text-[9px] font-mono font-bold text-red-400 uppercase tracking-widest border border-red-500/30 px-1.5 py-0.5 rounded bg-red-500/10 animate-pulse">
                      <AlertTriangle size={10} /> KRİTİK
                    </div>
                  )}
                </div>

                <div className="flex items-end justify-between mt-2">
                  <div className="flex flex-col">
                    <span className="text-[10px] font-mono text-slate-500">MEVCUT STOK</span>
                    <div className="flex items-baseline gap-1.5 mt-1">
                      <span className="text-2xl font-black font-mono tabular-nums leading-none" style={{ 
                        color: isLow ? '#f87171' : moduleColor,
                        textShadow: isLow ? '0 0 10px rgba(248, 113, 113, 0.5)' : `0 0 10px ${moduleColor}55`
                      }}>
                        {item.stok.toLocaleString()}
                      </span>
                      <span className="text-xs font-mono text-slate-400">{item.birim}</span>
                    </div>
                  </div>
                  
                  <div className="flex flex-col items-end text-right">
                    <span className="text-[10px] font-mono text-slate-500">MIN. SEVİYE</span>
                    <span className="text-sm font-mono font-bold text-slate-400">{item.min.toLocaleString()}</span>
                  </div>
                </div>

                <div className="w-full h-1 bg-slate-900 rounded-full mt-1 overflow-hidden">
                  <div 
                    className="h-full rounded-full transition-all duration-500" 
                    style={{ 
                      width: `${Math.min(100, (item.stok / item.min) * 50)}%`,
                      background: isLow ? '#f87171' : moduleColor,
                      boxShadow: `0 0 5px ${isLow ? '#f87171' : moduleColor}`
                    }} 
                  />
                </div>

                <div className="mt-2 text-[10px] font-mono text-slate-500 flex items-center justify-between border-t border-slate-800 pt-2">
                  <span>DEPO: {item.depo}</span>
                  <div className="flex gap-2">
                    <button 
                      onClick={() => {
                        form.setValue('id', item.id);
                        form.setValue('tip', 'giris');
                        setOpen(true);
                      }}
                      className="text-emerald-400 hover:text-emerald-300 flex items-center gap-1"
                    >
                      <ArrowDownRight size={12} /> GİRİŞ
                    </button>
                    <button 
                      onClick={() => {
                        form.setValue('id', item.id);
                        form.setValue('tip', 'cikis');
                        setOpen(true);
                      }}
                      className="text-red-400 hover:text-red-300 flex items-center gap-1"
                    >
                      <ArrowUpRight size={12} /> ÇIKIŞ
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}
