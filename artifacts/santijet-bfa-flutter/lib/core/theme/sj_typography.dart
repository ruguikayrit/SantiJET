import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ŞantiJET tipografi sistemi — Inter ailesi.
///
/// React Native BFA, Inter (400/500/600/700) ağırlıklarını kullanır.
/// Flutter'da `google_fonts` ile aynı aile sağlanır.
class SJTypography {
  const SJTypography._();

  /// Verilen [base] metin temasına Inter ailesini uygular.
  static TextTheme build(TextTheme base) {
    return GoogleFonts.interTextTheme(base);
  }
}
