import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'device_service.dart';

/// Wraps RevenueCat IAP and communicates with the Blinking entitlement
/// server for receipt validation and state transitions.
class PurchasesService extends ChangeNotifier {
  static const _entitlementBaseUrl =
      'https://blinkingchorus.com/api/entitlement';

  bool _initialized = false;
  bool _purchasing = false;
  bool _restoring = false;
  Offerings? _offerings;
  CustomerInfo? _customerInfo;
  String? _lastError;

  bool get isInitialized => _initialized;
  bool get isPurchasing => _purchasing;
  bool get isRestoring => _restoring;
  bool get isPro => _customerInfo?.entitlements.active.containsKey('pro_access') ?? false;
  Offerings? get offerings => _offerings;
  String? get lastError => _lastError;

  Future<void> init({
    String? appleApiKey,
    String? googleApiKey,
    String? unifiedKey,
  }) async {
    if (_initialized) return;

    final platformKey = unifiedKey ??
        (defaultTargetPlatform == TargetPlatform.android
            ? googleApiKey
            : appleApiKey);

    if (platformKey == null || platformKey.isEmpty) return;

    await Purchases.configure(
      PurchasesConfiguration(platformKey)
        ..appUserID = await DeviceService.getDeviceId(),
    );

    try {
      _customerInfo = await Purchases.getCustomerInfo();
      _offerings = await Purchases.getOfferings();
    } catch (e) {
      _lastError = e.toString();
    }
    _initialized = true;
    notifyListeners();
  }

  Future<CustomerInfo?> purchaseProduct(String productId) async {
    if (!_initialized) {
      _lastError = 'Store not initialized';
      return null;
    }

    _lastError = null;
    _purchasing = true;
    notifyListeners();

    try {
      Package? pkg;

      // Try current offering first
      final offering = _offerings?.current;
      if (offering != null) {
        for (final p in offering.availablePackages) {
          if (p.storeProduct.identifier == productId) {
            pkg = p;
            break;
          }
        }
      }

      // Fallback: search all offerings
      if (pkg == null && _offerings != null) {
        for (final off in _offerings!.all.values) {
          for (final p in off.availablePackages) {
            if (p.storeProduct.identifier == productId) {
              pkg = p;
              break;
            }
          }
          if (pkg != null) break;
        }
      }

      if (pkg == null) {
        _lastError = 'Product $productId not found. Check RevenueCat dashboard: offering must be set as "Current" and contain this product.';
        _purchasing = false;
        notifyListeners();
        return null;
      }

      final result = await Purchases.purchasePackage(pkg);
      final customerInfo = result.customerInfo;

      if (customerInfo.entitlements.active.containsKey('pro_access')) {
        await _validateWithServer();
      }

      _customerInfo = customerInfo;
      _purchasing = false;
      notifyListeners();
      return customerInfo;
    } on Exception catch (e) {
      final msg = e.toString();
      if (!msg.contains('cancelled') && !msg.contains('Cancel')) {
        _lastError = msg;
      }
      _purchasing = false;
      notifyListeners();
      return null;
    } catch (e) {
      _lastError = e.toString();
      _purchasing = false;
      notifyListeners();
      return null;
    }
  }

  Future<CustomerInfo?> restorePurchases() async {
    if (!_initialized) return null;

    _lastError = null;
    _restoring = true;
    notifyListeners();

    try {
      final customerInfo = await Purchases.restorePurchases();
      _customerInfo = customerInfo;

      if (customerInfo.entitlements.active.containsKey('pro_access')) {
        await _validateWithServer();
      }

      _restoring = false;
      notifyListeners();
      return customerInfo;
    } catch (e) {
      _lastError = e.toString();
      _restoring = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> _validateWithServer() async {
    try {
      final deviceId = await DeviceService.getDeviceId();

      await http.post(
        Uri.parse('$_entitlementBaseUrl/purchase'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'platform': defaultTargetPlatform == TargetPlatform.android
              ? 'google'
              : 'apple',
          'device_id': deviceId,
          'receipt': 'revenuecat_validated',
        }),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  Future<void> refreshCustomerInfo() async {
    if (!_initialized) return;
    _customerInfo = await Purchases.getCustomerInfo();
    notifyListeners();
  }
}
