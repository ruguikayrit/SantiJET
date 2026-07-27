/// Puantaj → Demir imalat ilerleme bulut anlık görüntüsü.
///
/// Kayıtlar hesap e-postasına bağlanır; Demir aynı e-posta ile oturum açmış
/// kullanıcı için çeker.
class PuantajImalatProgressItem {
  const PuantajImalatProgressItem({
    required this.imalatName,
    required this.progressPercent,
    this.imalatId = '',
  });

  final String imalatId;
  final String imalatName;
  final double progressPercent;

  factory PuantajImalatProgressItem.fromJson(Map<String, dynamic> json) {
    return PuantajImalatProgressItem(
      imalatId: json['imalat_id'] as String? ??
          json['imalatId'] as String? ??
          '',
      imalatName: (json['imalat_name'] as String? ??
              json['imalatName'] as String? ??
              '')
          .trim(),
      progressPercent: (json['progress_percent'] as num? ??
              json['progressPercent'] as num? ??
              0)
          .toDouble()
          .clamp(0, 100),
    );
  }

  Map<String, dynamic> toJson() => {
        'imalatId': imalatId,
        'imalatName': imalatName,
        'progressPercent': progressPercent,
      };
}

class PuantajProgressSnapshot {
  const PuantajProgressSnapshot({
    required this.accountEmail,
    required this.projectCode,
    required this.updatedAt,
    required this.items,
    this.projectName = '',
    this.source = 'puantaj_cloud',
  });

  final String accountEmail;
  final String projectCode;
  final String projectName;
  final DateTime updatedAt;
  final List<PuantajImalatProgressItem> items;
  final String source;

  factory PuantajProgressSnapshot.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return PuantajProgressSnapshot(
      accountEmail: (json['account_email'] as String? ??
              json['accountEmail'] as String? ??
              '')
          .trim()
          .toLowerCase(),
      projectCode: (json['project_code'] as String? ??
              json['projectCode'] as String? ??
              '')
          .trim(),
      projectName: json['project_name'] as String? ??
          json['projectName'] as String? ??
          '',
      updatedAt: DateTime.tryParse(
            json['updated_at'] as String? ??
                json['updatedAt'] as String? ??
                '',
          ) ??
          DateTime.now(),
      source: json['source'] as String? ?? 'puantaj_cloud',
      items: rawItems
          .whereType<Map>()
          .map(
            (e) => PuantajImalatProgressItem.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .where((e) => e.imalatName.isNotEmpty)
          .toList(),
    );
  }
}

class PuantajProgressImportResult {
  const PuantajProgressImportResult({
    required this.updatedCount,
    required this.unmatchedNames,
    required this.snapshot,
  });

  final int updatedCount;
  final List<String> unmatchedNames;
  final PuantajProgressSnapshot snapshot;
}
