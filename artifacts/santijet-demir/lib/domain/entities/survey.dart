class DiameterLine {
  const DiameterLine({
    required this.diameter,
    required this.planned,
    required this.ordered,
    required this.delivered,
  });

  final int diameter;
  final double planned;
  final double ordered;
  final double delivered;

  double get pending => (ordered - delivered).clamp(0, double.infinity);
  double get ratio => planned > 0 ? ordered / planned * 100 : 0;
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
}
