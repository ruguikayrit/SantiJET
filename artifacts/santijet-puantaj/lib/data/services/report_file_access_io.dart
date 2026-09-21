import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

import 'report_bytes_prepare.dart';

Future<void> downloadBytesFile({
  required String fileName,
  required List<int> bytes,
  required String mimeType,
  String? shareText,
}) async {
  final out = await prepareBytesForDownload(bytes: bytes, mimeType: mimeType);
  await Share.shareXFiles(
    [
      XFile.fromData(
        Uint8List.fromList(out),
        name: fileName,
        mimeType: mimeType,
      ),
    ],
    text: shareText ?? fileName,
  );
}
