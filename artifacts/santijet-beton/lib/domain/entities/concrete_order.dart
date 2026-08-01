import 'package:equatable/equatable.dart';

/// Planlı beton siparişi (program / WhatsApp paylaşımı).
class ConcreteOrder extends Equatable {
  const ConcreteOrder({
    required this.id,
    required this.projectId,
    required this.plannedDate,
    required this.plannedM3,
    this.elementName = '',
    this.block = '',
    this.floor = '',
    this.concreteClass = 'C30/37',
    this.supplier = '',
    this.plannedStartHour = '',
    this.slumpCm,
    this.pumpCount,
    this.pumpType = '',
    this.notes = '',
    this.sharedViaWhatsApp = false,
  });

  final String id;
  final String projectId;

  /// gg.aa.yyyy
  final String plannedDate;
  final double plannedM3;

  /// Yapısal eleman (örn. Perde Duvar B1).
  final String elementName;

  /// Blok (örn. A Blok).
  final String block;

  /// Kat (örn. Bodrum Kat).
  final String floor;

  final String concreteClass;
  final String supplier;
  final String plannedStartHour;

  /// Talep edilen beton slump (cm).
  final double? slumpCm;

  /// Pompa talebi — adet.
  final int? pumpCount;

  /// Pompa talebi — tip (sabit / mobil vb.).
  final String pumpType;

  final String notes;
  final bool sharedViaWhatsApp;

  /// Blok + kat özeti (gösterim / paylaşım).
  String get locationSummary {
    final parts = <String>[
      if (block.trim().isNotEmpty) block.trim(),
      if (floor.trim().isNotEmpty) floor.trim(),
    ];
    return parts.join(' · ');
  }

  String get pumpRequestSummary {
    final parts = <String>[
      if (pumpCount != null) '$pumpCount adet',
      if (pumpType.trim().isNotEmpty) pumpType.trim(),
    ];
    return parts.join(' · ');
  }

  ConcreteOrder copyWith({
    String? id,
    String? projectId,
    String? plannedDate,
    double? plannedM3,
    String? elementName,
    String? block,
    String? floor,
    String? concreteClass,
    String? supplier,
    String? plannedStartHour,
    double? slumpCm,
    int? pumpCount,
    String? pumpType,
    String? notes,
    bool? sharedViaWhatsApp,
  }) {
    return ConcreteOrder(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      plannedDate: plannedDate ?? this.plannedDate,
      plannedM3: plannedM3 ?? this.plannedM3,
      elementName: elementName ?? this.elementName,
      block: block ?? this.block,
      floor: floor ?? this.floor,
      concreteClass: concreteClass ?? this.concreteClass,
      supplier: supplier ?? this.supplier,
      plannedStartHour: plannedStartHour ?? this.plannedStartHour,
      slumpCm: slumpCm ?? this.slumpCm,
      pumpCount: pumpCount ?? this.pumpCount,
      pumpType: pumpType ?? this.pumpType,
      notes: notes ?? this.notes,
      sharedViaWhatsApp: sharedViaWhatsApp ?? this.sharedViaWhatsApp,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'plannedDate': plannedDate,
        'plannedM3': plannedM3,
        'elementName': elementName,
        'block': block,
        'floor': floor,
        'concreteClass': concreteClass,
        'supplier': supplier,
        'plannedStartHour': plannedStartHour,
        'slumpCm': slumpCm,
        'pumpCount': pumpCount,
        'pumpType': pumpType,
        'notes': notes,
        'sharedViaWhatsApp': sharedViaWhatsApp,
      };

  factory ConcreteOrder.fromJson(Map<String, dynamic> json) {
    var block = json['block'] as String? ?? '';
    var floor = json['floor'] as String? ?? '';
    // Eski tek satır lokasyon → blok / kat
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

    return ConcreteOrder(
      id: json['id'] as String,
      projectId: json['projectId'] as String? ?? '',
      plannedDate: json['plannedDate'] as String? ??
          json['orderDate'] as String? ??
          '',
      plannedM3: (json['plannedM3'] as num?)?.toDouble() ??
          (json['orderedM3'] as num?)?.toDouble() ??
          0,
      elementName: json['elementName'] as String? ?? '',
      block: block,
      floor: floor,
      concreteClass: json['concreteClass'] as String? ?? 'C30/37',
      supplier: json['supplier'] as String? ?? '',
      plannedStartHour: json['plannedStartHour'] as String? ?? '',
      slumpCm: (json['slumpCm'] as num?)?.toDouble(),
      pumpCount: (json['pumpCount'] as num?)?.toInt(),
      pumpType: json['pumpType'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      sharedViaWhatsApp: json['sharedViaWhatsApp'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        projectId,
        plannedDate,
        plannedM3,
        elementName,
        block,
        floor,
        concreteClass,
        supplier,
        plannedStartHour,
        slumpCm,
        pumpCount,
        pumpType,
        notes,
        sharedViaWhatsApp,
      ];
}
