import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Aktif tema modu (sistem/açık/koyu).
///
/// Demir, tema modunu `appSettingsProvider` üzerinden yönetir. BFA'da Faz 12
/// (Ayarlar) ile Hive tabanlı kalıcı ayar sağlayıcısına bağlanacaktır; şimdilik
/// düz bir StateProvider yeterlidir (codegen kullanılmaz).
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
