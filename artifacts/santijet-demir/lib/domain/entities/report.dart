class ReportCategory {
  const ReportCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.iconName,
    required this.colorValue,
    required this.format,
  });

  final String id;
  final String title;
  final String subtitle;
  final String iconName;
  final int colorValue;
  final String format;
}

class ReportItem {
  const ReportItem({
    required this.id,
    required this.title,
    required this.category,
    required this.format,
    required this.size,
    required this.date,
    required this.generatedBy,
  });

  final String id;
  final String title;
  final String category;
  final String format;
  final String size;
  final DateTime date;
  final String generatedBy;
}
