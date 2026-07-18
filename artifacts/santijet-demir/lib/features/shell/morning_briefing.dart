import 'package:santijet_demir/core/format/app_format.dart';
import 'package:santijet_demir/domain/entities/field_count.dart';
import 'package:santijet_demir/domain/entities/order.dart';
import 'package:santijet_demir/domain/entities/prediction_models.dart';
import 'package:santijet_demir/domain/entities/work_schedule.dart';

/// Ana sayfa AI Sabah Brifingi — kural tabanlı, LLM yok.
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

class MorningBriefingBuilder {
  const MorningBriefingBuilder();

  MorningBriefing build({
    required DateTime now,
    required String displayName,
    WorkScheduleDay? todaySchedule,
    PredictionSnapshot? snapshot,
    List<OrderItem> inTransitOrders = const [],
    List<ReconciliationRow> reconciliation = const [],
    bool hasActiveProject = true,
  }) {
    final firstName = _firstName(displayName);
    final greeting = '${_daypartGreeting(now.hour)} $firstName';
    final daySeed = now.year * 1000 + now.month * 40 + now.day;

    if (!hasActiveProject) {
      return MorningBriefing(
        forDate: now,
        greetingLine: greeting,
        tone: PredictionRiskLevel.unknown,
        eyebrow: 'AI Sabah Brifingi',
        bullets: const [
          'Aktif proje seçildiğinde günlük brifing hazırlanır.',
          'İş programı, stok ve sipariş verileri burada özetlenir.',
        ],
      );
    }

    final bullets = <String>[];

    // 1) Bugünkü plan
    final planned = todaySchedule?.totalPlannedTonnage ?? 0;
    if (planned > 0) {
      bullets.add(
        'Bugün planlanan tüketim ${AppFormat.tonnage(planned)} ton',
      );
    } else {
      bullets.add(
        daySeed.isEven
            ? 'Bugün iş programında planlı tüketim yok'
            : 'Bugün için kayıtlı imalat planı bulunmuyor',
      );
    }

    // 2–3) Stok / sipariş (tahmin varsa)
    if (snapshot != null && snapshot.diameters.isNotEmpty) {
      final diameters = [...snapshot.diameters];
      final healthy = diameters
          .where(
            (d) =>
                d.risk == PredictionRiskLevel.green ||
                d.risk == PredictionRiskLevel.yellow,
          )
          .where((d) => d.daysRemaining != null && d.daysRemaining! > 0)
          .toList()
        ..sort(
          (a, b) => (b.daysRemaining ?? 0).compareTo(a.daysRemaining ?? 0),
        );
      final urgent = diameters
          .where(
            (d) =>
                d.risk == PredictionRiskLevel.red ||
                d.risk == PredictionRiskLevel.orange ||
                (d.recommendedPurchase > 0 &&
                    (d.daysRemaining ?? 99) <= 7),
          )
          .toList()
        ..sort(
          (a, b) => (a.daysRemaining ?? 99).compareTo(b.daysRemaining ?? 99),
        );

      if (healthy.isNotEmpty) {
        final pick = healthy[daySeed % healthy.length];
        final days = pick.daysRemaining!.round().clamp(1, 999);
        bullets.add(
          pick.risk == PredictionRiskLevel.green
              ? 'Ø${pick.diameter} stokunuz yeterli ($days gün)'
              : 'Ø${pick.diameter} stoğu izleniyor ($days gün)',
        );
      }

      if (urgent.isNotEmpty) {
        final u = urgent.first;
        final days = (u.daysRemaining ?? 0).round().clamp(0, 999);
        if (days <= 0) {
          bullets.add(
            'Ø${u.diameter} stoğu kritik — hemen sipariş değerlendirin',
          );
        } else {
          bullets.add(
            'Ø${u.diameter} için $days gün içinde sipariş öneriliyor',
          );
        }
      } else if ((snapshot.purchase?.totalRequired ?? 0) > 0) {
        bullets.add(
          'Önerilen sipariş ${AppFormat.tonnage(snapshot.purchase!.totalRequired)} ton',
        );
      }
    } else {
      bullets.add(
        daySeed % 3 == 0
            ? 'Stok tahmini için en az 2 saha sayımı gerekir'
            : 'Demir tahmin motoru için veri tamamlanıyor',
      );
    }

    // 4) Teslimat
    if (inTransitOrders.isEmpty) {
      bullets.add('Beklenen teslimat bulunmuyor');
    } else {
      final tons = inTransitOrders.fold<double>(0, (s, o) => s + o.tonnage);
      bullets.add(
        inTransitOrders.length == 1
            ? 'Yolda 1 teslimat · ${AppFormat.tonnage(tons)} ton'
            : 'Yolda ${inTransitOrders.length} teslimat · ${AppFormat.tonnage(tons)} ton',
      );
    }

    // 5) Fire
    bullets.add(_fireBullet(reconciliation, daySeed));

    // Günlük çeşitlilik: ilk 2 madde sabit, kalanlar güne göre kaydırılır
    var capped = bullets.take(5).toList();
    if (capped.length > 3) {
      final rotate = daySeed % (capped.length - 2);
      if (rotate > 0) {
        final head = capped.sublist(0, 2);
        final rest = capped.sublist(2);
        capped = [
          ...head,
          ...rest.sublist(rotate),
          ...rest.sublist(0, rotate),
        ];
      }
    }

    return MorningBriefing(
      forDate: now,
      greetingLine: greeting,
      tone: _tone(snapshot, reconciliation, inTransitOrders),
      eyebrow: 'AI Sabah Brifingi',
      bullets: capped,
    );
  }

  String _fireBullet(List<ReconciliationRow> rows, int daySeed) {
    if (rows.isEmpty) {
      return daySeed.isEven
          ? 'Fire riski değerlendirilemiyor — saha sayımı yok'
          : 'Fire özeti için güncel saha sayımı gerekir';
    }
    final critical = rows.where((r) => r.status == 'critical').toList();
    final warning = rows.where((r) => r.status == 'warning').toList();
    if (critical.isNotEmpty) {
      final r = critical.first;
      return 'Ø${r.diameter} fire riski yüksek (${AppFormat.tonnage(r.fire)} t)';
    }
    if (warning.isNotEmpty) {
      return 'Fire uyarısı var — çap bazlı sapmayı kontrol edin';
    }
    return 'Fire riski düşük';
  }

  PredictionRiskLevel _tone(
    PredictionSnapshot? snapshot,
    List<ReconciliationRow> rows,
    List<OrderItem> inTransit,
  ) {
    if (rows.any((r) => r.status == 'critical')) {
      return PredictionRiskLevel.red;
    }
    if (snapshot?.criticalDiameters.isNotEmpty == true) {
      return PredictionRiskLevel.red;
    }
    final risks = snapshot?.diameters.map((d) => d.risk).toList() ?? [];
    if (risks.contains(PredictionRiskLevel.orange) ||
        rows.any((r) => r.status == 'warning')) {
      return PredictionRiskLevel.orange;
    }
    if (risks.contains(PredictionRiskLevel.yellow)) {
      return PredictionRiskLevel.yellow;
    }
    if (snapshot == null && rows.isEmpty && inTransit.isEmpty) {
      return PredictionRiskLevel.unknown;
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
