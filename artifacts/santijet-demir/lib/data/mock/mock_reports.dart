import 'package:santijet_demir/domain/entities/report.dart';

/// DEMO PDF kapalı. Açma — sahte “Ankara Rezidans” verisi basar.
/// Canlı üreticisi olmayan raporlar katalogda yok.
const useDemoReports = false;

/// Canlı [ReportService] üreticisi olan raporlar.
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
    id: 'teslimat_liste',
    title: 'Teslimat / İrsaliye Listesi',
    subtitle: 'Gelen demir kayıtları',
    iconName: 'local_shipping',
    colorValue: 0xFFF59E0B,
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
    id: 'aylik_ozet',
    title: 'Aylık Proje Özeti',
    subtitle: 'Dönemsel aktivite',
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
