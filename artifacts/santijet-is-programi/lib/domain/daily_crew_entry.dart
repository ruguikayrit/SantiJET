/// Bir imalata o gün kaç adam çalıştığını tutar. Gerçekleşen adam-gün
/// bu satırların toplamıdır.
class DailyCrewEntry {
  const DailyCrewEntry({
    required this.id,
    required this.itemId,
    required this.date,
    required this.workers,
  });

  final String id;
  final String itemId;
  final DateTime date;
  final int workers;

  DailyCrewEntry copyWith({int? workers}) => DailyCrewEntry(
    id: id,
    itemId: itemId,
    date: date,
    workers: workers ?? this.workers,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'itemId': itemId,
    'date': _date(date),
    'workers': workers,
  };

  factory DailyCrewEntry.fromJson(Map<String, dynamic> json) => DailyCrewEntry(
    id: json['id'] as String,
    itemId: json['itemId'] as String,
    date: DateTime.parse(json['date'] as String),
    workers: json['workers'] as int,
  );

  static String _date(DateTime value) =>
      value.toIso8601String().substring(0, 10);
}

class DailyCrewValidator {
  static String? workers(int value) =>
      value < 0 || value > 200 ? 'Günlük adam sayısı 0–200 arasında olmalıdır.' : null;
}
