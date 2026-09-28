/// Tek şantiye kimliği. Modül alanları (logo, WhatsApp, owner) burada yoktur.
class Project {
  const Project({
    required this.id,
    required this.name,
    this.code = '',
    this.company = '',
  });

  final String id;
  final String code;
  final String name;
  final String company;
}
