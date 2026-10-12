import 'dart:async';
import 'dart:developer' as developer;

import 'package:deneme_takip/ads/billing_config.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Outcome of a user-facing purchase or restore attempt.
enum BillingActionResult {
  success,
  cancelled,
  unavailable,
  productMissing,
  nothingToRestore,
  error,
}

extension BillingActionResultMessage on BillingActionResult {
  String get messageTr {
    switch (this) {
      case BillingActionResult.success:
        return 'Destekçi oldun — reklamlar kapatıldı. Teşekkürler!';
      case BillingActionResult.cancelled:
        return 'Satın alma iptal edildi.';
      case BillingActionResult.unavailable:
        return 'Satın alma şu an kullanılamıyor. Google Play hesabı gerekli.';
      case BillingActionResult.productMissing:
        return 'Ürün bulunamadı. Daha sonra tekrar dene.';
      case BillingActionResult.nothingToRestore:
        return 'Geri yüklenecek satın alma bulunamadı.';
      case BillingActionResult.error:
        return 'Satın alma tamamlanamadı. Lütfen tekrar dene.';
    }
  }
}

/// Google Play Billing wrapper for the one-time Destekçi unlock.
class BillingService {
  BillingService({
    required this.onSupporterUnlocked,
    InAppPurchase? iap,
  }) : _iap = iap ?? InAppPurchase.instance;

  final Future<void> Function() onSupporterUnlocked;
  final InAppPurchase _iap;

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  ProductDetails? _product;
  var _available = false;
  var _initialized = false;
  var _purchaseInFlight = false;
  var _restoreInFlight = false;

  Completer<BillingActionResult>? _actionCompleter;
  var _sawOwnedDuringRestore = false;

  bool get isAvailable => _available;
  ProductDetails? get supporterProduct => _product;

  /// Localized price from Play when loaded; otherwise the UI copy fallback.
  String get supporterPriceLabel => _product?.price ?? '50 ₺';

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb) {
      _available = false;
      return;
    }

    try {
      _available = await _iap.isAvailable();
      if (!_available) {
        developer.log(
          'Play Billing unavailable (emulator/sideload/no Play Store)',
          name: 'BillingService',
        );
        return;
      }

      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdates,
        onError: (Object error, StackTrace stack) {
          developer.log(
            'purchaseStream error: $error',
            name: 'BillingService',
            error: error,
            stackTrace: stack,
          );
          _completeAction(BillingActionResult.error);
        },
      );

      await _queryProduct();
      // Quiet restore: stream unlocks isSupporter if Play reports ownership.
      unawaited(_quietRestore());
    } on Object catch (error, stack) {
      _available = false;
      developer.log(
        'Billing initialize failed: $error',
        name: 'BillingService',
        error: error,
        stackTrace: stack,
      );
    }
  }

  Future<void> _quietRestore() async {
    try {
      await _iap.restorePurchases();
    } on Object catch (error) {
      developer.log(
        'Quiet restore failed: $error',
        name: 'BillingService',
      );
    }
  }

  Future<BillingActionResult> purchaseSupporter() async {
    if (kIsWeb || !_available) return BillingActionResult.unavailable;
    if (_purchaseInFlight || _restoreInFlight) {
      return BillingActionResult.error;
    }

    try {
      if (_product == null) {
        await _queryProduct();
      }
      final product = _product;
      if (product == null) return BillingActionResult.productMissing;

      _purchaseInFlight = true;
      _actionCompleter = Completer<BillingActionResult>();

      final started = await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!started) {
        _purchaseInFlight = false;
        _actionCompleter = null;
        return BillingActionResult.error;
      }

      return await _actionCompleter!.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () => BillingActionResult.error,
      );
    } on Object catch (error, stack) {
      developer.log(
        'purchaseSupporter failed: $error',
        name: 'BillingService',
        error: error,
        stackTrace: stack,
      );
      return BillingActionResult.error;
    } finally {
      _purchaseInFlight = false;
      _actionCompleter = null;
    }
  }

  /// Restores prior non-consumable purchases (Settings / explicit CTA).
  Future<BillingActionResult> restorePurchases() async {
    if (kIsWeb || !_available) return BillingActionResult.unavailable;
    if (_purchaseInFlight || _restoreInFlight) {
      return BillingActionResult.error;
    }

    try {
      _restoreInFlight = true;
      _sawOwnedDuringRestore = false;
      _actionCompleter = Completer<BillingActionResult>();

      await _iap.restorePurchases();

      // Play delivers owned items on the stream; empty means nothing to restore.
      return await _actionCompleter!.future.timeout(
        const Duration(seconds: 12),
        onTimeout: () {
          if (_sawOwnedDuringRestore) return BillingActionResult.success;
          return BillingActionResult.nothingToRestore;
        },
      );
    } on Object catch (error, stack) {
      developer.log(
        'restorePurchases failed: $error',
        name: 'BillingService',
        error: error,
        stackTrace: stack,
      );
      return BillingActionResult.error;
    } finally {
      _restoreInFlight = false;
      _actionCompleter = null;
      _sawOwnedDuringRestore = false;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _completeAction(BillingActionResult.cancelled);
  }

  Future<void> _queryProduct() async {
    try {
      final response = await _iap.queryProductDetails({
        BillingConfig.supporterProductId,
      });
      if (response.error != null) {
        developer.log(
          'queryProductDetails error: ${response.error}',
          name: 'BillingService',
        );
      }
      if (response.notFoundIDs.isNotEmpty) {
        developer.log(
          'Product not found in Play: ${response.notFoundIDs.join(', ')}',
          name: 'BillingService',
        );
      }
      _product = response.productDetails.isEmpty
          ? null
          : response.productDetails.first;
    } on Object catch (error, stack) {
      _product = null;
      developer.log(
        'queryProductDetails threw: $error',
        name: 'BillingService',
        error: error,
        stackTrace: stack,
      );
    }
  }

  Future<void> _onPurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != BillingConfig.supporterProductId) {
        if (purchase.pendingCompletePurchase) {
          await _safeComplete(purchase);
        }
        continue;
      }

      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _sawOwnedDuringRestore = true;
          try {
            await onSupporterUnlocked();
            await _safeComplete(purchase);
            _completeAction(BillingActionResult.success);
          } on Object catch (error, stack) {
            developer.log(
              'Failed to unlock supporter: $error',
              name: 'BillingService',
              error: error,
              stackTrace: stack,
            );
            _completeAction(BillingActionResult.error);
          }
        case PurchaseStatus.error:
          developer.log(
            'Purchase error: ${purchase.error}',
            name: 'BillingService',
          );
          await _safeComplete(purchase);
          // Quiet launch restore should not surface stream noise.
          if (_purchaseInFlight || _restoreInFlight) {
            _completeAction(BillingActionResult.error);
          }
        case PurchaseStatus.canceled:
          await _safeComplete(purchase);
          if (_purchaseInFlight) {
            _completeAction(BillingActionResult.cancelled);
          }
      }
    }
  }

  Future<void> _safeComplete(PurchaseDetails purchase) async {
    if (!purchase.pendingCompletePurchase) return;
    try {
      await _iap.completePurchase(purchase);
    } on Object catch (error) {
      developer.log(
        'completePurchase failed: $error',
        name: 'BillingService',
      );
    }
  }

  void _completeAction(BillingActionResult result) {
    final completer = _actionCompleter;
    if (completer == null || completer.isCompleted) return;
    completer.complete(result);
  }
}
