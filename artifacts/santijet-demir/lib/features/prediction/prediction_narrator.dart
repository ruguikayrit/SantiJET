import 'package:santijet_demir/core/routing/app_routes.dart';
import 'package:santijet_demir/domain/entities/prediction_models.dart';

/// Hesaplanan sonuçlardan şablon cümleler — LLM yok, sayı uydurmaz.
abstract final class PredictionNarrator {
  static List<String> narrate(PredictionSnapshot snapshot) {
    if (!snapshot.canPredict) {
      return [
        'Tahmin üretilemedi. Eksik verileri tamamladıktan sonra motor '
            'yeniden çalıştırılacak.',
        ...snapshot.dataGaps.map((g) => g.message),
      ];
    }

    final lines = <String>[];

    final actual = snapshot.actualDailyConsumption;
    final planned = snapshot.plannedDailyConsumption;
    if (actual != null && actual > 0) {
      lines.add(
        'Mevcut gerçek ortalama tüketim ${actual.toStringAsFixed(1)} t/gün.',
      );
    }
    if (planned != null && planned > 0) {
      lines.add(
        'İş programına göre planlı tüketim ${planned.toStringAsFixed(1)} t/gün.',
      );
    }

    if (snapshot.deviationPercent != null &&
        snapshot.deviationPercent!.abs() >= 1) {
      final d = snapshot.deviationPercent!;
      lines.add(
        d > 0
            ? 'Tüketim plana göre %${d.toStringAsFixed(0)} daha yüksek.'
            : 'Tüketim plana göre %${d.abs().toStringAsFixed(0)} daha düşük.',
      );
    }

    for (final d in snapshot.criticalDiameters) {
      if (d.daysRemaining == null) continue;
      lines.add(
        'Ø${d.diameter} stokunun ${d.daysRemaining!.toStringAsFixed(1)} gün '
        'içinde kritik seviyeye düşmesi bekleniyor '
        '(stok ${d.currentStock.toStringAsFixed(1)} t, '
        'tüketim ${d.actualDailyConsumption > 0 ? d.actualDailyConsumption.toStringAsFixed(1) : d.plannedDailyConsumption.toStringAsFixed(1)} t/gün).',
      );
    }

    final purchase = snapshot.purchase;
    if (purchase != null && purchase.totalRequired > 0) {
      lines.add(
        'Önerilen toplam sipariş miktarı '
        '${purchase.totalRequired.toStringAsFixed(1)} t. '
        'Tedarikçi teslimat süresi ${purchase.supplierLeadDays} gün.',
      );
      if (purchase.requiredPurchaseDate != null) {
        final dt = purchase.requiredPurchaseDate!;
        lines.add(
          'Siparişin en geç ${dt.day}.${dt.month}.${dt.year} tarihinde '
          'verilmesi önerilir.',
        );
      }
    }

    if (snapshot.tonsPerWorkerDay != null && snapshot.tonsPerWorkerDay! > 0) {
      lines.add(
        'Puantaj verilerine göre işçi başına yaklaşık '
        '${snapshot.tonsPerWorkerDay!.toStringAsFixed(2)} t/işçi-gün verimlilik.',
      );
    }

    if (snapshot.predictedDepletionDate != null) {
      final dt = snapshot.predictedDepletionDate!;
      lines.add(
        'Toplam stok tükenme tahmini: ${dt.day}.${dt.month}.${dt.year}.',
      );
    }

    return lines;
  }

  static List<PredictionDataGap> buildGaps({
    required bool hasSurveyDiameters,
    required int fieldCountCount,
    required bool hasWorkSchedule,
    required bool hasWorkforce,
  }) {
    final gaps = <PredictionDataGap>[];

    if (!hasSurveyDiameters) {
      gaps.add(
        const PredictionDataGap(
          kind: PredictionDataGapKind.survey,
          message: 'Keşifte çap tonajları yok. Önce keşif ekleyin.',
          actionLabel: 'Keşfe git',
          route: AppRoutes.survey,
        ),
      );
    }

    if (fieldCountCount < 2) {
      gaps.add(
        PredictionDataGap(
          kind: PredictionDataGapKind.fieldCounts,
          message: fieldCountCount == 0
              ? 'Gerçek tüketim için en az iki saha sayımı gerekli.'
              : 'Tek sayım var. Gerçek tüketim için ikinci sayımı ekleyin.',
          actionLabel: 'Saha sayımı',
          route: AppRoutes.newCount,
        ),
      );
    }

    if (!hasWorkSchedule) {
      gaps.add(
        const PredictionDataGap(
          kind: PredictionDataGapKind.workSchedule,
          message: 'Planlı tüketim için iş programı günü girilmemiş.',
          actionLabel: 'İş programı',
          route: AppRoutes.workSchedule,
        ),
      );
    }

    if (!hasWorkforce) {
      gaps.add(
        const PredictionDataGap(
          kind: PredictionDataGapKind.workforce,
          message:
              'İşgücü verimliliği için günlük puantaj kaydı gerekli '
              '(zorunlu değil; verimlilik uyarısı üretilmez).',
          actionLabel: 'Puantaj',
          route: AppRoutes.workforce,
        ),
      );
    }

    return gaps;
  }

  /// Zorunlu gap'ler (puantaj opsiyonel).
  static bool canPredictFromGaps(List<PredictionDataGap> gaps) {
    return !gaps.any(
      (g) =>
          g.kind == PredictionDataGapKind.survey ||
          g.kind == PredictionDataGapKind.fieldCounts ||
          g.kind == PredictionDataGapKind.workSchedule,
    );
  }
}
