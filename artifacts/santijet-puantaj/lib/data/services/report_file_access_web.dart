import 'dart:html' as html;
import 'dart:typed_data';

Future<void> downloadBytesFile({
  required String fileName,
  required List<int> bytes,
  required String mimeType,
  String? shareText,
}) async {
  final blob = html.Blob([Uint8List.fromList(bytes)], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
