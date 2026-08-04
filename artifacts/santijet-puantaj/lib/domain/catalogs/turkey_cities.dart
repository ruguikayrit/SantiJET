/// Türkiye illeri — günlük rapor hava durumu seçimi (plaka kodu + merkez koordinat).
class TurkeyCity {
  const TurkeyCity({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
  });

  /// Plaka kodu (`'01'` … `'81'`).
  final String id;
  final String name;
  final double lat;
  final double lon;
}

/// Alfabetik değil; plaka sırası. UI alfabetik sıralar.
const turkeyCities = <TurkeyCity>[
  TurkeyCity(id: '01', name: 'Adana', lat: 37.0000, lon: 35.3213),
  TurkeyCity(id: '02', name: 'Adıyaman', lat: 37.7648, lon: 38.2786),
  TurkeyCity(id: '03', name: 'Afyonkarahisar', lat: 38.7507, lon: 30.5567),
  TurkeyCity(id: '04', name: 'Ağrı', lat: 39.7191, lon: 43.0503),
  TurkeyCity(id: '05', name: 'Amasya', lat: 40.6499, lon: 35.8353),
  TurkeyCity(id: '06', name: 'Ankara', lat: 39.9334, lon: 32.8597),
  TurkeyCity(id: '07', name: 'Antalya', lat: 36.8969, lon: 30.7133),
  TurkeyCity(id: '08', name: 'Artvin', lat: 41.1828, lon: 41.8183),
  TurkeyCity(id: '09', name: 'Aydın', lat: 37.8560, lon: 27.8416),
  TurkeyCity(id: '10', name: 'Balıkesir', lat: 39.6484, lon: 27.8826),
  TurkeyCity(id: '11', name: 'Bilecik', lat: 40.1506, lon: 29.9833),
  TurkeyCity(id: '12', name: 'Bingöl', lat: 38.8855, lon: 40.4966),
  TurkeyCity(id: '13', name: 'Bitlis', lat: 38.4006, lon: 42.1095),
  TurkeyCity(id: '14', name: 'Bolu', lat: 40.7350, lon: 31.6061),
  TurkeyCity(id: '15', name: 'Burdur', lat: 37.7203, lon: 30.2908),
  TurkeyCity(id: '16', name: 'Bursa', lat: 40.1885, lon: 29.0610),
  TurkeyCity(id: '17', name: 'Çanakkale', lat: 40.1553, lon: 26.4142),
  TurkeyCity(id: '18', name: 'Çankırı', lat: 40.6013, lon: 33.6134),
  TurkeyCity(id: '19', name: 'Çorum', lat: 40.5506, lon: 34.9556),
  TurkeyCity(id: '20', name: 'Denizli', lat: 37.7765, lon: 29.0864),
  TurkeyCity(id: '21', name: 'Diyarbakır', lat: 37.9144, lon: 40.2306),
  TurkeyCity(id: '22', name: 'Edirne', lat: 41.6771, lon: 26.5557),
  TurkeyCity(id: '23', name: 'Elazığ', lat: 38.6810, lon: 39.2264),
  TurkeyCity(id: '24', name: 'Erzincan', lat: 39.7500, lon: 39.5000),
  TurkeyCity(id: '25', name: 'Erzurum', lat: 39.9043, lon: 41.2679),
  TurkeyCity(id: '26', name: 'Eskişehir', lat: 39.7767, lon: 30.5206),
  TurkeyCity(id: '27', name: 'Gaziantep', lat: 37.0662, lon: 37.3833),
  TurkeyCity(id: '28', name: 'Giresun', lat: 40.9128, lon: 38.3895),
  TurkeyCity(id: '29', name: 'Gümüşhane', lat: 40.4602, lon: 39.4814),
  TurkeyCity(id: '30', name: 'Hakkari', lat: 37.5744, lon: 43.7408),
  TurkeyCity(id: '31', name: 'Hatay', lat: 36.4018, lon: 36.3498),
  TurkeyCity(id: '32', name: 'Isparta', lat: 37.7648, lon: 30.5566),
  TurkeyCity(id: '33', name: 'Mersin', lat: 36.8121, lon: 34.6415),
  TurkeyCity(id: '34', name: 'İstanbul', lat: 41.0082, lon: 28.9784),
  TurkeyCity(id: '35', name: 'İzmir', lat: 38.4237, lon: 27.1428),
  TurkeyCity(id: '36', name: 'Kars', lat: 40.6013, lon: 43.0975),
  TurkeyCity(id: '37', name: 'Kastamonu', lat: 41.3887, lon: 33.7827),
  TurkeyCity(id: '38', name: 'Kayseri', lat: 38.7205, lon: 35.4826),
  TurkeyCity(id: '39', name: 'Kırklareli', lat: 41.7350, lon: 27.2252),
  TurkeyCity(id: '40', name: 'Kırşehir', lat: 39.1425, lon: 34.1709),
  TurkeyCity(id: '41', name: 'Kocaeli', lat: 40.8533, lon: 29.8815),
  TurkeyCity(id: '42', name: 'Konya', lat: 37.8746, lon: 32.4932),
  TurkeyCity(id: '43', name: 'Kütahya', lat: 39.4192, lon: 29.9857),
  TurkeyCity(id: '44', name: 'Malatya', lat: 38.3552, lon: 38.3095),
  TurkeyCity(id: '45', name: 'Manisa', lat: 38.6191, lon: 27.4289),
  TurkeyCity(id: '46', name: 'Kahramanmaraş', lat: 37.5858, lon: 36.9371),
  TurkeyCity(id: '47', name: 'Mardin', lat: 37.3212, lon: 40.7245),
  TurkeyCity(id: '48', name: 'Muğla', lat: 37.2153, lon: 28.3636),
  TurkeyCity(id: '49', name: 'Muş', lat: 38.7433, lon: 41.5065),
  TurkeyCity(id: '50', name: 'Nevşehir', lat: 38.6939, lon: 34.6857),
  TurkeyCity(id: '51', name: 'Niğde', lat: 37.9667, lon: 34.6833),
  TurkeyCity(id: '52', name: 'Ordu', lat: 40.9839, lon: 37.8764),
  TurkeyCity(id: '53', name: 'Rize', lat: 41.0201, lon: 40.5234),
  TurkeyCity(id: '54', name: 'Sakarya', lat: 40.7889, lon: 30.4053),
  TurkeyCity(id: '55', name: 'Samsun', lat: 41.2867, lon: 36.3300),
  TurkeyCity(id: '56', name: 'Siirt', lat: 37.9333, lon: 41.9500),
  TurkeyCity(id: '57', name: 'Sinop', lat: 42.0231, lon: 35.1531),
  TurkeyCity(id: '58', name: 'Sivas', lat: 39.7477, lon: 37.0179),
  TurkeyCity(id: '59', name: 'Tekirdağ', lat: 40.9781, lon: 27.5110),
  TurkeyCity(id: '60', name: 'Tokat', lat: 40.3167, lon: 36.5500),
  TurkeyCity(id: '61', name: 'Trabzon', lat: 41.0027, lon: 39.7168),
  TurkeyCity(id: '62', name: 'Tunceli', lat: 39.1079, lon: 39.5401),
  TurkeyCity(id: '63', name: 'Şanlıurfa', lat: 37.1674, lon: 38.7955),
  TurkeyCity(id: '64', name: 'Uşak', lat: 38.6823, lon: 29.4082),
  TurkeyCity(id: '65', name: 'Van', lat: 38.4891, lon: 43.4089),
  TurkeyCity(id: '66', name: 'Yozgat', lat: 39.8181, lon: 34.8147),
  TurkeyCity(id: '67', name: 'Zonguldak', lat: 41.4564, lon: 31.7987),
  TurkeyCity(id: '68', name: 'Aksaray', lat: 38.3687, lon: 34.0370),
  TurkeyCity(id: '69', name: 'Bayburt', lat: 40.2552, lon: 40.2249),
  TurkeyCity(id: '70', name: 'Karaman', lat: 37.1759, lon: 33.2287),
  TurkeyCity(id: '71', name: 'Kırıkkale', lat: 39.8468, lon: 33.5153),
  TurkeyCity(id: '72', name: 'Batman', lat: 37.8812, lon: 41.1351),
  TurkeyCity(id: '73', name: 'Şırnak', lat: 37.5164, lon: 42.4611),
  TurkeyCity(id: '74', name: 'Bartın', lat: 41.6358, lon: 32.3375),
  TurkeyCity(id: '75', name: 'Ardahan', lat: 41.1105, lon: 42.7022),
  TurkeyCity(id: '76', name: 'Iğdır', lat: 39.9167, lon: 44.0333),
  TurkeyCity(id: '77', name: 'Yalova', lat: 40.6500, lon: 29.2667),
  TurkeyCity(id: '78', name: 'Karabük', lat: 41.2061, lon: 32.6204),
  TurkeyCity(id: '79', name: 'Kilis', lat: 36.7184, lon: 37.1212),
  TurkeyCity(id: '80', name: 'Osmaniye', lat: 37.0742, lon: 36.2478),
  TurkeyCity(id: '81', name: 'Düzce', lat: 40.8438, lon: 31.1565),
];

TurkeyCity? turkeyCityById(String? id) {
  if (id == null || id.isEmpty) return null;
  for (final c in turkeyCities) {
    if (c.id == id) return c;
  }
  return null;
}

List<TurkeyCity> turkeyCitiesSorted() {
  final list = List<TurkeyCity>.from(turkeyCities);
  list.sort((a, b) => a.name.compareTo(b.name));
  return list;
}
