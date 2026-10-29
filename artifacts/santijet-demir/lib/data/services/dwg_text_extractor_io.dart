import 'package:santijet_demir/data/services/cad_text_entity.dart';
import 'package:santijet_demir/data/services/dwg_embedded_extractor.dart';

Future<List<CadTextEntity>> extractDwgTextsWeb(List<int> bytes) {
  throw UnsupportedError('DWG web parser is only available on web.');
}

Future<List<Map<String, dynamic>>> extractDwgTextsEmbedded(List<int> bytes) {
  return DwgEmbeddedExtractor.instance.extract(bytes);
}
