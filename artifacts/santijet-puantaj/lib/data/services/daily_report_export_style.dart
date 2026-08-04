/// Günlük saha raporu PDF çıktı stili.
enum DailyReportExportStyle {
  /// Kısa özet — hava, puantaj sayıları, yapılan işler.
  ozet('Özet', 'Kısa tek sayfa özet'),

  /// Örnek şantiye raporu düzeni (standart form).
  standart('Standart', 'Günlük şantiye raporu formu'),

  /// Tüm alanlar + personel kırılımı + foto açıklamaları.
  gelismis('Gelişmiş', 'Detaylı saha raporu');

  const DailyReportExportStyle(this.label, this.description);

  final String label;
  final String description;
}
