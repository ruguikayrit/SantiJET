import React, { useState } from 'react';
import { useStore } from '@/store/useStore';
import { Scale, Plus, Search, Truck, Clock } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from '@/components/ui/form';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import { useToast } from '@/hooks/use-toast';

const moduleColor = '#facc15';

const formSchema = z.object({
  plaka: z.string().min(2, 'Plaka zorunludur.'),
  malzeme: z.string().min(2, 'Malzeme zorunludur.'),
  dara: z.coerce.number().min(0.1, 'Dara 0\'dan büyük olmalıdır.'),
  brut: z.coerce.number().min(0.1, 'Brüt 0\'dan büyük olmalıdır.'),
}).refine(data => data.brut > data.dara, {
  message: "Brüt ağırlık, daradan büyük olmalıdır.",
  path: ["brut"],
});

export default function Kantar() {
  const { kantar, addKantar, addActivity } = useStore();
  const [searchTerm, setSearchTerm] = useState('');
  const [open, setOpen] = useState(false);
  const { toast } = useToast();

  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: { plaka: '', malzeme: '', dara: 0, brut: 0 },
  });

  const onSubmit = (values: z.infer<typeof formSchema>) => {
    const net = Number((values.brut - values.dara).toFixed(2));
    const fisNo = `K-${Math.floor(Math.random() * 10000).toString().padStart(4, '0')}`;
    const tarih = new Date().toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' });
    
    addKantar({ ...values, fisNo, net, tarih });
    addActivity(`Kantar tartımı: ${values.plaka} - Net: ${net}t`, 'info');
    
    toast({
      title: "Tartım Tamamlandı",
      description: `${fisNo} numaralı fiş oluşturuldu. Net: ${net} ton.`,
      className: "bg-[#0b1224] border border-[#facc15] text-[#facc15] font-mono",
    });
    setOpen(false);
    form.reset();
  };

  const filteredData = kantar.filter(k => 
    k.plaka.toLowerCase().includes(searchTerm.toLowerCase()) || 
    k.fisNo.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const totalNet = kantar.reduce((acc, curr) => acc + curr.net, 0);

  return (
    <div className="h-full flex flex-col gap-4">
      {/* Module Header Band */}
      <div className="flex items-center justify-between border-b pb-4 relative" style={{ borderColor: `${moduleColor}33` }}>
        <div className="absolute bottom-[-1px] left-0 w-32 h-[1px]" style={{ background: moduleColor, boxShadow: `0 0 10px ${moduleColor}` }} />
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded bg-[#facc15]/10 border border-[#facc15]/30 flex items-center justify-center">
            <Scale size={20} color={moduleColor} style={{ filter: `drop-shadow(0 0 5px ${moduleColor})` }} />
          </div>
          <div>
            <h1 className="text-xl font-bold tracking-widest text-slate-100">OTOMATİK KANTAR</h1>
            <p className="text-[10px] font-mono text-[#facc15]/70 mt-1">AĞIRLIK VE GİRİŞ KONTROLÜ</p>
          </div>
        </div>
        
        <div className="flex gap-4">
          <div className="flex flex-col items-end">
            <span className="text-[9px] font-mono text-slate-500">GÜNLÜK ARAÇ</span>
            <span className="text-lg font-bold font-mono text-slate-200">
              {kantar.length}
            </span>
          </div>
          <div className="w-px bg-slate-800" />
          <div className="flex flex-col items-end">
            <span className="text-[9px] font-mono text-slate-500">TOPLAM NET TONAJ</span>
            <span className="text-lg font-bold font-mono" style={{ color: moduleColor, textShadow: `0 0 10px ${moduleColor}88` }}>
              {totalNet.toFixed(2)} t
            </span>
          </div>
        </div>
      </div>

      {/* Toolbar */}
      <div className="flex items-center justify-between bg-black/20 p-2 rounded border border-slate-800">
        <div className="flex items-center gap-2 w-full max-w-sm relative">
          <Search size={14} className="absolute left-3 text-slate-500" />
          <Input 
            placeholder="Plaka veya fiş no ara..." 
            className="pl-9 bg-[#0b1224] border-slate-700 text-sm font-mono h-8 rounded-sm focus-visible:ring-[#facc15]/50"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            data-testid="input-search-kantar"
          />
        </div>
        
        <Dialog open={open} onOpenChange={setOpen}>
          <DialogTrigger asChild>
            <Button size="sm" className="h-8 bg-[#facc15]/20 hover:bg-[#facc15]/30 text-[#facc15] border border-[#facc15]/50 rounded-sm font-mono text-[11px] tracking-wider" data-testid="button-yeni-tartim">
              <Plus size={14} className="mr-1" /> YENİ TARTIM
            </Button>
          </DialogTrigger>
          <DialogContent className="bg-[#050810] border-[#facc15]/30 text-slate-200 font-mono rounded-none border-t-2 border-t-[#facc15]">
            <DialogHeader>
              <DialogTitle className="text-[#facc15] tracking-widest uppercase text-sm flex items-center gap-2">
                <Scale size={16} /> KANTAR FİŞİ
              </DialogTitle>
            </DialogHeader>
            
            <Form {...form}>
              <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4 mt-4">
                <div className="grid grid-cols-2 gap-3">
                  <FormField control={form.control} name="plaka" render={({ field }) => (
                    <FormItem>
                      <FormLabel className="text-[10px] text-slate-400">PLAKA</FormLabel>
                      <FormControl><Input {...field} className="bg-black/50 border-slate-700 h-8 rounded-sm text-sm uppercase font-bold text-center" data-testid="input-plaka" /></FormControl>
                      <FormMessage className="text-[10px] text-red-400" />
                    </FormItem>
                  )} />
                  <FormField control={form.control} name="malzeme" render={({ field }) => (
                    <FormItem>
                      <FormLabel className="text-[10px] text-slate-400">MALZEME</FormLabel>
                      <FormControl><Input {...field} className="bg-black/50 border-slate-700 h-8 rounded-sm text-sm" data-testid="input-malzeme" /></FormControl>
                      <FormMessage className="text-[10px] text-red-400" />
                    </FormItem>
                  )} />
                </div>
                
                <div className="grid grid-cols-2 gap-3 p-4 bg-black/30 border border-slate-800 rounded">
                  <FormField control={form.control} name="brut" render={({ field }) => (
                    <FormItem>
                      <FormLabel className="text-[10px] text-slate-400">BRÜT AĞIRLIK (TON)</FormLabel>
                      <FormControl><Input type="number" step="0.1" {...field} className="bg-black/80 border-slate-700 h-10 rounded-sm text-lg tabular-nums text-[#facc15] text-right font-black" data-testid="input-brut" /></FormControl>
                      <FormMessage className="text-[10px] text-red-400" />
                    </FormItem>
                  )} />
                  <FormField control={form.control} name="dara" render={({ field }) => (
                    <FormItem>
                      <FormLabel className="text-[10px] text-slate-400">DARA (TON)</FormLabel>
                      <FormControl><Input type="number" step="0.1" {...field} className="bg-black/80 border-slate-700 h-10 rounded-sm text-lg tabular-nums text-slate-400 text-right font-bold" data-testid="input-dara" /></FormControl>
                      <FormMessage className="text-[10px] text-red-400" />
                    </FormItem>
                  )} />
                </div>
                
                {/* Fake dynamic net calculation */}
                <div className="flex justify-between items-end px-2">
                  <span className="text-[10px] text-slate-500">HESAPLANAN NET:</span>
                  <span className="text-sm font-mono text-[#facc15]">
                    {Math.max(0, (Number(form.watch('brut')) || 0) - (Number(form.watch('dara')) || 0)).toFixed(2)} t
                  </span>
                </div>

                <div className="pt-2">
                  <Button type="submit" className="w-full bg-[#facc15] hover:bg-[#facc15]/80 text-black font-bold tracking-widest text-xs h-9 rounded-sm" data-testid="button-submit-kantar">
                    TARTIMI KAYDET
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
                <th className="px-4 py-3 font-semibold tracking-widest border-b border-slate-800">FİŞ NO / SAAT</th>
                <th className="px-4 py-3 font-semibold tracking-widest border-b border-slate-800">PLAKA</th>
                <th className="px-4 py-3 font-semibold tracking-widest border-b border-slate-800">MALZEME</th>
                <th className="px-4 py-3 font-semibold tracking-widest border-b border-slate-800 text-right">BRÜT</th>
                <th className="px-4 py-3 font-semibold tracking-widest border-b border-slate-800 text-right">DARA</th>
                <th className="px-4 py-3 font-semibold tracking-widest border-b border-slate-800 text-right text-[#facc15]">NET TON</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/50">
              {filteredData.length === 0 ? (
                <tr>
                  <td colSpan={6} className="px-4 py-8 text-center text-slate-500 font-mono text-xs">
                    KAYIT BULUNAMADI.
                  </td>
                </tr>
              ) : (
                filteredData.map((row) => (
                  <tr key={row.id} className="hover:bg-slate-800/30 transition-colors group">
                    <td className="px-4 py-3">
                      <div className="font-mono text-xs text-slate-300">{row.fisNo}</div>
                      <div className="flex items-center gap-1 text-[10px] text-slate-500 mt-1">
                        <Clock size={10} /> {row.tarih}
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-2">
                        <Truck size={14} className="text-slate-500" />
                        <span className="font-bold text-slate-200 tracking-wider font-mono text-xs bg-slate-900 border border-slate-700 px-1.5 py-0.5 rounded">
                          {row.plaka}
                        </span>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-slate-300 text-xs">{row.malzeme}</td>
                    <td className="px-4 py-3 text-right font-mono text-slate-400 text-xs tabular-nums">{row.brut.toFixed(2)}</td>
                    <td className="px-4 py-3 text-right font-mono text-slate-500 text-xs tabular-nums">{row.dara.toFixed(2)}</td>
                    <td className="px-4 py-3 text-right font-mono font-black tabular-nums text-sm" style={{ color: moduleColor, textShadow: `0 0 5px ${moduleColor}55` }}>
                      {row.net.toFixed(2)}
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
