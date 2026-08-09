import 'package:equatable/equatable.dart';

/// Hive typeId plan: 3
/// Katalog malzeme kartı.
class MaterialItem extends Equatable {
  const MaterialItem({
    required this.id,
    required this.ad,
    required this.birim,
    this.teknikKategori = '',
    this.defaultManufacturer = '',
    this.defaultProductLink = '',
  });

  final String id;
  final String ad;
  final String birim;
  final String teknikKategori;
  final String defaultManufacturer;
  final String defaultProductLink;

  MaterialItem copyWith({
    String? id,
    String? ad,
    String? birim,
    String? teknikKategori,
    String? defaultManufacturer,
    String? defaultProductLink,
  }) {
    return MaterialItem(
      id: id ?? this.id,
      ad: ad ?? this.ad,
      birim: birim ?? this.birim,
      teknikKategori: teknikKategori ?? this.teknikKategori,
      defaultManufacturer: defaultManufacturer ?? this.defaultManufacturer,
      defaultProductLink: defaultProductLink ?? this.defaultProductLink,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ad': ad,
        'birim': birim,
        'teknikKategori': teknikKategori,
        'defaultManufacturer': defaultManufacturer,
        'defaultProductLink': defaultProductLink,
      };

  factory MaterialItem.fromJson(Map<String, dynamic> json) => MaterialItem(
        id: json['id'] as String,
        ad: json['ad'] as String? ?? '',
        birim: json['birim'] as String? ?? '',
        teknikKategori: json['teknikKategori'] as String? ?? '',
        defaultManufacturer: json['defaultManufacturer'] as String? ?? '',
        defaultProductLink: json['defaultProductLink'] as String? ?? '',
      );

  @override
  List<Object?> get props => [
        id,
        ad,
        birim,
        teknikKategori,
        defaultManufacturer,
        defaultProductLink,
      ];
}
