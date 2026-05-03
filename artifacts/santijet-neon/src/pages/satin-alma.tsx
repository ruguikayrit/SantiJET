import React, { useState } from 'react';
import { useStore } from '@/store/useStore';
import { ShoppingCart, Plus, Search, FileText, IndianRupee } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from '@/components/ui/form';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { useToast } from '@/hooks/use-toast';
import { Badge } from '@/components/ui/badge';

const moduleColor = '#f472b6';

const formSchema = z.object({
  poNo: z.string().min(2, 'PO No zorunludur.'),
  tedarikci: z.string().min(2, 'Tedarikçi zorunludur.'),
  kalemSayisi: z.coerce.number().min(1, 'En az 1 kalem olmalıdır.'),
  tutar: z.coerce.number().min(0, 'Tutar 0\'dan küçük olamaz.'),
});

export default function SatinAlma() {
  const { satinAlma, addSatinAlma, addActivity } = useStore();
  const [searchTerm, setSearchTerm] = useState('');
  const [open, setOpen] = useState(false);
  const { toast } = useToast();

  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: { poNo: `PO-${new Date().getFullYear()}-${Math.floor(Math.random() * 1000).toString().padStart(3, '0')}`, tedarikci: '', kalemSayisi: 1, tutar: 0 },
  });

  const onSubmit = (values: z.infer<typeof formSchema>) => {
    addSatinAlma({ ...values, durum: 'Taslak' });
    addActivity(`Yeni satınalma siparişi: ${values.poNo} (${values.tedarikci})`, 'info');
    toast({
      title: "Sipariş Oluşturuldu",
      description: `${values.poNo} numaralı sipariş taslak olarak kaydedildi.`,
      className: "bg-[#0b1224] border border-[#f472b6] text-[#f472b6] font-mono",
    });
    setOpen(false);
    form.reset({ poNo: `PO-${new Date().getFullYear()}-${Math.floor(Math.random() * 1000).toString().padStart(3, '0')}`, tedarikci: '', kalemSayisi: 1, tutar: 0 });
  };

  const filteredData = satinAlma.filter(s => 
    s.poNo.toLowerCase().includes(searchTerm.toLowerCase()) || 
    s.tedarikci.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const getStatusColor = (durum: string) => {
    switch (durum) {
      case 'Taslak': return 'text-slate-400 border-slate-500/30 bg-slate-500/10';
      case 'Bekliyor': return 'text-amber-400 border-amber-500/30 bg-amber-500/10 shadow-[0_0_10px_rgba(245,158,11,0.2)]';
      case 'Onaylandı': return 'text-[#f472b6] border-[#f472b6]/30 bg-[#f472b6]/10 shadow-[0_0_10px_rgba(244,114,182,0.2)]';
      case 'Tamamlandı': return 'text-emerald-400 border-emerald-500/30 bg-emerald-500/10 shadow-[0_0_10px_rgba(16,185,129,0.2)]';
      default: return 'text-slate-400 border-slate-500/30 bg-slate-500/10';
    }
  };

  const totalTutar = satinAlma.reduce((acc, curr) => acc + curr.tutar, 0);

  return (
    <div className="h-full flex flex-col gap-4">
      {/* Module Header Band */}
      <div className="flex items-center justify-between border-b pb-4 relative" style={{ borderColor: `${moduleColor}33` }}>
        <div className="absolute bottom-[-1px] left-0 w-32 h-[1px]" style={{ background: moduleColor, boxShadow: `0 0 10px ${moduleColor}` }} />
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded bg-[#f472b6]/10 border border-[#f472b6]/30 flex items-center justify-center">
            <ShoppingCart size={20} color={moduleColor} style={{ filter: `drop-shadow(0 0 5px ${moduleColor})` }} />
          </div>
          <div>
            <h1 className="text-xl font-bold tracking-widest text-slate-100">SATINALMA YÖNETİMİ</h1>
            <p className="text-[10px] font-mono text-[#f472b6]/70 mt-1">SİPARİŞ VE TEDARİK AĞI</p>
          </div>
        </div>
        
        <div className="flex gap-4">
          <div className="flex flex-col items-end">
            <span className="text-[9px] font-mono text-slate-500">TOPLAM TUTAR</span>
            <span className="text-lg font-bold font-mono" style={{ color: moduleColor, textShadow: `0 0 10px ${moduleColor}88` }}>
              ₺{totalTutar.toLocaleString('tr-TR')}
            </span>
          </div>
          <div className="w-px bg-slate-800" />
          <div className="flex flex-col items-end">
            <span className="text-[9px] font-mono text-slate-500">ONAY BEKLEYEN</span>
            <span className="text-lg font-bold font-mono text-amber-400" style={{ textShadow: `0 0 10px rgba(245,158,11,0.5)` }}>
              {satinAlma.filter(s => s.durum === 'Bekliyor').length}
            </span>
          </div>
        </div>
      </div>

      {/* Toolbar */}
      <div className="flex items-center justify-between bg-black/20 p-2 rounded border border-slate-800">
        <div className="flex items-center gap-2 w-full max-w-sm relative">
          <Search size={14} className="absolute left-3 text-slate-500" />
          <Input 
            placeholder="PO No veya tedarikçi ara..." 
            className="pl-9 bg-[#0b1224] border-slate-700 text-sm font-mono h-8 rounded-sm focus-visible:ring-[#f472b6]/50"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            data-testid="input-search-satin-alma"
          />
        </div>
        
        <Dialog open={open} onOpenChange={setOpen}>
          <DialogTrigger asChild>
            <Button size="sm" className="h-8 bg-[#f472b6]/20 hover:bg-[#f472b6]/30 text-[#f472b6] border border-[#f472b6]/50 rounded-sm font-mono text-[11px] tracking-wider" data-testid="button-yeni-siparis">
              <Plus size={14} className="mr-1" /> YENİ SİPARİŞ
            </Button>
          </DialogTrigger>
          <DialogContent className="bg-[#050810] border-[#f472b6]/30 text-slate-200 font-mono rounded-none border-t-2 border-t-[#f472b6]">
            <DialogHeader>
              <DialogTitle className="text-[#f472b6] tracking-widest uppercase text-sm flex items-center gap-2">
                <ShoppingCart size={16} /> SATINALMA SİPARİŞİ (PO)
              </DialogTitle>
            </DialogHeader>
            
            <Form {...form}>
              <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4 mt-4">
                <FormField control={form.control} name="poNo" render={({ field }) => (
                  <FormItem>
                    <FormLabel className="text-[10px] text-slate-400">PO NUMARASI</FormLabel>
                    <FormControl><Input {...field} className="bg-black/50 border-slate-700 h-8 rounded-sm text-sm font-bold tracking-widest" data-testid="input-poNo" /></FormControl>
                    <FormMessage className="text-[10px] text-red-400" />
                  </FormItem>
                )} />
                <FormField control={form.control} name="tedarikci" render={({ field }) => (
                  <FormItem>
                    <FormLabel className="text-[10px] text-slate-400">TEDARİKÇİ FİRMA</FormLabel>
                    <FormControl><Input {...field} className="bg-black/50 border-slate-700 h-8 rounded-sm text-sm" data-testid="input-tedarikci" /></FormControl>
                    <FormMessage className="text-[10px] text-red-400" />
                  </FormItem>
                )} />
                
                <div className="grid grid-cols-2 gap-3">
                  <FormField control={form.control} name="kalemSayisi" render={({ field }) => (
                    <FormItem>
                      <FormLabel className="text-[10px] text-slate-400">KALEM SAYISI</FormLabel>
                      <FormControl><Input type="number" {...field} className="bg-black/50 border-slate-700 h-8 rounded-sm text-sm tabular-nums" data-testid="input-kalem" /></FormControl>
                      <FormMessage className="text-[10px] text-red-400" />
                    </FormItem>
                  )} />
                  <FormField control={form.control} name="tutar" render={({ field }) => (
                    <FormItem>
                      <FormLabel className="text-[10px] text-slate-400">TOPLAM TUTAR (₺)</FormLabel>
                      <FormControl><Input type="number" {...field} className="bg-black/50 border-slate-700 h-8 rounded-sm text-sm tabular-nums text-[#f472b6]" data-testid="input-tutar" /></FormControl>
                      <FormMessage className="text-[10px] text-red-400" />
                    </FormItem>
                  )} />
                </div>
                
                <div className="pt-2">
                  <Button type="submit" className="w-full bg-[#f472b6] hover:bg-[#f472b6]/80 text-black font-bold tracking-widest text-xs h-9 rounded-sm" data-testid="button-submit-po">
                    SİPARİŞİ OLUŞTUR
                  </Button>
                </div>
              </form>
            </Form>
          </DialogContent>
        </Dialog>
      </div>

      {/* Data Table */}
      <div className="flex-1 border border-slate-800 rounded bg-[#0b1224]/50 overflow-hidden flex flex-col">
        <div className="overflow-x-auto flex-1">
          <table className="w-full text-sm text-left">
            <thead className="text-[10px] uppercase font-mono bg-black/40 text-slate-400 sticky top-0">
              <tr>
                <th className="px-4 py-3 font-semibold tracking-widest border-b border-slate-800">PO NO</th>
                <th className="px-4 py-3 font-semibold tracking-widest border-b border-slate-800">TEDARİKÇİ</th>
                <th className="px-4 py-3 font-semibold tracking-widest border-b border-slate-800 text-center">KALEM</th>
                <th className="px-4 py-3 font-semibold tracking-widest border-b border-slate-800 text-right">TUTAR</th>
                <th className="px-4 py-3 font-semibold tracking-widest border-b border-slate-800">DURUM</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/50">
              {filteredData.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-4 py-8 text-center text-slate-500 font-mono text-xs">
                    KAYIT BULUNAMADI.
                  </td>
                </tr>
              ) : (
                filteredData.map((row) => (
                  <tr key={row.id} className="hover:bg-slate-800/30 transition-colors group">
                    <td className="px-4 py-3 font-mono font-bold text-[#f472b6] tracking-wider text-xs">
                      {row.poNo}
                    </td>
                    <td className="px-4 py-3 text-slate-200 font-medium">{row.tedarikci}</td>
                    <td className="px-4 py-3 text-center">
                      <Badge variant="outline" className="bg-slate-900/50 text-slate-300 border-slate-700 font-mono text-[10px] rounded-sm">
                        {row.kalemSayisi} ADET
                      </Badge>
                    </td>
                    <td className="px-4 py-3 font-mono text-right tabular-nums text-slate-200">
                      ₺{row.tutar.toLocaleString('tr-TR')}
                    </td>
                    <td className="px-4 py-3">
                      <div className={`inline-flex items-center px-2 py-0.5 rounded border font-mono text-[10px] uppercase tracking-wider font-bold ${getStatusColor(row.durum)}`}>
                        {row.durum}
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
