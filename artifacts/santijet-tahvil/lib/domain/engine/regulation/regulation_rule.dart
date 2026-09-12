/// Yönetmelik maddesi — değerler katalogda, motor maddeleri buradan okur.
class RegulationRule {
  const RegulationRule({
    required this.ruleCode,
    required this.standard,
    required this.article,
    required this.description,
  });

  final String ruleCode;
  final String standard;
  final String article;
  final String description;

  String get citation => '$standard $article';
}
