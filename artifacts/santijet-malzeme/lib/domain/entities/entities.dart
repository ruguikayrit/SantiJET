/// Domain entity barrel + Hive typeId planı (JSON-in-box; adapter sonraki faz).
///
/// | typeId | Entity |
/// |------:|--------|
/// | 0 | Project |
/// | 1 | KesifSnapshot |
/// | 2 | KesifLine |
/// | 3 | MaterialItem |
/// | 4 | MaterialRequest |
/// | 5 | MaterialRequestLine |
/// | 6 | QuoteRound |
/// | 7 | SupplierQuote |
/// | 8 | QuoteLine |
/// | 9 | Delivery |
/// | 10 | DeliveryLine |
/// | 11 | TechSheet |
/// | 12 | MaterialDecision |
/// | 13 | UnitConsumption |
library;

export 'delivery.dart';
export 'delivery_line.dart';
export 'kesif_line.dart';
export 'kesif_snapshot.dart';
export 'material_decision.dart';
export 'material_item.dart';
export 'material_request.dart';
export 'material_request_line.dart';
export 'project.dart';
export 'quote_line.dart';
export 'quote_round.dart';
export 'request_approvals.dart';
export 'supplier_quote.dart';
export 'tech_sheet.dart';
export 'unit_consumption.dart';
