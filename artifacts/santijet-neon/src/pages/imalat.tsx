import React, { useState } from 'react';
import { useStore } from '@/store/useStore';
import { Hammer, Plus, Search, Map } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from '@/components/ui/form';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { useToast } from '@/hooks/use-toast';
import { Slider } from '@/components/ui/slider';

const moduleColor = '#fb923c';

const formSchema = z.object({
  isEmri: z.string().min(2, 'İş emri zorunludur.'),
  blok: z.string().min(1, 'Blok zorunludur.'),
  kat: z.string().min(1, 'Kat zorunludur.'),
  imalatTipi: z.string().min(2, 'İmalat tipi zorunludur.'),
  ilerleme: z.coerce.number().min(0).max(100),
});

export default function Imalat() {
  const { imalat, addImalat, updateImalatProgress, addActivity } = useStore();
  const [searchTerm, setSearchTerm] = useState('');
  const [open, setOpen] = useState(false);
  const { toast } = useToast();

  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: { isEmri: `IE-${Math.floor(Math.random() * 1000).toString().padStart(3, '0')}`, blok: '', kat: '', imalatTipi: '', ilerleme: 0 },
  });

  const onSubmit = (values: z.infer<typeof formSchema>) => {
    addImalat(values);
    addActivity(`Yeni imalat emri: ${values.isEmri} - ${values.blok} ${values.imalatTipi}`, 'info');
    toast({
      title: "İş Emri Açıldı",
      description: `${values.isEmri} numaralı üretim emri kaydedildi.`,
      className: "bg-[#0b1224] border border-[#fb923c] text-[#fb923c] font-mono",
    });
    setOpen(false);
    form.reset({ isEmri: `IE-${Math.floor(Math.random() * 1000).toString().padStart(3, '0')}`, blok: '', kat: '', imalatTipi: '', ilerleme: 0 });
  };

  const handleProgressUpdate = (id: string, val: number[], isEmri: string) => {
    updateImalatProgress(id, val[0]);
    if (val[0] === 100) {
      addActivity(`İmalat tamamlandı: ${isEmri}`, 'success');
    }
  };

  const filteredData = imalat.filter(i => 
    i.isEmri.toLowerCase().includes(searchTerm.toLowerCase()) || 
    i.blok.toLowerCase().includes(searchTerm.toLowerCase()) ||
    i.imalatTipi.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="h-full flex flex-col gap-4">
      {/* Module Header Band */}
      <div className="flex items-center justify-between border-b pb-4 relative" style={{ borderColor: `${moduleColor}33` }}>
        <div className="absolute bottom-[-1px] left-0 w-32 h-[1px]" style={{ background: moduleColor, boxShadow: `0 0 10px ${moduleColor}` }} />
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded bg-[#fb923c]/10 border border-[#fb923c]/30 flex items-center justify-center">
            <Hammer size={20} color={moduleColor} style={{ filter: `drop-shadow(0 0 5px ${moduleColor})` }} />
          </div>
          <div>
            <h1 className="text-xl font-bold tracking-widest text-slate-100">SAHA İMALAT TAKİBİ</h1>
            <p className="text-[10px] font-mono text-[#fb923c]/70 mt-1">ÜRETİM DURUM KONTROLÜ</p>
          </div>
        </div>
        
        <div className="flex gap-4">
          <div className="flex flex-col items-end">
            <span className="text-[9px] font-mono text-slate-500">TAMAMLANAN</span>
            <span className="text-lg font-bold font-mono text-emerald-400" style={{ textShadow: `0 0 10px rgba(16,185,129,0.5)` }}>
              {imalat.filter(i => i.ilerleme === 100).length}
            </span>
          </div>
          <div className="w-px bg-slate-800" />
          <div className="flex flex-col items-end">
            <span className="text-[9px] font-mono text-slate-500">AKTİF İŞ EMRİ</span>
            <span className="text-lg font-bold font-mono" style={{ color: moduleColor, textShadow: `0 0 10px ${moduleColor}88` }}>
              {imalat.filter(i => i.ilerleme < 100).length}
            </span>
          </div>
        </div>
      </div>

      {/* Toolbar */}
      <div className="flex items-center justify-between bg-black/20 p-2 rounded border border-slate-800">
        <div className="flex items-center gap-2 w-full max-w-sm relative">
          <Search size={14} className="absolute left-3 text-slate-500" />
          <Input 
            placeholder="İş emri, blok veya tip ara..." 
            className="pl-9 bg-[#0b1224] border-slate-700 text-sm font-mono h-8 rounded-sm focus-visible:ring-[#fb923c]/50"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            data-testid="input-search-imalat"
          />
        </div>
        
        <Dialog open={open} onOpenChange={setOpen}>
          <DialogTrigger asChild>
            <Button size="sm" className="h-8 bg-[#fb923c]/20 hover:bg-[#fb923c]/30 text-[#fb923c] border border-[#fb923c]/50 rounded-sm font-mono text-[11px] tracking-wider" data-testid="button-yeni-imalat">
              <Plus size={14} className="mr-1" /> YENİ İŞ EMRİ
            </Button>
          </DialogTrigger>
          <DialogContent className="bg-[#050810] border-[#fb923c]/30 text-slate-200 font-mono rounded-none border-t-2 border-t-[#fb923c]">
            <DialogHeader>
              <DialogTitle className="text-[#fb923c] tracking-widest uppercase text-sm flex items-center gap-2">
                <Hammer size={16} /> ÜRETİM EMRİ
              </DialogTitle>
            </DialogHeader>
            
            <Form {...form}>
              <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4 mt-4">
                <FormField control={form.control} name="isEmri" render={({ field }) => (
                  <FormItem>
                    <FormLabel className="text-[10px] text-slate-400">İŞ EMRİ KODU</FormLabel>
                    <FormControl><Input {...field} className="bg-black/50 border-slate-700 h-8 rounded-sm text-sm font-bold tracking-widest text-[#fb923c]" data-testid="input-isEmri" /></FormControl>
                    <FormMessage className="text-[10px] text-red-400" />
                  </FormItem>
                )} />
                
                <div className="grid grid-cols-2 gap-3">
                  <FormField control={form.control} name="blok" render={({ field }) => (
                    <FormItem>
                      <FormLabel className="text-[10px] text-slate-400">BLOK/BÖLGE</FormLabel>
                      <FormControl><Input {...field} className="bg-black/50 border-slate-700 h-8 rounded-sm text-sm uppercase" data-testid="input-blok" /></FormControl>
                      <FormMessage className="text-[10px] text-red-400" />
                    </FormItem>
                  )} />
                  <FormField control={form.control} name="kat" render={({ field }) => (
                    <FormItem>
                      <FormLabel className="text-[10px] text-slate-400">KAT/KOT</FormLabel>
                      <FormControl><Input {...field} className="bg-black/50 border-slate-700 h-8 rounded-sm text-sm uppercase" data-testid="input-kat" /></FormControl>
                      <FormMessage className="text-[10px] text-red-400" />
                    </FormItem>
                  )} />
                </div>

                <FormField control={form.control} name="imalatTipi" render={({ field }) => (
                  <FormItem>
                    <FormLabel className="text-[10px] text-slate-400">İMALAT TİPİ</FormLabel>
                    <FormControl><Input {...field} className="bg-black/50 border-slate-700 h-8 rounded-sm text-sm" data-testid="input-imalatTipi" /></FormControl>
                    <FormMessage className="text-[10px] text-red-400" />
                  </FormItem>
                )} />

                <FormField control={form.control} name="ilerleme" render={({ field }) => (
                  <FormItem>
                    <FormLabel className="text-[10px] text-slate-400">BAŞLANGIÇ İLERLEMESİ (%)</FormLabel>
                    <FormControl>
                      <div className="flex items-center gap-4">
                        <Slider 
                          value={[field.value]} 
                          onValueChange={(vals) => field.onChange(vals[0])}
                          max={100} step={1}
                          className="flex-1"
                        />
                        <span className="font-mono text-xs w-8 text-right">{field.value}%</span>
                      </div>
                    </FormControl>
                    <FormMessage className="text-[10px] text-red-400" />
                  </FormItem>
                )} />
                
                <div className="pt-2">
                  <Button type="submit" className="w-full bg-[#fb923c] hover:bg-[#fb923c]/80 text-black font-bold tracking-widest text-xs h-9 rounded-sm" data-testid="button-submit-imalat">
                    SAHAYA AKTAR
                  </Button>
                </div>
              </form>
            </Form>
          </DialogContent>
        </Dialog>
      </div>

      {/* List View */}
      <div className="flex-1 overflow-y-auto space-y-3 pb-4">
        {filteredData.map((item) => (
          <div key={item.id} className="bg-[#0b1224]/80 border border-slate-800 rounded p-4 flex flex-col md:flex-row md:items-center gap-4 transition-colors hover:border-[#fb923c]/30">
            <div className="w-40 shrink-0">
              <div className="text-[10px] font-mono text-slate-500 uppercase tracking-widest">İŞ EMRİ</div>
              <div className="font-mono font-bold text-[#fb923c] text-sm mt-0.5" style={{ textShadow: `0 0 5px ${moduleColor}55` }}>{item.isEmri}</div>
            </div>
            
            <div className="w-48 shrink-0">
              <div className="text-[10px] font-mono text-slate-500 uppercase tracking-widest">LOKASYON</div>
              <div className="flex items-center gap-1.5 text-sm text-slate-200 mt-0.5">
                <Map size={14} className="text-slate-400" />
                <span className="font-bold">{item.blok}</span>
                <span className="text-slate-500">/</span>
                <span>{item.kat}</span>
              </div>
            </div>

            <div className="w-48 shrink-0">
              <div className="text-[10px] font-mono text-slate-500 uppercase tracking-widest">İMALAT TİPİ</div>
              <div className="text-sm text-slate-300 mt-0.5 font-medium">{item.imalatTipi}</div>
            </div>

            <div className="flex-1 flex items-center gap-4 min-w-[200px]">
              <div className="flex-1">
                <Slider 
                  value={[item.ilerleme]} 
                  onValueChange={(vals) => handleProgressUpdate(item.id, vals, item.isEmri)}
                  max={100} step={5}
                  className="w-full"
                />
              </div>
              <div className="w-16 text-right">
                <span className="text-xl font-black font-mono tabular-nums leading-none" style={{ 
                  color: item.ilerleme === 100 ? '#10b981' : moduleColor,
                  textShadow: item.ilerleme === 100 ? '0 0 10px rgba(16,185,129,0.5)' : `0 0 10px ${moduleColor}55`
                }}>
                  {item.ilerleme}
                </span>
                <span className="text-[10px] font-mono text-slate-500">%</span>
              </div>
            </div>
          </div>
        ))}
        {filteredData.length === 0 && (
          <div className="p-8 text-center text-slate-500 font-mono text-sm border border-dashed border-slate-800 rounded">
            KAYIT BULUNAMADI.
          </div>
        )}
      </div>
    </div>
  );
}
