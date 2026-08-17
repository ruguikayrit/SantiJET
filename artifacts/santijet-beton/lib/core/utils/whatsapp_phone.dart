/// WhatsApp `wa.me` için numara normalizasyonu.
abstract final class WhatsAppPhone {
  /// `05xx...` / `+90...` → `90xxxxxxxxxx`. Geçersizse null.
  static String? toWaMeDigits(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }
    if (digits.length == 11 && digits.startsWith('0')) {
      digits = '90${digits.substring(1)}';
    } else if (digits.length == 10 && digits.startsWith('5')) {
      digits = '90$digits';
    }
    if (digits.length < 10 || digits.length > 15) return null;
    return digits;
  }

  static Uri chatUri({required String digits, required String text}) {
    return Uri.parse(
      'https://wa.me/$digits?text=${Uri.encodeComponent(text)}',
    );
  }

  /// Geçerli numaraları sırayı koruyarak tekilleştirir.
  static List<String> uniqueDigits(Iterable<String> rawNumbers) {
    return uniqueRecipients(
      rawNumbers.map((raw) => (name: '', number: raw)),
    ).map((e) => e.number).toList();
  }

  /// Geçerli alıcıları sırayı koruyarak tekilleştirir; `number` wa.me rakamıdır.
  static List<({String name, String number})> uniqueRecipients(
    Iterable<({String name, String number})> items,
  ) {
    final seen = <String>{};
    final out = <({String name, String number})>[];
    for (final item in items) {
      final digits = toWaMeDigits(item.number);
      if (digits == null || seen.contains(digits)) continue;
      seen.add(digits);
      out.add((name: item.name.trim(), number: digits));
    }
    return out;
  }
}
