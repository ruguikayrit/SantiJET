// Referans marka PNG'sinden yalnızca ŞANTİJET'i alır (OPERASYON YÖNETİMİ yok),
// siyah zemini saydamlaştırır, koyu tema wordmark asset'ini yazar.
import 'dart:io';
import 'dart:math' as math;
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
    offset = dataStart + length + 4;
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

({int width, int height, Uint8List pixels}) _decodeRgba(String path) {
  final bytes = File(path).readAsBytesSync();
  for (var i = 0; i < 8; i++) {
    if (bytes[i] != _pngSignature[i]) {
      throw StateError('Geçersiz PNG: $path');
    }
  }
  final chunks = _readChunks(bytes);
  final ihdr = chunks.firstWhere((c) => c.type == 'IHDR');
  final width = ByteData.sublistView(ihdr.data, 0, 4).getUint32(0);
  final height = ByteData.sublistView(ihdr.data, 4, 8).getUint32(0);
  final bitDepth = ihdr.data[8];
  final colorType = ihdr.data[9];
  final interlace = ihdr.data[12];
  if (bitDepth != 8 || interlace != 0) {
    throw StateError(
      'Desteklenmeyen PNG: bitDepth=$bitDepth colorType=$colorType interlace=$interlace',
    );
  }

  final idatBytes = BytesBuilder();
  for (final c in chunks.where((c) => c.type == 'IDAT')) {
    idatBytes.add(c.data);
  }
  final raw = ZLibCodec().decode(idatBytes.toBytes());

  late final int bpp;
  switch (colorType) {
    case 2:
      bpp = 3; // RGB
    case 6:
      bpp = 4; // RGBA
    default:
      throw StateError('Desteklenmeyen colorType=$colorType');
  }

  final stride = width * bpp;
  final srcPixels = Uint8List(height * stride);
  var pos = 0;
  for (var y = 0; y < height; y++) {
    final filterType = raw[pos];
    pos += 1;
    final rowStart = y * stride;
    final prevRowStart = (y - 1) * stride;
    for (var x = 0; x < stride; x++) {
      final rawByte = raw[pos + x];
      final a = x >= bpp ? srcPixels[rowStart + x - bpp] : 0;
      final b = y > 0 ? srcPixels[prevRowStart + x] : 0;
      final c = (y > 0 && x >= bpp) ? srcPixels[prevRowStart + x - bpp] : 0;
      final int value = switch (filterType) {
        0 => rawByte,
        1 => (rawByte + a) & 0xFF,
        2 => (rawByte + b) & 0xFF,
        3 => (rawByte + ((a + b) >> 1)) & 0xFF,
        4 => (rawByte + _paeth(a, b, c)) & 0xFF,
        _ => throw StateError('Bilinmeyen filtre: $filterType'),
      };
      srcPixels[rowStart + x] = value;
    }
    pos += stride;
  }

  // Normalize to RGBA.
  final rgba = Uint8List(height * width * 4);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final si = (y * width + x) * bpp;
      final di = (y * width + x) * 4;
      rgba[di] = srcPixels[si];
      rgba[di + 1] = srcPixels[si + 1];
      rgba[di + 2] = srcPixels[si + 2];
      rgba[di + 3] = bpp == 4 ? srcPixels[si + 3] : 255;
    }
  }
  return (width: width, height: height, pixels: rgba);
}

bool _isInk(int r, int g, int b, int a) {
  if (a < 8) return false;
  // Siyah/near-black zemin değil; beyaz veya mavi mürekkep.
  final maxC = math.max(r, math.max(g, b));
  final minC = math.min(r, math.min(g, b));
  if (maxC < 28) return false; // siyah
  // Mavi veya açık gri/beyaz
  final isBlue = b > r + 20 && b > g + 20 && b > 40;
  final isLight = maxC > 140 && (maxC - minC) < 80;
  final isBright = maxC > 180;
  return isBlue || isLight || isBright;
}

void _writePng(String path, int width, int height, Uint8List rgba) {
  const bpp = 4;
  final stride = width * bpp;
  final filtered = Uint8List(height * (stride + 1));
  for (var y = 0; y < height; y++) {
    final srcOffset = y * stride;
    final dstOffset = y * (stride + 1);
    filtered[dstOffset] = 0;
    filtered.setRange(dstOffset + 1, dstOffset + 1 + stride, rgba, srcOffset);
  }
  final compressed = ZLibCodec(level: 9).encode(filtered);

  final ihdrOut = Uint8List(13);
  final ihdrData = ByteData.sublistView(ihdrOut);
  ihdrData.setUint32(0, width);
  ihdrData.setUint32(4, height);
  ihdrOut[8] = 8;
  ihdrOut[9] = 6;

  final out = BytesBuilder();
  out.add(_pngSignature);
  out.add(_buildChunk('IHDR', ihdrOut));
  out.add(_buildChunk('IDAT', Uint8List.fromList(compressed)));
  out.add(_buildChunk('IEND', Uint8List(0)));
  File(path).writeAsBytesSync(out.toBytes());
}

void main(List<String> args) {
  final srcPath = args.isNotEmpty
      ? args[0]
      : r'C:\Users\Pc\.cursor\projects\c-Users-Pc-Desktop-PROJECT-SantiJET\assets\c__Users_Pc_AppData_Roaming_Cursor_User_workspaceStorage_empty-window_images_image-e5b06f5e-a53d-430c-8344-a2796486a70d.png';
  const outPath = 'assets/images/splash_wordmark.png';

  final decoded = _decodeRgba(srcPath);
  final width = decoded.width;
  final height = decoded.height;
  final pixels = decoded.pixels;
  stdout.writeln('Kaynak: $width x $height');

  // Satır bazında mürekkep yoğunluğu — ilk blok = ŞANTİJET, ikinci = tagline.
  final rowInk = List<int>.filled(height, 0);
  for (var y = 0; y < height; y++) {
    var count = 0;
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      if (_isInk(pixels[i], pixels[i + 1], pixels[i + 2], pixels[i + 3])) {
        count++;
      }
    }
    rowInk[y] = count;
  }

  var firstInk = -1;
  var lastInk = -1;
  for (var y = 0; y < height; y++) {
    if (rowInk[y] > 0) {
      if (firstInk < 0) firstInk = y;
      lastInk = y;
    }
  }
  if (firstInk < 0) {
    stderr.writeln('Mürekkep bulunamadı');
    exit(1);
  }

  // İlk boşluk bandı: wordmark ile OPERASYON YÖNETİMİ arası.
  var gapStart = -1;
  var gapEnd = -1;
  for (var y = firstInk; y <= lastInk; y++) {
    if (rowInk[y] == 0) {
      if (gapStart < 0) gapStart = y;
      gapEnd = y;
    } else if (gapStart >= 0) {
      final gapH = gapEnd - gapStart + 1;
      // Anlamlı boşluk: tagline ayrımı (en az ~8px veya wordmark yüksekliğinin %8'i).
      if (gapH >= 8) {
        break;
      }
      gapStart = -1;
      gapEnd = -1;
    }
  }

  final brandBottom = (gapStart > firstInk) ? (gapStart - 1) : lastInk;
  stdout.writeln(
    'Wordmark satırları: $firstInk..$brandBottom '
    '(tagline gap=${gapStart >= 0 ? '$gapStart..$gapEnd' : 'yok'})',
  );

  // Yatay mürekkep sınırları (yalnızca wordmark bandı).
  var minX = width, maxX = -1, minY = height, maxY = -1;
  for (var y = firstInk; y <= brandBottom; y++) {
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      if (_isInk(pixels[i], pixels[i + 1], pixels[i + 2], pixels[i + 3])) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }

  // Açık asset ile benzer nefes payı; tagline bandına asla girme.
  const padX = 12;
  const padY = 18;
  final cropL = math.max(0, minX - padX);
  final cropT = math.max(0, minY - padY);
  final cropR = math.min(width - 1, maxX + padX);
  // Alt kenar: wordmark son satırını aşma (OPERASYON YÖNETİMİ kesilsin).
  final cropB = math.min(brandBottom, maxY + padY);
  final outW = cropR - cropL + 1;
  final outH = cropB - cropT + 1;
  stdout.writeln('Crop: ($cropL,$cropT)-($cropR,$cropB) => $outW x $outH');

  final out = Uint8List(outW * outH * 4);
  var ink = 0, blue = 0, white = 0, clear = 0;
  for (var y = 0; y < outH; y++) {
    for (var x = 0; x < outW; x++) {
      final sx = cropL + x;
      final sy = cropT + y;
      final si = (sy * width + sx) * 4;
      final di = (y * outW + x) * 4;
      final r = pixels[si];
      final g = pixels[si + 1];
      final b = pixels[si + 2];
      final a = pixels[si + 3];

      // Wordmark bandı dışındaki satırları (tagline) asla kopyalama.
      if (sy < firstInk || sy > brandBottom || !_isInk(r, g, b, a)) {
        out[di] = 0;
        out[di + 1] = 0;
        out[di + 2] = 0;
        out[di + 3] = 0;
        clear++;
        continue;
      }

      final isBlue = b > r + 20 && b > g + 20;
      if (isBlue) {
        out[di] = r;
        out[di + 1] = g;
        out[di + 2] = b;
        out[di + 3] = a;
        blue++;
      } else {
        out[di] = 255;
        out[di + 1] = 255;
        out[di + 2] = 255;
        out[di + 3] = a;
        white++;
      }
      ink++;
    }
  }

  _writePng(outPath, outW, outH, out);
  stdout.writeln(
    'Yazıldı: $outPath ($outW x $outH) ink=$ink white=$white blue=$blue clear=$clear',
  );
  stdout.writeln('leftInkPx≈$padX  (metrics için)');
}
