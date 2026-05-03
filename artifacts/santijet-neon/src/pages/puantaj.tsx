import React, { useState } from 'react';
import { useStore } from '@/store/useStore';
import { Users, Plus, Search, Filter } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from '@/components/ui/form';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { useToast } from '@/hooks/use-toast';
import { Badge } from '@/components/ui/badge';

const moduleColor = '#22d3ee'; // PUANTAJ color

const formSchema = z.object({
  ad: z.string().min(2, 'Ad soyad en az 2 karakter olmalıdır.'),
  firma: z.string().min(2, 'Firma adı zorunludur.'),
  gorev: z.string().min(2, 'Görev zorunludur.'),
  giris: z.string().regex(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/, 'Geçerli bir saat giriniz (SS:DD)'),
  cikis: z.string().regex(/^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/, 'Geçerli bir saat giriniz (SS:DD)'),
  mesai: z.string().default('0'),
});

export default function Puantaj() {
  const { puantaj, addPuantaj, addActivity } = useStore();
  const [searchTerm, setSearchTerm] = useState('');
  const [open, setOpen] = useState(false);
  const { toast } = useToast();

  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: { ad: '', firma: '', gorev: '', giris: '08:00', cikis: '18:00', mesai: '0' },
  });

  const onSubmit = (values: z.infer<typeof formSchema>) => {
    addPuantaj(values);
    addActivity(`Yeni puantaj eklendi: ${values.ad} (${values.firma})`, 'info');
    toast({
      title: "Kayıt Başarılı",
      description: `${values.ad} personeli puantaja eklendi.`,
      className: "bg-[#0b1224] border border-[#22d3ee] text-[#22d3ee] font-mono",
    });
    setOpen(false);
    form.reset();
  };

  const filteredData = puantaj.filter(p => 
    p.ad.toLowerCase().includes(searchTerm.toLowerCase()) || 
    p.firma.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="h-full flex flex-col gap-4">
      {/* Module Header Band */}
      <div className="flex items-center justify-between border-b pb-4 relative" style={{ borderColor: `${moduleColor}33` }}>
        <div className="absolute bottom-[-1px] left-0 w-32 h-[1px]" style={{ background: moduleColor, boxShadow: `0 0 10px ${moduleColor}` }} />
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded bg-cyan-500/10 border border-cyan-500/30 flex items-center justify-center">
            <Users size={20} color={moduleColor} style={{ filter: `drop-shadow(0 0 5px ${moduleColor})` }} />
          </div>
          <div>
            <h1 className="text-xl font-bold tracking-widest text-slate-100">PUANTAJ SİSTEMİ</h1>
            <p className="text-[10px] font-mono text-cyan-400/70 mt-1">GÜNLÜK PERSONEL TAKİBİ</p>
          </div>
        </div>
        
        <div className="flex gap-4">
          <div className="flex flex-col items-end">
            <span className="text-[9px] font-mono text-slate-500">TOPLAM PERSONEL</span>
            <span className="text-lg font-bold font-mono" style={{ color: moduleColor, textShadow: `0 0 10px ${moduleColor}88` }}>
              {puantaj.length}
            </span>
          </div>
        </div>
      </div>

      {/* Toolbar */}
      <div className="flex items-center justify-between bg-black/20 p-2 rounded border border-slate-800">
        <div className="flex items-center gap-2 w-full max-w-sm relative">
          <Search size={14} className="absolute left-3 text-slate-500" />
          <Input 
            placeholder="Personel veya firma ara..." 
            className="pl-9 bg-[#0b1224] border-slate-700 text-sm font-mono h-8 rounded-sm focus-visible:ring-cyan-500/50"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            data-testid="input-search-puantaj"
          />
        </div>
        
        <Dialog open={open} onOpenChange={setOpen}>
          <DialogTrigger asChild>
            <Button size="sm" className="h-8 bg-cyan-500/20 hover:bg-cyan-500/30 text-cyan-400 border border-cyan-500/50 rounded-sm font-mono text-[11px] tracking-wider" data-testid="button-new-puantaj">
              <Plus size={14} className="mr-1" /> YENİ PUANTAJ
            </Button>
          </DialogTrigger>
          <DialogContent className="bg-[#050810] border-cyan-500/30 text-slate-200 font-mono rounded-none border-t-2 border-t-cyan-500">
            <DialogHeader>
              <DialogTitle className="text-cyan-400 tracking-widest uppercase text-sm flex items-center gap-2">
                <Users size={16} /> PUANTAJ GİRİŞİ
              </DialogTitle>
            </DialogHeader>
            
            <Form {...form}>
              <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4 mt-4">
                <FormField control={form.control} name="ad" render={({ field }) => (
                  <FormItem>
                    <FormLabel className="text-[10px] text-slate-400">AD SOYAD</FormLabel>
                    <FormControl><Input {...field} className="bg-black/50 border-slate-700 h-8 rounded-sm text-sm" data-testid="input-ad" /></FormControl>
                    <FormMessage className="text-[10px] text-red-400" />
                  </FormItem>
                )} />
                <FormField control={form.control} name="firma" render={({ field }) => (
                  <FormItem>
                    <FormLabel className="text-[10px] text-slate-400">FİRMA</FormLabel>
                    <FormControl><Input {...field} className="bg-black/50 border-slate-700 h-8 rounded-sm text-sm" data-testid="input-firma" /></FormControl>
                    <FormMessage className="text-[10px] text-red-400" />
                  </FormItem>
                )} />
                <FormField control={form.control} name="gorev" render={({ field }) => (
                  <FormItem>
                    <FormLabel className="text-[10px] text-slate-400">GÖREV</FormLabel>
                    <FormControl><Input {...field} className="bg-black/50 border-slate-700 h-8 rounded-sm text-sm" data-testid="input-gorev" /></FormControl>
                    <FormMessage className="text-[10px] text-red-400" />
                  </FormItem>
                )} />
                
                <div className="grid grid-cols-3 gap-3">
                  <FormField control={form.control} name="giris" render={({ field }) => (
                    <FormItem>
                      <FormLabel className="text-[10px] text-slate-400">GİRİŞ (SS:DD)</FormLabel>
                      <FormControl><Input {...field} className="bg-black/50 border-slate-700 h-8 rounded-sm text-sm tabular-nums" data-testid="input-giris" /></FormControl>
                    </FormItem>
                  )} />
                  <FormField control={form.control} name="cikis" render={({ field }) => (
                    <FormItem>
                      <FormLabel className="text-[10px] text-slate-400">ÇIKIŞ (SS:DD)</FormLabel>
                      <FormControl><Input {...field} className="bg-black/50 border-slate-700 h-8 rounded-sm text-sm tabular-nums" data-testid="input-cikis" /></FormControl>
                    </FormItem>
                  )} />
                  <FormField control={form.control} name="mesai" render={({ field }) => (
                    <FormItem>
                      <FormLabel className="text-[10px] text-slate-400">MESAİ (SAAT)</FormLabel>
                      <FormControl><Input {...field} className="bg-black/50 border-slate-700 h-8 rounded-sm text-sm tabular-nums text-cyan-400" data-testid="input-mesai" /></FormControl>
                    </FormItem>
                  )} />
                </div>
                
                <div className="pt-2">
                  <Button type="submit" className="w-full bg-cyan-500 hover:bg-cyan-400 text-black font-bold tracking-widest text-xs h-9 rounded-sm" data-testid="button-submit-puantaj">
                    KAYDET
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
                <th className="px-4 py-3 font-semibold tracking-widest border-b border-slate-800">PERSONEL</th>
                <th className="px-4 py-3 font-semibold tracking-widest border-b border-slate-800">FİRMA</th>
                <th className="px-4 py-3 font-semibold tracking-widest border-b border-slate-800">GÖREV</th>
                <th className="px-4 py-3 font-semibold tracking-widest border-b border-slate-800">GİRİŞ - ÇIKIŞ</th>
                <th className="px-4 py-3 font-semibold tracking-widest border-b border-slate-800 text-right">MESAİ</th>
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
                    <td className="px-4 py-2.5 font-medium text-slate-200">{row.ad}</td>
                    <td className="px-4 py-2.5">
                      <Badge variant="outline" className="bg-slate-900/50 text-slate-300 border-slate-700 font-mono text-[10px] rounded-sm">
                        {row.firma}
                      </Badge>
                    </td>
                    <td className="px-4 py-2.5 text-slate-400 text-xs">{row.gorev}</td>
                    <td className="px-4 py-2.5 font-mono text-xs tabular-nums text-slate-300">
                      <span className="text-emerald-400/80">{row.giris}</span> 
                      <span className="text-slate-600 mx-1">/</span> 
                      <span className="text-red-400/80">{row.cikis}</span>
                    </td>
                    <td className="px-4 py-2.5 font-mono text-right font-bold">
                      {Number(row.mesai) > 0 ? (
                        <span className="text-cyan-400" style={{ textShadow: '0 0 5px #22d3ee55' }}>+{row.mesai}s</span>
                      ) : (
                        <span className="text-slate-600">-</span>
                      )}
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
