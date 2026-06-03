import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:blinking/screens/purchase/paywall_screen.dart';
import 'package:blinking/core/services/purchases_service.dart';
import 'package:blinking/core/services/entitlement_service.dart';
import 'package:blinking/providers/locale_provider.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

CustomerInfo _makeCustomerInfo({bool hasPro = false}) {
  final entry = <String, dynamic>{
    'identifier': 'pro_access',
    'isActive': true,
    'willRenew': false,
    'latestPurchaseDate': '2026-01-01T00:00:00Z',
    'originalPurchaseDate': '2026-01-01T00:00:00Z',
    'productIdentifier': 'blinking_pro',
    'isSandbox': true,
    'ownershipType': 'PURCHASED',
    'store': 'APP_STORE',
    'periodType': 'NORMAL',
    'expirationDate': null,
    'unsubscribeDetectedAt': null,
    'billingIssueDetectedAt': null,
    'productPlanIdentifier': null,
    'verification': 'NOT_REQUESTED',
  };
  final map = hasPro ? {'pro_access': entry} : <String, dynamic>{};
  return CustomerInfo.fromJson({
    'entitlements': {'all': map, 'active': map, 'verification': 'NOT_REQUESTED'},
    'allPurchaseDates': hasPro ? {'blinking_pro': '2026-01-01T00:00:00Z'} : <String, dynamic>{},
    'activeSubscriptions': <String>[],
    'allPurchasedProductIdentifiers': hasPro ? ['blinking_pro'] : <String>[],
    'nonSubscriptionTransactions': <Map<String, dynamic>>[],
    'firstSeen': '2026-01-01T00:00:00Z',
    'originalAppUserId': 'test_user',
    'allExpirationDates': <String, dynamic>{},
    'requestDate': '2026-01-01T00:00:00Z',
    'latestExpirationDate': null,
    'originalPurchaseDate': null,
    'originalApplicationVersion': null,
    'managementURL': null,
  });
}

enum _NextPurchase { success, cancel, error }
enum _NextRestore { success, noPrior, error }

/// Subclasses PurchasesService so it can be injected as the correct type
/// via Provider without touching RevenueCat platform channels.
class _FakePurchasesService extends PurchasesService {
  bool _fakeInitialized;
  bool _fakeIsPro;
  String? _fakeLastError;
  final String? _fakePriceString;
  _NextPurchase nextPurchase;
  _NextRestore nextRestore;
  int refreshCallCount = 0;

  _FakePurchasesService({
    bool initialized = true,
    bool isPro = false,
    String? priceString = '\$7.99',
    this.nextPurchase = _NextPurchase.cancel,
    this.nextRestore = _NextRestore.noPrior,
  })  : _fakeInitialized = initialized,
        _fakeIsPro = isPro,
        _fakePriceString = priceString;

  @override bool get isInitialized => _fakeInitialized;
  @override bool get isPro => _fakeIsPro;
  @override String? get lastError => _fakeLastError;
  @override String? get proPriceString => _fakePriceString;

  @override
  Future<void> init({String? appleApiKey, String? googleApiKey, String? unifiedKey}) async {}

  @override
  Future<CustomerInfo?> purchaseProduct(String productId) async {
    _fakeLastError = null;
    // Yield so the widget can process isPurchasing=true before completing.
    await Future.microtask(() {});
    switch (nextPurchase) {
      case _NextPurchase.success:
        _fakeIsPro = true;
        notifyListeners();
        return _makeCustomerInfo(hasPro: true);
      case _NextPurchase.cancel:
        // info=null + lastError=null → cancel branch in _handlePurchase
        notifyListeners();
        return null;
      case _NextPurchase.error:
        _fakeLastError = 'Purchase failed. Please try again.';
        notifyListeners();
        return null;
    }
  }

  @override
  Future<CustomerInfo?> restorePurchases() async {
    _fakeLastError = null;
    await Future.microtask(() {});
    switch (nextRestore) {
      case _NextRestore.success:
        _fakeIsPro = true;
        notifyListeners();
        return _makeCustomerInfo(hasPro: true);
      case _NextRestore.noPrior:
        // Real RC returns non-null CustomerInfo with empty entitlements on
        // "no prior purchase" — never null unless an exception occurred.
        notifyListeners();
        return _makeCustomerInfo(hasPro: false);
      case _NextRestore.error:
        // Returns null with lastError set — maps to the error snackbar branch.
        _fakeLastError = 'Restore failed. Please try again.';
        notifyListeners();
        return null;
    }
  }

  @override
  Future<void> refreshCustomerInfo() async {
    refreshCallCount++;
  }
}

/// Pumps PaywallScreen on top of a home scaffold so Navigator.pop() resolves.
/// After a successful purchase/restore the screen pops and 'Home' is visible.
Future<void> _pump(
  WidgetTester tester,
  _FakePurchasesService purchases,
) async {
  SharedPreferences.setMockInitialValues({});

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<PurchasesService>.value(value: purchases),
        ChangeNotifierProvider<EntitlementService>(create: (_) => EntitlementService()),
        ChangeNotifierProvider<LocaleProvider>(create: (_) => LocaleProvider()),
      ],
      child: const MaterialApp(
        home: Scaffold(body: Text('Home')),
      ),
    ),
  );

  // Push PaywallScreen on top so Navigator.pop() inside it has somewhere to go.
  final NavigatorState nav = tester.state(find.byType(Navigator));
  nav.push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('PaywallScreen', () {
    group('purchase flow', () {
      testWidgets('store unavailable hides Get Pro button and shows warning',
          (tester) async {
        final purchases = _FakePurchasesService(initialized: false);
        await _pump(tester, purchases);

        expect(find.text('Store unavailable, please try again later'),
            findsOneWidget);
        // Get Pro button is disabled when store not ready — its onPressed is null.
        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(button.onPressed, isNull);
      });

      testWidgets('successful purchase shows Welcome to Pro snackbar and pops screen',
          (tester) async {
        final purchases = _FakePurchasesService(nextPurchase: _NextPurchase.success);
        await _pump(tester, purchases);

        await tester.tap(find.text('Get Pro — \$7.99'));
        await tester.pumpAndSettle();

        expect(find.text('Welcome to Pro!'), findsOneWidget);
        // Paywall was popped — home scaffold is now visible.
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Blinking Pro'), findsNothing);
      });

      testWidgets('user cancel shows no snackbar and paywall stays open',
          (tester) async {
        final purchases = _FakePurchasesService(nextPurchase: _NextPurchase.cancel);
        await _pump(tester, purchases);

        await tester.tap(find.text('Get Pro — \$7.99'));
        await tester.pumpAndSettle();

        expect(find.byType(SnackBar), findsNothing);
        // Screen is still open.
        expect(find.text('Blinking Pro'), findsOneWidget);
      });

      testWidgets('purchase error shows error snackbar and paywall stays open',
          (tester) async {
        final purchases = _FakePurchasesService(nextPurchase: _NextPurchase.error);
        await _pump(tester, purchases);

        await tester.tap(find.text('Get Pro — \$7.99'));
        await tester.pumpAndSettle();

        expect(find.text('Purchase failed. Please try again.'), findsOneWidget);
        // Screen is still open.
        expect(find.text('Blinking Pro'), findsOneWidget);
      });

      testWidgets('Get Pro button is re-enabled after purchase completes',
          (tester) async {
        final purchases = _FakePurchasesService(nextPurchase: _NextPurchase.cancel);
        await _pump(tester, purchases);

        await tester.tap(find.text('Get Pro — \$7.99'));
        await tester.pumpAndSettle();

        // After cancel, button should be enabled (not null onPressed).
        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(button.onPressed, isNotNull);
      });

      testWidgets('dynamic price from service is shown on button',
          (tester) async {
        final purchases = _FakePurchasesService(priceString: '¥58.00');
        await _pump(tester, purchases);

        expect(find.text('Get Pro — ¥58.00'), findsOneWidget);
      });

      testWidgets('fallback price shown when proPriceString is null',
          (tester) async {
        final purchases = _FakePurchasesService(priceString: null);
        await _pump(tester, purchases);

        // Falls back to hardcoded $7.99 in build().
        expect(find.text('Get Pro — \$7.99'), findsOneWidget);
      });
    });

    group('restore flow', () {
      testWidgets('successful restore shows Pro restored snackbar and pops screen',
          (tester) async {
        final purchases = _FakePurchasesService(nextRestore: _NextRestore.success);
        await _pump(tester, purchases);

        await tester.tap(find.text('Restore Purchases'));
        await tester.pumpAndSettle();

        expect(find.text('Pro restored.'), findsOneWidget);
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Blinking Pro'), findsNothing);
      });

      testWidgets('restore with no prior purchase shows informational snackbar',
          (tester) async {
        final purchases = _FakePurchasesService(nextRestore: _NextRestore.noPrior);
        await _pump(tester, purchases);

        await tester.tap(find.text('Restore Purchases'));
        await tester.pumpAndSettle();

        expect(find.text('No previous Pro purchase found.'), findsOneWidget);
        expect(find.text('Blinking Pro'), findsOneWidget);
      });

      testWidgets('restore store error shows error snackbar not misleading message',
          (tester) async {
        final purchases = _FakePurchasesService(nextRestore: _NextRestore.error);
        await _pump(tester, purchases);

        await tester.tap(find.text('Restore Purchases'));
        await tester.pumpAndSettle();

        // Shows the actual error, not "No previous Pro purchase found.".
        expect(find.text('Restore failed. Please try again.'), findsOneWidget);
        expect(find.text('No previous Pro purchase found.'), findsNothing);
        expect(find.text('Blinking Pro'), findsOneWidget);
      });

      testWidgets('Restore button is re-enabled after restore completes',
          (tester) async {
        final purchases = _FakePurchasesService(nextRestore: _NextRestore.noPrior);
        await _pump(tester, purchases);

        await tester.tap(find.text('Restore Purchases'));
        await tester.pumpAndSettle();

        // Button shows text again, not spinner — _isRestoring is false.
        expect(find.text('Restore Purchases'), findsOneWidget);
        final btn = tester.widget<TextButton>(find.ancestor(
          of: find.text('Restore Purchases'),
          matching: find.byType(TextButton),
        ));
        expect(btn.onPressed, isNotNull);
      });

      testWidgets('refreshCustomerInfo is NOT called during restore flow',
          (tester) async {
        // Validates the fix: removing refreshCustomerInfo() from _handleRestore.
        // The restore result is already the most authoritative CustomerInfo —
        // calling refresh overwrites it with potentially stale server state.
        final purchases = _FakePurchasesService(nextRestore: _NextRestore.success);
        await _pump(tester, purchases);

        await tester.tap(find.text('Restore Purchases'));
        await tester.pumpAndSettle();

        expect(purchases.refreshCallCount, equals(0));
      });
    });
  });
}
