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

class ImalatSubWork {
  const ImalatSubWork({
    required this.id,
    required this.name,
    this.note = '',
    this.lines = const [],
  });

  final String id;
  final String name;
  final String note;
  final List<DiameterLine> lines;

  double get planned => lines.fold(0, (sum, line) => sum + line.planned);

  ImalatSubWork copyWith({
    String? id,
    String? name,
    String? note,
    List<DiameterLine>? lines,
  }) {
    return ImalatSubWork(
      id: id ?? this.id,
      name: name ?? this.name,
      note: note ?? this.note,
      lines: lines ?? this.lines,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'note': note,
        'lines': lines.map((line) => line.toJson()).toList(),
      };

  factory ImalatSubWork.fromJson(Map<dynamic, dynamic> json) {
    return ImalatSubWork(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      note: json['note'] as String? ?? '',
      lines: (json['lines'] as List<dynamic>? ?? const [])
          .map((line) => DiameterLine.fromJson(line as Map<dynamic, dynamic>))
          .toList(),
    );
  }
}

class ImalatBlock {
  const ImalatBlock({
    required this.id,
    required this.code,
    required this.name,
    this.items = const [],
  });

  final String id;
  final String code;
  final String name;
  final List<ImalatSubWork> items;

  double get planned => items.fold(0, (sum, item) => sum + item.planned);

  ImalatBlock copyWith({
    String? id,
    String? code,
    String? name,
    List<ImalatSubWork>? items,
  }) {
    return ImalatBlock(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'items': items.map((item) => item.toJson()).toList(),
      };

  factory ImalatBlock.fromJson(Map<dynamic, dynamic> json) {
    return ImalatBlock(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((item) => ImalatSubWork.fromJson(item as Map<dynamic, dynamic>))
          .toList(),
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
    this.blocks = const [],
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
  final List<ImalatBlock> blocks;

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
    List<ImalatBlock>? blocks,
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
      blocks: blocks ?? this.blocks,
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
        'blocks': blocks.map((block) => block.toJson()).toList(),
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
      blocks: (json['blocks'] as List<dynamic>? ?? const [])
          .map((block) => ImalatBlock.fromJson(block as Map<dynamic, dynamic>))
          .toList(),
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
