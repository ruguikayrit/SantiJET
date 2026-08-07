/// Türkçe başlık biçimi: her kelimenin ilk harfi büyük, kalanı küçük.
///
/// Büyük harfle girilmiş (`İSA ALKAN`) değerler `İsa Alkan` olur.
/// Boşluk, `/`, `-` ve `·` ayraçları korunur.
String titleCaseTr(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return trimmed;

  return trimmed.splitMapJoin(
    RegExp(r'([\s/\-·]+)'),
    onMatch: (m) => m.group(0)!,
    onNonMatch: (part) => part.isEmpty ? part : _titleWordTr(part),
  );
}

String _titleWordTr(String word) {
  if (word.isEmpty) return word;
  final lower = _lowerTr(word);
  final runes = lower.runes.toList();
  if (runes.isEmpty) return lower;
  final first = String.fromCharCode(runes.first);
  final rest = String.fromCharCodes(runes.skip(1));
  return '${_upperTr(first)}$rest';
}

String _lowerTr(String s) {
  final b = StringBuffer();
  for (final unit in s.runes) {
    final c = String.fromCharCode(unit);
    switch (c) {
      case 'I':
        b.write('ı');
      case 'İ':
        b.write('i');
      case 'Ğ':
        b.write('ğ');
      case 'Ü':
        b.write('ü');
      case 'Ş':
        b.write('ş');
      case 'Ö':
        b.write('ö');
      case 'Ç':
        b.write('ç');
      default:
        b.write(c.toLowerCase());
    }
  }
  return b.toString();
}

String _upperTr(String c) {
  switch (c) {
    case 'i':
      return 'İ';
    case 'ı':
      return 'I';
    case 'ğ':
      return 'Ğ';
    case 'ü':
      return 'Ü';
    case 'ş':
      return 'Ş';
    case 'ö':
      return 'Ö';
    case 'ç':
      return 'Ç';
    default:
      return c.toUpperCase();
  }
}
