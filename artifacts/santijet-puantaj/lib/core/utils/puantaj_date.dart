/// TR tarih yardımcıları — santiye-takip `puantaj.tsx` ile aynı format (`dd.MM.yyyy`).
abstract final class PuantajDate {
  static const trDaysShort = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
  static const trMonths = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  static String format(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}';
  }

  static DateTime parse(String s) {
    final parts = s.split('.');
    return DateTime(
      int.parse(parts[2]),
      int.parse(parts[1]),
      int.parse(parts[0]),
    );
  }

  static String today() => format(DateTime.now());

  static String shift(String dateStr, int days) {
    final d = parse(dateStr).add(Duration(days: days));
    return format(d);
  }

  /// Pazartesi başlangıçlı haftanın 7 günü.
  static List<String> weekDays(String dateStr) {
    final d = parse(dateStr);
    final dow = d.weekday; // 1=Mon … 7=Sun
    final monday = d.subtract(Duration(days: dow - 1));
    return List.generate(7, (i) => format(monday.add(Duration(days: i))));
  }

  static List<String> monthDays(String dateStr) {
    final d = parse(dateStr);
    final last = DateTime(d.year, d.month + 1, 0).day;
    return List.generate(last, (i) => format(DateTime(d.year, d.month, i + 1)));
  }

  static String weekLabel(List<String> days) {
    final a = days.first.split('.');
    final b = days.last.split('.');
    return '${a[0]}.${a[1]} – ${b[0]}.${b[1]}.${b[2]}';
  }

  static String monthLabel(String dateStr) {
    final d = parse(dateStr);
    return '${trMonths[d.month - 1]} ${d.year}';
  }

  static const trDaysLong = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  /// Örn. `27 Temmuz 2026 Pazartesi`
  static String longLabel(String dateStr) {
    final d = parse(dateStr);
    return '${d.day} ${trMonths[d.month - 1]} ${d.year} ${trDaysLong[d.weekday - 1]}';
  }
}
