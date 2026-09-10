import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../data/program_repository.dart';

const lifetimeProductId = 'santijet_is_programi_lifetime';

class LicenseState {
  const LicenseState({
    this.licensed = false,
    this.storeAvailable = false,
    this.loading = false,
    this.product,
    this.message,
  });

  final bool licensed;
  final bool storeAvailable;
  final bool loading;
  final ProductDetails? product;
  final String? message;

  LicenseState copyWith({
    bool? licensed,
    bool? storeAvailable,
    bool? loading,
    ProductDetails? product,
    String? message,
  }) => LicenseState(
    licensed: licensed ?? this.licensed,
    storeAvailable: storeAvailable ?? this.storeAvailable,
    loading: loading ?? this.loading,
    product: product ?? this.product,
    message: message,
  );
}

final licenseProvider = NotifierProvider<LicenseController, LicenseState>(
  LicenseController.new,
);

class LicenseController extends Notifier<LicenseState> {
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final _iap = InAppPurchase.instance;

  Box<dynamic> get _box => Hive.box<dynamic>(licenseBoxName);

  @override
  LicenseState build() {
    ref.onDispose(() => _subscription?.cancel());
    final licensed = _box.get('lifetime', defaultValue: false) as bool;
    Future<void>.microtask(initialize);
    return LicenseState(licensed: licensed);
  }

  Future<void> initialize() async {
    try {
      state = state.copyWith(loading: true);
      final available = await _iap.isAvailable();
      if (!available) {
        state = state.copyWith(
          loading: false,
          storeAvailable: false,
          message: 'Mağaza bu cihazda kullanılamıyor.',
        );
        return;
      }
      _subscription ??= _iap.purchaseStream.listen(_handlePurchases);
      final response = await _iap.queryProductDetails({lifetimeProductId});
      state = state.copyWith(
        loading: false,
        storeAvailable: true,
        product: response.productDetails.firstOrNull,
        message: response.notFoundIDs.isEmpty
            ? null
            : 'Lisans ürünü mağazada henüz yayınlanmamış.',
      );
    } catch (_) {
      state = state.copyWith(
        loading: false,
        storeAvailable: false,
        message: 'Mağaza bu platformda desteklenmiyor.',
      );
    }
  }

  Future<void> buy() async {
    final product = state.product;
    if (product == null) return;
    state = state.copyWith(loading: true);
    await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
  }

  Future<void> restore() => _iap.restorePurchases();

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != lifetimeProductId) continue;
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _box.put('lifetime', true);
        state = state.copyWith(
          licensed: true,
          loading: false,
          message: 'Tek seferlik lisans etkin.',
        );
      } else if (purchase.status == PurchaseStatus.error) {
        state = state.copyWith(
          loading: false,
          message: 'Satın alma tamamlanamadı.',
        );
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }
}
