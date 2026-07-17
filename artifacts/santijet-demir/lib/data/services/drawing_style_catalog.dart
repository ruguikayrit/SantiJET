/// Referans proje paftalarından çıkarılan CAD gösterim stilleri.
/// Yeni proje tipinde benzer parse hatalarını önlemek için katalog tutulur.
enum CadDrawingStyleId {
  /// S1[100/160] 182 ADET + 42Ø28 L=280 + etr*18Ø12
  classicBracketHeader,

  /// SB107 (35/30) · 6Φ16 · 42Φ10/15/7/15/10 Etr. L=130 · Çiroz L=
  ideCadColumnDetail,

  /// PS01 PERDE DETAYI · Etz. L= · 15 Φ 10 / 25
  ideCadWallElevation,

  /// S01-S02 KOLON DETAYI · kat zonları · 12Φ18 L=270 · 6Φ10/9
  ideCadColumnElevation,

  /// PSB / KB plan · 11Φ10/30 L=522
  ideCadSlabPlan,

  /// KB101 / KZ01 · ilave · Montaj/Düz · 13Φ10/9 108 · K101 / 28 Adet
  ideCadBeamDetail,

  /// Tanınmayan / karışık
  unknown,
}

class CadDrawingStyleProfile {
  const CadDrawingStyleProfile({
    required this.id,
    required this.name,
    required this.description,
    required this.sampleLabels,
  });

  final CadDrawingStyleId id;
  final String name;
  final String description;
  final List<String> sampleLabels;
}

class CadDrawingStyleMatch {
  const CadDrawingStyleMatch({
    required this.primary,
    required this.scores,
    required this.detectedLabels,
  });

  final CadDrawingStyleProfile primary;
  final Map<CadDrawingStyleId, int> scores;
  final List<String> detectedLabels;

  String get summary =>
      '${primary.name} (${detectedLabels.take(3).join(', ')})';
}

/// Bilinen pafta gösterim tipleri (referans görsellerden).
class DrawingStyleCatalog {
  const DrawingStyleCatalog();

  static const profiles = <CadDrawingStyleProfile>[
    CadDrawingStyleProfile(
      id: CadDrawingStyleId.classicBracketHeader,
      name: 'Klasik köşeli başlık',
      description: 'S/P/K/D + [en/boy] + ADET; etr* / Çiroz* önekli etiketler',
      sampleLabels: [
        'S1[100/160] 182 ADET',
        '42Ø28 L=280',
        'etr*18Ø12/10 L=510',
      ],
    ),
    CadDrawingStyleProfile(
      id: CadDrawingStyleId.ideCadColumnDetail,
      name: 'IdeCAD kolon detay (kesit)',
      description: 'SB/SZ (en/boy); Φ; çok zonlu Etr.; Çiroz L=',
      sampleLabels: [
        'SB107 (35/30)',
        '42Φ10/15/7/15/10 Etr. L=130',
        '108Φ10 Çiroz L=53',
      ],
    ),
    CadDrawingStyleProfile(
      id: CadDrawingStyleId.ideCadWallElevation,
      name: 'IdeCAD perde görünüş',
      description: 'PS PERDE DETAYI; Etz. L=; yatay donatı / aralık',
      sampleLabels: [
        'PS01 PERDE DETAYI',
        '15 Φ 10 / 25',
        'Etz. L=330',
      ],
    ),
    CadDrawingStyleProfile(
      id: CadDrawingStyleId.ideCadColumnElevation,
      name: 'IdeCAD kolon görünüş',
      description: 'Sxx-Syy KOLON DETAYI; kat zonları; boy L=; etriye /aralık',
      sampleLabels: [
        'S01-S02 KOLON DETAYI',
        '12Φ18 L=270',
        '15Φ10/9',
      ],
    ),
    CadDrawingStyleProfile(
      id: CadDrawingStyleId.ideCadSlabPlan,
      name: 'IdeCAD döşeme planı',
      description: 'PSB/KB/SB plan; NΦdd/ss L=',
      sampleLabels: [
        'PSB102 25/255',
        '11Φ10/30 L=522',
        'KB102 30/50',
      ],
    ),
    CadDrawingStyleProfile(
      id: CadDrawingStyleId.ideCadBeamDetail,
      name: 'IdeCAD kiriş detay',
      description: 'KB/KZ/K; ilave; Montaj/Düz; zon etriyesi; / N Adet',
      sampleLabels: [
        'KB101 (30/50)',
        '3Φ14 ilave',
        'K101 / 28 Adet',
        '2 Φ 12 L=441',
      ],
    ),
  ];

  CadDrawingStyleMatch detect(Iterable<String> texts) {
    final scores = <CadDrawingStyleId, int>{
      for (final p in profiles) p.id: 0,
    };
    final hits = <String>[];

    for (final raw in texts) {
      final t = raw.toUpperCase()
          .replaceAll('İ', 'I')
          .replaceAll('Ş', 'S')
          .replaceAll('Ğ', 'G')
          .replaceAll('Ü', 'U')
          .replaceAll('Ö', 'O')
          .replaceAll('Ç', 'C')
          .replaceAll('Φ', 'Ø')
          .replaceAll('φ', 'Ø');

      void hit(CadDrawingStyleId id, String label, [int w = 1]) {
        scores[id] = (scores[id] ?? 0) + w;
        if (!hits.contains(label)) hits.add(label);
      }

      if (RegExp(r'^[SPKD]\d+\s*[\[\()]').hasMatch(t)) {
        hit(CadDrawingStyleId.classicBracketHeader, 'köşeli başlık', 3);
      }
      if (RegExp(r'ETR\*').hasMatch(t)) {
        hit(CadDrawingStyleId.classicBracketHeader, 'etr*', 2);
      }

      if (RegExp(r'\b(?:SB|SZ)\d+').hasMatch(t) &&
          RegExp(r'\(\d+\s*/\s*\d+\)').hasMatch(t)) {
        hit(CadDrawingStyleId.ideCadColumnDetail, 'SB/SZ (en/boy)', 3);
      }
      if (RegExp(r'(?:ETR|ETZ)\.?\s*L\s*=').hasMatch(t)) {
        hit(CadDrawingStyleId.ideCadColumnDetail, 'Etr. L=', 2);
        hit(CadDrawingStyleId.ideCadWallElevation, 'Etz. L=', 1);
      }
      if (RegExp(r'CIROZ\s*L\s*=').hasMatch(t)) {
        hit(CadDrawingStyleId.ideCadColumnDetail, 'Çiroz L=', 3);
      }

      if (RegExp(r'PERDE\s*DETAY').hasMatch(t) ||
          RegExp(r'\bPS\d+\b').hasMatch(t) && t.contains('PERDE')) {
        hit(CadDrawingStyleId.ideCadWallElevation, 'perde detayı', 4);
      }
      if (RegExp(r'ETZ\.?\s*L\s*=').hasMatch(t)) {
        hit(CadDrawingStyleId.ideCadWallElevation, 'Etz.', 3);
      }

      if (RegExp(r'KOLON\s*DETAY').hasMatch(t)) {
        hit(CadDrawingStyleId.ideCadColumnElevation, 'kolon detayı', 4);
      }
      if (RegExp(r'\b(?:BODRUM|ZEMIN\s*KAT|\d+\.\s*KAT)\b').hasMatch(t)) {
        hit(CadDrawingStyleId.ideCadColumnElevation, 'kat etiketi', 2);
      }

      if (RegExp(r'\bPSB\d+').hasMatch(t)) {
        hit(CadDrawingStyleId.ideCadSlabPlan, 'PSB panel', 3);
      }
      if (RegExp(r'\d+Ø\d{1,2}/\d+\s*L\s*=').hasMatch(t) &&
          RegExp(r'\b(?:PSB|KB|SB)\d+').hasMatch(t)) {
        hit(CadDrawingStyleId.ideCadSlabPlan, 'plan L=', 2);
      }

      if (RegExp(r'\b(?:KB|KZ)\d+').hasMatch(t) &&
          RegExp(r'\(\d+\s*/\s*\d+\)').hasMatch(t)) {
        hit(CadDrawingStyleId.ideCadBeamDetail, 'KB/KZ (en/boy)', 3);
      }
      if (t.contains('ILAVE') || t.contains('MONTAJ') || t.contains('DUZ')) {
        hit(CadDrawingStyleId.ideCadBeamDetail, 'ilave/montaj', 2);
      }
      if (RegExp(r'(?:KB|KZ|K)\d+\s*/\s*\d+\s*ADET').hasMatch(t)) {
        hit(CadDrawingStyleId.ideCadBeamDetail, '/ N Adet', 3);
      }
    }

    CadDrawingStyleProfile primary = profiles.last; // unknown fallback below
    var best = -1;
    for (final p in profiles) {
      final s = scores[p.id] ?? 0;
      if (s > best) {
        best = s;
        primary = p;
      }
    }

    if (best <= 0) {
      primary = const CadDrawingStyleProfile(
        id: CadDrawingStyleId.unknown,
        name: 'Bilinmeyen / karışık',
        description: 'Referans stillerle eşleşmedi; genel kurallar uygulanır',
        sampleLabels: const [],
      );
    }

    return CadDrawingStyleMatch(
      primary: primary,
      scores: scores,
      detectedLabels: hits,
    );
  }
}
