import 'dart:convert';

import 'package:crypto/crypto.dart';

/// PIN hash — düz metin depolanmaz.
abstract final class PinHasher {
  static String hash(String pin) {
    final bytes = utf8.encode(pin.trim());
    return sha256.convert(bytes).toString();
  }

  static bool verify(String pin, String storedHash) {
    return hash(pin) == storedHash;
  }
}
