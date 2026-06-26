/// CAD metinlerini demir etiketi okumadan önce normalize eder.
String preprocessCadText(String raw) {
  var text = raw.trim();
  if (text.isEmpty) return text;

  // MTEXT biçim kodları: {...;gerçek metin} veya |b0|i0;metin
  if (text.contains(';')) {
    final afterSemicolon = text.split(';').last.trim();
    if (afterSemicolon.isNotEmpty) {
      text = afterSemicolon;
    }
  }

  text = text
      .replaceAll('%%c', 'Ø')
      .replaceAll('%%C', 'Ø')
      .replaceAll('%%d', '°')
      .replaceAll('%%D', '°')
      .replaceAll(RegExp(r'[{}]'), '')
      .replaceAll(RegExp(r'^\|[\w|]+'), '')
      .trim();

  return text;
}
