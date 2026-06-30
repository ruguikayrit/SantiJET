class DiameterLine {
  const DiameterLine({
    required this.diameter,
    required this.planned,
    required this.ordered,
    required this.delivered,
    this.progressPercent = 0,
  });

  final int diameter;
  final double planned;
  final double ordered;
  final double delivered;

  /// Gerçek saha ilerleme oranı — imalat + çap bazında.
  final double progressPercent;

  double get pending => (ordered - delivered).clamp(0, double.infinity);
  double get ratio => planned > 0 ? ordered / planned * 100 : 0;
  double get expectedUsage => planned * progressPercent / 100;

  DiameterLine copyWith({
    int? diameter,
    double? planned,
    double? ordered,
    double? delivered,
    double? progressPercent,
  }) {
    return DiameterLine(
      diameter: diameter ?? this.diameter,
      planned: planned ?? this.planned,
      ordered: ordered ?? this.ordered,
      delivered: delivered ?? this.delivered,
      progressPercent: progressPercent ?? this.progressPercent,
    );
  }

  Map<String, dynamic> toJson() => {
        'diameter': diameter,
        'planned': planned,
        'ordered': ordered,
        'delivered': delivered,
        'progressPercent': progressPercent,
      };

  factory DiameterLine.fromJson(Map<dynamic, dynamic> json) {
    return DiameterLine(
      diameter: (json['diameter'] as num).toInt(),
      planned: (json['planned'] as num).toDouble(),
      ordered: (json['ordered'] as num).toDouble(),
      delivered: (json['delivered'] as num).toDouble(),
      progressPercent: (json['progressPercent'] as num?)?.toDouble() ?? 0,
    );
  }
}

class SurveyImalat {
  const SurveyImalat({
    required this.id,
    required this.name,
    required this.totalTonnage,
    required this.progressPercent,
    required this.diameters,
    required this.diameterLines,
    required this.planned,
    required this.ordered,
    required this.delivered,
    required this.pending,
  });

  final String id;
  final String name;
  final double totalTonnage;
  final double progressPercent;
  final List<int> diameters;
  final List<DiameterLine> diameterLines;
  final double planned;
  final double ordered;
  final double delivered;
  final double pending;

  double get orderProgress => planned > 0 ? ordered / planned * 100 : 0;
  double get deliveryProgress => ordered > 0 ? delivered / ordered * 100 : 0;

  SurveyImalat copyWith({
    String? id,
    String? name,
    double? totalTonnage,
    double? progressPercent,
    List<int>? diameters,
    List<DiameterLine>? diameterLines,
    double? planned,
    double? ordered,
    double? delivered,
    double? pending,
  }) {
    return SurveyImalat(
      id: id ?? this.id,
      name: name ?? this.name,
      totalTonnage: totalTonnage ?? this.totalTonnage,
      progressPercent: progressPercent ?? this.progressPercent,
      diameters: diameters ?? this.diameters,
      diameterLines: diameterLines ?? this.diameterLines,
      planned: planned ?? this.planned,
      ordered: ordered ?? this.ordered,
      delivered: delivered ?? this.delivered,
      pending: pending ?? this.pending,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'totalTonnage': totalTonnage,
        'progressPercent': progressPercent,
        'diameters': diameters,
        'diameterLines': diameterLines.map((line) => line.toJson()).toList(),
        'planned': planned,
        'ordered': ordered,
        'delivered': delivered,
        'pending': pending,
      };

  factory SurveyImalat.fromJson(Map<dynamic, dynamic> json) {
    final lines = (json['diameterLines'] as List<dynamic>? ?? const [])
        .map((line) => DiameterLine.fromJson(line as Map<dynamic, dynamic>))
        .toList();
    return SurveyImalat(
      id: json['id'] as String,
      name: json['name'] as String,
      totalTonnage: (json['totalTonnage'] as num).toDouble(),
      progressPercent: (json['progressPercent'] as num).toDouble(),
      diameters: (json['diameters'] as List<dynamic>? ?? const [])
          .map((value) => (value as num).toInt())
          .toList(),
      diameterLines: lines,
      planned: (json['planned'] as num).toDouble(),
      ordered: (json['ordered'] as num).toDouble(),
      delivered: (json['delivered'] as num).toDouble(),
      pending: (json['pending'] as num).toDouble(),
    );
  }
}

class SurveyProject {
  const SurveyProject({
    required this.projectName,
    required this.date,
    required this.revision,
    required this.imalats,
  });

  final String projectName;
  final DateTime date;
  final String revision;
  final List<SurveyImalat> imalats;

  double get totalPlanned =>
      imalats.fold(0, (sum, i) => sum + i.planned);

  SurveyProject copyWith({
    String? projectName,
    DateTime? date,
    String? revision,
    List<SurveyImalat>? imalats,
  }) {
    return SurveyProject(
      projectName: projectName ?? this.projectName,
      date: date ?? this.date,
      revision: revision ?? this.revision,
      imalats: imalats ?? this.imalats,
    );
  }

  Map<String, dynamic> toJson() => {
        'projectName': projectName,
        'date': date.toIso8601String(),
        'revision': revision,
        'imalats': imalats.map((imalat) => imalat.toJson()).toList(),
      };

  factory SurveyProject.fromJson(Map<dynamic, dynamic> json) {
    return SurveyProject(
      projectName: json['projectName'] as String,
      date: DateTime.parse(json['date'] as String),
      revision: json['revision'] as String,
      imalats: (json['imalats'] as List<dynamic>? ?? const [])
          .map((imalat) => SurveyImalat.fromJson(imalat as Map<dynamic, dynamic>))
          .toList(),
    );
  }
}
