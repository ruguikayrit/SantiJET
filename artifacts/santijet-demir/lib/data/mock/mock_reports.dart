import 'package:santijet_demir/domain/entities/report.dart';

/// DEMO: true iken raporlar örnek veri ile üretilir / önizlenir.
/// Canlı veriye geçince false yapın ve [demoReportPayload] kullanımını kaldırın.
const useDemoReports = true;

/// Onaylanan 16 kullanıcı raporu.
const reportCategories = [
  ReportCategory(
    id: 'genel',
    title: 'Genel Proje Özeti',
    subtitle: 'Yönetici tek sayfa özeti',
    iconName: 'summarize',
    colorValue: 0xFFEF4444,
    format: 'PDF',
  ),
  ReportCategory(
    id: 'kesif_icmal',
    title: 'Keşif Metraj İcmali',
    subtitle: 'İmalat × çap × ton',
    iconName: 'architecture',
    colorValue: 0xFF3B82F6,
    format: 'PDF',
  ),
  ReportCategory(
    id: 'kesif_ilerleme',
    title: 'Keşif İlerleme Raporu',
    subtitle: 'İmalat / çap ilerleme %',
    iconName: 'trending_up',
    colorValue: 0xFF0EA5E9,
    format: 'PDF',
  ),
  ReportCategory(
    id: 'otomatik_metraj',
    title: 'Otomatik Metraj Raporu',
    subtitle: 'DWG/DXF icmali ve cetvel',
    iconName: 'auto_fix_high',
    colorValue: 0xFF8B5CF6,
    format: 'PDF',
  ),
  ReportCategory(
    id: 'siparis_ozet',
    title: 'Sipariş Özet Raporu',
    subtitle: 'No, firma, durum, tonaj',
    iconName: 'receipt_long',
    colorValue: 0xFF06B6D4,
    format: 'PDF',
  ),
  ReportCategory(
    id: 'siparis_bakiye',
    title: 'İmalat Sipariş Bakiyesi',
    subtitle: 'Keşif − sipariş kalan',
    iconName: 'account_balance',
    colorValue: 0xFF10B981,
    format: 'PDF',
  ),
  ReportCategory(
    id: 'teslimat_liste',
    title: 'Teslimat / İrsaliye Listesi',
    subtitle: 'Gelen demir kayıtları',
    iconName: 'local_shipping',
    colorValue: 0xFFF59E0B,
    format: 'PDF',
  ),
  ReportCategory(
    id: 'teslim_sapma',
    title: 'Çap Bazlı Teslim Sapması',
    subtitle: 'Sipariş vs teslim (Ø)',
    iconName: 'swap_vert',
    colorValue: 0xFFF97316,
    format: 'PDF',
  ),
  ReportCategory(
    id: 'saha_tutanak',
    title: 'Saha Sayım Tutanağı',
    subtitle: 'Tarih, personel, çap satırları',
    iconName: 'assignment',
    colorValue: 0xFFA855F7,
    format: 'PDF',
  ),
  ReportCategory(
    id: 'stok_mukayese',
    title: 'Stok Mukayese Raporu',
    subtitle: 'Keşif → sayım → fire zinciri',
    iconName: 'inventory_2',
    colorValue: 0xFF3B82F6,
    format: 'PDF',
  ),
  ReportCategory(
    id: 'sayim_sapma',
    title: 'Sayım Sapma Raporu',
    subtitle: 'Plan stok vs sayım',
    iconName: 'compare_arrows',
    colorValue: 0xFFEF4444,
    format: 'PDF',
  ),
  ReportCategory(
    id: 'hesap_analiz',
    title: 'Hesap ve Analiz Raporu',
    subtitle: 'Fire özeti ve kesim planı',
    iconName: 'analytics',
    colorValue: 0xFF0055FF,
    format: 'PDF',
  ),
  ReportCategory(
    id: 'fire_karsilastirma',
    title: 'Fire Karşılaştırma Raporu',
    subtitle: 'Ham vs plan + kazanç',
    iconName: 'local_fire_department',
    colorValue: 0xFFF97316,
    format: 'PDF',
  ),
  ReportCategory(
    id: 'tahvil_uygulama',
    title: 'Tahvil Uygulama Raporu',
    subtitle: 'Onaylı çap dönüşümleri',
    iconName: 'transform',
    colorValue: 0xFF0EA5E9,
    format: 'PDF',
  ),
  ReportCategory(
    id: 'kesim_plani',
    title: 'Kesim Planı Raporu',
    subtitle: 'Firesiz / fireli listeler',
    iconName: 'content_cut',
    colorValue: 0xFF64748B,
    format: 'PDF',
  ),
  ReportCategory(
    id: 'aylik_ozet',
    title: 'Aylık Proje Özeti',
    subtitle: 'Dönemsel aktivite ve tonaj',
    iconName: 'calendar_month',
    colorValue: 0xFF06B6D4,
    format: 'PDF',
  ),
];

List<ReportItem> getMockReports() {
  final now = DateTime.now();
  return [
    for (var i = 0; i < reportCategories.length; i++)
      ReportItem(
        id: reportCategories[i].id,
        title: reportCategories[i].title,
        category: reportCategories[i].title,
        format: 'PDF',
        size: useDemoReports ? 'Demo' : '—',
        date: now.subtract(Duration(hours: i)),
        generatedBy: useDemoReports ? 'Demo Veri' : 'Sistem',
      ),
  ];
}
