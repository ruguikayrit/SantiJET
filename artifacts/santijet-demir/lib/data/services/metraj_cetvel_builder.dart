import 'package:santijet_demir/data/services/cad_text_entity.dart';
import 'package:santijet_demir/data/services/element_header_parser.dart';
import 'package:santijet_demir/data/services/rebar_text_parser.dart';
import 'package:santijet_demir/data/services/rebar_weight_calculator.dart';
import 'package:santijet_demir/domain/entities/rebar_metraj.dart';

class MetrajCetvelBuildResult {
  const MetrajCetvelBuildResult({
    required this.textDetails,
    required this.cetvel,
    required this.unassignedCount,
  });

  final List<RebarMetrajTextDetail> textDetails;
  final List<MetrajCetvelEntry> cetvel;
  final int unassignedCount;
}

class MetrajCetvelBuilder {
  const MetrajCetvelBuilder({
    this.headerParser = const ElementHeaderParser(),
    this.textParser = const RebarTextParser(),
    this.unitScale = 1.0,
  });

  final ElementHeaderParser headerParser;
  final RebarTextParser textParser;
  final double unitScale;

  MetrajCetvelBuildResult build(List<CadTextEntity> entities) {
    final textDetails = <RebarMetrajTextDetail>[];
    final cetvelEntries = <MetrajCetvelEntry>[];
    var unassignedCount = 0;

    ElementHeader? currentHeader;
    _ElementRowsBuilder? currentBuilder;
    var awaitingBenzer = false;

    void startElement(ElementHeader header) {
      currentHeader = header;
      awaitingBenzer = header.benzerCount <= 1 &&
          !RegExp(r'\d+\s*(?:ADET|ADT|AD)', caseSensitive: false)
              .hasMatch(header.sourceText);
      currentBuilder = _ElementRowsBuilder(header: header);
    }

    void finalizeCurrentElement() {
      if (currentBuilder == null || currentHeader == null) return;
      final entry = currentBuilder!.toEntry();
      if (entry.rows.isNotEmpty) {
        cetvelEntries.add(entry);
      }
      currentBuilder = null;
      currentHeader = null;
      awaitingBenzer = false;
    }

    for (final entity in entities) {
      final raw = entity.text.trim();
      if (raw.isEmpty) continue;

      final header = headerParser.tryParse(raw);
      if (header != null) {
        finalizeCurrentElement();
        startElement(header);
        continue;
      }

      if (awaitingBenzer && currentHeader != null) {
        final benzer = headerParser.tryParseBenzerOnly(raw);
        if (benzer != null && benzer > 0) {
          final updated = ElementHeader(
            type: currentHeader!.type,
            id: currentHeader!.id,
            code: currentHeader!.code,
            benzerCount: benzer,
            sourceText: '${currentHeader!.sourceText} · $raw',
            dimensionText: currentHeader!.dimensionText,
          );
          currentHeader = updated;
          currentBuilder?.updateHeader(updated);
          awaitingBenzer = false;
          continue;
        }
      }

      final parsed = textParser.parseOne(raw);
      if (parsed == null) continue;

      final scaledLength = parsed.lengthM * unitScale;
      final unitWeightKg = RebarWeightCalculator.weightKg(
        diameterMm: parsed.diameter,
        lengthM: scaledLength,
      );

      if (currentHeader == null || currentBuilder == null) {
        unassignedCount++;
        textDetails.add(
          RebarMetrajTextDetail(
            entityType: entity.entityType,
            sourceText: raw,
            included: true,
            diameter: parsed.diameter,
            lengthM: scaledLength,
            unitQuantity: parsed.quantity,
            benzerCount: 1,
            quantity: parsed.quantity,
            weightKg: unitWeightKg * parsed.quantity,
            spacingCm: parsed.spacingCm,
            rebarRole: parsed.role,
          ),
        );
        continue;
      }

      final benzer = currentHeader!.benzerCount;
      final totalQty = parsed.quantity * benzer;
      textDetails.add(
        RebarMetrajTextDetail(
          entityType: entity.entityType,
          sourceText: raw,
          included: true,
          diameter: parsed.diameter,
          lengthM: scaledLength,
          unitQuantity: parsed.quantity,
          benzerCount: benzer,
          quantity: totalQty,
          weightKg: unitWeightKg * totalQty,
          spacingCm: parsed.spacingCm,
          elementCode: currentHeader!.code,
          elementTypeCode: currentHeader!.type.codeLetter,
          dimensionText: currentHeader!.dimensionText,
          rebarRole: parsed.role,
        ),
      );
      currentBuilder!.addRow(
        role: parsed.role,
        diameter: parsed.diameter,
        lengthM: scaledLength,
        unitQuantity: parsed.quantity,
        benzerCount: benzer,
        unitWeightKg: unitWeightKg,
        sourceText: raw,
      );
    }

    finalizeCurrentElement();

    return MetrajCetvelBuildResult(
      textDetails: textDetails,
      cetvel: cetvelEntries,
      unassignedCount: unassignedCount,
    );
  }
}

class _ElementRowsBuilder {
  _ElementRowsBuilder({required ElementHeader header}) : _header = header;

  ElementHeader _header;
  final List<MetrajCetvelRow> _rows = [];

  void updateHeader(ElementHeader header) {
    final previousBenzer = _header.benzerCount;
    _header = header;
    if (previousBenzer == header.benzerCount) return;

    for (var i = 0; i < _rows.length; i++) {
      final row = _rows[i];
      _rows[i] = MetrajCetvelRow(
        role: row.role,
        diameter: row.diameter,
        lengthM: row.lengthM,
        unitQuantity: row.unitQuantity,
        totalQuantity: row.unitQuantity * header.benzerCount,
        unitWeightKg: row.unitWeightKg,
        totalWeightKg: row.unitWeightKg * header.benzerCount,
        sourceText: row.sourceText,
      );
    }
  }

  void addRow({
    required RebarLabelRole role,
    required int diameter,
    required double lengthM,
    required int unitQuantity,
    required int benzerCount,
    required double unitWeightKg,
    required String sourceText,
  }) {
    _rows.add(
      MetrajCetvelRow(
        role: role,
        diameter: diameter,
        lengthM: lengthM,
        unitQuantity: unitQuantity,
        totalQuantity: unitQuantity * benzerCount,
        unitWeightKg: unitWeightKg,
        totalWeightKg: unitWeightKg * benzerCount,
        sourceText: sourceText,
      ),
    );
  }

  MetrajCetvelEntry toEntry() {
    return MetrajCetvelEntry(
      elementCode: _header.code,
      elementTypeCode: _header.type.codeLetter,
      elementTypeLabel: _header.type.label,
      dimensionText: _header.dimensionText,
      benzerCount: _header.benzerCount,
      sourceText: _header.sourceText,
      rows: List<MetrajCetvelRow>.from(_rows),
    );
  }
}
