/// Ödeme şekli sabitleri (filtre / form).
abstract final class OdemeSekli {
  static const sahsiKart = 'Şahsi K.Kartı';
  static const havale = 'Havale';
  static const nakit = 'Nakit';
  static const sirketKart = 'Şirket K.Kartı';
  static const diger = 'Diğer';

  static const all = <String>[
    sahsiKart,
    havale,
    nakit,
    sirketKart,
    diger,
  ];
}

/// Belge türü sabitleri.
abstract final class BelgeTuru {
  static const fis = 'Fiş';
  static const fatura = 'Fatura';
  static const yok = 'Yok';

  static const all = <String>[fis, fatura, yok];
}
