import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'pdf_image_optimizer.dart';

/// PDF oluşturulduktan sonra otomatik boyut optimizasyonu.
///
/// - Sayfa rasterization YOK
/// - Metin / vektör / layout değişmez
/// - Gömülü DCTDecode (JPEG) akışlarını aynı WxH ile yeniden sıkıştırır
/// - Optimize daha büyükse orijinal döner
abstract final class PdfOptimizationService {
  /// Ana API — paylaşım / indirmeden hemen önce.
  static Future<Uint8List> optimize(Uint8List original) {
    if (original.length < 32) return Future.value(original);
    return compute(_optimizeIsolate, original);
  }

  /// Senkron (test / zaten isolate içinde).
  static Uint8List optimizeSync(Uint8List original) => _optimizeIsolate(original);

  static Uint8List _optimizeIsolate(Uint8List original) {
    final originalSize = original.length;
    if (!_looksLikePdf(original)) {
      _log(
        originalSize: originalSize,
        optimizedSize: originalSize,
        pages: 0,
        images: 0,
        resized: 0,
        success: false,
        note: 'not a pdf',
      );
      return original;
    }

    final pagesExact = _countPageObjects(original);
    final imagesBefore = _countAsciiToken(original, '/DCTDecode');

    Uint8List candidate;
    try {
      candidate = _recompressDctStreams(original) ?? original;
    } catch (e, st) {
      debugPrint('PdfOptimizationService: $e\n$st');
      candidate = original;
    }

    if (!_looksLikePdf(candidate)) {
      candidate = original;
    }

    final pagesAfter = _countPageObjects(candidate);
    final imagesAfter = _countAsciiToken(candidate, '/DCTDecode');

    if (pagesAfter != pagesExact || imagesAfter != imagesBefore) {
      _log(
        originalSize: originalSize,
        optimizedSize: candidate.length,
        pages: pagesExact,
        images: imagesBefore,
        resized: 0,
        success: false,
        note: 'structure mismatch — kept original',
      );
      return original;
    }

    if (candidate.length >= originalSize) {
      _log(
        originalSize: originalSize,
        optimizedSize: candidate.length,
        pages: pagesExact,
        images: imagesBefore,
        resized: 0,
        success: false,
        note: 'not smaller — kept original',
      );
      return original;
    }

    _log(
      originalSize: originalSize,
      optimizedSize: candidate.length,
      pages: pagesExact,
      images: imagesBefore,
      resized: 0,
      success: true,
    );
    return candidate;
  }

  static void _log({
    required int originalSize,
    required int optimizedSize,
    required int pages,
    required int images,
    required int resized,
    required bool success,
    String note = '',
  }) {
    final oMb = (originalSize / (1024 * 1024)).toStringAsFixed(2);
    final nMb = (optimizedSize / (1024 * 1024)).toStringAsFixed(2);
    final reduction = originalSize == 0
        ? 0.0
        : (100.0 * (originalSize - optimizedSize) / originalSize);
    debugPrint(
      'PDF OPTIMIZATION\n'
      'Original: $oMb MB\n'
      'Optimized: $nMb MB\n'
      'Reduction: ${reduction.toStringAsFixed(1)} %\n'
      'Pages: $pages\n'
      'Images: $images\n'
      'Resized: $resized\n'
      'Downsampled: 0\n'
      'Rasterized Pages: 0\n'
      'Resolution Changed: NO\n'
      'Optimization: ${success ? 'SUCCESS' : 'SKIPPED'}'
      '${note.isEmpty ? '' : ' ($note)'}\n',
    );
  }

  static bool _looksLikePdf(Uint8List bytes) {
    if (bytes.length < 5) return false;
    return bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46; // %PDF
  }

  static int _countAsciiToken(Uint8List bytes, String token) {
    final needle = ascii.encode(token);
    var count = 0;
    var i = 0;
    while (i <= bytes.length - needle.length) {
      var match = true;
      for (var j = 0; j < needle.length; j++) {
        if (bytes[i + j] != needle[j]) {
          match = false;
          break;
        }
      }
      if (match) {
        count++;
        i += needle.length;
      } else {
        i++;
      }
    }
    return count;
  }

  /// `/Type /Page` ama `/Pages` değil.
  static int _countPageObjects(Uint8List bytes) {
    final needle = ascii.encode('/Type /Page');
    var count = 0;
    var i = 0;
    while (i <= bytes.length - needle.length) {
      var match = true;
      for (var j = 0; j < needle.length; j++) {
        if (bytes[i + j] != needle[j]) {
          match = false;
          break;
        }
      }
      if (match) {
        final next = i + needle.length;
        // /Pages ise sonraki harf 's'
        if (next < bytes.length) {
          final c = bytes[next];
          if (c == 0x73 /* s */ ||
              (c >= 0x41 && c <= 0x5A) ||
              (c >= 0x61 && c <= 0x7A)) {
            i += needle.length;
            continue;
          }
        }
        count++;
        i += needle.length;
      } else {
        i++;
      }
    }
    return count;
  }

  static int? _indexOfAscii(Uint8List bytes, String token, [int start = 0]) {
    final needle = ascii.encode(token);
    var i = start;
    while (i <= bytes.length - needle.length) {
      var match = true;
      for (var j = 0; j < needle.length; j++) {
        if (bytes[i + j] != needle[j]) {
          match = false;
          break;
        }
      }
      if (match) return i;
      i++;
    }
    return null;
  }

  static Uint8List? _recompressDctStreams(Uint8List original) {
    final out = Uint8List.fromList(original);
    var changed = false;
    var searchFrom = 0;

    while (true) {
      final filterAt = _indexOfAscii(out, '/DCTDecode', searchFrom);
      if (filterAt == null) break;
      searchFrom = filterAt + 10;

      final streamKey = _indexOfAscii(out, 'stream', filterAt);
      if (streamKey == null || streamKey - filterAt > 800) continue;

      var dataStart = streamKey + 6; // 'stream'
      if (dataStart < out.length && out[dataStart] == 13) dataStart++;
      if (dataStart < out.length && out[dataStart] == 10) dataStart++;

      final endstream = _indexOfAscii(out, 'endstream', dataStart);
      if (endstream == null) continue;

      var jpegEnd = endstream;
      while (jpegEnd > dataStart) {
        final c = out[jpegEnd - 1];
        if (c == 10 || c == 13 || c == 32) {
          jpegEnd--;
        } else {
          break;
        }
      }

      if (jpegEnd - dataStart < 24) continue;
      if (out[dataStart] != 0xFF || out[dataStart + 1] != 0xD8) continue;

      final slotLen = jpegEnd - dataStart;
      final jpegBytes = Uint8List.sublistView(out, dataStart, jpegEnd);

      final decoded = img.decodeImage(jpegBytes);
      if (decoded == null) continue;
      final w = decoded.width;
      final h = decoded.height;

      final recompressed = img.encodeJpg(
        decoded,
        quality: PdfImageOptimizer.jpegQuality,
      );
      if (recompressed.length >= slotLen) continue;

      final check = img.decodeImage(Uint8List.fromList(recompressed));
      if (check == null || check.width != w || check.height != h) continue;

      for (var i = 0; i < recompressed.length; i++) {
        out[dataStart + i] = recompressed[i];
      }
      for (var i = recompressed.length; i < slotLen; i++) {
        out[dataStart + i] = 0x20;
      }

      _patchLengthInPlace(
        out,
        dictSearchStart: math.max(0, filterAt - 400),
        dictSearchEnd: streamKey,
        newLength: recompressed.length,
      );
      changed = true;
    }

    return changed ? out : null;
  }

  static void _patchLengthInPlace(
    Uint8List out, {
    required int dictSearchStart,
    required int dictSearchEnd,
    required int newLength,
  }) {
    final lengthKey = _indexOfAscii(out, '/Length', dictSearchStart);
    if (lengthKey == null || lengthKey >= dictSearchEnd) return;

    var i = lengthKey + '/Length'.length;
    while (i < dictSearchEnd && (out[i] == 32 || out[i] == 9 || out[i] == 10 || out[i] == 13)) {
      i++;
    }
    final numStart = i;
    while (i < dictSearchEnd && out[i] >= 0x30 && out[i] <= 0x39) {
      i++;
    }
    final numEnd = i;
    if (numEnd <= numStart) return;

    final width = numEnd - numStart;
    var newStr = '$newLength';
    if (newStr.length > width) return;
    if (newStr.length < width) {
      newStr = newStr.padLeft(width, ' ');
    }
    for (var k = 0; k < width; k++) {
      out[numStart + k] = newStr.codeUnitAt(k);
    }
  }
}
