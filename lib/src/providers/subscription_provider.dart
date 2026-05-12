import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/purchase_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  SubscriptionProvider(this._purchaseService);

  static const _proKey = 'gympro_is_pro';

  final PurchaseService _purchaseService;

  bool _isPro = false;
  bool _loading = true;
  bool _storeAvailable = false;
  String? _error;
  List<ProductDetails> _products = [];

  bool get isPro => _isPro;
  bool get loading => _loading;
  bool get storeAvailable => _storeAvailable;
  String? get error => _error;
  List<ProductDetails> get products => _products;

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _isPro = prefs.getBool(_proKey) ?? false;

    try {
      _storeAvailable = await _purchaseService.isAvailable;
      if (_storeAvailable) {
        _products = await _purchaseService.loadProducts();
        _purchaseService.listen((purchase) async {
          await setPro(true);
        });
      }
    } catch (error) {
      _error = error.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> buy(ProductDetails product) async {
    try {
      await _purchaseService.buy(product);
    } catch (error) {
      _error = error.toString();
      notifyListeners();
    }
  }

  Future<void> restore() => _purchaseService.restore();

  Future<void> setPro(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_proKey, value);
    _isPro = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _purchaseService.dispose();
    super.dispose();
  }
}
