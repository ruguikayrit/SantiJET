import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_provider.g.dart';

/// Aktif tema modu (sistem/açık/koyu).
///
/// NOT (Faz 2 / Faz 12): React Native BFA 6 isimli tema sunar ve tercihi
/// AsyncStorage'da saklar. Burada önce ThemeMode iskeleti kurulmuştur; tema
/// kimliği bazlı kalıcılık Faz 12 (Ayarlar) ile eklenecektir.
@riverpod
class AppThemeMode extends _$AppThemeMode {
  @override
  ThemeMode build() => ThemeMode.system;

  void set(ThemeMode mode) => state = mode;
}
