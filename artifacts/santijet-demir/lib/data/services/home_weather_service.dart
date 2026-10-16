import 'dart:convert';

import 'package:http/http.dart' as http;

class HomeWeatherSnapshot {
  const HomeWeatherSnapshot({
    required this.cityLabel,
    required this.temperatureC,
    required this.summary,
    required this.icon,
  });

  final String cityLabel;
  final int temperatureC;
  final String summary;
  final IconKind icon;
}

enum IconKind { clear, partlyCloudy, cloudy, fog, rain, snow, thunder }

abstract final class HomeWeatherService {
  static Future<HomeWeatherSnapshot?> fetchForLocation(String locationRaw) async {
    final city = _cityQuery(locationRaw);
    if (city.isEmpty) return null;

    final geoUri = Uri.https(
      'geocoding-api.open-meteo.com',
      '/v1/search',
      {'name': city, 'count': '1', 'language': 'tr', 'format': 'json'},
    );
    final geoRes = await http.get(geoUri).timeout(const Duration(seconds: 8));
    if (geoRes.statusCode != 200) return null;

    final geoJson = jsonDecode(geoRes.body) as Map<String, dynamic>;
    final results = geoJson['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) return null;

    final place = results.first as Map<String, dynamic>;
    final lat = (place['latitude'] as num).toDouble();
    final lon = (place['longitude'] as num).toDouble();
    final label = place['name'] as String? ?? city;

    final weatherUri = Uri.https(
      'api.open-meteo.com',
      '/v1/forecast',
      {
        'latitude': lat.toString(),
        'longitude': lon.toString(),
        'current': 'temperature_2m,weather_code',
        'timezone': 'auto',
      },
    );
    final weatherRes = await http.get(weatherUri).timeout(const Duration(seconds: 8));
    if (weatherRes.statusCode != 200) return null;

    final weatherJson = jsonDecode(weatherRes.body) as Map<String, dynamic>;
    final current = weatherJson['current'] as Map<String, dynamic>?;
    if (current == null) return null;

    final temp = (current['temperature_2m'] as num?)?.round() ?? 0;
    final code = current['weather_code'] as int? ?? 0;
    final (summary, icon) = _decodeWeatherCode(code);

    return HomeWeatherSnapshot(
      cityLabel: label,
      temperatureC: temp,
      summary: summary,
      icon: icon,
    );
  }

  static String _cityQuery(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'İstanbul';
    final parts = trimmed.split('·').map((p) => p.trim()).where((p) => p.isNotEmpty);
    final first = parts.isEmpty ? trimmed : parts.first;
    // "İstanbul · Kartal" → İstanbul; uzun adreslerde ilk anlamlı parça.
    return first.length > 48 ? first.substring(0, 48) : first;
  }

  static (String, IconKind) _decodeWeatherCode(int code) {
    if (code == 0) return ('Açık', IconKind.clear);
    if (code <= 3) return ('Parçalı bulutlu', IconKind.partlyCloudy);
    if (code <= 48) return ('Sisli', IconKind.fog);
    if (code <= 57) return ('Çisenti', IconKind.rain);
    if (code <= 67) return ('Yağmurlu', IconKind.rain);
    if (code <= 77) return ('Karlı', IconKind.snow);
    if (code <= 82) return ('Sağanak', IconKind.rain);
    if (code <= 86) return ('Kar sağanağı', IconKind.snow);
    if (code >= 95) return ('Gök gürültülü', IconKind.thunder);
    return ('Bulutlu', IconKind.cloudy);
  }
}
