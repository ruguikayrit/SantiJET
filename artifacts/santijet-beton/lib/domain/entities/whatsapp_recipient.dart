import 'package:equatable/equatable.dart';

/// Proje siparişinin gideceği WhatsApp alıcısı (sevkiyatçı, saha mühendisi…).
class WhatsAppRecipient extends Equatable {
  const WhatsAppRecipient({
    this.name = '',
    required this.number,
  });

  final String name;
  final String number;

  Map<String, dynamic> toJson() => {
        'name': name,
        'number': number,
      };

  factory WhatsAppRecipient.fromJson(Map<String, dynamic> json) =>
      WhatsAppRecipient(
        name: json['name'] as String? ?? '',
        number: json['number'] as String? ?? '',
      );

  @override
  List<Object?> get props => [name, number];
}
