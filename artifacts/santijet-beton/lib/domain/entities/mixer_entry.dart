import 'package:equatable/equatable.dart';

/// Tek mikser / irsaliye satırı.
class MixerEntry extends Equatable {
  const MixerEntry({
    required this.id,
    this.ticketNo = '',
    this.plate = '',
    this.volumeM3 = 0,
    this.slumpCm,
    this.note = '',
    this.waybillImageBase64 = '',
    this.ocrRawText = '',
  });

  final String id;
  final String ticketNo;
  final String plate;
  final double volumeM3;
  final double? slumpCm;
  final String note;

  /// İrsaliye fotoğrafı (JPEG/PNG base64, data-URL öneki olmadan).
  final String waybillImageBase64;
  final String ocrRawText;

  MixerEntry copyWith({
    String? id,
    String? ticketNo,
    String? plate,
    double? volumeM3,
    double? slumpCm,
    String? note,
    String? waybillImageBase64,
    String? ocrRawText,
  }) {
    return MixerEntry(
      id: id ?? this.id,
      ticketNo: ticketNo ?? this.ticketNo,
      plate: plate ?? this.plate,
      volumeM3: volumeM3 ?? this.volumeM3,
      slumpCm: slumpCm ?? this.slumpCm,
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
        'slumpCm': slumpCm,
        'note': note,
        'waybillImageBase64': waybillImageBase64,
        'ocrRawText': ocrRawText,
      };

  factory MixerEntry.fromJson(Map<String, dynamic> json) => MixerEntry(
        id: json['id'] as String? ?? '',
        ticketNo: json['ticketNo'] as String? ?? '',
        plate: json['plate'] as String? ?? '',
        volumeM3: (json['volumeM3'] as num?)?.toDouble() ?? 0,
        slumpCm: (json['slumpCm'] as num?)?.toDouble(),
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
        slumpCm,
        note,
        waybillImageBase64,
        ocrRawText,
      ];
}
