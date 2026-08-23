class TahvilRecord {
  const TahvilRecord({
    required this.id,
    required this.createdAt,
    required this.basis,
    required this.summary,
    required this.detail,
    required this.isAllowed,
    this.sourceLine,
    this.targetLine,
    this.sourceAs,
    this.targetAs,
    this.asUnit,
  });

  final String id;
  final DateTime createdAt;
  final String basis;
  final String summary;
  final String detail;
  final bool isAllowed;
  final String? sourceLine;
  final String? targetLine;
  final double? sourceAs;
  final double? targetAs;
  final String? asUnit;

  bool get hasStructuredDisplay =>
      sourceLine != null &&
      targetLine != null &&
      sourceAs != null &&
      targetAs != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'basis': basis,
        'summary': summary,
        'detail': detail,
        'isAllowed': isAllowed,
        if (sourceLine != null) 'sourceLine': sourceLine,
        if (targetLine != null) 'targetLine': targetLine,
        if (sourceAs != null) 'sourceAs': sourceAs,
        if (targetAs != null) 'targetAs': targetAs,
        if (asUnit != null) 'asUnit': asUnit,
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
      sourceLine: json['sourceLine'] as String?,
      targetLine: json['targetLine'] as String?,
      sourceAs: (json['sourceAs'] as num?)?.toDouble(),
      targetAs: (json['targetAs'] as num?)?.toDouble(),
      asUnit: json['asUnit'] as String?,
    );
  }
}
