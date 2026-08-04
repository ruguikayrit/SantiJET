import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/daily_report.dart';

/// Open-Meteo hava servisi — API key gerektirmez.
///
/// Konum stratejisi:
/// 1) [cityHint] (proje firma/şehir) → geocoding
/// 2) Başarısızsa İstanbul varsayılan + not
class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _defaultLat = 41.0082;
  static const _defaultLon = 28.9784;
  static const _defaultLabel = 'İstanbul (varsayılan)';

  Future<DailyReportWeather> fetch({String? cityHint}) async {
    try {
      var lat = _defaultLat;
      var lon = _defaultLon;
      var label = _defaultLabel;
      var usedFallback = true;

      final hint = cityHint?.trim() ?? '';
      if (hint.isNotEmpty) {
        final geo = await _geocode(hint);
        if (geo != null) {
          lat = geo.$1;
          lon = geo.$2;
          label = geo.$3;
          usedFallback = false;
        } else {
          label = '$_defaultLabel · “$hint” bulunamadı';
        }
      }

      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': lat.toString(),
        'longitude': lon.toString(),
        'current': 'temperature_2m,weather_code,wind_speed_10m',
        'timezone': 'auto',
        'wind_speed_unit': 'kmh',
      });
      final res = await _client.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final current = body['current'] as Map<String, dynamic>?;
      if (current == null) throw Exception('current yok');

      final temp = (current['temperature_2m'] as num?)?.toDouble();
      final wind = (current['wind_speed_10m'] as num?)?.toDouble();
      final code = (current['weather_code'] as num?)?.toInt() ?? 0;

      return DailyReportWeather(
        temperatureC: temp,
        description: wmoDescription(code),
        windKmh: wind,
        locationLabel: label,
        fetchedAt: DateTime.now(),
        synced: true,
        offlineNote: usedFallback && hint.isNotEmpty
            ? 'Şehir bulunamadı; varsayılan konum kullanıldı.'
            : '',
      );
    } catch (_) {
      return DailyReportWeather(
        synced: false,
        offlineNote: 'Hava durumu senkron edilemedi.',
        fetchedAt: DateTime.now(),
        locationLabel: cityHint?.trim().isNotEmpty == true
            ? cityHint!.trim()
            : _defaultLabel,
      );
    }
  }

  Future<(double, double, String)?> _geocode(String name) async {
    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': name,
      'count': '1',
      'language': 'tr',
      'format': 'json',
    });
    final res = await _client.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final results = body['results'];
    if (results is! List || results.isEmpty) return null;
    final first = Map<String, dynamic>.from(results.first as Map);
    final lat = (first['latitude'] as num?)?.toDouble();
    final lon = (first['longitude'] as num?)?.toDouble();
    if (lat == null || lon == null) return null;
    final place = first['name'] as String? ?? name;
    final admin = first['admin1'] as String?;
    final country = first['country'] as String?;
    final parts = [place, if (admin != null && admin.isNotEmpty) admin, if (country != null) country];
    return (lat, lon, parts.join(', '));
  }

  /// WMO weather interpretation codes → Türkçe kısa açıklama.
  static String wmoDescription(int code) {
    return switch (code) {
      0 => 'Açık / güneşli',
      1 => 'Çoğunlukla açık',
      2 => 'Parçalı bulutlu',
      3 => 'Kapalı',
      45 || 48 => 'Sisli',
      51 || 53 || 55 => 'Çisenti',
      56 || 57 => 'Dondurucu çisenti',
      61 || 63 || 65 => 'Yağmurlu',
      66 || 67 => 'Dondurucu yağmur',
      71 || 73 || 75 => 'Karlı',
      77 => 'Kar taneleri',
      80 || 81 || 82 => 'Sağanak yağış',
      85 || 86 => 'Kar sağanağı',
      95 => 'Gök gürültülü fırtına',
      96 || 99 => 'Dolu / fırtına',
      _ => 'Değişken',
    };
  }
}

final weatherService = WeatherService();
