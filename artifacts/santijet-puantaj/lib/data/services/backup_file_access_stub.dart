import 'dart:convert';

Future<void> downloadJsonFile({
  required String fileName,
  required List<int> bytes,
}) async {
  throw UnsupportedError('Dosya indirme bu platformda desteklenmiyor');
}

Future<String?> pickJsonText() async {
  throw UnsupportedError('Dosya seçimi bu platformda desteklenmiyor');
}
