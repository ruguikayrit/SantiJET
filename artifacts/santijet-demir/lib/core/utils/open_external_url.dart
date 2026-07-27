import 'package:flutter/foundation.dart';
import 'package:santijet_demir/core/config/santijet_store_links.dart';
import 'package:url_launcher/url_launcher.dart';

/// Harici URL / mağaza sayfası açar.
Future<void> openExternalUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// ŞantiJET Puantaj mağaza indirme sayfasını açar.
Future<void> openPuantajStorePage() async {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    final market = Uri.parse(SantijetStoreLinks.puantajPlayMarket);
    if (await canLaunchUrl(market)) {
      final ok = await launchUrl(market, mode: LaunchMode.externalApplication);
      if (ok) return;
    }
  }
  await openExternalUrl(SantijetStoreLinks.puantajDownloadUrl());
}
