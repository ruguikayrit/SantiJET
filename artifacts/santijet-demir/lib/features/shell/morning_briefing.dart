import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/domain/entities/field_count.dart';
import 'package:santijet_demir/domain/entities/prediction_models.dart';

/// Ana sayfa / Demir Tahmin Motoru — kural tabanlı günlük brifing (LLM yok).
///
/// Kaynaklar: keşif, gerçekleşen imalat, kalan imalat, demir stok, saha sayımı.
class MorningBriefing {
  const MorningBriefing({
    required this.forDate,
    required this.greetingLine,
    required this.tone,
    required this.bullets,
    required this.eyebrow,
  });

  final DateTime forDate;
  final String greetingLine;
  final PredictionRiskLevel tone;
  final List<String> bullets;
  final String eyebrow;
}

/// Günlük operasyon özeti girdileri.
class DailyOpsBriefingInput {
  const DailyOpsBriefingInput({
    required this.kesifTonnage,
    required this.gerceklesenImalat,
    required this.kalanImalat,
    required this.overallProgressPercent,
    this.latestCount,
    this.reconciliation = const [],
    this.snapshot,
  });

  /// Keşif toplam plan tonajı.
  final double kesifTonnage;

  /// İlerleme % ile hesaplanan gerçekleşen imalat (ton).
  final double gerceklesenImalat;

  /// Kalan imalat = keşif − gerçekleşen (ton, ≥ 0).
  final double kalanImalat;

  final double overallProgressPercent;

  /// En güncel saha sayımı (stok = [FieldCountRecord.actual]).
  final FieldCountRecord? latestCount;

  final List<ReconciliationRow> reconciliation;
  final PredictionSnapshot? snapshot;

  double get demirStok {
    final count = latestCount;
    if (count == null) return 0;
    if (count.lines.isNotEmpty) {
      return count.lines.fold(0.0, (s, l) => s + l.actual);
    }
    return count.actual;
  }

  bool get hasKesif => kesifTonnage > 0.0001;
  bool get hasCount => latestCount != null;
}

class MorningBriefingBuilder {
  const MorningBriefingBuilder();

  MorningBriefing build({
    required DateTime now,
    required String displayName,
    DailyOpsBriefingInput? ops,
    bool hasActiveProject = true,
  }) {
    final firstName = _firstName(displayName);
    final greeting = '${_daypartGreeting(now.hour)} $firstName';

    if (!hasActiveProject) {
      return MorningBriefing(
        forDate: now,
        greetingLine: greeting,
        tone: PredictionRiskLevel.unknown,
        eyebrow: 'Günlük Brifing',
        bullets: const [
          'Aktif proje seçildiğinde günlük brifing hazırlanır.',
          'Keşif, imalat, stok ve saha sayımı burada özetlenir.',
        ],
      );
    }

    final input = ops ??
        const DailyOpsBriefingInput(
          kesifTonnage: 0,
          gerceklesenImalat: 0,
          kalanImalat: 0,
          overallProgressPercent: 0,
        );

    final bullets = <String>[
      _kesifBullet(input),
      _gerceklesenBullet(input),
      _kalanBullet(input),
      _stokBullet(input),
      _sayimBullet(input),
    ];

    // İsteğe bağlı 6. satır: kritik çap riski (tahmin motoru çıktısı varsa).
    final risk = _riskBullet(input);
    if (risk != null) bullets.add(risk);

    return MorningBriefing(
      forDate: now,
      greetingLine: greeting,
      tone: _tone(input),
      eyebrow: 'Günlük Brifing',
      bullets: bullets.take(6).toList(),
    );
  }

  String _kesifBullet(DailyOpsBriefingInput input) {
    if (!input.hasKesif) {
      return 'Keşif: henüz keşif tonajı girilmemiş';
    }
    return 'Keşif: ${AppFormat.tonnage(input.kesifTonnage)} ton';
  }

  String _gerceklesenBullet(DailyOpsBriefingInput input) {
    if (!input.hasKesif) {
      return 'Gerçekleşen imalat: keşif olmadan hesaplanamaz';
    }
    final pct = input.overallProgressPercent.clamp(0, 100);
    return 'Gerçekleşen imalat: ${AppFormat.tonnage(input.gerceklesenImalat)} ton '
        '(%${pct.toStringAsFixed(0)})';
  }

  String _kalanBullet(DailyOpsBriefingInput input) {
    if (!input.hasKesif) {
      return 'Kalan imalat: keşif tamamlanınca görünecek';
    }
    return 'Kalan imalat: ${AppFormat.tonnage(input.kalanImalat)} ton';
  }

  String _stokBullet(DailyOpsBriefingInput input) {
    if (!input.hasCount) {
      return 'Demir stok: saha sayımı yok — stok henüz ölçülmedi';
    }
    return 'Demir stok: ${AppFormat.tonnage(input.demirStok)} ton '
        '(son saha sayımı)';
  }

  String _sayimBullet(DailyOpsBriefingInput input) {
    final count = input.latestCount;
    if (count == null) {
      return 'Saha sayımı: kayıt yok — stok ve fire için sayım ekleyin';
    }
    final d = count.date;
    final dateLabel = '${d.day}.${d.month}.${d.year}';
    final stock = input.demirStok;
    final used = count.totalUsed;
    if (used > 0.0001) {
      return 'Saha sayımı: $dateLabel · stok ${AppFormat.tonnage(stock)} t · '
          'kullanılan ${AppFormat.tonnage(used)} t';
    }
    return 'Saha sayımı: $dateLabel · ${AppFormat.tonnage(stock)} ton sayıldı';
  }

  String? _riskBullet(DailyOpsBriefingInput input) {
    final critical = input.reconciliation
        .where((r) => r.status == 'critical')
        .toList();
    if (critical.isNotEmpty) {
      final r = critical.first;
      return 'Ø${r.diameter} fire riski yüksek '
          '(${AppFormat.tonnage(r.fire)} t sapma)';
    }

    final snapshot = input.snapshot;
    if (snapshot == null || !snapshot.canPredict) return null;
    final urgent = snapshot.criticalDiameters;
    if (urgent.isEmpty) return null;
    final u = urgent.first;
    final days = (u.daysRemaining ?? 0).round().clamp(0, 999);
    if (days <= 0) {
      return 'Ø${u.diameter} stok tahmini kritik — sipariş değerlendirin';
    }
    return 'Ø${u.diameter} stok tahmini: ~$days gün kaldı';
  }

  PredictionRiskLevel _tone(DailyOpsBriefingInput input) {
    if (input.reconciliation.any((r) => r.status == 'critical')) {
      return PredictionRiskLevel.red;
    }
    if (input.snapshot?.criticalDiameters.isNotEmpty == true) {
      return PredictionRiskLevel.red;
    }
    if (input.reconciliation.any((r) => r.status == 'warning') ||
        (input.snapshot?.diameters
                .any((d) => d.risk == PredictionRiskLevel.orange) ??
            false)) {
      return PredictionRiskLevel.orange;
    }
    if (!input.hasKesif && !input.hasCount) {
      return PredictionRiskLevel.unknown;
    }
    if (!input.hasCount) {
      return PredictionRiskLevel.yellow;
    }
    if (input.snapshot?.diameters
            .any((d) => d.risk == PredictionRiskLevel.yellow) ??
        false) {
      return PredictionRiskLevel.yellow;
    }
    return PredictionRiskLevel.green;
  }

  String _firstName(String displayName) {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return 'Usta';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  String _daypartGreeting(int hour) {
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }
}
