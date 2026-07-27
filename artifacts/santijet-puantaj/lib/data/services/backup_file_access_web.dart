import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

Future<void> downloadJsonFile({
  required String fileName,
  required List<int> bytes,
}) async {
  final blob = html.Blob([bytes], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

Future<String?> pickJsonText() async {
  final input = html.FileUploadInputElement()
    ..accept = '.json,application/json';
  input.click();
  await input.onChange.first;
  final file = input.files?.first;
  if (file == null) return null;
  final reader = html.FileReader();
  reader.readAsText(file);
  await reader.onLoad.first;
  return reader.result as String?;
}

Uint8List encodeUtf8(String text) => Uint8List.fromList(utf8.encode(text));
