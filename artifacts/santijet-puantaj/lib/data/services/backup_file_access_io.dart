import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

Future<void> downloadJsonFile({
  required String fileName,
  required List<int> bytes,
}) async {
  await Share.shareXFiles(
    [
      XFile.fromData(
        Uint8List.fromList(bytes),
        name: fileName,
        mimeType: 'application/json',
      ),
    ],
    text: 'ŞantiJET Puantaj yedeği',
  );
}

Future<String?> pickJsonText() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['json'],
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;
  final file = result.files.first;
  if (file.bytes != null) return utf8.decode(file.bytes!);
  return null;
}

Uint8List encodeUtf8(String text) => Uint8List.fromList(utf8.encode(text));
