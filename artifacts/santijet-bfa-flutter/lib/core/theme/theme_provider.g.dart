// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Aktif tema modu (sistem/açık/koyu).
///
/// NOT (Faz 2 / Faz 12): React Native BFA 6 isimli tema sunar ve tercihi
/// AsyncStorage'da saklar. Burada önce ThemeMode iskeleti kurulmuştur; tema
/// kimliği bazlı kalıcılık Faz 12 (Ayarlar) ile eklenecektir.

@ProviderFor(AppThemeMode)
final appThemeModeProvider = AppThemeModeProvider._();

/// Aktif tema modu (sistem/açık/koyu).
///
/// NOT (Faz 2 / Faz 12): React Native BFA 6 isimli tema sunar ve tercihi
/// AsyncStorage'da saklar. Burada önce ThemeMode iskeleti kurulmuştur; tema
/// kimliği bazlı kalıcılık Faz 12 (Ayarlar) ile eklenecektir.
final class AppThemeModeProvider
    extends $NotifierProvider<AppThemeMode, ThemeMode> {
  /// Aktif tema modu (sistem/açık/koyu).
  ///
  /// NOT (Faz 2 / Faz 12): React Native BFA 6 isimli tema sunar ve tercihi
  /// AsyncStorage'da saklar. Burada önce ThemeMode iskeleti kurulmuştur; tema
  /// kimliği bazlı kalıcılık Faz 12 (Ayarlar) ile eklenecektir.
  AppThemeModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appThemeModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appThemeModeHash();

  @$internal
  @override
  AppThemeMode create() => AppThemeMode();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ThemeMode>(value),
    );
  }
}

String _$appThemeModeHash() => r'9848457ce47534f544ca2fb4dd507f1d7df6a419';

/// Aktif tema modu (sistem/açık/koyu).
///
/// NOT (Faz 2 / Faz 12): React Native BFA 6 isimli tema sunar ve tercihi
/// AsyncStorage'da saklar. Burada önce ThemeMode iskeleti kurulmuştur; tema
/// kimliği bazlı kalıcılık Faz 12 (Ayarlar) ile eklenecektir.

abstract class _$AppThemeMode extends $Notifier<ThemeMode> {
  ThemeMode build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ThemeMode, ThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ThemeMode, ThemeMode>,
              ThemeMode,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
