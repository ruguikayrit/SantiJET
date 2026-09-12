import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/kasa_hareket.dart';
import '../domain/kasa_rules.dart';

/// Cihazdaki kasa verisinin JSON yedeği.
class KasaJsonSnapshot {
  const KasaJsonSnapshot({
    required this.hareketler,
    required this.santiyeler,
    required this.activeSantiye,
    this.skipped = 0,
  });

  final List<KasaHareket> hareketler;
  final List<String> santiyeler;
  final String activeSantiye;
  final int skipped;
}

/// Hareketler + şantiye listesi + aktif şantiye — JSON dosya.
class KasaJsonBackup {
  static const appId = 'santijet_kasa';
  static const formatVersion = 1;
  static final _stamp = DateFormat('yyyyMMdd_HHmm');

  String encode({
    required List<KasaHareket> hareketler,
    required List<String> santiyeler,
    required String activeSantiye,
    DateTime? now,
  }) {
    final stamp = now ?? DateTime.now();
    return const JsonEncoder.withIndent('  ').convert({
      'app': appId,
      'formatVersion': formatVersion,
      'exportedAt': stamp.toIso8601String(),
      'activeSantiye': activeSantiye,
      'santiyeler': santiyeler,
      'hareketler': hareketler.map((h) => h.toJson()).toList(),
    });
  }

  KasaJsonSnapshot decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return _fromHareketList(decoded);
    }
    if (decoded is! Map) {
      throw StateError('JSON yedeği okunamadı.');
    }
    final app = decoded['app']?.toString();
    if (app != null && app.isNotEmpty && app != appId) {
      throw StateError('Bu dosya ŞantiJET Kasa yedeği değil.');
    }

    final hareketRaw = decoded['hareketler'];
    if (hareketRaw is! List) {
      throw StateError('Yedekte hareket listesi yok.');
    }
    final parsed = _fromHareketList(hareketRaw);

    final santiyeRaw = decoded['santiyeler'];
    var santiyeler = <String>[];
    if (santiyeRaw is List) {
      santiyeler = santiyeRaw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (santiyeler.isEmpty) {
      santiyeler = {
        for (final h in parsed.hareketler)
          if (h.santiye.trim().isNotEmpty) h.santiye.trim(),
      }.toList();
    }

    var active = (decoded['activeSantiye']?.toString() ?? '').trim();
    if (active.isEmpty || !santiyeler.contains(active)) {
      active = santiyeler.isNotEmpty ? santiyeler.first : 'İZMİT/EFSANE';
    }
    if (santiyeler.isEmpty) santiyeler = const ['İZMİT/EFSANE'];

    return KasaJsonSnapshot(
      hareketler: parsed.hareketler,
      santiyeler: santiyeler,
      activeSantiye: active,
      skipped: parsed.skipped,
    );
  }

  KasaJsonSnapshot _fromHareketList(List<dynamic> raw) {
    final out = <KasaHareket>[];
    var skipped = 0;
    for (final item in raw) {
      if (item is! Map) {
        skipped++;
        continue;
      }
      try {
        final h = KasaHareket.fromJson(item);
        if (validateHareket(
              aciklama: h.aciklama,
              gelir: h.gelir,
              gider: h.gider,
            ) !=
            null) {
          skipped++;
          continue;
        }
        out.add(h);
      } catch (_) {
        skipped++;
      }
    }
    return KasaJsonSnapshot(
      hareketler: out,
      santiyeler: const ['İZMİT/EFSANE'],
      activeSantiye: 'İZMİT/EFSANE',
      skipped: skipped,
    );
  }

  Future<void> share({
    required List<KasaHareket> hareketler,
    required List<String> santiyeler,
    required String activeSantiye,
  }) async {
    final json = encode(
      hareketler: hareketler,
      santiyeler: santiyeler,
      activeSantiye: activeSantiye,
    );
    final name = 'santijet_kasa_${_stamp.format(DateTime.now())}.json';
    await Share.shareXFiles(
      [
        XFile.fromData(
          Uint8List.fromList(utf8.encode(json)),
          name: name,
          mimeType: 'application/json',
        ),
      ],
      subject: 'ŞantiJET Kasa — JSON yedek',
      fileNameOverrides: [name],
    );
  }

  Future<KasaJsonSnapshot?> pickAndDecode() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return null;
    final bytes = picked.files.first.bytes;
    if (bytes == null) {
      throw StateError('Dosya okunamadı.');
    }
    return decode(utf8.decode(bytes));
  }
}

final kasaJsonBackup = KasaJsonBackup();
