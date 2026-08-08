import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../domain/catalogs/mgm_stations.dart';
import '../../domain/catalogs/turkey_cities.dart';
import '../../domain/entities/daily_report.dart';

/// Hava durumu — birincil kaynak MGM (mgm.gov.tr).
///
/// GitHub Pages (web) MGM’ye doğrudan istek atamaz (Origin kilidi).
/// Web’de aynı origin / staging önbelleği (`weather/mgm.json`) kullanılır;
/// native’de MGM canlı çağrılır. Son çare: Open-Meteo.
class WeatherService {
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _mgmHeaders = {
    'Origin': 'https://www.mgm.gov.tr',
    'Referer': 'https://www.mgm.gov.tr/',
    'Accept': 'application/json',
  };

  Future<DailyReportWeather> fetchForCity(TurkeyCity city) async {
    if (!kIsWeb) {
      final live = await _fetchMgmLive(city);
      if (live != null) return live;
    }

    final cached = await _fetchMgmCache(city);
    if (cached != null) return cached;

    // Web’de canlı MGM denemesi (proxy / özel ortam için); CORS’ta başarısız olur.
    if (kIsWeb) {
      final live = await _fetchMgmLive(city);
      if (live != null) return live;
    }

    return _fetchOpenMeteoFallback(city);
  }

  Future<DailyReportWeather?> _fetchMgmLive(TurkeyCity city) async {
    final station = mgmStationsByPlate[city.id];
    if (station == null) return null;
    try {
      final sondurumUri = Uri.https(
        'servis.mgm.gov.tr',
        '/web/sondurumlar',
        {'merkezid': '${station.merkezId}'},
      );
      final gunlukUri = Uri.https(
        'servis.mgm.gov.tr',
        '/web/tahminler/gunluk',
        {'istno': '${station.gunlukIstNo}'},
      );

      final sondurumRes = await _client
          .get(sondurumUri, headers: _mgmHeaders)
          .timeout(const Duration(seconds: 12));
      if (sondurumRes.statusCode != 200) {
        throw Exception('sondurum HTTP ${sondurumRes.statusCode}');
      }
      final gunlukRes = await _client
          .get(gunlukUri, headers: _mgmHeaders)
          .timeout(const Duration(seconds: 12));

      final sondurumList = jsonDecode(sondurumRes.body);
      if (sondurumList is! List || sondurumList.isEmpty) {
        throw Exception('sondurum boş');
      }
      final s = Map<String, dynamic>.from(sondurumList.first as Map);

      Map<String, dynamic>? g;
      if (gunlukRes.statusCode == 200) {
        final gunlukList = jsonDecode(gunlukRes.body);
        if (gunlukList is List && gunlukList.isNotEmpty) {
          g = Map<String, dynamic>.from(gunlukList.first as Map);
        }
      }

      final code = (s['hadiseKodu'] as String?)?.trim().isNotEmpty == true
          ? s['hadiseKodu'] as String
          : (g?['hadiseGun0'] as String? ?? '');

      return DailyReportWeather(
        temperatureC: _mgmNum(s['sicaklik']),
        nightTemperatureC:
            _mgmNum(g?['enDusukGun0']) ?? _mgmNum(g?['enDusukGun1']),
        humidityPercent: _mgmNum(s['nem']),
        description: hadiseDescription(code),
        windKmh: _mgmNum(s['ruzgarHiz']),
        locationLabel: city.name,
        fetchedAt: DateTime.now(),
        synced: true,
        offlineNote: '',
        isManual: false,
      );
    } catch (_) {
      return null;
    }
  }

  Future<DailyReportWeather?> _fetchMgmCache(TurkeyCity city) async {
    final uris = <Uri>[
      Uri.base.resolve('weather/mgm.json'),
      Uri.parse(
        'https://raw.githubusercontent.com/ruguikayrit/SantiJET/staging/'
        'data/mgm-weather/mgm.json',
      ),
      Uri.parse(
        'https://raw.githubusercontent.com/ruguikayrit/SantiJET/staging/'
        'artifacts/santijet-puantaj/web/weather/mgm.json',
      ),
    ];

    for (final uri in uris) {
      try {
        final bust = uri.replace(
          queryParameters: {
            ...uri.queryParameters,
            't': '${DateTime.now().millisecondsSinceEpoch}',
          },
        );
        final res =
            await _client.get(bust).timeout(const Duration(seconds: 12));
        if (res.statusCode != 200) continue;
        final body = jsonDecode(res.body);
        if (body is! Map) continue;
        final cities = body['cities'];
        if (cities is! Map) continue;
        final raw = cities[city.id] ?? cities[city.id.replaceFirst(RegExp(r'^0'), '')];
        if (raw is! Map) continue;
        final row = Map<String, dynamic>.from(raw);
        return DailyReportWeather(
          temperatureC: _mgmNum(row['temperatureC']),
          nightTemperatureC: _mgmNum(row['nightTemperatureC']),
          humidityPercent: _mgmNum(row['humidityPercent']),
          description: (row['description'] as String?)?.trim().isNotEmpty == true
              ? row['description'] as String
              : hadiseDescription(row['hadiseKodu'] as String? ?? ''),
          windKmh: _mgmNum(row['windKmh']),
          locationLabel: city.name,
          fetchedAt: DateTime.tryParse(body['updatedAt'] as String? ?? '') ??
              DateTime.now(),
          synced: true,
          offlineNote: '',
          isManual: false,
        );
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  Future<DailyReportWeather> _fetchOpenMeteoFallback(TurkeyCity city) async {
    try {
      final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': city.lat.toString(),
        'longitude': city.lon.toString(),
        'current':
            'temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m',
        'daily': 'temperature_2m_min',
        'forecast_days': '1',
        'timezone': 'auto',
        'wind_speed_unit': 'kmh',
      });
      final res = await _client.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final current = body['current'] as Map<String, dynamic>?;
      if (current == null) throw Exception('current yok');

      return DailyReportWeather(
        temperatureC: (current['temperature_2m'] as num?)?.toDouble(),
        nightTemperatureC: _dailyMin(body),
        humidityPercent:
            (current['relative_humidity_2m'] as num?)?.toDouble(),
        description: wmoDescription((current['weather_code'] as num?)?.toInt() ?? 0),
        windKmh: (current['wind_speed_10m'] as num?)?.toDouble(),
        locationLabel: city.name,
        fetchedAt: DateTime.now(),
        synced: true,
        offlineNote: '',
        isManual: false,
      );
    } catch (_) {
      return DailyReportWeather(
        synced: false,
        offlineNote: 'Hava durumu senkron edilemedi.',
        fetchedAt: DateTime.now(),
        locationLabel: city.name,
        isManual: false,
      );
    }
  }

  static double? _mgmNum(dynamic v) {
    if (v == null) return null;
    if (v is num) {
      final d = v.toDouble();
      if (d <= -9000) return null;
      return d;
    }
    final d = double.tryParse(v.toString());
    if (d == null || d <= -9000) return null;
    return d;
  }

  static double? _dailyMin(Map<String, dynamic> body) {
    final daily = body['daily'];
    if (daily is! Map) return null;
    final mins = daily['temperature_2m_min'];
    if (mins is! List || mins.isEmpty) return null;
    final first = mins.first;
    if (first is num) return first.toDouble();
    return null;
  }

  /// MGM hadise kodu → Türkçe kısa açıklama.
  static String hadiseDescription(String code) {
    final key = code.trim().toUpperCase();
    if (key.isEmpty || key == '-9999') return 'Değişken';
    return switch (key) {
      'A' => 'Açık',
      'AB' => 'Az bulutlu',
      'PB' => 'Parçalı bulutlu',
      'CBS' => 'Çok bulutlu',
      'KAP' => 'Kapalı',
      'HY' => 'Hafif yağmurlu',
      'Y' || 'YAG' => 'Yağmurlu',
      'KY' => 'Kuvvetli yağmurlu',
      'SY' => 'Sağanak yağışlı',
      'HSY' => 'Hafif sağanak',
      'MSY' => 'Orta sağanak',
      'KSY' || 'KSYG' => 'Kuvvetli sağanak',
      'YSY' => 'Yer yer sağanak',
      'GSY' => 'Gökgürültülü sağanak',
      'GOK' => 'Gökgürültülü',
      'KGY' => 'Kuvvetli gök gürültülü',
      'KYŞ' => 'Kuvvetli yağış',
      'SCK' => 'Sıcak',
      'SGK' => 'Soğuk',
      'PUS' => 'Puslu',
      'SIS' => 'Sisli',
      'DMN' => 'Dumanlı',
      'KF' => 'Kum fırtınası',
      'TOZ' => 'Tozlu',
      'RZL' => 'Rüzgarlı',
      'KAR' => 'Karlı',
      'KRLH' => 'Karla karışık yağmur',
      'DKH' => 'Dolu',
      _ => code.trim().isEmpty ? 'Değişken' : code.trim(),
    };
  }

  /// WMO weather interpretation codes → Türkçe (Open-Meteo yedek).
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
