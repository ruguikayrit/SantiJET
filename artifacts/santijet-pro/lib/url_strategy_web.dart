import 'package:flutter_web_plugins/url_strategy.dart';

/// Hash adres, sayfa yenilemesinde yolu korur.
void useHashUrlStrategy() {
  setUrlStrategy(const HashUrlStrategy());
}
