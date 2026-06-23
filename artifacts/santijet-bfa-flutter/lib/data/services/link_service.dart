import 'package:url_launcher/url_launcher.dart';

/// Harici bağlantıları sistem tarayıcısında açar.
class LinkService {
  Future<void> openExternal(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      throw StateError('Bağlantı açılamadı: $url');
    }
  }
}

final linkService = LinkService();
