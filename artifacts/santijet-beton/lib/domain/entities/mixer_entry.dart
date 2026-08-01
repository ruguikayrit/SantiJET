import 'package:equatable/equatable.dart';

/// Tek mikser / irsaliye satırı.
class MixerEntry extends Equatable {
  const MixerEntry({
    required this.id,
    this.ticketNo = '',
    this.plate = '',
    this.volumeM3 = 0,
    this.concreteClass = '',
    this.note = '',
    this.waybillImageBase64 = '',
    this.ocrRawText = '',
  });

  final String id;
  final String ticketNo;
  final String plate;
  final double volumeM3;
  final String concreteClass;
  final String note;

  /// İrsaliye fotoğrafı (JPEG/PNG base64, data-URL öneki olmadan).
  final String waybillImageBase64;
  final String ocrRawText;

  MixerEntry copyWith({
    String? id,
    String? ticketNo,
    String? plate,
    double? volumeM3,
    String? concreteClass,
    String? note,
    String? waybillImageBase64,
    String? ocrRawText,
  }) {
    return MixerEntry(
      id: id ?? this.id,
      ticketNo: ticketNo ?? this.ticketNo,
      plate: plate ?? this.plate,
      volumeM3: volumeM3 ?? this.volumeM3,
      concreteClass: concreteClass ?? this.concreteClass,
      note: note ?? this.note,
      waybillImageBase64: waybillImageBase64 ?? this.waybillImageBase64,
      ocrRawText: ocrRawText ?? this.ocrRawText,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ticketNo': ticketNo,
        'plate': plate,
        'volumeM3': volumeM3,
        'concreteClass': concreteClass,
        'note': note,
        'waybillImageBase64': waybillImageBase64,
        'ocrRawText': ocrRawText,
      };

  factory MixerEntry.fromJson(Map<String, dynamic> json) => MixerEntry(
        id: json['id'] as String? ?? '',
        ticketNo: json['ticketNo'] as String? ?? '',
        plate: json['plate'] as String? ?? '',
        volumeM3: (json['volumeM3'] as num?)?.toDouble() ?? 0,
        concreteClass: json['concreteClass'] as String? ?? '',
        note: json['note'] as String? ?? '',
        waybillImageBase64: json['waybillImageBase64'] as String? ?? '',
        ocrRawText: json['ocrRawText'] as String? ?? '',
      );

  @override
  List<Object?> get props => [
        id,
        ticketNo,
        plate,
        volumeM3,
        concreteClass,
        note,
        waybillImageBase64,
        ocrRawText,
      ];
}
