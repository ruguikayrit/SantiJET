// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Uygulama yönlendiricisi (go_router) — Riverpod ile sağlanır.
///
/// Faz 5'te bottom navigation için `StatefulShellRoute` ve geçiş animasyonları
/// genişletilecektir. Şu an Faz 1 iskelet rotaları tanımlıdır.

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// Uygulama yönlendiricisi (go_router) — Riverpod ile sağlanır.
///
/// Faz 5'te bottom navigation için `StatefulShellRoute` ve geçiş animasyonları
/// genişletilecektir. Şu an Faz 1 iskelet rotaları tanımlıdır.

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// Uygulama yönlendiricisi (go_router) — Riverpod ile sağlanır.
  ///
  /// Faz 5'te bottom navigation için `StatefulShellRoute` ve geçiş animasyonları
  /// genişletilecektir. Şu an Faz 1 iskelet rotaları tanımlıdır.
  AppRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRouterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return appRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$appRouterHash() => r'847a1980e782361639c582eba4a9b3bca4a6f31f';
