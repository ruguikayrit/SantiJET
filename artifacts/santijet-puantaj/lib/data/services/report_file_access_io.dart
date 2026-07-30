import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

Future<void> downloadBytesFile({
  required String fileName,
  required List<int> bytes,
  required String mimeType,
  String? shareText,
}) async {
  await Share.shareXFiles(
    [
      XFile.fromData(
        Uint8List.fromList(bytes),
        name: fileName,
        mimeType: mimeType,
      ),
    ],
    text: shareText ?? fileName,
  );
}
