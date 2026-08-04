import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/catalogs/turkey_cities.dart';
import '../../domain/entities/daily_report.dart';

/// Open-Meteo hava servisi — API key gerektirmez.
///
/// Konum: listeden seçilen [TurkeyCity] koordinatları (GPS / geocode yok).
class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<DailyReportWeather> fetchForCity(TurkeyCity city) async {
    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': city.lat.toString(),
        'longitude': city.lon.toString(),
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
        locationLabel: city.name,
        fetchedAt: DateTime.now(),
        synced: true,
        offlineNote: '',
      );
    } catch (_) {
      return DailyReportWeather(
        synced: false,
        offlineNote: 'Hava durumu senkron edilemedi.',
        fetchedAt: DateTime.now(),
        locationLabel: city.name,
      );
    }
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
