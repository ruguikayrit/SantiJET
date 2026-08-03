import 'package:equatable/equatable.dart';

/// Uygulama geneli firma bilgileri (Demir `AppSettings` firma alanlarıyla hizalı).
class CompanyInfo extends Equatable {
  const CompanyInfo({
    this.name = '',
    this.taxNo = '',
    this.address = '',
    this.email = '',
    this.phone = '',
  });

  final String name;
  final String taxNo;
  final String address;
  final String email;
  final String phone;

  bool get isEmpty =>
      name.trim().isEmpty &&
      taxNo.trim().isEmpty &&
      address.trim().isEmpty &&
      email.trim().isEmpty &&
      phone.trim().isEmpty;

  CompanyInfo copyWith({
    String? name,
    String? taxNo,
    String? address,
    String? email,
    String? phone,
  }) {
    return CompanyInfo(
      name: name ?? this.name,
      taxNo: taxNo ?? this.taxNo,
      address: address ?? this.address,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'taxNo': taxNo,
        'address': address,
        'email': email,
        'phone': phone,
      };

  factory CompanyInfo.fromJson(Map<String, dynamic> json) {
    return CompanyInfo(
      name: json['name'] as String? ?? '',
      taxNo: json['taxNo'] as String? ?? '',
      address: json['address'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [name, taxNo, address, email, phone];
}
