class AppSettings {
  AppSettings({
    this.themeMode = 'system',
    this.weightUnit = 'kg',
    this.language = 'tr',
    this.companyName = 'ABC İnşaat A.Ş.',
    this.taxNo = '1234567890',
    this.address = 'İstanbul, Türkiye',
    this.contactEmail = 'info@abcinsaat.com',
    this.contactPhone = '+90 212 000 00 00',
    this.projectName = 'ABC İnşaat — Blok A',
    this.projectCode = 'YTFC2T377X',
    this.projectLocation = 'İstanbul',
    this.projectStartDate,
    this.projectEndDate,
    this.projectProgress = 72,
    this.notifyStock = true,
    this.notifyOrders = true,
    this.notifyDeliveries = true,
    this.notifyReports = false,
    this.notifyAnalysis = true,
    this.notifyCritical = true,
    this.profileName = '',
    this.profileProfession = 'Şantiye Şefi',
  });

  final String themeMode;
  final String weightUnit;
  final String language;
  final String companyName;
  final String taxNo;
  final String address;
  final String contactEmail;
  final String contactPhone;
  final String projectName;
  final String projectCode;
  final String projectLocation;
  final DateTime? projectStartDate;
  final DateTime? projectEndDate;
  final double projectProgress;
  final bool notifyStock;
  final bool notifyOrders;
  final bool notifyDeliveries;
  final bool notifyReports;
  final bool notifyAnalysis;
  final bool notifyCritical;
  final String profileName;
  final String profileProfession;

  AppSettings copyWith({
    String? themeMode,
    String? weightUnit,
    String? language,
    String? companyName,
    String? taxNo,
    String? address,
    String? contactEmail,
    String? contactPhone,
    String? projectName,
    String? projectCode,
    String? projectLocation,
    DateTime? projectStartDate,
    DateTime? projectEndDate,
    double? projectProgress,
    bool? notifyStock,
    bool? notifyOrders,
    bool? notifyDeliveries,
    bool? notifyReports,
    bool? notifyAnalysis,
    bool? notifyCritical,
    String? profileName,
    String? profileProfession,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      weightUnit: weightUnit ?? this.weightUnit,
      language: language ?? this.language,
      companyName: companyName ?? this.companyName,
      taxNo: taxNo ?? this.taxNo,
      address: address ?? this.address,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      projectName: projectName ?? this.projectName,
      projectCode: projectCode ?? this.projectCode,
      projectLocation: projectLocation ?? this.projectLocation,
      projectStartDate: projectStartDate ?? this.projectStartDate,
      projectEndDate: projectEndDate ?? this.projectEndDate,
      projectProgress: projectProgress ?? this.projectProgress,
      notifyStock: notifyStock ?? this.notifyStock,
      notifyOrders: notifyOrders ?? this.notifyOrders,
      notifyDeliveries: notifyDeliveries ?? this.notifyDeliveries,
      notifyReports: notifyReports ?? this.notifyReports,
      notifyAnalysis: notifyAnalysis ?? this.notifyAnalysis,
      notifyCritical: notifyCritical ?? this.notifyCritical,
      profileName: profileName ?? this.profileName,
      profileProfession: profileProfession ?? this.profileProfession,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode,
        'weightUnit': weightUnit,
        'language': language,
        'companyName': companyName,
        'taxNo': taxNo,
        'address': address,
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
        'projectName': projectName,
        'projectCode': projectCode,
        'projectLocation': projectLocation,
        'projectStartDate': projectStartDate?.toIso8601String(),
        'projectEndDate': projectEndDate?.toIso8601String(),
        'projectProgress': projectProgress,
        'notifyStock': notifyStock,
        'notifyOrders': notifyOrders,
        'notifyDeliveries': notifyDeliveries,
        'notifyReports': notifyReports,
        'notifyAnalysis': notifyAnalysis,
        'notifyCritical': notifyCritical,
        'profileName': profileName,
        'profileProfession': profileProfession,
      };

  factory AppSettings.fromJson(Map<dynamic, dynamic> json) {
    return AppSettings(
      themeMode: json['themeMode'] as String? ?? 'system',
      weightUnit: json['weightUnit'] as String? ?? 'kg',
      language: json['language'] as String? ?? 'tr',
      companyName: json['companyName'] as String? ?? '',
      taxNo: json['taxNo'] as String? ?? '',
      address: json['address'] as String? ?? '',
      contactEmail: json['contactEmail'] as String? ?? '',
      contactPhone: json['contactPhone'] as String? ?? '',
      projectName: json['projectName'] as String? ?? '',
      projectCode: json['projectCode'] as String? ?? '',
      projectLocation: json['projectLocation'] as String? ?? '',
      projectStartDate: json['projectStartDate'] != null
          ? DateTime.tryParse(json['projectStartDate'] as String)
          : null,
      projectEndDate: json['projectEndDate'] != null
          ? DateTime.tryParse(json['projectEndDate'] as String)
          : null,
      projectProgress: (json['projectProgress'] as num?)?.toDouble() ?? 0,
      notifyStock: json['notifyStock'] as bool? ?? true,
      notifyOrders: json['notifyOrders'] as bool? ?? true,
      notifyDeliveries: json['notifyDeliveries'] as bool? ?? true,
      notifyReports: json['notifyReports'] as bool? ?? false,
      notifyAnalysis: json['notifyAnalysis'] as bool? ?? true,
      notifyCritical: json['notifyCritical'] as bool? ?? true,
      profileName: json['profileName'] as String? ?? '',
      profileProfession: json['profileProfession'] as String? ?? 'Şantiye Şefi',
    );
  }
}
