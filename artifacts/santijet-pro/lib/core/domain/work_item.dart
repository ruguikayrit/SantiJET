import 'unit.dart';

/// İş kaleminin türü. Çelik değeri ilerideki modül içindir; ekran açmaz.
enum WorkItemKind {
  general,
  beton,
  donati,
  celik,
}

/// Ne yapılacak, ne kadara planlanıyor.
///
/// Gerçekleşen miktar Faz 4’e kadar elle yazılmaz; varsayılan sıfırdır.
/// Stok, maliyet fişi, hakediş ve kasa bu sınıfta yoktur.
class WorkItem {
  const WorkItem({
    required this.id,
    required this.projectId,
    required this.name,
    required this.unit,
    this.code = '',
    this.kind = WorkItemKind.general,
    this.category = '',
    this.plannedQty = 0,
    this.unitPrice = 0,
    this.actualQty = 0,
    this.revision = 1,
    this.supersedesId,
  });

  final String id;
  final String projectId;
  final String code;
  final String name;

  /// Örn. C35/40, Ø16, 20 cm gazbeton.
  final String category;
  final WorkItemKind kind;
  final MeasureUnit unit;
  final double plannedQty;
  final double unitPrice;

  /// Yapılan miktar. Üretim kayıtları gelene kadar 0.
  final double actualQty;
  final int revision;
  final String? supersedesId;

  /// Bağ 3: ne kadara yapılması planlanıyor.
  double get plannedAmount => plannedQty * unitPrice;

  /// Bağ 4: kalan = plan − yapılan.
  double get remainingQty => plannedQty - actualQty;

  /// Plan yoksa gerçekleşme oranı 0’dır.
  double get progress => plannedQty == 0 ? 0 : actualQty / plannedQty;
}
