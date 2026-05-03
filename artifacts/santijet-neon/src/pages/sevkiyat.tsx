import React, { useState } from 'react';
import { useStore } from '@/store/useStore';
import { Truck, Plus, Search, MapPin, Calendar } from 'lucide-react';
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

const moduleColor = '#34d399';

const formSchema = z.object({
  plaka: z.string().min(2, 'Plaka zorunludur.'),
  sofor: z.string().min(2, 'Şoför adı zorunludur.'),
  hedef: z.string().min(2, 'Hedef zorunludur.'),
  icerik: z.string().min(2, 'İçerik zorunludur.'),
});

export default function Sevkiyat() {
  const { sevkiyat, addSevkiyat, updateSevkiyatStatus, addActivity } = useStore();
  const [searchTerm, setSearchTerm] = useState('');
  const [open, setOpen] = useState(false);
  const { toast } = useToast();

  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: { plaka: '', sofor: '', hedef: '', icerik: '' },
  });

  const onSubmit = (values: z.infer<typeof formSchema>) => {
    addSevkiyat({ ...values, tarih: new Date().toISOString().split('T')[0], durum: 'Hazırlanıyor' });
    addActivity(`Yeni sevkiyat kaydı: ${values.plaka} - ${values.hedef}`, 'info');
    toast({
      title: "Kayıt Başarılı",
      description: `${values.plaka} plakalı aracın sevkiyatı oluşturuldu.`,
      className: "bg-[#0b1224] border border-[#34d399] text-[#34d399] font-mono",
    });
    setOpen(false);
    form.reset();
  };

  const updateStatus = (id: string, status: string, plaka: string) => {
    updateSevkiyatStatus(id, status);
    addActivity(`${plaka} durumu güncellendi: ${status}`, status === 'Teslim Edildi' ? 'success' : 'info');
  };

  const filteredData = sevkiyat.filter(s => 
    s.plaka.toLowerCase().includes(searchTerm.toLowerCase()) || 
    s.hedef.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const getStatusColor = (durum: string) => {
    switch (durum) {
      case 'Hazırlanıyor': return 'text-amber-400 border-amber-500/30 bg-amber-500/10 shadow-[0_0_10px_rgba(245,158,11,0.2)]';
      case 'Yolda': return 'text-cyan-400 border-cyan-500/30 bg-cyan-500/10 shadow-[0_0_10px_rgba(34,211,238,0.2)]';
      case 'Teslim Edildi': return 'text-emerald-400 border-emerald-500/30 bg-emerald-500/10 shadow-[0_0_10px_rgba(16,185,129,0.2)]';
      case 'İptal': return 'text-red-400 border-red-500/30 bg-red-500/10 shadow-[0_0_10px_rgba(239,68,68,0.2)]';
      default: return 'text-slate-400 border-slate-500/30 bg-slate-500/10';
    }
  };

  return (
    <div className="h-full flex flex-col gap-4">
      {/* Module Header Band */}
      <div className="flex items-center justify-between border-b pb-4 relative" style={{ borderColor: `${moduleColor}33` }}>
        <div className="absolute bottom-[-1px] left-0 w-32 h-[1px]" style={{ background: moduleColor, boxShadow: `0 0 10px ${moduleColor}` }} />
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded bg-[#34d399]/10 border border-[#34d399]/30 flex items-center justify-center">
            <Truck size={20} color={moduleColor} style={{ filter: `drop-shadow(0 0 5px ${moduleColor})` }} />
          </div>
          <div>
            <h1 className="text-xl font-bold tracking-widest text-slate-100">SEVKİYAT AĞI</h1>
            <p className="text-[10px] font-mono text-[#34d399]/70 mt-1">CANLI ARAÇ TAKİBİ</p>
          </div>
        </div>
        
        <div className="flex gap-4">
          <div className="flex flex-col items-end">
            <span className="text-[9px] font-mono text-slate-500">YOLDAKİ ARAÇLAR</span>
            <span className="text-lg font-bold font-mono text-cyan-400" style={{ textShadow: `0 0 10px rgba(34,211,238,0.5)` }}>
              {sevkiyat.filter(s => s.durum === 'Yolda').length}
            </span>
          </div>
          <div className="w-px bg-slate-800" />
          <div className="flex flex-col items-end">
            <span className="text-[9px] font-mono text-slate-500">GÜNLÜK SEVKİYAT</span>
            <span className="text-lg font-bold font-mono" style={{ color: moduleColor, textShadow: `0 0 10px ${moduleColor}88` }}>
              {sevkiyat.length}
            </span>
          </div>
        </div>
      </div>

      {/* Toolbar */}
      <div className="flex items-center justify-between bg-black/20 p-2 rounded border border-slate-800">
        <div className="flex items-center gap-2 w-full max-w-sm relative">
          <Search size={14} className="absolute left-3 text-slate-500" />
          <Input 
            placeholder="Plaka veya hedef ara..." 
            className="pl-9 bg-[#0b1224] border-slate-700 text-sm font-mono h-8 rounded-sm focus-visible:ring-[#34d399]/50"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            data-testid="input-search-sevkiyat"
          />
        </div>
        
        <Dialog open={open} onOpenChange={setOpen}>
          <DialogTrigger asChild>
            <Button size="sm" className="h-8 bg-[#34d399]/20 hover:bg-[#34d399]/30 text-[#34d399] border border-[#34d399]/50 rounded-sm font-mono text-[11px] tracking-wider" data-testid="button-yeni-sevkiyat">
              <Plus size={14} className="mr-1" /> YENİ SEVKİYAT
            </Button>
          </DialogTrigger>
          <DialogContent className="bg-[#050810] border-[#34d399]/30 text-slate-200 font-mono rounded-none border-t-2 border-t-[#34d399]">
            <DialogHeader>
              <DialogTitle className="text-[#34d399] tracking-widest uppercase text-sm flex items-center gap-2">
                <Truck size={16} /> SEVKİYAT EMRİ OLUŞTUR
              </DialogTitle>
            </DialogHeader>
            
            <Form {...form}>
              <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4 mt-4">
                <div className="grid grid-cols-2 gap-3">
                  <FormField control={form.control} name="plaka" render={({ field }) => (
                    <FormItem>
                      <FormLabel className="text-[10px] text-slate-400">PLAKA</FormLabel>
                      <FormControl><Input {...field} className="bg-black/50 border-slate-700 h-8 rounded-sm text-sm uppercase font-bold" data-testid="input-plaka" /></FormControl>
                      <FormMessage className="text-[10px] text-red-400" />
                    </FormItem>
                  )} />
                  <FormField control={form.control} name="sofor" render={({ field }) => (
                    <FormItem>
                      <FormLabel className="text-[10px] text-slate-400">ŞOFÖR ADI</FormLabel>
                      <FormControl><Input {...field} className="bg-black/50 border-slate-700 h-8 rounded-sm text-sm" data-testid="input-sofor" /></FormControl>
                      <FormMessage className="text-[10px] text-red-400" />
                    </FormItem>
                  )} />
                </div>

                <FormField control={form.control} name="hedef" render={({ field }) => (
                  <FormItem>
                    <FormLabel className="text-[10px] text-slate-400">HEDEF LOKASYON</FormLabel>
                    <FormControl><Input {...field} className="bg-black/50 border-slate-700 h-8 rounded-sm text-sm" data-testid="input-hedef" /></FormControl>
                    <FormMessage className="text-[10px] text-red-400" />
                  </FormItem>
                )} />

                <FormField control={form.control} name="icerik" render={({ field }) => (
                  <FormItem>
                    <FormLabel className="text-[10px] text-slate-400">YÜK İÇERİĞİ</FormLabel>
                    <FormControl><Input {...field} className="bg-black/50 border-slate-700 h-8 rounded-sm text-sm" data-testid="input-icerik" /></FormControl>
                    <FormMessage className="text-[10px] text-red-400" />
                  </FormItem>
                )} />
                
                <div className="pt-2">
                  <Button type="submit" className="w-full bg-[#34d399] hover:bg-[#34d399]/80 text-black font-bold tracking-widest text-xs h-9 rounded-sm" data-testid="button-submit-sevkiyat">
                    EMRİ KAYDET
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
                <th className="px-4 py-3 font-semibold tracking-widest border-b border-slate-800">PLAKA / ŞOFÖR</th>
                <th className="px-4 py-3 font-semibold tracking-widest border-b border-slate-800">İÇERİK</th>
                <th className="px-4 py-3 font-semibold tracking-widest border-b border-slate-800">HEDEF</th>
                <th className="px-4 py-3 font-semibold tracking-widest border-b border-slate-800">TARİH</th>
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
                    <td className="px-4 py-3">
                      <div className="font-bold text-slate-200 tracking-wider bg-slate-900 border border-slate-700 rounded px-2 py-0.5 inline-block font-mono text-xs shadow-[inset_0_0_5px_rgba(0,0,0,0.5)]">
                        {row.plaka}
                      </div>
                      <div className="text-[10px] text-slate-400 mt-1 uppercase tracking-wider">{row.sofor}</div>
                    </td>
                    <td className="px-4 py-3 text-slate-300 font-medium text-xs">{row.icerik}</td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-1.5 text-slate-300 text-xs">
                        <MapPin size={12} className="text-[#34d399]" />
                        {row.hedef}
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-1.5 text-slate-400 font-mono text-[11px]">
                        <Calendar size={12} />
                        {row.tarih}
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      <Select 
                        defaultValue={row.durum} 
                        onValueChange={(val) => updateStatus(row.id, val, row.plaka)}
                      >
                        <SelectTrigger className={`h-7 w-[130px] font-mono text-[10px] font-bold uppercase tracking-wider rounded-sm ${getStatusColor(row.durum)}`} data-testid={`select-durum-${row.id}`}>
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent className="bg-[#0b1224] border-slate-700 text-slate-200 font-mono">
                          <SelectItem value="Hazırlanıyor">HAZIRLANIYOR</SelectItem>
                          <SelectItem value="Yolda">YOLDA</SelectItem>
                          <SelectItem value="Teslim Edildi">TESLİM EDİLDİ</SelectItem>
                          <SelectItem value="İptal">İPTAL</SelectItem>
                        </SelectContent>
                      </Select>
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
