import 'package:santijet_demir/data/services/cad_text_entity.dart';
import 'package:santijet_demir/data/services/cad_text_sorter.dart';
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

class _HeaderAnchor {
  _HeaderAnchor({
    required this.header,
    required this.entity,
  });

  ElementHeader header;
  final CadTextEntity entity;
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
    final positioned = entities.where((entity) => entity.hasPosition).length >= 2;
    if (positioned) {
      return _buildSpatial(entities);
    }
    return _buildSequential(sortCadTextEntitiesForMetraj(entities));
  }

  MetrajCetvelBuildResult _buildSequential(List<CadTextEntity> entities) {
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
          final updated = currentHeader!.copyWithBenzer(benzer, raw);
          currentHeader = updated;
          currentBuilder?.updateHeader(updated);
          awaitingBenzer = false;
          continue;
        }
      }

      final parsed = textParser.parseOne(raw);
      if (parsed == null) continue;

      final detail = _detailFromParsed(
        entity: entity,
        parsed: parsed,
        header: currentHeader,
      );
      textDetails.add(detail);

      if (currentHeader == null || currentBuilder == null) {
        unassignedCount++;
        continue;
      }

      currentBuilder!.addRow(
        role: parsed.role,
        diameter: parsed.diameter,
        lengthM: detail.lengthM!,
        unitQuantity: parsed.quantity,
        benzerCount: currentHeader!.benzerCount,
        unitWeightKg: detail.quantity > 0 ? detail.weightKg / detail.quantity : 0,
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

  MetrajCetvelBuildResult _buildSpatial(List<CadTextEntity> entities) {
    final assignRadius = estimateMetrajAssignRadius(entities);
    final headers = <_HeaderAnchor>[];
    final benzerOnly = <CadTextEntity>[];
    final rebars = <({CadTextEntity entity, RebarTextEntry parsed})>[];

    for (final entity in entities) {
      final raw = entity.text.trim();
      if (raw.isEmpty) continue;

      final header = headerParser.tryParse(raw);
      if (header != null) {
        headers.add(_HeaderAnchor(header: header, entity: entity));
        continue;
      }

      if (headerParser.tryParseBenzerOnly(raw) != null) {
        benzerOnly.add(entity);
        continue;
      }

      final parsed = textParser.parseOne(raw);
      if (parsed != null) {
        rebars.add((entity: entity, parsed: parsed));
      }
    }

    _attachBenzerCounts(headers, benzerOnly, assignRadius);

    final builders = {
      for (final anchor in headers) anchor.header.code: _ElementRowsBuilder(header: anchor.header),
    };

    var unassignedCount = 0;
    final textDetails = <RebarMetrajTextDetail>[];

    for (final item in rebars) {
      final anchor = _nearestHeaderAnchor(
        item.entity,
        headers,
        assignRadius,
      );
      final header = anchor?.header;

      final detail = _detailFromParsed(
        entity: item.entity,
        parsed: item.parsed,
        header: header,
      );
      textDetails.add(detail);

      if (header == null || builders[header.code] == null) {
        unassignedCount++;
        continue;
      }

      builders[header.code]!.addRow(
        role: item.parsed.role,
        diameter: item.parsed.diameter,
        lengthM: detail.lengthM!,
        unitQuantity: item.parsed.quantity,
        benzerCount: header.benzerCount,
        unitWeightKg: detail.quantity > 0 ? detail.weightKg / detail.quantity : 0,
        sourceText: item.entity.text.trim(),
      );
    }

    final cetvelEntries = headers
        .map((anchor) => builders[anchor.header.code]?.toEntry())
        .whereType<MetrajCetvelEntry>()
        .where((entry) => entry.rows.isNotEmpty)
        .toList();

    if (cetvelEntries.isEmpty && rebars.isNotEmpty) {
      return _buildSequential(sortCadTextEntitiesForMetraj(entities));
    }

    return MetrajCetvelBuildResult(
      textDetails: textDetails,
      cetvel: cetvelEntries,
      unassignedCount: unassignedCount,
    );
  }

  void _attachBenzerCounts(
    List<_HeaderAnchor> headers,
    List<CadTextEntity> benzerOnly,
    double assignRadius,
  ) {
    for (final entity in benzerOnly) {
      final count = headerParser.tryParseBenzerOnly(entity.text.trim());
      if (count == null || count <= 0) continue;

      final anchor = _nearestHeaderAnchor(entity, headers, assignRadius * 0.6);
      if (anchor == null) continue;

      final updated = anchor.header.copyWithBenzer(count, entity.text.trim());
      anchor.header = updated;
    }
  }

  _HeaderAnchor? _nearestHeaderAnchor(
    CadTextEntity entity,
    List<_HeaderAnchor> headers,
    double maxDistance,
  ) {
    if (headers.isEmpty || !entity.hasPosition) return null;

    _HeaderAnchor? best;
    var bestScore = double.infinity;

    for (final anchor in headers) {
      if (!anchor.entity.hasPosition) continue;

      final dx = (entity.x! - anchor.entity.x!).abs();
      final dy = entity.y! - anchor.entity.y!;
      final distance = cadTextDistance(entity, anchor.entity);

      if (distance > maxDistance) continue;

      // Başlık demirin üstünde olmalı; yatay yakınlık önemli.
      final verticalPenalty = dy > 0 ? dy * 1.4 : dy.abs() * 0.35;
      final score = dx * 1.1 + verticalPenalty + distance * 0.05;

      if (score < bestScore) {
        bestScore = score;
        best = anchor;
      }
    }

    return best;
  }

  RebarMetrajTextDetail _detailFromParsed({
    required CadTextEntity entity,
    required RebarTextEntry parsed,
    required ElementHeader? header,
  }) {
    final scaledLength = parsed.lengthM * unitScale;
    final unitWeightKg = RebarWeightCalculator.weightKg(
      diameterMm: parsed.diameter,
      lengthM: scaledLength,
    );
    final benzer = header?.benzerCount ?? 1;
    final totalQty = parsed.quantity * benzer;

    return RebarMetrajTextDetail(
      entityType: entity.entityType,
      sourceText: entity.text.trim(),
      included: true,
      diameter: parsed.diameter,
      lengthM: scaledLength,
      unitQuantity: parsed.quantity,
      benzerCount: benzer,
      quantity: totalQty,
      weightKg: unitWeightKg * totalQty,
      spacingCm: parsed.spacingCm,
      elementCode: header?.code,
      elementTypeCode: header?.type.codeLetter,
      dimensionText: header?.dimensionText,
      rebarRole: parsed.role,
    );
  }
}

extension on ElementHeader {
  ElementHeader copyWithBenzer(int benzer, String benzerText) {
    return ElementHeader(
      type: type,
      id: id,
      code: code,
      benzerCount: benzer,
      sourceText: '$sourceText · $benzerText',
      dimensionText: dimensionText,
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
