import 'kasa_hareket.dart';

/// Hareket listesi filtreleri.
class HareketFilters {
  const HareketFilters({
    this.query = '',
    this.santiye,
    this.tedarikci,
    this.odemeSekli,
    this.belgeTuru,
    this.onlyGelir = false,
    this.onlyGider = false,
    this.from,
    this.to,
  });

  final String query;
  final String? santiye;
  final String? tedarikci;
  final String? odemeSekli;
  final String? belgeTuru;
  final bool onlyGelir;
  final bool onlyGider;
  final DateTime? from;
  final DateTime? to;

  bool get isEmpty =>
      query.trim().isEmpty &&
      santiye == null &&
      tedarikci == null &&
      odemeSekli == null &&
      belgeTuru == null &&
      !onlyGelir &&
      !onlyGider &&
      from == null &&
      to == null;

  HareketFilters copyWith({
    String? query,
    String? santiye,
    bool clearSantiye = false,
    String? tedarikci,
    bool clearTedarikci = false,
    String? odemeSekli,
    bool clearOdemeSekli = false,
    String? belgeTuru,
    bool clearBelgeTuru = false,
    bool? onlyGelir,
    bool? onlyGider,
    DateTime? from,
    bool clearFrom = false,
    DateTime? to,
    bool clearTo = false,
  }) {
    return HareketFilters(
      query: query ?? this.query,
      santiye: clearSantiye ? null : (santiye ?? this.santiye),
      tedarikci: clearTedarikci ? null : (tedarikci ?? this.tedarikci),
      odemeSekli: clearOdemeSekli ? null : (odemeSekli ?? this.odemeSekli),
      belgeTuru: clearBelgeTuru ? null : (belgeTuru ?? this.belgeTuru),
      onlyGelir: onlyGelir ?? this.onlyGelir,
      onlyGider: onlyGider ?? this.onlyGider,
      from: clearFrom ? null : (from ?? this.from),
      to: clearTo ? null : (to ?? this.to),
    );
  }
}

String _foldTr(String s) => s
    .toLowerCase()
    .replaceAll('ı', 'i')
    .replaceAll('İ', 'i')
    .replaceAll('ş', 's')
    .replaceAll('ğ', 'g')
    .replaceAll('ü', 'u')
    .replaceAll('ö', 'o')
    .replaceAll('ç', 'c');

bool _eqField(String? filter, String value) {
  if (filter == null) return true;
  return value.trim() == filter.trim();
}

List<KasaHareket> filterHareketler(
  Iterable<KasaHareket> source,
  HareketFilters filters,
) {
  final q = _foldTr(filters.query.trim());
  return source.where((h) {
    if (!_eqField(filters.santiye, h.santiye)) return false;
    if (!_eqField(filters.tedarikci, h.tedarikci)) return false;
    if (!_eqField(filters.odemeSekli, h.odemeSekli)) return false;
    if (!_eqField(filters.belgeTuru, h.belgeTuru)) return false;
    if (filters.onlyGelir && !h.isGelir) return false;
    if (filters.onlyGider && !h.isGider) return false;
    if (filters.from != null) {
      final d = DateTime(h.tarih.year, h.tarih.month, h.tarih.day);
      final f = DateTime(
        filters.from!.year,
        filters.from!.month,
        filters.from!.day,
      );
      if (d.isBefore(f)) return false;
    }
    if (filters.to != null) {
      final d = DateTime(h.tarih.year, h.tarih.month, h.tarih.day);
      final t = DateTime(
        filters.to!.year,
        filters.to!.month,
        filters.to!.day,
      );
      if (d.isAfter(t)) return false;
    }
    if (q.isNotEmpty) {
      final haystack = _foldTr(
        '${h.tedarikci} ${h.aciklama} ${h.ekAciklama}',
      );
      if (!haystack.contains(q)) return false;
    }
    return true;
  }).toList();
}

/// Şantiye / ödeme / belge kırılımı.
class BreakdownRow {
  const BreakdownRow({required this.label, required this.amount});
  final String label;
  final double amount;
}

List<BreakdownRow> breakdownBy(
  Iterable<KasaHareket> hareketler,
  String Function(KasaHareket h) keyOf, {
  required bool gider,
}) {
  final map = <String, double>{};
  for (final h in hareketler) {
    final amount = gider ? (h.gider ?? 0) : (h.gelir ?? 0);
    if (amount <= 0) continue;
    final key = keyOf(h).trim().isEmpty ? '—' : keyOf(h).trim();
    map[key] = (map[key] ?? 0) + amount;
  }
  final rows = map.entries
      .map((e) => BreakdownRow(label: e.key, amount: e.value))
      .toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));
  return rows;
}
