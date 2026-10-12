import 'package:santijet_demir/domain/entities/field_count.dart';

/// Çap hesabı — referanstaki kırılım.
///
/// Kabul edilen fire, keşif tonajının %5'idir.
class DiameterCalc {
  const DiameterCalc({
    required this.diameter,
    required this.survey,
    required this.acceptedRate,
    required this.acceptedTons,
    required this.totalNeed,
    required this.consumption,
    required this.actualFire,
    required this.actualFireRate,
    required this.counted,
    required this.pendingOrder,
    required this.availableStock,
    required this.remainingNeed,
  });

  static const acceptedFirePercent = 5.0;

  final int diameter;
  final double survey;
  final double acceptedRate;
  final double acceptedTons;
  final double totalNeed;
  final double consumption;
  final double actualFire;
  final double actualFireRate;
  final double counted;
  final double pendingOrder;
  final double availableStock;
  final double remainingNeed;

  bool get overAccepted => actualFireRate > acceptedRate;
  bool get critical => actualFireRate > 8;
  bool get warning => actualFireRate > acceptedRate && !critical;

  factory DiameterCalc.fromRow(ReconciliationRow row) {
    final survey = row.survey;
    const rate = acceptedFirePercent;
    final acceptedTons = survey * rate / 100;
    final totalNeed = survey + acceptedTons;
    final consumption = row.used;
    final hasConsumption = consumption > 0.05;
    final actualFire = hasConsumption ? consumption - totalNeed : 0.0;
    final actualFireRate =
        hasConsumption && survey > 0 ? actualFire / survey * 100 : 0.0;
    final pending = (row.ordered - row.delivered).clamp(0.0, double.infinity);
    final counted = row.counted;
    return DiameterCalc(
      diameter: row.diameter,
      survey: survey,
      acceptedRate: rate,
      acceptedTons: acceptedTons,
      totalNeed: totalNeed,
      consumption: consumption,
      actualFire: actualFire,
      actualFireRate: actualFireRate,
      counted: counted,
      pendingOrder: pending.toDouble(),
      availableStock: counted + pending,
      remainingNeed: totalNeed - consumption,
    );
  }
}
