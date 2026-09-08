import 'package:intl/intl.dart';

import 'kasa_hareket.dart';
import 'money_format.dart';

/// CSV dışa aktarım (Excel uyumlu TR ayırıcılar).
abstract final class CsvExport {
  static final _date = DateFormat('dd.MM.yyyy');

  static String hareketlerToCsv(Iterable<KasaHareket> hareketler) {
    final buf = StringBuffer();
    buf.writeln(
      'Tarih;Tedarikçi;Açıklama;Gelir;Gider;Ödeme Şekli;Belge Türü;Şantiye',
    );
    for (final h in hareketler) {
      buf.writeln([
        _date.format(h.tarih),
        _csv(h.tedarikci),
        _csv(h.aciklama),
        h.gelir != null ? MoneyFormat.format(h.gelir!) : '',
        h.gider != null ? MoneyFormat.format(h.gider!) : '',
        _csv(h.odemeSekli),
        _csv(h.belgeTuru),
        _csv(h.santiye),
      ].join(';'));
    }
    return buf.toString();
  }

  static String _csv(String value) {
    final v = value.replaceAll('"', '""');
    if (v.contains(';') || v.contains('"') || v.contains('\n')) {
      return '"$v"';
    }
    return v;
  }
}
