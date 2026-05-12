import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

class PurchaseService {
  static const monthlyId = 'gympro_pro_monthly_199';
  static const yearlyId = 'gympro_pro_yearly_999';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  Future<bool> get isAvailable => _iap.isAvailable();

  Future<List<ProductDetails>> loadProducts() async {
    final response = await _iap.queryProductDetails({monthlyId, yearlyId});
    if (response.error != null) throw response.error!;
    return response.productDetails;
  }

  void listen(void Function(PurchaseDetails purchase) onPurchased) {
    _subscription?.cancel();
    _subscription = _iap.purchaseStream.listen((purchases) async {
      for (final purchase in purchases) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          onPurchased(purchase);
        }
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
      }
    });
  }

  Future<void> buy(ProductDetails product) {
    final param = PurchaseParam(productDetails: product);
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  Future<void> restore() => _iap.restorePurchases();

  void dispose() {
    _subscription?.cancel();
  }
}
