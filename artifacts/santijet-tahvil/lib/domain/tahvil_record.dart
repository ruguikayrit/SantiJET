class TahvilRecord {
  const TahvilRecord({
    required this.id,
    required this.createdAt,
    required this.basis,
    required this.summary,
    required this.detail,
    required this.isAllowed,
  });

  final String id;
  final DateTime createdAt;
  final String basis;
  final String summary;
  final String detail;
  final bool isAllowed;

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'basis': basis,
        'summary': summary,
        'detail': detail,
        'isAllowed': isAllowed,
      };

  factory TahvilRecord.fromJson(Map<dynamic, dynamic> json) {
    return TahvilRecord(
      id: json['id'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      basis: json['basis'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
      isAllowed: json['isAllowed'] as bool? ?? false,
    );
  }
}
