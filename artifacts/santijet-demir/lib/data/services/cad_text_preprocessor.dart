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
      // IdeCAD / Türkçe pafta çap sembolleri
      .replaceAll('Φ', 'Ø')
      .replaceAll('φ', 'Ø')
      .replaceAll('∅', 'Ø')
      .replaceAll('⌀', 'Ø')
      .replaceAll(RegExp(r'[{}]'), '')
      .replaceAll(RegExp(r'^\|[\w|]+'), '')
      .trim();

  // "15 Ø 10" / "15Φ 10" → "15Ø10" (boşlukları çap etrafında sıkıştır)
  text = text.replaceAllMapped(
    RegExp(r'(\d)\s*[ØΦφ∅⌀]\s*(\d)'),
    (m) => '${m[1]}Ø${m[2]}',
  );

  return text;
}
