// Tek seferlik araç — ek paket bağımlılığı yok (yalnızca dart:io/dart:convert).
// Açık temadaki dolu (solid) ŞANTİJET wordmark'ını (siyah + mavi) koyu tema
// için beyaz + mavi dolu sürüme çevirir: AYNI tipografi, sadece renk.
// Çalıştır: dart run tool/recolor_wordmark.dart
import 'dart:io';
import 'dart:typed_data';

const _pngSignature = [137, 80, 78, 71, 13, 10, 26, 10];

class _Chunk {
  _Chunk(this.type, this.data);
  final String type;
  final Uint8List data;
}

List<_Chunk> _readChunks(Uint8List bytes) {
  final chunks = <_Chunk>[];
  var offset = 8;
  while (offset < bytes.length) {
    final length = ByteData.sublistView(bytes, offset, offset + 4).getUint32(0);
    final type = String.fromCharCodes(bytes, offset + 4, offset + 8);
    final dataStart = offset + 8;
    final data = Uint8List.sublistView(bytes, dataStart, dataStart + length);
    chunks.add(_Chunk(type, data));
    offset = dataStart + length + 4; // +4 CRC
    if (type == 'IEND') break;
  }
  return chunks;
}

final _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? (0xEDB88320 ^ (c >> 1)) : (c >> 1);
  }
  return c;
});

int _crc32(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}

Uint8List _buildChunk(String type, Uint8List data) {
  final typeBytes = type.codeUnits;
  final out = BytesBuilder();
  final lenBytes = ByteData(4)..setUint32(0, data.length);
  out.add(lenBytes.buffer.asUint8List());
  out.add(typeBytes);
  out.add(data);
  final crc = _crc32([...typeBytes, ...data]);
  final crcBytes = ByteData(4)..setUint32(0, crc);
  out.add(crcBytes.buffer.asUint8List());
  return out.toBytes();
}

int _paeth(int a, int b, int c) {
  final p = a + b - c;
  final pa = (p - a).abs();
  final pb = (p - b).abs();
  final pc = (p - c).abs();
  if (pa <= pb && pa <= pc) return a;
  if (pb <= pc) return b;
  return c;
}

void main() {
  const srcPath = 'assets/images/splash_wordmark_light.png';
  const outPath = 'assets/images/splash_wordmark.png';

  final bytes = File(srcPath).readAsBytesSync();
  for (var i = 0; i < 8; i++) {
    if (bytes[i] != _pngSignature[i]) {
      stderr.writeln('Geçersiz PNG imzası: $srcPath');
      exit(1);
    }
  }

  final chunks = _readChunks(bytes);
  final ihdr = chunks.firstWhere((c) => c.type == 'IHDR');
  final width = ByteData.sublistView(ihdr.data, 0, 4).getUint32(0);
  final height = ByteData.sublistView(ihdr.data, 4, 8).getUint32(0);
  final bitDepth = ihdr.data[8];
  final colorType = ihdr.data[9];
  final interlace = ihdr.data[12];

  if (bitDepth != 8 || colorType != 6 || interlace != 0) {
    stderr.writeln(
      'Beklenmeyen PNG biçimi: bitDepth=$bitDepth colorType=$colorType interlace=$interlace '
      '(bu araç yalnızca 8-bit RGBA, interlace olmayan PNG bekler)',
    );
    exit(1);
  }

  final idatBytes = BytesBuilder();
  for (final c in chunks.where((c) => c.type == 'IDAT')) {
    idatBytes.add(c.data);
  }
  final raw = ZLibCodec().decode(idatBytes.toBytes());

  const bpp = 4; // RGBA
  final stride = width * bpp;
  final pixels = Uint8List(height * stride);

  var pos = 0;
  for (var y = 0; y < height; y++) {
    final filterType = raw[pos];
    pos += 1;
    final rowStart = y * stride;
    final prevRowStart = (y - 1) * stride;
    for (var x = 0; x < stride; x++) {
      final rawByte = raw[pos + x];
      final a = x >= bpp ? pixels[rowStart + x - bpp] : 0;
      final b = y > 0 ? pixels[prevRowStart + x] : 0;
      final c = (y > 0 && x >= bpp) ? pixels[prevRowStart + x - bpp] : 0;
      int value;
      switch (filterType) {
        case 0:
          value = rawByte;
        case 1:
          value = (rawByte + a) & 0xFF;
        case 2:
          value = (rawByte + b) & 0xFF;
        case 3:
          value = (rawByte + ((a + b) >> 1)) & 0xFF;
        case 4:
          value = (rawByte + _paeth(a, b, c)) & 0xFF;
        default:
          stderr.writeln('Bilinmeyen PNG filtre tipi: $filterType');
          exit(1);
      }
      pixels[rowStart + x] = value;
    }
    pos += stride;
  }

  // —— Recolor: siyah "ŞANTİ" -> beyaz dolu; mavi "JET" -> marka mavisi ——
  var inkCount = 0, blueCount = 0, transparentCount = 0;
  for (var y = 0; y < height; y++) {
    final rowStart = y * stride;
    for (var x = 0; x < width; x++) {
      final i = rowStart + x * bpp;
      final r = pixels[i];
      final g = pixels[i + 1];
      final b = pixels[i + 2];
      final a = pixels[i + 3];
      if (a == 0) {
        transparentCount++;
        continue;
      }
      final isBlue = b > r + 30 && b > g + 30;
      if (isBlue) {
        pixels[i] = 37;
        pixels[i + 1] = 99;
        pixels[i + 2] = 235;
        blueCount++;
      } else {
        pixels[i] = 255;
        pixels[i + 1] = 255;
        pixels[i + 2] = 255;
        inkCount++;
      }
    }
  }

  // —— Re-encode: filter type 0 (None) her satır için, sonra zlib deflate ——
  final filtered = Uint8List(height * (stride + 1));
  for (var y = 0; y < height; y++) {
    final srcOffset = y * stride;
    final dstOffset = y * (stride + 1);
    filtered[dstOffset] = 0; // filter: None
    filtered.setRange(dstOffset + 1, dstOffset + 1 + stride, pixels, srcOffset);
  }
  final compressed = ZLibCodec(level: 9).encode(filtered);

  final ihdrOut = Uint8List(13);
  final ihdrData = ByteData.sublistView(ihdrOut);
  ihdrData.setUint32(0, width);
  ihdrData.setUint32(4, height);
  ihdrOut[8] = 8; // bit depth
  ihdrOut[9] = 6; // color type RGBA
  ihdrOut[10] = 0;
  ihdrOut[11] = 0;
  ihdrOut[12] = 0;

  final out = BytesBuilder();
  out.add(_pngSignature);
  out.add(_buildChunk('IHDR', ihdrOut));
  out.add(_buildChunk('IDAT', Uint8List.fromList(compressed)));
  out.add(_buildChunk('IEND', Uint8List(0)));

  File(outPath).writeAsBytesSync(out.toBytes());
  stdout.writeln(
    'Yazıldı: $outPath ($width x $height) — ink=$inkCount blue=$blueCount transparent=$transparentCount',
  );
}
