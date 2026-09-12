/// Yapı elemanı — her biri kendi hesaplayıcısına sahiptir.
enum TahvilElementType {
  foundation('Temel'),
  column('Kolon'),
  beam('Kiriş'),
  slab('Döşeme');

  const TahvilElementType(this.label);
  final String label;
}

/// Hesap ekranı üst seçimi. Saha mevcut 1 çeşit / 2 çeşit motorudur.
enum TahvilModule {
  saha('Saha'),
  foundation('Temel'),
  column('Kolon'),
  beam('Kiriş'),
  slab('Döşeme');

  const TahvilModule(this.label);
  final String label;

  TahvilElementType? get elementType => switch (this) {
        TahvilModule.saha => null,
        TahvilModule.foundation => TahvilElementType.foundation,
        TahvilModule.column => TahvilElementType.column,
        TahvilModule.beam => TahvilElementType.beam,
        TahvilModule.slab => TahvilElementType.slab,
      };
}

enum FoundationKind {
  isolated('Tekil temel'),
  strip('Sürekli temel'),
  raft('Radye temel');

  const FoundationKind(this.label);
  final String label;
}

enum RebarLayer {
  bottom('Alt donatı'),
  top('Üst donatı');

  const RebarLayer(this.label);
  final String label;
}

enum RebarDirection {
  x('X yönü'),
  y('Y yönü');

  const RebarDirection(this.label);
  final String label;
}

enum BeamRegion {
  spanBottom('Açıklık alt donatısı'),
  supportTop('Mesnet üst donatısı'),
  assembly('Montaj donatısı'),
  extra('Ek donatı');

  const BeamRegion(this.label);
  final String label;

  bool get requiresEngineerReview =>
      this == BeamRegion.supportTop || this == BeamRegion.extra;
}

enum StirrupZone {
  confinement('Sarılma / kritik bölge'),
  middle('Orta bölge');

  const StirrupZone(this.label);
  final String label;
}
