import 'package:equatable/equatable.dart';

import 'mixer_entry.dart';

/// Şantiyeye gelen / dökülen beton kaydı.
///
/// Sipariş seçilince yapısal eleman, blok, kat, sınıf ve firma siparişten
/// gelir. Kullanıcı mikser (çoklu) ve pompa verilerini girer.
/// Sipariş dışı yere döküm → [isExtraPour] = true.
class ConcretePour extends Equatable {
  const ConcretePour({
    required this.id,
    required this.projectId,
    required this.date,
    required this.volumeM3,
    this.elementName = '',
    this.block = '',
    this.floor = '',
    this.concreteClass = 'C30/37',
    this.supplier = '',
    this.ticketNo = '',
    this.mixerCount,
    this.mixerPlate = '',
    this.mixerNote = '',
    this.mixers = const [],
    this.pumpCount,
    this.pumpType = '',
    this.pumpNote = '',
    this.slumpCm,
    this.pourStart,
    this.pourEnd,
    this.notes = '',
    this.orderId,
    this.isExtraPour = false,
    this.discoveryItemId,
  });

  final String id;
  final String projectId;
  final String date;

  /// Toplam dökülen hacim (genelde mikser hacimleri toplamı).
  final double volumeM3;

  final String elementName;
  final String block;
  final String floor;
  final String concreteClass;
  final String supplier;

  /// Özet / geriye dönük tek satır alanlar.
  final String ticketNo;
  final int? mixerCount;
  final String mixerPlate;
  final String mixerNote;

  /// Mikser / irsaliye satırları.
  final List<MixerEntry> mixers;

  final int? pumpCount;
  final String pumpType;
  final String pumpNote;

  final double? slumpCm;
  final DateTime? pourStart;
  final DateTime? pourEnd;
  final String notes;
  final String? orderId;
  final bool isExtraPour;
  final String? discoveryItemId;

  String get locationSummary {
    final parts = <String>[
      if (block.trim().isNotEmpty) block.trim(),
      if (floor.trim().isNotEmpty) floor.trim(),
    ];
    return parts.join(' · ');
  }

  ConcretePour copyWith({
    String? id,
    String? projectId,
    String? date,
    double? volumeM3,
    String? elementName,
    String? block,
    String? floor,
    String? concreteClass,
    String? supplier,
    String? ticketNo,
    int? mixerCount,
    String? mixerPlate,
    String? mixerNote,
    List<MixerEntry>? mixers,
    int? pumpCount,
    String? pumpType,
    String? pumpNote,
    double? slumpCm,
    DateTime? pourStart,
    DateTime? pourEnd,
    String? notes,
    String? orderId,
    bool? isExtraPour,
    String? discoveryItemId,
  }) {
    return ConcretePour(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      date: date ?? this.date,
      volumeM3: volumeM3 ?? this.volumeM3,
      elementName: elementName ?? this.elementName,
      block: block ?? this.block,
      floor: floor ?? this.floor,
      concreteClass: concreteClass ?? this.concreteClass,
      supplier: supplier ?? this.supplier,
      ticketNo: ticketNo ?? this.ticketNo,
      mixerCount: mixerCount ?? this.mixerCount,
      mixerPlate: mixerPlate ?? this.mixerPlate,
      mixerNote: mixerNote ?? this.mixerNote,
      mixers: mixers ?? this.mixers,
      pumpCount: pumpCount ?? this.pumpCount,
      pumpType: pumpType ?? this.pumpType,
      pumpNote: pumpNote ?? this.pumpNote,
      slumpCm: slumpCm ?? this.slumpCm,
      pourStart: pourStart ?? this.pourStart,
      pourEnd: pourEnd ?? this.pourEnd,
      notes: notes ?? this.notes,
      orderId: orderId ?? this.orderId,
      isExtraPour: isExtraPour ?? this.isExtraPour,
      discoveryItemId: discoveryItemId ?? this.discoveryItemId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'date': date,
        'volumeM3': volumeM3,
        'elementName': elementName,
        'block': block,
        'floor': floor,
        'concreteClass': concreteClass,
        'supplier': supplier,
        'ticketNo': ticketNo,
        'mixerCount': mixerCount,
        'mixerPlate': mixerPlate,
        'mixerNote': mixerNote,
        'mixers': mixers.map((e) => e.toJson()).toList(),
        'pumpCount': pumpCount,
        'pumpType': pumpType,
        'pumpNote': pumpNote,
        'slumpCm': slumpCm,
        'pourStart': pourStart?.toIso8601String(),
        'pourEnd': pourEnd?.toIso8601String(),
        'notes': notes,
        'orderId': orderId,
        'isExtraPour': isExtraPour,
        'discoveryItemId': discoveryItemId,
      };

  factory ConcretePour.fromJson(Map<String, dynamic> json) {
    var block = json['block'] as String? ?? '';
    var floor = json['floor'] as String? ?? '';
    if (block.isEmpty && floor.isEmpty) {
      final legacy = (json['location'] as String? ?? '').trim();
      if (legacy.isNotEmpty) {
        final parts = legacy.split('·').map((e) => e.trim()).toList();
        if (parts.length >= 2) {
          block = parts.first;
          floor = parts.sublist(1).join(' · ');
        } else {
          block = legacy;
        }
      }
    }

    final rawMixers = json['mixers'] as List<dynamic>? ?? const [];
    var mixers = rawMixers
        .whereType<Map>()
        .map((e) => MixerEntry.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    // Eski tek mikser alanlarından satır üret
    if (mixers.isEmpty) {
      final ticket = json['ticketNo'] as String? ?? '';
      final plate = json['mixerPlate'] as String? ?? '';
      final vol = (json['volumeM3'] as num?)?.toDouble() ?? 0;
      final slump = (json['slumpCm'] as num?)?.toDouble();
      final note = json['mixerNote'] as String? ?? '';
      if (ticket.isNotEmpty || plate.isNotEmpty || vol > 0) {
        mixers = [
          MixerEntry(
            id: '${json['id']}_m1',
            ticketNo: ticket,
            plate: plate,
            volumeM3: vol,
            slumpCm: slump,
            note: note,
          ),
        ];
      }
    }

    return ConcretePour(
      id: json['id'] as String,
      projectId: json['projectId'] as String? ?? '',
      date: json['date'] as String? ?? '',
      volumeM3: (json['volumeM3'] as num?)?.toDouble() ?? 0,
      elementName: json['elementName'] as String? ?? '',
      block: block,
      floor: floor,
      concreteClass: json['concreteClass'] as String? ?? 'C30/37',
      supplier: json['supplier'] as String? ?? '',
      ticketNo: json['ticketNo'] as String? ?? '',
      mixerCount: (json['mixerCount'] as num?)?.toInt() ??
          (mixers.isEmpty ? null : mixers.length),
      mixerPlate: json['mixerPlate'] as String? ?? '',
      mixerNote: json['mixerNote'] as String? ?? '',
      mixers: mixers,
      pumpCount: (json['pumpCount'] as num?)?.toInt(),
      pumpType: json['pumpType'] as String? ?? '',
      pumpNote: json['pumpNote'] as String? ?? '',
      slumpCm: (json['slumpCm'] as num?)?.toDouble(),
      pourStart: json['pourStart'] != null
          ? DateTime.tryParse(json['pourStart'] as String)
          : null,
      pourEnd: json['pourEnd'] != null
          ? DateTime.tryParse(json['pourEnd'] as String)
          : null,
      notes: json['notes'] as String? ?? '',
      orderId: json['orderId'] as String?,
      isExtraPour: json['isExtraPour'] as bool? ?? false,
      discoveryItemId: json['discoveryItemId'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        date,
        volumeM3,
        elementName,
        block,
        floor,
        concreteClass,
        supplier,
        ticketNo,
        mixerCount,
        mixerPlate,
        mixerNote,
        mixers,
        pumpCount,
        pumpType,
        pumpNote,
        slumpCm,
        pourStart,
        pourEnd,
        notes,
        orderId,
        isExtraPour,
        discoveryItemId,
      ];
}
