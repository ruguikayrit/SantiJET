/// Ortak birim. Kaynak uygulamalardaki serbest metin buna eşlenir.
enum MeasureUnit {
  m3('m³'),
  m2('m²'),
  m('m'),
  ton('ton'),
  kg('kg'),
  adet('adet'),
  adamGun('adam-gün'),
  saat('sa');

  const MeasureUnit(this.label);
  final String label;

  static MeasureUnit? parse(String raw) {
    final text = raw.trim().toLowerCase().replaceAll(' ', '');
    return switch (text) {
      'm³' || 'm3' => MeasureUnit.m3,
      'm²' || 'm2' => MeasureUnit.m2,
      'm' => MeasureUnit.m,
      'ton' || 't' => MeasureUnit.ton,
      'kg' => MeasureUnit.kg,
      'adet' => MeasureUnit.adet,
      'adam-gün' || 'adamgün' || 'adamgun' => MeasureUnit.adamGun,
      'sa' || 'saat' => MeasureUnit.saat,
      _ => null,
    };
  }
}
