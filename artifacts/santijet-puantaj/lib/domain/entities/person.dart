import 'package:equatable/equatable.dart';

import '../../core/utils/text_format.dart';

/// Personel kaydı — her proje kendi personel listesine sahiptir.
///
/// PIN / rol yetkilendirmesi sonraki fazda; şimdilik puantaj cetveli kaynağı.
///
/// [name] (Ad Soyad) daima başlık biçiminde saklanır: her kelimenin ilk harfi
/// büyük, kalanı küçük (`İSA ALKAN` → `İsa Alkan`).
class Person extends Equatable {
  const Person._({
    required this.id,
    required this.projectId,
    required this.name,
    this.profession = '',
    this.phone = '',
    this.company = '',
    this.team = '',
    this.address = '',
    this.tc = '',
    this.iban = '',
    this.bankName = '',
    this.hireDate = '',
    this.leaveDate = '',
    this.active = true,
  });

  factory Person({
    required String id,
    required String projectId,
    required String name,
    String profession = '',
    String phone = '',
    String company = '',
    String team = '',
    String address = '',
    String tc = '',
    String iban = '',
    String bankName = '',
    String hireDate = '',
    String leaveDate = '',
    bool active = true,
  }) {
    return Person._(
      id: id,
      projectId: projectId,
      name: titleCaseTr(name),
      profession: titleCaseTr(profession),
      phone: phone,
      company: titleCaseTr(company),
      team: titleCaseTr(team),
      address: address,
      tc: tc,
      iban: iban,
      bankName: bankName,
      hireDate: hireDate,
      leaveDate: leaveDate,
      active: active,
    );
  }

  final String id;

  /// Personelin ait olduğu proje — projeler arası paylaşılmaz.
  final String projectId;

  /// Ad Soyad — başlık biçimi (bkz. [titleCaseTr]).
  final String name;

  /// Meslek — başlık biçimi.
  final String profession;
  final String phone;

  /// Firma — başlık biçimi.
  final String company;

  /// Ekip — başlık biçimi.
  final String team;
  final String address;

  /// T.C. kimlik no (opsiyonel).
  final String tc;

  /// IBAN (opsiyonel).
  final String iban;

  /// Banka adı (opsiyonel).
  final String bankName;

  /// İşe giriş tarihi — yyyy-MM-dd.
  final String hireDate;

  /// İşten çıkış tarihi — yyyy-MM-dd; doluysa genelde pasif.
  final String leaveDate;

  final bool active;

  /// İşe giriş / çıkış tarihini ISO (`yyyy-MM-dd`) veya `dd.MM.yyyy` olarak çözümler.
  static DateTime? parseEmploymentDate(String? raw) {
    final s = raw?.trim() ?? '';
    if (s.isEmpty) return null;
    final iso = DateTime.tryParse(s);
    if (iso != null) return DateTime(iso.year, iso.month, iso.day);
    final parts = s.split('.');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final d = DateTime(year, month, day);
    if (d.year != year || d.month != month || d.day != day) return null;
    return d;
  }

  /// [date] — puantaj günü (`dd.MM.yyyy` veya ISO).
  ///
  /// İşe giriş–çıkış takvimine göre: çıkış günü dahil çalışıyor sayılır;
  /// çıkıştan sonraki günlerde false. Manuel `active` bayrağı kullanılmaz.
  bool isActiveOn(String date) {
    final day = parseEmploymentDate(date);
    if (day == null) return true;

    final hire = parseEmploymentDate(hireDate);
    if (hire != null && day.isBefore(hire)) return false;

    final leave = parseEmploymentDate(leaveDate);
    if (leave != null && day.isAfter(leave)) return false;

    return true;
  }

  /// Rapor/seçim döneminde listelensin mi?
  ///
  /// - Günlük: yalnızca o gün istihdamdaysa (çıkış günü dahil, sonrası hayır)
  /// - Haftalık: haftada çıkış gününe kadar en az bir gün varsa
  /// - Aylık: çıkış yaptığı ay (veya çalıştığı ay) günlerinden en az biri varsa
  bool wasEmployedInPeriod(Iterable<String> dates) =>
      dates.any(isActiveOn);

  Person copyWith({
    String? id,
    String? projectId,
    String? name,
    String? profession,
    String? phone,
    String? company,
    String? team,
    String? address,
    String? tc,
    String? iban,
    String? bankName,
    String? hireDate,
    String? leaveDate,
    bool? active,
  }) {
    return Person(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      profession: profession ?? this.profession,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      team: team ?? this.team,
      address: address ?? this.address,
      tc: tc ?? this.tc,
      iban: iban ?? this.iban,
      bankName: bankName ?? this.bankName,
      hireDate: hireDate ?? this.hireDate,
      leaveDate: leaveDate ?? this.leaveDate,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'projectId': projectId,
        'name': name,
        'profession': profession,
        'phone': phone,
        'company': company,
        'team': team,
        'address': address,
        'tc': tc,
        'iban': iban,
        'bankName': bankName,
        'hireDate': hireDate,
        'leaveDate': leaveDate,
        'active': active,
      };

  factory Person.fromJson(Map<String, dynamic> json) => Person(
        id: json['id'] as String,
        projectId: json['projectId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        profession: json['profession'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        company: json['company'] as String? ?? '',
        team: json['team'] as String? ?? '',
        address: json['address'] as String? ?? '',
        tc: json['tc'] as String? ?? '',
        iban: json['iban'] as String? ?? '',
        bankName: json['bankName'] as String? ?? '',
        hireDate: json['hireDate'] as String? ?? '',
        leaveDate: json['leaveDate'] as String? ?? '',
        active: json['active'] as bool? ?? true,
      );

  @override
  List<Object?> get props => [
        id,
        projectId,
        name,
        profession,
        phone,
        company,
        team,
        address,
        tc,
        iban,
        bankName,
        hireDate,
        leaveDate,
        active,
      ];
}
